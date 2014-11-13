

#include "OpenGLS3D.h"


namespace nme {


OpenGLS3D::OpenGLS3D()
{
   mFocalLength = 0.5;
   mEyeSeparation = 0.01;

   mCurrentEye = EYE_MIDDLE;
}

OpenGLS3D::~OpenGLS3D()
{
   glDeleteRenderbuffers(1, &mRenderbuffer);
   glDeleteFramebuffers(1, &mFramebuffer);
   glDeleteTextures(1, &mLeftEyeTexture);
   glDeleteTextures(1, &mRightEyeTexture);
   glDeleteTextures(1, &mEyeMaskTexture);
   glDeleteBuffers(1, &mS3DVertexBuffer);
   glDeleteBuffers(1, &mS3DTextureBuffer);
   delete mS3DProgram;
}

void OpenGLS3D::Init()
{
   // TODO: renderbuffer is only needed when using depth buffer
   glGenRenderbuffers(1, &mRenderbuffer);

   glGenFramebuffers(1, &mFramebuffer);
   glGenBuffers(1, &mS3DVertexBuffer);
   glGenBuffers(1, &mS3DTextureBuffer);

   mCurrentEye = EYE_MIDDLE;
   mLeftEyeTexture = mRightEyeTexture = mEyeMaskTexture = 0;

   mS3DProgram = new OGLProg(
      /* vertex */
      "attribute vec3 aVertex;\n"
      "attribute vec2 aTexCoord;\n"
      "varying vec2 vTexCoord;\n"
      "uniform mat4 uTransform;"
      "\n"
      "void main (void) {\n"
      "  vTexCoord = aTexCoord;\n"
      "  gl_Position = vec4 (aVertex, 1.0) * uTransform;\n"
      "}\n"
      ,

      /* fragment */
      #if defined (NME_GLES)
      // TODO: highp precision is required for screens above a certain
      // dimension, however, GLES doesn't guarantee highp support in fragment
      // shaders
      "precision highp float;\n"
      "precision highp sampler2D;\n"
      #endif
      "varying vec2 vTexCoord;\n"
      "uniform sampler2D uLeft;\n"
      "uniform sampler2D uRight;\n"
      "uniform sampler2D uMask;\n"
      "\n"
      "void main (void)\n"
      "{\n"
      "  float parity = mod (gl_FragCoord.x, 2.0);\n"
      "  vec4 left = texture2D (uLeft, vTexCoord).rgba;\n"
      "  vec4 right = texture2D (uRight, vTexCoord).rgba;\n"
      "   float mask = texture2D (uMask, floor (gl_FragCoord.xy) / vec2 (2.0, 1.0)).x;\n"
      "   gl_FragColor = mix (left, right, mask);\n"
      "}\n"
   );

   mLeftImageUniform = glGetUniformLocation(mS3DProgram->mProgramId, "uLeft");
   mRightImageUniform = glGetUniformLocation(mS3DProgram->mProgramId, "uRight");
   mMaskImageUniform = glGetUniformLocation(mS3DProgram->mProgramId, "uMask");
   mPixelSizeUniform = glGetUniformLocation(mS3DProgram->mProgramId, "pixelSize");
}

void OpenGLS3D::EndS3DRender(int inWidth, int inHeight, const Trans4x4 &inTrans)
{
   mCurrentEye = EYE_MIDDLE;

   const GLfloat verts[] = 
   {
      inWidth, inHeight, 0,
      0,       inHeight, 0,
      inWidth,        0, 0,
      0,              0, 0
   };
      
   static const GLfloat textureCoords[] = 
   {
      1, 1,
      0, 1, 
      1, 0, 
      0, 0
   };

   glBindRenderbuffer(GL_RENDERBUFFER, 0);
   glBindFramebuffer(GL_FRAMEBUFFER, 0);

   // use the multiplexing shader
   mS3DProgram->bind();
   
   glClearColor(0, 0, 0, 1.0);
   glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

   glEnableVertexAttribArray(mS3DProgram->vertexSlot);
   glEnableVertexAttribArray(mS3DProgram->textureSlot);
   
   glBindBuffer(GL_ARRAY_BUFFER, mS3DVertexBuffer);
   glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 12, verts, GL_STATIC_DRAW);
   glVertexAttribPointer(mS3DProgram->vertexSlot, 3, GL_FLOAT, false, 0, 0);

   glBindBuffer(GL_ARRAY_BUFFER, mS3DTextureBuffer);
   glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 8, textureCoords, GL_STATIC_DRAW);
   glVertexAttribPointer(mS3DProgram->textureSlot, 2, GL_FLOAT, false, 0, 0);

   // bind left eye texture
   glActiveTexture(GL_TEXTURE0);
   glBindTexture(GL_TEXTURE_2D, mLeftEyeTexture);
   glUniform1i(mLeftImageUniform, 0);

   // bind right eye texture
   glActiveTexture(GL_TEXTURE1);
   glBindTexture(GL_TEXTURE_2D, mRightEyeTexture);
   glUniform1i(mRightImageUniform, 1);
   
   // bind eye mask
   glActiveTexture(GL_TEXTURE2);
   glBindTexture(GL_TEXTURE_2D, mEyeMaskTexture);
   glUniform1i(mMaskImageUniform, 2);

   // supply our matrices and screen info
   glUniformMatrix4fv(mS3DProgram->mTransformSlot, 1, false, (const GLfloat*) inTrans);
   
   // here's where the magic happens
   glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

   // glDisable (GL_TEXTURE_2D);

   // clean up
   glBindBuffer(GL_ARRAY_BUFFER, 0);
   glDisableVertexAttribArray(mS3DProgram->vertexSlot);
   glDisableVertexAttribArray(mS3DProgram->textureSlot);
   glUseProgram(0);

   glBindRenderbuffer(GL_RENDERBUFFER, 0);
   glBindFramebuffer(GL_FRAMEBUFFER, 0);

   glActiveTexture(GL_TEXTURE0);
   glBindTexture(GL_TEXTURE_2D, 0);
   
   glActiveTexture(GL_TEXTURE1);
   glBindTexture(GL_TEXTURE_2D, 0);
   
   glActiveTexture(GL_TEXTURE2);
   glBindTexture(GL_TEXTURE_2D, 0);
}

void OpenGLS3D::SetS3DEye(int eye)
{
   if (eye == EYE_MIDDLE)
   {
      return;
   }

   mCurrentEye = eye;

   GLint texture = mRightEyeTexture;
   if (eye == EYE_LEFT)
   {
      texture = mLeftEyeTexture;
   }

   glActiveTexture(GL_TEXTURE0);

   // TODO: no need to bind 0 texture here, right?
   glBindTexture(GL_TEXTURE_2D, 0);

   glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
   glBindRenderbuffer(GL_RENDERBUFFER, mRenderbuffer);
   glBindTexture(GL_TEXTURE_2D, texture);

   glFramebufferTexture2D(
      GL_FRAMEBUFFER,
      GL_COLOR_ATTACHMENT0,
      GL_TEXTURE_2D, texture, 0);
   
   glClearColor(0, 0, 0, 1.0);
   glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void OpenGLS3D::Resize(int inWidth, int inHeight)
{
   if (mLeftEyeTexture != 0)
   {
      glDeleteTextures(1, &mLeftEyeTexture);
      glDeleteTextures(1, &mRightEyeTexture);
      glDeleteTextures(1, &mEyeMaskTexture);
   }

   int texWidth = inWidth; // UpToPower2 (inWidth);
   int texHeight = inHeight; // UpToPower2 (inHeight);

   glGenTextures(1, &mLeftEyeTexture);
   glBindTexture(GL_TEXTURE_2D, mLeftEyeTexture);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
   glBindTexture(GL_TEXTURE_2D, 0);

   glGenTextures(1, &mRightEyeTexture);
   glBindTexture(GL_TEXTURE_2D, mRightEyeTexture);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
   glBindTexture(GL_TEXTURE_2D, 0);

   GLubyte maskData[] = {
      0, 0xFF,
      0, 0xFF
   };

   glGenTextures(1, &mEyeMaskTexture);
   glBindTexture(GL_TEXTURE_2D, mEyeMaskTexture);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, 2, 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, maskData);
   glBindTexture(GL_TEXTURE_2D, 0);

   // create depth buffer
   glBindRenderbuffer(GL_RENDERBUFFER, mRenderbuffer);
   glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
   glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, inWidth, inHeight);
   glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, mRenderbuffer);

   glBindRenderbuffer(GL_RENDERBUFFER, 0);
   glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void OpenGLS3D::FocusEye(Trans4x4 &outTrans)
{
   if (mCurrentEye != EYE_MIDDLE)
   {
      float offset = GetEyeOffset();
      float theta = asin(offset/mFocalLength);

      float m = sin(theta);
      float n = cos(theta);

      float a = outTrans[0][0];
      float b = outTrans[0][1];
      float c = outTrans[1][0];
      float d = outTrans[1][1];
      float tx = outTrans[0][3];
      float ty = outTrans[1][3];
      float tz = outTrans[2][3];
      
      outTrans[0][0] = (a*n);
      outTrans[0][1] = (b*n);
      outTrans[0][2] = m;
      outTrans[0][3] = (n*tx + m*-tz);
      
      outTrans[1][0] = c;
      outTrans[1][1] = d;
      outTrans[1][2] = 0;
      outTrans[1][3] = ty;

      outTrans[2][0] = -a*m;
      outTrans[2][1] = -b*m;
      outTrans[2][2] = -n;
      outTrans[2][3] = -(n*-tz-m*tx);
   }
}

double OpenGLS3D::GetEyeOffset()
{
   if (mCurrentEye == EYE_MIDDLE)
   {
      return 0;
   }
   else if (mCurrentEye == EYE_LEFT)
   {
      return -1 * mEyeSeparation;
   }
   return mEyeSeparation;
}


}