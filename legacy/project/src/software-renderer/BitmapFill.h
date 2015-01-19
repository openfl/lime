#include <Graphics.h>
#include <Surface.h>
#include "Render.h"

namespace nme
{

static inline bool IsPOW2(int inX)
{
   return (inX & (inX-1)) == 0;
}

enum { EDGE_CLAMP, EDGE_REPEAT, EDGE_POW2 };

enum FillAlphaMode
{
   FillAlphaIgnore,
   FillAlphaHas,
   FillAlphaIs,
};



class BitmapFillerBase : public Filler
{
public:
   BitmapFillerBase(GraphicsBitmapFill *inFill) : mBitmap(inFill)
   {
      mWidth = mBitmap->bitmapData->Width();
      mHeight = mBitmap->bitmapData->Height();
      mW1 = mWidth-1;
      mH1 = mHeight-1;
      mBase = mBitmap->bitmapData->GetBase();
      mStride = mBitmap->bitmapData->GetStride();
      mMapped = false;
      mPerspective = false;
      mBilinearAdjust = 0;
      mTint = ARGB(0xffffffff);
   }


   void SetupMatrix(const Matrix &inMatrix)
   {
      if (mMapped) return;

      // Get combined mapping matrix...
      Matrix mapper = inMatrix;
      mapper = mapper.Mult(mBitmap->matrix);
      mMapper = mapper.Inverse();
      adjustSubpixelMapper();

      mDPxDX = (int)(mMapper.m00 * (1<<16)+ 0.5);
      mDPyDX = (int)(mMapper.m10 * (1<<16)+ 0.5);
   }

   void SetTint(ARGB inTint) { mTint = inTint; }


   void SetMapping(const UserPoint *inVertex, const float *inUVT,int inComponents)
   {
      mMapped = true;
      double w = mBitmap->bitmapData->Width();
      double h = mBitmap->bitmapData->Height();
      // Solve tx = f(x,y),  ty = f(x,y)
      double dx1;
      double dy1;
      double dx2;
      double dy2;
      double du1;
      double du2;
      double dv1;
      double dv2;
      double dw1=0;
      double dw2=0;
      double w0=1,w1=1,w2=1;
      if (inComponents==3)
      {
         w0 = inUVT[2];
         w1 = inUVT[3+2];
         w2 = inUVT[6+2];
         //w0 = w1 = w2 = 1.0;
         dx1 = inVertex[1].x-inVertex[0].x;
         dy1 = inVertex[1].y-inVertex[0].y;
         dx2 = inVertex[2].x-inVertex[0].x;
         dy2 = inVertex[2].y-inVertex[0].y;
         du1 = (inUVT[inComponents  ]*w1 - inUVT[0]*w0)*w;
         du2 = (inUVT[inComponents*2]*w2 - inUVT[0]*w0)*w;
         dv1 = (inUVT[inComponents  +1]*w1 - inUVT[1]*w0)*h;
         dv2 = (inUVT[inComponents*2+1]*w2 - inUVT[1]*w0)*h;

         dw1 = w1 - w0;
         dw2 = w2 - w0;
      }
      else
      {
         dx1 = inVertex[1].x-inVertex[0].x;
         dy1 = inVertex[1].y-inVertex[0].y;
         dx2 = inVertex[2].x-inVertex[0].x;
         dy2 = inVertex[2].y-inVertex[0].y;
         du1 = (inUVT[inComponents  ] - inUVT[0])*w;
         du2 = (inUVT[inComponents*2] - inUVT[0])*w;
         dv1 = (inUVT[inComponents  +1] - inUVT[1])*h;
         dv2 = (inUVT[inComponents*2+1] - inUVT[1])*h;
      }

      // u = a*x + b*y + c
      //   u0 = a*v0.x + b*v0.y + c
      //   u1 = a*v1.x + b*v1.y + c
      //   u2 = a*v2.x + b*v2.y + c
      //
      //   (u1-u0) = a*(v1.x-v0.x) + b*(v1.y-v0.y) = du1 = a*dx1 + b*dy1
      //   (u2-u0) = a*(v2.x-v0.x) + b*(v2.y-v0.y) = du2 = a*dx2 + b*dy2
      //
      //   du1*dy2 - du2*dy1= a*(dx1*dy2 - dx2*dy1)
      double det = dx1*dy2 - dx2*dy1;
      if (det==0)
      {
         // TODO: x-only or y-only
         mMapper = Matrix(0,0,inUVT[0],inUVT[1]);
         mWX = mWY = 0;
         mW0 = 1;
      }
      else
      {
         det = 1.0/det;

         double a = mMapper.m00 = (du1*dy2 - du2*dy1)*det;
         double b = mMapper.m01 = (du2*dx1 - du1*dx2)*det;
         mMapper.mtx = (inUVT[0]*w*w0 - a*inVertex[0].x - b*inVertex[0].y);

         a = mMapper.m10 = (dv1*dy2 - dv2*dy1)*det;
         b = mMapper.m11 = (dv2*dx1 - dv1*dx2)*det;
         mMapper.mty = (inUVT[1]*h*w0 - a*inVertex[0].x - b*inVertex[0].y);

         if (mPerspective && inComponents>2)
         {
            a = mWX = (dw1*dy2 - dw2*dy1)*det;
            b = mWY = (dw2*dx1 - dw1*dx2)*det;
            mW0= w0 - a*inVertex[0].x - b*inVertex[0].y;
         }
      }

      adjustSubpixelMapper();

      if (!mPerspective || inComponents<3)
      {
         mDPxDX = (int)(mMapper.m00 * (1<<16)+ 0.5);
         mDPyDX = (int)(mMapper.m10 * (1<<16)+ 0.5);
      }
   }

   void adjustSubpixelMapper()
   {
      //  Tex =  mMapper * screen
      //  But, screen is sampled at centre, so Tex = mMapper * (screenCorner + (0.5,0.5))

      //  For bilinear-interp, a tex value of 0.5 should map to the beginning of the range between pixel 0 and pixel 1
      //   so an adjustment of  - (0.5,0.5) is subtracted to make this a truncation operation
      
      mMapper.mtx += (mMapper.m00 + mMapper.m01)*0.5 - mBilinearAdjust;
      mMapper.mty += (mMapper.m10 + mMapper.m11)*0.5 - mBilinearAdjust;

      if (mPerspective)
         mW0 += (mWX + mWY)*0.5;
   }


   const uint8 *mBase;
   int  mStride;

   ImagePoint mPos;
   int mDPxDX;
   int mDPyDX;
   int mWidth;
   int mHeight;
   int mW1;
   int mH1;
   bool mMapped;
   bool mPerspective;
   double mWX, mWY, mW0;
   double mTX, mTY, mTW;
   double mBilinearAdjust;
   Matrix mMapper;
   ARGB   mTint;
   GraphicsBitmapFill *mBitmap;
};


template<int EDGE,bool SMOOTH,FillAlphaMode FILL_ALPHA,bool PERSP>
class BitmapFiller : public BitmapFillerBase
{
public:
   enum { HasAlpha = FILL_ALPHA!=FillAlphaIgnore };
   enum { AlphaMode = FILL_ALPHA };

   BitmapFiller(GraphicsBitmapFill *inFill) : BitmapFillerBase(inFill)
   {
      mPerspective = PERSP;
      mBilinearAdjust = SMOOTH ? 0.5 : 0.0;
   }

   ARGB GetInc( )
   {
      if (PERSP)
      {
         double w = 65536.0/mTW;
         mPos.x = (int)(mTX*w);
         mPos.y = (int)(mTY*w);
         mTX += mMapper.m00;
         mTY += mMapper.m10;
         mTW += mWX;
      }

      int x = mPos.x >> 16;
      int y = mPos.y >> 16;
      if (SMOOTH)
      {
         ARGB result;

         int frac_x = (mPos.x & 0xff00) >> 8; 
         int frac_y = (mPos.y & 0xff00) >> 8; 

         if (!PERSP)
         {
            mPos.x += mDPxDX;
            mPos.y += mDPyDX;
         }

         if ((FillAlphaMode)AlphaMode==FillAlphaIs)
         {
            int a00,a01,a10,a11;

            if (EDGE == EDGE_CLAMP) 
            { 
               int x_step = 1; 
               int y_step = mStride; 

               if (x<0) {  x_step = x = 0; } 
               else if (x>=mW1) { x_step = 0; x = mW1; } 

               if (y<0) {  y_step = y = 0; } 
               else if (y>=mH1) { y_step = 0; y = mH1; } 

               const uint8 * ptr = mBase + y*mStride + x; 
               a00 = ptr[0]; 
               a01 = ptr[x_step]; 
               a10 = ptr[y_step]; 
               a11 = ptr[y_step + x_step]; 
            } 
            else if (EDGE==EDGE_POW2) 
            { 
               const uint8 *p = mBase + (y&mH1)*mStride; 

               a00 = *(p+ (x & mW1)); 
               a01 = *(p+ ((x+1) & mW1)); 

               p = mBase + ( (y+1) &mH1)*mStride; 
               a10 = *(p+ (x & mW1)); 
               a11 = *(p+ ((x+1) & mW1)); 
            } 
            else 
            { 
               int x1 = ((x+1) % mWidth); 
               if (x1<0) x1+=mWidth; 
               x = (x % mWidth); 
               if (x<0) x+=mWidth; 

               int y0= (y%mHeight); if (y0<0) y0+=mHeight; 
               const uint8 *p = mBase + y0*mStride; 

               a00 = *(p+ x); 
               a01 = *(p+ x1); 

               int y1= ((y+1)%mHeight); if (y1<0) y1+=mHeight; 
               p = mBase + y1*mStride; 
               a10 = *(p+ x); 
               a11 = *(p+ x1); 
            }

            int y0a = (a00<<8) + (a01-a00) * frac_x;
            int y1a = (a10<<8) + (a11-a10) * frac_x;
            result = mTint;
            result.a = ((y0a<<8) + (y1a-y0a) * frac_y)>>16;

            return result;
         }
         else
         {
            ARGB p00,p01,p10,p11;

            if (EDGE == EDGE_CLAMP) 
            { 
               int x_step = 4; 
               int y_step = mStride; 

               if (x<0) {  x_step = x = 0; } 
               else if (x>=mW1) { x_step = 0; x = mW1; } 

               if (y<0) {  y_step = y = 0; } 
               else if (y>=mH1) { y_step = 0; y = mH1; } 

               const uint8 * ptr = mBase + y*mStride + x*4; 
               p00 = *(ARGB *)ptr; 
               p01 = *(ARGB *)(ptr + x_step); 
               p10 = *(ARGB *)(ptr + y_step); 
               p11 = *(ARGB *)(ptr + y_step + x_step); 
            } 
            else if (EDGE==EDGE_POW2) 
            { 
               const uint8 *p = mBase + (y&mH1)*mStride; 

               p00 = *(ARGB *)(p+ (x & mW1)*4); 
               p01 = *(ARGB *)(p+ ((x+1) & mW1)*4); 

               p = mBase + ( (y+1) &mH1)*mStride; 
               p10 = *(ARGB *)(p+ (x & mW1)*4); 
               p11 = *(ARGB *)(p+ ((x+1) & mW1)*4); 
            } 
            else 
            { 
               int x1 = ((x+1) % mWidth) * 4; 
               if (x1<0) x1+=mWidth; 
               x = (x % mWidth)*4; 
               if (x<0) x+=mWidth; 

               int y0= (y%mHeight); if (y0<0) y0+=mHeight; 
               const uint8 *p = mBase + y0*mStride; 

               p00 = *(ARGB *)(p+ x); 
               p01 = *(ARGB *)(p+ x1); 

               int y1= ((y+1)%mHeight); if (y1<0) y1+=mHeight; 
               p = mBase + y1*mStride; 
               p10 = *(ARGB *)(p+ x); 
               p11 = *(ARGB *)(p+ x1); 
            }


            int y0r = (p00.r<<8) + (p01.r-p00.r) * frac_x;
            int y1r = (p10.r<<8) + (p11.r-p10.r) * frac_x;
            result.r = ((y0r<<8) + (y1r-y0r) * frac_y)>>16;

            int y0g = (p00.g<<8) + (p01.g-p00.g) * frac_x;
            int y1g = (p10.g<<8) + (p11.g-p10.g) * frac_x;
            result.g = ((y0g<<8) + (y1g-y0g) * frac_y)>>16;

            int y0b = (p00.b<<8) + (p01.b-p00.b) * frac_x;
            int y1b = (p10.b<<8) + (p11.b-p10.b) * frac_x;
            result.b = ((y0b<<8) + (y1b-y0b) * frac_y)>>16;

            if ((FillAlphaMode)AlphaMode==FillAlphaHas)
            {
               int y0a = (p00.a<<8) + (p01.a-p00.a) * frac_x;
               int y1a = (p10.a<<8) + (p11.a-p10.a) * frac_x;
               result.a = ((y0a<<8) + (y1a-y0a) * frac_y)>>16;
            }
            else
            {
               result.a = 255;
            }
         }
         return result;

      }
      else
      {
         if (!PERSP)
         {
            mPos.x += mDPxDX;
            mPos.y += mDPyDX;
         }

         if (EDGE == EDGE_CLAMP) 
         { 
            if (x<0) x = 0; 
            else if (x>=mWidth) x = mW1; 
 
            if (y<0) y = 0; 
            else if (y>=mHeight) y = mH1; 
         } 
         else if (EDGE == EDGE_POW2) 
         { 
            x &= mW1; 
            y &= mH1; 
         } 
         else if (EDGE == EDGE_REPEAT) 
         { 
            x = x % mWidth; if (x<0) x+=mWidth;
            y = y % mHeight; if (y<0) y+=mHeight;
         }

         if ((FillAlphaMode)AlphaMode==FillAlphaIs)
         {
            ARGB result(mTint);
            result.a = *( mBase + y*mStride + x);
            return result;
         }
         else
         {
            return *(ARGB *)( mBase + y*mStride + x*4);
         }
      }
   }

   inline void SetPos(int inSX,int inSY)
   {
      double x = inSX;
      double y = inSY;
      if (PERSP)
      {
         mTX = mMapper.m00*x + mMapper.m01*y + mMapper.mtx;
         mTY = mMapper.m10*x + mMapper.m11*y + mMapper.mty;
         mTW =         mWX*x +         mWY*y +         mW0;
      }
      else
      {
         mPos.x = (int)( (mMapper.m00*x + mMapper.m01*y + mMapper.mtx) * (1<<16) + 0.5);
         mPos.y = (int)( (mMapper.m10*x + mMapper.m11*y + mMapper.mty) * (1<<16) + 0.5);
      }
   }


   void Fill(const AlphaMask &mAlphaMask,int inTX,int inTY,
       const RenderTarget &inTarget,const RenderState &inState)
   {
      if (!mBase)
         return;
      SetupMatrix(*inState.mTransform.mMatrix);

      Render( mAlphaMask, *this, inTarget, inState, inTX,inTY );
   }

};


} // end namespace nme
