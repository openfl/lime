#include "OpenALSound.h"

#include <math.h>

namespace lime
{
   
   OpenALChannel::OpenALChannel(Object *inSound, ALuint inBufferID, int startTime, int inLoops, const SoundTransform &inTransform)
   {
      //LOG_SOUND("OpenALChannel constructor %d",inBufferID);
      mSound = inSound;
      inSound->IncRef();
      mSourceID = 0;
      mDynamicDone = true;
      mDynamicBuffer[0] = 0;
      mDynamicBuffer[1] = 0;
      mDynamicStackSize = 0;
      mWasPlaying = false;
      mSampleBuffer = 0;
      float seek = 0;
      mSize = 0;
      mStream = 0;
      mUseStream = false;
      
      mStartTime = startTime;
      mLoops = inLoops;
      
      if (inBufferID>0)
      {
         // grab a source ID from openAL
         alGenSources(1, &mSourceID);
         
         //if (inLoops < 1)
         //{
            // attach the buffer to the source
            alSourcei(mSourceID, AL_BUFFER, inBufferID);
         /*}
         else
         {
            for (int i = 0; i <= inLoops; i++)
            {
               alSourceQueueBuffers(mSourceID, 1, &inBufferID);
            }
         }*/
         
         // set some basic source prefs
         alSourcef(mSourceID, AL_PITCH, 1.0f);
         alSourcef(mSourceID, AL_GAIN, inTransform.volume);
         alSource3f(mSourceID, AL_POSITION, (float) cos((inTransform.pan - 1) * (1.5707)), 0, (float) sin((inTransform.pan + 1) * (1.5707)));

         // TODO: not right!
         //if (inLoops>1)
            //alSourcei(mSourceID, AL_LOOPING, AL_TRUE);
         
         if (startTime > 0)
         {
            ALint bits, channels, freq;
            alGetBufferi(inBufferID, AL_SIZE, &mSize);
            alGetBufferi(inBufferID, AL_BITS, &bits);
            alGetBufferi(inBufferID, AL_CHANNELS, &channels);
            alGetBufferi(inBufferID, AL_FREQUENCY, &freq);
            mLength = (ALfloat)((ALuint)mSize/channels/(bits/8)) / (ALfloat)freq;
            seek = (startTime * 0.001) / mLength;
         }
         
         if (seek < 1)
         {
            //alSourceQueueBuffers(mSourceID, 1, &inBufferID);
            alSourcePlay(mSourceID);
            alSourcef(mSourceID, AL_BYTE_OFFSET, seek * mSize);
         }
         
         mWasPlaying = true;
         sgOpenChannels.push_back((intptr_t)this);
      }
   }
   
   
   OpenALChannel::OpenALChannel(Object *inSound, AudioStream *inStream, int startTime, int inLoops, const SoundTransform &inTransform)
   {
      mSound = inSound;
      inSound->IncRef();
      mSourceID = 0;
      mDynamicDone = true;
      mDynamicBuffer[0] = 0;
      mDynamicBuffer[1] = 0;
      mDynamicStackSize = 0;
      mWasPlaying = false;
      mSampleBuffer = 0;
      float seek = 0;
      int size = 0;
      
      mStartTime = startTime;
      mLoops = inLoops;
      
      mStream = inStream;
      mUseStream = true;
      
      if (mStream)
      {
         //mStream->update();
         mStream->playback();
      }
      
      mWasPlaying = true;
      sgOpenChannels.push_back((intptr_t)this);
   }
   
   
   OpenALChannel::OpenALChannel(const ByteArray &inBytes,const SoundTransform &inTransform)
   {
      //LOG_SOUND("OpenALChannel dynamic %d",inBytes.Size());
      mSound = 0;
      mSourceID = 0;
      mUseStream = false;
      
      mDynamicBuffer[0] = 0;
      mDynamicBuffer[1] = 0;
      mDynamicStackSize = 0;
      mSampleBuffer = 0;
      mWasPlaying = true;
      mStream = 0;
      
      alGenBuffers(2, mDynamicBuffer);
      if (!mDynamicBuffer[0])
      {
         //LOG_SOUND("Error creating dynamic sound buffer!");
      }
      else
      {
         mSampleBuffer = new short[8192*STEREO_SAMPLES];
         
         // grab a source ID from openAL
         alGenSources(1, &mSourceID); 
         
         QueueBuffer(mDynamicBuffer[0],inBytes);
         
         if (!mDynamicDone)
            mDynamicStack[mDynamicStackSize++] = mDynamicBuffer[1];
         
         // set some basic source prefs
         alSourcef(mSourceID, AL_PITCH, 1.0f);
         alSourcef(mSourceID, AL_GAIN, inTransform.volume);
         alSource3f(mSourceID, AL_POSITION, (float) cos((inTransform.pan - 1) * (1.5707)), 0, (float) sin((inTransform.pan + 1) * (1.5707)));
         
         alSourcePlay(mSourceID);
      }
      
      //sgOpenChannels.push_back((intptr_t)this);
   }
   
   
   void OpenALChannel::QueueBuffer(ALuint inBuffer, const ByteArray &inBytes)
   {
      int time_samples = inBytes.Size()/sizeof(float)/STEREO_SAMPLES;
      const float *buffer = (const float *)inBytes.Bytes();
      
      for(int i=0;i<time_samples;i++)
      {
         mSampleBuffer[ i<<1 ] = *buffer++ * ((1<<15)-1);
         mSampleBuffer[ (i<<1) + 1 ] = *buffer++ * ((1<<15)-1);
      }
      
      mDynamicDone = time_samples < 1024;
      
      alBufferData(inBuffer, AL_FORMAT_STEREO16, mSampleBuffer, time_samples*STEREO_SAMPLES*sizeof(short), 44100 );
      
      //LOG_SOUND("Dynamic queue buffer %d (%d)", inBuffer, time_samples );
      alSourceQueueBuffers(mSourceID, 1, &inBuffer );
   }
   
   
   void OpenALChannel::unqueueBuffers()
   {
      ALint processed = 0;
      alGetSourcei(mSourceID, AL_BUFFERS_PROCESSED, &processed);
      //LOG_SOUND("Recover buffers : %d (%d)", processed, mDynamicStackSize);
      if (processed)
      {
         alSourceUnqueueBuffers(mSourceID,processed,&mDynamicStack[mDynamicStackSize]);
         mDynamicStackSize += processed;
      }
   }
   
   
   bool OpenALChannel::needsData()
   {
      if (!mDynamicBuffer[0] || mDynamicDone)
         return false;
      
      unqueueBuffers();
      
      //LOG_SOUND("needsData (%d)", mDynamicStackSize);
      if (mDynamicStackSize)
      {
         mDynamicDone = true;
         return true;
      }
      
      return false;
      
   }
   
   
   void OpenALChannel::addData(const ByteArray &inBytes)
   {
      if (!mDynamicStackSize)
      {
         //LOG_SOUND("Adding data with no buffers?");
         return;
      }
      mDynamicDone = false;
      ALuint buffer = mDynamicStack[0];
      mDynamicStack[0] = mDynamicStack[1];
      mDynamicStackSize--;
      QueueBuffer(buffer,inBytes);
      
      // Make sure it is still playing ...
      if (!mDynamicDone && mDynamicStackSize==1)
      {
         ALint val = 0;
         alGetSourcei(mSourceID, AL_SOURCE_STATE, &val);
         if(val != AL_PLAYING)
         {
            //LOG_SOUND("Kickstart (%d/%d)",val,mDynamicStackSize);
            
            // This is an indication that the previous buffer finished playing before we could deliver the new buffer.
            // You will hear ugly popping noises...
            alSourcePlay(mSourceID);
         }
      }
   }
   
   
   OpenALChannel::~OpenALChannel()
   {
      //LOG_SOUND("OpenALChannel destructor");
      if (mSourceID)
         alDeleteSources(1, &mSourceID);
      if (mDynamicBuffer[0])
         alDeleteBuffers(2, mDynamicBuffer);
      delete [] mSampleBuffer;
      if (mSound)
         mSound->DecRef();
      if (mStream)
      {
         mStream->release();
         delete mStream;
      }
      
      for (int i = 0; i < sgOpenChannels.size(); i++)
      {
         if (sgOpenChannels[i] == (intptr_t)this)
         {
            sgOpenChannels.erase (i, 1);
            break;
         }
      }
   }
   
   
   bool OpenALChannel::isComplete()
   {
      if (mUseStream)
      {
         if (mStream)
         {
            mStream->update();
            return !(mStream->isActive());
         }
         else
         {
            return true;
         }
      }
      
      if (!mSourceID)
      {
         //LOG_SOUND("OpenALChannel isComplete() - never started!");
         return true;
      }
      
      if (!mDynamicDone)
         return false;
      
      // got this hint from
      // http://www.gamedev.net/topic/410696-openal-how-to-query-if-a-source-sound-is-playing-solved/
      ALint state;
      alGetSourcei(mSourceID, AL_SOURCE_STATE, &state);
      /*
       Possible values of state
       AL_INITIAL
       AL_STOPPED
       AL_PLAYING
       AL_PAUSED
       */
      if(state == AL_STOPPED)
      {
         if (mLoops > 0)
         {   
            float seek = 0;
            
            if (mStartTime > 0)
            {
               seek = (mStartTime * 0.001) / mLength;
            }
            
            if (seek < 1)
            {
               //alSourceQueueBuffers(mSourceID, 1, &inBufferID);
               alSourcePlay(mSourceID);
               alSourcef(mSourceID, AL_BYTE_OFFSET, seek * mSize);
            }
            
            mLoops --;
            
            return false;
         }
         else
         {
            return true;
         }
         //LOG_SOUND("OpenALChannel isComplete() returning true");
      }
      else
      {
         //LOG_SOUND("OpenALChannel isComplete() returning false");
         return false;
      }
   }
   
   
   double OpenALChannel::getLeft()  
   {
      if (mUseStream)
      {
         return mStream ? mStream->getLeft() : 0;
      }
      else
      {
         float panX=0;
         float panY=0;
         float panZ=0;
         alGetSource3f(mSourceID, AL_POSITION, &panX, &panY, &panZ);
         return (1-panX)/2;
      }
   }
   
   
   double OpenALChannel::getRight()   
   {
      if (mUseStream)
      {
         return mStream ? mStream->getRight() : 0;
      }
      else
      {
         float panX=0;
         float panY=0;
         float panZ=0;
         alGetSource3f(mSourceID, AL_POSITION, &panX, &panY, &panZ);
         return (panX+1)/2;
      }
   }
   
   
   double OpenALChannel::setPosition(const float &inFloat)
   {
      if (mUseStream)
      {
         return mStream ? mStream->setPosition(inFloat) : inFloat;
      }
      else
      {
         alSourcef(mSourceID,AL_SEC_OFFSET,inFloat);
         return inFloat;
      }
   }
   
   
   double OpenALChannel::getPosition() 
   {
      if (mUseStream)
      {
         return mStream ? mStream->getPosition() : 0;
      }
      else
      {
         float pos = 0;
         alGetSourcef(mSourceID, AL_SEC_OFFSET, &pos);
         return pos * 1000.0;
      }
   }
   
   
   void OpenALChannel::setTransform(const SoundTransform &inTransform)
   {
      if (mUseStream)
      {
         if (mStream) mStream->setTransform(inTransform);
      }
      else
      {
         alSourcef(mSourceID, AL_GAIN, inTransform.volume);
         alSource3f(mSourceID, AL_POSITION, inTransform.pan * 1, 0, 0);
      }
   }
   
   
   void OpenALChannel::stop()
   {
      if (mUseStream)
      {
         if (mStream)
         {
            mStream->release();
            delete mStream;
            mStream = 0;
            mWasPlaying = false;
         }
      }
      else
      {
         ALint state;
         alGetSourcei(mSourceID, AL_SOURCE_STATE, &state);
         
         if (state == AL_PLAYING)
         {
            alSourceStop(mSourceID);
         }
      }
   }
   
   
   void OpenALChannel::suspend()
   {
      if (mUseStream)
      {
         if (mStream)
         {
            mStream->suspend();
            mWasPlaying = true;
         }
         else
         {
            mWasPlaying = false;
         }
      }
      else 
      {
         ALint state;
         alGetSourcei(mSourceID, AL_SOURCE_STATE, &state);
         
         if (state == AL_PLAYING)
         {
            alSourcePause(mSourceID);
            mWasPlaying = true;
            return;
         }
         
         mWasPlaying = false;
      }
   }
   
   
   void OpenALChannel::resume()
   {
      if (mUseStream)
      {
         if (mWasPlaying)
         {
            mStream->resume();
         }
      }
      else
      {
         if (mWasPlaying)
         {
            alSourcePlay(mSourceID);
         }
      }
   }
   
   
   SoundChannel *SoundChannel::Create(const ByteArray &inBytes,const SoundTransform &inTransform)
   {
      if (!OpenALInit())
         return 0;
      
      return new OpenALChannel(inBytes, inTransform);
   }
   
   
   OpenALSound::OpenALSound(const std::string &inFilename, bool inForceMusic)
   {
      IncRef();
      mBufferID = 0;
      mIsStream = false;
      
      #ifdef HX_MACOS
      char fileURL[1024];
      GetBundleFilename(inFilename.c_str(),fileURL,1024);
      #else
      #ifdef IPHONE
      std::string asset = GetResourcePath() + gAssetBase + inFilename;
      const char *fileURL = asset.c_str();
      #else
      const char *fileURL = inFilename.c_str();
      #endif
      #endif
      
      if (!fileURL) {
         
         //LOG_SOUND("OpenALSound constructor() error in url");
         mError = "Error int url: " + inFilename;

      } else {

         QuickVec<uint8> buffer;
         int _channels;
         int _bitsPerSample;
         ALenum  format;
         ALsizei freq;
         bool ok = false; 

            //Determine the file format before we try anything
         AudioFormat type = Audio::determineFormatFromFile(std::string(fileURL));
         switch(type) {
            case eAF_ogg:
               if (inForceMusic)
               {
                  mIsStream = true;
                  mStreamPath = fileURL;
               }
               else
               {
                  ok = Audio::loadOggSampleFromFile( fileURL, buffer, &_channels, &_bitsPerSample, &freq );
               }
            break;
            case eAF_wav:
               ok = Audio::loadWavSampleFromFile( fileURL, buffer, &_channels, &_bitsPerSample, &freq );
            break;
            default:
               LOG_SOUND("Error opening sound file, unsupported type.\n");
         }
         
         if (mIsStream)
            return;
         
            //Work out the format from the data
         if (_channels == 1) {
            if (_bitsPerSample == 8 ) {
               format = AL_FORMAT_MONO8;
            } else if (_bitsPerSample == 16) {
               format = (int)AL_FORMAT_MONO16;
            }
         } else if (_channels == 2) {
            if (_bitsPerSample == 8 ) {
               format = (int)AL_FORMAT_STEREO8;
            } else if (_bitsPerSample == 16) {
               format = (int)AL_FORMAT_STEREO16;
            }
         } //channels = 2
          
         
         if (!ok) {
            LOG_SOUND("Error opening sound data\n");
            mError = "Error opening sound data";
         } else if (alGetError() != AL_NO_ERROR) {
            LOG_SOUND("Error after opening sound data\n");
            mError = "Error after opening sound data";  
         } else {
               // grab a buffer ID from openAL
            alGenBuffers(1, &mBufferID);
            
               // load the awaiting data blob into the openAL buffer.
            alBufferData(mBufferID,format,&buffer[0],buffer.size(),freq); 

               // once we have all our information loaded, get some extra flags
            alGetBufferi(mBufferID, AL_SIZE, &bufferSize);
            alGetBufferi(mBufferID, AL_FREQUENCY, &frequency);
            alGetBufferi(mBufferID, AL_CHANNELS, &channels);    
            alGetBufferi(mBufferID, AL_BITS, &bitsPerSample); 
            
         } //!ok
      }
   }
   
   
   OpenALSound::OpenALSound(float *inData, int len)
   {
      IncRef();
      mBufferID = 0;
      mIsStream = false;
      
      QuickVec<uint8> buffer;
      int _channels;
      int _bitsPerSample;
      ALenum  format;
      ALsizei freq;
      bool ok = false; 
      
      //Determine the file format before we try anything
      AudioFormat type = Audio::determineFormatFromBytes(inData, len);
      
      switch(type) {
         case eAF_ogg:
            ok = Audio::loadOggSampleFromBytes(inData, len, buffer, &_channels, &_bitsPerSample, &freq );
         break;
         case eAF_wav:
            ok = Audio::loadWavSampleFromBytes(inData, len, buffer, &_channels, &_bitsPerSample, &freq );
         break;
         default:
            LOG_SOUND("Error opening sound file, unsupported type.\n");
      }
      
      //Work out the format from the data
      if (_channels == 1) {
         if (_bitsPerSample == 8 ) {
            format = AL_FORMAT_MONO8;
         } else if (_bitsPerSample == 16) {
            format = (int)AL_FORMAT_MONO16;
         }
      } else if (_channels == 2) {
         if (_bitsPerSample == 8 ) {
            format = (int)AL_FORMAT_STEREO8;
         } else if (_bitsPerSample == 16) {
            format = (int)AL_FORMAT_STEREO16;
         }
      } //channels = 2
       
      
      if (!ok) {
         LOG_SOUND("Error opening sound data\n");
         mError = "Error opening sound data";
      } else if (alGetError() != AL_NO_ERROR) {
         LOG_SOUND("Error after opening sound data\n");
         mError = "Error after opening sound data";  
      } else {
            // grab a buffer ID from openAL
         alGenBuffers(1, &mBufferID);
         
            // load the awaiting data blob into the openAL buffer.
         alBufferData(mBufferID,format,&buffer[0],buffer.size(),freq); 

            // once we have all our information loaded, get some extra flags
         alGetBufferi(mBufferID, AL_SIZE, &bufferSize);
         alGetBufferi(mBufferID, AL_FREQUENCY, &frequency);
         alGetBufferi(mBufferID, AL_CHANNELS, &channels);    
         alGetBufferi(mBufferID, AL_BITS, &bitsPerSample); 
         
      }
   }
   
   
   OpenALSound::~OpenALSound()
   {
      //LOG_SOUND("OpenALSound destructor() ###################################");
      if (mBufferID!=0)
         alDeleteBuffers(1, &mBufferID);
   }
   
   
   double OpenALSound::getLength()
   {
      if (mIsStream)
      {
         return 100;
      }
      else
      {
         double result = ((double)bufferSize) / (frequency * channels * (bitsPerSample/8) );
         
         //LOG_SOUND("OpenALSound getLength returning %f", toBeReturned);
         return result;
      }
   }
   
   
   void OpenALSound::getID3Value(const std::string &inKey, std::string &outValue)
   {
      //LOG_SOUND("OpenALSound getID3Value returning empty string");
      outValue = "";
   }
   
   
   int OpenALSound::getBytesLoaded()
   {
      int toBeReturned = ok() ? 100 : 0;
      //LOG_SOUND("OpenALSound getBytesLoaded returning %i", toBeReturned);
      return toBeReturned;
   }
   
   
   int OpenALSound::getBytesTotal()
   {
      int toBeReturned = ok() ? 100 : 0;
      //LOG_SOUND("OpenALSound getBytesTotal returning %i", toBeReturned);
      return toBeReturned;
   }
   
   
   bool OpenALSound::ok()
   {
      bool toBeReturned = mError.empty();
      //LOG_SOUND("OpenALSound ok() returning BOOL = %@\n", (toBeReturned ? @"YES" : @"NO")); 
      return toBeReturned;
   }
   
   
   std::string OpenALSound::getError()
   {
      //LOG_SOUND("OpenALSound getError()"); 
      return mError;
   }
   
   
   void OpenALSound::close()
   {
      //LOG_SOUND("OpenALSound close() doing nothing"); 
   }
   
   
   SoundChannel *OpenALSound::openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      //LOG_SOUND("OpenALSound openChannel()"); 
      if (mIsStream)
      {
         AudioStream_Ogg *audioStream = new AudioStream_Ogg();
         if (audioStream) audioStream->open(mStreamPath.c_str(), startTime, loops, inTransform);
         
         return new OpenALChannel(this, audioStream, startTime, loops, inTransform);
      }
      else
      {
         return new OpenALChannel(this, mBufferID, startTime, loops, inTransform);
      }
   }
   
   
   #ifndef IPHONE
   Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
   {
      //Always check if openal is intitialized
      if (!OpenALInit())
         return 0;
      
      //Return a reference
      OpenALSound *sound;
      
      #ifdef ANDROID
      if (!inForceMusic)
      {
         ByteArray bytes = AndroidGetAssetBytes(inFilename.c_str());
         sound = new OpenALSound((float*)bytes.Bytes(), bytes.Size());
      }
      else
      {
         sound = new OpenALSound(inFilename, inForceMusic);
      }
      #else
      sound = new OpenALSound(inFilename, inForceMusic);
      #endif
      
      if (sound->ok ())
         return sound;
      else
         return 0;
   }
   
   
   Sound *Sound::Create(float *inData, int len, bool inForceMusic)
   {
      //Always check if openal is intitialized
      if (!OpenALInit())
         return 0;

      //Return a reference
      OpenALSound *sound = new OpenALSound(inData, len);
      
      if (sound->ok ())
         return sound;
      else
         return 0;
   }
   #endif
   
   
   void Sound::Suspend()
   {
      //Always check if openal is initialized
      if (!OpenALInit())
         return;
      
      OpenALChannel* channel = 0;
      for (int i = 0; i < sgOpenChannels.size(); i++)
      {
         channel = (OpenALChannel*)(sgOpenChannels[i]);
         if (channel)
         {
            channel->suspend();
         }
      }
      
      alcMakeContextCurrent(0);
      alcSuspendContext(sgContext);
      
      #ifdef ANDROID
      alcSuspend();
      #endif
   }
   
   
   void Sound::Resume()
   {
      //Always check if openal is initialized
      if (!OpenALInit())
         return;
      
      #ifdef ANDROID
      alcResume();
      #endif
      
      alcMakeContextCurrent(sgContext);
      
      OpenALChannel* channel = 0;
      for (int i = 0; i < sgOpenChannels.size(); i++)
      {
         channel = (OpenALChannel*)(sgOpenChannels[i]);
         if (channel)
         {
            channel->resume();
         }
      }
      
      alcProcessContext(sgContext);
   }
   
   
   //Ogg Audio Stream implementation
   void AudioStream_Ogg::open(const std::string &path, int startTime, int inLoops, const SoundTransform &inTransform) {
        
        int result;
        mPath = std::string(path.c_str());
        mStartTime = startTime;
        mLoops = inLoops;
        mIsValid = true;
		mSuspend = false;
        
        #ifdef ANDROID
        
        mInfo = AndroidGetAssetFD(path.c_str());
        oggFile = fdopen(mInfo.fd, "rb");
        fseek(oggFile, mInfo.offset, 0);
        
        ov_callbacks callbacks;
        callbacks.read_func = &lime::AudioStream_Ogg::read_func;
        callbacks.seek_func = &lime::AudioStream_Ogg::seek_func;
        callbacks.close_func = &lime::AudioStream_Ogg::close_func;
        callbacks.tell_func = &lime::AudioStream_Ogg::tell_func;
        
        #else
        
        oggFile = fopen(path.c_str(), "rb");
        
        #endif
        
        if(!oggFile) {
            //throw std::string("Could not open Ogg file.");
            LOG_SOUND("Could not open Ogg file.");
            mIsValid = false;
            return;
        }
		
		oggStream = new OggVorbis_File();
        
        #ifdef ANDROID
        result = ov_open_callbacks(this, oggStream, NULL, 0, callbacks);
        #else
        result = ov_open(oggFile, oggStream, NULL, 0);
        #endif
         
        if(result < 0) {
			
            fclose(oggFile);
			   oggFile = 0;
			
            //throw std::string("Could not open Ogg stream. ") + errorString(result);
            LOG_SOUND("Could not open Ogg stream.");
            //LOG_SOUND(errorString(result).c_str());
            mIsValid = false;
            return;
        }

        vorbisInfo = ov_info(oggStream, -1);
        vorbisComment = ov_comment(oggStream, -1);

        if(vorbisInfo->channels == 1) {
            format = AL_FORMAT_MONO16;
        } else {
            format = AL_FORMAT_STEREO16;
        }
        
        if (startTime != 0)
        {
          double seek = startTime * 0.001;
          ov_time_seek(oggStream, seek);
        }
        
        alGenBuffers(2, buffers);
        check();
        alGenSources(1, &source);
        check();

        alSource3f(source, AL_POSITION,        0.0, 0.0, 0.0);
        alSource3f(source, AL_VELOCITY,        0.0, 0.0, 0.0);
        alSource3f(source, AL_DIRECTION,       0.0, 0.0, 0.0);
        alSourcef (source, AL_ROLLOFF_FACTOR,  0.0          );
        alSourcei (source, AL_SOURCE_RELATIVE, AL_TRUE      );
        
        setTransform(inTransform);
   } //open


   void AudioStream_Ogg::release() {
      
	  if (source) {
		  alSourceStop(source);
		  empty();
         alDeleteSources(1, &source);
         check();
         alDeleteBuffers(2, buffers);
         check();
		 
		 source = 0;
	  }
	  
	  if (oggStream) {
		 ov_clear(oggStream);
		 delete oggStream;
		 oggStream = 0;
		 oggFile = 0;
	  }
	  
	  mIsValid = false;
      
   } //release
   
   
   bool AudioStream_Ogg::playback() {

      if(playing()) {
           return true;
      }
           
       if(!stream(buffers[0])) {
           return false;
      }
           
       if(!stream(buffers[1])) {
           return false;
      }
       
       alSourceQueueBuffers(source, 2, buffers);
       alSourcePlay(source);
    
      return true;

   } //playback
   
   
   bool AudioStream_Ogg::playing() {
      
       ALint state;
       alGetSourcei(source, AL_SOURCE_STATE, &state);
       return (state == AL_PLAYING);

   } //playing
   
   
   bool AudioStream_Ogg::update() {
      
       if (mSuspend) return true;
       if (!mIsValid) return false;
      
       int processed = 0;
       bool active = true;

       alGetSourcei(source, AL_BUFFERS_PROCESSED, &processed);

       while(processed--) {

           ALuint buffer;
           alSourceUnqueueBuffers(source, 1, &buffer);
           alGetError();
           
           if (buffer)
           {
              active = stream(buffer);
              
              alSourceQueueBuffers(source, 1, &buffer);
              check();
           }
       }
       
       if (active && !playing())
         alSourcePlay(source);
       
       if (!active && mLoops > 0)
       {
         mLoops --;
         double seek = mStartTime * 0.001;
         ov_time_seek(oggStream, seek);
         return update();
       }
       
       return active;

   } //update
   
   
   bool AudioStream_Ogg::stream( ALuint buffer ) {
      
       if (mSuspend) return true;
       //LOG_SOUND("STREAM\n");
       char pcm[STREAM_BUFFER_SIZE];
       int  size = 0;
       int  section;
       int  result;
       
       while (size < STREAM_BUFFER_SIZE) {
           result = ov_read(oggStream, pcm + size, STREAM_BUFFER_SIZE - size, 0, 2, 1, &section);
           if(result > 0)
               size += result;
           else
               if(result < 0) {
                   break;
                   //LOG_SOUND ("Result is less than 0");
                   //throw errorString(result);
               }
               else
                   break;
       }
       if(size <= 0) {
           alSourceStop(source);
           return false;
      }
      
       alBufferData(buffer, format, pcm, size, vorbisInfo->rate);
       check();
       return true;

   } //stream


    void AudioStream_Ogg::empty() {

      int queued;
    
      alGetSourcei(source, AL_BUFFERS_QUEUED, &queued);
    
       while(queued--) {
           ALuint buffer;
       
           alSourceUnqueueBuffers(source, 1, &buffer);
           check();
       }

    } //empty


    void AudioStream_Ogg::check()
    {
      int error = alGetError();

      if(error != AL_NO_ERROR) {
         //todo : print meaningful errors instead
         LOG_SOUND("OpenAL error was raised: %d\n", error);
         mIsValid = false;
         //throw std::string("OpenAL error was raised.");
      }

    } //check


   std::string AudioStream_Ogg::errorString(int code) {

       switch(code) {

           case OV_EREAD:
               return std::string("Read from media.");
           case OV_ENOTVORBIS:
               return std::string("Not Vorbis data.");
           case OV_EVERSION:
               return std::string("Vorbis version mismatch.");
           case OV_EBADHEADER:
               return std::string("Invalid Vorbis header.");
           case OV_EFAULT:
               return std::string("Internal logic fault (bug or heap/stack corruption.");
           default:
               return std::string("Unknown Ogg error.");

       } //switch

   } //errorString
   
   
   double AudioStream_Ogg::getLeft()  
   {
      float panX=0;
      float panY=0;
      float panZ=0;
      alGetSource3f(source, AL_POSITION, &panX, &panY, &panZ);
      return (1-panX)/2;
   }
   
   
   double AudioStream_Ogg::getRight()   
   {
      float panX=0;
      float panY=0;
      float panZ=0;
      alGetSource3f(source, AL_POSITION, &panX, &panY, &panZ);
      return (panX+1)/2;
   }
   
   
   double AudioStream_Ogg::setPosition(const float &inFloat)
   {
      if (!mSuspend)
      {
         double seek = inFloat * 0.001;
         ov_time_seek(oggStream, seek);
      }
      return inFloat;
   }
   
   
   double AudioStream_Ogg::getPosition() 
   {
      if (mSuspend)
      {
         return 0;
      }
      else
      {
         double pos = ov_time_tell(oggStream);
         return pos * 1000.0;
      }
   }
   
   
   void AudioStream_Ogg::setTransform(const SoundTransform &inTransform)
   {
      if (!mSuspend)
      {
         alSourcef(source, AL_GAIN, inTransform.volume);
             //magic number : Half PI 
         alSource3f(source, AL_POSITION, (float) cos((inTransform.pan - 1) * (1.5707)), 0, (float) sin((inTransform.pan + 1) * (1.5707)));
      }
   }
   
   
   void AudioStream_Ogg::suspend()
   {
      mSuspend = true;
      alSourcePause(source);
      //release();
   }
   
   
   void AudioStream_Ogg::resume()
   {
      alSourcePlay(source);
      //SoundTransform transform = SoundTransform();
      //transform.volume = 1;
      //transform.pan = 0;
      //open(mPath, mStartTime, mLoops, transform);
      mSuspend = false;
      //update();
      //update();
      //playback();
   }
   
   
   bool AudioStream_Ogg::isActive()
   {
      //#ifdef ANDROID
      // TODO: Android stream sounds won't resume :(
      //if (mSuspend) return false;
      //#else
      if (mSuspend) return true;
      //#endif
      //playback();
      return (mIsValid && playing());
   }

   
}
