#include <media/CameraCapture.h>
#include <string.h>


namespace lime {


	CameraCapture::CameraCapture () {

		frameRate = 0;
		frameColorMatrix = VIDEO_COLOR_MATRIX_BT601;
		frameFullRange = false;
		frameHeight = 0;
		frameLength = 0;
		frameTime = 0;
		frameWidth = 0;
		height = 0;
		width = 0;

		bufferColorMatrix = VIDEO_COLOR_MATRIX_BT601;
		bufferFullRange = false;
		bufferHeight = 0;
		bufferTime = 0;
		bufferWidth = 0;
		connected = true;
		pending = false;

	}


	CameraCapture::~CameraCapture () {}


	bool CameraCapture::IsConnected () {

		Update ();
		std::lock_guard<std::mutex> lock (mutex);
		return connected;

	}


	void CameraCapture::PushFrame (const VideoPlanes* planes, double time) {

		int frameWidth = planes->width;
		int frameHeight = planes->height;
		if (frameWidth <= 0 || frameHeight <= 0) return;

		int chromaWidth = (frameWidth + 1) >> 1;
		int chromaHeight = (frameHeight + 1) >> 1;

		std::lock_guard<std::mutex> lock (mutex);

		buffer.resize ((size_t)frameWidth * frameHeight + (size_t)chromaWidth * 2 * chromaHeight);
		unsigned char* y = &buffer[0];
		unsigned char* uv = y + (size_t)frameWidth * frameHeight;

		for (int row = 0; row < frameHeight; row++) {

			memcpy (y + (size_t)row * frameWidth, planes->y + (size_t)row * planes->yStride, frameWidth);

		}

		for (int row = 0; row < chromaHeight; row++) {

			const unsigned char* u = planes->u + (size_t)row * planes->uvStride;
			const unsigned char* v = planes->v + (size_t)row * planes->uvStride;
			unsigned char* target = uv + (size_t)row * chromaWidth * 2;

			if (planes->uvPixelStride == 2 && v == u + 1) {

				memcpy (target, u, (size_t)chromaWidth * 2);

			} else {

				for (int column = 0; column < chromaWidth; column++) {

					target[column * 2] = u[column * planes->uvPixelStride];
					target[column * 2 + 1] = v[column * planes->uvPixelStride];

				}

			}

		}

		bufferColorMatrix = planes->colorMatrix;
		bufferFullRange = planes->fullRange;
		bufferHeight = frameHeight;
		bufferTime = time;
		bufferWidth = frameWidth;
		pending = true;

	}


	int CameraCapture::ReadFrame (VideoFrameFormat format, unsigned char* data, int length) {

		Update ();
		std::lock_guard<std::mutex> lock (mutex);

		if (!pending) return VIDEO_READ_NOT_READY;

		// Frames are kept in memory, so a texture is read as RGBA
		if (format == VIDEO_FRAME_FORMAT_TEXTURE) format = VIDEO_FRAME_FORMAT_RGBA;

		int needed = VideoDecoder::GetFrameLength (format, bufferWidth, bufferHeight);

		if (!data || length < needed) {

			frameLength = needed;
			return VIDEO_READ_BUFFER_TOO_SMALL;

		}

		VideoPlanes planes;
		planes.colorMatrix = bufferColorMatrix;
		planes.fullRange = bufferFullRange;
		planes.height = bufferHeight;
		planes.transfer = VIDEO_COLOR_TRANSFER_SDR;
		planes.width = bufferWidth;
		planes.y = &buffer[0];
		planes.yStride = bufferWidth;
		planes.u = planes.y + (size_t)bufferWidth * bufferHeight;
		planes.v = planes.u + 1;
		planes.uvPixelStride = 2;
		planes.uvStride = ((bufferWidth + 1) >> 1) * 2;

		int written = VideoDecoder::WriteFrame (&planes, format, data, length);
		if (written <= 0) return VIDEO_READ_ERROR;

		frameColorMatrix = bufferColorMatrix;
		frameFullRange = bufferFullRange;
		frameHeight = bufferHeight;
		frameLength = written;
		frameTime = bufferTime;
		frameWidth = bufferWidth;
		pending = false;
		return written;

	}


	void CameraCapture::SetDisconnected () {

		std::lock_guard<std::mutex> lock (mutex);
		connected = false;

	}


	#if !defined (LIME_VIDEO_MEDIA_FOUNDATION) && !defined (LIME_VIDEO_AVFOUNDATION) && !defined (LIME_VIDEO_MEDIACODEC) && !defined (LIME_VIDEO_GSTREAMER)
	bool CameraCapture::GetDevices (std::vector<CameraDeviceInfo>* devices) { return false; }
	int CameraCapture::GetPermissionStatus () { return 2; }
	bool CameraCapture::IsSupported () { return false; }
	CameraCapture* CameraCapture::Open (const char* id, int width, int height, double frameRate) { return NULL; }
	void CameraCapture::RequestPermission () {}
	#endif


}
