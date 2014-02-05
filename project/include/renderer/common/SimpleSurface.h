#ifndef RENDERER_SIMPLE_SURFACE_H
#define RENDERER_SIMPLE_SURFACE_H


#include "renderer/common/Surface.h"


namespace lime {
	
	
	class SimpleSurface : public Surface {
		
		public:
			
			SimpleSurface (int inWidth, int inHeight, PixelFormat inPixelFormat, int inByteAlign = 4, int inGPUPixelFormat = -1);
			
			virtual void BlitChannel (const RenderTarget &outTarget, const Rect &inSrcRect, int inPosX, int inPosY, int inSrcChannel, int inDestChannel) const;
			virtual void BlitTo (const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY, BlendMode inBlend, const BitmapCache *inMask, uint32 inTint = 0xffffff) const;
			virtual void colorTransform (const Rect &inRect, ColorTransform &inTransform);
			virtual void StretchTo (const RenderTarget &outTarget, const Rect &inSrcRect, const DRect &inDestRect) const;
			
			virtual void setGPUFormat (PixelFormat pf) { mGPUPixelFormat = pf; }
			
			void applyFilter (Surface *inSrc, const Rect &inRect, ImagePoint inOffset, Filter *inFilter);
			RenderTarget BeginRender (const Rect &inRect, bool inForHitTest);
			void Clear (uint32 inColour, const Rect *inRect);
			Surface *clone ();
			void createHardwareSurface ();
			void destroyHardwareSurface ();
			void dispose ();
			void dumpBits ();
			void EndRender ();
			void getColorBoundsRect(int inMask, int inCol, bool inFind, Rect &outRect);
			uint32 getPixel (int inX, int inY);
			void getPixels (const Rect &inRect, uint32 *outPixels, bool inIgnoreOrder = false, bool inLittleEndian = false);
			void multiplyAlpha ();
			void noise (unsigned int randomSeed, unsigned int low, unsigned int high, int channelOptions, bool grayScale);
			void scroll (int inDX, int inDY);
			void setPixel (int inX, int inY, uint32 inRGBA, bool inAlphaToo = false);
			void setPixels (const Rect &inRect, const uint32 *intPixels, bool inIgnoreOrder = false, bool inLittleEndian = false);
			void unmultiplyAlpha ();
			void Zero ();
			
			PixelFormat Format () const { return mPixelFormat; }
			const uint8 *GetBase () const { return mBase; }
			int GetStride () const { return mStride; }
			int	GPUFormat () const { return mGPUPixelFormat; }
			int Height () const { return mHeight; }
			int Width () const { return mWidth; }
		
		protected:
			
			~SimpleSurface ();
			
			uint8 *mBase;
			int mGPUPixelFormat;
			int	mHeight;
			PixelFormat	mPixelFormat;
			int mStride;
			int mWidth;
		
		private:
			
			SimpleSurface (const SimpleSurface &inRHS);
			
			void operator = (const SimpleSurface &inRHS);
		
	};
	
	
	enum {
		
		CHAN_ALPHA = 0x0008,
		CHAN_BLUE = 0x0004,
		CHAN_GREEN = 0x0002,
		CHAN_RED = 0x0001
		
	};
	
	
	template<bool SWAP, bool SRC_ALPHA, bool DEST_ALPHA>
	void TStretchTo (const SimpleSurface *inSrc, const RenderTarget &outTarget, const Rect &inSrcRect, const DRect &inDestRect) {
		
		Rect irect (inDestRect.x + 0.5, inDestRect.y + 0.5, inDestRect.x1 () + 0.5, inDestRect.y1 () + 0.5, true);
		Rect out = irect.Intersect (outTarget.mRect);
		if (!out.Area ())
			return;
		
		int dsx_dx = (inSrcRect.w << 16) / inDestRect.w;
		int dsy_dy = (inSrcRect.h << 16) / inDestRect.h;
		
		#ifndef STRETCH_BILINEAR
		
		// (Dx - inDestRect.x) * dsx_dx = ( Sx- inSrcRect.x )
		// Start first sample at out.x+0.5, and subtract 0.5 so src(1) is between first and second pixel
		//
		// Sx = (out.x+0.5-inDestRect.x)*dsx_dx + inSrcRect.x - 0.5

		//int sx0 = (int)((out.x-inDestRect.x*inSrcRect.w/inDestRect.w)*65536) +(inSrcRect.x<<16);
		//int sy0 = (int)((out.y-inDestRect.y*inSrcRect.h/inDestRect.h)*65536) +(inSrcRect.y<<16);
		int sx0 = (int)((out.x + 0.5 - inDestRect.x) * dsx_dx + (inSrcRect.x << 16));
		int sy0 = (int)((out.y + 0.5 - inDestRect.y) * dsy_dy + (inSrcRect.y << 16));
		
		for (int y = 0; y < out.h; y++) {
			
			ARGB *dest = (ARGB *)outTarget.Row (y + out.y) + out.x;
			int y_ = (sy0 >> 16);
			const ARGB *src = (const ARGB *)inSrc->Row (y_);
			sy0 += dsy_dy;
			
			int sx = sx0;
			for (int x = 0; x < out.w; x++) {
				
				ARGB s (src[sx >> 16]);
				sx += dsx_dx;
				if (SWAP) s.SwapRB ();
				if (!SRC_ALPHA) {
					
					if (DEST_ALPHA)
						s.a = 255;
					*dest++ = s;
					
				} else {
					
					if (!s.a)
						dest++;
					else if (s.a == 255)
						*dest++ = s;
					else if (DEST_ALPHA)
						dest++->QBlendA (s);
					else
						dest++->QBlend (s);
					
				}
				
			}
			
		}
		
		#else
		
		// todo - overflow testing
		// (Dx - inDestRect.x) * dsx_dx = ( Sx- inSrcRect.x )
		// Start first sample at out.x+0.5, and subtract 0.5 so src(1) is between first and second pixel
		//
		// Sx = (out.x+0.5-inDestRect.x)*dsx_dx + inSrcRect.x - 0.5
		int sx0 = (((((out.x - inDestRect.x) << 8) + 0x80) * (inSrcRect.w / inDestRect.w)) << 8) + (inSrcRect.x << 16) - 0x8000;
		int sy0 = (((((out.y - inDestRect.y) << 8) + 0x80) * (inSrcRect.h / inDestRect.h)) << 8) + (inSrcRect.y << 16) - 0x8000;
		int last_y = inSrcRect.y1 () - 1;
		ARGB s;
		s.a = 255;
		for (int y = 0; y < out.h; y++) {
			
			ARGB *dest = (ARGB *)outTarget.Row (y + out.y) + out.x;
			int y_ = (sy0 >> 16);
			int y_frac = sy0 & 0xffff;
			const ARGB *src0 = (const ARGB *)inSrc->Row (y_);
			const ARGB *src1 = (const ARGB *)inSrc->Row (y_ < last_y ? y_ + 1 : y_);
			sy0 += dsy_dy;
			
			int sx = sx0;
			for (int x = 0; x < out.w; x++) {
				
				int x_ = sx >> 16;
				int x_frac = sx & 0xffff;
				
				ARGB s00 (src0[x_]);
				ARGB s01 (src0[x_ + 1]);
				ARGB s10 (src1[x_]);
				ARGB s11 (src1[x_ + 1]);
				
				int c0_0 = s00.c0 + (((s01.c0 - s00.c0) * x_frac) >> 16);
				int c0_1 = s10.c0 + (((s11.c0 - s10.c0) * x_frac) >> 16);
				s.c0 = c0_0 + (((c0_1 - c0_0) * y_frac) >> 16);
				
				int c1_0 = s00.c1 + (((s01.c1 - s00.c1) * x_frac) >> 16);
				int c1_1 = s10.c1 + (((s11.c1 - s10.c1) * x_frac) >> 16);
				s.c1 = c1_0 + (((c1_1 - c1_0) * y_frac) >> 16);
				
				int c2_0 = s00.c2 + (((s01.c2 - s00.c2) * x_frac) >> 16);
				int c2_1 = s10.c2 + (((s11.c2 - s10.c2) * x_frac) >> 16);
				s.c2 = c2_0 + (((c2_1 - c2_0) * y_frac) >> 16);
				
				sx += dsx_dx;
				if (SWAP) s.SwapRB ();
				if (!SRC_ALPHA) {
					
					*dest++ = s;
					
				} else {
					
					int a_x0 = s00.a + (((s01.a - s00.a) * x_frac) >> 16);
					int a_x1 = s10.a + (((s11.a - s10.a) * x_frac) >> 16);
					s.a = a_x0 + (((a_x1 - a_x0) * y_frac) >> 16);
					
					if (!s.a)
						dest++;
					else if (s.a == 255)
						*dest++ = s;
					else if (DEST_ALPHA)
						dest++->QBlendA (s);
					else
						dest++->QBlend (s);
					
				}
				
			}
			
		}
		
		#endif
		
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
	class MinstdGenerator {
		
		public:
			
			MinstdGenerator (unsigned int seed) {
				
				if (seed == 0) {
					x = 1U;
				} else {
					x = seed;
				}
				
			}
			
			unsigned int operator () () {
				
				const unsigned int a = 16807U;
				const unsigned int m = (1U << 31) - 1;
				
				unsigned int lo = a * (x & 0xffffU);
				unsigned int hi = a * (x >> 16);
				lo += (hi & 0x7fffU) << 16;
				
				if (lo > m) {
					
					lo &= m;
					++lo;
					
				}
				
				lo += hi >> 15;
				
				if (lo > m) {
					
					lo &= m;
					++lo;
					
				}
				
				x = lo;
				
				return x;
				
			}
		
		private:
			
			unsigned int x;
		
	};
	
	
}


#endif
