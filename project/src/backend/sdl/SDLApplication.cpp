#include "SDLApplication.h"
#include "SDLGamepad.h"
#include "SDLJoystick.h"
#include "SDLMenu.h"
#include "SDLTrayIcon.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <net/LocalSocket.h>
#include <system/System.h>

#ifdef HX_MACOS
#include <CoreFoundation/CoreFoundation.h>
#endif

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#ifndef CREATE_WAITABLE_TIMER_HIGH_RESOLUTION
#define CREATE_WAITABLE_TIMER_HIGH_RESOLUTION 0x00000002
#endif

// Looked up at run time: MinGW's headers declare CreateWaitableTimerExW only
// when _WIN32_WINNT says Vista or later
typedef HANDLE (WINAPI *CreateWaitableTimerExWFunc) (LPSECURITY_ATTRIBUTES, LPCWSTR, DWORD, DWORD);

static HANDLE CreateHighResolutionTimer ()
{
	HMODULE kernel32 = GetModuleHandleW (L"kernel32.dll");
	if (!kernel32) return NULL;
	CreateWaitableTimerExWFunc create = (CreateWaitableTimerExWFunc)GetProcAddress (kernel32, "CreateWaitableTimerExW");
	if (!create) return NULL;
	return create (NULL, NULL, CREATE_WAITABLE_TIMER_HIGH_RESOLUTION, TIMER_ALL_ACCESS);
}
#elif !defined(HX_WINDOWS)
#include <time.h>
#endif

#ifdef EMSCRIPTEN
#include "emscripten.h"
#endif

#ifdef LIME_SDL_SOUND
#include "media/SDLSound.h"
#include "SDL_sound.h"
#endif

namespace lime
{

	AutoGCRoot *Application::callback = 0;
	SDLApplication *SDLApplication::currentApplication = 0;

	const int analogAxisDeadZone = 1000;
	std::map<int, std::map<int, int>> gamepadsAxisMap;
	bool inBackground = false;

	static SDL_atomic_t s_waitEventBlocking;

	// Swaps made by every window, counted on the main thread
	static unsigned int s_contextFlips = 0;

	// The swaps that were timed, and how long they took, in performance counter ticks
	static unsigned int s_timedSwaps = 0;
	static Uint64 s_swapTicks = 0;
	static Uint64 s_swapStart = 0;

	// Set by RequestFrame on any thread, and taken by the loop
	static SDL_atomic_t s_frameRequested;

	// The earliest time RequestTimer has asked to be woken at since timers last ran, on the
	// loop's clock, or below zero for none
	static SDL_SpinLock s_timedLock = 0;
	static double s_timedRequest = -1.0;
	static SDL_atomic_t s_timedChanged;

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
	// Signalled from another thread to end the loop's wait. It is kept for as long as the
	// process runs, as a thread may signal it while the application is being let go of.
	static HANDLE s_wakeEvent = NULL;
	// An event was pushed from another thread. SDL queues it once its watches have seen it.
	static SDL_atomic_t s_foreignPush;
#else
	// Pushed from another thread to end SDL's wait, one at a time
	static Uint32 s_wakeEventType = 0;
	static SDL_atomic_t s_wakeQueued;
#endif

	// Pushed from native-ipc's threads when local socket events wait, so a loop
	// waiting for events wakes and dispatches them.
	static Uint32 localSocketEventType = 0;

	static void WakeLocalSockets()
	{
		SDL_Event event;
		SDL_zero(event);
		event.type = localSocketEventType;
		SDL_PushEvent(&event);
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		// The loop's wait on Windows is its own, which SDL's queue doesn't end
		SDLApplication::Wake();
#endif
	}

	class ScopedModalGC {
		bool wasBlocking;
	public:
		ScopedModalGC():wasBlocking(SDL_AtomicGet(&s_waitEventBlocking) != 0) {
			if (wasBlocking) {
				System::GCExitBlocking();
				SDL_AtomicSet(&s_waitEventBlocking, 0);
			}
		}
		~ScopedModalGC() {
			if (wasBlocking) {
				System::GCEnterBlocking();
				SDL_AtomicSet(&s_waitEventBlocking, 1);
			}
		}
	};

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
	static SDL_atomic_t s_nativeModalLoopDepth;
	static SDL_atomic_t s_inModalEventWatch;

	// Restore native callback state even if a dispatched callback throws.
	class ScopedModalWatch {
		bool entered;
	public:
		ScopedModalWatch():entered(SDL_AtomicCAS(&s_inModalEventWatch, 0, 1) != 0) {}
		~ScopedModalWatch() { if (entered) SDL_AtomicSet(&s_inModalEventWatch, 0); }
		bool Entered() const { return entered; }
	};

	class ScopedModalCallbacks {
		ValuePointer* update;
		ValuePointer* render;
		ValuePointer* window;
	public:
		ScopedModalCallbacks(ValuePointer** callbacks):update(ApplicationEvent::callback),render(RenderEvent::callback),window(WindowEvent::callback)
		{
			ApplicationEvent::callback = callbacks[0];
			RenderEvent::callback = callbacks[1];
			WindowEvent::callback = callbacks[2];
		}
		~ScopedModalCallbacks()
		{
			ApplicationEvent::callback = update;
			RenderEvent::callback = render;
			WindowEvent::callback = window;
		}
	};
#endif

	// For native code that the system calls back while it waits for events, and
	// which needs an answer from Haxe before it returns
	void SDLApplication::CallFromEventPump(void (*callback)(void*), void* data)
	{
		ScopedModalGC gc;
		callback(data);
	}

	void AllowHighDPI()
	{

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		// Windows otherwise draws the application at 96 DPI and stretches it to
		// each display's scale. Window sizes stay in points, as on macOS, with
		// the drawable in pixels. Both are read as SDL starts.
		SDL_SetHint(SDL_HINT_WINDOWS_DPI_AWARENESS, "permonitorv2");
		SDL_SetHint(SDL_HINT_WINDOWS_DPI_SCALING, "1");
#endif
	}

	// Idle events leave this many milliseconds before a frame, and come this often to a listener
	// that has more to do
	static const double IDLE_MIN_REMAINING = 2.0;
	static const double IDLE_INTERVAL = 1.0;

	// The least time between two wakes for input, by profile, in milliseconds. Input that comes
	// sooner after the last waits out the rest, and is still handled before the next frame.
	static const double INPUT_INTERVAL_BALANCED = 2.0;
	static const double INPUT_INTERVAL_LOW_ENERGY = 8.0;

	// Frames that swapped and started under this part of a refresh after the one before, this
	// many times running, show that swaps don't wait for the display. A display that paces
	// frames can't bring them closer than a refresh for longer than its queue of frames is deep.
	static const double UNPACED_SWAP_INTERVAL = 0.85;
	static const int UNPACED_SWAP_COUNT = 5;

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
	// Why SleepUntilWork returned
	static const int SLEEP_TIME_UP = 0;
	static const int SLEEP_WOKEN = 1;
	static const int SLEEP_INPUT = 2;

	// The high-resolution timer ends a wait within about half a millisecond, so a loop that
	// busy-waits spins for the last one
	static const double SPIN_MARGIN = 1.0;

	// A wait on the timer is exact while it is shorter than a tick of Windows' default clock,
	// about 15.6 ms. A longer one can come back tens of milliseconds late: measured on Windows
	// Server 2022, at 5 frames a second and at 60, where two waits of 12 and 4 ms never ran
	// late and one of 16 did. So a profile that keeps its frames on time waits in steps no
	// longer than this, without pumping between them. The low energy profile, and any
	// application whose windows are all hidden, sleeps the whole wait in one.
	static const double WAIT_STEP = 12.0;
	static const double WAIT_STEP_PART = 0.75;

	// SDL reads game controllers and sensors as it pumps, and its own wait wakes to pump for
	// them: every millisecond while one is connected, every few seconds to find new ones
	static int DevicePollInterval()
	{
		int interval = 0;

		if (SDL_WasInit(SDL_INIT_JOYSTICK) && SDL_GetHintBoolean(SDL_HINT_AUTO_UPDATE_JOYSTICKS, SDL_TRUE))
			interval = (SDL_NumJoysticks() > 0) ? 1 : 3000;

		if (SDL_WasInit(SDL_INIT_SENSOR) && SDL_GetHintBoolean(SDL_HINT_AUTO_UPDATE_SENSORS, SDL_TRUE))
		{
			int sensors = (SDL_NumSensors() > 0) ? 1 : 3000;
			if (interval == 0 || sensors < interval)
				interval = sensors;
		}

		return interval;
	}
#endif

	static inline int QueuedEvents()
	{
		return SDL_PeepEvents(NULL, 0, SDL_PEEKEVENT, SDL_FIRSTEVENT, SDL_LASTEVENT);
	}

	// Whether an event is Wake's, which only ends the wait
	static inline bool IsWakeEvent(const SDL_Event &event)
	{
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		return false;
#else
		return s_wakeEventType != 0 && event.type == s_wakeEventType;
#endif
	}

	SDLApplication::SDLApplication()
	{

		active = false;
		activePeriod = 1000.0 / 60.0;
		allowBusyWait = true;
		busyWaitOnly = false;
		earliestUpdate = 0.0;
		frameDeltaTime = 0.0;
		frameForced = false;
		framePending = false;
		frameSlot = 0.0;
		idleArmed = false;
		idlePeriod = 0.0;
		inputHoldUntil = 0.0;
		inputInterval = INPUT_INTERVAL_BALANCED;
		mainLoopApplied = false;
		mainThreadID = SDL_ThreadID();
		requestedIdleFrameRate = 0.0;
		timedUpdate = -1.0;
		timersRanAt = 0.0;
		SDL_AtomicSet(&s_frameRequested, 0);
		SDL_AtomicSet(&s_timedChanged, 0);
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		// Windows 10 1803 and later; without it a wait ends on the system's timer tick, and the
		// remainder of a frame is spun as before
		frameTimer = CreateHighResolutionTimer ();
		if (!s_wakeEvent) s_wakeEvent = CreateEventW (NULL, FALSE, FALSE, NULL);
		SDL_AtomicSet(&s_foreignPush, 0);
#else
		SDL_AtomicSet(&s_wakeQueued, 0);
#endif
		swapPaced = false;
		swapFallback = false;
		shortSwaps = 0;
		lastSwapFrame = 0.0;
		currentUpdate = 0.0;
		deltaRemainder = 0.0;
		dispatchedFrames = 0;
		displayRefreshRate = 60.0;
		initFlags = SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER | SDL_INIT_TIMER | SDL_INIT_JOYSTICK;
		firstTime = true;
		mouseCaptureRequested = false;
#if defined(LIME_MOJOAL) || defined(LIME_OPENALSOFT)
		initFlags |= SDL_INIT_AUDIO;
#endif

		// Input methods show their own composition and candidate windows, which
		// Lime apps don't draw, and compositions longer than an SDL text event
		// holds arrive whole. Both are read as the video subsystem starts.
		SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");
		SDL_SetHint(SDL_HINT_IME_SUPPORT_EXTENDED_TEXT, "1");

		if (SDL_Init(initFlags) != 0)
		{

			printf("Could not initialize SDL: %s.\n", SDL_GetError());
		}

		// Lime's cancelable window-close callback owns last-window termination.
		SDL_SetHintWithPriority(SDL_HINT_QUIT_ON_LAST_WINDOW_CLOSE, "0", SDL_HINT_OVERRIDE);

#ifdef LIME_SDL_SOUND
		if (!Sound_Init ()) {

			printf ("Could not initialize SDL_sound: %s.\n", Sound_GetError ());

		}
#endif

		SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_WARN);

		if (localSocketEventType == 0)
		{
			localSocketEventType = SDL_RegisterEvents(1);

			// The first type registered is SDL_USEREVENT, which other code may push by name
			if (localSocketEventType == SDL_USEREVENT)
				localSocketEventType = SDL_RegisterEvents(1);

			if (localSocketEventType == (Uint32)-1)
				localSocketEventType = 0;
		}

#if !defined(HX_WINDOWS) || defined(HX_WINRT)
		if (s_wakeEventType == 0)
		{
			s_wakeEventType = SDL_RegisterEvents(1);

			if (s_wakeEventType == SDL_USEREVENT)
				s_wakeEventType = SDL_RegisterEvents(1);

			if (s_wakeEventType == (Uint32)-1)
				s_wakeEventType = 0;
		}
#endif

		if (localSocketEventType != 0)
			LocalSocket::SetWakeHandler(WakeLocalSockets);

		currentApplication = this;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		modalWatchInstalled = false;
		modalExceptionPending = false;
		modalFramePending = false;
		SDL_zero(modalFrameEvent);
		for (int i = 0; i < 4; ++i)
			modalCallbacks[i] = 0;
#endif

		framePeriod = 1000.0 / 60.0;
		idleEvents = false;
		lastUpdate = 0.0;
		lastSleepCalibration = 0;
		nextIdle = 0.0;
		nextUpdate = 0.0;
		performanceFrequency = SDL_GetPerformanceFrequency();
		clockStartCounter = SDL_GetPerformanceCounter();
#if SDL_VERSION_ATLEAST(2, 0, 18)
		clockStartTicks = SDL_GetTicks64();
#else
		clockStartTicks = 0;
#endif
		clockLastTicks = SDL_GetTicks();
		clockElapsedTicks = 0;
		realVSyncActive = false;
		requestedBackgroundFrameRate = 30.0;
		requestedBusyWaitMode = MAIN_LOOP_BUSY_WAIT_AUTO;
		windowsHidden = false;
		requestedFrameRate = 60.0;
		requestedProfile = MAIN_LOOP_PROFILE_BALANCED;
		requestedTimePrecisionMode = MAIN_LOOP_TIME_PRECISION_AUTO;
		requestedUncapMode = MAIN_LOOP_UNCAP_OFF;
		activeUncapMode = MAIN_LOOP_UNCAP_OFF;
		requestedVSyncMode = MAIN_LOOP_VSYNC_OFF;
		schedulerUnthrottled = false;
		sleepGuardMs = 2.0;
		swapPaced = false;
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

		SDL_EventState(SDL_DROPFILE, SDL_ENABLE);
		SDL_EventState(SDL_DROPTEXT, SDL_ENABLE);
		SDL_EventState(SDL_DROPBEGIN, SDL_ENABLE);
		SDL_EventState(SDL_DROPCOMPLETE, SDL_ENABLE);
		SDLJoystick::Init();
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		SDL_AtomicSet(&s_nativeModalLoopDepth, 0);
		SDL_AtomicSet(&s_inModalEventWatch, 0);
		SDL_AtomicSet(&s_waitEventBlocking, 0);
		SDL_AddEventWatch(ModalEventWatch, this);
		modalWatchInstalled = true;
#endif
		SDL_AddEventWatch(MinimizeOnFocusLossWatch, NULL);

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

		// A frame keeps the place it was due at, so frames that start a little late stay evenly
		// apart. One that starts a whole period late, or before it was due, starts the count
		// afresh: nothing is made up for, and the frame after it is a whole period away.
		double slot = nextUpdate;
		if (schedulerUnthrottled || framePeriod <= 0.0 || slot > currentUpdate || currentUpdate - slot >= framePeriod)
			slot = currentUpdate;

		frameSlot = slot;
		activePeriod = framePeriod;
		Reschedule();
	}

	void SDLApplication::Reschedule()
	{

		// The one place the next frame's time is worked out, from when the last one was due
		double period = (schedulerUnthrottled || activePeriod <= 0.0) ? 0.0 : activePeriod;
		earliestUpdate = frameSlot + period;

		// Rounding at a large clock value must not leave a timed deadline where the last one was
		if (period > 0.0 && earliestUpdate <= frameSlot)
			earliestUpdate = std::nextafter(frameSlot, (std::numeric_limits<double>::infinity)());

		nextUpdate = earliestUpdate;

		// While no frame is asked for, frames come at the idle rate where that is the slower
		if (idlePeriod > period && !framePending)
			nextUpdate = frameSlot + idlePeriod;
	}

	double SDLApplication::GetFrameDeltaTime()
	{

		return frameDeltaTime;
	}

	void SDLApplication::MakeFrameDue(double now)
	{

		frameSlot = now;
		earliestUpdate = now;
		nextUpdate = now;
	}

	void SDLApplication::TakeFrameRequest()
	{

		if (SDL_AtomicGet(&s_timedChanged) != 0)
		{
			SDL_AtomicSet(&s_timedChanged, 0);
			SDL_AtomicLock(&s_timedLock);
			timedUpdate = s_timedRequest;
			SDL_AtomicUnlock(&s_timedLock);
		}

		if (SDL_AtomicGet(&s_frameRequested) == 0)
			return;

		SDL_AtomicSet(&s_frameRequested, 0);

		// The frame comes as soon as the frame rate allows. Where frames already come at that
		// rate there is nothing to bring forward.
		if (!framePending)
		{
			framePending = true;
			if (nextUpdate > earliestUpdate)
				nextUpdate = earliestUpdate;
		}
	}

	void SDLApplication::RequestFrame()
	{

		// From any thread. The loop takes the request before it waits and before it decides
		// whether a frame is due, so only a loop that may be waiting needs waking.
		if (SDL_AtomicSet(&s_frameRequested, 1) == 0 && SDL_ThreadID() != mainThreadID)
			Wake();
	}

	void SDLApplication::RequestTimer(double milliseconds)
	{

		// Timers run from the application's updates. With an idle frame rate the next update
		// may be a long way off, so the loop is asked to run them at the time the next one is
		// due. The earliest time asked for is kept until they run, and they ask again then for
		// the one after.
		double time = GetCurrentTimeMs() + (milliseconds > 0.0 ? milliseconds : 0.0);
		bool sooner = false;

		SDL_AtomicLock(&s_timedLock);
		if (s_timedRequest < 0.0 || time < s_timedRequest)
		{
			s_timedRequest = time;
			sooner = true;
		}
		SDL_AtomicUnlock(&s_timedLock);

		if (sooner)
		{
			SDL_AtomicSet(&s_timedChanged, 1);
			if (SDL_ThreadID() != mainThreadID)
				Wake();
		}
	}

	void SDLApplication::Wake()
	{

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		if (s_wakeEvent)
			SetEvent(s_wakeEvent);
#else
		// SDL ends its wait for an event pushed from another thread. One is enough until the
		// loop has taken it.
		if (s_wakeEventType != 0 && SDL_AtomicCAS(&s_wakeQueued, 0, 1))
		{
			SDL_Event event;
			SDL_zero(event);
			event.type = s_wakeEventType;
			if (SDL_PushEvent(&event) <= 0)
				SDL_AtomicSet(&s_wakeQueued, 0);
		}
#endif
	}

	void SDLApplication::SetIdleFrameRate(double frameRate)
	{

		double rate = (frameRate > 0.0) ? frameRate : 0.0;
		if (rate == requestedIdleFrameRate)
			return;

		requestedIdleFrameRate = rate;
		idlePeriod = (rate > 0.0) ? 1000.0 / rate : 0.0;
		Reschedule();
	}

	void SDLApplication::ApplyMainLoopSettings()
	{

		bool wasUnthrottled = schedulerUnthrottled;
		bool wasSwapPaced = swapPaced;
		bool wasDisplayDriven = useDisplayDrivenFallback;
		bool wasBusyWaitOnly = busyWaitOnly;

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
		swapPaced = false;
		swapFallback = false;
		shortSwaps = 0;

		bool hasExplicitFrameRate = (clampedFrameRate > 0.0);
		double effectiveFrameRate = hasExplicitFrameRate ? clampedFrameRate : 1.0;

		// The uncapped profile uncaps the loop unless the options ask for more
		activeUncapMode = requestedUncapMode;
		if (activeUncapMode == MAIN_LOOP_UNCAP_OFF && requestedProfile == MAIN_LOOP_PROFILE_UNCAPPED)
			activeUncapMode = MAIN_LOOP_UNCAP_SOFT;

		if (activeUncapMode == MAIN_LOOP_UNCAP_SOFT || activeUncapMode == MAIN_LOOP_UNCAP_HARD)
		{
			schedulerUnthrottled = true;
		}
		else if (realVSyncActive && hasExplicitFrameRate && clampedFrameRate >= displayRefreshRate)
		{
			schedulerUnthrottled = true;
			swapPaced = true;
		}
		else if (requestedVSyncMode == MAIN_LOOP_VSYNC_AUTO && !realVSyncActive && hasExplicitFrameRate && clampedFrameRate >= displayRefreshRate)
		{
			useDisplayDrivenFallback = true;
			effectiveFrameRate = displayRefreshRate;
		}

		framePeriod = 1000.0 / effectiveFrameRate;

		// While every window is minimised or hidden, nothing shows the frames, so they are
		// timed at no more than the background frame rate, whatever the profile
		bool backgroundLimited = windowsHidden && requestedBackgroundFrameRate > 0.0;

		if (backgroundLimited)
		{
			double backgroundPeriod = 1000.0 / requestedBackgroundFrameRate;
			schedulerUnthrottled = false;
			swapPaced = false;
			useDisplayDrivenFallback = false;
			if (framePeriod < backgroundPeriod)
				framePeriod = backgroundPeriod;
		}

		switch (requestedTimePrecisionMode)
		{
			case MAIN_LOOP_TIME_PRECISION_MILLISECOND:
				useHighResolutionTimer = false;
				break;

			case MAIN_LOOP_TIME_PRECISION_HIGH_RESOLUTION:
				useHighResolutionTimer = true;
				break;

			default:
				// The performance counter in every profile. A clock in whole milliseconds reads up
				// to a millisecond behind, so a wait measured by it ends that late.
				useHighResolutionTimer = true;
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

		if (backgroundLimited)
			allowBusyWait = false;

		busyWaitOnly = allowBusyWait && (activeUncapMode == MAIN_LOOP_UNCAP_HARD || (framePeriod > 0.0 && framePeriod <= 2.0));

		switch (requestedProfile)
		{
			case MAIN_LOOP_PROFILE_PRECISION:
				inputInterval = 0.0;
				break;

			case MAIN_LOOP_PROFILE_LOW_ENERGY:
				inputInterval = INPUT_INTERVAL_LOW_ENERGY;
				break;

			default:
				inputInterval = INPUT_INTERVAL_BALANCED;
				break;
		}

		idlePeriod = (requestedIdleFrameRate > 0.0) ? 1000.0 / requestedIdleFrameRate : 0.0;
		activePeriod = framePeriod;

		bool samePacing = mainLoopApplied && wasUnthrottled == schedulerUnthrottled && wasSwapPaced == swapPaced &&
			wasDisplayDriven == useDisplayDrivenFallback && wasBusyWaitOnly == busyWaitOnly;
		mainLoopApplied = true;

		if (samePacing && !schedulerUnthrottled && framePeriod > 0.0)
		{
			// The next frame stays a period after the last one, by the new period, so setting
			// the frame rate often doesn't make a frame due each time
			Reschedule();
		}
		else
		{
			currentUpdate = GetCurrentTimeMs();
			MakeFrameDue(currentUpdate);
		}
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

	bool SDLApplication::CalibrateSleepGuardBefore(double remaining)
	{

		// The measurement sleeps for about the guard, so it waits for a wait
		// with time to spare, where it can't make the frame start late. The
		// caller reads the time left again when it returns true.
		Uint32 now = SDL_GetTicks();
		if (lastSleepCalibration != 0 && (now - lastSleepCalibration) < 5000)
			return false;

		if (remaining < (double)GetSleepGuardMs() * 2.0 + 2.0)
			return false;

		CalibrateSleepGuard();
		return true;
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

		if (performanceFrequency != 0)
		{
			// Both precision modes use the same epoch; only their resolution differs.
			double now = ((double)(SDL_GetPerformanceCounter() - clockStartCounter) * 1000.0) / (double)performanceFrequency;
			return useHighResolutionTimer ? now : std::floor(now);
		}

		// Extend legacy ticks without requiring a newer SDL minimum version.
#if SDL_VERSION_ATLEAST(2, 0, 18)
		return (double)(SDL_GetTicks64() - clockStartTicks);
#else
		Uint32 ticks = SDL_GetTicks();
		clockElapsedTicks += (Uint32)(ticks - clockLastTicks);
		clockLastTicks = ticks;
		return (double)clockElapsedTicks;
#endif
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

#if defined(IPHONE) || defined(EMSCRIPTEN)
		int top = 0;
		gc_set_top_of_stack(&top, false);
#endif

		currentUpdate = (std::max)(now, lastUpdate);
		applicationEvent.type = UPDATE;

		double delta = currentUpdate - lastUpdate;
		if (delta < 0.0)
			delta = 0.0;

		double elapsed = delta + deltaRemainder;
		double rounded = std::floor(elapsed + 0.5);
		if (rounded > (double)(std::numeric_limits<int>::max)())
		{
			rounded = (double)(std::numeric_limits<int>::max)();
			elapsed = rounded;
		}
		applicationEvent.deltaTime = (int)rounded;
		frameDeltaTime = delta;
		deltaRemainder = elapsed - rounded;
		lastUpdate = currentUpdate;
		dispatchedFrames++;

		// This frame is the one that was asked for. One asked for while it runs comes after it.
		framePending = false;
		frameForced = false;
		SDL_AtomicSet(&s_frameRequested, 0);

		// The update runs the timers, which ask again for the next one
		timersRanAt = currentUpdate;
		timedUpdate = -1.0;
		SDL_AtomicLock(&s_timedLock);
		s_timedRequest = -1.0;
		SDL_AtomicUnlock(&s_timedLock);

		AdvanceNextUpdate();

		ApplicationEvent::Dispatch(&applicationEvent);

		if (renderFrame)
		{
			unsigned int flips = s_contextFlips;
			unsigned int timedSwaps = s_timedSwaps;
			Uint64 swapTicks = s_swapTicks;
			double renderStart = GetCurrentTimeMs();
			RenderEvent::Dispatch(&renderEvent);

			if (swapPaced)
			{
				// How long the swaps took, apart from the drawing before them. Vulkan presents
				// outside ContextFlip, so its swaps aren't timed and the whole render stands for them.
				double swapMs = GetCurrentTimeMs() - renderStart;
				if (s_timedSwaps != timedSwaps && performanceFrequency != 0)
					swapMs = ((double)(s_swapTicks - swapTicks) * 1000.0) / (double)performanceFrequency;

				PaceFrameAfterRender(s_contextFlips != flips, swapMs);
			}
		}
	}

	void SDLApplication::NoteContextFlip()
	{

		s_contextFlips++;
	}

	// A swap with vsync waits for the display for most of a light frame, and the
	// collector needn't wait for it. The flag is the event wait's, so a callback
	// that arrives during the swap leaves the blocking section first.
	static int s_swapWasBlocking = 0;

	void SDLApplication::EnterSwapBlocking()
	{

		System::GCEnterBlocking();
		s_swapWasBlocking = SDL_AtomicSet(&s_waitEventBlocking, 1);
		s_swapStart = SDL_GetPerformanceCounter();
	}

	void SDLApplication::ExitSwapBlocking()
	{

		// Before leaving the blocking section, which waits for a collection under way
		s_swapTicks += SDL_GetPerformanceCounter() - s_swapStart;
		s_timedSwaps++;

		SDL_AtomicSet(&s_waitEventBlocking, s_swapWasBlocking);
		System::GCExitBlocking();
	}

	void SDLApplication::PaceFrameAfterRender(bool swapped, double swapMs)
	{

		double refreshPeriod = 1000.0 / displayRefreshRate;

		// The loop runs unthrottled while each swap waits for the display. A frame that
		// swaps nothing, as when an application skips drawing an unchanged scene, waits
		// for nothing, so until a frame swaps again, frames come once per refresh.
		if (!swapped)
		{
			schedulerUnthrottled = false;
			activePeriod = refreshPeriod;
			frameSlot = currentUpdate;
			Reschedule();
			return;
		}

		if (swapFallback)
		{
			// Frames are timed while the swaps don't wait. One that blocks for a good part of a
			// refresh shows the display pacing them again. The time is the swap's own: an
			// application that takes that long to draw would otherwise leave here every frame.
			if (swapMs >= refreshPeriod * 0.25)
			{
				swapFallback = false;
				shortSwaps = 0;
				lastSwapFrame = currentUpdate;
				schedulerUnthrottled = true;
				Reschedule();
			}

			return;
		}

		// A swap can return at once, as when a driver forces vsync off, in a remote session or
		// a virtual machine, which would leave update and render running back to back. Frames
		// that swapped coming under a refresh apart several times running show that.
		double interval = currentUpdate - lastSwapFrame;
		lastSwapFrame = currentUpdate;

		if (interval < refreshPeriod * UNPACED_SWAP_INTERVAL)
		{
			if (++shortSwaps >= UNPACED_SWAP_COUNT)
			{
				swapFallback = true;
				schedulerUnthrottled = false;
				activePeriod = framePeriod;
				frameSlot = currentUpdate;
				Reschedule();
				return;
			}
		}
		else
		{
			shortSwaps = 0;
		}

		if (!schedulerUnthrottled)
		{
			schedulerUnthrottled = true;
			Reschedule();
		}
	}

	bool SDLApplication::IsFrameDue(double now)
	{

		TakeFrameRequest();
		return (now >= nextUpdate);
	}

	bool SDLApplication::IsIdleDue(double now) const
	{

		return idleEvents && idleArmed && now >= nextIdle && nextUpdate - now >= IDLE_MIN_REMAINING;
	}

	void SDLApplication::DispatchIdle(double remaining)
	{

		ApplicationEvent idleEvent;
		idleEvent.type = IDLE;
		idleEvent.deltaTime = (int)remaining;
		ApplicationEvent::Dispatch(&idleEvent);

		// A listener with more to do, as a collector part way through a cycle, answers below zero
		// and is called again while there is time before the frame. The loop isn't woken for one
		// that is done.
		idleArmed = (idleEvent.deltaTime < 0);
		nextIdle = GetCurrentTimeMs() + IDLE_INTERVAL;
	}

	double SDLApplication::NextTimerTime() const
	{

		// Only with an idle frame rate. Without one, timers keep to the updates, as they always have.
		if (idlePeriod <= 0.0 || timedUpdate < 0.0)
			return -1.0;

		// No sooner after they last ran than a frame period, which is how often they run where
		// frames keep coming. A timer of no time at all would otherwise be all the loop did.
		double earliest = timersRanAt + (framePeriod > 1.0 ? framePeriod : 1.0);
		return (timedUpdate > earliest) ? timedUpdate : earliest;
	}

	bool SDLApplication::IsTimerDue(double now) const
	{

		double time = NextTimerTime();
		return time >= 0.0 && now >= time;
	}

	void SDLApplication::DispatchTimers()
	{

		timersRanAt = GetCurrentTimeMs();
		timedUpdate = -1.0;
		SDL_AtomicLock(&s_timedLock);
		s_timedRequest = -1.0;
		SDL_AtomicUnlock(&s_timedLock);

		// The timers that are due, with no update or render: what a timer changes is drawn by
		// the frame it asks for
		ApplicationEvent timerEvent;
		timerEvent.type = TIMER;
		timerEvent.deltaTime = 0;
		ApplicationEvent::Dispatch(&timerEvent);
	}

	bool SDLApplication::IsSchedulerUnthrottled() const
	{

		return schedulerUnthrottled;
	}

	void SDLApplication::RefreshVSyncState()
	{

		ApplyMainLoopSettings();
	}

	bool SDLApplication::SleepsOutTheRemainder() const
	{

		// The precision profile, or busy waiting asked for by name, keeps the spin
		return requestedProfile != MAIN_LOOP_PROFILE_PRECISION && requestedBusyWaitMode != MAIN_LOOP_BUSY_WAIT_ON;
	}

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
	int SDLApplication::SleepUntilWork(double ms, bool watchInput)
	{

		// The one wait of a turn on Windows: until the time is up, another thread wakes the
		// loop, or, when it is watched for, input waits in the message queue
		HANDLE handles[2];
		DWORD count = 0;
		DWORD wakeIndex = MAXIMUM_WAIT_OBJECTS;
		DWORD timeout = 0;
		bool timed = false;

		if (s_wakeEvent)
		{
			wakeIndex = count;
			handles[count++] = s_wakeEvent;
		}

		if (frameTimer)
		{
			// Relative, in 100 ns units
			LARGE_INTEGER due;
			due.QuadPart = -(LONGLONG)(ms * 10000.0);

			if (due.QuadPart >= 0)
				return SLEEP_TIME_UP;

			if (SetWaitableTimer((HANDLE)frameTimer, &due, 0, NULL, NULL, FALSE))
			{
				handles[count++] = (HANDLE)frameTimer;
				timeout = INFINITE;
				timed = true;
			}
		}

		if (!timed)
		{
			// Whole milliseconds, ending on the system's timer tick. The caller rounds up, or
			// makes up what is left.
			if (ms < 1.0)
				return SLEEP_TIME_UP;

			timeout = (DWORD)ms;
		}

		System::GCEnterBlocking();
		SDL_AtomicSet(&s_waitEventBlocking, 1);
		DWORD result = MsgWaitForMultipleObjectsEx(count, handles, timeout, watchInput ? QS_ALLINPUT : 0, watchInput ? MWMO_INPUTAVAILABLE : 0);
		SDL_AtomicSet(&s_waitEventBlocking, 0);
		System::GCExitBlocking();

		if (result == WAIT_OBJECT_0 + wakeIndex)
			return SLEEP_WOKEN;

		if (result == WAIT_OBJECT_0 + count)
			return SLEEP_INPUT;

		// With nothing to wait on, a loop that came straight back would spin
		if (result == WAIT_FAILED)
			SDL_Delay(1);

		return SLEEP_TIME_UP;
	}
#else
	void SDLApplication::SleepThroughInput(double ms)
	{

		if (ms <= 0.0)
			return;

		System::GCEnterBlocking();
		SDL_AtomicSet(&s_waitEventBlocking, 1);
#if defined(HX_WINDOWS)
		SDL_Delay((Uint32)(ms + 0.999));
#else
		struct timespec time;
		time.tv_sec = (time_t)(ms / 1000.0);
		time.tv_nsec = (long)((ms - (double)time.tv_sec * 1000.0) * 1000000.0);
		nanosleep(&time, NULL);
#endif
		SDL_AtomicSet(&s_waitEventBlocking, 0);
		System::GCExitBlocking();
	}
#endif

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
		if (frameTimer)
		{
			CloseHandle((HANDLE)frameTimer);
			frameTimer = NULL;
		}
		if (modalWatchInstalled && SDL_WasInit(0))
		{
			SDL_DelEventWatch(ModalEventWatch, this);
			modalWatchInstalled = false;
		}
		for (int i = 0; i < 4; ++i)
			delete modalCallbacks[i];
#endif
	}

	// SDL reads its minimize on focus loss hint when a window loses focus. Only the window that has
	// focus can lose it, so the hint follows each window's Window.minimizeOnFocusLoss as it gains focus.
	// A watch is called as SDL raises the event, before the window can lose focus again.
	int SDLApplication::MinimizeOnFocusLossWatch(void *userdata, SDL_Event *event)
	{

		if (event && event->type == SDL_WINDOWEVENT && event->window.event == SDL_WINDOWEVENT_FOCUS_GAINED)
		{
			SDL_Window *window = SDL_GetWindowFromID(event->window.windowID);
			if (window) SDL_SetHint(SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS, SDL_GetWindowData(window, "Lime.KeepOnFocusLoss") == NULL ? "auto" : "0");
		}

		return 0;

	}

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
	void SDLApplication::EnterNativeModalLoop()
	{

		SDL_AtomicAdd(&s_nativeModalLoopDepth, 1);
	}

	void SDLApplication::ExitNativeModalLoop()
	{

		int previousDepth = SDL_AtomicAdd(&s_nativeModalLoopDepth, -1);
		if (previousDepth <= 1)
		{
			SDL_AtomicSet(&s_nativeModalLoopDepth, 0);
		}
	}


	int SDLApplication::ModalEventWatch(void *userdata, SDL_Event *event)
	{

		SDLApplication *application = (SDLApplication *)userdata;
		if (!application || !event)
			return 0;

		if (SDL_ThreadID() != application->mainThreadID)
		{
			// SDL wakes only its own wait for an event pushed from another thread, and the
			// loop's wait is not SDL's. The event is queued once the watches return, so the
			// loop looks again if it gets there first.
			SDL_AtomicSet(&s_foreignPush, 1);
			Wake();
			return 0;
		}

		if (event->type != SDL_WINDOWEVENT)
			return 0;

		const Uint8 windowEvent = event->window.event;
		if (windowEvent != SDL_WINDOWEVENT_EXPOSED && windowEvent != SDL_WINDOWEVENT_SIZE_CHANGED && windowEvent != SDL_WINDOWEVENT_RESIZED && windowEvent != SDL_WINDOWEVENT_MOVED)
			return 0;
		if (!application->active || inBackground)
			return 0;
		if (SDL_AtomicGet(&s_waitEventBlocking) == 0 && SDL_AtomicGet(&s_nativeModalLoopDepth) == 0)
			return 0;

		if (application->modalExceptionPending || application->modalNativeException || !application->modalCallbacks[3])
			return 0;

		// A window event queued while a frame is drawn doesn't draw another
		if (SDL_AtomicGet(&s_inModalEventWatch) != 0)
			return 0;

		// SDL calls every watch with its event lock held, so a frame drawn here would make any
		// thread pushing an event wait for it, and anything the frame waits on that pushes one,
		// such as a local socket's thread it closes, would never finish. The frame is drawn once
		// SDL_PushEvent has returned, from the window's procedure. A resize is kept over other
		// events, as it draws even when no frame is due.
		bool pendingResize = application->modalFramePending && (application->modalFrameEvent.window.event == SDL_WINDOWEVENT_SIZE_CHANGED || application->modalFrameEvent.window.event == SDL_WINDOWEVENT_RESIZED);
		if (!pendingResize)
			application->modalFrameEvent = *event;
		application->modalFramePending = true;
		return 0;
	}

	void SDLApplication::RunPendingModalFrame()
	{

		SDLApplication *application = currentApplication;
		if (!application || !application->modalFramePending || SDL_ThreadID() != application->mainThreadID)
			return;

		SDL_Event event = application->modalFrameEvent;
		application->modalFramePending = false;

		// Otherwise the frame loop draws it, as it handles the window event
		if (!application->active || inBackground)
			return;
		if (SDL_AtomicGet(&s_waitEventBlocking) == 0 && SDL_AtomicGet(&s_nativeModalLoopDepth) == 0)
			return;
		if (application->modalExceptionPending || application->modalNativeException || !application->modalCallbacks[3])
			return;

		// Prevent re-entry if rendering sends the window another message.
		ScopedModalWatch watch;
		if (!watch.Entered())
			return;

		try
		{
			ScopedModalCallbacks callbacks(application->modalCallbacks);
			application->PumpOneFrameFromWatch(&event);
		}
		catch (...)
		{
			application->modalNativeException = std::current_exception();
		}
	}

	void SDLApplication::SetModalCallbacks(ValuePointer* update, ValuePointer* render, ValuePointer* window, ValuePointer* rethrow)
	{
		for (int i = 0; i < 4; ++i)
			delete modalCallbacks[i];
		modalCallbacks[0] = update;
		modalCallbacks[1] = render;
		modalCallbacks[2] = window;
		modalCallbacks[3] = rethrow;
	}

	void SDLApplication::DeferModalException()
	{
		modalExceptionPending = true;
	}

	void SDLApplication::CheckModalException(bool blocking)
	{
		if (!modalExceptionPending && !modalNativeException)
			return;
		if (blocking)
		{
			SDL_AtomicSet(&s_waitEventBlocking, 0);
			System::GCExitBlocking();
		}
		if (modalNativeException)
		{
			std::exception_ptr exception = modalNativeException;
			modalNativeException = std::exception_ptr();
			std::rethrow_exception(exception);
		}
		modalExceptionPending = false;
		modalCallbacks[3]->Call();
	}

	void SDLApplication::PumpOneFrameFromWatch(SDL_Event *watchEvent)
	{

		if (!active || inBackground)
			return;

		bool isResizeEvent = false;
		if (watchEvent && watchEvent->type == SDL_WINDOWEVENT)
		{
			isResizeEvent = (watchEvent->window.event == SDL_WINDOWEVENT_SIZE_CHANGED || watchEvent->window.event == SDL_WINDOWEVENT_RESIZED);
		}

		double now = GetCurrentTimeMs();
		bool frameDue = IsFrameDue(now);
		if (!frameDue && !isResizeEvent)
			return;

		ScopedModalGC gc;

		if (isResizeEvent)
		{
			ProcessWindowEvent(watchEvent);
		}

		// A new size is drawn at once, while Windows is still handling it: until a frame is drawn at that size the
		// window shows the last one stretched to it, so content laid out between due frames jumps as it's resized.
		if (frameDue || isResizeEvent)
		{
			DispatchFrame(now);
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

		case SDL_APP_WILLENTERBACKGROUND:

			inBackground = true;

			windowEvent.type = WINDOW_DEACTIVATE;
			WindowEvent::Dispatch(&windowEvent);
			break;

		case SDL_APP_WILLENTERFOREGROUND:

			break;

		case SDL_APP_DIDENTERFOREGROUND:

			lastUpdate = GetCurrentTimeMs();
			MakeFrameDue(lastUpdate);
			deltaRemainder = 0.0;
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
		case SDL_CONTROLLERSENSORUPDATE:
		case SDL_CONTROLLERTOUCHPADDOWN:
		case SDL_CONTROLLERTOUCHPADMOTION:
		case SDL_CONTROLLERTOUCHPADUP:

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

			case SDL_DISPLAYEVENT_CONNECTED:
			case SDL_DISPLAYEVENT_DISCONNECTED:
			case SDL_DISPLAYEVENT_MOVED:

				// Displays come and go, and move as they are arranged or the primary
				// display changes
				orientationEvent.type = event->display.event == SDL_DISPLAYEVENT_CONNECTED ? DISPLAY_CONNECT : (event->display.event == SDL_DISPLAYEVENT_DISCONNECTED ? DISPLAY_DISCONNECT : DISPLAY_MOVE);
				orientationEvent.orientation = 0;
				orientationEvent.display = event->display.display;
				OrientationEvent::Dispatch(&orientationEvent);

				break;
			}
			break;

		case SDL_DROPFILE:
		case SDL_DROPTEXT:
		case SDL_DROPBEGIN:
		case SDL_DROPCOMPLETE:

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

		case SDL_SYSWMEVENT:

			ProcessMenuEvent(event);
			break;

		case SDL_TEXTINPUT:
		case SDL_TEXTEDITING:
		case SDL_TEXTEDITING_EXT:

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

				// The frame rate drops while every window is minimised or hidden
				if (event->window.event == SDL_WINDOWEVENT_SHOWN || event->window.event == SDL_WINDOWEVENT_HIDDEN ||
					event->window.event == SDL_WINDOWEVENT_MINIMIZED || event->window.event == SDL_WINDOWEVENT_RESTORED ||
					event->window.event == SDL_WINDOWEVENT_MAXIMIZED)
					UpdateWindowsHidden(true);

				// A window that comes back into view is drawn without waiting out an idle frame
				if (event->window.event == SDL_WINDOWEVENT_SHOWN || event->window.event == SDL_WINDOWEVENT_RESTORED ||
					event->window.event == SDL_WINDOWEVENT_MAXIMIZED)
					SDL_AtomicSet(&s_frameRequested, 1);
				break;

			case SDL_WINDOWEVENT_DISPLAY_CHANGED:

				// The display's refresh rate decides whether frames are swap paced
				ApplyMainLoopSettings();
				break;

			case SDL_WINDOWEVENT_EXPOSED:

				ProcessWindowEvent(event);

				// The frame is Update's, once the rest of this turn's events are handled, or
				// the watch's while a native modal loop owns the thread. An exposed window
				// asks for one, which a loop running at its idle rate would otherwise put off.
				SDL_AtomicSet(&s_frameRequested, 1);
				break;

			case SDL_WINDOWEVENT_SIZE_CHANGED:
			case SDL_WINDOWEVENT_RESIZED:
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
				ProcessWindowEvent(event, true);
#else
				// SDL posts SIZE_CHANGED for every change of size, and RESIZED after it with the
				// same size when the user or the system resized the window, so one is enough
				if (event->window.event == SDL_WINDOWEVENT_RESIZED) break;

				ProcessWindowEvent(event);
#endif
				// A new size is drawn by the frame that follows this turn's events
				SDL_AtomicSet(&s_frameRequested, 1);
				break;

			case SDL_WINDOWEVENT_CLOSE:

				ProcessWindowEvent(event);
				break;
			}

			break;

		case SDL_QUIT:

			// SDL raises SDL_QUIT for exits the application did not initiate itself:
			// SIGTERM / SIGINT through its default signal handlers, Cmd+Q on macOS.
			// Stopping the loop here skips the Haxe side entirely: Window.onClose,
			// Application.onExit (documented as cancelable, but dispatched only after
			// Exec has already returned) and anything built on them, such as OpenFL's
			// NativeApplication "exiting". Route the quit as a close request on every
			// open window instead, so the same cancelable chain runs as for a click on
			// the close button. Only stop the loop outright when nothing is open; SDL
			// also raises SDL_QUIT when the last window goes away.
#if defined(ANDROID) || defined(IPHONE) || defined(EMSCRIPTEN)
			// On mobile and the web, SDL_QUIT means the system is ending the
			// application, which a close handler cannot refuse
			active = false;
#else
			if (windows.empty () || !WindowEvent::callback)
			{
				active = false;
				break;
			}

			{
				// Closing a window unregisters it, so iterate over a copy.
				std::vector<SDLWindow*> openWindows (windows);

				for (std::vector<SDLWindow*>::const_iterator iter = openWindows.begin (); iter != openWindows.end (); ++iter)
				{
					if (!(*iter)->sdlWindow) continue;

					windowEvent.type = WINDOW_CLOSE;
					windowEvent.windowID = SDL_GetWindowID ((*iter)->sdlWindow);
					WindowEvent::Dispatch (&windowEvent);
				}
			}
#endif

			break;

		default:

			if (localSocketEventType != 0 && event->type == localSocketEventType)
			{
				LocalSocket::Update();
				break;
			}

#if !defined(HX_WINDOWS) || defined(HX_WINRT)
			// Pushed by Wake to end the wait, with nothing of its own to do
			if (s_wakeEventType != 0 && event->type == s_wakeEventType)
			{
				SDL_AtomicSet(&s_wakeQueued, 0);
				break;
			}
#endif

			// Menu and tray icon events queued by SDLMenu use a registered event type
			ProcessMenuEvent(event);
			ProcessTrayIconEvent(event);
			break;
		}
	}

	void SDLApplication::Init()
	{

		active = true;
		deltaRemainder = 0.0;
		lastUpdate = GetCurrentTimeMs();
		MakeFrameDue(lastUpdate);
		frameForced = false;
		framePending = false;
		inputHoldUntil = 0.0;
		firstTime = true;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		dispatchedWindowSizes.clear();
		SDL_AtomicSet(&s_nativeModalLoopDepth, 0);
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
			case SDL_DROPTEXT:
				dropEvent.type = DROP_TEXT;
				break;
			case SDL_DROPBEGIN:
				dropEvent.type = DROP_BEGIN;
				break;
			case SDL_DROPCOMPLETE:
				dropEvent.type = DROP_COMPLETE;
				break;
			default:
				dropEvent.type = DROP_FILE;
				break;
			}

			dropEvent.file = (vbyte *)event->drop.file;
			dropEvent.windowID = event->drop.windowID;

			DropEvent::Dispatch(&dropEvent);
			if (event->drop.file) SDL_free(event->drop.file);
			dropEvent.file = NULL;
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
				gamepadEvent.timestamp = event->common.timestamp;

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
				gamepadEvent.timestamp = event->common.timestamp;

				GamepadEvent::Dispatch(&gamepadEvent);
				break;

			case SDL_CONTROLLERBUTTONUP:

				gamepadEvent.type = GAMEPAD_BUTTON_UP;
				gamepadEvent.button = event->cbutton.button;
				gamepadEvent.id = event->cbutton.which;
				gamepadEvent.timestamp = event->common.timestamp;

				GamepadEvent::Dispatch(&gamepadEvent);
				break;

			case SDL_CONTROLLERDEVICEADDED:

				if (SDLGamepad::Connect(event->cdevice.which))
				{

					gamepadEvent.type = GAMEPAD_CONNECT;
					gamepadEvent.id = SDLGamepad::GetInstanceID(event->cdevice.which);
					gamepadEvent.timestamp = event->common.timestamp;

					GamepadEvent::Dispatch(&gamepadEvent);
				}

				break;

			case SDL_CONTROLLERDEVICEREMOVED:
			{

				gamepadEvent.type = GAMEPAD_DISCONNECT;
				gamepadEvent.id = event->cdevice.which;
				gamepadEvent.timestamp = event->common.timestamp;

				GamepadEvent::Dispatch(&gamepadEvent);
				SDLGamepad::Disconnect(event->cdevice.which);
				break;
			}

			case SDL_CONTROLLERSENSORUPDATE:

				// The sensor goes in axis, and its readings in x, y and z
				gamepadEvent.type = GAMEPAD_SENSOR_UPDATE;
				gamepadEvent.id = event->csensor.which;
				gamepadEvent.axis = event->csensor.sensor;
				gamepadEvent.x = event->csensor.data[0];
				gamepadEvent.y = event->csensor.data[1];
				gamepadEvent.z = event->csensor.data[2];
				gamepadEvent.timestamp = event->common.timestamp;

				GamepadEvent::Dispatch(&gamepadEvent);
				break;

			case SDL_CONTROLLERTOUCHPADDOWN:
			case SDL_CONTROLLERTOUCHPADMOTION:
			case SDL_CONTROLLERTOUCHPADUP:

				// The finger goes in button, and where it is in x and y
				gamepadEvent.type = event->type == SDL_CONTROLLERTOUCHPADDOWN ? GAMEPAD_TOUCHPAD_DOWN : (event->type == SDL_CONTROLLERTOUCHPADMOTION ? GAMEPAD_TOUCHPAD_MOVE : GAMEPAD_TOUCHPAD_UP);
				gamepadEvent.id = event->ctouchpad.which;
				gamepadEvent.button = event->ctouchpad.finger;
				gamepadEvent.x = event->ctouchpad.x;
				gamepadEvent.y = event->ctouchpad.y;
				gamepadEvent.z = event->ctouchpad.pressure;
				gamepadEvent.timestamp = event->common.timestamp;

				GamepadEvent::Dispatch(&gamepadEvent);
				break;
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
			keyEvent.timestamp = event->common.timestamp;
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

	void SDLApplication::ProcessMenuEvent(SDL_Event *event)
	{

		Uint32 windowID;
		int id;

		if (!MenuEvent::callback)
			return;

		if (SDLMenu::GetSelection(event, &windowID, &id))
		{

			menuEvent.type = MENU_SELECT;
			menuEvent.id = id;
			menuEvent.windowID = windowID;

			MenuEvent::Dispatch(&menuEvent);
		}
		else if (SDLMenu::GetDockMenuSelection(event, &id))
		{

			menuEvent.type = MENU_DOCK_SELECT;
			menuEvent.id = id;
			menuEvent.windowID = 0;

			MenuEvent::Dispatch(&menuEvent);
		}
		else
		{

			int source;

			if (SDLMenu::GetClose(event, &windowID, &id, &source) && source >= 0 && source <= 3)
			{

				// One type for each place a menu belongs, in native_desktop's MenuSource order
				menuEvent.type = (MenuEventType)(MENU_CLOSE_WINDOW + source);
				menuEvent.id = id;
				menuEvent.windowID = windowID;

				MenuEvent::Dispatch(&menuEvent);
			}
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

				// SDL 2.0.22+ captures while buttons are held, before queued events
				// reach Lime. Replaying capture here can recapture after SDL has
				// already processed a complete down/up batch. Keep the legacy
				// path for older SDL, touch-synthesized mouse events (excluded
				// by SDL auto capture), and applications that disable it.
#if defined(HX_WINDOWS) && !defined(HX_WINRT) && SDL_VERSION_ATLEAST(2, 0, 22)
				if (event->button.which == SDL_TOUCH_MOUSEID || !SDL_GetHintBoolean(SDL_HINT_MOUSE_AUTO_CAPTURE, SDL_TRUE))
#endif
				{
					SDL_CaptureMouse(SDL_TRUE);
					mouseCaptureRequested = true;
				}

				mouseEvent.type = MOUSE_DOWN;
				mouseEvent.button = event->button.button - 1;
				mouseEvent.x = event->button.x;
				mouseEvent.y = event->button.y;
				mouseEvent.clickCount = event->button.clicks;
				break;

			case SDL_MOUSEBUTTONUP:

#if defined(HX_WINDOWS) && !defined(HX_WINRT) && SDL_VERSION_ATLEAST(2, 0, 22)
				// Release our own request even if the hint changed while held.
				if (mouseCaptureRequested || event->button.which == SDL_TOUCH_MOUSEID || !SDL_GetHintBoolean(SDL_HINT_MOUSE_AUTO_CAPTURE, SDL_TRUE))
#endif
				{
					SDL_CaptureMouse(SDL_FALSE);
					mouseCaptureRequested = false;
				}

				mouseEvent.type = MOUSE_UP;
				mouseEvent.button = event->button.button - 1;
				mouseEvent.x = event->button.x;
				mouseEvent.y = event->button.y;
				mouseEvent.clickCount = event->button.clicks;
				break;

			case SDL_MOUSEWHEEL:

				mouseEvent.type = MOUSE_WHEEL;

				// Whole steps, and, in movementX and movementY, the fractions of a
				// step that touchpads and smooth wheels scroll by, for windows
				// with preciseMouseWheel
				if (event->wheel.direction == SDL_MOUSEWHEEL_FLIPPED)
				{

					mouseEvent.x = -event->wheel.x;
					mouseEvent.y = -event->wheel.y;
					mouseEvent.movementX = -event->wheel.preciseX;
					mouseEvent.movementY = -event->wheel.preciseY;
				}
				else
				{

					mouseEvent.x = event->wheel.x;
					mouseEvent.y = event->wheel.y;
					mouseEvent.movementX = event->wheel.preciseX;
					mouseEvent.movementY = event->wheel.preciseY;
				}
				break;
			}

			mouseEvent.windowID = event->button.windowID;
			mouseEvent.timestamp = event->common.timestamp;
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

			const char *text = event->text.text;

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

			case SDL_TEXTEDITING_EXT:

				// A composition too long for SDL_TEXTEDITING
				textEvent.type = TEXT_EDIT;
				textEvent.start = event->editExt.start;
				textEvent.length = event->editExt.length;
				text = event->editExt.text ? event->editExt.text : "";
				break;
			}

			if (textEvent.text)
			{

				free(textEvent.text);
			}

			textEvent.text = (vbyte *)malloc(strlen(text) + 1);
			strcpy((char *)textEvent.text, text);

			textEvent.windowID = event->text.windowID;
			TextEvent::Dispatch(&textEvent);
		}

		// SDL leaves the long composition's text to the application to free
		if (event->type == SDL_TEXTEDITING_EXT)
		{

			SDL_free(event->editExt.text);
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
			touchEvent.timestamp = event->common.timestamp;

			TouchEvent::Dispatch(&touchEvent);
		}
	}

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
	bool SDLApplication::PrepareResizeEvent(SDL_Event *event, bool currentSize)
	{
		// SDL coalesces its own events, but directly pushed live-resize events
		// can still contain older sizes. Reconcile queued events to current native
		// dimensions; the watch uses its immediate dimensions before SDL updates.
		if (currentSize)
		{
			SDL_Window *window = SDL_GetWindowFromID(event->window.windowID);
			if (window)
				SDL_GetWindowSize(window, &event->window.data1, &event->window.data2);
		}
		std::pair<int, int> points(event->window.data1, event->window.data2);
		std::pair<int, int> pixels(0, 0);
#if SDL_VERSION_ATLEAST(2, 26, 0)
		// A window that moves to a display of another scale keeps its size in points, and SDL
		// says so with a size event of the same size. Its size in pixels is what changed.
		SDL_Window *sized = SDL_GetWindowFromID(event->window.windowID);
		if (sized)
			SDL_GetWindowSizeInPixels(sized, &pixels.first, &pixels.second);
#endif
		std::pair<std::pair<int, int>, std::pair<int, int>> size(points, pixels);
		std::map<Uint32, std::pair<std::pair<int, int>, std::pair<int, int>>>::iterator previous = dispatchedWindowSizes.find(event->window.windowID);
		if (previous != dispatchedWindowSizes.end() && previous->second == size)
			return false;
		dispatchedWindowSizes[event->window.windowID] = size;
		return true;
	}
#endif

	void SDLApplication::ProcessTrayIconEvent(SDL_Event *event)
	{

		int id;
		int type;
		int itemID;
		int x;
		int y;

		if (TrayIconEvent::callback && SDLMenu::GetTrayIconEvent(event, &id, &type, &itemID, &x, &y))
		{

			trayIconEvent.type = (TrayIconEventType)type;
			trayIconEvent.id = id;
			trayIconEvent.itemID = itemID;
			trayIconEvent.x = x;
			trayIconEvent.y = y;

			TrayIconEvent::Dispatch(&trayIconEvent);
		}
	}

	void SDLApplication::ProcessWindowEvent(SDL_Event *event, bool currentSize)
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

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
				if (!PrepareResizeEvent(event, currentSize)) return;
#endif
				windowEvent.type = WINDOW_RESIZE;
				windowEvent.width = event->window.data1;
				windowEvent.height = event->window.data2;
				break;

			case SDL_WINDOWEVENT_RESTORED:
				windowEvent.type = WINDOW_RESTORE;
				break;
			}

			windowEvent.windowID = event->window.windowID;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
			try {
				// A new size is drawn at once, due or not: until a frame is drawn at that size
				// the window shows the last one stretched to it
				if (event->window.event == SDL_WINDOWEVENT_SIZE_CHANGED || event->window.event == SDL_WINDOWEVENT_RESIZED)
					frameForced = true;
				WindowEvent::Dispatch(&windowEvent);
				if (modalExceptionPending && (event->window.event == SDL_WINDOWEVENT_SIZE_CHANGED || event->window.event == SDL_WINDOWEVENT_RESIZED))
					dispatchedWindowSizes.erase(event->window.windowID);
			} catch (...) {
				// A failed resize callback must be retryable at the same dimensions.
				if (event->window.event == SDL_WINDOWEVENT_SIZE_CHANGED || event->window.event == SDL_WINDOWEVENT_RESIZED)
					dispatchedWindowSizes.erase(event->window.windowID);
				throw;
			}
#else
			WindowEvent::Dispatch(&windowEvent);
#endif
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
		SDL_AtomicSet(&s_nativeModalLoopDepth, 0);
#endif

#ifdef LIME_SDL_SOUND
		// Not under a stream being refilled on another thread
		SDLSound::Quit ();
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
			UpdateWindowsHidden (false);
			RefreshVSyncState ();
		}

#ifdef IPHONE
		SDL_iPhoneSetAnimationCallback(window->sdlWindow, 1, UpdateFrame, NULL);
#endif
	}

	void SDLApplication::UnregisterWindow(SDLWindow *window)
	{

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		if (window) dispatchedWindowSizes.erase(window->GetID());
#endif
		windows.erase (std::remove (windows.begin (), windows.end (), window), windows.end ());
		UpdateWindowsHidden (false);
		RefreshVSyncState ();
	}

	void SDLApplication::UpdateWindowsHidden(bool apply)
	{

		// An application without windows isn't limited, as it may draw nothing on purpose
		int shown = 0;
		int counted = 0;

		for (std::vector<SDLWindow*>::const_iterator iter = windows.begin (); iter != windows.end (); ++iter)
		{
			if (!*iter || !(*iter)->sdlWindow)
				continue;

			counted++;
			if (!(SDL_GetWindowFlags ((*iter)->sdlWindow) & (SDL_WINDOW_MINIMIZED | SDL_WINDOW_HIDDEN)))
				shown++;
		}

		bool hidden = (counted > 0 && shown == 0);

		if (hidden != windowsHidden)
		{
			windowsHidden = hidden;
			if (apply) ApplyMainLoopSettings ();
		}
	}

	void SDLApplication::SetBackgroundFrameRate(double frameRate)
	{

		double rate = (frameRate > 0.0) ? frameRate : 0.0;
		if (rate == requestedBackgroundFrameRate)
			return;

		requestedBackgroundFrameRate = rate;
		if (windowsHidden) ApplyMainLoopSettings ();
	}

	void SDLApplication::SetIdleEvents(bool enabled)
	{

		idleEvents = enabled;
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

	bool SDLApplication::SetMenu(const unsigned char *data, int length)
	{

		return SDLMenu::SetApplicationMenu(data, length);
	}

	void SDLApplication::SetVSyncMode(int vsyncMode)
	{

		bool changed = (vsyncMode != requestedVSyncMode);
		requestedVSyncMode = vsyncMode;

		for (std::vector<SDLWindow*>::iterator iter = windows.begin (); iter != windows.end (); ++iter)
		{
			// A window applies its mode when it is made, so one already in this mode is left alone
			if (*iter && (*iter)->GetRequestedVSyncMode () != requestedVSyncMode)
			{
				(*iter)->SetVSyncMode (requestedVSyncMode);
				changed = true;
			}
		}

		if (changed)
			RefreshVSyncState();
	}

	bool SDLApplication::Update()
	{

		SDLTrayIcon::Update();
		LocalSocket::Update();

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		CheckModalException();
#endif
		Uint64 framesBeforeEvents = dispatchedFrames;
		SDL_Event event;
		event.type = -1;
		int waited = WAIT_NONE;
		int handled = 0;

#if (!defined(IPHONE) && !defined(EMSCRIPTEN))

		// A turn of the loop: wait until there is something to do, collect the system's events
		// once, handle every one of them, then run a frame if one is due. A loop with a frame
		// due, as an uncapped one always has, doesn't wait.
		if (active && (inBackground || !firstTime))
		{
			waited = WaitEvent(&event);

			if (waited == WAIT_EVENT)
			{
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
				CheckModalException();
#endif
				if (!IsWakeEvent(event))
					handled++;
				HandleEvent(&event);
				event.type = -1;
				if (!active)
					return active;
			}
		}

		firstTime = false;

#endif

		// One pump for each turn: the wait's own, where it made one
		if (waited == WAIT_NONE)
			SDL_PumpEvents();

		double collected = GetCurrentTimeMs();

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		CheckModalException();
#endif

		// Every event collected comes before the frame, whether or not one is due: a frame is
		// drawn from the input before it, and a frame that went first would leave input only the
		// time frames don't use. The count is taken before any is handled, so events that arrive
		// meanwhile wait for the next turn and can't hold a frame back. One is fetched at a time,
		// which keeps a SYSWMEVENT's message valid while it is handled.
		int queued = QueuedEvents();

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		if (SDL_AtomicSet(&s_foreignPush, 0) != 0)
		{
			// Woken for an event another thread was pushing, which SDL queues just after
			for (int i = 0; i < 8 && queued == 0; i++)
			{
				SwitchToThread();
				queued = QueuedEvents();
			}
		}
#endif

		while (queued-- > 0)
		{
			if (SDL_PeepEvents(&event, 1, SDL_GETEVENT, SDL_FIRSTEVENT, SDL_LASTEVENT) != 1)
				break;

			if (!IsWakeEvent(event))
				handled++;
			HandleEvent(&event);
			event.type = -1;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
			CheckModalException();
#endif
			if (!active)
				return active;
		}

		// Input that follows within the profile's interval waits for the interval to pass
		if (handled > 0)
			inputHoldUntil = collected + inputInterval;

		currentUpdate = GetCurrentTimeMs();

		if (!inBackground && dispatchedFrames == framesBeforeEvents && (frameForced || IsFrameDue(currentUpdate)))
		{

			DispatchFrame(currentUpdate);
		}

		frameForced = false;
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

		if (inBackground)
		{
			System::GCEnterBlocking();
			SDL_AtomicSet(&s_waitEventBlocking, 1);
			int result = SDL_WaitEventTimeout(event, 100);
			SDL_AtomicSet(&s_waitEventBlocking, 0);
			System::GCExitBlocking();
			return (result == 1) ? WAIT_EVENT : WAIT_NONE;
		}

		// An idle event is due as the wait begins
		idleArmed = true;

#if defined(HX_WINDOWS) && !defined(HX_WINRT)

		// One wait for each turn, on a timer set to when the frame is due, which input and Wake
		// end. SDL's own wait counts in whole milliseconds and pumps as it goes round, so it
		// isn't used here, and its pump is left to Update.

		// SDL reads controllers as it pumps, so the wait is cut short to pump for them
		int devicePoll = DevicePollInterval();
		double pollMs = 0.0;
		if (devicePoll > 0)
			pollMs = (devicePoll > 1 || inputInterval < 1.0) ? (double)devicePoll : inputInterval;

		for (;;)
		{

			double now = GetCurrentTimeMs();
			if (IsFrameDue(now))
				return WAIT_NONE;

			// Events the application queued itself, as a window does when a listener resizes
			// it, are in SDL's queue and not the system's, which is all the wait hears
			if (QueuedEvents() > 0)
				return WAIT_NONE;

			if (IsTimerDue(now))
			{
				DispatchTimers();
				continue;
			}

			if (IsIdleDue(now))
			{
				DispatchIdle(nextUpdate - now);
				continue;
			}

			double until = nextUpdate;
			bool forFrame = true;
			bool poll = false;
			double spin = 0.0;

			// Back in time for the next timer, where frames come at an idle rate
			double timer = NextTimerTime();
			if (timer >= 0.0 && timer < until)
			{
				until = timer;
				forFrame = false;
			}

			// Input that comes within the profile's interval of the last isn't watched for
			// until the interval is up
			bool watchInput = (now >= inputHoldUntil);
			if (!watchInput && inputHoldUntil < until)
			{
				until = inputHoldUntil;
				forFrame = false;
			}

			// Back in time for the next idle event of a listener with more to do
			if (idleEvents && idleArmed && nextIdle > now && nextIdle < until && nextUpdate - nextIdle >= IDLE_MIN_REMAINING)
			{
				until = nextIdle;
				forFrame = false;
			}

			if (watchInput && pollMs > 0.0 && now + pollMs < until)
			{
				until = now + pollMs;
				forFrame = false;
				poll = true;
			}

			double ms = until - now;

			if (!poll && allowBusyWait && ms > WAIT_STEP)
			{
				// A step towards it, which leaves a last wait that is short
				ms = (ms * WAIT_STEP_PART < WAIT_STEP) ? ms * WAIT_STEP_PART : WAIT_STEP;
				until = now + ms;
				forFrame = false;
			}

			if (allowBusyWait && busyWaitOnly && nextUpdate <= earliestUpdate)
			{
				// Frames this close together are spun for from one to the next
				until = nextUpdate;
				poll = false;
				spin = 1.0;
				ms = 0.0;
			}
			else if (forFrame && allowBusyWait && (!frameTimer || !SleepsOutTheRemainder()))
			{
				// The precision profile, and busy waiting asked for by name, spin up to the
				// frame. So does a loop without a high-resolution timer, as before, since its
				// waits end on a timer tick.
				spin = frameTimer ? SPIN_MARGIN : (double)GetSleepGuardMs() + 1.0;
				ms -= spin;
			}
			else if (!frameTimer)
			{
				// Whole milliseconds, rounded up rather than spun
				ms = std::ceil(ms);
			}

			int ended = (ms > 0.0) ? SleepUntilWork(ms, watchInput) : SLEEP_TIME_UP;

			// Input, or an event another thread pushed: Update collects what there is
			if (ended == SLEEP_INPUT || (ended == SLEEP_WOKEN && SDL_AtomicGet(&s_foreignPush) != 0))
				return WAIT_NONE;

			// Woken for a frame that was asked for, which is due now or waited for from here
			if (ended == SLEEP_WOKEN)
				continue;

			if (spin > 0.0)
			{
				System::GCEnterBlocking();
				while (GetCurrentTimeMs() < until)
					YieldProcessor();
				System::GCExitBlocking();
			}

			if (poll)
			{
				SDL_PumpEvents();
				CheckModalException();
				if (QueuedEvents() > 0)
					return WAIT_PUMPED;
			}
		}

#else

		// SDL's wait, in whole milliseconds, to within the sleep guard of the frame, and then
		// what the platform does best for the remainder

		for (;;)
		{

			double now = GetCurrentTimeMs();
			if (IsFrameDue(now))
				return WAIT_NONE;

			double remaining = nextUpdate - now;

			if (IsTimerDue(now))
			{
				DispatchTimers();
				continue;
			}

			if (IsIdleDue(now))
			{
				DispatchIdle(remaining);
				continue;
			}

			// Input that comes within the profile's interval of the last is left until the
			// interval is up. Events the application queued itself don't wait.
			if (now < inputHoldUntil && QueuedEvents() == 0)
			{
				double hold = inputHoldUntil - now;
				SleepThroughInput(hold < remaining ? hold : remaining);
				continue;
			}

			if (allowBusyWait && busyWaitOnly && nextUpdate <= earliestUpdate)
			{
				// Frames this close together are spun for from one to the next
				bool pumped = false;
				int result = 0;

				System::GCEnterBlocking();
				SDL_AtomicSet(&s_waitEventBlocking, 1);
				while (result == 0 && (nextUpdate - GetCurrentTimeMs()) > 0.0)
				{
					SDL_PumpEvents();
					pumped = true;
					result = SDL_PeepEvents(event, 1, SDL_GETEVENT, SDL_FIRSTEVENT, SDL_LASTEVENT);
				}
				SDL_AtomicSet(&s_waitEventBlocking, 0);
				System::GCExitBlocking();

				if (result == 1)
					return WAIT_EVENT;
				return pumped ? WAIT_PUMPED : WAIT_NONE;
			}

			int waitMs = (int)(remaining + 0.999);
			if (waitMs < 1)
				waitMs = 1;

			bool remainder = false;

			if (!allowBusyWait)
			{
				if (waitMs > 16)
					waitMs = 16;
			}
			else
			{
				// Measuring sleeps, so the time left is read again
				if (CalibrateSleepGuardBefore(remaining))
					continue;

				Uint32 guardMs = GetSleepGuardMs();
				if (remaining > (double)guardMs + 1.0)
				{

					waitMs = (int)(remaining - (double)guardMs);
					if (waitMs > 8)
						waitMs = 8;
				}
				else
				{
					remainder = true;
				}
			}

			// Back in time for the next idle event of a listener with more to do
			if (idleEvents && idleArmed && nextIdle > now && nextUpdate - nextIdle >= IDLE_MIN_REMAINING)
			{
				int idleMs = (int)(nextIdle - now + 0.999);
				if (idleMs < 1)
					idleMs = 1;

				if (idleMs < waitMs)
				{
					waitMs = idleMs;
					remainder = false;
				}
			}

			// And for the next timer, where frames come at an idle rate
			double timer = NextTimerTime();
			if (timer >= 0.0 && timer < nextUpdate)
			{
				int timerMs = (int)(timer - now + 0.999);
				if (timerMs < 1)
					timerMs = 1;

				if (timerMs <= waitMs)
				{
					waitMs = timerMs;
					remainder = false;
				}
			}

#if !defined(HX_MACOS) && !defined(ANDROID)
			if (remainder)
			{
				// SDL's wait would overshoot what is left, so it is slept in fifths of a
				// millisecond between pumps, or spun where the application asked for that
				int result = 0;

				System::GCEnterBlocking();
				SDL_AtomicSet(&s_waitEventBlocking, 1);

				for (;;)
				{
					SDL_PumpEvents();
					result = SDL_PeepEvents(event, 1, SDL_GETEVENT, SDL_FIRSTEVENT, SDL_LASTEVENT);
					if (result != 0 || (nextUpdate - GetCurrentTimeMs()) <= 0.0)
						break;

#if !defined(HX_WINDOWS)
					if (SleepsOutTheRemainder())
					{
						struct timespec slice;
						slice.tv_sec = 0;
						slice.tv_nsec = 200000;
						nanosleep(&slice, NULL);
					}
#endif
				}

				SDL_AtomicSet(&s_waitEventBlocking, 0);
				System::GCExitBlocking();
				return (result == 1) ? WAIT_EVENT : WAIT_PUMPED;
			}
#else
			(void)remainder;
#endif

			Uint32 waitStart = SDL_GetTicks();
			System::GCEnterBlocking();
			SDL_AtomicSet(&s_waitEventBlocking, 1);
			int result = SDL_WaitEventTimeout(event, waitMs);
			SDL_AtomicSet(&s_waitEventBlocking, 0);
			System::GCExitBlocking();
			Uint32 waitElapsed = SDL_GetTicks() - waitStart;

			if (result == 1)
				return WAIT_EVENT;

			if (allowBusyWait)
				UpdateSleepGuard((Uint32)waitMs, waitElapsed);
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
