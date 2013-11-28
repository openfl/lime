#include "PolygonRender.h"

#include <map>

namespace lime
{

struct Edge
{
   UserPoint p0,p1;
   Edge(const UserPoint &inP0, const UserPoint &inP1) : p0(inP0), p1(inP1)
   {
      if (p1<p0) std::swap(p0,p1);
   }
   inline bool operator<(const Edge &e) const
   {
      if (p0<e.p0) return true;
      if (e.p0<p0) return false;
      return p1<e.p1;
   }
};
typedef std::map<Edge,int> EdgeCount;



class TriangleRender : public PolygonRender 
{
public:
   bool                  mMappingDirty;
   QuickVec<AlphaMask *> mAlphaMasks;
   QuickVec<bool>        mEdgeAA;
   GraphicsTrianglePath *mTriangles;

   
   TriangleRender(const GraphicsJob &inJob, const GraphicsPath &inPath):
       PolygonRender(inJob, inPath, inJob.mFill)
   {
      mTriangles = inJob.mTriangles;
      mAlphaMasks.resize(mTriangles->mTriangleCount);
      mAlphaMasks.Zero();

      mMappingDirty = true;
      int n  = mTriangles->mTriangleCount;
      const UserPoint *p = &mTriangles->mVertices[0];
   
      EdgeCount edges;
      for(int t=0;t<n;t++)
      {
          edges[ Edge(p[0],p[1]) ]++;
          edges[ Edge(p[1],p[2]) ]++;
          edges[ Edge(p[2],p[0]) ]++;
          p+=3;
      }

      p = &mTriangles->mVertices[0];
      int idx=0;
      mEdgeAA.resize(n*3);
      for(int t=0;t<n;t++)
      {
          mEdgeAA[idx++] = edges[Edge(p[0],p[1])]<2;
          mEdgeAA[idx++] = edges[Edge(p[1],p[2])]<2;
          mEdgeAA[idx++] = edges[Edge(p[2],p[0])]<2;
          p+=3;
      }
   }
   
   
   ~TriangleRender()
   {
      for(int i=0;i<mAlphaMasks.size();i++)
         if (mAlphaMasks[i])
           mAlphaMasks[i]->Dispose();
   }
   
   
   int Iterate(IterateMode inMode,const Matrix &m)
   {
      const UserPoint *point = 0;

      if (inMode==itHitTest)
         point = (const UserPoint *)&mTriangles->mVertices[0];
      else
         point = &mTransformed[0];


      int points = mTriangles->mVertices.size();
      if (inMode==itGetExtent)
      {
         for(int p=0;p<points;p++)
            mBuildExtent->Add(point[p]);
      }
      else
      {
         typedef void (PolygonRender::*ItFunc)(const UserPoint &inP0, const UserPoint &inP1);
         ItFunc func = inMode==itCreateRenderer ? &PolygonRender::BuildSolid :
                  &PolygonRender::BuildHitTest;

         int tris = mTriangles->mTriangleCount;
         for(int t=0;t<tris;t++)
         {
            (*this.*func)(point[0],point[1]);
            (*this.*func)(point[1],point[2]);
            (*this.*func)(point[2],point[0]);
            point += 3;
         }
      }
      return 256;
   }
   
   
   bool Render(const RenderTarget &inTarget, const RenderState &inState)
   {
      if (mTriangles->mUVT.empty())
         return PolygonRender::Render(inTarget,inState);

      Extent2DF extent;
      CachedExtentRenderer::GetExtent(inState.mTransform,extent,true);

      if (!extent.Valid())
         return true;

      // Get bounding pixel rect
      Rect rect = inState.mTransform.GetTargetRect(extent);

      // Intersect with clip rect ...
      Rect visible_pixels = rect.Intersect(inState.mClipRect);
     

      int tris = mTriangles->mTriangleCount;
      UserPoint *point = &mTransformed[0];
      bool *edge_aa = &mEdgeAA[0];
      float *uvt = &mTriangles->mUVT[0];
      int tex_components = mTriangles->mType == vtVertex ? 0 : mTriangles->mType==vtVertexUV ? 2 : 3;
      int  aa = inState.mTransform.mAAFactor;
      bool aa1 = aa==1;
      for(int i=0;i<tris;i++)
      {
         // For each alpha mask ...
         // Check to see if AlphaMask is invalid...
         AlphaMask *&alpha = mAlphaMasks[i];
         int tx=0;
         int ty=0;
         if (alpha && !alpha->Compatible(inState.mTransform, rect,visible_pixels,tx,ty))
         {
            alpha->Dispose();
            alpha = 0;
         }

         if (!alpha)
         {
            SetTransform(inState.mTransform);
   
            SpanRect *span = new SpanRect(visible_pixels,inState.mTransform.mAAFactor);
			
            if (aa1 || edge_aa[0])
               span->Line01( mTransform.ToImageAA(point[0]),mTransform.ToImageAA(point[1]) );
            else
               span->Line11( mTransform.ToImageAA(point[0]),mTransform.ToImageAA(point[1]) );

            if (aa1 || edge_aa[1])
               span->Line01( mTransform.ToImageAA(point[1]),mTransform.ToImageAA(point[2]) );
            else
               span->Line11( mTransform.ToImageAA(point[1]),mTransform.ToImageAA(point[2]) );

            if (aa1 || edge_aa[2])
               span->Line01( mTransform.ToImageAA(point[2]),mTransform.ToImageAA(point[0]) );
            else
               span->Line11( mTransform.ToImageAA(point[2]),mTransform.ToImageAA(point[0]) );

            alpha = span->CreateMask(mTransform,256);
            delete span;
         }


   
         if (inTarget.mPixelFormat==pfAlpha)
         {
            alpha->RenderBitmap(tx,ty,inTarget,inState);
         }
         else
         {
            if (tex_components)
               mFiller->SetMapping(point,uvt,tex_components);

            mFiller->Fill(*alpha,tx,ty,inTarget,inState);
         }

         point += 3;
         uvt+=tex_components*3;
         edge_aa += 3;
      }

      mMappingDirty = false;

      return true;
   }
   
   
   void SetTransform(const Transform &inTransform)
   {
      int points = mTriangles->mVertices.size();
      if (points!=mTransformed.size() || inTransform!=mTransform)
      {
         mMappingDirty = true;
         mTransform = inTransform;
         mTransMat = *inTransform.mMatrix;
         mTransform.mMatrix = &mTransMat;
         mTransform.mMatrix3D = &mTransMat;
         mTransScale9 = *inTransform.mScale9;
         mTransform.mScale9 = &mTransScale9;
         mTransformed.resize(points);
         UserPoint *src= (UserPoint *)&mTriangles->mVertices[ 0 ];
         for(int i=0;i<points;i++)
            mTransformed[i] = mTransform.Apply(src[i].x,src[i].y);
      }
   }
   
};

Renderer *CreateTriangleRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath)
{
   return new TriangleRender(inJob,inPath);
}


} // end namespace lime
