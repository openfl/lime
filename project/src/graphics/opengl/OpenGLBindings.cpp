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
	
	
	std::map<GLObjectType, std::map <GLuint, value> > glObjects;
	std::map<value, GLuint> glObjectIDs;
	std::map<value, GLObjectType> glObjectTypes;
	
	std::vector<GLuint> gc_gl_id;
	std::vector<GLObjectType> gc_gl_type;
	Mutex gc_gl_mutex;
	
	void gc_gl_object (value object) {
		
		gc_gl_mutex.Lock ();
		
		if (glObjectIDs.find (object) != glObjectIDs.end ()) {
			
			GLuint id = glObjectIDs[object];
			GLObjectType type = glObjectTypes[object];
			
			gc_gl_id.push_back (id);
			gc_gl_type.push_back (type);
			
			glObjects[type].erase (id);
			glObjectIDs.erase (object);
			glObjectTypes.erase (object);
			
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
					
					case TYPE_RENDERBUFFER:
						
						if (glIsProgram (id)) glDeleteRenderbuffers (1, &id);
						break;
					
					case TYPE_SHADER:
						
						if (glIsShader (id)) glDeleteShader (id);
						break;
					
					case TYPE_TEXTURE:
						
						if (glIsTexture (id)) glDeleteTextures (1, &id);
						break;
					
					default: break;
					
				}
				
			}
			
			gc_gl_id.clear ();
			gc_gl_type.clear ();
			
			gc_gl_mutex.Unlock ();
			
		}
		
	}
	
	
	void lime_gl_active_texture (int texture) {
		
		glActiveTexture (texture);
		
	}
	
	
	void lime_gl_attach_shader (int program, int shader) {
		
		glAttachShader (program, shader);
		
	}
	
	
	//void lime_gl_begin_query (int target, int query) {
		//
		//glBeginQuery (target, query);
		//
	//}
	
	
	void lime_gl_bind_attrib_location (int program, int index, HxString name) {
		
		glBindAttribLocation (program, index, name.__s);
		
	}
	
	
	void lime_gl_bind_buffer (int target, int buffer) {
		
		glBindBuffer (target, buffer);
		
	}
	
	
	void lime_gl_bind_framebuffer (int target, int framebuffer) {
		
		if (!framebuffer) {
			
			framebuffer = OpenGLBindings::defaultFramebuffer;
			
		}
		
		glBindFramebuffer (target, framebuffer);
		
	}
	
	
	void lime_gl_bind_renderbuffer (int target, int renderbuffer) {
		
		glBindRenderbuffer (target, renderbuffer);
		
	}
	
	
	void lime_gl_bind_texture (int target, int texture) {
		
		glBindTexture (target, texture);
		
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
	
	
	void lime_gl_compile_shader (int shader) {
		
		glCompileShader (shader);
		
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
	
	
	int lime_gl_create_buffer () {
		
		GLuint id = 0;
		glGenBuffers (1, &id);
		return id;
		
	}
	
	
	int lime_gl_create_framebuffer () {
		
		GLuint id = 0;
		glGenFramebuffers (1, &id);
		return id;
		
	}
	
	
	int lime_gl_create_program () {
		
		return glCreateProgram ();
		
	}
	
	
	int lime_gl_create_renderbuffer () {
		
		GLuint id = 0;
		glGenRenderbuffers (1, &id);
		return id;
		
	}
	
	
	int lime_gl_create_shader (int type) {
		
		return glCreateShader (type);
		
	}
	
	
	int lime_gl_create_texture () {
		
		GLuint id = 0;
		glGenTextures (1, &id);
		return id;
		
	}
	
	
	void lime_gl_cull_face (int mode) {
		
		glCullFace (mode);
		
	}
	
	
	void lime_gl_delete_buffer (int buffer) {
		
		glDeleteBuffers (1, (GLuint*)&buffer);
		
	}
	
	
	void lime_gl_delete_framebuffer (int framebuffer) {
		
		glDeleteFramebuffers (1, (GLuint*)&framebuffer);
		
	}
	
	
	void lime_gl_delete_program (int program) {
		
		glDeleteProgram (program);
		
	}
	
	
	void lime_gl_delete_renderbuffer (int renderbuffer) {
		
		glDeleteRenderbuffers (1, (GLuint*)&renderbuffer);
		
	}
	
	
	void lime_gl_delete_shader (int shader) {
		
		glDeleteShader (shader);
		
	}
	
	
	void lime_gl_delete_texture (int texture) {
		
		glDeleteTextures (1, (GLuint*)&texture);
		
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
	
	
	void lime_gl_detach_shader (int program, int shader) {
		
		glDetachShader (program, shader);
		
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
	
	
	void lime_gl_draw_buffers (value buffers) {
		
		GLsizei size = val_array_size (buffers);
		GLenum *_buffers = (GLenum*)alloca (size);
		
		for (int i = 0; i < size; i++) {
			
			_buffers[i] = val_int (val_array_i (buffers, i));
			
		}
		
		glDrawBuffers (size, _buffers);
		
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
	
	
	void lime_gl_framebuffer_renderbuffer (int target, int attachment, int renderbuffertarget, int renderbuffer) {
		
		glFramebufferRenderbuffer (target, attachment, renderbuffertarget, renderbuffer);
		
	}
	
	
	void lime_gl_framebuffer_texture2D (int target, int attachment, int textarget, int texture, int level) {
		
		glFramebufferTexture2D (target, attachment, textarget, texture, level);
		
	}
	
	
	void lime_gl_front_face (int face) {
		
		glFrontFace (face);
		
	}
	
	
	void lime_gl_generate_mipmap (int target) {
		
		glGenerateMipmap (target);
		
	}
	
	
	value lime_gl_get_active_attrib (int program, int index) {
		
		value result = alloc_empty_object ();
		
		std::string buffer (GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, 0);
		GLsizei outLen = 0;
		GLsizei size = 0;
		GLenum  type = 0;
		
		glGetActiveAttrib (program, index, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &outLen, &size, &type, &buffer[0]);
		
		buffer.resize (outLen);
		
		alloc_field (result, val_id ("size"), alloc_int (size));
		alloc_field (result, val_id ("type"), alloc_int (type));
		alloc_field (result, val_id ("name"), alloc_string (buffer.c_str ()));
		
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
	
	
	int lime_gl_get_attrib_location (int program, HxString name) {
		
		return glGetAttribLocation (program, name.__s);
		
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
	
	
	int lime_gl_get_programi (int program, int pname) {
		
		GLint params = 0;
		glGetProgramiv (program, pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_programiv (int program, int pname, double params) {
		
		glGetProgramiv (program, pname, (GLint*)(uintptr_t)params);
		
	}
	
	
	int lime_gl_get_renderbuffer_parameteri (int target, int pname) {
		
		GLint params = 0;
		glGetRenderbufferParameteriv (target, pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_renderbuffer_parameteriv (int target, int pname, double params) {
		
		glGetRenderbufferParameteriv (target, pname, (GLint*)(uintptr_t)params);
		
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
	
	
	int lime_gl_get_shaderi (int shader, int pname) {
		
		GLint params = 0;
		glGetShaderiv (shader, pname, &params);
		return params;
		
	}
	
	
	void lime_gl_get_shaderiv (int shader, int pname, double params) {
		
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
	
	
	float lime_gl_get_uniformf (int program, int location) {
		
		GLfloat params = 0;
		glGetUniformfv (program, location, &params);
		return params;
		
	}
	
	
	void lime_gl_get_uniformfv (int program, int location, double params) {
		
		glGetUniformfv (program, location, (GLfloat*)(uintptr_t)params);
		
	}
	
	
	int lime_gl_get_uniformi (int program, int location) {
		
		GLint params = 0;
		glGetUniformiv (program, location, &params);
		return params;
		
	}
	
	
	void lime_gl_get_uniformiv (int program, int location, double params) {
		
		glGetUniformiv (program, location, (GLint*)(uintptr_t)params);
		
	}
	
	
	int lime_gl_get_uniform_location (int program, HxString name) {
		
		return glGetUniformLocation (program, name.__s);
		
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
	
	
	bool lime_gl_is_buffer (int handle) {
		
		return glIsBuffer (handle);
		
	}
	
	
	bool lime_gl_is_enabled (int cap) {
		
		return glIsEnabled (cap);
		
	}
	
	
	bool lime_gl_is_framebuffer (int handle) {
		
		return glIsFramebuffer (handle);
		
	}
	
	
	bool lime_gl_is_program (int handle) {
		
		return glIsProgram (handle);
		
	}
	
	
	bool lime_gl_is_renderbuffer (int handle) {
		
		return glIsRenderbuffer (handle);
		
	}
	
	
	bool lime_gl_is_shader (int handle) {
		
		return glIsShader (handle);
		
	}
	
	
	bool lime_gl_is_texture (int handle) {
		
		return glIsTexture (handle);
		
	}
	
	
	void lime_gl_line_width (float width) {
		
		glLineWidth (width);
		
	}
	
	
	void lime_gl_link_program (int program) {
		
		glLinkProgram (program);
		
	}
	
	
	void lime_gl_object_deregister (value object) {
		
		val_gc (object, 0);
		
		if (glObjectIDs.find (object) != glObjectIDs.end ()) {
			
			GLuint id = glObjectIDs[object];
			GLObjectType type = glObjectTypes[object];
			
			glObjects[type].erase (id);
			glObjectTypes.erase (object);
			glObjectIDs.erase (object);
			
		}
		
	}
	
	
	value lime_gl_object_from_id (int id, int type) {
		
		GLObjectType _type = (GLObjectType)type;
		
		if (glObjects[_type].find (id) != glObjects[_type].end ()) {
			
			return glObjects[_type][id];
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	void lime_gl_object_register (int id, int type, value object) {
		
		GLObjectType _type = (GLObjectType)type;
		
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
		
		val_gc (object, gc_gl_object);
		
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
	
	
	void lime_gl_shader_source (int handle, HxString source) {
		
		glShaderSource (handle, 1, &source.__s, 0);
		
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
	
	
	void lime_gl_use_program (int handle) {
		
		glUseProgram (handle);
		
	}
	
	
	void lime_gl_validate_program (int handle) {
		
		glValidateProgram (handle);
		
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
	DEFINE_PRIME1v (lime_gl_draw_buffers);
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
	DEFINE_PRIME1v (lime_gl_object_deregister);
	DEFINE_PRIME2 (lime_gl_object_from_id);
	DEFINE_PRIME3v (lime_gl_object_register);
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