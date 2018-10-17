#include <app/ApplicationEvent.h>
#include <system/CFFI.h>


namespace lime {


	ValuePointer* ApplicationEvent::callback = 0;
	ValuePointer* ApplicationEvent::eventObject = 0;

	static int id_deltaTime;
	static int id_type;
	static bool init = false;


	ApplicationEvent::ApplicationEvent () {

		deltaTime = 0;
		type = UPDATE;

	}


	void ApplicationEvent::Dispatch (ApplicationEvent* event) {

		if (ApplicationEvent::callback) {

			if (ApplicationEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_deltaTime = val_id ("deltaTime");
					id_type = val_id ("type");
					init = true;

				}

				value object = (value)ApplicationEvent::eventObject->Get ();

				alloc_field (object, id_deltaTime, alloc_int (event->deltaTime));
				alloc_field (object, id_type, alloc_int (event->type));

			} else {

				ApplicationEvent* eventObject = (ApplicationEvent*)ApplicationEvent::eventObject->Get ();

				eventObject->deltaTime = event->deltaTime;
				eventObject->type = event->type;

			}

			ApplicationEvent::callback->Call ();

		}

	}


}