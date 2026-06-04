#include <media/VideoDecoder.h>

#include <algorithm>
#include <cerrno>
#include <cstring>
#include <deque>
#include <mutex>
#include <string>
#include <vector>

#ifdef HX_WINDOWS
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <propvarutil.h>
#endif

#if defined(HX_LINUX) && defined(LIME_GSTREAMER)
#include <gst/app/gstappsink.h>
#include <gst/gst.h>
#include <gst/pbutils/gstdiscoverer.h>
#include <gst/video/video.h>
#endif

#if defined(HX_LINUX) && defined(LIME_FFMPEG)
extern "C" {
	#include <libavcodec/avcodec.h>
	#include <libavformat/avformat.h>
	#include <libavutil/channel_layout.h>
	#include <libavutil/imgutils.h>
	#include <libavutil/opt.h>
	#include <libavutil/samplefmt.h>
	#include <libswresample/swresample.h>
	#include <libswscale/swscale.h>
}
#endif


namespace lime {


#ifdef HX_WINDOWS


	static int ClampByte (int value) {

		return value < 0 ? 0 : (value > 255 ? 255 : value);

	}


	static std::wstring WidenPath (const char* utf8) {

		if (!utf8) return std::wstring ();

		int length = MultiByteToWideChar (CP_UTF8, 0, utf8, -1, 0, 0);
		if (length <= 0) return std::wstring ();

		std::wstring result (length, 0);
		MultiByteToWideChar (CP_UTF8, 0, utf8, -1, &result[0], length);
		if (!result.empty () && result[result.size () - 1] == 0) result.resize (result.size () - 1);
		return result;

	}


	static void YUVToRGB (unsigned char y, unsigned char u, unsigned char v, unsigned char& r, unsigned char& g, unsigned char& b) {

		int c = y - 16;
		int d = u - 128;
		int e = v - 128;

		r = (unsigned char)ClampByte ((298 * c + 409 * e + 128) >> 8);
		g = (unsigned char)ClampByte ((298 * c - 100 * d - 208 * e + 128) >> 8);
		b = (unsigned char)ClampByte ((298 * c + 516 * d + 128) >> 8);

	}


	static IMFAttributes* CreateReaderAttributes (bool hardwareDecodingEnabled) {

		IMFAttributes* attributes = 0;
		if (FAILED (MFCreateAttributes (&attributes, 4))) return 0;

		attributes->SetUINT32 (MF_READWRITE_ENABLE_HARDWARE_TRANSFORMS, hardwareDecodingEnabled ? 1u : 0u);
		attributes->SetUINT32 (MF_SOURCE_READER_DISABLE_DXVA, hardwareDecodingEnabled ? 0u : 1u);
		return attributes;

	}


	static HRESULT CreateSourceReaderForPath (const wchar_t* path, bool hardwareDecodingEnabled, IMFSourceReader** outReader) {

		if (!outReader) return E_POINTER;
		*outReader = 0;

		IMFAttributes* attributes = CreateReaderAttributes (hardwareDecodingEnabled);
		HRESULT hr = MFCreateSourceReaderFromURL (path, attributes, outReader);
		if (attributes) attributes->Release ();
		return hr;

	}


	enum SampleReadStatus {

		SAMPLE_READ_SUCCESS = 0,
		SAMPLE_READ_NO_SAMPLE = 1,
		SAMPLE_READ_END_OF_STREAM = 2,
		SAMPLE_READ_ERROR = 3

	};


	static SampleReadStatus ReadNextUsableSample (IMFSourceReader* reader, DWORD streamIndex, IMFSample** outSample) {

		if (outSample) *outSample = 0;
		if (!reader) return SAMPLE_READ_ERROR;

		for (int attempt = 0; attempt < 16; ++attempt) {

			IMFSample* sample = 0;
			DWORD flags = 0;
			HRESULT hr = reader->ReadSample (streamIndex, 0, 0, &flags, 0, &sample);

			if (FAILED (hr)) {

				if (sample) sample->Release ();
				return SAMPLE_READ_ERROR;

			}

			if (flags & MF_SOURCE_READERF_ENDOFSTREAM) {

				if (sample) sample->Release ();
				return SAMPLE_READ_END_OF_STREAM;

			}

			if (sample) {

				if (outSample) *outSample = sample;
				return SAMPLE_READ_SUCCESS;

			}

			if ((flags & MF_SOURCE_READERF_STREAMTICK) != 0
				|| (flags & MF_SOURCE_READERF_NEWSTREAM) != 0
				|| (flags & MF_SOURCE_READERF_NATIVEMEDIATYPECHANGED) != 0
				|| (flags & MF_SOURCE_READERF_CURRENTMEDIATYPECHANGED) != 0) {

				continue;

			}

			return SAMPLE_READ_NO_SAMPLE;

		}

		return SAMPLE_READ_NO_SAMPLE;

	}


	struct LockedVideoBuffer {

		IMFMediaBuffer* buffer = 0;
		IMF2DBuffer* buffer2D = 0;
		BYTE* data = 0;
		DWORD length = 0;
		LONG stride = 0;

	};


	static LONG ReadDefaultStride (IMFMediaType* mediaType, LONG fallbackStride) {

		if (!mediaType) return fallbackStride;

		UINT32 value = 0;
		if (SUCCEEDED (mediaType->GetUINT32 (MF_MT_DEFAULT_STRIDE, &value))) {

			LONG stride = (LONG)value;
			if (stride < 0) stride = -stride;
			if (stride > 0) return stride;

		}

		return fallbackStride;

	}


	static bool LockVideoBuffer (IMFSample* sample, LockedVideoBuffer& locked) {

		if (!sample) return false;

		IMFMediaBuffer* buffer = 0;
		HRESULT hr = sample->GetBufferByIndex (0, &buffer);
		if (FAILED (hr) || !buffer) {

			hr = sample->ConvertToContiguousBuffer (&buffer);
			if (FAILED (hr) || !buffer) return false;

		}

		locked.buffer = buffer;

		IMF2DBuffer* buffer2D = 0;
		if (SUCCEEDED (buffer->QueryInterface (IID_PPV_ARGS (&buffer2D))) && buffer2D) {

			BYTE* scanline0 = 0;
			LONG pitch = 0;
			hr = buffer2D->Lock2D (&scanline0, &pitch);
			if (SUCCEEDED (hr) && scanline0) {

				DWORD currentLength = 0;
				buffer->GetCurrentLength (&currentLength);
				locked.buffer2D = buffer2D;
				locked.data = scanline0;
				locked.length = currentLength;
				locked.stride = pitch < 0 ? -pitch : pitch;
				return true;

			}

			buffer2D->Release ();

		}

		BYTE* data = 0;
		DWORD length = 0;
		hr = buffer->Lock (&data, 0, &length);
		if (FAILED (hr) || !data) {

			buffer->Release ();
			locked.buffer = 0;
			return false;

		}

		locked.data = data;
		locked.length = length;
		locked.stride = 0;
		return true;

	}


	static void UnlockVideoBuffer (LockedVideoBuffer& locked) {

		if (locked.buffer2D) {

			locked.buffer2D->Unlock2D ();
			locked.buffer2D->Release ();
			locked.buffer2D = 0;

		} else if (locked.buffer) {

			locked.buffer->Unlock ();

		}

		if (locked.buffer) {

			locked.buffer->Release ();
			locked.buffer = 0;

		}

		locked.data = 0;
		locked.length = 0;
		locked.stride = 0;

	}


	static int ResolveAlignedLumaHeight (DWORD length, int strideBytes, int visibleHeight) {

		if (strideBytes <= 0 || visibleHeight <= 0) return visibleHeight;
		int minimum = strideBytes * (visibleHeight + (visibleHeight / 2));
		if ((int)length <= minimum) return visibleHeight;

		int totalRows = (int)length / strideBytes;
		int aligned = (totalRows * 2) / 3;
		return aligned >= visibleHeight ? aligned : visibleHeight;

	}


	struct VideoDecoderState {

		bool hardwareDecodingEnabled = true;
		bool mfStarted = false;
		bool hasAudio = false;
		IMFSourceReader* reader = 0;
		int width = 0;
		int height = 0;
		float frameRate = 0.0f;
		int durationMs = 0;
		int audioBitsPerSample = 0;
		int audioChannels = 0;
		int audioSampleRate = 0;
		LONGLONG currentAudioPosition = 0;
		LONGLONG currentVideoPosition = 0;
		LONG videoStrideBytes = 0;
		std::vector<unsigned char> audioLeftover;
		size_t audioLeftoverOffset = 0;
		std::mutex mutex;

	};


	static void ReleaseReader (VideoDecoderState* state) {

		if (state && state->reader) {

			state->reader->Release ();
			state->reader = 0;

		}

	}


	static void ResetState (VideoDecoderState* state) {

		if (!state) return;

		state->hasAudio = false;
		state->width = 0;
		state->height = 0;
		state->frameRate = 0.0f;
		state->durationMs = 0;
		state->audioBitsPerSample = 0;
		state->audioChannels = 0;
		state->audioSampleRate = 0;
		state->currentAudioPosition = 0;
		state->currentVideoPosition = 0;
		state->videoStrideBytes = 0;
		state->audioLeftover.clear ();
		state->audioLeftoverOffset = 0;

	}


	static void CompactAudioLeftover (VideoDecoderState* state) {

		if (!state || state->audioLeftoverOffset == 0) return;

		if (state->audioLeftoverOffset >= state->audioLeftover.size ()) {

			state->audioLeftover.clear ();
			state->audioLeftoverOffset = 0;
			return;

		}

		state->audioLeftover.erase (state->audioLeftover.begin (), state->audioLeftover.begin () + state->audioLeftoverOffset);
		state->audioLeftoverOffset = 0;

	}


	VideoDecoder::VideoDecoder () {

		state = new VideoDecoderState ();
		state->mfStarted = SUCCEEDED (MFStartup (MF_VERSION));

	}


	VideoDecoder::~VideoDecoder () {

		Close ();

		if (state) {

			if (state->mfStarted) MFShutdown ();
			delete state;
			state = 0;

		}

	}


	bool VideoDecoder::IsSupported () {

		return true;

	}


	void VideoDecoder::Close () {

		if (!state) return;

		std::lock_guard<std::mutex> lock (state->mutex);
		ReleaseReader (state);
		ResetState (state);

	}


	int VideoDecoder::GetAudioBitsPerSample () {

		return state ? state->audioBitsPerSample : 0;

	}


	int VideoDecoder::GetAudioChannelCount () {

		return state ? state->audioChannels : 0;

	}


	int VideoDecoder::GetAudioSampleRate () {

		return state ? state->audioSampleRate : 0;

	}


	int VideoDecoder::GetDuration () {

		return state ? state->durationMs : 0;

	}


	float VideoDecoder::GetFrameRate () {

		return state ? state->frameRate : 0.0f;

	}


	int VideoDecoder::GetHeight () {

		return state ? state->height : 0;

	}


	int VideoDecoder::GetVideoPosition () {

		return state ? (int)(state->currentVideoPosition / 10000) : 0;

	}


	int VideoDecoder::GetWidth () {

		return state ? state->width : 0;

	}


	bool VideoDecoder::Load (const char* path) {

		if (!state || !state->mfStarted || !path || !path[0]) return false;

		std::lock_guard<std::mutex> lock (state->mutex);
		ReleaseReader (state);
		ResetState (state);

		IMFSourceReader* reader = 0;
		IMFMediaType* videoType = 0;
		IMFMediaType* actualVideoType = 0;
		IMFMediaType* audioType = 0;
		bool success = false;

		std::wstring widePath = WidenPath (path);
		if (widePath.empty ()) goto cleanup;

		if (FAILED (CreateSourceReaderForPath (widePath.c_str (), state->hardwareDecodingEnabled, &reader))) goto cleanup;
		if (FAILED (MFCreateMediaType (&videoType))) goto cleanup;

		videoType->SetGUID (MF_MT_MAJOR_TYPE, MFMediaType_Video);
		videoType->SetGUID (MF_MT_SUBTYPE, MFVideoFormat_NV12);
		if (FAILED (reader->SetCurrentMediaType (MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0, videoType))) goto cleanup;
		if (FAILED (reader->GetCurrentMediaType (MF_SOURCE_READER_FIRST_VIDEO_STREAM, &actualVideoType))) goto cleanup;

		GUID actualSubtype = GUID_NULL;
		if (FAILED (actualVideoType->GetGUID (MF_MT_SUBTYPE, &actualSubtype)) || actualSubtype != MFVideoFormat_NV12) goto cleanup;

		UINT32 width = 0;
		UINT32 height = 0;
		if (FAILED (MFGetAttributeSize (actualVideoType, MF_MT_FRAME_SIZE, &width, &height)) || width == 0 || height == 0) goto cleanup;

		UINT32 numerator = 0;
		UINT32 denominator = 0;
		if (SUCCEEDED (MFGetAttributeRatio (actualVideoType, MF_MT_FRAME_RATE, &numerator, &denominator)) && denominator != 0) {

			state->frameRate = (float)numerator / (float)denominator;

		}

		state->width = (int)width;
		state->height = (int)height;
		state->videoStrideBytes = ReadDefaultStride (actualVideoType, (LONG)width);

		if (SUCCEEDED (MFCreateMediaType (&audioType))) {

			audioType->SetGUID (MF_MT_MAJOR_TYPE, MFMediaType_Audio);
			audioType->SetGUID (MF_MT_SUBTYPE, MFAudioFormat_PCM);

			if (SUCCEEDED (reader->SetCurrentMediaType (MF_SOURCE_READER_FIRST_AUDIO_STREAM, 0, audioType))) {

				IMFMediaType* actualAudioType = 0;
				if (SUCCEEDED (reader->GetCurrentMediaType (MF_SOURCE_READER_FIRST_AUDIO_STREAM, &actualAudioType)) && actualAudioType) {

					UINT32 value = 0;
					if (SUCCEEDED (actualAudioType->GetUINT32 (MF_MT_AUDIO_BITS_PER_SAMPLE, &value))) state->audioBitsPerSample = (int)value;
					if (SUCCEEDED (actualAudioType->GetUINT32 (MF_MT_AUDIO_NUM_CHANNELS, &value))) state->audioChannels = (int)value;
					if (SUCCEEDED (actualAudioType->GetUINT32 (MF_MT_AUDIO_SAMPLES_PER_SECOND, &value))) state->audioSampleRate = (int)value;
					state->hasAudio = state->audioChannels > 0 && state->audioSampleRate > 0;
					actualAudioType->Release ();

				}

			}

		}

		PROPVARIANT duration;
		PropVariantInit (&duration);
		if (SUCCEEDED (reader->GetPresentationAttribute (MF_SOURCE_READER_MEDIASOURCE, MF_PD_DURATION, &duration))) {

			state->durationMs = (int)(duration.uhVal.QuadPart / 10000);

		}
		PropVariantClear (&duration);

		state->reader = reader;
		reader = 0;
		success = true;

cleanup:
		if (audioType) audioType->Release ();
		if (actualVideoType) actualVideoType->Release ();
		if (videoType) videoType->Release ();
		if (reader) reader->Release ();

		if (!success) ResetState (state);
		return success;

	}


	int VideoDecoder::ReadAudio (unsigned char* outBuffer, int bytesLength) {

		if (!state || !outBuffer || bytesLength <= 0) return -1;

		std::lock_guard<std::mutex> lock (state->mutex);
		if (!state->reader || !state->hasAudio) return -1;

		int totalCopied = 0;

		while (totalCopied < bytesLength && state->audioLeftoverOffset < state->audioLeftover.size ()) {

			int available = (int)(state->audioLeftover.size () - state->audioLeftoverOffset);
			int toCopy = std::min (available, bytesLength - totalCopied);
			memcpy (outBuffer + totalCopied, state->audioLeftover.data () + state->audioLeftoverOffset, toCopy);
			totalCopied += toCopy;
			state->audioLeftoverOffset += toCopy;

			if (state->audioLeftoverOffset >= state->audioLeftover.size ()) {

				state->audioLeftover.clear ();
				state->audioLeftoverOffset = 0;

			}

		}

		while (totalCopied < bytesLength) {

			IMFSample* sample = 0;
			SampleReadStatus readStatus = ReadNextUsableSample (state->reader, MF_SOURCE_READER_FIRST_AUDIO_STREAM, &sample);
			if (readStatus == SAMPLE_READ_END_OF_STREAM) break;
			if (readStatus == SAMPLE_READ_ERROR) return totalCopied > 0 ? totalCopied : -1;
			if (readStatus == SAMPLE_READ_NO_SAMPLE || !sample) break;

			LONGLONG sampleTime = 0;
			if (SUCCEEDED (sample->GetSampleTime (&sampleTime))) state->currentAudioPosition = sampleTime;

			IMFMediaBuffer* buffer = 0;
			HRESULT hr = sample->ConvertToContiguousBuffer (&buffer);
			sample->Release ();
			if (FAILED (hr) || !buffer) break;

			BYTE* data = 0;
			DWORD length = 0;
			hr = buffer->Lock (&data, 0, &length);
			if (FAILED (hr) || !data) {

				buffer->Release ();
				break;

			}

			int toCopy = std::min ((int)length, bytesLength - totalCopied);
			memcpy (outBuffer + totalCopied, data, toCopy);
			totalCopied += toCopy;

			if (toCopy < (int)length) {

				CompactAudioLeftover (state);
				state->audioLeftover.insert (state->audioLeftover.end (), data + toCopy, data + length);

			}

			buffer->Unlock ();
			buffer->Release ();

		}

		return totalCopied > 0 ? totalCopied : -1;

	}


	bool VideoDecoder::ReadRGBAFrame (unsigned char* outBuffer, int bufferSize) {

		if (!state || !outBuffer) return false;

		std::lock_guard<std::mutex> lock (state->mutex);
		if (!state->reader || state->width <= 0 || state->height <= 0) return false;

		IMFSample* sample = 0;
		SampleReadStatus readStatus = ReadNextUsableSample (state->reader, MF_SOURCE_READER_FIRST_VIDEO_STREAM, &sample);
		if (readStatus == SAMPLE_READ_END_OF_STREAM || readStatus == SAMPLE_READ_ERROR) return false;
		if (readStatus == SAMPLE_READ_NO_SAMPLE || !sample) return true;

		LONGLONG timestamp = 0;
		bool hasTimestamp = SUCCEEDED (sample->GetSampleTime (&timestamp));

		LockedVideoBuffer locked;
		if (!LockVideoBuffer (sample, locked)) {

			sample->Release ();
			return false;

		}
		sample->Release ();

		int width = state->width;
		int height = state->height;
		int uvHeight = height / 2;
		int requiredOutputSize = width * height * 4;
		int frameSize = width * height;
		int requiredNv12Size = frameSize + (frameSize / 2);

		if (bufferSize < requiredOutputSize || (int)locked.length < requiredNv12Size || width <= 0 || height <= 0 || uvHeight <= 0) {

			UnlockVideoBuffer (locked);
			return false;

		}

		int strideBytes = locked.stride > 0 ? locked.stride : state->videoStrideBytes;
		if (strideBytes <= 0) {

			strideBytes = width;
			int rowCount = height + uvHeight;
			if (rowCount > 0) {

				int inferredStride = (int)locked.length / rowCount;
				if (inferredStride >= width) strideBytes = inferredStride;

			}

		}

		int alignedLumaHeight = ResolveAlignedLumaHeight (locked.length, strideBytes, height);
		int requiredStrideBytes = strideBytes * (alignedLumaHeight + (alignedLumaHeight / 2));
		if (strideBytes < width || (int)locked.length < requiredStrideBytes) {

			UnlockVideoBuffer (locked);
			return false;

		}

		BYTE* yPlane = locked.data;
		BYTE* uvPlane = locked.data + (strideBytes * alignedLumaHeight);

		for (int y = 0; y < height; ++y) {

			const BYTE* yRow = yPlane + (y * strideBytes);
			const BYTE* uvRow = uvPlane + ((y / 2) * strideBytes);
			unsigned char* outRow = outBuffer + (y * width * 4);

			for (int x = 0; x < width; ++x) {

				int uvIndex = x & ~1;
				unsigned char r, g, b;
				YUVToRGB (yRow[x], uvRow[uvIndex], uvRow[uvIndex + 1], r, g, b);

				int outIndex = x * 4;
				outRow[outIndex] = r;
				outRow[outIndex + 1] = g;
				outRow[outIndex + 2] = b;
				outRow[outIndex + 3] = 255;

			}

		}

		if (hasTimestamp) state->currentVideoPosition = timestamp;

		UnlockVideoBuffer (locked);
		return true;

	}


	void VideoDecoder::Seek (int targetMs) {

		if (!state) return;

		std::lock_guard<std::mutex> lock (state->mutex);
		if (!state->reader) return;

		if (targetMs < 0) targetMs = 0;
		LONGLONG seekTime = (LONGLONG)targetMs * 10000;

		PROPVARIANT prop;
		PropVariantInit (&prop);
		prop.vt = VT_I8;
		prop.hVal.QuadPart = seekTime;

		HRESULT hr = state->reader->SetCurrentPosition (GUID_NULL, prop);
		PropVariantClear (&prop);
		if (FAILED (hr)) return;

		state->currentVideoPosition = seekTime;
		state->currentAudioPosition = seekTime;
		state->audioLeftover.clear ();
		state->audioLeftoverOffset = 0;

	}


	void VideoDecoder::SetHardwareDecodingEnabled (bool enabled) {

		if (state) state->hardwareDecodingEnabled = enabled;

	}


#elif defined(HX_LINUX) && defined(LIME_GSTREAMER)


	struct VideoDecoderState {

		bool hardwareDecodingEnabled = true;
		GstElement* videoPipeline = 0;
		GstElement* audioPipeline = 0;
		GstElement* videoSink = 0;
		GstElement* audioSink = 0;
		int width = 0;
		int height = 0;
		float frameRate = 0.0f;
		int durationMs = 0;
		int audioBitsPerSample = 0;
		int audioChannels = 0;
		int audioSampleRate = 0;
		int currentAudioPosition = 0;
		int currentVideoPosition = 0;
		std::vector<unsigned char> audioLeftover;
		size_t audioLeftoverOffset = 0;
		std::mutex mutex;

	};


	static std::once_flag gGStreamerInitOnce;


	static void InitGStreamerOnce () {

		std::call_once (gGStreamerInitOnce, [] () {

			int argc = 0;
			char** argv = 0;
			gst_init (&argc, &argv);

		});

	}


	static void ResetState (VideoDecoderState* state) {

		if (!state) return;

		state->width = 0;
		state->height = 0;
		state->frameRate = 0.0f;
		state->durationMs = 0;
		state->audioBitsPerSample = 0;
		state->audioChannels = 0;
		state->audioSampleRate = 0;
		state->currentAudioPosition = 0;
		state->currentVideoPosition = 0;
		state->audioLeftover.clear ();
		state->audioLeftoverOffset = 0;

	}


	static void ReleasePipeline (GstElement*& pipeline, GstElement*& sink) {

		if (pipeline) {

			gst_element_set_state (pipeline, GST_STATE_NULL);
			gst_object_unref (pipeline);
			pipeline = 0;

		}

		if (sink) {

			gst_object_unref (sink);
			sink = 0;

		}

	}


	static void ReleaseDecoder (VideoDecoderState* state) {

		if (!state) return;

		ReleasePipeline (state->videoPipeline, state->videoSink);
		ReleasePipeline (state->audioPipeline, state->audioSink);
		ResetState (state);

	}


	static void CompactAudioLeftover (VideoDecoderState* state) {

		if (!state || state->audioLeftoverOffset == 0) return;

		if (state->audioLeftoverOffset >= state->audioLeftover.size ()) {

			state->audioLeftover.clear ();
			state->audioLeftoverOffset = 0;
			return;

		}

		state->audioLeftover.erase (state->audioLeftover.begin (), state->audioLeftover.begin () + state->audioLeftoverOffset);
		state->audioLeftoverOffset = 0;

	}


	static GstElement* CreateSinkBin (const char* description, const char* sinkName, GstElement** outSink) {

		if (outSink) *outSink = 0;

		GError* error = 0;
		GstElement* bin = gst_parse_bin_from_description (description, TRUE, &error);

		if (error) {

			g_error_free (error);

		}

		if (!bin) return 0;
		if (!outSink) return bin;

		*outSink = gst_bin_get_by_name (GST_BIN (bin), sinkName);
		if (!*outSink) {

			gst_object_unref (bin);
			return 0;

		}

		return bin;

	}


	static GstElement* CreateFakeSink () {

		GstElement* sink = gst_element_factory_make ("fakesink", 0);
		if (sink) g_object_set (G_OBJECT (sink), "sync", FALSE, 0);
		return sink;

	}


	static bool WaitForPipeline (GstElement* pipeline) {

		if (!pipeline) return false;

		GstStateChangeReturn result = gst_element_get_state (pipeline, 0, 0, 5 * GST_SECOND);
		return result != GST_STATE_CHANGE_FAILURE;

	}


	static void ApplyDiscovererStreamInfo (VideoDecoderState* state, GstDiscovererStreamInfo* streamInfo) {

		if (!state || !streamInfo) return;

		if (GST_IS_DISCOVERER_VIDEO_INFO (streamInfo)) {

			GstDiscovererVideoInfo* videoInfo = GST_DISCOVERER_VIDEO_INFO (streamInfo);
			state->width = (int)gst_discoverer_video_info_get_width (videoInfo);
			state->height = (int)gst_discoverer_video_info_get_height (videoInfo);

			int frameRateNum = gst_discoverer_video_info_get_framerate_num (videoInfo);
			int frameRateDen = gst_discoverer_video_info_get_framerate_denom (videoInfo);
			state->frameRate = frameRateNum > 0 && frameRateDen > 0 ? (float)frameRateNum / (float)frameRateDen : 0.0f;

		} else if (GST_IS_DISCOVERER_AUDIO_INFO (streamInfo)) {

			GstDiscovererAudioInfo* audioInfo = GST_DISCOVERER_AUDIO_INFO (streamInfo);
			state->audioChannels = (int)gst_discoverer_audio_info_get_channels (audioInfo);
			state->audioSampleRate = (int)gst_discoverer_audio_info_get_sample_rate (audioInfo);
			state->audioBitsPerSample = state->audioChannels > 0 && state->audioSampleRate > 0 ? 16 : 0;

		} else if (GST_IS_DISCOVERER_CONTAINER_INFO (streamInfo)) {

			GList* streams = gst_discoverer_container_info_get_streams (GST_DISCOVERER_CONTAINER_INFO (streamInfo));

			for (GList* item = streams; item; item = item->next) {

				ApplyDiscovererStreamInfo (state, GST_DISCOVERER_STREAM_INFO (item->data));

			}

			gst_discoverer_stream_info_list_free (streams);

		}

	}


	static bool DiscoverSource (VideoDecoderState* state, const char* uri) {

		GError* error = 0;
		GstDiscoverer* discoverer = gst_discoverer_new (5 * GST_SECOND, &error);

		if (error) {

			g_error_free (error);

		}

		if (!discoverer) return false;

		error = 0;
		GstDiscovererInfo* info = gst_discoverer_discover_uri (discoverer, uri, &error);

		if (error) {

			g_error_free (error);

		}

		if (!info) {

			gst_object_unref (discoverer);
			return false;

		}

		GstClockTime duration = gst_discoverer_info_get_duration (info);
		state->durationMs = GST_CLOCK_TIME_IS_VALID (duration) ? (int)(duration / GST_MSECOND) : 0;

		GstDiscovererStreamInfo* streamInfo = gst_discoverer_info_get_stream_info (info);
		if (streamInfo) {

			ApplyDiscovererStreamInfo (state, streamInfo);
			gst_discoverer_stream_info_unref (streamInfo);

		}

		gst_discoverer_info_unref (info);
		gst_object_unref (discoverer);
		return state->width > 0 && state->height > 0;

	}


	static void ApplyAudioCaps (VideoDecoderState* state, GstCaps* caps) {

		if (!state || !caps || gst_caps_get_size (caps) <= 0) return;

		GstStructure* structure = gst_caps_get_structure (caps, 0);
		if (!structure) return;

		int channels = 0;
		int sampleRate = 0;
		if (gst_structure_get_int (structure, "channels", &channels) && channels > 0) state->audioChannels = channels;
		if (gst_structure_get_int (structure, "rate", &sampleRate) && sampleRate > 0) state->audioSampleRate = sampleRate;
		state->audioBitsPerSample = state->audioChannels > 0 && state->audioSampleRate > 0 ? 16 : 0;

	}


	static bool ApplyVideoCaps (VideoDecoderState* state, GstCaps* caps, GstVideoInfo* outInfo) {

		if (!state || !caps || !outInfo) return false;

		gst_video_info_init (outInfo);
		if (!gst_video_info_from_caps (outInfo, caps)) return false;

		state->width = GST_VIDEO_INFO_WIDTH (outInfo);
		state->height = GST_VIDEO_INFO_HEIGHT (outInfo);
		return state->width > 0 && state->height > 0;

	}


	static void DrainAppSink (GstElement* sink) {

		if (!sink) return;

		while (true) {

			GstSample* sample = gst_app_sink_try_pull_sample (GST_APP_SINK (sink), 0);
			if (!sample) break;
			gst_sample_unref (sample);

		}

	}


	VideoDecoder::VideoDecoder () {

		InitGStreamerOnce ();
		state = new VideoDecoderState ();

	}


	VideoDecoder::~VideoDecoder () {

		Close ();

		if (state) {

			delete state;
			state = 0;

		}

	}


	bool VideoDecoder::IsSupported () {

		return true;

	}


	void VideoDecoder::Close () {

		if (!state) return;

		std::lock_guard<std::mutex> lock (state->mutex);
		ReleaseDecoder (state);

	}


	int VideoDecoder::GetAudioBitsPerSample () {

		return state ? state->audioBitsPerSample : 0;

	}


	int VideoDecoder::GetAudioChannelCount () {

		return state ? state->audioChannels : 0;

	}


	int VideoDecoder::GetAudioSampleRate () {

		return state ? state->audioSampleRate : 0;

	}


	int VideoDecoder::GetDuration () {

		return state ? state->durationMs : 0;

	}


	float VideoDecoder::GetFrameRate () {

		return state ? state->frameRate : 0.0f;

	}


	int VideoDecoder::GetHeight () {

		return state ? state->height : 0;

	}


	int VideoDecoder::GetVideoPosition () {

		return state ? state->currentVideoPosition : 0;

	}


	int VideoDecoder::GetWidth () {

		return state ? state->width : 0;

	}


	bool VideoDecoder::Load (const char* path) {

		if (!state || !path || !*path) return false;

		std::lock_guard<std::mutex> lock (state->mutex);
		ReleaseDecoder (state);

		GError* error = 0;
		gchar* uri = gst_filename_to_uri (path, &error);

		if (error) {

			g_error_free (error);

		}

		if (!uri) return false;

		bool discovered = DiscoverSource (state, uri);
		if (!discovered) {

			g_free (uri);
			ReleaseDecoder (state);
			return false;

		}

		GstElement* videoBin = CreateSinkBin ("videoconvert ! video/x-raw,format=RGBA ! appsink name=limevideosink emit-signals=false sync=false max-buffers=8 drop=false",
			"limevideosink", &state->videoSink);
		GstElement* fakeAudioSink = CreateFakeSink ();
		state->videoPipeline = gst_element_factory_make ("playbin", 0);

		if (!state->videoPipeline || !videoBin || !fakeAudioSink) {

			if (videoBin) gst_object_unref (videoBin);
			if (fakeAudioSink) gst_object_unref (fakeAudioSink);
			g_free (uri);
			ReleaseDecoder (state);
			return false;

		}

		g_object_set (G_OBJECT (state->videoPipeline), "uri", uri, "video-sink", videoBin, "audio-sink", fakeAudioSink, 0);
		gst_object_unref (videoBin);
		gst_object_unref (fakeAudioSink);

		GstElement* audioBin = CreateSinkBin ("audioconvert ! audioresample ! audio/x-raw,format=S16LE,layout=interleaved ! appsink name=limeaudiosink emit-signals=false sync=false max-buffers=64 drop=false",
			"limeaudiosink", &state->audioSink);
		GstElement* fakeVideoSink = CreateFakeSink ();
		state->audioPipeline = gst_element_factory_make ("playbin", 0);

		if (state->audioPipeline && audioBin && fakeVideoSink) {

			g_object_set (G_OBJECT (state->audioPipeline), "uri", uri, "audio-sink", audioBin, "video-sink", fakeVideoSink, 0);
			gst_object_unref (audioBin);
			gst_object_unref (fakeVideoSink);

		} else {

			if (audioBin) gst_object_unref (audioBin);
			if (fakeVideoSink) gst_object_unref (fakeVideoSink);
			if (state->audioPipeline) {

				gst_object_unref (state->audioPipeline);
				state->audioPipeline = 0;

			}
			if (state->audioSink) {

				gst_object_unref (state->audioSink);
				state->audioSink = 0;

			}

			state->audioBitsPerSample = 0;
			state->audioChannels = 0;
			state->audioSampleRate = 0;

		}

		g_free (uri);

		if (gst_element_set_state (state->videoPipeline, GST_STATE_PLAYING) == GST_STATE_CHANGE_FAILURE || !WaitForPipeline (state->videoPipeline)) {

			ReleaseDecoder (state);
			return false;

		}

		if (state->audioPipeline) {

			if (gst_element_set_state (state->audioPipeline, GST_STATE_PLAYING) == GST_STATE_CHANGE_FAILURE || !WaitForPipeline (state->audioPipeline)) {

				ReleasePipeline (state->audioPipeline, state->audioSink);
				state->audioBitsPerSample = 0;
				state->audioChannels = 0;
				state->audioSampleRate = 0;

			}

		}

		return state->width > 0 && state->height > 0;

	}


	int VideoDecoder::ReadAudio (unsigned char* outBuffer, int bytesLength) {

		if (!state || !outBuffer || bytesLength <= 0 || !state->audioSink) return -1;

		std::lock_guard<std::mutex> lock (state->mutex);

		int bytesWritten = 0;

		while (bytesWritten < bytesLength) {

			if (state->audioLeftoverOffset < state->audioLeftover.size ()) {

				int available = (int)(state->audioLeftover.size () - state->audioLeftoverOffset);
				int copyLength = std::min (available, bytesLength - bytesWritten);
				memcpy (outBuffer + bytesWritten, state->audioLeftover.data () + state->audioLeftoverOffset, copyLength);
				state->audioLeftoverOffset += copyLength;
				bytesWritten += copyLength;
				CompactAudioLeftover (state);
				continue;

			}

			GstSample* sample = gst_app_sink_try_pull_sample (GST_APP_SINK (state->audioSink), 2 * GST_SECOND);
			if (!sample) break;

			GstCaps* caps = gst_sample_get_caps (sample);
			ApplyAudioCaps (state, caps);

			GstBuffer* buffer = gst_sample_get_buffer (sample);
			GstMapInfo map;

			if (!buffer || !gst_buffer_map (buffer, &map, GST_MAP_READ)) {

				gst_sample_unref (sample);
				break;

			}

			int available = (int)map.size;
			int copyLength = std::min (available, bytesLength - bytesWritten);
			memcpy (outBuffer + bytesWritten, map.data, copyLength);
			bytesWritten += copyLength;

			if (copyLength < available) {

				state->audioLeftover.assign (map.data + copyLength, map.data + available);
				state->audioLeftoverOffset = 0;

			}

			GstClockTime timestamp = GST_BUFFER_PTS (buffer);
			if (GST_CLOCK_TIME_IS_VALID (timestamp)) state->currentAudioPosition = (int)(timestamp / GST_MSECOND);

			gst_buffer_unmap (buffer, &map);
			gst_sample_unref (sample);

		}

		return bytesWritten > 0 ? bytesWritten : -1;

	}


	bool VideoDecoder::ReadRGBAFrame (unsigned char* outBuffer, int bufferSize) {

		if (!state || !outBuffer || !state->videoSink) return false;

		std::lock_guard<std::mutex> lock (state->mutex);

		GstSample* sample = gst_app_sink_try_pull_sample (GST_APP_SINK (state->videoSink), 2 * GST_SECOND);
		if (!sample) return false;

		GstCaps* caps = gst_sample_get_caps (sample);
		GstVideoInfo videoInfo;

		if (!ApplyVideoCaps (state, caps, &videoInfo)) {

			gst_sample_unref (sample);
			return false;

		}

		int rowBytes = state->width * 4;
		int requiredSize = rowBytes * state->height;
		int stride = GST_VIDEO_INFO_PLANE_STRIDE (&videoInfo, 0);

		if (bufferSize < requiredSize || stride < rowBytes) {

			gst_sample_unref (sample);
			return false;

		}

		GstBuffer* buffer = gst_sample_get_buffer (sample);
		GstMapInfo map;

		if (!buffer || !gst_buffer_map (buffer, &map, GST_MAP_READ)) {

			gst_sample_unref (sample);
			return false;

		}

		for (int y = 0; y < state->height; ++y) {

			memcpy (outBuffer + y * rowBytes, map.data + y * stride, rowBytes);

		}

		GstClockTime timestamp = GST_BUFFER_PTS (buffer);
		if (GST_CLOCK_TIME_IS_VALID (timestamp)) state->currentVideoPosition = (int)(timestamp / GST_MSECOND);

		gst_buffer_unmap (buffer, &map);
		gst_sample_unref (sample);
		return true;

	}


	void VideoDecoder::Seek (int targetMs) {

		if (!state) return;

		std::lock_guard<std::mutex> lock (state->mutex);

		if (targetMs < 0) targetMs = 0;
		GstClockTime targetTime = (GstClockTime)targetMs * GST_MSECOND;
		GstSeekFlags flags = (GstSeekFlags)(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_KEY_UNIT);

		if (state->videoPipeline) gst_element_seek_simple (state->videoPipeline, GST_FORMAT_TIME, flags, targetTime);
		if (state->audioPipeline) gst_element_seek_simple (state->audioPipeline, GST_FORMAT_TIME, flags, targetTime);

		DrainAppSink (state->videoSink);
		DrainAppSink (state->audioSink);

		state->audioLeftover.clear ();
		state->audioLeftoverOffset = 0;
		state->currentVideoPosition = targetMs;
		state->currentAudioPosition = targetMs;

	}


	void VideoDecoder::SetHardwareDecodingEnabled (bool enabled) {

		if (state) state->hardwareDecodingEnabled = enabled;

	}


#elif defined(HX_LINUX) && defined(LIME_FFMPEG)


	struct VideoDecoderState {

		bool hardwareDecodingEnabled = true;
		AVFormatContext* formatContext = 0;
		AVCodecContext* videoContext = 0;
		AVCodecContext* audioContext = 0;
		AVFrame* videoFrame = 0;
		AVFrame* audioFrame = 0;
		AVPacket* packet = 0;
		SwsContext* swsContext = 0;
		SwrContext* swrContext = 0;
		std::deque<AVPacket*> videoPackets;
		std::deque<AVPacket*> audioPackets;
		std::vector<unsigned char> audioLeftover;
		size_t audioLeftoverOffset = 0;
		int videoStream = -1;
		int audioStream = -1;
		int width = 0;
		int height = 0;
		float frameRate = 0.0f;
		int durationMs = 0;
		int audioBitsPerSample = 0;
		int audioChannels = 0;
		int audioSampleRate = 0;
		int currentAudioPosition = 0;
		int currentVideoPosition = 0;
		std::mutex mutex;

	};


	static const size_t MAX_QUEUED_PACKETS = 256;


	static AVRational MillisecondsTimeBase () {

		AVRational timeBase = { 1, 1000 };
		return timeBase;

	}


	static int GetAudioChannelCount (AVCodecContext* context) {

		if (!context) return 0;

		#if LIBAVUTIL_VERSION_MAJOR >= 57
		return context->ch_layout.nb_channels;
		#else
		return context->channels;
		#endif

	}


	static void ClearPacketQueue (std::deque<AVPacket*>& queue) {

		while (!queue.empty ()) {

			AVPacket* packet = queue.front ();
			queue.pop_front ();
			if (packet) av_packet_free (&packet);

		}

	}


	static void PushPacket (std::deque<AVPacket*>& queue, AVPacket* packet) {

		if (!packet) return;

		if (queue.size () >= MAX_QUEUED_PACKETS) {

			av_packet_free (&packet);
			return;

		}

		queue.push_back (packet);

	}


	static AVPacket* PopPacket (std::deque<AVPacket*>& queue) {

		if (queue.empty ()) return 0;

		AVPacket* packet = queue.front ();
		queue.pop_front ();
		return packet;

	}


	static void ResetStreamQueues (VideoDecoderState* state) {

		if (!state) return;

		ClearPacketQueue (state->videoPackets);
		ClearPacketQueue (state->audioPackets);
		state->audioLeftover.clear ();
		state->audioLeftoverOffset = 0;

	}


	static void ReleaseDecoder (VideoDecoderState* state) {

		if (!state) return;

		ResetStreamQueues (state);

		if (state->swrContext) {

			swr_free (&state->swrContext);

		}

		if (state->swsContext) {

			sws_freeContext (state->swsContext);
			state->swsContext = 0;

		}

		if (state->videoFrame) {

			av_frame_free (&state->videoFrame);

		}

		if (state->audioFrame) {

			av_frame_free (&state->audioFrame);

		}

		if (state->packet) {

			av_packet_free (&state->packet);

		}

		if (state->videoContext) {

			avcodec_free_context (&state->videoContext);

		}

		if (state->audioContext) {

			avcodec_free_context (&state->audioContext);

		}

		if (state->formatContext) {

			avformat_close_input (&state->formatContext);

		}

		state->videoStream = -1;
		state->audioStream = -1;
		state->width = 0;
		state->height = 0;
		state->frameRate = 0.0f;
		state->durationMs = 0;
		state->audioBitsPerSample = 0;
		state->audioChannels = 0;
		state->audioSampleRate = 0;
		state->currentAudioPosition = 0;
		state->currentVideoPosition = 0;

	}


	static bool OpenCodecContext (AVFormatContext* formatContext, int streamIndex, AVCodecContext** outContext) {

		if (!formatContext || streamIndex < 0 || !outContext) return false;
		*outContext = 0;

		AVStream* stream = formatContext->streams[streamIndex];
		if (!stream || !stream->codecpar) return false;

		const AVCodec* codec = avcodec_find_decoder (stream->codecpar->codec_id);
		if (!codec) return false;

		AVCodecContext* context = avcodec_alloc_context3 (codec);
		if (!context) return false;

		if (avcodec_parameters_to_context (context, stream->codecpar) < 0) {

			avcodec_free_context (&context);
			return false;

		}

		if (avcodec_open2 (context, codec, 0) < 0) {

			avcodec_free_context (&context);
			return false;

		}

		*outContext = context;
		return true;

	}


	static AVPacket* ReadPacketForStream (VideoDecoderState* state, int streamIndex) {

		if (!state || !state->formatContext || streamIndex < 0) return 0;

		if (streamIndex == state->videoStream) {

			AVPacket* packet = PopPacket (state->videoPackets);
			if (packet) return packet;

		} else if (streamIndex == state->audioStream) {

			AVPacket* packet = PopPacket (state->audioPackets);
			if (packet) return packet;

		}

		while (av_read_frame (state->formatContext, state->packet) >= 0) {

			AVPacket* packet = av_packet_clone (state->packet);
			int packetStream = state->packet->stream_index;
			av_packet_unref (state->packet);

			if (!packet) return 0;
			if (packetStream == streamIndex) return packet;

			if (packetStream == state->videoStream) {

				PushPacket (state->videoPackets, packet);

			} else if (packetStream == state->audioStream) {

				PushPacket (state->audioPackets, packet);

			} else {

				av_packet_free (&packet);

			}

		}

		return 0;

	}


	static bool DecodeFrameForStream (VideoDecoderState* state, int streamIndex, AVCodecContext* context, AVFrame* frame) {

		if (!state || !context || !frame) return false;

		while (true) {

			int receiveResult = avcodec_receive_frame (context, frame);
			if (receiveResult == 0) return true;
			if (receiveResult == AVERROR_EOF) return false;
			if (receiveResult != AVERROR (EAGAIN)) return false;

			AVPacket* packet = ReadPacketForStream (state, streamIndex);
			int sendResult = packet ? avcodec_send_packet (context, packet) : avcodec_send_packet (context, 0);
			if (packet) av_packet_free (&packet);

			if (sendResult == AVERROR_EOF) return false;
			if (sendResult < 0 && sendResult != AVERROR (EAGAIN)) return false;

		}

	}


	static bool EnsureSwrContext (VideoDecoderState* state) {

		if (!state || !state->audioContext || state->audioChannels <= 0 || state->audioSampleRate <= 0) return false;
		if (state->swrContext) return true;

		#if LIBAVUTIL_VERSION_MAJOR >= 57
		AVChannelLayout outputLayout;
		AVChannelLayout fallbackInputLayout;
		const AVChannelLayout* inputLayout = &state->audioContext->ch_layout;
		bool hasFallbackInputLayout = false;

		av_channel_layout_default (&outputLayout, state->audioChannels);

		if (!inputLayout || inputLayout->nb_channels <= 0) {

			av_channel_layout_default (&fallbackInputLayout, state->audioChannels);
			inputLayout = &fallbackInputLayout;
			hasFallbackInputLayout = true;

		}

		int result = swr_alloc_set_opts2 (&state->swrContext, &outputLayout, AV_SAMPLE_FMT_S16, state->audioSampleRate,
			inputLayout, state->audioContext->sample_fmt, state->audioContext->sample_rate, 0, 0);

		if (hasFallbackInputLayout) av_channel_layout_uninit (&fallbackInputLayout);
		av_channel_layout_uninit (&outputLayout);

		if (result < 0 || !state->swrContext) return false;
		#else
		int64_t inputLayout = state->audioContext->channel_layout;
		if (!inputLayout) inputLayout = av_get_default_channel_layout (state->audioChannels);

		int64_t outputLayout = av_get_default_channel_layout (state->audioChannels);
		state->swrContext = swr_alloc_set_opts (0, outputLayout, AV_SAMPLE_FMT_S16, state->audioSampleRate,
			inputLayout, state->audioContext->sample_fmt, state->audioContext->sample_rate, 0, 0);

		if (!state->swrContext) return false;
		#endif

		return swr_init (state->swrContext) >= 0;

	}


	static int FrameTimestampMs (AVFrame* frame, AVStream* stream, int fallbackMs) {

		if (!frame || !stream) return fallbackMs;

		int64_t timestamp = frame->best_effort_timestamp;
		if (timestamp == AV_NOPTS_VALUE) return fallbackMs;

		return (int)av_rescale_q (timestamp, stream->time_base, MillisecondsTimeBase ());

	}


	static void CompactAudioLeftover (VideoDecoderState* state) {

		if (!state || state->audioLeftoverOffset == 0) return;

		if (state->audioLeftoverOffset >= state->audioLeftover.size ()) {

			state->audioLeftover.clear ();
			state->audioLeftoverOffset = 0;
			return;

		}

		state->audioLeftover.erase (state->audioLeftover.begin (), state->audioLeftover.begin () + state->audioLeftoverOffset);
		state->audioLeftoverOffset = 0;

	}


	VideoDecoder::VideoDecoder () {

		state = new VideoDecoderState ();

	}


	VideoDecoder::~VideoDecoder () {

		Close ();

		if (state) {

			delete state;
			state = 0;

		}

	}


	bool VideoDecoder::IsSupported () {

		return true;

	}


	void VideoDecoder::Close () {

		if (!state) return;

		std::lock_guard<std::mutex> lock (state->mutex);
		ReleaseDecoder (state);

	}


	int VideoDecoder::GetAudioBitsPerSample () {

		return state ? state->audioBitsPerSample : 0;

	}


	int VideoDecoder::GetAudioChannelCount () {

		return state ? state->audioChannels : 0;

	}


	int VideoDecoder::GetAudioSampleRate () {

		return state ? state->audioSampleRate : 0;

	}


	int VideoDecoder::GetDuration () {

		return state ? state->durationMs : 0;

	}


	float VideoDecoder::GetFrameRate () {

		return state ? state->frameRate : 0.0f;

	}


	int VideoDecoder::GetHeight () {

		return state ? state->height : 0;

	}


	int VideoDecoder::GetVideoPosition () {

		return state ? state->currentVideoPosition : 0;

	}


	int VideoDecoder::GetWidth () {

		return state ? state->width : 0;

	}


	bool VideoDecoder::Load (const char* path) {

		if (!state || !path || !*path) return false;

		std::lock_guard<std::mutex> lock (state->mutex);
		ReleaseDecoder (state);

		state->formatContext = avformat_alloc_context ();
		if (!state->formatContext) return false;

		if (avformat_open_input (&state->formatContext, path, 0, 0) < 0) {

			ReleaseDecoder (state);
			return false;

		}

		if (avformat_find_stream_info (state->formatContext, 0) < 0) {

			ReleaseDecoder (state);
			return false;

		}

		state->videoStream = av_find_best_stream (state->formatContext, AVMEDIA_TYPE_VIDEO, -1, -1, 0, 0);
		if (state->videoStream < 0 || !OpenCodecContext (state->formatContext, state->videoStream, &state->videoContext)) {

			ReleaseDecoder (state);
			return false;

		}

		AVStream* videoStream = state->formatContext->streams[state->videoStream];
		state->width = state->videoContext->width;
		state->height = state->videoContext->height;

		AVRational frameRate = videoStream->avg_frame_rate.num > 0 ? videoStream->avg_frame_rate : videoStream->r_frame_rate;
		state->frameRate = frameRate.num > 0 && frameRate.den > 0 ? (float)av_q2d (frameRate) : 0.0f;

		if (state->formatContext->duration != AV_NOPTS_VALUE) {

			state->durationMs = (int)(state->formatContext->duration / (AV_TIME_BASE / 1000));

		} else if (videoStream->duration != AV_NOPTS_VALUE) {

			state->durationMs = (int)av_rescale_q (videoStream->duration, videoStream->time_base, MillisecondsTimeBase ());

		}

		state->audioStream = av_find_best_stream (state->formatContext, AVMEDIA_TYPE_AUDIO, -1, state->videoStream, 0, 0);

		if (state->audioStream >= 0 && OpenCodecContext (state->formatContext, state->audioStream, &state->audioContext)) {

			state->audioSampleRate = state->audioContext->sample_rate;
			state->audioChannels = GetAudioChannelCount (state->audioContext);
			state->audioBitsPerSample = state->audioChannels > 0 && state->audioSampleRate > 0 ? 16 : 0;

		} else {

			state->audioStream = -1;
			state->audioSampleRate = 0;
			state->audioChannels = 0;
			state->audioBitsPerSample = 0;

		}

		state->videoFrame = av_frame_alloc ();
		state->audioFrame = av_frame_alloc ();
		state->packet = av_packet_alloc ();

		if (!state->videoFrame || !state->packet || (state->audioStream >= 0 && !state->audioFrame)) {

			ReleaseDecoder (state);
			return false;

		}

		return state->width > 0 && state->height > 0;

	}


	int VideoDecoder::ReadAudio (unsigned char* outBuffer, int bytesLength) {

		if (!state || !outBuffer || bytesLength <= 0 || state->audioStream < 0 || !state->audioContext) return -1;

		std::lock_guard<std::mutex> lock (state->mutex);
		if (!EnsureSwrContext (state)) return -1;

		int bytesWritten = 0;

		while (bytesWritten < bytesLength) {

			if (state->audioLeftoverOffset < state->audioLeftover.size ()) {

				int available = (int)(state->audioLeftover.size () - state->audioLeftoverOffset);
				int copyLength = std::min (available, bytesLength - bytesWritten);
				memcpy (outBuffer + bytesWritten, state->audioLeftover.data () + state->audioLeftoverOffset, copyLength);
				state->audioLeftoverOffset += copyLength;
				bytesWritten += copyLength;
				CompactAudioLeftover (state);
				continue;

			}

			av_frame_unref (state->audioFrame);
			if (!DecodeFrameForStream (state, state->audioStream, state->audioContext, state->audioFrame)) break;

			int outputSamples = (int)av_rescale_rnd (swr_get_delay (state->swrContext, state->audioContext->sample_rate) +
				state->audioFrame->nb_samples, state->audioSampleRate, state->audioContext->sample_rate, AV_ROUND_UP);

			if (outputSamples <= 0) continue;

			int maxOutputBytes = outputSamples * state->audioChannels * 2;
			std::vector<unsigned char> converted (maxOutputBytes);
			uint8_t* outputData[1] = { converted.data () };

			int convertedSamples = swr_convert (state->swrContext, outputData, outputSamples,
				(const uint8_t**)state->audioFrame->extended_data, state->audioFrame->nb_samples);

			if (convertedSamples <= 0) continue;

			int convertedBytes = convertedSamples * state->audioChannels * 2;
			int copyLength = std::min (convertedBytes, bytesLength - bytesWritten);
			memcpy (outBuffer + bytesWritten, converted.data (), copyLength);
			bytesWritten += copyLength;

			if (copyLength < convertedBytes) {

				state->audioLeftover.assign (converted.begin () + copyLength, converted.begin () + convertedBytes);
				state->audioLeftoverOffset = 0;

			}

			AVStream* audioStream = state->formatContext->streams[state->audioStream];
			state->currentAudioPosition = FrameTimestampMs (state->audioFrame, audioStream, state->currentAudioPosition);

		}

		return bytesWritten > 0 ? bytesWritten : -1;

	}


	bool VideoDecoder::ReadRGBAFrame (unsigned char* outBuffer, int bufferSize) {

		if (!state || !outBuffer || state->videoStream < 0 || !state->videoContext || state->width <= 0 || state->height <= 0) return false;

		std::lock_guard<std::mutex> lock (state->mutex);

		int requiredSize = state->width * state->height * 4;
		if (bufferSize < requiredSize) return false;

		av_frame_unref (state->videoFrame);
		if (!DecodeFrameForStream (state, state->videoStream, state->videoContext, state->videoFrame)) return false;

		state->swsContext = sws_getCachedContext (state->swsContext, state->videoFrame->width, state->videoFrame->height,
			(AVPixelFormat)state->videoFrame->format, state->width, state->height, AV_PIX_FMT_RGBA, SWS_BILINEAR, 0, 0, 0);

		if (!state->swsContext) return false;

		uint8_t* outputData[4] = { outBuffer, 0, 0, 0 };
		int outputStride[4] = { state->width * 4, 0, 0, 0 };

		int scaledRows = sws_scale (state->swsContext, state->videoFrame->data, state->videoFrame->linesize, 0,
			state->videoFrame->height, outputData, outputStride);

		if (scaledRows <= 0) return false;

		AVStream* videoStream = state->formatContext->streams[state->videoStream];
		state->currentVideoPosition = FrameTimestampMs (state->videoFrame, videoStream, state->currentVideoPosition);
		return true;

	}


	void VideoDecoder::Seek (int targetMs) {

		if (!state || !state->formatContext) return;

		std::lock_guard<std::mutex> lock (state->mutex);

		if (targetMs < 0) targetMs = 0;
		int64_t targetTimestamp = (int64_t)targetMs * (AV_TIME_BASE / 1000);

		if (av_seek_frame (state->formatContext, -1, targetTimestamp, AVSEEK_FLAG_BACKWARD) < 0) return;

		if (state->videoContext) avcodec_flush_buffers (state->videoContext);
		if (state->audioContext) avcodec_flush_buffers (state->audioContext);

		ResetStreamQueues (state);
		state->currentVideoPosition = targetMs;
		state->currentAudioPosition = targetMs;

	}


	void VideoDecoder::SetHardwareDecodingEnabled (bool enabled) {

		if (state) state->hardwareDecodingEnabled = enabled;

	}


#else


	struct VideoDecoderState {};


	VideoDecoder::VideoDecoder () {

		state = 0;

	}


	VideoDecoder::~VideoDecoder () {}
	bool VideoDecoder::IsSupported () { return false; }
	void VideoDecoder::Close () {}
	int VideoDecoder::GetAudioBitsPerSample () { return 0; }
	int VideoDecoder::GetAudioChannelCount () { return 0; }
	int VideoDecoder::GetAudioSampleRate () { return 0; }
	int VideoDecoder::GetDuration () { return 0; }
	float VideoDecoder::GetFrameRate () { return 0.0f; }
	int VideoDecoder::GetHeight () { return 0; }
	int VideoDecoder::GetVideoPosition () { return 0; }
	int VideoDecoder::GetWidth () { return 0; }
	bool VideoDecoder::Load (const char* path) { return false; }
	int VideoDecoder::ReadAudio (unsigned char* outBuffer, int bytesLength) { return -1; }
	bool VideoDecoder::ReadRGBAFrame (unsigned char* outBuffer, int bufferSize) { return false; }
	void VideoDecoder::Seek (int targetMs) {}
	void VideoDecoder::SetHardwareDecodingEnabled (bool enabled) {}


#endif


}
