#include <graphics/ImageData.h>


namespace lime {

	static int id_data;
	static int id_height;
	static int id_width;
	static bool init = false;

	ImageData::ImageData():width(0), height(0), data(0) { }

	ImageData::~ImageData() {

		delete data;

	}

	value ImageData::Value() {

		if (!init) {

			id_width = val_id ("width");
			id_height = val_id ("height");
			id_data = val_id ("data");
			init = true;

		}

		mValue = alloc_empty_object ();
		alloc_field (mValue, id_width, alloc_int (width));
		alloc_field (mValue, id_height, alloc_int (height));
		alloc_field (mValue, id_data, data->mValue);
		return mValue;

	}

}
