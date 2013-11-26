#ifndef ALPHA_MASK_H
#define ALPHA_MASK_H


#include <Geom.h>
#include <Graphics.h>
#include <QuickVec.h>
#include <vector>


namespace nme
{


struct AlphaRun
{
   inline AlphaRun() { }
   inline AlphaRun(int inX0, int inX1, short inAlpha) : mX0(inX0), mX1(inX1), mAlpha(inAlpha) { }
   
   inline bool Contains(int inX) const
   {
      return inX >= mX0 && inX<mX1;
   }
   
   inline void Set(int inX0, int inX1, int inAlpha)
   {
      mX0 = inX0;
      mX1 = inX1;
      mAlpha = inAlpha;
   }
   
   short mX0, mX1;
   // mAlpha is 0 ... 256 inclusive
   short mAlpha;
};


typedef QuickVec<AlphaRun> AlphaRuns;
typedef QuickVec<int> LineStart;
typedef std::vector<AlphaRuns> Lines;


class AlphaMask
{
   
   AlphaMask(const Rect &inRect, const Transform &inTrans) : mRect(inRect), mLineStarts(inRect.h + 1)
   {
      mMatrix = *inTrans.mMatrix;
      mScale9 = *inTrans.mScale9;
      mAAFactor = inTrans.mAAFactor;
   }
   
   // Use Dispose
   ~AlphaMask() { }
   
public:
   
   static AlphaMask *Create(const Rect &inRect, const Transform &inTrans);
   
   void Dispose();
   void ClearCache();
   void RenderBitmap(int inTX, int inTY, const RenderTarget &inTarget, const RenderState &inState);
   
   // Given we were created with a certain transform and valid data rect, can we
   // cover the requested area for the requested transform?
   bool Compatible(const Transform &inTransform, const Rect &inExtent, const Rect &inVisiblePixels, int &outTX, int &outTY);	
   
   Rect mRect;
   AlphaRuns mAlphaRuns;
   LineStart mLineStarts;
   Matrix mMatrix;
   Scale9 mScale9;
   int mAAFactor;
};


struct SpanRect
{
   SpanRect(const Rect &inRect, int inAA);
   ~SpanRect();

   AlphaMask *CreateMask(const Transform &inTransform, int inAlpha);
   inline AlphaMask *CreateMask(const Transform &inTransform, int inAlpha, Lines &inLineBuf);

   // first bit = X AA, second bit = Y AA
   void Line00(Fixed10 inP0, Fixed10 inP1);
   void Line01(Fixed10 inP0, Fixed10 inP1);
   void Line10(Fixed10 inP0, Fixed10 inP1);
   void Line11(Fixed10 inP0, Fixed10 inP1);

   int mAA;
   int mAAMask;
   int mLeftPos;
   int mMaxX;
   int mMinX;
   int mWinding;
   AlphaRuns *mLines;
   struct Transitions *mTransitions;
   Rect   mRect;

private:
   template<bool MASK_AA_X, bool MASK_AA_Y> inline void Line(Fixed10 inP0, Fixed10 inP1);
};



class Filler
{
public:
   
   virtual ~Filler() { };
   
   virtual void Fill(const AlphaMask &mAlphaMask, int inTX, int inTY, const RenderTarget &inTarget, const RenderState &inState) = 0;
   virtual void SetMapping(const UserPoint *inVertex, const float *inUVT, int inComponents) { }
   
   static Filler *Create(GraphicsSolidFill *inFill);
   static Filler *Create(GraphicsGradientFill *inFill);
   static Filler *Create(GraphicsBitmapFill *inFill);
   static Filler *CreatePerspective(GraphicsBitmapFill *inFil);
   
};

	
}


#endif
