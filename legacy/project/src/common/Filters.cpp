#include <Graphics.h>
#include <Display.h>
#include <Surface.h>
#include <nme/Pixel.h>

namespace nme
{


Surface *ExtractAlpha(const Surface *inSurface)
{
   if (inSurface->Format()!=pfXRGB && inSurface->Format()!=pfARGB)
      return 0;

   int w =  inSurface->Width();
   int h = inSurface->Height();
   Surface *result = new SimpleSurface(w,h,pfAlpha);
   result->IncRef();

   AutoSurfaceRender render(result);
   const RenderTarget &target = render.Target();
   for(int y=0;y<h;y++)
   {
      const uint8 *src = &((const ARGB *)inSurface->Row(y))->a;
      uint8 *dest = target.Row(y);
      for(int x=0;x<w;x++)
      {
         *dest = *src;
         dest++;
         src+=4;
      }
   }
   return result;
}

/*
 
   The BlurFilter has its size, mBlurX, mBlurY.  These are the "extra" pixels
    that get blended together. So Blur of 0 = original image, 1 = 1 extra, 2 = 2 extra.

   The even blends are easy: central pixel + Blur/2 either size.

   The Odd blends takes *source* pixels from the *right* first, at quality 1, and then from
    the left first for the second quality pass.  This means the destination will be
    bigger on the *left* first.  (flip the convolution filter)

*/



// --- BlurFilter --------------------------------------------------------------

BlurFilter::BlurFilter(int inQuality, int inBlurX, int inBlurY) : Filter(inQuality)
{
   mBlurX = std::max(0, std::min(256, inBlurX-1) );
   mBlurY = std::max(0, std::min(256, inBlurY-1) );
}

void BlurFilter::ExpandVisibleFilterDomain(Rect &ioRect,int inPass) const
{
   // This is about the source rect, so we have to add pixels to the right first,
   //  from where they will be taken first.
   int extra_x0 = mBlurX/2;
   int extra_x1 = mBlurX - extra_x0;
   int extra_y0 = mBlurY/2;
   int extra_y1 = mBlurY - extra_y0;

   if (inPass & 1)
   {
      std::swap(extra_x0, extra_x1);
      std::swap(extra_y0, extra_y1);
   }

   ioRect.x -= extra_x0;
   ioRect.y -= extra_y0;
   ioRect.w += mBlurX;
   ioRect.h += mBlurY;

}

void BlurFilter::GetFilteredObjectRect(Rect &ioRect,int inPass) const
{
   // Distination pixels can "move" more left, as these left pixels can take extra from the right
   int extra_x1 = mBlurX/2;
   int extra_x0 = mBlurX - extra_x1;
   int extra_y1 = mBlurY/2;
   int extra_y0 = mBlurY - extra_y1;

   if (inPass & 1)
   {
      std::swap(extra_x0, extra_x1);
      std::swap(extra_y0, extra_y1);
   }

   ioRect.x -= extra_x0;
   ioRect.y -= extra_y0;
   ioRect.w += mBlurX;
   ioRect.h += mBlurY;
}

/*
   Mask of size 4 looks like:  x+xx where + is the centre
   The blurreed image is then 2 pixel bigger in the left and one on the right
*/

/*
  inSrc        - src pixel corresponding to first output pixel
  inDS         - pixel stride
  inSrcW       - number of valid source pixels after inSrc
  inFilterLeft - filter size on left

  inDest       - first output pixel
  inDD         - output pixel stride
  inDest       - number of pixels to render
  
  inFilterSize - total filter size
  inPixelsLeft - number of valid pixels on left
*/
    
void BlurRow(const ARGB *inSrc, int inDS, int inSrcW, int inFilterLeft,
             ARGB *inDest, int inDD, int inDestW, int inFilterSize,int inPixelsLeft)
{
   int sr = 0;
   int sg = 0;
   int sb = 0;
   int sa = 0;

   // loop over destination pixels with kernel    -xxx+
   // At each pixel, we - the trailing pixel and + the leading pixel
   const ARGB *prev = inSrc - inFilterLeft*inDS;
   const ARGB *first = std::max(prev,inSrc - inPixelsLeft*inDS);
   const ARGB *src = prev + inFilterSize*inDS;
   const ARGB *src_end = inSrc + inSrcW*inDS;
   ARGB *dest = inDest;
   for(const ARGB *s=first;s<src;s+=inDS)
   {
      int a = s->a;
      sa+=a;
      sr+= s->r * a;
      sg+= s->g * a;
      sb+= s->b * a;
   }
   for(int x=0;x<inDestW; x++)
   {
      if (prev>=src_end)
      {
         for( ; x<inDestW; x++ )
         {
            dest->ival = 0;
            dest+=inDD;
         }
         return;
      }

      if (sa==0)
         dest->ival = 0;
      else
      {
         dest->r = sr/sa;
         dest->g = sg/sa;
         dest->b = sb/sa;
         dest->a = sa/inFilterSize;
      }

      if (src>=inSrc && src<src_end)
      {
         int a = src->a;
         sa+=a;
         sr+= src->r * a;
         sg+= src->g * a;
         sb+= src->b * a;
      }

      if (prev>=first)
      {
         int a = prev->a;
         sa-=a;
         sr-= prev->r * a;
         sg-= prev->g * a;
         sb-= prev->b * a;
      }


      src+=inDS;
      prev+=inDS;
      dest+=inDD;
   }
}

    
// Alpha version
void BlurRow(const uint8 *inSrc, int inDS, int inSrcW, int inFilterLeft,
             uint8 *inDest, int inDD, int inDestW, int inFilterSize,int inPixelsLeft)
{
   int sa = 0;

   // loop over destination pixels with kernel    -xxx+
   // At each pixel, we - the trailing pixel and + the leading pixel
   const uint8 *prev = inSrc - inFilterLeft*inDS;
   const uint8 *first = std::max(prev,inSrc - inPixelsLeft*inDS);
   const uint8 *src = prev + inFilterSize*inDS;
   const uint8 *src_end = inSrc + inSrcW*inDS;
   uint8 *dest = inDest;
   for(const uint8 *s=first;s<src;s+=inDS)
      sa += *s;

   for(int x=0;x<inDestW; x++)
   {
      if (prev>=src_end)
      {
         for( ; x<inDestW; x++ )
         {
            *dest = 0;
            dest+=inDD;
         }
         return;
      }

      *dest = sa/inFilterSize;

      if (src>=inSrc && src<src_end)
         sa+=*src;

      if (prev>=first)
         sa -= *prev;

      src+=inDS;
      prev+=inDS;
      dest+=inDD;
   }
}



template<typename PIXEL>
void BlurFilter::DoApply(const Surface *inSrc,Surface *outDest,ImagePoint inSrc0,ImagePoint inDiff,int inPass
      ) const
{
   int w = outDest->Width();
   int h = outDest->Height();
   int sw = inSrc->Width();
   int sh = inSrc->Height();

   outDest->Zero();

   int blurred_w = std::min(sw+mBlurX,w);
   int blurred_h = std::min(sh+mBlurY,h);
   // TODO: tmp height is potentially less (h+mBlurY) than sh ...
   SimpleSurface *tmp = new SimpleSurface(blurred_w,sh,outDest->Format());
   tmp->IncRef();

   int ox = mBlurX/2;
   int oy = mBlurY/2;
   if ( (inPass & 1) == 0)
   {
      ox = mBlurX - ox;
      oy = mBlurY - oy;
   }

   {
   AutoSurfaceRender tmp_render(tmp);
   const RenderTarget &target = tmp_render.Target();
   // Blur rows ...
   int sx0 = inSrc0.x + inDiff.x;
   for(int y=0;y<sh;y++)
   {
      PIXEL *dest = (PIXEL *)target.Row(y);
      const PIXEL *src = ((PIXEL *)inSrc->Row(y)) + sx0;

      BlurRow(src,1,sw-sx0,ox, dest,1,blurred_w, mBlurX+1, sx0);
   }
   sw = tmp->Width();
   }

   if (0)
   {
      AutoSurfaceRender dest_render(outDest);
      const RenderTarget &target = dest_render.Target();
      for(int y=0;y<sh;y++)
         memcpy(target.Row(y),tmp->Row(y),sw*sizeof(PIXEL));
   }
   else
   {
   AutoSurfaceRender dest_render(outDest);
   const RenderTarget &target = dest_render.Target();
   int s_stride = tmp->GetStride()/sizeof(PIXEL);
   int d_stride = target.mSoftStride/sizeof(PIXEL);
   // Blur cols ...
   int sy0 = inSrc0.y + inDiff.y;
   for(int x=0;x<blurred_w;x++)
   {
      PIXEL *dest = (PIXEL *)target.Row(0) + x;
      const PIXEL *src = ((PIXEL *)tmp->Row(sy0)) + x;

      BlurRow(src,s_stride,sh-sy0,oy, dest,d_stride,blurred_h,mBlurY+1,sy0);
   }
   }
   tmp->DecRef();
}

void BlurFilter::Apply(const Surface *inSrc,Surface *outDest,ImagePoint inSrc0,ImagePoint inDiff,int inPass) const
{
   DoApply<ARGB>(inSrc,outDest,inSrc0,inDiff,inPass);
   //ApplyStrength(mStrength,outDest);
}


// --- ColorMatrixFilter -------------------------------------------------------------

ColorMatrixFilter::ColorMatrixFilter(QuickVec<float> inMatrix) : Filter(1)
{
   mMatrix = inMatrix;
}

void ColorMatrixFilter::ExpandVisibleFilterDomain(Rect &ioRect,int inPass) const
{
}

void ColorMatrixFilter::GetFilteredObjectRect(Rect &ioRect,int inPass) const
{
}

int clamp255 (float val)
{
   if (val > 0xff) return 0xff;
   else if (val < 0) return 0;
   else return int (val);
}

template<typename PIXEL>
void ColorMatrixFilter::DoApply(const Surface *inSrc,Surface *outDest,ImagePoint inSrc0,ImagePoint inDiff,int inPass
      ) const
{
   int w = outDest->Width();
   int h = outDest->Height();
   int sw = inSrc->Width();
   int sh = inSrc->Height();
   
   //outDest->Zero();
   
   int filter_w = std::min(sw,w);
   int filter_h = std::min(sh,h);
   
   AutoSurfaceRender render(outDest);
   const RenderTarget &target = render.Target();
   for(int y=0;y<filter_h;y++)
   {
      ARGB *src = (ARGB*)inSrc->Row(y);
      ARGB *dest = (ARGB*)target.Row(y);
      for(int x=0;x<filter_w;x++)
      {
         dest->r = clamp255 ((mMatrix[0]  * src->r) + (mMatrix[1]  * src->g) + (mMatrix[2]  * src->b) + (mMatrix[3]  * src->a) + mMatrix[4]);
         dest->g = clamp255 ((mMatrix[5]  * src->r) + (mMatrix[6]  * src->g) + (mMatrix[7]  * src->b) + (mMatrix[8]  * src->a) + mMatrix[9]);
         dest->b = clamp255 ((mMatrix[10]  * src->r) + (mMatrix[11]  * src->g) + (mMatrix[12]  * src->b) + (mMatrix[13]  * src->a) + mMatrix[14]);
         dest->a = clamp255 ((mMatrix[15]  * src->r) + (mMatrix[16]  * src->g) + (mMatrix[17]  * src->b) + (mMatrix[18]  * src->a) + mMatrix[19]);
         src++;
         dest++;
      }
   }
}

void ColorMatrixFilter::Apply(const Surface *inSrc,Surface *outDest,ImagePoint inSrc0,ImagePoint inDiff,int inPass) const
{
   DoApply<ARGB>(inSrc,outDest,inSrc0,inDiff,inPass);
   //ApplyStrength(mStrength,outDest);
}


// --- DropShadowFilter --------------------------------------------------------------

DropShadowFilter::DropShadowFilter(int inQuality, int inBlurX, int inBlurY,
      double inTheta, double inDistance, int inColour, double inStrength,
      double inAlpha, bool inHide, bool inKnockout, bool inInner )
  : BlurFilter(inQuality, inBlurX, inBlurY),
     mCol(inColour), mAlpha(inAlpha),
     mHideObject(inHide), mKnockout(inKnockout), mInner(inInner)
{
   double theta = inTheta * M_PI/180.0;
   if (inDistance>255) inDistance = 255;
   if (inDistance<0) inDistance = 0;
   mTX = (int)( cos(theta) * inDistance );
   mTY = (int)( sin(theta) * inDistance );

   mStrength  = (int)(inStrength* 256);
   if ((unsigned int)mStrength>0x10000)
      mStrength = 0x10000;

   mAlpha  = (int)(inAlpha*256);
   if ((unsigned int)mAlpha > 256) mAlpha = 256;

   mAlpha255  = (int)(inAlpha*255);
   if ((unsigned int)mAlpha255 > 255) mAlpha255 = 255;

}

void ShadowRect(const RenderTarget &inTarget, const Rect &inRect, int inCol,int inStrength)
{
   Rect rect = inTarget.mRect.Intersect(inRect);
   int a = ((inCol >> 24 ) + (inCol>>31))*inStrength>>8;
   int r = (inCol>>16) & 0xff;
   int g = (inCol>>8) & 0xff;
   int b = inCol & 0xff;
   for(int y=0;y<rect.h;y++)
   {
      ARGB *argb = ( (ARGB *)inTarget.Row(y+rect.y)) + rect.x;
      for(int x=0;x<rect.w;x++)
      {
         argb->r += ((r-argb->r)*a)>>8;
         argb->g += ((g-argb->g)*a)>>8;
         argb->b += ((b-argb->b)*a)>>8;
         argb++;
      }
   }
}


void ApplyStrength(Surface *inAlpha,int inStrength)
{
   if (inStrength!=0x100)
   {
      uint8 lut[256];
      for(int a=0;a<256;a++)
      {
         int v= (a*inStrength) >> 8;
         lut[a] = v<255 ? v : 255;
      }
      AutoSurfaceRender render(inAlpha);
      const RenderTarget &target = render.Target();
      int w = target.Width();
      for(int y=0;y<target.Height();y++)
      {
         if (inAlpha->Format()==pfAlpha)
         {
            uint8 *r = target.Row(y);
            for(int x=0;x<w;x++)
               r[x] = lut[r[x]];
         }
         else
         {
            ARGB *r = (ARGB*)target.Row(y);
            for(int x=0;x<w;x++)
               r[x].a = lut[r[x].a];
         }
      }
   }
}


/*
void DumpAlpha(const char *inName, const Surface *inSurf)
{
   printf("------ %s ------\n", inName);
   for(int i=0;i<12;i++)
   {
      for(int x=0;x<12;x++)
         printf( inSurf->Row(i)[x]>128 ? "X" : ".");
      printf("\n");
   }
   printf("\n");
}
*/


void DropShadowFilter::Apply(const Surface *inSrc,Surface *outDest,ImagePoint inSrc0,ImagePoint inDiff,int inPass) const
{
   bool inner_hide = mInner && ( mKnockout || mHideObject);
   Surface *alpha = ExtractAlpha(inSrc);
   Surface *orig_alpha = 0;
   if (inner_hide)
      orig_alpha = alpha->IncRef();

   // Blur alpha..
   ImagePoint offset(0,0);
   ImagePoint a_src(inSrc0);
   for(int q=0;q<mQuality;q++)
   {
      Rect src_rect(alpha->Width(),alpha->Height());
      BlurFilter::GetFilteredObjectRect(src_rect,q);
      Surface *blur = new SimpleSurface(src_rect.w, src_rect.h, pfAlpha);
      blur->IncRef();

      ImagePoint diff(src_rect.x, src_rect.y);

      DoApply<uint8>(alpha,blur,a_src,diff,q);

      a_src = ImagePoint(0,0);
      alpha->DecRef();
      alpha = blur;
      offset += diff;
   }

   ApplyStrength(alpha,mStrength);


   AutoSurfaceRender render(outDest);
	outDest->Zero();
   //outDest->Clear(0xff00ff00);
   const RenderTarget &target = render.Target();

   // Copy it into the destination rect...
   ImagePoint blur_pos = offset + ImagePoint(mTX,mTY) - inDiff;
   int a = mAlpha;

   int scol = mCol;
   Rect src(inSrc0.x,inSrc0.y,inSrc->Width(),inSrc->Height());

   if (mInner )
   {
      if (a>127) a--;
      scol = (scol & 0xffffff) | (a<<24);
      if (inner_hide)
      {
         orig_alpha->BlitTo(target, src, -inDiff.x, -inDiff.y, bmTinted, 0, scol );
      }
      else
      {
         inSrc->BlitTo(target, src, -inDiff.x, -inDiff.y , bmCopy, 0, 0xffffff );
      }

      // And overlay shadow...
      Rect rect(alpha->Width(), alpha->Height() );
      alpha->BlitTo(target, rect, blur_pos.x, blur_pos.y, inner_hide ? bmErase : bmTintedInner, 0, scol);

      if (!inner_hide)
      {
         // Missing overlap between blurred and object...
         ImagePoint obj_pos = offset;
         int all = 999999;

         if (blur_pos.x > obj_pos.x)
            ShadowRect(target,Rect(obj_pos.x, blur_pos.y, blur_pos.x-obj_pos.x, rect.h), scol, mStrength);

         if (blur_pos.y > obj_pos.y)
            ShadowRect(target,Rect(obj_pos.x, obj_pos.y, all, blur_pos.y-obj_pos.y), scol, mStrength);
   
         if (blur_pos.x+rect.w < outDest->Width())
            ShadowRect(target,Rect(blur_pos.x+rect.w, blur_pos.y, all, rect.h), scol, mStrength);

         if (blur_pos.y+rect.h < outDest->Height())
            ShadowRect(target,Rect(obj_pos.x, blur_pos.y + rect.h, all, all), scol, mStrength);
      }
   }
   else
   {

      int dy0 = std::max(0,blur_pos.y);
      int dy1 = std::min(outDest->Height(),blur_pos.y+alpha->Height());
      int dx0 = std::max(0,blur_pos.x);
      int dx1 = std::min(outDest->Width(),blur_pos.x+alpha->Width());

      if (dx1>dx0)
      {
         int col = scol & 0x00ffffff;
         for(int y=dy0;y<dy1;y++)
         {
            ARGB *dest = ((ARGB *)target.Row(y)) + dx0;
            const uint8 *src = alpha->Row(y-blur_pos.y) + dx0 - blur_pos.x;
            for(int x=dx0;x<dx1;x++)
            {
               dest++->ival = col | ( (((*src++)*a)>>8) << 24 );
            }
         }
      }

      if (mKnockout)
      {
         inSrc->BlitTo(target, src, -inDiff.x, -inDiff.y, bmErase, 0, 0xffffff );
      }
      else if (!mHideObject)
      {
         inSrc->BlitTo(target, src, -inDiff.x, -inDiff.y, bmNormal, 0, 0xffffff );
      }
   }
   
   alpha->DecRef();
   if (orig_alpha)
      orig_alpha->DecRef();

}

void DropShadowFilter::ExpandVisibleFilterDomain(Rect &ioRect,int inPass) const
{
   Rect orig = ioRect;

   // Handle the quality ourselves, so iterate here.
   // Work out blur component...
   for(int q=0;q<mQuality;q++)
      BlurFilter::ExpandVisibleFilterDomain(ioRect,q);

   ioRect.Translate(-mTX,-mTY);

   if (!mKnockout)
      ioRect = ioRect.Union(orig);
}

void DropShadowFilter::GetFilteredObjectRect(Rect &ioRect,int inPass) const
{
   Rect orig = ioRect;

   if (!mInner)
   {
      // Handle the quality ourselves, so iterate here.
      // Work out blur component...
      for(int q=0;q<mQuality;q++)
         BlurFilter::GetFilteredObjectRect(ioRect,q);

      ioRect.Translate(mTX,mTY);

      if (!mKnockout && !mHideObject)
         ioRect = ioRect.Union(orig);

      //ioRect.x--;
      //ioRect.y--;
      //ioRect.w+=2;
      //ioRect.h+=2;
   }
}



// --- FilterList --------------------------------------------------------------


Rect ExpandVisibleFilterDomain( const FilterList &inList, const Rect &inRect )
{
   Rect r = inRect;
   for(int i=0;i<inList.size();i++)
   {
      Filter *f = inList[i];
      int quality = f->GetQuality();
      for(int q=0;q<quality;q++)
         f->ExpandVisibleFilterDomain(r, q);
   }
   return r;
}

// Given the intial pixel rect, calculate the filtered pixels...
Rect GetFilteredObjectRect( const FilterList &inList, const Rect &inRect)
{
   Rect r = inRect;
   for(int i=0;i<inList.size();i++)
   {
      Filter *f = inList[i];
      int quality = f->GetQuality();
      for(int q=0;q<quality;q++)
         f->GetFilteredObjectRect(r, q);
   }
   return r;
}

void HighlightZeroAlpha(Surface *ioBMP)
{
   AutoSurfaceRender render(ioBMP);
   const RenderTarget &target = render.Target();

   for(int y=0;y<target.Height();y++)
   {
      ARGB *pixel = (ARGB *)target.Row(y);
      for(int x=0; x<target.Width(); x++)
      {
         if (pixel[x].a==0)
            pixel[x] = 0xff00ff00;
      }
   }
}


Surface *FilterBitmap( const FilterList &inFilters, Surface *inBitmap,
                       const Rect &inSrcRect, const Rect &inDestRect, bool inMakePOW2,
                       ImagePoint inSrc0)
{
   int n = inFilters.size();
   if (n==0)
      return inBitmap;

   Rect src_rect = inSrcRect;


   Surface *bmp = inBitmap;

   bool do_clear = false;
   for(int i=0;i<n;i++)
   {
      Filter *f = inFilters[i];

      int quality = f->GetQuality();
      for(int q=0;q<quality;q++)
      {
         Rect dest_rect(src_rect);
         if (i==n-1 && q==quality-1)
         {
            dest_rect = inDestRect;
            if (inMakePOW2)
            {
              do_clear = true;
              dest_rect.w = UpToPower2(dest_rect.w);
              dest_rect.h = UpToPower2(dest_rect.h);
            }
         }
         else
         {
            f->GetFilteredObjectRect(dest_rect, q);
         }

         Surface *filtered = new SimpleSurface(dest_rect.w,dest_rect.h,bmp->Format());
         filtered->IncRef();

         if (do_clear)
            filtered->Zero();

         f->Apply(bmp,filtered, inSrc0, ImagePoint(dest_rect.x-src_rect.x, dest_rect.y-src_rect.y), q );
         inSrc0 = ImagePoint(0,0);

         bmp->DecRef();
         bmp = filtered;
         src_rect = dest_rect;
      }
   }

   //HighlightZeroAlpha(bmp);

   return bmp;
}

 
} // end namespace nme


