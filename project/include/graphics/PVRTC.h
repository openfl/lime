#ifndef LIME_GRAPHICS_PVRTC_H
#define LIME_GRAPHICS_PVRTC_H


namespace lime {

	class ImageData;

	class PVRTC {


		public:

			static bool Decode (const char *path, ImageData *imageData);


	};


}


#endif
