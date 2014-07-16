#include "ConsoleWindow.h"


namespace lime {
	
	
	ConsoleWindow::ConsoleWindow (Application* application, int width, int height, int flags, const char* title) {
		
		currentApplication = application;
		this->flags = flags;
		
	}
	
	
	ConsoleWindow::~ConsoleWindow () {
		
		
		
	}
	
	
	void ConsoleWindow::Move (int x, int y) {
		
		
		
	}
	
	
	void ConsoleWindow::Resize (int width, int height) {
		
		
		
	}
	
	
	Window* CreateWindow (Application* application, int width, int height, int flags, const char* title) {
		
		return new ConsoleWindow (application, width, height, flags, title);
		
	}
	
	
}