#ifndef POLYGON_RENDER_H
#define POLYGON_RENDER_H


#include <CachedExtent.h>
#include <vector>
#include "AlphaMask.h"
#include <stdio.h>


namespace lime
{

enum IterateMode { itGetExtent, itCreateRenderer, itHitTest };


class PolygonRender : public CachedExtentRenderer
{
public:
   PolygonRender(const GraphicsJob &inJob, const GraphicsPath &inPath, IGraphicsFill *inFill);


   static PolygonRender *CreateLines(const GraphicsJob &inJob, const GraphicsPath &inPath);
   static PolygonRender *CreateTriangleLines(const GraphicsJob &inJob, const GraphicsPath &inPath, Renderer *inSolid);
   
   ~PolygonRender();
   void Destroy();
   
   void GetExtent(CachedExtent &ioCache);
   virtual void SetTransform(const Transform &inTransform);
   void Align(const UserPoint &t0, const UserPoint &t1, UserPoint &ioP0, UserPoint &ioP1);
   bool Render(const RenderTarget &inTarget, const RenderState &inState);
   void BuildSolid(const UserPoint &inP0, const UserPoint &inP1);
   void BuildCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2);
   void BuildFatCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2, double perp_len, const UserPoint &perp0, const UserPoint perp1);
   void HitTestCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2);
   void HitTestFatCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2, double perp_len, const UserPoint &perp0, const UserPoint &perp1);
   void CurveExtent(const UserPoint &p0, const UserPoint &p1, const UserPoint &p2);
   void FatCurveExtent(const UserPoint &p0, const UserPoint &p1, const UserPoint &p2, double perp_len);
   bool Hits(const RenderState &inState);
   void BuildHitTest(const UserPoint &inP0, const UserPoint &inP1);
   virtual int  GetWinding() { return 0xffffffff; }
   
   virtual int Iterate(IterateMode inMode,const Matrix &m) = 0;
   virtual void AlignOrthogonal() {}
   
   UserPoint mHitTest;
   int mHitsLeft;
   Transform mTransform;
   Matrix mTransMat;
   Scale9 mTransScale9;
   QuickVec<UserPoint> mTransformed;
   Filler *mFiller;
   Extent2DF *mBuildExtent;
   struct SpanRect *mSpanRect;
   AlphaMask *mAlphaMask;
   
   const QuickVec<uint8> &mCommands;
   const QuickVec<float> &mData;
   
   int mCommand0;
   int mData0;
   int mCommandCount;
   int mDataCount;
   bool mIncludeStrokeInExtent;
   
};


} // end namespace lime


#endif
