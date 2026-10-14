#include <media/VideoDecoder.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <algorithm>
#include <map>

#if defined (LIME_OPENGL) && !defined (LIME_VIDEO_STANDALONE)
#define LIME_VIDEO_TEXTURES
#include "../../graphics/opengl/OpenGL.h"
#include "../../graphics/opengl/OpenGLBindings.h"
#ifdef NEED_EXTENSIONS
#define DECLARE_EXTENSION
#include "../../graphics/opengl/OpenGLExtensions.h"
#undef DECLARE_EXTENSION
#endif
#ifdef LIME_SDL
#include <SDL.h>
#endif
#endif

#ifndef GL_PIXEL_UNPACK_BUFFER
#define GL_PIXEL_UNPACK_BUFFER 0x88EC
#endif
#ifndef GL_PIXEL_UNPACK_BUFFER_BINDING
#define GL_PIXEL_UNPACK_BUFFER_BINDING 0x88EF
#endif
#ifndef GL_UNPACK_ROW_LENGTH
#define GL_UNPACK_ROW_LENGTH 0x0CF2
#endif


namespace lime {


	// Textures of decoders closed away from the GL thread, deleted the next
	// time any decoder reads a texture frame where their context is current
	struct OrphanTexture {

		unsigned int name;
		void* context;

	};

	// Never destroyed, as exiting on Android and Linux runs static destructors
	// while threads can still be closing videos
	static std::mutex* orphanMutex = new std::mutex ();
	static std::vector<OrphanTexture>* orphanTextures = new std::vector<OrphanTexture> ();


	static void ReleaseOrphans (VideoBackend* backend) {

		#ifdef LIME_VIDEO_TEXTURES
		std::vector<OrphanTexture> textures;

		{
			std::lock_guard<std::mutex> lock (*orphanMutex);
			textures.swap (*orphanTextures);
		}

		void* context = VideoBackend::GetCurrentGLContext ();

		for (size_t i = 0; i < textures.size (); i++) {

			// A texture made in a context that has since been replaced went with it
			if (textures[i].context == context) glDeleteTextures (1, &textures[i].name);

		}
		#endif

		backend->ReleaseOrphans ();

	}


	// Decoding stops once this many frames or seconds of audio are queued
	static const size_t MAX_QUEUED_FRAMES = 4;
	static const double MAX_QUEUED_AUDIO = 0.75;

	// HDR is shown as ITU-R BT.2408 suggests, with its reference white, 203
	// nits, as standard range white, and highlights up to 1000 nits rolled off
	// into it by the curve of BT.2390. HLG is taken as shown on a 1000 nit
	// display. The tone map table holds every luma for chroma in steps of 4.
	static const double TONE_MAP_PEAK = 1000.0;
	static const double TONE_MAP_WHITE = 203.0;
	static const int TONE_MAP_CHROMA_STEP = 4;
	static const int TONE_MAP_CHROMA_NODES = 256 / TONE_MAP_CHROMA_STEP + 1;


	static inline unsigned char ClampByte (int value) {

		return value < 0 ? 0 : (value > 255 ? 255 : (unsigned char)value);

	}


	void VideoBackend::ConvertAudio (const short* in, int frames, int channels, int rate, int outChannels, int outRate, VideoAudioConverter* converter, std::vector<unsigned char>* pcm) {

		if (frames <= 0 || channels <= 0 || rate <= 0 || outChannels < 1 || outChannels > 2 || outRate <= 0) return;

		// Mix the channels first, folding surround into stereo
		std::vector<unsigned char> stereo;
		std::vector<short> mixed (frames * outChannels);

		if (channels > 2) {

			DownmixToStereo (in, frames, channels, &stereo);
			in = (const short*)stereo.data ();
			channels = 2;

		}

		for (int i = 0; i < frames; i++) {

			if (channels == outChannels) {

				for (int c = 0; c < outChannels; c++) mixed[i * outChannels + c] = in[i * channels + c];

			} else if (channels == 1) {

				mixed[i * 2] = mixed[i * 2 + 1] = in[i];

			} else {

				mixed[i] = (short)(((int)in[i * 2] + in[i * 2 + 1]) / 2);

			}

		}

		if (converter->previousChannels != outChannels) {

			// Nothing comes before the first packet, so it starts on its first frame
			converter->position = 0;
			converter->previousChannels = outChannels;
			for (int c = 0; c < outChannels; c++) converter->previous[c] = mixed[c];

		}

		if (rate == outRate) {

			converter->position = 0;
			for (int c = 0; c < outChannels; c++) converter->previous[c] = mixed[(frames - 1) * outChannels + c];
			pcm->insert (pcm->end (), (const unsigned char*)mixed.data (), (const unsigned char*)(mixed.data () + mixed.size ()));
			return;

		}

		// Linear interpolation, where a position below 0 lies between the last
		// frame of the previous packet and the first of this one
		double step = (double)rate / outRate;
		double position = converter->position;
		size_t offset = pcm->size ();
		size_t count = position < frames - 1 ? (size_t)((frames - 1 - position) / step) + 1 : 0;
		pcm->resize (offset + count * outChannels * 2);
		short* out = (short*)(pcm->data () + offset);
		size_t written = 0;

		while (position < frames - 1 && written < count) {

			int index = (int)floor (position);
			double t = position - index;

			for (int c = 0; c < outChannels; c++) {

				double a = index < 0 ? converter->previous[c] : mixed[index * outChannels + c];
				double b = mixed[(index + 1) * outChannels + c];
				out[written * outChannels + c] = (short)(a + (b - a) * t);

			}

			written++;
			position += step;

		}

		pcm->resize (offset + written * outChannels * 2);
		converter->position = position - frames;
		for (int c = 0; c < outChannels; c++) converter->previous[c] = mixed[(frames - 1) * outChannels + c];

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


	void* VideoBackend::GetCurrentGLContext () {

		// Lime makes its contexts current through SDL, which keeps track of them
		#if defined (LIME_VIDEO_TEXTURES) && defined (LIME_SDL)
		return SDL_GL_GetCurrentContext ();
		#else
		return 0;
		#endif

	}


	VideoColorMatrix VideoBackend::GetDefaultColorMatrix (int width, int height) {

		// Streams without color information use BT.601 for SD and BT.709 for HD
		return (width > 1024 || height >= 600) ? VIDEO_COLOR_MATRIX_BT709 : VIDEO_COLOR_MATRIX_BT601;

	}


	int VideoBackend::NormalizeRotation (int degrees) {

		// Rounded to the nearest quarter turn
		degrees = ((degrees % 360) + 360) % 360;
		return ((degrees + 45) / 90) % 4 * 90;

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

		runningThreads = 0;

		audioEnded = true;
		audioError = false;
		audioQueued = 0;
		audioQueueEnd = 0;
		audioSeekTime = 0;
		audioTime = 0;
		currentFrame = 0;
		dropLateFrames = true;
		droppedFrames = 0;
		format = VIDEO_FRAME_FORMAT_NV12;
		frameColorMatrix = VIDEO_COLOR_MATRIX_BT709;
		frameDuration = 0;
		frameFullRange = false;
		frameHeight = 0;
		frameLength = 0;
		frameTexture = 0;
		frameTime = 0;
		frameWidth = 0;
		memset (&info, 0, sizeof (info));
		open = false;
		presentationTime = -1;
		quit = false;
		seekAccurate = false;
		seekPending = false;
		texture = 0;
		textureContext = 0;
		textureHeight = 0;
		texturesFailed = false;
		textureThreadKnown = false;
		textureWidth = 0;
		videoEnded = true;
		videoError = false;
		videoSeekTime = 0;

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

			if (result == VIDEO_DECODE_AGAIN) continue;

			if (result != VIDEO_DECODE_OK) {

				std::lock_guard<std::mutex> lock (mutex);
				audioEnded = true;
				audioError = (result == VIDEO_DECODE_ERROR);
				continue;

			}

			size_t offset = 0;
			size_t length = pcm.size () - (pcm.size () % blockAlign);

			if (seekAccurate && time < audioSeekTime) {

				// Drop the audio before an accurate seek target
				size_t skip = (size_t)((audioSeekTime - time) * info.audioSampleRate + 0.5) * blockAlign;
				if (skip >= length) continue;
				offset = skip;
				time = audioSeekTime;

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

		if (currentFrame) {

			if (currentFrame->texture && IsTextureThread ()) backend->UnlockTexture (currentFrame->texture);

			std::lock_guard<std::mutex> lock (mutex);
			ReleaseFrame (currentFrame);
			currentFrame = 0;

		}

		{
			std::lock_guard<std::mutex> lock (mutex);
			Flush ();
		}

		// GL objects can only be deleted where their context is current, so
		// closing on another thread queues them for the next texture read there
		if (IsTextureThread ()) {

			ReleaseTextures ();

		} else {

			#ifdef LIME_VIDEO_TEXTURES
			if (texture) {

				std::lock_guard<std::mutex> lock (*orphanMutex);
				OrphanTexture orphan = { texture, textureContext };
				orphanTextures->push_back (orphan);

			}
			#endif

			texture = 0;
			textureContext = 0;
			frameTexture = 0;
			textureHeight = 0;
			textureThreadKnown = false;
			textureWidth = 0;

		}

		backend->Close ();

		std::lock_guard<std::mutex> lock (mutex);

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
		for (size_t i = 0; i < frames.size (); i++) ReleaseFrame (frames[i]);

		audioChunks.clear ();
		audioQueued = 0;
		frames.clear ();

	}


	int VideoDecoder::GetFrameLength (VideoFrameFormat format, int width, int height) {

		if (width <= 0 || height <= 0) return 0;

		switch (format) {

			case VIDEO_FRAME_FORMAT_NV12: return width * height + ((width + 1) / 2) * 2 * ((height + 1) / 2);
			case VIDEO_FRAME_FORMAT_RGBA:
			case VIDEO_FRAME_FORMAT_BGRA:
			case VIDEO_FRAME_FORMAT_ARGB:
			case VIDEO_FRAME_FORMAT_TEXTURE: return width * height * 4;
			default: return 0;

		}

	}


	bool VideoDecoder::Open (const char* path, bool hardwareDecoding, VideoFrameFormat format) {

		Close ();

		if (!backend || !path) return false;

		VideoStreamInfo streamInfo;
		memset (&streamInfo, 0, sizeof (streamInfo));

		texturesFailed = false;
		backend->SetTextureOutput (format == VIDEO_FRAME_FORMAT_TEXTURE);

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

		if (!streamInfo.hasVideo || !(streamInfo.pixelAspectRatio > 0.0 && streamInfo.pixelAspectRatio < 100.0)) streamInfo.pixelAspectRatio = 1.0;
		streamInfo.rotation = streamInfo.hasVideo ? VideoBackend::NormalizeRotation (streamInfo.rotation) : 0;

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
		frameLength = format == VIDEO_FRAME_FORMAT_TEXTURE ? 0 : GetFrameLength (format, info.width, info.height);
		frameTexture = 0;
		frameTime = 0;
		frameWidth = info.width;
		droppedFrames = 0;
		lastQueued = std::chrono::steady_clock::now ();
		presentationTime = -1;
		audioSeekTime = 0;
		seekAccurate = false;
		seekPending = false;
		videoEnded = !info.hasVideo;
		videoError = false;
		videoSeekTime = 0;

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

		if (format == VIDEO_FRAME_FORMAT_TEXTURE) return ReadTexture (time);

		std::lock_guard<std::mutex> lock (mutex);

		if (!open || !info.hasVideo) return VIDEO_READ_END;

		bool dropped = false;

		if (time >= 0) {

			presentationTime = time;

			// Drop frames that a later queued frame replaces by time
			while (dropLateFrames && frames.size () > 1 && frames[1]->time <= time) {

				ReleaseFrame (frames.front ());
				frames.pop_front ();
				droppedFrames++;
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
		ReleaseFrame (frame);
		videoCondition.notify_one ();

		return frameLength;

	}


	bool VideoDecoder::IsTextureThread () {

		return textureThreadKnown && textureThread == std::this_thread::get_id ();

	}


	int VideoDecoder::ReadTexture (double time) {

		Frame* frame = 0;

		{
			std::lock_guard<std::mutex> lock (mutex);

			if (!open || !info.hasVideo) return VIDEO_READ_END;

			bool dropped = false;

			if (time >= 0) {

				presentationTime = time;

				while (dropLateFrames && frames.size () > 1 && frames[1]->time <= time) {

					ReleaseFrame (frames.front ());
					frames.pop_front ();
					droppedFrames++;
					dropped = true;

				}

			}

			if (dropped) videoCondition.notify_one ();

			if (frames.empty ()) {

				if (videoEnded) return videoError ? VIDEO_READ_ERROR : VIDEO_READ_END;
				return VIDEO_READ_NOT_READY;

			}

			if (time >= 0 && frames.front ()->time > time) return VIDEO_READ_NOT_READY;

			frame = frames.front ();
			frames.pop_front ();
			videoCondition.notify_one ();
		}

		textureThread = std::this_thread::get_id ();
		textureThreadKnown = true;
		ReleaseOrphans (backend);

		unsigned int name = frame->texture ? backend->LockTexture (frame->texture) : UploadTexture (frame);

		if (!name) {

			bool fallBack = (frame->texture != 0 && !texturesFailed);
			double resume = frame->time;

			{
				std::lock_guard<std::mutex> lock (mutex);
				ReleaseFrame (frame);
			}

			if (!fallBack) return VIDEO_READ_ERROR;

			// This context cannot use the backend's textures, so decode into
			// memory and upload from here on. The audio carries on from where it
			// was read to, as it has already been played.
			texturesFailed = true;
			backend->SetTextureOutput (false);
			SeekStreams (resume, true, true);
			return VIDEO_READ_NOT_READY;

		}

		if (currentFrame) {

			if (currentFrame->texture) backend->UnlockTexture (currentFrame->texture);

			std::lock_guard<std::mutex> lock (mutex);
			ReleaseFrame (currentFrame);

		}

		currentFrame = frame;

		frameColorMatrix = frame->colorMatrix;
		frameDuration = frame->duration;
		frameFullRange = frame->fullRange;
		frameHeight = frame->height;
		frameLength = 0;
		frameTexture = name;
		frameTime = frame->time;
		frameWidth = frame->width;

		return 1;

	}


	void VideoDecoder::ReleaseFrame (Frame* frame) {

		if (frame->texture) {

			backend->ReleaseTextureFrame (frame->texture);
			frame->texture = 0;

		}

		freeFrames.push_back (frame);

	}


	void VideoDecoder::ReleaseTextures () {

		backend->ReleaseTextures ();

		#ifdef LIME_VIDEO_TEXTURES
		// A texture made in a context that has since been replaced went with it
		if (texture && textureContext == VideoBackend::GetCurrentGLContext ()) {

			glDeleteTextures (1, &texture);

		}
		#endif

		texture = 0;
		textureContext = 0;
		frameTexture = 0;
		textureHeight = 0;
		textureThreadKnown = false;
		textureWidth = 0;

	}


	bool VideoDecoder::Seek (double time, bool accurate) {

		return SeekStreams (time, accurate, false);

	}


	bool VideoDecoder::SeekStreams (double time, bool accurate, bool keepAudio) {

		if (!open) return false;
		if (time < 0) time = 0;

		{
			std::lock_guard<std::mutex> lock (mutex);
			seekPending = true;
		}

		audioCondition.notify_all ();
		videoCondition.notify_all ();

		// A stream waiting on a stalled source gives up waiting, so the seek does
		// not wait for it
		backend->PrepareSeek ();

		// Wait for the frame or packet in progress, then seek with both streams idle
		std::lock_guard<std::mutex> videoLock (videoDecodeMutex);
		std::lock_guard<std::mutex> audioLock (audioDecodeMutex);

		// Audio that is kept carries on from what has been read, and the backend
		// seeks to whichever stream starts first
		double audioTarget = time;

		if (keepAudio) {

			std::lock_guard<std::mutex> lock (mutex);
			audioTarget = audioTime;

		}

		// There is nothing to decode from the end on, and some backends cannot
		// seek there
		bool ended = !keepAudio && info.duration > 0 && time >= info.duration;

		if (!ended && !backend->Seek (audioTarget < time ? audioTarget : time)) {

			// Nothing has moved, so what is queued still follows on
			std::lock_guard<std::mutex> lock (mutex);
			seekPending = false;
			audioCondition.notify_all ();
			videoCondition.notify_all ();
			return false;

		}

		if (ended) time = audioTarget = info.duration;

		std::lock_guard<std::mutex> lock (mutex);
		Flush ();

		audioEnded = ended || !info.hasAudio;
		audioError = false;
		audioQueueEnd = audioTarget;
		audioSeekTime = audioTarget;
		audioTime = audioTarget;
		frameTime = time;
		lastQueued = std::chrono::steady_clock::now ();
		presentationTime = -1;
		seekAccurate = accurate || keepAudio;
		seekPending = false;
		videoEnded = ended || !info.hasVideo;
		videoError = false;
		videoSeekTime = time;

		audioCondition.notify_all ();
		videoCondition.notify_all ();

		return true;

	}


	void VideoDecoder::StartThreads () {

		quit = false;
		runningThreads = (info.hasAudio ? 1 : 0) + (info.hasVideo ? 1 : 0);

		if (info.hasAudio) audioThread = std::thread ([this] { AudioThread (); ThreadStopped (); });
		if (info.hasVideo) videoThread = std::thread ([this] { VideoThread (); ThreadStopped (); });

	}


	void VideoDecoder::StopThreads () {

		{
			std::lock_guard<std::mutex> lock (mutex);
			quit = true;
			Flush ();
		}

		audioCondition.notify_all ();
		videoCondition.notify_all ();

		backend->Interrupt ();

		{
			// Media Foundation now and then leaves a read waiting on a stalled
			// network source after its byte stream is closed, so the streams are
			// interrupted again until they finish
			std::unique_lock<std::mutex> lock (mutex);

			while (!stoppedCondition.wait_for (lock, std::chrono::milliseconds (200), [this] { return runningThreads == 0; })) {

				lock.unlock ();
				backend->Interrupt ();
				lock.lock ();

			}
		}

		if (audioThread.joinable ()) audioThread.join ();
		if (videoThread.joinable ()) videoThread.join ();

	}


	void VideoDecoder::ThreadStopped () {

		{
			std::lock_guard<std::mutex> lock (mutex);
			runningThreads--;
		}

		stoppedCondition.notify_all ();

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
			planes.transfer = VIDEO_COLOR_TRANSFER_SDR;
			VideoTextureFrame* textureFrame = 0;
			double time = 0;
			double duration = 0;
			VideoDecodeResult result;

			if (format == VIDEO_FRAME_FORMAT_TEXTURE && !texturesFailed && backend->SupportsTextures ()) {

				result = backend->DecodeVideoTexture (&textureFrame, &time, &duration);

				// A backend that stops supporting textures returns no frame, and the
				// next one is decoded into memory
				if (result == VIDEO_DECODE_OK && !textureFrame) continue;

			} else {

				result = backend->DecodeVideo (&planes, &time, &duration);

			}

			if (result == VIDEO_DECODE_AGAIN) continue;

			if (result != VIDEO_DECODE_OK) {

				std::lock_guard<std::mutex> lock (mutex);
				videoEnded = true;
				videoError = (result == VIDEO_DECODE_ERROR);
				continue;

			}

			if (duration <= 0) duration = info.frameRate > 0 ? 1.0 / info.frameRate : 0;

			// Drop the frames that end before an accurate seek target
			if (seekAccurate && time + duration <= videoSeekTime + 0.0001) {

				if (textureFrame) backend->ReleaseTextureFrame (textureFrame);
				continue;

			}

			// A frame that ends before the time the application last asked for is
			// late, and is dropped before it is converted or copied, most of the
			// work for each frame, so a decoder that falls behind catches up. One
			// is still kept every quarter of a second, so a decoder that cannot keep
			// up at all still shows something.
			std::chrono::steady_clock::time_point now = std::chrono::steady_clock::now ();
			Frame* frame = 0;

			{
				std::lock_guard<std::mutex> lock (mutex);

				if (dropLateFrames && presentationTime >= 0 && time + duration <= presentationTime && now - lastQueued < std::chrono::milliseconds (250)) {

					if (textureFrame) backend->ReleaseTextureFrame (textureFrame);
					droppedFrames++;
					continue;

				}

				if (!freeFrames.empty ()) {

					frame = freeFrames.back ();
					freeFrames.pop_back ();

				}
			}

			if (!frame) frame = new Frame ();

			frame->duration = duration;
			frame->texture = textureFrame;
			frame->time = time;

			if (textureFrame) {

				// The backend converts to RGB on the GPU
				frame->colorMatrix = VIDEO_COLOR_MATRIX_BT709;
				frame->fullRange = true;
				frame->height = textureFrame->height;
				frame->length = 1;
				frame->width = textureFrame->width;

			} else {

				if (planes.transfer != VIDEO_COLOR_TRANSFER_SDR) toneMapper.Map (&planes);

				// Texture output without GPU support converts to RGBA here and uploads
				VideoFrameFormat outputFormat = format == VIDEO_FRAME_FORMAT_TEXTURE ? VIDEO_FRAME_FORMAT_RGBA : format;
				int length = GetFrameLength (outputFormat, planes.width, planes.height);
				if ((int)frame->data.size () < length) frame->data.resize (length);

				frame->colorMatrix = planes.colorMatrix;
				frame->fullRange = planes.fullRange;
				frame->height = planes.height;
				frame->length = length > 0 ? WriteFrame (&planes, outputFormat, frame->data.data (), (int)frame->data.size ()) : 0;
				frame->width = planes.width;

			}

			std::lock_guard<std::mutex> lock (mutex);

			if (frame->length > 0) {

				frames.push_back (frame);
				lastQueued = now;

			} else {

				ReleaseFrame (frame);

			}

		}

	}


	unsigned int VideoDecoder::UploadTexture (Frame* frame) {

		#ifdef LIME_VIDEO_TEXTURES
		if (!OpenGLBindings::Init ()) return 0;

		// Unpack buffers and row lengths exist from OpenGL 3 and OpenGL ES 3. The
		// version is only known once a context is current.
		static int glVersion = -1;

		if (glVersion < 0) {

			const char* version = (const char*)glGetString (GL_VERSION);
			if (!version) return 0;
			if (strncmp (version, "OpenGL ES ", 10) == 0) version += 10;
			glVersion = atoi (version);

		}

		// A texture from a context that has since been replaced, as Android does
		// after losing it, went with that context, and its name may now belong to
		// one of the application's textures
		void* context = VideoBackend::GetCurrentGLContext ();

		if (texture && context != textureContext) {

			texture = 0;

		}

		// Leave the application's GL state as it was
		GLint previousTexture = 0;
		GLint previousUnpackBuffer = 0;
		GLint previousRowLength = 0;
		glGetIntegerv (GL_TEXTURE_BINDING_2D, &previousTexture);

		if (glVersion >= 3) {

			glGetIntegerv (GL_PIXEL_UNPACK_BUFFER_BINDING, &previousUnpackBuffer);
			glGetIntegerv (GL_UNPACK_ROW_LENGTH, &previousRowLength);
			if (previousUnpackBuffer) glBindBuffer (GL_PIXEL_UNPACK_BUFFER, 0);
			if (previousRowLength) glPixelStorei (GL_UNPACK_ROW_LENGTH, 0);

		}

		if (!texture) {

			glGenTextures (1, &texture);
			textureContext = context;
			glBindTexture (GL_TEXTURE_2D, texture);
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
			textureWidth = 0;
			textureHeight = 0;

		} else {

			glBindTexture (GL_TEXTURE_2D, texture);

		}

		// RGBA rows are always four-byte aligned, so the unpack alignment does not matter
		if (frame->width != textureWidth || frame->height != textureHeight) {

			glTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, frame->width, frame->height, 0, GL_RGBA, GL_UNSIGNED_BYTE, frame->data.data ());
			textureWidth = frame->width;
			textureHeight = frame->height;

		} else {

			glTexSubImage2D (GL_TEXTURE_2D, 0, 0, 0, frame->width, frame->height, GL_RGBA, GL_UNSIGNED_BYTE, frame->data.data ());

		}

		glBindTexture (GL_TEXTURE_2D, previousTexture);

		if (glVersion >= 3) {

			if (previousUnpackBuffer) glBindBuffer (GL_PIXEL_UNPACK_BUFFER, previousUnpackBuffer);
			if (previousRowLength) glPixelStorei (GL_UNPACK_ROW_LENGTH, previousRowLength);

		}

		return texture;
		#else
		return 0;
		#endif

	}


	static double DecodeHLG (double value) {

		// Scene light from 0 to 1
		value = (std::max) (value, 0.0);
		return value <= 0.5 ? value * value / 3.0 : (exp ((value - 0.55991073) / 0.17883277) + 0.28466892) / 12.0;

	}


	static double DecodePQ (double value) {

		// Nits
		double p = pow ((std::max) (value, 0.0), 1.0 / 78.84375);
		return 10000.0 * pow ((std::max) (p - 0.8359375, 0.0) / (18.8515625 - 18.6875 * p), 1.0 / 0.1593017578125);

	}


	static double EncodePQ (double nits) {

		double y = pow ((std::max) (nits, 0.0) / 10000.0, 0.1593017578125);
		return pow ((0.8359375 + 18.8515625 * y) / (1.0 + 18.6875 * y), 78.84375);

	}


	// The transfer curves are sampled, and looked up between samples, as
	// building a table calls them a million times
	static const int TONE_MAP_CURVE_SAMPLES = 4096;

	struct ToneMapCurves {

		double gamma[TONE_MAP_CURVE_SAMPLES + 1];
		double hlg[TONE_MAP_CURVE_SAMPLES + 1];
		double peak;
		double pq[TONE_MAP_CURVE_SAMPLES + 1];
		double white;

	};


	static double LookUpCurve (const double* curve, double value) {

		// Values from 0 to 1
		double position = (std::min) ((std::max) (value, 0.0), 1.0) * TONE_MAP_CURVE_SAMPLES;
		int index = (int)position;
		if (index >= TONE_MAP_CURVE_SAMPLES) return curve[TONE_MAP_CURVE_SAMPLES];
		return curve[index] + (curve[index + 1] - curve[index]) * (position - index);

	}


	static double ToneMapLuminance (const ToneMapCurves& curves, double nits) {

		// BT.2390's curve, in PQ, from 0 to TONE_MAP_PEAK nits into 0 to
		// TONE_MAP_WHITE, which passes darker light through as it is
		double peak = curves.peak;
		double value = (std::min) (EncodePQ (nits) / peak, 1.0);
		double white = curves.white / peak;
		double knee = 1.5 * white - 0.5;

		if (value > knee) {

			double t = (value - knee) / (1.0 - knee);
			double t2 = t * t;
			double t3 = t2 * t;
			value = (2 * t3 - 3 * t2 + 1) * knee + (t3 - 2 * t2 + t) * (1 - knee) + (-2 * t3 + 3 * t2) * white;

		}

		return LookUpCurve (curves.pq, value * peak);

	}


	static const unsigned char* GetToneMapTable (VideoColorTransfer transfer, VideoColorMatrix matrix, bool fullRange) {

		// Each kind of frame's table is built once, a few megabytes, and kept.
		// They are never destroyed, as exiting on Android and Linux runs static
		// destructors while decoding threads can still be using them.
		static std::mutex* mutex = new std::mutex ();
		static std::map<int, std::vector<unsigned char> >* tables = new std::map<int, std::vector<unsigned char> > ();

		std::lock_guard<std::mutex> lock (*mutex);
		std::vector<unsigned char>& table = (*tables)[(int)transfer * 16 + (int)matrix * 2 + (fullRange ? 1 : 0)];
		if (!table.empty ()) return table.data ();

		double kr, kb;

		switch (matrix) {

			case VIDEO_COLOR_MATRIX_BT601: kr = 0.299; kb = 0.114; break;
			case VIDEO_COLOR_MATRIX_BT709: kr = 0.2126; kb = 0.0722; break;
			default: kr = 0.2627; kb = 0.0593; break;

		}

		static ToneMapCurves* curves = NULL;

		if (!curves) {

			curves = new ToneMapCurves ();
			curves->peak = EncodePQ (TONE_MAP_PEAK);
			curves->white = EncodePQ (TONE_MAP_WHITE);

			for (int i = 0; i <= TONE_MAP_CURVE_SAMPLES; i++) {

				double value = (double)i / TONE_MAP_CURVE_SAMPLES;
				curves->gamma[i] = pow (value, 1.0 / 2.4);
				curves->hlg[i] = DecodeHLG (value);
				curves->pq[i] = DecodePQ (value);

			}

		}

		double kg = 1.0 - kr - kb;
		table.resize ((size_t)TONE_MAP_CHROMA_NODES * TONE_MAP_CHROMA_NODES * 256 * 3);
		unsigned char* entry = table.data ();

		for (int u = 0; u < TONE_MAP_CHROMA_NODES; u++) {

			for (int v = 0; v < TONE_MAP_CHROMA_NODES; v++) {

				double cb = ((std::min) (u * TONE_MAP_CHROMA_STEP, 255) - 128) / (fullRange ? 255.0 : 224.0);
				double cr = ((std::min) (v * TONE_MAP_CHROMA_STEP, 255) - 128) / (fullRange ? 255.0 : 224.0);

				for (int y = 0; y < 256; y++) {

					double luma = fullRange ? y / 255.0 : (y - 16) / 219.0;
					double rgb[3];
					rgb[0] = luma + 2.0 * (1.0 - kr) * cr;
					rgb[2] = luma + 2.0 * (1.0 - kb) * cb;
					rgb[1] = (luma - kr * rgb[0] - kb * rgb[2]) / kg;

					for (int i = 0; i < 3; i++) rgb[i] = (std::min) ((std::max) (rgb[i], 0.0), 1.0);

					// Light in nits, as shown on an HDR display
					if (transfer == VIDEO_COLOR_TRANSFER_HLG) {

						for (int i = 0; i < 3; i++) rgb[i] = LookUpCurve (curves->hlg, rgb[i]);
						double scene = 0.2627 * rgb[0] + 0.6780 * rgb[1] + 0.0593 * rgb[2];
						double gain = scene > 0 ? TONE_MAP_PEAK * pow (scene, 0.2) : 0;
						for (int i = 0; i < 3; i++) rgb[i] *= gain;

					} else {

						for (int i = 0; i < 3; i++) rgb[i] = LookUpCurve (curves->pq, rgb[i]);

					}

					// The brightness is tone mapped, keeping the color's hue, and white
					// becomes 1
					double luminance = 0.2627 * rgb[0] + 0.6780 * rgb[1] + 0.0593 * rgb[2];
					double scale = luminance > 0 ? ToneMapLuminance (*curves, luminance) / luminance / TONE_MAP_WHITE : 0;

					// BT.2020 primaries to BT.709, clipping colors outside it
					double r = (1.6605 * rgb[0] - 0.5876 * rgb[1] - 0.0728 * rgb[2]) * scale;
					double g = (-0.1246 * rgb[0] + 1.1329 * rgb[1] - 0.0083 * rgb[2]) * scale;
					double b = (-0.0182 * rgb[0] - 0.1006 * rgb[1] + 1.1187 * rgb[2]) * scale;

					// Standard range video is made for BT.1886's display gamma
					r = LookUpCurve (curves->gamma, r);
					g = LookUpCurve (curves->gamma, g);
					b = LookUpCurve (curves->gamma, b);

					double outLuma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
					entry[0] = ClampByte ((int)(16 + 219 * outLuma + 0.5));
					entry[1] = ClampByte ((int)(128 + 224 * (b - outLuma) / 1.8556 + 0.5));
					entry[2] = ClampByte ((int)(128 + 224 * (r - outLuma) / 1.5748 + 0.5));
					entry += 3;

				}

			}

		}

		return table.data ();

	}


	void VideoToneMapper::Map (VideoPlanes* planes) {

		const unsigned char* table = GetToneMapTable (planes->transfer, planes->colorMatrix, planes->fullRange);

		int width = planes->width;
		int height = planes->height;
		int chromaWidth = (width + 1) / 2;
		int chromaHeight = (height + 1) / 2;
		int pixelStride = planes->uvPixelStride;

		buffer.resize ((size_t)width * height + (size_t)chromaWidth * chromaHeight * 2);
		unsigned char* yOut = buffer.data ();
		unsigned char* uvOut = yOut + (size_t)width * height;

		for (int row = 0; row < chromaHeight; row++) {

			const unsigned char* u = planes->u + row * planes->uvStride;
			const unsigned char* v = planes->v + row * planes->uvStride;
			const unsigned char* top = planes->y + (row * 2) * planes->yStride;
			const unsigned char* bottom = row * 2 + 1 < height ? top + planes->yStride : top;
			unsigned char* topOut = yOut + (size_t)(row * 2) * width;
			unsigned char* bottomOut = row * 2 + 1 < height ? topOut + width : NULL;
			unsigned char* uv = uvOut + (size_t)row * chromaWidth * 2;

			for (int x = 0; x < chromaWidth; x++) {

				// The pixels sharing this chroma, each mapped with its own luma
				int node = ((u[x * pixelStride] + TONE_MAP_CHROMA_STEP / 2) / TONE_MAP_CHROMA_STEP) * TONE_MAP_CHROMA_NODES + (v[x * pixelStride] + TONE_MAP_CHROMA_STEP / 2) / TONE_MAP_CHROMA_STEP;
				const unsigned char* entries = table + (size_t)node * 256 * 3;
				int left = x * 2;
				int right = left + 1 < width ? left + 1 : left;

				const unsigned char* a = entries + top[left] * 3;
				const unsigned char* b = entries + top[right] * 3;
				const unsigned char* c = entries + bottom[left] * 3;
				const unsigned char* d = entries + bottom[right] * 3;

				topOut[left] = a[0];
				topOut[right] = b[0];

				if (bottomOut) {

					bottomOut[left] = c[0];
					bottomOut[right] = d[0];

				}

				uv[x * 2] = (unsigned char)((a[1] + b[1] + c[1] + d[1] + 2) >> 2);
				uv[x * 2 + 1] = (unsigned char)((a[2] + b[2] + c[2] + d[2] + 2) >> 2);

			}

		}

		planes->colorMatrix = VIDEO_COLOR_MATRIX_BT709;
		planes->fullRange = false;
		planes->transfer = VIDEO_COLOR_TRANSFER_SDR;
		planes->u = uvOut;
		planes->uvPixelStride = 2;
		planes->uvStride = chromaWidth * 2;
		planes->v = uvOut + 1;
		planes->y = yOut;
		planes->yStride = width;

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

		// Where each channel goes in the four bytes of a pixel
		int red = 0, green = 1, blue = 2, alpha = 3;

		if (format == VIDEO_FRAME_FORMAT_BGRA) {

			red = 2;
			blue = 0;

		} else if (format == VIDEO_FRAME_FORMAT_ARGB) {

			alpha = 0;
			red = 1;
			green = 2;
			blue = 3;

		}

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

				out[red] = ClampByte ((luma + rv * cv) >> 16);
				out[green] = ClampByte ((luma - gu * cu - gv * cv) >> 16);
				out[blue] = ClampByte ((luma + bu * cu) >> 16);
				out[alpha] = 255;
				out += 4;

			}

		}

		return frameLength;

	}


}
