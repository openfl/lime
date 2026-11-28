#ifndef LIME_UI_DRAG_EVENT_H
#define LIME_UI_DRAG_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {


	enum DragEventType {

		DRAG_ENTER = 1,
		DRAG_OVER = 2,
		DRAG_LEAVE = 3,
		DRAG_DROP = 4,
		DRAG_COMPLETE = 5

	};


	// A drag over a window, or the end of one started from it. The handler writes the action a drop would
	// take into action, which Dispatch reads back.
	struct DragEvent {

		hl_type* t;
		int action;
		int allowedActions;
		int type;
		int windowID;
		double x;
		double y;

		static ValuePointer* callback;
		static ValuePointer* eventObject;

		DragEvent ();

		static void Dispatch (DragEvent* event);

	};


}


#endif
