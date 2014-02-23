#ifndef LIME_RENDERER_OPENGL_S3D_H
#define LIME_RENDERER_OPENGL_S3D_H

#include "renderer/opengl/OGL.h"
#include "renderer/opengl/OpenGLProgram.h"

namespace lime {

class OpenGLS3D {
public:
   OpenGLS3D ();
   ~OpenGLS3D ();

   void Init ();
   void EndS3DRender (int inWidth, int inHeight, const Trans4x4 &inTrans);
   void SetS3DEye (int eye);
   void Resize (int inWidth, int inHeight);
   void FocusEye (Trans4x4 &outTrans);
   double GetEyeOffset ();

   double mFocalLength;
   double mEyeSeparation;

private:
   int mWidth;
   int mHeight;

   int mCurrentEye;
   OpenGLProgram *mS3DProgram;
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

}; // namespace lime

#endif
