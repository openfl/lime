#include "PolygonRender.h"

#include "QuickVec.h"



namespace lime
{


PolygonRender::PolygonRender(const GraphicsJob &inJob, const GraphicsPath &inPath, IGraphicsFill *inFill) : 
   mCommands(inPath.commands), mData(inPath.data),mCommand0(inJob.mCommand0), 
   mData0(inJob.mData0), mCommandCount(inJob.mCommandCount), mDataCount(inJob.mDataCount)
{
   mBuildExtent = 0;
   mAlphaMask = 0;
   mIncludeStrokeInExtent = true;
   
   switch(inFill->GetType())
   {
      case gdtSolidFill:
         mFiller = Filler::Create(inFill->AsSolidFill());
         break;
      case gdtGradientFill:
         mFiller = Filler::Create(inFill->AsGradientFill());
         break;
      case gdtBitmapFill:
         if (inJob.mTriangles && inJob.mTriangles->mType == vtVertexUVT )
            mFiller = Filler::CreatePerspective(inFill->AsBitmapFill());
         else
            mFiller = Filler::Create(inFill->AsBitmapFill());
         break;
      default:
         printf("Fill type not implemented\n");
         mFiller = 0;
   }
}


PolygonRender::~PolygonRender()
{
   if (mAlphaMask)
      mAlphaMask->Dispose();
   delete mFiller;
}


void PolygonRender::Align(const UserPoint &t0, const UserPoint &t1, UserPoint &ioP0, UserPoint &ioP1)
{
   if (t0 != t1)
   {
      if (t0.x == t1.x)
      {
         ioP0.x = ioP1.x = floor(ioP0.x) + 0.5;
         //printf(" align x %f -> %f\n", t0.x,ioP0.x);
      }
      else if (t0.y == t1.y)
      {
         ioP0.y = ioP1.y = floor(ioP0.y) + 0.5;
         //printf(" align y %f -> %f\n", t0.y,ioP0.y);
      }
   }
}


void PolygonRender::BuildCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2)
{
   // todo: calculate steps
   double len = (inP0 - inP1).Norm() + (inP2 - inP1).Norm();
   
   int steps = (int)len;
   if (steps < 1) steps = 1;
   if (steps > 100) steps = 100;
   
   double step = 1.0 / (steps + 1);
   Fixed10 last = mTransform.ToImageAA(inP0);
   double t = 0;
   
   for (int s = 0; s < steps; s++)
   {
      t += step;
      double t_ = 1.0 - t;
      UserPoint p = inP0 * (t_* t_) + inP1 * (2.0 * t * t_) + inP2 * (t * t);
      Fixed10 fixed = mTransform.ToImageAA(p);
      mSpanRect->Line00(last, fixed);
      last = fixed;
   }
   mSpanRect->Line00(last, mTransform.ToImageAA(inP2));
}


void PolygonRender::BuildFatCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2, double perp_len, const UserPoint &perp0, const UserPoint perp1)
{
   // todo: calculate steps
   double len = (inP0 - inP1).Norm() + (inP2 - inP1).Norm();
   
   int steps = (int)len;
   if (steps < 1) steps = 1;
   if (steps > 100) steps = 100;
   
   double step = 1.0 / (steps + 1);
   double t = 0;
   
   Fixed10 last_p0 = mTransform.ToImageAA(inP0 + perp0);
   Fixed10 last_p1 = mTransform.ToImageAA(inP0 - perp0);
   
   for (int s=1; s < steps; s++)
   {
      t += step;
      double t_ = 1.0 - t;
      UserPoint p = inP0 * (t_ * t_) + inP1 * (2.0 * t * t_) + inP2 * (t * t);
      UserPoint dir = (inP0 * -t_ + inP1 * (1.0 - 2.0 * t) + inP2 * t);
      UserPoint perp = dir.Perp(perp_len);
      
      Fixed10 p0 = mTransform.ToImageAA(p + perp);
      Fixed10 p1 = mTransform.ToImageAA(p - perp);
      mSpanRect->Line00(last_p0, p0);
      mSpanRect->Line00(p1, last_p1);
      last_p0 = p0;
      last_p1 = p1;
   }
   
   Fixed10 p0 = mTransform.ToImageAA(inP2 + perp1);
   Fixed10 p1 = mTransform.ToImageAA(inP2 - perp1);
   mSpanRect->Line00(last_p0, p0);
   mSpanRect->Line00(p1, last_p1);
}


void PolygonRender::BuildHitTest(const UserPoint &inP0, const UserPoint &inP1)
{
   if ((inP0.y < mHitTest.y) != (inP1.y < mHitTest.y))
   {
      double l1 = (mHitTest.y - inP0.y) / (inP1.y - inP0.y);
      double x = inP0.x + l1 * (inP1.x - inP0.x);
      if (x < mHitTest.x)
         mHitsLeft++;
   }
}


void PolygonRender::BuildSolid(const UserPoint &inP0, const UserPoint &inP1)
{
   mSpanRect->Line00(mTransform.ToImageAA(inP0), mTransform.ToImageAA(inP1));
}


void PolygonRender::CurveExtent(const UserPoint &p0, const UserPoint &p1, const UserPoint &p2)
{
   // B(t) = (1-t)^2p0 + 2(1-t)t p1 + t^2p2
   // Find maxima/minima : d/dt B(t) = 0
   //  d/dt x(t) = -2(1-t) p0.x + (2 -4t)p1.x + 2t p2.x = 0
   //
   //  -> t 2[  p2.x+p0.x - 2 p1.x ] = 2 p0.x - 2p1.x
   double denom = p2.x + p0.x - 2 * p1.x;
   
   if (denom != 0)
   {
      double t = (p0.x - p1.x) / denom;
      if (t > 0 && t < 1)
         mBuildExtent->AddX((1 - t) * (1 - t) * p0.x + (2 * t * (1 - t) * p1.x) + (t * t * p2.x));
   }
   
   denom = p2.y + p0.y - 2 * p1.y;
   
   if (denom != 0)
   {
      double t = (p0.y - p1.y) / denom;
      if (t > 0 && t < 1)
         mBuildExtent->AddY((1 - t) * (1 - t) * p0.y + (2 * t * (1 - t) * p1.y) + t * t * p2.y);
   }
   mBuildExtent->Add(p0);
   mBuildExtent->Add(p2);
}


void PolygonRender::Destroy()
{
   delete this;
}


void PolygonRender::FatCurveExtent(const UserPoint &p0, const UserPoint &p1, const UserPoint &p2, double perp_len)
{
   // B(t) = (1-t)^2p0 + 2(1-t)t p1 + t^2p2
   // Find maxima/minima : d/dt B(t) = 0
   //  d/dt x(t) = -2(1-t) p0.x + (2 -4t)p1.x + 2t p2.x = 0
   //
   //  -> t 2[  p2.x+p0.x - 2 p1.x ] = 2 p0.x - 2p1.x
   double denom = p2.x + p0.x - 2 * p1.x;
   
   if (denom != 0)
   {
      double t = (p0.x - p1.x) / denom;
      if (t > 0 && t < 1)
      {
         double x = (1 - t) * (1 - t) * p0.x + 2 * t * (1 - t) * p1.x + t * t * p2.x;
         mBuildExtent->AddX(x - perp_len);
         mBuildExtent->AddX(x + perp_len);
      }
   }
   
   denom = p2.y + p0.y - 2 * p1.y;
   
   if (denom != 0)
   {
      double t = (p0.y - p1.y) / denom;
      if (t > 0 && t < 1)
      {
         double y = (1 - t) * (1 - t) * p0.y + 2 * t * (1 - t) * p1.y + t * t * p2.y;
         mBuildExtent->AddY(y - perp_len);
         mBuildExtent->AddY(y + perp_len);
      }
   }
   
   mBuildExtent->AddX(p0.x - perp_len);
   mBuildExtent->AddX(p0.x + perp_len);
   mBuildExtent->AddY(p0.y - perp_len);
   mBuildExtent->AddY(p0.y + perp_len);
}


void PolygonRender::GetExtent(CachedExtent &ioCache)
{
   mBuildExtent = &ioCache.mExtent;
   *mBuildExtent = Extent2DF();
   
   SetTransform(ioCache.mTransform);

   mIncludeStrokeInExtent = ioCache.mIncludeStroke;
   
   Iterate(itGetExtent,*ioCache.mTransform.mMatrix);

   mIncludeStrokeInExtent = true;
   
   mBuildExtent = 0;
}


bool PolygonRender::Hits(const RenderState &inState)
{
   if (inState.mClipRect.w != 1 || inState.mClipRect.h != 1)
      return false;
   
   UserPoint screen(inState.mClipRect.x, inState.mClipRect.y);
   
   Extent2DF extent;
   CachedExtentRenderer::GetExtent(inState.mTransform, extent,true);
   
   if (!extent.Contains(screen))
      return false;
   
   mHitTest = inState.mTransform.mMatrix->ApplyInverse(screen);
   if (inState.mTransform.mScale9->Active())
   {
      mHitTest.x = inState.mTransform.mScale9->InvTransX(mHitTest.x);
      mHitTest.y = inState.mTransform.mScale9->InvTransY(mHitTest.y);
   }
   
   mHitsLeft = 0;
   Iterate(itHitTest, Matrix());
   return mHitsLeft & 0x01;
}


void PolygonRender::HitTestCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2)
{
   if ((inP0.y <= mHitTest.y && inP1.y <= mHitTest.y && inP2.y <= mHitTest.y) || (inP0.y >= mHitTest.y && inP1.y >= mHitTest.y && inP2.y >= mHitTest.y))
      return;
   
   // todo: calculate steps
   double len = (inP0 - inP1).Norm() + (inP2 - inP1).Norm();
   
   int steps = (int)(len * 0.5);
   if (steps < 1) steps = 1;
   if (steps > 100) steps = 100;
   
   double step = 1.0 / (steps + 1);
   double t = 0;
   UserPoint last = inP0;
   
   for (int s = 0; s < steps; s++)
   {
      t += step;
      double t_ = 1.0 - t;
      UserPoint p = inP0 * (t_ * t_) + inP1 * (2.0 * t * t_) + inP2 * (t * t);
      BuildHitTest(last, p);
      last = p;
   }
   
   BuildHitTest(last, inP2);
}


void PolygonRender::HitTestFatCurve(const UserPoint &inP0, const UserPoint &inP1, const UserPoint &inP2, double perp_len, const UserPoint &perp0, const UserPoint &perp1)
{
   if ((inP0.y <= mHitTest.y - perp_len && inP1.y <= mHitTest.y - perp_len && inP2.y <= mHitTest.y - perp_len) || (inP0.y >= mHitTest.y + perp_len && inP1.y >= mHitTest.y + perp_len && inP2.y >= mHitTest.y + perp_len))
      return;
   
   // todo: calculate steps
   double len = (inP0 - inP1).Norm() + (inP2 - inP1).Norm();
   
   int steps = (int)(len * 0.5);
   if (steps < 1) steps = 1;
   if (steps > 100) steps = 100;
   
   double step = 1.0 / (steps + 1);
   double t = 0;

   UserPoint last_p0 = inP0 + perp0;
   UserPoint last_p1 = inP0 - perp0;
   
   for (int s = 1; s < steps; s++)
   {
      t += step;
      double t_ = 1.0 - t;
      UserPoint p = inP0 * (t_ * t_) + inP1 * (2.0 * t * t_) + inP2 * (t * t);
      UserPoint dir = (inP0 * -t_ + inP1 * (1.0 - 2.0 * t) + inP2 * t);
      UserPoint perp = dir.Perp(perp_len);
      
      UserPoint p0 = p + perp;
      UserPoint p1 = p - perp;
      BuildHitTest(last_p0, p0);
      BuildHitTest(p1, last_p1);
      last_p0 = p0;
      last_p1 = p1;
   }
   
   UserPoint p0 = inP2 + perp1;
   UserPoint p1 = inP2 - perp1;
   BuildHitTest(last_p0, p0);
   BuildHitTest(p1, last_p1);
}


bool PolygonRender::Render(const RenderTarget &inTarget, const RenderState &inState)
{
   Extent2DF extent;
   CachedExtentRenderer::GetExtent(inState.mTransform, extent,true);
   
   if (!extent.Valid())
      return true;
   
   // Get bounding pixel rect
   Rect rect = inState.mTransform.GetTargetRect(extent);
   
   // Intersect with clip rect ...
   Rect visible_pixels = rect.Intersect(inState.mClipRect);
   
   if (visible_pixels.HasPixels())
   {
      // Check to see if AlphaMask is invalid...
      int tx = 0;
      int ty = 0;
      
      if (mAlphaMask && !mAlphaMask->Compatible(inState.mTransform, rect,visible_pixels, tx, ty))
      {
         mAlphaMask->Dispose();
         mAlphaMask = 0;
      }
      
      if (!mAlphaMask)
      {
         SetTransform(inState.mTransform);
         
         // TODO: make visible_pixels a bit bigger ?
         SpanRect span(visible_pixels, inState.mTransform.mAAFactor);
         span.mWinding = GetWinding();
         mSpanRect = &span;
         
         int alpha_factor = Iterate(itCreateRenderer, *inState.mTransform.mMatrix);
         mAlphaMask = mSpanRect->CreateMask(mTransform, alpha_factor);
         
         mSpanRect = 0;
      }
      
      if (inTarget.mPixelFormat == pfAlpha)
      {
         mAlphaMask->RenderBitmap(tx, ty, inTarget, inState);
      }
      else
      {
         mFiller->Fill(*mAlphaMask, tx, ty, inTarget, inState);
      }
   }
   
   return true;
}


void PolygonRender::SetTransform(const Transform &inTransform)
{
   int points = mDataCount/2;
   if (points != mTransformed.size() || inTransform != mTransform)
   {
      mTransform = inTransform;
      mTransMat = *inTransform.mMatrix;
      mTransform.mMatrix = &mTransMat;
      mTransform.mMatrix3D = &mTransMat;
      mTransScale9 = *inTransform.mScale9;
      mTransform.mScale9 = &mTransScale9;
      mTransformed.resize(points);
      UserPoint *src = (UserPoint *)&mData[mData0];
      
      for (int i = 0; i < points; i++)
      {
         mTransformed[i] = mTransform.Apply(src[i].x, src[i].y);
         //__android_log_print(ANDROID_LOG_ERROR, "lime", "%d/%d %f,%f -> %f,%f", i, points, src[i].x, src[i].y,
                           //mTransformed[i].x, mTransformed[i].y );
      }
      
      AlignOrthogonal();
   }
}

   
} // end namespace lime
