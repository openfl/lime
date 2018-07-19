#include <graphics/RenderEvent.h>
#include <system/CFFI.h>


namespace lime {


	ValuePointer* RenderEvent::callback = 0;
	ValuePointer* RenderEvent::eventObject = 0;

	static int id_type;
	static bool init = false;


	RenderEvent::RenderEvent () {

		type = RENDER;

	}


	void RenderEvent::Dispatch (RenderEvent* event) {

		if (RenderEvent::callback) {

			if (RenderEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_type = val_id ("type");

				}

				value object = (value)RenderEvent::eventObject->Get ();

				alloc_field (object, id_type, alloc_int (event->type));

			} else {

				RenderEvent* eventObject = (RenderEvent*)RenderEvent::eventObject->Get ();

				eventObject->type = event->type;

			}

			RenderEvent::callback->Call ();

		}

	}


}