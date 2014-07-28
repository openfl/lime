#ifndef LIME_FORMAT_OGG_H
#define LIME_FORMAT_OGG_H


#include <audio/Sound.h>
#include <utils/Resource.h>


namespace lime {
	
	
	class OGG {
		
		
		public:
			
			static bool Decode (Resource *resource, Sound *sound);
		
		
	};
	
	
}


#endif