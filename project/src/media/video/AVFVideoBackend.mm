#include <media/VideoDecoder.h>


#ifdef LIME_VIDEO_AVFOUNDATION


#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
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


	static bool IsNV12 (CVImageBufferRef image) {

		return CFGetTypeID (image) == CVPixelBufferGetTypeID () && CVPixelBufferGetPixelFormatType (image) == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange && CVPixelBufferGetPlaneCount (image) >= 2;

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
			virtual bool Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info);
			virtual bool Seek (double time);

		private:

			CMSampleBufferRef CopyNextVideoSample ();
			bool OpenAudio (AVAssetTrack* track);
			bool OpenVideo (AVAssetTrack* track, int* width, int* height);
			bool StartAudio (double time);
			bool StartVideo (double time);
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
			double frameRate;
			CMSampleBufferRef lockedSample;
			CMSampleBufferRef pendingSample;
			AVAssetReaderTrackOutput* videoOutput;
			double videoPosition;
			AVAssetReader* videoReader;
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
		frameRate = 0;
		lockedSample = NULL;
		pendingSample = NULL;
		videoOutput = nil;
		videoPosition = 0;
		videoReader = nil;
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

		if (!videoOutput) return videoTrack ? VIDEO_DECODE_ERROR : VIDEO_DECODE_END;

		@autoreleasepool {

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

			double sampleDuration = GetSeconds (CMSampleBufferGetDuration (sample), 0);

			*time = GetSeconds (CMSampleBufferGetPresentationTimeStamp (sample), videoPosition);
			*duration = sampleDuration > 0 ? sampleDuration : (frameRate > 0 ? 1.0 / frameRate : 0);
			videoPosition = *time + *duration;

			return VIDEO_DECODE_OK;

		}

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

		if (StartVideo (0)) {

			// Decode the first frame for its size, which can differ from the
			// track's natural size
			pendingSample = CopyNextVideoSample ();
			CVImageBufferRef image = pendingSample ? CMSampleBufferGetImageBuffer (pendingSample) : NULL;

			if (image && IsNV12 (image)) {

				*width = (int)CVPixelBufferGetWidthOfPlane (image, 0);
				*height = (int)CVPixelBufferGetHeightOfPlane (image, 0);

				if (frameRate <= 0) {

					double sampleDuration = GetSeconds (CMSampleBufferGetDuration (pendingSample), 0);
					if (sampleDuration > 0) frameRate = 1.0 / sampleDuration;

				}

				if (*width > 0 && *height > 0) return true;

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


	bool AVFVideoBackend::Seek (double time) {

		@autoreleasepool {

			// A seek past the end reads the last frames, which an accurate seek drops
			double start = time - SEEK_PREROLL;
			if (assetDuration > 0 && start > assetDuration - SEEK_PREROLL) start = assetDuration - SEEK_PREROLL;
			if (start < 0) start = 0;

			bool success = true;

			if (videoTrack) {

				StopVideo ();
				success = StartVideo (start) && success;

			}

			if (audioTrack) {

				StopAudio ();
				success = StartAudio (start) && success;

			}

			return success;

		}

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


	bool AVFVideoBackend::StartVideo (double time) {

		NSDictionary* settings = @{
			LIME_BRIDGE (NSString*, kCVPixelBufferPixelFormatTypeKey): @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
		};

		@try {

			videoOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:settings];
			[videoOutput setAlwaysCopiesSampleData:NO];
			videoReader = LIME_RETAIN (StartReader (asset, videoOutput, time));

		} @catch (NSException* exception) {}

		videoPosition = time;

		if (!videoReader) StopVideo ();
		return videoReader != nil;

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
