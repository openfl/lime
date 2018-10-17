#ifndef LIME_MEDIA_CODECS_VORBIS_VORBIS_FILE_H
#define LIME_MEDIA_CODECS_VORBIS_VORBIS_FILE_H


#include <utils/Bytes.h>
#include <vorbis/vorbisfile.h>


namespace lime {


	class VorbisFile {


		public:

			static OggVorbis_File* FromBytes (Bytes* bytes);
			static OggVorbis_File* FromFile (const char* path);


	};


}


#endif