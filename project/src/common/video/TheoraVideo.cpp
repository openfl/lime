#include "renderer/common/SimpleSurface.h"
#include "renderer/common/HardwareContext.h"
#include <Display.h>
#include <Graphics.h>
#include <Video.h>
#include <Sound.h>
#include <theoraplay.h>

#define AUDIO_BUFFER_FRAMES 4096
#define AUDIO_OUT_CHANNELS 2

namespace lime
{

   class VideoSurface : public SimpleSurface
   {
   public:
      VideoSurface(int inW, int inH)
         : SimpleSurface(inW, inH, pfARGB)
      {
         Clear();
      }

      void Clear()
      {
         memset(mBase, mWidth * mHeight * 4, 0);
      }

      void RenderTo(const unsigned int *pixels, int width, int height, bool smoothing)
      {
         if (width == mWidth && height == mHeight)
         {
            // grab scanlines
            for (int y = 0; y < height; y++)
            {
               memcpy(&mBase[y * mWidth],
                  &pixels[y * width],
                  width * sizeof(unsigned int));
            }
         }
         else if (smoothing)
         {
            // bilinear filtering
            float xRatio = (width - 1) / (float)mWidth;
            float yRatio = (height - 1) / (float)mHeight;
            float xDiff, yDiff;
            uint8 *buffer = mBase;
            for (int i = 0; i < mHeight; i++)
            {
               for (int j = 0; j < mWidth; j++)
               {
                  int x = (int)(xRatio * j);
                  int y = (int)(yRatio * i);
                  xDiff = (xRatio * j) - x;
                  yDiff = (yRatio * i) - y;
                  int index = y * width + x;

                  int A = pixels[index];
                  int B = pixels[index + 1];
                  int C = pixels[index + width];
                  int D = pixels[index + width + 1];

                  float a = (1 - xDiff) * (1 - yDiff);
                  float b = xDiff * (1 - yDiff);
                  float c = yDiff * (1 - xDiff);
                  float d = (xDiff * yDiff);

                  // blue
                  *(buffer++) = (A & 0xFF) * a +
                                (B & 0xFF) * b +
                                (C & 0xFF) * c +
                                (D & 0xFF) * d;

                  // green
                  *(buffer++) = (A >> 8 & 0xFF) * a +
                                (B >> 8 & 0xFF) * b +
                                (C >> 8 & 0xFF) * c +
                                (D >> 8 & 0xFF) * d;

                  // red
                  *(buffer++) = (A >> 16 & 0xFF) * a +
                                (B >> 16 & 0xFF) * b +
                                (C >> 16 & 0xFF) * c +
                                (D >> 16 & 0xFF) * d;
                  
                  // alpha
                  *(buffer++) = 0xFF;
               }
            }
         }
         else
         {
            // nearest neighbor scaling
            float xRatio = width / (float)mWidth;
            float yRatio = height / (float)mHeight;
            unsigned int *buffer = (unsigned int *)mBase;
            for (int y = 0; y < mHeight; y++)
            {
               for (int x = 0; x < mWidth; x++)
               {
                  *(buffer++) = pixels[(int)(floor(y * yRatio) * width + floor(x * xRatio))];
               }
            }
         }
         mTexture->Dirty( Rect(0, 0, mWidth, mHeight) );
      }
   };

   class TheoraVideo : public Video {
   public:
      TheoraVideo(const int inWidth, const int inHeight)
         : mStartTime(-1), mDecoder(0)
         , mVideoFrame(0), mLastVideoFrame(0)
         , mAudioPacket(0), mLastAudioPacket(0), mChannel(0)
         , mSoundBufferOffset(0), mPlaying(false)
      {
         mSurface = new VideoSurface(inWidth, inHeight);
         mSurface->IncRef();
         mRect = Rect(0, 0, inWidth, inHeight);

         mSoundBuffer = new float[AUDIO_BUFFER_FRAMES * AUDIO_OUT_CHANNELS];
         smoothing = false;
      }

      ~TheoraVideo()
      {
         if (mDecoder)
         {
            THEORAPLAY_stopDecode(mDecoder);
         }
         if (mSoundBuffer) delete mSoundBuffer;
         mSurface->DecRef();
      }

      void queueSoundBuffer()
      {
         int size = AUDIO_BUFFER_FRAMES * AUDIO_OUT_CHANNELS * sizeof(float);
         ByteArray soundBuffer = ByteArray(size);
         memcpy(soundBuffer.Bytes(), mSoundBuffer, size);
         if (mChannel)
         {
            mChannel->addData(soundBuffer);
         }
         else
         {
            SoundTransform transform;
            mChannel = SoundChannel::Create(soundBuffer, transform);
         }
      }

      inline void fillAudioBuffer(float *buffer, const float *samples, int length, int channels)
      {
         for (int i = 0; i < length; i++)
         {
            float value = *(samples++);
            // clip values between -1 to 1
            *(buffer++) = (value > 1.0f ? 1.0f : (value < -1.0f ? -1.0f : value));
            // only grab a new value on stereo audio
            if (channels == 2)
            {
               value = *(samples++);
               value = (value > 1.0f ? 1.0f : (value < -1.0f ? -1.0f : value));
            }
            *(buffer++) = value;
         }
      }

      void loadAudioPacket()
      {
         // check if audio needs to be split between queued buffers
         if (mSoundBufferOffset + mAudioPacket->frames >= AUDIO_BUFFER_FRAMES)
         {
            int first = AUDIO_BUFFER_FRAMES - mSoundBufferOffset;
            int last = mAudioPacket->frames - first;
            const float *samples = (const float *)mAudioPacket->samples;
            fillAudioBuffer(mSoundBuffer + mSoundBufferOffset * AUDIO_OUT_CHANNELS, samples, first, mAudioPacket->channels);
            queueSoundBuffer();
            if (last > 0)
            {
               fillAudioBuffer(mSoundBuffer, samples + first * AUDIO_OUT_CHANNELS, last, mAudioPacket->channels);
            }
            mSoundBufferOffset = last;
         }
         else
         {
            fillAudioBuffer(mSoundBuffer + mSoundBufferOffset * AUDIO_OUT_CHANNELS,
               (const float *)mAudioPacket->samples,
               mAudioPacket->frames, mAudioPacket->channels);
            mSoundBufferOffset += mAudioPacket->frames;
         }
      }

      void Play()
      {
         if (!(mDecoder && THEORAPLAY_isDecoding(mDecoder)))
         {
            printf("Must load video before playing it\n");
            return;
         }

         mStartTime = lime::GetTimeStamp() * 1000;
         mPlaying = true;
      }

      void Clear()
      {
         mSurface->Clear();
      }

      bool Load(const char *inFileURL)
      {
         mDecoder = THEORAPLAY_startDecodeFile(inFileURL, 20, THEORAPLAY_VIDFMT_RGBA);

         if (THEORAPLAY_decodingError(mDecoder))
         {
            printf("There was an error decoding this file!\n");
            return false;
         }

         return true;
      }

      void Render(const RenderTarget &inTarget, const RenderState &inState)
      {
         RenderState state(inState);

         HardwareContext *hardware = inTarget.IsHardware() ? inTarget.mHardware : 0;

         const int elapsed = lime::GetTimeStamp() * 1000 - mStartTime;

         if (THEORAPLAY_isDecoding(mDecoder) && mPlaying)
         {
            while ((mAudioPacket = THEORAPLAY_getAudio(mDecoder)) != NULL)
            {
               loadAudioPacket();
               if (mLastAudioPacket)
               {
                  THEORAPLAY_freeAudio(mLastAudioPacket);
               }
               mLastAudioPacket = mAudioPacket;

               if (mAudioPacket->playms > elapsed + 400)
                  break;
            }

            if (mVideoFrame)
            {
               if (mVideoFrame->playms <= elapsed)
               {
                  // TODO: implement frame skip
                  mSurface->RenderTo((unsigned int *)mVideoFrame->pixels, mVideoFrame->width, mVideoFrame->height, smoothing);

                  mLastVideoFrame = mVideoFrame;
                  mVideoFrame = 0;
               }
            }
            else
            {
               mVideoFrame = THEORAPLAY_getVideo(mDecoder);
               // we must have a frame ready before freeing the last one
               if (mVideoFrame)
               {
                  THEORAPLAY_freeVideo(mLastVideoFrame);
               }
            }
         }

         if (hardware)
         {
            hardware->SetViewport(state.mClipRect);
            hardware->BeginBitmapRender(mSurface, 0xFFFFFFFF);
            hardware->RenderBitmap(mRect, x, y);
            hardware->EndBitmapRender();
         }
         else
         {
            RenderTarget clipped = inTarget.ClipRect( state.mClipRect );
            mSurface->BlitTo(clipped, mRect, x, y, bmNormal, 0, 0);
         }
      }

   private:
      int mStartTime;
      bool mPlaying;
      Rect mRect;

      float *mSoundBuffer;
      int mSoundBufferOffset;

      VideoSurface *mSurface;
      SoundChannel *mChannel;
      THEORAPLAY_Decoder *mDecoder;
      const THEORAPLAY_VideoFrame *mVideoFrame;
      const THEORAPLAY_VideoFrame *mLastVideoFrame;
      const THEORAPLAY_AudioPacket *mAudioPacket;
      const THEORAPLAY_AudioPacket *mLastAudioPacket;
   };

   Video *Video::Create(int inWidth, int inHeight) {
      //Return a reference
      return new TheoraVideo(inWidth, inHeight);
   }

}
