#include "SDLApplication.h"
#include "SDLGamepad.h"
#include "SDLJoystick.h"
#include <system/System.h>

#ifdef HX_MACOS
#include <CoreFoundation/CoreFoundation.h>
#endif

#ifdef EMSCRIPTEN
#include "emscripten.h"
#endif

namespace lime
{

	AutoGCRoot *Application::callback = 0;
	SDLApplication *SDLApplication::currentApplication = 0;

	const int analogAxisDeadZone = 1000;
	std::map<int, std::map<int, int>> gamepadsAxisMap;
	bool inBackground = false;

	static double nextFrac = 0.0;
	static double s_sleepGuardMs = 2.0;
	static Uint32 s_lastSleepCalibration = 0;
	static bool s_busyWaitOnly = false;
	static bool firstTime = true;
	static SDL_atomic_t s_waitEventBlocking;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
	static SDL_atomic_t s_inModalEventWatch;
#endif

	static inline void CalibrateSleepGuard(bool force = false)
	{

		Uint32 now = SDL_GetTicks();
		if (!force && s_lastSleepCalibration != 0 && (now - s_lastSleepCalibration) < 5000)
			return;

		Uint32 t0 = SDL_GetTicks();
		SDL_Delay(1);
		Uint32 t1 = SDL_GetTicks();

		Uint32 observed = t1 - t0;
		if (observed < 1)
			observed = 1;

		double observedD = (double)observed;

		if (s_lastSleepCalibration == 0 || force)
		{

			s_sleepGuardMs = observedD;
		}
		else
		{

			// bend in scheduler changes passively so pacing stays stable
			s_sleepGuardMs = (s_sleepGuardMs * 0.8) + (observedD * 0.2);
		}

		if (s_sleepGuardMs < 1.0)
			s_sleepGuardMs = 1.0;
		if (s_sleepGuardMs > 16.0)
			s_sleepGuardMs = 16.0;

		s_lastSleepCalibration = now;
	}

	static inline Uint32 GetSleepGuardMs()
	{

		Uint32 guardMs = (Uint32)(s_sleepGuardMs + 0.5);
		if (guardMs < 1)
			guardMs = 1;
		return guardMs;
	}

	static inline void UpdateSleepGuard(Uint32 requestedMs, Uint32 elapsedMs)
	{

		if (requestedMs == 0 || elapsedMs < requestedMs)
			return;

		double overshoot = (double)elapsedMs - (double)requestedMs;
		double targetGuard = overshoot + 1.0;

		if (targetGuard < 1.0)
			targetGuard = 1.0;
		if (targetGuard > 16.0)
			targetGuard = 16.0;

		s_sleepGuardMs = (s_sleepGuardMs * 0.9) + (targetGuard * 0.1);
	}

	static inline Uint32 NextFrameStep(double framePeriod)
	{
		Uint32 base = (Uint32)framePeriod;
		nextFrac += framePeriod - (double)base;
		if (nextFrac >= 1.0)
		{
			base++;
			nextFrac -= 1.0;
		}
		return base;
	}

	SDLApplication::SDLApplication()
	{

		initFlags = SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER | SDL_INIT_TIMER | SDL_INIT_JOYSTICK;
#if defined(LIME_MOJOAL) || defined(LIME_OPENALSOFT)
		initFlags |= SDL_INIT_AUDIO;
#endif

		if (SDL_Init(initFlags) != 0)
		{

			printf("Could not initialize SDL: %s.\n", SDL_GetError());
		}

		SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_WARN);

		currentApplication = this;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		modalWatchInstalled = false;
		mainThreadID = SDL_ThreadID();
		pendingResizeDispatchSkips = 0;
		pendingWatchRenderSkips = 0;
#endif

		framePeriod = 1000.0 / 60.0;
		currentUpdate = 0;

		lastUpdate = 0;
		nextUpdate = 0;

		ApplicationEvent applicationEvent;
		ClipboardEvent clipboardEvent;
		DropEvent dropEvent;
		GamepadEvent gamepadEvent;
		JoystickEvent joystickEvent;
		KeyEvent keyEvent;
		MouseEvent mouseEvent;
		OrientationEvent orientationEvent;
		RenderEvent renderEvent;
		SensorEvent sensorEvent;
		TextEvent textEvent;
		TouchEvent touchEvent;
		WindowEvent windowEvent;

		SDL_EventState(SDL_DROPFILE, SDL_ENABLE);
		SDLJoystick::Init();
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		SDL_AtomicSet(&s_inModalEventWatch, 0);
		SDL_AtomicSet(&s_waitEventBlocking, 0);
		SDL_AddEventWatch(ModalEventWatch, this);
		modalWatchInstalled = true;
#endif

#ifdef HX_MACOS
		CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(CFBundleGetMainBundle());
		char path[PATH_MAX];

		if (CFURLGetFileSystemRepresentation(resourcesURL, TRUE, (UInt8 *)path, PATH_MAX))
		{

			chdir(path);
		}

		CFRelease(resourcesURL);
#endif
	}

	SDLApplication::~SDLApplication()
	{
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		if (modalWatchInstalled && SDL_WasInit(0))
		{
			SDL_DelEventWatch(ModalEventWatch, this);
			modalWatchInstalled = false;
		}
#endif
	}

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
	int SDLApplication::ModalEventWatch(void *userdata, SDL_Event *event)
	{

		if (!event || event->type != SDL_WINDOWEVENT)
			return 0;

		const Uint8 windowEvent = event->window.event;
		if (windowEvent != SDL_WINDOWEVENT_EXPOSED && windowEvent != SDL_WINDOWEVENT_SIZE_CHANGED && windowEvent != SDL_WINDOWEVENT_RESIZED && windowEvent != SDL_WINDOWEVENT_MOVED)
			return 0;

		SDLApplication *application = (SDLApplication *)userdata;
		if (!application || !application->active || inBackground)
			return 0;
		if (SDL_AtomicGet(&s_waitEventBlocking) == 0)
			return 0;

		if (SDL_ThreadID() != application->mainThreadID)
			return 0;

		// Prevent re-entry if rendering queues another window event.
		if (!SDL_AtomicCAS(&s_inModalEventWatch, 0, 1))
			return 0;

		application->PumpOneFrameFromWatch(event);
		SDL_AtomicSet(&s_inModalEventWatch, 0);
		return 0;
	}

	void SDLApplication::PumpOneFrameFromWatch(SDL_Event *watchEvent)
	{

		if (!active || inBackground)
			return;

		bool isResizeEvent = false;
		bool isExposeEvent = false;
		if (watchEvent && watchEvent->type == SDL_WINDOWEVENT)
		{
			isResizeEvent = (watchEvent->window.event == SDL_WINDOWEVENT_SIZE_CHANGED || watchEvent->window.event == SDL_WINDOWEVENT_RESIZED);
			isExposeEvent = (watchEvent->window.event == SDL_WINDOWEVENT_EXPOSED);
		}

		currentUpdate = SDL_GetTicks();
		bool frameDue = ((Sint32)(currentUpdate - nextUpdate) >= 0);
		bool isResizeOrExposeEvent = (isResizeEvent || isExposeEvent);
		if (!frameDue && !isResizeEvent)
			return;

		bool exitedBlocking = false;
		if (SDL_AtomicGet(&s_waitEventBlocking))
		{
			System::GCExitBlocking();
			SDL_AtomicSet(&s_waitEventBlocking, 0);
			exitedBlocking = true;
		}

		if (isResizeEvent)
		{
			ProcessWindowEvent(watchEvent);
			pendingResizeDispatchSkips++;
		}

		if (frameDue)
		{
			applicationEvent.type = UPDATE;
			applicationEvent.deltaTime = currentUpdate - lastUpdate;
			lastUpdate = currentUpdate;

			nextUpdate += NextFrameStep(framePeriod);
			while (nextUpdate <= currentUpdate)
			{
				nextUpdate += NextFrameStep(framePeriod);
			}

			ApplicationEvent::Dispatch(&applicationEvent);
			RenderEvent::Dispatch(&renderEvent);

			if (watchEvent && isResizeOrExposeEvent)
			{
				pendingWatchRenderSkips++;
			}
		}

		if (exitedBlocking)
		{
			System::GCEnterBlocking();
			SDL_AtomicSet(&s_waitEventBlocking, 1);
		}
	}
#endif

	int SDLApplication::Exec()
	{

		Init();

#ifdef EMSCRIPTEN
		emscripten_cancel_main_loop();
		emscripten_set_main_loop(UpdateFrame, 0, 0);
		emscripten_set_main_loop_timing(EM_TIMING_RAF, 1);
#endif

#if defined(IPHONE) || defined(EMSCRIPTEN)

		return 0;

#else

		while (active)
		{

			Update();
		}

		return Quit();

#endif
	}

	void SDLApplication::HandleEvent(SDL_Event *event)
	{

#if defined(IPHONE) || defined(EMSCRIPTEN)

		int top = 0;
		gc_set_top_of_stack(&top, false);

#endif

		switch (event->type)
		{

		case SDL_USEREVENT:

			if (!inBackground)
			{

				currentUpdate = SDL_GetTicks();
				applicationEvent.type = UPDATE;
				applicationEvent.deltaTime = currentUpdate - lastUpdate;
				lastUpdate = currentUpdate;

				nextUpdate += NextFrameStep(framePeriod);

				while (nextUpdate <= currentUpdate)
				{
					nextUpdate += NextFrameStep(framePeriod);
				}

				ApplicationEvent::Dispatch(&applicationEvent);
				RenderEvent::Dispatch(&renderEvent);
			}

			break;

		case SDL_APP_WILLENTERBACKGROUND:

			inBackground = true;

			windowEvent.type = WINDOW_DEACTIVATE;
			WindowEvent::Dispatch(&windowEvent);
			break;

		case SDL_APP_WILLENTERFOREGROUND:

			break;

		case SDL_APP_DIDENTERFOREGROUND:

			windowEvent.type = WINDOW_ACTIVATE;
			WindowEvent::Dispatch(&windowEvent);

			inBackground = false;
			break;

		case SDL_CLIPBOARDUPDATE:

			ProcessClipboardEvent(event);
			break;

		case SDL_CONTROLLERAXISMOTION:
		case SDL_CONTROLLERBUTTONDOWN:
		case SDL_CONTROLLERBUTTONUP:
		case SDL_CONTROLLERDEVICEADDED:
		case SDL_CONTROLLERDEVICEREMOVED:

			ProcessGamepadEvent(event);
			break;

		case SDL_DISPLAYEVENT:

			switch (event->display.event)
			{

			case SDL_DISPLAYEVENT_ORIENTATION:

				// this is the orientation of what is rendered, which
				// may not exactly match the orientation of the device,
				// if the app was locked to portrait or landscape.
				orientationEvent.type = DISPLAY_ORIENTATION_CHANGE;
				orientationEvent.orientation = event->display.data1;
				orientationEvent.display = event->display.display;
				OrientationEvent::Dispatch(&orientationEvent);

				break;
			}
			break;

		case SDL_DROPFILE:

			ProcessDropEvent(event);
			break;

		case SDL_FINGERMOTION:
		case SDL_FINGERDOWN:
		case SDL_FINGERUP:

			ProcessTouchEvent(event);
			break;

		case SDL_JOYAXISMOTION:

			if (SDLJoystick::IsAccelerometer(event->jaxis.which))
			{

				ProcessSensorEvent(event);
			}
			else
			{

				ProcessJoystickEvent(event);
			}

			break;

		case SDL_JOYBALLMOTION:
		case SDL_JOYBUTTONDOWN:
		case SDL_JOYBUTTONUP:
		case SDL_JOYHATMOTION:
		case SDL_JOYDEVICEADDED:
		case SDL_JOYDEVICEREMOVED:

			ProcessJoystickEvent(event);
			break;

		case SDL_KEYDOWN:
		case SDL_KEYUP:

			ProcessKeyEvent(event);
			break;

		case SDL_MOUSEMOTION:
		case SDL_MOUSEBUTTONDOWN:
		case SDL_MOUSEBUTTONUP:
		case SDL_MOUSEWHEEL:

			ProcessMouseEvent(event);
			break;

#ifndef EMSCRIPTEN
		case SDL_RENDER_DEVICE_RESET:

			renderEvent.type = RENDER_CONTEXT_LOST;
			RenderEvent::Dispatch(&renderEvent);

			renderEvent.type = RENDER_CONTEXT_RESTORED;
			RenderEvent::Dispatch(&renderEvent);

			renderEvent.type = RENDER;
			break;
#endif

		case SDL_TEXTINPUT:
		case SDL_TEXTEDITING:

			ProcessTextEvent(event);
			break;

		case SDL_WINDOWEVENT:

			switch (event->window.event)
			{

			case SDL_WINDOWEVENT_ENTER:
			case SDL_WINDOWEVENT_LEAVE:
			case SDL_WINDOWEVENT_SHOWN:
			case SDL_WINDOWEVENT_HIDDEN:
			case SDL_WINDOWEVENT_FOCUS_GAINED:
			case SDL_WINDOWEVENT_FOCUS_LOST:
			case SDL_WINDOWEVENT_MAXIMIZED:
			case SDL_WINDOWEVENT_MINIMIZED:
			case SDL_WINDOWEVENT_MOVED:
			case SDL_WINDOWEVENT_RESTORED:

				ProcessWindowEvent(event);
				break;

			case SDL_WINDOWEVENT_EXPOSED:

				ProcessWindowEvent(event);

				if (!inBackground)
				{
					bool skipImmediateRender = false;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
					if (pendingWatchRenderSkips > 0)
					{
						pendingWatchRenderSkips--;
						skipImmediateRender = true;
					}

					if (SDL_AtomicGet(&s_waitEventBlocking))
					{
						PumpOneFrameFromWatch();
					}
					else
#endif
					{
						currentUpdate = SDL_GetTicks();
						bool frameDue = ((Sint32)(currentUpdate - nextUpdate) >= 0);
						if (frameDue)
						{
							applicationEvent.type = UPDATE;
							applicationEvent.deltaTime = currentUpdate - lastUpdate;
							lastUpdate = currentUpdate;

							nextUpdate += NextFrameStep(framePeriod);
							while (nextUpdate <= currentUpdate)
							{
								nextUpdate += NextFrameStep(framePeriod);
							}

							ApplicationEvent::Dispatch(&applicationEvent);
						}

						if (frameDue && !skipImmediateRender)
						{
							RenderEvent::Dispatch(&renderEvent);
						}
					}
				}

				break;

			case SDL_WINDOWEVENT_SIZE_CHANGED:
			case SDL_WINDOWEVENT_RESIZED:
			{

				bool skipResizeDispatch = false;
				bool skipImmediateRender = false;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
				if (pendingResizeDispatchSkips > 0)
				{
					pendingResizeDispatchSkips--;
					skipResizeDispatch = true;
				}
				if (pendingWatchRenderSkips > 0)
				{
					pendingWatchRenderSkips--;
					skipImmediateRender = true;
				}
#endif
				if (!skipResizeDispatch)
				{
					ProcessWindowEvent(event);
				}

				if (!inBackground)
				{
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
					if (SDL_AtomicGet(&s_waitEventBlocking))
					{
						PumpOneFrameFromWatch();
					}
					else
#endif
					{
						currentUpdate = SDL_GetTicks();
						bool frameDue = ((Sint32)(currentUpdate - nextUpdate) >= 0);
						if (frameDue)
						{
							applicationEvent.type = UPDATE;
							applicationEvent.deltaTime = currentUpdate - lastUpdate;
							lastUpdate = currentUpdate;

							nextUpdate += NextFrameStep(framePeriod);
							while (nextUpdate <= currentUpdate)
							{
								nextUpdate += NextFrameStep(framePeriod);
							}

							ApplicationEvent::Dispatch(&applicationEvent);
						}

						if (frameDue && !skipImmediateRender)
						{
							RenderEvent::Dispatch(&renderEvent);
						}
					}
				}

				break;
			}

			case SDL_WINDOWEVENT_CLOSE:

				ProcessWindowEvent(event);

				// Avoid handling SDL_QUIT if in response to window.close
				SDL_Event event;

				if (SDL_PollEvent(&event))
				{

					if (event.type != SDL_QUIT)
					{

						HandleEvent(&event);
					}
				}
				break;
			}

			break;

		case SDL_QUIT:

			active = false;
			break;
		}
	}

	void SDLApplication::Init()
	{

		active = true;
		lastUpdate = SDL_GetTicks();
		nextUpdate = lastUpdate;
		nextFrac = 0.0;
		firstTime = true;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		pendingResizeDispatchSkips = 0;
		pendingWatchRenderSkips = 0;
#endif
		CalibrateSleepGuard(true);
	}

	void SDLApplication::ProcessClipboardEvent(SDL_Event *event)
	{

		if (ClipboardEvent::callback)
		{

			clipboardEvent.type = CLIPBOARD_UPDATE;

			ClipboardEvent::Dispatch(&clipboardEvent);
		}
	}

	void SDLApplication::ProcessDropEvent(SDL_Event *event)
	{

		if (DropEvent::callback)
		{

			dropEvent.type = DROP_FILE;
			dropEvent.file = (vbyte *)event->drop.file;

			DropEvent::Dispatch(&dropEvent);
			SDL_free(dropEvent.file);
		}
	}

	void SDLApplication::ProcessGamepadEvent(SDL_Event *event)
	{

		if (GamepadEvent::callback)
		{

			switch (event->type)
			{

			case SDL_CONTROLLERAXISMOTION:

				if (gamepadsAxisMap[event->caxis.which].empty())
				{

					gamepadsAxisMap[event->caxis.which][event->caxis.axis] = event->caxis.value;
				}
				else if (gamepadsAxisMap[event->caxis.which][event->caxis.axis] == event->caxis.value)
				{

					break;
				}

				gamepadEvent.type = GAMEPAD_AXIS_MOVE;
				gamepadEvent.axis = event->caxis.axis;
				gamepadEvent.id = event->caxis.which;

				if (event->caxis.value > -analogAxisDeadZone && event->caxis.value < analogAxisDeadZone)
				{

					if (gamepadsAxisMap[event->caxis.which][event->caxis.axis] != 0)
					{

						gamepadsAxisMap[event->caxis.which][event->caxis.axis] = 0;
						gamepadEvent.axisValue = 0;
						GamepadEvent::Dispatch(&gamepadEvent);
					}

					break;
				}

				gamepadsAxisMap[event->caxis.which][event->caxis.axis] = event->caxis.value;
				gamepadEvent.axisValue = event->caxis.value / (event->caxis.value > 0 ? 32767.0 : 32768.0);

				GamepadEvent::Dispatch(&gamepadEvent);
				break;

			case SDL_CONTROLLERBUTTONDOWN:

				gamepadEvent.type = GAMEPAD_BUTTON_DOWN;
				gamepadEvent.button = event->cbutton.button;
				gamepadEvent.id = event->cbutton.which;

				GamepadEvent::Dispatch(&gamepadEvent);
				break;

			case SDL_CONTROLLERBUTTONUP:

				gamepadEvent.type = GAMEPAD_BUTTON_UP;
				gamepadEvent.button = event->cbutton.button;
				gamepadEvent.id = event->cbutton.which;

				GamepadEvent::Dispatch(&gamepadEvent);
				break;

			case SDL_CONTROLLERDEVICEADDED:

				if (SDLGamepad::Connect(event->cdevice.which))
				{

					gamepadEvent.type = GAMEPAD_CONNECT;
					gamepadEvent.id = SDLGamepad::GetInstanceID(event->cdevice.which);

					GamepadEvent::Dispatch(&gamepadEvent);
				}

				break;

			case SDL_CONTROLLERDEVICEREMOVED:
			{

				gamepadEvent.type = GAMEPAD_DISCONNECT;
				gamepadEvent.id = event->cdevice.which;

				GamepadEvent::Dispatch(&gamepadEvent);
				SDLGamepad::Disconnect(event->cdevice.which);
				break;
			}
			}
		}
	}

	void SDLApplication::ProcessJoystickEvent(SDL_Event *event)
	{

		if (JoystickEvent::callback)
		{

			switch (event->type)
			{

			case SDL_JOYAXISMOTION:

				if (!SDLJoystick::IsAccelerometer(event->jaxis.which))
				{

					joystickEvent.type = JOYSTICK_AXIS_MOVE;
					joystickEvent.index = event->jaxis.axis;
					joystickEvent.x = event->jaxis.value / (event->jaxis.value > 0 ? 32767.0 : 32768.0);
					joystickEvent.id = event->jaxis.which;

					JoystickEvent::Dispatch(&joystickEvent);
				}
				break;

			case SDL_JOYBUTTONDOWN:

				if (!SDLJoystick::IsAccelerometer(event->jbutton.which))
				{

					joystickEvent.type = JOYSTICK_BUTTON_DOWN;
					joystickEvent.index = event->jbutton.button;
					joystickEvent.id = event->jbutton.which;

					JoystickEvent::Dispatch(&joystickEvent);
				}
				break;

			case SDL_JOYBUTTONUP:

				if (!SDLJoystick::IsAccelerometer(event->jbutton.which))
				{

					joystickEvent.type = JOYSTICK_BUTTON_UP;
					joystickEvent.index = event->jbutton.button;
					joystickEvent.id = event->jbutton.which;

					JoystickEvent::Dispatch(&joystickEvent);
				}
				break;

			case SDL_JOYHATMOTION:

				if (!SDLJoystick::IsAccelerometer(event->jhat.which))
				{

					joystickEvent.type = JOYSTICK_HAT_MOVE;
					joystickEvent.index = event->jhat.hat;
					joystickEvent.eventValue = event->jhat.value;
					joystickEvent.id = event->jhat.which;

					JoystickEvent::Dispatch(&joystickEvent);
				}
				break;

			case SDL_JOYDEVICEADDED:

				if (SDLJoystick::Connect(event->jdevice.which))
				{

					joystickEvent.type = JOYSTICK_CONNECT;
					joystickEvent.id = SDLJoystick::GetInstanceID(event->jdevice.which);

					JoystickEvent::Dispatch(&joystickEvent);
				}
				break;

			case SDL_JOYDEVICEREMOVED:

				if (!SDLJoystick::IsAccelerometer(event->jdevice.which))
				{

					joystickEvent.type = JOYSTICK_DISCONNECT;
					joystickEvent.id = event->jdevice.which;

					JoystickEvent::Dispatch(&joystickEvent);
					SDLJoystick::Disconnect(event->jdevice.which);
				}
				break;
			}
		}
	}

	void SDLApplication::ProcessKeyEvent(SDL_Event *event)
	{

		if (KeyEvent::callback)
		{

			switch (event->type)
			{

			case SDL_KEYDOWN:
				keyEvent.type = KEY_DOWN;
				break;
			case SDL_KEYUP:
				keyEvent.type = KEY_UP;
				break;
			}

			keyEvent.keyCode = event->key.keysym.sym;
			keyEvent.modifier = event->key.keysym.mod;
			keyEvent.windowID = event->key.windowID;

			if (keyEvent.type == KEY_DOWN)
			{

				if (keyEvent.keyCode == SDLK_CAPSLOCK)
					keyEvent.modifier |= KMOD_CAPS;
				if (keyEvent.keyCode == SDLK_LALT)
					keyEvent.modifier |= KMOD_LALT;
				if (keyEvent.keyCode == SDLK_LCTRL)
					keyEvent.modifier |= KMOD_LCTRL;
				if (keyEvent.keyCode == SDLK_LGUI)
					keyEvent.modifier |= KMOD_LGUI;
				if (keyEvent.keyCode == SDLK_LSHIFT)
					keyEvent.modifier |= KMOD_LSHIFT;
				if (keyEvent.keyCode == SDLK_MODE)
					keyEvent.modifier |= KMOD_MODE;
				if (keyEvent.keyCode == SDLK_NUMLOCKCLEAR)
					keyEvent.modifier |= KMOD_NUM;
				if (keyEvent.keyCode == SDLK_RALT)
					keyEvent.modifier |= KMOD_RALT;
				if (keyEvent.keyCode == SDLK_RCTRL)
					keyEvent.modifier |= KMOD_RCTRL;
				if (keyEvent.keyCode == SDLK_RGUI)
					keyEvent.modifier |= KMOD_RGUI;
				if (keyEvent.keyCode == SDLK_RSHIFT)
					keyEvent.modifier |= KMOD_RSHIFT;
			}

			KeyEvent::Dispatch(&keyEvent);
		}
	}

	void SDLApplication::ProcessMouseEvent(SDL_Event *event)
	{

		if (MouseEvent::callback)
		{

			switch (event->type)
			{

			case SDL_MOUSEMOTION:

				mouseEvent.type = MOUSE_MOVE;
				mouseEvent.x = event->motion.x;
				mouseEvent.y = event->motion.y;
				mouseEvent.movementX = event->motion.xrel;
				mouseEvent.movementY = event->motion.yrel;
				break;

			case SDL_MOUSEBUTTONDOWN:

				SDL_CaptureMouse(SDL_TRUE);

				mouseEvent.type = MOUSE_DOWN;
				mouseEvent.button = event->button.button - 1;
				mouseEvent.x = event->button.x;
				mouseEvent.y = event->button.y;
				mouseEvent.clickCount = event->button.clicks;
				break;

			case SDL_MOUSEBUTTONUP:

				SDL_CaptureMouse(SDL_FALSE);

				mouseEvent.type = MOUSE_UP;
				mouseEvent.button = event->button.button - 1;
				mouseEvent.x = event->button.x;
				mouseEvent.y = event->button.y;
				mouseEvent.clickCount = event->button.clicks;
				break;

			case SDL_MOUSEWHEEL:

				mouseEvent.type = MOUSE_WHEEL;

				if (event->wheel.direction == SDL_MOUSEWHEEL_FLIPPED)
				{

					mouseEvent.x = -event->wheel.x;
					mouseEvent.y = -event->wheel.y;
				}
				else
				{

					mouseEvent.x = event->wheel.x;
					mouseEvent.y = event->wheel.y;
				}
				break;
			}

			mouseEvent.windowID = event->button.windowID;
			MouseEvent::Dispatch(&mouseEvent);
		}
	}

	void SDLApplication::ProcessSensorEvent(SDL_Event *event)
	{

		if (SensorEvent::callback)
		{

			double value = event->jaxis.value / 32767.0f;

			switch (event->jaxis.axis)
			{

			case 0:
				sensorEvent.x = value;
				break;
			case 1:
				sensorEvent.y = value;
				break;
			case 2:
				sensorEvent.z = value;
				break;
			default:
				break;
			}

			SensorEvent::Dispatch(&sensorEvent);
		}
	}

	void SDLApplication::ProcessTextEvent(SDL_Event *event)
	{

		if (TextEvent::callback)
		{

			switch (event->type)
			{

			case SDL_TEXTINPUT:

				textEvent.type = TEXT_INPUT;
				break;

			case SDL_TEXTEDITING:

				textEvent.type = TEXT_EDIT;
				textEvent.start = event->edit.start;
				textEvent.length = event->edit.length;
				break;
			}

			if (textEvent.text)
			{

				free(textEvent.text);
			}

			textEvent.text = (vbyte *)malloc(strlen(event->text.text) + 1);
			strcpy((char *)textEvent.text, event->text.text);

			textEvent.windowID = event->text.windowID;
			TextEvent::Dispatch(&textEvent);
		}
	}

	void SDLApplication::ProcessTouchEvent(SDL_Event *event)
	{

		if (TouchEvent::callback)
		{

			switch (event->type)
			{

			case SDL_FINGERMOTION:

				touchEvent.type = TOUCH_MOVE;
				break;

			case SDL_FINGERDOWN:

				touchEvent.type = TOUCH_START;
				break;

			case SDL_FINGERUP:

				touchEvent.type = TOUCH_END;
				break;
			}

			touchEvent.x = event->tfinger.x;
			touchEvent.y = event->tfinger.y;
			touchEvent.id = event->tfinger.fingerId;
			touchEvent.dx = event->tfinger.dx;
			touchEvent.dy = event->tfinger.dy;
			touchEvent.pressure = event->tfinger.pressure;
			touchEvent.device = event->tfinger.touchId;

			TouchEvent::Dispatch(&touchEvent);
		}
	}

	void SDLApplication::ProcessWindowEvent(SDL_Event *event)
	{

		if (WindowEvent::callback)
		{

			switch (event->window.event)
			{

			case SDL_WINDOWEVENT_SHOWN:
				windowEvent.type = WINDOW_SHOW;
				break;
			case SDL_WINDOWEVENT_CLOSE:
				windowEvent.type = WINDOW_CLOSE;
				break;
			case SDL_WINDOWEVENT_HIDDEN:
				windowEvent.type = WINDOW_HIDE;
				break;
			case SDL_WINDOWEVENT_ENTER:
				windowEvent.type = WINDOW_ENTER;
				break;
			case SDL_WINDOWEVENT_FOCUS_GAINED:
				windowEvent.type = WINDOW_FOCUS_IN;
				break;
			case SDL_WINDOWEVENT_FOCUS_LOST:
				windowEvent.type = WINDOW_FOCUS_OUT;
				break;
			case SDL_WINDOWEVENT_LEAVE:
				windowEvent.type = WINDOW_LEAVE;
				break;
			case SDL_WINDOWEVENT_MAXIMIZED:
				windowEvent.type = WINDOW_MAXIMIZE;
				break;
			case SDL_WINDOWEVENT_MINIMIZED:
				windowEvent.type = WINDOW_MINIMIZE;
				break;
			case SDL_WINDOWEVENT_EXPOSED:
				windowEvent.type = WINDOW_EXPOSE;
				break;

			case SDL_WINDOWEVENT_MOVED:

				windowEvent.type = WINDOW_MOVE;
				windowEvent.x = event->window.data1;
				windowEvent.y = event->window.data2;
				break;

			case SDL_WINDOWEVENT_SIZE_CHANGED:
			case SDL_WINDOWEVENT_RESIZED:

				windowEvent.type = WINDOW_RESIZE;
				windowEvent.width = event->window.data1;
				windowEvent.height = event->window.data2;
				break;

			case SDL_WINDOWEVENT_RESTORED:
				windowEvent.type = WINDOW_RESTORE;
				break;
			}

			windowEvent.windowID = event->window.windowID;
			WindowEvent::Dispatch(&windowEvent);
		}
	}

	int SDLApplication::Quit()
	{

		applicationEvent.type = EXIT;
		ApplicationEvent::Dispatch(&applicationEvent);
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		if (modalWatchInstalled)
		{
			SDL_DelEventWatch(ModalEventWatch, this);
			modalWatchInstalled = false;
		}
#endif

		SDL_QuitSubSystem(initFlags);

		SDL_Quit();

		return 0;
	}

	void SDLApplication::RegisterWindow(SDLWindow *window)
	{

#ifdef IPHONE
		SDL_iPhoneSetAnimationCallback(window->sdlWindow, 1, UpdateFrame, NULL);
#endif
	}

	void SDLApplication::SetFrameRate(double frameRate)
	{

		if (frameRate > 0)
		{

			// Millisecond pacing cannot represent >1000 FPS accurately.
			if (frameRate > 1000.0)
				frameRate = 1000.0;
			framePeriod = 1000.0 / frameRate;
		}
		else
		{

			framePeriod = 1000.0;
		}

		nextFrac = 0.0;
		s_busyWaitOnly = (framePeriod <= 2.0);
	}

	bool SDLApplication::Update()
	{

		SDL_Event event;
		event.type = -1;

#if (!defined(IPHONE) && !defined(EMSCRIPTEN))

		if (active && !firstTime && WaitEvent(&event))
		{

			HandleEvent(&event);
			event.type = -1;
			if (!active)
				return active;
		}

		firstTime = false;

#endif

		while (SDL_PollEvent(&event))
		{

			HandleEvent(&event);
			event.type = -1;
			if (!active)
				return active;
		}

		currentUpdate = SDL_GetTicks();

#if defined(IPHONE) || defined(EMSCRIPTEN)

		if (currentUpdate >= nextUpdate)
		{

			event.type = SDL_USEREVENT;
			HandleEvent(&event);
			event.type = -1;
		}

#else

		if (currentUpdate >= nextUpdate)
		{

			event.type = SDL_USEREVENT;
			HandleEvent(&event);
			event.type = -1;
		}

#endif

		return active;
	}

	void SDLApplication::UpdateFrame()
	{

#ifdef EMSCRIPTEN
		System::GCTryExitBlocking();
#endif

		currentApplication->Update();

#ifdef EMSCRIPTEN
		System::GCTryEnterBlocking();
#endif
	}

	void SDLApplication::UpdateFrame(void *)
	{

		UpdateFrame();
	}

	int SDLApplication::WaitEvent(SDL_Event *event)
	{

#if defined(HX_MACOS) || defined(ANDROID)

		for (;;)
		{

			Uint32 now = SDL_GetTicks();
			Sint32 remaining = (Sint32)(nextUpdate - now);

			if (remaining <= 0)
			{

				SDL_zero(*event);
				event->type = SDL_USEREVENT;
				return 1;
			}

			int waitMs = 1;

			if (!s_busyWaitOnly)
			{

				CalibrateSleepGuard();
				Uint32 guardMs = GetSleepGuardMs();
				if ((Uint32)remaining > guardMs + 1)
				{

					waitMs = (int)((Uint32)remaining - guardMs);
					if (waitMs > 8)
						waitMs = 8;
				}
			}

			Uint32 waitStart = SDL_GetTicks();
			System::GCEnterBlocking();
			int result = SDL_WaitEventTimeout(event, waitMs);
			System::GCExitBlocking();
			Uint32 waitElapsed = SDL_GetTicks() - waitStart;

			if (result == 1)
				return 1;
			if (result == -1)
				return 0;

			if (!s_busyWaitOnly)
				UpdateSleepGuard((Uint32)waitMs, waitElapsed);

			if (s_busyWaitOnly)
			{

				while ((Sint32)(nextUpdate - SDL_GetTicks()) > 0)
				{

					SDL_PumpEvents();

					switch (SDL_PeepEvents(event, 1, SDL_GETEVENT, SDL_FIRSTEVENT, SDL_LASTEVENT))
					{

					case -1:
						return 0;

					case 1:
						return 1;

					default:
						break;
					}
				}

				SDL_zero(*event);
				event->type = SDL_USEREVENT;
				return 1;
			}
		}

#else

		bool isBlocking = false;
		SDL_AtomicSet(&s_waitEventBlocking, 0);

		for (;;)
		{

			SDL_PumpEvents();

			switch (SDL_PeepEvents(event, 1, SDL_GETEVENT, SDL_FIRSTEVENT, SDL_LASTEVENT))
			{

			case -1:

				if (isBlocking)
				{
					SDL_AtomicSet(&s_waitEventBlocking, 0);
					System::GCExitBlocking();
				}
				return 0;

			case 1:

				if (isBlocking)
				{
					SDL_AtomicSet(&s_waitEventBlocking, 0);
					System::GCExitBlocking();
				}
				return 1;

			default:

				if (!isBlocking)
				{
					System::GCEnterBlocking();
					SDL_AtomicSet(&s_waitEventBlocking, 1);
				}
				isBlocking = true;

				Uint32 now = SDL_GetTicks();
				Sint32 remaining = (Sint32)(nextUpdate - now);

				if (remaining <= 0)
				{

					SDL_zero(*event);
					event->type = SDL_USEREVENT;

					if (isBlocking)
					{
						SDL_AtomicSet(&s_waitEventBlocking, 0);
						System::GCExitBlocking();
					}
					return 1;
				}

				if (!s_busyWaitOnly)
				{

					CalibrateSleepGuard();

					Uint32 guardMs = GetSleepGuardMs();
					if ((Uint32)remaining > guardMs + 1)
					{

						Uint32 waitMs = (Uint32)remaining - guardMs;
						if (waitMs > 8)
							waitMs = 8;

						SDL_zero(*event);
						Uint32 waitStart = SDL_GetTicks();
						int waitResult = SDL_WaitEventTimeout(event, (int)waitMs);
						Uint32 waitElapsed = SDL_GetTicks() - waitStart;

						if (waitResult == 1)
						{

							if (isBlocking)
							{
								SDL_AtomicSet(&s_waitEventBlocking, 0);
								System::GCExitBlocking();
							}
							return 1;
						}
						else if (waitResult == -1)
						{

							if (isBlocking)
							{
								SDL_AtomicSet(&s_waitEventBlocking, 0);
								System::GCExitBlocking();
							}
							return 0;
						}

						UpdateSleepGuard(waitMs, waitElapsed);
						break;
					}
				}

				// Busy-wait the final remainder for tighter frame pacing.
				for (;;)
				{

					SDL_PumpEvents();

					switch (SDL_PeepEvents(event, 1, SDL_GETEVENT, SDL_FIRSTEVENT, SDL_LASTEVENT))
					{

					case -1:

						if (isBlocking)
						{
							SDL_AtomicSet(&s_waitEventBlocking, 0);
							System::GCExitBlocking();
						}
						return 0;

					case 1:

						if (isBlocking)
						{
							SDL_AtomicSet(&s_waitEventBlocking, 0);
							System::GCExitBlocking();
						}
						return 1;

					default:

						if ((Sint32)(nextUpdate - SDL_GetTicks()) <= 0)
						{

							SDL_zero(*event);
							event->type = SDL_USEREVENT;

							if (isBlocking)
							{
								SDL_AtomicSet(&s_waitEventBlocking, 0);
								System::GCExitBlocking();
							}
							return 1;
						}

						break;
					}
				}

				break;
			}
		}

#endif
	}

	Application *CreateApplication()
	{

		return new SDLApplication();
	}

}

#ifdef ANDROID
int SDL_main(int argc, char *argv[]) { return 0; }
#endif
