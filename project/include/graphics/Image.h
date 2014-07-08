#ifndef LIME_GRAPHICS_IMAGE_H
#define LIME_GRAPHICS_IMAGE_H


#include <hx/CFFI.h>
#include <utils/ByteArray.h>


namespace lime {
	
	
	class Image {
		
		
		public:
			
			Image ();
			~Image ();
			
			value Value ();
			
			int width;
			int height;
			ByteArray *data;
		
		
		private:
			
			value mValue;
		
		
	};
	
	
}


#endif