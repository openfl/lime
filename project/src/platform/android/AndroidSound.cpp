#include <Sound.h>
#include <Display.h>
#include <Utils.h>
#include <jni.h>

#include <android/log.h>
#include "AndroidCommon.h"

#undef LOGV
#undef LOGE

#define LOGV(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "lime::AndroidSound", msg, ## args)
#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "lime::AndroidSound", msg, ## args)

namespace lime
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
