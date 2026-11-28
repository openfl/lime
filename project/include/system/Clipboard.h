#ifndef LIME_SYSTEM_CLIPBOARD_H
#define LIME_SYSTEM_CLIPBOARD_H

#include <string>
#include <vector>


namespace lime {


	class Clipboard {


		public:

			static const char* GetText ();
			static bool HasText ();
			static bool SetText (const char* text);

			// Formats beyond text, from native-desktop where Lime has it. Images are straight RGBA, top row
			// first. SetItems reads little-endian Int32 values: count, then for each item its format and
			// either length and UTF-8 text, a count of files each with length and UTF-8 path, or width,
			// height and the pixels.
			static bool GetFiles (std::vector<std::string>* files);
			static bool GetFormatText (int format, std::string* text);
			static bool GetImage (std::vector<unsigned char>* pixels, int* width, int* height);
			static bool HasFormat (int format);
			static bool SetItems (const unsigned char* data, int length);

			// Whether text goes through native-desktop's clipboard as well, as on Linux with GTK, where
			// SDL's X11 clipboard and GTK's are two owners in one process that don't answer each other
			// while either waits for the clipboard. SetDesktopText replaces the clipboard with the text.
			static bool HasDesktopText ();
			static bool SetDesktopText (const char* text);


	};


}


#endif