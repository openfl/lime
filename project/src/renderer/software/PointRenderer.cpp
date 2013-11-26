#include "PolygonRender.h"


namespace nme
{

class PointRenderer : public CachedExtentRenderer
{
public:
      
   const QuickVec<float> &mData;
      
   int             mData0;
   int             mCount;
   bool            mHasColours;
      
   ARGB            mCol;
      
   Transform           mTransform;
   QuickVec<UserPoint> mTransformed;
      
   
   PointRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath) :
       mData(inPath.data), mData0(inJob.mData0)
   {
      GraphicsSolidFill *fill = inJob.mFill ? inJob.mFill->AsSolidFill() : 0;
      if (fill)
         mCol = fill->mRGB;
      
      mHasColours = fill == 0;
      mCount = inJob.mDataCount/(fill ? 2 : 3);
   }
   
   
   void Destroy()
   {
      delete this;
   }
   
   
   void GetExtent(CachedExtent &ioCache)
   {
      SetTransform(ioCache.mTransform);

      for(int i=0;i<mTransformed.size();i++)
         ioCache.mExtent.Add(mTransformed[i]);
   }
   
   
   bool Hits(const RenderState &inState)
   {
      UserPoint screen(inState.mClipRect.x, inState.mClipRect.y);

      Extent2DF extent;
      CachedExtentRenderer::GetExtent(inState.mTransform,extent,true);
      if (!extent.Contains(screen))
          return false;

      UserPoint hit_test = inState.mTransform.mMatrix->ApplyInverse(screen);
      if (inState.mTransform.mScale9->Active())
      {
         hit_test.x = inState.mTransform.mScale9->InvTransX(hit_test.x);
         hit_test.y = inState.mTransform.mScale9->InvTransY(hit_test.y);
      }

      for(int i=0;i<mTransformed.size();i++)
      {
         const UserPoint &point = mTransformed[i];
         if ( fabs(point.x-screen.x) < 1 && fabs(point.y-screen.y) < 1 )
            return true;
      }
      return false;
   }
   

   bool Render( const RenderTarget &inTarget, const RenderState &inState )
   {
      Extent2DF extent;
      CachedExtentRenderer::GetExtent(inState.mTransform,extent,true);

      if (!extent.Valid())
         return true;

      // Get bounding pixel rect
      Rect rect = inState.mTransform.GetTargetRect(extent);

      // Intersect with clip rect ...
      Rect visible_pixels = rect.Intersect(inState.mClipRect);
      int x0 = visible_pixels.x;
      int y0 = visible_pixels.y;
      int x1 = visible_pixels.x1();
      int y1 = visible_pixels.y1();

      bool swap = gC0IsRed != (bool)(inTarget.mPixelFormat & pfSwapRB);
      //bool alpha = (inTarget.mPixelFormat & pfHasAlpha);

      if (!mHasColours)
      {
         int val = swap ? mCol.SwappedIVal() : mCol.ival;
         // 100% alpha...
         if ( ( (val & 0xff000000) == 0xff000000 ) || (inTarget.mPixelFormat & pfHasAlpha) )
         {
            for(int i=0;i<mTransformed.size();i++)
            {
                const UserPoint &point = mTransformed[i];
                int tx = point.x;
                if (x0<=tx && tx<x1)
                {
                   int ty = point.y;
                   if (y0<=ty && ty<y1)
                      ((int *)inTarget.Row(ty))[tx] = val;
                }
             }
         }
         else
         {
            ARGB argb = swap ? mCol.Swapped() : mCol;

            for(int i=0;i<mTransformed.size();i++)
            {
               const UserPoint &point = mTransformed[i];
               int tx = point.x;
               if (x0<=tx && tx<x1)
               {
                  int ty = point.y;
                  if (y0<=ty && ty<y1)
                     ((ARGB *)inTarget.Row(ty))[tx].QBlendA(argb);
               }
            }
         }
      }
      else
      {
         ARGB *argb = (ARGB *) & mData[mData0 + mTransformed.size()*2];
         if (inTarget.mPixelFormat & pfHasAlpha)
            for(int i=0;i<mTransformed.size();i++)
            {
               const UserPoint &point = mTransformed[i];
               int tx = point.x;
               if (x0<=tx && tx<x1)
               {
                  int ty = point.y;
                  if (y0<=ty && ty<y1)
                     ((ARGB *)inTarget.Row(ty))[tx].QBlendA( swap? argb[i] : argb[i].Swapped() );
               }
            }
         else
            for(int i=0;i<mTransformed.size();i++)
            {
               const UserPoint &point = mTransformed[i];
               int tx = point.x;
               if (x0<=tx && tx<x1)
               {
                  int ty = point.y;
                  if (y0<=ty && ty<y1)
                     ((ARGB *)inTarget.Row(ty))[tx].QBlend( swap? argb[i].Swapped() : argb[i] );
               }
            }
      }
      
      return true;
   }
   
   
   void SetTransform(const Transform &inTrans)
   {
      int points = mCount;
      if (points!=mTransformed.size() || inTrans!=mTransform)
      {
         mTransform = inTrans;
         mTransformed.resize(points);
         UserPoint *src= (UserPoint *)&mData[ mData0 ];
         for(int i=0;i<points;i++)
         {
            mTransformed[i] = mTransform.Apply(src[i].x,src[i].y);
         }
      }
   }
   
   
};

Renderer *CreatePointRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath)
{
   return new PointRenderer(inJob,inPath);
}

} // end namespace nme



