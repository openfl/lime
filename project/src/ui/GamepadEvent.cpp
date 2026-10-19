#include <system/CFFI.h>
#include <ui/GamepadEvent.h>


namespace lime {


	ValuePointer* GamepadEvent::callback = 0;
	ValuePointer* GamepadEvent::eventObject = 0;

	static double id_axis;
	static int id_button;
	static int id_id;
	static int id_timestamp;
	static int id_type;
	static int id_value;
	static int id_x;
	static int id_y;
	static int id_z;
	static bool init = false;


	GamepadEvent::GamepadEvent () {

		axis = 0;
		axisValue = 0;
		button = 0;
		id = 0;
		timestamp = 0;
		type = GAMEPAD_AXIS_MOVE;
		x = 0;
		y = 0;
		z = 0;

	}


	void GamepadEvent::Dispatch (GamepadEvent* event) {

		if (GamepadEvent::callback) {

			if (GamepadEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_axis = val_id ("axis");
					id_button = val_id ("button");
					id_id = val_id ("id");
					id_timestamp = val_id ("timestamp");
					id_type = val_id ("type");
					id_value = val_id ("axisValue");
					id_x = val_id ("x");
					id_y = val_id ("y");
					id_z = val_id ("z");
					init = true;

				}

				value object = (value)GamepadEvent::eventObject->Get ();

				alloc_field (object, id_axis, alloc_int (event->axis));
				alloc_field (object, id_button, alloc_int (event->button));
				alloc_field (object, id_id, alloc_int (event->id));
				alloc_field (object, id_timestamp, alloc_int (event->timestamp));
				alloc_field (object, id_type, alloc_int (event->type));
				alloc_field (object, id_value, alloc_float (event->axisValue));
				alloc_field (object, id_x, alloc_float (event->x));
				alloc_field (object, id_y, alloc_float (event->y));
				alloc_field (object, id_z, alloc_float (event->z));

			} else {

				GamepadEvent* eventObject = (GamepadEvent*)GamepadEvent::eventObject->Get ();

				eventObject->axis = event->axis;
				eventObject->button = event->button;
				eventObject->id = event->id;
				eventObject->timestamp = event->timestamp;
				eventObject->type = event->type;
				eventObject->axisValue = event->axisValue;
				eventObject->x = event->x;
				eventObject->y = event->y;
				eventObject->z = event->z;

			}

			GamepadEvent::callback->Call ();

		}

	}


}
