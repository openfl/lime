#include <system/CFFI.h>
#include <ui/MenuEvent.h>


namespace lime {


	ValuePointer* MenuEvent::callback = 0;
	ValuePointer* MenuEvent::eventObject = 0;

	static int id_id;
	static int id_type;
	static int id_windowID;
	static bool init = false;


	MenuEvent::MenuEvent () {

		id = 0;
		type = MENU_SELECT;
		windowID = 0;

	}


	void MenuEvent::Dispatch (MenuEvent* event) {

		if (MenuEvent::callback) {

			if (MenuEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_id = val_id ("id");
					id_type = val_id ("type");
					id_windowID = val_id ("windowID");
					init = true;

				}

				value object = (value)MenuEvent::eventObject->Get ();

				alloc_field (object, id_id, alloc_int (event->id));
				alloc_field (object, id_type, alloc_int (event->type));
				alloc_field (object, id_windowID, alloc_int (event->windowID));

			} else {

				MenuEvent* eventObject = (MenuEvent*)MenuEvent::eventObject->Get ();

				eventObject->id = event->id;
				eventObject->type = event->type;
				eventObject->windowID = event->windowID;

			}

			MenuEvent::callback->Call ();

		}

	}


}
