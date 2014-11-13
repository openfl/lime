#ifndef OPENGL_S3D_H
#define OPENGL_S3D_H


#include "./OGLShaders.h"
#include "S3D.h"
#include "S3DEye.h"


namespace nme {


class OGLProg;


class OpenGLS3D
{
public:
   
   OpenGLS3D();
   ~OpenGLS3D();

   void Init();
   void EndS3DRender(int inWidth, int inHeight, const Trans4x4 &inTrans);
   void SetS3DEye(int eye);
   void Resize(int inWidth, int inHeight);
   void FocusEye(Trans4x4 &outTrans);
   double GetEyeOffset();

   double mFocalLength;
   double mEyeSeparation;

private:
   int mWidth;
   int mHeight;

   int mCurrentEye;
   OGLProg *mS3DProgram;
   GLuint mFramebuffer;
   GLuint mRenderbuffer;
   GLuint mLeftEyeTexture;
   GLuint mRightEyeTexture;
   GLuint mEyeMaskTexture;
   GLint mLeftImageUniform;
   GLint mRightImageUniform;
   GLint mMaskImageUniform;
   GLint mPixelSizeUniform;
   GLint mScreenUniform;
   GLuint mS3DVertexBuffer;
   GLuint mS3DTextureBuffer;
};


}


#endif