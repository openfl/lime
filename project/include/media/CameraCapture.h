#ifndef LIME_MEDIA_CAMERA_CAPTURE_H
#define LIME_MEDIA_CAMERA_CAPTURE_H


#include <media/VideoDecoder.h>
#include <mutex>
#include <string>
#include <vector>


namespace lime {


	enum CameraPosition {

		CAMERA_POSITION_UNKNOWN = 0,
		CAMERA_POSITION_FRONT = 1,
		CAMERA_POSITION_BACK = 2

	};


	struct CameraDeviceInfo {

		std::string id;
		std::string name;
		CameraPosition position;

	};


	// A camera's frames, captured on a thread or callback of the platform's and
	// kept as the latest NV12 picture for the application to read
	class CameraCapture {


		public:

			// Lists the cameras, the default one first. Returns false where cameras
			// cannot be listed at all.
			static bool GetDevices (std::vector<CameraDeviceInfo>* devices);

			// 0 undetermined, 1 granted and 2 denied, as AudioInput's permission
			static int GetPermissionStatus ();
			static bool IsSupported ();

			// Opens the camera with id, or the default camera when id is null, at the
			// size and rate closest to those asked for. Returns null when it cannot.
			static CameraCapture* Open (const char* id, int width, int height, double frameRate);

			static void RequestPermission ();

			virtual ~CameraCapture ();

			virtual void Close () = 0;
			virtual bool Start () = 0;
			virtual void Stop () = 0;

			bool IsConnected ();

			// Copies the newest frame in format and returns the number of bytes
			// written, VIDEO_READ_NOT_READY when no frame came since the last read,
			// or VIDEO_READ_BUFFER_TOO_SMALL when it needs frameLength bytes
			int ReadFrame (VideoFrameFormat format, unsigned char* data, int length);

			double frameRate;
			VideoColorMatrix frameColorMatrix;
			bool frameFullRange;
			int frameHeight;
			int frameLength;
			double frameTime;
			int frameWidth;
			int height;
			int width;


		protected:

			CameraCapture ();

			// Keeps a frame given as planes, from the platform's thread
			void PushFrame (const VideoPlanes* planes, double time);
			void SetDisconnected ();

			// Called before a frame is read or the connection checked, for platforms
			// that are polled for frames
			virtual void Update () {}


		private:

			std::vector<unsigned char> buffer;
			VideoColorMatrix bufferColorMatrix;
			bool bufferFullRange;
			int bufferHeight;
			double bufferTime;
			int bufferWidth;
			bool connected;
			std::mutex mutex;
			bool pending;


	};


}


#endif
