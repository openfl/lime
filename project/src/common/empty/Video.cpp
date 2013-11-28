#include "renderer/common/SimpleSurface.h"
#include <Display.h>
#include <Graphics.h>
#include <Video.h>
#include <Sound.h>

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
         
      }

      void RenderTo(const unsigned int *pixels, int width, int height, bool smoothing)
      {
         
      }
   };

   class EmptyVideo : public Video {
   public:
      EmptyVideo(const int inWidth, const int inHeight)
	  {
      }

      ~EmptyVideo()
      {
      }

      
      void Play()
      {
      }

      void Clear()
      {
      }

      bool Load(const char *inFileURL)
      {
         return true;
      }

      void Render(const RenderTarget &inTarget, const RenderState &inState)
      {
      }
   };

   Video *Video::Create(int inWidth, int inHeight) {
      //Return a reference
      return new EmptyVideo(inWidth, inHeight);
   }

}
