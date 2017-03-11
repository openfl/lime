#include <hx/CFFIPrime.h>
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

#ifdef LIME_SDL
#include <SDL.h>
#endif


namespace lime {
	
	
	bool OpenGLBindings::initialized = false;
	void *OpenGLBindings::handle = 0;
	int OpenGLBindings::defaultFramebuffer = 0;
	
	
	void gc_gl_object (value object);
	
	std::map<GLuint, value> glObjects;
	std::map<GLuint, GLObjectType> glObjectTypes;
	value glObjectConstructor;
	value *glObjectConstructorRoot;
	int id_id = 0;
	
	GLuint GLObjectID (value object) {
		
		if (val_is_null (object)) {
			
			return 0;
			
		} else {
			
			return val_int (val_field (object, id_id));
			
		}
		
	}
	
	value GLObjectFromID (GLObjectType type, GLuint id) {
		
		if (glObjects.find (id) == glObjects.end ()) {
			
			glObjectTypes[id] = type;
			glObjects[id] = CFFIPointer (val_call1 (glObjectConstructor, alloc_int (id)), gc_gl_object);
			
		}
		
		return glObjects[id];
		
	}
	
	
	void lime_gl_delete_buffer (value handle);
	void lime_gl_delete_framebuffer (value handle);
	void lime_gl_delete_program (value handle);
	void lime_gl_delete_renderbuffer (value handle);
	void lime_gl_delete_shader (value handle);
	void lime_gl_delete_texture (value handle);
	
	std::vector<GLuint> gc_gl_id;
	Mutex gc_gl_mutex;
	
	void gc_gl_object (value object) {
		
		gc_gl_mutex.Lock ();
		gc_gl_id.push_back (GLObjectID (object));
		gc_gl_mutex.Unlock ();
		
	}
	
	void gc_gl_run () {
		
		gc_gl_mutex.Lock ();
		
		int size = gc_gl_id.size ();
		
		if (size > 0) {
			
			GLuint id;
			GLObjectType type;
			
			for (int i = 0; i < size; i++) {
				
				id = gc_gl_id[i];
				type = glObjectTypes[id];
				
				switch (type) {
					
					case TYPE_BUFFER:
						
						glDeleteBuffers (1, &id);
						break;
					
					case TYPE_FRAMEBUFFER:
						
						glDeleteFramebuffers (1, &id);
						break;
					
					case TYPE_PROGRAM:
						
						glDeleteProgram (id);
						break;
					
					case TYPE_RENDERBUFFER:
						
						glDeleteRenderbuffers (1, &id);
						break;
					
					case TYPE_SHADER:
						
						glDeleteShader (id);
						break;
					
					case TYPE_TEXTURE:
						
						glDeleteTextures (1, &id);
						break;
					
					case TYPE_UNKNOWN:
						
						glObjectTypes.erase (id);
						glObjects.erase (id);
						break;
					
				}
				
			}
			
			gc_gl_id.clear ();
			
		}
		
		gc_gl_mutex.Unlock ();
		
	}
	
	
	void lime_gl_active_texture (int texture) {
		
		glActiveTexture (texture);
		
	}
	
	
	void lime_gl_attach_shader (value program, value shader) {
		
		glAttachShader (GLObjectID (program), GLObjectID (shader));
		
	}
	
	
	void lime_gl_bind_attrib_location (value program, int index, HxString name) {
		
		glBindAttribLocation (GLObjectID (program), index, name.__s);
		
	}
	
	
	void lime_gl_bind_buffer (int target, value buffer) {
		
		glBindBuffer (target, GLObjectID (buffer));
		
	}
	
	
	void lime_gl_bind_framebuffer (int target, value framebuffer) {
		
		GLuint id = GLObjectID (framebuffer);
		
		if (!id) {
			
			id = OpenGLBindings::defaultFramebuffer;
			
		}
		
		glBindFramebuffer (target, id);
		
	}
	
	
	void lime_gl_bind_renderbuffer (int target, value renderbuffer) {
		
		glBindRenderbuffer (target, GLObjectID (renderbuffer));
		
	}
	
	
	void lime_gl_bind_texture (int target, value texture) {
		
		glBindTexture (target, GLObjectID (texture));
		
	}
	
	
	void lime_gl_blend_color (float r, float g, float b, float a) {
		
		glBlendColor (r, g, b, a);
		
	}
	
	
	void lime_gl_blend_equation (int mode) {
		
		glBlendEquation (mode);
		
	}
	
	
	void lime_gl_blend_equation_separate (int rgb, int a) {
		
		glBlendEquationSeparate (rgb, a);
		
	}
	
	
	void lime_gl_blend_func (int sfactor, int dfactor) {
		
		glBlendFunc (sfactor, dfactor);
		
	}
	
	
	void lime_gl_blend_func_separate (int srcRGB, int destRGB, int srcAlpha, int destAlpha) {
		
		glBlendFuncSeparate (srcRGB, destRGB, srcAlpha, destAlpha);
		
	}
	
	
	void lime_gl_buffer_data (int target, int size, double data, int usage) {
		
		glBufferData (target, size, (void*)(uintptr_t)data, usage);
		
	}
	
	
	void lime_gl_buffer_sub_data (int target, int offset, int size, double data) {
		
		glBufferSubData (target, offset, size, (void*)(uintptr_t)data);
		
	}
	
	
	int lime_gl_check_framebuffer_status (int target) {
		
		return glCheckFramebufferStatus (target);
		
	}
	
	
	void lime_gl_clear (int mask) {
		
		gc_gl_run ();
		glClear (mask);
		
	}
	
	
	void lime_gl_clear_color (float red, float green, float blue, float alpha) {
		
		glClearColor (red, green, blue, alpha);
		
	}
	
	
	void lime_gl_clear_depthf (float depth) {
		
		#ifdef LIME_GLES
		glClearDepthf (depth);
		#else
		glClearDepth (depth);
		#endif
		
	}
	
	
	void lime_gl_clear_stencil (int stencil) {
		
		glClearStencil (stencil);
		
	}
	
	
	void lime_gl_color_mask (bool red, bool green, bool blue, bool alpha) {
		
		glColorMask (red, green, blue, alpha);
		
	}
	
	
	void lime_gl_compile_shader (value shader) {
		
		glCompileShader (GLObjectID (shader));
		
	}
	
	
	void lime_gl_compressed_tex_image_2d (int target, int level, int internalformat, int width, int height, int border, int imageSize, double data) {
		
		glCompressedTexImage2D (target, level, internalformat, width, height, border, imageSize, (void*)(uintptr_t)data);
		
	}
	
	
	void lime_gl_compressed_tex_sub_image_2d (int target, int level, int xoffset, int yoffset, int width, int height, int format, int imageSize, double data) {
		
		glCompressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, imageSize, (void*)(uintptr_t)data);
		
	}
	
	
	void lime_gl_copy_tex_image_2d (int target, int level, int internalformat, int x, int y, int width, int height, int border) {
		
		glCopyTexImage2D (target, level, internalformat, x, y, width, height, border);
		
	}
	
	
	void lime_gl_copy_tex_sub_image_2d (int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) {
		
		glCopyTexSubImage2D (target, level, xoffset, yoffset, x, y, width, height);
		
	}
	
	
	value lime_gl_create_buffer () {
		
		GLuint id;
		glGenBuffers (1, &id);
		return GLObjectFromID (TYPE_BUFFER, id);
		
	}
	
	
	value lime_gl_create_framebuffer () {
		
		GLuint id = 0;
		glGenFramebuffers (1, &id);
		return GLObjectFromID (TYPE_FRAMEBUFFER, id);
		
	}
	
	
	value lime_gl_create_program () {
		
		GLuint id = glCreateProgram ();
		return GLObjectFromID (TYPE_PROGRAM, id);
		
	}
	
	
	value lime_gl_create_renderbuffer () {
		
		GLuint id = 0;
		glGenRenderbuffers (1, &id);
		return GLObjectFromID (TYPE_RENDERBUFFER, id);
		
	}
	
	
	value lime_gl_create_shader (int type) {
		
		GLuint id = glCreateShader (type);
		return GLObjectFromID (TYPE_SHADER, id);
		
	}
	
	
	value lime_gl_create_texture () {
		
		GLuint id = 0;
		glGenTextures (1, &id);
		return GLObjectFromID (TYPE_TEXTURE, id);
		
	}
	
	
	void lime_gl_cull_face (int mode) {
		
		glCullFace (mode);
		
	}
	
	
	void lime_gl_delete_buffer (value buffer) {
		
		GLuint id = GLObjectID (buffer);
		
		if (id) {
			
			val_gc (buffer, 0);
			glDeleteBuffers (1, &id);
			glObjectTypes.erase (id);
			glObjects.erase (id);
			
		}
		
	}
	
	
	void lime_gl_delete_framebuffer (value framebuffer) {
		
		GLuint id = GLObjectID (framebuffer);
		
		if (id) {
			
			val_gc (framebuffer, 0);
			glDeleteFramebuffers (1, &id);
			glObjectTypes.erase (id);
			glObjects.erase (id);
			
		}
		
	}
	
	
	void lime_gl_delete_program (value program) {
		
		GLuint id = GLObjectID (program);
		
		if (id) {
			
			val_gc (program, 0);
			glDeleteProgram (id);
			glObjectTypes.erase (id);
			glObjects.erase (id);
			
		}
		
	}
	
	
	void lime_gl_delete_renderbuffer (value renderbuffer) {
		
		GLuint id = GLObjectID (renderbuffer);
		
		if (id) {
			
			val_gc (renderbuffer, 0);
			glDeleteRenderbuffers (1, &id);
			glObjectTypes.erase (id);
			glObjects.erase (id);
			
		}
		
	}
	
	
	void lime_gl_delete_shader (value shader) {
		
		GLuint id = GLObjectID (shader);
		
		if (id) {
			
			val_gc (shader, 0);
			glDeleteShader (id);
			glObjectTypes.erase (id);
			glObjects.erase (id);
			
		}
		
	}
	
	
	void lime_gl_delete_texture (value texture) {
		
		GLuint id = GLObjectID (texture);
		
		if (id) {
			
			val_gc (texture, 0);
			glDeleteTextures (1, &id);
			glObjectTypes.erase (id);
			glObjects.erase (id);
			
		}
		
	}
	
	
	void lime_gl_depth_func (int func) {
		
		glDepthFunc (func);
		
	}
	
	
	void lime_gl_depth_mask (bool flag) {
		
		glDepthMask (flag);
		
	}
	
	
	void lime_gl_depth_rangef (float zNear, float zFar) {
		
		#ifdef LIME_GLES
		glDepthRangef (zNear, zFar);
		#else
		glDepthRange (zNear, zFar);
		#endif
		
	}
	
	
	void lime_gl_detach_shader (value program, value shader) {
		
		glDetachShader (GLObjectID (program), GLObjectID (shader));
		
	}
	
	
	void lime_gl_disable (int cap) {
		
		glDisable (cap);
		
	}
	
	
	void lime_gl_disable_vertex_attrib_array (int index) {
		
		glDisableVertexAttribArray (index);
		
	}
	
	
	void lime_gl_draw_arrays (int mode, int first, int count) {
		
		glDrawArrays (mode, first, count);
		
	}
	
	
	void lime_gl_draw_elements (int mode, int count, int type, double offset) {
		
		glDrawElements (mode, count, type, (void*)(uintptr_t)offset);
		
	}
	
	
	void lime_gl_enable (int cap) {
		
		glEnable (cap);
		
	}
	
	
	void lime_gl_enable_vertex_attrib_array (int index) {
		
		glEnableVertexAttribArray (index);
		
	}
	
	
	void lime_gl_finish () {
		
		glFinish ();
		
	}
	
	
	void lime_gl_flush () {
		
		glFlush ();
		
	}
	
	
	void lime_gl_framebuffer_renderbuffer (int target, int attachment, int renderbuffertarget, value renderbuffer) {
		
		glFramebufferRenderbuffer (target, attachment, renderbuffertarget, GLObjectID (renderbuffer));
		
	}
	
	
	void lime_gl_framebuffer_texture2D (int target, int attachment, int textarget, value texture, int level) {
		
		glFramebufferTexture2D (target, attachment, textarget, GLObjectID (texture), level);
		
	}
	
	
	void lime_gl_front_face (int face) {
		
		glFrontFace (face);
		
	}
	
	
	void lime_gl_generate_mipmap (int target) {
		
		glGenerateMipmap (target);
		
	}
	
	
	value lime_gl_get_active_attrib (value program, int index) {
		
		value result = alloc_empty_object ();
		
		std::string buffer (GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, 0);
		GLsizei outLen = 0;
		GLsizei size = 0;
		GLenum  type = 0;
		
		glGetActiveAttrib (GLObjectID (program), index, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &outLen, &size, &type, &buffer[0]);
		
		buffer.resize (outLen);
		
		alloc_field (result, val_id ("size"), alloc_int (size));
		alloc_field (result, val_id ("type"), alloc_int (type));
		alloc_field (result, val_id ("name"), alloc_string (buffer.c_str ()));
		
		return result;
		
	}
	
	
	value lime_gl_get_active_uniform (value program, int index) {
		
		std::string buffer (GL_ACTIVE_UNIFORM_MAX_LENGTH, 0);
		GLsizei outLen = 0;
		GLsizei size = 0;
		GLenum  type = 0;
		
		glGetActiveUniform (GLObjectID (program), index, GL_ACTIVE_UNIFORM_MAX_LENGTH, &outLen, &size, &type, &buffer[0]);
		
		buffer.resize (outLen);
		
		value result = alloc_empty_object ();
		alloc_field (result, val_id ("size"), alloc_int (size));
		alloc_field (result, val_id ("type"), alloc_int (type));
		alloc_field (result, val_id ("name"), alloc_string (buffer.c_str ()));
		
		return result;
		
	}
	
	
	value lime_gl_get_attached_shaders (value program) {
		
		GLuint id = GLObjectID (program);
		GLsizei maxCount = 0;
		
		glGetProgramiv (id, GL_ATTACHED_SHADERS, &maxCount);
		
		if (!maxCount) {
			
			return alloc_null ();
			
		}
		
		GLsizei count;
		GLuint* shaders = new GLuint[maxCount];
		
		glGetAttachedShaders (id, maxCount, &count, shaders);
		
		value data = alloc_array (maxCount);
		
		for (int i = 0; i < maxCount; i++) {
			
			val_array_set_i (data, i, GLObjectFromID (TYPE_SHADER, shaders[i]));
			
		}
		
		delete[] shaders;
		return data;
		
	}
	
	
	int lime_gl_get_attrib_location (value program, HxString name) {
		
		return glGetAttribLocation (GLObjectID (program), name.__s);
		
	}
	
	
	int lime_gl_get_buffer_parameteri (int target, int index) {
		
		GLint params = 0;
		glGetBufferParameteriv (target, index, &params);
		return params;
		
	}
	
	
	void lime_gl_get_buffer_parameteriv (int target, int index, double params) {
		
		glGetBufferParameteriv (target, index, (GLint*)(uintptr_t)params);
		
	}
	
	
	bool lime_gl_get_boolean (int pname) {
		
		unsigned char params;
		glGetBooleanv (pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_booleanv (int pname, double params) {
		
		glGetBooleanv (pname, (unsigned char*)(uintptr_t)params);
		
	}
	
	
	value lime_gl_get_context_attributes () {
		
		value result = alloc_empty_object ();
		
		alloc_field (result, val_id ("alpha"), alloc_bool (true));
		alloc_field (result, val_id ("depth"), alloc_bool (true));
		alloc_field (result, val_id ("stencil"), alloc_bool (true));
		alloc_field (result, val_id ("antialias"), alloc_bool (true));
		
		return result;
		
	}
	
	
	int lime_gl_get_error () {
		
		return glGetError ();
		
	}
	
	
	value lime_gl_get_extension (HxString name) {
		
		void *result = 0;
		
		#ifdef LIME_SDL
		result = SDL_GL_GetProcAddress (name.__s);
		#endif
		
		if (result) {
			
			static bool init = false;
			static vkind functionKind;
			
			if (!init) {
				
				init = true;
				kind_share (&functionKind, "function");
				
			}
			
			return alloc_abstract (functionKind, result);
			
		}
		
		return alloc_null ();
		
	}
	
	
	float lime_gl_get_float (int pname) {
		
		GLfloat params;
		glGetFloatv (pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_floatv (int pname, double params) {
		
		glGetFloatv (pname, (GLfloat*)(uintptr_t)params);
		
	}
	
	
	int lime_gl_get_framebuffer_attachment_parameteri (int target, int attachment, int pname) {
		
		GLint params = 0;
		glGetFramebufferAttachmentParameteriv (target, attachment, pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_framebuffer_attachment_parameteriv (int target, int attachment, int pname, double params) {
		
		glGetFramebufferAttachmentParameteriv (target, attachment, pname, (GLint*)(uintptr_t)params);
		
	}
	
	
	int lime_gl_get_integer (int pname) {
		
		GLint params;
		glGetIntegerv (pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_integerv (int pname, double params) {
		
		glGetIntegerv (pname, (GLint*)(uintptr_t)params);
		
	}
	
	
	value lime_gl_get_program_info_log (value handle) {
		
		GLuint program = GLObjectID (handle);
		
		GLint logSize = 0;
		glGetProgramiv (program, GL_INFO_LOG_LENGTH, &logSize);
		
		if (logSize == 0) {
			
			return alloc_null ();
			
		}
		
		std::string buffer (logSize, 0);
		
		glGetProgramInfoLog (program, logSize, 0, &buffer[0]);
		
		return alloc_string (buffer.c_str ());
		
	}
	
	
	int lime_gl_get_programi (value program, int pname) {
		
		GLint params = 0;
		glGetProgramiv (GLObjectID (program), pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_programiv (value program, int pname, double params) {
		
		glGetProgramiv (GLObjectID (program), pname, (GLint*)(uintptr_t)params);
		
	}
	
	
	int lime_gl_get_renderbuffer_parameteri (int target, int pname) {
		
		GLint params = 0;
		glGetRenderbufferParameteriv (target, pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_renderbuffer_parameteriv (int target, int pname, double params) {
		
		glGetRenderbufferParameteriv (target, pname, (GLint*)(uintptr_t)params);
		
	}
	
	
	value lime_gl_get_shader_info_log (value handle) {
		
		GLuint shader = GLObjectID (handle);
		
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
	
	
	int lime_gl_get_shaderi (value shader, int pname) {
		
		GLint params = 0;
		glGetShaderiv (GLObjectID (shader), pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_shaderiv (value shader, int pname, double params) {
		
		glGetShaderiv (GLObjectID (shader), pname, (GLint*)(uintptr_t)params);
		
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
	
	
	value lime_gl_get_shader_source (value shader) {
		
		GLuint id = GLObjectID (shader);
		
		GLint len = 0;
		glGetShaderiv (id, GL_SHADER_SOURCE_LENGTH, &len);
		
		if (len == 0) {
			
			return alloc_null ();
			
		}
		
		char *buf = new char[len + 1];
		glGetShaderSource (id, len + 1, 0, buf);
		value result = alloc_string (buf);
		
		delete [] buf;
		
		return result;
		
	}
	
	
	value lime_gl_get_string (int pname) {
		
		const char* val = (const char*)glGetString (pname);
		
		if (val) {
			
			return alloc_string (val);
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	float lime_gl_get_tex_parameterf (int target, int pname) {
		
		GLfloat params = 0;
		glGetTexParameterfv (target, pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_tex_parameterfv (int target, int pname, double params) {
		
		glGetTexParameterfv (target, pname, (GLfloat*)(uintptr_t)params);
		
	}
	
	
	int lime_gl_get_tex_parameteri (int target, int pname) {
		
		GLint params = 0;
		glGetTexParameteriv (target, pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_tex_parameteriv (int target, int pname, double params) {
		
		glGetTexParameteriv (target, pname, (GLint*)(uintptr_t)params);
		
	}
	
	
	float lime_gl_get_uniformf (value program, int location) {
		
		GLfloat params = 0;
		glGetUniformfv (GLObjectID (program), location, &params);
		return params;
		
	}
	
	
	void lime_gl_get_uniformfv (value program, int location, double params) {
		
		glGetUniformfv (GLObjectID (program), location, (GLfloat*)(uintptr_t)params);
		
	}
	
	
	int lime_gl_get_uniformi (value program, int location) {
		
		GLint params = 0;
		glGetUniformiv (GLObjectID (program), location, &params);
		return params;
		
	}
	
	
	void lime_gl_get_uniformiv (value program, int location, double params) {
		
		glGetUniformiv (GLObjectID (program), location, (GLint*)(uintptr_t)params);
		
	}
	
	
	int lime_gl_get_uniform_location (value program, HxString name) {
		
		return glGetUniformLocation (GLObjectID (program), name.__s);
		
	}
	
	
	int lime_gl_get_vertex_attribi (int index, int pname) {
		
		GLint params = 0;
		glGetVertexAttribiv (index, pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_vertex_attribiv (int index, int pname, double params) {
		
		glGetVertexAttribiv (index, pname, (GLint*)(uintptr_t)params);
		
	}
	
	
	double lime_gl_get_vertex_attrib_pointerv (int index, int pname) {
		
		uintptr_t result = 0;
		glGetVertexAttribPointerv (index, pname, (void**)result);
		return (double)result;
		
	}
	
	
	void lime_gl_hint (int target, int mode) {
		
		glHint (target, mode);
		
	}
	
	
	bool lime_gl_is_buffer (value handle) {
		
		return glIsBuffer (GLObjectID (handle));
		
	}
	
	
	bool lime_gl_is_enabled (int cap) {
		
		return glIsEnabled (cap);
		
	}
	
	
	bool lime_gl_is_framebuffer (value handle) {
		
		return glIsFramebuffer (GLObjectID (handle));
		
	}
	
	
	bool lime_gl_is_program (value handle) {
		
		return glIsProgram (GLObjectID (handle));
		
	}
	
	
	bool lime_gl_is_renderbuffer (value handle) {
		
		return glIsRenderbuffer (GLObjectID (handle));
		
	}
	
	
	bool lime_gl_is_shader (value handle) {
		
		return glIsShader (GLObjectID (handle));
		
	}
	
	
	bool lime_gl_is_texture (value handle) {
		
		return glIsTexture (GLObjectID (handle));
		
	}
	
	
	void lime_gl_line_width (float width) {
		
		glLineWidth (width);
		
	}
	
	
	void lime_gl_link_program (value program) {
		
		glLinkProgram (GLObjectID (program));
		
	}
	
	
	void lime_gl_object_constructor (value constructor) {
		
		value* root = alloc_root ();
		*root = constructor;
		
		if (glObjectConstructorRoot) {
			
			free_root (glObjectConstructorRoot);
			
		}
		
		glObjectConstructorRoot = root;
		glObjectConstructor = constructor;
		
	}
	
	
	value lime_gl_object_from_id (int type, int id) {
		
		GLObjectType _type = (GLObjectType)type;
		
		if (glObjectTypes.find (id) != glObjectTypes.end () && glObjectTypes[id] != _type) {
			
			return alloc_null ();
			
		} else {
			
			return GLObjectFromID (_type, id);
			
		}
		
	}
	
	
	void lime_gl_pixel_storei (int pname, int param) {
		
		glPixelStorei (pname, param);
		
	}
	
	
	void lime_gl_polygon_offset (float factor, float units) {
		
		glPolygonOffset (factor, units);
		
	}
	
	
	void lime_gl_read_pixels (int x, int y, int width, int height, int format, int type, double pixels) {
		
		glReadPixels (x, y, width, height, format, type, (void*)(uintptr_t)pixels);
		
	}
	
	
	void lime_gl_renderbuffer_storage (int target, int internalformat, int width, int height) {
		
		glRenderbufferStorage (target, internalformat, width, height);
		
	}
	
	
	void lime_gl_sample_coverage (float val, bool invert) {
		
		glSampleCoverage (val, invert);
		
	}
	
	
	void lime_gl_scissor (int x, int y, int width, int height) {
		
		glScissor (x, y, width, height);
		
	}
	
	
	void lime_gl_shader_source (value handle, HxString source) {
		
		glShaderSource (GLObjectID (handle), 1, &source.__s, 0);
		
	}
	
	
	void lime_gl_stencil_func (int func, int ref, int mask) {
		
		glStencilFunc (func, ref, mask);
		
	}
	
	
	void lime_gl_stencil_func_separate (int face, int func, int ref, int mask) {
		
		glStencilFuncSeparate (face, func, ref, mask);
		
	}
	
	
	void lime_gl_stencil_mask (int mask) {
		
		glStencilMask (mask);
		
	}
	
	
	void lime_gl_stencil_mask_separate (int face, int mask) {
		
		glStencilMaskSeparate (face, mask);
		
	}
	
	
	void lime_gl_stencil_op (int sfail, int dpfail, int dppass) {
		
		glStencilOp (sfail, dpfail, dppass);
		
	}
	
	
	void lime_gl_stencil_op_separate (int face, int sfail, int dpfail, int dppass) {
		
		glStencilOpSeparate (face, sfail, dpfail, dppass);
		
	}
	
	
	void lime_gl_tex_image_2d (int target, int level, int internalformat, int width, int height, int border, int format, int type, double data) {
		
		glTexImage2D (target, level, internalformat, width, height, border, format, type, (void*)(uintptr_t)data);
		
	}
	
	
	void lime_gl_tex_parameterf (int target, int pname, float param) {
		
		glTexParameterf (target, pname, param);
		
	}
	
	
	void lime_gl_tex_parameteri (int target, int pname, int param) {
		
		glTexParameterf (target, pname, param);
		
	}
	
	
	void lime_gl_tex_sub_image_2d (int target, int level, int xoffset, int yoffset, int width, int height, int format, int type, double data) {
		
		glTexSubImage2D (target, level, xoffset, yoffset, width, height, format, type, (void*)(uintptr_t)data);
		
	}
	
	
	void lime_gl_uniform1f (int location, float v0) {
		
		glUniform1f (location, v0);
		
	}
	
	
	void lime_gl_uniform1fv (int location, int count, double _value) {
		
		glUniform1fv (location, count, (GLfloat*)(uintptr_t)_value);
		
	}
	
	
	void lime_gl_uniform1i (int location, int v0) {
		
		glUniform1i (location, v0);
		
	}
	
	
	void lime_gl_uniform1iv (int location, int count, double _value) {
		
		glUniform1iv (location, count, (GLint*)(uintptr_t)_value);
		
	}
	
	
	void lime_gl_uniform2f (int location, float v0, float v1) {
		
		glUniform2f (location, v0, v1);
		
	}
	
	
	void lime_gl_uniform2fv (int location, int count, double _value) {
		
		glUniform2fv (location, count, (GLfloat*)(uintptr_t)_value);
		
	}
	
	
	void lime_gl_uniform2i (int location, int v0, int v1) {
		
		glUniform2i (location, v0, v1);
		
	}
	
	
	void lime_gl_uniform2iv (int location, int count, double _value) {
		
		glUniform2iv (location, count, (GLint*)(uintptr_t)_value);
		
	}
	
	
	void lime_gl_uniform3f (int location, float v0, float v1, float v2) {
		
		glUniform3f (location, v0, v1, v2);
		
	}
	
	
	void lime_gl_uniform3fv (int location, int count, double _value) {
		
		glUniform3fv (location, count, (GLfloat*)(uintptr_t)_value);
		
	}
	
	
	void lime_gl_uniform3i (int location, int v0, int v1, int v2) {
		
		glUniform3i (location, v0, v1, v2);
		
	}
	
	
	void lime_gl_uniform3iv (int location, int count, double _value) {
		
		glUniform3iv (location, count, (GLint*)(uintptr_t)_value);
		
	}
	
	
	void lime_gl_uniform4f (int location, float v0, float v1, float v2, float v3) {
		
		glUniform4f (location, v0, v1, v2, v3);
		
	}
	
	
	void lime_gl_uniform4fv (int location, int count, double _value) {
		
		glUniform4fv (location, count, (GLfloat*)(uintptr_t)_value);
		
	}
	
	
	void lime_gl_uniform4i (int location, int v0, int v1, int v2, int v3) {
		
		glUniform4i (location, v0, v1, v2, v3);
		
	}
	
	
	void lime_gl_uniform4iv (int location, int count, double _value) {
		
		glUniform4iv (location, count, (GLint*)(uintptr_t)_value);
		
	}
	
	
	void lime_gl_uniform_matrix2fv (int location, int count, bool transpose, double _value) {
		
		glUniformMatrix2fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		
	}
	
	
	void lime_gl_uniform_matrix3fv (int location, int count, bool transpose, double _value) {
		
		glUniformMatrix3fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		
	}
	
	
	void lime_gl_uniform_matrix4fv (int location, int count, bool transpose, double _value) {
		
		glUniformMatrix4fv (location, count, transpose, (GLfloat*)(uintptr_t)_value);
		
	}
	
	
	void lime_gl_use_program (value handle) {
		
		glUseProgram (GLObjectID (handle));
		
	}
	
	
	void lime_gl_validate_program (value handle) {
		
		glValidateProgram (GLObjectID (handle));
		
	}
	
	
	void lime_gl_vertex_attrib_pointer (int index, int size, int type, bool normalized, int stride, double offset) {
		
		glVertexAttribPointer (index, size, type, normalized, stride, (void*)(uintptr_t)offset);
		
	}
	
	
	void lime_gl_vertex_attrib1f (int index, float v0) {
		
		glVertexAttrib1f (index, v0);
		
	}
	
	
	void lime_gl_vertex_attrib1fv (int index, double v) {
		
		glVertexAttrib1fv (index, (GLfloat*)(uintptr_t)v);
		
	}
	
	
	void lime_gl_vertex_attrib2f (int index, float v0, float v1) {
		
		glVertexAttrib2f (index, v0, v1);
		
	}
	
	
	void lime_gl_vertex_attrib2fv (int index, double v) {
		
		glVertexAttrib2fv (index, (GLfloat*)(uintptr_t)v);
		
	}
	
	
	void lime_gl_vertex_attrib3f (int index, float v0, float v1, float v2) {
		
		glVertexAttrib3f (index, v0, v1, v2);
		
	}
	
	
	void lime_gl_vertex_attrib3fv (int index, double v) {
		
		glVertexAttrib3fv (index, (GLfloat*)(uintptr_t)v);
		
	}
	
	
	void lime_gl_vertex_attrib4f (int index, float v0, float v1, float v2, float v3) {
		
		glVertexAttrib4f (index, v0, v1, v2, v3);
		
	}
	
	
	void lime_gl_vertex_attrib4fv (int index, double v) {
		
		glVertexAttrib4fv (index, (GLfloat*)(uintptr_t)v);
		
	}
	
	
	void lime_gl_viewport (int x, int y, int width, int height) {
		
		glViewport (x, y, width, height);
		
	}
	
	
	bool OpenGLBindings::Init () {
		
		static bool result = true;
		
		if (!initialized) {
			
			initialized = true;
			
			id_id = val_id ("id");
			
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
	DEFINE_PRIME3v (lime_gl_bind_attrib_location);
	DEFINE_PRIME2v (lime_gl_bind_buffer);
	DEFINE_PRIME2v (lime_gl_bind_framebuffer);
	DEFINE_PRIME2v (lime_gl_bind_renderbuffer);
	DEFINE_PRIME2v (lime_gl_bind_texture);
	DEFINE_PRIME4v (lime_gl_blend_color);
	DEFINE_PRIME1v (lime_gl_blend_equation);
	DEFINE_PRIME2v (lime_gl_blend_equation_separate);
	DEFINE_PRIME2v (lime_gl_blend_func);
	DEFINE_PRIME4v (lime_gl_blend_func_separate);
	DEFINE_PRIME4v (lime_gl_buffer_data);
	DEFINE_PRIME4v (lime_gl_buffer_sub_data);
	DEFINE_PRIME1 (lime_gl_check_framebuffer_status);
	DEFINE_PRIME1v (lime_gl_clear);
	DEFINE_PRIME4v (lime_gl_clear_color);
	DEFINE_PRIME1v (lime_gl_clear_depthf);
	DEFINE_PRIME1v (lime_gl_clear_stencil);
	DEFINE_PRIME4v (lime_gl_color_mask);
	DEFINE_PRIME1v (lime_gl_compile_shader);
	DEFINE_PRIME8v (lime_gl_compressed_tex_image_2d);
	DEFINE_PRIME9v (lime_gl_compressed_tex_sub_image_2d);
	DEFINE_PRIME8v (lime_gl_copy_tex_image_2d);
	DEFINE_PRIME8v (lime_gl_copy_tex_sub_image_2d);
	DEFINE_PRIME0 (lime_gl_create_buffer);
	DEFINE_PRIME0 (lime_gl_create_framebuffer);
	DEFINE_PRIME0 (lime_gl_create_program);
	DEFINE_PRIME0 (lime_gl_create_renderbuffer);
	DEFINE_PRIME1 (lime_gl_create_shader);
	DEFINE_PRIME0 (lime_gl_create_texture);
	DEFINE_PRIME1v (lime_gl_cull_face);
	DEFINE_PRIME1v (lime_gl_delete_buffer);
	DEFINE_PRIME1v (lime_gl_delete_framebuffer);
	DEFINE_PRIME1v (lime_gl_delete_program);
	DEFINE_PRIME1v (lime_gl_delete_renderbuffer);
	DEFINE_PRIME1v (lime_gl_delete_shader);
	DEFINE_PRIME1v (lime_gl_delete_texture);
	DEFINE_PRIME2v (lime_gl_detach_shader);
	DEFINE_PRIME1v (lime_gl_depth_func);
	DEFINE_PRIME1v (lime_gl_depth_mask);
	DEFINE_PRIME2v (lime_gl_depth_rangef);
	DEFINE_PRIME1v (lime_gl_disable);
	DEFINE_PRIME1v (lime_gl_disable_vertex_attrib_array);
	DEFINE_PRIME3v (lime_gl_draw_arrays);
	DEFINE_PRIME4v (lime_gl_draw_elements);
	DEFINE_PRIME1v (lime_gl_enable);
	DEFINE_PRIME1v (lime_gl_enable_vertex_attrib_array);
	DEFINE_PRIME0v (lime_gl_finish);
	DEFINE_PRIME0v (lime_gl_flush);
	DEFINE_PRIME4v (lime_gl_framebuffer_renderbuffer);
	DEFINE_PRIME5v (lime_gl_framebuffer_texture2D);
	DEFINE_PRIME1v (lime_gl_front_face);
	DEFINE_PRIME1v (lime_gl_generate_mipmap);
	DEFINE_PRIME2 (lime_gl_get_active_attrib);
	DEFINE_PRIME2 (lime_gl_get_active_uniform);
	DEFINE_PRIME1 (lime_gl_get_attached_shaders);
	DEFINE_PRIME2 (lime_gl_get_attrib_location);
	DEFINE_PRIME2 (lime_gl_get_buffer_parameteri);
	DEFINE_PRIME3v (lime_gl_get_buffer_parameteriv);
	DEFINE_PRIME1 (lime_gl_get_boolean);
	DEFINE_PRIME2v (lime_gl_get_booleanv);
	DEFINE_PRIME0 (lime_gl_get_context_attributes);
	DEFINE_PRIME0 (lime_gl_get_error);
	DEFINE_PRIME1 (lime_gl_get_extension);
	DEFINE_PRIME1 (lime_gl_get_float);
	DEFINE_PRIME2v (lime_gl_get_floatv);
	DEFINE_PRIME3 (lime_gl_get_framebuffer_attachment_parameteri);
	DEFINE_PRIME4v (lime_gl_get_framebuffer_attachment_parameteriv);
	DEFINE_PRIME1 (lime_gl_get_integer);
	DEFINE_PRIME2v (lime_gl_get_integerv);
	DEFINE_PRIME1 (lime_gl_get_program_info_log);
	DEFINE_PRIME2 (lime_gl_get_programi);
	DEFINE_PRIME3v (lime_gl_get_programiv);
	DEFINE_PRIME2 (lime_gl_get_renderbuffer_parameteri);
	DEFINE_PRIME3v (lime_gl_get_renderbuffer_parameteriv);
	DEFINE_PRIME1 (lime_gl_get_shader_info_log);
	DEFINE_PRIME2 (lime_gl_get_shaderi);
	DEFINE_PRIME3v (lime_gl_get_shaderiv);
	DEFINE_PRIME2 (lime_gl_get_shader_precision_format);
	DEFINE_PRIME1 (lime_gl_get_shader_source);
	DEFINE_PRIME1 (lime_gl_get_string);
	DEFINE_PRIME2 (lime_gl_get_tex_parameterf);
	DEFINE_PRIME3v (lime_gl_get_tex_parameterfv);
	DEFINE_PRIME2 (lime_gl_get_tex_parameteri);
	DEFINE_PRIME3v (lime_gl_get_tex_parameteriv);
	DEFINE_PRIME2 (lime_gl_get_uniformf);
	DEFINE_PRIME3v (lime_gl_get_uniformfv);
	DEFINE_PRIME2 (lime_gl_get_uniformi);
	DEFINE_PRIME3v (lime_gl_get_uniformiv);
	DEFINE_PRIME2 (lime_gl_get_uniform_location);
	DEFINE_PRIME2 (lime_gl_get_vertex_attribi);
	DEFINE_PRIME3v (lime_gl_get_vertex_attribiv);
	DEFINE_PRIME2 (lime_gl_get_vertex_attrib_pointerv);
	DEFINE_PRIME2v (lime_gl_hint);
	DEFINE_PRIME1 (lime_gl_is_buffer);
	DEFINE_PRIME1 (lime_gl_is_enabled);
	DEFINE_PRIME1 (lime_gl_is_framebuffer);
	DEFINE_PRIME1 (lime_gl_is_program);
	DEFINE_PRIME1 (lime_gl_is_renderbuffer);
	DEFINE_PRIME1 (lime_gl_is_shader);
	DEFINE_PRIME1 (lime_gl_is_texture);
	DEFINE_PRIME1v (lime_gl_line_width);
	DEFINE_PRIME1v (lime_gl_link_program);
	DEFINE_PRIME1v (lime_gl_object_constructor);
	DEFINE_PRIME2 (lime_gl_object_from_id);
	DEFINE_PRIME2v (lime_gl_pixel_storei);
	DEFINE_PRIME2v (lime_gl_polygon_offset);
	DEFINE_PRIME7v (lime_gl_read_pixels);
	DEFINE_PRIME4v (lime_gl_renderbuffer_storage);
	DEFINE_PRIME2v (lime_gl_sample_coverage);
	DEFINE_PRIME4v (lime_gl_scissor);
	DEFINE_PRIME2v (lime_gl_shader_source);
	DEFINE_PRIME3v (lime_gl_stencil_func);
	DEFINE_PRIME4v (lime_gl_stencil_func_separate);
	DEFINE_PRIME1v (lime_gl_stencil_mask);
	DEFINE_PRIME2v (lime_gl_stencil_mask_separate);
	DEFINE_PRIME3v (lime_gl_stencil_op);
	DEFINE_PRIME4v (lime_gl_stencil_op_separate);
	DEFINE_PRIME9v (lime_gl_tex_image_2d);
	DEFINE_PRIME3v (lime_gl_tex_parameterf);
	DEFINE_PRIME3v (lime_gl_tex_parameteri);
	DEFINE_PRIME9v (lime_gl_tex_sub_image_2d);
	DEFINE_PRIME2v (lime_gl_uniform1f);
	DEFINE_PRIME3v (lime_gl_uniform1fv);
	DEFINE_PRIME2v (lime_gl_uniform1i);
	DEFINE_PRIME3v (lime_gl_uniform1iv);
	DEFINE_PRIME3v (lime_gl_uniform2f);
	DEFINE_PRIME3v (lime_gl_uniform2fv);
	DEFINE_PRIME3v (lime_gl_uniform2i);
	DEFINE_PRIME3v (lime_gl_uniform2iv);
	DEFINE_PRIME4v (lime_gl_uniform3f);
	DEFINE_PRIME3v (lime_gl_uniform3fv);
	DEFINE_PRIME4v (lime_gl_uniform3i);
	DEFINE_PRIME3v (lime_gl_uniform3iv);
	DEFINE_PRIME5v (lime_gl_uniform4f);
	DEFINE_PRIME3v (lime_gl_uniform4fv);
	DEFINE_PRIME5v (lime_gl_uniform4i);
	DEFINE_PRIME3v (lime_gl_uniform4iv);
	DEFINE_PRIME4v (lime_gl_uniform_matrix2fv);
	DEFINE_PRIME4v (lime_gl_uniform_matrix3fv);
	DEFINE_PRIME4v (lime_gl_uniform_matrix4fv);
	DEFINE_PRIME1v (lime_gl_use_program);
	DEFINE_PRIME1v (lime_gl_validate_program);
	DEFINE_PRIME4v (lime_gl_viewport);
	DEFINE_PRIME6v (lime_gl_vertex_attrib_pointer);
	DEFINE_PRIME2v (lime_gl_vertex_attrib1f);
	DEFINE_PRIME2v (lime_gl_vertex_attrib1fv);
	DEFINE_PRIME3v (lime_gl_vertex_attrib2f);
	DEFINE_PRIME2v (lime_gl_vertex_attrib2fv);
	DEFINE_PRIME4v (lime_gl_vertex_attrib3f);
	DEFINE_PRIME2v (lime_gl_vertex_attrib3fv);
	DEFINE_PRIME5v (lime_gl_vertex_attrib4f);
	DEFINE_PRIME2v (lime_gl_vertex_attrib4fv);
	
	
}


extern "C" int lime_opengl_register_prims () {
	
	return 0;
	
}