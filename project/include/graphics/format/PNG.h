#ifndef LIME_GRAPHICS_FORMAT_PNG_H
#define LIME_GRAPHICS_FORMAT_PNG_H


#include <graphics/ImageBuffer.h>
#include <utils/Resource.h>


namespace lime {
	
	
	class PNG {
		
		
		public:
			
			static bool Decode (Resource *resource, ImageBuffer *imageBuffer);
		
		
	};
	
	
}


#endif