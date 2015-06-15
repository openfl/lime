#include <Graphics.h>
#include <Surface.h>
#include <nme/Pixel.h>

namespace nme
{

int gTextureContextVersion = 1;


// --- Surface -------------------------------------------------------


Surface::~Surface()
{
   delete mTexture;
}

void Surface::Bind(HardwareContext &inHardware,int inSlot)
{
   if (mTexture && !mTexture->IsCurrentVersion())
   {
      delete mTexture;
      mTexture = 0;
   }
 
   if (!mTexture)
      mTexture = inHardware.CreateTexture(this,mFlags);

   mTexture->Bind(inSlot);
}

Texture *Surface::GetTexture(HardwareContext *inHardware,int inPlane)
{
   if (mTexture && !mTexture->IsCurrentVersion())
   {
      delete mTexture;
      mTexture = 0;
   }
   if (!mTexture && inHardware)
      mTexture = inHardware->CreateTexture(this,mFlags);
   return mTexture;
}




// --- SimpleSurface -------------------------------------------------------

SimpleSurface::SimpleSurface(int inWidth,int inHeight,PixelFormat inPixelFormat,int inByteAlign,int inGPUFormat)
{
   mWidth = inWidth;
   mHeight = inHeight;
   mTexture = 0;
   mPixelFormat = inPixelFormat;
   mGPUPixelFormat = inPixelFormat;
   
   #ifdef NME_PREMULTIPLIED_ALPHA
   if (mPixelFormat != pfAlpha)
      mFlags |= surfUsePremultipliedAlpha;
   #endif

   if (inGPUFormat==-1)
   {
      int pix_size = inPixelFormat == pfAlpha ? 1 : 4;
      if (inByteAlign>1)
      {
         mStride = inWidth * pix_size + inByteAlign -1;
         mStride -= mStride % inByteAlign;
      }
      else
      {
         mStride = inWidth*pix_size;
      }

      mBase = new unsigned char[mStride * mHeight+1];
      mBase[mStride*mHeight] = 69;
   }
   else
   {
      mStride = 0;
      mBase = 0;
      if (inGPUFormat!=0)
         mGPUPixelFormat = inGPUFormat;

      createHardwareSurface();
   }
}

SimpleSurface::~SimpleSurface()
{
   if (mBase)
   {
      if (mBase[mStride*mHeight]!=69)
         ELOG("Image write overflow");
      delete [] mBase;
   }
}


void SimpleSurface::destroyHardwareSurface() {

  if (mTexture )
   {
      delete mTexture;
      mTexture = 0;
   }
   
}


void SimpleSurface::createHardwareSurface() {

   if ( nme::HardwareRenderer::current == NULL )
      printf( "Null Hardware Context" );
   else
       GetTexture( nme::HardwareRenderer::current );
   
}

void SimpleSurface::MakeTextureOnly()
{ 
   if(mBase)
   {
       createHardwareSurface();
       delete [] mBase;
       mBase = NULL;
   }
}





// --- Surface Blitting ------------------------------------------------------------------

struct NullMask
{
   inline void SetPos(int inX,int inY) const { }
   inline const uint8 &MaskAlpha(const uint8 &inAlpha) const { return inAlpha; }
   inline const uint8 &MaskAlpha(const ARGB &inRGB) const { return inRGB.a; }
   inline const ARGB Mask(const uint8 &inAlpha) const { return ARGB( inAlpha<<24 ); }
   inline const ARGB &Mask(const ARGB &inRGB) const { return inRGB; }
};


struct ImageMask
{
   ImageMask(const BitmapCache &inMask) :
      mMask(inMask), mOx(inMask.GetDestX()), mOy(inMask.GetDestY())
   {
      if (mMask.Format()==pfAlpha)
      {
         mComponentOffset = 0;
         mPixelStride = 1;
      }
      else
      {
         ARGB tmp;
         mComponentOffset = (uint8 *)&tmp.a - (uint8 *)&tmp;
         mPixelStride = 4;
      }
   }

   inline void SetPos(int inX,int inY) const
   {
      mRow = (mMask.Row(inY-mOy) + mComponentOffset) + mPixelStride*(inX-mOx);
   }
   inline uint8 MaskAlpha(uint8 inAlpha) const
   {
      inAlpha = (inAlpha * (*mRow) ) >> 8;
      mRow += mPixelStride;
      return inAlpha;
   }
   inline uint8 MaskAlpha(ARGB inARGB) const
   {
      int a = (inARGB.a * (*mRow) ) >> 8;
      mRow += mPixelStride;
      return a;
   }
   inline ARGB Mask(const uint8 &inA) const
   {
      ARGB argb( ((inA * (*mRow) ) >> 8) << 24 );
      mRow += mPixelStride;
      return argb;
   }
   inline ARGB Mask(ARGB inRGB) const
   {
      inRGB.a = (inRGB.a * (*mRow) ) >> 8;
      mRow += mPixelStride;
      return inRGB;
   }

   const BitmapCache &mMask;
   mutable const uint8 *mRow;
   int mOx,mOy;
   int mComponentOffset;
   int mPixelStride;
};

template<typename PIXEL>
struct ImageSource
{
   typedef PIXEL Pixel;

   ImageSource(const uint8 *inBase, int inStride, PixelFormat inFmt)
   {
      mBase = inBase;
      mStride = inStride;
      mFormat = inFmt;
   }

   inline void SetPos(int inX,int inY) const
   {
      mPos = ((const PIXEL *)( mBase + mStride*inY)) + inX;
   }
   inline const Pixel &Next() const { return *mPos++; }


   mutable const PIXEL *mPos;
   int   mStride;
   const uint8 *mBase;
   PixelFormat mFormat;
};


template<bool INNER,bool TINT_RGB=false>
struct TintSource
{
   typedef ARGB Pixel;

   TintSource(const uint8 *inBase, int inStride, int inCol,PixelFormat inFormat)
   {
      mBase = inBase;
      mStride = inStride;
      mCol = ARGB(inCol);
      a0 = mCol.a; if (a0>127) a0++;
      r = mCol.r; if (r>127) r++;
      g = mCol.g; if (g>127) g++;
      b = mCol.b; if (b>127) b++;
      mFormat = inFormat;

      if (inFormat==pfAlpha)
      {
         mComponentOffset = 0;
         mPixelStride = 1;
      }
      else
      {
         ARGB tmp;
         mComponentOffset = (uint8 *)&tmp.a - (uint8 *)&tmp;
         mPixelStride = 4;
      }
   }

   inline void SetPos(int inX,int inY) const
   {
      if (TINT_RGB)
         mPos = ((const uint8 *)( mBase + mStride*inY)) + inX*mPixelStride;
      else
         mPos = ((const uint8 *)( mBase + mStride*inY)) + inX*mPixelStride + mComponentOffset;
   }
   inline const ARGB &Next() const
   {
      if (INNER)
         mCol.a =  a0*(255 - *mPos)>>8;
      else if (TINT_RGB)
      {
         ARGB col = *(ARGB *)(mPos);
         mCol.a =   (a0*col.a)>>8;
         mCol.r =  (r*col.r)>>8;
         mCol.g =  (g*col.g)>>8;
         mCol.b =  (b*col.b)>>8;
      }
      else
      {
         mCol.a =  (a0 * *mPos)>>8;
      }
      mPos+=mPixelStride;
      return mCol;
   }

   int a0;
   int r;
   int g;
   int b;
   PixelFormat mFormat;
   mutable ARGB mCol;
   mutable const uint8 *mPos;
   int   mComponentOffset;
   int   mPixelStride;
   int   mStride;
   const uint8 *mBase;
};


template<typename PIXEL>
struct ImageDest
{
   typedef PIXEL Pixel;

   ImageDest(const RenderTarget &inTarget) : mTarget(inTarget) { }

   inline void SetPos(int inX,int inY) const
   {
      mPos = ((PIXEL *)mTarget.Row(inY)) + inX;
   }
   inline Pixel &Next() const { return *mPos++; }

   PixelFormat Format() const { return mTarget.mPixelFormat; }

   const RenderTarget &mTarget;
   mutable PIXEL *mPos;
};


template<bool DEST_ALPHA, typename DEST, typename SRC, typename MASK>
void TTBlit( const DEST &outDest, const SRC &inSrc,const MASK &inMask,
            int inX, int inY, const Rect &inSrcRect)
{
   for(int y=0;y<inSrcRect.h;y++)
   {
      outDest.SetPos(inX , inY + y );
      inMask.SetPos(inX , inY + y );
      inSrc.SetPos( inSrcRect.x, inSrcRect.y + y );
      for(int x=0;x<inSrcRect.w;x++)
      #if defined(HX_WINDOWS) && !defined(__MINGW32__)
         outDest.Next().Blend<DEST_ALPHA>(inMask.Mask(inSrc.Next()));
      #else
         if (!DEST_ALPHA)
            outDest.Next().TBlend_0(inMask.Mask(inSrc.Next()));
         else
            outDest.Next().TBlend_1(inMask.Mask(inSrc.Next()));
      #endif
   }
}

template<typename DEST, typename SRC, typename MASK>
void TBlit( const DEST &outDest, const SRC &inSrc,const MASK &inMask,
            int inX, int inY, const Rect &inSrcRect)
{
   bool dest_alpha = outDest.Format() & pfHasAlpha;

   if (dest_alpha)
      TTBlit<true,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect);
   else
      TTBlit<false,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect);
}



template<typename DEST, typename SRC, typename MASK>
void TBlitAlpha( const DEST &outDest, const SRC &inSrc,const MASK &inMask,
            int inX, int inY, const Rect &inSrcRect)
{
   for(int y=0;y<inSrcRect.h;y++)
   {
      outDest.SetPos(inX + inSrcRect.x, inY + y+inSrcRect.y );
      inMask.SetPos(inX + inSrcRect.x, inY + y+inSrcRect.y );
      inSrc.SetPos( inSrcRect.x, inSrcRect.y + y );
      for(int x=0;x<inSrcRect.w;x++)
         BlendAlpha(outDest.Next(),inMask.MaskAlpha(inSrc.Next()));
   }

}

static uint8 sgClamp0255Values[256*3];
static uint8 *sgClamp0255;
int InitClamp()
{
   sgClamp0255 = sgClamp0255Values + 256;
   for(int i=-255; i<=255+255;i++)
      sgClamp0255[i] = i<0 ? 0 : i>255 ? 255 : i;
   return 0;
}
static int init_clamp = InitClamp();

typedef void (*BlendFunc)(ARGB &ioDest, ARGB inSrc);

template<bool DEST_ALPHA,typename FUNC>
inline void BlendFuncWithAlpha(ARGB &ioDest, ARGB &inSrc,FUNC F)
{
   if (inSrc.a==0)
      return;
   ARGB val = inSrc;
   if (!DEST_ALPHA || ioDest.a>0)
   {
      F(val.r,ioDest.r);
      F(val.g,ioDest.g);
      F(val.b,ioDest.b);
   }
   if (DEST_ALPHA && ioDest.a<255)
   {
      int A = ioDest.a + (ioDest.a>>7);
      int A_ = 256-A;
      val.r = (val.r *A + inSrc.r*A_)>>8;
      val.g = (val.g *A + inSrc.g*A_)>>8;
      val.b = (val.b *A + inSrc.b*A_)>>8;
   }
   if (val.a==255)
   {
      ioDest = val;
      return;
   }

   if (DEST_ALPHA)
      ioDest.QBlendA(val);
   else
      ioDest.QBlend(val);
}


// --- Multiply -----

struct DoMult
{
   inline void operator()(uint8 &ioVal,uint8 inDest) const
     { ioVal = (inDest * ( ioVal + (ioVal>>7)))>>8; }
};

template<bool DEST_ALPHA> void MultiplyFunc(ARGB &ioDest, ARGB inSrc)
   { BlendFuncWithAlpha<DEST_ALPHA>(ioDest,inSrc,DoMult()); }

// --- Screen -----

struct DoScreen
{
   inline void operator()(uint8 &ioVal,uint8 inDest) const
     { ioVal = 255 - (((255 - inDest) * ( 256 - ioVal - (ioVal>>7)))>>8); }
};

template<bool DEST_ALPHA> void ScreenFunc(ARGB &ioDest, ARGB inSrc)
   { BlendFuncWithAlpha<DEST_ALPHA>(ioDest,inSrc,DoScreen()); }

// --- Lighten -----

struct DoLighten
{
   inline void operator()(uint8 &ioVal,uint8 inDest) const
   { if (inDest > ioVal ) ioVal = inDest; }
};

template<bool DEST_ALPHA> void LightenFunc(ARGB &ioDest, ARGB inSrc)
   { BlendFuncWithAlpha<DEST_ALPHA>(ioDest,inSrc,DoLighten()); }

// --- Darken -----

struct DoDarken
{
   inline void operator()(uint8 &ioVal,uint8 inDest) const
   { if (inDest < ioVal ) ioVal = inDest; }
};

template<bool DEST_ALPHA> void DarkenFunc(ARGB &ioDest, ARGB inSrc)
   { BlendFuncWithAlpha<DEST_ALPHA>(ioDest,inSrc,DoDarken()); }

// --- Difference -----

struct DoDifference
{
   inline void operator()(uint8 &ioVal,uint8 inDest) const
   { if (inDest < ioVal ) ioVal -= inDest; else ioVal = inDest-ioVal; }
};

template<bool DEST_ALPHA> void DifferenceFunc(ARGB &ioDest, ARGB inSrc)
   { BlendFuncWithAlpha<DEST_ALPHA>(ioDest,inSrc,DoDifference()); }

// --- Add -----

struct DoAdd
{
   inline void operator()(uint8 &ioVal,uint8 inDest) const
   { ioVal = sgClamp0255[ioVal+inDest]; }
};

template< bool DEST_ALPHA> void AddFunc(ARGB &ioDest, ARGB inSrc)
   { BlendFuncWithAlpha<DEST_ALPHA>(ioDest,inSrc,DoAdd()); }

// --- Subtract -----

struct DoSubtract
{
   inline void operator()(uint8 &ioVal,uint8 inDest) const
   { ioVal = sgClamp0255[inDest-ioVal]; }
};

template<bool DEST_ALPHA> void SubtractFunc(ARGB &ioDest, ARGB inSrc)
   { BlendFuncWithAlpha<DEST_ALPHA>(ioDest,inSrc,DoSubtract()); }

// --- Invert -----

struct DoInvert
{
   inline void operator()(uint8 &ioVal,uint8 inDest) const
   { ioVal = 255 - inDest; }
};

template< bool DEST_ALPHA> void InvertFunc(ARGB &ioDest, ARGB inSrc)
   { BlendFuncWithAlpha<DEST_ALPHA>(ioDest,inSrc,DoInvert()); }

// --- Alpha -----

template<bool DEST_ALPHA> void AlphaFunc(ARGB &ioDest, ARGB inSrc)
{
   if (DEST_ALPHA)
      ioDest.a = (ioDest.a * ( inSrc.a + (inSrc.a>>7))) >> 8;
}

// --- Erase -----

template< bool DEST_ALPHA> void EraseFunc(ARGB &ioDest, ARGB inSrc)
{
   if (DEST_ALPHA)
      ioDest.a = (ioDest.a * ( 256-inSrc.a - (inSrc.a>>7))) >> 8;
}

// --- Overlay -----

struct DoOverlay
{
   inline void operator()(uint8 &ioVal,uint8 inDest) const
   { if (inDest>127) DoScreen()(ioVal,inDest); else DoMult()(ioVal,inDest); }
};

template<bool DEST_ALPHA> void OverlayFunc(ARGB &ioDest, ARGB inSrc)
   { BlendFuncWithAlpha<DEST_ALPHA>(ioDest,inSrc,DoOverlay()); }

// --- HardLight -----

struct DoHardLight
{
   inline void operator()(uint8 &ioVal,uint8 inDest) const
   { if (ioVal>127) DoScreen()(ioVal,inDest); else DoMult()(ioVal,inDest); }
};

template<bool DEST_ALPHA> void HardLightFunc(ARGB &ioDest, ARGB inSrc)
   { BlendFuncWithAlpha<DEST_ALPHA>(ioDest,inSrc,DoHardLight()); }

// -- Set ---------

template<bool DEST_ALPHA> void CopyFunc(ARGB &ioDest, ARGB inSrc)
{
   ioDest = inSrc;
}

// -- Inner ---------

template<bool DEST_ALPHA> void InnerFunc(ARGB &ioDest, ARGB inSrc)
{
   int A = inSrc.a;
   if (A)
   {
      ioDest.r += ((inSrc.r - ioDest.r)*A)>>8;
      ioDest.g += ((inSrc.g - ioDest.g)*A)>>8;
      ioDest.b += ((inSrc.b - ioDest.b)*A)>>8;
   }
}


#define BLEND_METHOD(blend) blend<false>, blend<true>,

BlendFunc sgBlendFuncs[] = 
{
   0, 0,  // Normal
   0, 0,  // Layer
   BLEND_METHOD(MultiplyFunc)
   BLEND_METHOD(ScreenFunc)
   BLEND_METHOD(LightenFunc)
   BLEND_METHOD(DarkenFunc)
   BLEND_METHOD(DifferenceFunc)
   BLEND_METHOD(AddFunc)
   BLEND_METHOD(SubtractFunc)
   BLEND_METHOD(InvertFunc)
   BLEND_METHOD(AlphaFunc)
   BLEND_METHOD(EraseFunc)
   BLEND_METHOD(OverlayFunc)
   BLEND_METHOD(HardLightFunc)
   BLEND_METHOD(CopyFunc)
   BLEND_METHOD(InnerFunc)
};

template<typename MASK,typename SOURCE>
void TBlitBlend( const ImageDest<ARGB> &outDest, SOURCE &inSrc,const MASK &inMask,
            int inX, int inY, const Rect &inSrcRect, BlendMode inMode)
{
   bool dest_alpha = outDest.Format() & pfHasAlpha;

   BlendFunc blend = sgBlendFuncs[inMode*2 + (dest_alpha?1:0)];

   for(int y=0;y<inSrcRect.h;y++)
   {
      outDest.SetPos(inX , inY + y );
      inMask.SetPos(inX , inY + y );
      inSrc.SetPos( inSrcRect.x, inSrcRect.y + y );
      for(int x=0;x<inSrcRect.w;x++)
         blend(outDest.Next(),inMask.Mask(inSrc.Next()));
   }
}




void SimpleSurface::BlitTo(const RenderTarget &outDest,
                     const Rect &inSrcRect,int inPosX, int inPosY,
                     BlendMode inBlend, const BitmapCache *inMask,
                     uint32 inTint ) const
{
   if (!mBase)
      return;

   // Translate inSrcRect src_rect to dest ...
   Rect src_rect(inPosX,inPosY, inSrcRect.w, inSrcRect.h );
   // clip ...
   src_rect = src_rect.Intersect(outDest.mRect);

   if (inMask)
      src_rect = src_rect.Intersect(inMask->GetRect());

   // translate back to source-coordinates ...
   src_rect.Translate(inSrcRect.x-inPosX, inSrcRect.y-inPosY);
   // clip to origial rect...
   src_rect = src_rect.Intersect( inSrcRect );

   if (src_rect.HasPixels())
   {
      bool src_alpha = mPixelFormat==pfAlpha;
      bool dest_alpha = outDest.mPixelFormat==pfAlpha;

      int dx = inPosX + src_rect.x - inSrcRect.x;
      int dy = inPosY + src_rect.y - inSrcRect.y;

      // Check for overlap....
      if (src_alpha==dest_alpha)
      {
          int size_shift = src_alpha ? 0 : 2;
          int d_base = (outDest.mSoftPtr-mBase);
          int y_off = d_base/mStride;
          int x_off = (d_base-y_off*mStride) >> size_shift;
          Rect dr(dx + x_off, dy + y_off, src_rect.w, src_rect.h);
          if (src_rect.Intersect(dr).HasPixels())
          {
              SimpleSurface sub(src_rect.w, src_rect.h, mPixelFormat);
              Rect sub_dest(0,0,src_rect.w, src_rect.h);
              
              for(int y=0;y<src_rect.h;y++)
                 memcpy((void *)sub.Row(y), Row(src_rect.y+y) + (src_rect.x<<size_shift), src_rect.w<<size_shift );

              sub.BlitTo(outDest, sub_dest, dx, dy, inBlend, 0, inTint);
              return;
          }
      }



      // Blitting to alpha image - can ignore blend mode
      if (dest_alpha)
      {
         ImageDest<uint8> dest(outDest);
         if (inMask)
         {
            if (src_alpha)
               TBlitAlpha(dest, ImageSource<uint8>(mBase,mStride,mPixelFormat),
                     ImageMask(*inMask), dx, dy, src_rect );
            else
               TBlitAlpha(dest, ImageSource<ARGB>(mBase,mStride,mPixelFormat),
                     ImageMask(*inMask), dx, dy, src_rect );
         }
         else
         {
            if (src_alpha)
               TBlitAlpha(dest, ImageSource<uint8>(mBase,mStride,mPixelFormat),
                     NullMask(), dx, dy, src_rect );
            else
               TBlitAlpha(dest, ImageSource<ARGB>(mBase,mStride,mPixelFormat),
                     NullMask(), dx, dy, src_rect );
         }
         return;
      }

      ImageDest<ARGB> dest(outDest);
      bool tint = inBlend==bmTinted;
      bool tint_inner = inBlend==bmTintedInner;
      bool tint_add = inBlend==bmTintedAdd;

      // Blitting tint, we can ignore blend mode too (this is used for rendering text)
      if (tint)
      {
         if (src_alpha)
         {
            TintSource<false> src(mBase,mStride,inTint,mPixelFormat);
            if (inMask)
               TBlit( dest, src, ImageMask(*inMask), dx, dy, src_rect );
            else
               TBlit( dest, src, NullMask(), dx, dy, src_rect );
         }
         else
         {
            TintSource<false,true> src(mBase,mStride,inTint,mPixelFormat);
            if (inMask)
               TBlit( dest, src, ImageMask(*inMask), dx, dy, src_rect );
            else
               TBlit( dest, src, NullMask(), dx, dy, src_rect );
         }
      }
      else if (tint_inner)
      {
         TintSource<true> src(mBase,mStride,inTint,mPixelFormat);

         if (inMask)
            TBlitBlend( dest, src, ImageMask(*inMask), dx, dy, src_rect, bmInner );
         else
            TBlitBlend( dest, src, NullMask(), dx, dy, src_rect, bmInner );
      }
      else if (tint_add)
      {
         TintSource<false,true> src(mBase,mStride,inTint,mPixelFormat);

         if (inMask)
            TBlitBlend( dest, src, ImageMask(*inMask), dx, dy, src_rect, bmAdd );
         else
            TBlitBlend( dest, src, NullMask(), dx, dy, src_rect, bmAdd );
      }
      else if (src_alpha)
      {
         ImageSource<uint8> src(mBase,mStride,mPixelFormat);
         if (inBlend==bmNormal || inBlend==bmLayer)
         {
            if (inMask)
               TBlit( dest, src, ImageMask(*inMask), dx, dy, src_rect );
            else
               TBlit( dest, src, NullMask(), dx, dy, src_rect );
         }
         else
         {
            if (inMask)
               TBlitBlend( dest, src, ImageMask(*inMask), dx, dy, src_rect, inBlend );
            else
               TBlitBlend( dest, src, NullMask(), dx, dy, src_rect, inBlend );
         }
      }
      else
      {
         ImageSource<ARGB> src(mBase,mStride,mPixelFormat);
         if (inBlend==bmNormal || inBlend==bmLayer)
         {
            if (inMask)
               TBlit( dest, src, ImageMask(*inMask), dx, dy, src_rect );
            else
               TBlit( dest, src, NullMask(), dx, dy, src_rect );
         }
         else
         {
            if (inMask)
               TBlitBlend( dest, src, ImageMask(*inMask), dx, dy, src_rect, inBlend );
            else
               TBlitBlend( dest, src, NullMask(), dx, dy, src_rect, inBlend );
         }
      }
   }
}

void SimpleSurface::colorTransform(const Rect &inRect, ColorTransform &inTransform)
{
   if (mPixelFormat==pfAlpha || !mBase)
      return;

   const uint8 *ta = inTransform.GetAlphaLUT();
   const uint8 *tr = inTransform.GetRLUT();
   const uint8 *tg = inTransform.GetGLUT();
   const uint8 *tb = inTransform.GetBLUT();

   RenderTarget target = BeginRender(inRect,false);

   Rect r = target.mRect;
   for(int y=0;y<r.h;y++)
   {
      ARGB *rgb = ((ARGB *)target.Row(y+r.y)) + r.x;
      for(int x=0;x<r.w;x++)
      {
         rgb->r = tr[rgb->r];
         rgb->g = tg[rgb->g];
         rgb->b = tb[rgb->b];
         rgb->a = ta[rgb->a];
         rgb++;
      }
   }

   EndRender();
}


enum
{
   CHAN_ALPHA = 0x0008,
   CHAN_BLUE  = 0x0004,
   CHAN_GREEN = 0x0002,
   CHAN_RED   = 0x0001,
};

void SimpleSurface::BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect,
                   int inPosX, int inPosY,
                   int inSrcChannel, int inDestChannel ) const
{
  bool src_alpha = mPixelFormat==pfAlpha;
  bool dest_alpha = outTarget.mPixelFormat==pfAlpha;

  // Flash API does not have alpha images (might be useful somewhere else?)
   if (src_alpha || dest_alpha)
     return;

   if (inDestChannel==CHAN_ALPHA && !(outTarget.Format() & pfHasAlpha) )
      return;

   bool set_255 = (inSrcChannel==CHAN_ALPHA && !(mPixelFormat & pfHasAlpha) );


   // Start with unclipped dest rect
   Rect src_rect(inSrcRect.x+inPosX,inSrcRect.y+inPosY, inSrcRect.w, inSrcRect.h );
   // Clip to dest size...
   src_rect = src_rect.Intersect(outTarget.mRect);

   // Translate back to source-coordinates ...
   src_rect.Translate(-inPosX, -inPosY);

   // Clip to actual source rect...
   src_rect = src_rect.Intersect( Rect(0,0,Width(),Height() ) );

   if (src_rect.HasPixels())
   {
      int dx = inPosX + src_rect.x;
      int dy = inPosY + src_rect.y;

      int src_ch = inSrcChannel==CHAN_ALPHA ? 3 :
                   inSrcChannel==CHAN_RED   ? 2 :
                   inSrcChannel==CHAN_GREEN ? 1 :
                                              0;

      int dest_ch = inDestChannel==CHAN_ALPHA ? 3 :
                    inDestChannel==CHAN_RED   ? 2 :
                    inDestChannel==CHAN_GREEN ? 1 :
                                                0;


      for(int y=0;y<src_rect.h;y++)
      {
         uint8 *d = outTarget.Row(y+dy) + dx* 4 + dest_ch;
         if (set_255)
         {
            for(int x=0;x<src_rect.w;x++)
            {
               *d = 255;
               d+=4;
            }
         }
         else
         {
            const uint8 *s = Row(y+src_rect.y) + src_rect.x * 4 + src_ch;

            for(int x=0;x<src_rect.w;x++)
            {
               *d = *s;
               d+=4;
               s+=4;
            }
         }
      }
   }
}


template<bool SRC_ALPHA,bool DEST_ALPHA>
void TStretchTo(const SimpleSurface *inSrc,const RenderTarget &outTarget,
                const Rect &inSrcRect, const DRect &inDestRect)
{
   Rect irect( inDestRect.x+0.5, inDestRect.y+0.5, inDestRect.x1()+0.5, inDestRect.y1()+0.5, true);
   Rect out = irect.Intersect(outTarget.mRect);
   if (!out.Area())
      return;

   int dsx_dx = (inSrcRect.w << 16)/inDestRect.w;
   int dsy_dy = (inSrcRect.h << 16)/inDestRect.h;

   #ifndef STRETCH_BILINEAR
   // (Dx - inDestRect.x) * dsx_dx = ( Sx- inSrcRect.x )
   // Start first sample at out.x+0.5, and subtract 0.5 so src(1) is between first and second pixel
   //
   // Sx = (out.x+0.5-inDestRect.x)*dsx_dx + inSrcRect.x - 0.5

   //int sx0 = (int)((out.x-inDestRect.x*inSrcRect.w/inDestRect.w)*65536) +(inSrcRect.x<<16);
   //int sy0 = (int)((out.y-inDestRect.y*inSrcRect.h/inDestRect.h)*65536) +(inSrcRect.y<<16);
   int sx0 = (int)((out.x+0.5-inDestRect.x)*dsx_dx + (inSrcRect.x<<16) );
   int sy0 = (int)((out.y+0.5-inDestRect.y)*dsy_dy + (inSrcRect.y<<16) );

   for(int y=0;y<out.h;y++)
   {
      ARGB *dest= (ARGB *)outTarget.Row(y+out.y) + out.x;
      int y_ = (sy0>>16);
      const ARGB *src = (const ARGB *)inSrc->Row(y_);
      sy0+=dsy_dy;

      int sx = sx0;
      for(int x=0;x<out.w;x++)
      {
         ARGB s(src[sx>>16]);
         sx+=dsx_dx;
         if (!SRC_ALPHA)
         {
            if (DEST_ALPHA)
               s.a = 255;
            *dest++ = s;
         }
         else
         {
            if (!s.a)
               dest++;
            else if (s.a==255)
               *dest++ = s;
            else if (DEST_ALPHA)
               dest++ ->QBlendA(s);
            else
               dest++ ->QBlend(s);
         }
      }
   }

   #else
   // todo - overflow testing
   // (Dx - inDestRect.x) * dsx_dx = ( Sx- inSrcRect.x )
   // Start first sample at out.x+0.5, and subtract 0.5 so src(1) is between first and second pixel
   //
   // Sx = (out.x+0.5-inDestRect.x)*dsx_dx + inSrcRect.x - 0.5
   int sx0 = (((((out.x-inDestRect.x)<<8) + 0x80) * inSrcRect.w/inDestRect.w) << 8) +(inSrcRect.x<<16) - 0x8000;
   int sy0 = (((((out.y-inDestRect.y)<<8) + 0x80) * inSrcRect.h/inDestRect.h) << 8) +(inSrcRect.y<<16) - 0x8000;
   int last_y = inSrcRect.y1()-1;
   ARGB s;
   s.a = 255;
   for(int y=0;y<out.h;y++)
   {
      ARGB *dest= (ARGB *)outTarget.Row(y+out.y) + out.x;
      int y_ = (sy0>>16);
      int y_frac = sy0 & 0xffff;
      const ARGB *src0 = (const ARGB *)inSrc->Row(y_);
      const ARGB *src1 = (const ARGB *)inSrc->Row(y_<last_y ? y_+1 : y_);
      sy0+=dsy_dy;

      int sx = sx0;
      for(int x=0;x<out.w;x++)
      {
         int x_ = sx>>16;
         int x_frac = sx & 0xffff;

         ARGB s00(src0[x_]);
         ARGB s01(src0[x_+1]);
         ARGB s10(src1[x_]);
         ARGB s11(src1[x_+1]);

         int c0_0 = s00.r + (((s01.r-s00.r)*x_frac) >> 16);
         int c0_1 = s10.r + (((s11.r-s10.r)*x_frac) >> 16);
         s.r = c0_0 + (((c0_1-c0_0)*y_frac) >> 16);

         int c1_0 = s00.g + (((s01.g-s00.g)*x_frac) >> 16);
         int c1_1 = s10.g + (((s11.g-s10.g)*x_frac) >> 16);
         s.g = c1_0 + (((c1_1-c1_0)*y_frac) >> 16);

         int c2_0 = s00.b + (((s01.b-s00.b)*x_frac) >> 16);
         int c2_1 = s10.b + (((s11.b-s10.b)*x_frac) >> 16);
         s.b = c2_0 + (((c2_1-c2_0)*y_frac) >> 16);

         sx+=dsx_dx;
         if (!SRC_ALPHA)
         {
            *dest++ = s;
         }
         else
         {
            int a_x0 = s00.a + (((s01.a-s00.a)*x_frac) >> 16);
            int a_x1 = s10.a + (((s11.a-s10.a)*x_frac) >> 16);
            s.a = a_x0 + (((a_x1-a_x0)*y_frac) >> 16);

            if (!s.a)
               dest++;
            else if (s.a==255)
               *dest++ = s;
            else if (DEST_ALPHA)
               dest++ ->QBlendA(s);
            else
               dest++ ->QBlend(s);
         }
      }
   }
   #endif
}

void SimpleSurface::StretchTo(const RenderTarget &outTarget,
                     const Rect &inSrcRect, const DRect &inDestRect) const
{
   // Only RGB supported
   if (mPixelFormat==pfAlpha || outTarget.mPixelFormat==pfAlpha)
      return;

   bool dest_has_alpha = outTarget.mPixelFormat & pfHasAlpha;
   bool src_has_alpha = mPixelFormat &  pfHasAlpha;

   if (src_has_alpha)
   {
      if (dest_has_alpha)
         TStretchTo<true,true>(this,outTarget,inSrcRect,inDestRect);
      else
         TStretchTo<true,false>(this,outTarget,inSrcRect,inDestRect);
   }
   else
   {
      if (dest_has_alpha)
         TStretchTo<false,true>(this,outTarget,inSrcRect,inDestRect);
      else
         TStretchTo<false,false>(this,outTarget,inSrcRect,inDestRect);
   }
}



void SimpleSurface::Clear(uint32 inColour,const Rect *inRect)
{
   if (!mBase)
      return;
   ARGB rgb(inColour | ((mPixelFormat & pfHasAlpha) ? 0 : 0xFF000000));
   if (mPixelFormat==pfAlpha)
   {
      memset(mBase, rgb.a,mStride*mHeight);
      return;
   }

   int x0 = inRect ? inRect->x  : 0;
   int x1 = inRect ? inRect->x1()  : Width();
   int y0 = inRect ? inRect->y  : 0;
   int y1 = inRect ? inRect->y1()  : Height();
   if( x0 < 0 ) x0 = 0;
   if( x1 > Width() ) x1 = Width();
   if( y0 < 0 ) y0 = 0;
   if( y1 > Height() ) y1 = Height();
   if (x1<=x0 || y1<=y0)
      return;
   for(int y=y0;y<y1;y++)
   {
      uint32 *ptr = (uint32 *)(mBase + y*mStride) + x0;
      for(int x=x0;x<x1;x++)
         *ptr++ = rgb.ival;
   }
   if (mTexture)
      mTexture->Dirty( Rect(x0,y0,x1-x0,y1-y0) );
}

void SimpleSurface::Zero()
{
   if (mBase)
      memset(mBase,0,mStride * mHeight);
}

void SimpleSurface::dispose()
{
   destroyHardwareSurface();
   if (mBase)
   {
      if (mBase[mStride * mHeight] != 69)
      {
         ELOG("Image write overflow");
      }
      delete [] mBase;
      mBase = NULL;
   }
}

uint8  *SimpleSurface::Edit(const Rect *inRect)
{
   if (!mBase)
      return 0;

   Rect r = inRect ? inRect->Intersect( Rect(0,0,mWidth,mHeight) ) : Rect(0,0,mWidth,mHeight);
   if (mTexture)
      mTexture->Dirty(r);
   mVersion++;
      return mBase;
}



RenderTarget SimpleSurface::BeginRender(const Rect &inRect,bool inForHitTest)
{
   if (!mBase)
      return RenderTarget();

   Rect r =  inRect.Intersect( Rect(0,0,mWidth,mHeight) );
   if (mTexture)
      mTexture->Dirty(r);
   mVersion++;
   return RenderTarget(r, mPixelFormat,mBase,mStride);
}

void SimpleSurface::EndRender()
{
}

Surface *SimpleSurface::clone()
{
   SimpleSurface *copy = new SimpleSurface(mWidth,mHeight,mPixelFormat,1,mBase?-1:0);
   if (mBase)
      for(int y=0;y<mHeight;y++)
         memcpy(copy->mBase + copy->mStride*y, mBase+mStride*y, mWidth*(mPixelFormat==pfAlpha?1:4));
   
   copy->SetAllowTrans(mAllowTrans);
   copy->IncRef();
   return copy;
}

void SimpleSurface::getPixels(const Rect &inRect,uint32 *outPixels,bool inIgnoreOrder, bool inLittleEndian)
{
   if (!mBase)
      return;

   Rect r = inRect.Intersect(Rect(0,0,Width(),Height()));

   for(int y=0;y<r.h;y++)
   {
      uint8 *src = mBase + (r.y+y)*mStride + r.x*(mPixelFormat==pfAlpha?1:4);
      if (mPixelFormat==pfAlpha)
      {
         for(int x=0;x<r.w;x++)
            *outPixels++ = (*src++) << 24;
      }
      else if (inIgnoreOrder || inLittleEndian)
      {
         memcpy(outPixels,src,r.w*4);
         outPixels+=r.w;
      }
      else
      {
         uint8 *a = src;
         uint8 *pix = (uint8 *)outPixels;

         for(int x=0;x<r.w;x++)
         {
            *pix++ = src[3];
            *pix++ = src[2];
            *pix++ = src[1];
            *pix++ = src[0];
            src+=4;
         }
         outPixels += r.w;
      }
   }
}

void SimpleSurface::getColorBoundsRect(int inMask, int inCol, bool inFind, Rect &outRect)
{
   if (!mBase)
      return;

   int w = Width();
   int h = Height();

   if (w==0 || h==0 || mPixelFormat==pfAlpha)
   {
      outRect = Rect();
      return;
   }

   int min_x = w + 1;
   int max_x = -1;
   int min_y = h + 1;
   int max_y = -1;

   for(int y=0;y<h;y++)
   {
      int *pixel = (int *)( mBase + y*mStride);
      for(int x=0;x<w;x++)
      {
         if ( (((*pixel++)&inMask)==inCol)==inFind )
         {
            if (x<min_x) min_x=x;
            if (x>max_x) max_x=x;
            if (y<min_y) min_y=y;
            if (y>max_y) max_y=y;
         }
      }
   }

   if (min_x>max_x)
      outRect = Rect(0,0,0,0);
   else
      outRect = Rect(min_x,min_y,max_x-min_x+1,max_y-min_y+1);
}


void SimpleSurface::setPixels(const Rect &inRect,const uint32 *inPixels,bool inIgnoreOrder,
        bool inLittleEndian)
{
   if (!mBase)
      return;
   Rect r = inRect.Intersect(Rect(0,0,Width(),Height()));
   mVersion++;
   if (mTexture)
      mTexture->Dirty(r);

   const uint8 *src = (const uint8 *)inPixels;
   
   if (mAllowTrans && mPixelFormat==pfXRGB)
      mPixelFormat=pfARGB;
   
   for(int y=0;y<r.h;y++)
   {
      uint8 *dest = mBase + (r.y+y)*mStride + r.x*(mPixelFormat==pfAlpha?1:4);
      if (mPixelFormat==pfAlpha)
      {
         for(int x=0;x<r.w;x++)
            *dest++ = (*inPixels++) >> 24;
      }
      else if (inIgnoreOrder)
      {
         if (mAllowTrans)
         {
            memcpy(dest,inPixels,r.w*4);
            inPixels+=r.w;
         }
         else
         {
            for(int x=0;x<r.w;x++)
            {
               *dest++ = src[0];
               *dest++ = src[1];
               *dest++ = src[2];
               *dest++ = 0xff;
               src+=4;
            }
         }
      }
      else
      {
         if (inLittleEndian)
         {
               if (mAllowTrans)
               {
                  memcpy(dest,src,r.w*sizeof(int));
                  src += r.w*sizeof(int);
               }
               else
               {
                  for(int x=0;x<r.w;x++)
                  {
                     *dest++ = src[0];
                     *dest++ = src[1];
                     *dest++ = src[2];
                     *dest++ = 0xff;
                     src+=4;
                  }
               }
         }
         else
         {
               for(int x=0;x<r.w;x++)
               {
                  *dest++ = src[3];
                  *dest++ = src[2];
                  *dest++ = src[1];
                  *dest++ = mAllowTrans ? src[0] : 0xff;
                  src+=4;
               }
         }
      }
   }
}

uint32 SimpleSurface::getPixel(int inX,int inY)
{
   if (inX<0 || inY<0 || inX>=mWidth || inY>=mHeight || !mBase)
      return 0;

   if (mPixelFormat==pfAlpha)
      return mBase[inY*mStride + inX]<<24;

   return ((int *)(mBase + inY*mStride))[inX];
}

void SimpleSurface::setPixel(int inX,int inY,uint32 inRGBA,bool inAlphaToo)
{
   if (inX<0 || inY<0 || inX>=mWidth || inY>=mHeight || !mBase)
      return;

   mVersion++;
   if (mTexture)
      mTexture->Dirty(Rect(inX,inY,1,1));

   if (inAlphaToo)
   {
      if(mPixelFormat==pfXRGB)
         mPixelFormat=pfARGB;
      if (mPixelFormat==pfAlpha)
         mBase[inY*mStride + inX] = inRGBA >> 24;
      else
         ((uint32 *)(mBase + inY*mStride))[inX] = inRGBA;
   }
   else
   {
      if (mPixelFormat!=pfAlpha)
      {
         int &pixel = ((int *)(mBase + inY*mStride))[inX];
         pixel = (inRGBA & 0xffffff) | (pixel & 0xff000000);
      }
   }
}

void SimpleSurface::scroll(int inDX,int inDY)
{
   if ((inDX==0 && inDY==0) || !mBase) return;

   Rect src(0,0,mWidth,mHeight);
   src = src.Intersect( src.Translated(inDX,inDY) ).Translated(-inDX,-inDY);
   int pixels = src.Area();
   if (!pixels)
      return;

   uint32 *buffer = (uint32 *)malloc( pixels * sizeof(int) );
   getPixels(src,buffer,true);
   src.Translate(inDX,inDY);
   setPixels(src,buffer,true);
   free(buffer);
   mVersion++;
   if (mTexture)
      mTexture->Dirty(src);
}

void SimpleSurface::applyFilter(Surface *inSrc, const Rect &inRect, ImagePoint inOffset, Filter *inFilter)
{
   if (!mBase) return;
   FilterList f;
   f.push_back(inFilter);

   Rect src_rect(inRect.w,inRect.h);
   Rect dest = GetFilteredObjectRect(f,src_rect);

   inSrc->IncRef();
   Surface *result = FilterBitmap(f, inSrc, src_rect, dest, false, ImagePoint(inRect.x,inRect.y) );

   dest.Translate(inOffset.x, inOffset.y);

   src_rect = Rect(0,0,result->Width(),result->Height());
   int dx = dest.x;
   int dy = dest.y;
   dest = dest.Intersect( Rect(0,0,mWidth,mHeight) );
   dest.Translate(-dx,-dy);
   dest = dest.Intersect( src_rect );
   dest.Translate(dx,dy);

   int bpp = BytesPP();

   RenderTarget t = BeginRender(dest,false);
   //printf("Copy back @ %d,%d %dx%d  + (%d,%d)\n", dest.x, dest.y, t.Width(), t.Height(), dx, dy);
   for(int y=0;y<t.Height();y++)
      memcpy((void *)(t.Row(y+dest.y)+(dest.x)*bpp), result->Row(y-dy)-dx*bpp, dest.w*bpp);

   EndRender();

   result->DecRef();
}

/* A MINSTD pseudo-random number generator.
 *
 * This generates a pseudo-random number sequence equivalent to std::minstd_rand0 from the C++11 standard library, which
 * is the generator that Flash uses to generate noise for BitmapData.noise().
 *
 * It is reimplemented here because std::minstd_rand0 is not available in earlier versions of C++.
 *
 * MINSTD was originally suggested in "A pseudo-random number generator for the System/360", P.A. Lewis, A.S. Goodman,
 * J.M. Miller, IBM Systems Journal, Vol. 8, No. 2, 1969, pp. 136-146 */
class MinstdGenerator
{
public:
   MinstdGenerator(unsigned int seed)
   {
      if (seed == 0) {
         x = 1U;
      } else {
         x = seed;
      }
   }

   unsigned int operator () ()
   {
      const unsigned int a = 16807U;
      const unsigned int m = (1U << 31) - 1;

      unsigned int lo = a * (x & 0xffffU);
      unsigned int hi = a * (x >> 16);
      lo += (hi & 0x7fffU) << 16;

      if (lo > m)
      {
         lo &= m;
         ++lo;
      }

      lo += hi >> 15;

      if (lo > m)
      {
         lo &= m;
         ++lo;
      }

      x = lo;

      return x;
   }

private:
   unsigned int x;
};

void SimpleSurface::noise(unsigned int randomSeed, unsigned int low, unsigned int high, int channelOptions, bool grayScale)
{
   if (!mBase)
      return;

   MinstdGenerator generator(randomSeed);

   RenderTarget target = BeginRender(Rect(0,0,mWidth,mHeight),false);
   ARGB tmpRgb;

   int range = high - low + 1;

   for (int y=0;y<mHeight;y++)
   {
      ARGB *rgb = ((ARGB *)target.Row(y));
      for(int x=0;x<mWidth;x++)
      {
         if (grayScale)
         {
            tmpRgb.r = tmpRgb.g = tmpRgb.b = low + generator() % (high - low + 1);
         }
         else
         {
            if (channelOptions & CHAN_RED)
               tmpRgb.r = low + generator() % range;
            else
               tmpRgb.r = 0;

            if (channelOptions & CHAN_GREEN)
               tmpRgb.g = low + generator() % range;
            else
               tmpRgb.g = 0;

            if (channelOptions & CHAN_BLUE)
               tmpRgb.b = low + generator() % range;
            else
               tmpRgb.b = 0;
         }

         if (channelOptions & CHAN_ALPHA)
            tmpRgb.a = low + generator() % range;
         else
            tmpRgb.a = 255;

         *rgb = tmpRgb;

         rgb++;
      }
   }
   
   EndRender();
}


void SimpleSurface::unmultiplyAlpha()
{
   if (!mBase)
      return;
   Rect r = Rect(0,0,mWidth,mHeight);
   mVersion++;
   if (mTexture)
      mTexture->Dirty(r);
   
   if (mPixelFormat==pfAlpha)
      return;
   int i = 0;
   int a;
   double unmultiply;
   
   for(int y=0;y<r.h;y++)
   {
      uint8 *dest = mBase + (r.y+y)*mStride + r.x*4;
      for(int x=0;x<r.w;x++)
      {
         a = *(dest + 3);
         if(a!=0)
         {
            unmultiply = 255.0/a;
            *dest = sgClamp0255[int((*dest) * unmultiply)];
            *(dest+1) = sgClamp0255[int(*(dest + 1) * unmultiply)];
            *(dest+2) = sgClamp0255[int(*(dest + 2) * unmultiply)];
         }
         dest += 4;
      }
   }
}



// --- HardwareSurface -------------------------------------------------------------

HardwareSurface::HardwareSurface(HardwareRenderer *inContext)
{
   mHardware = inContext;
   mHardware->IncRef();
}

HardwareSurface::~HardwareSurface()
{
   mHardware->DecRef();
}

Surface *HardwareSurface::clone()
{
   // This is not really a clone...
   Surface *copy = new HardwareSurface(mHardware);
   copy->IncRef();
   return copy;

}

void HardwareSurface::getPixels(const Rect &inRect, uint32 *outPixels,bool inIgnoreOrder)
{
   memset(outPixels,0,Width()*Height()*4);
}

void HardwareSurface::setPixels(const Rect &inRect,const uint32 *outPixels,bool inIgnoreOrder)
{
}



// --- BitmapCache -----------------------------------------------------------------

const uint8 *BitmapCache::Row(int inRow) const
{
   return mBitmap->Row(inRow);
}


const uint8 *BitmapCache::DestRow(int inRow) const
{
   return mBitmap->Row(inRow-(mRect.y+mTY)) - mBitmap->BytesPP()*(mRect.x+mTX);
}


PixelFormat BitmapCache::Format() const
{
   return mBitmap->Format();
}

} // end namespace nme

