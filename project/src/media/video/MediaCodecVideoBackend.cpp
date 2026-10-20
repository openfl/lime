#include <media/VideoDecoder.h>


#ifdef LIME_VIDEO_MEDIACODEC

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <media/NdkImage.h>
#include <media/NdkImageReader.h>
#include <media/NdkMediaCodec.h>
#include <media/NdkMediaExtractor.h>
#include <media/NdkMediaFormat.h>
#include <algorithm>
#include <chrono>
#include <dlfcn.h>
#include <fcntl.h>
#include <math.h>
#include <memory>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <sys/stat.h>
#include <sys/system_properties.h>
#include <unistd.h>

#ifndef LIME_VIDEO_STANDALONE
#include <jni.h>
#include <SDL.h>
#include <system/System.h>
#endif

#ifndef EGL_NATIVE_BUFFER_ANDROID
#define EGL_NATIVE_BUFFER_ANDROID 0x3140
#endif
#ifndef EGL_SYNC_NATIVE_FENCE_ANDROID
#define EGL_SYNC_NATIVE_FENCE_ANDROID 0x3144
#endif
#ifndef GL_PIXEL_UNPACK_BUFFER
#define GL_PIXEL_UNPACK_BUFFER 0x88EC
#endif
#ifndef GL_PIXEL_UNPACK_BUFFER_BINDING
#define GL_PIXEL_UNPACK_BUFFER_BINDING 0x88EF
#endif
#ifndef GL_RASTERIZER_DISCARD
#define GL_RASTERIZER_DISCARD 0x8C89
#endif
#ifndef GL_TEXTURE_BINDING_EXTERNAL_OES
#define GL_TEXTURE_BINDING_EXTERNAL_OES 0x8D67
#endif
#ifndef GL_TEXTURE_EXTERNAL_OES
#define GL_TEXTURE_EXTERNAL_OES 0x8D65
#endif
#ifndef GL_VERTEX_ARRAY_BINDING
#define GL_VERTEX_ARRAY_BINDING 0x85B5
#endif


struct AHardwareBuffer;
struct AMediaDataSource;


namespace lime {


	// AHardwareBuffer_Desc, which older NDK headers only declare from API level 26
	struct HardwareBufferDesc {

		uint32_t width;
		uint32_t height;
		uint32_t layers;
		uint32_t format;
		uint64_t usage;
		uint32_t stride;
		uint32_t rfu0;
		uint64_t rfu1;

	};


	// AImageReader_ImageListener, which older NDK headers only declare from
	// API level 24
	struct ImageListener {

		void* context;
		void (*onImageAvailable) (void* context, AImageReader* reader);

	};


	// The NDK media library is loaded at runtime, so Lime does not link it.
	// The image functions are newer than the rest, and only texture output
	// needs them.
	struct MediaNDK {

		int (*AHardwareBuffer_describe) (const AHardwareBuffer*, HardwareBufferDesc*);
		void (*AImage_delete) (AImage*);
		void (*AImage_deleteAsync) (AImage*, int);
		media_status_t (*AImage_getCropRect) (const AImage*, AImageCropRect*);
		media_status_t (*AImage_getHardwareBuffer) (const AImage*, AHardwareBuffer**);
		media_status_t (*AImage_getTimestamp) (const AImage*, int64_t*);
		media_status_t (*AImageReader_acquireNextImage) (AImageReader*, AImage**);
		void (*AImageReader_delete) (AImageReader*);
		media_status_t (*AImageReader_getWindow) (AImageReader*, ANativeWindow**);
		media_status_t (*AImageReader_newWithUsage) (int32_t, int32_t, int32_t, uint64_t, int32_t, AImageReader**);
		media_status_t (*AImageReader_setImageListener) (AImageReader*, ImageListener*);
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
		media_status_t (*AMediaExtractor_setDataSourceCustom) (AMediaExtractor*, AMediaDataSource*);
		media_status_t (*AMediaExtractor_setDataSourceFd) (AMediaExtractor*, int, off64_t, off64_t);
		void (*AMediaDataSource_close) (AMediaDataSource*);
		void (*AMediaDataSource_delete) (AMediaDataSource*);
		AMediaDataSource* (*AMediaDataSource_newUri) (const char*, int, const char* const*);
		media_status_t (*AMediaFormat_delete) (AMediaFormat*);
		bool (*AMediaFormat_getBuffer) (AMediaFormat*, const char*, void**, size_t*);
		bool (*AMediaFormat_getFloat) (AMediaFormat*, const char*, float*);
		bool (*AMediaFormat_getInt32) (AMediaFormat*, const char*, int32_t*);
		bool (*AMediaFormat_getInt64) (AMediaFormat*, const char*, int64_t*);
		bool (*AMediaFormat_getRect) (AMediaFormat*, const char*, int32_t*, int32_t*, int32_t*, int32_t*);
		bool (*AMediaFormat_getString) (AMediaFormat*, const char*, const char**);
		void (*AMediaFormat_setInt32) (AMediaFormat*, const char*, int32_t);

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


	// The GL state that LockTexture changes and restores, since OpenFL caches
	// GL state
	struct SavedGLState {

		GLint activeTexture;
		GLint arrayBuffer;
		GLint attribBuffer;
		GLint attribEnabled;
		GLint attribNormalized;
		void* attribPointer;
		GLint attribSize;
		GLint attribStride;
		GLint attribType;
		GLboolean blend;
		GLboolean colorMask[4];
		GLboolean cullFace;
		GLboolean depthTest;
		GLint externalTexture;
		GLint framebuffer;
		GLint program;
		GLboolean rasterizerDiscard;
		GLboolean scissorTest;
		GLboolean stencilTest;
		GLint texture;
		GLint unpackBuffer;
		GLint vertexArray;
		GLint viewport[4];

	};


	struct SoftwareDecoder {

		const char* mime;
		const char* codec2;
		const char* omx;

	};


	class MediaCodecTextureFrame : public VideoTextureFrame {


		public:

			int cropX;
			int cropY;
			int fence;
			AImage* image;


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
		COLOR_TRANSFER_SDR_VIDEO = 3,
		COLOR_TRANSFER_ST2084 = 6,
		COLOR_TRANSFER_HLG = 7,
		MEDIA_IMAGE_SIZE = 80,
		MEDIA_IMAGE_TYPE_YUV = 1,
		MEDIA_IMAGE2_SIZE = 104,
		PCM_ENCODING_16BIT = 2,
		PCM_ENCODING_8BIT = 3,
		PCM_ENCODING_FLOAT = 4,
		PCM_ENCODING_24BIT_PACKED = 21,
		PCM_ENCODING_32BIT = 22

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

	// AIMAGE_FORMAT_PRIVATE and AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE
	static const int32_t IMAGE_FORMAT_PRIVATE = 0x22;
	static const uint64_t IMAGE_USAGE_GPU_SAMPLED = 1ULL << 8;

	// Texture output keeps decoded frames in an image reader, which holds
	// enough for the decoder's queue, the frame on screen and one being read
	static const int OUTPUT_IMAGES = 8;

	// Decoding gives up after about 3 seconds without progress
	static const int MAX_IDLE_WAITS = 300;
	static const int64_t OUTPUT_TIMEOUT_US = 10000;

	// Buffer indices are small, so a larger one is an error code, such as the
	// system reclaiming the codec for another app
	static const ssize_t MAX_BUFFER_INDEX = 1000;

	// A codec that fails is replaced this many times in a row, such as when
	// the system reclaims it while the app is in the background
	static const int MAX_CODEC_RESTARTS = 3;

	// How long a seek waits for reads in progress before giving up on them, as
	// reads from a source that is still sending finish well within it
	static const int SEEK_WAIT_MS = 250;

	// How long decoding waits at a time for a connection being made again
	static const int CONNECT_WAIT_MS = 50;

	static const char* COPY_FRAGMENT_SHADER =
		"#extension GL_OES_EGL_image_external : require\n"
		"#ifdef GL_FRAGMENT_PRECISION_HIGH\n"
		"precision highp float;\n"
		"#else\n"
		"precision mediump float;\n"
		"#endif\n"
		"uniform samplerExternalOES image;\n"
		"varying vec2 coord;\n"
		"void main () { gl_FragColor = texture2D (image, coord); }\n";

	// The crop is the offset and size of the picture in the buffer, in texture
	// coordinates. Row 0 of the copy samples the buffer's first row, the top.
	static const char* COPY_VERTEX_SHADER =
		"attribute vec2 position;\n"
		"uniform vec4 crop;\n"
		"varying vec2 coord;\n"
		"void main () {\n"
		"	coord = crop.xy + (position * 0.5 + 0.5) * crop.zw;\n"
		"	gl_Position = vec4 (position, 0.0, 1.0);\n"
		"}\n";

	typedef void (*GLBindVertexArrayFunc) (GLuint);
	typedef void (*GLDeleteVertexArraysFunc) (GLsizei, const GLuint*);
	typedef void (*GLEGLImageTargetTexture2DFunc) (GLenum, void*);
	typedef void (*GLGenVertexArraysFunc) (GLsizei, GLuint*);
	typedef EGLImageKHR (*EGLCreateImageFunc) (EGLDisplay, EGLContext, EGLenum, EGLClientBuffer, const EGLint*);
	typedef EGLSyncKHR (*EGLCreateSyncFunc) (EGLDisplay, EGLenum, const EGLint*);
	typedef EGLBoolean (*EGLDestroyImageFunc) (EGLDisplay, EGLImageKHR);
	typedef EGLBoolean (*EGLDestroySyncFunc) (EGLDisplay, EGLSyncKHR);
	typedef EGLint (*EGLDupNativeFenceFDFunc) (EGLDisplay, EGLSyncKHR);
	typedef EGLClientBuffer (*EGLGetNativeClientBufferFunc) (const AHardwareBuffer*);

	static GLBindVertexArrayFunc _glBindVertexArray = 0;
	static GLDeleteVertexArraysFunc _glDeleteVertexArrays = 0;
	static GLEGLImageTargetTexture2DFunc _glEGLImageTargetTexture2DOES = 0;
	static GLGenVertexArraysFunc _glGenVertexArrays = 0;
	static EGLCreateImageFunc _eglCreateImageKHR = 0;
	static EGLCreateSyncFunc _eglCreateSyncKHR = 0;
	static EGLDestroyImageFunc _eglDestroyImageKHR = 0;
	static EGLDestroySyncFunc _eglDestroySyncKHR = 0;
	static EGLDupNativeFenceFDFunc _eglDupNativeFenceFDANDROID = 0;
	static EGLGetNativeClientBufferFunc _eglGetNativeClientBufferANDROID = 0;

	static std::once_flag extensionsFlag;
	static std::once_flag loadFlag;
	static bool loaded = false;
	static MediaNDK ndk;


	static bool LoadMediaNDK () {

		std::call_once (loadFlag, [] {

			void* library = dlopen ("libmediandk.so", RTLD_NOW | RTLD_LOCAL);
			if (!library) return;

			#define LIME_MEDIANDK_REQUIRE(name) ndk.name = (decltype (ndk.name))dlsym (library, #name); if (!ndk.name) return;
			#define LIME_MEDIANDK_OPTIONAL(library, name) ndk.name = (decltype (ndk.name))dlsym (library, #name);

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

			// API level 24 to 28
			LIME_MEDIANDK_OPTIONAL (library, AImage_delete);
			LIME_MEDIANDK_OPTIONAL (library, AImage_deleteAsync);
			LIME_MEDIANDK_OPTIONAL (library, AImage_getCropRect);
			LIME_MEDIANDK_OPTIONAL (library, AImage_getHardwareBuffer);
			LIME_MEDIANDK_OPTIONAL (library, AImage_getTimestamp);
			LIME_MEDIANDK_OPTIONAL (library, AImageReader_acquireNextImage);
			LIME_MEDIANDK_OPTIONAL (library, AImageReader_delete);
			LIME_MEDIANDK_OPTIONAL (library, AImageReader_getWindow);
			LIME_MEDIANDK_OPTIONAL (library, AImageReader_newWithUsage);
			LIME_MEDIANDK_OPTIONAL (library, AImageReader_setImageListener);
			LIME_MEDIANDK_OPTIONAL (library, AMediaFormat_getRect);
			LIME_MEDIANDK_OPTIONAL (library, AMediaFormat_setInt32);

			// API level 28 and 29
			LIME_MEDIANDK_OPTIONAL (library, AMediaDataSource_close);
			LIME_MEDIANDK_OPTIONAL (library, AMediaDataSource_delete);
			LIME_MEDIANDK_OPTIONAL (library, AMediaDataSource_newUri);
			LIME_MEDIANDK_OPTIONAL (library, AMediaExtractor_setDataSourceCustom);

			void* android = dlopen ("libandroid.so", RTLD_NOW | RTLD_LOCAL);
			if (android) LIME_MEDIANDK_OPTIONAL (android, AHardwareBuffer_describe);

			#undef LIME_MEDIANDK_REQUIRE
			#undef LIME_MEDIANDK_OPTIONAL

			loaded = true;

		});

		return loaded;

	}


	static bool CanUseImageReader () {

		return ndk.AHardwareBuffer_describe && ndk.AImage_delete && ndk.AImage_deleteAsync && ndk.AImage_getCropRect && ndk.AImage_getHardwareBuffer && ndk.AImage_getTimestamp
			&& ndk.AImageReader_acquireNextImage && ndk.AImageReader_delete && ndk.AImageReader_getWindow && ndk.AImageReader_newWithUsage && ndk.AImageReader_setImageListener;

	}


	static GLuint CompileShader (GLenum type, const char* source) {

		GLuint shader = glCreateShader (type);
		glShaderSource (shader, 1, &source, NULL);
		glCompileShader (shader);

		GLint compiled = 0;
		glGetShaderiv (shader, GL_COMPILE_STATUS, &compiled);

		if (!compiled) {

			glDeleteShader (shader);
			return 0;

		}

		return shader;

	}


	static void ConvertSamples (const uint8_t* data, size_t count, int encoding, std::vector<short>* out) {

		// Decoders that cannot give 16-bit samples give these instead
		out->resize (count);
		short* samples = out->data ();

		for (size_t i = 0; i < count; i++) {

			switch (encoding) {

				case PCM_ENCODING_FLOAT: {

					float value;
					memcpy (&value, data + i * 4, 4);
					value *= 32768.0f;
					samples[i] = value >= 32767.0f ? 32767 : (value <= -32768.0f ? -32768 : (short)value);
					break;

				}

				case PCM_ENCODING_8BIT: samples[i] = (short)((data[i] - 128) << 8); break;
				case PCM_ENCODING_24BIT_PACKED: samples[i] = (short)(data[i * 3 + 1] | (data[i * 3 + 2] << 8)); break;

				case PCM_ENCODING_32BIT: {

					int32_t value;
					memcpy (&value, data + i * 4, 4);
					samples[i] = (short)(value >> 16);
					break;

				}

				default: samples[i] = 0; break;

			}

		}

	}


	static int GetSampleBytes (int encoding) {

		switch (encoding) {

			case PCM_ENCODING_16BIT: return 2;
			case PCM_ENCODING_8BIT: return 1;
			case PCM_ENCODING_24BIT_PACKED: return 3;
			case PCM_ENCODING_FLOAT: case PCM_ENCODING_32BIT: return 4;
			default: return 0;

		}

	}


	#ifndef LIME_VIDEO_STANDALONE
	static int OpenContentURI (const char* uri) {

		// A content URI, as file pickers and the media store give, is opened
		// through the content resolver, which hands out a file descriptor
		JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv ();
		jobject activity = env ? (jobject)SDL_AndroidGetActivity () : NULL;
		if (!activity) return -1;

		int fd = -1;

		if (env->PushLocalFrame (16) == 0) {

			jclass contextClass = env->GetObjectClass (activity);
			jmethodID getContentResolver = env->GetMethodID (contextClass, "getContentResolver", "()Landroid/content/ContentResolver;");
			jobject resolver = getContentResolver ? env->CallObjectMethod (activity, getContentResolver) : NULL;
			jclass uriClass = env->FindClass ("android/net/Uri");
			jmethodID parse = uriClass ? env->GetStaticMethodID (uriClass, "parse", "(Ljava/lang/String;)Landroid/net/Uri;") : NULL;
			jobject uriObject = parse ? env->CallStaticObjectMethod (uriClass, parse, env->NewStringUTF (uri)) : NULL;

			if (env->ExceptionCheck ()) {

				env->ExceptionClear ();
				resolver = NULL;

			}

			if (resolver && uriObject) {

				jmethodID openFileDescriptor = env->GetMethodID (env->GetObjectClass (resolver), "openFileDescriptor", "(Landroid/net/Uri;Ljava/lang/String;)Landroid/os/ParcelFileDescriptor;");
				jobject descriptor = openFileDescriptor ? env->CallObjectMethod (resolver, openFileDescriptor, uriObject, env->NewStringUTF ("r")) : NULL;

				if (env->ExceptionCheck ()) {

					// Such as a URI that does not exist or is not permitted
					env->ExceptionClear ();
					descriptor = NULL;

				}

				if (descriptor) {

					jclass descriptorClass = env->GetObjectClass (descriptor);
					jmethodID detachFd = env->GetMethodID (descriptorClass, "detachFd", "()I");
					jmethodID close = env->GetMethodID (descriptorClass, "close", "()V");

					if (detachFd) fd = env->CallIntMethod (descriptor, detachFd);
					if (env->ExceptionCheck ()) { env->ExceptionClear (); fd = -1; }
					if (close) env->CallVoidMethod (descriptor, close);
					if (env->ExceptionCheck ()) env->ExceptionClear ();

				}

			}

			if (env->ExceptionCheck ()) env->ExceptionClear ();
			env->PopLocalFrame (NULL);

		}

		env->DeleteLocalRef (activity);
		return fd;

	}
	#endif


	static AMediaCodec* CreateDecoder (AMediaFormat* format, bool hardware, ANativeWindow* surface) {

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

			if (ndk.AMediaCodec_configure (codec, format, surface, NULL, 0) == AMEDIA_OK && ndk.AMediaCodec_start (codec) == AMEDIA_OK) {

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


	static bool HasExtension (const char* extensions, const char* name) {

		if (!extensions) return false;

		size_t length = strlen (name);
		const char* found = extensions;

		while ((found = strstr (found, name)) != NULL) {

			if ((found == extensions || found[-1] == ' ') && (found[length] == ' ' || found[length] == '\0')) return true;
			found += length;

		}

		return false;

	}


	static bool LoadEGLExtensions () {

		std::call_once (extensionsFlag, [] {

			_eglCreateImageKHR = (EGLCreateImageFunc)eglGetProcAddress ("eglCreateImageKHR");
			_eglCreateSyncKHR = (EGLCreateSyncFunc)eglGetProcAddress ("eglCreateSyncKHR");
			_eglDestroyImageKHR = (EGLDestroyImageFunc)eglGetProcAddress ("eglDestroyImageKHR");
			_eglDestroySyncKHR = (EGLDestroySyncFunc)eglGetProcAddress ("eglDestroySyncKHR");
			_eglDupNativeFenceFDANDROID = (EGLDupNativeFenceFDFunc)eglGetProcAddress ("eglDupNativeFenceFDANDROID");
			_eglGetNativeClientBufferANDROID = (EGLGetNativeClientBufferFunc)eglGetProcAddress ("eglGetNativeClientBufferANDROID");
			_glBindVertexArray = (GLBindVertexArrayFunc)eglGetProcAddress ("glBindVertexArray");
			_glDeleteVertexArrays = (GLDeleteVertexArraysFunc)eglGetProcAddress ("glDeleteVertexArrays");
			_glEGLImageTargetTexture2DOES = (GLEGLImageTargetTexture2DFunc)eglGetProcAddress ("glEGLImageTargetTexture2DOES");
			_glGenVertexArrays = (GLGenVertexArraysFunc)eglGetProcAddress ("glGenVertexArrays");

		});

		return _eglCreateImageKHR && _eglDestroyImageKHR && _eglGetNativeClientBufferANDROID && _glEGLImageTargetTexture2DOES;

	}


	// GL objects of a backend closed away from the GL thread, deleted the next
	// time a decoder reads a texture frame where their context is current
	struct MediaCodecOrphan {

		EGLContext context;
		GLuint copyBuffer;
		GLuint copyFramebuffer;
		GLuint copyProgram;
		GLuint copyTexture;
		GLuint copyVertexArray;
		GLuint imageTexture;

	};

	// Never destroyed, as exiting runs static destructors while threads can
	// still be closing videos
	static std::mutex* orphanMutex = new std::mutex ();
	static std::vector<MediaCodecOrphan>* orphans = new std::vector<MediaCodecOrphan> ();


	static void RestoreGLState (const SavedGLState* state, bool gles3) {

		glBindFramebuffer (GL_FRAMEBUFFER, state->framebuffer);
		glUseProgram (state->program);
		glViewport (state->viewport[0], state->viewport[1], state->viewport[2], state->viewport[3]);
		glColorMask (state->colorMask[0], state->colorMask[1], state->colorMask[2], state->colorMask[3]);

		if (state->blend) glEnable (GL_BLEND);
		if (state->cullFace) glEnable (GL_CULL_FACE);
		if (state->depthTest) glEnable (GL_DEPTH_TEST);
		if (state->scissorTest) glEnable (GL_SCISSOR_TEST);
		if (state->stencilTest) glEnable (GL_STENCIL_TEST);

		glActiveTexture (GL_TEXTURE0);
		glBindTexture (GL_TEXTURE_2D, state->texture);
		glBindTexture (GL_TEXTURE_EXTERNAL_OES, state->externalTexture);
		glActiveTexture (state->activeTexture);

		if (gles3) {

			if (state->rasterizerDiscard) glEnable (GL_RASTERIZER_DISCARD);
			glBindBuffer (GL_PIXEL_UNPACK_BUFFER, state->unpackBuffer);
			_glBindVertexArray (state->vertexArray);

		} else {

			glBindBuffer (GL_ARRAY_BUFFER, state->attribBuffer);
			glVertexAttribPointer (0, state->attribSize, state->attribType, state->attribNormalized, state->attribStride, state->attribPointer);

			if (state->attribEnabled) {

				glEnableVertexAttribArray (0);

			} else {

				glDisableVertexAttribArray (0);

			}

		}

		glBindBuffer (GL_ARRAY_BUFFER, state->arrayBuffer);

	}


	static void SaveGLState (SavedGLState* state, bool gles3) {

		glGetIntegerv (GL_ACTIVE_TEXTURE, &state->activeTexture);
		glGetIntegerv (GL_ARRAY_BUFFER_BINDING, &state->arrayBuffer);
		glGetIntegerv (GL_CURRENT_PROGRAM, &state->program);
		glGetIntegerv (GL_FRAMEBUFFER_BINDING, &state->framebuffer);
		glGetIntegerv (GL_VIEWPORT, state->viewport);
		glGetBooleanv (GL_COLOR_WRITEMASK, state->colorMask);
		state->blend = glIsEnabled (GL_BLEND);
		state->cullFace = glIsEnabled (GL_CULL_FACE);
		state->depthTest = glIsEnabled (GL_DEPTH_TEST);
		state->scissorTest = glIsEnabled (GL_SCISSOR_TEST);
		state->stencilTest = glIsEnabled (GL_STENCIL_TEST);

		glActiveTexture (GL_TEXTURE0);
		glGetIntegerv (GL_TEXTURE_BINDING_2D, &state->texture);
		glGetIntegerv (GL_TEXTURE_BINDING_EXTERNAL_OES, &state->externalTexture);

		if (gles3) {

			// The copy draws with its own vertex array, so the application's
			// vertex attributes are left alone
			glGetIntegerv (GL_PIXEL_UNPACK_BUFFER_BINDING, &state->unpackBuffer);
			glGetIntegerv (GL_VERTEX_ARRAY_BINDING, &state->vertexArray);
			state->rasterizerDiscard = glIsEnabled (GL_RASTERIZER_DISCARD);

		} else {

			glGetVertexAttribiv (0, GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, &state->attribBuffer);
			glGetVertexAttribiv (0, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &state->attribEnabled);
			glGetVertexAttribiv (0, GL_VERTEX_ATTRIB_ARRAY_NORMALIZED, &state->attribNormalized);
			glGetVertexAttribiv (0, GL_VERTEX_ATTRIB_ARRAY_SIZE, &state->attribSize);
			glGetVertexAttribiv (0, GL_VERTEX_ATTRIB_ARRAY_STRIDE, &state->attribStride);
			glGetVertexAttribiv (0, GL_VERTEX_ATTRIB_ARRAY_TYPE, &state->attribType);
			glGetVertexAttribPointerv (0, GL_VERTEX_ATTRIB_ARRAY_POINTER, &state->attribPointer);

		}

	}


	static int GetSystemVersion () {

		// The API level, which the NDK only gives from Android 10
		static int version = -1;

		if (version < 0) {

			char value[PROP_VALUE_MAX] = {};
			version = __system_property_get ("ro.build.version.sdk", value) > 0 ? atoi (value) : 0;

		}

		return version;

	}


	static AMediaFormat* SelectTrack (AMediaExtractor* extractor, const char* type, size_t* track) {

		size_t count = ndk.AMediaExtractor_getTrackCount (extractor);

		for (size_t i = 0; i < count; i++) {

			AMediaFormat* format = ndk.AMediaExtractor_getTrackFormat (extractor, i);
			if (!format) continue;

			const char* mime = NULL;

			if (ndk.AMediaFormat_getString (format, "mime", &mime) && mime && strncmp (mime, type, strlen (type)) == 0) {

				*track = i;
				if (ndk.AMediaExtractor_selectTrack (extractor, i) == AMEDIA_OK) return format;

				ndk.AMediaFormat_delete (format);
				return NULL;

			}

			ndk.AMediaFormat_delete (format);

		}

		return NULL;

	}


	// Whether a seek waits for the streams, and which of them are reading,
	// under the mutex, so a read does not start while a seek waits
	struct MediaCodecReads {

		MediaCodecReads () : seeking (false) {}

		std::condition_variable condition;
		std::mutex mutex;
		std::atomic<bool> seeking;

	};


	// Connecting to a server, which Android cannot cancel, so it happens on a
	// thread of its own that seeking and closing can leave behind
	struct MediaCodecConnection {

		MediaCodecConnection () : abandoned (false), dataSource (NULL), done (false) {}

		bool abandoned;
		std::condition_variable condition;
		AMediaDataSource* dataSource;
		bool done;
		std::mutex mutex;

	};


	static std::shared_ptr<MediaCodecConnection> Connect (const std::string& path) {

		std::shared_ptr<MediaCodecConnection> connection = std::make_shared<MediaCodecConnection> ();

		std::thread ([connection, path] {

			#ifndef LIME_VIDEO_STANDALONE
			// The data source reads through Java, so the thread joins the Java VM
			SDL_AndroidGetJNIEnv ();
			#endif

			AMediaDataSource* dataSource = ndk.AMediaDataSource_newUri (path.c_str (), 0, NULL);

			std::lock_guard<std::mutex> lock (connection->mutex);

			if (connection->abandoned && dataSource) {

				ndk.AMediaDataSource_delete (dataSource);
				dataSource = NULL;

			}

			connection->dataSource = dataSource;
			connection->done = true;
			connection->condition.notify_all ();

		}).detach ();

		return connection;

	}


	// One stream's extractor and decoder, which no other thread touches while
	// it decodes
	class MediaCodecStream {


		public:

			MediaCodecStream ();

			bool BeginRead ();
			void Close ();
			void EndRead ();
			void GiveUp ();
			bool Prime ();
			VideoDecodeResult Read (bool* formatChanged);
			void Release ();
			bool Seek (int64_t position, bool later);
			void SetDataSource (AMediaDataSource* value);

			// Reading, under the reads mutex
			bool busy;

			std::atomic<bool> cancelled;
			AMediaCodec* codec;
			std::shared_ptr<MediaCodecConnection> connection;
			AMediaDataSource* dataSource;
			bool ended;
			AMediaExtractor* extractor;
			ssize_t index;
			AMediaCodecBufferInfo info;
			bool inputEnded;
			bool inputError;
			std::atomic<bool> interrupted;
			bool pending;
			MediaCodecReads* reads;

			// Given up by a seek, so the stream connects again
			std::atomic<bool> reopen;

			// Where the extractor seeks before reading next, or -1
			int64_t seekPosition;

		private:

			bool QueueInput ();


	};


	MediaCodecStream::MediaCodecStream () {

		busy = false;
		cancelled = false;
		codec = NULL;
		dataSource = NULL;
		ended = false;
		extractor = NULL;
		index = -1;
		inputEnded = false;
		inputError = false;
		interrupted = false;
		memset (&info, 0, sizeof (info));
		pending = false;
		reads = NULL;
		reopen = false;
		seekPosition = -1;

	}


	bool MediaCodecStream::BeginRead () {

		// Reading a URL can wait on a stalled network source, which a seek gives
		// up, and reads do not start while a seek waits
		std::lock_guard<std::mutex> lock (reads->mutex);
		if (reads->seeking) return false;

		busy = true;
		cancelled = false;
		return true;

	}


	void MediaCodecStream::Close () {

		Release ();

		if (connection) {

			std::lock_guard<std::mutex> lock (connection->mutex);
			connection->abandoned = true;

			if (connection->dataSource) {

				ndk.AMediaDataSource_delete (connection->dataSource);
				connection->dataSource = NULL;

			}

		}

		connection.reset ();

		if (codec) {

			ndk.AMediaCodec_stop (codec);
			ndk.AMediaCodec_delete (codec);
			codec = NULL;

		}

		if (extractor) {

			ndk.AMediaExtractor_delete (extractor);
			extractor = NULL;

		}

		// The extractor reads from the data source until it is deleted
		SetDataSource (NULL);

		cancelled = false;
		ended = false;
		inputEnded = false;
		inputError = false;
		interrupted = false;
		reopen = false;
		seekPosition = -1;

	}


	void MediaCodecStream::EndRead () {

		std::lock_guard<std::mutex> lock (reads->mutex);
		busy = false;
		reads->condition.notify_all ();

	}


	void MediaCodecStream::GiveUp () {

		// With the reads mutex held. Closing the data source makes a read waiting
		// on a stalled network source fail, and the stream connects again.
		cancelled = true;
		reopen = true;
		if (dataSource) ndk.AMediaDataSource_close (dataSource);

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

		if (inputIndex >= MAX_BUFFER_INDEX) {

			inputError = true;
			return false;

		}

		size_t capacity = 0;
		uint8_t* buffer = ndk.AMediaCodec_getInputBuffer (codec, inputIndex, &capacity);

		// The input buffer goes back to the codec when the seek flushes it
		if (!BeginRead ()) {

			inputError = true;
			return false;

		}

		ssize_t size = buffer ? ndk.AMediaExtractor_readSampleData (extractor, buffer, capacity) : -1;
		int64_t time = ndk.AMediaExtractor_getSampleTime (extractor);
		EndRead ();

		if (cancelled || (time >= 0 && size < 0)) {

			// A sample that is there but cannot be read, such as one larger than
			// the input buffer or one lost to a network error, is not the end
			inputError = true;
			return false;

		}

		if (time < 0) {

			ndk.AMediaCodec_queueInputBuffer (codec, inputIndex, 0, 0, 0, AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM);
			inputEnded = true;

		} else {

			ndk.AMediaCodec_queueInputBuffer (codec, inputIndex, 0, size, time, 0);

			// Advancing reads the next sample
			if (BeginRead ()) {

				ndk.AMediaExtractor_advance (extractor);
				EndRead ();
				if (cancelled) inputError = true;

			} else {

				inputError = true;

			}

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
		if (!extractor) return reopen ? VIDEO_DECODE_AGAIN : VIDEO_DECODE_ERROR;

		if (seekPosition >= 0) {

			if (!BeginRead ()) return VIDEO_DECODE_AGAIN;
			media_status_t status = ndk.AMediaExtractor_seekTo (extractor, seekPosition, AMEDIAEXTRACTOR_SEEK_PREVIOUS_SYNC);
			EndRead ();

			if (cancelled) return VIDEO_DECODE_AGAIN;

			seekPosition = -1;
			if (status != AMEDIA_OK) return VIDEO_DECODE_ERROR;

		}

		int idle = 0;

		while (!interrupted) {

			bool queued = QueueInput ();

			// A seek gave up on this read, or it waits for one, and reading
			// carries on after it
			if (inputError) return cancelled || reads->seeking ? VIDEO_DECODE_AGAIN : VIDEO_DECODE_ERROR;
			if (queued) idle = 0;

			ssize_t result = ndk.AMediaCodec_dequeueOutputBuffer (codec, &info, queued ? 0 : OUTPUT_TIMEOUT_US);

			if (result >= MAX_BUFFER_INDEX) {

				return VIDEO_DECODE_ERROR;

			} else if (result >= 0) {

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

		return VIDEO_DECODE_ERROR;

	}


	void MediaCodecStream::Release () {

		if (index >= 0) {

			ndk.AMediaCodec_releaseOutputBuffer (codec, index, false);
			index = -1;

		}

		pending = false;

	}


	bool MediaCodecStream::Seek (int64_t position, bool later) {

		Release ();

		// Seeking a URL reads from the network, so the extractor seeks later,
		// on the thread that decodes, where a seek can give up on it
		bool success = true;

		if (later || !extractor) {

			seekPosition = position;

		} else {

			seekPosition = -1;
			success = (ndk.AMediaExtractor_seekTo (extractor, position, AMEDIAEXTRACTOR_SEEK_PREVIOUS_SYNC) == AMEDIA_OK);

		}

		success = (ndk.AMediaCodec_flush (codec) == AMEDIA_OK) && success;

		ended = false;
		inputEnded = false;
		inputError = false;

		return success;

	}


	void MediaCodecStream::SetDataSource (AMediaDataSource* value) {

		AMediaDataSource* previous = NULL;

		{
			// Interrupt and PrepareSeek close it from another thread
			std::lock_guard<std::mutex> lock (reads->mutex);
			previous = dataSource;
			dataSource = value;
		}

		if (previous) ndk.AMediaDataSource_delete (previous);

	}


	class MediaCodecVideoBackend : public VideoBackend {


		public:

			MediaCodecVideoBackend ();
			~MediaCodecVideoBackend ();

			virtual void Close ();
			virtual VideoDecodeResult DecodeAudio (std::vector<unsigned char>* pcm, double* time);
			virtual VideoDecodeResult DecodeVideo (VideoPlanes* planes, double* time, double* duration);
			virtual VideoDecodeResult DecodeVideoTexture (VideoTextureFrame** frame, double* time, double* duration);
			virtual void Interrupt ();
			virtual unsigned int LockTexture (VideoTextureFrame* frame);
			virtual bool Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info);
			virtual void PrepareSeek ();
			virtual void ReleaseTextureFrame (VideoTextureFrame* frame);
			virtual void ReleaseOrphans ();
			virtual void ReleaseTextures ();
			virtual bool Seek (double time);
			virtual void SetTextureOutput (bool enabled);
			virtual bool SupportsTextures ();

		private:

			AImage* AcquireImage ();
			AMediaExtractor* CreateExtractor (AMediaDataSource** dataSource);
			ANativeWindow* CreateImageReader (int width, int height);
			bool CreateTextures ();
			AMediaCodec* CreateVideoDecoder (bool hardware, bool surface);
			void ForgetTextures ();
			bool GetPlanes (VideoPlanes* planes);
			bool OpenAudio ();
			bool OpenVideo (bool hardware);
			bool ReadAudioFormat ();
			bool ReadPlaneLayout (AMediaFormat* format, int width, int height);
			bool ReadVideoFormat ();
			void ReleaseImage (AImage* image, int fence);
			VideoDecodeResult ReopenStream (MediaCodecStream* stream, size_t track);
			bool ReplaceVideoCodec (bool hardware, bool surface, int64_t position);
			bool RestartAudio ();
			bool RestartVideo ();

			static void OnImageAvailable (void* context, AImageReader* reader);

			MediaCodecStream audio;
			int audioChannels;
			VideoAudioConverter audioConverter;
			int audioEncoding;
			int64_t audioPosition;
			int audioRestarts;
			std::vector<short> audioSamples;
			int audioSampleRate;
			int64_t audioSkipTime;
			int audioSourceChannels;
			int audioSourceRate;
			int64_t audioTime;
			size_t audioTrack;
			bool audioTrackFound;
			VideoColorMatrix colorMatrix;
			VideoColorTransfer colorTransfer;
			GLuint copyBuffer;
			GLuint copyFramebuffer;
			GLuint copyProgram;
			GLuint copyTexture;
			int copyTextureHeight;
			int copyTextureWidth;
			GLuint copyVertexArray;
			GLint cropLocation;
			int cropHeight;
			int cropWidth;
			int cropX;
			int cropY;
			double duration;
			double frameRate;
			bool fullRange;
			bool hardwareActive;
			std::condition_variable imageCondition;
			std::mutex imageMutex;
			AImageReader* imageReader;
			int imageSignals;
			int imagesHeld;
			GLuint imageTexture;
			ANativeWindow* imageWindow;
			bool nativeFences;
			bool network;
			std::string path;
			double pixelAspectRatio;
			MediaCodecReads reads;
			int rotation;
			EGLContext textureContext;
			bool textureGLES3;
			std::atomic<bool> textureOutput;
			bool texturesFailed;
			size_t uOffset;
			int uvPixelStride;
			int uvStride;
			size_t vOffset;
			MediaCodecStream video;
			AMediaFormat* videoFormat;
			int64_t videoPosition;
			int videoRestarts;
			int64_t videoSkipTime;
			bool videoSurface;
			int64_t videoTime;
			size_t videoTrack;
			bool videoTrackFound;
			size_t yOffset;
			int yStride;


	};


	MediaCodecVideoBackend::MediaCodecVideoBackend () {

		audio.reads = &reads;
		video.reads = &reads;
		audioChannels = 0;
		audioEncoding = PCM_ENCODING_16BIT;
		audioPosition = 0;
		audioRestarts = 0;
		audioSampleRate = 0;
		audioSkipTime = INT64_MIN;
		audioSourceChannels = 0;
		audioSourceRate = 0;
		audioTime = INT64_MIN;
		audioTrack = 0;
		audioTrackFound = false;
		colorMatrix = VIDEO_COLOR_MATRIX_BT709;
		colorTransfer = VIDEO_COLOR_TRANSFER_SDR;
		copyBuffer = 0;
		copyFramebuffer = 0;
		copyProgram = 0;
		copyTexture = 0;
		copyTextureHeight = 0;
		copyTextureWidth = 0;
		copyVertexArray = 0;
		cropLocation = -1;
		cropHeight = 0;
		cropWidth = 0;
		cropX = 0;
		cropY = 0;
		duration = 0;
		frameRate = 0;
		fullRange = false;
		hardwareActive = false;
		imageReader = NULL;
		imageSignals = 0;
		imagesHeld = 0;
		imageTexture = 0;
		imageWindow = NULL;
		nativeFences = false;
		network = false;
		pixelAspectRatio = 0;
		rotation = 0;
		textureContext = EGL_NO_CONTEXT;
		textureGLES3 = false;
		textureOutput = false;
		texturesFailed = false;
		uOffset = 0;
		uvPixelStride = 0;
		uvStride = 0;
		vOffset = 0;
		videoFormat = NULL;
		videoPosition = 0;
		videoRestarts = 0;
		videoSkipTime = INT64_MIN;
		videoSurface = false;
		videoTime = INT64_MIN;
		videoTrack = 0;
		videoTrackFound = false;
		yOffset = 0;
		yStride = 0;

	}


	MediaCodecVideoBackend::~MediaCodecVideoBackend () {

		Close ();

	}


	AImage* MediaCodecVideoBackend::AcquireImage () {

		// Frames reach the reader one at a time, so the codec never queues more
		// than it holds, and each image is matched to its output buffer
		{
			std::unique_lock<std::mutex> lock (imageMutex);
			imageCondition.wait_for (lock, std::chrono::seconds (5), [this] { return imagesHeld < OUTPUT_IMAGES || video.interrupted; });
			if (imagesHeld >= OUTPUT_IMAGES) return NULL;
		}

		int64_t time = video.info.presentationTimeUs;
		ndk.AMediaCodec_releaseOutputBuffer (video.codec, video.index, true);
		video.index = -1;

		std::chrono::steady_clock::time_point deadline = std::chrono::steady_clock::now () + std::chrono::seconds (1);

		while (!video.interrupted) {

			int signals = 0;

			{
				std::lock_guard<std::mutex> lock (imageMutex);
				signals = imageSignals;
			}

			AImage* image = NULL;
			media_status_t status = ndk.AImageReader_acquireNextImage (imageReader, &image);

			if (status == AMEDIA_OK && image) {

				int64_t timestamp = -1;
				ndk.AImage_getTimestamp (image, &timestamp);

				if (timestamp / 1000 == time) {

					std::lock_guard<std::mutex> lock (imageMutex);
					imagesHeld++;
					return image;

				}

				// A frame rendered before a flush, or a blank one from a codec
				// that was released
				ndk.AImage_delete (image);
				continue;

			}

			if (status != AMEDIA_IMGREADER_NO_BUFFER_AVAILABLE) return NULL;

			std::unique_lock<std::mutex> lock (imageMutex);
			if (!imageCondition.wait_until (lock, deadline, [this, signals] { return imageSignals != signals || video.interrupted; })) return NULL;

		}

		return NULL;

	}


	void MediaCodecVideoBackend::Close () {

		// GL objects still held were left by closing away from the GL thread, as
		// closing there releases them first
		if (textureContext != EGL_NO_CONTEXT && (copyBuffer || copyFramebuffer || copyProgram || copyTexture || copyVertexArray || imageTexture)) {

			MediaCodecOrphan orphan = { textureContext, copyBuffer, copyFramebuffer, copyProgram, copyTexture, copyVertexArray, imageTexture };

			{
				std::lock_guard<std::mutex> lock (*orphanMutex);
				orphans->push_back (orphan);
			}

			ForgetTextures ();

		}

		video.Close ();
		audio.Close ();

		// VideoDecoder gives back every frame before closing, so no image
		// outlives the reader
		if (imageReader) {

			ndk.AImageReader_delete (imageReader);
			imageReader = NULL;
			imageWindow = NULL;

		}

		if (videoFormat) {

			ndk.AMediaFormat_delete (videoFormat);
			videoFormat = NULL;

		}

		audioChannels = 0;
		audioConverter.Reset ();
		audioPosition = 0;
		audioRestarts = 0;
		audioSampleRate = 0;
		audioSkipTime = INT64_MIN;
		audioSourceChannels = 0;
		audioSourceRate = 0;
		audioTime = INT64_MIN;
		audioTrackFound = false;
		duration = 0;
		frameRate = 0;
		hardwareActive = false;
		imagesHeld = 0;
		network = false;
		pixelAspectRatio = 0;
		reads.seeking = false;
		rotation = 0;
		texturesFailed = false;
		videoPosition = 0;
		videoRestarts = 0;
		videoSkipTime = INT64_MIN;
		videoSurface = false;
		videoTime = INT64_MIN;
		videoTrackFound = false;

	}


	AMediaExtractor* MediaCodecVideoBackend::CreateExtractor (AMediaDataSource** dataSource) {

		*dataSource = NULL;

		AMediaExtractor* extractor = ndk.AMediaExtractor_new ();
		if (!extractor) return NULL;

		media_status_t status = AMEDIA_ERROR_UNKNOWN;
		bool url = path.find ("://") != std::string::npos;

		#ifndef LIME_VIDEO_STANDALONE
		// The extractor opens URLs through Java, so a thread that opens one, such
		// as one VideoSource.loadFromFile uses, joins the Java VM, which SDL
		// does for any thread that asks for its environment
		if (url) SDL_AndroidGetJNIEnv ();
		#endif

		#ifndef LIME_VIDEO_STANDALONE
		if (path.compare (0, 10, "content://") == 0) {

			int fd = OpenContentURI (path.c_str ());

			if (fd >= 0) {

				// A provider that streams through a pipe has no length
				struct stat fileInfo;
				off64_t length = (fstat (fd, &fileInfo) == 0 && fileInfo.st_size > 0) ? fileInfo.st_size : INT64_MAX;
				status = ndk.AMediaExtractor_setDataSourceFd (extractor, fd, 0, length);
				::close (fd);

			}

		} else
		#endif
		if (url) {

			// From Android 10, a URL is read through a data source, which
			// Interrupt can close, so a stream waiting on a stalled network
			// returns rather than waiting for the connection to time out
			if (ndk.AMediaDataSource_newUri && ndk.AMediaDataSource_close && ndk.AMediaDataSource_delete && ndk.AMediaExtractor_setDataSourceCustom) {

				*dataSource = ndk.AMediaDataSource_newUri (path.c_str (), 0, NULL);

				if (*dataSource) {

					status = ndk.AMediaExtractor_setDataSourceCustom (extractor, *dataSource);

					if (status != AMEDIA_OK) {

						ndk.AMediaExtractor_delete (extractor);
						ndk.AMediaDataSource_delete (*dataSource);
						*dataSource = NULL;
						extractor = ndk.AMediaExtractor_new ();
						if (!extractor) return NULL;

					}

				}

			}

			if (status != AMEDIA_OK) status = ndk.AMediaExtractor_setDataSource (extractor, path.c_str ());

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

			if (*dataSource) {

				ndk.AMediaDataSource_delete (*dataSource);
				*dataSource = NULL;

			}

			return NULL;

		}

		return extractor;

	}


	ANativeWindow* MediaCodecVideoBackend::CreateImageReader (int width, int height) {

		if (imageWindow) return imageWindow;
		if (!CanUseImageReader ()) return NULL;

		AImageReader* reader = NULL;

		if (ndk.AImageReader_newWithUsage (std::max (width, 1), std::max (height, 1), IMAGE_FORMAT_PRIVATE, IMAGE_USAGE_GPU_SAMPLED, OUTPUT_IMAGES, &reader) != AMEDIA_OK || !reader) {

			return NULL;

		}

		ImageListener listener = { this, OnImageAvailable };
		ANativeWindow* window = NULL;

		if (ndk.AImageReader_setImageListener (reader, &listener) != AMEDIA_OK || ndk.AImageReader_getWindow (reader, &window) != AMEDIA_OK || !window) {

			ndk.AImageReader_delete (reader);
			return NULL;

		}

		imageReader = reader;
		imageWindow = window;

		return window;

	}


	bool MediaCodecVideoBackend::CreateTextures () {

		GLuint vertexShader = CompileShader (GL_VERTEX_SHADER, COPY_VERTEX_SHADER);
		GLuint fragmentShader = CompileShader (GL_FRAGMENT_SHADER, COPY_FRAGMENT_SHADER);
		GLuint program = 0;

		if (vertexShader && fragmentShader) {

			program = glCreateProgram ();
			glAttachShader (program, vertexShader);
			glAttachShader (program, fragmentShader);
			glBindAttribLocation (program, 0, "position");
			glLinkProgram (program);

			GLint linked = 0;
			glGetProgramiv (program, GL_LINK_STATUS, &linked);

			if (!linked) {

				glDeleteProgram (program);
				program = 0;

			}

		}

		if (vertexShader) glDeleteShader (vertexShader);
		if (fragmentShader) glDeleteShader (fragmentShader);
		if (!program) return false;

		copyProgram = program;
		cropLocation = glGetUniformLocation (program, "crop");
		glUseProgram (program);
		glUniform1i (glGetUniformLocation (program, "image"), 0);

		static const GLfloat positions[] = { -1, -1, 1, -1, -1, 1, 1, 1 };
		glGenBuffers (1, &copyBuffer);
		glBindBuffer (GL_ARRAY_BUFFER, copyBuffer);
		glBufferData (GL_ARRAY_BUFFER, sizeof (positions), positions, GL_STATIC_DRAW);

		if (textureGLES3) {

			_glGenVertexArrays (1, &copyVertexArray);
			_glBindVertexArray (copyVertexArray);
			glVertexAttribPointer (0, 2, GL_FLOAT, GL_FALSE, 0, NULL);
			glEnableVertexAttribArray (0);

		}

		glGenTextures (1, &imageTexture);
		glBindTexture (GL_TEXTURE_EXTERNAL_OES, imageTexture);
		glTexParameteri (GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri (GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri (GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri (GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

		glGenTextures (1, &copyTexture);
		glBindTexture (GL_TEXTURE_2D, copyTexture);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

		glGenFramebuffers (1, &copyFramebuffer);
		copyTextureWidth = 0;
		copyTextureHeight = 0;

		return true;

	}


	AMediaCodec* MediaCodecVideoBackend::CreateVideoDecoder (bool hardware, bool surface) {

		// HDR video is tone mapped to standard range, in 8-bit frames, by
		// decoders that can from Android 13, rather than shown washed out. A
		// decoder that refuses the request is configured without it.
		for (int attempt = 0; attempt < 2; attempt++) {

			// Configuring with a surface stores it in the format, so each codec
			// gets its own copy of the track format
			AMediaFormat* format = ndk.AMediaExtractor_getTrackFormat (video.extractor, videoTrack);
			if (!format) return NULL;

			int32_t transfer = 0;
			bool hdr = ndk.AMediaFormat_getInt32 (format, "color-transfer", &transfer) && (transfer == COLOR_TRANSFER_ST2084 || transfer == COLOR_TRANSFER_HLG);

			if (ndk.AMediaFormat_setInt32) {

				// Containers without an index, such as MPEG-TS, do not say how
				// large a sample can be, and a keyframe larger than the decoder's
				// default buffer could not be read
				int32_t maxInputSize = 0;
				int32_t width = 0;
				int32_t height = 0;

				if (!ndk.AMediaFormat_getInt32 (format, "max-input-size", &maxInputSize) && ndk.AMediaFormat_getInt32 (format, "width", &width) && ndk.AMediaFormat_getInt32 (format, "height", &height)) {

					int64_t estimate = (int64_t)width * height * 3 / 4;
					ndk.AMediaFormat_setInt32 (format, "max-input-size", (int32_t)std::min<int64_t> (std::max<int64_t> (estimate, 1 << 20), 16 << 20));

				}

				if (hdr && attempt == 0) {

					ndk.AMediaFormat_setInt32 (format, "color-transfer-request", COLOR_TRANSFER_SDR_VIDEO);
					if (!surface) ndk.AMediaFormat_setInt32 (format, "color-format", COLOR_FORMAT_YUV420_FLEXIBLE);

				}

			}

			AMediaCodec* codec = CreateDecoder (format, hardware, surface ? imageWindow : NULL);
			ndk.AMediaFormat_delete (format);

			if (codec || !hdr || !ndk.AMediaFormat_setInt32) return codec;

		}

		return NULL;

	}


	VideoDecodeResult MediaCodecVideoBackend::DecodeAudio (std::vector<unsigned char>* pcm, double* time) {

		if (audio.reopen && audio.codec) {

			VideoDecodeResult result = ReopenStream (&audio, audioTrack);
			if (result != VIDEO_DECODE_OK) return result;

		}

		while (audio.codec) {

			bool formatChanged = false;
			VideoDecodeResult result = audio.Read (&formatChanged);

			if (formatChanged && !ReadAudioFormat ()) result = VIDEO_DECODE_ERROR;

			// After restarting, the audio up to the last packet returned is skipped
			if (result == VIDEO_DECODE_OK && audio.info.presentationTimeUs <= audioSkipTime) {

				audio.Release ();
				continue;

			}

			size_t capacity = 0;
			uint8_t* data = result == VIDEO_DECODE_OK ? ndk.AMediaCodec_getOutputBuffer (audio.codec, audio.index, &capacity) : NULL;
			size_t offset = (size_t)audio.info.offset;
			size_t length = (size_t)audio.info.size;
			int sampleBytes = GetSampleBytes (audioEncoding);

			if (result == VIDEO_DECODE_OK && (!data || offset > capacity || length > capacity - offset || sampleBytes <= 0 || audioSourceChannels <= 0)) {

				result = VIDEO_DECODE_ERROR;

			}

			if (result != VIDEO_DECODE_OK) {

				audio.Release ();

				// A codec that fails, or that the system reclaims for another app, is
				// replaced, carrying on after the last audio returned
				if (result == VIDEO_DECODE_ERROR && RestartAudio ()) continue;

				return result;

			}

			int frames = (int)(length / (audioSourceChannels * sampleBytes));
			const short* samples = (const short*)(data + offset);

			if (audioEncoding != PCM_ENCODING_16BIT) {

				ConvertSamples (data + offset, (size_t)frames * audioSourceChannels, audioEncoding, &audioSamples);
				samples = audioSamples.data ();

			}

			// Audio is given in the format it opened with, downmixing surround and
			// following a stream that changes its rate or channels
			if (audioSourceChannels == audioChannels && audioSourceRate == audioSampleRate) {

				pcm->insert (pcm->end (), (const unsigned char*)samples, (const unsigned char*)(samples + frames * audioChannels));

			} else {

				ConvertAudio (samples, frames, audioSourceChannels, audioSourceRate, audioChannels, audioSampleRate, &audioConverter, pcm);

			}

			audioRestarts = 0;
			audioSkipTime = INT64_MIN;
			audioTime = audio.info.presentationTimeUs;
			*time = audioTime / 1000000.0;
			audio.Release ();

			return VIDEO_DECODE_OK;

		}

		return VIDEO_DECODE_END;

	}


	VideoDecodeResult MediaCodecVideoBackend::DecodeVideo (VideoPlanes* planes, double* time, double* duration) {

		if (video.reopen && video.codec) {

			VideoDecodeResult result = ReopenStream (&video, videoTrack);
			if (result != VIDEO_DECODE_OK) return result;

		}

		// Texture output stopped, and VideoDecoder reads in memory until the
		// seek that follows, so continue after the last frame in memory
		if (videoSurface && video.codec) {

			// A decoder that cannot give the same video in memory, as with a
			// layout that cannot be read, is replaced in software
			videoSkipTime = videoTime;
			if (!ReplaceVideoCodec (hardwareActive, false, std::max (videoPosition, videoTime)) && !RestartVideo ()) return VIDEO_DECODE_ERROR;

		}

		while (video.codec) {

			bool formatChanged = false;
			VideoDecodeResult result = video.Read (&formatChanged);

			if (formatChanged) ReadVideoFormat ();
			if (result == VIDEO_DECODE_OK && video.info.presentationTimeUs <= videoSkipTime) continue;
			if (result == VIDEO_DECODE_OK && !GetPlanes (planes)) result = VIDEO_DECODE_ERROR;

			// Some hardware decoders fail on a stream they accepted, or lose it to
			// another app, so continue from the same frame
			if (result == VIDEO_DECODE_ERROR && RestartVideo ()) continue;
			if (result != VIDEO_DECODE_OK) return result;

			videoRestarts = 0;
			videoSkipTime = INT64_MIN;
			videoTime = video.info.presentationTimeUs;
			*time = videoTime / 1000000.0;
			*duration = frameRate > 0 ? 1.0 / frameRate : 0;

			return VIDEO_DECODE_OK;

		}

		return VIDEO_DECODE_END;

	}


	VideoDecodeResult MediaCodecVideoBackend::DecodeVideoTexture (VideoTextureFrame** frame, double* time, double* duration) {

		*frame = NULL;

		if (video.reopen && video.codec) {

			VideoDecodeResult result = ReopenStream (&video, videoTrack);
			if (result != VIDEO_DECODE_OK) return result;

		}

		while (video.codec) {

			// VideoDecoder reads the next frame with DecodeVideo instead
			if (!SupportsTextures ()) return VIDEO_DECODE_OK;

			bool formatChanged = false;
			VideoDecodeResult result = video.Read (&formatChanged);

			if (formatChanged) ReadVideoFormat ();
			if (result == VIDEO_DECODE_OK && video.info.presentationTimeUs <= videoSkipTime) continue;
			if (result == VIDEO_DECODE_ERROR && RestartVideo ()) continue;
			if (result != VIDEO_DECODE_OK) return result;

			AImage* image = AcquireImage ();
			AImageCropRect crop;

			if (!image || ndk.AImage_getCropRect (image, &crop) != AMEDIA_OK || crop.left < 0 || crop.top < 0 || crop.right <= crop.left || crop.bottom <= crop.top) {

				// Frames that do not reach the reader are decoded into memory
				if (image) ReleaseImage (image, -1);
				texturesFailed = true;
				return VIDEO_DECODE_OK;

			}

			MediaCodecTextureFrame* textureFrame = new MediaCodecTextureFrame ();
			textureFrame->cropX = crop.left;
			textureFrame->cropY = crop.top;
			textureFrame->fence = -1;
			textureFrame->height = crop.bottom - crop.top;
			textureFrame->image = image;
			textureFrame->width = crop.right - crop.left;
			*frame = textureFrame;

			videoRestarts = 0;
			videoSkipTime = INT64_MIN;
			videoTime = video.info.presentationTimeUs;
			*time = videoTime / 1000000.0;
			*duration = frameRate > 0 ? 1.0 / frameRate : 0;

			return VIDEO_DECODE_OK;

		}

		return VIDEO_DECODE_END;

	}


	void MediaCodecVideoBackend::ForgetTextures () {

		// Leaves the GL objects, which belong to a context that may be gone
		copyBuffer = 0;
		copyFramebuffer = 0;
		copyProgram = 0;
		copyTexture = 0;
		copyTextureHeight = 0;
		copyTextureWidth = 0;
		copyVertexArray = 0;
		cropLocation = -1;
		imageTexture = 0;
		nativeFences = false;
		textureContext = EGL_NO_CONTEXT;
		textureGLES3 = false;

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
		planes->transfer = colorTransfer;
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


	void MediaCodecVideoBackend::Interrupt () {

		audio.interrupted = true;
		video.interrupted = true;

		{
			// Reads waiting on a stalled network fail at once
			std::lock_guard<std::mutex> lock (reads.mutex);
			if (audio.dataSource) ndk.AMediaDataSource_close (audio.dataSource);
			if (video.dataSource) ndk.AMediaDataSource_close (video.dataSource);
		}

		std::lock_guard<std::mutex> lock (imageMutex);
		imageCondition.notify_all ();

	}


	unsigned int MediaCodecVideoBackend::LockTexture (VideoTextureFrame* frame) {

		MediaCodecTextureFrame* textureFrame = (MediaCodecTextureFrame*)frame;
		EGLDisplay display = eglGetCurrentDisplay ();
		EGLContext context = eglGetCurrentContext ();

		if (display == EGL_NO_DISPLAY || context == EGL_NO_CONTEXT || !LoadEGLExtensions ()) return 0;

		if (context != textureContext) ForgetTextures ();
		textureContext = context;

		if (!copyProgram) {

			const char* eglExtensions = eglQueryString (display, EGL_EXTENSIONS);
			const char* glExtensions = (const char*)glGetString (GL_EXTENSIONS);
			const char* version = (const char*)glGetString (GL_VERSION);

			if (!HasExtension (eglExtensions, "EGL_ANDROID_image_native_buffer") || !HasExtension (glExtensions, "GL_OES_EGL_image_external")) return 0;

			// A GLES 3 context draws the copy with its own vertex array
			textureGLES3 = version && strncmp (version, "OpenGL ES ", 10) == 0 && atoi (version + 10) >= 3 && _glBindVertexArray && _glDeleteVertexArrays && _glGenVertexArrays;
			nativeFences = HasExtension (eglExtensions, "EGL_ANDROID_native_fence_sync") && _eglCreateSyncKHR && _eglDestroySyncKHR && _eglDupNativeFenceFDANDROID;

		}

		AHardwareBuffer* buffer = NULL;
		HardwareBufferDesc desc;
		memset (&desc, 0, sizeof (desc));

		if (ndk.AImage_getHardwareBuffer (textureFrame->image, &buffer) != AMEDIA_OK || !buffer) return 0;

		ndk.AHardwareBuffer_describe (buffer, &desc);

		int width = textureFrame->width;
		int height = textureFrame->height;

		if (desc.width == 0 || desc.height == 0 || textureFrame->cropX + width > (int)desc.width || textureFrame->cropY + height > (int)desc.height) return 0;

		EGLClientBuffer clientBuffer = _eglGetNativeClientBufferANDROID (buffer);
		EGLint attributes[] = { EGL_IMAGE_PRESERVED_KHR, EGL_TRUE, EGL_NONE };
		EGLImageKHR image = clientBuffer ? _eglCreateImageKHR (display, EGL_NO_CONTEXT, EGL_NATIVE_BUFFER_ANDROID, clientBuffer, attributes) : EGL_NO_IMAGE_KHR;

		if (image == EGL_NO_IMAGE_KHR) return 0;

		SavedGLState state;
		SaveGLState (&state, textureGLES3);

		bool copied = false;

		if (copyProgram || CreateTextures ()) {

			glActiveTexture (GL_TEXTURE0);
			glBindTexture (GL_TEXTURE_EXTERNAL_OES, imageTexture);
			_glEGLImageTargetTexture2DOES (GL_TEXTURE_EXTERNAL_OES, image);

			if (copyTextureWidth != width || copyTextureHeight != height) {

				// A bound unpack buffer would be read as the initial contents
				if (textureGLES3) glBindBuffer (GL_PIXEL_UNPACK_BUFFER, 0);

				glBindTexture (GL_TEXTURE_2D, copyTexture);
				glTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
				glBindFramebuffer (GL_FRAMEBUFFER, copyFramebuffer);
				glFramebufferTexture2D (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, copyTexture, 0);

				copyTextureWidth = width;
				copyTextureHeight = height;

			}

			glBindFramebuffer (GL_FRAMEBUFFER, copyFramebuffer);

			if (glCheckFramebufferStatus (GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE) {

				glDisable (GL_BLEND);
				glDisable (GL_CULL_FACE);
				glDisable (GL_DEPTH_TEST);
				glDisable (GL_SCISSOR_TEST);
				glDisable (GL_STENCIL_TEST);
				if (textureGLES3) glDisable (GL_RASTERIZER_DISCARD);
				glColorMask (GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
				glViewport (0, 0, width, height);

				glUseProgram (copyProgram);
				glUniform4f (cropLocation, (float)textureFrame->cropX / desc.width, (float)textureFrame->cropY / desc.height, (float)width / desc.width, (float)height / desc.height);

				if (textureGLES3) {

					_glBindVertexArray (copyVertexArray);

				} else {

					glBindBuffer (GL_ARRAY_BUFFER, copyBuffer);
					glVertexAttribPointer (0, 2, GL_FLOAT, GL_FALSE, 0, NULL);
					glEnableVertexAttribArray (0);

				}

				// The driver converts YUV to RGB as it samples the external texture
				glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);
				copied = true;

			}

		}

		RestoreGLState (&state, textureGLES3);

		// The texture keeps the buffer it was drawn from, so the image is not needed
		_eglDestroyImageKHR (display, image);

		// The decoder can reuse the buffer once the copy has read it, which a
		// native fence tells it without waiting here
		if (copied && nativeFences) {

			EGLSyncKHR sync = _eglCreateSyncKHR (display, EGL_SYNC_NATIVE_FENCE_ANDROID, NULL);

			if (sync != EGL_NO_SYNC_KHR) {

				glFlush ();
				if (textureFrame->fence >= 0) ::close (textureFrame->fence);
				textureFrame->fence = _eglDupNativeFenceFDANDROID (display, sync);
				_eglDestroySyncKHR (display, sync);

			} else {

				glFlush ();

			}

		} else {

			glFlush ();

		}

		return copied ? copyTexture : 0;

	}


	void MediaCodecVideoBackend::OnImageAvailable (void* context, AImageReader* reader) {

		MediaCodecVideoBackend* backend = (MediaCodecVideoBackend*)context;

		std::lock_guard<std::mutex> lock (backend->imageMutex);
		backend->imageSignals++;
		backend->imageCondition.notify_all ();

	}


	bool MediaCodecVideoBackend::Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info) {

		Close ();

		if (!path || !path[0]) return false;

		this->path = path;

		// A seek can give up on a URL read through a data source, from Android 10
		std::string source = path;
		network = source.find ("://") != std::string::npos && source.compare (0, 10, "content://") != 0 && source.compare (0, 7, "file://") != 0
			&& ndk.AMediaDataSource_newUri && ndk.AMediaDataSource_close && ndk.AMediaDataSource_delete && ndk.AMediaExtractor_setDataSourceCustom;

		info->hasVideo = OpenVideo (hardwareDecoding) || (hardwareDecoding && OpenVideo (false));
		info->hasAudio = OpenAudio ();

		// A track that was found but cannot be decoded, such as one in a codec the
		// device lacks
		info->videoUnsupported = !info->hasVideo && videoTrackFound;
		info->audioUnsupported = !info->hasAudio && audioTrackFound;

		if (!info->hasVideo && !info->hasAudio) return false;

		info->audioChannels = audioChannels;
		info->audioSampleRate = audioSampleRate;
		info->duration = duration;
		info->frameRate = info->hasVideo ? frameRate : 0;
		info->pixelAspectRatio = info->hasVideo ? pixelAspectRatio : 0;
		info->rotation = info->hasVideo ? rotation : 0;
		info->width = info->hasVideo ? cropWidth : 0;
		info->height = info->hasVideo ? cropHeight : 0;

		return true;

	}


	bool MediaCodecVideoBackend::OpenAudio () {

		AMediaDataSource* dataSource = NULL;
		AMediaExtractor* extractor = CreateExtractor (&dataSource);
		if (!extractor) return false;

		AMediaFormat* format = SelectTrack (extractor, "audio/", &audioTrack);

		if (!format) {

			ndk.AMediaExtractor_delete (extractor);
			if (dataSource) ndk.AMediaDataSource_delete (dataSource);
			return false;

		}

		audioTrackFound = true;

		int64_t durationUs = 0;
		ndk.AMediaFormat_getInt64 (format, "durationUs", &durationUs);

		// Decoders that can choose give 16-bit samples, which need no conversion
		if (ndk.AMediaFormat_setInt32) ndk.AMediaFormat_setInt32 (format, "pcm-encoding", PCM_ENCODING_16BIT);

		// Hardware decoding only applies to video
		audio.codec = CreateDecoder (format, false, NULL);
		audio.dataSource = dataSource;
		audio.extractor = extractor;
		ndk.AMediaFormat_delete (format);

		if (!audio.codec || !audio.Prime () || !ReadAudioFormat ()) {

			audio.Close ();
			return false;

		}

		audioChannels = audioSourceChannels > 2 ? 2 : audioSourceChannels;
		audioSampleRate = audioSourceRate;
		audioConverter.Reset ();
		if (durationUs / 1000000.0 > duration) duration = durationUs / 1000000.0;

		return true;

	}


	bool MediaCodecVideoBackend::OpenVideo (bool hardware) {

		AMediaDataSource* dataSource = NULL;
		AMediaExtractor* extractor = CreateExtractor (&dataSource);
		if (!extractor) return false;

		AMediaFormat* format = SelectTrack (extractor, "video/", &videoTrack);

		if (!format) {

			ndk.AMediaExtractor_delete (extractor);
			if (dataSource) ndk.AMediaDataSource_delete (dataSource);
			return false;

		}

		videoTrackFound = true;

		// Phones store video recorded upright sideways, with the turn that shows
		// it upright, and some video has pixels that are not square. Decoding
		// keeps frames as they are stored.
		int32_t degrees = 0;
		int32_t sarWidth = 0;
		int32_t sarHeight = 0;
		rotation = ndk.AMediaFormat_getInt32 (format, "rotation-degrees", &degrees) ? degrees : 0;
		pixelAspectRatio = ndk.AMediaFormat_getInt32 (format, "sar-width", &sarWidth) && ndk.AMediaFormat_getInt32 (format, "sar-height", &sarHeight) && sarWidth > 0 && sarHeight > 0 ? (double)sarWidth / sarHeight : 0;

		float floatRate = 0;
		int32_t intRate = 0;
		double formatRate = ndk.AMediaFormat_getFloat (format, "frame-rate", &floatRate) ? floatRate : (ndk.AMediaFormat_getInt32 (format, "frame-rate", &intRate) ? intRate : 0);

		// Containers may round the frame rate, so prefer the spacing of the
		// first frames when it agrees
		frameRate = EstimateFrameRate (extractor);
		if (formatRate > 0 && !(fabs (frameRate - formatRate) < 0.5)) frameRate = formatRate;

		int64_t durationUs = 0;
		int32_t trackWidth = 0;
		int32_t trackHeight = 0;
		ndk.AMediaFormat_getInt64 (format, "durationUs", &durationUs);
		ndk.AMediaFormat_getInt32 (format, "width", &trackWidth);
		ndk.AMediaFormat_getInt32 (format, "height", &trackHeight);

		// Containers also give the size to show the picture at, which for pixels
		// that are not square is wider or taller than the picture
		int32_t displayWidth = 0;
		int32_t displayHeight = 0;

		if (pixelAspectRatio <= 0 && trackWidth > 0 && trackHeight > 0 && ndk.AMediaFormat_getInt32 (format, "display-width", &displayWidth) && ndk.AMediaFormat_getInt32 (format, "display-height", &displayHeight) && displayWidth > 0 && displayHeight > 0) {

			double shape = ((double)displayWidth / trackWidth) / ((double)displayHeight / trackHeight);
			if (fabs (shape - 1.0) > 0.01) pixelAspectRatio = shape;

		}

		// Texture output decodes into an image reader, falling back to memory
		// when the decoder cannot use one
		bool surface = textureOutput && CreateImageReader (trackWidth, trackHeight);

		video.dataSource = dataSource;
		video.extractor = extractor;
		videoFormat = format;
		video.codec = surface ? CreateVideoDecoder (hardware, true) : NULL;
		videoSurface = (video.codec != NULL);
		if (!video.codec) video.codec = CreateVideoDecoder (hardware, false);
		hardwareActive = hardware;

		if (!video.codec || !video.Prime () || !ReadVideoFormat () || cropWidth <= 0 || cropHeight <= 0) {

			video.Close ();
			ndk.AMediaFormat_delete (videoFormat);
			videoFormat = NULL;
			hardwareActive = false;
			videoSurface = false;
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

		// The format of the audio being decoded now, which can change partway
		audioEncoding = encoding;
		audioSourceChannels = channels;
		audioSourceRate = sampleRate;

		return (channels > 0 && channels <= 8 && sampleRate > 0 && GetSampleBytes (encoding) > 0);

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

		// Decoders give the pixel shape from the stream itself where the
		// container does not
		int32_t sarWidth = 0;
		int32_t sarHeight = 0;

		if (pixelAspectRatio <= 0 && ndk.AMediaFormat_getInt32 (format, "sar-width", &sarWidth) && ndk.AMediaFormat_getInt32 (format, "sar-height", &sarHeight) && sarWidth > 0 && sarHeight > 0) {

			pixelAspectRatio = (double)sarWidth / sarHeight;

		}

		// Frames decoded into the image reader have no memory layout to read
		bool supported = videoSurface || ReadPlaneLayout (format, width, height);

		// Decoders only report the color aspects that the stream signals
		int32_t range = 0;
		int32_t standard = 0;

		if (!ndk.AMediaFormat_getInt32 (format, "color-range", &range) || range == 0) ndk.AMediaFormat_getInt32 (videoFormat, "color-range", &range);
		if (!ndk.AMediaFormat_getInt32 (format, "color-standard", &standard) || standard == 0) ndk.AMediaFormat_getInt32 (videoFormat, "color-standard", &standard);

		// Decoders that tone map HDR, which they can from Android 13, say their
		// frames are standard range. HDR that is not is tone mapped by
		// VideoDecoder.
		int32_t transfer = 0;
		if ((!ndk.AMediaFormat_getInt32 (format, "color-transfer", &transfer) || transfer == 0) && GetSystemVersion () < 33) ndk.AMediaFormat_getInt32 (videoFormat, "color-transfer", &transfer);
		colorTransfer = transfer == COLOR_TRANSFER_ST2084 ? VIDEO_COLOR_TRANSFER_PQ : (transfer == COLOR_TRANSFER_HLG ? VIDEO_COLOR_TRANSFER_HLG : VIDEO_COLOR_TRANSFER_SDR);

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


	void MediaCodecVideoBackend::ReleaseImage (AImage* image, int fence) {

		// The reader waits for the fence before the decoder writes the buffer again
		if (fence >= 0) {

			ndk.AImage_deleteAsync (image, fence);

		} else {

			ndk.AImage_delete (image);

		}

		std::lock_guard<std::mutex> lock (imageMutex);
		imagesHeld--;
		imageCondition.notify_all ();

	}


	void MediaCodecVideoBackend::ReleaseTextureFrame (VideoTextureFrame* frame) {

		MediaCodecTextureFrame* textureFrame = (MediaCodecTextureFrame*)frame;
		ReleaseImage (textureFrame->image, textureFrame->fence);
		delete textureFrame;

	}


	void MediaCodecVideoBackend::ReleaseOrphans () {

		std::vector<MediaCodecOrphan> list;

		{
			std::lock_guard<std::mutex> lock (*orphanMutex);
			if (orphans->empty ()) return;
			list.swap (*orphans);
		}

		EGLContext context = eglGetCurrentContext ();

		for (size_t i = 0; i < list.size (); i++) {

			// Objects from a context that is no longer current are left with it
			MediaCodecOrphan& orphan = list[i];
			if (orphan.context != context) continue;

			if (orphan.copyBuffer) glDeleteBuffers (1, &orphan.copyBuffer);
			if (orphan.copyFramebuffer) glDeleteFramebuffers (1, &orphan.copyFramebuffer);
			if (orphan.copyProgram) glDeleteProgram (orphan.copyProgram);
			if (orphan.copyTexture) glDeleteTextures (1, &orphan.copyTexture);
			if (orphan.copyVertexArray && _glDeleteVertexArrays) _glDeleteVertexArrays (1, &orphan.copyVertexArray);
			if (orphan.imageTexture) glDeleteTextures (1, &orphan.imageTexture);

		}

	}


	void MediaCodecVideoBackend::ReleaseTextures () {

		// GL names only mean these objects in the context that made them
		if (textureContext != EGL_NO_CONTEXT && eglGetCurrentContext () == textureContext) {

			if (copyBuffer) glDeleteBuffers (1, &copyBuffer);
			if (copyFramebuffer) glDeleteFramebuffers (1, &copyFramebuffer);
			if (copyProgram) glDeleteProgram (copyProgram);
			if (copyTexture) glDeleteTextures (1, &copyTexture);
			if (copyVertexArray) _glDeleteVertexArrays (1, &copyVertexArray);
			if (imageTexture) glDeleteTextures (1, &imageTexture);

		}

		ForgetTextures ();

	}


	void MediaCodecVideoBackend::PrepareSeek () {

		// A stream waiting on a stalled network source would hold up the seek
		// until the connection gives up, which takes minutes. Reads from a
		// source that is still sending finish soon, and those that have not by
		// then are given up. Their streams connect again once the seek is done.
		if (!network) return;

		std::unique_lock<std::mutex> lock (reads.mutex);
		reads.seeking = true;
		reads.condition.wait_for (lock, std::chrono::milliseconds (SEEK_WAIT_MS), [this] { return !audio.busy && !video.busy; });

		if (audio.busy) audio.GiveUp ();
		if (video.busy) video.GiveUp ();

	}


	VideoDecodeResult MediaCodecVideoBackend::ReopenStream (MediaCodecStream* stream, size_t track) {

		// A seek gave up on a read that waited on a stalled network source, so
		// the stream reads through a new connection, from where the seek went.
		// The codec carries on, as the seek flushed it. Connecting cannot be
		// cancelled, so decoding waits for it a little at a time, and seeking
		// and closing do not wait for it.
		#ifndef LIME_VIDEO_STANDALONE
		// A URL is read and closed through Java, so this thread joins the Java VM
		SDL_AndroidGetJNIEnv ();
		#endif

		if (!stream->connection) {

			if (stream->extractor) {

				ndk.AMediaExtractor_delete (stream->extractor);
				stream->extractor = NULL;

			}

			stream->SetDataSource (NULL);
			stream->connection = Connect (path);

		}

		std::shared_ptr<MediaCodecConnection> connection = stream->connection;
		AMediaDataSource* dataSource = NULL;

		{
			std::unique_lock<std::mutex> lock (connection->mutex);
			if (!connection->condition.wait_for (lock, std::chrono::milliseconds (CONNECT_WAIT_MS), [&connection] { return connection->done; })) return VIDEO_DECODE_AGAIN;

			dataSource = connection->dataSource;
			connection->dataSource = NULL;
		}

		stream->connection.reset ();

		// A server that cannot be reached is tried again at the next seek
		if (!dataSource) return VIDEO_DECODE_ERROR;

		// Opening reads from the source, which a seek or closing can give up
		stream->SetDataSource (dataSource);
		if (!stream->BeginRead ()) return VIDEO_DECODE_AGAIN;

		AMediaExtractor* extractor = ndk.AMediaExtractor_new ();
		bool opened = extractor && ndk.AMediaExtractor_setDataSourceCustom (extractor, dataSource) == AMEDIA_OK && ndk.AMediaExtractor_selectTrack (extractor, track) == AMEDIA_OK;
		stream->EndRead ();

		if (!opened) {

			if (extractor) ndk.AMediaExtractor_delete (extractor);
			return stream->cancelled ? VIDEO_DECODE_AGAIN : VIDEO_DECODE_ERROR;

		}

		// The extractor seeks to where the seek went before reading next
		stream->extractor = extractor;
		stream->reopen = false;
		return VIDEO_DECODE_OK;

	}


	bool MediaCodecVideoBackend::ReplaceVideoCodec (bool hardware, bool surface, int64_t position) {

		video.Release ();

		if (video.codec) {

			ndk.AMediaCodec_stop (video.codec);
			ndk.AMediaCodec_delete (video.codec);

		}

		video.codec = CreateVideoDecoder (hardware, surface);
		video.ended = false;
		video.inputEnded = false;
		videoSurface = surface && video.codec;

		if (!video.codec) return false;

		video.seekPosition = position;

		return video.Prime () && ReadVideoFormat ();

	}


	bool MediaCodecVideoBackend::RestartAudio () {

		// Closing interrupts decoding, which is not a failure
		if (audio.interrupted || !audio.extractor || audioRestarts >= MAX_CODEC_RESTARTS) return false;

		audioRestarts++;
		audio.Release ();

		if (audio.codec) {

			ndk.AMediaCodec_stop (audio.codec);
			ndk.AMediaCodec_delete (audio.codec);
			audio.codec = NULL;

		}

		AMediaFormat* format = ndk.AMediaExtractor_getTrackFormat (audio.extractor, audioTrack);
		if (!format) return false;

		if (ndk.AMediaFormat_setInt32) ndk.AMediaFormat_setInt32 (format, "pcm-encoding", PCM_ENCODING_16BIT);
		audio.codec = CreateDecoder (format, false, NULL);
		ndk.AMediaFormat_delete (format);

		if (!audio.codec) return false;

		audio.ended = false;
		audio.inputEnded = false;
		audio.inputError = false;

		// Resume from the packet before the last one returned, and skip to it
		audio.seekPosition = audioTime != INT64_MIN ? audioTime : audioPosition;
		audioSkipTime = audioTime;
		return true;

	}


	bool MediaCodecVideoBackend::RestartVideo () {

		// Closing interrupts decoding, which is not a failure
		if (video.interrupted || videoRestarts >= MAX_CODEC_RESTARTS) return false;

		videoRestarts++;

		// Resume from the keyframe before the last frame returned, and skip to it
		int64_t position = std::max (videoPosition, videoTime);
		videoSkipTime = videoTime;

		// A hardware codec that the system reclaimed for another app is replaced
		// by another the first time, and one that fails again by software
		if (hardwareActive && videoRestarts == 1 && ReplaceVideoCodec (true, videoSurface, position)) return true;

		hardwareActive = false;
		return ReplaceVideoCodec (false, videoSurface, position);

	}


	bool MediaCodecVideoBackend::Seek (double time) {

		reads.seeking = false;

		int64_t position = (int64_t)(time * 1000000.0);
		bool success = true;

		if (video.codec) {

			videoPosition = position;
			videoSkipTime = INT64_MIN;
			videoTime = INT64_MIN;

			// Texture output stopped, so decode into memory from here on, which
			// a stream that connects again does once it has
			if (videoSurface && !textureOutput && !video.reopen) {

				success = ReplaceVideoCodec (hardwareActive, false, position) && success;

			} else {

				success = video.Seek (position, network) && success;

			}

		}

		if (audio.codec) {

			audioConverter.Reset ();
			audioPosition = position;
			audioSkipTime = INT64_MIN;
			audioTime = INT64_MIN;
			success = audio.Seek (position, network) && success;

		}

		return success;

	}


	void MediaCodecVideoBackend::SetTextureOutput (bool enabled) {

		// This can be called while the video thread decodes, so the codec only
		// changes output at the next Open, Seek or DecodeVideo
		textureOutput = enabled;

	}


	bool MediaCodecVideoBackend::SupportsTextures () {

		// HDR frames that VideoDecoder tone maps are decoded into memory
		return videoSurface && textureOutput && !texturesFailed && colorTransfer == VIDEO_COLOR_TRANSFER_SDR;

	}


	VideoBackend* VideoBackend::Create () {

		return LoadMediaNDK () ? new MediaCodecVideoBackend () : NULL;

	}


	bool VideoBackend::IsSupported () {

		return LoadMediaNDK ();

	}


}


#endif
