#include <system/CFFI.h>
#include <net/LocalSocketEvent.h>


namespace lime {


	ValuePointer* LocalSocketEvent::callback = 0;
	ValuePointer* LocalSocketEvent::eventObject = 0;

	static int id_error;
	static int id_id;
	static int id_length;
	static int id_type;
	static bool init = false;


	LocalSocketEvent::LocalSocketEvent () {

		error = 0;
		id = 0;
		length = 0;
		type = LOCAL_SOCKET_DATA;

	}


	void LocalSocketEvent::Dispatch (LocalSocketEvent* event) {

		if (LocalSocketEvent::callback) {

			if (LocalSocketEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_error = val_id ("error");
					id_id = val_id ("id");
					id_length = val_id ("length");
					id_type = val_id ("type");
					init = true;

				}

				value object = (value)LocalSocketEvent::eventObject->Get ();

				alloc_field (object, id_error, alloc_int (event->error));
				alloc_field (object, id_id, alloc_int (event->id));
				alloc_field (object, id_length, alloc_int (event->length));
				alloc_field (object, id_type, alloc_int (event->type));

			} else {

				LocalSocketEvent* eventObject = (LocalSocketEvent*)LocalSocketEvent::eventObject->Get ();

				eventObject->error = event->error;
				eventObject->id = event->id;
				eventObject->length = event->length;
				eventObject->type = event->type;

			}

			LocalSocketEvent::callback->Call ();

		}

	}


}
