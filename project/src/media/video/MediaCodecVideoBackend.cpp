#include <media/VideoDecoder.h>


#ifdef LIME_VIDEO_MEDIACODEC

#include <media/NdkMediaCodec.h>
#include <media/NdkMediaExtractor.h>
#include <media/NdkMediaFormat.h>
#include <algorithm>
#include <dlfcn.h>
#include <fcntl.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <string>
#include <sys/stat.h>
#include <unistd.h>

#ifndef LIME_VIDEO_STANDALONE
#include <system/System.h>
#endif


namespace lime {


	// The NDK media library is loaded at runtime, so Lime does not link it
	struct MediaNDK {

		media_status_t (*AMediaCodec_configure) (AMediaCodec*, const AMediaFormat*, ANativeWindow*, AMediaCrypto*, uint32_t);
		AMediaCodec* (*AMediaCodec_createCodecByName) (const char*);
		AMediaCodec* (*AMediaCodec_createDecoderByType) (const char*);
		media_status_t (*AMediaCodec_delete) (AMediaCodec*);
		ssize_t (*AMediaCodec_dequeueInputBuffer) (AMediaCodec*, int64_t);
		ssize_t (*AMediaCodec_dequeueOutputBuffer) (AMediaCodec*, AMediaCodecBufferInfo*, int64_t);
		media_status_t (*AMediaCodec_flush) (AMediaCodec*);
		uint8_t* (*AMediaCodec_getInputBuffer) (AMediaCodec*, size_t, size_t*);
		uint8_t* (*AMediaCodec_getOutputBuffer) (AMediaCodec*, size_t, size_t*);
		AMediaFormat* (*AMediaCodec_getOutputFormat) (AMediaCodec*);
		media_status_t (*AMediaCodec_queueInputBuffer) (AMediaCodec*, size_t, long, size_t, uint64_t, uint32_t);
		media_status_t (*AMediaCodec_releaseOutputBuffer) (AMediaCodec*, size_t, bool);
		media_status_t (*AMediaCodec_start) (AMediaCodec*);
		media_status_t (*AMediaCodec_stop) (AMediaCodec*);
		bool (*AMediaExtractor_advance) (AMediaExtractor*);
		media_status_t (*AMediaExtractor_delete) (AMediaExtractor*);
		int64_t (*AMediaExtractor_getSampleTime) (AMediaExtractor*);
		size_t (*AMediaExtractor_getTrackCount) (AMediaExtractor*);
		AMediaFormat* (*AMediaExtractor_getTrackFormat) (AMediaExtractor*, size_t);
		AMediaExtractor* (*AMediaExtractor_new) ();
		ssize_t (*AMediaExtractor_readSampleData) (AMediaExtractor*, uint8_t*, size_t);
		media_status_t (*AMediaExtractor_seekTo) (AMediaExtractor*, int64_t, SeekMode);
		media_status_t (*AMediaExtractor_selectTrack) (AMediaExtractor*, size_t);
		media_status_t (*AMediaExtractor_setDataSource) (AMediaExtractor*, const char*);
		media_status_t (*AMediaExtractor_setDataSourceFd) (AMediaExtractor*, int, off64_t, off64_t);
		media_status_t (*AMediaFormat_delete) (AMediaFormat*);
		bool (*AMediaFormat_getBuffer) (AMediaFormat*, const char*, void**, size_t*);
		bool (*AMediaFormat_getFloat) (AMediaFormat*, const char*, float*);
		bool (*AMediaFormat_getInt32) (AMediaFormat*, const char*, int32_t*);
		bool (*AMediaFormat_getInt64) (AMediaFormat*, const char*, int64_t*);
		bool (*AMediaFormat_getRect) (AMediaFormat*, const char*, int32_t*, int32_t*, int32_t*, int32_t*);
		bool (*AMediaFormat_getString) (AMediaFormat*, const char*, const char**);

	};


	// A plane of MediaImage2 from the platform's VideoAPI.h, which describes a
	// decoder's output as "image-data". The MediaImage of API level 23 lacks
	// mBitDepthAllocated, so its planes start 4 bytes sooner.
	struct MediaImagePlane {

		uint32_t offset;
		int32_t colInc;
		int32_t rowInc;
		uint32_t horizSubsampling;
		uint32_t vertSubsampling;

	};


	struct SoftwareDecoder {

		const char* mime;
		const char* codec2;
		const char* omx;

	};


	// Values from MediaFormat, MediaCodecInfo and VideoAPI.h
	enum {

		COLOR_FORMAT_YUV420_PLANAR = 19,
		COLOR_FORMAT_YUV420_PACKED_PLANAR = 20,
		COLOR_FORMAT_YUV420_SEMI_PLANAR = 21,
		COLOR_FORMAT_YUV420_PACKED_SEMI_PLANAR = 39,
		COLOR_FORMAT_YUV420_FLEXIBLE = 0x7F420888,
		COLOR_FORMAT_QCOM_YUV420_SEMI_PLANAR = 0x7FA30C00,
		COLOR_FORMAT_QCOM_YUV420_SEMI_PLANAR_32M = 0x7FA30C04,
		COLOR_RANGE_FULL = 1,
		COLOR_STANDARD_BT709 = 1,
		COLOR_STANDARD_BT601_PAL = 2,
		COLOR_STANDARD_BT601_NTSC = 4,
		COLOR_STANDARD_BT2020 = 6,
		MEDIA_IMAGE_SIZE = 80,
		MEDIA_IMAGE_TYPE_YUV = 1,
		MEDIA_IMAGE2_SIZE = 104,
		PCM_ENCODING_16BIT = 2,
		PCM_ENCODING_FLOAT = 4

	};


	// Google's software decoders, by their Codec 2.0 and older OMX names
	static const SoftwareDecoder SOFTWARE_DECODERS[] = {

		{ "audio/3gpp", "c2.android.amrnb.decoder", "OMX.google.amrnb.decoder" },
		{ "audio/amr-wb", "c2.android.amrwb.decoder", "OMX.google.amrwb.decoder" },
		{ "audio/flac", "c2.android.flac.decoder", "OMX.google.flac.decoder" },
		{ "audio/g711-alaw", "c2.android.g711.alaw.decoder", "OMX.google.g711.alaw.decoder" },
		{ "audio/g711-mlaw", "c2.android.g711.mlaw.decoder", "OMX.google.g711.mlaw.decoder" },
		{ "audio/mp4a-latm", "c2.android.aac.decoder", "OMX.google.aac.decoder" },
		{ "audio/mpeg", "c2.android.mp3.decoder", "OMX.google.mp3.decoder" },
		{ "audio/opus", "c2.android.opus.decoder", "OMX.google.opus.decoder" },
		{ "audio/raw", "c2.android.raw.decoder", "OMX.google.raw.decoder" },
		{ "audio/vorbis", "c2.android.vorbis.decoder", "OMX.google.vorbis.decoder" },
		{ "video/3gpp", "c2.android.h263.decoder", "OMX.google.h263.decoder" },
		{ "video/av01", "c2.android.av1.decoder", NULL },
		{ "video/avc", "c2.android.avc.decoder", "OMX.google.h264.decoder" },
		{ "video/hevc", "c2.android.hevc.decoder", "OMX.google.hevc.decoder" },
		{ "video/mp4v-es", "c2.android.mpeg4.decoder", "OMX.google.mpeg4.decoder" },
		{ "video/mpeg2", "c2.android.mpeg2.decoder", "OMX.google.mpeg2.decoder" },
		{ "video/x-vnd.on2.vp8", "c2.android.vp8.decoder", "OMX.google.vp8.decoder" },
		{ "video/x-vnd.on2.vp9", "c2.android.vp9.decoder", "OMX.google.vp9.decoder" }

	};

	// Decoding gives up after about 3 seconds without progress
	static const int MAX_IDLE_WAITS = 300;
	static const int64_t OUTPUT_TIMEOUT_US = 10000;

	static std::once_flag loadFlag;
	static bool loaded = false;
	static MediaNDK ndk;


	static bool LoadMediaNDK () {

		std::call_once (loadFlag, [] {

			void* library = dlopen ("libmediandk.so", RTLD_NOW | RTLD_LOCAL);
			if (!library) return;

			#define LIME_MEDIANDK_REQUIRE(name) ndk.name = (decltype (ndk.name))dlsym (library, #name); if (!ndk.name) return;

			LIME_MEDIANDK_REQUIRE (AMediaCodec_configure);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_createCodecByName);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_createDecoderByType);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_delete);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_dequeueInputBuffer);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_dequeueOutputBuffer);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_flush);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_getInputBuffer);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_getOutputBuffer);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_getOutputFormat);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_queueInputBuffer);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_releaseOutputBuffer);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_start);
			LIME_MEDIANDK_REQUIRE (AMediaCodec_stop);
			LIME_MEDIANDK_REQUIRE (AMediaExtractor_advance);
			LIME_MEDIANDK_REQUIRE (AMediaExtractor_delete);
			LIME_MEDIANDK_REQUIRE (AMediaExtractor_getSampleTime);
			LIME_MEDIANDK_REQUIRE (AMediaExtractor_getTrackCount);
			LIME_MEDIANDK_REQUIRE (AMediaExtractor_getTrackFormat);
			LIME_MEDIANDK_REQUIRE (AMediaExtractor_new);
			LIME_MEDIANDK_REQUIRE (AMediaExtractor_readSampleData);
			LIME_MEDIANDK_REQUIRE (AMediaExtractor_seekTo);
			LIME_MEDIANDK_REQUIRE (AMediaExtractor_selectTrack);
			LIME_MEDIANDK_REQUIRE (AMediaExtractor_setDataSource);
			LIME_MEDIANDK_REQUIRE (AMediaExtractor_setDataSourceFd);
			LIME_MEDIANDK_REQUIRE (AMediaFormat_delete);
			LIME_MEDIANDK_REQUIRE (AMediaFormat_getBuffer);
			LIME_MEDIANDK_REQUIRE (AMediaFormat_getFloat);
			LIME_MEDIANDK_REQUIRE (AMediaFormat_getInt32);
			LIME_MEDIANDK_REQUIRE (AMediaFormat_getInt64);
			LIME_MEDIANDK_REQUIRE (AMediaFormat_getString);

			#undef LIME_MEDIANDK_REQUIRE

			// API level 28
			ndk.AMediaFormat_getRect = (decltype (ndk.AMediaFormat_getRect))dlsym (library, "AMediaFormat_getRect");

			loaded = true;

		});

		return loaded;

	}


	static AMediaCodec* CreateDecoder (AMediaFormat* format, bool hardware) {

		const char* mime = NULL;
		if (!ndk.AMediaFormat_getString (format, "mime", &mime) || !mime) return NULL;

		std::string type = mime;
		const char* names[] = { NULL, NULL };

		if (!hardware) {

			for (size_t i = 0; i < sizeof (SOFTWARE_DECODERS) / sizeof (SOFTWARE_DECODERS[0]); i++) {

				if (type == SOFTWARE_DECODERS[i].mime) {

					names[0] = SOFTWARE_DECODERS[i].codec2;
					names[1] = SOFTWARE_DECODERS[i].omx;
					break;

				}

			}

		}

		// The software decoders by name, then the platform's choice for the type
		for (int i = 0; i < 3; i++) {

			AMediaCodec* codec = NULL;

			if (i < 2) {

				if (names[i]) codec = ndk.AMediaCodec_createCodecByName (names[i]);

			} else {

				codec = ndk.AMediaCodec_createDecoderByType (type.c_str ());

			}

			if (!codec) continue;

			if (ndk.AMediaCodec_configure (codec, format, NULL, NULL, 0) == AMEDIA_OK && ndk.AMediaCodec_start (codec) == AMEDIA_OK) {

				return codec;

			}

			ndk.AMediaCodec_delete (codec);

		}

		return NULL;

	}


	static double EstimateFrameRate (AMediaExtractor* extractor) {

		// Samples arrive in decode order, so sort their times and measure the
		// evenly spaced run from the first frame
		std::vector<int64_t> times;

		while (times.size () < 16) {

			int64_t time = ndk.AMediaExtractor_getSampleTime (extractor);
			if (time < 0) break;

			times.push_back (time);
			if (!ndk.AMediaExtractor_advance (extractor)) break;

		}

		ndk.AMediaExtractor_seekTo (extractor, 0, AMEDIAEXTRACTOR_SEEK_PREVIOUS_SYNC);

		if (times.size () < 3) return 0;

		std::sort (times.begin (), times.end ());

		std::vector<int64_t> deltas;
		for (size_t i = 1; i < times.size (); i++) deltas.push_back (times[i] - times[i - 1]);

		std::nth_element (deltas.begin (), deltas.begin () + deltas.size () / 2, deltas.end ());
		int64_t median = deltas[deltas.size () / 2];

		if (median <= 0) return 0;

		size_t count = 1;

		while (count < times.size ()) {

			int64_t delta = times[count] - times[count - 1];
			if (delta < median - median / 4 || delta > median + median / 4) break;
			count++;

		}

		return count > 1 ? (count - 1) * 1000000.0 / (times[count - 1] - times[0]) : 1000000.0 / median;

	}


	static AMediaFormat* SelectTrack (AMediaExtractor* extractor, const char* type) {

		size_t count = ndk.AMediaExtractor_getTrackCount (extractor);

		for (size_t i = 0; i < count; i++) {

			AMediaFormat* format = ndk.AMediaExtractor_getTrackFormat (extractor, i);
			if (!format) continue;

			const char* mime = NULL;

			if (ndk.AMediaFormat_getString (format, "mime", &mime) && mime && strncmp (mime, type, strlen (type)) == 0) {

				if (ndk.AMediaExtractor_selectTrack (extractor, i) == AMEDIA_OK) return format;

				ndk.AMediaFormat_delete (format);
				return NULL;

			}

			ndk.AMediaFormat_delete (format);

		}

		return NULL;

	}


	// One stream's extractor and decoder, which no other thread touches while
	// it decodes
	class MediaCodecStream {


		public:

			MediaCodecStream ();

			void Close ();
			bool Prime ();
			VideoDecodeResult Read (bool* formatChanged);
			void Release ();
			bool Seek (int64_t position);

			AMediaCodec* codec;
			bool ended;
			AMediaExtractor* extractor;
			ssize_t index;
			AMediaCodecBufferInfo info;
			bool inputEnded;
			bool pending;

		private:

			bool QueueInput ();


	};


	MediaCodecStream::MediaCodecStream () {

		codec = NULL;
		ended = false;
		extractor = NULL;
		index = -1;
		inputEnded = false;
		memset (&info, 0, sizeof (info));
		pending = false;

	}


	void MediaCodecStream::Close () {

		Release ();

		if (codec) {

			ndk.AMediaCodec_stop (codec);
			ndk.AMediaCodec_delete (codec);
			codec = NULL;

		}

		if (extractor) {

			ndk.AMediaExtractor_delete (extractor);
			extractor = NULL;

		}

		ended = false;
		inputEnded = false;

	}


	bool MediaCodecStream::Prime () {

		// Decode ahead to the first output, so the output format is the real one
		bool formatChanged = false;
		pending = (Read (&formatChanged) == VIDEO_DECODE_OK);
		return pending;

	}


	bool MediaCodecStream::QueueInput () {

		if (inputEnded) return false;

		ssize_t inputIndex = ndk.AMediaCodec_dequeueInputBuffer (codec, 0);
		if (inputIndex < 0) return false;

		size_t capacity = 0;
		uint8_t* buffer = ndk.AMediaCodec_getInputBuffer (codec, inputIndex, &capacity);
		ssize_t size = buffer ? ndk.AMediaExtractor_readSampleData (extractor, buffer, capacity) : -1;
		int64_t time = ndk.AMediaExtractor_getSampleTime (extractor);

		if (size < 0 || time < 0) {

			ndk.AMediaCodec_queueInputBuffer (codec, inputIndex, 0, 0, 0, AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM);
			inputEnded = true;

		} else {

			ndk.AMediaCodec_queueInputBuffer (codec, inputIndex, 0, size, time, 0);
			ndk.AMediaExtractor_advance (extractor);

		}

		return true;

	}


	VideoDecodeResult MediaCodecStream::Read (bool* formatChanged) {

		if (pending) {

			pending = false;
			return VIDEO_DECODE_OK;

		}

		Release ();

		if (ended) return VIDEO_DECODE_END;

		int idle = 0;

		while (true) {

			bool queued = QueueInput ();
			if (queued) idle = 0;

			ssize_t result = ndk.AMediaCodec_dequeueOutputBuffer (codec, &info, queued ? 0 : OUTPUT_TIMEOUT_US);

			if (result >= 0) {

				if (info.flags & AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM) ended = true;

				if (info.size > 0) {

					index = result;
					return VIDEO_DECODE_OK;

				}

				ndk.AMediaCodec_releaseOutputBuffer (codec, result, false);
				if (ended) return VIDEO_DECODE_END;

			} else if (result == AMEDIACODEC_INFO_OUTPUT_FORMAT_CHANGED) {

				*formatChanged = true;

			} else if (result == AMEDIACODEC_INFO_TRY_AGAIN_LATER) {

				// Some decoders never flag the end of the stream after the last input
				if (!queued && ++idle >= MAX_IDLE_WAITS) return inputEnded ? VIDEO_DECODE_END : VIDEO_DECODE_ERROR;

			} else if (result != AMEDIACODEC_INFO_OUTPUT_BUFFERS_CHANGED) {

				return VIDEO_DECODE_ERROR;

			}

		}

	}


	void MediaCodecStream::Release () {

		if (index >= 0) {

			ndk.AMediaCodec_releaseOutputBuffer (codec, index, false);
			index = -1;

		}

		pending = false;

	}


	bool MediaCodecStream::Seek (int64_t position) {

		Release ();

		bool success = (ndk.AMediaExtractor_seekTo (extractor, position, AMEDIAEXTRACTOR_SEEK_PREVIOUS_SYNC) == AMEDIA_OK);
		success = (ndk.AMediaCodec_flush (codec) == AMEDIA_OK) && success;

		ended = false;
		inputEnded = false;

		return success;

	}


	class MediaCodecVideoBackend : public VideoBackend {


		public:

			MediaCodecVideoBackend ();
			~MediaCodecVideoBackend ();

			virtual void Close ();
			virtual VideoDecodeResult DecodeAudio (std::vector<unsigned char>* pcm, double* time);
			virtual VideoDecodeResult DecodeVideo (VideoPlanes* planes, double* time, double* duration);
			virtual bool Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info);
			virtual bool Seek (double time);

		private:

			AMediaExtractor* CreateExtractor ();
			bool GetPlanes (VideoPlanes* planes);
			bool OpenAudio ();
			bool OpenVideo (bool hardware);
			bool ReadAudioFormat ();
			bool ReadPlaneLayout (AMediaFormat* format, int width, int height);
			bool ReadVideoFormat ();
			bool RestartVideo ();

			MediaCodecStream audio;
			int audioChannels;
			bool audioFloat;
			std::vector<short> audioSamples;
			int audioSampleRate;
			int audioSourceChannels;
			VideoColorMatrix colorMatrix;
			int cropHeight;
			int cropWidth;
			int cropX;
			int cropY;
			double duration;
			double frameRate;
			bool fullRange;
			bool hardwareActive;
			std::string path;
			size_t uOffset;
			int uvPixelStride;
			int uvStride;
			size_t vOffset;
			MediaCodecStream video;
			AMediaFormat* videoFormat;
			int64_t videoPosition;
			int64_t videoSkipTime;
			int64_t videoTime;
			size_t yOffset;
			int yStride;


	};


	MediaCodecVideoBackend::MediaCodecVideoBackend () {

		audioChannels = 0;
		audioFloat = false;
		audioSampleRate = 0;
		audioSourceChannels = 0;
		colorMatrix = VIDEO_COLOR_MATRIX_BT709;
		cropHeight = 0;
		cropWidth = 0;
		cropX = 0;
		cropY = 0;
		duration = 0;
		frameRate = 0;
		fullRange = false;
		hardwareActive = false;
		uOffset = 0;
		uvPixelStride = 0;
		uvStride = 0;
		vOffset = 0;
		videoFormat = NULL;
		videoPosition = 0;
		videoSkipTime = INT64_MIN;
		videoTime = INT64_MIN;
		yOffset = 0;
		yStride = 0;

	}


	MediaCodecVideoBackend::~MediaCodecVideoBackend () {

		Close ();

	}


	void MediaCodecVideoBackend::Close () {

		video.Close ();
		audio.Close ();

		if (videoFormat) {

			ndk.AMediaFormat_delete (videoFormat);
			videoFormat = NULL;

		}

		audioChannels = 0;
		audioSampleRate = 0;
		audioSourceChannels = 0;
		duration = 0;
		frameRate = 0;
		hardwareActive = false;
		videoPosition = 0;
		videoSkipTime = INT64_MIN;
		videoTime = INT64_MIN;

	}


	AMediaExtractor* MediaCodecVideoBackend::CreateExtractor () {

		AMediaExtractor* extractor = ndk.AMediaExtractor_new ();
		if (!extractor) return NULL;

		media_status_t status = AMEDIA_ERROR_UNKNOWN;

		if (path.find ("://") != std::string::npos) {

			status = ndk.AMediaExtractor_setDataSource (extractor, path.c_str ());

		} else {

			// Each extractor opens the file itself, since descriptors that share
			// an open file also share its read position
			int fd = ::open (path.c_str (), O_RDONLY | O_CLOEXEC);
			off64_t offset = 0;
			off64_t length = 0;
			struct stat fileInfo;

			if (fd >= 0 && fstat (fd, &fileInfo) == 0) length = fileInfo.st_size;

			#ifndef LIME_VIDEO_STANDALONE
			if (fd < 0) {

				// An asset in the APK opens as the APK file, at the asset's offset
				FILE_HANDLE* handle = lime::fopen (path.c_str (), "rb");

				if (handle) {

					FILE* file = handle->getFile ();

					if (file) {

						fd = dup (fileno (file));
						offset = ::ftell (file);
						length = handle->getLength ();

						// getFile opens a new stream for an asset
						if (!handle->isFile ()) ::fclose (file);

					}

					lime::fclose (handle);

				}

			}
			#endif

			// The extractor keeps its own duplicate of the descriptor
			if (fd >= 0) {

				status = ndk.AMediaExtractor_setDataSourceFd (extractor, fd, offset, length);
				::close (fd);

			}

		}

		if (status != AMEDIA_OK) {

			ndk.AMediaExtractor_delete (extractor);
			return NULL;

		}

		return extractor;

	}


	VideoDecodeResult MediaCodecVideoBackend::DecodeAudio (std::vector<unsigned char>* pcm, double* time) {

		if (!audio.codec) return VIDEO_DECODE_END;

		bool formatChanged = false;
		VideoDecodeResult result = audio.Read (&formatChanged);

		if (formatChanged && !ReadAudioFormat ()) result = VIDEO_DECODE_ERROR;

		if (result != VIDEO_DECODE_OK) {

			audio.Release ();
			return result;

		}

		size_t capacity = 0;
		uint8_t* data = ndk.AMediaCodec_getOutputBuffer (audio.codec, audio.index, &capacity);
		size_t offset = (size_t)audio.info.offset;
		size_t length = (size_t)audio.info.size;
		bool downmix = (audioSourceChannels > 2 && audioChannels == 2);

		if (!data || offset > capacity || length > capacity - offset || (audioSourceChannels != audioChannels && !downmix)) {

			audio.Release ();
			return VIDEO_DECODE_ERROR;

		}

		int frames = (int)(length / (audioSourceChannels * (audioFloat ? 4 : 2)));
		const short* samples = (const short*)(data + offset);

		if (audioFloat) {

			const float* in = (const float*)(data + offset);
			audioSamples.resize (frames * audioSourceChannels);

			for (size_t i = 0; i < audioSamples.size (); i++) {

				float sample = in[i] * 32768.0f;
				audioSamples[i] = sample >= 32767.0f ? 32767 : (sample <= -32768.0f ? -32768 : (short)sample);

			}

			samples = audioSamples.data ();

		}

		if (downmix) {

			DownmixToStereo (samples, frames, audioSourceChannels, pcm);

		} else {

			pcm->insert (pcm->end (), (const unsigned char*)samples, (const unsigned char*)(samples + frames * audioChannels));

		}

		*time = audio.info.presentationTimeUs / 1000000.0;
		audio.Release ();

		return VIDEO_DECODE_OK;

	}


	VideoDecodeResult MediaCodecVideoBackend::DecodeVideo (VideoPlanes* planes, double* time, double* duration) {

		while (video.codec) {

			bool formatChanged = false;
			VideoDecodeResult result = video.Read (&formatChanged);

			if (formatChanged) ReadVideoFormat ();
			if (result == VIDEO_DECODE_OK && video.info.presentationTimeUs <= videoSkipTime) continue;
			if (result == VIDEO_DECODE_OK && !GetPlanes (planes)) result = VIDEO_DECODE_ERROR;

			// Some hardware decoders fail on a stream they accepted, or lose it to
			// another app, so continue from the same frame in software
			if (result == VIDEO_DECODE_ERROR && hardwareActive && RestartVideo ()) continue;
			if (result != VIDEO_DECODE_OK) return result;

			videoSkipTime = INT64_MIN;
			videoTime = video.info.presentationTimeUs;
			*time = videoTime / 1000000.0;
			*duration = frameRate > 0 ? 1.0 / frameRate : 0;

			return VIDEO_DECODE_OK;

		}

		return VIDEO_DECODE_END;

	}


	bool MediaCodecVideoBackend::GetPlanes (VideoPlanes* planes) {

		size_t capacity = 0;
		uint8_t* data = ndk.AMediaCodec_getOutputBuffer (video.codec, video.index, &capacity);
		size_t offset = (size_t)video.info.offset;

		if (!data || yStride <= 0 || cropWidth <= 0 || cropHeight <= 0 || offset > capacity) return false;

		int chromaX = cropX / 2;
		int chromaY = cropY / 2;
		size_t size = capacity - offset;
		size_t lumaEnd = yOffset + (size_t)(cropY + cropHeight - 1) * yStride + cropX + cropWidth;
		size_t chromaEnd = (size_t)(chromaY + (cropHeight + 1) / 2 - 1) * uvStride + (size_t)(chromaX + (cropWidth + 1) / 2 - 1) * uvPixelStride + 1;

		if (lumaEnd > size || uOffset + chromaEnd > size || vOffset + chromaEnd > size) return false;

		data += offset;

		planes->colorMatrix = colorMatrix;
		planes->fullRange = fullRange;
		planes->width = cropWidth;
		planes->height = cropHeight;
		planes->y = data + yOffset + (size_t)cropY * yStride + cropX;
		planes->yStride = yStride;
		planes->u = data + uOffset + (size_t)chromaY * uvStride + chromaX * uvPixelStride;
		planes->v = data + vOffset + (size_t)chromaY * uvStride + chromaX * uvPixelStride;
		planes->uvStride = uvStride;
		planes->uvPixelStride = uvPixelStride;

		return true;

	}


	bool MediaCodecVideoBackend::Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info) {

		Close ();

		if (!path || !path[0]) return false;

		this->path = path;

		info->hasVideo = OpenVideo (hardwareDecoding) || (hardwareDecoding && OpenVideo (false));
		info->hasAudio = OpenAudio ();

		if (!info->hasVideo && !info->hasAudio) return false;

		info->audioChannels = audioChannels;
		info->audioSampleRate = audioSampleRate;
		info->duration = duration;
		info->frameRate = info->hasVideo ? frameRate : 0;
		info->width = info->hasVideo ? cropWidth : 0;
		info->height = info->hasVideo ? cropHeight : 0;

		return true;

	}


	bool MediaCodecVideoBackend::OpenAudio () {

		AMediaExtractor* extractor = CreateExtractor ();
		if (!extractor) return false;

		AMediaFormat* format = SelectTrack (extractor, "audio/");

		if (!format) {

			ndk.AMediaExtractor_delete (extractor);
			return false;

		}

		int64_t durationUs = 0;
		ndk.AMediaFormat_getInt64 (format, "durationUs", &durationUs);

		// Hardware decoding only applies to video
		audio.codec = CreateDecoder (format, false);
		audio.extractor = extractor;
		ndk.AMediaFormat_delete (format);

		if (!audio.codec || !audio.Prime () || !ReadAudioFormat ()) {

			audio.Close ();
			return false;

		}

		audioChannels = audioSourceChannels > 2 ? 2 : audioSourceChannels;
		if (durationUs / 1000000.0 > duration) duration = durationUs / 1000000.0;

		return true;

	}


	bool MediaCodecVideoBackend::OpenVideo (bool hardware) {

		AMediaExtractor* extractor = CreateExtractor ();
		if (!extractor) return false;

		AMediaFormat* format = SelectTrack (extractor, "video/");

		if (!format) {

			ndk.AMediaExtractor_delete (extractor);
			return false;

		}

		float floatRate = 0;
		int32_t intRate = 0;
		double formatRate = ndk.AMediaFormat_getFloat (format, "frame-rate", &floatRate) ? floatRate : (ndk.AMediaFormat_getInt32 (format, "frame-rate", &intRate) ? intRate : 0);

		// Containers may round the frame rate, so prefer the spacing of the
		// first frames when it agrees
		frameRate = EstimateFrameRate (extractor);
		if (formatRate > 0 && !(fabs (frameRate - formatRate) < 0.5)) frameRate = formatRate;

		int64_t durationUs = 0;
		ndk.AMediaFormat_getInt64 (format, "durationUs", &durationUs);

		video.codec = CreateDecoder (format, hardware);
		video.extractor = extractor;
		videoFormat = format;
		hardwareActive = hardware;

		if (!video.codec || !video.Prime () || !ReadVideoFormat () || cropWidth <= 0 || cropHeight <= 0) {

			video.Close ();
			ndk.AMediaFormat_delete (videoFormat);
			videoFormat = NULL;
			hardwareActive = false;
			return false;

		}

		if (durationUs / 1000000.0 > duration) duration = durationUs / 1000000.0;

		return true;

	}


	bool MediaCodecVideoBackend::ReadAudioFormat () {

		AMediaFormat* format = ndk.AMediaCodec_getOutputFormat (audio.codec);
		if (!format) return false;

		int32_t channels = 0;
		int32_t encoding = PCM_ENCODING_16BIT;
		int32_t sampleRate = 0;

		ndk.AMediaFormat_getInt32 (format, "channel-count", &channels);
		ndk.AMediaFormat_getInt32 (format, "pcm-encoding", &encoding);
		ndk.AMediaFormat_getInt32 (format, "sample-rate", &sampleRate);
		ndk.AMediaFormat_delete (format);

		audioFloat = (encoding == PCM_ENCODING_FLOAT);
		audioSampleRate = sampleRate;
		audioSourceChannels = channels;

		return (channels > 0 && channels <= 8 && sampleRate > 0 && (encoding == PCM_ENCODING_16BIT || audioFloat));

	}


	bool MediaCodecVideoBackend::ReadPlaneLayout (AMediaFormat* format, int width, int height) {

		void* image = NULL;
		size_t imageSize = 0;

		if (ndk.AMediaFormat_getBuffer (format, "image-data", &image, &imageSize) && imageSize >= MEDIA_IMAGE_SIZE) {

			uint32_t header[6] = {};
			MediaImagePlane plane[3];
			size_t headerSize = imageSize >= MEDIA_IMAGE2_SIZE ? 24 : 20;

			memcpy (header, image, headerSize);
			memcpy (plane, (const uint8_t*)image + headerSize, sizeof (plane));

			bool eightBit = (header[4] == 8 && (headerSize == 20 || header[5] == 8));
			bool luma = (plane[0].colInc == 1 && plane[0].rowInc > 0 && plane[0].horizSubsampling == 1 && plane[0].vertSubsampling == 1);
			bool chroma = (plane[1].colInc >= 1 && plane[1].colInc <= 2 && plane[1].rowInc > 0 && plane[1].colInc == plane[2].colInc && plane[1].rowInc == plane[2].rowInc);
			bool subsampled = (plane[1].horizSubsampling == 2 && plane[1].vertSubsampling == 2 && plane[2].horizSubsampling == 2 && plane[2].vertSubsampling == 2);

			if (header[0] == MEDIA_IMAGE_TYPE_YUV && header[1] == 3 && eightBit && luma && chroma && subsampled) {

				yOffset = plane[0].offset;
				yStride = plane[0].rowInc;
				uOffset = plane[1].offset;
				vOffset = plane[2].offset;
				uvStride = plane[1].rowInc;
				uvPixelStride = plane[1].colInc;
				return true;

			}

		}

		int32_t colorFormat = 0;
		int32_t sliceHeight = 0;
		int32_t stride = 0;

		ndk.AMediaFormat_getInt32 (format, "color-format", &colorFormat);
		ndk.AMediaFormat_getInt32 (format, "slice-height", &sliceHeight);
		ndk.AMediaFormat_getInt32 (format, "stride", &stride);

		// Some decoders report no stride or a slice height of 0
		if (stride < width) stride = width;
		if (sliceHeight < height) sliceHeight = height;

		if (colorFormat == COLOR_FORMAT_QCOM_YUV420_SEMI_PLANAR_32M) {

			// Venus buffers align the stride to 128 and the height to 32
			stride = std::max (stride, (width + 127) & ~127);
			sliceHeight = std::max (sliceHeight, (height + 31) & ~31);

		}

		yOffset = 0;
		yStride = stride;
		uOffset = (size_t)stride * sliceHeight;

		switch (colorFormat) {

			case COLOR_FORMAT_YUV420_PLANAR:
			case COLOR_FORMAT_YUV420_PACKED_PLANAR:
			case COLOR_FORMAT_YUV420_FLEXIBLE:

				uvStride = (stride + 1) / 2;
				vOffset = uOffset + (size_t)uvStride * ((sliceHeight + 1) / 2);
				uvPixelStride = 1;
				return true;

			case COLOR_FORMAT_YUV420_SEMI_PLANAR:
			case COLOR_FORMAT_YUV420_PACKED_SEMI_PLANAR:
			case COLOR_FORMAT_QCOM_YUV420_SEMI_PLANAR:
			case COLOR_FORMAT_QCOM_YUV420_SEMI_PLANAR_32M:

				uvStride = stride;
				vOffset = uOffset + 1;
				uvPixelStride = 2;
				return true;

			default:

				return false;

		}

	}


	bool MediaCodecVideoBackend::ReadVideoFormat () {

		AMediaFormat* format = ndk.AMediaCodec_getOutputFormat (video.codec);
		if (!format) return false;

		int32_t width = 0;
		int32_t height = 0;
		int32_t trackWidth = 0;
		int32_t trackHeight = 0;

		ndk.AMediaFormat_getInt32 (format, "width", &width);
		ndk.AMediaFormat_getInt32 (format, "height", &height);
		ndk.AMediaFormat_getInt32 (videoFormat, "width", &trackWidth);
		ndk.AMediaFormat_getInt32 (videoFormat, "height", &trackHeight);

		if (width <= 0 || height <= 0) {

			width = trackWidth;
			height = trackHeight;

		}

		int32_t left = 0;
		int32_t top = 0;
		int32_t right = -1;
		int32_t bottom = -1;

		bool cropped = (ndk.AMediaFormat_getRect && ndk.AMediaFormat_getRect (format, "crop", &left, &top, &right, &bottom));

		if (!cropped || left < 0 || top < 0 || right < left || bottom < top || right >= width || bottom >= height) {

			// The crop rectangle cannot be read before API level 28, so use the
			// track's picture size
			left = 0;
			top = 0;
			right = (trackWidth > 0 && trackWidth < width ? trackWidth : width) - 1;
			bottom = (trackHeight > 0 && trackHeight < height ? trackHeight : height) - 1;

		}

		cropX = left;
		cropY = top;
		cropWidth = right - left + 1;
		cropHeight = bottom - top + 1;

		bool supported = ReadPlaneLayout (format, width, height);

		// Decoders only report the color aspects that the stream signals
		int32_t range = 0;
		int32_t standard = 0;

		if (!ndk.AMediaFormat_getInt32 (format, "color-range", &range) || range == 0) ndk.AMediaFormat_getInt32 (videoFormat, "color-range", &range);
		if (!ndk.AMediaFormat_getInt32 (format, "color-standard", &standard) || standard == 0) ndk.AMediaFormat_getInt32 (videoFormat, "color-standard", &standard);

		ndk.AMediaFormat_delete (format);

		switch (standard) {

			case COLOR_STANDARD_BT709: colorMatrix = VIDEO_COLOR_MATRIX_BT709; break;
			case COLOR_STANDARD_BT601_PAL: case COLOR_STANDARD_BT601_NTSC: colorMatrix = VIDEO_COLOR_MATRIX_BT601; break;
			case COLOR_STANDARD_BT2020: colorMatrix = VIDEO_COLOR_MATRIX_BT2020; break;
			default: colorMatrix = GetDefaultColorMatrix (cropWidth, cropHeight); break;

		}

		fullRange = (range == COLOR_RANGE_FULL);

		// DecodeVideo fails on a layout it cannot read
		if (!supported) yStride = 0;

		return supported;

	}


	bool MediaCodecVideoBackend::RestartVideo () {

		video.Release ();
		ndk.AMediaCodec_stop (video.codec);
		ndk.AMediaCodec_delete (video.codec);

		hardwareActive = false;
		video.codec = CreateDecoder (videoFormat, false);
		video.ended = false;
		video.inputEnded = false;

		if (!video.codec) return false;

		// Resume from the keyframe before the last frame returned, and skip to it
		ndk.AMediaExtractor_seekTo (video.extractor, std::max (videoPosition, videoTime), AMEDIAEXTRACTOR_SEEK_PREVIOUS_SYNC);
		videoSkipTime = videoTime;

		return video.Prime () && ReadVideoFormat ();

	}


	bool MediaCodecVideoBackend::Seek (double time) {

		int64_t position = (int64_t)(time * 1000000.0);
		bool success = true;

		if (video.codec) {

			success = video.Seek (position) && success;
			videoPosition = position;
			videoSkipTime = INT64_MIN;
			videoTime = INT64_MIN;

		}

		if (audio.codec) success = audio.Seek (position) && success;

		return success;

	}


	VideoBackend* VideoBackend::Create () {

		return LoadMediaNDK () ? new MediaCodecVideoBackend () : NULL;

	}


	bool VideoBackend::IsSupported () {

		return LoadMediaNDK ();

	}


}


#endif
