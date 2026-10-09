#ifndef LIME_UI_MENU_H
#define LIME_UI_MENU_H


namespace lime {


	enum MenuSupport {

		MENU_SUPPORT_POPUP = 0x01,
		MENU_SUPPORT_WINDOW = 0x02,
		MENU_SUPPORT_APPLICATION = 0x04

	};


	class Menu {

		public:

			static int GetSupport ();

	};


}


#endif
