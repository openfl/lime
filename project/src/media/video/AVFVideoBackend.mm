#include <media/VideoDecoder.h>


#ifdef LIME_VIDEO_AVFOUNDATION


// OpenGL, OpenGL ES and the CoreVideo texture caches for them are deprecated
#ifndef GL_SILENCE_DEPRECATION
#define GL_SILENCE_DEPRECATION
#endif
#ifndef GLES_SILENCE_DEPRECATION
#define GLES_SILENCE_DEPRECATION
#endif

// ANGLE contexts are not CGL or EAGL contexts that can share CoreVideo textures
#ifndef NATIVE_TOOLKIT_SDL_ANGLE
#define LIME_VIDEO_AVF_TEXTURES
#endif

#ifdef LIME_VIDEO_AVF_TEXTURES
#ifdef HX_MACOS
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#else
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#endif
#endif

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#include <stdlib.h>
#include <string.h>

#if __has_feature(objc_arc)
#define LIME_AUTORELEASE(object) (object)
#define LIME_RETAIN(object) (object)
#define LIME_RELEASE(object)
#define LIME_BRIDGE(type, pointer) ((__bridge type)(pointer))
#else
#define LIME_AUTORELEASE(object) [(object) autorelease]
#define LIME_RETAIN(object) [(object) retain]
#define LIME_RELEASE(object) [(object) release]
#define LIME_BRIDGE(type, pointer) ((type)(pointer))
#endif


namespace lime {


	// AVAssetReader starts each stream at the first frame or sample in its time
	// range, so a seek reads from a little earlier to include the frame showing
	// at the seek time. VideoDecoder drops what precedes an accurate seek.
	static const double SEEK_PREROLL = 0.1;


	// CVBufferCopyAttachment, which replaces CVBufferGetAttachment, needs macOS 12 and iOS 15
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"

	static VideoColorMatrix GetColorMatrix (CVBufferRef buffer, int width, int height) {

		CFTypeRef matrix = CVBufferGetAttachment (buffer, kCVImageBufferYCbCrMatrixKey, NULL);

		if (matrix) {

			if (CFEqual (matrix, kCVImageBufferYCbCrMatrix_ITU_R_601_4)) return VIDEO_COLOR_MATRIX_BT601;
			if (CFEqual (matrix, kCVImageBufferYCbCrMatrix_ITU_R_709_2)) return VIDEO_COLOR_MATRIX_BT709;

			// kCVImageBufferYCbCrMatrix_ITU_R_2020 needs macOS 10.11, so compare with its value
			if (CFEqual (matrix, CFSTR ("ITU_R_2020"))) return VIDEO_COLOR_MATRIX_BT2020;

		}

		return VideoBackend::GetDefaultColorMatrix (width, height);

	}

	#pragma clang diagnostic pop


	static VideoDecodeResult GetEndResult (AVAssetReader* reader) {

		// copyNextSampleBuffer returns NULL at the end of the time range or on failure
		return [reader status] == AVAssetReaderStatusFailed ? VIDEO_DECODE_ERROR : VIDEO_DECODE_END;

	}


	static double GetSeconds (CMTime time, double fallback) {

		return CMTIME_IS_NUMERIC (time) ? CMTimeGetSeconds (time) : fallback;

	}


	static NSURL* GetURL (const char* path) {

		NSString* string = [NSString stringWithUTF8String:path];
		if (!string) return nil;

		if ([string rangeOfString:@"://"].location != NSNotFound) {

			NSURL* url = [NSURL URLWithString:string];

			// File URLs are often written without escaping spaces and other characters
			if (!url && [string hasPrefix:@"file://"]) url = [NSURL fileURLWithPath:[string substringFromIndex:7]];

			return url;

		}

		if ([string hasPrefix:@"/"]) return [NSURL fileURLWithPath:string];

		// Relative paths are resources in the application bundle, or files in the current directory
		NSFileManager* fileManager = [NSFileManager defaultManager];
		NSString* resourcePath = [[NSBundle mainBundle] resourcePath];

		if (resourcePath) {

			NSString* bundlePath = [resourcePath stringByAppendingPathComponent:string];
			if ([fileManager fileExistsAtPath:bundlePath]) return [NSURL fileURLWithPath:bundlePath];

		}

		return [NSURL fileURLWithPath:[[fileManager currentDirectoryPath] stringByAppendingPathComponent:string]];

	}


	static bool IsBGRA (CVImageBufferRef image) {

		return CFGetTypeID (image) == CVPixelBufferGetTypeID () && CVPixelBufferGetPixelFormatType (image) == kCVPixelFormatType_32BGRA;

	}


	static bool IsNV12 (CVImageBufferRef image) {

		return CFGetTypeID (image) == CVPixelBufferGetTypeID () && CVPixelBufferGetPixelFormatType (image) == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange && CVPixelBufferGetPlaneCount (image) >= 2;

	}


	#if defined (LIME_VIDEO_AVF_TEXTURES) && defined (HX_MACOS)

	// Framebuffer objects and blits are core from OpenGL 3.0. Legacy 2.1
	// contexts have them as ARB_framebuffer_object, which uses the same
	// functions, or as the EXT extensions.

	static void BindFramebuffer (bool ext, GLenum target, GLuint framebuffer) {

		if (ext) glBindFramebufferEXT (target, framebuffer);
		else glBindFramebuffer (target, framebuffer);

	}


	static void BlitFramebuffer (bool ext, GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1) {

		if (ext) glBlitFramebufferEXT (srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, GL_COLOR_BUFFER_BIT, GL_NEAREST);
		else glBlitFramebuffer (srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, GL_COLOR_BUFFER_BIT, GL_NEAREST);

	}


	static void DeleteFramebuffer (bool ext, GLuint framebuffer) {

		if (ext) glDeleteFramebuffersEXT (1, &framebuffer);
		else glDeleteFramebuffers (1, &framebuffer);

	}


	static void FramebufferTexture2D (bool ext, GLenum target, GLenum textureTarget, GLuint texture) {

		if (ext) glFramebufferTexture2DEXT (target, GL_COLOR_ATTACHMENT0, textureTarget, texture, 0);
		else glFramebufferTexture2D (target, GL_COLOR_ATTACHMENT0, textureTarget, texture, 0);

	}


	static GLuint GenFramebuffer (bool ext) {

		GLuint framebuffer = 0;

		if (ext) glGenFramebuffersEXT (1, &framebuffer);
		else glGenFramebuffers (1, &framebuffer);

		return framebuffer;

	}


	static bool HasExtension (const char* extensions, const char* name) {

		if (!extensions) return false;

		size_t length = strlen (name);

		for (const char* match = strstr (extensions, name); match; match = strstr (match + length, name)) {

			if ((match == extensions || match[-1] == ' ') && (match[length] == ' ' || match[length] == '\0')) return true;

		}

		return false;

	}


	static bool IsFramebufferComplete (bool ext, GLenum target) {

		return (ext ? glCheckFramebufferStatusEXT (target) : glCheckFramebufferStatus (target)) == GL_FRAMEBUFFER_COMPLETE;

	}

	#endif


	#if defined (LIME_VIDEO_AVF_TEXTURES) && defined (HX_MACOS)
	typedef CVOpenGLTextureCacheRef AVFTextureCacheRef;
	#elif defined (LIME_VIDEO_AVF_TEXTURES)
	typedef CVOpenGLESTextureCacheRef AVFTextureCacheRef;
	#else
	typedef void* AVFTextureCacheRef;
	#endif


	// A BGRA frame that VideoToolbox converted on the GPU, kept in its IOSurface
	class AVFTextureFrame : public VideoTextureFrame {


		public:

			AVFTextureFrame (CVPixelBufferRef pixelBuffer);
			~AVFTextureFrame ();

			CVPixelBufferRef buffer;

			// The CVOpenGLTextureRef or CVOpenGLESTextureRef made from the
			// buffer while the frame is locked
			CVImageBufferRef texture;


	};


	AVFTextureFrame::AVFTextureFrame (CVPixelBufferRef pixelBuffer) {

		buffer = CVPixelBufferRetain (pixelBuffer);
		height = (int)CVPixelBufferGetHeight (pixelBuffer);
		texture = NULL;
		width = (int)CVPixelBufferGetWidth (pixelBuffer);

	}


	AVFTextureFrame::~AVFTextureFrame () {

		if (texture) CFRelease (texture);
		CVPixelBufferRelease (buffer);

	}


	// Returns an autoreleased reader that has started reading the output from
	// time, or nil
	static AVAssetReader* StartReader (AVAsset* asset, AVAssetReaderTrackOutput* output, double time) {

		AVAssetReader* reader = LIME_AUTORELEASE ([[AVAssetReader alloc] initWithAsset:asset error:NULL]);
		if (!reader || ![reader canAddOutput:output]) return nil;

		if (time > 0) {

			[reader setTimeRange:CMTimeRangeMake (CMTimeMakeWithSeconds (time, 1000000), kCMTimePositiveInfinity)];

		}

		[reader addOutput:output];
		return [reader startReading] ? reader : nil;

	}


	// Audio and video use separate readers of one asset. A reader with two
	// outputs stalls when only one of them is read, and VideoDecoder reads the
	// streams on different threads at different rates. AVAssetReader cannot
	// seek, so seeking replaces the readers with ones that start at the new time.
	class AVFVideoBackend : public VideoBackend {


		public:

			AVFVideoBackend ();
			~AVFVideoBackend ();

			virtual void Close ();
			virtual VideoDecodeResult DecodeAudio (std::vector<unsigned char>* pcm, double* time);
			virtual VideoDecodeResult DecodeVideo (VideoPlanes* planes, double* time, double* duration);
			virtual VideoDecodeResult DecodeVideoTexture (VideoTextureFrame** frame, double* time, double* duration);
			virtual unsigned int LockTexture (VideoTextureFrame* frame);
			virtual bool Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info);
			virtual void ReleaseTextureFrame (VideoTextureFrame* frame);
			virtual void ReleaseTextures ();
			virtual bool Seek (double time);
			virtual void SetTextureOutput (bool enabled);
			virtual bool SupportsTextures ();
			virtual void UnlockTexture (VideoTextureFrame* frame);

		private:

			CMSampleBufferRef CopyNextVideoSample ();
			void ForgetTextures ();
			void GetSampleTimes (CMSampleBufferRef sample, double* time, double* duration);
			bool OpenAudio (AVAssetTrack* track);
			bool OpenVideo (AVAssetTrack* track, int* width, int* height);
			bool StartAudio (double time);
			bool StartVideo (double time, bool textures);
			void StopAudio ();
			void StopVideo ();
			void UnlockVideo ();

			AVURLAsset* asset;
			double assetDuration;
			int audioChannels;
			AVAssetReaderTrackOutput* audioOutput;
			double audioPosition;
			AVAssetReader* audioReader;
			int audioSampleRate;
			AVAssetTrack* audioTrack;
			unsigned int copyFramebuffer;
			unsigned int copyTexture;
			int copyTextureHeight;
			int copyTextureWidth;
			bool framebufferEXT;
			double frameRate;
			CMSampleBufferRef lockedSample;
			CMSampleBufferRef pendingSample;
			unsigned int sourceFramebuffer;
			AVFTextureCacheRef textureCache;
			void* textureContext;
			std::atomic<bool> textureOutput;
			AVAssetReaderTrackOutput* videoOutput;
			double videoPosition;
			AVAssetReader* videoReader;
			bool videoTextures;
			AVAssetTrack* videoTrack;


	};


	AVFVideoBackend::AVFVideoBackend () {

		asset = nil;
		assetDuration = 0;
		audioChannels = 0;
		audioOutput = nil;
		audioPosition = 0;
		audioReader = nil;
		audioSampleRate = 0;
		audioTrack = nil;
		copyFramebuffer = 0;
		copyTexture = 0;
		copyTextureHeight = 0;
		copyTextureWidth = 0;
		framebufferEXT = false;
		frameRate = 0;
		lockedSample = NULL;
		pendingSample = NULL;
		sourceFramebuffer = 0;
		textureCache = NULL;
		textureContext = NULL;
		textureOutput = false;
		videoOutput = nil;
		videoPosition = 0;
		videoReader = nil;
		videoTextures = false;
		videoTrack = nil;

	}


	AVFVideoBackend::~AVFVideoBackend () {

		Close ();

	}


	void AVFVideoBackend::Close () {

		@autoreleasepool {

			StopAudio ();
			StopVideo ();

			LIME_RELEASE (audioTrack);
			audioTrack = nil;
			LIME_RELEASE (videoTrack);
			videoTrack = nil;
			LIME_RELEASE (asset);
			asset = nil;

		}

		assetDuration = 0;
		audioChannels = 0;
		audioPosition = 0;
		audioSampleRate = 0;
		frameRate = 0;
		videoPosition = 0;

	}


	CMSampleBufferRef AVFVideoBackend::CopyNextVideoSample () {

		if (pendingSample) {

			CMSampleBufferRef sample = pendingSample;
			pendingSample = NULL;
			return sample;

		}

		while (true) {

			CMSampleBufferRef sample = [videoOutput copyNextSampleBuffer];
			if (!sample || CMSampleBufferGetImageBuffer (sample)) return sample;

			// Skip sample buffers that carry no picture
			CFRelease (sample);

		}

	}


	VideoDecodeResult AVFVideoBackend::DecodeAudio (std::vector<unsigned char>* pcm, double* time) {

		if (!audioOutput) return audioTrack ? VIDEO_DECODE_ERROR : VIDEO_DECODE_END;

		@autoreleasepool {

			while (true) {

				CMSampleBufferRef sample = [audioOutput copyNextSampleBuffer];
				if (!sample) return GetEndResult (audioReader);

				CMBlockBufferRef buffer = CMSampleBufferGetDataBuffer (sample);
				size_t length = buffer ? CMBlockBufferGetDataLength (buffer) : 0;

				if (length == 0) {

					CFRelease (sample);
					continue;

				}

				size_t offset = pcm->size ();
				pcm->resize (offset + length);

				OSStatus status = CMBlockBufferCopyDataBytes (buffer, 0, length, pcm->data () + offset);
				double timestamp = GetSeconds (CMSampleBufferGetPresentationTimeStamp (sample), audioPosition);
				CFRelease (sample);

				if (status != kCMBlockBufferNoErr) {

					pcm->resize (offset);
					return VIDEO_DECODE_ERROR;

				}

				*time = timestamp;
				audioPosition = timestamp + (double)(length / (audioChannels * 2)) / audioSampleRate;

				return VIDEO_DECODE_OK;

			}

		}

	}


	VideoDecodeResult AVFVideoBackend::DecodeVideo (VideoPlanes* planes, double* time, double* duration) {

		UnlockVideo ();

		@autoreleasepool {

			// Texture output stopped, and VideoDecoder reads in memory until the
			// seek that follows, so continue from the next frame as NV12
			if (videoTextures) {

				StopVideo ();
				StartVideo (videoPosition, false);

			}

			if (!videoOutput) return videoTrack ? VIDEO_DECODE_ERROR : VIDEO_DECODE_END;

			CMSampleBufferRef sample = CopyNextVideoSample ();
			if (!sample) return GetEndResult (videoReader);

			CVPixelBufferRef image = CMSampleBufferGetImageBuffer (sample);

			if (!IsNV12 (image) || CVPixelBufferLockBaseAddress (image, kCVPixelBufferLock_ReadOnly) != kCVReturnSuccess) {

				CFRelease (sample);
				return VIDEO_DECODE_ERROR;

			}

			lockedSample = sample;

			const unsigned char* y = (const unsigned char*)CVPixelBufferGetBaseAddressOfPlane (image, 0);
			const unsigned char* uv = (const unsigned char*)CVPixelBufferGetBaseAddressOfPlane (image, 1);
			int width = (int)CVPixelBufferGetWidthOfPlane (image, 0);
			int height = (int)CVPixelBufferGetHeightOfPlane (image, 0);

			if (!y || !uv || width <= 0 || height <= 0) {

				UnlockVideo ();
				return VIDEO_DECODE_ERROR;

			}

			// The output format is video range, which full range sources are converted to
			planes->colorMatrix = GetColorMatrix (image, width, height);
			planes->fullRange = false;
			planes->width = width;
			planes->height = height;
			planes->y = y;
			planes->yStride = (int)CVPixelBufferGetBytesPerRowOfPlane (image, 0);
			planes->u = uv;
			planes->v = uv + 1;
			planes->uvStride = (int)CVPixelBufferGetBytesPerRowOfPlane (image, 1);
			planes->uvPixelStride = 2;

			GetSampleTimes (sample, time, duration);

			return VIDEO_DECODE_OK;

		}

	}


	VideoDecodeResult AVFVideoBackend::DecodeVideoTexture (VideoTextureFrame** frame, double* time, double* duration) {

		*frame = NULL;

		// VideoDecoder reads the next frame with DecodeVideo instead
		if (!SupportsTextures ()) return VIDEO_DECODE_OK;

		@autoreleasepool {

			CMSampleBufferRef sample = CopyNextVideoSample ();
			if (!sample) return GetEndResult (videoReader);

			CVPixelBufferRef image = CMSampleBufferGetImageBuffer (sample);

			if (!IsBGRA (image)) {

				CFRelease (sample);
				return VIDEO_DECODE_ERROR;

			}

			GetSampleTimes (sample, time, duration);
			*frame = new AVFTextureFrame (image);
			CFRelease (sample);

			return VIDEO_DECODE_OK;

		}

	}


	void AVFVideoBackend::ForgetTextures () {

		// Leaves the GL objects, which belong to a context that may be gone
		if (textureCache) {

			CFRelease (textureCache);
			textureCache = NULL;

		}

		copyFramebuffer = 0;
		copyTexture = 0;
		copyTextureHeight = 0;
		copyTextureWidth = 0;
		framebufferEXT = false;
		sourceFramebuffer = 0;
		textureContext = NULL;

	}


	void AVFVideoBackend::GetSampleTimes (CMSampleBufferRef sample, double* time, double* duration) {

		double sampleDuration = GetSeconds (CMSampleBufferGetDuration (sample), 0);

		*time = GetSeconds (CMSampleBufferGetPresentationTimeStamp (sample), videoPosition);
		*duration = sampleDuration > 0 ? sampleDuration : (frameRate > 0 ? 1.0 / frameRate : 0);
		videoPosition = *time + *duration;

	}


	unsigned int AVFVideoBackend::LockTexture (VideoTextureFrame* frame) {

		#ifdef LIME_VIDEO_AVF_TEXTURES
		AVFTextureFrame* textureFrame = (AVFTextureFrame*)frame;

		if (textureFrame->texture) {

			CFRelease (textureFrame->texture);
			textureFrame->texture = NULL;

		}

		int width = textureFrame->width;
		int height = textureFrame->height;

		@autoreleasepool {

			#ifdef HX_MACOS
			CGLContextObj context = CGLGetCurrentContext ();
			if (!context) return 0;

			if ((void*)context != textureContext) ForgetTextures ();
			textureContext = (void*)context;

			if (!sourceFramebuffer) {

				const char* version = (const char*)glGetString (GL_VERSION);
				int major = version ? atoi (version) : 0;
				const char* extensions = major < 3 ? (const char*)glGetString (GL_EXTENSIONS) : NULL;

				if (major >= 3 || HasExtension (extensions, "GL_ARB_framebuffer_object")) {

					framebufferEXT = false;

				} else if (HasExtension (extensions, "GL_EXT_framebuffer_object") && HasExtension (extensions, "GL_EXT_framebuffer_blit")) {

					framebufferEXT = true;

				} else {

					return 0;

				}

				copyFramebuffer = GenFramebuffer (framebufferEXT);
				sourceFramebuffer = GenFramebuffer (framebufferEXT);

			}

			if (!textureCache) {

				CGLPixelFormatObj pixelFormat = CGLGetPixelFormat (context);

				if (!pixelFormat || CVOpenGLTextureCacheCreate (kCFAllocatorDefault, NULL, context, pixelFormat, NULL, &textureCache) != kCVReturnSuccess) {

					textureCache = NULL;
					return 0;

				}

			}

			// OpenFL caches GL state, so everything changed here is restored
			GLint previousDrawFramebuffer = 0;
			GLint previousReadFramebuffer = 0;
			GLint previousRectangleTexture = 0;
			GLint previousTexture = 0;
			GLint previousUnpackBuffer = 0;
			glGetIntegerv (GL_DRAW_FRAMEBUFFER_BINDING, &previousDrawFramebuffer);
			glGetIntegerv (GL_READ_FRAMEBUFFER_BINDING, &previousReadFramebuffer);
			glGetIntegerv (GL_TEXTURE_BINDING_2D, &previousTexture);
			glGetIntegerv (GL_TEXTURE_BINDING_RECTANGLE_ARB, &previousRectangleTexture);
			glGetIntegerv (GL_PIXEL_UNPACK_BUFFER_BINDING, &previousUnpackBuffer);
			GLboolean scissorTest = glIsEnabled (GL_SCISSOR_TEST);

			// The cache gives a rectangle texture of the IOSurface, which is copied
			// into a 2D texture on the GPU
			CVOpenGLTextureRef texture = NULL;
			unsigned int name = 0;

			if (CVOpenGLTextureCacheCreateTextureFromImage (kCFAllocatorDefault, textureCache, textureFrame->buffer, NULL, &texture) == kCVReturnSuccess && texture) {

				if (!copyTexture || copyTextureWidth != width || copyTextureHeight != height) {

					if (!copyTexture) glGenTextures (1, &copyTexture);

					glBindTexture (GL_TEXTURE_2D, copyTexture);
					glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
					glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
					glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
					glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

					// A bound unpack buffer would be read as the initial contents
					if (previousUnpackBuffer) glBindBuffer (GL_PIXEL_UNPACK_BUFFER, 0);
					glTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
					if (previousUnpackBuffer) glBindBuffer (GL_PIXEL_UNPACK_BUFFER, previousUnpackBuffer);

					BindFramebuffer (framebufferEXT, GL_DRAW_FRAMEBUFFER, copyFramebuffer);
					FramebufferTexture2D (framebufferEXT, GL_DRAW_FRAMEBUFFER, GL_TEXTURE_2D, copyTexture);

					copyTextureWidth = width;
					copyTextureHeight = height;

				}

				GLenum target = CVOpenGLTextureGetTarget (texture);

				BindFramebuffer (framebufferEXT, GL_DRAW_FRAMEBUFFER, copyFramebuffer);
				BindFramebuffer (framebufferEXT, GL_READ_FRAMEBUFFER, sourceFramebuffer);
				FramebufferTexture2D (framebufferEXT, GL_READ_FRAMEBUFFER, target, CVOpenGLTextureGetName (texture));

				if (IsFramebufferComplete (framebufferEXT, GL_READ_FRAMEBUFFER) && IsFramebufferComplete (framebufferEXT, GL_DRAW_FRAMEBUFFER)) {

					// Rows of the copy start at the top of the picture, as uploaded
					// frames do. A flipped CoreVideo texture already starts there.
					bool topDown = CVOpenGLTextureIsFlipped (texture);

					if (scissorTest) glDisable (GL_SCISSOR_TEST);
					BlitFramebuffer (framebufferEXT, 0, 0, width, height, 0, topDown ? 0 : height, width, topDown ? height : 0);
					if (scissorTest) glEnable (GL_SCISSOR_TEST);

					name = copyTexture;

				}

				FramebufferTexture2D (framebufferEXT, GL_READ_FRAMEBUFFER, target, 0);

			}

			BindFramebuffer (framebufferEXT, GL_READ_FRAMEBUFFER, previousReadFramebuffer);
			BindFramebuffer (framebufferEXT, GL_DRAW_FRAMEBUFFER, previousDrawFramebuffer);
			glBindTexture (GL_TEXTURE_RECTANGLE_ARB, previousRectangleTexture);
			glBindTexture (GL_TEXTURE_2D, previousTexture);

			if (!name) {

				if (texture) CFRelease (texture);
				return 0;

			}

			// VideoToolbox can decode into the IOSurface again once the frame is
			// released, so send the copy to the GPU now
			glFlush ();
			#else
			EAGLContext* context = [EAGLContext currentContext];
			if (!context) return 0;

			if (LIME_BRIDGE (void*, context) != textureContext) ForgetTextures ();
			textureContext = LIME_BRIDGE (void*, context);

			if (!textureCache && CVOpenGLESTextureCacheCreate (kCFAllocatorDefault, NULL, context, NULL, &textureCache) != kCVReturnSuccess) {

				textureCache = NULL;
				return 0;

			}

			GLint previousTexture = 0;
			glGetIntegerv (GL_TEXTURE_BINDING_2D, &previousTexture);

			// The texture samples the IOSurface directly, swizzling BGRA to RGBA
			CVOpenGLESTextureRef texture = NULL;
			CVReturn result = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, textureCache, textureFrame->buffer, NULL, GL_TEXTURE_2D, GL_RGBA, width, height, GL_BGRA_EXT, GL_UNSIGNED_BYTE, 0, &texture);

			if (result != kCVReturnSuccess || !texture) {

				if (texture) CFRelease (texture);
				glBindTexture (GL_TEXTURE_2D, previousTexture);
				return 0;

			}

			// Without mipmaps, the default minification filter would leave the
			// texture incomplete
			GLuint name = CVOpenGLESTextureGetName (texture);
			glBindTexture (GL_TEXTURE_2D, name);
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
			glBindTexture (GL_TEXTURE_2D, previousTexture);
			#endif

			textureFrame->texture = texture;
			return name;

		}
		#else
		return 0;
		#endif

	}


	// The synchronous asset and track properties are deprecated in favor of
	// asynchronous loading, but Open has to wait for them anyway

	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"

	bool AVFVideoBackend::Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info) {

		Close ();

		if (!path || !path[0]) return false;

		@autoreleasepool {

			NSURL* url = GetURL (path);
			if (!url) return false;

			// Precise timing makes the duration and the readers' time ranges exact for formats such as MP3
			asset = [[AVURLAsset alloc] initWithURL:url options:@{ AVURLAssetPreferPreciseDurationAndTimingKey: @YES }];

			NSArray* audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
			NSArray* videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
			assetDuration = GetSeconds ([asset duration], 0);

			// VideoToolbox decodes in hardware whenever it can and AVAssetReader
			// has no option to prevent it, so hardwareDecoding is only a hint
			int width = 0;
			int height = 0;

			info->hasVideo = [videoTracks count] > 0 && OpenVideo ([videoTracks objectAtIndex:0], &width, &height);
			info->hasAudio = [audioTracks count] > 0 && OpenAudio ([audioTracks objectAtIndex:0]);

			if (!info->hasVideo && !info->hasAudio) return false;

			info->audioChannels = audioChannels;
			info->audioSampleRate = audioSampleRate;
			info->duration = assetDuration;
			info->frameRate = frameRate;
			info->width = width;
			info->height = height;

			return true;

		}

	}


	bool AVFVideoBackend::OpenAudio (AVAssetTrack* track) {

		NSArray* formats = [track formatDescriptions];
		if ([formats count] == 0) return false;

		CMAudioFormatDescriptionRef format = LIME_BRIDGE (CMAudioFormatDescriptionRef, [formats objectAtIndex:0]);
		const AudioStreamBasicDescription* description = CMAudioFormatDescriptionGetStreamBasicDescription (format);

		// HE-AAC describes its base layer, at half the decoded sample rate
		const AudioFormatListItem* richest = CMAudioFormatDescriptionGetRichestDecodableFormat (format);
		if (richest && richest->mASBD.mSampleRate > 0) description = &richest->mASBD;

		if (!description || description->mSampleRate <= 0) return false;

		audioChannels = description->mChannelsPerFrame == 1 ? 1 : 2;
		audioSampleRate = (int)(description->mSampleRate + 0.5);
		audioTrack = LIME_RETAIN (track);

		if (StartAudio (0)) return true;

		LIME_RELEASE (audioTrack);
		audioTrack = nil;
		audioChannels = 0;
		audioSampleRate = 0;

		return false;

	}


	bool AVFVideoBackend::OpenVideo (AVAssetTrack* track, int* width, int* height) {

		videoTrack = LIME_RETAIN (track);
		frameRate = [track nominalFrameRate];

		if (StartVideo (0, textureOutput)) {

			// Decode the first frame for its size, which can differ from the
			// track's natural size
			pendingSample = CopyNextVideoSample ();
			CVImageBufferRef image = pendingSample ? CMSampleBufferGetImageBuffer (pendingSample) : NULL;

			if (image && videoTextures && IsBGRA (image)) {

				*width = (int)CVPixelBufferGetWidth (image);
				*height = (int)CVPixelBufferGetHeight (image);

			} else if (image && !videoTextures && IsNV12 (image)) {

				*width = (int)CVPixelBufferGetWidthOfPlane (image, 0);
				*height = (int)CVPixelBufferGetHeightOfPlane (image, 0);

			}

			if (*width > 0 && *height > 0) {

				if (frameRate <= 0) {

					double sampleDuration = GetSeconds (CMSampleBufferGetDuration (pendingSample), 0);
					if (sampleDuration > 0) frameRate = 1.0 / sampleDuration;

				}

				return true;

			}

		}

		StopVideo ();

		LIME_RELEASE (videoTrack);
		videoTrack = nil;
		frameRate = 0;
		*width = 0;
		*height = 0;

		return false;

	}

	#pragma clang diagnostic pop


	void AVFVideoBackend::ReleaseTextureFrame (VideoTextureFrame* frame) {

		delete frame;

	}


	void AVFVideoBackend::ReleaseTextures () {

		#ifdef LIME_VIDEO_AVF_TEXTURES
		#ifdef HX_MACOS
		// GL names only mean these objects in the context that made them
		if (textureContext && (void*)CGLGetCurrentContext () == textureContext) {

			if (copyTexture) glDeleteTextures (1, &copyTexture);
			if (copyFramebuffer) DeleteFramebuffer (framebufferEXT, copyFramebuffer);
			if (sourceFramebuffer) DeleteFramebuffer (framebufferEXT, sourceFramebuffer);

		}
		#endif
		#endif

		ForgetTextures ();

	}


	bool AVFVideoBackend::Seek (double time) {

		@autoreleasepool {

			// A seek past the end reads the last frames, which an accurate seek drops
			double start = time - SEEK_PREROLL;
			if (assetDuration > 0 && start > assetDuration - SEEK_PREROLL) start = assetDuration - SEEK_PREROLL;
			if (start < 0) start = 0;

			bool success = true;

			if (videoTrack) {

				StopVideo ();
				success = StartVideo (start, textureOutput) && success;

			}

			if (audioTrack) {

				StopAudio ();
				success = StartAudio (start) && success;

			}

			return success;

		}

	}


	void AVFVideoBackend::SetTextureOutput (bool enabled) {

		// This can be called while the video thread decodes, so the video reader
		// only changes format at the next Open or Seek
		#ifdef LIME_VIDEO_AVF_TEXTURES
		textureOutput = enabled;
		#endif

	}


	bool AVFVideoBackend::StartAudio (double time) {

		// The channel layout lets AVFoundation downmix multichannel audio
		AudioChannelLayout layout;
		memset (&layout, 0, sizeof (layout));
		layout.mChannelLayoutTag = (audioChannels == 1) ? kAudioChannelLayoutTag_Mono : kAudioChannelLayoutTag_Stereo;

		NSDictionary* settings = @{
			AVFormatIDKey: @(kAudioFormatLinearPCM),
			AVSampleRateKey: @((double)audioSampleRate),
			AVNumberOfChannelsKey: @(audioChannels),
			AVChannelLayoutKey: [NSData dataWithBytes:&layout length:sizeof (layout)],
			AVLinearPCMBitDepthKey: @16,
			AVLinearPCMIsBigEndianKey: @NO,
			AVLinearPCMIsFloatKey: @NO,
			AVLinearPCMIsNonInterleaved: @NO
		};

		// AVFoundation throws instead of failing for some assets and settings,
		// such as remote URLs on some versions
		@try {

			audioOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioTrack outputSettings:settings];
			[audioOutput setAlwaysCopiesSampleData:NO];
			audioReader = LIME_RETAIN (StartReader (asset, audioOutput, time));

		} @catch (NSException* exception) {}

		audioPosition = time;

		if (!audioReader) StopAudio ();
		return audioReader != nil;

	}


	bool AVFVideoBackend::StartVideo (double time, bool textures) {

		NSDictionary* settings = @{
			LIME_BRIDGE (NSString*, kCVPixelBufferPixelFormatTypeKey): @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
		};

		#ifdef LIME_VIDEO_AVF_TEXTURES
		if (textures) {

			#ifdef HX_MACOS
			CFStringRef compatibilityKey = kCVPixelBufferOpenGLCompatibilityKey;
			#else
			CFStringRef compatibilityKey = kCVPixelBufferOpenGLESCompatibilityKey;
			#endif

			// VideoToolbox converts to BGRA on the GPU, into IOSurfaces that the
			// texture caches share with OpenGL
			settings = @{
				LIME_BRIDGE (NSString*, kCVPixelBufferPixelFormatTypeKey): @(kCVPixelFormatType_32BGRA),
				LIME_BRIDGE (NSString*, kCVPixelBufferIOSurfacePropertiesKey): @{},
				LIME_BRIDGE (NSString*, compatibilityKey): @YES
			};

		}
		#else
		textures = false;
		#endif

		@try {

			videoOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:settings];
			[videoOutput setAlwaysCopiesSampleData:NO];
			videoReader = LIME_RETAIN (StartReader (asset, videoOutput, time));

		} @catch (NSException* exception) {}

		videoPosition = time;

		if (!videoReader) {

			StopVideo ();

			// Decode into memory when the texture output is not accepted
			return textures ? StartVideo (time, false) : false;

		}

		videoTextures = textures;
		return true;

	}


	void AVFVideoBackend::StopAudio () {

		if (audioReader) {

			[audioReader cancelReading];
			LIME_RELEASE (audioReader);
			audioReader = nil;

		}

		LIME_RELEASE (audioOutput);
		audioOutput = nil;

	}


	void AVFVideoBackend::StopVideo () {

		UnlockVideo ();

		if (pendingSample) {

			CFRelease (pendingSample);
			pendingSample = NULL;

		}

		if (videoReader) {

			[videoReader cancelReading];
			LIME_RELEASE (videoReader);
			videoReader = nil;

		}

		LIME_RELEASE (videoOutput);
		videoOutput = nil;
		videoTextures = false;

	}


	bool AVFVideoBackend::SupportsTextures () {

		return videoTextures && textureOutput;

	}


	void AVFVideoBackend::UnlockTexture (VideoTextureFrame* frame) {

		AVFTextureFrame* textureFrame = (AVFTextureFrame*)frame;

		if (textureFrame->texture) {

			CFRelease (textureFrame->texture);
			textureFrame->texture = NULL;

		}

		// Lets the cache reuse the textures of released frames
		#if defined (LIME_VIDEO_AVF_TEXTURES) && defined (HX_MACOS)
		if (textureCache) CVOpenGLTextureCacheFlush (textureCache, 0);
		#elif defined (LIME_VIDEO_AVF_TEXTURES)
		if (textureCache) CVOpenGLESTextureCacheFlush (textureCache, 0);
		#endif

	}


	void AVFVideoBackend::UnlockVideo () {

		if (lockedSample) {

			CVPixelBufferUnlockBaseAddress (CMSampleBufferGetImageBuffer (lockedSample), kCVPixelBufferLock_ReadOnly);
			CFRelease (lockedSample);
			lockedSample = NULL;

		}

	}


	VideoBackend* VideoBackend::Create () {

		return new AVFVideoBackend ();

	}


	bool VideoBackend::IsSupported () {

		return true;

	}


}


#endif
