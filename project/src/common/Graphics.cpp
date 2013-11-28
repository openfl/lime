#include <Graphics.h>
#include "renderer/common/Surface.h"
#include <Display.h>

namespace lime
{

void Graphics::OnChanged()
{
   mVersion++;
   if (mOwner && !(mOwner->mDirtyFlags & dirtExtent))
      mOwner->DirtyExtent();
}



// TODO: invlidate/cache extents (do for whole lot at once)

Graphics::Graphics(DisplayObject *inOwner,bool inInitRef) : Object(inInitRef)
{
   mRotation0 = 0;
   mCursor = UserPoint(0,0);
   mHardwareData = 0;
   mPathData = new GraphicsPath;
   mBuiltHardware = 0;
   mTileJob.mIsTileJob = true;
   mMeasuredJobs = 0;
   mVersion = 0;
   mOwner = inOwner;
}


Graphics::~Graphics()
{
   mOwner = 0;
   clear();
   mPathData->DecRef();
}


void Graphics::clear()
{
   mFillJob.clear();
   mLineJob.clear();
   mTileJob.clear();

   // clear jobs
   for(int i=0;i<mJobs.size();i++)
      mJobs[i].clear();
   mJobs.resize(0);

   if (mHardwareData)
   {
      delete mHardwareData;
      mHardwareData = 0;
   }
   mPathData->clear();

   mExtent0 = Extent2DF();
   mRotation0 = 0;
   mBuiltHardware = 0;
   mMeasuredJobs = 0;
   mCursor = UserPoint(0,0);
   OnChanged();
}

int Graphics::Version() const
{
   int result = mVersion;
	for(int i=0;i<mJobs.size();i++)
		result += mJobs[i].Version();
	return result;
}

#define SIN45 0.70710678118654752440084436210485
#define TAN22 0.4142135623730950488016887242097

void Graphics::drawEllipse(float x, float y, float width, float height)
{
   x += width/2;
   y += height/2;
   float w = width*0.5;
   float w_ = w*SIN45;
   float cw_ = w*TAN22;
   float h = height*0.5;
   float h_ = h*SIN45;
   float ch_ = h*TAN22;

   Flush();

   mPathData->moveTo(x+w,y);
   mPathData->curveTo(x+w,  y+ch_, x+w_, y+h_);
   mPathData->curveTo(x+cw_,y+h,   x,    y+h);
   mPathData->curveTo(x-cw_,y+h,   x-w_, y+h_);
   mPathData->curveTo(x-w,  y+ch_, x-w,  y);
   mPathData->curveTo(x-w,  y-ch_, x-w_, y-h_);
   mPathData->curveTo(x-cw_,y-h,   x,    y-h);
   mPathData->curveTo(x+cw_,y-h,   x+w_, y-h_);
   mPathData->curveTo(x+w,  y-ch_, x+w,  y);

   Flush();
   OnChanged();
}

/*

   < ------------ w ----->
      < -------- w_ ----->
       < ------ cw_ ----->
             < --- lw ---> 
        c   --------------+
         222 |            x
        2    |
       p
    c 1 ..   ry
     1    . 
     1     ..|
    | - rx --
    |
    |

*/

void Graphics::drawRoundRect(float x,float  y,float  width,float  height,float  rx,float  ry)
{
   rx *= 0.5;
   ry *= 0.5;
   float w = width*0.5;
   x+=w;
   if (rx>w) rx = w;
   float lw = w - rx;
   float w_ = lw + rx*SIN45;
   float cw_ = lw + rx*TAN22;
   float h = height*0.5;
   y+=h;
   if (ry>h) ry = h;
   float lh = h - ry;
   float h_ = lh + ry*SIN45;
   float ch_ = lh + ry*TAN22;

   Flush();

   mPathData->moveTo(x+w,y+lh);
   mPathData->curveTo(x+w,  y+ch_, x+w_, y+h_);
   mPathData->curveTo(x+cw_,y+h,   x+lw,    y+h);
   mPathData->lineTo(x-lw,    y+h);
   mPathData->curveTo(x-cw_,y+h,   x-w_, y+h_);
   mPathData->curveTo(x-w,  y+ch_, x-w,  y+lh);
   mPathData->lineTo( x-w, y-lh);
   mPathData->curveTo(x-w,  y-ch_, x-w_, y-h_);
   mPathData->curveTo(x-cw_,y-h,   x-lw,    y-h);
   mPathData->lineTo(x+lw,    y-h);
   mPathData->curveTo(x+cw_,y-h,   x+w_, y-h_);
   mPathData->curveTo(x+w,  y-ch_, x+w,  y-lh);
   mPathData->lineTo(x+w,  y+lh);

   Flush();
   OnChanged();
}

void Graphics::drawPath(const QuickVec<uint8> &inCommands, const QuickVec<float> &inData,
           WindingRule inWinding )
{
   int n = inCommands.size();
   if (n==0 || inData.size()<2)
      return;

   const UserPoint *point = (UserPoint *)&inData[0];
   const UserPoint *last =  point + inData.size()/2;

   if ( (mFillJob.mFill && mFillJob.mCommand0==mPathData->commands.size()) ||
        (mLineJob.mStroke && mLineJob.mCommand0==mPathData->commands.size()) )
     mPathData->initPosition(mCursor);

   for(int i=0;i<n && point<last;i++)
   {
      switch(inCommands[i])
      {
         case pcWideMoveTo:
            point++;
            if (point==last) break;
         case pcMoveTo:
            mPathData->moveTo(point->x,point->y);
            mCursor = *point++;
            break;

         case pcWideLineTo:
            point++;
            if (point==last) break;
         case pcLineTo:
            mPathData->lineTo(point->x,point->y);
            mCursor = *point++;
            break;

         case pcCurveTo:
            if (point+1==last) break;
            mPathData->curveTo(point->x,point->y,point[1].x,point[1].y);
            mCursor = point[1];
            point += 2;
      }
   }
   OnChanged();
}



void Graphics::drawGraphicsDatum(IGraphicsData *inData)
{
   switch(inData->GetType())
   {
      case gdtUnknown: break;
      case gdtTrianglePath: break;
      case gdtPath:
         {
         GraphicsPath *path = inData->AsPath();
         drawPath(path->commands, path->data, path->winding);
         break;
         }
      case gdtEndFill:
         endFill();
         break;
      case gdtSolidFill:
      case gdtGradientFill:
      case gdtBitmapFill:
         {
         IGraphicsFill *fill = inData->AsIFill();
         if (fill->isSolidStyle())
         {
            Flush(false,true);
            endTiles();
            if (mFillJob.mFill)
               mFillJob.mFill->DecRef();
            mFillJob.mFill = fill;
            mFillJob.mFill->IncRef();
            if (mFillJob.mCommand0 == mPathData->commands.size())
               mPathData->initPosition(mCursor);
         }
         else if (mLineJob.mStroke)
         {
            Flush(true,false);
            mLineJob.mStroke = mLineJob.mStroke->CloneWithFill(fill);
         }
         }
         break;
      case gdtStroke:
         {
         Flush(true,false);
         if (mLineJob.mStroke)
         {
            mLineJob.mStroke->DecRef();
            mLineJob.mStroke = 0;
         }
         GraphicsStroke *stroke = inData->AsStroke();
         if (stroke->thickness>=0 && stroke->fill)
         {
            mLineJob.mStroke = stroke;
            mLineJob.mStroke->IncRef();
            if (mLineJob.mCommand0 == mPathData->commands.size())
               mPathData->initPosition(mCursor);
         }
         }
         break;

   }
   OnChanged();
}

void Graphics::drawGraphicsData(IGraphicsData **graphicsData,int inN)
{
   for(int i=0;i<inN;i++)
      drawGraphicsDatum(graphicsData[i]);
   OnChanged();
}

void Graphics::beginFill(unsigned int color, float alpha)
{
   Flush(false,true,true);
   endTiles();
   if (mFillJob.mFill)
      mFillJob.mFill->DecRef();
   mFillJob.mFill = new GraphicsSolidFill(color,alpha);
   mFillJob.mFill->IncRef();
   if (mFillJob.mCommand0 == mPathData->commands.size())
      mPathData->initPosition(mCursor);
}

void Graphics::endFill()
{
   Flush(true,true);
   if (mFillJob.mFill)
   {
      mFillJob.mFill->DecRef();
      mFillJob.mFill = 0;
   }
}

void Graphics::beginBitmapFill(Surface *bitmapData, const Matrix &inMatrix,
   bool inRepeat, bool inSmooth)
{
   Flush(false,true,true);
   endTiles();
   if (mFillJob.mFill)
      mFillJob.mFill->DecRef();
   mFillJob.mFill = new GraphicsBitmapFill(bitmapData,inMatrix,inRepeat,inSmooth);
   mFillJob.mFill->IncRef();
   if (mFillJob.mCommand0 == mPathData->commands.size())
      mPathData->initPosition(mCursor);
}

void Graphics::endTiles()
{
   if (mTileJob.mFill)
   {
      mTileJob.mFill->DecRef();
      mTileJob.mFill = 0;

      OnChanged();
   }
}

void Graphics::beginTiles(Surface *bitmapData,bool inSmooth,int inBlendMode)
{
   endFill();
   lineStyle(-1);
   Flush();
   if (mTileJob.mFill)
      mTileJob.mFill->DecRef();
   mTileJob.mFill = new GraphicsBitmapFill(bitmapData,Matrix(),false,inSmooth);
   mTileJob.mFill->IncRef();
   mPathData->elementBlendMode(inBlendMode);
}

void Graphics::lineStyle(double thickness, unsigned int color, double alpha,
                  bool pixelHinting, StrokeScaleMode scaleMode,
                  StrokeCaps caps,
                  StrokeJoints joints, double miterLimit)
{
   Flush(true,false,true);
   endTiles();
   if (mLineJob.mStroke)
   {
      mLineJob.mStroke->DecRef();
      mLineJob.mStroke = 0;
   }
   if (thickness>=0)
   {
      IGraphicsFill *solid = new GraphicsSolidFill(color,alpha);
      mLineJob.mStroke = new GraphicsStroke(solid,thickness,pixelHinting,
          scaleMode,caps,joints,miterLimit);
      mLineJob.mStroke->IncRef();
      if (mLineJob.mCommand0 == mPathData->commands.size())
         mPathData->initPosition(mCursor);
   }
}



void Graphics::lineTo(float x, float y)
{
   if ( (mFillJob.mFill && mFillJob.mCommand0==mPathData->commands.size()) ||
        (mLineJob.mStroke && mLineJob.mCommand0==mPathData->commands.size()) )
     mPathData->initPosition(mCursor);

   mPathData->lineTo(x,y);
   mCursor = UserPoint(x,y);
   OnChanged();
}

void Graphics::moveTo(float x, float y)
{
   mPathData->moveTo(x,y);
   mCursor = UserPoint(x,y);
   OnChanged();
}

void Graphics::curveTo(float cx, float cy, float x, float y)
{
   if ( (mFillJob.mFill && mFillJob.mCommand0==mPathData->commands.size()) ||
        (mLineJob.mStroke && mLineJob.mCommand0==mPathData->commands.size()) )
     mPathData->initPosition(mCursor);

   if ( (fabs(mCursor.x-cx)<0.00001 && fabs(mCursor.y-cy)<0.00001) ||
        (fabs(x-cx)<0.00001 && fabs(y-cy)<0.00001)  )
   {
      mPathData->lineTo(x,y);
   }
   else
      mPathData->curveTo(cx,cy,x,y);
   mCursor = UserPoint(x,y);
   OnChanged();
}

void Graphics::arcTo(float cx, float cy, float x, float y)
{
   if ( (mFillJob.mFill && mFillJob.mCommand0==mPathData->commands.size()) ||
        (mLineJob.mStroke && mLineJob.mCommand0==mPathData->commands.size()) )
     mPathData->initPosition(mCursor);

   mPathData->arcTo(cx,cy,x,y);
   mCursor = UserPoint(x,y);
   OnChanged();
}

void Graphics::tile(float x, float y, const Rect &inTileRect,float *inTrans,float *inRGBA)
{
   mPathData->tile(x,y,inTileRect,inTrans,inRGBA);
}


void Graphics::drawPoints(QuickVec<float> inXYs, QuickVec<int> inRGBAs, unsigned int inDefaultRGBA,
								  double inSize)
{
   endFill();
   lineStyle(-1);
   Flush();

   GraphicsJob job;
   job.mCommand0 = mPathData->commands.size();
   job.mCommandCount = 1;
   job.mData0 = mPathData->data.size();
   job.mIsPointJob = true;
   mPathData->drawPoints(inXYs,inRGBAs);
   job.mDataCount = mPathData->data.size() - job.mData0;
   if (mPathData->commands[job.mCommand0]==pcPointsXY)
   {
      job.mFill = new GraphicsSolidFill(inDefaultRGBA&0xffffff,(inDefaultRGBA>>24)/255.0);
      job.mFill->IncRef();
   }
	if (inSize>0)
	{
		job.mStroke = new GraphicsStroke(0,inSize);
		job.mStroke->IncRef();
	}

   mJobs.push_back(job);
}

void Graphics::drawTriangles(const QuickVec<float> &inXYs,
            const QuickVec<int> &inIndices,
            const QuickVec<float> &inUVT, int inCull,
            const QuickVec<int> &inColours,
            int blendMode, const QuickVec<float,4> &inViewport )
{
	Flush( );
	
	if (!mFillJob.mFill)
	{
		beginFill (0, 0);
	}
	
	IGraphicsFill *fill = mFillJob.mFill;

   GraphicsTrianglePath *path = new GraphicsTrianglePath(inXYs,
           inIndices, inUVT, inCull, inColours, blendMode, inViewport );
   GraphicsJob job;
   path->IncRef();

	if (!fill || !fill->AsBitmapFill())
		path->mUVT.resize(0);

   job.mFill = fill ? fill->IncRef() : 0;
   job.mStroke = mLineJob.mStroke ? mLineJob.mStroke->IncRef() : 0;
   job.mTriangles = path;

   mJobs.push_back(job);
}



// This routine converts a list of "GraphicsPaths" (mItems) into a list
//  of LineData and SolidData.
// The items intermix fill-styles and line-stypes with move/draw/triangle
//  geometry data - this routine separates them out.

void Graphics::Flush(bool inLine, bool inFill, bool inTile)
{
   int n = mPathData->commands.size();
   int d = mPathData->data.size();
   bool wasFilled = false;

   if (inTile)
   {
      if (mTileJob.mFill && mTileJob.mCommand0 <n)
      {
         mTileJob.mFill->IncRef();
         mTileJob.mDataCount = d-mTileJob.mData0;
         mTileJob.mCommandCount = n-mTileJob.mCommand0;
         mTileJob.mIsTileJob = true;
         mJobs.push_back(mTileJob);
      }
   }


   // Do fill first, so lines go over top.
   if (inFill)
   {
      if (mFillJob.mFill && mFillJob.mCommand0 <n)
      {
         mFillJob.mFill->IncRef();
         mFillJob.mCommandCount = n-mFillJob.mCommand0;
         mFillJob.mDataCount = d-mFillJob.mData0;
         wasFilled = true;

         // Move the fill job up the list so it is "below" lines that start at the same
         // (or later) data point
         int pos = mJobs.size()-1;
         while(pos>=0)
         {
            if (mJobs[pos].mData0 < mFillJob.mData0)
               break;
            pos--;
         }
         pos++;
         if (pos==mJobs.size())
         {
            mJobs.push_back(mFillJob);
         }
         else
         {
            mJobs.InsertAt(0,mFillJob);
         }
         mFillJob.mCommand0 = n;
         mFillJob.mData0 = d;
      }
   }


   if (inLine)
   {
      if (mLineJob.mStroke && mLineJob.mCommand0 <n-1)
      {
         mLineJob.mStroke->IncRef();

         // Add closing segment...
         if (wasFilled)
         {
            mPathData->closeLine(mLineJob.mCommand0,mLineJob.mData0);
            n = mPathData->commands.size();
            d = mPathData->data.size();
         }
         mLineJob.mCommandCount = n-mLineJob.mCommand0;
         mLineJob.mDataCount = d-mLineJob.mData0;
         mJobs.push_back(mLineJob);
      }
      mLineJob.mCommand0 = n;
      mLineJob.mData0 = d;
   }


   if (inTile)
   {
      mTileJob.mCommand0 = n;
      mTileJob.mData0 = d;
   }

   if (inFill)
   {
      mFillJob.mCommand0 = n;
      mFillJob.mData0 = d;
   }

}


Extent2DF Graphics::GetSoftwareExtent(const Transform &inTransform, bool inIncludeStroke)
{
   Extent2DF result;
   Flush();

   for(int i=0;i<mJobs.size();i++)
   {
      GraphicsJob &job = mJobs[i];
      if (!job.mSoftwareRenderer)
         job.mSoftwareRenderer = Renderer::CreateSoftware(job,*mPathData);

      job.mSoftwareRenderer->GetExtent(inTransform,result,inIncludeStroke);
   }

   return result;
}

const Extent2DF &Graphics::GetExtent0(double inRotation)
{
   if ( mMeasuredJobs<mJobs.size() || inRotation!=mRotation0)
   {
      Transform trans;
      Matrix  m;
      trans.mMatrix = &m;
      if (inRotation)
         m.Rotate(inRotation);
      mExtent0 = GetSoftwareExtent(trans,true);
      mRotation0 = inRotation;
      mMeasuredJobs = mJobs.size();
   }
   return mExtent0;
}


bool Graphics::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   Flush();
   
   #ifdef LIME_DIRECTFB
   
   for(int i=0;i<mJobs.size();i++)
   {
      GraphicsJob &job = mJobs[i];
      
      if (!job.mHardwareRenderer /*&& !job.mSoftwareRenderer*/)
         job.mHardwareRenderer = Renderer::CreateHardware(job,*mPathData,*inTarget.mHardware);
      
      //if (!job.mSoftwareRenderer)
         //job.mSoftwareRenderer = Renderer::CreateSoftware(job,*mPathData);
      
      if (inState.mPhase==rpHitTest)
      {
         if (job.mHardwareRenderer && job.mSoftwareRenderer->Hits(inState))
         {
            return true;
         }
         /*else if (job.mSoftwareRenderer && job.mSoftwareRenderer->Hits(inState))
         {
            return true;
         }*/
      }
      else
      {
         if (job.mHardwareRenderer)
            job.mHardwareRenderer->Render(inTarget,inState);
         //else
            //job.mSoftwareRenderer->Render(inTarget,inState);
      }
   }
   
   #else
   
   if (inTarget.IsHardware())
   {
      if (!mHardwareData)
         mHardwareData = new HardwareData();
      
      while(mBuiltHardware<mJobs.size())
      {
         BuildHardwareJob(mJobs[mBuiltHardware++],*mPathData,*mHardwareData,*inTarget.mHardware);
      }
      
      if (mHardwareData->mCalls.size())
      {
         if (inState.mPhase==rpHitTest)
            return inTarget.mHardware->Hits(inState,mHardwareData->mCalls);
         else
            inTarget.mHardware->Render(inState,mHardwareData->mCalls);
      }
   }
   else
   {
      for(int i=0;i<mJobs.size();i++)
      {
         GraphicsJob &job = mJobs[i];
         if (!job.mSoftwareRenderer)
            job.mSoftwareRenderer = Renderer::CreateSoftware(job,*mPathData);

         if (inState.mPhase==rpHitTest)
         {
            if (job.mSoftwareRenderer->Hits(inState))
               return true;
         }
         else
            job.mSoftwareRenderer->Render(inTarget,inState);
      }
   }
   
   #endif

   return false;
}


// --- RenderState -------------------------------------------------------------------

void GraphicsJob::clear()
{
   if (mStroke) mStroke->DecRef();
   if (mFill) mFill->DecRef();
   if (mTriangles) mTriangles->DecRef();
   if (mSoftwareRenderer) mSoftwareRenderer->Destroy();
   bool was_tile = mIsTileJob;
   memset(this,0,sizeof(GraphicsJob));
   mIsTileJob = was_tile;
}

// --- RenderState -------------------------------------------------------------------

ColorTransform sgIdentityColourTransform;

RenderState::RenderState(Surface *inSurface,int inAA)
{
   mTransform.mAAFactor = inAA;
   mMask = 0;
   mPhase = rpRender;
   mAlpha_LUT = 0;
   mC0_LUT = 0;
   mC1_LUT = 0;
   mC2_LUT = 0;
   mColourTransform = &sgIdentityColourTransform;
   mRoundSizeToPOW2 = false;
   mHitResult = 0;
	mRecurse = true;
	mTargetOffset = ImagePoint(0,0);
   if (inSurface)
   {
      mClipRect = Rect(inSurface->Width(),inSurface->Height());
   }
   else
      mClipRect = Rect(0,0);
}



void RenderState::CombineColourTransform(const RenderState &inState,
                                         const ColorTransform *inObjTrans,
                                         ColorTransform *inBuf)
{
   mAlpha_LUT = mColourTransform->IsIdentityAlpha() ? 0 : mColourTransform->GetAlphaLUT();
   if (inObjTrans->IsIdentity())
   {
      mColourTransform = inState.mColourTransform;
      mAlpha_LUT = inState.mAlpha_LUT;
      mC0_LUT = inState.mC0_LUT;
      mC1_LUT = inState.mC1_LUT;
      mC2_LUT = inState.mC2_LUT;
      return;
   }

   mColourTransform = inBuf;
   inBuf->Combine(*(inState.mColourTransform),*inObjTrans);

   if (mColourTransform->IsIdentityColour())
   {
      mC0_LUT = 0;
      mC1_LUT = 0;
      mC2_LUT = 0;
   }
   else
   {
      mC0_LUT = mColourTransform->GetC0LUT();
      mC1_LUT = mColourTransform->GetC1LUT();
      mC2_LUT = mColourTransform->GetC2LUT();
   }

   if (mColourTransform->IsIdentityAlpha())
      mAlpha_LUT = 0;
   else
      mAlpha_LUT = mColourTransform->GetAlphaLUT();
}



// --- RenderTarget -------------------------------------------------------------------

RenderTarget::RenderTarget(const Rect &inRect,PixelFormat inFormat,uint8 *inPtr, int inStride)
{
   mRect = inRect;
   mPixelFormat = inFormat;
   mSoftPtr = inPtr;
   mSoftStride = inStride;
   mHardware = 0;
}

RenderTarget::RenderTarget(const Rect &inRect,HardwareContext *inContext)
{
   mRect = inRect;
   mPixelFormat = pfHardware;
   mSoftPtr = 0;
   mSoftStride = 0;
   mHardware = inContext;
}

RenderTarget::RenderTarget() : mRect(0,0)
{
   mPixelFormat = pfAlpha;
   mSoftPtr = 0;
   mSoftStride = 0;
   mHardware = 0;
}


RenderTarget RenderTarget::ClipRect(const Rect &inRect) const
{
   RenderTarget result = *this;
   result.mRect = result.mRect.Intersect(inRect);
   return result;
}

void RenderTarget::Clear(uint32 inColour, const Rect &inRect) const
{
   if (IsHardware())
   {
      mHardware->Clear(inColour,&inRect);
      return;
   }

   if (mPixelFormat==pfAlpha)
   {
      int val = inColour>>24;
      for(int y=inRect.y;y<inRect.y1();y++)
      {
         uint8 *alpha = (uint8 *)Row(y) + inRect.x;
         memset(alpha,val,inRect.w);
      }
   }
   else
   {
      ARGB rgb(inColour);
      if ( mPixelFormat&pfSwapRB)
         rgb.SwapRB();
      if (!(mPixelFormat & pfHasAlpha))
         rgb.a = 255;

      for(int y=inRect.y;y<inRect.y1();y++)
      {
         int *ptr = (int *)Row(y) + inRect.x;
         for(int x=0;x<inRect.w;x++)
            *ptr++ = rgb.ival;
      }
 
   }
}




// --- GraphicsBitmapFill -------------------------------------------------------------------

GraphicsBitmapFill::GraphicsBitmapFill(Surface *inBitmapData,
      const Matrix &inMatrix, bool inRepeat, bool inSmooth) : bitmapData(inBitmapData),
         matrix(inMatrix),  repeat(inRepeat), smooth(inSmooth)
{
   if (bitmapData)
      bitmapData->IncRef();
}

GraphicsBitmapFill::~GraphicsBitmapFill()
{
   if (bitmapData)
      bitmapData->DecRef();
}

int GraphicsBitmapFill::Version() const
{
	return bitmapData->Version();
}
// --- GraphicsStroke -------------------------------------------------------------------

GraphicsStroke::GraphicsStroke(IGraphicsFill *inFill, double inThickness,
                  bool inPixelHinting, StrokeScaleMode inScaleMode,
                  StrokeCaps inCaps,
                  StrokeJoints inJoints, double inMiterLimit)
      : fill(inFill), thickness(inThickness), pixelHinting(inPixelHinting),
        scaleMode(inScaleMode), caps(inCaps), joints(inJoints), miterLimit(inMiterLimit)
   {
      if (fill)
         fill->IncRef();
   }


GraphicsStroke::~GraphicsStroke()
{
   if (fill)
      fill->DecRef();
}

GraphicsStroke *GraphicsStroke::CloneWithFill(IGraphicsFill *inFill)
{
   if (mRefCount < 2)
   {
      inFill->IncRef();
      if (fill)
         fill->DecRef();
      fill = inFill;
      return this;
   }

   GraphicsStroke *clone = new GraphicsStroke(inFill,thickness,pixelHinting,scaleMode,caps,joints,miterLimit);
   DecRef();
   clone->IncRef();
   return clone;
}



// --- Gradient ---------------------------------------------------------------------


static void GetLinearLookups(int **outToLinear, int **outFromLinear)
{
   static int *to = 0;
   static int *from = 0;

   if (!to)
   {
      double a = 0.055;
      to = new int[256];
      from = new int[4096];

      for(int i=0;i<4096;i++)
      {
         double t = i / 4095.0;
         from[i] = 255.0 * (t<=0.0031308 ? t*12.92 : (a+1)*pow(t,1/2.4)-a) + 0.5;
      }

      for(int i=0;i<256;i++)
      {
         double t = i / 255.0;
         to[i] = 4095.0 * ( t<=0.04045 ? t/12.92 : pow( (t+a)/(1+a), 2.4 ) ) + 0.5;
      }
   }

   *outToLinear = to;
   *outFromLinear = from;
}


void GraphicsGradientFill::FillArray(ARGB *outColours, bool inSwap)
{
   int *ToLinear = 0;
   int *FromLinear = 0;

   if (interpolationMethod==imLinearRGB)
      GetLinearLookups(&ToLinear,&FromLinear);
    
   bool reflect = spreadMethod==smReflect;
   int n = mStops.size();
   if (n==0)
      memset(outColours,0,sizeof(ARGB)*(reflect?512:256));
   else
   {
      int i;
      int last = mStops[0].mPos;
      if (last>255) last = 255;

      for(i=0;i<=last;i++)
         outColours[i] = mStops[0].mARGB;
      for(int k=0;k<n-1;k++)
      {
         ARGB c0 = mStops[k].mARGB;
         int p0 = mStops[k].mPos;
         int p1 = mStops[k+1].mPos;
         int diff = p1 - p0;
         if (diff>0)
         {
            if (p0<0) p0 = 0;
            if (p1>256) p1 = 256;

            int da = mStops[k+1].mARGB.a - c0.a;
            if (ToLinear)
            {
               int dc0 = ToLinear[mStops[k+1].mARGB.c0] - ToLinear[c0.c0];
               int dc1 = ToLinear[mStops[k+1].mARGB.c1] - ToLinear[c0.c1];
               int dc2 = ToLinear[mStops[k+1].mARGB.c2] - ToLinear[c0.c2];
               for(i=p0;i<p1;i++)
               {
                  outColours[i].c1= FromLinear[ ToLinear[c0.c1] + dc1*(i-p0)/diff];
                  if (inSwap)
                  {
                     outColours[i].c2= FromLinear[ ToLinear[c0.c0] + dc0*(i-p0)/diff];
                     outColours[i].c0= FromLinear[ ToLinear[c0.c2] + dc2*(i-p0)/diff];
                  }
                  else
                  {
                     outColours[i].c0= FromLinear[ ToLinear[c0.c0] + dc0*(i-p0)/diff];
                     outColours[i].c2= FromLinear[ ToLinear[c0.c2] + dc2*(i-p0)/diff];
                  }
                  outColours[i].a = FromLinear[ ToLinear[c0.a] + da*(i-p0)/diff];
               }
            }
            else
            {
               int dc0 = mStops[k+1].mARGB.c0 - c0.c0;
               int dc1 = mStops[k+1].mARGB.c1 - c0.c1;
               int dc2 = mStops[k+1].mARGB.c2 - c0.c2;
               for(i=p0;i<p1;i++)
               {
                  outColours[i].c1 = c0.c1 + dc1*(i-p0)/diff;
                  if (inSwap)
                  {
                     outColours[i].c2 = c0.c0 + dc0*(i-p0)/diff;
                     outColours[i].c0 = c0.c2 + dc2*(i-p0)/diff;
                  }
                  else
                  {
                     outColours[i].c0 = c0.c0 + dc0*(i-p0)/diff;
                     outColours[i].c2 = c0.c2 + dc2*(i-p0)/diff;
                  }
                  outColours[i].a = c0.a + da*(i-p0)/diff;
               }
            }
         }
      }
      for(;i<256;i++)
         outColours[i] = mStops[n-1].mARGB;

      if (reflect)
      {
         for(;i<512;i++)
            outColours[i] = outColours[511-i];
      }
   }
}

// --- Helper ----------------------------------------

int UpToPower2(int inX)
{
   int result = 1;
   while(result<inX) result<<=1;
   return result;
}

}
