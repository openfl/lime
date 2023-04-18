#ifndef LIME_UI_KEY_EVENT_H
#define LIME_UI_KEY_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>
#include <stdint.h>


namespace lime {


	enum KeyEventType {

		KEY_DOWN,
		KEY_UP

	};


	struct KeyEvent {

		hl_type* t;
		double keyCode;
		int modifier;
		KeyEventType type;
		int windowID;

		static ValuePointer* callback;
		static ValuePointer* eventObject;

		KeyEvent ();

		static void Dispatch (KeyEvent* event);

	};


}


#endif