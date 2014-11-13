#ifndef HX_LIME

#include <Sound.h>
#include <Display.h>
#include <Utils.h>
#include <jni.h>

#include <android/log.h>
#include "AndroidCommon.h"

#undef LOGV
#undef LOGE

//#define LOGV(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::AndroidSound", msg, ## args)
#define LOGV(msg,args...) { }

#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::AndroidSound", msg, ## args)

namespace nme
{

static jclass soundClass;
static bool init = false;
static jmethodID   jGetDuration;
static jmethodID   jPlaySound;
static jmethodID   jGetSoundComplete;
static jmethodID   jGetSoundPosition;
static jmethodID   jStopSound;
static jmethodID   jPlayMusic;
static jmethodID   jGetComplete;
static jmethodID   jGetPosition;
static jmethodID   jSetPosition;
static jmethodID   jGetLeft;
static jmethodID   jGetRight;
static jmethodID   jStopMusic;
static jmethodID   jGetSoundPathByByteArray;
static jmethodID   jGetSoundHandle;
static jmethodID   jSetMusicTransform;
;

void initJni()
{
   if (!init)
   {
      init = true;
      JNIEnv *env = GetEnv();
      soundClass = FindClass("org/haxe/nme/Sound");

      LOGV("initJni...");
      jGetDuration = env->GetStaticMethodID(soundClass, "getDuration", "(Ljava/lang/String;)I");
      CheckException(env,false);
      jPlaySound = env->GetStaticMethodID(soundClass, "playSound", "(IDDI)I");
      CheckException(env,false);
      jGetSoundComplete = env->GetStaticMethodID(soundClass, "getSoundComplete", "(III)Z");
      CheckException(env,false);
      jGetSoundPosition = env->GetStaticMethodID(soundClass, "getSoundPosition", "(III)I");
      CheckException(env,false);
      jStopSound = env->GetStaticMethodID(soundClass, "stopSound", "(I)V");
      CheckException(env,false);
      jPlayMusic = env->GetStaticMethodID(soundClass, "playMusic", "(Ljava/lang/String;DDID)I");
      CheckException(env,false);
      jGetComplete = env->GetStaticMethodID(soundClass, "getComplete", "(Ljava/lang/String;)Z");
      CheckException(env,false);
      jGetPosition = env->GetStaticMethodID(soundClass, "getPosition", "(Ljava/lang/String;)I");
      CheckException(env,false);
      jSetPosition = env->GetStaticMethodID(soundClass, "setPosition", "(Ljava/lang/String;)I");
      CheckException(env,false);
      jGetLeft = env->GetStaticMethodID(soundClass, "getLeft", "(Ljava/lang/String;)D");
      CheckException(env,false);
      jGetRight = env->GetStaticMethodID(soundClass, "getRight", "(Ljava/lang/String;)D");
      CheckException(env,false);
      jStopMusic = env->GetStaticMethodID(soundClass, "stopMusic", "(Ljava/lang/String;)V");
      CheckException(env,false);
      jGetSoundPathByByteArray = env->GetStaticMethodID(soundClass, "getSoundPathByByteArray", "([B)Ljava/lang/String;");
      CheckException(env,false);
      jGetSoundHandle = env->GetStaticMethodID(soundClass, "getSoundHandle", "(Ljava/lang/String;)I");
      CheckException(env,false);
      jSetMusicTransform = env->GetStaticMethodID(soundClass, "setMusicTransform", "(Ljava/lang/String;DD)V");
      CheckException(env,false);
      LOGV("Done initJni.");
   }
}


class AndroidSoundChannel : public SoundChannel
{
public:
   AndroidSoundChannel(Object *inSound, int inHandle, double startTime, int loops, const SoundTransform &inTransform)
   {
      LOGV("Android Sound Channel create, in handle, %d",inHandle);
      JNIEnv *env = GetEnv();
      mStreamID = -1;
      mSound = inSound;
      mSoundHandle = inHandle;
      mLoop = (loops < 1) ? 1 : loops;
      inSound->IncRef();
      if (inHandle >= 0)
      {
         mStreamID = env->CallStaticIntMethod(soundClass, jPlaySound, inHandle, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2), mLoop );
      }
      CheckException(env,false);
    }

   ~AndroidSoundChannel()
   {
      mSound->DecRef();
   }

   bool isComplete()
   {
      JNIEnv *env = GetEnv();
      return env->CallStaticBooleanMethod(soundClass, jGetSoundComplete, mSoundHandle, mStreamID, mLoop);
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
      JNIEnv *env = GetEnv();
      return env->CallStaticIntMethod(soundClass, jGetSoundPosition, mSoundHandle, mStreamID, mLoop);
   }

   double setPosition(const float &inFloat)
   {
      //not implemented yet.
      return -1;
   }

   void stop()
   {
      if (mStreamID > -1)
      {   
         JNIEnv *env = GetEnv();

         env->CallStaticVoidMethod(soundClass, jStopSound, mStreamID);
      }
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


class AndroidMusicChannel : public SoundChannel
{
public:
   AndroidMusicChannel(Object *inSound, const std::string &inPath, double startTime, int loops, const SoundTransform &inTransform)
   {
      LOGV("Android Music Channel create %d", inPath.c_str());
      JNIEnv *env = GetEnv();
      mState = 0;
      mSound = inSound;
      inSound->IncRef();

      jstring path = env->NewStringUTF(inPath.c_str());
      mJSoundPath = (jstring)env->NewGlobalRef(path);

      mState = env->CallStaticIntMethod(soundClass, jPlayMusic, mJSoundPath, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2), loops, startTime);
      mSoundPath = inPath;
    }

   ~AndroidMusicChannel()
   {
      GetEnv()->DeleteGlobalRef(mJSoundPath);
      mSound->DecRef();
   }

   bool isComplete()
   {
      JNIEnv *env = GetEnv();
      return env->CallStaticBooleanMethod(soundClass, jGetComplete, mJSoundPath);
   }

   double getPosition()
   {
      JNIEnv *env = GetEnv();
      return env->CallStaticIntMethod(soundClass, jGetPosition, mJSoundPath);
   }

   double setPosition(const float &inFloat)
   {
      JNIEnv *env = GetEnv();
      return env->CallStaticIntMethod(soundClass, jSetPosition, mJSoundPath);
   }

   double getLeft()
   {
      JNIEnv *env = GetEnv();
      return env->CallStaticDoubleMethod(soundClass, jGetLeft, mJSoundPath);
   }

   double getRight()
   {
      JNIEnv *env = GetEnv();
      return env->CallStaticDoubleMethod(soundClass, jGetRight, mJSoundPath);
   }

   void stop()
   {
      JNIEnv *env = GetEnv();

      env->CallStaticVoidMethod(soundClass, jStopMusic, mJSoundPath);
   }

   void setTransform(const SoundTransform &inTransform)
   {
      JNIEnv *env = GetEnv();

      env->CallStaticVoidMethod(soundClass, jSetMusicTransform, mJSoundPath, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2));
   }

   Object *mSound;
   int mState;
   std::string mSoundPath;
   jstring     mJSoundPath;
};


class AndroidSound : public Sound
{
   enum SoundMode
   {
      MODE_UNKNOWN,
      MODE_SOUND_ID,
      MODE_MUSIC_PATH,
   };
   
private:
   void loadWithPath(const std::string &inPath, bool inForceMusic)
   {
      JNIEnv *env = GetEnv();
      IncRef();

      mMode = MODE_UNKNOWN;
      handleID = -1;
      mLength = 0;
      mSoundPath = inPath;

      jstring path = env->NewStringUTF(mSoundPath.c_str());
      mJSoundPath = (jstring)env->NewGlobalRef(path);

      if (!inForceMusic)
      {
         handleID = env->CallStaticIntMethod(soundClass, jGetSoundHandle, path);

         if (handleID >= 0)
            mMode = MODE_SOUND_ID;
      }

      //env->ReleaseStringUTFChars(str, inSound.c_str() );

      if (handleID < 0)
         mMode = MODE_MUSIC_PATH;
   }

public:
   AndroidSound(const std::string &inPath, bool inForceMusic)
   {
      LOGV("AndroidSound - create %s",inPath.c_str());
      loadWithPath(inPath, inForceMusic);
   }
   
   AndroidSound(float *inData, int len, bool inForceMusic)
   {
      JNIEnv *env = GetEnv();

      jbyteArray data = env->NewByteArray(len);
      env->SetByteArrayRegion(data, 0, len, (const jbyte *)inData);

      jstring jname = (jstring)env->CallStaticObjectMethod(soundClass, jGetSoundPathByByteArray, data);
      
      std::string inPath = std::string(env->GetStringUTFChars(jname, NULL));
      loadWithPath(inPath, inForceMusic);
   }
   ~AndroidSound()
   {
      GetEnv()->DeleteGlobalRef(mJSoundPath);
   }


   void reloadSound()
   {
      JNIEnv *env = GetEnv();
      handleID = env->CallStaticIntMethod(soundClass, jGetSoundHandle, mJSoundPath);
   }

   int getBytesLoaded() { return 0; }
   int getBytesTotal() { return 0; }
   bool ok() { return handleID >= 0; }
   std::string getError() { return ok() ? "" : "Error"; }

   double getLength()
   {
      if (mLength == 0)
      {
         JNIEnv *env = GetEnv();
         mLength = env->CallStaticIntMethod(soundClass, jGetDuration, mJSoundPath);
      }
       return mLength;
   }
   
    void close()  { }

   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      LOGV("SoundTransform openChannel...");
      switch (mMode)
      {
         case MODE_SOUND_ID:
            return new AndroidSoundChannel(this, handleID, startTime, loops, inTransform);
            break;
         case MODE_MUSIC_PATH:
         default:
            return new AndroidMusicChannel(this, mSoundPath, startTime, loops, inTransform);
            break;
      }
   }

   int handleID;
   int mLength;
   // int mManagerID;
   std::string mSoundPath;
   SoundMode mMode;
   jstring   mJSoundPath;
};

void Sound::Suspend()
{
   /* TODO
   OpenALChannel* channel = 0;
   for (int i = 0; i < sgOpenChannels.size(); i++)
   {
      channel = (OpenALChannel*)(sgOpenChannels[i]);
      if (channel)
      {
         channel->suspend();
      }
   }
   */
}


void Sound::Resume()
{
   /* TODO
   
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
   */
}



Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
{
   initJni();
   return new AndroidSound(inFilename, inForceMusic);
}

Sound *Sound::Create(float *inData, int len, bool inForceMusic)
{
   initJni();
   return new AndroidSound(inData, len, inForceMusic);
}

} // end namespace name

#else

#include <Sound.h>
#include <Display.h>
#include <Utils.h>
#include <jni.h>

#include <android/log.h>
#include "AndroidCommon.h"

#undef LOGV
#undef LOGE

#define LOGV(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "nme::AndroidSound", msg, ## args)
#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "nme::AndroidSound", msg, ## args)

namespace nme
{
	class AndroidSoundChannel : public SoundChannel
	{
	public:
	   	AndroidSoundChannel(Object *inSound, int inHandle, double startTime, int loops, const SoundTransform &inTransform)
		{
			//LOGV("Android Sound Channel create, in handle, %d",inHandle);
	      	JNIEnv *env = GetEnv();
			mStreamID = -1;
			mSound = inSound;
			mSoundHandle = inHandle;
			mLoop = (loops < 1) ? 1 : loops;
			inSound->IncRef();
			if (inHandle >= 0)
			{
			   	jclass cls = FindClass("org/haxe/lime/Sound");
	         	jmethodID mid = env->GetStaticMethodID(cls, "playSound", "(IDDI)I");
	         	if (mid > 0) {
					mStreamID = env->CallStaticIntMethod(cls, mid, inHandle, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2), mLoop );
			   	}
			}
	    }

		~AndroidSoundChannel()
		{
			mSound->DecRef();
		}

		bool isComplete()
		{
			JNIEnv *env = GetEnv();
		   	jclass cls = FindClass("org/haxe/lime/Sound");
         	jmethodID mid = env->GetStaticMethodID(cls, "getSoundComplete", "(III)Z");
         	if (mid > 0) {
				return env->CallStaticBooleanMethod(cls, mid, mSoundHandle, mStreamID, mLoop);
		   	}
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
			JNIEnv *env = GetEnv();
		   	jclass cls = FindClass("org/haxe/lime/Sound");
         	jmethodID mid = env->GetStaticMethodID(cls, "getSoundPosition", "(III)I");
         	if (mid > 0) {
				return env->CallStaticIntMethod(cls, mid, mSoundHandle, mStreamID, mLoop);
		   	}
		}

		double setPosition(const float &inFloat) {
				//not implemented yet.
			return -1;
		}

		void stop()
		{
			if (mStreamID > -1) {	
				JNIEnv *env = GetEnv();

				jclass cls = FindClass("org/haxe/lime/Sound");
			    jmethodID mid = env->GetStaticMethodID(cls, "stopSound", "(I)V");
			    if (mid > 0){
					env->CallStaticVoidMethod(cls, mid, mStreamID);
				}
			}
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


	class AndroidMusicChannel : public SoundChannel
	{
	public:
		AndroidMusicChannel(Object *inSound, const std::string &inPath, double startTime, int loops, const SoundTransform &inTransform)
		{
			JNIEnv *env = GetEnv();
			mState = 0;
			mSound = inSound;
			inSound->IncRef();

			jclass cls = FindClass("org/haxe/lime/Sound");
			jstring path = env->NewStringUTF(inPath.c_str());
			jmethodID mid = env->GetStaticMethodID(cls, "playMusic", "(Ljava/lang/String;DDID)I");
			if (mid > 0) {
				mState = env->CallStaticIntMethod(cls, mid, path, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2), loops, startTime);
			}
			mSoundPath = inPath;
	    }

		~AndroidMusicChannel()
		{
			mSound->DecRef();
		}

		bool isComplete()
		{
			JNIEnv *env = GetEnv();
			jclass cls = FindClass("org/haxe/lime/Sound");
			jstring path = env->NewStringUTF(mSoundPath.c_str());
			jmethodID mid = env->GetStaticMethodID(cls, "getComplete", "(Ljava/lang/String;)Z");
			if (mid > 0) {
				return env->CallStaticBooleanMethod(cls, mid, path);
			}
			return false;
		}

		double getPosition()
		{
			JNIEnv *env = GetEnv();
			jclass cls = FindClass("org/haxe/lime/Sound");
			jstring path = env->NewStringUTF(mSoundPath.c_str());
			jmethodID mid = env->GetStaticMethodID(cls, "getPosition", "(Ljava/lang/String;)I");
			if (mid > 0) {
				return env->CallStaticIntMethod(cls, mid, path);
			}
			return -1;
		}

		double setPosition(const float &inFloat) {
			JNIEnv *env = GetEnv();
			jclass cls = FindClass("org/haxe/lime/Sound");
			jstring path = env->NewStringUTF(mSoundPath.c_str());
			jmethodID mid = env->GetStaticMethodID(cls, "setPosition", "(Ljava/lang/String;)I");
			if (mid > 0) {
				return env->CallStaticIntMethod(cls, mid, path);
			}
			return -1;
		}

		double getLeft()
		{
			JNIEnv *env = GetEnv();
			jclass cls = FindClass("org/haxe/lime/Sound");
			jstring path = env->NewStringUTF(mSoundPath.c_str());
			jmethodID mid = env->GetStaticMethodID(cls, "getLeft", "(Ljava/lang/String;)D");
			if (mid > 0) {
				return env->CallStaticDoubleMethod(cls, mid, path);
			}
			return -1;
		}

		double getRight()
		{
			JNIEnv *env = GetEnv();
			jclass cls = FindClass("org/haxe/lime/Sound");
			jstring path = env->NewStringUTF(mSoundPath.c_str());
			jmethodID mid = env->GetStaticMethodID(cls, "getRight", "(Ljava/lang/String;)D");
			if (mid > 0) {
				return env->CallStaticDoubleMethod(cls, mid, path);
			}
			return -1;
		}

		void stop()
		{
			JNIEnv *env = GetEnv();

			jclass cls = FindClass("org/haxe/lime/Sound");
			jstring path = env->NewStringUTF(mSoundPath.c_str());
			jmethodID mid = env->GetStaticMethodID(cls, "stopMusic", "(Ljava/lang/String;)V");
			if (mid > 0) {
				env->CallStaticVoidMethod(cls, mid, path);
			}
		}

		void setTransform(const SoundTransform &inTransform)
		{
			JNIEnv *env = GetEnv();

			jclass cls = FindClass("org/haxe/lime/Sound");
			jstring path = env->NewStringUTF(mSoundPath.c_str());
			jmethodID mid = env->GetStaticMethodID(cls, "setMusicTransform", "(Ljava/lang/String;DD)V");
			if (mid > 0 ) {
				env->CallStaticVoidMethod(cls, mid, path, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2));
			}
		}

		Object *mSound;
		int mState;
		std::string mSoundPath;
	};


	class AndroidSound : public Sound
	{
	   enum SoundMode
	   {
			MODE_UNKNOWN,
			MODE_SOUND_ID,
			MODE_MUSIC_PATH,
		};
		
	private:
		void loadWithPath(const std::string &inPath, bool inForceMusic)
		{
			JNIEnv *env = GetEnv();
			IncRef();

			mMode = MODE_UNKNOWN;
			handleID = -1;
			mLength = 0;
			mSoundPath = inPath;

			jclass cls = FindClass("org/haxe/lime/Sound");
			jstring path = env->NewStringUTF(mSoundPath.c_str());

			if (!inForceMusic) {
				jmethodID mid = env->GetStaticMethodID(cls, "getSoundHandle", "(Ljava/lang/String;)I");
				if (mid > 0) {
					handleID = env->CallStaticIntMethod(cls, mid, path);
					if (handleID >= 0)
						mMode = MODE_SOUND_ID;
				}
			}

			//env->ReleaseStringUTFChars(str, inSound.c_str() );

			if (handleID < 0)
				mMode = MODE_MUSIC_PATH;
		}

	public:
		AndroidSound(const std::string &inPath, bool inForceMusic)
		{
			loadWithPath(inPath, inForceMusic);
		}
		
		AndroidSound(float *inData, int len, bool inForceMusic)
		{
			JNIEnv *env = GetEnv();

			jbyteArray data = env->NewByteArray(len);
			env->SetByteArrayRegion(data, 0, len, (const jbyte *)inData);

			jclass cls = FindClass("org/haxe/lime/Sound");
			jmethodID mid = env->GetStaticMethodID(cls, "getSoundPathByByteArray", "([B)Ljava/lang/String;");
			jstring jname = (jstring)env->CallStaticObjectMethod(cls, mid, data);
			
			std::string inPath = std::string(env->GetStringUTFChars(jname, NULL));
			loadWithPath(inPath, inForceMusic);
		}

		void reloadSound()
		{
			JNIEnv *env = GetEnv();
			jclass cls = FindClass("org/haxe/lime/Sound");
			jmethodID mid = env->GetStaticMethodID(cls, "getSoundHandle", "(Ljava/lang/String;)I");
			if (mid > 0) {
				jstring path = env->NewStringUTF(mSoundPath.c_str());
				handleID = env->CallStaticIntMethod(cls, mid, path);
				//env->ReleaseStringUTFChars(path, mSoundName.c_str() );
			}
		}

		int getBytesLoaded() { return 0; }
		int getBytesTotal() { return 0; }
		bool ok() { return handleID >= 0; }
		std::string getError() { return ok() ? "" : "Error"; }

		double getLength()
		{
			if (mLength == 0) {
				JNIEnv *env = GetEnv();
				jclass cls = FindClass("org/haxe/lime/Sound");
				jstring path = env->NewStringUTF(mSoundPath.c_str());
				jmethodID mid = env->GetStaticMethodID(cls, "getDuration", "(Ljava/lang/String;)I");
				if (mid > 0) {
					mLength = env->CallStaticIntMethod(cls, mid, path);
				}
			}
		    return mLength;
		}
	   
	    void close()  { }

		SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
		{
			switch (mMode) {
				case MODE_SOUND_ID:
					return new AndroidSoundChannel(this, handleID, startTime, loops, inTransform);
					break;
				case MODE_MUSIC_PATH:
				default:
					return new AndroidMusicChannel(this, mSoundPath, startTime, loops, inTransform);
					break;
			}
		}

		int handleID;
		int mLength;
		// int mManagerID;
		std::string mSoundPath;
		SoundMode mMode;
	};

	Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
	{
		return new AndroidSound(inFilename, inForceMusic);
	}

	Sound *Sound::Create(float *inData, int len, bool inForceMusic)
	{
		return new AndroidSound(inData, len, inForceMusic);
	}
}

#endif
