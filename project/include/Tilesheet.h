#ifndef LIME_TILESHEET_H
#define LIME_TILESHEET_H

#include <Graphics.h>
#include <Object.h>

namespace lime
{

struct Tile
{
	float   mOx;
	float   mOy;
	Rect    mRect;
	Surface *mSurface;
};

class Tilesheet : public Object
{
public:
   Tilesheet(int inWidth,int inHeight,PixelFormat inFormat,bool inInitRef=false);
   Tilesheet(Surface *inSurface,bool inInitRef=false);

	Tilesheet *IncRef() { Object::IncRef(); return this; }

	int AllocRect(int inW,int inH,float inOx = 0, float inOy = 0);
   int addTileRect(const Rect &inRect,float inOx=0, float inOy=0);
	const Tile &GetTile(int inID) { return mTiles[inID]; }
	Surface &GetSurface() { return *mSheet; }
	int Tiles() const { return mTiles.size(); }

private:
	~Tilesheet();

	int  mCurrentX;
	int  mCurrentY;
	int  mMaxHeight;

	QuickVec<Tile> mTiles;
	Surface        *mSheet;
};


}

#endif
