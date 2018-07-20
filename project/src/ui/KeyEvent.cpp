#include <system/CFFI.h>
#include <ui/KeyEvent.h>


namespace lime {


	ValuePointer* KeyEvent::callback = 0;
	ValuePointer* KeyEvent::eventObject = 0;

	static double id_keyCode;
	static int id_modifier;
	static int id_type;
	static int id_windowID;
	static bool init = false;


	KeyEvent::KeyEvent () {

		keyCode = 0;
		modifier = 0;
		type = KEY_DOWN;
		windowID = 0;

	}


	void KeyEvent::Dispatch (KeyEvent* event) {

		if (KeyEvent::callback) {

			if (KeyEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_keyCode = val_id ("keyCode");
					id_modifier = val_id ("modifier");
					id_type = val_id ("type");
					id_windowID = val_id ("windowID");
					init = true;

				}

				value object = (value)KeyEvent::eventObject->Get ();

				alloc_field (object, id_keyCode, alloc_float (event->keyCode));
				alloc_field (object, id_modifier, alloc_int (event->modifier));
				alloc_field (object, id_type, alloc_int (event->type));
				alloc_field (object, id_windowID, alloc_int (event->windowID));

			} else {

				KeyEvent* eventObject = (KeyEvent*)KeyEvent::eventObject->Get ();

				eventObject->keyCode = event->keyCode;
				eventObject->modifier = event->modifier;
				eventObject->type = event->type;
				eventObject->windowID = event->windowID;

			}

			KeyEvent::callback->Call ();

		}

	}


}