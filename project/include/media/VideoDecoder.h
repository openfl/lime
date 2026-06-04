#ifndef LIME_MEDIA_VIDEO_DECODER_H
#define LIME_MEDIA_VIDEO_DECODER_H


namespace lime {


	struct VideoDecoderState;


	class VideoDecoder {

		public:

			VideoDecoder ();
			~VideoDecoder ();

			static bool IsSupported ();

			void Close ();
			int GetAudioBitsPerSample ();
			int GetAudioChannelCount ();
			int GetAudioSampleRate ();
			int GetDuration ();
			float GetFrameRate ();
			int GetHeight ();
			int GetVideoPosition ();
			int GetWidth ();
			bool Load (const char* path);
			int ReadAudio (unsigned char* outBuffer, int bytesLength);
			bool ReadRGBAFrame (unsigned char* outBuffer, int bufferSize);
			void Seek (int targetMs);
			void SetHardwareDecodingEnabled (bool enabled);

		private:

			VideoDecoderState* state;

	};


}


#endif
