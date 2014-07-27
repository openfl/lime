#ifndef LIME_GRAPHICS_PNG_H
#define LIME_GRAPHICS_PNG_H


#include <graphics/Image.h>
#include <io/Resource.h>


namespace lime {
	
	
	class PNG {
		
		
		public:
			
			static bool Decode (Resource *resource, Image *image);
		
		
	};
	
	
}


#endif