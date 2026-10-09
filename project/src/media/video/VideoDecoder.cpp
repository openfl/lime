#include <media/VideoDecoder.h>
#include <string.h>


namespace lime {


	// Decoding stops once this many frames or seconds of audio are queued
	static const size_t MAX_QUEUED_FRAMES = 4;
	static const double MAX_QUEUED_AUDIO = 0.75;


	static inline unsigned char ClampByte (int value) {

		return value < 0 ? 0 : (value > 255 ? 255 : (unsigned char)value);

	}


	// Folds the WAVE channel orders (3: FL FR FC, 4: FL FR BL BR, 5: FL FR FC BL
	// BR, 6: FL FR FC LFE BL BR, 7.1 adds SL SR) into stereo, keeping the level
	void VideoBackend::DownmixToStereo (const short* in, int frames, int channels, std::vector<unsigned char>* pcm) {

		int center = (channels == 3 || channels == 5 || channels >= 6) ? 2 : -1;
		int backLeft = channels == 4 ? 2 : (channels == 5 ? 3 : (channels >= 6 ? 4 : -1));
		int sideLeft = channels >= 8 ? 6 : -1;
		float mix = 0.7071f;
		float scale = 1.0f / (1.0f + (center >= 0 ? mix : 0) + (backLeft >= 0 ? mix : 0) + (sideLeft >= 0 ? mix : 0));

		size_t offset = pcm->size ();
		pcm->resize (offset + frames * 4);
		short* out = (short*)(pcm->data () + offset);

		for (int i = 0; i < frames; i++) {

			const short* frame = in + i * channels;
			float left = frame[0];
			float right = frame[1];

			if (center >= 0) { left += frame[center] * mix; right += frame[center] * mix; }
			if (backLeft >= 0) { left += frame[backLeft] * mix; right += frame[backLeft + 1] * mix; }
			if (sideLeft >= 0) { left += frame[sideLeft] * mix; right += frame[sideLeft + 1] * mix; }

			out[i * 2] = (short)(left * scale);
			out[i * 2 + 1] = (short)(right * scale);

		}

	}


	VideoColorMatrix VideoBackend::GetDefaultColorMatrix (int width, int height) {

		// Streams without color information use BT.601 for SD and BT.709 for HD
		return (width > 1024 || height >= 600) ? VIDEO_COLOR_MATRIX_BT709 : VIDEO_COLOR_MATRIX_BT601;

	}


	#if !defined (LIME_VIDEO_MEDIA_FOUNDATION) && !defined (LIME_VIDEO_AVFOUNDATION) && !defined (LIME_VIDEO_MEDIACODEC) && !defined (LIME_VIDEO_GSTREAMER)

	VideoBackend* VideoBackend::Create () {

		return 0;

	}


	bool VideoBackend::IsSupported () {

		return false;

	}

	#endif


	VideoDecoder::VideoDecoder (VideoBackend* backend) : backend (backend) {

		audioEnded = true;
		audioError = false;
		audioQueued = 0;
		audioQueueEnd = 0;
		audioTime = 0;
		format = VIDEO_FRAME_FORMAT_NV12;
		frameColorMatrix = VIDEO_COLOR_MATRIX_BT709;
		frameDuration = 0;
		frameFullRange = false;
		frameHeight = 0;
		frameLength = 0;
		frameTime = 0;
		frameWidth = 0;
		memset (&info, 0, sizeof (info));
		open = false;
		quit = false;
		seekAccurate = false;
		seekPending = false;
		seekTime = 0;
		videoEnded = true;
		videoError = false;

	}


	VideoDecoder::~VideoDecoder () {

		Close ();
		delete backend;

	}


	void VideoDecoder::AudioThread () {

		std::vector<unsigned char> pcm;
		int blockAlign = info.audioChannels * 2;
		double bytesPerSecond = (double)info.audioSampleRate * blockAlign;
		size_t maxQueued = (size_t)(bytesPerSecond * MAX_QUEUED_AUDIO);

		while (true) {

			{
				std::unique_lock<std::mutex> lock (mutex);
				audioCondition.wait (lock, [this, maxQueued] { return quit || (!seekPending && !audioEnded && audioQueued < maxQueued); });
				if (quit) break;
			}

			std::lock_guard<std::mutex> decodeLock (audioDecodeMutex);

			pcm.clear ();
			double time = 0;
			VideoDecodeResult result = backend->DecodeAudio (&pcm, &time);

			if (result != VIDEO_DECODE_OK) {

				std::lock_guard<std::mutex> lock (mutex);
				audioEnded = true;
				audioError = (result == VIDEO_DECODE_ERROR);
				continue;

			}

			size_t offset = 0;
			size_t length = pcm.size () - (pcm.size () % blockAlign);

			if (seekAccurate && time < seekTime) {

				// Drop the audio before an accurate seek target
				size_t skip = (size_t)((seekTime - time) * info.audioSampleRate + 0.5) * blockAlign;
				if (skip >= length) continue;
				offset = skip;
				time = seekTime;

			}

			if (offset >= length) continue;

			std::lock_guard<std::mutex> lock (mutex);

			AudioChunk* chunk;

			if (freeChunks.empty ()) {

				chunk = new AudioChunk ();

			} else {

				chunk = freeChunks.back ();
				freeChunks.pop_back ();

			}

			chunk->data.assign (pcm.begin () + offset, pcm.begin () + length);
			chunk->offset = 0;
			chunk->time = time;

			audioChunks.push_back (chunk);
			audioQueued += chunk->data.size ();
			audioQueueEnd = time + chunk->data.size () / bytesPerSecond;

		}

	}


	void VideoDecoder::Close () {

		if (!open) return;

		StopThreads ();
		backend->Close ();

		std::lock_guard<std::mutex> lock (mutex);
		Flush ();

		for (size_t i = 0; i < freeChunks.size (); i++) delete freeChunks[i];
		for (size_t i = 0; i < freeFrames.size (); i++) delete freeFrames[i];
		freeChunks.clear ();
		freeFrames.clear ();

		open = false;
		audioEnded = true;
		videoEnded = true;
		memset (&info, 0, sizeof (info));

	}


	void VideoDecoder::Flush () {

		for (size_t i = 0; i < audioChunks.size (); i++) freeChunks.push_back (audioChunks[i]);
		for (size_t i = 0; i < frames.size (); i++) freeFrames.push_back (frames[i]);

		audioChunks.clear ();
		audioQueued = 0;
		frames.clear ();

	}


	int VideoDecoder::GetFrameLength (VideoFrameFormat format, int width, int height) {

		if (width <= 0 || height <= 0) return 0;

		switch (format) {

			case VIDEO_FRAME_FORMAT_NV12: return width * height + ((width + 1) / 2) * 2 * ((height + 1) / 2);
			case VIDEO_FRAME_FORMAT_RGBA: return width * height * 4;
			default: return 0;

		}

	}


	bool VideoDecoder::Open (const char* path, bool hardwareDecoding, VideoFrameFormat format) {

		Close ();

		if (!backend || !path) return false;

		VideoStreamInfo streamInfo;
		memset (&streamInfo, 0, sizeof (streamInfo));

		if (!backend->Open (path, hardwareDecoding, &streamInfo)) {

			backend->Close ();
			return false;

		}

		if (streamInfo.audioChannels < 1 || streamInfo.audioChannels > 2 || streamInfo.audioSampleRate <= 0) {

			streamInfo.hasAudio = false;

		}

		if (!streamInfo.hasAudio) {

			streamInfo.audioChannels = 0;
			streamInfo.audioSampleRate = 0;

		}

		if (!streamInfo.hasAudio && !streamInfo.hasVideo) {

			backend->Close ();
			return false;

		}

		info = streamInfo;
		this->format = format;

		audioEnded = !info.hasAudio;
		audioError = false;
		audioQueueEnd = 0;
		audioTime = 0;
		frameColorMatrix = VideoBackend::GetDefaultColorMatrix (info.width, info.height);
		frameDuration = info.frameRate > 0 ? 1.0 / info.frameRate : 0;
		frameFullRange = false;
		frameHeight = info.height;
		frameLength = GetFrameLength (format, info.width, info.height);
		frameTime = 0;
		frameWidth = info.width;
		seekAccurate = false;
		seekPending = false;
		seekTime = 0;
		videoEnded = !info.hasVideo;
		videoError = false;

		open = true;
		StartThreads ();
		return true;

	}


	int VideoDecoder::ReadAudio (unsigned char* data, int length) {

		std::lock_guard<std::mutex> lock (mutex);

		if (!open || !info.hasAudio) return VIDEO_READ_END;

		int blockAlign = info.audioChannels * 2;
		double bytesPerSecond = (double)info.audioSampleRate * blockAlign;
		length -= length % blockAlign;

		int written = 0;

		while (written < length && !audioChunks.empty ()) {

			AudioChunk* chunk = audioChunks.front ();
			size_t available = chunk->data.size () - chunk->offset;
			size_t count = (size_t)(length - written) < available ? (size_t)(length - written) : available;

			memcpy (data + written, chunk->data.data () + chunk->offset, count);
			chunk->offset += count;
			written += (int)count;
			audioQueued -= count;

			if (chunk->offset >= chunk->data.size ()) {

				audioTime = chunk->time + chunk->data.size () / bytesPerSecond;
				audioChunks.pop_front ();
				freeChunks.push_back (chunk);

			} else {

				audioTime = chunk->time + chunk->offset / bytesPerSecond;

			}

		}

		if (written > 0) {

			audioCondition.notify_one ();
			return written;

		}

		if (audioEnded) return audioError ? VIDEO_READ_ERROR : VIDEO_READ_END;
		return VIDEO_READ_NOT_READY;

	}


	int VideoDecoder::ReadFrame (unsigned char* data, int length, double time) {

		std::lock_guard<std::mutex> lock (mutex);

		if (!open || !info.hasVideo) return VIDEO_READ_END;

		bool dropped = false;

		if (time >= 0) {

			// Drop frames that a later queued frame replaces by time
			while (frames.size () > 1 && frames[1]->time <= time) {

				freeFrames.push_back (frames.front ());
				frames.pop_front ();
				dropped = true;

			}

		}

		if (dropped) videoCondition.notify_one ();

		if (frames.empty ()) {

			if (videoEnded) return videoError ? VIDEO_READ_ERROR : VIDEO_READ_END;
			return VIDEO_READ_NOT_READY;

		}

		Frame* frame = frames.front ();

		if (time >= 0 && frame->time > time) return VIDEO_READ_NOT_READY;

		frameColorMatrix = frame->colorMatrix;
		frameDuration = frame->duration;
		frameFullRange = frame->fullRange;
		frameHeight = frame->height;
		frameLength = frame->length;
		frameTime = frame->time;
		frameWidth = frame->width;

		if (!data || length < frame->length) return VIDEO_READ_BUFFER_TOO_SMALL;

		memcpy (data, frame->data.data (), frame->length);

		frames.pop_front ();
		freeFrames.push_back (frame);
		videoCondition.notify_one ();

		return frameLength;

	}


	void VideoDecoder::Seek (double time, bool accurate) {

		if (!open) return;
		if (time < 0) time = 0;

		{
			std::lock_guard<std::mutex> lock (mutex);
			seekPending = true;
			Flush ();
		}

		audioCondition.notify_all ();
		videoCondition.notify_all ();

		// Wait for the frame or packet in progress, then seek with both streams idle
		std::lock_guard<std::mutex> videoLock (videoDecodeMutex);
		std::lock_guard<std::mutex> audioLock (audioDecodeMutex);

		backend->Seek (time);

		std::lock_guard<std::mutex> lock (mutex);
		Flush ();

		audioEnded = !info.hasAudio;
		audioError = false;
		audioQueueEnd = time;
		audioTime = time;
		frameTime = time;
		seekAccurate = accurate;
		seekPending = false;
		seekTime = time;
		videoEnded = !info.hasVideo;
		videoError = false;

		audioCondition.notify_all ();
		videoCondition.notify_all ();

	}


	void VideoDecoder::StartThreads () {

		quit = false;

		if (info.hasAudio) audioThread = std::thread (&VideoDecoder::AudioThread, this);
		if (info.hasVideo) videoThread = std::thread (&VideoDecoder::VideoThread, this);

	}


	void VideoDecoder::StopThreads () {

		{
			std::lock_guard<std::mutex> lock (mutex);
			quit = true;
			Flush ();
		}

		audioCondition.notify_all ();
		videoCondition.notify_all ();

		if (audioThread.joinable ()) audioThread.join ();
		if (videoThread.joinable ()) videoThread.join ();

	}


	void VideoDecoder::VideoThread () {

		while (true) {

			{
				std::unique_lock<std::mutex> lock (mutex);
				videoCondition.wait (lock, [this] { return quit || (!seekPending && !videoEnded && frames.size () < MAX_QUEUED_FRAMES); });
				if (quit) break;
			}

			std::lock_guard<std::mutex> decodeLock (videoDecodeMutex);

			VideoPlanes planes;
			double time = 0;
			double duration = 0;
			VideoDecodeResult result = backend->DecodeVideo (&planes, &time, &duration);

			if (result != VIDEO_DECODE_OK) {

				std::lock_guard<std::mutex> lock (mutex);
				videoEnded = true;
				videoError = (result == VIDEO_DECODE_ERROR);
				continue;

			}

			if (duration <= 0) duration = info.frameRate > 0 ? 1.0 / info.frameRate : 0;

			// Drop the frames that end before an accurate seek target
			if (seekAccurate && time + duration <= seekTime + 0.0001) continue;

			int length = GetFrameLength (format, planes.width, planes.height);
			if (length <= 0) continue;

			Frame* frame = 0;

			{
				std::lock_guard<std::mutex> lock (mutex);

				if (!freeFrames.empty ()) {

					frame = freeFrames.back ();
					freeFrames.pop_back ();

				}
			}

			if (!frame) frame = new Frame ();

			if ((int)frame->data.size () < length) frame->data.resize (length);

			frame->colorMatrix = planes.colorMatrix;
			frame->duration = duration;
			frame->fullRange = planes.fullRange;
			frame->height = planes.height;
			frame->length = WriteFrame (&planes, format, frame->data.data (), (int)frame->data.size ());
			frame->time = time;
			frame->width = planes.width;

			std::lock_guard<std::mutex> lock (mutex);

			if (frame->length > 0) {

				frames.push_back (frame);

			} else {

				freeFrames.push_back (frame);

			}

		}

	}


	int VideoDecoder::WriteFrame (const VideoPlanes* planes, VideoFrameFormat format, unsigned char* data, int length) {

		int frameLength = GetFrameLength (format, planes->width, planes->height);

		if (frameLength <= 0 || !data) return VIDEO_READ_ERROR;
		if (length < frameLength) return VIDEO_READ_BUFFER_TOO_SMALL;

		int width = planes->width;
		int height = planes->height;
		int chromaWidth = (width + 1) / 2;
		int chromaHeight = (height + 1) / 2;
		int pixelStride = planes->uvPixelStride;

		if (format == VIDEO_FRAME_FORMAT_NV12) {

			for (int row = 0; row < height; row++) {

				memcpy (data + row * width, planes->y + row * planes->yStride, width);

			}

			unsigned char* uv = data + width * height;
			bool interleaved = (pixelStride == 2 && planes->v == planes->u + 1);

			for (int row = 0; row < chromaHeight; row++) {

				unsigned char* out = uv + row * chromaWidth * 2;
				const unsigned char* u = planes->u + row * planes->uvStride;

				if (interleaved) {

					memcpy (out, u, chromaWidth * 2);

				} else {

					const unsigned char* v = planes->v + row * planes->uvStride;

					for (int x = 0; x < chromaWidth; x++) {

						out[x * 2] = u[x * pixelStride];
						out[x * 2 + 1] = v[x * pixelStride];

					}

				}

			}

			return frameLength;

		}

		// Kr and Kb from ITU-R BT.601, BT.709 and BT.2020

		double kr, kb;

		switch (planes->colorMatrix) {

			case VIDEO_COLOR_MATRIX_BT601: kr = 0.299; kb = 0.114; break;
			case VIDEO_COLOR_MATRIX_BT2020: kr = 0.2627; kb = 0.0593; break;
			default: kr = 0.2126; kb = 0.0722; break;

		}

		double kg = 1.0 - kr - kb;
		double yScale = planes->fullRange ? 1.0 : 255.0 / 219.0;
		double cScale = planes->fullRange ? 1.0 : 255.0 / 224.0;
		int yOffset = planes->fullRange ? 0 : 16;

		int yFactor = (int)(yScale * 65536.0 + 0.5);
		int rv = (int)(2.0 * (1.0 - kr) * cScale * 65536.0 + 0.5);
		int gu = (int)(2.0 * kb * (1.0 - kb) / kg * cScale * 65536.0 + 0.5);
		int gv = (int)(2.0 * kr * (1.0 - kr) / kg * cScale * 65536.0 + 0.5);
		int bu = (int)(2.0 * (1.0 - kb) * cScale * 65536.0 + 0.5);

		for (int row = 0; row < height; row++) {

			const unsigned char* y = planes->y + row * planes->yStride;
			const unsigned char* u = planes->u + (row / 2) * planes->uvStride;
			const unsigned char* v = planes->v + (row / 2) * planes->uvStride;
			unsigned char* out = data + row * width * 4;

			for (int x = 0; x < width; x++) {

				int cu = u[(x / 2) * pixelStride] - 128;
				int cv = v[(x / 2) * pixelStride] - 128;
				int luma = (y[x] - yOffset) * yFactor + 32768;

				out[0] = ClampByte ((luma + rv * cv) >> 16);
				out[1] = ClampByte ((luma - gu * cu - gv * cv) >> 16);
				out[2] = ClampByte ((luma + bu * cu) >> 16);
				out[3] = 255;
				out += 4;

			}

		}

		return frameLength;

	}


}
