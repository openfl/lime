#include "TriangleLineRender.h"


namespace nme
{
	
	TriangleLineRender::TriangleLineRender(const GraphicsJob &inJob, const GraphicsPath &inPath, Renderer *inSolid) : LineRender(inJob, inPath)
	{
		mSolid = inSolid;
		mTriangles = inJob.mTriangles;
	}
	
	
	TriangleLineRender::~TriangleLineRender()
	{
		if (mSolid) mSolid->Destroy();
	}
	

	bool TriangleLineRender::GetExtent(const Transform &inTransform,Extent2DF &ioExtent,bool inIncludeStroke)
	{
		bool result = false;
		if (mSolid)
			result = mSolid->GetExtent(inTransform,ioExtent,inIncludeStroke);
		return CachedExtentRenderer::GetExtent(inTransform,ioExtent,inIncludeStroke) || result;
	}
	
	
	bool TriangleLineRender::Hits(const RenderState &inState)
	{
		if (mSolid && mSolid->Hits(inState))
			return true;
		return LineRender::Hits(inState);
	}
	
	
	int TriangleLineRender::Iterate(IterateMode inMode,const Matrix &m)
	{
		ItLine = inMode==itGetExtent ? &LineRender::BuildExtent :
				inMode==itCreateRenderer ? &LineRender::BuildSolid :
						&LineRender::BuildHitTest;
		
	  double perp_len = GetPerpLen(m);
		
	  UserPoint *point = 0;
	  if (inMode==itHitTest)
		 point = &mTriangles->mVertices[0];
	  else
		 point = &mTransformed[0];
		
		int tris = mTriangles->mTriangleCount;
	  for(int i=0;i<tris;i++)
		{
			UserPoint v0 = *point++;
			UserPoint v1 = *point++;
			UserPoint v2 = *point++;
			
			UserPoint perp0 = (v1-v0).Perp(perp_len);
			UserPoint perp1 = (v2-v1).Perp(perp_len);
			UserPoint perp2 = (v0-v2).Perp(perp_len);
			
			AddJoint(v0,perp2,perp0);
		 AddLinePart(v0+perp0,v1+perp0,v1-perp0,v0-perp0);
			AddJoint(v1,perp0,perp1);
		 AddLinePart(v1+perp1,v2+perp1,v2-perp1,v1-perp1);
			AddJoint(v2,perp1,perp2);
		 AddLinePart(v2+perp2,v0+perp2,v0-perp2,v2-perp2);
		}
		
	  return 256;
	}
	
	
	bool TriangleLineRender::Render( const RenderTarget &inTarget, const RenderState &inState )
	{
		if (mSolid)
			mSolid->Render(inTarget,inState);
		return LineRender::Render(inTarget,inState);
	}
	

	void TriangleLineRender::SetTransform(const Transform &inTransform)
	{
		int points = mTriangles->mVertices.size();
		if (points!=mTransformed.size() || inTransform!=mTransform)
		{
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
	
}
