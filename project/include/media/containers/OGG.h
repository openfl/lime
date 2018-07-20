#ifndef LIME_MEDIA_CONTAINERS_OGG_H
#define LIME_MEDIA_CONTAINERS_OGG_H


#include <media/AudioBuffer.h>
#include <utils/Resource.h>


namespace lime {


	class OGG {


		public:

			static bool Decode (Resource *resource, AudioBuffer *audioBuffer);


	};


}


#endif