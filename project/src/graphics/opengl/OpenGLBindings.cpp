#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <system/Mutex.h>
#include <utils/Bytes.h>
#include "OpenGL.h"
#include "OpenGLBindings.h"
#include <map>
#include <string>
#include <vector>

#ifdef NEED_EXTENSIONS
#define DEFINE_EXTENSION
#include "OpenGLExtensions.h"
#undef DEFINE_EXTENSION
#endif

#ifdef HX_LINUX
#include <dlfcn.h>
#endif

#ifndef APIENTRY
#define APIENTRY GLAPIENTRY
#endif

#ifdef LIME_SDL
#include <SDL.h>
#endif


namespace lime {


	bool OpenGLBindings::initialized = false;

	int OpenGLBindings::defaultFramebuffer = 0;
	int OpenGLBindings::defaultRenderbuffer = 0;
	void* OpenGLBindings::handle = 0;

	#ifdef NATIVE_TOOLKIT_SDL_ANGLE
	void* OpenGLBindings::eglHandle = 0;
	#endif

	#if (defined (HX_LINUX) || defined (HX_WINDOWS) || defined (HX_MACOS)) && !defined (NATIVE_TOOLKIT_SDL_ANGLE) && !defined (RASPBERRYPI)
	typedef void (APIENTRY * GL_DebugMessageCallback_Func)(GLDEBUGPROC, const void *);
	GL_DebugMessageCallback_Func glDebugMessageCallback_ptr = 0;
	#endif

	std::map<GLObjectType, std::map <GLuint, void*> > glObjects;
	std::map<void*, GLuint> glObjectIDs;
	std::map<void*, void*> glObjectPtrs;
	std::map<void*, GLObjectType> glObjectTypes;

	std::vector<GLuint> gc_gl_id;
	std::vector<void*> gc_gl_ptr;
	std::vector<GLObjectType> gc_gl_type;
	Mutex gc_gl_mutex;


	void gc_gl_object (value object) {

		gc_gl_mutex.Lock ();

		if (glObjectTypes.find (object) != glObjectTypes.end ()) {

			GLObjectType type = glObjectTypes[object];

			if (type != TYPE_SYNC) {

				GLuint id = glObjectIDs[object];

				gc_gl_id.push_back (id);
				gc_gl_type.push_back (type);

				glObjects[type].erase (id);
				glObjectIDs.erase (object);
				glObjectTypes.erase (object);

			} else {

				void* ptr = glObjectPtrs[object];

				gc_gl_ptr.push_back (ptr);

				glObjectPtrs.erase (object);
				glObjectTypes.erase (object);

			}

		}

		gc_gl_mutex.Unlock ();

	}


	void gc_gl_run () {

		if (gc_gl_id.size () > 0) {

			gc_gl_mutex.Lock ();

			int size = gc_gl_id.size ();

			GLuint id;
			GLObjectType type;

			for (int i = 0; i < size; i++) {

				id = gc_gl_id[i];
				type = gc_gl_type[i];

				switch (type) {

					case TYPE_BUFFER:

						if (glIsBuffer (id)) glDeleteBuffers (1, &id);
						break;

					case TYPE_FRAMEBUFFER:

						if (glIsFramebuffer (id)) glDeleteFramebuffers (1, &id);
						break;

					case TYPE_PROGRAM:

						if (glIsProgram (id)) glDeleteProgram (id);
						break;

					#ifdef LIME_GLES3_API
					case TYPE_QUERY:

						if (glIsQuery (id)) glDeleteQueries (1, &id);
						break;
					#endif

					case TYPE_RENDERBUFFER:

						if (glIsRenderbuffer (id)) glDeleteRenderbuffers (1, &id);
						break;

					#ifdef LIME_GLES3_API
					case TYPE_SAMPLER:

						if (glIsSampler (id)) glDeleteSamplers (1, &id);
						break;
					#endif

					case TYPE_SHADER:

						if (glIsShader (id)) glDeleteShader (id);
						break;

					case TYPE_TEXTURE:

						if (glIsTexture (id)) glDeleteTextures (1, &id);
						break;

					#ifdef LIME_GLES3_API
					case TYPE_VERTEX_ARRAY_OBJECT:

						if (glIsVertexArray (id)) glDeleteVertexArrays (1, &id);
						break;
					#endif

					default: break;

				}

			}

			size = gc_gl_ptr.size ();
			void* ptr;

			for (int i = 0; i < size; i++) {

				ptr = gc_gl_ptr[i];
				//type = gc_gl_type[i];

				#ifdef LIME_GLES3_API
				if (glIsSync ((GLsync)ptr)) glDeleteSync ((GLsync)ptr);
				#endif

			}

			gc_gl_id.clear ();
			gc_gl_ptr.clear ();
			gc_gl_type.clear ();

			gc_gl_mutex.Unlock ();

		}

	}


	#if (defined (HX_LINUX) || defined (HX_WINDOWS) || defined (HX_MACOS)) && !defined (NATIVE_TOOLKIT_SDL_ANGLE) && !defined (RASPBERRYPI)
	void APIENTRY gl_debug_callback (GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *message, GLvoid *userParam) {

		puts (message);

	}
	#endif


	void lime_gl_active_texture (int texture) {

		glActiveTexture (texture);

	}


	HL_PRIM void HL_NAME(hl_gl_active_texture) (int texture) {

		glActiveTexture (texture);

	}


	void lime_gl_attach_shader (int program, int shader) {

		glAttachShader (program, shader);

	}


	HL_PRIM void HL_NAME(hl_gl_attach_shader) (int program, int shader) {

		glAttachShader (program, shader);

	}


	void lime_gl_begin_query (int target, int query) {

		#ifdef LIME_GLES3_API
		glBeginQuery (target, query);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_begin_query) (int target, int query) {

		#ifdef LIME_GLES3_API
		glBeginQuery (target, query);
		#endif

	}


	void lime_gl_begin_transform_feedback (int primitiveNode) {

		#ifdef LIME_GLES3_API
		glBeginTransformFeedback (primitiveNode);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_begin_transform_feedback) (int primitiveNode) {

		#ifdef LIME_GLES3_API
		glBeginTransformFeedback (primitiveNode);
		#endif

	}


	void lime_gl_bind_attrib_location (int program, int index, HxString name) {

		glBindAttribLocation (program, index, name.__s);

	}


	HL_PRIM void HL_NAME(hl_gl_bind_attrib_location) (int program, int index, hl_vstring* name) {

		glBindAttribLocation (program, index, name ? hl_to_utf8 (name->bytes) : NULL);

	}


	void lime_gl_bind_buffer (int target, int buffer) {

		glBindBuffer (target, buffer);

	}


	HL_PRIM void HL_NAME(hl_gl_bind_buffer) (int target, int buffer) {

		glBindBuffer (target, buffer);

	}


	void lime_gl_bind_buffer_base (int target, int index, int buffer) {

		#ifdef LIME_GLES3_API
		glBindBufferBase (target, index, buffer);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_bind_buffer_base) (int target, int index, int buffer) {

		#ifdef LIME_GLES3_API
		glBindBufferBase (target, index, buffer);
		#endif

	}


	void lime_gl_bind_buffer_range (int target, int index, int buffer, double offset, int size) {

		#ifdef LIME_GLES3_API
		glBindBufferRange (target, index, buffer, (GLintptr)(uintptr_t)offset, size);
		#endif


	}


	HL_PRIM void HL_NAME(hl_gl_bind_buffer_range) (int target, int index, int buffer, double offset, int size) {

		#ifdef LIME_GLES3_API
		glBindBufferRange (target, index, buffer, (GLintptr)(uintptr_t)offset, size);
		#endif


	}


	void lime_gl_bind_framebuffer (int target, int framebuffer) {

		if (!framebuffer) {

			framebuffer = OpenGLBindings::defaultFramebuffer;

		}

		glBindFramebuffer (target, framebuffer);

	}


	HL_PRIM void HL_NAME(hl_gl_bind_framebuffer) (int target, int framebuffer) {

		if (!framebuffer) {

			framebuffer = OpenGLBindings::defaultFramebuffer;

		}

		glBindFramebuffer (target, framebuffer);

	}


	void lime_gl_bind_renderbuffer (int target, int renderbuffer) {

		if (!renderbuffer) {

			renderbuffer = OpenGLBindings::defaultRenderbuffer;

		}

		glBindRenderbuffer (target, renderbuffer);

	}


	HL_PRIM void HL_NAME(hl_gl_bind_renderbuffer) (int target, int renderbuffer) {

		if (!renderbuffer) {

			renderbuffer = OpenGLBindings::defaultRenderbuffer;

		}

		glBindRenderbuffer (target, renderbuffer);

	}


	void lime_gl_bind_sampler (int unit, int sampler) {

		#ifdef LIME_GLES3_API
		glBindSampler (unit, sampler);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_bind_sampler) (int unit, int sampler) {

		#ifdef LIME_GLES3_API
		glBindSampler (unit, sampler);
		#endif

	}


	void lime_gl_bind_texture (int target, int texture) {

		glBindTexture (target, texture);

	}


	HL_PRIM void HL_NAME(hl_gl_bind_texture) (int target, int texture) {

		glBindTexture (target, texture);

	}


	void lime_gl_bind_transform_feedback (int target, int transformFeedback) {

		#ifdef LIME_GLES3_API
		glBindTransformFeedback (target, transformFeedback);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_bind_transform_feedback) (int target, int transformFeedback) {

		#ifdef LIME_GLES3_API
		glBindTransformFeedback (target, transformFeedback);
		#endif

	}


	void lime_gl_bind_vertex_array (int vertexArray) {

		#ifdef LIME_GLES3_API
		glBindVertexArray (vertexArray);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_bind_vertex_array) (int vertexArray) {

		#ifdef LIME_GLES3_API
		glBindVertexArray (vertexArray);
		#endif

	}


	void lime_gl_blend_color (float r, float g, float b, float a) {

		glBlendColor (r, g, b, a);

	}


	HL_PRIM void HL_NAME(hl_gl_blend_color) (float r, float g, float b, float a) {

		glBlendColor (r, g, b, a);

	}


	void lime_gl_blend_equation (int mode) {

		glBlendEquation (mode);

	}


	HL_PRIM void HL_NAME(hl_gl_blend_equation) (int mode) {

		glBlendEquation (mode);

	}


	void lime_gl_blend_equation_separate (int rgb, int a) {

		glBlendEquationSeparate (rgb, a);

	}


	HL_PRIM void HL_NAME(hl_gl_blend_equation_separate) (int rgb, int a) {

		glBlendEquationSeparate (rgb, a);

	}


	void lime_gl_blend_func (int sfactor, int dfactor) {

		glBlendFunc (sfactor, dfactor);

	}


	HL_PRIM void HL_NAME(hl_gl_blend_func) (int sfactor, int dfactor) {

		glBlendFunc (sfactor, dfactor);

	}


	void lime_gl_blend_func_separate (int srcRGB, int destRGB, int srcAlpha, int destAlpha) {

		glBlendFuncSeparate (srcRGB, destRGB, srcAlpha, destAlpha);

	}


	HL_PRIM void HL_NAME(hl_gl_blend_func_separate) (int srcRGB, int destRGB, int srcAlpha, int destAlpha) {

		glBlendFuncSeparate (srcRGB, destRGB, srcAlpha, destAlpha);

	}


	void lime_gl_blit_framebuffer (int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1, int mask, int filter) {

		#ifdef LIME_GLES3_API
		glBlitFramebuffer (srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_blit_framebuffer) (int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1, int mask, int filter) {

		#ifdef LIME_GLES3_API
		glBlitFramebuffer (srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
		#endif

	}


	void lime_gl_buffer_data (int target, int size, double data, int usage) {

		glBufferData (target, size, (void*)(uintptr_t)data, usage);

	}


	HL_PRIM void HL_NAME(hl_gl_buffer_data) (int target, int size, double data, int usage) {

		glBufferData (target, size, (void*)(uintptr_t)data, usage);

	}


	void lime_gl_buffer_sub_data (int target, int offset, int size, double data) {

		glBufferSubData (target, offset, size, (void*)(uintptr_t)data);

	}


	HL_PRIM void HL_NAME(hl_gl_buffer_sub_data) (int target, int offset, int size, double data) {

		glBufferSubData (target, offset, size, (void*)(uintptr_t)data);

	}


	int lime_gl_check_framebuffer_status (int target) {

		return glCheckFramebufferStatus (target);

	}


	HL_PRIM int HL_NAME(hl_gl_check_framebuffer_status) (int target) {

		return glCheckFramebufferStatus (target);

	}


	void lime_gl_clear (int mask) {

		gc_gl_run ();
		glClear (mask);

	}


	HL_PRIM void HL_NAME(hl_gl_clear) (int mask) {

		gc_gl_run ();
		glClear (mask);

	}


	void lime_gl_clear_bufferfi (int buffer, int drawBuffer, float depth, int stencil) {

		#ifdef LIME_GLES3_API
		glClearBufferfi (buffer, drawBuffer, depth, stencil);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_clear_bufferfi) (int buffer, int drawBuffer, float depth, int stencil) {

		#ifdef LIME_GLES3_API
		glClearBufferfi (buffer, drawBuffer, depth, stencil);
		#endif

	}


	void lime_gl_clear_bufferfv (int buffer, int drawBuffer, double data) {

		#ifdef LIME_GLES3_API
		glClearBufferfv (buffer, drawBuffer, (GLfloat*)(uintptr_t)data);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_clear_bufferfv) (int buffer, int drawBuffer, double data) {

		#ifdef LIME_GLES3_API
		glClearBufferfv (buffer, drawBuffer, (GLfloat*)(uintptr_t)data);
		#endif

	}


	void lime_gl_clear_bufferiv (int buffer, int drawBuffer, double data) {

		#ifdef LIME_GLES3_API
		glClearBufferiv (buffer, drawBuffer, (GLint*)(uintptr_t)data);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_clear_bufferiv) (int buffer, int drawBuffer, double data) {

		#ifdef LIME_GLES3_API
		glClearBufferiv (buffer, drawBuffer, (GLint*)(uintptr_t)data);
		#endif

	}


	void lime_gl_clear_bufferuiv (int buffer, int drawBuffer, double data) {

		#ifdef LIME_GLES3_API
		glClearBufferuiv (buffer, drawBuffer, (GLuint*)(uintptr_t)data);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_clear_bufferuiv) (int buffer, int drawBuffer, double data) {

		#ifdef LIME_GLES3_API
		glClearBufferuiv (buffer, drawBuffer, (GLuint*)(uintptr_t)data);
		#endif

	}


	void lime_gl_clear_color (float red, float green, float blue, float alpha) {

		glClearColor (red, green, blue, alpha);

	}


	HL_PRIM void HL_NAME(hl_gl_clear_color) (float red, float green, float blue, float alpha) {

		glClearColor (red, green, blue, alpha);

	}


	void lime_gl_clear_depthf (float depth) {

		#ifdef LIME_GLES
		glClearDepthf (depth);
		#else
		glClearDepth (depth);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_clear_depthf) (float depth) {

		#ifdef LIME_GLES
		glClearDepthf (depth);
		#else
		glClearDepth (depth);
		#endif

	}


	void lime_gl_clear_stencil (int stencil) {

		glClearStencil (stencil);

	}


	HL_PRIM void HL_NAME(hl_gl_clear_stencil) (int stencil) {

		glClearStencil (stencil);

	}


	int lime_gl_client_wait_sync (value sync, int flags, int timeoutA, int timeoutB) {

		#ifdef LIME_GLES3_API
		GLuint64 timeout = (GLuint64) timeoutA << 32 | timeoutB;
		return glClientWaitSync ((GLsync)val_data (sync), flags, timeout);
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_gl_client_wait_sync) (HL_CFFIPointer* sync, int flags, int timeoutA, int timeoutB) {

		#ifdef LIME_GLES3_API
		GLuint64 timeout = (GLuint64) timeoutA << 32 | timeoutB;
		return glClientWaitSync ((GLsync)sync->ptr, flags, timeout);
		#else
		return 0;
		#endif

	}


	void lime_gl_color_mask (bool red, bool green, bool blue, bool alpha) {

		glColorMask (red, green, blue, alpha);

	}


	HL_PRIM void HL_NAME(hl_gl_color_mask) (bool red, bool green, bool blue, bool alpha) {

		glColorMask (red, green, blue, alpha);

	}


	void lime_gl_compile_shader (int shader) {

		glCompileShader (shader);

	}


	HL_PRIM void HL_NAME(hl_gl_compile_shader) (int shader) {

		glCompileShader (shader);

	}


	void lime_gl_compressed_tex_image_2d (int target, int level, int internalformat, int width, int height, int border, int imageSize, double data) {

		glCompressedTexImage2D (target, level, internalformat, width, height, border, imageSize, (void*)(uintptr_t)data);

	}


	HL_PRIM void HL_NAME(hl_gl_compressed_tex_image_2d) (int target, int level, int internalformat, int width, int height, int border, int imageSize, double data) {

		glCompressedTexImage2D (target, level, internalformat, width, height, border, imageSize, (void*)(uintptr_t)data);

	}


	void lime_gl_compressed_tex_image_3d (int target, int level, int internalformat, int width, int height, int depth, int border, int imageSize, double data) {

		#ifdef LIME_GLES3_API
		glCompressedTexImage3D (target, level, internalformat, width, height, depth, border, imageSize, (void*)(uintptr_t)data);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_compressed_tex_image_3d) (int target, int level, int internalformat, int width, int height, int depth, int border, int imageSize, double data) {

		#ifdef LIME_GLES3_API
		glCompressedTexImage3D (target, level, internalformat, width, height, depth, border, imageSize, (void*)(uintptr_t)data);
		#endif

	}


	void lime_gl_compressed_tex_sub_image_2d (int target, int level, int xoffset, int yoffset, int width, int height, int format, int imageSize, double data) {

		glCompressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, imageSize, (void*)(uintptr_t)data);

	}


	HL_PRIM void HL_NAME(hl_gl_compressed_tex_sub_image_2d) (int target, int level, int xoffset, int yoffset, int width, int height, int format, int imageSize, double data) {

		glCompressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, imageSize, (void*)(uintptr_t)data);

	}


	void lime_gl_compressed_tex_sub_image_3d (int target, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, int format, int imageSize, double data) {

		#ifdef LIME_GLES3_API
		glCompressedTexSubImage3D (target, level, xoffset, yoffset, zoffset, width, height, depth, format, imageSize, (void*)(uintptr_t)data);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_compressed_tex_sub_image_3d) (int target, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, int format, int imageSize, double data) {

		#ifdef LIME_GLES3_API
		glCompressedTexSubImage3D (target, level, xoffset, yoffset, zoffset, width, height, depth, format, imageSize, (void*)(uintptr_t)data);
		#endif

	}


	void lime_gl_copy_buffer_sub_data (int readTarget, int writeTarget, double readOffset, double writeOffset, int size) {

		#ifdef LIME_GLES3_API
		glCopyBufferSubData (readTarget, writeTarget, (GLintptr)(uintptr_t)readOffset, (GLintptr)(uintptr_t)writeOffset, size);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_copy_buffer_sub_data) (int readTarget, int writeTarget, double readOffset, double writeOffset, int size) {

		#ifdef LIME_GLES3_API
		glCopyBufferSubData (readTarget, writeTarget, (GLintptr)(uintptr_t)readOffset, (GLintptr)(uintptr_t)writeOffset, size);
		#endif

	}


	void lime_gl_copy_tex_image_2d (int target, int level, int internalformat, int x, int y, int width, int height, int border) {

		glCopyTexImage2D (target, level, internalformat, x, y, width, height, border);

	}


	HL_PRIM void HL_NAME(hl_gl_copy_tex_image_2d) (int target, int level, int internalformat, int x, int y, int width, int height, int border) {

		glCopyTexImage2D (target, level, internalformat, x, y, width, height, border);

	}


	void lime_gl_copy_tex_sub_image_2d (int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) {

		glCopyTexSubImage2D (target, level, xoffset, yoffset, x, y, width, height);

	}


	HL_PRIM void HL_NAME(hl_gl_copy_tex_sub_image_2d) (int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) {

		glCopyTexSubImage2D (target, level, xoffset, yoffset, x, y, width, height);

	}


	void lime_gl_copy_tex_sub_image_3d (int target, int level, int xoffset, int yoffset, int zoffset, int x, int y, int width, int height) {

		#ifdef LIME_GLES3_API
		glCopyTexSubImage3D (target, level, xoffset, yoffset, zoffset, x, y, width, height);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_copy_tex_sub_image_3d) (int target, int level, int xoffset, int yoffset, int zoffset, int x, int y, int width, int height) {

		#ifdef LIME_GLES3_API
		glCopyTexSubImage3D (target, level, xoffset, yoffset, zoffset, x, y, width, height);
		#endif

	}


	int lime_gl_create_buffer () {

		GLuint id = 0;
		glGenBuffers (1, &id);
		return id;

	}


	HL_PRIM int HL_NAME(hl_gl_create_buffer) () {

		GLuint id = 0;
		glGenBuffers (1, &id);
		return id;

	}


	int lime_gl_create_framebuffer () {

		GLuint id = 0;
		glGenFramebuffers (1, &id);
		return id;

	}


	HL_PRIM int HL_NAME(hl_gl_create_framebuffer) () {

		GLuint id = 0;
		glGenFramebuffers (1, &id);
		return id;

	}


	int lime_gl_create_program () {

		return glCreateProgram ();

	}


	HL_PRIM int HL_NAME(hl_gl_create_program) () {

		return glCreateProgram ();

	}


	int lime_gl_create_query () {

		GLuint id = 0;
		#ifdef LIME_GLES3_API
		glGenQueries (1, &id);
		#endif
		return id;

	}


	HL_PRIM int HL_NAME(hl_gl_create_query) () {

		GLuint id = 0;
		#ifdef LIME_GLES3_API
		glGenQueries (1, &id);
		#endif
		return id;

	}


	int lime_gl_create_renderbuffer () {

		GLuint id = 0;
		glGenRenderbuffers (1, &id);
		return id;

	}


	HL_PRIM int HL_NAME(hl_gl_create_renderbuffer) () {

		GLuint id = 0;
		glGenRenderbuffers (1, &id);
		return id;

	}


	int lime_gl_create_sampler () {

		GLuint id = 0;
		#ifdef LIME_GLES3_API
		glGenSamplers (1, &id);
		#endif
		return id;

	}


	HL_PRIM int HL_NAME(hl_gl_create_sampler) () {

		GLuint id = 0;
		#ifdef LIME_GLES3_API
		glGenSamplers (1, &id);
		#endif
		return id;

	}


	int lime_gl_create_shader (int type) {

		return glCreateShader (type);

	}


	HL_PRIM int HL_NAME(hl_gl_create_shader) (int type) {

		return glCreateShader (type);

	}


	int lime_gl_create_texture () {

		GLuint id = 0;
		glGenTextures (1, &id);
		return id;

	}


	HL_PRIM int HL_NAME(hl_gl_create_texture) () {

		GLuint id = 0;
		glGenTextures (1, &id);
		return id;

	}


	int lime_gl_create_transform_feedback () {

		GLuint id = 0;
		#ifdef LIME_GLES3_API
		glGenTransformFeedbacks (1, &id);
		#endif
		return id;

	}


	HL_PRIM int HL_NAME(hl_gl_create_transform_feedback) () {

		GLuint id = 0;
		#ifdef LIME_GLES3_API
		glGenTransformFeedbacks (1, &id);
		#endif
		return id;

	}


	int lime_gl_create_vertex_array () {

		GLuint id = 0;
		#ifdef LIME_GLES3_API
		glGenVertexArrays (1, &id);
		#endif
		return id;

	}


	HL_PRIM int HL_NAME(hl_gl_create_vertex_array) () {

		GLuint id = 0;
		#ifdef LIME_GLES3_API
		glGenVertexArrays (1, &id);
		#endif
		return id;

	}


	void lime_gl_cull_face (int mode) {

		glCullFace (mode);

	}


	HL_PRIM void HL_NAME(hl_gl_cull_face) (int mode) {

		glCullFace (mode);

	}


	void lime_gl_delete_buffer (int buffer) {

		glDeleteBuffers (1, (GLuint*)&buffer);

	}


	HL_PRIM void HL_NAME(hl_gl_delete_buffer) (int buffer) {

		glDeleteBuffers (1, (GLuint*)&buffer);

	}


	void lime_gl_delete_framebuffer (int framebuffer) {

		glDeleteFramebuffers (1, (GLuint*)&framebuffer);

	}


	HL_PRIM void HL_NAME(hl_gl_delete_framebuffer) (int framebuffer) {

		glDeleteFramebuffers (1, (GLuint*)&framebuffer);

	}


	void lime_gl_delete_program (int program) {

		glDeleteProgram (program);

	}


	HL_PRIM void HL_NAME(hl_gl_delete_program) (int program) {

		glDeleteProgram (program);

	}


	void lime_gl_delete_query (int query) {

		#ifdef LIME_GLES3_API
		glDeleteQueries (1, (GLuint*)&query);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_delete_query) (int query) {

		#ifdef LIME_GLES3_API
		glDeleteQueries (1, (GLuint*)&query);
		#endif

	}


	void lime_gl_delete_renderbuffer (int renderbuffer) {

		glDeleteRenderbuffers (1, (GLuint*)&renderbuffer);

	}


	HL_PRIM void HL_NAME(hl_gl_delete_renderbuffer) (int renderbuffer) {

		glDeleteRenderbuffers (1, (GLuint*)&renderbuffer);

	}


	void lime_gl_delete_sampler (int sampler) {

		#ifdef LIME_GLES3_API
		glDeleteSamplers (1, (GLuint*)&sampler);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_delete_sampler) (int sampler) {

		#ifdef LIME_GLES3_API
		glDeleteSamplers (1, (GLuint*)&sampler);
		#endif

	}


	void lime_gl_delete_shader (int shader) {

		glDeleteShader (shader);

	}


	HL_PRIM void HL_NAME(hl_gl_delete_shader) (int shader) {

		glDeleteShader (shader);

	}


	void lime_gl_delete_sync (value sync) {

		#ifdef LIME_GLES3_API
		if (val_is_null (sync)) return;
		glDeleteSync ((GLsync)val_data (sync));
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_delete_sync) (HL_CFFIPointer* sync) {

		#ifdef LIME_GLES3_API
		if (!sync) return;
		glDeleteSync ((GLsync)sync->ptr);
		#endif

	}


	void lime_gl_delete_texture (int texture) {

		glDeleteTextures (1, (GLuint*)&texture);

	}


	HL_PRIM void HL_NAME(hl_gl_delete_texture) (int texture) {

		glDeleteTextures (1, (GLuint*)&texture);

	}


	void lime_gl_delete_transform_feedback (int transformFeedback) {

		#ifdef LIME_GLES3_API
		glDeleteTransformFeedbacks (1, (GLuint*)&transformFeedback);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_delete_transform_feedback) (int transformFeedback) {

		#ifdef LIME_GLES3_API
		glDeleteTransformFeedbacks (1, (GLuint*)&transformFeedback);
		#endif

	}


	void lime_gl_delete_vertex_array (int vertexArray) {

		#ifdef LIME_GLES3_API
		glDeleteVertexArrays (1, (GLuint*)&vertexArray);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_delete_vertex_array) (int vertexArray) {

		#ifdef LIME_GLES3_API
		glDeleteVertexArrays (1, (GLuint*)&vertexArray);
		#endif

	}


	void lime_gl_depth_func (int func) {

		glDepthFunc (func);

	}


	HL_PRIM void HL_NAME(hl_gl_depth_func) (int func) {

		glDepthFunc (func);

	}


	void lime_gl_depth_mask (bool flag) {

		glDepthMask (flag);

	}


	HL_PRIM void HL_NAME(hl_gl_depth_mask) (bool flag) {

		glDepthMask (flag);

	}


	void lime_gl_depth_rangef (float zNear, float zFar) {

		#ifdef LIME_GLES
		glDepthRangef (zNear, zFar);
		#else
		glDepthRange (zNear, zFar);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_depth_rangef) (float zNear, float zFar) {

		#ifdef LIME_GLES
		glDepthRangef (zNear, zFar);
		#else
		glDepthRange (zNear, zFar);
		#endif

	}


	void lime_gl_detach_shader (int program, int shader) {

		glDetachShader (program, shader);

	}


	HL_PRIM void HL_NAME(hl_gl_detach_shader) (int program, int shader) {

		glDetachShader (program, shader);

	}


	void lime_gl_disable (int cap) {

		glDisable (cap);

	}


	HL_PRIM void HL_NAME(hl_gl_disable) (int cap) {

		glDisable (cap);

	}


	void lime_gl_disable_vertex_attrib_array (int index) {

		glDisableVertexAttribArray (index);

	}


	HL_PRIM void HL_NAME(hl_gl_disable_vertex_attrib_array) (int index) {

		glDisableVertexAttribArray (index);

	}


	void lime_gl_draw_arrays (int mode, int first, int count) {

		glDrawArrays (mode, first, count);

	}


	HL_PRIM void HL_NAME(hl_gl_draw_arrays) (int mode, int first, int count) {

		glDrawArrays (mode, first, count);

	}


	void lime_gl_draw_arrays_instanced (int mode, int first, int count, int instanceCount) {

		#ifdef LIME_GLES3_API
		glDrawArraysInstanced (mode, first, count, instanceCount);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_draw_arrays_instanced) (int mode, int first, int count, int instanceCount) {

		#ifdef LIME_GLES3_API
		glDrawArraysInstanced (mode, first, count, instanceCount);
		#endif

	}


	void lime_gl_draw_buffers (value buffers) {

		#ifdef LIME_GLES3_API
		GLsizei size = val_array_size (buffers);
		GLenum *_buffers = (GLenum*)alloca (size * sizeof(GLenum));

		for (int i = 0; i < size; i++) {

			_buffers[i] = val_int (val_array_i (buffers, i));

		}

		glDrawBuffers (size, _buffers);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_draw_buffers) (hl_varray* buffers) {

		#ifdef LIME_GLES3_API
		GLsizei size = buffers->size;
		glDrawBuffers (size, (GLenum*)hl_aptr (buffers, int));
		#endif

	}


	void lime_gl_draw_elements (int mode, int count, int type, double offset) {

		glDrawElements (mode, count, type, (void*)(uintptr_t)offset);

	}


	HL_PRIM void HL_NAME(hl_gl_draw_elements) (int mode, int count, int type, double offset) {

		glDrawElements (mode, count, type, (void*)(uintptr_t)offset);

	}


	void lime_gl_draw_elements_instanced (int mode, int count, int type, double offset, int instanceCount) {

		#ifdef LIME_GLES3_API
		glDrawElementsInstanced (mode, count, type, (void*)(uintptr_t)offset, instanceCount);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_draw_elements_instanced) (int mode, int count, int type, double offset, int instanceCount) {

		#ifdef LIME_GLES3_API
		glDrawElementsInstanced (mode, count, type, (void*)(uintptr_t)offset, instanceCount);
		#endif

	}


	void lime_gl_draw_range_elements (int mode, int start, int end, int count, int type, double offset) {

		#ifdef LIME_GLES3_API
		glDrawRangeElements (mode, start, end, count, type, (void*)(uintptr_t)offset);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_draw_range_elements) (int mode, int start, int end, int count, int type, double offset) {

		#ifdef LIME_GLES3_API
		glDrawRangeElements (mode, start, end, count, type, (void*)(uintptr_t)offset);
		#endif

	}


	void lime_gl_enable (int cap) {

		glEnable (cap);

	}


	HL_PRIM void HL_NAME(hl_gl_enable) (int cap) {

		glEnable (cap);

	}


	void lime_gl_enable_vertex_attrib_array (int index) {

		glEnableVertexAttribArray (index);

	}


	HL_PRIM void HL_NAME(hl_gl_enable_vertex_attrib_array) (int index) {

		glEnableVertexAttribArray (index);

	}


	void lime_gl_end_query (int target) {

		#ifdef LIME_GLES3_API
		glEndQuery (target);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_end_query) (int target) {

		#ifdef LIME_GLES3_API
		glEndQuery (target);
		#endif

	}


	void lime_gl_end_transform_feedback () {

		#ifdef LIME_GLES3_API
		glEndTransformFeedback ();
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_end_transform_feedback) () {

		#ifdef LIME_GLES3_API
		glEndTransformFeedback ();
		#endif

	}


	value lime_gl_fence_sync (int condition, int flags) {

		#ifdef LIME_GLES3_API
		GLsync result = glFenceSync (condition, flags);
		value handle = CFFIPointer (result, gc_gl_object);
		glObjectPtrs[handle] = result;
		return handle;
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_gl_fence_sync) (int condition, int flags) {

		#ifdef LIME_GLES3_API
		GLsync result = glFenceSync (condition, flags);
		HL_CFFIPointer* handle = HLCFFIPointer (result, (hl_finalizer)gc_gl_object);
		glObjectPtrs[handle] = result;
		return handle;
		#else
		return NULL;
		#endif

	}


	void lime_gl_finish () {

		glFinish ();

	}


	HL_PRIM void HL_NAME(hl_gl_finish) () {

		glFinish ();

	}


	void lime_gl_flush () {

		glFlush ();

	}


	HL_PRIM void HL_NAME(hl_gl_flush) () {

		glFlush ();

	}


	void lime_gl_framebuffer_renderbuffer (int target, int attachment, int renderbuffertarget, int renderbuffer) {

		glFramebufferRenderbuffer (target, attachment, renderbuffertarget, renderbuffer);

	}


	HL_PRIM void HL_NAME(hl_gl_framebuffer_renderbuffer) (int target, int attachment, int renderbuffertarget, int renderbuffer) {

		glFramebufferRenderbuffer (target, attachment, renderbuffertarget, renderbuffer);

	}


	void lime_gl_framebuffer_texture2D (int target, int attachment, int textarget, int texture, int level) {

		glFramebufferTexture2D (target, attachment, textarget, texture, level);

	}


	HL_PRIM void HL_NAME(hl_gl_framebuffer_texture2D) (int target, int attachment, int textarget, int texture, int level) {

		glFramebufferTexture2D (target, attachment, textarget, texture, level);

	}


	void lime_gl_framebuffer_texture_layer (int target, int attachment, int texture, int level, int layer) {

		#ifdef LIME_GLES3_API
		glFramebufferTextureLayer (target, attachment, texture, level, layer);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_framebuffer_texture_layer) (int target, int attachment, int texture, int level, int layer) {

		#ifdef LIME_GLES3_API
		glFramebufferTextureLayer (target, attachment, texture, level, layer);
		#endif

	}


	void lime_gl_front_face (int face) {

		glFrontFace (face);

	}


	HL_PRIM void HL_NAME(hl_gl_front_face) (int face) {

		glFrontFace (face);

	}


	void lime_gl_generate_mipmap (int target) {

		glGenerateMipmap (target);

	}


	HL_PRIM void HL_NAME(hl_gl_generate_mipmap) (int target) {

		glGenerateMipmap (target);

	}


	value lime_gl_get_active_attrib (int program, int index) {

		value result = alloc_empty_object ();

		std::string buffer (GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, 0);
		GLsizei outLen = 0;
		GLsizei size = 0;
		GLenum type = 0;

		glGetActiveAttrib (program, index, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &outLen, &size, &type, &buffer[0]);

		buffer.resize (outLen);

		alloc_field (result, val_id ("size"), alloc_int (size));
		alloc_field (result, val_id ("type"), alloc_int (type));
		alloc_field (result, val_id ("name"), alloc_string (buffer.c_str ()));

		return result;

	}


	HL_PRIM vdynamic* HL_NAME(hl_gl_get_active_attrib) (int program, int index) {

		char buffer[GL_ACTIVE_ATTRIBUTE_MAX_LENGTH];
		GLsizei outLen = 0;
		GLsizei size = 0;
		GLenum type = 0;

		glGetActiveAttrib (program, index, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &outLen, &size, &type, &buffer[0]);

		char* _buffer = (char*)malloc (outLen + 1);
		memcpy (_buffer, &buffer, outLen);
		_buffer[outLen] = '\0';

		const int id_size = hl_hash_utf8 ("size");
		const int id_type = hl_hash_utf8 ("type");
		const int id_name = hl_hash_utf8 ("name");

		vdynamic *result = (vdynamic*)hl_alloc_dynobj();
		hl_dyn_seti (result, id_size, &hlt_i32, size);
		hl_dyn_seti (result, id_type, &hlt_i32, type);
		hl_dyn_setp (result, id_name, &hlt_bytes, _buffer);

		return result;

	}


	value lime_gl_get_active_uniform (int program, int index) {

		std::string buffer (GL_ACTIVE_UNIFORM_MAX_LENGTH, 0);
		GLsizei outLen = 0;
		GLsizei size = 0;
		GLenum  type = 0;

		glGetActiveUniform (program, index, GL_ACTIVE_UNIFORM_MAX_LENGTH, &outLen, &size, &type, &buffer[0]);

		buffer.resize (outLen);

		value result = alloc_empty_object ();
		alloc_field (result, val_id ("size"), alloc_int (size));
		alloc_field (result, val_id ("type"), alloc_int (type));
		alloc_field (result, val_id ("name"), alloc_string (buffer.c_str ()));

		return result;

	}


	HL_PRIM vdynamic* HL_NAME(hl_gl_get_active_uniform) (int program, int index) {

		char* buffer[GL_ACTIVE_UNIFORM_MAX_LENGTH];
		GLsizei outLen = 0;
		GLsizei size = 0;
		GLenum type = 0;

		glGetActiveUniform (program, index, GL_ACTIVE_UNIFORM_MAX_LENGTH, &outLen, &size, &type, (GLchar*)&buffer);

		char* _buffer = (char*)malloc (outLen + 1);
		memcpy (_buffer, &buffer, outLen);
		_buffer[outLen] = '\0';

		const int id_size = hl_hash_utf8 ("size");
		const int id_type = hl_hash_utf8 ("type");
		const int id_name = hl_hash_utf8 ("name");

		vdynamic *result = (vdynamic*)hl_alloc_dynobj();
		hl_dyn_seti (result, id_size, &hlt_i32, size);
		hl_dyn_seti (result, id_type, &hlt_i32, type);
		hl_dyn_setp (result, id_name, &hlt_bytes, _buffer);

		return result;

	}


	int lime_gl_get_active_uniform_blocki (int program, int uniformBlockIndex, int pname) {

		GLint param = 0;
		#ifdef LIME_GLES3_API
		glGetActiveUniformBlockiv (program, uniformBlockIndex, pname, &param);
		#endif
		return param;

	}


	HL_PRIM int HL_NAME(hl_gl_get_active_uniform_blocki) (int program, int uniformBlockIndex, int pname) {

		GLint param = 0;
		#ifdef LIME_GLES3_API
		glGetActiveUniformBlockiv (program, uniformBlockIndex, pname, &param);
		#endif
		return param;

	}


	void lime_gl_get_active_uniform_blockiv (int program, int uniformBlockIndex, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetActiveUniformBlockiv (program, uniformBlockIndex, pname, (GLint*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_active_uniform_blockiv) (int program, int uniformBlockIndex, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetActiveUniformBlockiv (program, uniformBlockIndex, pname, (GLint*)(uintptr_t)params);
		#endif

	}


	value lime_gl_get_active_uniform_block_name (int program, int uniformBlockIndex) {

		#ifdef LIME_GLES3_API
		GLint length;
		glGetActiveUniformBlockiv (program, uniformBlockIndex, GL_UNIFORM_BLOCK_NAME_LENGTH, &length);

		std::string buffer (length, 0);

		glGetActiveUniformBlockName (program, uniformBlockIndex, length, 0, &buffer[0]);

		return alloc_string (buffer.c_str ());
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM vbyte* HL_NAME(hl_gl_get_active_uniform_block_name) (int program, int uniformBlockIndex) {

		#ifdef LIME_GLES3_API
		GLint length;
		glGetActiveUniformBlockiv (program, uniformBlockIndex, GL_UNIFORM_BLOCK_NAME_LENGTH, &length);

		char* buffer = (char*)malloc (length + 1);

		glGetActiveUniformBlockName (program, uniformBlockIndex, length, 0, buffer);

		buffer[length] = '\0';
		return (vbyte*)buffer;
		#else
		return NULL;
		#endif

	}


	void lime_gl_get_active_uniformsiv (int program, value uniformIndices, int pname, double params) {

		#ifdef LIME_GLES3_API
		GLsizei size = val_array_size (uniformIndices);
		GLenum *_uniformIndices = (GLenum*)alloca (size * sizeof(GLenum));

		for (int i = 0; i < size; i++) {

			_uniformIndices[i] = val_int (val_array_i (uniformIndices, i));

		}

		glGetActiveUniformsiv (program, size, _uniformIndices, pname, (GLint*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_active_uniformsiv) (int program, hl_varray* uniformIndices, int pname, double params) {

		#ifdef LIME_GLES3_API
		GLsizei size = uniformIndices->size;
		glGetActiveUniformsiv (program, size, (GLenum*)hl_aptr (uniformIndices, int), pname, (GLint*)(uintptr_t)params);
		#endif

	}


	value lime_gl_get_attached_shaders (int program) {

		GLsizei maxCount = 0;
		glGetProgramiv (program, GL_ATTACHED_SHADERS, &maxCount);

		if (!maxCount) {

			return alloc_null ();

		}

		GLsizei count;
		GLuint* shaders = new GLuint[maxCount];

		glGetAttachedShaders (program, maxCount, &count, shaders);

		value data = alloc_array (maxCount);

		for (int i = 0; i < maxCount; i++) {

			val_array_set_i (data, i, alloc_int (shaders[i]));

		}

		delete[] shaders;
		return data;

	}


	HL_PRIM varray* HL_NAME(hl_gl_get_attached_shaders) (int program) {

		GLsizei maxCount = 0;
		glGetProgramiv (program, GL_ATTACHED_SHADERS, &maxCount);

		if (!maxCount) {

			return NULL;

		}

		GLsizei count;
		varray* data = hl_alloc_array (&hlt_i32, maxCount);

		glGetAttachedShaders (program, maxCount, &count, (GLuint*)hl_aptr (data, int));

		return data;

	}


	int lime_gl_get_attrib_location (int program, HxString name) {

		return glGetAttribLocation (program, name.__s);

	}


	HL_PRIM int HL_NAME(hl_gl_get_attrib_location) (int program, hl_vstring* name) {

		return glGetAttribLocation (program, name ? hl_to_utf8 (name->bytes) : NULL);

	}


	bool lime_gl_get_boolean (int pname) {

		unsigned char params;
		glGetBooleanv (pname, &params);
		return params;

	}


	HL_PRIM bool HL_NAME(hl_gl_get_boolean) (int pname) {

		unsigned char params;
		glGetBooleanv (pname, &params);
		return params;

	}


	void lime_gl_get_booleanv (int pname, double params) {

		glGetBooleanv (pname, (unsigned char*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_booleanv) (int pname, double params) {

		glGetBooleanv (pname, (unsigned char*)(uintptr_t)params);

	}


	int lime_gl_get_buffer_parameteri (int target, int index) {

		GLint params = 0;
		glGetBufferParameteriv (target, index, &params);
		return params;

	}


	HL_PRIM int HL_NAME(hl_gl_get_buffer_parameteri) (int target, int index) {

		GLint params = 0;
		glGetBufferParameteriv (target, index, &params);
		return params;

	}


	void lime_gl_get_buffer_parameteri64v (int target, int index, double params) {

		#ifdef LIME_GLES3_API
		glGetBufferParameteri64v (target, index, (GLint64*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_buffer_parameteri64v) (int target, int index, double params) {

		#ifdef LIME_GLES3_API
		glGetBufferParameteri64v (target, index, (GLint64*)(uintptr_t)params);
		#endif

	}


	void lime_gl_get_buffer_parameteriv (int target, int index, double params) {

		glGetBufferParameteriv (target, index, (GLint*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_buffer_parameteriv) (int target, int index, double params) {

		glGetBufferParameteriv (target, index, (GLint*)(uintptr_t)params);

	}


	double lime_gl_get_buffer_pointerv (int target, int pname) {

		uintptr_t result = 0;
		#ifdef LIME_GLES3_API
		glGetBufferPointerv (target, pname, (void**)result);
		#endif
		return (double)result;

	}


	HL_PRIM double HL_NAME(hl_gl_get_buffer_pointerv) (int target, int pname) {

		uintptr_t result = 0;
		#ifdef LIME_GLES3_API
		glGetBufferPointerv (target, pname, (void**)result);
		#endif
		return (double)result;

	}


	void lime_gl_get_buffer_sub_data (int target, double offset, int size, double data) {

		#ifndef LIME_GLES
		glGetBufferSubData (target, (GLintptr)(uintptr_t)offset, size, (void*)(uintptr_t)data);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_buffer_sub_data) (int target, double offset, int size, double data) {

		#ifndef LIME_GLES
		glGetBufferSubData (target, (GLintptr)(uintptr_t)offset, size, (void*)(uintptr_t)data);
		#endif

	}


	value lime_gl_get_context_attributes () {

		value result = alloc_empty_object ();

		alloc_field (result, val_id ("alpha"), alloc_bool (true));
		alloc_field (result, val_id ("depth"), alloc_bool (true));
		alloc_field (result, val_id ("stencil"), alloc_bool (true));
		alloc_field (result, val_id ("antialias"), alloc_bool (true));

		return result;

	}


	HL_PRIM vdynamic* HL_NAME(hl_gl_get_context_attributes) () {

		const int id_alpha = hl_hash_utf8 ("alpha");
		const int id_depth = hl_hash_utf8 ("depth");
		const int id_stencil = hl_hash_utf8 ("stencil");
		const int id_antialias = hl_hash_utf8 ("antialias");

		// TODO: Handle if depth and stencil are disabled

		vdynamic *result = (vdynamic*)hl_alloc_dynobj();
		hl_dyn_seti (result, id_alpha, &hlt_bool, true);
		hl_dyn_seti (result, id_depth, &hlt_bool, true);
		hl_dyn_seti (result, id_stencil, &hlt_bool, true);
		hl_dyn_seti (result, id_antialias, &hlt_bool, true);

		return result;

	}


	int lime_gl_get_error () {

		return glGetError ();

	}


	HL_PRIM int HL_NAME(hl_gl_get_error) () {

		return glGetError ();

	}


	value lime_gl_get_extension (HxString name) {

		#if (defined (HX_LINUX) || defined (HX_WINDOWS) || defined (HX_MACOS)) && !defined (NATIVE_TOOLKIT_SDL_ANGLE) && !defined (RASPBERRYPI)
		if (!glDebugMessageCallback_ptr && strcmp (name.__s, "KHR_debug") == 0) {

			glDebugMessageCallback_ptr = (GL_DebugMessageCallback_Func)SDL_GL_GetProcAddress ("glDebugMessageCallback");

			if (!glDebugMessageCallback_ptr) {

				glDebugMessageCallback_ptr = (GL_DebugMessageCallback_Func)SDL_GL_GetProcAddress ("glDebugMessageCallbackKHR");

			}

			if (glDebugMessageCallback_ptr) {

				glDebugMessageCallback_ptr ((GLDEBUGPROCARB)gl_debug_callback, NULL);

			}

		}
		#endif

		// void *result = 0;

		// #ifdef LIME_SDL
		// result = SDL_GL_GetProcAddress (name.__s);
		// #endif

		// if (result) {

		// 	static bool init = false;
		// 	static vkind functionKind;

		// 	if (!init) {

		// 		init = true;
		// 		kind_share (&functionKind, "function");

		// 	}

		// 	return alloc_abstract (functionKind, result);

		// }

		return alloc_null ();

	}


	HL_PRIM vdynamic* HL_NAME(hl_gl_get_extension) (hl_vstring* name) {

		if (name == NULL) return NULL;

		#if (defined (HX_LINUX) || defined (HX_WINDOWS) || defined (HX_MACOS)) && !defined (NATIVE_TOOLKIT_SDL_ANGLE) && !defined (RASPBERRYPI)
		if (!glDebugMessageCallback_ptr && strcmp (hl_to_utf8 (name->bytes), "KHR_debug") == 0) {

			glDebugMessageCallback_ptr = (GL_DebugMessageCallback_Func)SDL_GL_GetProcAddress ("glDebugMessageCallback");

			if (!glDebugMessageCallback_ptr) {

				glDebugMessageCallback_ptr = (GL_DebugMessageCallback_Func)SDL_GL_GetProcAddress ("glDebugMessageCallbackKHR");

			}

			if (glDebugMessageCallback_ptr) {

				glDebugMessageCallback_ptr ((GLDEBUGPROCARB)gl_debug_callback, NULL);

			}

		}
		#endif

		// void *result = 0;

		// #ifdef LIME_SDL
		// result = SDL_GL_GetProcAddress (name.__s);
		// #endif

		// if (result) {

		// 	static bool init = false;
		// 	static vkind functionKind;

		// 	if (!init) {

		// 		init = true;
		// 		kind_share (&functionKind, "function");

		// 	}

		// 	return alloc_abstract (functionKind, result);

		// }

		return NULL;

	}


	float lime_gl_get_float (int pname) {

		GLfloat params;
		glGetFloatv (pname, &params);
		return params;

	}


	HL_PRIM float HL_NAME(hl_gl_get_float) (int pname) {

		GLfloat params;
		glGetFloatv (pname, &params);
		return params;

	}


	void lime_gl_get_floatv (int pname, double params) {

		glGetFloatv (pname, (GLfloat*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_floatv) (int pname, double params) {

		glGetFloatv (pname, (GLfloat*)(uintptr_t)params);

	}


	int lime_gl_get_frag_data_location (int program, HxString name) {

		#ifdef LIME_GLES3_API
		return glGetFragDataLocation (program, name.__s);
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_gl_get_frag_data_location) (int program, hl_vstring* name) {

		#ifdef LIME_GLES3_API
		return glGetFragDataLocation (program, name ? hl_to_utf8 (name->bytes) : NULL);
		#else
		return 0;
		#endif

	}


	int lime_gl_get_framebuffer_attachment_parameteri (int target, int attachment, int pname) {

		GLint params = 0;
		glGetFramebufferAttachmentParameteriv (target, attachment, pname, &params);
		return params;

	}


	HL_PRIM int HL_NAME(hl_gl_get_framebuffer_attachment_parameteri) (int target, int attachment, int pname) {

		GLint params = 0;
		glGetFramebufferAttachmentParameteriv (target, attachment, pname, &params);
		return params;

	}


	void lime_gl_get_framebuffer_attachment_parameteriv (int target, int attachment, int pname, double params) {

		glGetFramebufferAttachmentParameteriv (target, attachment, pname, (GLint*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_framebuffer_attachment_parameteriv) (int target, int attachment, int pname, double params) {

		glGetFramebufferAttachmentParameteriv (target, attachment, pname, (GLint*)(uintptr_t)params);

	}


	int lime_gl_get_integer (int pname) {

		GLint params;
		glGetIntegerv (pname, &params);
		return params;

	}


	HL_PRIM int HL_NAME(hl_gl_get_integer) (int pname) {

		GLint params;
		glGetIntegerv (pname, &params);
		return params;

	}


	void lime_gl_get_integer64v (int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetInteger64v (pname, (GLint64*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_integer64v) (int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetInteger64v (pname, (GLint64*)(uintptr_t)params);
		#endif

	}


	void lime_gl_get_integer64i_v (int pname, int index, double params) {

		#ifdef LIME_GLES3_API
		glGetInteger64i_v (pname, index, (GLint64*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_integer64i_v) (int pname, int index, double params) {

		#ifdef LIME_GLES3_API
		glGetInteger64i_v (pname, index, (GLint64*)(uintptr_t)params);
		#endif

	}


	void lime_gl_get_integerv (int pname, double params) {

		glGetIntegerv (pname, (GLint*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_integerv) (int pname, double params) {

		glGetIntegerv (pname, (GLint*)(uintptr_t)params);

	}


	void lime_gl_get_integeri_v (int pname, int index, double params) {

		#ifdef LIME_GLES3_API
		glGetIntegeri_v (pname, index, (GLint*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_integeri_v) (int pname, int index, double params) {

		#ifdef LIME_GLES3_API
		glGetIntegeri_v (pname, index, (GLint*)(uintptr_t)params);
		#endif

	}


	void lime_gl_get_internalformativ (int target, int internalformat, int pname, int bufSize, double params) {

		#ifdef LIME_GLES3_API
		glGetInternalformativ (target, internalformat, pname, (GLsizei)bufSize, (GLint*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_internalformativ) (int target, int internalformat, int pname, int bufSize, double params) {

		#ifdef LIME_GLES3_API
		glGetInternalformativ (target, internalformat, pname, (GLsizei)bufSize, (GLint*)(uintptr_t)params);
		#endif

	}


	void lime_gl_get_program_binary (int program, int binaryFormat, value bytes) {

		#ifdef LIME_GLES3_API
		GLint size = 0;
		glGetProgramiv (program, GL_PROGRAM_BINARY_LENGTH, &size);

		if (size > 0) {

			Bytes _bytes (bytes);
			_bytes.Resize (size);

			glGetProgramBinary (program, size, &size, (GLenum*)&binaryFormat, _bytes.b);

		}
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_program_binary) (int program, int binaryFormat, Bytes* bytes) {

		#ifdef LIME_GLES3_API
		GLint size = 0;
		glGetProgramiv (program, GL_PROGRAM_BINARY_LENGTH, &size);

		if (size > 0) {

			bytes->Resize (size);

			glGetProgramBinary (program, size, &size, (GLenum*)&binaryFormat, bytes->b);

		}
		#endif

	}


	value lime_gl_get_program_info_log (int handle) {

		GLuint program = handle;

		GLint logSize = 0;
		glGetProgramiv (program, GL_INFO_LOG_LENGTH, &logSize);

		if (logSize == 0) {

			return alloc_null ();

		}

		std::string buffer (logSize, 0);

		glGetProgramInfoLog (program, logSize, 0, &buffer[0]);

		return alloc_string (buffer.c_str ());

	}


	HL_PRIM vbyte* HL_NAME(hl_gl_get_program_info_log) (int handle) {

		GLuint program = handle;

		GLint logSize = 0;
		glGetProgramiv (program, GL_INFO_LOG_LENGTH, &logSize);

		if (logSize == 0) {

			return NULL;

		}

		char* buffer = (char*)malloc (logSize + 1);

		glGetProgramInfoLog (program, logSize, 0, buffer);

		buffer[logSize] = '\0';
		return (vbyte*)buffer;

	}


	int lime_gl_get_programi (int program, int pname) {

		GLint params = 0;
		glGetProgramiv (program, pname, &params);
		return params;

	}


	HL_PRIM int HL_NAME(hl_gl_get_programi) (int program, int pname) {

		GLint params = 0;
		glGetProgramiv (program, pname, &params);
		return params;

	}


	void lime_gl_get_programiv (int program, int pname, double params) {

		glGetProgramiv (program, pname, (GLint*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_programiv) (int program, int pname, double params) {

		glGetProgramiv (program, pname, (GLint*)(uintptr_t)params);

	}


	int lime_gl_get_queryi (int target, int pname) {

		GLint param = 0;
		#ifdef LIME_GLES3_API
		glGetQueryiv (target, pname, &param);
		#endif
		return param;

	}


	HL_PRIM int HL_NAME(hl_gl_get_queryi) (int target, int pname) {

		GLint param = 0;
		#ifdef LIME_GLES3_API
		glGetQueryiv (target, pname, &param);
		#endif
		return param;

	}


	void lime_gl_get_queryiv (int target, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetQueryiv (target, pname, (GLint*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_queryiv) (int target, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetQueryiv (target, pname, (GLint*)(uintptr_t)params);
		#endif

	}


	int lime_gl_get_query_objectui (int query, int pname) {

		GLuint param = 0;
		#ifdef LIME_GLES3_API
		glGetQueryObjectuiv (query, pname, &param);
		#endif
		return param;

	}


	HL_PRIM int HL_NAME(hl_gl_get_query_objectui) (int query, int pname) {

		GLuint param = 0;
		#ifdef LIME_GLES3_API
		glGetQueryObjectuiv (query, pname, &param);
		#endif
		return param;

	}


	void lime_gl_get_query_objectuiv (int query, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetQueryObjectuiv (query, pname, (GLuint*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_query_objectuiv) (int query, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetQueryObjectuiv (query, pname, (GLuint*)(uintptr_t)params);
		#endif

	}


	int lime_gl_get_renderbuffer_parameteri (int target, int pname) {

		GLint param = 0;
		glGetRenderbufferParameteriv (target, pname, &param);
		return param;

	}


	HL_PRIM int HL_NAME(hl_gl_get_renderbuffer_parameteri) (int target, int pname) {

		GLint param = 0;
		glGetRenderbufferParameteriv (target, pname, &param);
		return param;

	}


	void lime_gl_get_renderbuffer_parameteriv (int target, int pname, double params) {

		glGetRenderbufferParameteriv (target, pname, (GLint*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_renderbuffer_parameteriv) (int target, int pname, double params) {

		glGetRenderbufferParameteriv (target, pname, (GLint*)(uintptr_t)params);

	}


	float lime_gl_get_sampler_parameterf (int sampler, int pname) {

		GLfloat param = 0;
		#ifdef LIME_GLES3_API
		glGetSamplerParameterfv (sampler, pname, &param);
		#endif
		return param;

	}


	HL_PRIM float HL_NAME(hl_gl_get_sampler_parameterf) (int sampler, int pname) {

		GLfloat param = 0;
		#ifdef LIME_GLES3_API
		glGetSamplerParameterfv (sampler, pname, &param);
		#endif
		return param;

	}


	void lime_gl_get_sampler_parameterfv (int sampler, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetSamplerParameterfv (sampler, pname, (GLfloat*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_sampler_parameterfv) (int sampler, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetSamplerParameterfv (sampler, pname, (GLfloat*)(uintptr_t)params);
		#endif

	}


	int lime_gl_get_sampler_parameteri (int sampler, int pname) {

		GLint param = 0;
		#ifdef LIME_GLES3_API
		glGetSamplerParameteriv (sampler, pname, &param);
		#endif
		return param;

	}


	HL_PRIM int HL_NAME(hl_gl_get_sampler_parameteri) (int sampler, int pname) {

		GLint param = 0;
		#ifdef LIME_GLES3_API
		glGetSamplerParameteriv (sampler, pname, &param);
		#endif
		return param;

	}


	void lime_gl_get_sampler_parameteriv (int sampler, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetSamplerParameteriv (sampler, pname, (GLint*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_sampler_parameteriv) (int sampler, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetSamplerParameteriv (sampler, pname, (GLint*)(uintptr_t)params);
		#endif

	}


	value lime_gl_get_shader_info_log (int handle) {

		GLuint shader = handle;

		GLint logSize = 0;
		glGetShaderiv (shader, GL_INFO_LOG_LENGTH, &logSize);

		if (logSize == 0) {

			return alloc_null ();

		}

		std::string buffer (logSize, 0);
		GLint writeSize;
		glGetShaderInfoLog (shader, logSize, &writeSize, &buffer[0]);

		return alloc_string (buffer.c_str ());

	}


	HL_PRIM vbyte* HL_NAME(hl_gl_get_shader_info_log) (int handle) {

		GLuint shader = handle;

		GLint logSize = 0;
		glGetShaderiv (shader, GL_INFO_LOG_LENGTH, &logSize);

		if (logSize == 0) {

			return NULL;

		}

		char* buffer = (char*)malloc (logSize + 1);
		GLint writeSize;
		glGetShaderInfoLog (shader, logSize, &writeSize, buffer);

		buffer[logSize] = '\0';
		return (vbyte*)buffer;

	}


	int lime_gl_get_shaderi (int shader, int pname) {

		GLint params = 0;
		glGetShaderiv (shader, pname, &params);
		return params;

	}


	HL_PRIM int HL_NAME(hl_gl_get_shaderi) (int shader, int pname) {

		GLint params = 0;
		glGetShaderiv (shader, pname, &params);
		return params;

	}


	void lime_gl_get_shaderiv (int shader, int pname, double params) {

		glGetShaderiv (shader, pname, (GLint*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_shaderiv) (int shader, int pname, double params) {

		glGetShaderiv (shader, pname, (GLint*)(uintptr_t)params);

	}


	value lime_gl_get_shader_precision_format (int shadertype, int precisiontype) {

		#ifdef LIME_GLES

		GLint range[2];
		GLint precision;

		glGetShaderPrecisionFormat (shadertype, precisiontype, range, &precision);

		value result = alloc_empty_object ();
		alloc_field (result, val_id ("rangeMin"), alloc_int (range[0]));
		alloc_field (result, val_id ("rangeMax"), alloc_int (range[1]));
		alloc_field (result, val_id ("precision"), alloc_int (precision));
		return result;

		#else

		return alloc_null ();

		#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_gl_get_shader_precision_format) (int shadertype, int precisiontype) {

		#ifdef LIME_GLES

		GLint range[2];
		GLint precision;

		glGetShaderPrecisionFormat (shadertype, precisiontype, range, &precision);

		const int id_rangeMin = hl_hash_utf8 ("rangeMin");
		const int id_rangeMax = hl_hash_utf8 ("rangeMax");
		const int id_precision = hl_hash_utf8 ("precision");

		vdynamic *result = (vdynamic*)hl_alloc_dynobj();
		hl_dyn_seti (result, id_rangeMin, &hlt_i32, range[0]);
		hl_dyn_seti (result, id_rangeMax, &hlt_i32, range[1]);
		hl_dyn_seti (result, id_precision, &hlt_i32, precision);
		return result;

		#else

		return NULL;

		#endif

	}


	value lime_gl_get_shader_source (int shader) {

		GLint len = 0;
		glGetShaderiv (shader, GL_SHADER_SOURCE_LENGTH, &len);

		if (len == 0) {

			return alloc_null ();

		}

		char *buf = new char[len + 1];
		glGetShaderSource (shader, len + 1, 0, buf);
		value result = alloc_string (buf);

		delete [] buf;

		return result;

	}


	HL_PRIM vbyte* HL_NAME(hl_gl_get_shader_source) (int shader) {

		GLint len = 0;
		glGetShaderiv (shader, GL_SHADER_SOURCE_LENGTH, &len);

		if (len == 0) {

			return NULL;

		}

		char *result = new char[len + 1];
		glGetShaderSource (shader, len, 0, result);

		result[len] = '\0';
		return (vbyte*)result;

	}


	value lime_gl_get_string (int pname) {

		const char* val = (const char*)glGetString (pname);

		if (val) {

			return alloc_string (val);

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM vbyte* HL_NAME(hl_gl_get_string) (int pname) {

		const char* val = (const char*)glGetString (pname);

		if (val) {

			int size = strlen (val);
			char* result = (char*)malloc (size + 1);
			memcpy (result, val, size);
			result[size] = '\0';
			return (vbyte*)result;

		} else {

			return NULL;

		}

	}


	value lime_gl_get_stringi (int pname, int index) {

		#ifdef LIME_GLES3_API
		const char* val = (const char*)glGetStringi (pname, index);

		if (val) {

			return alloc_string (val);

		} else {

			return alloc_null ();

		}
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM vbyte* HL_NAME(hl_gl_get_stringi) (int pname, int index) {

		#ifdef LIME_GLES3_API
		const char* val = (const char*)glGetStringi (pname, index);

		if (val) {

			int size = strlen (val);
			char* result = (char*)malloc (size + 1);
			memcpy (result, val, size);
			result[size] = '\0';
			return (vbyte*)result;

		} else {

			return NULL;

		}
		#else
		return NULL;
		#endif

	}


	int lime_gl_get_sync_parameteri (value sync, int pname) {

		// TODO

		GLint param = 0;
		//glGetSynciv ((GLsync)(uintptr_t)sync, pname, &param);
		return param;

	}


	HL_PRIM int HL_NAME(hl_gl_get_sync_parameteri) (HL_CFFIPointer* sync, int pname) {

		// TODO

		GLint param = 0;
		//glGetSynciv ((GLsync)(uintptr_t)sync, pname, &param);
		return param;

	}


	void lime_gl_get_sync_parameteriv (value sync, int pname, double params) {

		// TODO

		//glGetSynciv ((GLsync)(uintptr_t)sync, pname, (GLint*)(uintptr_t)param);

	}


	HL_PRIM void HL_NAME(hl_gl_get_sync_parameteriv) (HL_CFFIPointer* sync, int pname, double params) {

		// TODO

		//glGetSynciv ((GLsync)(uintptr_t)sync, pname, (GLint*)(uintptr_t)param);

	}


	float lime_gl_get_tex_parameterf (int target, int pname) {

		GLfloat params = 0;
		glGetTexParameterfv (target, pname, &params);
		return params;

	}


	HL_PRIM float HL_NAME(hl_gl_get_tex_parameterf) (int target, int pname) {

		GLfloat params = 0;
		glGetTexParameterfv (target, pname, &params);
		return params;

	}


	void lime_gl_get_tex_parameterfv (int target, int pname, double params) {

		glGetTexParameterfv (target, pname, (GLfloat*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_tex_parameterfv) (int target, int pname, double params) {

		glGetTexParameterfv (target, pname, (GLfloat*)(uintptr_t)params);

	}


	int lime_gl_get_tex_parameteri (int target, int pname) {

		GLint params = 0;
		glGetTexParameteriv (target, pname, &params);
		return params;

	}


	HL_PRIM int HL_NAME(hl_gl_get_tex_parameteri) (int target, int pname) {

		GLint params = 0;
		glGetTexParameteriv (target, pname, &params);
		return params;

	}


	void lime_gl_get_tex_parameteriv (int target, int pname, double params) {

		glGetTexParameteriv (target, pname, (GLint*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_tex_parameteriv) (int target, int pname, double params) {

		glGetTexParameteriv (target, pname, (GLint*)(uintptr_t)params);

	}


	value lime_gl_get_transform_feedback_varying (int program, int index) {

		#ifdef LIME_GLES3_API
		value result = alloc_empty_object ();

		GLint maxLength = 0;
		glGetProgramiv (program, GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH, &maxLength);

		GLsizei outLen = 0;
		GLsizei size = 0;
		GLenum type = 0;

		std::string buffer (maxLength, 0);

		glGetTransformFeedbackVarying (program, index, maxLength, &outLen, &size, &type, &buffer[0]);

		buffer.resize (outLen);

		alloc_field (result, val_id ("size"), alloc_int (size));
		alloc_field (result, val_id ("type"), alloc_int (type));
		alloc_field (result, val_id ("name"), alloc_string (buffer.c_str ()));

		return result;
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_gl_get_transform_feedback_varying) (int program, int index) {

		#ifdef LIME_GLES3_API
		GLint maxLength = 0;
		glGetProgramiv (program, GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH, &maxLength);

		GLsizei outLen = 0;
		GLsizei size = 0;
		GLenum type = 0;

		char* buffer = (char*)malloc (maxLength);

		glGetTransformFeedbackVarying (program, index, maxLength, &outLen, &size, &type, buffer);

		char* _buffer = (char*)malloc (outLen + 1);
		memcpy (_buffer, &buffer, outLen);
		_buffer[outLen] = '\0';

		const int id_size = hl_hash_utf8 ("size");
		const int id_type = hl_hash_utf8 ("type");
		const int id_name = hl_hash_utf8 ("name");

		vdynamic *result = (vdynamic*)hl_alloc_dynobj();
		hl_dyn_seti (result, id_size, &hlt_i32, size);
		hl_dyn_seti (result, id_type, &hlt_i32, type);
		hl_dyn_setp (result, id_name, &hlt_bytes, _buffer);

		return result;
		#else
		return NULL;
		#endif

	}


	float lime_gl_get_uniformf (int program, int location) {

		GLfloat params = 0;
		glGetUniformfv (program, location, &params);
		return params;

	}


	HL_PRIM float HL_NAME(hl_gl_get_uniformf) (int program, int location) {

		GLfloat params = 0;
		glGetUniformfv (program, location, &params);
		return params;

	}


	void lime_gl_get_uniformfv (int program, int location, double params) {

		glGetUniformfv (program, location, (GLfloat*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_uniformfv) (int program, int location, double params) {

		glGetUniformfv (program, location, (GLfloat*)(uintptr_t)params);

	}


	int lime_gl_get_uniformi (int program, int location) {

		GLint params = 0;
		glGetUniformiv (program, location, &params);
		return params;

	}


	HL_PRIM int HL_NAME(hl_gl_get_uniformi) (int program, int location) {

		GLint params = 0;
		glGetUniformiv (program, location, &params);
		return params;

	}


	void lime_gl_get_uniformiv (int program, int location, double params) {

		glGetUniformiv (program, location, (GLint*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_uniformiv) (int program, int location, double params) {

		glGetUniformiv (program, location, (GLint*)(uintptr_t)params);

	}


	int lime_gl_get_uniformui (int program, int location) {

		GLuint params = 0;
		#ifdef LIME_GLES3_API
		glGetUniformuiv (program, location, &params);
		#endif
		return params;

	}


	HL_PRIM int HL_NAME(hl_gl_get_uniformui) (int program, int location) {

		GLuint params = 0;
		#ifdef LIME_GLES3_API
		glGetUniformuiv (program, location, &params);
		#endif
		return params;

	}


	void lime_gl_get_uniformuiv (int program, int location, double params) {

		#ifdef LIME_GLES3_API
		glGetUniformuiv (program, location, (GLuint*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_uniformuiv) (int program, int location, double params) {

		#ifdef LIME_GLES3_API
		glGetUniformuiv (program, location, (GLuint*)(uintptr_t)params);
		#endif

	}


	int lime_gl_get_uniform_block_index (int program, HxString uniformBlockName) {

		#ifdef LIME_GLES3_API
		return glGetUniformBlockIndex (program, uniformBlockName.__s);
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_gl_get_uniform_block_index) (int program, hl_vstring* uniformBlockName) {

		#ifdef LIME_GLES3_API
		return glGetUniformBlockIndex (program, uniformBlockName ? hl_to_utf8 (uniformBlockName->bytes) : NULL);
		#else
		return 0;
		#endif

	}


	int lime_gl_get_uniform_location (int program, HxString name) {

		return glGetUniformLocation (program, name.__s);

	}


	HL_PRIM int HL_NAME(hl_gl_get_uniform_location) (int program, hl_vstring* name) {

		return glGetUniformLocation (program, name ? hl_to_utf8 (name->bytes) : NULL);

	}


	float lime_gl_get_vertex_attribf (int index, int pname) {

		GLfloat params = 0;
		glGetVertexAttribfv (index, pname, &params);
		return params;

	}


	HL_PRIM float HL_NAME(hl_gl_get_vertex_attribf) (int index, int pname) {

		GLfloat params = 0;
		glGetVertexAttribfv (index, pname, &params);
		return params;

	}


	void lime_gl_get_vertex_attribfv (int index, int pname, double params) {

		glGetVertexAttribfv (index, pname, (GLfloat*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_vertex_attribfv) (int index, int pname, double params) {

		glGetVertexAttribfv (index, pname, (GLfloat*)(uintptr_t)params);

	}


	int lime_gl_get_vertex_attribi (int index, int pname) {

		GLint params = 0;
		glGetVertexAttribiv (index, pname, &params);
		return params;

	}


	HL_PRIM int HL_NAME(hl_gl_get_vertex_attribi) (int index, int pname) {

		GLint params = 0;
		glGetVertexAttribiv (index, pname, &params);
		return params;

	}


	void lime_gl_get_vertex_attribiv (int index, int pname, double params) {

		glGetVertexAttribiv (index, pname, (GLint*)(uintptr_t)params);

	}


	HL_PRIM void HL_NAME(hl_gl_get_vertex_attribiv) (int index, int pname, double params) {

		glGetVertexAttribiv (index, pname, (GLint*)(uintptr_t)params);

	}


	int lime_gl_get_vertex_attribii (int index, int pname) {

		GLint params = 0;
		#ifdef LIME_GLES3_API
		glGetVertexAttribIiv (index, pname, &params);
		#endif
		return params;

	}


	HL_PRIM int HL_NAME(hl_gl_get_vertex_attribii) (int index, int pname) {

		GLint params = 0;
		#ifdef LIME_GLES3_API
		glGetVertexAttribIiv (index, pname, &params);
		#endif
		return params;

	}


	void lime_gl_get_vertex_attribiiv (int index, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetVertexAttribIiv (index, pname, (GLint*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_vertex_attribiiv) (int index, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetVertexAttribIiv (index, pname, (GLint*)(uintptr_t)params);
		#endif

	}


	int lime_gl_get_vertex_attribiui (int index, int pname) {

		GLuint params = 0;
		#ifdef LIME_GLES3_API
		glGetVertexAttribIuiv (index, pname, &params);
		#endif
		return params;

	}


	HL_PRIM int HL_NAME(hl_gl_get_vertex_attribiui) (int index, int pname) {

		GLuint params = 0;
		#ifdef LIME_GLES3_API
		glGetVertexAttribIuiv (index, pname, &params);
		#endif
		return params;

	}


	void lime_gl_get_vertex_attribiuiv (int index, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetVertexAttribIuiv (index, pname, (GLuint*)(uintptr_t)params);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_get_vertex_attribiuiv) (int index, int pname, double params) {

		#ifdef LIME_GLES3_API
		glGetVertexAttribIuiv (index, pname, (GLuint*)(uintptr_t)params);
		#endif

	}


	double lime_gl_get_vertex_attrib_pointerv (int index, int pname) {

		uintptr_t result = 0;
		glGetVertexAttribPointerv (index, pname, (void**)result);
		return (double)result;

	}


	HL_PRIM double HL_NAME(hl_gl_get_vertex_attrib_pointerv) (int index, int pname) {

		uintptr_t result = 0;
		glGetVertexAttribPointerv (index, pname, (void**)result);
		return (double)result;

	}


	void lime_gl_hint (int target, int mode) {

		glHint (target, mode);

	}


	HL_PRIM void HL_NAME(hl_gl_hint) (int target, int mode) {

		glHint (target, mode);

	}


	void lime_gl_invalidate_framebuffer (int target, value attachments) {

		#ifdef LIME_GLES3_API
		GLint size = val_array_size (attachments);
		GLenum *_attachments = (GLenum*)alloca (size * sizeof(GLenum));

		for (int i = 0; i < size; i++) {

			_attachments[i] = val_int (val_array_i (attachments, i));

		}

		glInvalidateFramebuffer (target, size, _attachments);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_invalidate_framebuffer) (int target, varray* attachments) {

		#ifdef LIME_GLES3_API
		GLint size = attachments->size;
		glInvalidateFramebuffer (target, size, (GLenum*)hl_aptr (attachments, int));
		#endif

	}


	void lime_gl_invalidate_sub_framebuffer (int target, value attachments, int x, int y, int width, int height) {

		#ifdef LIME_GLES3_API
		GLint size = val_array_size (attachments);
		GLenum *_attachments = (GLenum*)alloca (size * sizeof(GLenum));

		for (int i = 0; i < size; i++) {

			_attachments[i] = val_int (val_array_i (attachments, i));

		}

		glInvalidateSubFramebuffer (target, size, _attachments, x, y, width, height);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_invalidate_sub_framebuffer) (int target, varray* attachments, int x, int y, int width, int height) {

		#ifdef LIME_GLES3_API
		GLint size = attachments->size;
		glInvalidateSubFramebuffer (target, size, (GLenum*)hl_aptr (attachments, int), x, y, width, height);
		#endif

	}


	bool lime_gl_is_buffer (int handle) {

		return glIsBuffer (handle);

	}


	HL_PRIM bool HL_NAME(hl_gl_is_buffer) (int handle) {

		return glIsBuffer (handle);

	}


	bool lime_gl_is_enabled (int cap) {

		return glIsEnabled (cap);

	}


	HL_PRIM bool HL_NAME(hl_gl_is_enabled) (int cap) {

		return glIsEnabled (cap);

	}


	bool lime_gl_is_framebuffer (int handle) {

		return glIsFramebuffer (handle);

	}


	HL_PRIM bool HL_NAME(hl_gl_is_framebuffer) (int handle) {

		return glIsFramebuffer (handle);

	}


	bool lime_gl_is_program (int handle) {

		return glIsProgram (handle);

	}


	HL_PRIM bool HL_NAME(hl_gl_is_program) (int handle) {

		return glIsProgram (handle);

	}


	bool lime_gl_is_query (int handle) {

		#ifdef LIME_GLES3_API
		return glIsQuery (handle);
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_gl_is_query) (int handle) {

		#ifdef LIME_GLES3_API
		return glIsQuery (handle);
		#else
		return false;
		#endif

	}


	bool lime_gl_is_renderbuffer (int handle) {

		return glIsRenderbuffer (handle);

	}


	HL_PRIM bool HL_NAME(hl_gl_is_renderbuffer) (int handle) {

		return glIsRenderbuffer (handle);

	}


	bool lime_gl_is_sampler (int handle) {

		#ifdef LIME_GLES3_API
		return glIsSampler (handle);
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_gl_is_sampler) (int handle) {

		#ifdef LIME_GLES3_API
		return glIsSampler (handle);
		#else
		return false;
		#endif

	}


	bool lime_gl_is_shader (int handle) {

		return glIsShader (handle);

	}


	HL_PRIM bool HL_NAME(hl_gl_is_shader) (int handle) {

		return glIsShader (handle);

	}


	bool lime_gl_is_sync (value handle) {

		#ifdef LIME_GLES3_API
		if (val_is_null (handle)) return false;
		return glIsSync ((GLsync)val_data (handle));
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_gl_is_sync) (HL_CFFIPointer* handle) {

		#ifdef LIME_GLES3_API
		if (!handle) return false;
		return glIsSync ((GLsync)handle->ptr);
		#else
		return false;
		#endif

	}


	bool lime_gl_is_texture (int handle) {

		return glIsTexture (handle);

	}


	HL_PRIM bool HL_NAME(hl_gl_is_texture) (int handle) {

		return glIsTexture (handle);

	}


	bool lime_gl_is_transform_feedback (int handle) {

		#ifdef LIME_GLES3_API
		return glIsTransformFeedback (handle);
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_gl_is_transform_feedback) (int handle) {

		#ifdef LIME_GLES3_API
		return glIsTransformFeedback (handle);
		#else
		return false;
		#endif

	}


	bool lime_gl_is_vertex_array (int handle) {

		#ifdef LIME_GLES3_API
		return glIsQuery (handle);
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_gl_is_vertex_array) (int handle) {

		#ifdef LIME_GLES3_API
		return glIsQuery (handle);
		#else
		return false;
		#endif

	}


	void lime_gl_line_width (float width) {

		glLineWidth (width);

	}


	HL_PRIM void HL_NAME(hl_gl_line_width) (float width) {

		glLineWidth (width);

	}


	void lime_gl_link_program (int program) {

		glLinkProgram (program);

	}


	HL_PRIM void HL_NAME(hl_gl_link_program) (int program) {

		glLinkProgram (program);

	}


	double lime_gl_map_buffer_range (int target, double offset, int length, int access) {

		#ifdef LIME_GLES3_API
		uintptr_t result = (uintptr_t)glMapBufferRange (target, (GLintptr)(uintptr_t)offset, length, access);
		return (double)result;
		#else
		return 0;
		#endif

	}


	HL_PRIM double HL_NAME(hl_gl_map_buffer_range) (int target, double offset, int length, int access) {

		#ifdef LIME_GLES3_API
		uintptr_t result = (uintptr_t)glMapBufferRange (target, (GLintptr)(uintptr_t)offset, length, access);
		return (double)result;
		#else
		return 0;
		#endif

	}


	void lime_gl_object_deregister (value object) {

		if (glObjectIDs.find (object) != glObjectIDs.end ()) {

			GLuint id = glObjectIDs[object];
			GLObjectType type = glObjectTypes[object];

			glObjects[type].erase (id);
			glObjectTypes.erase (object);
			glObjectIDs.erase (object);

		}

		if (glObjectPtrs.find (object) != glObjectPtrs.end ()) {

			value handle = (value)glObjectPtrs[object];
			val_gc (handle, 0);
			glObjectPtrs.erase (object);

		}

	}


	HL_PRIM void HL_NAME(hl_gl_object_deregister) (void* object) {

		if (glObjectIDs.find (object) != glObjectIDs.end ()) {

			GLuint id = glObjectIDs[object];
			GLObjectType type = glObjectTypes[object];

			glObjects[type].erase (id);
			glObjectTypes.erase (object);
			glObjectIDs.erase (object);

		}

		if (glObjectPtrs.find (object) != glObjectPtrs.end ()) {

			HL_CFFIPointer* handle = (HL_CFFIPointer*)glObjectPtrs[object];
			handle->finalizer = NULL;
			//delete handle;
			glObjectPtrs.erase (object);

		}

	}


	value lime_gl_object_from_id (int id, int type) {

		GLObjectType _type = (GLObjectType)type;

		if (glObjects[_type].find (id) != glObjects[_type].end ()) {

			return (value)glObjects[_type][id];

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM void* HL_NAME(hl_gl_object_from_id) (int id, int type) {

		GLObjectType _type = (GLObjectType)type;

		if (glObjects[_type].find (id) != glObjects[_type].end ()) {

			return glObjects[_type][id];

		} else {

			return NULL;

		}

	}


	value lime_gl_object_register (int id, int type, value object) {

		GLObjectType _type = (GLObjectType)type;
		value handle = CFFIPointer (object, gc_gl_object);

		//if (glObjects[_type].find (id) != glObjects[_type].end ()) {
			//
			//value otherObject = glObjects[_type][id];
			//if (otherObject == object) return;
			//
			//glObjectTypes.erase (otherObject);
			//glObjectIDs.erase (object);
			//
			//val_gc (otherObject, 0);
			//
		//}

		glObjectTypes[object] = (GLObjectType)type;
		glObjectIDs[object] = id;
		glObjects[_type][id] = object;
		glObjectPtrs[object] = handle;

		return handle;

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_gl_object_register) (int id, int type, void* object) {

		GLObjectType _type = (GLObjectType)type;
		HL_CFFIPointer* handle = HLCFFIPointer ((vobj*)object, (hl_finalizer)gc_gl_object);

		//if (glObjects[_type].find (id) != glObjects[_type].end ()) {
			//
			//value otherObject = glObjects[_type][id];
			//if (otherObject == object) return;
			//
			//glObjectTypes.erase (otherObject);
			//glObjectIDs.erase (object);
			//
			//val_gc (otherObject, 0);
			//
		//}

		glObjectTypes[object] = (GLObjectType)type;
		glObjectIDs[object] = id;
		glObjects[_type][id] = object;
		glObjectPtrs[object] = handle;

		return handle;

	}


	void lime_gl_pause_transform_feedback () {

		#ifdef LIME_GLES3_API
		glPauseTransformFeedback ();
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_pause_transform_feedback) () {

		#ifdef LIME_GLES3_API
		glPauseTransformFeedback ();
		#endif

	}


	void lime_gl_pixel_storei (int pname, int param) {

		glPixelStorei (pname, param);

	}


	HL_PRIM void HL_NAME(hl_gl_pixel_storei) (int pname, int param) {

		glPixelStorei (pname, param);

	}


	void lime_gl_polygon_offset (float factor, float units) {

		glPolygonOffset (factor, units);

	}


	HL_PRIM void HL_NAME(hl_gl_polygon_offset) (float factor, float units) {

		glPolygonOffset (factor, units);

	}


	void lime_gl_program_binary (int program, int binaryFormat, double binary, int length) {

		#ifdef LIME_GLES3_API
		glProgramBinary (program, binaryFormat, (void*)(uintptr_t)binary, length);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_program_binary) (int program, int binaryFormat, double binary, int length) {

		#ifdef LIME_GLES3_API
		glProgramBinary (program, binaryFormat, (void*)(uintptr_t)binary, length);
		#endif

	}


	void lime_gl_program_parameteri (int program, int pname, int value) {

		#ifdef LIME_GLES3_API
		glProgramParameteri (program, pname, value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_program_parameteri) (int program, int pname, int value) {

		#ifdef LIME_GLES3_API
		glProgramParameteri (program, pname, value);
		#endif

	}


	void lime_gl_read_buffer (int src) {

		#ifdef LIME_GLES3_API
		glReadBuffer (src);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_read_buffer) (int src) {

		#ifdef LIME_GLES3_API
		glReadBuffer (src);
		#endif

	}


	void lime_gl_read_pixels (int x, int y, int width, int height, int format, int type, double pixels) {

		glReadPixels (x, y, width, height, format, type, (void*)(uintptr_t)pixels);

	}


	HL_PRIM void HL_NAME(hl_gl_read_pixels) (int x, int y, int width, int height, int format, int type, double pixels) {

		glReadPixels (x, y, width, height, format, type, (void*)(uintptr_t)pixels);

	}


	void lime_gl_release_shader_compiler () {

		#ifdef LIME_GLES3_API
		glReleaseShaderCompiler ();
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_release_shader_compiler) () {

		#ifdef LIME_GLES3_API
		glReleaseShaderCompiler ();
		#endif

	}


	void lime_gl_renderbuffer_storage (int target, int internalformat, int width, int height) {

		glRenderbufferStorage (target, internalformat, width, height);

	}


	HL_PRIM void HL_NAME(hl_gl_renderbuffer_storage) (int target, int internalformat, int width, int height) {

		glRenderbufferStorage (target, internalformat, width, height);

	}


	void lime_gl_renderbuffer_storage_multisample (int target, int samples, int internalformat, int width, int height) {

		#ifdef LIME_GLES3_API
		glRenderbufferStorageMultisample (target, samples, internalformat, width, height);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_renderbuffer_storage_multisample) (int target, int samples, int internalformat, int width, int height) {

		#ifdef LIME_GLES3_API
		glRenderbufferStorageMultisample (target, samples, internalformat, width, height);
		#endif

	}


	void lime_gl_resume_transform_feedback () {

		#ifdef LIME_GLES3_API
		glResumeTransformFeedback ();
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_resume_transform_feedback) () {

		#ifdef LIME_GLES3_API
		glResumeTransformFeedback ();
		#endif

	}


	void lime_gl_sample_coverage (float val, bool invert) {

		#ifdef LIME_GLES3_API
		glSampleCoverage (val, invert);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_sample_coverage) (float val, bool invert) {

		#ifdef LIME_GLES3_API
		glSampleCoverage (val, invert);
		#endif

	}


	void lime_gl_sampler_parameterf (int sampler, int pname, float param) {

		#ifdef LIME_GLES3_API
		glSamplerParameterf (sampler, pname, param);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_sampler_parameterf) (int sampler, int pname, float param) {

		#ifdef LIME_GLES3_API
		glSamplerParameterf (sampler, pname, param);
		#endif

	}


	void lime_gl_sampler_parameteri (int sampler, int pname, int param) {

		#ifdef LIME_GLES3_API
		glSamplerParameteri (sampler, pname, param);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_sampler_parameteri) (int sampler, int pname, int param) {

		#ifdef LIME_GLES3_API
		glSamplerParameteri (sampler, pname, param);
		#endif

	}


	void lime_gl_scissor (int x, int y, int width, int height) {

		glScissor (x, y, width, height);

	}


	HL_PRIM void HL_NAME(hl_gl_scissor) (int x, int y, int width, int height) {

		glScissor (x, y, width, height);

	}


	void lime_gl_shader_binary (value shaders, int binaryformat, double binary, int length) {

		#ifdef LIME_GLES3_API
		GLsizei size = val_array_size (shaders);
		GLenum *_shaders = (GLenum*)alloca (size * sizeof(GLenum));

		for (int i = 0; i < size; i++) {

			_shaders[i] = val_int (val_array_i (shaders, i));

		}

		glShaderBinary (size, _shaders, binaryformat, (void*)(uintptr_t)binary, length);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_shader_binary) (varray* shaders, int binaryformat, double binary, int length) {

		#ifdef LIME_GLES3_API
		GLsizei size = shaders->size;
		glShaderBinary (size, (GLenum*)hl_aptr (shaders, int), binaryformat, (void*)(uintptr_t)binary, length);
		#endif

	}


	void lime_gl_shader_source (int handle, HxString source) {

		glShaderSource (handle, 1, &source.__s, 0);

	}


	HL_PRIM void HL_NAME(hl_gl_shader_source) (int handle, hl_vstring* source) {

		const char* _source = source ? hl_to_utf8 (source->bytes) : NULL;
		glShaderSource (handle, 1, (const char**)&_source, 0);

	}


	void lime_gl_stencil_func (int func, int ref, int mask) {

		glStencilFunc (func, ref, mask);

	}


	HL_PRIM void HL_NAME(hl_gl_stencil_func) (int func, int ref, int mask) {

		glStencilFunc (func, ref, mask);

	}


	void lime_gl_stencil_func_separate (int face, int func, int ref, int mask) {

		glStencilFuncSeparate (face, func, ref, mask);

	}


	HL_PRIM void HL_NAME(hl_gl_stencil_func_separate) (int face, int func, int ref, int mask) {

		glStencilFuncSeparate (face, func, ref, mask);

	}


	void lime_gl_stencil_mask (int mask) {

		glStencilMask (mask);

	}


	HL_PRIM void HL_NAME(hl_gl_stencil_mask) (int mask) {

		glStencilMask (mask);

	}


	void lime_gl_stencil_mask_separate (int face, int mask) {

		glStencilMaskSeparate (face, mask);

	}


	HL_PRIM void HL_NAME(hl_gl_stencil_mask_separate) (int face, int mask) {

		glStencilMaskSeparate (face, mask);

	}


	void lime_gl_stencil_op (int sfail, int dpfail, int dppass) {

		glStencilOp (sfail, dpfail, dppass);

	}


	HL_PRIM void HL_NAME(hl_gl_stencil_op) (int sfail, int dpfail, int dppass) {

		glStencilOp (sfail, dpfail, dppass);

	}


	void lime_gl_stencil_op_separate (int face, int sfail, int dpfail, int dppass) {

		glStencilOpSeparate (face, sfail, dpfail, dppass);

	}


	HL_PRIM void HL_NAME(hl_gl_stencil_op_separate) (int face, int sfail, int dpfail, int dppass) {

		glStencilOpSeparate (face, sfail, dpfail, dppass);

	}


	void lime_gl_tex_image_2d (int target, int level, int internalformat, int width, int height, int border, int format, int type, double data) {

		glTexImage2D (target, level, internalformat, width, height, border, format, type, (void*)(uintptr_t)data);

	}


	HL_PRIM void HL_NAME(hl_gl_tex_image_2d) (int target, int level, int internalformat, int width, int height, int border, int format, int type, double data) {

		glTexImage2D (target, level, internalformat, width, height, border, format, type, (void*)(uintptr_t)data);

	}


	void lime_gl_tex_image_3d (int target, int level, int internalformat, int width, int height, int depth, int border, int format, int type, double data) {

		#ifdef LIME_GLES3_API
		glTexImage3D (target, level, internalformat, width, height, depth, border, format, type, (void*)(uintptr_t)data);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_tex_image_3d) (int target, int level, int internalformat, int width, int height, int depth, int border, int format, int type, double data) {

		#ifdef LIME_GLES3_API
		glTexImage3D (target, level, internalformat, width, height, depth, border, format, type, (void*)(uintptr_t)data);
		#endif

	}


	void lime_gl_tex_parameterf (int target, int pname, float param) {

		glTexParameterf (target, pname, param);

	}


	HL_PRIM void HL_NAME(hl_gl_tex_parameterf) (int target, int pname, float param) {

		glTexParameterf (target, pname, param);

	}


	void lime_gl_tex_parameteri (int target, int pname, int param) {

		glTexParameterf (target, pname, param);

	}


	HL_PRIM void HL_NAME(hl_gl_tex_parameteri) (int target, int pname, int param) {

		glTexParameterf (target, pname, param);

	}


	void lime_gl_tex_storage_2d (int target, int level, int internalformat, int width, int height) {

		#ifdef LIME_GLES3_API
		glTexStorage2D (target, level, internalformat, width, height);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_tex_storage_2d) (int target, int level, int internalformat, int width, int height) {

		#ifdef LIME_GLES3_API
		glTexStorage2D (target, level, internalformat, width, height);
		#endif

	}


	void lime_gl_tex_storage_3d (int target, int level, int internalformat, int width, int height, int depth) {

		#ifdef LIME_GLES3_API
		glTexStorage3D (target, level, internalformat, width, height, depth);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_tex_storage_3d) (int target, int level, int internalformat, int width, int height, int depth) {

		#ifdef LIME_GLES3_API
		glTexStorage3D (target, level, internalformat, width, height, depth);
		#endif

	}


	void lime_gl_tex_sub_image_2d (int target, int level, int xoffset, int yoffset, int width, int height, int format, int type, double data) {

		glTexSubImage2D (target, level, xoffset, yoffset, width, height, format, type, (void*)(uintptr_t)data);

	}


	HL_PRIM void HL_NAME(hl_gl_tex_sub_image_2d) (int target, int level, int xoffset, int yoffset, int width, int height, int format, int type, double data) {

		glTexSubImage2D (target, level, xoffset, yoffset, width, height, format, type, (void*)(uintptr_t)data);

	}


	void lime_gl_tex_sub_image_3d (int target, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, int format, int type, double data) {

		#ifdef LIME_GLES3_API
		glTexSubImage3D (target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, (void*)(uintptr_t)data);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_tex_sub_image_3d) (int target, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, int format, int type, double data) {

		#ifdef LIME_GLES3_API
		glTexSubImage3D (target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, (void*)(uintptr_t)data);
		#endif

	}


	void lime_gl_transform_feedback_varyings (int program, value varyings, int bufferMode) {

		#ifdef LIME_GLES3_API
		GLsizei size = val_array_size (varyings);
		const char **_varyings = (const char**)alloca (size * sizeof(GLenum));

		for (int i = 0; i < size; i++) {

			_varyings[i] = val_string (val_array_i (varyings, i));

		}

		glTransformFeedbackVaryings (program, size, _varyings, bufferMode);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_transform_feedback_varyings) (int program, varray* varyings, int bufferMode) {

		#ifdef LIME_GLES3_API
		GLsizei size = varyings->size;
		glTransformFeedbackVaryings (program, size, (const char**)hl_aptr (varyings, int), bufferMode);
		#endif

	}


	void lime_gl_uniform1f (int location, float v0) {

		glUniform1f (location, v0);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform1f) (int location, float v0) {

		glUniform1f (location, v0);

	}


	void lime_gl_uniform1fv (int location, int count, double _value) {

		glUniform1fv (location, count, (GLfloat*)(uintptr_t)_value);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform1fv) (int location, int count, double _value) {

		glUniform1fv (location, count, (GLfloat*)(uintptr_t)_value);

	}


	void lime_gl_uniform1i (int location, int v0) {

		glUniform1i (location, v0);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform1i) (int location, int v0) {

		glUniform1i (location, v0);

	}


	void lime_gl_uniform1iv (int location, int count, double _value) {

		glUniform1iv (location, count, (GLint*)(uintptr_t)_value);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform1iv) (int location, int count, double _value) {

		glUniform1iv (location, count, (GLint*)(uintptr_t)_value);

	}


	void lime_gl_uniform1ui (int location, int v0) {

		#ifdef LIME_GLES3_API
		glUniform1ui (location, v0);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform1ui) (int location, int v0) {

		#ifdef LIME_GLES3_API
		glUniform1ui (location, v0);
		#endif

	}


	void lime_gl_uniform1uiv (int location, int count, double _value) {

		#ifdef LIME_GLES3_API
		glUniform1uiv (location, count, (GLuint*)(uintptr_t)_value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform1uiv) (int location, int count, double _value) {

		#ifdef LIME_GLES3_API
		glUniform1uiv (location, count, (GLuint*)(uintptr_t)_value);
		#endif

	}


	void lime_gl_uniform2f (int location, float v0, float v1) {

		glUniform2f (location, v0, v1);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform2f) (int location, float v0, float v1) {

		glUniform2f (location, v0, v1);

	}


	void lime_gl_uniform2fv (int location, int count, double _value) {

		glUniform2fv (location, count, (GLfloat*)(uintptr_t)_value);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform2fv) (int location, int count, double _value) {

		glUniform2fv (location, count, (GLfloat*)(uintptr_t)_value);

	}


	void lime_gl_uniform2i (int location, int v0, int v1) {

		glUniform2i (location, v0, v1);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform2i) (int location, int v0, int v1) {

		glUniform2i (location, v0, v1);

	}


	void lime_gl_uniform2iv (int location, int count, double _value) {

		glUniform2iv (location, count, (GLint*)(uintptr_t)_value);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform2iv) (int location, int count, double _value) {

		glUniform2iv (location, count, (GLint*)(uintptr_t)_value);

	}


	void lime_gl_uniform2ui (int location, int v0, int v1) {

		#ifdef LIME_GLES3_API
		glUniform2ui (location, v0, v1);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform2ui) (int location, int v0, int v1) {

		#ifdef LIME_GLES3_API
		glUniform2ui (location, v0, v1);
		#endif

	}


	void lime_gl_uniform2uiv (int location, int count, double _value) {

		#ifdef LIME_GLES3_API
		glUniform2uiv (location, count, (GLuint*)(uintptr_t)_value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform2uiv) (int location, int count, double _value) {

		#ifdef LIME_GLES3_API
		glUniform2uiv (location, count, (GLuint*)(uintptr_t)_value);
		#endif

	}


	void lime_gl_uniform3f (int location, float v0, float v1, float v2) {

		glUniform3f (location, v0, v1, v2);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform3f) (int location, float v0, float v1, float v2) {

		glUniform3f (location, v0, v1, v2);

	}


	void lime_gl_uniform3fv (int location, int count, double _value) {

		glUniform3fv (location, count, (GLfloat*)(uintptr_t)_value);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform3fv) (int location, int count, double _value) {

		glUniform3fv (location, count, (GLfloat*)(uintptr_t)_value);

	}


	void lime_gl_uniform3i (int location, int v0, int v1, int v2) {

		glUniform3i (location, v0, v1, v2);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform3i) (int location, int v0, int v1, int v2) {

		glUniform3i (location, v0, v1, v2);

	}


	void lime_gl_uniform3iv (int location, int count, double _value) {

		glUniform3iv (location, count, (GLint*)(uintptr_t)_value);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform3iv) (int location, int count, double _value) {

		glUniform3iv (location, count, (GLint*)(uintptr_t)_value);

	}


	void lime_gl_uniform3ui (int location, int v0, int v1, int v2) {

		#ifdef LIME_GLES3_API
		glUniform3ui (location, v0, v1, v2);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform3ui) (int location, int v0, int v1, int v2) {

		#ifdef LIME_GLES3_API
		glUniform3ui (location, v0, v1, v2);
		#endif

	}


	void lime_gl_uniform3uiv (int location, int count, double _value) {

		#ifdef LIME_GLES3_API
		glUniform3uiv (location, count, (GLuint*)(uintptr_t)_value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform3uiv) (int location, int count, double _value) {

		#ifdef LIME_GLES3_API
		glUniform3uiv (location, count, (GLuint*)(uintptr_t)_value);
		#endif

	}


	void lime_gl_uniform4f (int location, float v0, float v1, float v2, float v3) {

		glUniform4f (location, v0, v1, v2, v3);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform4f) (int location, float v0, float v1, float v2, float v3) {

		glUniform4f (location, v0, v1, v2, v3);

	}


	void lime_gl_uniform4fv (int location, int count, double _value) {

		glUniform4fv (location, count, (GLfloat*)(uintptr_t)_value);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform4fv) (int location, int count, double _value) {

		glUniform4fv (location, count, (GLfloat*)(uintptr_t)_value);

	}


	void lime_gl_uniform4i (int location, int v0, int v1, int v2, int v3) {

		glUniform4i (location, v0, v1, v2, v3);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform4i) (int location, int v0, int v1, int v2, int v3) {

		glUniform4i (location, v0, v1, v2, v3);

	}


	void lime_gl_uniform4iv (int location, int count, double _value) {

		glUniform4iv (location, count, (GLint*)(uintptr_t)_value);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform4iv) (int location, int count, double _value) {

		glUniform4iv (location, count, (GLint*)(uintptr_t)_value);

	}


	void lime_gl_uniform4ui (int location, int v0, int v1, int v2, int v3) {

		#ifdef LIME_GLES3_API
		glUniform4ui (location, v0, v1, v2, v3);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform4ui) (int location, int v0, int v1, int v2, int v3) {

		#ifdef LIME_GLES3_API
		glUniform4ui (location, v0, v1, v2, v3);
		#endif

	}


	void lime_gl_uniform4uiv (int location, int count, double _value) {

		#ifdef LIME_GLES3_API
		glUniform4uiv (location, count, (GLuint*)(uintptr_t)_value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform4uiv) (int location, int count, double _value) {

		#ifdef LIME_GLES3_API
		glUniform4uiv (location, count, (GLuint*)(uintptr_t)_value);
		#endif

	}


	void lime_gl_uniform_block_binding (int program, int uniformBlockIndex, int uniformBlockBinding) {

		#ifdef LIME_GLES3_API
		glUniformBlockBinding (program, uniformBlockIndex, uniformBlockBinding);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform_block_binding) (int program, int uniformBlockIndex, int uniformBlockBinding) {

		#ifdef LIME_GLES3_API
		glUniformBlockBinding (program, uniformBlockIndex, uniformBlockBinding);
		#endif

	}


	void lime_gl_uniform_matrix2fv (int location, int count, bool transpose, double _value) {

		glUniformMatrix2fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform_matrix2fv) (int location, int count, bool transpose, double _value) {

		glUniformMatrix2fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);

	}


	void lime_gl_uniform_matrix2x3fv (int location, int count, bool transpose, double _value) {

		#ifdef LIME_GLES3_API
		glUniformMatrix2x3fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform_matrix2x3fv) (int location, int count, bool transpose, double _value) {

		#ifdef LIME_GLES3_API
		glUniformMatrix2x3fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		#endif

	}


	void lime_gl_uniform_matrix2x4fv (int location, int count, bool transpose, double _value) {

		#ifdef LIME_GLES3_API
		glUniformMatrix2x4fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform_matrix2x4fv) (int location, int count, bool transpose, double _value) {

		#ifdef LIME_GLES3_API
		glUniformMatrix2x4fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		#endif

	}


	void lime_gl_uniform_matrix3fv (int location, int count, bool transpose, double _value) {

		glUniformMatrix3fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform_matrix3fv) (int location, int count, bool transpose, double _value) {

		glUniformMatrix3fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);

	}


	void lime_gl_uniform_matrix3x2fv (int location, int count, bool transpose, double _value) {

		#ifdef LIME_GLES3_API
		glUniformMatrix3x2fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform_matrix3x2fv) (int location, int count, bool transpose, double _value) {

		#ifdef LIME_GLES3_API
		glUniformMatrix3x2fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		#endif

	}


	void lime_gl_uniform_matrix3x4fv (int location, int count, bool transpose, double _value) {

		#ifdef LIME_GLES3_API
		glUniformMatrix3x4fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform_matrix3x4fv) (int location, int count, bool transpose, double _value) {

		#ifdef LIME_GLES3_API
		glUniformMatrix3x4fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		#endif

	}


	void lime_gl_uniform_matrix4fv (int location, int count, bool transpose, double _value) {

		glUniformMatrix4fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);

	}


	HL_PRIM void HL_NAME(hl_gl_uniform_matrix4fv) (int location, int count, bool transpose, double _value) {

		glUniformMatrix4fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);

	}


	void lime_gl_uniform_matrix4x2fv (int location, int count, bool transpose, double _value) {

		#ifdef LIME_GLES3_API
		glUniformMatrix4x2fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform_matrix4x2fv) (int location, int count, bool transpose, double _value) {

		#ifdef LIME_GLES3_API
		glUniformMatrix4x2fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		#endif

	}


	void lime_gl_uniform_matrix4x3fv (int location, int count, bool transpose, double _value) {

		#ifdef LIME_GLES3_API
		glUniformMatrix4x3fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_uniform_matrix4x3fv) (int location, int count, bool transpose, double _value) {

		#ifdef LIME_GLES3_API
		glUniformMatrix4x3fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		#endif

	}


	bool lime_gl_unmap_buffer (int target) {

		#ifdef LIME_GLES3_API
		return glUnmapBuffer (target);
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_gl_unmap_buffer) (int target) {

		#ifdef LIME_GLES3_API
		return glUnmapBuffer (target);
		#else
		return false;
		#endif

	}


	void lime_gl_use_program (int handle) {

		glUseProgram (handle);

	}


	HL_PRIM void HL_NAME(hl_gl_use_program) (int handle) {

		glUseProgram (handle);

	}


	void lime_gl_validate_program (int handle) {

		glValidateProgram (handle);

	}


	HL_PRIM void HL_NAME(hl_gl_validate_program) (int handle) {

		glValidateProgram (handle);

	}


	void lime_gl_vertex_attrib_divisor (int index, int divisor) {

		#ifdef LIME_GLES3_API
		glVertexAttribDivisor (index, divisor);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attrib_divisor) (int index, int divisor) {

		#ifdef LIME_GLES3_API
		glVertexAttribDivisor (index, divisor);
		#endif

	}


	void lime_gl_vertex_attrib_ipointer (int index, int size, int type, int stride, double offset) {

		#ifdef LIME_GLES3_API
		glVertexAttribIPointer (index, size, type, stride, (void*)(uintptr_t)offset);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attrib_ipointer) (int index, int size, int type, int stride, double offset) {

		#ifdef LIME_GLES3_API
		glVertexAttribIPointer (index, size, type, stride, (void*)(uintptr_t)offset);
		#endif

	}


	void lime_gl_vertex_attrib_pointer (int index, int size, int type, bool normalized, int stride, double offset) {

		glVertexAttribPointer (index, size, type, normalized, stride, (void*)(uintptr_t)offset);

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attrib_pointer) (int index, int size, int type, bool normalized, int stride, double offset) {

		glVertexAttribPointer (index, size, type, normalized, stride, (void*)(uintptr_t)offset);

	}


	void lime_gl_vertex_attribi4i (int index, int v0, int v1, int v2, int v3) {

		#ifdef LIME_GLES3_API
		glVertexAttribI4i (index, v0, v1, v2, v3);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attribi4i) (int index, int v0, int v1, int v2, int v3) {

		#ifdef LIME_GLES3_API
		glVertexAttribI4i (index, v0, v1, v2, v3);
		#endif

	}


	void lime_gl_vertex_attribi4iv (int index, double v) {

		#ifdef LIME_GLES3_API
		glVertexAttribI4iv (index, (GLint*)(uintptr_t)v);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attribi4iv) (int index, double v) {

		#ifdef LIME_GLES3_API
		glVertexAttribI4iv (index, (GLint*)(uintptr_t)v);
		#endif

	}


	void lime_gl_vertex_attribi4ui (int index, int v0, int v1, int v2, int v3) {

		#ifdef LIME_GLES3_API
		glVertexAttribI4ui (index, v0, v1, v2, v3);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attribi4ui) (int index, int v0, int v1, int v2, int v3) {

		#ifdef LIME_GLES3_API
		glVertexAttribI4ui (index, v0, v1, v2, v3);
		#endif

	}


	void lime_gl_vertex_attribi4uiv (int index, double v) {

		#ifdef LIME_GLES3_API
		glVertexAttribI4uiv (index, (GLuint*)(uintptr_t)v);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attribi4uiv) (int index, double v) {

		#ifdef LIME_GLES3_API
		glVertexAttribI4uiv (index, (GLuint*)(uintptr_t)v);
		#endif

	}


	void lime_gl_vertex_attrib1f (int index, float v0) {

		glVertexAttrib1f (index, v0);

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attrib1f) (int index, float v0) {

		glVertexAttrib1f (index, v0);

	}


	void lime_gl_vertex_attrib1fv (int index, double v) {

		glVertexAttrib1fv (index, (GLfloat*)(uintptr_t)v);

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attrib1fv) (int index, double v) {

		glVertexAttrib1fv (index, (GLfloat*)(uintptr_t)v);

	}


	void lime_gl_vertex_attrib2f (int index, float v0, float v1) {

		glVertexAttrib2f (index, v0, v1);

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attrib2f) (int index, float v0, float v1) {

		glVertexAttrib2f (index, v0, v1);

	}


	void lime_gl_vertex_attrib2fv (int index, double v) {

		glVertexAttrib2fv (index, (GLfloat*)(uintptr_t)v);

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attrib2fv) (int index, double v) {

		glVertexAttrib2fv (index, (GLfloat*)(uintptr_t)v);

	}


	void lime_gl_vertex_attrib3f (int index, float v0, float v1, float v2) {

		glVertexAttrib3f (index, v0, v1, v2);

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attrib3f) (int index, float v0, float v1, float v2) {

		glVertexAttrib3f (index, v0, v1, v2);

	}


	void lime_gl_vertex_attrib3fv (int index, double v) {

		glVertexAttrib3fv (index, (GLfloat*)(uintptr_t)v);

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attrib3fv) (int index, double v) {

		glVertexAttrib3fv (index, (GLfloat*)(uintptr_t)v);

	}


	void lime_gl_vertex_attrib4f (int index, float v0, float v1, float v2, float v3) {

		glVertexAttrib4f (index, v0, v1, v2, v3);

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attrib4f) (int index, float v0, float v1, float v2, float v3) {

		glVertexAttrib4f (index, v0, v1, v2, v3);

	}


	void lime_gl_vertex_attrib4fv (int index, double v) {

		glVertexAttrib4fv (index, (GLfloat*)(uintptr_t)v);

	}


	HL_PRIM void HL_NAME(hl_gl_vertex_attrib4fv) (int index, double v) {

		glVertexAttrib4fv (index, (GLfloat*)(uintptr_t)v);

	}


	void lime_gl_viewport (int x, int y, int width, int height) {

		glViewport (x, y, width, height);

	}


	HL_PRIM void HL_NAME(hl_gl_viewport) (int x, int y, int width, int height) {

		glViewport (x, y, width, height);

	}


	void lime_gl_wait_sync (value sync, int flags, int timeoutA, int timeoutB) {

		#ifdef LIME_GLES3_API
		GLuint64 timeout = (GLuint64) timeoutA << 32 | timeoutB;
		glWaitSync ((GLsync)val_data (sync), flags, timeout);
		#endif

	}


	HL_PRIM void HL_NAME(hl_gl_wait_sync) (HL_CFFIPointer* sync, int flags, int timeoutA, int timeoutB) {

		#ifdef LIME_GLES3_API
		GLuint64 timeout = (GLuint64) timeoutA << 32 | timeoutB;
		glWaitSync ((GLsync)sync->ptr, flags, timeout);
		#endif

	}


	bool OpenGLBindings::Init () {

		static bool result = true;

		if (!initialized) {

			initialized = true;

			#ifdef HX_LINUX

			OpenGLBindings::handle = dlopen ("libGL.so.1", RTLD_NOW|RTLD_GLOBAL);

			if (!OpenGLBindings::handle) {

				OpenGLBindings::handle = dlopen ("libGL.so", RTLD_NOW|RTLD_GLOBAL);

			}

			if (!OpenGLBindings::handle) {

				result = false;
				return result;

			}

			#endif

			#ifdef NATIVE_TOOLKIT_SDL_ANGLE

			#ifdef HX_WINRT
			return true;
			#else
			OpenGLBindings::eglHandle = LoadLibraryW (L"libegl.dll");

			if (!OpenGLBindings::eglHandle) {

				result = false;
				return result;

			}
			#endif

			#endif

			#ifdef NEED_EXTENSIONS
			#define GET_EXTENSION
			#include "OpenGLExtensions.h"
			#undef DEFINE_EXTENSION
			#endif

		}

		return result;

	}


	DEFINE_PRIME1v (lime_gl_active_texture);
	DEFINE_PRIME2v (lime_gl_attach_shader);
	DEFINE_PRIME2v (lime_gl_begin_query);
	DEFINE_PRIME1v (lime_gl_begin_transform_feedback);
	DEFINE_PRIME3v (lime_gl_bind_attrib_location);
	DEFINE_PRIME2v (lime_gl_bind_buffer);
	DEFINE_PRIME3v (lime_gl_bind_buffer_base);
	DEFINE_PRIME5v (lime_gl_bind_buffer_range);
	DEFINE_PRIME2v (lime_gl_bind_framebuffer);
	DEFINE_PRIME2v (lime_gl_bind_renderbuffer);
	DEFINE_PRIME2v (lime_gl_bind_sampler);
	DEFINE_PRIME2v (lime_gl_bind_texture);
	DEFINE_PRIME2v (lime_gl_bind_transform_feedback);
	DEFINE_PRIME1v (lime_gl_bind_vertex_array);
	DEFINE_PRIME4v (lime_gl_blend_color);
	DEFINE_PRIME1v (lime_gl_blend_equation);
	DEFINE_PRIME2v (lime_gl_blend_equation_separate);
	DEFINE_PRIME2v (lime_gl_blend_func);
	DEFINE_PRIME4v (lime_gl_blend_func_separate);
	DEFINE_PRIME10v (lime_gl_blit_framebuffer);
	DEFINE_PRIME4v (lime_gl_buffer_data);
	DEFINE_PRIME4v (lime_gl_buffer_sub_data);
	DEFINE_PRIME1 (lime_gl_check_framebuffer_status);
	DEFINE_PRIME1v (lime_gl_clear);
	DEFINE_PRIME4v (lime_gl_clear_bufferfi);
	DEFINE_PRIME3v (lime_gl_clear_bufferfv);
	DEFINE_PRIME3v (lime_gl_clear_bufferiv);
	DEFINE_PRIME3v (lime_gl_clear_bufferuiv);
	DEFINE_PRIME4v (lime_gl_clear_color);
	DEFINE_PRIME1v (lime_gl_clear_depthf);
	DEFINE_PRIME1v (lime_gl_clear_stencil);
	DEFINE_PRIME4 (lime_gl_client_wait_sync);
	DEFINE_PRIME4v (lime_gl_color_mask);
	DEFINE_PRIME1v (lime_gl_compile_shader);
	DEFINE_PRIME8v (lime_gl_compressed_tex_image_2d);
	DEFINE_PRIME9v (lime_gl_compressed_tex_image_3d);
	DEFINE_PRIME9v (lime_gl_compressed_tex_sub_image_2d);
	DEFINE_PRIME11v (lime_gl_compressed_tex_sub_image_3d);
	DEFINE_PRIME5v (lime_gl_copy_buffer_sub_data);
	DEFINE_PRIME8v (lime_gl_copy_tex_image_2d);
	DEFINE_PRIME8v (lime_gl_copy_tex_sub_image_2d);
	DEFINE_PRIME9v (lime_gl_copy_tex_sub_image_3d);
	DEFINE_PRIME0 (lime_gl_create_buffer);
	DEFINE_PRIME0 (lime_gl_create_framebuffer);
	DEFINE_PRIME0 (lime_gl_create_program);
	DEFINE_PRIME0 (lime_gl_create_query);
	DEFINE_PRIME0 (lime_gl_create_renderbuffer);
	DEFINE_PRIME0 (lime_gl_create_sampler);
	DEFINE_PRIME1 (lime_gl_create_shader);
	DEFINE_PRIME0 (lime_gl_create_texture);
	DEFINE_PRIME0 (lime_gl_create_transform_feedback);
	DEFINE_PRIME0 (lime_gl_create_vertex_array);
	DEFINE_PRIME1v (lime_gl_cull_face);
	DEFINE_PRIME1v (lime_gl_delete_buffer);
	DEFINE_PRIME1v (lime_gl_delete_framebuffer);
	DEFINE_PRIME1v (lime_gl_delete_program);
	DEFINE_PRIME1v (lime_gl_delete_query);
	DEFINE_PRIME1v (lime_gl_delete_renderbuffer);
	DEFINE_PRIME1v (lime_gl_delete_sampler);
	DEFINE_PRIME1v (lime_gl_delete_shader);
	DEFINE_PRIME1v (lime_gl_delete_sync);
	DEFINE_PRIME1v (lime_gl_delete_texture);
	DEFINE_PRIME1v (lime_gl_delete_transform_feedback);
	DEFINE_PRIME1v (lime_gl_delete_vertex_array);
	DEFINE_PRIME1v (lime_gl_depth_func);
	DEFINE_PRIME1v (lime_gl_depth_mask);
	DEFINE_PRIME2v (lime_gl_depth_rangef);
	DEFINE_PRIME2v (lime_gl_detach_shader);
	DEFINE_PRIME1v (lime_gl_disable);
	DEFINE_PRIME1v (lime_gl_disable_vertex_attrib_array);
	DEFINE_PRIME3v (lime_gl_draw_arrays);
	DEFINE_PRIME4v (lime_gl_draw_arrays_instanced);
	DEFINE_PRIME1v (lime_gl_draw_buffers);
	DEFINE_PRIME4v (lime_gl_draw_elements);
	DEFINE_PRIME5v (lime_gl_draw_elements_instanced);
	DEFINE_PRIME6v (lime_gl_draw_range_elements);
	DEFINE_PRIME1v (lime_gl_enable);
	DEFINE_PRIME1v (lime_gl_enable_vertex_attrib_array);
	DEFINE_PRIME1v (lime_gl_end_query);
	DEFINE_PRIME0v (lime_gl_end_transform_feedback);
	DEFINE_PRIME2 (lime_gl_fence_sync);
	DEFINE_PRIME0v (lime_gl_finish);
	DEFINE_PRIME0v (lime_gl_flush);
	DEFINE_PRIME4v (lime_gl_framebuffer_renderbuffer);
	DEFINE_PRIME5v (lime_gl_framebuffer_texture_layer);
	DEFINE_PRIME5v (lime_gl_framebuffer_texture2D);
	DEFINE_PRIME1v (lime_gl_front_face);
	DEFINE_PRIME1v (lime_gl_generate_mipmap);
	DEFINE_PRIME2 (lime_gl_get_active_attrib);
	DEFINE_PRIME2 (lime_gl_get_active_uniform);
	DEFINE_PRIME3 (lime_gl_get_active_uniform_blocki);
	DEFINE_PRIME4v (lime_gl_get_active_uniform_blockiv);
	DEFINE_PRIME2 (lime_gl_get_active_uniform_block_name);
	DEFINE_PRIME4v (lime_gl_get_active_uniformsiv);
	DEFINE_PRIME1 (lime_gl_get_attached_shaders);
	DEFINE_PRIME2 (lime_gl_get_attrib_location);
	DEFINE_PRIME1 (lime_gl_get_boolean);
	DEFINE_PRIME2v (lime_gl_get_booleanv);
	DEFINE_PRIME2 (lime_gl_get_buffer_parameteri);
	DEFINE_PRIME3v (lime_gl_get_buffer_parameteriv);
	DEFINE_PRIME3v (lime_gl_get_buffer_parameteri64v);
	DEFINE_PRIME2 (lime_gl_get_buffer_pointerv);
	DEFINE_PRIME4v (lime_gl_get_buffer_sub_data);
	DEFINE_PRIME0 (lime_gl_get_context_attributes);
	DEFINE_PRIME0 (lime_gl_get_error);
	DEFINE_PRIME1 (lime_gl_get_extension);
	DEFINE_PRIME1 (lime_gl_get_float);
	DEFINE_PRIME2v (lime_gl_get_floatv);
	DEFINE_PRIME2 (lime_gl_get_frag_data_location);
	DEFINE_PRIME3 (lime_gl_get_framebuffer_attachment_parameteri);
	DEFINE_PRIME4v (lime_gl_get_framebuffer_attachment_parameteriv);
	DEFINE_PRIME1 (lime_gl_get_integer);
	DEFINE_PRIME2v (lime_gl_get_integerv);
	DEFINE_PRIME2v (lime_gl_get_integer64v);
	DEFINE_PRIME3v (lime_gl_get_integer64i_v);
	DEFINE_PRIME3v (lime_gl_get_integeri_v);
	DEFINE_PRIME5v (lime_gl_get_internalformativ);
	DEFINE_PRIME2 (lime_gl_get_programi);
	DEFINE_PRIME3v (lime_gl_get_programiv);
	DEFINE_PRIME3v (lime_gl_get_program_binary);
	DEFINE_PRIME1 (lime_gl_get_program_info_log);
	DEFINE_PRIME2 (lime_gl_get_queryi);
	DEFINE_PRIME3v (lime_gl_get_queryiv);
	DEFINE_PRIME2 (lime_gl_get_query_objectui);
	DEFINE_PRIME3v (lime_gl_get_query_objectuiv);
	DEFINE_PRIME2 (lime_gl_get_renderbuffer_parameteri);
	DEFINE_PRIME3v (lime_gl_get_renderbuffer_parameteriv);
	DEFINE_PRIME2 (lime_gl_get_sampler_parameterf);
	DEFINE_PRIME3v (lime_gl_get_sampler_parameterfv);
	DEFINE_PRIME2 (lime_gl_get_sampler_parameteri);
	DEFINE_PRIME3v (lime_gl_get_sampler_parameteriv);
	DEFINE_PRIME1 (lime_gl_get_shader_info_log);
	DEFINE_PRIME2 (lime_gl_get_shaderi);
	DEFINE_PRIME3v (lime_gl_get_shaderiv);
	DEFINE_PRIME2 (lime_gl_get_shader_precision_format);
	DEFINE_PRIME1 (lime_gl_get_shader_source);
	DEFINE_PRIME1 (lime_gl_get_string);
	DEFINE_PRIME2 (lime_gl_get_stringi);
	DEFINE_PRIME2 (lime_gl_get_sync_parameteri);
	DEFINE_PRIME3v (lime_gl_get_sync_parameteriv);
	DEFINE_PRIME2 (lime_gl_get_tex_parameterf);
	DEFINE_PRIME3v (lime_gl_get_tex_parameterfv);
	DEFINE_PRIME2 (lime_gl_get_tex_parameteri);
	DEFINE_PRIME3v (lime_gl_get_tex_parameteriv);
	DEFINE_PRIME2 (lime_gl_get_transform_feedback_varying);
	DEFINE_PRIME2 (lime_gl_get_uniformf);
	DEFINE_PRIME3v (lime_gl_get_uniformfv);
	DEFINE_PRIME2 (lime_gl_get_uniformi);
	DEFINE_PRIME3v (lime_gl_get_uniformiv);
	DEFINE_PRIME2 (lime_gl_get_uniformui);
	DEFINE_PRIME3v (lime_gl_get_uniformuiv);
	DEFINE_PRIME2 (lime_gl_get_uniform_block_index);
	DEFINE_PRIME2 (lime_gl_get_uniform_location);
	DEFINE_PRIME2 (lime_gl_get_vertex_attribf);
	DEFINE_PRIME3v (lime_gl_get_vertex_attribfv);
	DEFINE_PRIME2 (lime_gl_get_vertex_attribi);
	DEFINE_PRIME3v (lime_gl_get_vertex_attribiv);
	DEFINE_PRIME2 (lime_gl_get_vertex_attribii);
	DEFINE_PRIME3v (lime_gl_get_vertex_attribiiv);
	DEFINE_PRIME2 (lime_gl_get_vertex_attribiui);
	DEFINE_PRIME3v (lime_gl_get_vertex_attribiuiv);
	DEFINE_PRIME2 (lime_gl_get_vertex_attrib_pointerv);
	DEFINE_PRIME2v (lime_gl_hint);
	DEFINE_PRIME2v (lime_gl_invalidate_framebuffer);
	DEFINE_PRIME6v (lime_gl_invalidate_sub_framebuffer);
	DEFINE_PRIME1 (lime_gl_is_buffer);
	DEFINE_PRIME1 (lime_gl_is_enabled);
	DEFINE_PRIME1 (lime_gl_is_framebuffer);
	DEFINE_PRIME1 (lime_gl_is_program);
	DEFINE_PRIME1 (lime_gl_is_query);
	DEFINE_PRIME1 (lime_gl_is_renderbuffer);
	DEFINE_PRIME1 (lime_gl_is_sampler);
	DEFINE_PRIME1 (lime_gl_is_shader);
	DEFINE_PRIME1 (lime_gl_is_sync);
	DEFINE_PRIME1 (lime_gl_is_texture);
	DEFINE_PRIME1 (lime_gl_is_transform_feedback);
	DEFINE_PRIME1 (lime_gl_is_vertex_array);
	DEFINE_PRIME1v (lime_gl_line_width);
	DEFINE_PRIME1v (lime_gl_link_program);
	DEFINE_PRIME4 (lime_gl_map_buffer_range);
	DEFINE_PRIME1v (lime_gl_object_deregister);
	DEFINE_PRIME2 (lime_gl_object_from_id);
	DEFINE_PRIME3 (lime_gl_object_register);
	DEFINE_PRIME0v (lime_gl_pause_transform_feedback);
	DEFINE_PRIME2v (lime_gl_pixel_storei);
	DEFINE_PRIME2v (lime_gl_polygon_offset);
	DEFINE_PRIME4v (lime_gl_program_binary);
	DEFINE_PRIME3v (lime_gl_program_parameteri);
	DEFINE_PRIME1v (lime_gl_read_buffer);
	DEFINE_PRIME7v (lime_gl_read_pixels);
	DEFINE_PRIME0v (lime_gl_release_shader_compiler);
	DEFINE_PRIME4v (lime_gl_renderbuffer_storage);
	DEFINE_PRIME5v (lime_gl_renderbuffer_storage_multisample);
	DEFINE_PRIME0v (lime_gl_resume_transform_feedback);
	DEFINE_PRIME2v (lime_gl_sample_coverage);
	DEFINE_PRIME3v (lime_gl_sampler_parameterf);
	DEFINE_PRIME3v (lime_gl_sampler_parameteri);
	DEFINE_PRIME4v (lime_gl_scissor);
	DEFINE_PRIME4v (lime_gl_shader_binary);
	DEFINE_PRIME2v (lime_gl_shader_source);
	DEFINE_PRIME3v (lime_gl_stencil_func);
	DEFINE_PRIME4v (lime_gl_stencil_func_separate);
	DEFINE_PRIME1v (lime_gl_stencil_mask);
	DEFINE_PRIME2v (lime_gl_stencil_mask_separate);
	DEFINE_PRIME3v (lime_gl_stencil_op);
	DEFINE_PRIME4v (lime_gl_stencil_op_separate);
	DEFINE_PRIME9v (lime_gl_tex_image_2d);
	DEFINE_PRIME10v (lime_gl_tex_image_3d);
	DEFINE_PRIME3v (lime_gl_tex_parameterf);
	DEFINE_PRIME3v (lime_gl_tex_parameteri);
	DEFINE_PRIME5v (lime_gl_tex_storage_2d);
	DEFINE_PRIME6v (lime_gl_tex_storage_3d);
	DEFINE_PRIME9v (lime_gl_tex_sub_image_2d);
	DEFINE_PRIME11v (lime_gl_tex_sub_image_3d);
	DEFINE_PRIME3v (lime_gl_transform_feedback_varyings);
	DEFINE_PRIME2v (lime_gl_uniform1f);
	DEFINE_PRIME3v (lime_gl_uniform1fv);
	DEFINE_PRIME2v (lime_gl_uniform1i);
	DEFINE_PRIME3v (lime_gl_uniform1iv);
	DEFINE_PRIME2v (lime_gl_uniform1ui);
	DEFINE_PRIME3v (lime_gl_uniform1uiv);
	DEFINE_PRIME3v (lime_gl_uniform2f);
	DEFINE_PRIME3v (lime_gl_uniform2fv);
	DEFINE_PRIME3v (lime_gl_uniform2i);
	DEFINE_PRIME3v (lime_gl_uniform2iv);
	DEFINE_PRIME3v (lime_gl_uniform2ui);
	DEFINE_PRIME3v (lime_gl_uniform2uiv);
	DEFINE_PRIME4v (lime_gl_uniform3f);
	DEFINE_PRIME3v (lime_gl_uniform3fv);
	DEFINE_PRIME4v (lime_gl_uniform3i);
	DEFINE_PRIME3v (lime_gl_uniform3iv);
	DEFINE_PRIME4v (lime_gl_uniform3ui);
	DEFINE_PRIME3v (lime_gl_uniform3uiv);
	DEFINE_PRIME5v (lime_gl_uniform4f);
	DEFINE_PRIME3v (lime_gl_uniform4fv);
	DEFINE_PRIME5v (lime_gl_uniform4i);
	DEFINE_PRIME3v (lime_gl_uniform4iv);
	DEFINE_PRIME5v (lime_gl_uniform4ui);
	DEFINE_PRIME3v (lime_gl_uniform4uiv);
	DEFINE_PRIME3v (lime_gl_uniform_block_binding);
	DEFINE_PRIME4v (lime_gl_uniform_matrix2fv);
	DEFINE_PRIME4v (lime_gl_uniform_matrix2x3fv);
	DEFINE_PRIME4v (lime_gl_uniform_matrix2x4fv);
	DEFINE_PRIME4v (lime_gl_uniform_matrix3fv);
	DEFINE_PRIME4v (lime_gl_uniform_matrix3x2fv);
	DEFINE_PRIME4v (lime_gl_uniform_matrix3x4fv);
	DEFINE_PRIME4v (lime_gl_uniform_matrix4fv);
	DEFINE_PRIME4v (lime_gl_uniform_matrix4x2fv);
	DEFINE_PRIME4v (lime_gl_uniform_matrix4x3fv);
	DEFINE_PRIME1 (lime_gl_unmap_buffer);
	DEFINE_PRIME1v (lime_gl_use_program);
	DEFINE_PRIME1v (lime_gl_validate_program);
	DEFINE_PRIME2v (lime_gl_vertex_attrib_divisor);
	DEFINE_PRIME5v (lime_gl_vertex_attrib_ipointer);
	DEFINE_PRIME6v (lime_gl_vertex_attrib_pointer);
	DEFINE_PRIME5v (lime_gl_vertex_attribi4i);
	DEFINE_PRIME2v (lime_gl_vertex_attribi4iv);
	DEFINE_PRIME5v (lime_gl_vertex_attribi4ui);
	DEFINE_PRIME2v (lime_gl_vertex_attribi4uiv);
	DEFINE_PRIME2v (lime_gl_vertex_attrib1f);
	DEFINE_PRIME2v (lime_gl_vertex_attrib1fv);
	DEFINE_PRIME3v (lime_gl_vertex_attrib2f);
	DEFINE_PRIME2v (lime_gl_vertex_attrib2fv);
	DEFINE_PRIME4v (lime_gl_vertex_attrib3f);
	DEFINE_PRIME2v (lime_gl_vertex_attrib3fv);
	DEFINE_PRIME5v (lime_gl_vertex_attrib4f);
	DEFINE_PRIME2v (lime_gl_vertex_attrib4fv);
	DEFINE_PRIME4v (lime_gl_viewport);
	DEFINE_PRIME4v (lime_gl_wait_sync);


	#define _TBYTES _OBJ (_I32 _BYTES)
	#define _TCFFIPOINTER _DYN

	#define _TGLOBJECT _OBJ (_I32 _TCFFIPOINTER _OBJ (_I32 _ARR))


	DEFINE_HL_PRIM (_VOID, hl_gl_active_texture, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_attach_shader, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_begin_query, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_begin_transform_feedback, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_bind_attrib_location, _I32 _I32 _STRING);
	DEFINE_HL_PRIM (_VOID, hl_gl_bind_buffer, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_bind_buffer_base, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_bind_buffer_range, _I32 _I32 _I32 _F64 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_bind_framebuffer, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_bind_renderbuffer, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_bind_sampler, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_bind_texture, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_bind_transform_feedback, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_bind_vertex_array, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_blend_color, _F32 _F32 _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_blend_equation, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_blend_equation_separate, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_blend_func, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_blend_func_separate, _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_blit_framebuffer, _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_buffer_data, _I32 _I32 _F64 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_buffer_sub_data, _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_check_framebuffer_status, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_clear, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_clear_bufferfi, _I32 _I32 _F32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_clear_bufferfv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_clear_bufferiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_clear_bufferuiv,  _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_clear_color, _F32 _F32 _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_clear_depthf, _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_clear_stencil, _I32);
	DEFINE_HL_PRIM (_I32, hl_gl_client_wait_sync, _TCFFIPOINTER _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_color_mask, _BOOL _BOOL _BOOL _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_gl_compile_shader, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_compressed_tex_image_2d, _I32 _I32 _I32 _I32 _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_compressed_tex_image_3d, _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_compressed_tex_sub_image_2d, _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_compressed_tex_sub_image_3d, _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_copy_buffer_sub_data, _I32 _I32 _F64 _F64 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_copy_tex_image_2d, _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_copy_tex_sub_image_2d, _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_copy_tex_sub_image_3d, _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_gl_create_buffer, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_gl_create_framebuffer, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_gl_create_program, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_gl_create_query, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_gl_create_renderbuffer, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_gl_create_sampler, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_gl_create_shader, _I32);
	DEFINE_HL_PRIM (_I32, hl_gl_create_texture, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_gl_create_transform_feedback, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_gl_create_vertex_array, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_gl_cull_face, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_delete_buffer, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_delete_framebuffer, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_delete_program, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_delete_query, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_delete_renderbuffer, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_delete_sampler, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_delete_shader, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_delete_sync, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_gl_delete_texture, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_delete_transform_feedback, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_delete_vertex_array, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_depth_func, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_depth_mask, _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_gl_depth_rangef, _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_detach_shader, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_disable, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_disable_vertex_attrib_array, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_draw_arrays, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_draw_arrays_instanced, _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_draw_buffers, _ARR);
	DEFINE_HL_PRIM (_VOID, hl_gl_draw_elements, _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_draw_elements_instanced, _I32 _I32 _I32 _F64 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_draw_range_elements, _I32 _I32 _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_enable, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_enable_vertex_attrib_array, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_end_query, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_end_transform_feedback, _NO_ARG);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_gl_fence_sync, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_finish, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_gl_flush, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_gl_framebuffer_renderbuffer, _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_framebuffer_texture_layer, _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_framebuffer_texture2D, _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_front_face, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_generate_mipmap, _I32);
	DEFINE_HL_PRIM (_DYN, hl_gl_get_active_attrib, _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_gl_get_active_uniform, _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_gl_get_active_uniform_blocki, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_active_uniform_blockiv, _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_BYTES, hl_gl_get_active_uniform_block_name, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_active_uniformsiv, _I32 _ARR _I32 _F64);
	DEFINE_HL_PRIM (_ARR, hl_gl_get_attached_shaders, _I32);
	DEFINE_HL_PRIM (_I32, hl_gl_get_attrib_location, _I32 _STRING);
	DEFINE_HL_PRIM (_BOOL, hl_gl_get_boolean, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_booleanv, _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_buffer_parameteri, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_buffer_parameteriv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_buffer_parameteri64v, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_F64, hl_gl_get_buffer_pointerv, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_buffer_sub_data, _I32 _F64 _I32 _F64);
	DEFINE_HL_PRIM (_DYN, hl_gl_get_context_attributes, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_gl_get_error, _NO_ARG);
	DEFINE_HL_PRIM (_DYN, hl_gl_get_extension, _STRING);
	DEFINE_HL_PRIM (_F32, hl_gl_get_float, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_floatv, _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_frag_data_location, _I32 _STRING);
	DEFINE_HL_PRIM (_I32, hl_gl_get_framebuffer_attachment_parameteri, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_framebuffer_attachment_parameteriv, _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_integer, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_integerv, _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_integer64v, _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_integer64i_v, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_integeri_v, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_internalformativ, _I32 _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_programi, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_programiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_program_binary, _I32 _I32 _TBYTES);
	DEFINE_HL_PRIM (_BYTES, hl_gl_get_program_info_log, _I32);
	DEFINE_HL_PRIM (_I32, hl_gl_get_queryi, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_queryiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_query_objectui, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_query_objectuiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_renderbuffer_parameteri, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_renderbuffer_parameteriv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_F32, hl_gl_get_sampler_parameterf, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_sampler_parameterfv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_sampler_parameteri, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_sampler_parameteriv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_BYTES, hl_gl_get_shader_info_log, _I32);
	DEFINE_HL_PRIM (_I32, hl_gl_get_shaderi, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_shaderiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_DYN, hl_gl_get_shader_precision_format, _I32 _I32);
	DEFINE_HL_PRIM (_BYTES, hl_gl_get_shader_source, _I32);
	DEFINE_HL_PRIM (_BYTES, hl_gl_get_string, _I32);
	DEFINE_HL_PRIM (_BYTES, hl_gl_get_stringi, _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_gl_get_sync_parameteri, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_sync_parameteriv, _TCFFIPOINTER _I32 _F64);
	DEFINE_HL_PRIM (_F32, hl_gl_get_tex_parameterf, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_tex_parameterfv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_tex_parameteri, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_tex_parameteriv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_DYN, hl_gl_get_transform_feedback_varying, _I32 _I32);
	DEFINE_HL_PRIM (_F32, hl_gl_get_uniformf, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_uniformfv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_uniformi, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_uniformiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_uniformui, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_uniformuiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_uniform_block_index, _I32 _STRING);
	DEFINE_HL_PRIM (_I32, hl_gl_get_uniform_location, _I32 _STRING);
	DEFINE_HL_PRIM (_F32, hl_gl_get_vertex_attribf, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_vertex_attribfv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_vertex_attribi, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_vertex_attribiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_vertex_attribii, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_vertex_attribiiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_I32, hl_gl_get_vertex_attribiui, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_get_vertex_attribiuiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_F64, hl_gl_get_vertex_attrib_pointerv, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_hint, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_invalidate_framebuffer, _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_gl_invalidate_sub_framebuffer, _I32 _ARR _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_gl_is_buffer, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_gl_is_enabled, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_gl_is_framebuffer, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_gl_is_program, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_gl_is_query, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_gl_is_renderbuffer, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_gl_is_sampler, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_gl_is_shader, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_gl_is_sync, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_gl_is_texture, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_gl_is_transform_feedback, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_gl_is_vertex_array, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_line_width, _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_link_program, _I32);
	DEFINE_HL_PRIM (_F64, hl_gl_map_buffer_range, _I32 _F64 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_object_deregister, _TGLOBJECT);
	DEFINE_HL_PRIM (_TGLOBJECT, hl_gl_object_from_id, _I32 _I32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_gl_object_register, _I32 _I32 _TGLOBJECT);
	DEFINE_HL_PRIM (_VOID, hl_gl_pause_transform_feedback, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_gl_pixel_storei, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_polygon_offset, _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_program_binary, _I32 _I32 _F64 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_program_parameteri, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_read_buffer, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_read_pixels, _I32 _I32 _I32 _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_release_shader_compiler, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_gl_renderbuffer_storage, _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_renderbuffer_storage_multisample, _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_resume_transform_feedback, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_gl_sample_coverage, _F32 _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_gl_sampler_parameterf, _I32 _I32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_sampler_parameteri, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_scissor, _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_shader_binary, _ARR _I32 _F64 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_shader_source, _I32 _STRING);
	DEFINE_HL_PRIM (_VOID, hl_gl_stencil_func, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_stencil_func_separate, _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_stencil_mask, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_stencil_mask_separate, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_stencil_op, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_stencil_op_separate, _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_tex_image_2d, _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_tex_image_3d, _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_tex_parameterf, _I32 _I32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_tex_parameteri, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_tex_storage_2d, _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_tex_storage_3d, _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_tex_sub_image_2d, _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_tex_sub_image_3d, _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_transform_feedback_varyings, _I32 _ARR _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform1f, _I32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform1fv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform1i, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform1iv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform1ui, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform1uiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform2f, _I32 _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform2fv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform2i, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform2iv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform2ui, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform2uiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform3f, _I32 _F32 _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform3fv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform3i, _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform3iv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform3ui, _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform3uiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform4f, _I32 _F32 _F32 _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform4fv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform4i, _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform4iv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform4ui, _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform4uiv, _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform_block_binding, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform_matrix2fv, _I32 _I32 _BOOL _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform_matrix2x3fv, _I32 _I32 _BOOL _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform_matrix2x4fv, _I32 _I32 _BOOL _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform_matrix3fv, _I32 _I32 _BOOL _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform_matrix3x2fv, _I32 _I32 _BOOL _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform_matrix3x4fv, _I32 _I32 _BOOL _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform_matrix4fv, _I32 _I32 _BOOL _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform_matrix4x2fv, _I32 _I32 _BOOL _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_uniform_matrix4x3fv, _I32 _I32 _BOOL _F64);
	DEFINE_HL_PRIM (_BOOL, hl_gl_unmap_buffer, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_use_program, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_validate_program, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attrib_divisor, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attrib_ipointer, _I32 _I32 _I32 _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attrib_pointer, _I32 _I32 _I32 _BOOL _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attribi4i, _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attribi4iv, _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attribi4ui, _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attribi4uiv, _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attrib1f, _I32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attrib1fv, _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attrib2f, _I32 _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attrib2fv, _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attrib3f, _I32 _F32 _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attrib3fv, _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attrib4f, _I32 _F32 _F32 _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_gl_vertex_attrib4fv, _I32 _F64);
	DEFINE_HL_PRIM (_VOID, hl_gl_viewport, _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gl_wait_sync, _TCFFIPOINTER _I32 _I32 _I32);


}


extern "C" int lime_opengl_register_prims () {

	return 0;

}