#ifndef LIME_GRAPHICS_OPENGL_OPENGL_H
#define LIME_GRAPHICS_OPENGL_OPENGL_H


#if defined (BLACKBERRY) || defined (ANDROID) || defined (WEBOS) || defined (GPH) || defined (EMSCRIPTEN) || defined (RASPBERRYPI)

#define LIME_GLES
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#elif defined (TIZEN)

#define LIME_GLES
#include <gl2.h>
#include <gl2ext.h>

#elif defined (IPHONE) || defined(APPLETV)

#define LIME_GLES
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#elif defined (HX_LINUX)

#define NEED_EXTENSIONS
#define DYNAMIC_OGL
#define GL_GLEXT_PROTOTYPES
#include <SDL_opengl.h>
#include <SDL_opengl_glext.h>
#define FORCE_NON_PO2

#elif defined (HX_MACOS)

#define GL_GLEXT_PROTOTYPES
#include <SDL_opengl.h>
#include <SDL_opengl_glext.h>
#define FORCE_NON_PO2
#define glBindFramebuffer glBindFramebufferEXT
#define glBindRenderbuffer glBindRenderbufferEXT
#define glGenFramebuffers glGenFramebuffersEXT
#define glDeleteFramebuffers glDeleteFramebuffersEXT
#define glGenRenderbuffers glGenRenderbuffersEXT
#define glDeleteRenderbuffers glDeleteRenderbuffersEXT
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

#elif defined (HX_WINDOWS)

#include <windows.h>
#include <gl/GL.h>
typedef ptrdiff_t GLsizeiptrARB;
#define NEED_EXTENSIONS
#define DYNAMIC_OGL
#include <SDL_opengl.h>
#include <SDL_opengl_glext.h>

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

#ifdef NEED_EXTENSIONS

#define DECLARE_EXTENSION
#include "OpenGLExtensions.h"
#undef DECLARE_EXTENSION
#define CHECK_EXT(x) x

#else

#define CHECK_EXT(x) true

#endif


#endif
