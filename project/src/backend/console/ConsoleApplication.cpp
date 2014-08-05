#include "ConsoleApplication.h"


namespace lime {
	
	
	AutoGCRoot* Application::callback = 0;
	
	
	double Application::GetTicks () {
		
		return 0;
		
	}
	
	
	ConsoleApplication::ConsoleApplication () {
		
		KeyEvent keyEvent;
		MouseEvent mouseEvent;
		RenderEvent renderEvent;
		TouchEvent touchEvent;
		UpdateEvent updateEvent;
		WindowEvent windowEvent;
		
	}
	
	
	ConsoleApplication::~ConsoleApplication () {
		
		
		
	}
	
	
	int ConsoleApplication::Exec () {
		
		printf ("Hello World\n");
		
		return 0;
		
	}
	
	
	Application* CreateApplication () {
		
		return new ConsoleApplication ();
		
	}
	
	
}