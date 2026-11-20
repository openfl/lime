#include <media/CameraCapture.h>

#ifdef LIME_VIDEO_MEDIACODEC

#include <jni.h>
#include <SDL.h>


namespace lime {


	static void ClearCameraException (JNIEnv* env) {

		if (env->ExceptionCheck ()) env->ExceptionClear ();

	}


	static std::string GetJavaString (JNIEnv* env, jstring text) {

		if (!text) return "";

		const char* utf8 = env->GetStringUTFChars (text, NULL);
		std::string result = utf8 ? utf8 : "";
		if (utf8) env->ReleaseStringUTFChars (text, utf8);
		return result;

	}


	// org.haxe.lime.CameraCapture captures with Camera2, and is polled here for its
	// newest frame, as NV12
	class AndroidCameraCapture : public CameraCapture {


		public:

			AndroidCameraCapture () {

				capture = NULL;
				data = NULL;
				dataLength = 0;

			}


			~AndroidCameraCapture () {

				Close ();

			}


			void Close () {

				JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv ();

				if (env && capture) {

					env->CallVoidMethod (capture, closeMethod);
					ClearCameraException (env);
					env->DeleteGlobalRef (capture);
					capture = NULL;

				}

				if (env && data) {

					env->DeleteGlobalRef (data);
					data = NULL;

				}

				SetDisconnected ();

			}


			bool Open (const char* id, int requestedWidth, int requestedHeight, double requestedFrameRate) {

				JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv ();
				if (!env) return false;

				// Classes from the application are found from SDL's thread, where Lime opens
				// the camera
				jclass captureClass = env->FindClass ("org/haxe/lime/CameraCapture");

				if (!captureClass) {

					ClearCameraException (env);
					return false;

				}

				jmethodID openMethod = env->GetStaticMethodID (captureClass, "open", "(Ljava/lang/String;III)Lorg/haxe/lime/CameraCapture;");
				closeMethod = env->GetMethodID (captureClass, "close", "()V");
				getFrameTimeMethod = env->GetMethodID (captureClass, "getFrameTime", "()D");
				readMethod = env->GetMethodID (captureClass, "read", "([B)I");
				startMethod = env->GetMethodID (captureClass, "start", "()Z");
				stopMethod = env->GetMethodID (captureClass, "stop", "()V");
				jmethodID getWidthMethod = env->GetMethodID (captureClass, "getWidth", "()I");
				jmethodID getHeightMethod = env->GetMethodID (captureClass, "getHeight", "()I");
				jmethodID getFrameRateMethod = env->GetMethodID (captureClass, "getFrameRate", "()I");

				if (!openMethod || !closeMethod || !getFrameTimeMethod || !readMethod || !startMethod || !stopMethod || !getWidthMethod || !getHeightMethod || !getFrameRateMethod) {

					ClearCameraException (env);
					env->DeleteLocalRef (captureClass);
					return false;

				}

				jstring javaId = env->NewStringUTF (id ? id : "");
				jobject local = env->CallStaticObjectMethod (captureClass, openMethod, javaId, requestedWidth, requestedHeight, (jint)(requestedFrameRate + 0.5));
				ClearCameraException (env);
				env->DeleteLocalRef (javaId);
				env->DeleteLocalRef (captureClass);

				if (!local) return false;

				capture = env->NewGlobalRef (local);
				env->DeleteLocalRef (local);

				width = env->CallIntMethod (capture, getWidthMethod);
				height = env->CallIntMethod (capture, getHeightMethod);
				frameRate = env->CallIntMethod (capture, getFrameRateMethod);
				ClearCameraException (env);

				dataLength = width * height + ((width + 1) / 2) * ((height + 1) / 2) * 2;
				jbyteArray array = env->NewByteArray (dataLength);

				if (!array) {

					ClearCameraException (env);
					return false;

				}

				data = (jbyteArray)env->NewGlobalRef (array);
				env->DeleteLocalRef (array);
				frame.resize (dataLength);

				return width > 0 && height > 0;

			}


			bool Start () {

				JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv ();
				if (!env || !capture) return false;

				bool started = env->CallBooleanMethod (capture, startMethod);
				ClearCameraException (env);
				return started;

			}


			void Stop () {

				JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv ();
				if (!env || !capture) return;

				env->CallVoidMethod (capture, stopMethod);
				ClearCameraException (env);

			}


		protected:

			void Update () {

				JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv ();
				if (!env || !capture) return;

				jint length = env->CallIntMethod (capture, readMethod, data);

				if (env->ExceptionCheck ()) {

					ClearCameraException (env);
					return;

				}

				if (length < 0) {

					SetDisconnected ();
					return;

				}

				if (length == 0 || length > dataLength) return;

				double time = env->CallDoubleMethod (capture, getFrameTimeMethod);
				ClearCameraException (env);
				env->GetByteArrayRegion (data, 0, length, (jbyte*)&frame[0]);

				// Camera2 gives BT.601 full range YUV
				VideoPlanes planes;
				planes.colorMatrix = VIDEO_COLOR_MATRIX_BT601;
				planes.fullRange = true;
				planes.height = height;
				planes.transfer = VIDEO_COLOR_TRANSFER_SDR;
				planes.width = width;
				planes.y = &frame[0];
				planes.yStride = width;
				planes.u = planes.y + (size_t)width * height;
				planes.v = planes.u + 1;
				planes.uvPixelStride = 2;
				planes.uvStride = ((width + 1) / 2) * 2;
				PushFrame (&planes, time);

			}


		private:

			jobject capture;
			jmethodID closeMethod;
			jbyteArray data;
			int dataLength;
			std::vector<unsigned char> frame;
			jmethodID getFrameTimeMethod;
			jmethodID readMethod;
			jmethodID startMethod;
			jmethodID stopMethod;


	};


	bool CameraCapture::GetDevices (std::vector<CameraDeviceInfo>* devices) {

		JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv ();
		if (!env) return false;

		jclass captureClass = env->FindClass ("org/haxe/lime/CameraCapture");

		if (!captureClass) {

			ClearCameraException (env);
			return false;

		}

		jmethodID getDevicesMethod = env->GetStaticMethodID (captureClass, "getDevices", "()Ljava/lang/String;");
		jstring text = getDevicesMethod ? (jstring)env->CallStaticObjectMethod (captureClass, getDevicesMethod) : NULL;
		ClearCameraException (env);
		env->DeleteLocalRef (captureClass);

		if (!text) return false;

		std::string list = GetJavaString (env, text);
		env->DeleteLocalRef (text);

		size_t start = 0;

		while (start < list.size ()) {

			size_t end = list.find ('\x1E', start);
			if (end == std::string::npos) end = list.size ();

			std::string record = list.substr (start, end - start);
			size_t first = record.find ('\x1F');
			size_t second = first == std::string::npos ? std::string::npos : record.find ('\x1F', first + 1);

			if (second != std::string::npos) {

				CameraDeviceInfo info;
				info.id = record.substr (0, first);
				info.name = record.substr (first + 1, second - first - 1);
				char position = second + 1 < record.size () ? record[second + 1] : '0';
				info.position = position == '1' ? CAMERA_POSITION_FRONT : (position == '2' ? CAMERA_POSITION_BACK : CAMERA_POSITION_UNKNOWN);
				devices->push_back (info);

			}

			start = end + 1;

		}

		return true;

	}


	// Android's permission is asked and read through GameActivity, from Haxe
	int CameraCapture::GetPermissionStatus () {

		return 0;

	}


	bool CameraCapture::IsSupported () {

		return true;

	}


	CameraCapture* CameraCapture::Open (const char* id, int width, int height, double frameRate) {

		AndroidCameraCapture* capture = new AndroidCameraCapture ();

		if (!capture->Open (id, width > 0 ? width : 640, height > 0 ? height : 480, frameRate > 0 ? frameRate : 30)) {

			delete capture;
			return NULL;

		}

		return capture;

	}


	void CameraCapture::RequestPermission () {}


}


#endif
