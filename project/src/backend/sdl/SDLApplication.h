#ifndef LIME_SDL_APPLICATION_H
#define LIME_SDL_APPLICATION_H


#include <SDL.h>
#include <vector>
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
			virtual void Init ();
			virtual int Quit ();
			virtual void SetMainLoop (int profile, double frameRate, int timePrecision, int busyWait, int uncapMode);
			virtual void SetFrameRate (double frameRate);
			virtual void SetVSyncMode (int vsyncMode);
			virtual bool Update ();

			void RegisterWindow (SDLWindow *window);
			void UnregisterWindow (SDLWindow *window);
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
			static void EnterNativeModalLoop ();
			static void ExitNativeModalLoop ();
#endif

		private:

			void AdvanceNextUpdate ();
			void ApplyMainLoopSettings ();
			void CalibrateSleepGuard (bool force = false);
			void DispatchFrame (double now, bool renderFrame = true);
			double GetCurrentTimeMs () const;
			double GetDisplayRefreshRate () const;
			Uint32 GetSleepGuardMs () const;
			void HandleEvent (SDL_Event* event);
			bool IsFrameDue (double now) const;
			bool IsSchedulerUnthrottled () const;
			void RefreshVSyncState ();
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
			void PumpOneFrameFromWatch (SDL_Event* watchEvent = 0);
			static int ModalEventWatch (void* userdata, SDL_Event* event);
#endif
			void ProcessClipboardEvent (SDL_Event* event);
			void ProcessDropEvent (SDL_Event* event);
			void ProcessGamepadEvent (SDL_Event* event);
			void ProcessJoystickEvent (SDL_Event* event);
			void ProcessKeyEvent (SDL_Event* event);
			void ProcessMouseEvent (SDL_Event* event);
			void ProcessSensorEvent (SDL_Event* event);
			void ProcessTextEvent (SDL_Event* event);
			void ProcessTouchEvent (SDL_Event* event);
			void ProcessWindowEvent (SDL_Event* event);
			void UpdateSleepGuard (Uint32 requestedMs, Uint32 elapsedMs);
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

			bool active;
			bool allowBusyWait;
			ApplicationEvent applicationEvent;
			bool busyWaitOnly;
			ClipboardEvent clipboardEvent;
			double currentUpdate;
			double displayRefreshRate;
			double framePeriod;
			Uint32 initFlags;
			DropEvent dropEvent;
			bool firstTime;
			GamepadEvent gamepadEvent;
			JoystickEvent joystickEvent;
			KeyEvent keyEvent;
			double lastUpdate;
			Uint32 lastSleepCalibration;
			MouseEvent mouseEvent;
			double nextUpdate;
			OrientationEvent orientationEvent;
			Uint64 performanceFrequency;
			bool realVSyncActive;
			int requestedBusyWaitMode;
			double requestedFrameRate;
			int requestedProfile;
			int requestedTimePrecisionMode;
			int requestedUncapMode;
			int requestedVSyncMode;
			RenderEvent renderEvent;
			SensorEvent sensorEvent;
			bool schedulerUnthrottled;
			double sleepGuardMs;
			TextEvent textEvent;
			TouchEvent touchEvent;
			bool useDisplayDrivenFallback;
			bool useHighResolutionTimer;
			WindowEvent windowEvent;
			std::vector<SDLWindow*> windows;
#if defined(HX_WINDOWS) && !defined(HX_WINRT)
			bool modalWatchInstalled;
			Uint32 mainThreadID;
			int pendingResizeDispatchSkips;
			int pendingWatchRenderSkips;
#endif

	};


}


#endif
