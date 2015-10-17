#ifndef LIME_UI_MOUSE_H
#define LIME_UI_MOUSE_H


#include <ui/MouseCursor.h>
#include <ui/Window.h>


namespace lime {
	
	
	class Mouse {
		
		public:
			
			static MouseCursor currentCursor;
			
			static void Hide ();
			static void SetCursor (MouseCursor cursor);
			static void SetLock (bool lock);
      static void SetCaptureMode(bool capture);
			static void Show ();
			static void Warp (int x, int y, Window* window);
		
	};
	
	
}


#endif