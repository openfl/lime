#include "SDLApplication.h"
#include "SDLGamepad.h"
#include "SDLJoystick.h"
#include <algorithm>
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

	static SDL_AtomicInt s_waitEventBlocking;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
	static SDL_AtomicInt s_nativeModalLoopDepth;
	static SDL_AtomicInt s_inModalEventWatch;
#endif

	static int GetEventTimestamp(SDL_Event *event)
	{
		return (int)SDL_NS_TO_MS(event->common.timestamp);
	}

	SDLApplication::SDLApplication()
	{

		allowBusyWait = true;
		busyWaitOnly = false;
		currentUpdate = 0.0;
		displayRefreshRate = 60.0;
		initFlags = SDL_INIT_VIDEO | SDL_INIT_GAMEPAD | SDL_INIT_JOYSTICK;
		firstTime = true;
#if defined(LIME_MOJOAL) || defined(LIME_OPENALSOFT)
		initFlags |= SDL_INIT_AUDIO;
#endif

		if (!SDL_Init(initFlags))
		{

			printf("Could not initialize SDL: %s.\n", SDL_GetError());
		}

		SDL_SetLogPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_WARN);

		currentApplication = this;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		modalWatchInstalled = false;
		mainThreadID = SDL_ThreadID();
		pendingResizeDispatchSkips = 0;
		pendingWatchRenderSkips = 0;
#endif

		framePeriod = 1000.0 / 60.0;
		lastUpdate = 0.0;
		lastSleepCalibration = 0;
		nextUpdate = 0.0;
		performanceFrequency = SDL_GetPerformanceFrequency();
		realVSyncActive = false;
		requestedBusyWaitMode = MAIN_LOOP_BUSY_WAIT_AUTO;
		requestedFrameRate = 60.0;
		requestedProfile = MAIN_LOOP_PROFILE_BALANCED;
		requestedTimePrecisionMode = MAIN_LOOP_TIME_PRECISION_AUTO;
		requestedUncapMode = MAIN_LOOP_UNCAP_OFF;
		requestedVSyncMode = MAIN_LOOP_VSYNC_OFF;
		schedulerUnthrottled = false;
		sleepGuardMs = 2.0;
		useDisplayDrivenFallback = false;
		useHighResolutionTimer = false;

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

		SDL_SetEventEnabled(SDL_EVENT_DROP_FILE, true);
		SDL_SetEventEnabled(SDL_EVENT_DROP_TEXT, true);
		SDL_SetEventEnabled(SDL_EVENT_DROP_BEGIN, true);
		SDL_SetEventEnabled(SDL_EVENT_DROP_COMPLETE, true);
		SDLJoystick::Init();
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		SDL_SetAtomicInt(&s_nativeModalLoopDepth, 0);
		SDL_SetAtomicInt(&s_inModalEventWatch, 0);
		SDL_SetAtomicInt(&s_waitEventBlocking, 0);
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

	void SDLApplication::AdvanceNextUpdate()
	{

		if (schedulerUnthrottled || framePeriod <= 0.0)
		{
			nextUpdate = currentUpdate;
			return;
		}

		nextUpdate += framePeriod;
		while (nextUpdate <= currentUpdate)
		{
			nextUpdate += framePeriod;
		}
	}

	void SDLApplication::ApplyMainLoopSettings()
	{

		double clampedFrameRate = requestedFrameRate;
		if (clampedFrameRate > 0.0 && clampedFrameRate > 10000.0)
			clampedFrameRate = 10000.0;

		displayRefreshRate = GetDisplayRefreshRate();
		if (displayRefreshRate <= 0.0)
			displayRefreshRate = 60.0;

		realVSyncActive = false;
		for (std::vector<SDLWindow*>::const_iterator iter = windows.begin (); iter != windows.end (); ++iter)
		{
			if (*iter && (*iter)->GetVSyncInterval () != 0)
			{
				realVSyncActive = true;
				break;
			}
		}

		useDisplayDrivenFallback = false;
		schedulerUnthrottled = false;

		bool hasExplicitFrameRate = (clampedFrameRate > 0.0);
		double effectiveFrameRate = hasExplicitFrameRate ? clampedFrameRate : 1.0;

		if (requestedUncapMode == MAIN_LOOP_UNCAP_SOFT || requestedUncapMode == MAIN_LOOP_UNCAP_HARD)
		{
			schedulerUnthrottled = true;
		}
		else if (realVSyncActive && hasExplicitFrameRate && clampedFrameRate >= displayRefreshRate)
		{
			schedulerUnthrottled = true;
		}
		else if (requestedVSyncMode == MAIN_LOOP_VSYNC_AUTO && !realVSyncActive && hasExplicitFrameRate && clampedFrameRate >= displayRefreshRate)
		{
			useDisplayDrivenFallback = true;
			effectiveFrameRate = displayRefreshRate;
		}

		framePeriod = 1000.0 / effectiveFrameRate;

		switch (requestedTimePrecisionMode)
		{
			case MAIN_LOOP_TIME_PRECISION_MILLISECOND:
				useHighResolutionTimer = false;
				break;

			case MAIN_LOOP_TIME_PRECISION_HIGH_RESOLUTION:
				useHighResolutionTimer = true;
				break;

			default:
				useHighResolutionTimer = (requestedProfile == MAIN_LOOP_PROFILE_PRECISION || requestedProfile == MAIN_LOOP_PROFILE_UNCAPPED ||
					requestedUncapMode != MAIN_LOOP_UNCAP_OFF || clampedFrameRate > 1000.0);
				break;
		}

		switch (requestedBusyWaitMode)
		{
			case MAIN_LOOP_BUSY_WAIT_OFF:
				allowBusyWait = false;
				break;

			case MAIN_LOOP_BUSY_WAIT_ON:
				allowBusyWait = true;
				break;

			default:
				allowBusyWait = (requestedProfile != MAIN_LOOP_PROFILE_LOW_ENERGY);
				break;
		}

		busyWaitOnly = allowBusyWait && (requestedUncapMode == MAIN_LOOP_UNCAP_HARD || (framePeriod > 0.0 && framePeriod <= 2.0));
		currentUpdate = GetCurrentTimeMs();
		nextUpdate = currentUpdate;
	}

	void SDLApplication::CalibrateSleepGuard(bool force)
	{

		Uint32 now = SDL_GetTicks();
		if (!force && lastSleepCalibration != 0 && (now - lastSleepCalibration) < 5000)
			return;

		Uint32 t0 = SDL_GetTicks();
		SDL_Delay(1);
		Uint32 t1 = SDL_GetTicks();

		Uint32 observed = t1 - t0;
		if (observed < 1)
			observed = 1;

		double observedD = (double)observed;

		if (lastSleepCalibration == 0 || force)
		{

			sleepGuardMs = observedD;
		}
		else
		{

			// bend in scheduler changes passively so pacing stays stable
			sleepGuardMs = (sleepGuardMs * 0.8) + (observedD * 0.2);
		}

		if (sleepGuardMs < 1.0)
			sleepGuardMs = 1.0;
		if (sleepGuardMs > 16.0)
			sleepGuardMs = 16.0;

		lastSleepCalibration = now;
	}

	Uint32 SDLApplication::GetSleepGuardMs() const
	{

		Uint32 guardMs = (Uint32)(sleepGuardMs + 0.5);
		if (guardMs < 1)
			guardMs = 1;
		return guardMs;
	}

	double SDLApplication::GetCurrentTimeMs() const
	{

		if (useHighResolutionTimer && performanceFrequency != 0)
		{
			return ((double)SDL_GetPerformanceCounter() * 1000.0) / (double)performanceFrequency;
		}

		return (double)SDL_GetTicks();
	}

	double SDLApplication::GetDisplayRefreshRate() const
	{

		for (std::vector<SDLWindow*>::const_iterator iter = windows.begin (); iter != windows.end (); ++iter)
		{
			if (*iter)
			{
				double refreshRate = (*iter)->GetRefreshRate ();
				if (refreshRate > 0.0)
					return refreshRate;
			}
		}

		return 60.0;
	}

	void SDLApplication::DispatchFrame(double now, bool renderFrame)
	{

		currentUpdate = now;
		applicationEvent.type = UPDATE;

		double delta = currentUpdate - lastUpdate;
		if (delta < 0.0)
			delta = 0.0;

		applicationEvent.deltaTime = (int)(delta + 0.5);
		lastUpdate = currentUpdate;

		AdvanceNextUpdate();

		ApplicationEvent::Dispatch(&applicationEvent);

		if (renderFrame)
		{
			RenderEvent::Dispatch(&renderEvent);
		}
	}

	bool SDLApplication::IsFrameDue(double now) const
	{

		if (schedulerUnthrottled)
			return true;

		return (now >= nextUpdate);
	}

	bool SDLApplication::IsSchedulerUnthrottled() const
	{

		return schedulerUnthrottled;
	}

	void SDLApplication::RefreshVSyncState()
	{

		ApplyMainLoopSettings();
	}

	void SDLApplication::UpdateSleepGuard(Uint32 requestedMs, Uint32 elapsedMs)
	{

		if (requestedMs == 0 || elapsedMs < requestedMs)
			return;

		double overshoot = (double)elapsedMs - (double)requestedMs;
		double targetGuard = overshoot + 1.0;

		if (targetGuard < 1.0)
			targetGuard = 1.0;
		if (targetGuard > 16.0)
			targetGuard = 16.0;

		sleepGuardMs = (sleepGuardMs * 0.9) + (targetGuard * 0.1);
	}

	SDLApplication::~SDLApplication()
	{
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		if (modalWatchInstalled && SDL_WasInit(0))
		{
			SDL_RemoveEventWatch(ModalEventWatch, this);
			modalWatchInstalled = false;
		}
#endif
	}

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
	void SDLApplication::EnterNativeModalLoop()
	{

		SDL_AddAtomicInt(&s_nativeModalLoopDepth, 1);
	}

	void SDLApplication::ExitNativeModalLoop()
	{

		int previousDepth = SDL_AddAtomicInt(&s_nativeModalLoopDepth, -1);
		if (previousDepth <= 1)
		{
			SDL_SetAtomicInt(&s_nativeModalLoopDepth, 0);
		}
	}

	bool SDLApplication::ModalEventWatch(void *userdata, SDL_Event *event)
	{

		if (!event || event->type < SDL_EVENT_WINDOW_FIRST || event->type > SDL_EVENT_WINDOW_LAST)
			return false;

		const SDL_EventType windowEvent = (SDL_EventType)event->type;
		if (windowEvent != SDL_EVENT_WINDOW_EXPOSED && windowEvent != SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED && windowEvent != SDL_EVENT_WINDOW_RESIZED && windowEvent != SDL_EVENT_WINDOW_MOVED)
			return false;

		SDLApplication *application = (SDLApplication *)userdata;
		if (!application || !application->active || inBackground)
			return false;
		if (SDL_GetAtomicInt(&s_waitEventBlocking) == 0 && SDL_GetAtomicInt(&s_nativeModalLoopDepth) == 0)
			return false;

		if (SDL_ThreadID() != application->mainThreadID)
			return false;

		// Prevent re-entry if rendering queues another window event.
		if (!SDL_CompareAndSwapAtomicInt(&s_inModalEventWatch, 0, 1))
			return false;

		application->PumpOneFrameFromWatch(event);
		SDL_SetAtomicInt(&s_inModalEventWatch, 0);
		return false;
	}

	void SDLApplication::PumpOneFrameFromWatch(SDL_Event *watchEvent)
	{

		if (!active || inBackground)
			return;

		bool isResizeEvent = false;
		bool isExposeEvent = false;
		if (watchEvent && watchEvent->type >= SDL_EVENT_WINDOW_FIRST && watchEvent->type <= SDL_EVENT_WINDOW_LAST)
		{
			isResizeEvent = (watchEvent->type == SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED || watchEvent->type == SDL_EVENT_WINDOW_RESIZED);
			isExposeEvent = (watchEvent->type == SDL_EVENT_WINDOW_EXPOSED);
		}

		double now = GetCurrentTimeMs();
		bool frameDue = IsFrameDue(now);
		bool isResizeOrExposeEvent = (isResizeEvent || isExposeEvent);
		if (!frameDue && !isResizeEvent)
			return;

		bool exitedBlocking = false;
		if (SDL_GetAtomicInt(&s_waitEventBlocking))
		{
			System::GCExitBlocking();
			SDL_SetAtomicInt(&s_waitEventBlocking, 0);
			exitedBlocking = true;
		}

		if (isResizeEvent)
		{
			ProcessWindowEvent(watchEvent);
			pendingResizeDispatchSkips++;
		}

		if (frameDue)
		{
			DispatchFrame(now);

			if (watchEvent && isResizeOrExposeEvent)
			{
				pendingWatchRenderSkips++;
			}
		}

		if (exitedBlocking)
		{
			System::GCEnterBlocking();
			SDL_SetAtomicInt(&s_waitEventBlocking, 1);
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

		case SDL_EVENT_USER:

			if (!inBackground)
			{

				DispatchFrame(GetCurrentTimeMs());
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

		case SDL_EVENT_DISPLAY_ORIENTATION:

			// this is the orientation of what is rendered, which
			// may not exactly match the orientation of the device,
			// if the app was locked to portrait or landscape.
			orientationEvent.type = DISPLAY_ORIENTATION_CHANGE;
			orientationEvent.orientation = event->display.data1;
			orientationEvent.display = event->display.displayID;
			OrientationEvent::Dispatch(&orientationEvent);
			break;

		case SDL_EVENT_DROP_FILE:
		case SDL_EVENT_DROP_TEXT:
		case SDL_EVENT_DROP_BEGIN:
		case SDL_EVENT_DROP_COMPLETE:

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

		case SDL_EVENT_JOYSTICK_BALL_MOTION:
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
				bool skipImmediateRender = false;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
				if (pendingWatchRenderSkips > 0)
				{
					pendingWatchRenderSkips--;
					skipImmediateRender = true;
				}

				if (SDL_GetAtomicInt(&s_waitEventBlocking))
				{
					PumpOneFrameFromWatch();
				}
				else
#endif
				{
					double now = GetCurrentTimeMs();
					bool frameDue = IsFrameDue(now);
					if (frameDue)
					{
						DispatchFrame(now, !skipImmediateRender);
					}
				}
			}

			break;

		case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
		case SDL_EVENT_WINDOW_RESIZED:
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
				if (SDL_GetAtomicInt(&s_waitEventBlocking))
				{
					PumpOneFrameFromWatch();
				}
				else
#endif
				{
					double now = GetCurrentTimeMs();
					bool frameDue = IsFrameDue(now);
					if (frameDue)
					{
						DispatchFrame(now, !skipImmediateRender);
					}
				}
			}

			break;
		}

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
		lastUpdate = GetCurrentTimeMs();
		nextUpdate = lastUpdate;
		firstTime = true;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		pendingResizeDispatchSkips = 0;
		pendingWatchRenderSkips = 0;
		SDL_SetAtomicInt(&s_nativeModalLoopDepth, 0);
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

			switch (event->type)
			{

			case SDL_EVENT_DROP_FILE:
				dropEvent.type = DROP_FILE;
				dropEvent.file = (vbyte *)event->drop.data;
				break;

			case SDL_EVENT_DROP_TEXT:
				dropEvent.type = DROP_TEXT;
				dropEvent.file = (vbyte *)event->drop.data;
				break;

			case SDL_EVENT_DROP_BEGIN:
				dropEvent.type = DROP_BEGIN;
				dropEvent.file = 0;
				break;

			case SDL_EVENT_DROP_COMPLETE:
				dropEvent.type = DROP_COMPLETE;
				dropEvent.file = 0;
				break;

			default:
				return;
			}

			DropEvent::Dispatch(&dropEvent);
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
				gamepadEvent.timestamp = GetEventTimestamp(event);

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
				gamepadEvent.timestamp = GetEventTimestamp(event);

				GamepadEvent::Dispatch(&gamepadEvent);
				break;

			case SDL_EVENT_GAMEPAD_BUTTON_UP:

				gamepadEvent.type = GAMEPAD_BUTTON_UP;
				gamepadEvent.button = event->gbutton.button;
				gamepadEvent.id = event->gbutton.which;
				gamepadEvent.timestamp = GetEventTimestamp(event);

				GamepadEvent::Dispatch(&gamepadEvent);
				break;

			case SDL_EVENT_GAMEPAD_ADDED:

				if (SDLGamepad::Connect(event->gdevice.which))
				{

					gamepadEvent.type = GAMEPAD_CONNECT;
					gamepadEvent.id = SDLGamepad::GetInstanceID(event->gdevice.which);
					gamepadEvent.timestamp = GetEventTimestamp(event);

					GamepadEvent::Dispatch(&gamepadEvent);
				}

				break;

			case SDL_EVENT_GAMEPAD_REMOVED:
			{

				gamepadEvent.type = GAMEPAD_DISCONNECT;
				gamepadEvent.id = event->gdevice.which;
				gamepadEvent.timestamp = GetEventTimestamp(event);

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

			keyEvent.keyCode = event->key.key;
			keyEvent.modifier = event->key.mod;
			keyEvent.timestamp = GetEventTimestamp(event);
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

				SDL_CaptureMouse(true);

				mouseEvent.type = MOUSE_DOWN;
				mouseEvent.button = event->button.button - 1;
				mouseEvent.x = event->button.x;
				mouseEvent.y = event->button.y;
				mouseEvent.clickCount = event->button.clicks;
				break;

			case SDL_EVENT_MOUSE_BUTTON_UP:

				SDL_CaptureMouse(false);

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

			const char *text = "";

			switch (event->type)
			{

			case SDL_EVENT_TEXT_INPUT:

				textEvent.type = TEXT_INPUT;
				textEvent.windowID = event->text.windowID;
				text = event->text.text ? event->text.text : "";
				break;

			case SDL_EVENT_TEXT_EDITING:

				textEvent.type = TEXT_EDIT;
				textEvent.start = event->edit.start;
				textEvent.length = event->edit.length;
				textEvent.windowID = event->edit.windowID;
				text = event->edit.text ? event->edit.text : "";
				break;

			default:
				return;
			}

			if (textEvent.text)
			{

				free(textEvent.text);
			}

			textEvent.text = (vbyte *)malloc(strlen(text) + 1);
			strcpy((char *)textEvent.text, text);

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
			touchEvent.id = event->tfinger.fingerID;
			touchEvent.dx = event->tfinger.dx;
			touchEvent.dy = event->tfinger.dy;
			touchEvent.pressure = event->tfinger.pressure;
			touchEvent.device = event->tfinger.touchID;

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
				windowEvent.type = WINDOW_SHOW;
				break;
			case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
				windowEvent.type = WINDOW_CLOSE;
				break;
			case SDL_EVENT_WINDOW_HIDDEN:
				windowEvent.type = WINDOW_HIDE;
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
			{
				SDL_Window* sdlWindow = SDL_GetWindowFromID (event->window.windowID);
				if (sdlWindow && SDL_GetWindowSize (sdlWindow, &windowEvent.width, &windowEvent.height)) {

					windowEvent.type = WINDOW_RESIZE;

				} else {

					windowEvent.type = WINDOW_RESIZE;
					windowEvent.width = event->window.data1;
					windowEvent.height = event->window.data2;

				}
				break;
			}

			case SDL_EVENT_WINDOW_RESIZED:

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
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		if (modalWatchInstalled)
		{
			SDL_RemoveEventWatch(ModalEventWatch, this);
			modalWatchInstalled = false;
		}
		SDL_SetAtomicInt(&s_nativeModalLoopDepth, 0);
#endif

		SDL_QuitSubSystem(initFlags);

		SDL_Quit();

		return 0;
	}

	void SDLApplication::RegisterWindow(SDLWindow *window)
	{

		if (window && std::find (windows.begin (), windows.end (), window) == windows.end ())
		{
			windows.push_back (window);
			window->SetVSyncMode (requestedVSyncMode);
			RefreshVSyncState ();
		}

#ifdef IPHONE
		SDL_iPhoneSetAnimationCallback(window->sdlWindow, 1, UpdateFrame, NULL);
#endif
	}

	void SDLApplication::UnregisterWindow(SDLWindow *window)
	{

		windows.erase (std::remove (windows.begin (), windows.end (), window), windows.end ());
		RefreshVSyncState ();
	}

	void SDLApplication::SetMainLoop(int profile, double frameRate, int timePrecision, int busyWait, int uncapMode)
	{

		requestedProfile = profile;
		requestedFrameRate = frameRate;
		requestedTimePrecisionMode = timePrecision;
		requestedBusyWaitMode = busyWait;
		requestedUncapMode = uncapMode;
		ApplyMainLoopSettings();
	}

	void SDLApplication::SetFrameRate(double frameRate)
	{

		requestedFrameRate = frameRate;
		ApplyMainLoopSettings();
	}

	void SDLApplication::SetVSyncMode(int vsyncMode)
	{

		requestedVSyncMode = vsyncMode;

		for (std::vector<SDLWindow*>::iterator iter = windows.begin (); iter != windows.end (); ++iter)
		{
			if (*iter)
			{
				(*iter)->SetVSyncMode (requestedVSyncMode);
			}
		}

		RefreshVSyncState();
	}

	bool SDLApplication::Update()
	{

		SDL_Event event;
		event.type = -1;

#if (!defined(IPHONE) && !defined(EMSCRIPTEN))

		if (active && !firstTime && requestedUncapMode != MAIN_LOOP_UNCAP_HARD && WaitEvent(&event))
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

		currentUpdate = GetCurrentTimeMs();

#if defined(IPHONE) || defined(EMSCRIPTEN)

		if (IsFrameDue(currentUpdate))
		{

			event.type = SDL_EVENT_USER;
			HandleEvent(&event);
			event.type = -1;
		}

#else

		if (IsFrameDue(currentUpdate))
		{

			event.type = SDL_EVENT_USER;
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

			double now = GetCurrentTimeMs();
			double remaining = nextUpdate - now;

			if (schedulerUnthrottled || remaining <= 0.0)
			{

				SDL_zero(*event);
				event->type = SDL_EVENT_USER;
				return 1;
			}

			int waitMs = (int)(remaining + 0.999);
			if (waitMs < 1)
				waitMs = 1;

			if (!allowBusyWait)
			{
				if (waitMs > 16)
					waitMs = 16;
			}
			else if (!busyWaitOnly)
			{

				CalibrateSleepGuard();
				Uint32 guardMs = GetSleepGuardMs();
				if (remaining > (double)guardMs + 1.0)
				{

					waitMs = (int)(remaining - (double)guardMs);
					if (waitMs > 8)
						waitMs = 8;
				}
			}

			Uint32 waitStart = SDL_GetTicks();
			System::GCEnterBlocking();
			bool result = SDL_WaitEventTimeout(event, waitMs);
			System::GCExitBlocking();
			Uint32 waitElapsed = SDL_GetTicks() - waitStart;

			if (result)
				return 1;

			if (allowBusyWait && !busyWaitOnly)
				UpdateSleepGuard((Uint32)waitMs, waitElapsed);

			if (allowBusyWait && busyWaitOnly)
			{

				while ((nextUpdate - GetCurrentTimeMs()) > 0.0)
				{

					SDL_PumpEvents();

					switch (SDL_PeepEvents(event, 1, SDL_GETEVENT, SDL_EVENT_FIRST, SDL_EVENT_LAST))
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
				event->type = SDL_EVENT_USER;
				return 1;
			}
		}

#else

		bool isBlocking = false;
		SDL_SetAtomicInt(&s_waitEventBlocking, 0);

		for (;;)
		{

			SDL_PumpEvents();

			switch (SDL_PeepEvents(event, 1, SDL_GETEVENT, SDL_EVENT_FIRST, SDL_EVENT_LAST))
			{

			case -1:

				if (isBlocking)
				{
					SDL_SetAtomicInt(&s_waitEventBlocking, 0);
					System::GCExitBlocking();
				}
				return 0;

			case 1:

				if (isBlocking)
				{
					SDL_SetAtomicInt(&s_waitEventBlocking, 0);
					System::GCExitBlocking();
				}
				return 1;

			default:

				if (!isBlocking)
				{
					System::GCEnterBlocking();
					SDL_SetAtomicInt(&s_waitEventBlocking, 1);
				}
				isBlocking = true;

				double now = GetCurrentTimeMs();
				double remaining = nextUpdate - now;

				if (schedulerUnthrottled || remaining <= 0.0)
				{

					SDL_zero(*event);
					event->type = SDL_EVENT_USER;

					if (isBlocking)
					{
						SDL_SetAtomicInt(&s_waitEventBlocking, 0);
						System::GCExitBlocking();
					}
					return 1;
				}

				if (!allowBusyWait)
				{
					int waitMs = (int)(remaining + 0.999);
					if (waitMs < 1)
						waitMs = 1;
					if (waitMs > 16)
						waitMs = 16;

					SDL_zero(*event);
					Uint32 waitStart = SDL_GetTicks();
					bool waitResult = SDL_WaitEventTimeout(event, waitMs);
					Uint32 waitElapsed = SDL_GetTicks() - waitStart;

					if (waitResult)
					{

						if (isBlocking)
						{
							SDL_SetAtomicInt(&s_waitEventBlocking, 0);
							System::GCExitBlocking();
						}
						return 1;
					}

					UpdateSleepGuard((Uint32)waitMs, waitElapsed);
					break;
				}

				if (!busyWaitOnly)
				{

					CalibrateSleepGuard();

					Uint32 guardMs = GetSleepGuardMs();
					if (remaining > (double)guardMs + 1.0)
					{

						Uint32 waitMs = (Uint32)(remaining - (double)guardMs);
						if (waitMs > 8)
							waitMs = 8;

						SDL_zero(*event);
						Uint32 waitStart = SDL_GetTicks();
						bool waitResult = SDL_WaitEventTimeout(event, (int)waitMs);
						Uint32 waitElapsed = SDL_GetTicks() - waitStart;

						if (waitResult)
						{

							if (isBlocking)
							{
								SDL_SetAtomicInt(&s_waitEventBlocking, 0);
								System::GCExitBlocking();
							}
							return 1;
						}

						UpdateSleepGuard(waitMs, waitElapsed);
						break;
					}
				}

				// Busy-wait the final remainder for tighter frame pacing.
				for (;;)
				{

					SDL_PumpEvents();

					switch (SDL_PeepEvents(event, 1, SDL_GETEVENT, SDL_EVENT_FIRST, SDL_EVENT_LAST))
					{

					case -1:

						if (isBlocking)
						{
							SDL_SetAtomicInt(&s_waitEventBlocking, 0);
							System::GCExitBlocking();
						}
						return 0;

					case 1:

						if (isBlocking)
						{
							SDL_SetAtomicInt(&s_waitEventBlocking, 0);
							System::GCExitBlocking();
						}
						return 1;

					default:

						if ((nextUpdate - GetCurrentTimeMs()) <= 0.0)
						{

							SDL_zero(*event);
							event->type = SDL_EVENT_USER;

							if (isBlocking)
							{
								SDL_SetAtomicInt(&s_waitEventBlocking, 0);
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
