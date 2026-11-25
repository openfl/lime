#ifndef LIME_UI_MENU_H
#define LIME_UI_MENU_H


#include <vector>


namespace lime {


	enum MenuSupport {

		MENU_SUPPORT_POPUP = 0x01,
		MENU_SUPPORT_WINDOW = 0x02,
		MENU_SUPPORT_APPLICATION = 0x04

	};


	class Menu {

		public:

			static bool GetApplicationMenu (std::vector<unsigned char>* data);
			static int GetSupport ();

			// The callback runs as a menu opens, before it is shown. It reads the
			// menu with GetOpenEvent, and may replace its items with SetOpenItems.
			static void GetOpenEvent (int* target, int* menu, int* source);
			static void SetOpenCallback (void (*callback) ());
			static void SetOpenItems (const unsigned char* data, int length);

	};


}


#endif
