#ifndef LIME_SYSTEM_CLIPBOARD_H
#define LIME_SYSTEM_CLIPBOARD_H


namespace lime {


	class Clipboard {


		public:

			static const char* GetText ();
			static bool HasText ();
			static void SetText (const char* text);


	};


}


#endif