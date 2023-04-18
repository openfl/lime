#include <system/CFFI.h>
#include <ui/TextEvent.h>


namespace lime {


	ValuePointer* TextEvent::callback = 0;
	ValuePointer* TextEvent::eventObject = 0;

	static int id_length;
	static int id_start;
	static int id_text;
	static int id_type;
	static int id_windowID;
	static bool init = false;


	TextEvent::TextEvent () {

		length = 0;
		start = 0;
		text = 0;
		windowID = 0;

	}


	void TextEvent::Dispatch (TextEvent* event) {

		if (TextEvent::callback) {

			if (TextEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_length = val_id ("length");
					id_start = val_id ("start");
					id_text = val_id ("text");
					id_type = val_id ("type");
					id_windowID = val_id ("windowID");
					init = true;

				}

				value object = (value)TextEvent::eventObject->Get ();

				if (event->type != TEXT_INPUT) {

					alloc_field (object, id_length, alloc_int (event->length));
					alloc_field (object, id_start, alloc_int (event->start));

				}

				alloc_field (object, id_text, alloc_string ((const char*)event->text));
				alloc_field (object, id_type, alloc_int (event->type));
				alloc_field (object, id_windowID, alloc_int (event->windowID));

			} else {

				TextEvent* eventObject = (TextEvent*)TextEvent::eventObject->Get ();

				if (event->type != TEXT_INPUT) {

					eventObject->length = event->length;
					eventObject->start = event->start;

				}

				int length = strlen ((const char*)event->text);
				char* text = (char*)malloc (length + 1);
				strcpy (text, (const char*)event->text);
				eventObject->text = (vbyte*)text;
				eventObject->type = event->type;
				eventObject->windowID = event->windowID;

			}

			TextEvent::callback->Call ();

		}

	}


}