#ifndef LIME_GRAPHICS_IMAGE_DATA_H
#define LIME_GRAPHICS_IMAGE_DATA_H

#include <hx/CFFI.h>
#include <utils/ByteArray.h>


namespace lime {
	
	
	class ImageData {

	public:
		
		int width;
		int height;
		ByteArray *data;

		ImageData();
		~ImageData();
		value Value();

	private:

		value mValue;
		
	};
	
	
}


#endif