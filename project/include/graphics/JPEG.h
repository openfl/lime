#ifndef LIME_GRAPHICS_JPEG_H
#define LIME_GRAPHICS_JPEG_H


namespace lime {
	
	
	class Image;
	
	class JPEG {


		public:

			static bool Decode (const char *path, Image *image);


	};


}


#endif
