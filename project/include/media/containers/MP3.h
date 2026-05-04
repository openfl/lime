#ifndef LIME_MEDIA_CONTAINERS_MP3_H
#define LIME_MEDIA_CONTAINERS_MP3_H

#include <media/AudioBuffer.h>
#include <utils/Resource.h>

namespace lime {

    class MP3 {

        public:

            static bool Decode (Resource *resource, AudioBuffer *audioBuffer);

    };

}

#endif