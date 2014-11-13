#include <Graphics.h>
#include "Render.h"

namespace nme
{

template<bool HAS_ALPHA>
class SolidFiller : public Filler
{
public:
	enum { HasAlpha = HAS_ALPHA };

	SolidFiller(GraphicsSolidFill *inFill)
	{
		mRGB = inFill->mRGB;
	}

   inline void SetPos(int,int) {}
   ARGB GetInc( ) { return mFillRGB; }


   void Fill(const AlphaMask &mAlphaMask,int inTX,int inTY,
       const RenderTarget &inTarget,const RenderState &inState)
	{
		mFillRGB = mRGB;

		Render( mAlphaMask, *this, inTarget,  inState, inTX,inTY );
	}

	ARGB mRGB;
	ARGB mFillRGB;

};


Filler *Filler::Create(GraphicsSolidFill *inFill)
{
	if (inFill->mRGB.a==255)
	   return new SolidFiller<false>(inFill);
	else
	   return new SolidFiller<true>(inFill);
}


} // end namespace nme
