#include <Sound.h>
#include <Display.h>
#include <Utils.h>


namespace nme
{

class MFSoundChannel : public SoundChannel
{
public:
   MFSoundChannel(Object *inSound, int inHandle, double startTime, int loops, const SoundTransform &inTransform)
   {
      mSound = inSound;
      mSoundHandle = inHandle;
      mLoop = (loops < 1) ? 1 : loops;
      inSound->IncRef();
    }

   ~MFSoundChannel()
   {
      mSound->DecRef();
   }

   bool isComplete()
   {
      return true;
   }

   double getLeft()
   {
      return 0.5;
   }
   
   double getRight()
   {
      return 0.5;
   }

   double getPosition()
   {
      return 0;
   }
   
   double setPosition(const float &inFloat)
   {
      return 0;
   }

   void stop()
   {
   }

   void setTransform(const SoundTransform &inTransform)
   {
   }

   Object *mSound;
   int mStreamID;
   int mSoundHandle;
   int mLoop;
};

SoundChannel *SoundChannel::Create(const ByteArray &inBytes,const SoundTransform &inTransform)
{
   return 0;
}


class MFMusicChannel : public SoundChannel
{
public:
   MFMusicChannel(Object *inSound, const std::string &inPath, double startTime, int loops, const SoundTransform &inTransform)
   {
      mSound = inSound;
      inSound->IncRef();
      mSoundPath = inPath;
    }

   ~MFMusicChannel()
   {
      mSound->DecRef();
   }

   bool isComplete()
   {
      return false;
   }

   double getPosition()
   {
      return -1;
   }
   
   double setPosition(const float &inFloat)
   {
      return 0;
   }

   double getLeft()
   {
      return 0.5;
   }

   double getRight()
   {
      return 0.5;
   }

   void stop()
   {
   }

   void setTransform(const SoundTransform &inTransform)
   {
   }

   Object *mSound;
   int mState;
   std::string mSoundPath;
};


class MFSound : public Sound
{
   enum SoundMode
   {
      MODE_UNKNOWN,
      MODE_SOUND_ID,
      MODE_MUSIC_PATH,
   };
   
public:
   MFSound(const std::string &inPath, bool inForceMusic)
   {
   }
   
   MFSound(float *inData, int len, bool inForceMusic)
   {
   }

   void reloadSound()
   {
   }

   int getBytesLoaded() { return 0; }
   int getBytesTotal() { return 0; }
   bool ok() { return handleID >= 0; }
   std::string getError() { return ok() ? "" : "Error"; }

   double getLength()
   {
      return 0;
   }

   void close()  { }

   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      switch (mMode) {
         case MODE_SOUND_ID:
            return new MFSoundChannel(this, handleID, startTime, loops, inTransform);
            break;
         case MODE_MUSIC_PATH:
         default:
            return new MFMusicChannel(this, mSoundPath, startTime, loops, inTransform);
            break;
      }
   }

   int handleID;
   std::string mSoundPath;
   SoundMode mMode;
};

Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
{
   return new MFSound(inFilename, inForceMusic);
}

Sound *Sound::Create(float *inData, int len, bool inForceMusic)
{
   return new MFSound(inData, len, inForceMusic);
}
}
