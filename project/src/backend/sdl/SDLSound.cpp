#include <Sound.h>
#include <Display.h>
#include <SDL.h>
#include <SDL_mixer.h>

#include <hx/Thread.h>


namespace nme
{

bool gSDLIsInit = false;

class SDLSoundChannel;

bool sChannelsInit = false;
enum { sMaxChannels = 8 };

bool sUsedChannel[sMaxChannels];
bool sDoneChannel[sMaxChannels];
void *sUsedMusic = 0;
bool sDoneMusic = false;
enum { STEREO_SAMPLES = 2 };

unsigned int  sSoundPos = 0;

void onChannelDone(int inChannel)
{
   if (sUsedChannel[inChannel])
      sDoneChannel[inChannel] = true;
}

void onMusicDone()
{
   if (sUsedMusic)
      sDoneMusic = true;
}

void  onPostMix(void *udata, Uint8 *stream, int len)
{
   sSoundPos += len / sizeof(short) / STEREO_SAMPLES ;
}


static bool Init()
{
   if (!gSDLIsInit)
   {
      ELOG("Please init Stage before creating sound.");
      return false;
   }

   if (!sChannelsInit)
   {
      sChannelsInit = true;
      for(int i=0;i<sMaxChannels;i++)
      {
         sUsedChannel[i] = false;
         sDoneChannel[i] = false;
      }
      Mix_ChannelFinished(onChannelDone);
      Mix_HookMusicFinished(onMusicDone);
      #ifndef EMSCRIPTEN
      Mix_SetPostMix(onPostMix,0);
      #endif
   }

   return sChannelsInit;
}

// ---  Using "Mix_Chunk" API ----------------------------------------------------


class SDLSoundChannel : public SoundChannel
{
  enum { BUF_SIZE = (1<<17) };

public:
   SDLSoundChannel(Object *inSound, Mix_Chunk *inChunk, double inStartTime, int inLoops,
                  const SoundTransform &inTransform)
   {
      mChunk = inChunk;
      mDynamicBuffer = 0;
      mSound = inSound;
      mSound->IncRef();

      mChannel = -1;

      // Allocate myself a channel
      if (mChunk)
      {
         for(int i=0;i<sMaxChannels;i++)
            if (!sUsedChannel[i])
            {
               IncRef();
               sDoneChannel[i] = false;
               sUsedChannel[i] = true;
               mChannel = i;
               break;
            }
      }

      if (mChannel>=0)
      {
         Mix_PlayChannel( mChannel , mChunk, inLoops<0 ? -1 : inLoops==0 ? 0 : inLoops-1 );
         Mix_Volume( mChannel, inTransform.volume*MIX_MAX_VOLUME );
         // Mix_SetPanning
      }
   }

   SDLSoundChannel(const ByteArray &inBytes, const SoundTransform &inTransform)
   {
      Mix_QuerySpec(&mFrequency, &mFormat, &mChannels);
      if (mFrequency!=44100)
         ELOG("Warning - Frequency mismatch %d",mFrequency);
      if (mFormat!=32784)
         ELOG("Warning - Format mismatch    %d",mFormat);
      if (mChannels!=2)
         ELOG("Warning - channe mismatch    %d",mChannels);


      mChunk = 0;
      mDynamicBuffer = new short[BUF_SIZE * STEREO_SAMPLES];
      memset(mDynamicBuffer,0,BUF_SIZE*sizeof(short));
      mSound = 0;
      mChannel = -1;
      mDynamicChunk.allocated = 0;
      mDynamicChunk.abuf = (Uint8 *)mDynamicBuffer;
      mDynamicChunk.alen = BUF_SIZE * sizeof(short) * STEREO_SAMPLES; // bytes
      mDynamicChunk.volume = MIX_MAX_VOLUME;
      mDynamicFillPos = 0;
      mDynamicStartPos = 0;
      mDynamicDataDue = 0;

      // Allocate myself a channel
      for(int i=0;i<sMaxChannels;i++)
         if (!sUsedChannel[i])
         {
            IncRef();
            sDoneChannel[i] = false;
            sUsedChannel[i] = true;
            mChannel = i;
            break;
         }

      if (mChannel>=0)
      {
         FillBuffer(inBytes);
         // Just once ...
         if (mDynamicFillPos<1024)
         {
            mDynamicDone = true;
            mDynamicChunk.alen = mDynamicFillPos * sizeof(short) * STEREO_SAMPLES;
            Mix_PlayChannel( mChannel , &mDynamicChunk,  0 );
         }
         else
         {
            mDynamicDone = false;
            // TODO: Lock?
            Mix_PlayChannel( mChannel , &mDynamicChunk,  -1 );
            mDynamicStartPos = sSoundPos;
         }

         Mix_Volume( mChannel, inTransform.volume*MIX_MAX_VOLUME );
      }
   }

   void FillBuffer(const ByteArray &inBytes)
   {
      int time_samples = inBytes.Size()/sizeof(float)/STEREO_SAMPLES;
      const float *buffer = (const float *)inBytes.Bytes();
      enum { MASK = BUF_SIZE - 1 };

      for(int i=0;i<time_samples;i++)
      {
         int mono_pos =  (i+mDynamicFillPos) & MASK;
         mDynamicBuffer[ mono_pos<<1 ] = *buffer++ * ((1<<15)-1);
         mDynamicBuffer[ (mono_pos<<1) + 1 ] = *buffer++ * ((1<<15)-1);
      }

      if (mDynamicFillPos<(sSoundPos-mDynamicStartPos))
         ELOG("Too slow - FillBuffer %d / %d)", mDynamicFillPos, (sSoundPos-mDynamicStartPos) );
      mDynamicFillPos += time_samples;
      if (time_samples<1024 && !mDynamicDone)
      {
         mDynamicDone = true;
         for(int i=0;i<2048;i++)
         {
            int mono_pos =  (i+mDynamicFillPos) & MASK;
            mDynamicBuffer[ mono_pos<<1 ] = 0;
            mDynamicBuffer[ (mono_pos<<1) + 1 ] = 0;
         }
            
         int samples_left = (int)mDynamicFillPos - (int)(sSoundPos-mDynamicStartPos);
         int ticks_left = samples_left*1000/44100;
         //printf("Expire in %d (%d)\n", samples_left, ticks_left );
		 #ifndef EMSCRIPTEN
         Mix_ExpireChannel(mChannel, ticks_left>0 ? ticks_left : 1 );
		 #endif
      }
   }
 
   ~SDLSoundChannel()
   {
      delete [] mDynamicBuffer;

      if (mSound)
         mSound->DecRef();
   }

   void CheckDone()
   {
      if (mChannel>=0 && sDoneChannel[mChannel])
      {
         sDoneChannel[mChannel] = false;
         int c = mChannel;
         mChannel = -1;
         DecRef();
         sUsedChannel[c] = 0;
      }
   }

   bool isComplete()
   {
      CheckDone();
      return mChannel < 0;
   }
   double getLeft() { return 1; }
   double getRight() { return 1; }
   double getPosition() { return 1; }
   double setPosition(const float &inFloat) { return 1; }
   void stop() 
   {
      if (mChannel>=0)
         Mix_HaltChannel(mChannel);
      
      CheckDone();
   }
   void setTransform(const SoundTransform &inTransform) 
   {
      if (mChannel>=0)
         Mix_Volume( mChannel, inTransform.volume*MIX_MAX_VOLUME );
   }

   double getDataPosition()
   {
      return (sSoundPos-mDynamicStartPos)*1000.0/mFrequency;
   }
   bool needsData()
   {
      if (!mDynamicBuffer || mDynamicDone)
         return false;

      if (mDynamicDataDue<=sSoundPos)
      {
         mDynamicDone = true;
         return true;
      }

      return false;

   }

   void addData(const ByteArray &inBytes)
   {
      mDynamicDone = false;
      mDynamicDataDue = mDynamicFillPos + mDynamicStartPos;
      FillBuffer(inBytes);
   }


   Object    *mSound;
   Mix_Chunk *mChunk;
   int       mChannel;

   Mix_Chunk mDynamicChunk;
   short    *mDynamicBuffer;
   unsigned int  mDynamicFillPos;
   unsigned int  mDynamicStartPos;
   unsigned int  mDynamicDataDue;
   bool      mDynamicDone;
   int       mFrequency;
   Uint16    mFormat;
   int       mChannels;
};

SoundChannel *SoundChannel::Create(const ByteArray &inBytes,const SoundTransform &inTransform)
{
   if (!Init())
      return 0;
   return new SDLSoundChannel(inBytes,inTransform);
}



class SDLSound : public Sound
{
public:
   SDLSound(const std::string &inFilename)
   {
      IncRef();

      #ifdef HX_MACOS
      char name[1024];
      GetBundleFilename(inFilename.c_str(),name,1024);
      #else
      const char *name = inFilename.c_str();
      #endif

      mChunk = Mix_LoadWAV(name);
      if ( mChunk == NULL )
      {
         mError = SDL_GetError();
         // ELOG("Error %s (%s)", mError.c_str(), name );
      }
   }
   
   SDLSound(float *inData, int len)
   {
      IncRef();
      
      #ifndef EMSCRIPTEN
      mChunk = Mix_LoadWAV_RW(SDL_RWFromMem(inData, len), 1);
      if ( mChunk == NULL )
      {
         mError = SDL_GetError();
         // ELOG("Error %s (%s)", mError.c_str(), name );
      }
      #endif
   }
   
   ~SDLSound()
   {
      if (mChunk)
         Mix_FreeChunk( mChunk );
   }
   double getLength()
   {
      if (mChunk==0) return 0;
      #if defined(DYNAMIC_SDL) || defined(WEBOS)
      // ?
      return 0.0;
      #else
	  return 0.0;
      #endif
   }
   // Will return with one ref...
   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      if (!mChunk)
         return 0;
      return new SDLSoundChannel(this,mChunk,startTime, loops,inTransform);
   }
   int getBytesLoaded() { return mChunk ? mChunk->alen : 0; }
   int getBytesTotal() { return mChunk ? mChunk->alen : 0; }
   bool ok() { return mChunk; }
   std::string getError() { return mError; }


   std::string mError;
   Mix_Chunk *mChunk;
};

// ---  Using "Mix_Music" API ----------------------------------------------------


class SDLMusicChannel : public SoundChannel
{
public:
   SDLMusicChannel(Object *inSound, Mix_Music *inMusic, double inStartTime, int inLoops,
                  const SoundTransform &inTransform)
   {
      mMusic = inMusic;
      mSound = inSound;
      mSound->IncRef();

      mPlaying = false;
      if (mMusic)
      {
         mPlaying = true;
         sUsedMusic = this;
         sDoneMusic = false;
		 mStartTime = SDL_GetTicks ();
		 mLength = 0;
         IncRef();
         Mix_PlayMusic( mMusic, inLoops<0 ? -1 : inLoops==0 ? 0 : inLoops-1 );
         Mix_VolumeMusic( inTransform.volume*MIX_MAX_VOLUME );
         if (inStartTime > 0)
		 {
			 // this is causing crash errors
			 
			 //Mix_RewindMusic();
			 //int seconds = inStartTime / 1000;
			 //Mix_SetMusicPosition(seconds); 
			 //mStartTime = SDL_GetTicks () - inStartTime;
		 }
         // Mix_SetPanning not available for music
      }
   }
   ~SDLMusicChannel()
   {
      mSound->DecRef();
   }

   void CheckDone()
   {
      if (mPlaying && (sDoneMusic || (sUsedMusic!=this)) )
      {
		 mLength = SDL_GetTicks () - mStartTime;
         mPlaying = false;
         if (sUsedMusic == this)
         {
            sUsedMusic = 0;
            sDoneMusic = false;
         }
         DecRef();
      }
   }

   bool isComplete()
   {
      CheckDone();
      return !mPlaying;
   }
   double getLeft() { return 1; }
   double getRight() { return 1; }
   double getPosition() { return mPlaying ? SDL_GetTicks() - mStartTime : mLength; }
   double setPosition(const float &inFloat) { return 1; }

   void stop() 
   {
      if (mMusic)
         Mix_HaltMusic();
   }
   void setTransform(const SoundTransform &inTransform) 
   {
      if (mMusic>=0)
         Mix_VolumeMusic( inTransform.volume*MIX_MAX_VOLUME );
   }

   bool      mPlaying;
   Object    *mSound;
   int       mStartTime;
   int       mLength;
   Mix_Music *mMusic;
};


class SDLMusic : public Sound
{
public:
   SDLMusic(const std::string &inFilename)
   {
      IncRef();

      #ifdef HX_MACOS
      char name[1024];
      GetBundleFilename(inFilename.c_str(),name,1024);
      #else
      const char *name = inFilename.c_str();
      #endif

      mMusic = Mix_LoadMUS(name);
      if ( mMusic == NULL )
      {
         mError = SDL_GetError();
         ELOG("Error in music %s (%s)", mError.c_str(), name );
      }
   }
   
   SDLMusic(float *inData, int len)
   {
      IncRef();
      
      #ifndef EMSCRIPTEN
      mMusic = Mix_LoadMUS_RW(SDL_RWFromMem(inData, len));
      if ( mMusic == NULL )
      {
         mError = SDL_GetError();
         ELOG("Error in music with len (%d)", len );
      }
      #endif
   }
   ~SDLMusic()
   {
      if (mMusic)
         Mix_FreeMusic( mMusic );
   }
   double getLength()
   {
      if (mMusic==0) return 0;
      // TODO:
      return 60000;
   }
   // Will return with one ref...
   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      if (!mMusic)
         return 0;
      return new SDLMusicChannel(this,mMusic,startTime, loops,inTransform);
   }
   int getBytesLoaded() { return mMusic ? 100 : 0; }
   int getBytesTotal() { return mMusic ? 100 : 0; }
   bool ok() { return mMusic; }
   std::string getError() { return mError; }


   std::string mError;
   Mix_Music *mMusic;
};

// --- External Interface -----------------------------------------------------------


Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
{
   if (!Init())
      return 0;
   Sound *sound = inForceMusic ? 0 :  new SDLSound(inFilename);
   if (!sound || !sound->ok())
   {
      if (sound) sound->DecRef();
      sound = new SDLMusic(inFilename);
   }
   return sound;
}

Sound *Sound::Create(float *inData, int len, bool inForceMusic) {
   if (!Init())
      return 0;
   Sound *sound = inForceMusic ? 0 :  new SDLSound(inData, len);
   if (!sound || !sound->ok())
   {
      if (sound) sound->DecRef();
      sound = new SDLMusic(inData, len);
   }
   return sound;
}


}
