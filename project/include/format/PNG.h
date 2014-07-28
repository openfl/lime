#ifndef LIME_FORMAT_PNG_H
#define LIME_FORMAT_PNG_H


#include <graphics/Image.h>
#include <utils/Resource.h>


namespace lime {
	
	
	class PNG {
		
		
		public:
			
			static bool Decode (Resource *resource, Image *image);
		
		
	};
	
	
}


#endif