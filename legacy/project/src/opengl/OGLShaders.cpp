#include "./OGLShaders.h"

#ifdef HX_MAXOS
  #include <OpenGL/glext.h>
#endif


namespace nme
{

const float one_on_255 = 1.0/255.0;

OGLProg::OGLProg(const std::string &inVertProg, const std::string &inFragProg)
{
   mVertProg = inVertProg;
   mFragProg = inFragProg;
   mVertId = 0;
   mFragId = 0;

   mImageSlot = -1;
   mColourTransform = 0;

   vertexSlot = -1;
   textureSlot = -1;
   normalSlot = -1;
   colourSlot = -1;

   //printf("%s", inVertProg.c_str());
   //printf("%s", inFragProg.c_str());

   recreate();
}

OGLProg::~OGLProg() {}


GLuint OGLProg::createShader(GLuint inType, const char *inShader)
{
   const char *source = inShader;
   GLuint shader = glCreateShader(inType);

   glShaderSource(shader,1,&source,0);
   glCompileShader(shader);

   GLint compiled = 0;
   glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
   if (compiled)
      return shader;

   GLint blen = 0;   
   GLsizei slen = 0;

   glGetShaderiv(shader, GL_INFO_LOG_LENGTH , &blen);       
   if (blen > 0)
   {
      char* compiler_log = (char*)malloc(blen);
      glGetShaderInfoLog(shader, blen, &slen, compiler_log);
      ELOG("Error compiling shader : %s\n", compiler_log);
      ELOG("%s\n", source);
      free (compiler_log);
   }
   else
   {
      ELOG("Unknown error compiling shader : \n");
    ELOG("%s\n", source);
   }
   glDeleteShader(shader);
   return 0;
}


void OGLProg::recreate()
{
   mContextVersion = gTextureContextVersion;
   mProgramId = 0;

   mVertId = createShader(GL_VERTEX_SHADER,mVertProg.c_str());
   if (!mVertId)
      return;
   mFragId = createShader(GL_FRAGMENT_SHADER,mFragProg.c_str());
   if (!mFragId)
      return;

   mProgramId = glCreateProgram();

   glAttachShader(mProgramId, mVertId);
   glAttachShader(mProgramId, mFragId);

   glLinkProgram(mProgramId); 


   // Validate program
   glValidateProgram(mProgramId);


   GLint linked;
   glGetProgramiv(mProgramId, GL_LINK_STATUS, &linked);
   if (linked)
   {
      // All good !
      //printf("Linked!\n");
   }
   else
   {
      ELOG("Bad Link.");
    
    // Check the status of the compile/link
   int logLen = 0;
   glGetProgramiv(mProgramId, GL_INFO_LOG_LENGTH, &logLen);
   if(logLen > 0)
   {
       // Show any errors as appropriate
       char *log = new char[logLen];
       glGetProgramInfoLog(mProgramId, logLen, &logLen, log);
       ELOG("----");
       ELOG("VERT: %s", mVertProg.c_str());
       ELOG("FRAG: %s", mFragProg.c_str());
       ELOG("ERROR:\n%s\n", log);
       delete [] log;
   }
  
      glDeleteShader(mVertId);
      glDeleteShader(mFragId);
      glDeleteProgram(mProgramId);
      mVertId = mFragId = mProgramId = 0;
   }


   vertexSlot = glGetAttribLocation(mProgramId, "aVertex");
   textureSlot = glGetAttribLocation(mProgramId, "aTexCoord");
   colourSlot = glGetAttribLocation(mProgramId, "aColourArray");
   normalSlot = glGetAttribLocation(mProgramId, "aNormal");

   mTransformSlot = glGetUniformLocation(mProgramId, "uTransform");
   mImageSlot = glGetUniformLocation(mProgramId, "uImage0");
   mColourOffsetSlot = glGetUniformLocation(mProgramId, "uColourOffset");
   mColourScaleSlot = glGetUniformLocation(mProgramId, "uColourScale");
   mFXSlot = glGetUniformLocation(mProgramId, "mFX");
   mASlot = glGetUniformLocation(mProgramId, "mA");
   mOn2ASlot = glGetUniformLocation(mProgramId, "mOn2A");

   
   glUseProgram(mProgramId);
   if (mImageSlot>=0)
      glUniform1i(mImageSlot,0);
}

bool OGLProg::bind()
{
   if (gTextureContextVersion!=mContextVersion)
      recreate();

   if (mProgramId==0)
      return false;

   glUseProgram(mProgramId);
   return true;
}

void OGLProg::disableSlots()
{
   if (vertexSlot>=0)
      glDisableVertexAttribArray(vertexSlot);

   if (normalSlot>=0)
      glDisableVertexAttribArray(normalSlot);

   if (colourSlot>=0)
      glDisableVertexAttribArray(colourSlot);
   
   if (textureSlot>=0)
      glDisableVertexAttribArray(textureSlot);
}

void OGLProg::setColourTransform(const ColorTransform *inTransform, uint32 inColor)
{
   float rf, gf, bf, af;
   if (inColor==0xffffffff)
   {
      rf = gf = bf = af = 1.0;
   }
   else
   {
      rf = ( (inColor>>16) & 0xff ) * one_on_255;
      gf = ( (inColor>>8 ) & 0xff ) * one_on_255;
      bf = ( (inColor    ) & 0xff ) * one_on_255;
      af = ( (inColor>>24) & 0xff ) * one_on_255;
   }

   if (inTransform && !inTransform->IsIdentity())
   {
       if (mColourOffsetSlot>=0)
          glUniform4f(mColourOffsetSlot,
                   #ifdef NME_PREMULTIPLIED_ALPHA
                   inTransform->redOffset*one_on_255*inTransform->alphaMultiplier,
                   inTransform->greenOffset*one_on_255*inTransform->alphaMultiplier,
                   inTransform->blueOffset*one_on_255*inTransform->alphaMultiplier,
                   #else
                   inTransform->redOffset*one_on_255,
                   inTransform->greenOffset*one_on_255,
                   inTransform->blueOffset*one_on_255,
                   #endif
                   inTransform->alphaOffset*one_on_255);

       if (mColourScaleSlot>=0)
          glUniform4f(mColourScaleSlot,
                   #ifdef NME_PREMULTIPLIED_ALPHA
                   inTransform->redMultiplier * inTransform->alphaMultiplier * rf,
                   inTransform->greenMultiplier * inTransform->alphaMultiplier * gf,
                   inTransform->blueMultiplier * inTransform->alphaMultiplier * bf,
                   #else
                   inTransform->redMultiplier * rf,
                   inTransform->greenMultiplier * gf,
                   inTransform->blueMultiplier * bf,
                   #endif
                   inTransform->alphaMultiplier * af);
   }
   else
   {
      if (mColourOffsetSlot>=0)
         glUniform4f(mColourOffsetSlot,0,0,0,0);

      if (mColourScaleSlot>=0)
      {
         glUniform4f(mColourScaleSlot,rf,gf,bf,af);
      }
   }
}

int OGLProg::getTextureSlot()
{
   return mImageSlot;
}


void OGLProg::setTransform(const Trans4x4 &inTrans)
{
   glUniformMatrix4fv(mTransformSlot, 1, 0, inTrans[0]);
}

void OGLProg::setGradientFocus(float inFocus)
{
   if (mASlot>=0)
   {
      double fx = inFocus;
      if (fx < -0.99) fx = -0.99;
      else if (fx > 0.99) fx = 0.99;
      
      // mFY = 0; mFY can be set to zero, since rotating the matrix
      //  can also compensate for this.
      
      double a = (fx * fx - 1.0);
      double on2a = 1.0 / (2.0 * a);
      a *= 4.0;
      glUniform1f(mASlot,a);
      glUniform1f(mFXSlot,fx);
      glUniform1f(mOn2ASlot,on2a);
   }
}


GPUProg *GPUProg::create(unsigned int inID)
{
   std::string vertexVars =
      "uniform mat4   uTransform;\n"
      "attribute vec4 aVertex;\n";
   std::string vertexProg =
      "   gl_Position = aVertex * uTransform;\n";
   std::string pixelVars = "";
   std::string pixelProlog = "";

   #ifdef NME_GLES
   pixelVars = std::string("precision mediump float;\n");
   #endif



   std::string fragColour = "";
   if (inID & PROG_TINT)
   {
      pixelVars += "uniform vec4 uColourScale;\n";
      fragColour = "uColourScale";
   }

   if (inID & PROG_COLOUR_OFFSET)
   {
       pixelVars += "uniform vec4 uColourOffset;\n";
   }


   if (inID & PROG_COLOUR_PER_VERTEX)
   {
      vertexVars +=
        "attribute vec4 aColourArray;\n"
        "varying vec4 vColourArray;\n";
      vertexProg =
        "   vColourArray = aColourArray;\n" + vertexProg;
      pixelVars +=
        "varying vec4 vColourArray;\n";

      if (fragColour!="")
         fragColour += "*";
      fragColour += "vColourArray";
   }


   if (inID & PROG_TEXTURE)
   {
      vertexVars +=
        "attribute vec2 aTexCoord;\n"
        "varying vec2 vTexCoord;\n";

      vertexProg =
        "   vTexCoord = aTexCoord;\n" + vertexProg;

      pixelVars +=
        "uniform sampler2D uImage0;\n"
        "varying vec2 vTexCoord;\n";

      if (!(inID & PROG_RADIAL))
      {
         if (fragColour!="")
            fragColour += "*";

         if (inID & PROG_ALPHA_TEXTURE)
            fragColour += "vec4(1,1,1,texture2D(uImage0,vTexCoord).a)";
         else
            fragColour += "texture2D(uImage0,vTexCoord)";
      }
   }

   if (inID & PROG_RADIAL)
   {
      if (inID & PROG_RADIAL_FOCUS)
      {
         pixelVars +=
            "uniform float mA;\n"
            "uniform float mFX;\n"
            "uniform float mOn2A;\n";

         pixelProlog = 
            "   float GX = vTexCoord.x - mFX;\n"
            "   float C = GX*GX + vTexCoord.y*vTexCoord.y;\n"
            "   float B = 2.0*GX * mFX;\n"
            "   float det =B*B - mA*C;\n"
            "   float rad;\n"
            "   if (det<0.0)\n"
            "      rad = -B * mOn2A;\n"
            "   else\n"
            "      rad = (-B - sqrt(det)) * mOn2A;\n";
      }
      else
      {
         pixelProlog = 
             "   float rad = sqrt(vTexCoord.x*vTexCoord.x + vTexCoord.y*vTexCoord.y);\n";
      }

      if (fragColour!="")
         fragColour += "*";
      fragColour += "texture2D(uImage0,vec2(rad,0))";
   }


   if (inID & PROG_NORMAL_DATA)
   {
      vertexVars +=
        "attribute vec2 aNormal;\n"
        "varying vec2 vNormal;\n";

      vertexProg =
        "   vNormal = aNormal;\n" + vertexProg;

      pixelVars +=
        "varying vec2 vNormal;\n";
   }

   std::string vertexShader = 
      vertexVars + 
      "void main()\n"
      "{\n" +
         vertexProg +
      "}\n";

   if (fragColour=="")
      fragColour = "vec4(1,1,1,1)";

   if ( inID & PROG_COLOUR_OFFSET )
      fragColour = fragColour + "+ uColourOffset";

   if ( inID & PROG_NORMAL_DATA )
   {
      fragColour = "(" + fragColour + ") * vec4(1,1,1, min(vNormal.x-abs(vNormal.y),1.0) )";
   }
 

   std::string pixelShader =
      pixelVars +
      "void main()\n"
      "{\n" +
         pixelProlog +
         "   gl_FragColor = " + fragColour + ";\n" +
      "}\n";

   return new OGLProg(vertexShader, pixelShader);
}


} // end namespace nme


