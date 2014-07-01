#ifndef LIME_GRAPHICS_JPEG_H
#define LIME_GRAPHICS_JPEG_H


namespace lime {

	class ImageData;

	class JPEG {


		public:

			static bool Decode (const char *path, ImageData *imageData);


	};


}


#endif
