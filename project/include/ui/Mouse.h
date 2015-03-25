#ifndef LIME_UI_MOUSE_H
#define LIME_UI_MOUSE_H


#include <ui/MouseCursor.h>


namespace lime {
	
	
	class Mouse {
		
		public:
			
			static MouseCursor currentCursor;
			
			static int SetRelative (bool value);
			static void Hide ();
			static void SetCursor (MouseCursor cursor);
			static void Show ();
		
	};
	
	
}


#endif