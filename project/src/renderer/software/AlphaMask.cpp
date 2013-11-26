#include "AlphaMask.h"
#include <NMEThread.h>

namespace nme
{
   
   //QuickVec<AlphaMask *> sMaskCache;
   //#define RECYCLE_ALPHA_MASK
   

void AlphaMask::ClearCache()
{
   #ifdef RECYCLE_ALPHA_MASK
   for (int i = 0;i < sMaskCache.size(); i++)
      delete sMaskCache[i];
   sMaskCache.resize(0);
   #endif
}


bool AlphaMask::Compatible(const Transform &inTransform, const Rect &inExtent, const Rect &inVisiblePixels, int &outTX, int &outTY)
{
   int tx, ty;
   
   if ((!mMatrix.IsIntTranslation(*inTransform.mMatrix, tx, ty)) || (mScale9 != *inTransform.mScale9))
      return false;
   
   if (mAAFactor != inTransform.mAAFactor)
      return false;
   
   // Translate our cached pixels to this new position ...
   Rect translated = mRect.Translated(tx, ty);
   
   if (translated.Contains(inVisiblePixels))
   {
      outTX = tx;
      outTY = ty;
      return true;
   }
   
   return false;
}


AlphaMask *AlphaMask::Create(const Rect &inRect, const Transform &inTrans)
{
   #ifdef RECYCLE_ALPHA_MASK
   int need = inRect.h + 1;
   
   for (int i = 0; i < sMaskCache.size(); i++)
   {
      AlphaMask *m = sMaskCache[i];
      
      if (m->mLineStarts.mAlloc >= need && m->mLineStarts.size() < need + 10)
      {
         sMaskCache[i] = sMaskCache[sMaskCache.size() - 1];
         sMaskCache.resize(sMaskCache.size() - 1);
         m->mRect = inRect;
         m->mLineStarts.resize(need);
         m->mMatrix = *inTrans.mMatrix;
         m->mScale9 = *inTrans.mScale9;
         m->mAAFactor = inTrans.mAAFactor;
         return m;
      }
   }
   #endif
   return new AlphaMask(inRect, inTrans);
}


void AlphaMask::Dispose()
{
   #ifdef RECYCLE_ALPHA_MASK
   sMaskCache.push_back(this);
   #else
   delete this;
   #endif
}


void AlphaMask::RenderBitmap(int inTX, int inTY, const RenderTarget &inTarget, const RenderState &inState)
{
   if (mLineStarts.size() < 2)
      return;
   
   Rect clip = inState.mClipRect;
   int y = mRect.y + inTY;
   const int *start = &mLineStarts[0] - y;
   
   int y1 = mRect.y1() + inTY;
   clip.ClipY(y, y1);
   
   for (; y < y1; y++)
   {
      const AlphaRun *end = &mAlphaRuns[start[y + 1]];
      const AlphaRun *run = &mAlphaRuns[start[y]];
      
      if (run != end)
      {
         Uint8 *dest0 = inTarget.Row(y);
         while (run < end && run->mX1 + inTX <= clip.x)
            run++;
         
         while (run < end)
         {
            int x0 = run->mX0 + inTX;
            if (x0 >= clip.x1())
               break;
            int x1 = run->mX1 + inTX;
            clip.ClipX(x0, x1);
            
            Uint8 *dest = dest0 + x0;
            int alpha = run->mAlpha;
            
            if (alpha > 0)
            {
               if (alpha >= 255)
               {
                  while (x0++ < x1)
                     *dest++ = 255;
               }
               else
               {
                  while(x0++ < x1)
                     QBlendAlpha(*dest++, alpha);
               }
            }
            ++run;
         }
      }
   }
   
}


// --- Build AlphaMask from SpanRect ----------------------------------------

struct Transition
{
   int x;
   short val;
   
   Transition(int inX = 0, int inVal = 0) : x(inX), val(inVal) {}
   bool operator<(const Transition &inRHS) const { return x < inRHS.x; }
   void operator+=(int inDiff) { val += inDiff; }
};


struct Transitions
{
   int mLeft;
   QuickVec<Transition> mX;
   
   void Compact()
   {
      Transition *ptr = mX.begin();
      Transition *end = mX.end();
      
      if (ptr == end) return;
      
      std::sort(ptr, end);
      Transition *dest = ptr;
      ptr++;
      
      for(; ptr < end; ptr++)
      {
         if (dest->x == ptr->x)
         {
            dest->val += ptr->val;
         }
         else
         {
            ++dest;
            if (dest != ptr)
               *dest = *ptr;
         }
      }
      
      mX.resize(dest - mX.begin() + 1);
      
   }
   
};



template<int BITS>   struct AlphaIterator
{
   enum { Size = (1 << BITS) };
   enum { Mask = ~((1 << BITS) - 1) };
   
   AlphaRun  *mEnd;
   AlphaRun  *mPtr;
   AlphaRuns mRuns;
   
   AlphaIterator() { mEnd = mPtr = 0; }
   
   void Reset() { mRuns.resize(0); }
   
   void Init(int &outXMin)
   {
      if (!mRuns.empty())
      {
         mPtr = &mRuns[0];
         mEnd = mPtr + mRuns.size();

         int x = mPtr->mX0 & Mask;
         if (x<outXMin) outXMin = x;
      }
   }
   
   
   // Move along until we hit x, calcualte alpha and update whn next change occurs
   inline int SetX(int inX, int &outNextX)
   {
      // zip along until we hit x
      do
      {
         if (mPtr == mEnd)
            return 0;
         if (mPtr->mX1 > inX)
            break;
         mPtr++;
         
      } while(1);
      
      int box = inX + Size;
      
      if (mPtr->mX0 >= box)
      {
         int next = mPtr->mX0 & Mask;
         if (outNextX > next)
            outNextX = next;
         return 0;
      }
      
      int next;
      
      if ( mPtr->mX0 > inX)
      {
         next = inX + Size;
      }
      else
      {
         next = mPtr->mX1 & Mask;
         if (next == inX)
            next += Size;
      }
      
      if (outNextX > next)
         outNextX = next;
      
      // Calculate number of pixels overlapping...
      int alpha = inX - mPtr->mX0;
      if (alpha > 0) alpha = 0;
      
      if (mPtr->mX1 < box)
      {
         alpha += mPtr->mX1 - inX;
         // Check next span too ...
         if (mPtr + 1 < mEnd)
         {
            AlphaRun &next = mPtr[1];
            if (next.mX0 < box)
            {
               if (next.mX1 < box)
                  alpha += next.mX1 - next.mX0;
               else
                  alpha += box - next.mX0;
            }
         }
      }
      else
      {
         alpha += Size;
      }
      
      return alpha;
   }
   
};




std::vector<Transitions> sTransitionsBuffer;

SpanRect::SpanRect(const Rect &inRect, int inAA)
{
   mAA =  inAA;
   mAAMask = ~(mAA-1);
   mRect = inRect * inAA;
   mWinding = 0xffffffff;
   mTransitions = 0;
   
   if (IsMainThread())
   {
      if (sTransitionsBuffer.size() < mRect.h)
         sTransitionsBuffer.resize(mRect.h);
      mTransitions = &sTransitionsBuffer[0];
   }
   else
   {
      mTransitions = new Transitions[mRect.h];
   }
   
   for (int y = 0; y < mRect.h; y++)
   {
      mTransitions[y].mLeft = 0;
      mTransitions[y].mX.resize(0);
   }
   
   mMinX = (mRect.x - 1) << 10;
   mMaxX = (mRect.x1()) << 10;
   mLeftPos = mRect.x;
}

SpanRect::~SpanRect()
{
   if (mTransitions && mTransitions != &sTransitionsBuffer[0])
      delete [] mTransitions;
}
   

// dX/dY int fixed bits ...
inline int FixedGrad(Fixed10 inVec, int inBits)
{
   int denom = inVec.y;
   if (denom == 0)
      return 0;

   int64 ratio = (((int64)inVec.x) << inBits) / denom;
   if (ratio < -(1 << 21)) return -(1 << 21);
   if (ratio >  (1 << 21)) return  (1 << 21);
   return ratio;
}


template<bool MASK_AA_X, bool MASK_AA_Y>
void SpanRect::Line(Fixed10 inP0, Fixed10 inP1)
{
   // All right ...
   if (inP0.x > mMaxX && inP1.x > mMaxX)
      return;
   
   // Make p1.y numerically greater than inP0.y
   int y0 = inP0.Y() - mRect.y;
   int y1 = inP1.Y() - mRect.y;
   
   if (MASK_AA_Y)
   {
      y0 = y0 & mAAMask;
      y1 = y1 & mAAMask;
   }
   
   int dy = y1-y0;
   if (dy == 0)
      return;
   
   int diff = 1;
   
   if (dy < 0)
   {
      diff = -1;
      std::swap(y0, y1);
      std::swap(inP0, inP1);
   }
   
   // All up or all down ....
   if (y0 >= mRect.h || y1 <= 0)
      return;
   
   // Just draw a vertical line down the left...
   if (inP0.x <= mMinX && inP1.x <= mMinX)
   {
      y0 = std::max(y0, 0);
      y1 = std::min(y1, mRect.h);
      
      for(; y0 < y1; y0++)
         mTransitions[y0].mLeft += diff;
      
      return;
   }
   
   // dx_dy in 10 bit precision ...
   int dx_dy = FixedGrad(inP1 - inP0, 10);
   
   // (10 bit) fractional bit true position pokes up above the first line...
   int extra_y = ((y0 + (MASK_AA_Y ? mAA : 1) + mRect.y) << 10) - inP0.y;
   // We have already started down the gradient bt a bit, so adjust x.
   // x is 10 bits, dx_dy is 10 bits and extra_y is 10 bits ...
   int x = inP0.x + ((dx_dy * extra_y)>>10);
   
   if (y0 < 0)
   {
      x -= y0 * dx_dy;
      y0 = 0;
   }
   
   int last = std::min(y1, mRect.h);
   
   if (MASK_AA_X)
   {
      dx_dy *= mAA;
      
      for(; y0 < last; y0 += mAA)
      {
         // X is fixed-10, y is fixed-aa
         int x_val = (x >> 10) & mAAMask;
         
         if (x_val < mMaxX)
         {
            for (int a = 0; a < mAA; a++)
               mTransitions[y0 + a].mX.push_back(Transition(x_val, diff));
         }
         
         x += dx_dy; 
      }
   }
   else
   {
      for(; y0 < last; y0++)
      {
         // X is fixed-10, y is fixed-aa
         if (x < mMaxX)
            mTransitions[y0].mX.push_back(Transition(x >> 10, diff));
         
         x += dx_dy; 
      }
   }
}

void SpanRect::Line00(Fixed10 inP0, Fixed10 inP1) { Line<false,false>(inP0,inP1); }
void SpanRect::Line01(Fixed10 inP0, Fixed10 inP1) { Line<false,true >(inP0,inP1); }
void SpanRect::Line10(Fixed10 inP0, Fixed10 inP1) { Line<true ,false>(inP0,inP1); }
void SpanRect::Line11(Fixed10 inP0, Fixed10 inP1) { Line<true ,true >(inP0,inP1); }


void BuildAlphaRuns(const SpanRect &inRect,Transitions &inTrans, AlphaRuns &outRuns, int inFactor)
{
   int last_x = inRect.mRect.x;
   inTrans.Compact();
   int total = inTrans.mLeft;
   Transition *end = inTrans.mX.end();
   int alpha =  (total & inRect.mWinding) ? inFactor : 0;
   
   for (Transition *t = inTrans.mX.begin(); t != end; ++t)
   {
      if (t->val)
      {
         if (t->x >= inRect.mRect.x1())
         {
            if (alpha > 0 && last_x < t->x)
               outRuns.push_back(AlphaRun(last_x, inRect.mRect.x1(), alpha));
            return;
         }
         
         if (alpha > 0 && last_x < t->x)
            outRuns.push_back(AlphaRun(last_x, t->x, alpha));
         
         last_x = std::max(t->x, inRect.mRect.x);

         total += t->val;
         alpha = (total & inRect.mWinding) ? inFactor : 0;
      }
   }
   
   
   if (alpha > 0)
     outRuns.push_back(AlphaRun(last_x, inRect.mRect.x1(), alpha));
}


void BuildAlphaRuns2(const SpanRect &inRect,Transitions *inTrans, AlphaRuns &outRuns, int inFactor)
{
   enum { MAX_X = 0x7fffffff };

   if (IsMainThread())
   {
      static AlphaIterator<1> a0,a1;
      a0.Reset();
      a1.Reset();
   
      BuildAlphaRuns(inRect,inTrans[0], a0.mRuns, 256);
      BuildAlphaRuns(inRect,inTrans[1], a1.mRuns, 256);
   
      enum { MAX_X = 0x7fffffff };
   
      int x = inRect.mRect.x;
   
      a0.Init(x);
      a1.Init(x);
      int f = inFactor >> 2;
   
      while(x < MAX_X)
      {
         int next_x = MAX_X;
         int alpha = a0.SetX(x, next_x) + a1.SetX(x, next_x);
      
         if (next_x == MAX_X)
            break;
         if (alpha > 0)
            outRuns.push_back(AlphaRun(x >> 1, next_x >> 1, alpha * f));
      
         x = next_x;
      }
   }
   else
   {
      AlphaIterator<1> a0,a1;
   
      BuildAlphaRuns(inRect,inTrans[0], a0.mRuns, 256);
      BuildAlphaRuns(inRect,inTrans[1], a1.mRuns, 256);
   
      int x = inRect.mRect.x;
   
      a0.Init(x);
      a1.Init(x);
      int f = inFactor >> 2;
   
      while(x < MAX_X)
      {
         int next_x = MAX_X;
         int alpha = a0.SetX(x, next_x) + a1.SetX(x, next_x);
      
         if (next_x == MAX_X)
            break;
         if (alpha > 0)
            outRuns.push_back(AlphaRun(x >> 1, next_x >> 1, alpha * f));
      
         x = next_x;
      }
   }
}


void BuildAlphaRuns4(const SpanRect &inRect,Transitions *inTrans, AlphaRuns &outRuns, int inFactor)
{
   enum { MAX_X = 0x7fffffff };

   if (IsMainThread())
   {
      static AlphaIterator<2> a0,a1,a2,a3;
      a0.Reset();
      a1.Reset();
      a2.Reset();
      a3.Reset();
   
      BuildAlphaRuns(inRect,inTrans[0], a0.mRuns, 256);
      BuildAlphaRuns(inRect,inTrans[1], a1.mRuns, 256);
      BuildAlphaRuns(inRect,inTrans[2], a2.mRuns, 256);
      BuildAlphaRuns(inRect,inTrans[3], a3.mRuns, 256);
   
      int x = inRect.mRect.x;
   
      a0.Init(x);
      a1.Init(x);
      a2.Init(x);
      a3.Init(x);
   
      int f = inFactor >> 4;
   
      while(x < MAX_X)
      {
         int next_x = MAX_X;
         int alpha = a0.SetX(x, next_x) + a1.SetX(x, next_x) + a2.SetX(x, next_x) + a3.SetX(x, next_x);
      
         if (next_x == MAX_X)
            break;
         if (alpha > 0)
            outRuns.push_back(AlphaRun(x >> 2, next_x >> 2, alpha * f));
      
         x = next_x;
      }
   }
   else
   {
      AlphaIterator<2> a0,a1,a2,a3;
   
      BuildAlphaRuns(inRect,inTrans[0], a0.mRuns, 256);
      BuildAlphaRuns(inRect,inTrans[1], a1.mRuns, 256);
      BuildAlphaRuns(inRect,inTrans[2], a2.mRuns, 256);
      BuildAlphaRuns(inRect,inTrans[3], a3.mRuns, 256);
   
      int x = inRect.mRect.x;
   
      a0.Init(x);
      a1.Init(x);
      a2.Init(x);
      a3.Init(x);
   
      int f = inFactor >> 4;
   
      while(x < MAX_X)
      {
         int next_x = MAX_X;
         int alpha = a0.SetX(x, next_x) + a1.SetX(x, next_x) + a2.SetX(x, next_x) + a3.SetX(x, next_x);
      
         if (next_x == MAX_X)
            break;
         if (alpha > 0)
            outRuns.push_back(AlphaRun(x >> 2, next_x >> 2, alpha * f));
      
         x = next_x;
      }
   }
}


AlphaMask *SpanRect::CreateMask(const Transform &inTransform, int inAlpha, Lines &inLines)
{
   Rect rect = mRect / mAA;
   
   if (inLines.size() < rect.h)
      inLines.resize(rect.h);
   mLines = &inLines[0];
   
   AlphaMask *mask = AlphaMask::Create(rect, inTransform);
   Transitions *t = &mTransitions[0];
   int start = 0;
   
   for (int y = 0; y < rect.h; y++)
   {
      mLines[y].resize(0);
      mask->mLineStarts[y] = start;
      
      switch(mAA)
      {
         case 1:
            BuildAlphaRuns(*this,*t, mLines[y], inAlpha);
            break;
         case 2:
            BuildAlphaRuns2(*this,t, mLines[y], inAlpha);
            break;
         case 4:
            BuildAlphaRuns4(*this,t, mLines[y], inAlpha);
            break;
      }
      start += mLines[y].size();
      t += mAA;
   }
   
   mask->mLineStarts[rect.h] = start;
   mask->mAlphaRuns.resize(start);
   
   for (int y = 0; y < rect.h; y++)
   {
      memcpy(&mask->mAlphaRuns[mask->mLineStarts[y]], &mLines[y][0], (mask->mLineStarts[y + 1] - mask->mLineStarts[y]) * sizeof(AlphaRun));
   }
   
   return mask;
}


static Lines sLineBuffer;
AlphaMask *SpanRect::CreateMask(const Transform &inTransform, int inAlpha)
{
   if (IsMainThread())
   {
      return CreateMask(inTransform, inAlpha, sLineBuffer);
   }
   else
   {
      Lines lineBuffer;
      return CreateMask(inTransform, inAlpha, lineBuffer);
   }
}



   
} // end namespace nme
