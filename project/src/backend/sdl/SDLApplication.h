#ifndef LIME_SDL_APPLICATION_H
#define LIME_SDL_APPLICATION_H


#include <SDL.h>
#include <vector>
#include <map>
#include <utility>
#include <exception>
#include <app/Application.h>
#include <app/ApplicationEvent.h>
#include <graphics/RenderEvent.h>
#include <system/ClipboardEvent.h>
#include <system/OrientationEvent.h>
#include <system/SensorEvent.h>
#include <ui/DropEvent.h>
#include <ui/GamepadEvent.h>
#include <ui/JoystickEvent.h>
#include <ui/KeyEvent.h>
#include <ui/MenuEvent.h>
#include <ui/TrayIconEvent.h>
#include <ui/MouseEvent.h>
#include <ui/TextEvent.h>
#include <ui/TouchEvent.h>
#include <ui/WindowEvent.h>
#include "SDLWindow.h"


namespace lime {


	class SDLApplication : public Application {

		public:

			SDLApplication ();
			~SDLApplication ();

			virtual int Exec ();
			virtual double GetFrameDeltaTime ();
			virtual void Init ();
			virtual int Quit ();
			virtual void RequestFrame ();
			virtual void RequestTimer (double milliseconds);
			virtual void SetMainLoop (int profile, double frameRate, int timePrecision, int busyWait, int uncapMode);
			virtual void SetBackgroundFrameRate (double frameRate);
			virtual void SetFrameRate (double frameRate);
			virtual void SetIdleEvents (bool enabled);
			virtual void SetIdleFrameRate (double frameRate);
			virtual bool SetMenu (const unsigned char* data, int length);
			virtual void SetVSyncMode (int vsyncMode);
			virtual bool Update ();

			void RegisterWindow (SDLWindow *window);
			void UnregisterWindow (SDLWindow *window);
			static void NoteContextFlip ();
			// Wakes a loop that is waiting for events or for a frame, from any thread
			static void Wake ();
			static void EnterSwapBlocking ();
			static void ExitSwapBlocking ();
			static void CallFromEventPump (void (*callback) (void*), void* data);
			static SDLApplication* GetCurrent () { return currentApplication; }
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
			static void EnterNativeModalLoop ();
			static void ExitNativeModalLoop ();
			static void RunPendingModalFrame ();
			void SetModalCallbacks (ValuePointer* update, ValuePointer* render, ValuePointer* window, ValuePointer* rethrow);
			void DeferModalException ();
#endif

		private:

			void AdvanceNextUpdate ();
			void ApplyMainLoopSettings ();
			void UpdateWindowsHidden (bool apply);
			void CalibrateSleepGuard (bool force = false);
			bool CalibrateSleepGuardBefore (double remaining);
			void DispatchFrame (double now, bool renderFrame = true);
			void DispatchIdle (double remaining);
			void DispatchTimers ();
			double GetCurrentTimeMs () const;
			double GetDisplayRefreshRate () const;
			Uint32 GetSleepGuardMs () const;
			void HandleEvent (SDL_Event* event);
			bool IsFrameDue (double now);
			bool IsIdleDue (double now) const;
			bool IsTimerDue (double now) const;
			double NextTimerTime () const;
			bool IsSchedulerUnthrottled () const;
			void MakeFrameDue (double now);
			void PaceFrameAfterRender (bool swapped, double renderMs);
			void Reschedule ();
			void TakeFrameRequest ();
			void RefreshVSyncState ();
			static int MinimizeOnFocusLossWatch (void* userdata, SDL_Event* event);
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
			void PumpOneFrameFromWatch (SDL_Event* watchEvent = 0);
			static int ModalEventWatch (void* userdata, SDL_Event* event);
			void CheckModalException (bool blocking = false);
#endif
			void ProcessClipboardEvent (SDL_Event* event);
			void ProcessDropEvent (SDL_Event* event);
			void ProcessGamepadEvent (SDL_Event* event);
			void ProcessJoystickEvent (SDL_Event* event);
			void ProcessKeyEvent (SDL_Event* event);
			void ProcessMenuEvent (SDL_Event* event);
			void ProcessMouseEvent (SDL_Event* event);
			void ProcessSensorEvent (SDL_Event* event);
			void ProcessTextEvent (SDL_Event* event);
			void ProcessTouchEvent (SDL_Event* event);
			void ProcessTrayIconEvent (SDL_Event* event);
			void ProcessWindowEvent (SDL_Event* event, bool currentSize = false);
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
			bool PrepareResizeEvent (SDL_Event* event, bool currentSize);
#endif
			void UpdateSleepGuard (Uint32 requestedMs, Uint32 elapsedMs);
			bool SleepsOutTheRemainder () const;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
			int SleepUntilWork (double ms, unsigned int wakeMask, bool byClock);
#endif
			int WaitEvent (SDL_Event* event);

			static void UpdateFrame ();
			static void UpdateFrame (void*);

			static SDLApplication* currentApplication;

			enum MainLoopProfileMode {

				MAIN_LOOP_PROFILE_BALANCED = 0,
				MAIN_LOOP_PROFILE_PRECISION = 1,
				MAIN_LOOP_PROFILE_LOW_ENERGY = 2,
				MAIN_LOOP_PROFILE_UNCAPPED = 3

			};

			enum MainLoopTimePrecisionMode {

				MAIN_LOOP_TIME_PRECISION_AUTO = 0,
				MAIN_LOOP_TIME_PRECISION_MILLISECOND = 1,
				MAIN_LOOP_TIME_PRECISION_HIGH_RESOLUTION = 2

			};

			enum MainLoopBusyWaitMode {

				MAIN_LOOP_BUSY_WAIT_AUTO = 0,
				MAIN_LOOP_BUSY_WAIT_OFF = 1,
				MAIN_LOOP_BUSY_WAIT_ON = 2

			};

			enum MainLoopUncapMode {

				MAIN_LOOP_UNCAP_OFF = 0,
				MAIN_LOOP_UNCAP_SOFT = 1,
				MAIN_LOOP_UNCAP_HARD = 2

			};

			enum MainLoopVSyncMode {

				MAIN_LOOP_VSYNC_OFF = 0,
				MAIN_LOOP_VSYNC_ON = 1,
				MAIN_LOOP_VSYNC_ADAPTIVE = 2,
				MAIN_LOOP_VSYNC_AUTO = 3

			};

			// What a wait leaves for Update to do
			enum WaitResult {

				// Nothing was collected: Update pumps
				WAIT_NONE = 0,
				// An event was taken off the queue, which the wait's own pump filled
				WAIT_EVENT = 1,
				// The queue was pumped, and nothing taken off it
				WAIT_PUMPED = 2

			};

			bool active;
			// The period frames are timed by: the frame period, or a refresh while swaps are skipped
			double activePeriod;
			int activeUncapMode;
			bool allowBusyWait;
			ApplicationEvent applicationEvent;
			bool busyWaitOnly;
			ClipboardEvent clipboardEvent;
			double currentUpdate;
			double deltaRemainder;
			Uint64 dispatchedFrames;
			// The time between the last two updates, which deltaTime rounds to whole milliseconds
			double frameDeltaTime;
			// The earliest the next frame may come: what a frame that is asked for is brought forward to
			double earliestUpdate;
			double displayRefreshRate;
			double framePeriod;
			Uint32 initFlags;
			DropEvent dropEvent;
			bool firstTime;
			// A frame is drawn once this turn's events are handled, due or not, as a new size is on Windows
			bool frameForced;
			// A frame was asked for and hasn't started
			bool framePending;
			// When the last frame was due, or when it started if it came a period late or early
			double frameSlot;
			GamepadEvent gamepadEvent;
			// An idle event is due in this wait: its first, or one more for a listener with work left
			bool idleArmed;
			bool idleEvents;
			// The time between frames while none is asked for, or 0 where frames always come
			double idlePeriod;
			// Input isn't watched for before this time: an interval after the last events were handled
			double inputHoldUntil;
			// The least time between two wakes for input, in milliseconds
			double inputInterval;
			// An event another thread was pushing wasn't in the queue yet, so the next wait is short
			bool lookAgain;
			JoystickEvent joystickEvent;
			KeyEvent keyEvent;
			double lastUpdate;
			Uint32 lastSleepCalibration;
			// Whether the loop settings have been applied, so a later change can keep the schedule
			bool mainLoopApplied;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
			// A high-resolution waitable timer, when Windows can make one
			void* frameTimer;
#endif
			SDL_threadID mainThreadID;
			MenuEvent menuEvent;
			MouseEvent mouseEvent;
			bool mouseCaptureRequested;
			double nextIdle;
			double nextUpdate;
			OrientationEvent orientationEvent;
			Uint64 performanceFrequency;
			Uint64 clockStartCounter;
			Uint64 clockStartTicks;
			mutable Uint32 clockLastTicks;
			mutable Uint64 clockElapsedTicks;
			bool realVSyncActive;
			// Every window is minimised or hidden
			bool windowsHidden;
			int requestedBusyWaitMode;
			// The most frames a second while every window is minimised or hidden, or 0 for no limit
			double requestedBackgroundFrameRate;
			double requestedFrameRate;
			// The frames a second while no frame is asked for, or 0 to keep them coming at the frame rate
			double requestedIdleFrameRate;
			int requestedProfile;
			int requestedTimePrecisionMode;
			int requestedUncapMode;
			int requestedVSyncMode;
			RenderEvent renderEvent;
			SensorEvent sensorEvent;
			bool schedulerUnthrottled;
			double sleepGuardMs;
			// Unthrottled because each swap waits for the display
			bool swapPaced;
			// Swap paced, but the swaps were seen not to wait, so frames are timed until one does
			bool swapFallback;
			// Swapped frames in a row that came well under a refresh period apart
			int shortSwaps;
			double lastSwapFrame;
			TextEvent textEvent;
			TouchEvent touchEvent;
			// When the next timer is due, on the loop's clock, or below zero for none
			double timedUpdate;
			// When the timers last ran, from an update or on their own
			double timersRanAt;
			TrayIconEvent trayIconEvent;
			bool useDisplayDrivenFallback;
			bool useHighResolutionTimer;
			WindowEvent windowEvent;
			std::vector<SDLWindow*> windows;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
			bool modalWatchInstalled;
			ValuePointer* modalCallbacks[4];
			bool modalExceptionPending;
			SDL_Event modalFrameEvent;
			bool modalFramePending;
			std::exception_ptr modalNativeException;
			std::map<Uint32, std::pair<int, int>> dispatchedWindowSizes;
#endif

	};


}


#endif
