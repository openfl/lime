#ifndef RENDERER_BLEND_MODE_H
#define RENDERER_BLEND_MODE_H


#include <Pixel.h>
#include "renderer/common/BitmapCache.h"


namespace lime {
	
	
	struct NullMask
	{
		inline void SetPos(int inX,int inY) const { }
		inline const uint8 &MaskAlpha(const uint8 &inAlpha) const { return inAlpha; }
		inline const uint8 &MaskAlpha(const ARGB &inRGB) const { return inRGB.a; }
		inline const ARGB Mask(const uint8 &inAlpha) const { ARGB r; r.a=inAlpha; return r; }
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
			ARGB argb;
			argb.a = (inA * (*mRow) ) >> 8;
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

		bool ShouldSwap(PixelFormat inFormat) const
		{
			return (inFormat & pfSwapRB) != (mFormat & pfSwapRB);
		}


		mutable const PIXEL *mPos;
		int	mStride;
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
			c0 = mCol.c0; if (c0>127) c0++;
			c1 = mCol.c1; if (c1>127) c1++;
			c2 = mCol.c2; if (c2>127) c2++;
			mFormat = inFormat;

			if (inFormat==pfAlpha)
			{
				mComponentOffset = 0;
				mPixelStride = 1;
			}
			else
			{
				if (gC0IsRed == (bool)(inFormat & pfSwapRB))
					std::swap(c0,c2);

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
				mCol.a =	(a0*col.a)>>8;
				mCol.c0 =  (c0*col.c0)>>8;
				mCol.c1 =  (c1*col.c1)>>8;
				mCol.c2 =  (c2*col.c2)>>8;
			}
			else
			{
				mCol.a =  (a0 * *mPos)>>8;
			}
			mPos+=mPixelStride;
			return mCol;
		}
		bool ShouldSwap(PixelFormat inFormat) const
		{
			if (TINT_RGB)
			{
				return (inFormat & pfSwapRB) != (mFormat & pfSwapRB );
			}
			else
			{
				// In the alpha case, the order will be in the "natural" way (ie, c0 according to platform)
				if (inFormat & pfSwapRB)
					mCol.SwapRB();
				return false;
			}
		}

		int a0;
		int c0;
		int c1;
		int c2;
		PixelFormat mFormat;
		mutable ARGB mCol;
		mutable const uint8 *mPos;
		int	mComponentOffset;
		int	mPixelStride;
		int	mStride;
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


	template<bool SWAP_RB, bool DEST_ALPHA, typename DEST, typename SRC, typename MASK>
	void TTBlit( const DEST &outDest, const SRC &inSrc,const MASK &inMask,
					int inX, int inY, const Rect &inSrcRect)
	{
		for(int y=0;y<inSrcRect.h;y++)
		{
			outDest.SetPos(inX , inY + y );
			inMask.SetPos(inX , inY + y );
			inSrc.SetPos( inSrcRect.x, inSrcRect.y + y );
			for(int x=0;x<inSrcRect.w;x++)
			#ifdef HX_WINDOWS
				outDest.Next().Blend<SWAP_RB,DEST_ALPHA>(inMask.Mask(inSrc.Next()));
			#else
				if (!SWAP_RB && !DEST_ALPHA)
					outDest.Next().TBlend_00(inMask.Mask(inSrc.Next()));
				else if (!SWAP_RB && DEST_ALPHA)
					outDest.Next().TBlend_01(inMask.Mask(inSrc.Next()));
				else if (SWAP_RB && !DEST_ALPHA)
					outDest.Next().TBlend_10(inMask.Mask(inSrc.Next()));
				else
					outDest.Next().TBlend_11(inMask.Mask(inSrc.Next()));
			#endif
		}
	}

	template<typename DEST, typename SRC, typename MASK>
	void TBlit( const DEST &outDest, const SRC &inSrc,const MASK &inMask,
					int inX, int inY, const Rect &inSrcRect)
	{
		bool swap = inSrc.ShouldSwap(outDest.Format());
		bool dest_alpha = outDest.Format() & pfHasAlpha;

			if (swap)
			{
				if (dest_alpha)
					TTBlit<true,true,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect);
				else
					TTBlit<true,false,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect);
			}
			else
			{
				if (dest_alpha)
					TTBlit<false,true,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect);
				else
					TTBlit<false,false,DEST,SRC,MASK>(outDest,inSrc,inMask,inX,inY,inSrcRect);
			}
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

	template<bool SWAP, bool DEST_ALPHA,typename FUNC>
	inline void BlendFuncWithAlpha(ARGB &ioDest, ARGB &inSrc,FUNC F)
	{
		if (inSrc.a==0)
			return;
		if (SWAP) inSrc.SwapRB();
		ARGB val = inSrc;
		if (!DEST_ALPHA || ioDest.a>0)
		{
			F(val.c0,ioDest.c0);
			F(val.c1,ioDest.c1);
			F(val.c2,ioDest.c2);
		}
		if (DEST_ALPHA && ioDest.a<255)
		{
			int A = ioDest.a + (ioDest.a>>7);
			int A_ = 256-A;
			val.c0 = (val.c0 *A + inSrc.c0*A_)>>8;
			val.c1 = (val.c1 *A + inSrc.c1*A_)>>8;
			val.c2 = (val.c2 *A + inSrc.c2*A_)>>8;
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

	template<bool SWAP, bool DEST_ALPHA> void MultiplyFunc(ARGB &ioDest, ARGB inSrc)
		{ BlendFuncWithAlpha<SWAP,DEST_ALPHA>(ioDest,inSrc,DoMult()); }

	// --- Screen -----

	struct DoScreen
	{
		inline void operator()(uint8 &ioVal,uint8 inDest) const
		  { ioVal = 255 - (((255 - inDest) * ( 256 - ioVal - (ioVal>>7)))>>8); }
	};

	template<bool SWAP, bool DEST_ALPHA> void ScreenFunc(ARGB &ioDest, ARGB inSrc)
		{ BlendFuncWithAlpha<SWAP,DEST_ALPHA>(ioDest,inSrc,DoScreen()); }

	// --- Lighten -----

	struct DoLighten
	{
		inline void operator()(uint8 &ioVal,uint8 inDest) const
		{ if (inDest > ioVal ) ioVal = inDest; }
	};

	template<bool SWAP, bool DEST_ALPHA> void LightenFunc(ARGB &ioDest, ARGB inSrc)
		{ BlendFuncWithAlpha<SWAP,DEST_ALPHA>(ioDest,inSrc,DoLighten()); }

	// --- Darken -----

	struct DoDarken
	{
		inline void operator()(uint8 &ioVal,uint8 inDest) const
		{ if (inDest < ioVal ) ioVal = inDest; }
	};

	template<bool SWAP, bool DEST_ALPHA> void DarkenFunc(ARGB &ioDest, ARGB inSrc)
		{ BlendFuncWithAlpha<SWAP,DEST_ALPHA>(ioDest,inSrc,DoDarken()); }

	// --- Difference -----

	struct DoDifference
	{
		inline void operator()(uint8 &ioVal,uint8 inDest) const
		{ if (inDest < ioVal ) ioVal -= inDest; else ioVal = inDest-ioVal; }
	};

	template<bool SWAP, bool DEST_ALPHA> void DifferenceFunc(ARGB &ioDest, ARGB inSrc)
		{ BlendFuncWithAlpha<SWAP,DEST_ALPHA>(ioDest,inSrc,DoDifference()); }

	// --- Add -----

	struct DoAdd
	{
		inline void operator()(uint8 &ioVal,uint8 inDest) const
		{ ioVal = sgClamp0255[ioVal+inDest]; }
	};

	template<bool SWAP, bool DEST_ALPHA> void AddFunc(ARGB &ioDest, ARGB inSrc)
		{ BlendFuncWithAlpha<SWAP,DEST_ALPHA>(ioDest,inSrc,DoAdd()); }

	// --- Subtract -----

	struct DoSubtract
	{
		inline void operator()(uint8 &ioVal,uint8 inDest) const
		{ ioVal = sgClamp0255[inDest-ioVal]; }
	};

	template<bool SWAP, bool DEST_ALPHA> void SubtractFunc(ARGB &ioDest, ARGB inSrc)
		{ BlendFuncWithAlpha<SWAP,DEST_ALPHA>(ioDest,inSrc,DoSubtract()); }

	// --- Invert -----

	struct DoInvert
	{
		inline void operator()(uint8 &ioVal,uint8 inDest) const
		{ ioVal = 255 - inDest; }
	};

	template<bool SWAP, bool DEST_ALPHA> void InvertFunc(ARGB &ioDest, ARGB inSrc)
		{ BlendFuncWithAlpha<false,DEST_ALPHA>(ioDest,inSrc,DoInvert()); }

	// --- Alpha -----

	template<bool SWAP, bool DEST_ALPHA> void AlphaFunc(ARGB &ioDest, ARGB inSrc)
	{
		if (DEST_ALPHA)
			ioDest.a = (ioDest.a * ( inSrc.a + (inSrc.a>>7))) >> 8;
	}

	// --- Erase -----

	template<bool SWAP, bool DEST_ALPHA> void EraseFunc(ARGB &ioDest, ARGB inSrc)
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

	template<bool SWAP, bool DEST_ALPHA> void OverlayFunc(ARGB &ioDest, ARGB inSrc)
		{ BlendFuncWithAlpha<SWAP,DEST_ALPHA>(ioDest,inSrc,DoOverlay()); }

	// --- HardLight -----

	struct DoHardLight
	{
		inline void operator()(uint8 &ioVal,uint8 inDest) const
		{ if (ioVal>127) DoScreen()(ioVal,inDest); else DoMult()(ioVal,inDest); }
	};

	template<bool SWAP, bool DEST_ALPHA> void HardLightFunc(ARGB &ioDest, ARGB inSrc)
		{ BlendFuncWithAlpha<SWAP,DEST_ALPHA>(ioDest,inSrc,DoHardLight()); }

	// -- Set ---------

	template<bool SWAP, bool DEST_ALPHA> void CopyFunc(ARGB &ioDest, ARGB inSrc)
	{
		ioDest = inSrc;
	}

	// -- Inner ---------

	template<bool SWAP, bool DEST_ALPHA> void InnerFunc(ARGB &ioDest, ARGB inSrc)
	{
		int A = inSrc.a;
		if (A)
		{
			if (SWAP)
			{
				ioDest.c2 += ((inSrc.c0 - ioDest.c0)*A)>>8;
				ioDest.c1 += ((inSrc.c1 - ioDest.c1)*A)>>8;
				ioDest.c0 += ((inSrc.c2 - ioDest.c2)*A)>>8;
			}
			else
			{
				ioDest.c0 += ((inSrc.c0 - ioDest.c0)*A)>>8;
				ioDest.c1 += ((inSrc.c1 - ioDest.c1)*A)>>8;
				ioDest.c2 += ((inSrc.c2 - ioDest.c2)*A)>>8;
			}
		}
	}


	#define BLEND_METHOD(blend) blend<false,false>, blend<false,true>, blend<true,false>, blend<true,true>,

	BlendFunc sgBlendFuncs[] = 
	{
		0, 0, 0, 0, // Normal
		0, 0, 0, 0, // Layer
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
		bool swap = inSrc.ShouldSwap(outDest.Format());
		bool dest_alpha = outDest.Format() & pfHasAlpha;

		BlendFunc blend = sgBlendFuncs[inMode*4 + ( swap ? 2 : 0) + (dest_alpha?1:0)];

		for(int y=0;y<inSrcRect.h;y++)
		{
			outDest.SetPos(inX , inY + y );
			inMask.SetPos(inX , inY + y );
			inSrc.SetPos( inSrcRect.x, inSrcRect.y + y );
			for(int x=0;x<inSrcRect.w;x++)
				blend(outDest.Next(),inMask.Mask(inSrc.Next()));
		}
	}


}


#endif
