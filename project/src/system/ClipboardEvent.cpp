#include <system/CFFI.h>
#include <system/ClipboardEvent.h>


namespace lime {


	ValuePointer* ClipboardEvent::callback = 0;
	ValuePointer* ClipboardEvent::eventObject = 0;

	static int id_type;
	static bool init = false;


	ClipboardEvent::ClipboardEvent () {

		type = CLIPBOARD_UPDATE;

	}


	void ClipboardEvent::Dispatch (ClipboardEvent* event) {

		if (ClipboardEvent::callback) {

			if (ClipboardEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_type = val_id ("type");
					init = true;

				}

				value object = (value)ClipboardEvent::eventObject->Get ();

				alloc_field (object, id_type, alloc_int (event->type));

			} else {

				ClipboardEvent* eventObject = (ClipboardEvent*)ClipboardEvent::eventObject->Get ();

				eventObject->type = event->type;

			}

			ClipboardEvent::callback->Call ();

		}

	}


}