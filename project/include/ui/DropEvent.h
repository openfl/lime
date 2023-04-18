#ifndef LIME_UI_DROP_EVENT_H
#define LIME_UI_DROP_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {


	enum DropEventType {

		DROP_FILE

	};


	struct DropEvent {

		hl_type* t;
		vbyte* file;
		DropEventType type;

		static ValuePointer* callback;
		static ValuePointer* eventObject;

		DropEvent ();

		static void Dispatch (DropEvent* event);

	};


}


#endif