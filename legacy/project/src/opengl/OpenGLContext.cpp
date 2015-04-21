#include "./OGL.h"
#include <NMEThread.h>

#if HX_LINUX
#include <dlfcn.h>
#endif


#ifdef NEED_EXTENSIONS
#define DEFINE_EXTENSION
#include "OGLExtensions.h"
#undef DEFINE_EXTENSION
#endif

#ifdef NME_S3D
#include "OpenGLS3D.h"
#endif



int sgDrawCount = 0;
int sgDrawBitmap = 0;


namespace nme
{

const double one_on_255 = 1.0/255.0;
const double one_on_256 = 1.0/256.0;

static GLuint sgOpenglType[] =
  { GL_TRIANGLE_FAN, GL_TRIANGLE_STRIP, GL_TRIANGLES, GL_LINE_STRIP, GL_POINTS, GL_LINES };


void ReloadExtentions();


// --- HardwareRenderer Interface ---------------------------------------------------------


HardwareRenderer* nme::HardwareRenderer::current = NULL;


void ResetHardwareContext()
{
   //__android_log_print(ANDROID_LOG_ERROR, "NME", "ResetHardwareContext");
   gTextureContextVersion++;
   if (HardwareRenderer::current)
      HardwareRenderer::current->OnContextLost();
}



class OGLContext : public HardwareRenderer
{
public:

   OGLContext(WinDC inDC, GLCtx inOGLCtx)
   {
      HardwareRenderer::current = this;
      mDC = inDC;
      mOGLCtx = inOGLCtx;
      mWidth = 0;
      mHeight = 0;
      mLineWidth = -1;
      mBitmapTexture = 0;
      mLineScaleNormal = -1;
      mLineScaleV = -1;
      mLineScaleH = -1;
      mThreadId = GetThreadId();
      mHasZombie = false;
      mContextId = gTextureContextVersion;
      #if defined(NME_GLES)
      mQuality = sqLow;
      #else
      mQuality = sqBest;
      #endif

      for(int i=0;i<PROG_COUNT;i++)
         mProg[i] = 0;
      for(int i=0;i<4;i++)
         for(int j=0;j<4;j++)
            mBitmapTrans[i][j] = mTrans[i][j] = i==j;

      mBitmapBuffer.mElements.resize(1);
      DrawElement &e = mBitmapBuffer.mElements[0];
      memset(&e,0,sizeof(DrawElement));
      e.mCount = 0;
      e.mFlags = DRAW_HAS_TEX;
      e.mPrimType = ptTriangles;
      e.mVertexOffset = 0;
      e.mColour = 0xff000000;
      e.mTexOffset = sizeof(float)*2;
      e.mStride = sizeof(float)*4;
      
      #if defined(NME_S3D) && defined(ANDROID)
      mS3D.Init ();
      #endif
   }
   ~OGLContext()
   {
      for(int i=0;i<PROG_COUNT;i++)
         delete mProg[i];
   }
   bool IsOpenGL() const { return true; }



   void DestroyNativeTexture(void *inNativeTexture)
   {
      GLuint tid = (GLuint)(size_t)inNativeTexture;
      DestroyTexture(tid);
   }

   void DestroyTexture(unsigned int inTex)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieTextures.push_back(inTex);
      }
      else
      {
         glDeleteTextures(1,&inTex);
      }
   }

   void DestroyVbo(unsigned int inVbo)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieVbos.push_back(inVbo);
      }
      else
         glDeleteBuffers(1,&inVbo);
   }

   void DestroyProgram(unsigned int inProg)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombiePrograms.push_back(inProg);
      }
      else
         glDeleteProgram(inProg);
   }
   void DestroyShader(unsigned int inShader)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieShaders.push_back(inShader);
      }
      else
         glDeleteShader(inShader);
   }
   void DestroyFramebuffer(unsigned int inBuffer)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieFramebuffers.push_back(inBuffer);
      }
      else
         glDeleteFramebuffers(1,&inBuffer);
   }

   void DestroyRenderbuffer(unsigned int inBuffer)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieRenderbuffers.push_back(inBuffer);
      }
      else
         glDeleteRenderbuffers(1,&inBuffer);
   }


   void OnContextLost()
   {
      mZombieTextures.resize(0);
      mZombieVbos.resize(0);
      mZombiePrograms.resize(0);
      mZombieShaders.resize(0);
      mZombieFramebuffers.resize(0);
      mZombieRenderbuffers.resize(0);
      mHasZombie = false;
   }

   void SetWindowSize(int inWidth,int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
      #ifdef ANDROID
      //__android_log_print(ANDROID_LOG_ERROR, "NME", "SetWindowSize %d %d", inWidth, inHeight);
      #endif
      
      #if defined(NME_S3D) && defined(ANDROID)
      mS3D.Resize (inWidth, inHeight);
      #endif
   }

   int Width() const { return mWidth; }
   int Height() const { return mHeight; }

   void Clear(uint32 inColour, const Rect *inRect)
   {
      Rect r = inRect ? *inRect : Rect(mWidth,mHeight);
     
      glViewport(r.x,mHeight-r.y1(),r.w,r.h);


      float alpha = ((inColour >>24) & 0xff) /255.0;
      float red =   ((inColour >>16) & 0xff) /255.0;
      float green = ((inColour >>8 ) & 0xff) /255.0;
      float blue  = ((inColour     ) & 0xff) /255.0;
      red *= alpha;
      green *= alpha;
      blue *= alpha;

      if (r==Rect(mWidth,mHeight))
      {
         glClearColor(red, green, blue, alpha );
         glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
      }
      else
      {
         //printf(" - partial clear\n");
      }


      if (r!=mViewport)
         glViewport(mViewport.x, mHeight-mViewport.y1(), mViewport.w, mViewport.h);
   }

   void SetViewport(const Rect &inRect)
   {
      if (inRect!=mViewport)
      {
         setOrtho(inRect.x,inRect.x1(), inRect.y1(),inRect.y);
         mViewport = inRect;
         glViewport(inRect.x, mHeight-inRect.y1(), inRect.w, inRect.h);
      }
   }


   void BeginRender(const Rect &inRect,bool inForHitTest)
   {
      if (!inForHitTest)
      {
         if (mContextId!=gTextureContextVersion)
         {
            updateContext();
         }

         #ifndef NME_GLES
         #ifndef SDL_OGL
         #ifndef GLFW_OGL
         wglMakeCurrent(mDC,mOGLCtx);
         #endif
         #endif
         #endif

         if (mHasZombie)
         {
            mHasZombie = false;
            if (mZombieTextures.size())
            {
               glDeleteTextures(mZombieTextures.size(),&mZombieTextures[0]);
               mZombieTextures.resize(0);
            }

            if (mZombieVbos.size())
            {
               glDeleteBuffers(mZombieVbos.size(),&mZombieVbos[0]);
               mZombieVbos.resize(0);
            }

            if (mZombiePrograms.size())
            {
               for(int i=0;i<mZombiePrograms.size();i++)
                  glDeleteProgram(mZombiePrograms[i]);
               mZombiePrograms.resize(0);
            }

            if (mZombieShaders.size())
            {
               for(int i=0;i<mZombieShaders.size();i++)
                  glDeleteShader(mZombieShaders[i]);
               mZombieShaders.resize(0);
            }

            if (mZombieFramebuffers.size())
            {
               glDeleteFramebuffers(mZombieFramebuffers.size(),&mZombieFramebuffers[0]);
               mZombieFramebuffers.resize(0);
            }

            if (mZombieRenderbuffers.size())
            {
               glDeleteRenderbuffers(mZombieRenderbuffers.size(),&mZombieRenderbuffers[0]);
               mZombieRenderbuffers.resize(0);
            }
         }


         // Force dirty
         mViewport.w = -1;
         SetViewport(inRect);


         glEnable(GL_BLEND);

        #ifdef WEBOS
         glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_FALSE);
         #endif

         mLineWidth = 99999;

         // printf("DrawArrays: %d, DrawBitmaps:%d  Buffers:%d\n", sgDrawCount, sgDrawBitmap, sgBufferCount );
         sgDrawCount = 0;
         sgDrawBitmap = 0;
      }
   }
   void EndRender()
   {

   }

   void updateContext()
   {
      mContextId = gTextureContextVersion;
      mThreadId = GetThreadId();
      mHasZombie = false;
      mZombieTextures.resize(0);
      mZombieVbos.resize(0);
      mZombiePrograms.resize(0);
      mZombieShaders.resize(0);
      mZombieFramebuffers.resize(0);
      mZombieRenderbuffers.resize(0);

      ReloadExtentions();
   }


   void Flip()
   {
      #ifndef NME_GLES
      #ifndef SDL_OGL
      #ifndef GLFW_OGL
      SwapBuffers(mDC);
      #endif
      #endif
      #endif
   }

   void BeginDirectRender()
   {
      gDirectMaxAttribArray = 0;
   }

   void EndDirectRender()
   {
      for(int i=0;i<gDirectMaxAttribArray;i++)
         glDisableVertexAttribArray(i);
   }


   void Render(const RenderState &inState, const HardwareData &inData )
   {
      if (!inData.mArray.size())
         return;

      SetViewport(inState.mClipRect);

      if (mModelView!=*inState.mTransform.mMatrix)
      {
         mModelView=*inState.mTransform.mMatrix;
         CombineModelView(mModelView);
         mLineScaleV = -1;
         mLineScaleH = -1;
         mLineScaleNormal = -1;
      }
      const ColorTransform *ctrans = inState.mColourTransform;
      if (ctrans && ctrans->IsIdentity())
         ctrans = 0;

      RenderData(inData,ctrans,mTrans);
   }

   void RenderData(const HardwareData &inData, const ColorTransform *ctrans,const Trans4x4 &inTrans)
   {
      const uint8 *data = 0;
      if (inData.mVertexBo)
      {
         if (inData.mContextId!=gTextureContextVersion)
         {
            if (inData.mVboOwner)
               inData.mVboOwner->DecRef();
            inData.mVboOwner = 0;
            // Create one right away...
            inData.mRendersWithoutVbo = 5;
            inData.mVertexBo = 0;
            inData.mContextId = 0;
         }
         else
            glBindBuffer(GL_ARRAY_BUFFER, inData.mVertexBo);
      }

      if (!inData.mVertexBo)
      {
         data = &inData.mArray[0];
         inData.mRendersWithoutVbo++;
         if ( inData.mRendersWithoutVbo>4)
         {
            glGenBuffers(1,&inData.mVertexBo);
            inData.mVboOwner = this;
            IncRef();
            inData.mContextId = gTextureContextVersion;
            glBindBuffer(GL_ARRAY_BUFFER, inData.mVertexBo);
            // printf("VBO DATA %d\n", inData.mArray.size());
            glBufferData(GL_ARRAY_BUFFER, inData.mArray.size(), data, GL_STATIC_DRAW);
            data = 0;
         }
      }

      GPUProg *lastProg = 0;
 
      for(int e=0;e<inData.mElements.size();e++)
      {
         const DrawElement &element = inData.mElements[e];
         int n = element.mCount;
         if (!n)
            continue;

 

         int progId = 0;
         bool premAlpha = false;
         if ((element.mFlags & DRAW_HAS_TEX) && element.mSurface)
         {
            if (element.mSurface->GetFlags() & surfUsePremultipliedAlpha)
               premAlpha = true;
            progId |= PROG_TEXTURE;
            if (element.mSurface->BytesPP()==1)
               progId |= PROG_ALPHA_TEXTURE;
         }

         if (element.mFlags & DRAW_HAS_COLOUR)
            progId |= PROG_COLOUR_PER_VERTEX;

         if (element.mFlags & DRAW_HAS_NORMAL)
            progId |= PROG_NORMAL_DATA;

         if (element.mFlags & DRAW_RADIAL)
         {
            progId |= PROG_RADIAL;
            if (element.mRadialPos!=0)
               progId |= PROG_RADIAL_FOCUS;
         }

         if (ctrans || element.mColour != 0xffffffff)
         {
            progId |= PROG_TINT;
            if (ctrans && ctrans->HasOffset())
               progId |= PROG_COLOUR_OFFSET;
         }

         bool persp = element.mFlags & DRAW_HAS_PERSPECTIVE;

         GPUProg *prog = mProg[progId];
         if (!prog)
             mProg[progId] = prog = GPUProg::create(progId);
         if (!prog)
            continue;

         switch(element.mBlendMode)
         {
            case bmAdd:
               glBlendFunc( GL_SRC_ALPHA, GL_ONE );
               glBlendEquation( GL_FUNC_ADD);
               break;
            case bmMultiply:
               glBlendFunc( GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
               glBlendEquation( GL_FUNC_ADD);
               break;
            case bmScreen:
               glBlendFunc( GL_ONE, GL_ONE_MINUS_SRC_COLOR);
               glBlendEquation( GL_FUNC_ADD);
               break;
            case bmSubtract:
               glBlendFunc( GL_SRC_ALPHA, GL_ONE);
               glBlendEquation( GL_FUNC_REVERSE_SUBTRACT);
               break;
            default:
               if (premAlpha){
                  glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
               }
               else {
                  glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
               }
               glBlendEquation( GL_FUNC_ADD);
         }


         if (prog!=lastProg)
         {
            if (lastProg)
               lastProg->disableSlots();

            prog->bind();
            prog->setTransform(inTrans);
            lastProg = prog;
         }

         int stride = element.mStride;
         if (prog->vertexSlot >= 0)
         {
            glVertexAttribPointer(prog->vertexSlot, persp ? 4 : 2 , GL_FLOAT, GL_FALSE, stride,
                data + element.mVertexOffset);
            glEnableVertexAttribArray(prog->vertexSlot);
         }

         if (prog->textureSlot >= 0)
         {
            glVertexAttribPointer(prog->textureSlot,  2 , GL_FLOAT, GL_FALSE, stride,
                data + element.mTexOffset);
            glEnableVertexAttribArray(prog->textureSlot);

            if (element.mSurface)
            {
               Texture *boundTexture = element.mSurface->GetTexture(this);
               element.mSurface->Bind(*this,0);
               boundTexture->BindFlags(element.mFlags & DRAW_BMP_REPEAT,element.mFlags & DRAW_BMP_SMOOTH);
            }
         }

         if (prog->colourSlot >= 0)
         {
            glVertexAttribPointer(prog->colourSlot, 4, GL_UNSIGNED_BYTE, GL_TRUE, stride,
                data + element.mColourOffset);
            glEnableVertexAttribArray(prog->colourSlot);
         }

         if (prog->normalSlot >= 0)
         {
            glVertexAttribPointer(prog->normalSlot, 2, GL_FLOAT, GL_FALSE, stride,
                data + element.mNormalOffset);
            glEnableVertexAttribArray(prog->normalSlot);
         }

         if (element.mFlags & DRAW_RADIAL)
         {
            prog->setGradientFocus(element.mRadialPos * one_on_256);
         }

         if (progId & (PROG_TINT | PROG_COLOUR_OFFSET) )
         {
            prog->setColourTransform(ctrans, element.mColour );
         }

         if ( (element.mPrimType == ptLineStrip || element.mPrimType==ptPoints || element.mPrimType==ptLines)
                 && element.mCount>1)
         {
            if (element.mWidth<0)
               SetLineWidth(1.0);
            else if (element.mWidth==0)
               SetLineWidth(0.0);
            else
               switch(element.mScaleMode)
               {
                  case ssmNone: SetLineWidth(element.mWidth); break;
                  case ssmNormal:
                  case ssmOpenGL:
                     if (mLineScaleNormal<0)
                        mLineScaleNormal =
                           sqrt( 0.5*( mModelView.m00*mModelView.m00 + mModelView.m01*mModelView.m01 +
                                          mModelView.m10*mModelView.m10 + mModelView.m11*mModelView.m11 ) );
                     SetLineWidth(element.mWidth*mLineScaleNormal);
                     break;
                  case ssmVertical:
                     if (mLineScaleV<0)
                        mLineScaleV =
                           sqrt( mModelView.m00*mModelView.m00 + mModelView.m01*mModelView.m01 );
                     SetLineWidth(element.mWidth*mLineScaleV);
                     break;

                  case ssmHorizontal:
                     if (mLineScaleH<0)
                        mLineScaleH =
                           sqrt( mModelView.m10*mModelView.m10 + mModelView.m11*mModelView.m11 );
                     SetLineWidth(element.mWidth*mLineScaleH);
                     break;
               }
         }
   
            //printf("glDrawArrays %d : %d x %d\n", element.mPrimType, element.mFirst, element.mCount );

         sgDrawCount++;
         glDrawArrays(sgOpenglType[element.mPrimType], 0, element.mCount );
      }

      if (lastProg)
        lastProg->disableSlots();

      if (inData.mVertexBo)
         glBindBuffer(GL_ARRAY_BUFFER,0);
   }




   void BeginBitmapRender(Surface *inSurface,uint32 inTint,bool inRepeat,bool inSmooth)
   {
      mBitmapBuffer.mArray.resize(0);
      mBitmapBuffer.mRendersWithoutVbo = -999;
      DrawElement &e = mBitmapBuffer.mElements[0];
      e.mCount = 0;

      e.mColour = inTint;
      if (e.mSurface)
         e.mSurface->DecRef();

      e.mSurface = inSurface;

      e.mSurface->IncRef();
      e.mFlags = (e.mFlags & ~(DRAW_BMP_REPEAT|DRAW_BMP_SMOOTH) );
      if (inRepeat)
         e.mFlags |= DRAW_BMP_REPEAT;
      if (inSmooth)
         e.mFlags |= DRAW_BMP_SMOOTH;

      mBitmapTexture = inSurface->GetTexture(this);
   }

   void RenderBitmap(const Rect &inSrc, int inX, int inY)
   {
      DrawElement &e = mBitmapBuffer.mElements[0];
      mBitmapBuffer.mArray.resize( (e.mCount+6) * e.mStride );
      UserPoint *p = (UserPoint *)&mBitmapBuffer.mArray[e.mCount*e.mStride];
      e.mCount+=6;
      
      UserPoint corners[4];
      UserPoint tex[4];
      for(int i=0;i<4;i++)
      {
         corners[i] =  UserPoint(inX + ((i&1)?inSrc.w:0), inY + ((i>1)?inSrc.h:0) ); 
         tex[i] = mBitmapTexture->PixelToTex(UserPoint(inSrc.x + ((i&1)?inSrc.w:0), inSrc.y + ((i>1)?inSrc.h:0) )); 
      }
      *p++ = corners[0];
      *p++ = tex[0];
      *p++ = corners[1];
      *p++ = tex[1];
      *p++ = corners[2];
      *p++ = tex[2];

      *p++ = corners[1];
      *p++ = tex[1];
      *p++ = corners[2];
      *p++ = tex[2];
      *p++ = corners[3];
      *p++ = tex[3];
   }
   

   void EndBitmapRender()
   {
      DrawElement &e = mBitmapBuffer.mElements[0];

      if (e.mCount)
      {
         RenderData(mBitmapBuffer,0,mBitmapTrans);
         e.mCount = 0;
      }

      if (e.mSurface)
      {
         e.mSurface->DecRef();
         e.mSurface = 0;
      }
      mBitmapBuffer.mArray.resize(0);
      mBitmapTexture = 0;
   }

   inline void SetLineWidth(double inWidth)
   {
      if (inWidth!=mLineWidth)
      {
         // TODO mQuality -> tessellate_lines/tessellate_lines_aa
         mLineWidth = inWidth;
         glLineWidth(inWidth<=0.25 ? 0.25 : inWidth);
      }
   }



   Texture *CreateTexture(Surface *inSurface,unsigned int inFlags)
   {
      return OGLCreateTexture(inSurface,inFlags);
   }

   void SetQuality(StageQuality inQ)
   {
      if (inQ!=mQuality)
      {
         mQuality = inQ;
         mLineWidth = 99999;
      }
   }



   void setOrtho(float x0,float x1, float y0, float y1)
   {
      mScaleX = 2.0/(x1-x0);
      mScaleY = 2.0/(y1-y0);
      mOffsetX = (x0+x1)/(x0-x1);
      mOffsetY = (y0+y1)/(y0-y1);
      mModelView = Matrix();

      mBitmapTrans[0][0] = mScaleX;
      mBitmapTrans[0][3] = mOffsetX;
      mBitmapTrans[1][1] = mScaleY;
      mBitmapTrans[1][3] = mOffsetY;

      CombineModelView(mModelView);
   } 

   void CombineModelView(const Matrix &inModelView)
   {
      #ifdef NME_S3D
      
      #ifdef ANDROID
      float eyeOffset = mS3D.GetEyeOffset ();
      #else
      float eyeOffset = 0;
      #endif

      mTrans[0][0] = inModelView.m00 * mScaleX;
      mTrans[0][1] = inModelView.m01 * mScaleX;
      mTrans[0][2] = 0;
      mTrans[0][3] = (inModelView.mtx + eyeOffset) * mScaleX + mOffsetX;

      mTrans[1][0] = inModelView.m10 * mScaleY;
      mTrans[1][1] = inModelView.m11 * mScaleY;
      mTrans[1][2] = 0;
      mTrans[1][3] = inModelView.mty * mScaleY + mOffsetY;

      mTrans[2][0] = 0;
      mTrans[2][1] = 0;
      mTrans[2][2] = -1;
      mTrans[2][3] = inModelView.mtz;
      
      #ifdef ANDROID
      mS3D.FocusEye (mTrans);
      #endif
      
      #else
      
      mTrans[0][0] = inModelView.m00 * mScaleX;
      mTrans[0][1] = inModelView.m01 * mScaleX;
      mTrans[0][2] = 0;
      mTrans[0][3] = inModelView.mtx * mScaleX + mOffsetX;

      mTrans[1][0] = inModelView.m10 * mScaleY;
      mTrans[1][1] = inModelView.m11 * mScaleY;
      mTrans[1][2] = 0;
      mTrans[1][3] = inModelView.mty * mScaleY + mOffsetY;
      
      #endif
   }
   
   #ifdef NME_S3D
   void EndS3DRender()
   {
      setOrtho(0, mWidth, 0, mHeight);
      #ifdef ANDROID
      mS3D.EndS3DRender(mWidth, mHeight, mTrans);
      #endif
   }
   
   void SetS3DEye(int eye)
   {
      #ifdef ANDROID
      mS3D.SetS3DEye(eye);
      #endif
   }
   #endif




   int mWidth,mHeight;
   Matrix mModelView;
   ThreadId mThreadId;
   int mContextId;

   double mLineScaleV;
   double mLineScaleH;
   double mLineScaleNormal;
   StageQuality mQuality;


   Rect mViewport;
   WinDC mDC;
   GLCtx mOGLCtx;

   HardwareData mBitmapBuffer;
   Texture *mBitmapTexture;

   double mLineWidth;
   
   // TODO - mutex in case finalizer is run from thread
   bool             mHasZombie;
   QuickVec<GLuint> mZombieTextures;
   QuickVec<GLuint> mZombieVbos;
   QuickVec<GLuint> mZombiePrograms;
   QuickVec<GLuint> mZombieShaders;
   QuickVec<GLuint> mZombieFramebuffers;
   QuickVec<GLuint> mZombieRenderbuffers;

   GPUProg *mProg[PROG_COUNT];

   double mScaleX;
   double mOffsetX;
   double mScaleY;
   double mOffsetY;

   Trans4x4 mTrans;
   Trans4x4 mBitmapTrans;
   
   #if defined(NME_S3D)
   OpenGLS3D mS3D;
   #endif
};


#ifdef NME_S3D

value nme_gl_s3d_set_focal_length (value length)
{

   OGLContext* ctx = dynamic_cast<OGLContext*> (HardwareRenderer::current);
   if (ctx) {

      ctx->mS3D.mFocalLength = val_float (length);

   }
   
   return alloc_null ();
}
DEFINE_PRIM (nme_gl_s3d_set_focal_length,1);

value nme_gl_s3d_get_focal_length ()
{

   OGLContext* ctx = dynamic_cast<OGLContext*> (HardwareRenderer::current);
   if (ctx) {

      return alloc_float (ctx->mS3D.mFocalLength);

   }

   return alloc_null ();

}
DEFINE_PRIM (nme_gl_s3d_get_focal_length,0);

value nme_gl_s3d_set_eye_separation (value separation)
{

   OGLContext* ctx = dynamic_cast<OGLContext*> (HardwareRenderer::current);
   if (ctx) {

      ctx->mS3D.mEyeSeparation = val_float (separation);

   }
   
   return alloc_null ();

}
DEFINE_PRIM (nme_gl_s3d_set_eye_separation,1);

value nme_gl_s3d_get_eye_separation ()
{

   OGLContext* ctx = dynamic_cast<OGLContext*> (HardwareRenderer::current);
   if (ctx) {

      return alloc_float (ctx->mS3D.mEyeSeparation);

   }

   return alloc_null ();

}
DEFINE_PRIM (nme_gl_s3d_get_eye_separation,0);

#endif


// ----------------------------------------------------------------------------


void * gOGLLibraryHandle = 0;

static bool extentions_init = false;

bool InitOGLFunctions()
{
   static bool result = true;
   if (!extentions_init)
   {
      extentions_init = true;

      #ifdef HX_LINUX
      gOGLLibraryHandle = dlopen("libGL.so.1", RTLD_NOW|RTLD_GLOBAL);
      if (!gOGLLibraryHandle)
         gOGLLibraryHandle = dlopen("libGL.so", RTLD_NOW|RTLD_GLOBAL);
      if (!gOGLLibraryHandle)
      {
         //printf("Could not load %s (%s)\n",path, dlerror());
         result = false;
         return result;
      }
      #endif

      #ifdef NEED_EXTENSIONS
         #define GET_EXTENSION
         #include "OGLExtensions.h"
         #undef DEFINE_EXTENSION
      #endif
   }
   return result;
}

void ReloadExtentions()
{
   // Spec says this might be required - but do not think so in practice
   /*
   #ifdef ANDROID
   extentions_init = false;
   InitOGLFunctions();
   #endif
   */
}



HardwareRenderer *HardwareRenderer::CreateOpenGL(void *inWindow, void *inGLCtx, bool shaders)
{
   if (!InitOGLFunctions())
      return 0;

   HardwareRenderer *ctx = new OGLContext( (WinDC)inWindow, (GLCtx)inGLCtx );

   return ctx;
}

} // end namespace nme
