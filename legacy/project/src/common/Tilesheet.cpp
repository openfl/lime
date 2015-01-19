#include <Tilesheet.h>
#include <Surface.h>
#include <algorithm>

namespace nme
{

Tilesheet::Tilesheet(int inWidth,int inHeight,PixelFormat inFormat, bool inInitRef) : Object(inInitRef)
{
	mCurrentX = 0;
	mCurrentY = 0;
	mMaxHeight = 0;
	mSheet = new SimpleSurface(inWidth,inHeight,inFormat);
   mSheet->IncRef();
}

Tilesheet::Tilesheet(Surface *inSurface,bool inInitRef) : Object(inInitRef)
{
	mCurrentX = 0;
	mCurrentY = 0;
	mMaxHeight = 0;
	mSheet = inSurface->IncRef();

}


Tilesheet::~Tilesheet()
{
	mSheet->DecRef();
}

int Tilesheet::AllocRect(int inW,int inH,float inOx, float inOy,bool inAlphaBorder)
{
	Tile tile;
	tile.mOx = inOx;
	tile.mOy = inOy;
	tile.mSurface = mSheet;

	// does it fit on the current row ?
   int cx = mCurrentX;
   if (inAlphaBorder && cx>0)
      cx++;
   int cy = mCurrentY;
   if (inAlphaBorder && cy>0)
      cy++;
	if (cx + inW <= mSheet->Width() && cy + inH < mSheet->Height())
	{
		tile.mRect = Rect(cx, cy, inW, inH);
		int result = mTiles.size();
		mTiles.push_back(tile);
		mCurrentX = cx+inW;
		mMaxHeight = std::max(mMaxHeight,inH+cy-mCurrentY);
		return result;
	}
	// No - go to next row
	mCurrentY += mMaxHeight;
	mCurrentX = 0;
	mMaxHeight = 0;
	if (inW>mSheet->Width() || mCurrentY + inH > mSheet->Height())
		return -1;

	tile.mRect = Rect(mCurrentX, mCurrentY, inW, inH);
	int result = mTiles.size();
	mTiles.push_back(tile);
	mCurrentX += inW;
	mMaxHeight = std::max(mMaxHeight,inH);
	return result;
}

int Tilesheet::addTileRect(const Rect &inRect,float inOx, float inOy)
{
   Tile tile;
	tile.mOx = inOx;
	tile.mOy = inOy;
	tile.mRect = inRect;
	tile.mSurface = mSheet;

   int result = mTiles.size();
   mTiles.push_back(tile);
   return result;
}



} // end namespace nme

