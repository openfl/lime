#ifndef LIME_MEDIA_FORMAT_JPEG_H
#define LIME_MEDIA_FORMAT_JPEG_H


#include <media/Image.h>
#include <utils/Resource.h>


namespace lime {
	
	
	class JPEG {
		
		
		public:
			
			static bool Decode (Resource *resource, Image *image);
		
		
	};
	
	
}


#endif