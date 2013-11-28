#ifndef INTERNAL_RENDER_H
#define INTERNAL_RENDER_H

#include "AlphaMask.h"
#include <Pixel.h>
#include "renderer/common/BitmapCache.h"



namespace lime
{


template<typename SOURCE_, typename DEST_, typename BLEND_>
void DestRender(const AlphaMask &inAlpha, SOURCE_ &inSource, DEST_ &outDest, const BLEND_ &inBlend,
            const RenderState &inState, int inTX, int inTY)
{
   if (inAlpha.mLineStarts.size()<2)
      return;
   int y = inAlpha.mRect.y + inTY;
   const int *lines = &inAlpha.mLineStarts[0] - y;

   int y1 = inAlpha.mRect.y1() + inTY;

   Rect clip = inState.mClipRect.Intersect(outDest.GetRect());

   if (inState.mMask)
      clip = clip.Intersect(inState.mMask->GetRect().Translated(-inState.mTargetOffset));

   clip.ClipY(y,y1);

   for(; y<y1; y++)
   {
      const AlphaRun *run = &inAlpha.mAlphaRuns[ lines[y] ];
      const AlphaRun *end = &inAlpha.mAlphaRuns[ lines[y+1] ];
      if (run!=end)
      {
         outDest.SetRow(y);
         while(run<end && run->mX1 + inTX<=clip.x)
            run++;

         if (inState.mMask)
         {
            const Uint8 *mask0 = inState.mMask->DestRow(y+inState.mTargetOffset.y) +
                                    inState.mTargetOffset.x;
            while(run<end)
            {
               int x0 = run->mX0 + inTX;
               if (x0 >= clip.x1())
                  break;
               int x1 = run->mX1 + inTX;
               clip.ClipX(x0,x1);

               outDest.SetX(x0);
               inSource.SetPos(x0,y);
               const Uint8 *m = mask0 + x0;
               while(x0++<x1)
               {
                  int alpha = (run->mAlpha * (*m++))>>8;

                  if (SOURCE_::HasAlpha)
						{
							alpha -= (alpha>>7);
						   if (DEST_::HasAlpha)
                         inBlend.BlendAlpha( outDest,inSource,alpha );
                     else
                         inBlend.BlendNoAlpha( outDest,inSource,alpha );
						}
						else
						{
						   if (DEST_::HasAlpha)
                         inBlend.BlendAlphaFull( outDest,inSource,alpha );
                     else
                         inBlend.BlendNoAlphaFull( outDest,inSource,alpha );
						}
               }
               ++run;
            }
         }
         else
         {
            while(run<end)
            {
               int x0 = run->mX0 + inTX;
               if (x0 >= clip.x1())
                  break;
               int x1 = run->mX1 + inTX;
               clip.ClipX(x0,x1);

               outDest.SetX(x0);
               inSource.SetPos(x0,y);
               int alpha = run->mAlpha;
               if (!SOURCE_::HasAlpha)
						alpha -= (alpha>>7);

               while(x0++<x1)
                  if (SOURCE_::HasAlpha)
						{
						   if (DEST_::HasAlpha)
                         inBlend.BlendAlpha( outDest,inSource,alpha );
                     else
                         inBlend.BlendNoAlpha( outDest,inSource,alpha );
						}
						else
						{
						   if (DEST_::HasAlpha)
                         inBlend.BlendAlphaFull( outDest,inSource,alpha );
                     else
                         inBlend.BlendNoAlphaFull( outDest,inSource,alpha );
						}
               ++run;
            }
         }
      }
   }
};

template<bool HAS_ALPHA>
struct DestSurface32
{
   enum { HasAlpha = HAS_ALPHA };

   DestSurface32(const RenderTarget &inTarget) : mTarget(inTarget) { }

   void SetRow(int inY) { mRow = (ARGB *) mTarget.Row(inY); }
   void SetX(int inX) { mPtr = mRow + inX; }
   const ARGB Get() { return *mPtr; }
   void SetInc( ARGB inCol ) { *mPtr++ = inCol; }
   const Rect &GetRect() const { return mTarget.mRect; }

   ARGB *mRow;
   ARGB *mPtr;
   const RenderTarget &mTarget;
};




template<bool SWAP_RB,bool ALPHA_LUT=false,bool COLOUR_LUT=false>
struct NormalBlender
{
	const uint8 *mAlpha_LUT;
	const uint8 *mC0_LUT;
	const uint8 *mC1_LUT;
	const uint8 *mC2_LUT;

	NormalBlender(const RenderState &inState,bool inSwapRB=false)
	{
		if (ALPHA_LUT)
         mAlpha_LUT = inState.mAlpha_LUT;
		if (COLOUR_LUT)
		{
			mC0_LUT = inSwapRB ? inState.mC2_LUT : inState.mC0_LUT;
			mC1_LUT = inState.mC1_LUT;
			mC2_LUT = inSwapRB ? inState.mC0_LUT : inState.mC2_LUT;
		}
	}
   template<bool DEST_ALPHA,bool SRC_ALPHA,typename DEST, typename SRC>
   void Blend(DEST &inDest, SRC &inSrc,int inAlpha) const
   {
      ARGB src = inSrc.GetInc();
		if (SRC_ALPHA)
		{
			if (ALPHA_LUT)
				src.a = mAlpha_LUT[ (src.a * inAlpha)>>8 ];
			else
				src.a = (src.a * inAlpha)>>8;
		}
		else
		{
			if (ALPHA_LUT)
				src.a = mAlpha_LUT[ inAlpha ];
			else
				src.a = inAlpha;
		}
		if (COLOUR_LUT)
		{
			src.c0 = mC0_LUT[src.c0];
			src.c1 = mC1_LUT[src.c1];
			src.c2 = mC2_LUT[src.c2];
		}
      ARGB dest = inDest.Get();
      dest.Blend<SWAP_RB,DEST_ALPHA>(src);
      inDest.SetInc(dest);
   }
   template<typename DEST, typename SRC>
   void BlendNoAlpha(DEST &inDest, SRC &inSrc,int inAlpha) const
   {
       Blend<false,true>(inDest,inSrc,inAlpha);
   }
   template<typename DEST, typename SRC>
   void BlendAlpha(DEST &inDest, SRC &inSrc,int inAlpha) const
   {
       Blend<true,true>(inDest,inSrc,inAlpha);
   }
	template<typename DEST, typename SRC>
   void BlendNoAlphaFull(DEST &inDest, SRC &inSrc,int inAlpha) const
   {
       Blend<false,false>(inDest,inSrc,inAlpha);
   }
   template<typename DEST, typename SRC>
   void BlendAlphaFull(DEST &inDest, SRC &inSrc,int inAlpha) const
   {
       Blend<true,false>(inDest,inSrc,inAlpha);
   }

};




template<typename SOURCE_,typename BLEND_>
void RenderBlend(const AlphaMask &inAlpha, SOURCE_ &inSource, const RenderTarget &inDest,
				const BLEND_ &inBlend, const RenderState &inState, int inTX, int inTY)
{
   if (inDest.mPixelFormat & pfHasAlpha)
   {
      DestSurface32<true> dest(inDest);
      DestRender(inAlpha, inSource, dest, inBlend, inState, inTX, inTY);
   }
   else
   {
      DestSurface32<false> dest(inDest);
      DestRender(inAlpha, inSource, dest, inBlend, inState, inTX, inTY);
   }
}


#define RENDER(SWAP_RB,ALPHA_TRANS,COL_TRANS) \
   RenderBlend(inAlpha,inSource, inDest, NormalBlender<SWAP_RB,ALPHA_TRANS,COL_TRANS>(inState), inState, inTX, inTY)

template<bool SWAP_RB_,typename SOURCE_>
void RenderSwap(const AlphaMask &inAlpha, SOURCE_ &inSource, const RenderTarget &inDest,
				const RenderState &inState, int inTX, int inTY)
{
	if (inState.HasAlphaLUT() && inState.HasColourLUT())
		RENDER(SWAP_RB_,true,true);
	else if (inState.HasAlphaLUT() && !inState.HasColourLUT())
		RENDER(SWAP_RB_,true,false);
	else if (!inState.HasAlphaLUT() && inState.HasColourLUT())
		RENDER(SWAP_RB_,false,true);
	else
		RENDER(SWAP_RB_,false,false);
}


template<typename SOURCE_>
void Render(const AlphaMask &inAlpha, SOURCE_ &inSource, const RenderTarget &inDest,
				bool inSwapRB, const RenderState &inState, int inTX, int inTY)
{
   if (inSwapRB)
   {
		RenderSwap<true>(inAlpha,inSource,inDest,inState,inTX,inTY);
   }
   else
   {
		RenderSwap<false>(inAlpha,inSource,inDest,inState,inTX,inTY);
   }
}

} // end namespace lime

#endif
