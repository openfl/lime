#include <system/CFFI.h>
#include <system/SensorEvent.h>


namespace lime {


	ValuePointer* SensorEvent::callback = 0;
	ValuePointer* SensorEvent::eventObject = 0;

	static int id_id;
	static int id_type;
	static int id_x;
	static int id_y;
	static int id_z;
	static bool init = false;


	SensorEvent::SensorEvent () {

		type = SENSOR_ACCELEROMETER;
		id = 0;
		x = 0;
		y = 0;
		z = 0;

	}


	void SensorEvent::Dispatch (SensorEvent* event) {

		if (SensorEvent::callback) {

			if (SensorEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_id = val_id ("id");
					id_type = val_id ("type");
					id_x = val_id ("x");
					id_y = val_id ("y");
					id_z = val_id ("z");
					init = true;

				}

				value object = (value)SensorEvent::eventObject->Get ();

				alloc_field (object, id_id, alloc_int (event->id));
				alloc_field (object, id_type, alloc_int (event->type));
				alloc_field (object, id_x, alloc_float (event->x));
				alloc_field (object, id_y, alloc_float (event->y));
				alloc_field (object, id_z, alloc_float (event->z));

			} else {

				SensorEvent* eventObject = (SensorEvent*)SensorEvent::eventObject->Get ();

				eventObject->id = event->id;
				eventObject->type = event->type;
				eventObject->x = event->x;
				eventObject->y = event->y;
				eventObject->z = event->z;

			}

			SensorEvent::callback->Call ();

		}

	}


}