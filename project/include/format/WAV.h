#ifndef LIME_FORMAT_WAV_H
#define LIME_FORMAT_WAV_H


#include <audio/Sound.h>
#include <utils/Resource.h>


namespace lime {
	
	
	class WAV {
		
		
		public:
			
			static bool Decode (Resource *resource, Sound *sound);
		
		
	};
	
	
}


#endif