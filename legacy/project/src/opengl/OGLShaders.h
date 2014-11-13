#ifndef OGL_SHADERS_H
#define OGL_SHADERS_H


#include "./OGL.h"


namespace nme
{


class OGLProg : public GPUProg
{
public:
  
   OGLProg(const std::string &inVertProg, const std::string &inFragProg);
   virtual ~OGLProg();

   GLuint createShader(GLuint inType, const char *inShader);
   void recreate();
   virtual bool bind();
   void disableSlots();
   void setColourTransform(const ColorTransform *inTransform, uint32 inColor);
   int  getTextureSlot();
   void setTransform(const Trans4x4 &inTrans);
   virtual void setGradientFocus(float inFocus);

   std::string mVertProg;
   std::string mFragProg;
   GLuint     mProgramId;
   GLuint     mVertId;
   GLuint     mFragId;
   int        mContextVersion;
   const ColorTransform *mColourTransform;


   // int vertexSlot;
   // int textureSlot;
   // int normalSlot;
   // int colourSlot;

   GLint     mImageSlot;
   GLint     mColourArraySlot;
   GLint     mColourScaleSlot;
   GLint     mColourOffsetSlot;
   GLint     mTransformSlot;
   GLint     mASlot;
   GLint     mFXSlot;
   GLint     mOn2ASlot;
};



} // end namespace nme


#endif