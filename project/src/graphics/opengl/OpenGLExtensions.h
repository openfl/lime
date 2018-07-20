#ifndef GL_UNSIGNED_SHORT_4_4_4_4
#define GL_UNSIGNED_SHORT_4_4_4_4 0x8033
#define GL_UNSIGNED_SHORT_5_6_5 0x8363
#endif


#ifdef HX_WINDOWS
#define CALLING_CONVENTION APIENTRY
#else
#define CALLING_CONVENTION APIENTRY
#endif

#include "OpenGLBindings.h"

#ifdef LIME_SDL
#include <SDL.h>
#ifdef NATIVE_TOOLKIT_SDL_ANGLE
#include <SDL_egl.h>
#endif
#endif


#ifdef DECLARE_EXTENSION

//namespace lime { void *OpenGLBindings::handle = 0; }

#define OGL_EXT(func,ret,args) \
   namespace lime { extern ret (CALLING_CONVENTION *func)args; }

#define EGL_EXT(func,ret,args) \
   namespace lime { extern ret (CALLING_CONVENTION *func)args; }

#elif defined(DEFINE_EXTENSION)

#define OGL_EXT(func,ret,args) \
   namespace lime { ret (CALLING_CONVENTION *func)args=0; }

#define EGL_EXT(func, ret, args) \
   namespace lime { ret (CALLING_CONVENTION *func)args=0; }

#elif defined(GET_EXTENSION)

#if defined (LIME_SDL) && defined (NATIVE_TOOLKIT_SDL_ANGLE)
   #define OGL_EXT(func,ret,args) \
   {\
      *(void **)&lime::func = (void *)SDL_GL_GetProcAddress(#func);\
   }

   #define EGL_EXT(func,ret,args) \
   {\
      *(void **)&lime::func = (void *)GetProcAddress((HMODULE)lime::OpenGLBindings::eglHandle, #func);\
   }
#elif LIME_SDL
   #define OGL_EXT(func,ret,args) \
   {\
      *(void **)&lime::func = (void *)SDL_GL_GetProcAddress(#func);\
      if (!func) \
         *(void **)&lime::func = (void *)SDL_GL_GetProcAddress(#func "ARB");\
   }
#elif HX_WINDOWS
   #define OGL_EXT(func,ret,args) \
   {\
      *(void **)&lime::func = (void *)wglGetProcAddress(#func);\
      if (!func) \
         *(void **)&lime::func = (void *)wglGetProcAddress(#func "ARB");\
   }
#elif defined(HX_LINUX)
   #define OGL_EXT(func,ret,args) \
   {\
      *(void **)&lime::func = (void *)dlsym(lime::OpenGLBindings::handle,#func);\
      if (!func) \
         *(void **)&lime::func = (void *)dlsym(lime::OpenGLBindings::handle,#func "ARB");\
   }
#endif

#endif

OGL_EXT(glBindBuffer,void,(GLenum,GLuint));
OGL_EXT(glDeleteBuffers,void,(GLsizei,const GLuint *));
OGL_EXT(glGenBuffers,void,(GLsizei,GLuint*));
OGL_EXT(glBufferData,void,(GLenum,GLuint,const void *, GLenum));
OGL_EXT(glCreateShader,GLuint,(GLenum));
OGL_EXT(glGetUniformLocation,GLint,(GLuint,const char *));
OGL_EXT(glUniform4f,void,(GLint,float,float,float,float));
OGL_EXT(glUniformMatrix2fv,void,(GLint,GLsizei,GLboolean,const float *));
OGL_EXT(glUniformMatrix3fv,void,(GLint,GLsizei,GLboolean,const float *));
OGL_EXT(glUniformMatrix4fv,void,(GLint,GLsizei,GLboolean,const float *));
OGL_EXT(glDeleteShader,void,(GLint));
OGL_EXT(glDeleteProgram,void,(GLint));
OGL_EXT(glGetAttribLocation,GLint,(GLuint,const char *));
OGL_EXT(glShaderSource,void,(GLuint,GLsizei,const char **, const GLint *));
OGL_EXT(glDisableVertexAttribArray,void,(GLuint));
OGL_EXT(glEnableVertexAttribArray,void,(GLuint));
OGL_EXT(glAttachShader,void,(GLuint,GLuint));
OGL_EXT(glCreateProgram,GLuint,());
OGL_EXT(glCompileShader,void,(GLuint));
OGL_EXT(glLinkProgram,void,(GLuint));
OGL_EXT(glGetShaderiv,void,(GLuint,GLenum,GLint *));
OGL_EXT(glValidateProgram,void,(GLuint));
OGL_EXT(glGetShaderInfoLog,void,(GLuint,GLsizei,GLsizei *,char *));
OGL_EXT(glGetProgramiv,void,(GLuint,GLenum,GLint *));
OGL_EXT(glGetProgramInfoLog,void,(GLuint,GLsizei,GLsizei *,char *));
OGL_EXT(glUseProgram,void,(GLuint));
OGL_EXT(glUniform1i,void,(GLuint,GLint));
OGL_EXT(glVertexAttribPointer,void,(GLuint,GLint,GLenum,GLboolean,GLsizei,const void *));
OGL_EXT(glActiveTexture,void,(GLenum));

OGL_EXT(glIsBuffer,GLboolean,(GLuint));
OGL_EXT(glIsFramebuffer,GLboolean,(GLuint));
OGL_EXT(glIsRenderbuffer,GLboolean,(GLuint));
OGL_EXT(glBlendColor,void,(GLclampf, GLclampf, GLclampf, GLclampf));
OGL_EXT(glBlendEquation,void,(GLenum));
OGL_EXT(glBlendFuncSeparate,void,(GLenum, GLenum, GLenum, GLenum));
OGL_EXT(glBufferSubData,void,(GLenum, GLintptr, GLsizeiptr, const GLvoid *));
OGL_EXT(glGetBufferParameteriv,void,(GLenum, GLenum, GLint *));
OGL_EXT(glBindFramebuffer,void,(GLenum, GLuint));
OGL_EXT(glGenFramebuffers,void,(GLsizei, GLuint *));
OGL_EXT(glDeleteFramebuffers,void,(GLsizei, GLuint *));
OGL_EXT(glBindRenderbuffer,void,(GLenum, GLuint));
OGL_EXT(glFramebufferRenderbuffer,void,(GLenum, GLenum, GLenum, GLuint));
OGL_EXT(glFramebufferTexture2D,void,(GLenum, GLenum, GLenum, GLuint, GLint));
OGL_EXT(glRenderbufferStorage,void,(GLenum, GLenum, GLsizei, GLsizei));
OGL_EXT(glCheckFramebufferStatus,GLenum,(GLenum));
OGL_EXT(glSampleCoverage,void,(GLclampf, GLboolean));
OGL_EXT(glCompressedTexSubImage2D,void,(GLenum, GLint, GLint, GLint, GLsizei, GLsizei, GLenum, GLsizei, const GLvoid *));
OGL_EXT(glCompressedTexImage2D,void,(GLenum, GLint, GLenum, GLsizei, GLsizei, GLint, GLsizei, const GLvoid *));
OGL_EXT(glGenerateMipmap,void,(GLenum));
OGL_EXT(glGenRenderbuffers,void,(GLsizei, GLuint *));
OGL_EXT(glDeleteRenderbuffers,void,(GLsizei, GLuint *));
OGL_EXT(glGetFramebufferAttachmentParameteriv,void,(GLenum, GLenum, GLenum, GLint *));
OGL_EXT(glGetRenderbufferParameteriv,void,(GLenum, GLenum, GLint *));

OGL_EXT(glBlendEquationSeparate,void,(GLenum, GLenum));
OGL_EXT(glDrawBuffers,void,(GLsizei, const GLenum *));
OGL_EXT(glStencilOpSeparate,void,(GLenum, GLenum, GLenum, GLenum));
OGL_EXT(glStencilFuncSeparate,void,(GLenum, GLenum, GLint, GLuint));
OGL_EXT(glStencilMaskSeparate,void,(GLenum, GLuint));
OGL_EXT(glBindAttribLocation,void,(GLuint, GLuint, const GLchar *));
OGL_EXT(glDetachShader,void,(GLuint, GLuint));
OGL_EXT(glGetActiveAttrib,void,(GLuint, GLuint, GLsizei, GLsizei *, GLint *, GLenum *, GLchar *));
OGL_EXT(glGetActiveUniform,void,(GLuint, GLuint, GLsizei, GLsizei *, GLint *, GLenum *, GLchar *));
OGL_EXT(glGetAttachedShaders,void,(GLuint, GLsizei, GLsizei *, GLuint *));
OGL_EXT(glGetShaderSource,void,(GLuint, GLsizei, GLsizei *, GLchar *));
OGL_EXT(glGetUniformfv,void,(GLuint, GLint, GLfloat *));
OGL_EXT(glGetUniformiv,void,(GLuint, GLint, GLint *));
OGL_EXT(glGetVertexAttribfv,void,(GLuint, GLenum, GLfloat *));
OGL_EXT(glGetVertexAttribiv,void,(GLuint, GLenum, GLint *));
OGL_EXT(glGetVertexAttribPointerv,void,(GLuint, GLenum, GLvoid* *));
OGL_EXT(glIsProgram,GLboolean,(GLuint));
OGL_EXT(glIsShader,GLboolean,(GLuint));

OGL_EXT(glUniform1f,void,(GLint, GLfloat));
OGL_EXT(glUniform2f,void,(GLint, GLfloat, GLfloat));
OGL_EXT(glUniform3f,void,(GLint, GLfloat, GLfloat, GLfloat));
OGL_EXT(glUniform2i,void,(GLint, GLint, GLint));
OGL_EXT(glUniform3i,void,(GLint, GLint, GLint, GLint));
OGL_EXT(glUniform4i,void,(GLint, GLint, GLint, GLint, GLint));
OGL_EXT(glUniform1fv,void,(GLint, GLsizei, const GLfloat *));
OGL_EXT(glUniform2fv,void,(GLint, GLsizei, const GLfloat *));
OGL_EXT(glUniform3fv,void,(GLint, GLsizei, const GLfloat *));
OGL_EXT(glUniform4fv,void,(GLint, GLsizei, const GLfloat *));
OGL_EXT(glUniform1iv,void,(GLint, GLsizei, const GLint *));
OGL_EXT(glUniform2iv,void,(GLint, GLsizei, const GLint *));
OGL_EXT(glUniform3iv,void,(GLint, GLsizei, const GLint *));
OGL_EXT(glUniform4iv,void,(GLint, GLsizei, const GLint *));

OGL_EXT(glVertexAttrib1f,void,(GLuint, GLfloat));
OGL_EXT(glVertexAttrib1fv,void,(GLuint, const GLfloat *));
OGL_EXT(glVertexAttrib2f,void,(GLuint, GLfloat, GLfloat));
OGL_EXT(glVertexAttrib2fv,void,(GLuint, const GLfloat *));
OGL_EXT(glVertexAttrib3f,void,(GLuint, GLfloat, GLfloat, GLfloat));
OGL_EXT(glVertexAttrib3fv,void,(GLuint, const GLfloat *));
OGL_EXT(glVertexAttrib4f,void,(GLuint, GLfloat, GLfloat, GLfloat, GLfloat));
OGL_EXT(glVertexAttrib4fv,void,(GLuint, const GLfloat *));

OGL_EXT(glBeginQuery, void, (GLenum target, GLuint id));
OGL_EXT(glBeginTransformFeedback, void, (GLenum primitiveMode));
OGL_EXT(glEndTransformFeedback, void, (void));
OGL_EXT(glBindBufferBase, void, (GLenum target, GLuint index, GLuint buffer));
OGL_EXT(glBindBufferRange, void, (GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size));
OGL_EXT(glBindVertexArray, void, (GLuint array));
OGL_EXT(glBlitFramebuffer, void, (GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter));
OGL_EXT(glClearBufferiv, void, (GLenum buffer, GLint drawbuffer, const GLint * value));
OGL_EXT(glClearBufferuiv, void, (GLenum buffer, GLint drawbuffer, const GLuint * value));
OGL_EXT(glClearBufferfv, void, (GLenum buffer, GLint drawbuffer, const GLfloat * value));
OGL_EXT(glClearBufferfi, void, (GLenum buffer, GLint drawbuffer, GLfloat depth, GLint stencil));
OGL_EXT(glClientWaitSync, GLenum, (GLsync sync, GLbitfield flags, GLuint64 timeout));
OGL_EXT(glCompressedTexImage3D, void, (GLenum target,	GLint level, GLenum internalformat,	GLsizei width, GLsizei height, GLsizei depth, GLint border,	GLsizei imageSize, const GLvoid * data));
OGL_EXT(glCompressedTexSubImage3D, void, (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const GLvoid * data));
OGL_EXT(glCopyTexSubImage3D, void, (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height));
OGL_EXT(glGenQueries, void, (GLsizei n, GLuint * ids));
OGL_EXT(glGenSamplers, void, (GLsizei n, GLuint *samplers));
OGL_EXT(glGenTransformFeedbacks, void, (GLsizei n, GLuint *ids));
OGL_EXT(glGenVertexArrays, void, (GLsizei n, GLuint *arrays));
OGL_EXT(glDeleteTransformFeedbacks, void, (GLsizei n,	const GLuint *ids));
OGL_EXT(glDrawArraysInstanced, void, (GLenum mode, GLint first, GLsizei count, GLsizei primcount));
OGL_EXT(glDrawRangeElements, void, (GLenum mode, GLuint start, GLuint end, GLsizei count,	GLenum type, const GLvoid * indices));
OGL_EXT(glEndQuery, void, (GLenum target));
OGL_EXT(glGetActiveUniformBlockiv, void, (GLuint program, GLuint uniformBlockIndex, GLenum pname, GLint *params));
OGL_EXT(glGetActiveUniformsiv, void, (GLuint program, GLsizei uniformCount, const GLuint *uniformIndices, GLenum pname, GLint *params));
OGL_EXT(glGetBufferPointerv, void, (GLenum target, GLenum pname, GLvoid ** params));
#ifndef LIME_GLES
OGL_EXT(glGetBufferSubData, void, (GLenum target, GLintptr offset, GLsizeiptr size, GLvoid * data));
#endif
OGL_EXT(glGetInteger64v, void, (GLenum pname, GLint64 * params));
OGL_EXT(glGetInteger64i_v, void, (GLenum pname, GLuint index, GLint64 * data));
OGL_EXT(glGetInternalformativ, void, (GLenum target, GLenum internalformat, GLenum pname, GLsizei bufSize, GLint *params));
OGL_EXT(glGetProgramBinary, void, (GLuint program, GLsizei bufsize, GLsizei *length, GLenum *binaryFormat, void *binary));
OGL_EXT(glGetQueryiv, void, (GLenum target, GLenum pname, GLint * params));
OGL_EXT(glGetQueryObjectiv, void, (GLuint id, GLenum pname, GLint * params));
OGL_EXT(glGetQueryObjectuiv, void, (GLuint id, GLenum pname, GLuint * params));
OGL_EXT(glGetSamplerParameterfv, void, (GLuint sampler, GLenum pname, GLfloat * params));
OGL_EXT(glGetSamplerParameteriv, void, (GLuint sampler, GLenum pname, GLint * params));
OGL_EXT(glGetTransformFeedbackVarying, void, (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLsizei *size, GLenum *type, char *name));
OGL_EXT(glGetUniformuiv, void, (GLuint program, GLint location, GLuint *params));
OGL_EXT(glGetUniformBlockIndex, GLuint, (GLuint program, const GLchar *uniformBlockName));
OGL_EXT(glGetVertexAttribIiv, void, (GLuint index, GLenum pname, GLint *params));
OGL_EXT(glGetVertexAttribIuiv, void, (GLuint index, GLenum pname, GLuint *params));
OGL_EXT(glMapBufferRange, void*, (GLenum target, GLintptr offset, GLsizeiptr length, GLbitfield access));
OGL_EXT(glPauseTransformFeedback, void, ());
OGL_EXT(glProgramBinary, void, (GLuint program, GLenum binaryFormat, const void *binary, GLsizei length));
OGL_EXT(glProgramParameteri, void, (GLuint program, GLenum pname, GLint value));
OGL_EXT(glReadBuffer, void, (GLenum mode));
OGL_EXT(glReleaseShaderCompiler, void, (void));
OGL_EXT(glRenderbufferStorageMultisample, void, (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height));
OGL_EXT(glResumeTransformFeedback, void, (void));
OGL_EXT(glSamplerParameterf, void, (GLuint sampler, GLenum pname, GLfloat param));
OGL_EXT(glSamplerParameteri, void, (GLuint sampler, GLenum pname, GLint param));
OGL_EXT(glTexStorage2D, void, (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height));
OGL_EXT(glTexStorage3D, void, (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth));
OGL_EXT(glUniform1ui, void, (GLint location, GLuint v0));
OGL_EXT(glUniform2ui, void, (GLint location, GLuint v0, GLuint v1));
OGL_EXT(glUniform3ui, void, (GLint location, GLuint v0, GLuint v1, GLuint v2));
OGL_EXT(glUniform4ui, void, (GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3));
OGL_EXT(glUniform1uiv, void, (GLint location, GLsizei count, const GLuint *value));
OGL_EXT(glUniform2uiv, void, (GLint location, GLsizei count, const GLuint *value));
OGL_EXT(glUniform3uiv, void, (GLint location, GLsizei count, const GLuint *value));
OGL_EXT(glUniform4uiv, void, (GLint location, GLsizei count, const GLuint *value));
OGL_EXT(glUniformBlockBinding, void, (GLuint program, GLuint uniformBlockIndex, GLuint uniformBlockBinding));
OGL_EXT(glUniformMatrix2x3fv, void, (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value));
OGL_EXT(glUniformMatrix3x2fv, void, (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value));
OGL_EXT(glUniformMatrix2x4fv, void, (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value));
OGL_EXT(glUniformMatrix4x2fv, void, (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value));
OGL_EXT(glUniformMatrix3x4fv, void, (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value));
OGL_EXT(glUniformMatrix4x3fv, void, (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value));
OGL_EXT(glVertexAttribDivisor, void, (GLuint index, GLuint divisor));
OGL_EXT(glVertexAttribIPointer, void, (GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid * pointer));
OGL_EXT(glVertexAttribI4i, void, (GLuint index, GLint v0, GLint v1, GLint v2, GLint v3));
OGL_EXT(glVertexAttribI4iv, void, (GLuint index, const GLint *v));
OGL_EXT(glVertexAttribI4uiv, void, (GLuint index, const GLuint *v));
OGL_EXT(glWaitSync, void, (GLsync sync, GLbitfield flags, GLuint64 timeout));
OGL_EXT(glDeleteSync, void, (GLsync sync));
OGL_EXT(glDeleteQueries, void, (GLsizei n, const GLuint* ids));
OGL_EXT(glDeleteSamplers, void, (GLsizei n, const GLuint* ids));
OGL_EXT(glDeleteVertexArrays, void, (GLsizei n, const GLuint* ids));
OGL_EXT(glIsQuery, GLboolean, (GLuint id));
OGL_EXT(glIsSampler, GLboolean, (GLuint id));
OGL_EXT(glIsVertexArray, GLboolean, (GLuint id));
OGL_EXT(glBindSampler, void, (GLuint unit, GLuint sampler));
OGL_EXT(glBindTransformFeedback, void, (GLenum target, GLuint id));
OGL_EXT(glCopyBufferSubData, void, (GLenum readTarget, GLenum writeTarget, GLintptr readOffset, GLintptr writeOffset, GLsizeiptr size));
OGL_EXT(glDrawElementsInstanced, void, (GLenum mode, GLsizei count, GLenum type, const void * indices, GLsizei primcount));
OGL_EXT(glFramebufferTextureLayer, void, (GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer));
OGL_EXT(glGetActiveUniformBlockName, void, (GLuint program, GLuint uniformBlockIndex, GLsizei bufSize, GLsizei *length, GLchar *uniformBlockName));
OGL_EXT(glGetBufferParameteri64v, void, (GLenum target, GLenum value, GLint64 * data));
OGL_EXT(glGetIntegeri_v, void, (GLenum target, GLuint index, GLint * data));
OGL_EXT(glIsTransformFeedback, GLboolean, (GLuint id));
OGL_EXT(glShaderBinary, void, (GLsizei n, const GLuint *shaders, GLenum binaryformat, const void *binary, GLsizei length));
OGL_EXT(glTexImage3D, void, (GLenum target, GLint level, GLint internalFormat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid * data));
OGL_EXT(glTexSubImage3D, void, (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const GLvoid * pixels));
OGL_EXT(glTransformFeedbackVaryings, void, (GLuint program, GLsizei count, const char **varyings, GLenum bufferMode));
OGL_EXT(glUnmapBuffer, GLboolean, (GLenum target));
OGL_EXT(glVertexAttribI4ui, void, (GLuint index, GLuint v0, GLuint v1, GLuint v2, GLuint v3));
OGL_EXT(glIsSync, GLboolean, (GLsync sync));
OGL_EXT(glGetStringi, const GLubyte *, (GLenum name, GLuint index));
OGL_EXT(glGetFragDataLocation, GLint, ( 	GLuint program, const char * name));
OGL_EXT(glFenceSync, GLsync, (GLenum condition, GLbitfield flags));


#ifdef DYNAMIC_OGL

//OGL_EXT(glActiveTexture,void, (GLenum texture));
OGL_EXT(glAlphaFunc,void, (GLenum func, GLclampf ref));
//OGL_EXT(glAlphaFuncx,void, (GLenum func, GLclampx ref));
OGL_EXT(glBindTexture,void, (GLenum target, GLuint texture));
OGL_EXT(glBlendFunc,void, (GLenum sfactor, GLenum dfactor));
OGL_EXT(glClear,void, (GLbitfield mask));
OGL_EXT(glClearColor,void, (GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha));
//OGL_EXT(glClearColorx,void, (GLclampx red, GLclampx green, GLclampx blue, GLclampx alpha));
#if !defined(LIME_GLES)
OGL_EXT(glClearDepth,void, (GLclampd depth));
#else
OGL_EXT(glClearDepthf,void, (GLclampf depth));
#endif
//OGL_EXT(glClearDepthx,void, (GLclampx depth));
OGL_EXT(glClearStencil,void, (GLint s));
OGL_EXT(glClientActiveTexture,void, (GLenum texture));
OGL_EXT(glColor4f,void, (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha));
//OGL_EXT(glColor4x,void, (GLfixed red, GLfixed green, GLfixed blue, GLfixed alpha));
OGL_EXT(glColorMask,void, (GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha));
OGL_EXT(glColorPointer,void, (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer));
//OGL_EXT(glCompressedTexImage2D,void, (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const GLvoid *data));
//OGL_EXT(glCompressedTexSubImage2D,void, (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const GLvoid *data));
OGL_EXT(glCopyTexImage2D,void, (GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border));
OGL_EXT(glCopyTexSubImage2D,void, (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height));
OGL_EXT(glCullFace,void, (GLenum mode));
OGL_EXT(glDeleteTextures,void, (GLsizei n, const GLuint *textures));
OGL_EXT(glDepthFunc,void, (GLenum func));
OGL_EXT(glDepthMask,void, (GLboolean flag));
#if !defined(LIME_GLES)
OGL_EXT(glDepthRange,void, (GLclampd zNear, GLclampd zFar));
#else
OGL_EXT(glDepthRangef,void, (GLclampf nearVal,GLclampf farVal));
#endif
//OGL_EXT(glDepthRangex,void, (GLclampx zNear, GLclampx zFar));
OGL_EXT(glDisable,void, (GLenum cap));
OGL_EXT(glDisableClientState,void, (GLenum array));
OGL_EXT(glDrawArrays,void, (GLenum mode, GLint first, GLsizei count));
OGL_EXT(glDrawElements,void, (GLenum mode, GLsizei count, GLenum type, const GLvoid *indices));
OGL_EXT(glEnable,void, (GLenum cap));
OGL_EXT(glEnableClientState,void, (GLenum array));
OGL_EXT(glFinish,void, (void));
OGL_EXT(glFlush,void, (void));
OGL_EXT(glFogf,void, (GLenum pname, GLfloat param));
OGL_EXT(glFogfv,void, (GLenum pname, const GLfloat *params));
//OGL_EXT(glFogx,void, (GLenum pname, GLfixed param));
//OGL_EXT(glFogxv,void, (GLenum pname, const GLfixed *params));
OGL_EXT(glFrontFace,void, (GLenum mode));
OGL_EXT(glFrustumf,void, (GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat zNear, GLfloat zFar));
//OGL_EXT(glFrustumx,void, (GLfixed left, GLfixed right, GLfixed bottom, GLfixed top, GLfixed zNear, GLfixed zFar));
OGL_EXT(glGenTextures,void, (GLsizei n, GLuint *textures));
OGL_EXT(glGetError,GLenum, (void));
OGL_EXT(glGetBooleanv,void, (GLenum pname, GLboolean* params));
OGL_EXT(glGetFloatv,void, (GLenum pname, GLfloat* params));
OGL_EXT(glGetIntegerv,void, (GLenum pname, GLint *params));
#ifdef LIME_GLES
OGL_EXT(glGetShaderPrecisionFormat,void, (GLenum shaderType, GLenum precisionType, GLint *range, GLint *precision));
#endif
OGL_EXT(glGetString, const GLubyte *,(GLenum name));
OGL_EXT(glHint,void, (GLenum target, GLenum mode));
OGL_EXT(glInvalidateFramebuffer,void, (GLenum target, GLsizei numAttachments, const GLenum *attachments));
OGL_EXT(glInvalidateSubFramebuffer,void, (GLenum target, GLsizei numAttachments, const GLenum *attachments, int x, int y, GLsizei width, GLsizei height));
OGL_EXT(glLightModelf,void, (GLenum pname, GLfloat param));
OGL_EXT(glLightModelfv,void, (GLenum pname, const GLfloat *params));
//OGL_EXT(glLightModelx,void, (GLenum pname, GLfixed param));
//OGL_EXT(glLightModelxv,void, (GLenum pname, const GLfixed *params));
OGL_EXT(glLightf,void, (GLenum light, GLenum pname, GLfloat param));
OGL_EXT(glLightfv,void, (GLenum light, GLenum pname, const GLfloat *params));
//OGL_EXT(glLightx,void, (GLenum light, GLenum pname, GLfixed param));
//OGL_EXT(glLightxv,void, (GLenum light, GLenum pname, const GLfixed *params));
OGL_EXT(glLineWidth,void, (GLfloat width));
//OGL_EXT(glLineWidthx,void, (GLfixed width));
OGL_EXT(glLoadIdentity,void, (void));
OGL_EXT(glLoadMatrixf,void, (const GLfloat *m));
//OGL_EXT(glLoadMatrixx,void, (const GLfixed *m));
OGL_EXT(glLogicOp,void, (GLenum opcode));
OGL_EXT(glMaterialf,void, (GLenum face, GLenum pname, GLfloat param));
OGL_EXT(glMaterialfv,void, (GLenum face, GLenum pname, const GLfloat *params));
//OGL_EXT(glMaterialx,void, (GLenum face, GLenum pname, GLfixed param));
//OGL_EXT(glMaterialxv,void, (GLenum face, GLenum pname, const GLfixed *params));
OGL_EXT(glMatrixMode,void, (GLenum mode));
OGL_EXT(glMultMatrixf,void, (const GLfloat *m));
//OGL_EXT(glMultMatrixx,void, (const GLfixed *m));
OGL_EXT(glMultiTexCoord4f,void, (GLenum target, GLfloat s, GLfloat t, GLfloat r, GLfloat q));
//OGL_EXT(glMultiTexCoord4x,void, (GLenum target, GLfixed s, GLfixed t, GLfixed r, GLfixed q));
OGL_EXT(glNormal3f,void, (GLfloat nx, GLfloat ny, GLfloat nz));
//OGL_EXT(glNormal3x,void, (GLfixed nx, GLfixed ny, GLfixed nz));
OGL_EXT(glNormalPointer,void, (GLenum type, GLsizei stride, const GLvoid *pointer));
OGL_EXT(glOrthof,void, (GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat zNear, GLfloat zFar));
//OGL_EXT(glOrthox,void, (GLfixed left, GLfixed right, GLfixed bottom, GLfixed top, GLfixed zNear, GLfixed zFar));
OGL_EXT(glPixelStorei,void, (GLenum pname, GLint param));
OGL_EXT(glPointSize,void, (GLfloat size));
//OGL_EXT(glPointSizex,void, (GLfixed size));
OGL_EXT(glPolygonOffset,void, (GLfloat factor, GLfloat units));
//OGL_EXT(glPolygonOffsetx,void, (GLfixed factor, GLfixed units));
OGL_EXT(glPopMatrix,void, (void));
OGL_EXT(glPushMatrix,void, (void));
OGL_EXT(glReadPixels,void, (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLvoid *pixels));
OGL_EXT(glRotatef,void, (GLfloat angle, GLfloat x, GLfloat y, GLfloat z));
//OGL_EXT(glRotatex,void, (GLfixed angle, GLfixed x, GLfixed y, GLfixed z));
//OGL_EXT(glSampleCoverage,void, (GLclampf value, GLboolean invert));
//OGL_EXT(glSampleCoveragex,void, (GLclampx value, GLboolean invert));
OGL_EXT(glScalef,void, (GLfloat x, GLfloat y, GLfloat z));
//OGL_EXT(glScalex,void, (GLfixed x, GLfixed y, GLfixed z));
OGL_EXT(glScissor,void, (GLint x, GLint y, GLsizei width, GLsizei height));
OGL_EXT(glShadeModel,void, (GLenum mode));
OGL_EXT(glStencilFunc,void, (GLenum func, GLint ref, GLuint mask));
OGL_EXT(glStencilMask,void, (GLuint mask));
OGL_EXT(glStencilOp,void, (GLenum fail, GLenum zfail, GLenum zpass));
OGL_EXT(glTexCoordPointer,void, (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer));
OGL_EXT(glTexEnvf,void, (GLenum target, GLenum pname, GLfloat param));
OGL_EXT(glTexEnvfv,void, (GLenum target, GLenum pname, const GLfloat *params));
//OGL_EXT(glTexEnvx,void, (GLenum target, GLenum pname, GLfixed param));
//OGL_EXT(glTexEnvxv,void, (GLenum target, GLenum pname, const GLfixed *params));
OGL_EXT(glTexImage2D,void, (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels));
OGL_EXT(glTexParameterf,void, (GLenum target, GLenum pname, GLfloat param));
OGL_EXT(glTexParameteri,void, (GLenum target, GLenum pname, GLint param));
OGL_EXT(glTexSubImage2D,void, (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *pixels));
OGL_EXT(glTranslatef,void, (GLfloat x, GLfloat y, GLfloat z));
//OGL_EXT(glTranslatex,void, (GLfixed x, GLfixed y, GLfixed z));
OGL_EXT(glVertexPointer,void, (GLint size, GLenum type, GLsizei stride, const GLvoid *pointer));
OGL_EXT(glViewport,void, (GLint x, GLint y, GLsizei width, GLsizei height));
OGL_EXT(glGetTexParameterfv,void,(GLenum target,  GLenum pname,  GLfloat * params));
OGL_EXT(glGetTexParameteriv,void,(GLenum target,  GLenum pname,  GLint * params));
OGL_EXT(glIsTexture, GLboolean, ( GLuint texture) );
OGL_EXT(glIsEnabled, GLboolean, ( GLuint texture) );


#ifdef NATIVE_TOOLKIT_SDL_ANGLE
EGL_EXT(eglBindTexImage, EGLBoolean, (EGLDisplay dpy, EGLSurface surface, EGLint buffer));
EGL_EXT(eglChooseConfig, EGLBoolean, (EGLDisplay dpy, const EGLint *attrib_list, EGLConfig *configs, EGLint config_size, EGLint *num_config));
EGL_EXT(eglCreatePbufferSurface, EGLSurface, (EGLDisplay dpy, EGLConfig config, const EGLint *attrib_list));
EGL_EXT(eglDestroySurface, EGLBoolean, (EGLDisplay display, EGLSurface surface));
EGL_EXT(eglGetDisplay, EGLDisplay, (EGLNativeDisplayType display_id));
EGL_EXT(eglGetError, EGLint, (void));
EGL_EXT(eglGetConfigs, EGLBoolean, (EGLDisplay dpy, EGLConfig *configs,EGLint config_size, EGLint *num_config));
EGL_EXT(eglGetConfigAttrib, EGLBoolean, (EGLDisplay dpy, EGLConfig config, EGLint attribute, EGLint *value));
EGL_EXT(eglReleaseTexImage, EGLBoolean, (EGLDisplay display, EGLSurface surface, EGLint buffer));
EGL_EXT(eglQuerySurfacePointerANGLE, EGLBoolean, (EGLDisplay dpy, EGLSurface surface, EGLint attribute, void **value));
#endif

#endif


#undef OGL_EXT
#undef EGL_EXT
#undef CALLING_CONVENTION
