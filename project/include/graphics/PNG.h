#ifndef LIME_GRAPHICS_PNG_H
#define LIME_GRAPHICS_PNG_H


#include <graphics/ImageData.h>
#include <utils/ByteArray.h>


namespace lime {
	
	
	class PNG {
		
		
		public:
			
			static void Decode (ByteArray bytes, value imageData);
		
		
	};
	
	
}


#endif