#include "renderer/common/BitmapCache.h"


namespace lime {
	
	
	static int sBitmapVersion = 1;
	
	
	BitmapCache::BitmapCache (Surface *inSurface, const Transform &inTrans, const Rect &inRect, bool inMaskOnly, BitmapCache *inMask) {
		
		mBitmap = inSurface->IncRef ();
		mMatrix = *inTrans.mMatrix;
		mScale9 = *inTrans.mScale9;
		mRect = inRect;
		mVersion = sBitmapVersion++;
		if (!mVersion)
			mVersion = sBitmapVersion++;
		mMaskVersion = inMask ? inMask->mVersion : 0;
		mMaskOffset = inMask ? ImagePoint (inMask->mTX, inMask->mTY) : ImagePoint (0, 0);
		mTX = mTY = 0;
		
	}
	
	
	BitmapCache::~BitmapCache () {
		
		mBitmap->DecRef ();
		
	}
	
	
	const uint8 *BitmapCache::DestRow (int inRow) const {
		
		return mBitmap->Row (inRow-(mRect.y+mTY)) - mBitmap->BytesPP () * (mRect.x + mTX);
		
	}
	
	
	PixelFormat BitmapCache::Format () const {
		
		return mBitmap->Format ();
		
	}
	
	
	bool BitmapCache::HitTest (double inX, double inY) {
		
		double x0 = mRect.x + mTX;
		double y0 = mRect.y + mTY;
		//printf("BMP hit %f,%f    %f,%f ... %d,%d\n", inX, inY, x0,y0, mRect.w, mRect.h );
		return x0 <= inX && y0 <= inY && (inX <= (x0 + mRect.w)) && (inY <= (y0 + mRect.h));
		
	}
	
	
	void BitmapCache::PopTargetOffset (ImagePoint &inBuffer) {
		
		mTX = inBuffer.x;
		mTY = inBuffer.y;
		
	}
	
	
	void BitmapCache::PushTargetOffset (const ImagePoint &inOffset, ImagePoint &outBuffer) {
		
		outBuffer = ImagePoint (mTX, mTY);
		mTX -= inOffset.x;
		mTY -= inOffset.y;
		
	}
	
	
	void BitmapCache::Render (const RenderTarget &inTarget, const Rect &inClipRect, const BitmapCache *inMask, BlendMode inBlend) {
		
		if (mBitmap) {
			
			int tint = 0xffffffff;
			if (inTarget.mPixelFormat != pfAlpha && mBitmap->Format () == pfAlpha)
				tint = 0xff000000;
			
			Rect src (mRect.x + mTX, mRect.y + mTY, mRect.w, mRect.h);
			int ox = src.x;
			int oy = src.y;
			src = src.Intersect (inClipRect);
			if (!src.HasPixels ())
				return;
			ox -= src.x;
			oy -= src.y;
			src.Translate (-mRect.x - mTX, -mRect.y - mTY);
			
			if (inTarget.IsHardware ()) {
				
				//__android_log_print(ANDROID_LOG_INFO,"BitmapCache", "Render %dx%d + (%d,%d) -> %dx%d + (%d,%d)",
					  //mRect.w,mRect.h, mRect.x + mTX , mRect.y+mTY,
					  //inTarget.mRect.w, inTarget.mRect.h, inTarget.mRect.x, inTarget.mRect.y );
				inTarget.mHardware->SetViewport (inTarget.mRect);
				inTarget.mHardware->BeginBitmapRender (mBitmap, tint);
				inTarget.mHardware->RenderBitmap (src, mRect.x + mTX - ox, mRect.y + mTY - oy);
				inTarget.mHardware->EndBitmapRender ();
				
			} else {
				
				// TX,TX is set in StillGood function
				mBitmap->BlitTo (inTarget, src, mRect.x + mTX - ox, mRect.y + mTY - oy, inBlend, inMask, tint);
				
			}
			
		}
		
	}
	
	
	const uint8 *BitmapCache::Row (int inRow) const {
		
		return mBitmap->Row (inRow);
		
	}
	
	
	bool BitmapCache::StillGood (const Transform &inTransform, const Rect &inVisiblePixels, BitmapCache *inMask) {
		
		// TODO: Need to break the cache for certain operations, for quality?
		if (!mMatrix.IsIntTranslation (*inTransform.mMatrix, mTX, mTY) || mScale9 != *inTransform.mScale9)
			return false;
		
		if (inMask) {
			
			if (inMask->mVersion != mMaskVersion)
				return false;
			if (mMaskOffset != ImagePoint (inMask->mTX, inMask->mTY))
				return false;
			
		} else if (mMaskVersion) {
			
			return false;
			
		}
		
		// Translate our cached pixels to this new position ...
		Rect translated = mRect.Translated (mTX, mTY);
		if (translated.Contains (inVisiblePixels))
			return true;
		
		return false;
		
	}
	
	
}
