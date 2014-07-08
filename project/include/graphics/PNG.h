#ifndef LIME_GRAPHICS_PNG_H
#define LIME_GRAPHICS_PNG_H


namespace lime {
	
	
	class Image;
	
	class PNG {
		
		
		public:
			
			static bool Decode (const char *path, Image *image);
		
		
	};
	
	
}


#endif