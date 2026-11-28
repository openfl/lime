#ifndef LIME_UI_DRAG_DROP_H
#define LIME_UI_DRAG_DROP_H


#include <ui/Window.h>
#include <string>
#include <vector>


namespace lime {


	// Drag and drop between windows and other applications, through native-desktop where Lime has it. The
	// data of a drag over a window is read while its DragEvent is dispatched, in Clipboard's formats.
	class DragDrop {


		public:

			static bool IsSupported ();
			static bool SetTarget (Window* window, bool enabled);

			// items are encoded as for Clipboard::SetItems, and image as width, height and straight RGBA
			// pixels, or null. Returns the action taken, or -1 when a DRAG_COMPLETE event with id follows.
			static int StartDrag (Window* window, const unsigned char* items, int itemsLength, const unsigned char* image, int imageLength, int offsetX, int offsetY, int actions, int id);

			static bool GetFiles (std::vector<std::string>* files);
			static bool GetFormatText (int format, std::string* text);
			static bool GetImage (std::vector<unsigned char>* pixels, int* width, int* height);
			static bool HasFormat (int format);


	};


}


#endif
