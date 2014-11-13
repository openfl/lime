#ifndef NME_TEXTURE_H
#define NME_TEXTURE_H

#include "Point.h"
#include "Rect.h"

namespace nme
{

class ImageBuffer;

class Texture
{
public:
   virtual ~Texture() {};

   virtual UserPoint PixelToTex(const UserPoint &inPixels)=0;
   virtual UserPoint TexToPaddedTex(const UserPoint &inPixels)=0;

   virtual void Bind(int inSlot)=0;
   virtual void BindFlags(bool inRepeat,bool inSmooth)=0;

   virtual void Dirty(const Rect &inRect) = 0;
   virtual bool IsCurrentVersion() = 0;
};


}


#endif
