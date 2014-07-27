#ifndef LIME_GRAPHICS_JPEG_H
#define LIME_GRAPHICS_JPEG_H


#include <graphics/Image.h>
#include <io/Resource.h>


namespace lime {
	
	
	class JPEG {
		
		
		public:
			
			static bool Decode (Resource *resource, Image *image);
		
		
	};
	
	
}


#endif