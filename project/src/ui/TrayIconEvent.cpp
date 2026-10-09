#include <system/CFFI.h>
#include <ui/TrayIconEvent.h>


namespace lime {


	ValuePointer* TrayIconEvent::callback = 0;
	ValuePointer* TrayIconEvent::eventObject = 0;

	static int id_id;
	static int id_itemID;
	static int id_type;
	static bool init = false;


	TrayIconEvent::TrayIconEvent () {

		id = 0;
		itemID = 0;
		type = TRAY_ICON_CLICK;

	}


	void TrayIconEvent::Dispatch (TrayIconEvent* event) {

		if (TrayIconEvent::callback) {

			if (TrayIconEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_id = val_id ("id");
					id_itemID = val_id ("itemID");
					id_type = val_id ("type");
					init = true;

				}

				value object = (value)TrayIconEvent::eventObject->Get ();

				alloc_field (object, id_id, alloc_int (event->id));
				alloc_field (object, id_itemID, alloc_int (event->itemID));
				alloc_field (object, id_type, alloc_int (event->type));

			} else {

				TrayIconEvent* eventObject = (TrayIconEvent*)TrayIconEvent::eventObject->Get ();

				eventObject->id = event->id;
				eventObject->itemID = event->itemID;
				eventObject->type = event->type;

			}

			TrayIconEvent::callback->Call ();

		}

	}


}
