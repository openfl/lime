#ifndef GL_UNSIGNED_SHORT_4_4_4_4
#define GL_UNSIGNED_SHORT_4_4_4_4 0x8033
#define GL_UNSIGNED_SHORT_5_6_5 0x8363
#endif


#ifdef HX_WINDOWS
#define CALLING_CONVENTION APIENTRY
#else
#define CALLING_CONVENTION APIENTRY
#endif


#ifdef DECLARE_EXTENSION

#define OGL_EXT(func,ret,args) \
   extern ret (CALLING_CONVENTION *func)args;

#elif defined(DEFINE_EXTENSION)

#define OGL_EXT(func,ret,args) \
   ret (CALLING_CONVENTION *func)args=0;

#elif defined(GET_EXTENSION)

#ifdef HX_WINDOWS
#define OGL_EXT(func,ret,args) \
{\
   *(void **)&func = (void *)wglGetProcAddress(#func);\
   if (!func) \
      *(void **)&func = (void *)wglGetProcAddress(#func "ARB");\
}
#endif


#endif

OGL_EXT(glBindBuffer,void,(GLenum,GLuint))
OGL_EXT(glDeleteBuffers,void,(GLsizei,const GLuint *))
OGL_EXT(glGenBuffers,void,(GLsizei,GLuint*))
OGL_EXT(glBufferData,void,(GLenum,GLuint,const void *, GLenum))
OGL_EXT(glCreateShader,GLuint,(GLenum))
OGL_EXT(glGetUniformLocation,GLint,(GLuint,const char *))
OGL_EXT(glUniform4f,void,(GLint,float,float,float,float))
OGL_EXT(glUniformMatrix2fv,void,(GLint,GLsizei,GLboolean,const float *))
OGL_EXT(glUniformMatrix3fv,void,(GLint,GLsizei,GLboolean,const float *))
OGL_EXT(glUniformMatrix4fv,void,(GLint,GLsizei,GLboolean,const float *))
OGL_EXT(glDeleteShader,void,(GLint))
OGL_EXT(glDeleteProgram,void,(GLint))
OGL_EXT(glGetAttribLocation,GLint,(GLuint,const char *))
OGL_EXT(glShaderSource,void,(GLuint,GLsizei,const char **, const GLint *))
OGL_EXT(glDisableVertexAttribArray,void,(GLuint))
OGL_EXT(glEnableVertexAttribArray,void,(GLuint))
OGL_EXT(glAttachShader,void,(GLuint,GLuint))
OGL_EXT(glCreateProgram,GLuint,())
OGL_EXT(glCompileShader,void,(GLuint))
OGL_EXT(glLinkProgram,void,(GLuint))
OGL_EXT(glGetShaderiv,void,(GLuint,GLenum,GLint *))
OGL_EXT(glValidateProgram,void,(GLuint))
OGL_EXT(glGetShaderInfoLog,void,(GLuint,GLsizei,GLsizei *,char *))
OGL_EXT(glGetProgramiv,void,(GLuint,GLenum,GLint *))
OGL_EXT(glGetProgramInfoLog,void,(GLuint,GLsizei,GLsizei *,char *))
OGL_EXT(glUseProgram,void,(GLuint))
OGL_EXT(glUniform1i,void,(GLuint,GLint))
OGL_EXT(glVertexAttribPointer,void,(GLuint,GLint,GLenum,GLboolean,GLsizei,const void *))
OGL_EXT(glActiveTexture,void,(GLenum))

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
OGL_EXT(glDeleteFramebuffers,void,(GLsizei, const GLuint *));
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
OGL_EXT(glDeleteRenderbuffers,void,(GLsizei, const GLuint *));
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
#undef OGL_EXT
#undef CALLING_CONVENTION

