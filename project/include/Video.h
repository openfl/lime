#ifndef VIDEO_H
#define VIDEO_H

#include "Display.h"

namespace lime {

class Video : public DisplayObject {
public:
   bool smoothing;

   static Video *Create(int inWidth, int inHeight);

   virtual void Play() = 0;
   virtual void Clear() = 0;

   virtual bool Load(const char *inFilename) = 0;
   virtual void Render(const RenderTarget &inTarget, const RenderState &inState) = 0;
};

}

#endif