#include <system/CFFI.h>
#include <ui/TouchEvent.h>


namespace lime {


	ValuePointer* TouchEvent::callback = 0;
	ValuePointer* TouchEvent::eventObject = 0;

	static int id_device;
	static int id_dx;
	static int id_dy;
	static int id_id;
	static int id_pressure;
	static int id_type;
	static int id_x;
	static int id_y;
	static bool init = false;


	TouchEvent::TouchEvent () {

		type = TOUCH_START;
		x = 0;
		y = 0;
		id = 0;
		dx = 0;
		dy = 0;
		pressure = 0;
		device = 0;

	}


	void TouchEvent::Dispatch (TouchEvent* event) {

		if (TouchEvent::callback) {

			if (TouchEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_device = val_id ("device");
					id_dx = val_id ("dx");
					id_dy = val_id ("dy");
					id_id = val_id ("id");
					id_pressure = val_id ("pressure");
					id_type = val_id ("type");
					id_x = val_id ("x");
					id_y = val_id ("y");
					init = true;

				}

				value object = (value)TouchEvent::eventObject->Get ();

				alloc_field (object, id_device, alloc_int (event->device));
				alloc_field (object, id_dx, alloc_float (event->dx));
				alloc_field (object, id_dy, alloc_float (event->dy));
				alloc_field (object, id_id, alloc_int (event->id));
				alloc_field (object, id_pressure, alloc_float (event->pressure));
				alloc_field (object, id_type, alloc_int (event->type));
				alloc_field (object, id_x, alloc_float (event->x));
				alloc_field (object, id_y, alloc_float (event->y));

			} else {

				TouchEvent* eventObject = (TouchEvent*)TouchEvent::eventObject->Get ();

				eventObject->device = event->device;
				eventObject->dx = event->dx;
				eventObject->dy = event->dy;
				eventObject->id = event->id;
				eventObject->pressure = event->pressure;
				eventObject->type = event->type;
				eventObject->x = event->x;
				eventObject->y = event->y;

			}

			TouchEvent::callback->Call ();

		}

	}


}