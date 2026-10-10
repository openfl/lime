#ifndef LIME_MEDIA_VIDEO_DECODER_H
#define LIME_MEDIA_VIDEO_DECODER_H


#include <atomic>
#include <condition_variable>
#include <deque>
#include <mutex>
#include <thread>
#include <vector>

#if defined (HX_WINDOWS) && !defined (HX_WINRT)
#define LIME_VIDEO_MEDIA_FOUNDATION
#elif defined (HX_MACOS) || (defined (IPHONE) && !defined (APPLETV))
#define LIME_VIDEO_AVFOUNDATION
#elif defined (HX_ANDROID)
#define LIME_VIDEO_MEDIACODEC
#elif defined (HX_LINUX) && !defined (EMSCRIPTEN)
#define LIME_VIDEO_GSTREAMER
#endif


namespace lime {


	enum VideoColorMatrix {

		VIDEO_COLOR_MATRIX_BT601 = 0,
		VIDEO_COLOR_MATRIX_BT709 = 1,
		VIDEO_COLOR_MATRIX_BT2020 = 2

	};


	enum VideoDecodeResult {

		VIDEO_DECODE_OK = 1,
		VIDEO_DECODE_END = 0,
		VIDEO_DECODE_ERROR = -1

	};


	enum VideoFrameFormat {

		VIDEO_FRAME_FORMAT_NV12 = 0,
		VIDEO_FRAME_FORMAT_RGBA = 1,
		VIDEO_FRAME_FORMAT_TEXTURE = 2

	};


	enum VideoReadResult {

		VIDEO_READ_NOT_READY = 0,
		VIDEO_READ_END = -1,
		VIDEO_READ_ERROR = -2,
		VIDEO_READ_BUFFER_TOO_SMALL = -3

	};


	// A decoded picture in system memory. NV12 sets u to the interleaved UV
	// plane, v to u + 1 and uvPixelStride to 2. I420 uses separate U and V
	// planes with a uvPixelStride of 1.
	struct VideoPlanes {

		VideoColorMatrix colorMatrix;
		bool fullRange;
		int height;
		const unsigned char* u;
		int uvPixelStride;
		int uvStride;
		const unsigned char* v;
		int width;
		const unsigned char* y;
		int yStride;

	};


	// A decoded frame kept on the GPU by a backend that supports texture output
	class VideoTextureFrame {


		public:

			virtual ~VideoTextureFrame () {};

			int height;
			int width;


	};


	struct VideoStreamInfo {

		int audioChannels;
		int audioSampleRate;
		double duration;
		double frameRate;
		bool hasAudio;
		bool hasVideo;
		int height;
		int width;

	};


	// Platform decoding. VideoDecoder calls DecodeAudio and DecodeVideo from
	// two threads at once, so the streams must not share decoder state. Open,
	// Close and Seek are only called while neither stream is decoding.
	class VideoBackend {


		public:

			virtual ~VideoBackend () {};

			virtual void Close () = 0;

			// Appends the next packet of interleaved signed 16-bit PCM with
			// info->audioChannels channels to pcm, and sets time to the time of
			// its first sample in seconds.
			virtual VideoDecodeResult DecodeAudio (std::vector<unsigned char>* pcm, double* time) = 0;

			// Decodes the next frame. The planes stay valid until the next call to
			// DecodeVideo, Seek or Close.
			virtual VideoDecodeResult DecodeVideo (VideoPlanes* planes, double* time, double* duration) = 0;

			virtual bool Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info) = 0;

			// Seeks both streams to the keyframe at or before time.
			virtual bool Seek (double time) = 0;

			// Texture output keeps frames on the GPU, which backends support by
			// returning true from SupportsTextures once open. DecodeVideoTexture
			// decodes the next frame like DecodeVideo, on the video thread. It
			// returns VIDEO_DECODE_OK without a frame when it stops supporting
			// textures, and the next frame is read with DecodeVideo.
			virtual VideoDecodeResult DecodeVideoTexture (VideoTextureFrame** frame, double* time, double* duration) { return VIDEO_DECODE_ERROR; }
			virtual bool SupportsTextures () { return false; }

			// With the application's GL context current, makes a frame available
			// as an RGBA GL_TEXTURE_2D until UnlockTexture, and returns its name,
			// or 0 when this context cannot share the backend's textures.
			virtual unsigned int LockTexture (VideoTextureFrame* frame) { return 0; }
			virtual void UnlockTexture (VideoTextureFrame* frame) {}

			// Gives a frame back to the backend, from any thread.
			virtual void ReleaseTextureFrame (VideoTextureFrame* frame) {}

			// Deletes the backend's GL objects, with the GL context current.
			virtual void ReleaseTextures () {}

			static VideoBackend* Create ();
			static bool IsSupported ();

			static void DownmixToStereo (const short* in, int frames, int channels, std::vector<unsigned char>* pcm);
			static VideoColorMatrix GetDefaultColorMatrix (int width, int height);


	};


	// Decodes a video on two background threads, one per stream, and queues
	// a few frames and a fraction of a second of audio ahead of the reader.
	class VideoDecoder {


		public:

			VideoDecoder (VideoBackend* backend);
			~VideoDecoder ();

			void Close ();
			bool Open (const char* path, bool hardwareDecoding, VideoFrameFormat format);

			// Returns the number of bytes written, VIDEO_READ_NOT_READY when no
			// audio is buffered yet, VIDEO_READ_END or VIDEO_READ_ERROR. Audio is
			// interleaved signed 16-bit PCM.
			int ReadAudio (unsigned char* data, int length);

			// Copies the next frame in the open format and returns the number of
			// bytes written. When time is not negative, frames that ended by time
			// are dropped and a frame is only returned once it starts by time.
			// Returns VIDEO_READ_NOT_READY when no frame is due, VIDEO_READ_END,
			// VIDEO_READ_ERROR, or VIDEO_READ_BUFFER_TOO_SMALL when the frame needs
			// frameLength bytes. The frame then stays queued.
			//
			// With VIDEO_FRAME_FORMAT_TEXTURE, call it with the GL context current.
			// It returns 1 for a new frame, which frameTexture shows until the next
			// call. Close the decoder on that thread too, so it can delete textures.
			int ReadFrame (unsigned char* data, int length, double time);

			// Seeks both streams. An accurate seek drops the frames and audio
			// before time, otherwise reading resumes from the preceding keyframe.
			void Seek (double time, bool accurate);

			static int GetFrameLength (VideoFrameFormat format, int width, int height);
			static int WriteFrame (const VideoPlanes* planes, VideoFrameFormat format, unsigned char* data, int length);

			double audioTime;
			VideoFrameFormat format;
			VideoColorMatrix frameColorMatrix;
			double frameDuration;
			bool frameFullRange;
			int frameHeight;
			int frameLength;
			unsigned int frameTexture;
			double frameTime;
			int frameWidth;
			VideoStreamInfo info;

		private:

			struct AudioChunk {

				std::vector<unsigned char> data;
				size_t offset;
				double time;

			};

			struct Frame {

				VideoColorMatrix colorMatrix;
				std::vector<unsigned char> data;
				double duration;
				bool fullRange;
				int height;
				int length;
				VideoTextureFrame* texture;
				double time;
				int width;

			};

			void AudioThread ();
			void Flush ();
			bool IsTextureThread ();
			int ReadTexture (double time);
			void ReleaseFrame (Frame* frame);
			void ReleaseTextures ();
			void StartThreads ();
			void StopThreads ();
			unsigned int UploadTexture (Frame* frame);
			void VideoThread ();

			std::deque<AudioChunk*> audioChunks;
			std::condition_variable audioCondition;
			std::mutex audioDecodeMutex;
			bool audioEnded;
			bool audioError;
			size_t audioQueued;
			double audioQueueEnd;
			std::thread audioThread;
			VideoBackend* backend;
			Frame* currentFrame;
			std::vector<AudioChunk*> freeChunks;
			std::vector<Frame*> freeFrames;
			std::deque<Frame*> frames;
			std::mutex mutex;
			bool open;
			bool quit;
			bool seekAccurate;
			bool seekPending;
			double seekTime;
			unsigned int texture;
			int textureHeight;
			std::atomic<bool> texturesFailed;
			std::thread::id textureThread;
			bool textureThreadKnown;
			int textureWidth;
			std::condition_variable videoCondition;
			std::mutex videoDecodeMutex;
			bool videoEnded;
			bool videoError;
			std::thread videoThread;


	};


}


#endif
