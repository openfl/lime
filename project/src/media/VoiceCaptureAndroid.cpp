#include <media/VoiceCapture.h>
#include <jni.h>
#include <SDL.h>


namespace lime {


	// org.haxe.lime.VoiceCapture records with Android's voice processing, and is
	// polled here with non-blocking reads, as OpenAL is polled
	class AndroidVoiceCapture : public VoiceCapture {


		public:

			AndroidVoiceCapture (int channels, int bitsPerSample, int bufferFrames) : VoiceCapture (channels, bitsPerSample, bufferFrames) {

				capture = NULL;
				samples = NULL;
				sampleCount = 0;

			}


			~AndroidVoiceCapture () {

				Close ();

			}


			void Close () {

				JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv ();

				if (env && capture) {

					env->CallVoidMethod (capture, releaseMethod);
					ClearException (env);
					env->DeleteGlobalRef (capture);
					capture = NULL;

				}

				if (env && samples) {

					env->DeleteGlobalRef (samples);
					samples = NULL;

				}

				SetDisconnected ();

			}


			bool Open (int sampleRate, int bufferFrames, int requested) {

				JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv ();
				if (!env) return false;

				// Classes from the application are found from SDL's thread, where Lime opens
				// the capture
				jclass captureClass = env->FindClass ("org/haxe/lime/VoiceCapture");

				if (!captureClass) {

					ClearException (env);
					return false;

				}

				jmethodID openMethod = env->GetStaticMethodID (captureClass, "open", "(III)Lorg/haxe/lime/VoiceCapture;");
				getProcessingMethod = env->GetMethodID (captureClass, "getProcessing", "()I");
				readMethod = env->GetMethodID (captureClass, "read", "([S)I");
				releaseMethod = env->GetMethodID (captureClass, "release", "()V");
				startMethod = env->GetMethodID (captureClass, "start", "()Z");
				stopMethod = env->GetMethodID (captureClass, "stop", "()V");

				if (!openMethod || !getProcessingMethod || !readMethod || !releaseMethod || !startMethod || !stopMethod) {

					ClearException (env);
					env->DeleteLocalRef (captureClass);
					return false;

				}

				jobject local = env->CallStaticObjectMethod (captureClass, openMethod, sampleRate, bufferFrames, requested);
				ClearException (env);
				env->DeleteLocalRef (captureClass);

				if (!local) return false;

				capture = env->NewGlobalRef (local);
				env->DeleteLocalRef (local);

				sampleCount = bufferFrames < 1024 ? 1024 : bufferFrames;
				jshortArray array = env->NewShortArray (sampleCount);

				if (!array) {

					ClearException (env);
					return false;

				}

				samples = (jshortArray)env->NewGlobalRef (array);
				env->DeleteLocalRef (array);
				chunk.resize (sampleCount);

				SetProcessing (env->CallIntMethod (capture, getProcessingMethod));
				ClearException (env);
				return true;

			}


			bool Start () {

				JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv ();
				if (!env || !capture) return false;

				bool started = env->CallBooleanMethod (capture, startMethod);
				ClearException (env);
				return started;

			}


			void Stop () {

				JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv ();
				if (!env || !capture) return;

				env->CallVoidMethod (capture, stopMethod);
				ClearException (env);

			}


		protected:

			void Update () {

				JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv ();
				if (!env || !capture) return;

				// Everything the recorder holds is taken, a buffer at a time
				for (int i = 0; i < 64; i++) {

					jint read = env->CallIntMethod (capture, readMethod, samples);

					if (env->ExceptionCheck ()) {

						ClearException (env);
						return;

					}

					if (read < 0) {

						// AudioRecord.ERROR_DEAD_OBJECT: the microphone went away
						if (read == -6) SetDisconnected ();
						return;

					}

					if (read == 0) return;

					env->GetShortArrayRegion (samples, 0, read, &chunk[0]);
					Write (&chunk[0], read, 1);

					if (read < sampleCount) return;

				}

			}


		private:

			static void ClearException (JNIEnv* env) {

				if (env->ExceptionCheck ()) env->ExceptionClear ();

			}


			jobject capture;
			std::vector<int16_t> chunk;
			jmethodID getProcessingMethod;
			jmethodID readMethod;
			jmethodID releaseMethod;
			jshortArray samples;
			int sampleCount;
			jmethodID startMethod;
			jmethodID stopMethod;


	};


	VoiceCapture* VoiceCapture::Open (const char* deviceName, int sampleRate, int channels, int bitsPerSample, int bufferFrames, int processing) {

		if (channels < 1 || channels > 2 || (bitsPerSample != 8 && bitsPerSample != 16) || sampleRate <= 0) return NULL;

		// Android records from the device it picks for voice
		AndroidVoiceCapture* capture = new AndroidVoiceCapture (channels, bitsPerSample, bufferFrames);

		if (!capture->Open (sampleRate, bufferFrames, processing)) {

			delete capture;
			return NULL;

		}

		return capture;

	}


}
