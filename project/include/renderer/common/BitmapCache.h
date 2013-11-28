#ifndef RENDERER_BITMAP_CACHE_H
#define RENDERER_BITMAP_CACHE_H


#include <Graphics.h>
#include "renderer/common/Surface.h"


namespace lime {

	
	class BitmapCache {
		
		public:
			
			BitmapCache (Surface *inSurface, const Transform &inTrans, const Rect &inRect, bool inMaskOnly, BitmapCache *inMask);
			~BitmapCache ();
			
			const uint8 *DestRow (int inRow) const;
			PixelFormat Format () const;
			bool HitTest (double inX, double inY);
			void PopTargetOffset (ImagePoint &inBuffer);
			void PushTargetOffset (const ImagePoint &inOffset, ImagePoint &outBuffer);
			void Render (const struct RenderTarget &inTarget, const Rect &inClipRect, const BitmapCache *inMask, BlendMode inBlend);
			const uint8 *Row (int inRow) const;
			bool StillGood (const Transform &inTransform, const Rect &inVisiblePixels, BitmapCache *inMask);
			
			int GetDestX () const { return mTX + mRect.x; }
			int GetDestY () const { return mTY + mRect.y; }
			Rect GetRect () const { return mRect.Translated (mTX, mTY); }
			int GetTX () const { return mTX; }
			int GetTY () const { return mTX; }
		
		//private:
			
			Surface *mBitmap;
			ImagePoint mMaskOffset;
			int mMaskVersion;
			Matrix mMatrix;
			Rect mRect;
			Scale9 mScale9;
			int mTX;
			int mTY;
			int mVersion;
		
	};
	
	
}


#endif
