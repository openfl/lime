#include <system/CFFI.h>
#include <system/OrientationEvent.h>


namespace lime {


	ValuePointer* OrientationEvent::callback = 0;
	ValuePointer* OrientationEvent::eventObject = 0;

	static int id_type;
	static int id_orientation;
	static int id_display;
	static bool init = false;


	OrientationEvent::OrientationEvent () {

		orientation = 0; // SDL_ORIENTATION_UNKNOWN
		display = 0;
		type = DISPLAY_ORIENTATION_CHANGE;

	}


	void OrientationEvent::Dispatch (OrientationEvent* event) {

		if (OrientationEvent::callback) {

			if (OrientationEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_orientation = val_id ("orientation");
					id_display = val_id ("display");
					id_type = val_id ("type");
					init = true;

				}

				value object = (value)OrientationEvent::eventObject->Get ();

				alloc_field (object, id_orientation, alloc_int (event->orientation));
				alloc_field (object, id_display, alloc_int (event->display));
				alloc_field (object, id_type, alloc_int (event->type));

			} else {

				OrientationEvent* eventObject = (OrientationEvent*)OrientationEvent::eventObject->Get ();

				eventObject->orientation = event->orientation;
				eventObject->display = event->display;
				eventObject->type = event->type;

			}

			OrientationEvent::callback->Call ();

		}

	}


}