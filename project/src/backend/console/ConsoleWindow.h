#ifndef LIME_CONSOLE_WINDOW_H
#define LIME_CONSOLE_WINDOW_H


#include <ui/Window.h>


namespace lime {
	
	
	class ConsoleWindow : public Window {
		
		public:
			
			ConsoleWindow (Application* application, int width, int height, int flags, const char* title);
			~ConsoleWindow ();
			
			virtual void Move (int x, int y);
			virtual void Resize (int width, int height);
		
	};
	
	
}


#endif