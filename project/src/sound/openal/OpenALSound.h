#ifndef INCLUDED_OPENALSOUND_H
#define INCLUDED_OPENALSOUND_H


#if defined(HX_MACOS) || defined(IPHONE)
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#else
#include <AL/al.h>
#include <AL/alc.h>
#endif

#ifdef ANDROID
#include <android_openal_funcs.h>
#include <ByteArray.h>
#endif

#include <Sound.h>
#include <QuickVec.h>
#include <Utils.h>
#include <Audio.h>

#include <vorbis/vorbisfile.h>

typedef unsigned char uint8;

#define STREAM_BUFFER_SIZE (4096 * 4)

namespace nme
{


class OpenALChannel;


   static ALCdevice  *sgDevice = 0;
   static ALCcontext *sgContext = 0;
   static QuickVec<intptr_t> sgOpenChannels;

   static bool openal_is_init = false;

   static bool OpenALInit()
   {
      //LOG_SOUND("Sound.mm OpenALInit()");
      
      if (!openal_is_init)
      {
         openal_is_init = true;
         sgDevice = alcOpenDevice(0); // select the "preferred device"
         if (sgDevice)
         {
            sgContext=alcCreateContext(sgDevice,0);
            alcMakeContextCurrent(sgContext);
         }
         sgOpenChannels = QuickVec<intptr_t>();
      }
      return sgContext;
   }
   
   
   //Ogg specific stream implementation
   class AudioStream_Ogg : public AudioStream {
       
       public:

           void open(const std::string &path, int startTime, int inLoops, const SoundTransform &inTransform);
           void release();
           bool playback();
           bool playing();
           bool update();
           void setTransform(const SoundTransform &inTransform);
           double getPosition();
           double setPosition(const float &inFloat);
           double getLeft();
           double getRight();
           void suspend();
           void resume();
           bool isActive();

       protected:

           bool stream( ALuint buffer );
           void empty();
           void start();
           void check();
           std::string errorString(int code);

       private:

           FILE*           oggFile;
           OggVorbis_File* oggStream;
           vorbis_info*    vorbisInfo;
           vorbis_comment* vorbisComment;

           ALuint buffers[2];
           ALuint source;
           ALenum format;
           
           std::string mPath;
           int mStartTime;
           int mLoops;
           bool mSuspend;
           bool mIsValid;
           
           #ifdef ANDROID
           
           FileInfo mInfo;
           off_t mFilePosition;
           
           static size_t read_func(void* ptr, size_t size, size_t nmemb, void* datasource)
           {
               AudioStream_Ogg *stream = (AudioStream_Ogg*)datasource;
               long pos = ftell(stream->oggFile);
               
               if (pos + size*nmemb > stream->mInfo.length + stream->mInfo.offset)
               {
                  nmemb = 1;
                  size = stream->mInfo.length + stream->mInfo.offset - pos;
                  if (size <= 0)
                  {
                    return 0;
                  }
               }
               
               return fread(ptr, size, nmemb, stream->oggFile);
           }

           static int seek_func(void* datasource, ogg_int64_t offset, int whence)
           {
               AudioStream_Ogg *stream = (AudioStream_Ogg*)datasource;
               long pos = 0;
               
               if (whence == SEEK_SET)
                   pos = stream->mInfo.offset + (unsigned int)offset;
               else if (whence == SEEK_CUR)
                   pos = ftell(stream->oggFile) + (unsigned int)offset;
               else if (whence == SEEK_END)
                   pos = stream->mInfo.offset + stream->mInfo.length;
                
               if (pos > stream->mInfo.offset + stream->mInfo.length) pos = stream->mInfo.offset + stream->mInfo.length;
               return fseek(stream->oggFile, pos, 0);
           }

           static int close_func(void* datasource)
           {
               AudioStream_Ogg *stream = (AudioStream_Ogg*)datasource;
               return fclose(stream->oggFile);
           }

           static long tell_func(void* datasource)
           {
               AudioStream_Ogg *stream = (AudioStream_Ogg*)datasource;
               return (long)ftell(stream->oggFile) - stream->mInfo.offset;
           }
           
           #endif
   };


   class OpenALChannel : public SoundChannel
   {
      public:
         OpenALChannel(Object *inSound, ALuint inBufferID, int startTime, int inLoops, const SoundTransform &inTransform);
         OpenALChannel(Object *inSound, AudioStream *inStream, int startTime, int inLoops, const SoundTransform &inTransform);
         OpenALChannel(const ByteArray &inBytes,const SoundTransform &inTransform);
         void QueueBuffer(ALuint inBuffer, const ByteArray &inBytes);
         void unqueueBuffers();
         bool needsData();
         void addData(const ByteArray &inBytes);
         bool isComplete();
         double getLeft();
         double getRight();
         double setPosition(const float &inFloat);
         double getPosition();
         void setTransform(const SoundTransform &inTransform);
         void stop();
         void suspend();
         void resume();
         
      protected:
         ~OpenALChannel();
         Object *mSound;
         ALuint mSourceID;
         short  *mSampleBuffer;
         bool   mDynamicDone;
         ALuint mDynamicStackSize;
         ALuint mDynamicStack[2];
         ALuint mDynamicBuffer[2];
         AudioStream *mStream;
         int mLength;
         int mSize;
         int mStartTime;
         int mLoops;
         bool mUseStream;
         enum { STEREO_SAMPLES = 2 };
         bool mWasPlaying;
      
   };


   class OpenALSound : public Sound
   {
      public:
         OpenALSound(const std::string &inFilename, bool stream);
         OpenALSound(float *inData, int len);
         double getLength();
         void getID3Value(const std::string &inKey, std::string &outValue);
         int getBytesLoaded();
         int getBytesTotal();
         bool ok();
         std::string getError();
         void close();
         SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform);
         
      protected:
         ~OpenALSound();
         ALint bufferSize;
         ALint frequency;
         ALint bitsPerSample;
         ALint channels;

         ALuint mBufferID;
         bool mIsStream;
         std::string mStreamPath;
         std::string mError;
         
   };
   
   
}


#endif
