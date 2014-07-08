#include <graphics/Image.h>


namespace lime {
	
	
	static int id_data;
	static int id_height;
	static int id_width;
	static bool init = false;
	
	
	Image::Image () {
		
		width = 0;
		height = 0;
		data = 0;
		
	}
	
	
	Image::~Image () {
		
		delete data;
		
	}
	
	
	value Image::Value() {
		
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