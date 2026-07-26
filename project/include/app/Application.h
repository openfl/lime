#ifndef LIME_APP_APPLICATION_H
#define LIME_APP_APPLICATION_H


#include <system/CFFI.h>


namespace lime {


	class Application {


		public:

			virtual ~Application () {};

			static AutoGCRoot* callback;

			virtual int Exec () = 0;
			virtual void Init () = 0;
			virtual int Quit () = 0;
			virtual void SetMainLoop (int profile, double frameRate, int timePrecision, int busyWait, int uncapMode) { SetFrameRate (frameRate); }
			virtual void SetFrameRate (double frameRate) = 0;
			virtual void SetVSyncMode (int vsyncMode) {}
			virtual bool Update () = 0;


	};


	Application* CreateApplication ();


}


#endif
