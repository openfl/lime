#ifndef LIME_CONSOLE_APPLICATION_H
#define LIME_CONSOLE_APPLICATION_H


#include <app/Application.h>
#include <app/UpdateEvent.h>
#include <graphics/RenderEvent.h>
#include <ui/KeyEvent.h>
#include <ui/MouseEvent.h>
#include <ui/TouchEvent.h>
#include <ui/WindowEvent.h>


namespace lime {
	
	
	class ConsoleApplication : public Application {
		
		public:
			
			ConsoleApplication ();
			~ConsoleApplication ();
			
			virtual int Exec ();
		
		private:
			
			KeyEvent keyEvent;
			MouseEvent mouseEvent;
			RenderEvent renderEvent;
			TouchEvent touchEvent;
			UpdateEvent updateEvent;
			WindowEvent windowEvent;
		
	};
	
	
}


#endif