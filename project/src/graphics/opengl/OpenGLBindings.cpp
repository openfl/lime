#include <hx/CFFIPrimePatch.h>
//#include <hx/CFFIPrime.h>
#include <system/CFFIPointer.h>
#include <system/Mutex.h>
#include <utils/Bytes.h>
#include "OpenGL.h"
#include "OpenGLBindings.h"
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
	
	void lime_gl_delete_buffer (value handle);
	void lime_gl_delete_framebuffer (value handle);
	void lime_gl_delete_program (value handle);
	void lime_gl_delete_render_buffer (value handle);
	void lime_gl_delete_shader (value handle);
	void lime_gl_delete_texture (value handle);
	
	enum GCObjectType {
		
		GC_BUFFER,
		GC_FRAMEBUFFER,
		GC_PROGRAM,
		GC_RENDERBUFFER,
		GC_SHADER,
		GC_TEXTURE
		
	};
	
	std::vector<GCObjectType> gc_gl_type;
	std::vector<GLuint> gc_gl_id;
	Mutex gc_gl_mutex;
	
	
	void gc_gl_buffer (value handle) {
		
		gc_gl_mutex.Lock ();
		
		gc_gl_type.push_back (GC_BUFFER);
		gc_gl_id.push_back (reinterpret_cast<uintptr_t> (val_data (handle)));
		
		gc_gl_mutex.Unlock ();
		
	}
	
	
	void gc_gl_framebuffer (value handle) {
		
		gc_gl_mutex.Lock ();
		
		gc_gl_type.push_back (GC_FRAMEBUFFER);
		gc_gl_id.push_back (reinterpret_cast<uintptr_t> (val_data (handle)));
		
		gc_gl_mutex.Unlock ();
		
	}
	
	
	void gc_gl_program (value handle) {
		
		gc_gl_mutex.Lock ();
		
		gc_gl_type.push_back (GC_PROGRAM);
		gc_gl_id.push_back (reinterpret_cast<uintptr_t> (val_data (handle)));
		
		gc_gl_mutex.Unlock ();
		
	}
	
	
	void gc_gl_render_buffer (value handle) {
		
		gc_gl_mutex.Lock ();
		
		gc_gl_type.push_back (GC_RENDERBUFFER);
		gc_gl_id.push_back (reinterpret_cast<uintptr_t> (val_data (handle)));
		
		gc_gl_mutex.Unlock ();
		
	}
	
	
	void gc_gl_run () {
		
		gc_gl_mutex.Lock ();
		
		int size = gc_gl_type.size ();
		
		if (size > 0) {
			
			GCObjectType type;
			GLuint id;
			
			for (int i = 0; i < size; i++) {
				
				GCObjectType type = gc_gl_type[i];
				GLuint id = gc_gl_id[i];
				
				switch (type) {
					
					case GC_BUFFER:
						
						glDeleteBuffers (1, &id);
						break;
					
					case GC_FRAMEBUFFER:
						
						glDeleteFramebuffers (1, &id);
						break;
					
					case GC_PROGRAM:
						
						glDeleteProgram (id);
						break;
					
					case GC_RENDERBUFFER:
						
						glDeleteRenderbuffers (1, &id);
						break;
					
					case GC_SHADER:
						
						glDeleteShader (id);
						break;
					
					case GC_TEXTURE:
						
						glDeleteTextures (1, &id);
						break;
					
				}
				
			}
			
			gc_gl_type.clear ();
			gc_gl_id.clear ();
			
		}
		
		gc_gl_mutex.Unlock ();
		
	}
	
	
	void gc_gl_shader (value handle) {
		
		gc_gl_mutex.Lock ();
		
		gc_gl_type.push_back (GC_SHADER);
		gc_gl_id.push_back (reinterpret_cast<uintptr_t> (val_data (handle)));
		
		gc_gl_mutex.Unlock ();
		
	}
	
	
	void gc_gl_texture (value handle) {
		
		gc_gl_mutex.Lock ();
		
		gc_gl_type.push_back (GC_TEXTURE);
		gc_gl_id.push_back (reinterpret_cast<uintptr_t> (val_data (handle)));
		
		gc_gl_mutex.Unlock ();
		
	}
	
	
	void lime_gl_active_texture (int inSlot) {
		
		glActiveTexture (inSlot);
		
	}
	
	
	void lime_gl_attach_shader (value program, value shader) {
		
		glAttachShader (reinterpret_cast<uintptr_t> (val_data (program)), reinterpret_cast<uintptr_t> (val_data (shader)));
		
	}
	
	
	void lime_gl_bind_attrib_location (value handle, int inSlot, HxString inName) {
		
		glBindAttribLocation (reinterpret_cast<uintptr_t> (val_data (handle)), inSlot, inName.__s);
		
	}
	
	
	void lime_gl_bind_buffer (int target, value buffer) {
		
		glBindBuffer (target, val_is_null (buffer) ? 0 : reinterpret_cast<uintptr_t> (val_data (buffer)));
		
	}
	
	
	void lime_gl_bind_framebuffer (int target, value framebuffer) {
		
		glBindFramebuffer (target, val_is_null (framebuffer) ? 0 : reinterpret_cast<uintptr_t> (val_data (framebuffer)));
		
	}
	
	
	void lime_gl_bind_renderbuffer (int target, value renderbuffer) {
		
		glBindRenderbuffer (target, val_is_null (renderbuffer) ? 0 : reinterpret_cast<uintptr_t> (val_data (renderbuffer)));
		
	}
	
	
	void lime_gl_bind_texture (int target, value texture) {
		
		glBindTexture (target, val_is_null (texture) ? 0 : reinterpret_cast<uintptr_t> (val_data (texture)));
		
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
	
	
	void lime_gl_blend_func (int s, int d) {
		
		glBlendFunc (s, d);
		
	}
	
	
	void lime_gl_blend_func_separate (int srgb, int drgb, int sa, int da) {
		
		glBlendFuncSeparate (srgb, drgb, sa, da);
		
	}
	
	
	void lime_gl_buffer_data (int inTarget, value inByteBuffer, int start, int len, int inUsage) {
		
		if (len == 0) return;
		
		Bytes bytes;
		bytes.Set (inByteBuffer);
		const unsigned char *data = bytes.Data ();
		int size = bytes.Length ();
		
		if (len + start > size) {
			
			val_throw (alloc_string ("Invalid byte length"));
			
		}
		
		glBufferData (inTarget, len, data + start, inUsage);
		
	}
	
	
	void lime_gl_buffer_sub_data (int inTarget, int inOffset, value inByteBuffer, int start, int len) {
		
		if (len == 0) return;
		
		Bytes bytes;
		bytes.Set (inByteBuffer);
		const unsigned char *data = bytes.Data ();
		int size = bytes.Length ();
		
		if (len + start > size) {
			
			val_throw (alloc_string ("Invalid byte length"));
			
		}
		
		glBufferSubData (inTarget, inOffset, len, data + start);
		
	}
	
	
	int lime_gl_check_framebuffer_status (int target) {
		
		return glCheckFramebufferStatus (target);
		
	}
	
	
	void lime_gl_clear (int mask) {
		
		gc_gl_run ();
		glClear (mask);
		
	}
	
	
	void lime_gl_clear_color (float r, float g, float b, float a) {
		
		glClearColor (r, g, b, a);
		
	}
	
	
	void lime_gl_clear_depth (float depth) {
		
		#ifdef LIME_GLES
		glClearDepthf (depth);
		#else
		glClearDepth (depth);
		#endif
		
	}
	
	
	void lime_gl_clear_stencil (int stencil) {
		
		glClearStencil (stencil);
		
	}
	
	
	void lime_gl_color_mask (bool r, bool g, bool b, bool a) {
		
		glColorMask (r, g, b, a);
		
	}
	
	
	void lime_gl_compile_shader (value handle) {
		
		glCompileShader (reinterpret_cast<uintptr_t> (val_data (handle)));
		
	}
	
	
	void lime_gl_compressed_tex_image_2d (int target, int level, int internalFormat, int width, int height, int border, value buffer, int offset) {
		
		unsigned char *data = 0;
		int size = 0;
		
		Bytes bytes;
		bytes.Set (buffer);
		
		if (bytes.Length ()) {
			
			data = bytes.Data () + offset;
			size = bytes.Length () - offset;
			
		}
		
		glCompressedTexImage2D (target, level, internalFormat, width, height, border, size, data);
		
	}
	
	
	void lime_gl_compressed_tex_sub_image_2d (int target, int level, int xOffset, int yOffset, int width, int height, int format, value buffer, int offset) {
		
		unsigned char *data = 0;
		int size = 0;
		
		Bytes bytes;
		bytes.Set (buffer);
		
		if (bytes.Length ()) {
			
			data = bytes.Data () + offset;
			size = bytes.Length () - offset;
			
		}
		
		glCompressedTexSubImage2D (target, level, xOffset, yOffset, width, height, format, size, data);
		
	}
	
	
	void lime_gl_copy_tex_image_2d (int target, int level, int internalFormat, int x, int y, int width, int height, int border) {
		
		glCopyTexImage2D (target, level, internalFormat, x, y, width, height, border);
		
	}
	
	
	void lime_gl_copy_tex_sub_image_2d (int target, int level, int xOffset, int yOffset, int x, int y, int width, int height) {
		
		glCopyTexSubImage2D (target, level, xOffset, yOffset, x, y, width, height);
		
	}
	
	
	value lime_gl_create_buffer () {
		
		GLuint buffer;
		glGenBuffers (1, &buffer);
		return CFFIPointer ((void*)(uintptr_t)buffer, gc_gl_buffer);
		
	}
	
	
	value lime_gl_create_framebuffer () {
		
		GLuint id = 0;
		glGenFramebuffers (1, &id);
		return CFFIPointer ((void*)(uintptr_t)id, gc_gl_framebuffer);
		
	}
	
	
	value lime_gl_create_program () {
		
		return CFFIPointer ((void*)(uintptr_t)glCreateProgram (), gc_gl_program);
		
	}
	
	
	value lime_gl_create_render_buffer () {
		
		GLuint id = 0;
		glGenRenderbuffers (1, &id);
		return CFFIPointer ((void*)(uintptr_t)id, gc_gl_render_buffer);
		
	}
	
	
	value lime_gl_create_shader (int type) {
		
		return CFFIPointer ((void*)(uintptr_t)glCreateShader (type), gc_gl_shader);
		
	}
	
	
	value lime_gl_create_texture () {
		
		GLuint id = 0;
		glGenTextures (1, &id);
		return CFFIPointer ((void*)(uintptr_t)id, gc_gl_texture);
		
	}
	
	
	void lime_gl_cull_face (int mode) {
		
		glCullFace (mode);
		
	}
	
	
	void lime_gl_delete_buffer (value handle) {
		
		if (!val_is_null (handle)) {
			
			GLuint id = reinterpret_cast<uintptr_t> (val_data (handle));
			val_gc (handle, 0);
			glDeleteBuffers (1, &id);
			
		}
		
	}
	
	
	void lime_gl_delete_framebuffer (value handle) {
		
		if (!val_is_null (handle)) {
			
			GLuint id = reinterpret_cast<uintptr_t> (val_data (handle));
			val_gc (handle, 0);
			glDeleteFramebuffers (1, &id);
			
		}
		
	}
	
	
	void lime_gl_delete_program (value handle) {
		
		if (!val_is_null (handle)) {
			
			GLuint id = reinterpret_cast<uintptr_t> (val_data (handle));
			val_gc (handle, 0);
			glDeleteProgram (id);
			
		}
		
	}
	
	
	void lime_gl_delete_render_buffer (value handle) {
		
		if (!val_is_null (handle)) {
			
			GLuint id = reinterpret_cast<uintptr_t> (val_data (handle));
			val_gc (handle, 0);
			glDeleteRenderbuffers (1, &id);
			
		}
		
	}
	
	
	void lime_gl_delete_shader (value handle) {
		
		if (!val_is_null (handle)) {
			
			GLuint id = reinterpret_cast<uintptr_t> (val_data (handle));
			val_gc (handle, 0);
			glDeleteShader (id);
			
		}
		
	}
	
	
	void lime_gl_delete_texture (value handle) {
		
		if (!val_is_null (handle)) {
			
			GLuint id = reinterpret_cast<uintptr_t> (val_data (handle));
			val_gc (handle, 0);
			glDeleteTextures (1, &id);
			
		}
		
	}
	
	
	void lime_gl_depth_func (int func) {
		
		glDepthFunc (func);
		
	}
	
	
	void lime_gl_depth_mask (bool mask) {
		
		glDepthMask (mask);
		
	}
	
	
	void lime_gl_depth_range (float inNear, float inFar) {
		
		#ifdef LIME_GLES
		glDepthRangef (inNear, inFar);
		#else
		glDepthRange (inNear, inFar);
		#endif
		
	}
	
	
	void lime_gl_detach_shader (value program, value shader) {
		
		glDetachShader (reinterpret_cast<uintptr_t> (val_data (program)), reinterpret_cast<uintptr_t> (val_data (shader)));
		
	}
	
	
	void lime_gl_disable (int cap) {
		
		glDisable (cap);
		
	}
	
	
	void lime_gl_disable_vertex_attrib_array (int inIndex) {
		
		glDisableVertexAttribArray (inIndex);
		
	}
	
	
	void lime_gl_draw_arrays (int inMode, int inFirst, int inCount) {
		
		glDrawArrays (inMode, inFirst, inCount);
		
	}
	
	
	void lime_gl_draw_elements (int inMode, int inCount, int inType, int inOffset) {
		
		glDrawElements (inMode, inCount, inType, (void *)(intptr_t)inOffset);
		
	}
	
	
	void lime_gl_enable (int inCap) {
		
		glEnable (inCap);
		
	}
	
	
	void lime_gl_enable_vertex_attrib_array (int inIndex) {
		
		glEnableVertexAttribArray (inIndex);
		
	}
	
	
	void lime_gl_finish () {
		
		glFinish ();
		
	}
	
	
	void lime_gl_flush () {
		
		glFlush ();
		
	}
	
	
	void lime_gl_framebuffer_renderbuffer (int target, int attachment, int renderbuffertarget, value renderbuffer) {
		
		glFramebufferRenderbuffer (target, attachment, renderbuffertarget, reinterpret_cast<uintptr_t> (val_data (renderbuffer)));
		
	}
	
	
	void lime_gl_framebuffer_texture2D (int target, int attachment, int textarget, value texture, int level) {
		
		glFramebufferTexture2D (target, attachment, textarget, reinterpret_cast<uintptr_t> (val_data (texture)), level);
		
	}
	
	
	void lime_gl_front_face (int inFace) {
		
		glFrontFace (inFace);
		
	}
	
	
	void lime_gl_generate_mipmap (int inTarget) {
		
		glGenerateMipmap (inTarget);
		
	}
	
	
	value lime_gl_get_active_attrib (value handle, int inIndex) {
		
		value result = alloc_empty_object ();
		
		char buf[1024];
		GLsizei outLen = 1024;
		GLsizei size = 0;
		GLenum  type = 0;
		
		glGetActiveAttrib (reinterpret_cast<uintptr_t> (val_data (handle)), inIndex, 1024, &outLen, &size, &type, buf);
		
		alloc_field (result, val_id ("size"), alloc_int (size));
		alloc_field (result, val_id ("type"), alloc_int (type));
		alloc_field (result, val_id ("name"), alloc_string (buf));
		
		return result;
		
	}
	
	
	value lime_gl_get_active_uniform (value handle, int inIndex) {
		
		char buf[1024];
		GLsizei outLen = 1024;
		GLsizei size = 0;
		GLenum  type = 0;
		
		glGetActiveUniform (reinterpret_cast<uintptr_t> (val_data (handle)), inIndex, 1024, &outLen, &size, &type, buf);
		
		value result = alloc_empty_object ();
		alloc_field (result, val_id ("size"), alloc_int (size));
		alloc_field (result, val_id ("type"), alloc_int (type));
		alloc_field (result, val_id ("name"), alloc_string (buf));
		
		return result;
		
	}
	
	
	int lime_gl_get_attrib_location (value handle, HxString inName) {
		
		return glGetAttribLocation (reinterpret_cast<uintptr_t> (val_data (handle)), inName.__s);
		
	}
	
	
	int lime_gl_get_buffer_parameter (int inTarget, int inIndex) {
		
		GLint data = 0;
		glGetBufferParameteriv (inTarget, inIndex, &data);
		return data;
		
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
	
	
	int lime_gl_get_framebuffer_attachment_parameter (int target, int attachment, int pname) {
		
		GLint result = 0;
		glGetFramebufferAttachmentParameteriv (target, attachment, pname, &result);
		return result;
		
	}
	
	
	value lime_gl_get_parameter (int pname) {
		
		int floats = 0;
		int ints = 0;
		int strings = 0;
		
		switch (pname) {
			
			case GL_ALIASED_LINE_WIDTH_RANGE:
			case GL_ALIASED_POINT_SIZE_RANGE:
			case GL_DEPTH_RANGE:
				floats = 2;
				break;
			
			case GL_BLEND_COLOR:
			case GL_COLOR_CLEAR_VALUE:
				floats = 4;
				break;
			
			case GL_COLOR_WRITEMASK:
				ints = 4;
				break;
			
			//case GL_COMPRESSED_TEXTURE_FORMATS  null
			
			case GL_MAX_VIEWPORT_DIMS:
				ints = 2;
				break;
			
			case GL_SCISSOR_BOX:
			case GL_VIEWPORT:
				ints = 4;
				break;
			
			case GL_ARRAY_BUFFER_BINDING:
			case GL_CURRENT_PROGRAM:
			case GL_ELEMENT_ARRAY_BUFFER_BINDING:
			case GL_FRAMEBUFFER_BINDING:
			case GL_RENDERBUFFER_BINDING:
			case GL_TEXTURE_BINDING_2D:
			case GL_TEXTURE_BINDING_CUBE_MAP:
			case GL_DEPTH_CLEAR_VALUE:
			case GL_LINE_WIDTH:
			case GL_POLYGON_OFFSET_FACTOR:
			case GL_POLYGON_OFFSET_UNITS:
			case GL_SAMPLE_COVERAGE_VALUE:
				ints = 1;
				break;
			
			case GL_BLEND:
			case GL_DEPTH_WRITEMASK:
			case GL_DITHER:
			case GL_CULL_FACE:
			case GL_POLYGON_OFFSET_FILL:
			case GL_SAMPLE_COVERAGE_INVERT:
			case GL_STENCIL_TEST:
			//case GL_UNPACK_FLIP_Y_WEBGL:
			//case GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL:
				ints = 1;
				break;
			
			case GL_ALPHA_BITS:
			case GL_ACTIVE_TEXTURE:
			case GL_BLEND_DST_ALPHA:
			case GL_BLEND_DST_RGB:
			case GL_BLEND_EQUATION_ALPHA:
			case GL_BLEND_EQUATION_RGB:
			case GL_BLEND_SRC_ALPHA:
			case GL_BLEND_SRC_RGB:
			case GL_BLUE_BITS:
			case GL_CULL_FACE_MODE:
			case GL_DEPTH_BITS:
			case GL_DEPTH_FUNC:
			case GL_DEPTH_TEST:
			case GL_FRONT_FACE:
			case GL_GENERATE_MIPMAP_HINT:
			case GL_GREEN_BITS:
			case GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS:
			case GL_MAX_CUBE_MAP_TEXTURE_SIZE:
			//case GL_MAX_FRAGMENT_UNIFORM_VECTORS:
			//case GL_MAX_RENDERBUFFER_SIZE:
			case GL_MAX_TEXTURE_IMAGE_UNITS:
			case GL_MAX_TEXTURE_SIZE:
			//case GL_MAX_VARYING_VECTORS:
			case GL_MAX_VERTEX_ATTRIBS:
			case GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS:
			case GL_MAX_VERTEX_UNIFORM_VECTORS:
			case GL_NUM_COMPRESSED_TEXTURE_FORMATS:
			case GL_PACK_ALIGNMENT:
			case GL_RED_BITS:
			case GL_SAMPLE_BUFFERS:
			case GL_SAMPLES:
			case GL_SCISSOR_TEST:
			case GL_SHADING_LANGUAGE_VERSION:
			case GL_STENCIL_BACK_FAIL:
			case GL_STENCIL_BACK_FUNC:
			case GL_STENCIL_BACK_PASS_DEPTH_FAIL:
			case GL_STENCIL_BACK_PASS_DEPTH_PASS:
			case GL_STENCIL_BACK_REF:
			case GL_STENCIL_BACK_VALUE_MASK:
			case GL_STENCIL_BACK_WRITEMASK:
			case GL_STENCIL_BITS:
			case GL_STENCIL_CLEAR_VALUE:
			case GL_STENCIL_FAIL:
			case GL_STENCIL_FUNC:
			case GL_STENCIL_PASS_DEPTH_FAIL:
			case GL_STENCIL_PASS_DEPTH_PASS:
			case GL_STENCIL_REF:
			case GL_STENCIL_VALUE_MASK:
			case GL_STENCIL_WRITEMASK:
			case GL_SUBPIXEL_BITS:
			case GL_UNPACK_ALIGNMENT:
			//case GL_UNPACK_COLORSPACE_CONVERSION_WEBGL:
				ints = 1;
				break;
			
			case GL_VENDOR:
			case GL_VERSION:
			case GL_RENDERER:
				strings = 1;
				break;
			
		}
		
		if (ints == 1) {
			
			int val;
			glGetIntegerv (pname, &val);
			return alloc_int (val);
			
		} else if (strings == 1) {
			
			return alloc_string ((const char *)glGetString (pname));
			
		} else if (floats == 1) {
			
			float f;
			glGetFloatv (pname, &f);
			return alloc_float (f);
			
		} else if (ints > 0) {
			
			int vals[4];
			glGetIntegerv (pname, vals);
			value result = alloc_array (ints);
			
			for (int i = 0; i < ints; i++) {
				
				val_array_set_i (result, i, alloc_int (vals[i]));
				
			}
			
			return result;
			
		} else if (floats > 0) {
			
			float vals[4];
			glGetFloatv (pname, vals);
			value result = alloc_array (ints);
			
			for (int i = 0; i < ints; i++) {
				
				val_array_set_i (result, i, alloc_int (vals[i]));
				
			}
			
			return result;
			
		}
		
		return alloc_null ();
		
	}
	
	
	HxString lime_gl_get_program_info_log (value handle) {
		
		char buf[1024];
		glGetProgramInfoLog (reinterpret_cast<uintptr_t> (val_data (handle)), 1024, 0, buf);
		return HxString (buf);
		
	}
	
	
	int lime_gl_get_program_parameter (value handle, int inName) {
		
		int result = 0;
		glGetProgramiv (reinterpret_cast<uintptr_t> (val_data (handle)), inName, &result);
		return result;
		
	}
	
	
	int lime_gl_get_render_buffer_parameter (int target, int pname) {
		
		int result = 0;
		glGetRenderbufferParameteriv (target, pname, &result);
		return result;
		
	}
	
	
	HxString lime_gl_get_shader_info_log (value handle) {
		
		char buf[1024] = "";
		
		glGetShaderInfoLog (reinterpret_cast<uintptr_t> (val_data (handle)), 1024, 0, buf);
		
		return HxString (buf);
		
	}
	
	
	int lime_gl_get_shader_parameter (value handle, int inName) {
		
		int result = 0;
		glGetShaderiv (reinterpret_cast<uintptr_t> (val_data (handle)), inName, &result);
		return result;
		
	}
	
	
	value lime_gl_get_shader_precision_format (int shaderType, int inPrec) {
		
		#ifdef LIME_GLES
		
		int range[2];
		int precision;
		
		glGetShaderPrecisionFormat (shaderType, inPrec, range, &precision);
		
		value result = alloc_empty_object ();
		alloc_field (result, val_id ("rangeMin"), alloc_int (range[0]));
		alloc_field (result, val_id ("rangeMax"), alloc_int (range[1]));
		alloc_field (result, val_id ("precision"), alloc_int (precision));
		return result;
		
		#else
		
		return alloc_null ();
		
		#endif
		
	}
	
	
	value lime_gl_get_shader_source (value handle) {
		
		int len = 0;
		glGetShaderiv (reinterpret_cast<uintptr_t> (val_data (handle)), GL_SHADER_SOURCE_LENGTH, &len);
		
		if (len == 0) {
			
			return alloc_null ();
			
		}
		
		char *buf = new char[len + 1];
		glGetShaderSource (reinterpret_cast<uintptr_t> (val_data (handle)), len + 1, 0, buf);
		value result = alloc_string (buf);
		
		delete [] buf;
		
		return result;
		
	}
	
	
	void lime_gl_get_supported_extensions (value ioList) {
		
		const char *ext = (const char *)glGetString (GL_EXTENSIONS);
		
		if (ext && *ext) {
			
			while (true) {
				
				const char *next = ext;
				
				while (*next && *next!=' ') {
					
					next++;
					
				}
				
				val_array_push (ioList, alloc_string_len (ext, next - ext));
				
				if (!*next || !next[1]) {
					
					break;
					
				}
				
				ext = next + 1;
				
			}
			
		}
		
		
	}
	
	
	int lime_gl_get_tex_parameter (int inTarget, int inPname) {
		
		int result = 0;
		glGetTexParameteriv (inTarget, inPname, &result);
		return result;
		
	}
	
	
	value lime_gl_get_uniform (value handle, int loc) {
		
		char buf[1];
		GLsizei outLen = 1;
		GLsizei size = 0;
		GLenum  type = 0;
		GLuint id = reinterpret_cast<uintptr_t> (val_data (handle));
		
		glGetActiveUniform (id, loc, 1, &outLen, &size, &type, buf);
		int ints = 0;
		int floats = 0;
		int bools = 0;
		
		switch (type) {
			
			case GL_FLOAT: {
				
				float result = 0;
				glGetUniformfv (id, loc, &result);
				return alloc_float (result);
				
			}
			
			case GL_FLOAT_VEC2: floats = 2;
			case GL_FLOAT_VEC3: floats++;
			case GL_FLOAT_VEC4: floats++;
				break;
			
			case GL_INT_VEC2: ints = 2;
			case GL_INT_VEC3: ints++;
			case GL_INT_VEC4: ints++;
				break;
			
			case GL_BOOL_VEC2: bools = 2;
			case GL_BOOL_VEC3: bools++;
			case GL_BOOL_VEC4: bools++;
				break;
			
			case GL_FLOAT_MAT2: floats = 4; break;
			case GL_FLOAT_MAT3: floats = 9; break;
			case GL_FLOAT_MAT4: floats = 16; break;
			
			#ifdef HX_MACOS
			case GL_FLOAT_MAT2x3: floats = 4 * 3; break;
			case GL_FLOAT_MAT2x4: floats = 4 * 4; break;
			case GL_FLOAT_MAT3x2: floats = 9 * 2; break;
			case GL_FLOAT_MAT3x4: floats = 9 * 4; break;
			case GL_FLOAT_MAT4x2: floats = 16 * 2; break;
			case GL_FLOAT_MAT4x3: floats = 16 * 3; break;
			#endif
			
			case GL_INT:
			case GL_BOOL:
			case GL_SAMPLER_2D:
			#ifdef HX_MACOS
			case GL_SAMPLER_1D:
			case GL_SAMPLER_3D:
			case GL_SAMPLER_CUBE:
			case GL_SAMPLER_1D_SHADOW:
			case GL_SAMPLER_2D_SHADOW:
			#endif
			{
				
				int result = 0;
				glGetUniformiv (id, loc, &result);
				return alloc_int (result);
				
			}
			
		}
		
		if (ints + bools > 0) {
			
			int buffer[4];
			glGetUniformiv (id, loc, buffer);
			
			value result = alloc_array (ints + bools);
			
			for (int i = 0; i < ints + bools; i++) {
				
				val_array_set_i (result, i, alloc_int (buffer[i]));
				
			}
			
			return result;
			
		}
		
		if (floats > 0) {
			
			float buffer[16 * 3];
			glGetUniformfv (id, loc, buffer);
			
			value result = alloc_array (floats);
			
			for (int i = 0; i < floats; i++) {
				
				val_array_set_i (result, i, alloc_float (buffer[i]));
				
			}
			
			return result;
			
		}
		
		return alloc_null ();
		
	}
	
	
	int lime_gl_get_uniform_location (value handle, HxString inName) {
		
		return glGetUniformLocation (reinterpret_cast<uintptr_t> (val_data (handle)), inName.__s);
		
	}
	
	
	int lime_gl_get_vertex_attrib (int index, int name) {
		
		int result = 0;
		glGetVertexAttribiv (index, name, &result);
		return result;
		
	}
	
	
	int lime_gl_get_vertex_attrib_offset (int index, int name) {
		
		int result = 0;
		glGetVertexAttribPointerv (index, name, (void **)&result);
		return result;
		
	}
	
	
	void lime_gl_hint (int inTarget, int inValue) {
		
		glHint (inTarget, inValue);
		
	}
	
	
	bool lime_gl_is_buffer (value handle) {
		
		return glIsBuffer (reinterpret_cast<uintptr_t> (val_data (handle)));
		
	}
	
	
	bool lime_gl_is_enabled (int val) {
		
		return glIsEnabled (val);
		
	}
	
	
	bool lime_gl_is_framebuffer (value handle) {
		
		return glIsFramebuffer (reinterpret_cast<uintptr_t> (val_data (handle)));
		
	}
	
	
	bool lime_gl_is_program (value handle) {
		
		return glIsProgram (reinterpret_cast<uintptr_t> (val_data (handle)));
		
	}
	
	
	bool lime_gl_is_renderbuffer (value handle) {
		
		return glIsRenderbuffer (reinterpret_cast<uintptr_t> (val_data (handle)));
		
	}
	
	
	bool lime_gl_is_shader (value handle) {
		
		return glIsShader (reinterpret_cast<uintptr_t> (val_data (handle)));
		
	}
	
	
	bool lime_gl_is_texture (value handle) {
		
		return glIsTexture (reinterpret_cast<uintptr_t> (val_data (handle)));
		
	}
	
	
	void lime_gl_line_width (float inWidth) {
		
		glLineWidth (inWidth);
		
	}
	
	
	void lime_gl_link_program (value handle) {
		
		glLinkProgram (reinterpret_cast<uintptr_t> (val_data (handle)));
		
	}
	
	
	void lime_gl_pixel_storei (int pname, int param) {
		
		glPixelStorei (pname, param);
		
	}
	
	
	void lime_gl_polygon_offset (float factor, float units) {
		
		glPolygonOffset (factor, units);
		
	}
	
	
	void lime_gl_read_pixels (int x, int y, int width, int height, int format, int type, value buffer, int offset) {
		
		unsigned char *data = 0;
		Bytes bytes;
		bytes.Set (buffer);
		
		if (bytes.Length ()) {
			
			data = bytes.Data () + offset;
			
		}
		
		glReadPixels (x, y, width, height, format, type, data);
		
	}
	
	
	void lime_gl_renderbuffer_storage (int target, int internalFormat, int width, int height) {
		
		glRenderbufferStorage (target, internalFormat, width, height);
		
	}
	
	
	void lime_gl_sample_coverage (float f, bool invert) {
		
		glSampleCoverage (f, invert);
		
	}
	
	
	void lime_gl_scissor (int inX, int inY, int inW, int inH) {
		
		glScissor (inX, inY, inW, inH);
		
	}
	
	
	void lime_gl_shader_source (value handle, HxString source) {
		
		glShaderSource (reinterpret_cast<uintptr_t> (val_data (handle)), 1, &source.__s, 0);
		
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
	
	
	void lime_gl_stencil_op (int fail, int zfail, int zpass) {
		
		glStencilOp (fail, zfail, zpass);
		
	}
	
	
	void lime_gl_stencil_op_separate (int face, int fail, int zfail, int zpass) {
		
		glStencilOpSeparate (face, fail, zfail, zpass);
		
	}
	
	
	void lime_gl_tex_image_2d (int target, int level, int internal, int width, int height, int border, int format, int type, value buffer, int offset) {
		
		unsigned char *data = 0;
		
		Bytes bytes;
		bytes.Set (buffer);
		
		if (bytes.Length ()) {
			
			data = bytes.Data () + offset;
			
		}
		
		glTexImage2D (target, level, internal, width, height, border, format, type, data);
		
	}
	
	
	void lime_gl_tex_parameterf (int inTarget, int inPName, float inVal) {
		
		glTexParameterf (inTarget, inPName, inVal);
		
	}
	
	
	void lime_gl_tex_parameteri (int inTarget, int inPName, int inVal) {
		
		glTexParameterf (inTarget, inPName, inVal);
		
	}
	
	
	void lime_gl_tex_sub_image_2d (int target, int level, int xOffset, int yOffset, int width, int height, int format, int type, value buffer, int offset) {
		
		unsigned char *data = 0;
		Bytes bytes;
		bytes.Set (buffer);
		
		if (bytes.Length ()) {
			
			data = bytes.Data () + offset;
			
		}
		
		glTexSubImage2D (target, level, xOffset, yOffset, width, height, format, type, data);
		
	}
	
	
	void lime_gl_uniform_matrix (int loc, bool trans, value inBytes, int count) {
		
		Bytes bytes;
		bytes.Set (inBytes);
		int size = bytes.Length ();
		const float *data = (float *)bytes.Data ();
		int nbElems = size / sizeof (float);
		
		switch (count) {
			
			case 2: glUniformMatrix2fv (loc, nbElems >> 2, trans, data); break;
			case 3: glUniformMatrix3fv (loc, nbElems / 9, trans, data); break;
			case 4: glUniformMatrix4fv (loc, nbElems >> 4, trans, data); break;
			
		}
		
	}
	
	
	void lime_gl_uniform1f (int inLocation, float inV0) {
		
		glUniform1f (inLocation, inV0);
		
	}
	
	
	void lime_gl_uniform1fv (int loc, value inByteBuffer) {
		
		Bytes bytes;
		bytes.Set (inByteBuffer);
		int size = bytes.Length ();
		const float *data = (float *)bytes.Data ();
		int nbElems = size / sizeof (float);
		
		glUniform1fv (loc, nbElems, data);
		
	}
	
	
	void lime_gl_uniform1i (int inLocation, int inV0) {
		
		glUniform1i (inLocation, inV0);
		
	}
	
	
	void lime_gl_uniform1iv (int loc, value inByteBuffer) {
		
		Bytes bytes;
		bytes.Set (inByteBuffer);
		int size = bytes.Length ();
		const int *data = (int *)bytes.Data ();
		int nbElems = size / sizeof (int);
		
		glUniform1iv (loc, nbElems, data);
		
	}
	
	
	void lime_gl_uniform2f (int inLocation, float inV0, float inV1) {
		
		glUniform2f (inLocation, inV0, inV1);
		
	}
	
	
	void lime_gl_uniform2fv (int loc, value inByteBuffer) {
		
		Bytes bytes (inByteBuffer);
		int size = bytes.Length ();
		const float *data = (float *)bytes.Data ();
		int nbElems = size / sizeof (float);
		
		glUniform2fv (loc, nbElems >> 1, data);
		
	}
	
	
	void lime_gl_uniform2i (int inLocation, int inV0, int inV1) {
		
		glUniform2i (inLocation, inV0, inV1);
		
	}
	
	
	void lime_gl_uniform2iv (int loc, value inByteBuffer) {
		
		Bytes bytes (inByteBuffer);
		int size = bytes.Length ();
		const int *data = (int *)bytes.Data ();
		int nbElems = size / sizeof (int);
		
		glUniform2iv (loc, nbElems >> 1, data);
		
	}
	
	
	void lime_gl_uniform3f (int inLocation, float inV0, float inV1, float inV2) {
		
		glUniform3f (inLocation, inV0, inV1, inV2);
		
	}
	
	
	void lime_gl_uniform3fv (int loc, value inByteBuffer) {
		
		Bytes bytes (inByteBuffer);
		int size = bytes.Length ();
		const float *data = (float *)bytes.Data ();
		int nbElems = size / sizeof (float);
		
		glUniform3fv (loc, nbElems / 3, data);
		
	}
	
	
	void lime_gl_uniform3i (int inLocation, int inV0, int inV1, int inV2) {
		
		glUniform3i (inLocation, inV0, inV1, inV2);
		
	}
	
	
	void lime_gl_uniform3iv (int loc, value inByteBuffer) {
		
		Bytes bytes (inByteBuffer);
		int size = bytes.Length ();
		const int *data = (int *)bytes.Data ();
		int nbElems = size / sizeof (int);
		
		glUniform3iv (loc, nbElems / 3, data);
		
	}
	
	
	void lime_gl_uniform4f (int inLocation, float inV0, float inV1, float inV2, float inV3) {
		
		glUniform4f (inLocation, inV0, inV1, inV2, inV3);
		
	}
	
	
	void lime_gl_uniform4fv (int loc, value inByteBuffer) {
		
		Bytes bytes (inByteBuffer);
		int size = bytes.Length ();
		const float *data = (float *)bytes.Data ();
		int nbElems = size / sizeof (float);
		
		glUniform4fv (loc, nbElems >> 2, data);
		
	}
	
	
	void lime_gl_uniform4i (int inLocation, int inV0, int inV1, int inV2, int inV3) {
		
		glUniform4i (inLocation, inV0, inV1, inV2, inV3);
		
	}
	
	
	void lime_gl_uniform4iv (int loc, value inByteBuffer) {
		
		Bytes bytes (inByteBuffer);
		int size = bytes.Length ();
		const int *data = (int *)bytes.Data ();
		int nbElems = size / sizeof (int);
		
		glUniform4iv (loc, nbElems >> 2, data);
		
	}
	
	
	void lime_gl_use_program (value handle) {
		
		glUseProgram (val_is_null (handle) ? 0 : reinterpret_cast<uintptr_t> (val_data (handle)));
		
	}
	
	
	void lime_gl_validate_program (value handle) {
		
		glValidateProgram (reinterpret_cast<uintptr_t> (val_data (handle)));
		
	}
	
	
	HxString lime_gl_version () {
		
		const char* gl_ver = (const char*)glGetString (GL_VERSION);
		const char* gl_sl  = (const char*)glGetString (GL_SHADING_LANGUAGE_VERSION);
		const char* gl_ren = (const char*)glGetString (GL_RENDERER);
		const char* gl_ven = (const char*)glGetString (GL_VENDOR);
		
		std::string glver (gl_ver ? gl_ver : "GL version null");
		std::string glslver (gl_sl ? gl_sl : "GL SL version null");
		std::string glren (gl_ren ? gl_ren : "GL renderer version null");
		std::string glven (gl_ven ? gl_ven : "GL vendor version null");
		
		std::string res = "/ " + glver + " / " + glslver + " / " + glren + " / " + glven + " /";
		
		return HxString (res.c_str ());
		
	}
	
	
	void lime_gl_vertex_attrib_pointer (int index, int size, int type, bool normalized, int stride, int offset) {
		
		glVertexAttribPointer (index, size, type, normalized, stride, (void *)(intptr_t)offset);
		
	}
	
	
	void lime_gl_vertex_attrib1f (int inLocation, float inV0) {
		
		glVertexAttrib1f (inLocation, inV0);
		
	}
	
	
	void lime_gl_vertex_attrib1fv (int loc, value inByteBuffer) {
		
		Bytes bytes (inByteBuffer);
		int size = bytes.Length ();
		const float *data = (float *)bytes.Data ();
		
		glVertexAttrib1fv (loc, data);
		
	}
	
	
	void lime_gl_vertex_attrib2f (int inLocation, float inV0, float inV1) {
		
		glVertexAttrib2f (inLocation, inV0, inV1);
		
	}
	
	
	void lime_gl_vertex_attrib2fv (int loc, value inByteBuffer) {
		
		Bytes bytes (inByteBuffer);
		int size = bytes.Length ();
		const float *data = (float *)bytes.Data ();
		
		glVertexAttrib2fv (loc, data);
		
	}
	
	
	void lime_gl_vertex_attrib3f (int inLocation, float inV0, float inV1, float inV2) {
		
		glVertexAttrib3f (inLocation, inV0, inV1, inV2);
		
	}
	
	
	void lime_gl_vertex_attrib3fv (int loc, value inByteBuffer) {
		
		Bytes bytes (inByteBuffer);
		int size = bytes.Length ();
		const float *data = (float *)bytes.Data ();
		
		glVertexAttrib3fv (loc, data);
		
	}
	
	
	void lime_gl_vertex_attrib4f (int inLocation, float inV0, float inV1, float inV2, float inV3) {
		
		glVertexAttrib4f (inLocation, inV0, inV1, inV2, inV3);
		
	}
	
	
	void lime_gl_vertex_attrib4fv (int loc, value inByteBuffer) {
		
		Bytes bytes (inByteBuffer);
		int size = bytes.Length ();
		const float *data = (float *)bytes.Data ();
		
		glVertexAttrib4fv (loc, data);
		
	}
	
	
	void lime_gl_viewport (int inX, int inY, int inW, int inH) {
		
		glViewport (inX, inY, inW, inH);
		
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
	DEFINE_PRIME5v (lime_gl_buffer_data);
	DEFINE_PRIME5v (lime_gl_buffer_sub_data);
	DEFINE_PRIME1 (lime_gl_check_framebuffer_status);
	DEFINE_PRIME1v (lime_gl_clear);
	DEFINE_PRIME4v (lime_gl_clear_color);
	DEFINE_PRIME1v (lime_gl_clear_depth);
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
	DEFINE_PRIME0 (lime_gl_create_render_buffer);
	DEFINE_PRIME1 (lime_gl_create_shader);
	DEFINE_PRIME0 (lime_gl_create_texture);
	DEFINE_PRIME1v (lime_gl_cull_face);
	DEFINE_PRIME1v (lime_gl_delete_buffer);
	DEFINE_PRIME1v (lime_gl_delete_framebuffer);
	DEFINE_PRIME1v (lime_gl_delete_program);
	DEFINE_PRIME1v (lime_gl_delete_render_buffer);
	DEFINE_PRIME1v (lime_gl_delete_shader);
	DEFINE_PRIME1v (lime_gl_delete_texture);
	DEFINE_PRIME2v (lime_gl_detach_shader);
	DEFINE_PRIME1v (lime_gl_depth_func);
	DEFINE_PRIME1v (lime_gl_depth_mask);
	DEFINE_PRIME2v (lime_gl_depth_range);
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
	DEFINE_PRIME2 (lime_gl_get_attrib_location);
	DEFINE_PRIME2 (lime_gl_get_buffer_parameter);
	DEFINE_PRIME0 (lime_gl_get_context_attributes);
	DEFINE_PRIME0 (lime_gl_get_error);
	DEFINE_PRIME1 (lime_gl_get_extension);
	DEFINE_PRIME3 (lime_gl_get_framebuffer_attachment_parameter);
	DEFINE_PRIME1 (lime_gl_get_parameter);
	DEFINE_PRIME1 (lime_gl_get_program_info_log);
	DEFINE_PRIME2 (lime_gl_get_program_parameter);
	DEFINE_PRIME2 (lime_gl_get_render_buffer_parameter);
	DEFINE_PRIME1 (lime_gl_get_shader_info_log);
	DEFINE_PRIME2 (lime_gl_get_shader_parameter);
	DEFINE_PRIME2 (lime_gl_get_shader_precision_format);
	DEFINE_PRIME1 (lime_gl_get_shader_source);
	DEFINE_PRIME1v (lime_gl_get_supported_extensions);
	DEFINE_PRIME2 (lime_gl_get_tex_parameter);
	DEFINE_PRIME2 (lime_gl_get_uniform);
	DEFINE_PRIME2 (lime_gl_get_uniform_location);
	DEFINE_PRIME2 (lime_gl_get_vertex_attrib);
	DEFINE_PRIME2 (lime_gl_get_vertex_attrib_offset);
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
	DEFINE_PRIME2v (lime_gl_pixel_storei);
	DEFINE_PRIME2v (lime_gl_polygon_offset);
	DEFINE_PRIME8v (lime_gl_read_pixels);
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
	DEFINE_PRIME10v (lime_gl_tex_image_2d);
	DEFINE_PRIME3v (lime_gl_tex_parameterf);
	DEFINE_PRIME3v (lime_gl_tex_parameteri);
	DEFINE_PRIME10v (lime_gl_tex_sub_image_2d);
	DEFINE_PRIME4v (lime_gl_uniform_matrix);
	DEFINE_PRIME2v (lime_gl_uniform1f);
	DEFINE_PRIME2v (lime_gl_uniform1fv);
	DEFINE_PRIME2v (lime_gl_uniform1i);
	DEFINE_PRIME2v (lime_gl_uniform1iv);
	DEFINE_PRIME3v (lime_gl_uniform2f);
	DEFINE_PRIME2v (lime_gl_uniform2fv);
	DEFINE_PRIME3v (lime_gl_uniform2i);
	DEFINE_PRIME2v (lime_gl_uniform2iv);
	DEFINE_PRIME4v (lime_gl_uniform3f);
	DEFINE_PRIME2v (lime_gl_uniform3fv);
	DEFINE_PRIME4v (lime_gl_uniform3i);
	DEFINE_PRIME2v (lime_gl_uniform3iv);
	DEFINE_PRIME5v (lime_gl_uniform4f);
	DEFINE_PRIME2v (lime_gl_uniform4fv);
	DEFINE_PRIME5v (lime_gl_uniform4i);
	DEFINE_PRIME2v (lime_gl_uniform4iv);
	DEFINE_PRIME1v (lime_gl_use_program);
	DEFINE_PRIME1v (lime_gl_validate_program);
	DEFINE_PRIME4v (lime_gl_viewport);
	DEFINE_PRIME0 (lime_gl_version);
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