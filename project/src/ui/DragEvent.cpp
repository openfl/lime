#include <system/CFFI.h>
#include <ui/DragEvent.h>


namespace lime {


	ValuePointer* DragEvent::callback = 0;
	ValuePointer* DragEvent::eventObject = 0;

	static int id_action;
	static int id_allowedActions;
	static int id_type;
	static int id_windowID;
	static int id_x;
	static int id_y;
	static bool init = false;


	DragEvent::DragEvent () {

		action = 0;
		allowedActions = 0;
		type = DRAG_ENTER;
		windowID = 0;
		x = 0;
		y = 0;

	}


	void DragEvent::Dispatch (DragEvent* event) {

		if (!DragEvent::callback) {

			event->action = 0;
			return;

		}

		if (DragEvent::eventObject->IsCFFIValue ()) {

			if (!init) {

				id_action = val_id ("action");
				id_allowedActions = val_id ("allowedActions");
				id_type = val_id ("type");
				id_windowID = val_id ("windowID");
				id_x = val_id ("x");
				id_y = val_id ("y");
				init = true;

			}

			value object = (value)DragEvent::eventObject->Get ();

			alloc_field (object, id_action, alloc_int (event->action));
			alloc_field (object, id_allowedActions, alloc_int (event->allowedActions));
			alloc_field (object, id_type, alloc_int (event->type));
			alloc_field (object, id_windowID, alloc_int (event->windowID));
			alloc_field (object, id_x, alloc_float (event->x));
			alloc_field (object, id_y, alloc_float (event->y));

			DragEvent::callback->Call ();

			// The listeners choose the action a drop takes
			event->action = val_int (val_field (object, id_action));

		} else {

			DragEvent* eventObject = (DragEvent*)DragEvent::eventObject->Get ();

			eventObject->action = event->action;
			eventObject->allowedActions = event->allowedActions;
			eventObject->type = event->type;
			eventObject->windowID = event->windowID;
			eventObject->x = event->x;
			eventObject->y = event->y;

			DragEvent::callback->Call ();

			event->action = eventObject->action;

		}

	}


}
