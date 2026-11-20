#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#include <TargetConditionals.h>

#include <media/VoiceCapture.h>


namespace lime {


	#if !TARGET_OS_TV
	// The voice processing I/O unit cancels echo and suppresses noise together,
	// and has its own automatic gain control
	class VoiceProcessingVoiceCapture : public VoiceCapture {


		public:

			VoiceProcessingVoiceCapture (int channels, int bitsPerSample, int bufferFrames) : VoiceCapture (channels, bitsPerSample, bufferFrames) {

				closed = false;
				started = false;
				unit = NULL;

				#ifdef IPHONE
				previousCategory = nil;
				previousMode = nil;
				previousOptions = 0;
				#endif

			}


			~VoiceProcessingVoiceCapture () {

				Close ();

			}


			void Close () {

				if (closed) return;
				closed = true;

				if (unit) {

					if (started) AudioOutputUnitStop (unit);
					AudioUnitUninitialize (unit);
					AudioComponentInstanceDispose (unit);
					unit = NULL;

				}

				started = false;
				SetDisconnected ();

				#ifdef IPHONE
				// The application's own audio session comes back
				if (previousCategory) {

					[[AVAudioSession sharedInstance] setCategory:previousCategory mode:previousMode options:previousOptions error:nil];
					[previousCategory release];
					[previousMode release];
					previousCategory = nil;
					previousMode = nil;

				}
				#endif

			}


			bool Open (int sampleRate, int requested) {

				#ifdef IPHONE
				// Voice processing needs a session that plays and records
				AVAudioSession* session = [AVAudioSession sharedInstance];
				previousCategory = [[session category] retain];
				previousMode = [[session mode] retain];
				previousOptions = [session categoryOptions];

				AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionMixWithOthers;
				if (![session setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeVoiceChat options:options error:nil]) return false;
				[session setActive:YES error:nil];
				#endif

				AudioComponentDescription description = {};
				description.componentType = kAudioUnitType_Output;
				description.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
				description.componentManufacturer = kAudioUnitManufacturer_Apple;

				AudioComponent component = AudioComponentFindNext (NULL, &description);
				if (!component || AudioComponentInstanceNew (component, &unit) != noErr) {

					unit = NULL;
					return false;

				}

				UInt32 enable = 1;
				if (AudioUnitSetProperty (unit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enable, sizeof (enable)) != noErr) return false;

				// Mono, as the unit processes a single voice, and copied to both channels
				// for stereo
				AudioStreamBasicDescription format = {};
				format.mSampleRate = sampleRate;
				format.mFormatID = kAudioFormatLinearPCM;
				format.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
				format.mFramesPerPacket = 1;
				format.mChannelsPerFrame = 1;
				format.mBitsPerChannel = 16;
				format.mBytesPerFrame = 2;
				format.mBytesPerPacket = 2;

				if (AudioUnitSetProperty (unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &format, sizeof (format)) != noErr) return false;
				if (AudioUnitSetProperty (unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &format, sizeof (format)) != noErr) return false;

				// The unit plays too, and it is given silence
				AURenderCallbackStruct render = { RenderCallback, this };
				if (AudioUnitSetProperty (unit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &render, sizeof (render)) != noErr) return false;

				AURenderCallbackStruct input = { InputCallback, this };
				if (AudioUnitSetProperty (unit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &input, sizeof (input)) != noErr) return false;

				UInt32 bypass = (requested & (VOICE_CAPTURE_ECHO_CANCELLATION | VOICE_CAPTURE_NOISE_SUPPRESSION)) ? 0 : 1;
				AudioUnitSetProperty (unit, kAUVoiceIOProperty_BypassVoiceProcessing, kAudioUnitScope_Global, 0, &bypass, sizeof (bypass));

				UInt32 gain = (requested & VOICE_CAPTURE_AUTO_GAIN) ? 1 : 0;
				AudioUnitSetProperty (unit, kAUVoiceIOProperty_VoiceProcessingEnableAGC, kAudioUnitScope_Global, 0, &gain, sizeof (gain));

				// The unit lowers all other sound while it runs, the application's own
				// included, so it is asked to lower it as little as it can
				#if (defined (__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 140000) || (defined (__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 170000)
				if (@available (macOS 14.0, iOS 17.0, *)) {

					AUVoiceIOOtherAudioDuckingConfiguration ducking = { false, kAUVoiceIOOtherAudioDuckingLevelMin };
					AudioUnitSetProperty (unit, kAUVoiceIOProperty_OtherAudioDuckingConfiguration, kAudioUnitScope_Global, 0, &ducking, sizeof (ducking));

				}
				#endif

				if (AudioUnitInitialize (unit) != noErr) return false;

				// Read back what the unit took
				int applied = 0;
				UInt32 size = sizeof (bypass);

				if (AudioUnitGetProperty (unit, kAUVoiceIOProperty_BypassVoiceProcessing, kAudioUnitScope_Global, 0, &bypass, &size) == noErr && !bypass) {

					applied |= VOICE_CAPTURE_ECHO_CANCELLATION | VOICE_CAPTURE_NOISE_SUPPRESSION;

				}

				size = sizeof (gain);

				if (AudioUnitGetProperty (unit, kAUVoiceIOProperty_VoiceProcessingEnableAGC, kAudioUnitScope_Global, 0, &gain, &size) == noErr && gain) {

					applied |= VOICE_CAPTURE_AUTO_GAIN;

				}

				SetProcessing (applied);
				return true;

			}


			bool Start () {

				if (!unit) return false;
				if (!started) started = AudioOutputUnitStart (unit) == noErr;
				return started;

			}


			void Stop () {

				if (unit && started) AudioOutputUnitStop (unit);
				started = false;

			}


		private:

			static OSStatus InputCallback (void* data, AudioUnitRenderActionFlags* flags, const AudioTimeStamp* timeStamp, UInt32 bus, UInt32 frames, AudioBufferList* unused) {

				VoiceProcessingVoiceCapture* capture = (VoiceProcessingVoiceCapture*)data;
				if (capture->samples.size () < frames) capture->samples.resize (frames);

				AudioBufferList list;
				list.mNumberBuffers = 1;
				list.mBuffers[0].mNumberChannels = 1;
				list.mBuffers[0].mDataByteSize = frames * 2;
				list.mBuffers[0].mData = &capture->samples[0];

				OSStatus status = AudioUnitRender (capture->unit, flags, timeStamp, 1, frames, &list);
				if (status == noErr) capture->Write (&capture->samples[0], (int)frames, 1);
				return status;

			}


			static OSStatus RenderCallback (void* data, AudioUnitRenderActionFlags* flags, const AudioTimeStamp* timeStamp, UInt32 bus, UInt32 frames, AudioBufferList* buffers) {

				for (UInt32 i = 0; i < buffers->mNumberBuffers; i++) {

					memset (buffers->mBuffers[i].mData, 0, buffers->mBuffers[i].mDataByteSize);

				}

				*flags |= kAudioUnitRenderAction_OutputIsSilence;
				return noErr;

			}


			bool closed;
			std::vector<int16_t> samples;
			bool started;
			AudioUnit unit;

			#ifdef IPHONE
			NSString* previousCategory;
			NSString* previousMode;
			AVAudioSessionCategoryOptions previousOptions;
			#endif


	};
	#endif


	VoiceCapture* VoiceCapture::Open (const char* deviceName, int sampleRate, int channels, int bitsPerSample, int bufferFrames, int processing) {

		#if TARGET_OS_TV
		return NULL;
		#else
		if (channels < 1 || channels > 2 || (bitsPerSample != 8 && bitsPerSample != 16) || sampleRate <= 0) return NULL;

		// The voice processing unit uses the system's default input device
		VoiceProcessingVoiceCapture* capture = new VoiceProcessingVoiceCapture (channels, bitsPerSample, bufferFrames);

		if (!capture->Open (sampleRate, processing)) {

			delete capture;
			return NULL;

		}

		return capture;
		#endif

	}


}
