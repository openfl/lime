#ifndef LIME_UI_KEY_CODE_H
#define LIME_UI_KEY_CODE_H


#include <system/System.h>


namespace lime {


	class KeyCode {

		public:

			static int32_t FromScanCode (int32_t keyCode);
			static int32_t ToScanCode (int32_t keyCode);

	};


}


#endif