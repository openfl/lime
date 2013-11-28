#ifndef INCLUDED_OGL_H
#define INCLUDED_OGL_H

#if defined(BLACKBERRY) || defined(ANDROID) || defined(WEBOS) || defined(GPH) || defined(RASPBERRYPI) || defined(EMSCRIPTEN)

#define LIME_GLES

#ifdef LIME_FORCE_GLES1

#include <GLES/gl.h>
#include <GLES/glext.h>

#else

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#define ALLOW_OGL2
#define LIME_FORCE_GLES2

#endif

#elif defined(TIZEN)

//#include <osp/gl.h>
#include <FGraphicsOpengl.h>
//#include <FGraphicsOpengl2.h>

using namespace Tizen::Graphics::Opengl;

//#include <osp/gl2.h>
//#define ALLOW_OGL2
//#define LIME_FORCE_GLES2
#define LIME_FORCE_GLES1
#define LIME_GLES

#elif defined(IPHONE)

#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#define ALLOW_OGL2

//typedef CAEAGLLayer *WinDC;
//typedef EAGLContext *GLCtx;
#define LIME_GLES

#elif !defined(HX_WINDOWS)

// Mac/Linux....


#ifdef SDL_OGL

#define GL_GLEXT_PROTOTYPES
#include <SDL_opengl.h>
#define FORCE_NON_PO2

#else

#include <GLFW/glfw3.h>

#endif

#ifndef HX_LINUX
#define ALLOW_OGL2
#endif

  #ifdef HX_MACOS
  #define glBindFramebuffer glBindFramebufferEXT
  #define glBindRenderbuffer glBindRenderbufferEXT
  #define glGenFramebuffers glGenFramebuffersEXT
  #define glGenRenderbuffers glGenRenderbuffersEXT
  #define glFramebufferRenderbuffer glFramebufferRenderbufferEXT
  #define glFramebufferTexture2D glFramebufferTexture2DEXT
  #define glRenderbufferStorage glRenderbufferStorageEXT
  #define glCheckFramebufferStatus glCheckFramebufferStatusEXT
  #define glCheckFramebufferStatus glCheckFramebufferStatusEXT
  #define glGenerateMipmap glGenerateMipmapEXT
  #define glGetFramebufferAttachmentParameteriv glGetFramebufferAttachmentParameterivEXT
  #define glGetRenderbufferParameteriv glGetRenderbufferParameterivEXT
  #define glIsFramebuffer glIsFramebufferEXT
  #define glIsRenderbuffer glIsRenderbufferEXT
  #endif

#else

// Windows ....
#include <windows.h>
#include <gl/GL.h>
//#define FORCE_NON_PO2
typedef ptrdiff_t GLsizeiptrARB;
#define NEED_EXTENSIONS


#define ALLOW_OGL2

#ifdef SDL_OGL
#include <SDL_opengl.h>
#endif

#ifdef GLFW_OGL
#include <GL/glext.h>
#include <GLFW/glfw3.h>
#endif

#endif


#ifdef HX_WINDOWS
typedef HDC WinDC;
typedef HGLRC GLCtx;
#else
typedef void *WinDC;
typedef void *GLCtx;
#endif


#ifndef GL_BUFFER_SIZE

#define GL_BUFFER_SIZE                0x8764
#define GL_BUFFER_USAGE               0x8765
#define GL_ARRAY_BUFFER               0x8892
#define GL_ELEMENT_ARRAY_BUFFER       0x8893
#define GL_ARRAY_BUFFER_BINDING       0x8894
#define GL_ELEMENT_ARRAY_BUFFER_BINDING 0x8895
#define GL_VERTEX_ARRAY_BUFFER_BINDING 0x8896
#define GL_NORMAL_ARRAY_BUFFER_BINDING 0x8897
#define GL_COLOR_ARRAY_BUFFER_BINDING 0x8898
#define GL_INDEX_ARRAY_BUFFER_BINDING 0x8899
#define GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING 0x889A
#define GL_EDGE_FLAG_ARRAY_BUFFER_BINDING 0x889B
#define GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING 0x889C
#define GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING 0x889D
#define GL_WEIGHT_ARRAY_BUFFER_BINDING 0x889E
#define GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING 0x889F
#define GL_READ_ONLY                  0x88B8
#define GL_WRITE_ONLY                 0x88B9
#define GL_READ_WRITE                 0x88BA
#define GL_BUFFER_ACCESS              0x88BB
#define GL_BUFFER_MAPPED              0x88BC
#define GL_BUFFER_MAP_POINTER         0x88BD
#define GL_STREAM_DRAW                0x88E0
#define GL_STREAM_READ                0x88E1
#define GL_STREAM_COPY                0x88E2
#define GL_STATIC_DRAW                0x88E4
#define GL_STATIC_READ                0x88E5
#define GL_STATIC_COPY                0x88E6
#define GL_DYNAMIC_DRAW               0x88E8
#define GL_DYNAMIC_READ               0x88E9
#define GL_DYNAMIC_COPY               0x88EA
#define GL_COMPILE_STATUS             0x8B81
#define GL_LINK_STATUS                0x8B82
#define GL_VALIDATE_STATUS            0x8B83
#define GL_INFO_LOG_LENGTH            0x8B84
#define GL_ATTACHED_SHADERS           0x8B85
#define GL_ACTIVE_UNIFORMS            0x8B86
#define GL_ACTIVE_UNIFORM_MAX_LENGTH  0x8B87
#define GL_SHADER_SOURCE_LENGTH       0x8B88
#define GL_VERTEX_SHADER              0x8B31
#define GL_FRAGMENT_SHADER            0x8B30
#define GL_TEXTURE0                   0x84C0
#endif


#ifndef GL_CLAMP_TO_EDGE
#define GL_CLAMP_TO_EDGE 0x812F
#endif

#ifndef GL_POINT_SMOOTH
#define GL_POINT_SMOOTH 0x0B10
#endif

#ifndef GL_LINE_SMOOTH
#define GL_LINE_SMOOTH  0x0B20
#endif



#ifdef GPH
#define LIME_DITHER
#endif

#include <Graphics.h>
#include "renderer/common/Surface.h"

#ifdef HX_MACOS
#define ALLOW_OGL2
#endif


#ifdef NEED_EXTENSIONS
#define DECLARE_EXTENSION
#include "OGLExtensions.h"
#undef DECLARE_EXTENSION
#endif

namespace lime
{

Texture *OGLCreateTexture(Surface *inSurface,unsigned int inFlags);

enum GPUProgID
{
   gpuNone = -1,
   gpuSolid,
   gpuColour,
   gpuColourTransform,
   gpuTexture,
   gpuTextureColourArray,
   gpuTextureTransform,
   gpuBitmap,
   gpuBitmapAlpha,
   gpuRadialGradient,
   gpuRadialFocusGradient,
   gpuSIZE,
};

typedef float Trans4x4[4][4];

class GPUProg
{
public:
   static GPUProg *create(GPUProgID inID, AlphaMode inAlphaMode);

   virtual ~GPUProg() {}

   virtual bool bind() = 0;

   virtual void setPositionData(const float *inData, bool inIsPerspective) = 0;
   virtual void setTexCoordData(const float *inData) = 0;
   virtual void setColourData(const int *inData) = 0;
   virtual void setColourTransform(const ColorTransform *inTransform) = 0;
   virtual int  getTextureSlot() = 0;

   virtual void setTransform(const Trans4x4 &inTrans) = 0;
   virtual void setTint(unsigned int inColour) = 0;
   virtual void setGradientFocus(float inFocus) = 0;
   virtual void finishDrawing() = 0;
};

void InitOGL2Extensions();

} // end namespace lime


#endif // INCLUDED_OGL_H
