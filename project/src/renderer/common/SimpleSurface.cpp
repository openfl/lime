#include "renderer/common/SimpleSurface.h"
#include "renderer/common/BlendMode.h"


namespace lime {
	
	
	SimpleSurface::SimpleSurface (int inWidth, int inHeight, PixelFormat inPixelFormat, int inByteAlign, int inGPUFormat) {
		
		mWidth = inWidth;
		mHeight = inHeight;
		mTexture = 0;
		mPixelFormat = inPixelFormat;
		mGPUPixelFormat = inPixelFormat;
		
		if (inGPUFormat == -1) {
			
			int pix_size = inPixelFormat == pfAlpha ? 1 : 4;
			if (inByteAlign > 1) {
				
				mStride = inWidth * pix_size + inByteAlign - 1;
				mStride -= mStride % inByteAlign;
				
			} else {
				
				mStride = inWidth * pix_size;
				
			}
			
			mBase = new unsigned char[mStride * mHeight + 1];
			mBase[mStride * mHeight] = 69;
			
		} else {
			
			mStride = 0;
			mBase = 0;
			if (inGPUFormat != 0)
				mGPUPixelFormat = inGPUFormat;
			
			createHardwareSurface ();
			
		}
		
	}
	
	
	SimpleSurface::~SimpleSurface () {
		
		if (mBase) {
			
			if (mBase[mStride * mHeight] != 69)
				ELOG ("Image write overflow");
			delete [] mBase;
			
		}
		
	}
	
	
	void SimpleSurface::applyFilter (Surface *inSrc, const Rect &inRect, ImagePoint inOffset, Filter *inFilter) {
		
		if (!mBase) return;
		FilterList f;
		f.push_back (inFilter);
		
		Rect src_rect (inRect.w, inRect.h);
		Rect dest = GetFilteredObjectRect (f, src_rect);
		
		inSrc->IncRef ();
		Surface *result = FilterBitmap (f, inSrc, src_rect, dest, false, ImagePoint (inRect.x, inRect.y));
		
		dest.Translate (inOffset.x, inOffset.y);
		
		src_rect = Rect (0, 0, result->Width (), result->Height ());
		int dx = dest.x;
		int dy = dest.y;
		dest = dest.Intersect (Rect (0, 0, mWidth, mHeight));
		dest.Translate (-dx, -dy);
		dest = dest.Intersect (src_rect);
		dest.Translate (dx, dy);
		
		int bpp = BytesPP ();
		
		RenderTarget t = BeginRender (dest, false);
		//printf("Copy back @ %d,%d %dx%d  + (%d,%d)\n", dest.x, dest.y, t.Width(), t.Height(), dx, dy);
		for (int y = 0; y < t.Height (); y++)
			memcpy ((void *)(t.Row (y + dest.y) + ((dest.x) * bpp)), result->Row (y - dy) - (dx * bpp), dest.w * bpp);
		
		EndRender ();
		
		result->DecRef ();
		
	}
	
	
	RenderTarget SimpleSurface::BeginRender (const Rect &inRect, bool inForHitTest) {
		
		if (!mBase)
			return RenderTarget ();
		
		Rect r = inRect.Intersect (Rect (0, 0, mWidth, mHeight));
		if (mTexture)
			mTexture->Dirty (r);
		mVersion++;
		return RenderTarget (r, mPixelFormat, mBase, mStride);
		
	}
	
	
	void SimpleSurface::BlitChannel (const RenderTarget &outTarget, const Rect &inSrcRect, int inPosX, int inPosY, int inSrcChannel, int inDestChannel) const {
		
		bool src_alpha = (mPixelFormat == pfAlpha);
		bool dest_alpha = (outTarget.mPixelFormat == pfAlpha);
		
		// Flash API does not have alpha images (might be useful somewhere else?)
		if (src_alpha || dest_alpha)
			return;
		
		if (inDestChannel == CHAN_ALPHA && !(outTarget.Format () & pfHasAlpha))
			return;
		
		bool set_255 = (inSrcChannel == CHAN_ALPHA && !(mPixelFormat & pfHasAlpha));
		
		// Translate inSrcRect src_rect to dest ...
		Rect src_rect (inPosX, inPosY, inSrcRect.w, inSrcRect.h);
		// clip ...
		src_rect = src_rect.Intersect (outTarget.mRect);
		
		// translate back to source-coordinates ...
		src_rect.Translate (inSrcRect.x - inPosX, inSrcRect.y - inPosY);
		// clip to origial rect...
		src_rect = src_rect.Intersect (inSrcRect);
		
		if (src_rect.HasPixels ()) {
			
			int dx = inPosX + src_rect.x;
			int dy = inPosY + src_rect.y;
			
			bool c0_red = gC0IsRed != ((mPixelFormat & pfSwapRB) != 0);
			int src_ch = (inSrcChannel == CHAN_ALPHA ? 3 : inSrcChannel == CHAN_BLUE ? (c0_red ? 2 : 0) : inSrcChannel == CHAN_GREEN ? 1 : (c0_red ? 0 : 2));
			
			c0_red = gC0IsRed != ((outTarget.Format () & pfSwapRB) != 0);
			int dest_ch = (inDestChannel == CHAN_ALPHA ? 3 : inDestChannel == CHAN_BLUE ? (c0_red ? 2 : 0) : inDestChannel == CHAN_GREEN ? 1 : (c0_red ? 0 : 2));
			
			for (int y = 0; y < src_rect.h; y++) {
				
				uint8 *d = outTarget.Row (y + dy) + (dx * 4) + dest_ch;
				if (set_255) {
					
					for (int x = 0; x < src_rect.w; x++) {
						
						*d = 255;
						d += 4;
						
					}
					
				} else {
					
					const uint8 *s = Row (y + src_rect.y) + (src_rect.x * 4) + src_ch;
					
					for(int x = 0; x < src_rect.w; x++) {
						
						*d = *s;
						d += 4;
						s += 4;
						
					}
					
				}
				
			}
			
		}
		
	}
	
	
	void SimpleSurface::BlitTo (const RenderTarget &outDest, const Rect &inSrcRect, int inPosX, int inPosY, BlendMode inBlend, const BitmapCache *inMask, uint32 inTint) const {
		
		if (!mBase)
			return;
		
		// Translate inSrcRect src_rect to dest ...
		Rect src_rect (inPosX, inPosY, inSrcRect.w, inSrcRect.h);
		// clip ...
		src_rect = src_rect.Intersect (outDest.mRect);
		
		if (inMask)
			src_rect = src_rect.Intersect (inMask->GetRect ());
		
		// translate back to source-coordinates ...
		src_rect.Translate (inSrcRect.x-inPosX, inSrcRect.y - inPosY);
		// clip to origial rect...
		src_rect = src_rect.Intersect (inSrcRect);
		
		if (src_rect.HasPixels ()) {
			
			bool src_alpha = (mPixelFormat == pfAlpha);
			bool dest_alpha = (outDest.mPixelFormat == pfAlpha);
			
			int dx = inPosX + src_rect.x - inSrcRect.x;
			int dy = inPosY + src_rect.y - inSrcRect.y;
			
			// Check for overlap....
			if (src_alpha == dest_alpha) {
				
				int size_shift = (src_alpha ? 0 : 2);
				int d_base = (outDest.mSoftPtr - mBase);
				int y_off = d_base / mStride;
				int x_off = (d_base - y_off * mStride) >> size_shift;
				Rect dr (dx + x_off, dy + y_off, src_rect.w, src_rect.h);
				if (src_rect.Intersect (dr).HasPixels ()) {
					
					SimpleSurface sub (src_rect.w, src_rect.h, mPixelFormat);
					Rect sub_dest (0, 0, src_rect.w, src_rect.h);
					
					for (int y = 0; y < src_rect.h; y++)
						memcpy ((void *)sub.Row (y), Row (src_rect.y + y) + (src_rect.x << size_shift), src_rect.w << size_shift);
					
					sub.BlitTo (outDest, sub_dest, dx, dy, inBlend, 0, inTint);
					return;
					
				}
				
			}
			
			// Blitting to alpha image - can ignore blend mode
			if (dest_alpha) {
				
				ImageDest<uint8> dest (outDest);
				if (inMask) {
					
					if (src_alpha)
						TBlitAlpha (dest, ImageSource<uint8> (mBase, mStride, mPixelFormat), ImageMask (*inMask), dx, dy, src_rect);
					else
						TBlitAlpha (dest, ImageSource<ARGB> (mBase, mStride, mPixelFormat), ImageMask (*inMask), dx, dy, src_rect);
					
				} else {
					
					if (src_alpha)
						TBlitAlpha (dest, ImageSource<uint8> (mBase, mStride, mPixelFormat), NullMask (), dx, dy, src_rect);
					else
						TBlitAlpha (dest, ImageSource<ARGB> (mBase, mStride, mPixelFormat), NullMask (), dx, dy, src_rect);
					
				}
				
				return;
				
			}
			
			ImageDest<ARGB> dest (outDest);
			bool tint = (inBlend == bmTinted);
			bool tint_inner = (inBlend == bmTintedInner);
			bool tint_add = (inBlend == bmTintedAdd);
			
			// Blitting tint, we can ignore blend mode too (this is used for rendering text)
			if (tint) {
				
				if (src_alpha) {
					
					TintSource<false> src (mBase, mStride, inTint, mPixelFormat);
					if (inMask)
						TBlit (dest, src, ImageMask (*inMask), dx, dy, src_rect);
					else
						TBlit (dest, src, NullMask (), dx, dy, src_rect);
					
				} else {
					
					TintSource<false, true> src (mBase, mStride, inTint, mPixelFormat);
					if (inMask)
						TBlit (dest, src, ImageMask (*inMask), dx, dy, src_rect);
					else
						TBlit (dest, src, NullMask (), dx, dy, src_rect);
					
				}
				
			} else if (tint_inner) {
				
				TintSource<true> src (mBase, mStride, inTint, mPixelFormat);
				
				if (inMask)
					TBlitBlend (dest, src, ImageMask (*inMask), dx, dy, src_rect, bmInner);
				else
					TBlitBlend (dest, src, NullMask (), dx, dy, src_rect, bmInner);
				
			} else if (tint_add) {
				
				TintSource<false, true> src (mBase, mStride, inTint, mPixelFormat);
				
				if (inMask)
					TBlitBlend (dest, src, ImageMask (*inMask), dx, dy, src_rect, bmAdd);
				else
					TBlitBlend (dest, src, NullMask (), dx, dy, src_rect, bmAdd);
				
			} else if (src_alpha) {
				
				ImageSource<uint8> src (mBase, mStride, mPixelFormat);
				if (inBlend == bmNormal || inBlend == bmLayer) {
					
					if (inMask)
						TBlit (dest, src, ImageMask (*inMask), dx, dy, src_rect);
					else
						TBlit (dest, src, NullMask (), dx, dy, src_rect);
					
				} else {
					
					if (inMask)
						TBlitBlend (dest, src, ImageMask (*inMask), dx, dy, src_rect, inBlend);
					else
						TBlitBlend (dest, src, NullMask (), dx, dy, src_rect, inBlend);
					
				}
				
			} else {
				
				ImageSource<ARGB> src (mBase, mStride, mPixelFormat);
				if (inBlend == bmNormal || inBlend == bmLayer) {
					
					if (inMask)
						TBlit (dest, src, ImageMask (*inMask), dx, dy, src_rect);
					else
						TBlit (dest, src, NullMask (), dx, dy, src_rect);
					
				} else {
					
					if (inMask)
						TBlitBlend (dest, src, ImageMask (*inMask), dx, dy, src_rect, inBlend);
					else
						TBlitBlend (dest, src, NullMask (), dx, dy, src_rect, inBlend);
					
				}
				
			}
			
		}
		
	}
	
	
	void SimpleSurface::Clear (uint32 inColour, const Rect *inRect) {
		
		if (!mBase)
			return;
		
		ARGB rgb (inColour | ((mPixelFormat & pfHasAlpha) ? 0 : 0xFF000000));
		if (mPixelFormat == pfAlpha) {
			
			memset (mBase, rgb.a, mStride * mHeight);
			return;
			
		}
		
		if (mPixelFormat & pfSwapRB)
			rgb.SwapRB ();
		
		int x0 = inRect ? inRect->x  : 0;
		int x1 = inRect ? inRect->x1 () : Width ();
		int y0 = inRect ? inRect->y : 0;
		int y1 = inRect ? inRect->y1 () : Height ();
		if (x0 < 0) x0 = 0;
		if (x1 > Width ()) x1 = Width ();
		if (y0 < 0) y0 = 0;
		if (y1 > Height ()) y1 = Height ();
		if (x1 <= x0 || y1 <= y0)
			return;
		for (int y = y0; y < y1; y++) {
			
			uint32 *ptr = (uint32 *)(mBase + (y * mStride)) + x0;
			for (int x = x0; x < x1; x++)
				*ptr++ = rgb.ival;
			
		}
		if (mTexture)
			mTexture->Dirty (Rect (x0, y0, x1 - x0, y1 - y0));
		
	}
	
	
	Surface *SimpleSurface::clone () {
		
		SimpleSurface *copy = new SimpleSurface (mWidth, mHeight, mPixelFormat, 1, mBase ? -1 : 0);
		if (mBase)
			for (int y = 0; y < mHeight; y++)
				memcpy (copy->mBase + (copy->mStride * y), mBase + (mStride * y), mWidth * (mPixelFormat == pfAlpha ? 1 : 4));
		
		copy->SetAllowTrans (mAllowTrans);
		copy->IncRef ();
		return copy;
		
	}
	
	
	void SimpleSurface::colorTransform (const Rect &inRect, ColorTransform &inTransform) {
		
		if (mPixelFormat == pfAlpha || !mBase)
			return;
		
		const uint8 *ta = inTransform.GetAlphaLUT ();
		const uint8 *t0 = inTransform.GetC0LUT ();
		const uint8 *t1 = inTransform.GetC1LUT ();
		const uint8 *t2 = inTransform.GetC2LUT ();
		
		RenderTarget target = BeginRender (inRect, false);
		
		Rect r = target.mRect;
		for (int y = 0; y < r.h; y++) {
			
			ARGB *rgb = ((ARGB *)target.Row (y + r.y)) + r.x;
			for (int x = 0; x < r.w; x++) {
				
				rgb->c0 = t0[rgb->c0];
				rgb->c1 = t1[rgb->c1];
				rgb->c2 = t2[rgb->c2];
				rgb->a = ta[rgb->a];
				rgb++;
				
			}
			
		}
		
		EndRender ();
		
	}
	
	
	void SimpleSurface::createHardwareSurface () {
		
		if (lime::HardwareContext::current == NULL)
			printf ("Null Hardware Context");
		else
			GetOrCreateTexture (*lime::HardwareContext::current);
		
	}
	
	
	void SimpleSurface::destroyHardwareSurface () {
		
		if (mTexture) {
			
			delete mTexture;
			mTexture = 0;
			
		}
		
	}
	
	
	void SimpleSurface::dispose () {
		
		destroyHardwareSurface ();
		if (mBase) {
			
			if (mBase[mStride * mHeight] != 69) {
				
				ELOG ("Image write overflow");
				
			}
			delete [] mBase;
			mBase = NULL;
			
		}
		
	}
	
	
	void SimpleSurface::dumpBits () {
		
		if (mBase) {
			
			createHardwareSurface ();
			delete [] mBase;
			mBase = NULL;
			
		}
		
	}
	
	
	void SimpleSurface::EndRender () {}
	
	
	void SimpleSurface::getColorBoundsRect (int inMask, int inCol, bool inFind, Rect &outRect) {
		
		if (!mBase)
			return;
		
		int w = Width ();
		int h = Height ();
		
		if (w == 0 || h == 0 || mPixelFormat == pfAlpha) {
			
			outRect = Rect ();
			return;
			
		}
		
		bool swap = ((bool)(mPixelFormat & pfSwapRB) != gC0IsRed);
		if (swap) {
			
			inMask = ARGB::Swap (inMask);
			inCol = ARGB::Swap (inCol);
			
		}
		
		int min_x = w + 1;
		int max_x = -1;
		int min_y = h + 1;
		int max_y = -1;
		
		for (int y = 0; y < h; y++) {
			
			int *pixel = (int *)(mBase + (y * mStride));
			for (int x = 0; x < w; x++) {
				
				if ((((*pixel++)&inMask) == inCol) == inFind) {
					
					if (x < min_x) min_x = x;
					if (x > max_x) max_x = x;
					if (y < min_y) min_y = y;
					if (y > max_y) max_y = y;
					
				}
				
			}
			
		}
		
		if (min_x > max_x)
			outRect = Rect (0, 0, 0, 0);
		else
			outRect = Rect (min_x, min_y, max_x - min_x + 1, max_y - min_y + 1);
		
	}
	
	
	uint32 SimpleSurface::getPixel (int inX, int inY) {
		
		if (inX < 0 || inY < 0 || inX >= mWidth || inY >= mHeight || !mBase)
			return 0;
		
		if (mPixelFormat == pfAlpha)
			return mBase[inY*mStride + inX] << 24;
		
		if ((bool)(mPixelFormat & pfSwapRB) == gC0IsRed)
			return ((uint32 *)(mBase + (inY * mStride)))[inX];
		
		return ARGB::Swap (((int *)(mBase + (inY * mStride)))[inX]);
		
	}
	
	
	void SimpleSurface::getPixels (const Rect &inRect, uint32 *outPixels, bool inIgnoreOrder, bool inLittleEndian) {
		
		if (!mBase)
			return;
		
		Rect r = inRect.Intersect (Rect (0, 0, Width (), Height ()));
		bool swap = ((bool)(mPixelFormat & pfSwapRB) != gC0IsRed);
		
		for (int y = 0; y < r.h; y++) {
			
			uint8 *src = mBase + ((r.y + y) * mStride) + (r.x * (mPixelFormat == pfAlpha ? 1 : 4));
			if (mPixelFormat == pfAlpha) {
				
				for (int x = 0; x < r.w; x++)
					*outPixels++ = (*src++) << 24;
				
			} else if (inIgnoreOrder) {
				
				memcpy (outPixels, src, r.w * 4);
				outPixels += r.w;
				
			} else {
				
				uint8 *a = src + 3;
				uint8 *pix = (uint8 *)outPixels;
				
				// IO in little endian
				if (inLittleEndian) {
					
					if (!swap) {
						
						memcpy (pix, src, r.w * sizeof (int));
						src += r.w * sizeof (int);
						
					} else {
						
						for (int x = 0; x < r.w; x++) {
							
							*pix++ = src[2];
							*pix++ = src[1];
							*pix++ = src[0];
							*pix++ = src[3];
							src += 4;
							
						}
						
					}
					
				} else {
					
					// Must output big-endian, while memory is stored little-endian
					a = src;
					if (!swap) {
						
						for (int x = 0; x < r.w; x++) {
							
							*pix++ = src[3];
							*pix++ = src[2];
							*pix++ = src[1];
							*pix++ = src[0];
							src += 4;
							
						}
						
					} else {
						
						for (int x = 0; x < r.w; x++) {
							
							*pix++ = src[3];
							*pix++ = src[0];
							*pix++ = src[1];
							*pix++ = src[2];
							src += 4;
							
						}
						
					}
					
				}
				outPixels += r.w;
				
				if (!(mPixelFormat & pfHasAlpha)) {
					
					for (int x = 0; x < r.w; x++) {
						
						*a = 255;
						a += 4;
						
					}
					
				}
				
			}
			
		}
		
	}
	
	
	void SimpleSurface::multiplyAlpha () {
		
		if (!mBase)
			return;
		if (mFlags & SURF_FLAGS_HAS_PREMULTIPLIED_ALPHA)
			return;
		
		Rect r = Rect (0, 0, mWidth, mHeight);
		mVersion++;
		if (mTexture)
			mTexture->Dirty (r);
		
		if (mPixelFormat == pfAlpha)
			return;
			
		//converted to uint 
		//converted to float
		//got rid of the premultiply so that we can allow compiler to pipeline computation
		//cuz ARM instr have that mul load shift greatness
		uint8 a;
		float multiply = 0.0f;
		int stride = mStride;
		uint8 *dest = 0;
		
		for (int y = 0; y < r.h; y++) {
			dest = mBase + ((r.y + y) * stride) + (r.x << 2);
			
			for (int x = 0; x < r.w; x++) {
				a = *(dest + 3);
				*dest = (uint8) (*dest * a * 0.0039215686274509803921568627451f);
				*(dest + 1) = (uint8) (*(dest + 1) * a * 0.0039215686274509803921568627451f);
				*(dest + 2) = (uint8) (*(dest + 2) * a * 0.0039215686274509803921568627451f);
				
				dest += 4;
			}
			
		}
		
		mFlags |= SURF_FLAGS_HAS_PREMULTIPLIED_ALPHA;
		
	}
	
	
	void SimpleSurface::noise (unsigned int randomSeed, unsigned int low, unsigned int high, int channelOptions, bool grayScale) {
		
		if (!mBase)
			return;
		
		MinstdGenerator generator (randomSeed);
		
		RenderTarget target = BeginRender (Rect (0, 0, mWidth, mHeight), false);
		ARGB tmpRgb;
		
		for (int y = 0; y < mHeight; y++) {
			
			ARGB *rgb = ((ARGB *)target.Row (y));
			for (int x = 0; x < mWidth; x++) {
				
				if (grayScale) {
					
					tmpRgb.c0 = tmpRgb.c1 = tmpRgb.c2 = low + generator () % (high - low + 1);
					
				} else {
					
					if (channelOptions & CHAN_RED) {
						
						tmpRgb.c2 = low + generator () % (high - low + 1);
						
					} else {
						
						tmpRgb.c2 = 0;
						
					}
					
					if (channelOptions & CHAN_GREEN) {
						
						tmpRgb.c1 = low + generator () % (high - low + 1);
						
					} else {
						
						tmpRgb.c1 = 0;
						
					}
					
					if (channelOptions & CHAN_BLUE) {
						
						tmpRgb.c0 = low + generator () % (high - low + 1);
						
					} else {
						
						tmpRgb.c0 = 0;
						
					}
					
				}
				
				if (channelOptions & CHAN_ALPHA) {
					
					tmpRgb.a = low + generator () % (high - low + 1);
					
				} else {
					
					tmpRgb.a = 255;
					
				}
				
				if ((bool)(mPixelFormat & pfSwapRB) == gC0IsRed) {
					
					*rgb = tmpRgb;
					
				} else {
					
					rgb->SetSwapRGBA (tmpRgb);
					
				}
				
				rgb++;
				
			}
			
		}
		
		EndRender ();
		
	}
	
	
	void SimpleSurface::scroll (int inDX, int inDY) {
		
		if ((inDX == 0 && inDY == 0) || !mBase) return;
		
		Rect src (0, 0, mWidth, mHeight);
		src = src.Intersect (src.Translated (inDX, inDY)).Translated (-inDX, -inDY);
		int pixels = src.Area ();
		if (!pixels)
			return;
		
		uint32 *buffer = (uint32 *)malloc (pixels * sizeof (int));
		getPixels (src, buffer, true);
		src.Translate (inDX, inDY);
		setPixels (src, buffer, true);
		free (buffer);
		mVersion++;
		if (mTexture)
			mTexture->Dirty (src);
		
	}
	
	
	void SimpleSurface::setPixel (int inX, int inY, uint32 inRGBA, bool inAlphaToo) {
		
		if (inX < 0 || inY < 0 || inX >= mWidth || inY >= mHeight || !mBase)
			return;
		
		mVersion++;
		if (mTexture)
			mTexture->Dirty (Rect (inX, inY, 1, 1));
		
		if (inAlphaToo) {
			
			if(mPixelFormat == pfXRGB)
				mPixelFormat = pfARGB;
			if (mPixelFormat == pfAlpha)
				mBase[inY*mStride + inX] = inRGBA >> 24;
			else if ((bool)(mPixelFormat & pfSwapRB) == gC0IsRed)
				((uint32 *)(mBase + (inY * mStride)))[inX] = inRGBA;
			else
				((int *)(mBase + (inY * mStride)))[inX] = ARGB::Swap (inRGBA);
			
		} else {
			
			if (mPixelFormat != pfAlpha) {
				
				int &pixel = ((int *)(mBase + (inY * mStride)))[inX];
				inRGBA = (inRGBA & 0xffffff) | (pixel & 0xff000000);
				if ((bool)(mPixelFormat & pfSwapRB) == gC0IsRed)
					pixel = inRGBA;
				else
					pixel = ARGB::Swap (inRGBA);
				
			}
			
		}
		
	}
	
	
	void SimpleSurface::setPixels (const Rect &inRect, const uint32 *inPixels, bool inIgnoreOrder, bool inLittleEndian) {
		
		if (!mBase)
			return;
		
		Rect r = inRect.Intersect (Rect (0, 0, Width (), Height ()));
		mVersion++;
		if (mTexture)
			mTexture->Dirty (r);

		const uint8 *src = (const uint8 *)inPixels;
		bool swap  = ((bool)(mPixelFormat & pfSwapRB) != gC0IsRed);
		
		if (mAllowTrans && mPixelFormat == pfXRGB)
			mPixelFormat = pfARGB;
		
		for (int y = 0; y < r.h; y++) {
			
			uint8 *dest = mBase + ((r.y + y) * mStride) + (r.x * (mPixelFormat == pfAlpha ? 1 : 4));
			if (mPixelFormat == pfAlpha) {
				
				for (int x = 0; x < r.w; x++)
					*dest++ = (*inPixels++) >> 24;
				
			} else if (inIgnoreOrder) {
				
				if (mAllowTrans) {
					
					memcpy (dest, inPixels, r.w * 4);
					inPixels += r.w;
					
				} else {
					
					for (int x = 0; x < r.w; x++) {
						
						*dest++ = src[0];
						*dest++ = src[1];
						*dest++ = src[2];
						*dest++ = 0xff;
						src += 4;
						
					}
					
				}
				
			} else {
				
				if (inLittleEndian) {
					
					if (!swap) {
						
						if (mAllowTrans) {
							
							memcpy (dest, src, r.w * sizeof (int));
							src += r.w * sizeof (int);
							
						} else {
							
							for (int x = 0; x < r.w; x++) {
								
								*dest++ = src[0];
								*dest++ = src[1];
								*dest++ = src[2];
								*dest++ = 0xff;
								src += 4;
								
							}
							
						}
						
					} else {
						
						for (int x = 0; x < r.w; x++) {
							
							*dest++ = src[2];
							*dest++ = src[1];
							*dest++ = src[0];
							*dest++ = mAllowTrans ? src[3] : 0xff;
							src += 4;
							
						}
						
					}
					
				} else {
					
					if (!swap) {
						
						for (int x = 0; x < r.w; x++) {
							
							*dest++ = src[3];
							*dest++ = src[2];
							*dest++ = src[1];
							*dest++ = mAllowTrans ? src[0] : 0xff;
							src += 4;
							
						}
						
					} else {
						
						for (int x = 0; x < r.w; x++) {
							
							*dest++ = src[1];
							*dest++ = src[2];
							*dest++ = src[3];
							*dest++ = mAllowTrans ? src[0] : 0xff;
							src += 4;
							
						}
						
					}
					
				}
				
			}
			
		}
		
	}
	
	
	void SimpleSurface::StretchTo (const RenderTarget &outTarget, const Rect &inSrcRect, const DRect &inDestRect) const {
		
		// Only RGB supported
		if (mPixelFormat == pfAlpha || outTarget.mPixelFormat == pfAlpha)
			return;
		
		bool swap = (outTarget.mPixelFormat & pfSwapRB) != (mPixelFormat & pfSwapRB);
		bool dest_has_alpha = outTarget.mPixelFormat & pfHasAlpha;
		bool src_has_alpha = mPixelFormat &  pfHasAlpha;
		
		if (swap) {
			
			if (src_has_alpha) {
				
				if (dest_has_alpha)
					TStretchTo<true, true, true> (this, outTarget, inSrcRect, inDestRect);
				else
					TStretchTo<true, true, false> (this, outTarget, inSrcRect, inDestRect);
				
			} else {
				
				if (dest_has_alpha)
					TStretchTo<true, false, true> (this, outTarget, inSrcRect, inDestRect);
				else
					TStretchTo<true, false, false> (this, outTarget, inSrcRect, inDestRect);
				
			}
			
		} else {
			
			if (src_has_alpha) {
				
				if (dest_has_alpha)
					TStretchTo<false, true, true> (this, outTarget, inSrcRect, inDestRect);
				else
					TStretchTo<false, true, false> (this, outTarget, inSrcRect, inDestRect);
				
			} else {
				
				if (dest_has_alpha)
					TStretchTo<false, false, true> (this, outTarget, inSrcRect, inDestRect);
				else
					TStretchTo<false, false, false> (this, outTarget, inSrcRect, inDestRect);
				
			}
			
		}
		
	}
	
	
	void SimpleSurface::unmultiplyAlpha () {
		
		if (!mBase)
			return;
		Rect r = Rect (0, 0, mWidth, mHeight);
		mVersion++;
		if (mTexture)
			mTexture->Dirty (r);
		
		if (mPixelFormat == pfAlpha)
			return;
		int a;
		double unmultiply;
		
		for (int y = 0; y < r.h; y++) {
			
			uint8 *dest = mBase + ((r.y + y) * mStride) + (r.x * 4);
			for (int x = 0; x < r.w; x++) {
				
				a = *(dest + 3);
				if (a != 0) {
					
					unmultiply = 255.0 / a;
					*dest = sgClamp0255[int((*dest) * unmultiply)];
					*(dest + 1) = sgClamp0255[int(*(dest + 1) * unmultiply)];
					*(dest + 2) = sgClamp0255[int(*(dest + 2) * unmultiply)];
					
				}
				
				dest += 4;
				
			}
			
		}
		
		mFlags &= ~SURF_FLAGS_HAS_PREMULTIPLIED_ALPHA;
		
	}
	
	
	void SimpleSurface::Zero () {
		
		if (mBase)
			memset (mBase, 0, mStride * mHeight);
		
	}
	
	
}
