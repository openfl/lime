#include <system/CFFI.h>
#include <ui/DropEvent.h>


namespace lime {


	ValuePointer* DropEvent::callback = 0;
	ValuePointer* DropEvent::eventObject = 0;

	static int id_file;
	static int id_type;
	static int id_windowID;
	static bool init = false;


	DropEvent::DropEvent () {

		file = 0;
		type = DROP_FILE;
		windowID = 0;

	}


	void DropEvent::Dispatch (DropEvent* event) {

		if (DropEvent::callback) {

			if (DropEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_file = val_id ("file");
					id_type = val_id ("type");
					id_windowID = val_id ("windowID");
					init = true;

				}

				value object = (value)DropEvent::eventObject->Get ();

				// Begin and complete events carry no file or text
				alloc_field (object, id_file, alloc_string (event->file ? (const char*)event->file : ""));
				alloc_field (object, id_type, alloc_int (event->type));
				alloc_field (object, id_windowID, alloc_int (event->windowID));

			} else {

				DropEvent* eventObject = (DropEvent*)DropEvent::eventObject->Get ();

				const char* text = event->file ? (const char*)event->file : "";
				int length = strlen (text);
				char* file = (char*)malloc (length + 1);
				strcpy (file, text);

				// The previous copy was read in its own dispatch
				if (eventObject->file) free (eventObject->file);
				eventObject->file = (vbyte*)file;
				eventObject->type = event->type;
				eventObject->windowID = event->windowID;

			}

			DropEvent::callback->Call ();

		}

	}


}