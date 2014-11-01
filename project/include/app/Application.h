#ifndef LIME_APP_APPLICATION_H
#define LIME_APP_APPLICATION_H


#include <hx/CFFI.h>


namespace lime {
	
	
	class Application {
		
		
		public:
			
			static double GetTicks ();
			
			static AutoGCRoot* callback;
			
			virtual void Init() = 0;
			virtual int Exec () = 0;
			virtual bool Update() = 0;
			virtual int Quit() = 0;
		
		
	};
	
	
	Application* CreateApplication ();
	
	
}


#endif