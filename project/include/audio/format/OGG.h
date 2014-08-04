#ifndef LIME_AUDIO_FORMAT_OGG_H
#define LIME_AUDIO_FORMAT_OGG_H


#include <audio/AudioBuffer.h>
#include <utils/Resource.h>


namespace lime {
	
	
	class OGG {
		
		
		public:
			
			static bool Decode (Resource *resource, AudioBuffer *audioBuffer);
		
		
	};
	
	
}


#endif