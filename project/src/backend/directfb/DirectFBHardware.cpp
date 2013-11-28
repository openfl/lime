#include <Graphics.h>
#include "renderer/common/HardwareContext.h"
#include "renderer/common/Texture.h"
#include <directfb.h>


namespace lime
{


// --- HardwareContext -----------------------------


class DirectFBHardwareContext : public HardwareContext
{
public:
   IDirectFB *mDirectFB;
   IDirectFBSurface *mPrimarySurface;
   int mWidth;
   int mHeight;
   
   DirectFBHardwareContext(IDirectFB *inDirectFB, IDirectFBSurface *inSurface)
   {
      mDirectFB = inDirectFB;
      mPrimarySurface = inSurface;
      mWidth = mHeight = 0;
   }
   
   void SetWindowSize(int inWidth, int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
   }
   
   void SetQuality(StageQuality inQuality) {}
   
   void BeginRender(const Rect &inRect,bool inForHitTest)
   {
      mPrimarySurface->Clear(mPrimarySurface, 0xFF, 0xFF, 0xFF, 0xFF);
   }
   
   void EndRender()
   {
      mPrimarySurface->Flip(mPrimarySurface, NULL, (DFBSurfaceFlipFlags)0);
   }
   
   void SetViewport(const Rect &inRect)
   {
      mBitmapRect = inRect;
   }
   
   void Clear(uint32 inColour,const Rect *inRect=0) {}
   void Flip() {}
   void DestroyNativeTexture(void *) {}
   
   int Width() const { return mWidth; }
   int Height() const { return mHeight; } 
   
   class Texture *CreateTexture(class Surface *inSurface, unsigned int inFlags);
   void Render(const RenderState &inState, const HardwareCalls &inCalls) {}
   
   void BeginBitmapRender(Surface *inSurface,uint32 inTint, bool inRepeat, bool inSmooth)
   {
      mBitmapSurface = inSurface;
      mBitmapTint = inTint;
      
      mPrimarySurface->Lock(mPrimarySurface, DSLF_WRITE, (void **)&mPixels, &mPitch);
   }
   
   void RenderBitmap(const Rect &inSrc, int inX, int inY)
   {
      const RenderTarget &target = RenderTarget(mBitmapRect, pfSwapRB, mPixels, mPitch);
      mBitmapSurface->BlitTo(target, inSrc, inX, inY, bmTinted, 0, mBitmapTint);
   }
   
   void EndBitmapRender()
   {
      mPrimarySurface->Unlock(mPrimarySurface);
   }
   
private:
   Rect mBitmapRect;
   Surface *mBitmapSurface;
   uint32 mBitmapTint;
   uint8 *mPixels;
   int mPitch;
   
};


class DirectFBTexture : public Texture
{
public:
   unsigned int flags;
   int          width;
   int          height;
   IDirectFBSurface *dfbSurface;
   
   DirectFBTexture(DirectFBHardwareContext *inContext, Surface *inSurface, unsigned int inFlags)
   {
      width = inSurface->Width();
      height = inSurface->Height();
      
      DFBSurfaceDescription dsc;
      dsc.width = width;
      dsc.height = height;
      dsc.flags = (DFBSurfaceDescriptionFlags)(DSDESC_HEIGHT | DSDESC_WIDTH | DSDESC_PREALLOCATED | DSDESC_PIXELFORMAT | DSDESC_CAPS);
      dsc.caps = DSCAPS_NONE;
      dsc.pixelformat = DSPF_ARGB;
      
      uint8 *pixelData = (uint8 *)malloc(inSurface->Width()*inSurface->Height()*4);
      for (int y=0;y<inSurface->Height();y++)
      {
         const uint8 *source = inSurface->Row(y);
         uint8 *dest = pixelData + (y*inSurface->Width()*4);
         for (int x=0;x<inSurface->Width();x++)
         {
            dest[0] = source[2];
            dest[1] = source[1];
            dest[2] = source[0];
            dest[3] = source[3];
            dest += 4;
            source += 4;
         }
      }
      
      dsc.preallocated[0].data = pixelData;
      dsc.preallocated[0].pitch = inSurface->GetStride();
      dsc.preallocated[1].data = NULL;
      dsc.preallocated[1].pitch = 0;
      
      inContext->mDirectFB->CreateSurface(inContext->mDirectFB, &dsc, &dfbSurface);
   }
   
   ~DirectFBTexture()
   {
      //dispose of dfbSurface somehow
      free(pixelData);
   }
   
   void Bind(class Surface *inSurface, int inSlot) {}
   void BindFlags(bool inRepeat, bool inSmooth) {}
   
   UserPoint PixelToTex(const UserPoint &inPixels)
   {
      return UserPoint(inPixels.x/width, inPixels.y/height);
   }
   
   UserPoint TexToPaddedTex(const UserPoint &inPixels)
   {
      return inPixels;
   }
   
private:
   uint8 *pixelData;
   
};


class Texture *DirectFBHardwareContext::CreateTexture(class Surface *inSurface, unsigned int inFlags)
{
   return new DirectFBTexture(this, inSurface, inFlags);
}


HardwareContext *HardwareContext::current = 0;

HardwareContext *HardwareContext::CreateDirectFB(void *inDirectFB, void *inSurface)
{
   return new DirectFBHardwareContext((IDirectFB*)inDirectFB, (IDirectFBSurface*)inSurface);
}


HardwareContext *HardwareContext::CreateOpenGL(void *inWindow, void *inGLCtx, bool shaders)
{
   return NULL;
}


// --- Hardware Renderer ---------------------------------------------------------------------


Renderer *CreateLineRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath);
Renderer *CreateTriangleLineRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath, Renderer *inSolid);
Renderer *CreateSolidRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath);
Renderer *CreatePointRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath);
Renderer *CreateTileRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath);
Renderer *CreateTriangleRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath);


class HardwareRenderer : public Renderer
{
public:
   HardwareRenderer(const GraphicsJob &inJob, const GraphicsPath &inPath, HardwareContext &inHardware)
   {
      mJob = &inJob;
      mPath = &inPath;
      mContext = (DirectFBHardwareContext*)&inHardware;
      mPrimarySurface = mContext->mPrimarySurface;
      mSoftwareRenderer = 0;
      
      if (inJob.mTriangles)
      {
         Renderer *solid = 0;
         if (inJob.mFill)
            solid = CreateTriangleRenderer(inJob,inPath);
         mSoftwareRenderer = inJob.mStroke ? CreateTriangleLineRenderer(inJob,inPath,solid) : solid;
      }
      else if (inJob.mIsTileJob)
      {
         //TODO: Use DirectFB blitting instead of the software renderer
         mSoftwareRenderer = CreateTileRenderer(inJob,inPath);
      }
      else if (inJob.mIsPointJob)
      {
         mSoftwareRenderer = CreatePointRenderer(inJob,inPath);
      }
      else if (inJob.mStroke)
      {
         mSoftwareRenderer = CreateLineRenderer(inJob,inPath);
      }
      else
      {
         //TODO: Detect bitmap blitting
         /* 
         if (mJob->mFill)
         {
            GraphicsBitmapFill *bmp = mJob->mFill->AsBitmapFill();
            if (bmp)
            {
               Surface *surface = bmp->bitmapData->IncRef();
               mTexture = (DirectFBTexture *)surface->GetOrCreateTexture(inHardware);
            }
         }
         bool useHardware = false;
         */
         mSoftwareRenderer = CreateSolidRenderer(inJob,inPath);
      }
   }
   
   void Destroy() {};

   bool Render(const RenderTarget &inTarget, const RenderState &inState)
   {
      if (mSoftwareRenderer)
      {
         uint8 *pixels;
         int pitch;
         
         mPrimarySurface->Lock(mPrimarySurface, DSLF_WRITE, (void **)&pixels, &pitch);
         const RenderTarget &target = RenderTarget(Rect(inState.mClipRect.w,inState.mClipRect.h), pfSwapRB, pixels, pitch);
         mSoftwareRenderer->Render(target, inState);
         mPrimarySurface->Unlock(mPrimarySurface);
         
         return true;
      }
      else
      {
         const Matrix *matrix = inState.mTransform.mMatrix;
         
         if (mJob->mIsTileJob)
         {
            printf("Render tiles\n");
            return true;
         }
         else if (mJob->mFill)
         {
            GraphicsSolidFill *solid = mJob->mFill->AsSolidFill();
            if (solid)
            {
               mPrimarySurface->SetColor(mPrimarySurface, solid->mRGB.c0, solid->mRGB.c1, solid->mRGB.c2, solid->mRGB.a);
            }
            else
            {
               GraphicsGradientFill *grad = mJob->mFill->AsGradientFill();
               if (grad)
               {
                  
               }
               else
               {
                  //GraphicsBitmapFill *bmp = mJob->mFill->AsBitmapFill();
                  //Surface *surface = bmp->bitmapData->IncRef();
                  //mTexture = surface->GetOrCreateTexture(mContext);
                }
             }
         }
         
         if (mJob->mTriangles)
         {
            printf("Render triangle\n");
            return true;
         }
         else if (mJob->mIsPointJob)
         {
            printf("Render point\n");
            return true;
         }
         else if (mJob->mStroke)
         {
            printf("Render stroke\n");
            return true;
         }
         else
         {
            const uint8* inCommands = (const uint8*)&mPath->commands[mJob->mCommand0];
            UserPoint *point = (UserPoint *)&mPath->data[mJob->mData0];
            
            float x0, y0, x1, y1;
            
            for(int i=0; i< mJob->mCommandCount; i++)
            {
               switch(inCommands[i])
               {
                  case pcBeginAt:
                     //printf("begin at\n");
                     // fallthrough
                  case pcMoveTo:
                     //printf("move to\n");
                     //printf("move to: %d %d \n", point->x, point->y);
                     x0 = point->x;
                     y0 = point->y;
                     point++;
                     break;

                  case pcLineTo:
                     if (point->x > x1) x1 = point->x;
                     if (point->x < x0) x0 = point->x;
                     if (point->y > y1) y1 = point->y;
                     if (point->y < y0) y0 = point->y;
                     point++;
                     break;

                  case pcCurveTo:
                     //printf("curve to\n");
                     point++;
                     break;
               }
            }
            
            if (mTexture)
            {
               GraphicsBitmapFill *bmp = mJob->mFill->AsBitmapFill();
               
               if (bmp->repeat)
               {
                  DFBRegion clip;
                  clip.x1 = x0;
                  clip.x2 = x1;
                  clip.y1 = y0;
                  clip.y2 = y1;
                  
                  mPrimarySurface->SetClip(mPrimarySurface, &clip);
                  mPrimarySurface->SetBlittingFlags(mPrimarySurface, DSBLIT_BLEND_ALPHACHANNEL);
                  mPrimarySurface->TileBlit(mPrimarySurface, mTexture->dfbSurface, NULL, x0, y0);
                  mPrimarySurface->SetClip(mPrimarySurface, NULL);
               }
               else
               {
                  if (matrix->GetScaleX() == 1 && matrix->GetScaleY() == 1)
                  {
                     /*DFBSurfaceDescription desc;
                     desc.flags = (DFBSurfaceDescriptionFlags)(DSDESC_WIDTH | DSDESC_HEIGHT);
                     desc.width = mTexture->width;
                     desc.height = mTexture->height;
                     
                     mContext->mDirectFB->CreateSurface(mContext->mDirectFB, &desc, &mMask);
                     
                     mMask->Clear(mMask, 0, 0, 0, 0x88);
                     
                     mPrimarySurface->SetSourceMask(mPrimarySurface, mMask, 0, 0, DSMF_NONE);
                     DFBSurfaceBlittingFlags flags = (DFBSurfaceBlittingFlags)(DSBLIT_BLEND_ALPHACHANNEL | DSBLIT_SRC_MASK_ALPHA);
                     mPrimarySurface->SetBlittingFlags(mPrimarySurface, flags);*/
                     
                     //mPrimarySurface->SetDrawingFlags(mPrimarySurface, DSDRAW_SRC_PREMULTIPLY);
                     //mPrimarySurface->SetDrawingFlags(mPrimarySurface, DSDRAW_BLEND);
                     //mPrimarySurface->SetPorterDuff(mPrimarySurface, DSPD_SRC);
                     //mTexture->dfbSurface->SetColor(mTexture->dfbSurface, 0x0, 0xFF, 0xFF, 0x8);
                     //mPrimarySurface->SetSrcBlendFunction(mPrimarySurface, DSBF_ONE);
                     //mPrimarySurface->SetBlittingFlags(mPrimarySurface, (DFBSurfaceBlittingFlags)(DSBLIT_BLEND_ALPHACHANNEL | DSBLIT_SRC_PREMULTIPLY | DSBLIT_SRC_PREMULTCOLOR));
                     //mPrimarySurface->SetBlittingFlags(mPrimarySurface, (DFBSurfaceBlittingFlags)(DSBLIT_BLEND_ALPHACHANNEL | DSBLIT_SRC_PREMULTIPLY | DSBLIT_SRC_PREMULTCOLOR));
                     mPrimarySurface->SetBlittingFlags(mPrimarySurface, DSBLIT_BLEND_ALPHACHANNEL);
                     mPrimarySurface->Blit(mPrimarySurface, mTexture->dfbSurface, NULL, matrix->mtx, matrix->mty);
                  }
                  else
                  {
                     DFBRectangle srcRect;
                     srcRect.x = srcRect.y = 0;
                     srcRect.w = mTexture->width;
                     srcRect.h = mTexture->height;
                     
                     DFBRectangle target;
                     target.x = matrix->mtx;
                     target.y = matrix->mty;
                     target.w = srcRect.w*matrix->GetScaleX();
                     target.h = srcRect.h*matrix->GetScaleY();
                     
                     mPrimarySurface->SetBlittingFlags(mPrimarySurface, DSBLIT_BLEND_ALPHACHANNEL);
                     mPrimarySurface->StretchBlit(mPrimarySurface, mTexture->dfbSurface, &srcRect, &target);
                  }
               }
            }
            else
            {
               mPrimarySurface->FillRectangle(mPrimarySurface, inState.mTransform.mMatrix->mtx + x0, inState.mTransform.mMatrix->mty + y0, x1 - x0, y1 - y0);
            }
         }
      }
      return true;
   };

   bool GetExtent(const Transform &inTransform,Extent2DF &ioExtent, bool inIncludeStroke) { return false; };
   bool Hits(const RenderState &inState) { return false; }
   
private:
   const GraphicsJob *mJob;
   const GraphicsPath *mPath;
   DirectFBHardwareContext *mContext;
   IDirectFBSurface *mPrimarySurface;
   IDirectFBSurface *mMask;
   DirectFBTexture *mTexture;
   Renderer *mSoftwareRenderer;
   
};


Renderer *Renderer::CreateHardware(const GraphicsJob &inJob, const GraphicsPath &inPath, HardwareContext &inHardware)
{
   return new HardwareRenderer(inJob, inPath, inHardware);
}



// --- HardwareArrays ---------------------------------------------------------------------


HardwareArrays::HardwareArrays(Surface *inSurface,unsigned int inFlags)
{
   mFlags = inFlags;
   mSurface = inSurface;
   if (inSurface)
      inSurface->IncRef();
}

HardwareArrays::~HardwareArrays()
{
   if (mSurface)
      mSurface->DecRef();
}

bool HardwareArrays::ColourMatch(bool inWantColour)
{
   if (mVertices.empty())
      return true;
   return mColours.empty() != inWantColour;
}



// --- HardwareData ---------------------------------------------------------------------


HardwareData::~HardwareData()
{
   mCalls.DeleteAll();
}

HardwareArrays &HardwareData::GetArrays(Surface *inSurface,bool inWithColour,unsigned int inFlags)
{
   if (mCalls.empty() || mCalls.last()->mSurface != inSurface ||
           !mCalls.last()->ColourMatch(inWithColour) ||
           mCalls.last()->mFlags != inFlags )
   {
       HardwareArrays *arrays = new HardwareArrays(inSurface,inFlags);
       mCalls.push_back(arrays);
   }

   return *mCalls.last();
}



// --- Texture -----------------------------


void Texture::Dirty(const Rect &inRect)
{
   if (!mDirtyRect.HasPixels())
      mDirtyRect = inRect;
   else
      mDirtyRect = mDirtyRect.Union(inRect);
}



// --- HardwareContext -----------------------------


// Cache line thickness transforms...
static Matrix sLastMatrix;
double sLineScaleV = -1;
double sLineScaleH = -1;
double sLineScaleNormal = -1;


bool HardwareContext::Hits(const RenderState &inState, const HardwareCalls &inCalls )
{
   if (inState.mClipRect.w!=1 || inState.mClipRect.h!=1)
      return false;

   UserPoint screen(inState.mClipRect.x, inState.mClipRect.y);
   UserPoint pos = inState.mTransform.mMatrix->ApplyInverse(screen);

   if (sLastMatrix!=*inState.mTransform.mMatrix)
   {
      sLastMatrix=*inState.mTransform.mMatrix;
      sLineScaleV = -1;
      sLineScaleH = -1;
      sLineScaleNormal = -1;
   }


    for(int c=0;c<inCalls.size();c++)
   {
      HardwareArrays &arrays = *inCalls[c];
      Vertices &vert = arrays.mVertices;

      // TODO: include extent in HardwareArrays

      DrawElements &elements = arrays.mElements;
      for(int e=0;e<elements.size();e++)
      {
         DrawElement draw = elements[e];

         if (draw.mPrimType == ptLineStrip)
         {
            if ( draw.mCount < 2 || draw.mWidth==0)
               continue;

            double width = 1;
            Matrix &m = sLastMatrix;
            switch(draw.mScaleMode)
            {
               case ssmNone: width = draw.mWidth; break;
               case ssmNormal:
               case ssmOpenGL:
                  if (sLineScaleNormal<0)
                     sLineScaleNormal =
                        sqrt( 0.5*( m.m00*m.m00 + m.m01*m.m01 +
                                    m.m10*m.m10 + m.m11*m.m11 ) );
                  width = draw.mWidth*sLineScaleNormal;
                  break;
               case ssmVertical:
                  if (sLineScaleV<0)
                     sLineScaleV =
                        sqrt( m.m00*m.m00 + m.m01*m.m01 );
                  width = draw.mWidth*sLineScaleV;
                  break;

               case ssmHorizontal:
                  if (sLineScaleH<0)
                     sLineScaleH =
                        sqrt( m.m10*m.m10 + m.m11*m.m11 );
                  width = draw.mWidth*sLineScaleH;
                  break;
            }

            double x0 = pos.x - width;
            double x1 = pos.x + width;
            double y0 = pos.y - width;
            double y1 = pos.y + width;
            double w2 = width*width;

            UserPoint *v = &vert[ draw.mFirst ];
            UserPoint p0 = *v;

            int prev = 0;
            if (p0.x<x0) prev |= 0x01;
            if (p0.x>x1) prev |= 0x02;
            if (p0.y<y0) prev |= 0x04;
            if (p0.y>y1) prev |= 0x08;
            if (prev==0 && pos.Dist2(p0)<=w2)
               return true;
            for(int i=1;i<draw.mCount;i++)
            {
               UserPoint p = v[i];
               int flags = 0;
               if (p.x<x0) flags |= 0x01;
               if (p.x>x1) flags |= 0x02;
               if (p.y<y0) flags |= 0x04;
               if (p.y>y1) flags |= 0x08;
               if (flags==0 && pos.Dist2(p)<=w2)
                  return true;
               if ( !(flags & prev) )
               {
                  // Line *may* pass though the point...
                  UserPoint vec = p-p0;
                  double len = sqrt(vec.x*vec.x + vec.y*vec.y);
                  if (len>0)
                  {
                     double a = vec.Dot(pos-p0)/len;
                     if (a>0 && a<1)
                     {
                        if ( (p0 + vec*a).Dist2(pos) < w2 )
                           return true;
                     }
                  }
               }
               prev = flags;
               p0 = p;
            }
         }
         else if (draw.mPrimType == ptTriangleFan)
         {
            if (draw.mCount<3)
               continue;
            UserPoint *v = &vert[ draw.mFirst ];
            UserPoint p0 = *v;
            int count_left = 0;
            for(int i=1;i<=draw.mCount;i++)
            {
               UserPoint p = v[i%draw.mCount];
               if ( (p.y<pos.y) != (p0.y<pos.y) )
               {
                  // Crosses, but to the left?
                  double ratio = (pos.y-p0.y)/(p.y-p0.y);
                  double x = p0.x + (p.x-p0.x) * ratio;
                  if (x<pos.x)
                     count_left++;
               }
               p0 = p;
            }
            if (count_left & 1)
               return true;
         }
         else if (draw.mPrimType == ptTriangles)
         {
            if (draw.mCount<3)
               continue;
            UserPoint *v = &vert[ draw.mFirst ];
			
			   int numTriangles = draw.mCount / 3;
			
            for(int i=0;i<numTriangles;i++)
            {
               UserPoint base = *v++;
               bool bgx = pos.x>base.x;
               if ( bgx!=(pos.x>v[0].x) || bgx!=(pos.x>v[1].x) )
               {
                  bool bgy = pos.y>base.y;
                  if ( bgy!=(pos.y>v[0].y) || bgy!=(pos.y>v[1].y) )
                  {
                     UserPoint v0 = v[0] - base;
                     UserPoint v1 = v[1] - base;
                     UserPoint v2 = pos - base;
                     double dot00 = v0.Dot(v0);
                     double dot01 = v0.Dot(v1);
                     double dot02 = v0.Dot(v2);
                     double dot11 = v1.Dot(v1);
                     double dot12 = v1.Dot(v2);

                     // Compute barycentric coordinates
                     double denom = (dot00 * dot11 - dot01 * dot01);
                     if (denom!=0)
                     {
                        denom = 1 / denom;
                        double u = (dot11 * dot02 - dot01 * dot12) * denom;
                        if (u>=0)
                        {
                           double v = (dot00 * dot12 - dot01 * dot02) * denom;

                           // Check if point is in triangle
                           if ( (v >= 0) && (u + v < 1) )
                              return true;
                        }
                     }
                  }
               }
               v+=2;
            }
         }
      }
   }

   return false;
}



} // end namespace lime
