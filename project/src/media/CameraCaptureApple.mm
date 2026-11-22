#include <media/CameraCapture.h>

#ifdef LIME_VIDEO_AVFOUNDATION

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#include <math.h>


namespace lime {


	class AVFCameraCapture;


}


@interface LimeCameraCaptureDelegate : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {

	@public lime::AVFCameraCapture* capture;

}

@end


namespace lime {


	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"

	// Every camera, the default one first. devicesWithMediaType lists external
	// cameras on every macOS and iOS version Lime supports, where discovery
	// sessions name their device types differently from one version to the next.
	static NSArray* GetCameraDevices () {

		NSMutableArray* devices = [NSMutableArray array];
		AVCaptureDevice* defaultDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		if (defaultDevice) [devices addObject:defaultDevice];

		for (AVCaptureDevice* device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {

			if (![device isEqual:defaultDevice]) [devices addObject:device];

		}

		return devices;

	}

	#pragma clang diagnostic pop


	class AVFCameraCapture : public CameraCapture {


		public:

			AVFCameraCapture () {

				delegate = nil;
				device = nil;
				disconnectObserver = nil;
				errorObserver = nil;
				input = nil;
				output = nil;
				queue = NULL;
				session = nil;

			}


			~AVFCameraCapture () {

				Close ();

			}


			void Close () {

				if (session) {

					[session stopRunning];

				}

				if (output) {

					[output setSampleBufferDelegate:nil queue:NULL];

				}

				// Frames already queued finish before the queue is let go
				if (queue) {

					dispatch_sync (queue, ^{});
					dispatch_release (queue);
					queue = NULL;

				}

				NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
				if (disconnectObserver) [center removeObserver:disconnectObserver];
				if (errorObserver) [center removeObserver:errorObserver];
				disconnectObserver = nil;
				errorObserver = nil;

				if (delegate) delegate->capture = NULL;
				[delegate release];
				[output release];
				[input release];
				[session release];
				[device release];
				delegate = nil;
				output = nil;
				input = nil;
				session = nil;
				device = nil;

				SetDisconnected ();

			}


			bool Open (const char* id, int requestedWidth, int requestedHeight, double requestedFrameRate) {

				NSArray* devices = GetCameraDevices ();
				NSString* wanted = id ? [NSString stringWithUTF8String:id] : nil;

				for (AVCaptureDevice* candidate in devices) {

					if (!wanted || [[candidate uniqueID] isEqualToString:wanted]) {

						device = [candidate retain];
						break;

					}

				}

				if (!device) return false;

				NSError* error = nil;
				input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
				if (!input) return false;

				session = [[AVCaptureSession alloc] init];
				[session beginConfiguration];

				if (![session canAddInput:input]) {

					[session commitConfiguration];
					return false;

				}

				[session addInput:input];
				ChooseFormat (requestedWidth, requestedHeight, requestedFrameRate);

				// Full range NV12, which is what cameras give without converting
				output = [[AVCaptureVideoDataOutput alloc] init];
				// Filled as AVFVideoBackend fills its settings: the toolchain's Objective-C++ rejects a dictionary
				// literal keyed by a cast, and the key's cast differs with and without ARC
				NSMutableDictionary* settings = [NSMutableDictionary dictionary];
				#if __has_feature(objc_arc)
				[settings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey];
				#else
				[settings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
				#endif
				output.videoSettings = settings;
				output.alwaysDiscardsLateVideoFrames = YES;

				delegate = [[LimeCameraCaptureDelegate alloc] init];
				delegate->capture = this;
				queue = dispatch_queue_create ("org.haxe.lime.camera", DISPATCH_QUEUE_SERIAL);
				[output setSampleBufferDelegate:delegate queue:queue];

				if (![session canAddOutput:output]) {

					[session commitConfiguration];
					return false;

				}

				[session addOutput:output];
				[session commitConfiguration];

				NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
				AVCaptureDevice* watched = device;

				disconnectObserver = [[center addObserverForName:AVCaptureDeviceWasDisconnectedNotification object:watched queue:nil usingBlock:^(NSNotification* notification) {

					SetDisconnected ();

				}] retain];

				errorObserver = [[center addObserverForName:AVCaptureSessionRuntimeErrorNotification object:session queue:nil usingBlock:^(NSNotification* notification) {

					SetDisconnected ();

				}] retain];

				return width > 0 && height > 0;

			}


			void OnSampleBuffer (CMSampleBufferRef sampleBuffer) {

				CVImageBufferRef image = CMSampleBufferGetImageBuffer (sampleBuffer);
				if (!image || CVPixelBufferGetPlaneCount (image) < 2) return;

				if (CVPixelBufferLockBaseAddress (image, kCVPixelBufferLock_ReadOnly) != kCVReturnSuccess) return;

				VideoPlanes planes;
				CFTypeRef matrix = CVBufferGetAttachment (image, kCVImageBufferYCbCrMatrixKey, NULL);
				planes.colorMatrix = (matrix && CFEqual (matrix, kCVImageBufferYCbCrMatrix_ITU_R_709_2)) ? VIDEO_COLOR_MATRIX_BT709 : VIDEO_COLOR_MATRIX_BT601;
				planes.fullRange = CVPixelBufferGetPixelFormatType (image) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
				planes.width = (int)CVPixelBufferGetWidthOfPlane (image, 0);
				planes.height = (int)CVPixelBufferGetHeightOfPlane (image, 0);
				planes.transfer = VIDEO_COLOR_TRANSFER_SDR;
				planes.y = (const unsigned char*)CVPixelBufferGetBaseAddressOfPlane (image, 0);
				planes.yStride = (int)CVPixelBufferGetBytesPerRowOfPlane (image, 0);
				planes.u = (const unsigned char*)CVPixelBufferGetBaseAddressOfPlane (image, 1);
				planes.v = planes.u + 1;
				planes.uvPixelStride = 2;
				planes.uvStride = (int)CVPixelBufferGetBytesPerRowOfPlane (image, 1);

				if (planes.y && planes.u) PushFrame (&planes, CMTimeGetSeconds (CMSampleBufferGetPresentationTimeStamp (sampleBuffer)));

				CVPixelBufferUnlockBaseAddress (image, kCVPixelBufferLock_ReadOnly);

			}


			bool Start () {

				if (!session) return false;
				if (![session isRunning]) [session startRunning];
				return [session isRunning];

			}


			void Stop () {

				if (session && [session isRunning]) [session stopRunning];

			}


		private:

			// The format nearest the size asked for, then the nearest rate at or above
			// the one asked for
			void ChooseFormat (int requestedWidth, int requestedHeight, double requestedFrameRate) {

				AVCaptureDeviceFormat* best = nil;
				AVFrameRateRange* bestRange = nil;
				double bestScore = 0;

				for (AVCaptureDeviceFormat* format in [device formats]) {

					CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions (format.formatDescription);

					for (AVFrameRateRange* range in format.videoSupportedFrameRateRanges) {

						double rate = requestedFrameRate;
						if (rate > range.maxFrameRate) rate = range.maxFrameRate;
						if (rate < range.minFrameRate) rate = range.minFrameRate;

						double score = fabs ((double)dimensions.width - requestedWidth) + fabs ((double)dimensions.height - requestedHeight);
						score = score * 1000 + (rate + 0.5 < requestedFrameRate ? (requestedFrameRate - rate) * 10 : rate - requestedFrameRate);

						if (!best || score < bestScore) {

							best = format;
							bestRange = range;
							bestScore = score;

						}

					}

				}

				if (!best) return;

				CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions (best.formatDescription);
				double rate = requestedFrameRate;
				if (rate > bestRange.maxFrameRate) rate = bestRange.maxFrameRate;
				if (rate < bestRange.minFrameRate) rate = bestRange.minFrameRate;

				if ([device lockForConfiguration:nil]) {

					device.activeFormat = best;

					// Frame durations are set within the range the format has
					CMTime duration = CMTimeMakeWithSeconds (1.0 / rate, 1000000);
					if (CMTimeCompare (duration, bestRange.minFrameDuration) < 0) duration = bestRange.minFrameDuration;
					if (CMTimeCompare (duration, bestRange.maxFrameDuration) > 0) duration = bestRange.maxFrameDuration;
					device.activeVideoMinFrameDuration = duration;
					device.activeVideoMaxFrameDuration = duration;

					[device unlockForConfiguration];

				}

				width = dimensions.width;
				height = dimensions.height;
				frameRate = rate;

			}


			LimeCameraCaptureDelegate* delegate;
			AVCaptureDevice* device;
			id disconnectObserver;
			id errorObserver;
			AVCaptureDeviceInput* input;
			AVCaptureVideoDataOutput* output;
			dispatch_queue_t queue;
			AVCaptureSession* session;


	};


	bool CameraCapture::GetDevices (std::vector<CameraDeviceInfo>* devices) {

		@autoreleasepool {

			for (AVCaptureDevice* device in GetCameraDevices ()) {

				CameraDeviceInfo info;
				info.id = [[device uniqueID] UTF8String];
				info.name = [[device localizedName] UTF8String];

				switch ([device position]) {

					case AVCaptureDevicePositionFront: info.position = CAMERA_POSITION_FRONT; break;
					case AVCaptureDevicePositionBack: info.position = CAMERA_POSITION_BACK; break;
					default: info.position = CAMERA_POSITION_UNKNOWN; break;

				}

				devices->push_back (info);

			}

		}

		return true;

	}


	int CameraCapture::GetPermissionStatus () {

		switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {

			case AVAuthorizationStatusAuthorized: return 1;
			case AVAuthorizationStatusDenied:
			case AVAuthorizationStatusRestricted: return 2;
			default: return 0;

		}

	}


	bool CameraCapture::IsSupported () {

		return true;

	}


	CameraCapture* CameraCapture::Open (const char* id, int width, int height, double frameRate) {

		@autoreleasepool {

			AVFCameraCapture* capture = new AVFCameraCapture ();

			if (!capture->Open (id, width > 0 ? width : 640, height > 0 ? height : 480, frameRate > 0 ? frameRate : 30)) {

				delete capture;
				return NULL;

			}

			return capture;

		}

	}


	void CameraCapture::RequestPermission () {

		// The answer is polled with GetPermissionStatus
		[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {}];

	}


}


@implementation LimeCameraCaptureDelegate

- (void)captureOutput:(AVCaptureOutput*)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection {

	if (capture) capture->OnSampleBuffer (sampleBuffer);

}

@end


#endif
