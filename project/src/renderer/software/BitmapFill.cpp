#include "BitmapFill.h"


namespace nme
{
   
   template<int EDGE,bool SMOOTH>
   static Filler *CreateAlpha(GraphicsBitmapFill *inFill)
   {
      if (inFill->bitmapData->Format() & pfHasAlpha)
        return new BitmapFiller<EDGE, SMOOTH, true, false>(inFill);
      else
        return new BitmapFiller<EDGE, SMOOTH, false, false>(inFill);
   }
   
   
   template<int EDGE>
   static Filler *CreateSmooth(GraphicsBitmapFill *inFill)
   {
      if (inFill->smooth)
        return CreateAlpha<EDGE, true>(inFill);
      else
        return CreateAlpha<EDGE, false>(inFill);
   }
   
   
   Filler *Filler::Create(GraphicsBitmapFill *inFill)
   {
      if (inFill->repeat)
      {
        if ( IsPOW2(inFill->bitmapData->Width()) && IsPOW2(inFill->bitmapData->Height()) )
          return CreateSmooth<EDGE_POW2>(inFill);
        else
          return CreateSmooth<EDGE_REPEAT>(inFill);
      }
      else
        return CreateSmooth<EDGE_CLAMP>(inFill);
   }
   
   
}
