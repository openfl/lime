#ifndef LIME_APP_APPLICATION_H
#define LIME_APP_APPLICATION_H


#include <system/CFFI.h>


namespace lime {


	class Application {


		public:

			virtual ~Application () {};

			static AutoGCRoot* callback;

			virtual int Exec () = 0;
			virtual double GetFrameDeltaTime () { return 0.0; }
			virtual void Init () = 0;
			virtual int Quit () = 0;
			virtual void RequestFrame () {}
			virtual void RequestTimer (double milliseconds) {}
			virtual void SetMainLoop (int profile, double frameRate, int timePrecision, int busyWait, int uncapMode) { SetFrameRate (frameRate); }
			virtual void SetFrameRate (double frameRate) = 0;
			virtual void SetBackgroundFrameRate (double frameRate) {}
			virtual void SetIdleEvents (bool enabled) {}
			virtual void SetIdleFrameRate (double frameRate) {}
			virtual bool SetMenu (const unsigned char* data, int length) { return false; }
			virtual void SetVSyncMode (int vsyncMode) {}
			virtual bool Update () = 0;


	};


	Application* CreateApplication ();

	// Called before CreateApplication where the windows allow high DPI
	void AllowHighDPI ();


}


#endif
