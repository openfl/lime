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

	SDLApplication::SDLApplication()
	{

		Uint32 initFlags = SDL_INIT_VIDEO | SDL_INIT_GAMEPAD | SDL_INIT_TIMER | SDL_INIT_JOYSTICK;
#if defined(LIME_MOJOAL) || defined(LIME_OPENALSOFT)
		initFlags |= SDL_INIT_AUDIO;
#endif

		if (SDL_Init(initFlags) != 0)
		{

			printf("Could not initialize SDL: %s.\n", SDL_GetError());
		}

		SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_WARN);

		currentApplication = this;

		framePeriod = 1000.0 / 60.0;

#ifdef EMSCRIPTEN
		emscripten_cancel_main_loop();
		emscripten_set_main_loop(UpdateFrame, 0, 0);
		emscripten_set_main_loop_timing(EM_TIMING_RAF, 1);
#endif

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
		RenderEvent renderEvent;
		SensorEvent sensorEvent;
		TextEvent textEvent;
		TouchEvent touchEvent;
		WindowEvent windowEvent;

		SDL_SetEventEnabled(SDL_EVENT_DROP_FILE, SDL_TRUE);
		SDLJoystick::Init();

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
	}

	int SDLApplication::Exec()
	{

		Init();

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

		case SDL_EVENT_USER:

			if (!inBackground)
			{

				currentUpdate = SDL_GetTicks();
				applicationEvent.type = UPDATE;
				applicationEvent.deltaTime = currentUpdate - lastUpdate;
				lastUpdate = currentUpdate;

				nextUpdate += framePeriod;

				while (nextUpdate <= currentUpdate)
				{

					nextUpdate += framePeriod;
				}

				ApplicationEvent::Dispatch(&applicationEvent);
				RenderEvent::Dispatch(&renderEvent);
			}

			break;

		case SDL_EVENT_WILL_ENTER_BACKGROUND:

			inBackground = true;

			windowEvent.type = WINDOW_DEACTIVATE;
			WindowEvent::Dispatch(&windowEvent);
			break;

		case SDL_EVENT_WILL_ENTER_FOREGROUND:

			break;

		case SDL_EVENT_DID_ENTER_FOREGROUND:

			windowEvent.type = WINDOW_ACTIVATE;
			WindowEvent::Dispatch(&windowEvent);

			inBackground = false;
			break;

		case SDL_EVENT_CLIPBOARD_UPDATE:

			ProcessClipboardEvent(event);
			break;

		case SDL_EVENT_GAMEPAD_AXIS_MOTION:
		case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
		case SDL_EVENT_GAMEPAD_BUTTON_UP:
		case SDL_EVENT_GAMEPAD_ADDED:
		case SDL_EVENT_GAMEPAD_REMOVED:

			ProcessGamepadEvent(event);
			break;

		case SDL_EVENT_DROP_FILE:

			ProcessDropEvent(event);
			break;

		case SDL_EVENT_FINGER_MOTION:
		case SDL_EVENT_FINGER_DOWN:
		case SDL_EVENT_FINGER_UP:

			ProcessTouchEvent(event);
			break;

		case SDL_EVENT_JOYSTICK_AXIS_MOTION:

			if (SDLJoystick::IsAccelerometer(event->jaxis.which))
			{

				ProcessSensorEvent(event);
			}
			else
			{

				ProcessJoystickEvent(event);
			}

			break;

		case SDL_EVENT_JOYSTICK_BUTTON_DOWN:
		case SDL_EVENT_JOYSTICK_BUTTON_UP:
		case SDL_EVENT_JOYSTICK_HAT_MOTION:
		case SDL_EVENT_JOYSTICK_ADDED:
		case SDL_EVENT_JOYSTICK_REMOVED:

			ProcessJoystickEvent(event);
			break;

		case SDL_EVENT_KEY_DOWN:
		case SDL_EVENT_KEY_UP:

			ProcessKeyEvent(event);
			break;

		case SDL_EVENT_MOUSE_MOTION:
		case SDL_EVENT_MOUSE_BUTTON_DOWN:
		case SDL_EVENT_MOUSE_BUTTON_UP:
		case SDL_EVENT_MOUSE_WHEEL:

			ProcessMouseEvent(event);
			break;

#ifndef EMSCRIPTEN
		case SDL_EVENT_RENDER_DEVICE_RESET:

			renderEvent.type = RENDER_CONTEXT_LOST;
			RenderEvent::Dispatch(&renderEvent);

			renderEvent.type = RENDER_CONTEXT_RESTORED;
			RenderEvent::Dispatch(&renderEvent);

			renderEvent.type = RENDER;
			break;
#endif

		case SDL_EVENT_TEXT_INPUT:
		case SDL_EVENT_TEXT_EDITING:

			ProcessTextEvent(event);
			break;

		case SDL_EVENT_WINDOW_MOUSE_ENTER:
		case SDL_EVENT_WINDOW_MOUSE_LEAVE:
		case SDL_EVENT_WINDOW_SHOWN:
		case SDL_EVENT_WINDOW_HIDDEN:
		case SDL_EVENT_WINDOW_FOCUS_GAINED:
		case SDL_EVENT_WINDOW_FOCUS_LOST:
		case SDL_EVENT_WINDOW_MAXIMIZED:
		case SDL_EVENT_WINDOW_MINIMIZED:
		case SDL_EVENT_WINDOW_MOVED:
		case SDL_EVENT_WINDOW_RESTORED:

			ProcessWindowEvent(event);
			break;

		case SDL_EVENT_WINDOW_EXPOSED:

			ProcessWindowEvent(event);

			if (!inBackground)
			{

				RenderEvent::Dispatch(&renderEvent);
			}

			break;

		case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:

			ProcessWindowEvent(event);

			if (!inBackground)
			{

				RenderEvent::Dispatch(&renderEvent);
			}

			break;

		case SDL_EVENT_WINDOW_CLOSE_REQUESTED:

			ProcessWindowEvent(event);

			// Avoid handling SDL_EVENT_QUIT if in response to window.close
			SDL_Event event;

			if (SDL_PollEvent(&event))
			{

				if (event.type != SDL_EVENT_QUIT)
				{

					HandleEvent(&event);
				}
			}
			break;

		case SDL_EVENT_QUIT:

			active = false;
			break;
		}
	}

	void SDLApplication::Init()
	{

		active = true;
		lastUpdate = SDL_GetTicks();
		nextUpdate = lastUpdate;
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

			case SDL_EVENT_GAMEPAD_AXIS_MOTION:

				if (gamepadsAxisMap[event->gaxis.which].empty())
				{

					gamepadsAxisMap[event->gaxis.which][event->gaxis.axis] = event->gaxis.value;
				}
				else if (gamepadsAxisMap[event->gaxis.which][event->gaxis.axis] == event->gaxis.value)
				{

					break;
				}

				gamepadEvent.type = GAMEPAD_AXIS_MOVE;
				gamepadEvent.axis = event->gaxis.axis;
				gamepadEvent.id = event->gaxis.which;

				if (event->gaxis.value > -analogAxisDeadZone && event->gaxis.value < analogAxisDeadZone)
				{

					if (gamepadsAxisMap[event->gaxis.which][event->gaxis.axis] != 0)
					{

						gamepadsAxisMap[event->gaxis.which][event->gaxis.axis] = 0;
						gamepadEvent.axisValue = 0;
						GamepadEvent::Dispatch(&gamepadEvent);
					}

					break;
				}

				gamepadsAxisMap[event->gaxis.which][event->gaxis.axis] = event->gaxis.value;
				gamepadEvent.axisValue = event->gaxis.value / (event->gaxis.value > 0 ? 32767.0 : 32768.0);

				GamepadEvent::Dispatch(&gamepadEvent);
				break;

			case SDL_EVENT_GAMEPAD_BUTTON_DOWN:

				gamepadEvent.type = GAMEPAD_BUTTON_DOWN;
				gamepadEvent.button = event->gbutton.button;
				gamepadEvent.id = event->gbutton.which;

				GamepadEvent::Dispatch(&gamepadEvent);
				break;

			case SDL_EVENT_GAMEPAD_BUTTON_UP:

				gamepadEvent.type = GAMEPAD_BUTTON_UP;
				gamepadEvent.button = event->gbutton.button;
				gamepadEvent.id = event->gbutton.which;

				GamepadEvent::Dispatch(&gamepadEvent);
				break;

			case SDL_EVENT_GAMEPAD_ADDED:

				if (SDLGamepad::Connect(event->gdevice.which))
				{

					gamepadEvent.type = GAMEPAD_CONNECT;
					gamepadEvent.id = SDLGamepad::GetInstanceID(event->gdevice.which);

					GamepadEvent::Dispatch(&gamepadEvent);
				}

				break;

			case SDL_EVENT_GAMEPAD_REMOVED:
			{

				gamepadEvent.type = GAMEPAD_DISCONNECT;
				gamepadEvent.id = event->gdevice.which;

				GamepadEvent::Dispatch(&gamepadEvent);
				SDLGamepad::Disconnect(event->gdevice.which);
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

			case SDL_EVENT_JOYSTICK_AXIS_MOTION:

				if (!SDLJoystick::IsAccelerometer(event->jaxis.which))
				{

					joystickEvent.type = JOYSTICK_AXIS_MOVE;
					joystickEvent.index = event->jaxis.axis;
					joystickEvent.x = event->jaxis.value / (event->jaxis.value > 0 ? 32767.0 : 32768.0);
					joystickEvent.id = event->jaxis.which;

					JoystickEvent::Dispatch(&joystickEvent);
				}
				break;

			case SDL_EVENT_JOYSTICK_BUTTON_DOWN:

				if (!SDLJoystick::IsAccelerometer(event->jbutton.which))
				{

					joystickEvent.type = JOYSTICK_BUTTON_DOWN;
					joystickEvent.index = event->jbutton.button;
					joystickEvent.id = event->jbutton.which;

					JoystickEvent::Dispatch(&joystickEvent);
				}
				break;

			case SDL_EVENT_JOYSTICK_BUTTON_UP:

				if (!SDLJoystick::IsAccelerometer(event->jbutton.which))
				{

					joystickEvent.type = JOYSTICK_BUTTON_UP;
					joystickEvent.index = event->jbutton.button;
					joystickEvent.id = event->jbutton.which;

					JoystickEvent::Dispatch(&joystickEvent);
				}
				break;

			case SDL_EVENT_JOYSTICK_HAT_MOTION:

				if (!SDLJoystick::IsAccelerometer(event->jhat.which))
				{

					joystickEvent.type = JOYSTICK_HAT_MOVE;
					joystickEvent.index = event->jhat.hat;
					joystickEvent.eventValue = event->jhat.value;
					joystickEvent.id = event->jhat.which;

					JoystickEvent::Dispatch(&joystickEvent);
				}
				break;

			case SDL_EVENT_JOYSTICK_ADDED:

				if (SDLJoystick::Connect(event->jdevice.which))
				{

					joystickEvent.type = JOYSTICK_CONNECT;
					joystickEvent.id = SDLJoystick::GetInstanceID(event->jdevice.which);

					JoystickEvent::Dispatch(&joystickEvent);
				}
				break;

			case SDL_EVENT_JOYSTICK_REMOVED:

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

			case SDL_EVENT_KEY_DOWN:
				keyEvent.type = KEY_DOWN;
				break;
			case SDL_EVENT_KEY_UP:
				keyEvent.type = KEY_UP;
				break;
			}

			keyEvent.keyCode = event->key.keysym.sym;
			keyEvent.modifier = event->key.keysym.mod;
			keyEvent.windowID = event->key.windowID;

			if (keyEvent.type == KEY_DOWN)
			{

				if (keyEvent.keyCode == SDLK_CAPSLOCK)
					keyEvent.modifier |= SDL_KMOD_CAPS;
				if (keyEvent.keyCode == SDLK_LALT)
					keyEvent.modifier |= SDL_KMOD_LALT;
				if (keyEvent.keyCode == SDLK_LCTRL)
					keyEvent.modifier |= SDL_KMOD_LCTRL;
				if (keyEvent.keyCode == SDLK_LGUI)
					keyEvent.modifier |= SDL_KMOD_LGUI;
				if (keyEvent.keyCode == SDLK_LSHIFT)
					keyEvent.modifier |= SDL_KMOD_LSHIFT;
				if (keyEvent.keyCode == SDLK_MODE)
					keyEvent.modifier |= SDL_KMOD_MODE;
				if (keyEvent.keyCode == SDLK_NUMLOCKCLEAR)
					keyEvent.modifier |= SDL_KMOD_NUM;
				if (keyEvent.keyCode == SDLK_RALT)
					keyEvent.modifier |= SDL_KMOD_RALT;
				if (keyEvent.keyCode == SDLK_RCTRL)
					keyEvent.modifier |= SDL_KMOD_RCTRL;
				if (keyEvent.keyCode == SDLK_RGUI)
					keyEvent.modifier |= SDL_KMOD_RGUI;
				if (keyEvent.keyCode == SDLK_RSHIFT)
					keyEvent.modifier |= SDL_KMOD_RSHIFT;
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

			case SDL_EVENT_MOUSE_MOTION:

				mouseEvent.type = MOUSE_MOVE;
				mouseEvent.x = event->motion.x;
				mouseEvent.y = event->motion.y;
				mouseEvent.movementX = event->motion.xrel;
				mouseEvent.movementY = event->motion.yrel;
				break;

			case SDL_EVENT_MOUSE_BUTTON_DOWN:

				SDL_CaptureMouse(SDL_TRUE);

				mouseEvent.type = MOUSE_DOWN;
				mouseEvent.button = event->button.button - 1;
				mouseEvent.x = event->button.x;
				mouseEvent.y = event->button.y;
				mouseEvent.clickCount = event->button.clicks;
				break;

			case SDL_EVENT_MOUSE_BUTTON_UP:

				SDL_CaptureMouse(SDL_FALSE);

				mouseEvent.type = MOUSE_UP;
				mouseEvent.button = event->button.button - 1;
				mouseEvent.x = event->button.x;
				mouseEvent.y = event->button.y;
				mouseEvent.clickCount = event->button.clicks;
				break;

			case SDL_EVENT_MOUSE_WHEEL:

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

			case SDL_EVENT_TEXT_INPUT:

				textEvent.type = TEXT_INPUT;
				break;

			case SDL_EVENT_TEXT_EDITING:

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

			case SDL_EVENT_FINGER_MOTION:

				touchEvent.type = TOUCH_MOVE;
				break;

			case SDL_EVENT_FINGER_DOWN:

				touchEvent.type = TOUCH_START;
				break;

			case SDL_EVENT_FINGER_UP:

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

			switch (event->type)
			{

			case SDL_EVENT_WINDOW_SHOWN:
				windowEvent.type = WINDOW_ACTIVATE;
				break;
			case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
				windowEvent.type = WINDOW_CLOSE;
				break;
			case SDL_EVENT_WINDOW_HIDDEN:
				windowEvent.type = WINDOW_DEACTIVATE;
				break;
			case SDL_EVENT_WINDOW_MOUSE_ENTER:
				windowEvent.type = WINDOW_ENTER;
				break;
			case SDL_EVENT_WINDOW_FOCUS_GAINED:
				windowEvent.type = WINDOW_FOCUS_IN;
				break;
			case SDL_EVENT_WINDOW_FOCUS_LOST:
				windowEvent.type = WINDOW_FOCUS_OUT;
				break;
			case SDL_EVENT_WINDOW_MOUSE_LEAVE:
				windowEvent.type = WINDOW_LEAVE;
				break;
			case SDL_EVENT_WINDOW_MAXIMIZED:
				windowEvent.type = WINDOW_MAXIMIZE;
				break;
			case SDL_EVENT_WINDOW_MINIMIZED:
				windowEvent.type = WINDOW_MINIMIZE;
				break;
			case SDL_EVENT_WINDOW_EXPOSED:
				windowEvent.type = WINDOW_EXPOSE;
				break;

			case SDL_EVENT_WINDOW_MOVED:

				windowEvent.type = WINDOW_MOVE;
				windowEvent.x = event->window.data1;
				windowEvent.y = event->window.data2;
				break;

			case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:

				windowEvent.type = WINDOW_RESIZE;
				windowEvent.width = event->window.data1;
				windowEvent.height = event->window.data2;
				break;

			case SDL_EVENT_WINDOW_RESTORED:
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

			framePeriod = 1000.0 / frameRate;
		}
		else
		{

			framePeriod = 1000.0;
		}
	}

	static SDL_TimerID timerID = 0;
	bool timerActive = false;
	bool firstTime = true;

	Uint32 OnTimer(Uint32 interval, void *)
	{

		SDL_Event event;
		SDL_UserEvent userevent;
		userevent.type = SDL_EVENT_USER;
		userevent.code = 0;
		userevent.data1 = NULL;
		userevent.data2 = NULL;
		event.type = SDL_EVENT_USER;
		event.user = userevent;

		timerActive = false;
		timerID = 0;

		SDL_PushEvent(&event);

		return 0;
	}

	bool SDLApplication::Update()
	{

		SDL_Event event;
		event.type = -1;

#if (!defined(IPHONE) && !defined(EMSCRIPTEN))

		if (active && (firstTime || WaitEvent(&event)))
		{

			firstTime = false;

			HandleEvent(&event);
			event.type = -1;
			if (!active)
				return active;

#endif

			while (SDL_PollEvent(&event))
			{

				HandleEvent(&event);
				event.type = -1;
				if (!active)
					return active;
			}

			currentUpdate = SDL_GetTicks();

#if defined(IPHONE)

			if (currentUpdate >= nextUpdate)
			{

				event.type = SDL_EVENT_USER;
				HandleEvent(&event);
				event.type = -1;
			}

#elif defined(EMSCRIPTEN)

		event.type = SDL_EVENT_USER;
		HandleEvent(&event);
		event.type = -1;

#else

		if (currentUpdate >= nextUpdate)
		{

			if (timerActive)
				SDL_RemoveTimer(timerID);
			OnTimer(0, 0);
		}
		else if (!timerActive)
		{

			timerActive = true;
			timerID = SDL_AddTimer(nextUpdate - currentUpdate, OnTimer, 0);
		}
	}

#endif

			return active;
		}

		void SDLApplication::UpdateFrame()
		{

			currentApplication->Update();
		}

		void SDLApplication::UpdateFrame(void *)
		{

			UpdateFrame();
		}

		int SDLApplication::WaitEvent(SDL_Event * event)
		{

#if defined(HX_MACOS) || defined(ANDROID)

			System::GCEnterBlocking();
			int result = SDL_WaitEvent(event);
			System::GCExitBlocking();
			return result;

#else

		bool isBlocking = false;

		for (;;)
		{

			SDL_PumpEvents();

			switch (SDL_PeepEvents(event, 1, SDL_GETEVENT, SDL_EVENT_FIRST, SDL_EVENT_LAST))
			{

			case -1:

				if (isBlocking)
					System::GCExitBlocking();
				return 0;

			case 1:

				if (isBlocking)
					System::GCExitBlocking();
				return 1;

			default:

				if (!isBlocking)
					System::GCEnterBlocking();
				isBlocking = true;
				SDL_Delay(1);
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
	int SDL_main(int argc, char *argv[])
	{
		return 0;
	}
#endif
