#ifndef LIME_GRAPHICS_FORMAT_JPEG_H
#define LIME_GRAPHICS_FORMAT_JPEG_H


#include <graphics/ImageBuffer.h>
#include <utils/Bytes.h>
#include <utils/Resource.h>


namespace lime {


	class JPEG {


		public:

			static bool Decode (Resource *resource, ImageBuffer *imageBuffer, bool decodeData = true);
			static bool Encode (ImageBuffer *imageBuffer, Bytes *bytes, int quality);


	};


}


#endif