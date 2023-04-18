#include <system/DisplayMode.h>


namespace lime {


	static int id_height;
	static int id_pixelFormat;
	static int id_refreshRate;
	static int id_width;
	static bool init = false;


	DisplayMode::DisplayMode () {

		width = 0;
		height = 0;
		pixelFormat = RGBA32;
		refreshRate = 0;

	}


	DisplayMode::DisplayMode (value displayMode) {

		width = val_int (val_field (displayMode, id_width));
		height = val_int (val_field (displayMode, id_height));
		pixelFormat = (PixelFormat)val_int (val_field (displayMode, id_pixelFormat));
		refreshRate = val_int (val_field (displayMode, id_refreshRate));

	}


	DisplayMode::DisplayMode (int _width, int _height, PixelFormat _pixelFormat, int _refreshRate) {

		width = _width;
		height = _height;
		pixelFormat = _pixelFormat;
		refreshRate = _refreshRate;

	}


	void DisplayMode::CopyFrom (DisplayMode* other) {

		height = other->height;
		pixelFormat = other->pixelFormat;
		refreshRate = other->refreshRate;
		width = other->width;

	}


	void* DisplayMode::Value () {

		// if (_mode) {

		// 	_mode->height = height;
		// 	_mode->pixelFormat = pixelFormat;
		// 	_mode->refreshRate = refreshRate;
		// 	_mode->width = width;
		// 	return _mode;

		// } else {

			if (!init) {

				id_height = val_id ("height");
				id_pixelFormat = val_id ("pixelFormat");
				id_refreshRate = val_id ("refreshRate");
				id_width = val_id ("width");
				init = true;

			}

			value displayMode = alloc_empty_object ();
			alloc_field (displayMode, id_height, alloc_int (height));
			alloc_field (displayMode, id_pixelFormat, alloc_int (pixelFormat));
			alloc_field (displayMode, id_refreshRate, alloc_int (refreshRate));
			alloc_field (displayMode, id_width, alloc_int (width));
			return displayMode;

		// }

	}


}