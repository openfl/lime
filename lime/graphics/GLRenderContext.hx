package lime.graphics;


#if (lime_cffi && lime_opengl && !display)
typedef GLRenderContext = lime._backend.native.NativeGLRenderContext;
#elseif (js && html5 && lime_opengl && !display)
typedef GLRenderContext = lime._backend.html5.HTML5GLRenderContext;
#else


import lime.graphics.opengl.GLActiveInfo;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLContextAttributes;
import lime.graphics.opengl.GLContextType;
import lime.graphics.opengl.GLFramebuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLRenderbuffer;
import lime.graphics.opengl.GLShader;
import lime.graphics.opengl.GLShaderPrecisionFormat;
import lime.graphics.opengl.GLTexture;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.DataPointer;

#if (js && html5)
import js.html.CanvasElement;
#end

class GLRenderContext {
	
	
	public var ACTIVE_ATTRIBUTES:Int;
	public var ACTIVE_TEXTURE:Int;
	public var ACTIVE_UNIFORMS:Int;
	public var ALIASED_LINE_WIDTH_RANGE:Int;
	public var ALIASED_POINT_SIZE_RANGE:Int;
	public var ALPHA:Int;
	public var ALPHA_BITS:Int;
	public var ALWAYS:Int;
	public var ARRAY_BUFFER:Int;
	public var ARRAY_BUFFER_BINDING:Int;
	public var ATTACHED_SHADERS:Int;
	public var BACK:Int;
	public var BLEND:Int;
	public var BLEND_COLOR:Int;
	public var BLEND_DST_ALPHA:Int;
	public var BLEND_DST_RGB:Int;
	public var BLEND_EQUATION:Int;
	public var BLEND_EQUATION_ALPHA:Int;
	public var BLEND_EQUATION_RGB:Int;
	public var BLEND_SRC_ALPHA:Int;
	public var BLEND_SRC_RGB:Int;
	public var BLUE_BITS:Int;
	public var BOOL:Int;
	public var BOOL_VEC2:Int;
	public var BOOL_VEC3:Int;
	public var BOOL_VEC4:Int;
	public var BROWSER_DEFAULT_WEBGL:Int;
	public var BUFFER_SIZE:Int;
	public var BUFFER_USAGE:Int;
	public var BYTE:Int;
	public var CCW:Int;
	public var CLAMP_TO_EDGE:Int;
	public var COLOR_ATTACHMENT0:Int;
	public var COLOR_BUFFER_BIT:Int;
	public var COLOR_CLEAR_VALUE:Int;
	public var COLOR_WRITEMASK:Int;
	public var COMPILE_STATUS:Int;
	public var COMPRESSED_TEXTURE_FORMATS:Int;
	public var CONSTANT_ALPHA:Int;
	public var CONSTANT_COLOR:Int;
	public var CONTEXT_LOST_WEBGL:Int;
	public var CULL_FACE:Int;
	public var CULL_FACE_MODE:Int;
	public var CURRENT_PROGRAM:Int;
	public var CURRENT_VERTEX_ATTRIB:Int;
	public var CW:Int;
	public var DECR:Int;
	public var DECR_WRAP:Int;
	public var DELETE_STATUS:Int;
	public var DEPTH_ATTACHMENT:Int;
	public var DEPTH_BITS:Int;
	public var DEPTH_BUFFER_BIT:Int;
	public var DEPTH_CLEAR_VALUE:Int;
	public var DEPTH_COMPONENT:Int;
	public var DEPTH_COMPONENT16:Int;
	public var DEPTH_FUNC:Int;
	public var DEPTH_RANGE:Int;
	public var DEPTH_STENCIL:Int;
	public var DEPTH_STENCIL_ATTACHMENT:Int;
	public var DEPTH_TEST:Int;
	public var DEPTH_WRITEMASK:Int;
	public var DITHER:Int;
	public var DONT_CARE:Int;
	public var DST_ALPHA:Int;
	public var DST_COLOR:Int;
	public var DYNAMIC_DRAW:Int;
	public var ELEMENT_ARRAY_BUFFER:Int;
	public var ELEMENT_ARRAY_BUFFER_BINDING:Int;
	public var EQUAL:Int;
	public var FASTEST:Int;
	public var FLOAT:Int;
	public var FLOAT_MAT2:Int;
	public var FLOAT_MAT3:Int;
	public var FLOAT_MAT4:Int;
	public var FLOAT_VEC2:Int;
	public var FLOAT_VEC3:Int;
	public var FLOAT_VEC4:Int;
	public var FRAGMENT_SHADER:Int;
	public var FRAMEBUFFER:Int;
	public var FRAMEBUFFER_ATTACHMENT_OBJECT_NAME:Int;
	public var FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE:Int;
	public var FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE:Int;
	public var FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL:Int;
	public var FRAMEBUFFER_BINDING:Int;
	public var FRAMEBUFFER_COMPLETE:Int;
	public var FRAMEBUFFER_INCOMPLETE_ATTACHMENT:Int;
	public var FRAMEBUFFER_INCOMPLETE_DIMENSIONS:Int;
	public var FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:Int;
	public var FRAMEBUFFER_UNSUPPORTED:Int;
	public var FRONT:Int;
	public var FRONT_AND_BACK:Int;
	public var FRONT_FACE:Int;
	public var FUNC_ADD:Int;
	public var FUNC_REVERSE_SUBTRACT:Int;
	public var FUNC_SUBTRACT:Int;
	public var GENERATE_MIPMAP_HINT:Int;
	public var GEQUAL:Int;
	public var GREATER:Int;
	public var GREEN_BITS:Int;
	public var HIGH_FLOAT:Int;
	public var HIGH_INT:Int;
	public var INCR:Int;
	public var INCR_WRAP:Int;
	public var INT:Int;
	public var INT_VEC2:Int;
	public var INT_VEC3:Int;
	public var INT_VEC4:Int;
	public var INVALID_ENUM:Int;
	public var INVALID_FRAMEBUFFER_OPERATION:Int;
	public var INVALID_OPERATION:Int;
	public var INVALID_VALUE:Int;
	public var INVERT:Int;
	public var KEEP:Int;
	public var LEQUAL:Int;
	public var LESS:Int;
	public var LINEAR:Int;
	public var LINEAR_MIPMAP_LINEAR:Int;
	public var LINEAR_MIPMAP_NEAREST:Int;
	public var LINES:Int;
	public var LINE_LOOP:Int;
	public var LINE_STRIP:Int;
	public var LINE_WIDTH:Int;
	public var LINK_STATUS:Int;
	public var LOW_FLOAT:Int;
	public var LOW_INT:Int;
	public var LUMINANCE:Int;
	public var LUMINANCE_ALPHA:Int;
	public var MAX_COMBINED_TEXTURE_IMAGE_UNITS:Int;
	public var MAX_CUBE_MAP_TEXTURE_SIZE:Int;
	public var MAX_FRAGMENT_UNIFORM_VECTORS:Int;
	public var MAX_RENDERBUFFER_SIZE:Int;
	public var MAX_TEXTURE_IMAGE_UNITS:Int;
	public var MAX_TEXTURE_SIZE:Int;
	public var MAX_VARYING_VECTORS:Int;
	public var MAX_VERTEX_ATTRIBS:Int;
	public var MAX_VERTEX_TEXTURE_IMAGE_UNITS:Int;
	public var MAX_VERTEX_UNIFORM_VECTORS:Int;
	public var MAX_VIEWPORT_DIMS:Int;
	public var MEDIUM_FLOAT:Int;
	public var MEDIUM_INT:Int;
	public var MIRRORED_REPEAT:Int;
	public var NEAREST:Int;
	public var NEAREST_MIPMAP_LINEAR:Int;
	public var NEAREST_MIPMAP_NEAREST:Int;
	public var NEVER:Int;
	public var NICEST:Int;
	public var NONE:Int;
	public var NOTEQUAL:Int;
	public var NO_ERROR:Int;
	public var ONE:Int;
	public var ONE_MINUS_CONSTANT_ALPHA:Int;
	public var ONE_MINUS_CONSTANT_COLOR:Int;
	public var ONE_MINUS_DST_ALPHA:Int;
	public var ONE_MINUS_DST_COLOR:Int;
	public var ONE_MINUS_SRC_ALPHA:Int;
	public var ONE_MINUS_SRC_COLOR:Int;
	public var OUT_OF_MEMORY:Int;
	public var PACK_ALIGNMENT:Int;
	public var POINTS:Int;
	public var POLYGON_OFFSET_FACTOR:Int;
	public var POLYGON_OFFSET_FILL:Int;
	public var POLYGON_OFFSET_UNITS:Int;
	public var RED_BITS:Int;
	public var RENDERBUFFER:Int;
	public var RENDERBUFFER_ALPHA_SIZE:Int;
	public var RENDERBUFFER_BINDING:Int;
	public var RENDERBUFFER_BLUE_SIZE:Int;
	public var RENDERBUFFER_DEPTH_SIZE:Int;
	public var RENDERBUFFER_GREEN_SIZE:Int;
	public var RENDERBUFFER_HEIGHT:Int;
	public var RENDERBUFFER_INTERNAL_FORMAT:Int;
	public var RENDERBUFFER_RED_SIZE:Int;
	public var RENDERBUFFER_STENCIL_SIZE:Int;
	public var RENDERBUFFER_WIDTH:Int;
	public var RENDERER:Int;
	public var REPEAT:Int;
	public var REPLACE:Int;
	public var RGB:Int;
	public var RGB565:Int;
	public var RGB5_A1:Int;
	public var RGBA:Int;
	public var RGBA4:Int;
	public var SAMPLER_2D:Int;
	public var SAMPLER_CUBE:Int;
	public var SAMPLES:Int;
	public var SAMPLE_ALPHA_TO_COVERAGE:Int;
	public var SAMPLE_BUFFERS:Int;
	public var SAMPLE_COVERAGE:Int;
	public var SAMPLE_COVERAGE_INVERT:Int;
	public var SAMPLE_COVERAGE_VALUE:Int;
	public var SCISSOR_BOX:Int;
	public var SCISSOR_TEST:Int;
	public var SHADER_TYPE:Int;
	public var SHADING_LANGUAGE_VERSION:Int;
	public var SHORT:Int;
	public var SRC_ALPHA:Int;
	public var SRC_ALPHA_SATURATE:Int;
	public var SRC_COLOR:Int;
	public var STATIC_DRAW:Int;
	public var STENCIL_ATTACHMENT:Int;
	public var STENCIL_BACK_FAIL:Int;
	public var STENCIL_BACK_FUNC:Int;
	public var STENCIL_BACK_PASS_DEPTH_FAIL:Int;
	public var STENCIL_BACK_PASS_DEPTH_PASS:Int;
	public var STENCIL_BACK_REF:Int;
	public var STENCIL_BACK_VALUE_MASK:Int;
	public var STENCIL_BACK_WRITEMASK:Int;
	public var STENCIL_BITS:Int;
	public var STENCIL_BUFFER_BIT:Int;
	public var STENCIL_CLEAR_VALUE:Int;
	public var STENCIL_FAIL:Int;
	public var STENCIL_FUNC:Int;
	public var STENCIL_INDEX:Int;
	public var STENCIL_INDEX8:Int;
	public var STENCIL_PASS_DEPTH_FAIL:Int;
	public var STENCIL_PASS_DEPTH_PASS:Int;
	public var STENCIL_REF:Int;
	public var STENCIL_TEST:Int;
	public var STENCIL_VALUE_MASK:Int;
	public var STENCIL_WRITEMASK:Int;
	public var STREAM_DRAW:Int;
	public var SUBPIXEL_BITS:Int;
	public var TEXTURE:Int;
	public var TEXTURE0:Int;
	public var TEXTURE1:Int;
	public var TEXTURE10:Int;
	public var TEXTURE11:Int;
	public var TEXTURE12:Int;
	public var TEXTURE13:Int;
	public var TEXTURE14:Int;
	public var TEXTURE15:Int;
	public var TEXTURE16:Int;
	public var TEXTURE17:Int;
	public var TEXTURE18:Int;
	public var TEXTURE19:Int;
	public var TEXTURE2:Int;
	public var TEXTURE20:Int;
	public var TEXTURE21:Int;
	public var TEXTURE22:Int;
	public var TEXTURE23:Int;
	public var TEXTURE24:Int;
	public var TEXTURE25:Int;
	public var TEXTURE26:Int;
	public var TEXTURE27:Int;
	public var TEXTURE28:Int;
	public var TEXTURE29:Int;
	public var TEXTURE3:Int;
	public var TEXTURE30:Int;
	public var TEXTURE31:Int;
	public var TEXTURE4:Int;
	public var TEXTURE5:Int;
	public var TEXTURE6:Int;
	public var TEXTURE7:Int;
	public var TEXTURE8:Int;
	public var TEXTURE9:Int;
	public var TEXTURE_2D:Int;
	public var TEXTURE_BINDING_2D:Int;
	public var TEXTURE_BINDING_CUBE_MAP:Int;
	public var TEXTURE_CUBE_MAP:Int;
	public var TEXTURE_CUBE_MAP_NEGATIVE_X:Int;
	public var TEXTURE_CUBE_MAP_NEGATIVE_Y:Int;
	public var TEXTURE_CUBE_MAP_NEGATIVE_Z:Int;
	public var TEXTURE_CUBE_MAP_POSITIVE_X:Int;
	public var TEXTURE_CUBE_MAP_POSITIVE_Y:Int;
	public var TEXTURE_CUBE_MAP_POSITIVE_Z:Int;
	public var TEXTURE_MAG_FILTER:Int;
	public var TEXTURE_MIN_FILTER:Int;
	public var TEXTURE_WRAP_S:Int;
	public var TEXTURE_WRAP_T:Int;
	public var TRIANGLES:Int;
	public var TRIANGLE_FAN:Int;
	public var TRIANGLE_STRIP:Int;
	public var UNPACK_ALIGNMENT:Int;
	public var UNPACK_COLORSPACE_CONVERSION_WEBGL:Int;
	public var UNPACK_FLIP_Y_WEBGL:Int;
	public var UNPACK_PREMULTIPLY_ALPHA_WEBGL:Int;
	public var UNSIGNED_BYTE:Int;
	public var UNSIGNED_INT:Int;
	public var UNSIGNED_SHORT:Int;
	public var UNSIGNED_SHORT_4_4_4_4:Int;
	public var UNSIGNED_SHORT_5_5_5_1:Int;
	public var UNSIGNED_SHORT_5_6_5:Int;
	public var VALIDATE_STATUS:Int;
	public var VENDOR:Int;
	public var VERSION:Int;
	public var VERTEX_ATTRIB_ARRAY_BUFFER_BINDING:Int;
	public var VERTEX_ATTRIB_ARRAY_ENABLED:Int;
	public var VERTEX_ATTRIB_ARRAY_NORMALIZED:Int;
	public var VERTEX_ATTRIB_ARRAY_POINTER:Int;
	public var VERTEX_ATTRIB_ARRAY_SIZE:Int;
	public var VERTEX_ATTRIB_ARRAY_STRIDE:Int;
	public var VERTEX_ATTRIB_ARRAY_TYPE:Int;
	public var VERTEX_SHADER:Int;
	public var VIEWPORT:Int;
	public var ZERO:Int;
	
	public var POINT_SPRITE:Int;
	public var VERTEX_PROGRAM_POINT_SIZE:Int;
	
	public var READ_BUFFER:Int;
	public var UNPACK_ROW_LENGTH:Int;
	public var UNPACK_SKIP_ROWS:Int;
	public var UNPACK_SKIP_PIXELS:Int;
	public var PACK_ROW_LENGTH:Int;
	public var PACK_SKIP_ROWS:Int;
	public var PACK_SKIP_PIXELS:Int;
	public var TEXTURE_BINDING_3D:Int;
	public var UNPACK_SKIP_IMAGES:Int;
	public var UNPACK_IMAGE_HEIGHT:Int;
	public var MAX_3D_TEXTURE_SIZE:Int;
	public var MAX_ELEMENTS_VERTICES:Int;
	public var MAX_ELEMENTS_INDICES:Int;
	public var MAX_TEXTURE_LOD_BIAS:Int;
	public var MAX_FRAGMENT_UNIFORM_COMPONENTS:Int;
	public var MAX_VERTEX_UNIFORM_COMPONENTS:Int;
	public var MAX_ARRAY_TEXTURE_LAYERS:Int;
	public var MIN_PROGRAM_TEXEL_OFFSET:Int;
	public var MAX_PROGRAM_TEXEL_OFFSET:Int;
	public var MAX_VARYING_COMPONENTS:Int;
	public var FRAGMENT_SHADER_DERIVATIVE_HINT:Int;
	public var RASTERIZER_DISCARD:Int;
	public var VERTEX_ARRAY_BINDING:Int;
	public var MAX_VERTEX_OUTPUT_COMPONENTS:Int;
	public var MAX_FRAGMENT_INPUT_COMPONENTS:Int;
	public var MAX_SERVER_WAIT_TIMEOUT:Int;
	public var MAX_ELEMENT_INDEX:Int;
	
	public var RED:Int;
	public var RGB8:Int;
	public var RGBA8:Int;
	public var RGB10_A2:Int;
	public var TEXTURE_3D:Int;
	public var TEXTURE_WRAP_R:Int;
	public var TEXTURE_MIN_LOD:Int;
	public var TEXTURE_MAX_LOD:Int;
	public var TEXTURE_BASE_LEVEL:Int;
	public var TEXTURE_MAX_LEVEL:Int;
	public var TEXTURE_COMPARE_MODE:Int;
	public var TEXTURE_COMPARE_FUNC:Int;
	public var SRGB:Int;
	public var SRGB8:Int;
	public var SRGB8_ALPHA8:Int;
	public var COMPARE_REF_TO_TEXTURE:Int;
	public var RGBA32F:Int;
	public var RGB32F:Int;
	public var RGBA16F:Int;
	public var RGB16F:Int;
	public var TEXTURE_2D_ARRAY:Int;
	public var TEXTURE_BINDING_2D_ARRAY:Int;
	public var R11F_G11F_B10F:Int;
	public var RGB9_E5:Int;
	public var RGBA32UI:Int;
	public var RGB32UI:Int;
	public var RGBA16UI:Int;
	public var RGB16UI:Int;
	public var RGBA8UI:Int;
	public var RGB8UI:Int;
	public var RGBA32I:Int;
	public var RGB32I:Int;
	public var RGBA16I:Int;
	public var RGB16I:Int;
	public var RGBA8I:Int;
	public var RGB8I:Int;
	public var RED_INTEGER:Int;
	public var RGB_INTEGER:Int;
	public var RGBA_INTEGER:Int;
	public var R8:Int;
	public var RG8:Int;
	public var R16F:Int;
	public var R32F:Int;
	public var RG16F:Int;
	public var RG32F:Int;
	public var R8I:Int;
	public var R8UI:Int;
	public var R16I:Int;
	public var R16UI:Int;
	public var R32I:Int;
	public var R32UI:Int;
	public var RG8I:Int;
	public var RG8UI:Int;
	public var RG16I:Int;
	public var RG16UI:Int;
	public var RG32I:Int;
	public var RG32UI:Int;
	public var R8_SNORM:Int;
	public var RG8_SNORM:Int;
	public var RGB8_SNORM:Int;
	public var RGBA8_SNORM:Int;
	public var RGB10_A2UI:Int;
	public var TEXTURE_IMMUTABLE_FORMAT:Int;
	public var TEXTURE_IMMUTABLE_LEVELS:Int;
	
	public var UNSIGNED_INT_2_10_10_10_REV:Int;
	public var UNSIGNED_INT_10F_11F_11F_REV:Int;
	public var UNSIGNED_INT_5_9_9_9_REV:Int;
	public var FLOAT_32_UNSIGNED_INT_24_8_REV:Int;
	public var UNSIGNED_INT_24_8:Int;
	public var HALF_FLOAT:Int;
	public var RG:Int;
	public var RG_INTEGER:Int;
	public var INT_2_10_10_10_REV:Int;
	
	public var CURRENT_QUERY:Int;
	public var QUERY_RESULT:Int;
	public var QUERY_RESULT_AVAILABLE:Int;
	public var ANY_SAMPLES_PASSED:Int;
	public var ANY_SAMPLES_PASSED_CONSERVATIVE:Int;
	
	public var MAX_DRAW_BUFFERS:Int;
	public var DRAW_BUFFER0:Int;
	public var DRAW_BUFFER1:Int;
	public var DRAW_BUFFER2:Int;
	public var DRAW_BUFFER3:Int;
	public var DRAW_BUFFER4:Int;
	public var DRAW_BUFFER5:Int;
	public var DRAW_BUFFER6:Int;
	public var DRAW_BUFFER7:Int;
	public var DRAW_BUFFER8:Int;
	public var DRAW_BUFFER9:Int;
	public var DRAW_BUFFER10:Int;
	public var DRAW_BUFFER11:Int;
	public var DRAW_BUFFER12:Int;
	public var DRAW_BUFFER13:Int;
	public var DRAW_BUFFER14:Int;
	public var DRAW_BUFFER15:Int;
	public var MAX_COLOR_ATTACHMENTS:Int;
	public var COLOR_ATTACHMENT1:Int;
	public var COLOR_ATTACHMENT2:Int;
	public var COLOR_ATTACHMENT3:Int;
	public var COLOR_ATTACHMENT4:Int;
	public var COLOR_ATTACHMENT5:Int;
	public var COLOR_ATTACHMENT6:Int;
	public var COLOR_ATTACHMENT7:Int;
	public var COLOR_ATTACHMENT8:Int;
	public var COLOR_ATTACHMENT9:Int;
	public var COLOR_ATTACHMENT10:Int;
	public var COLOR_ATTACHMENT11:Int;
	public var COLOR_ATTACHMENT12:Int;
	public var COLOR_ATTACHMENT13:Int;
	public var COLOR_ATTACHMENT14:Int;
	public var COLOR_ATTACHMENT15:Int;
	
	public var SAMPLER_3D:Int;
	public var SAMPLER_2D_SHADOW:Int;
	public var SAMPLER_2D_ARRAY:Int;
	public var SAMPLER_2D_ARRAY_SHADOW:Int;
	public var SAMPLER_CUBE_SHADOW:Int;
	public var INT_SAMPLER_2D:Int;
	public var INT_SAMPLER_3D:Int;
	public var INT_SAMPLER_CUBE:Int;
	public var INT_SAMPLER_2D_ARRAY:Int;
	public var UNSIGNED_INT_SAMPLER_2D:Int;
	public var UNSIGNED_INT_SAMPLER_3D:Int;
	public var UNSIGNED_INT_SAMPLER_CUBE:Int;
	public var UNSIGNED_INT_SAMPLER_2D_ARRAY:Int;
	public var MAX_SAMPLES:Int;
	public var SAMPLER_BINDING:Int;
	
	public var PIXEL_PACK_BUFFER:Int;
	public var PIXEL_UNPACK_BUFFER:Int;
	public var PIXEL_PACK_BUFFER_BINDING:Int;
	public var PIXEL_UNPACK_BUFFER_BINDING:Int;
	public var COPY_READ_BUFFER:Int;
	public var COPY_WRITE_BUFFER:Int;
	public var COPY_READ_BUFFER_BINDING:Int;
	public var COPY_WRITE_BUFFER_BINDING:Int;
	
	public var FLOAT_MAT2x3:Int;
	public var FLOAT_MAT2x4:Int;
	public var FLOAT_MAT3x2:Int;
	public var FLOAT_MAT3x4:Int;
	public var FLOAT_MAT4x2:Int;
	public var FLOAT_MAT4x3:Int;
	public var UNSIGNED_INT_VEC2:Int;
	public var UNSIGNED_INT_VEC3:Int;
	public var UNSIGNED_INT_VEC4:Int;
	public var UNSIGNED_NORMALIZED:Int;
	public var SIGNED_NORMALIZED:Int;
	
	public var VERTEX_ATTRIB_ARRAY_INTEGER:Int;
	public var VERTEX_ATTRIB_ARRAY_DIVISOR:Int;
	
	public var TRANSFORM_FEEDBACK_BUFFER_MODE:Int;
	public var MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS:Int;
	public var TRANSFORM_FEEDBACK_VARYINGS:Int;
	public var TRANSFORM_FEEDBACK_BUFFER_START:Int;
	public var TRANSFORM_FEEDBACK_BUFFER_SIZE:Int;
	public var TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN:Int;
	public var MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS:Int;
	public var MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS:Int;
	public var INTERLEAVED_ATTRIBS:Int;
	public var SEPARATE_ATTRIBS:Int;
	public var TRANSFORM_FEEDBACK_BUFFER:Int;
	public var TRANSFORM_FEEDBACK_BUFFER_BINDING:Int;
	public var TRANSFORM_FEEDBACK:Int;
	public var TRANSFORM_FEEDBACK_PAUSED:Int;
	public var TRANSFORM_FEEDBACK_ACTIVE:Int;
	public var TRANSFORM_FEEDBACK_BINDING:Int;
	
	public var FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING:Int;
	public var FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE:Int;
	public var FRAMEBUFFER_ATTACHMENT_RED_SIZE:Int;
	public var FRAMEBUFFER_ATTACHMENT_GREEN_SIZE:Int;
	public var FRAMEBUFFER_ATTACHMENT_BLUE_SIZE:Int;
	public var FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE:Int;
	public var FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE:Int;
	public var FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE:Int;
	public var FRAMEBUFFER_DEFAULT:Int;
	public var DEPTH24_STENCIL8:Int;
	public var DRAW_FRAMEBUFFER_BINDING:Int;
	public var READ_FRAMEBUFFER:Int;
	public var DRAW_FRAMEBUFFER:Int;
	public var READ_FRAMEBUFFER_BINDING:Int;
	public var RENDERBUFFER_SAMPLES:Int;
	public var FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER:Int;
	public var FRAMEBUFFER_INCOMPLETE_MULTISAMPLE:Int;
	
	public var UNIFORM_BUFFER:Int;
	public var UNIFORM_BUFFER_BINDING:Int;
	public var UNIFORM_BUFFER_START:Int;
	public var UNIFORM_BUFFER_SIZE:Int;
	public var MAX_VERTEX_UNIFORM_BLOCKS:Int;
	public var MAX_FRAGMENT_UNIFORM_BLOCKS:Int;
	public var MAX_COMBINED_UNIFORM_BLOCKS:Int;
	public var MAX_UNIFORM_BUFFER_BINDINGS:Int;
	public var MAX_UNIFORM_BLOCK_SIZE:Int;
	public var MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS:Int;
	public var MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS:Int;
	public var UNIFORM_BUFFER_OFFSET_ALIGNMENT:Int;
	public var ACTIVE_UNIFORM_BLOCKS:Int;
	public var UNIFORM_TYPE:Int;
	public var UNIFORM_SIZE:Int;
	public var UNIFORM_BLOCK_INDEX:Int;
	public var UNIFORM_OFFSET:Int;
	public var UNIFORM_ARRAY_STRIDE:Int;
	public var UNIFORM_MATRIX_STRIDE:Int;
	public var UNIFORM_IS_ROW_MAJOR:Int;
	public var UNIFORM_BLOCK_BINDING:Int;
	public var UNIFORM_BLOCK_DATA_SIZE:Int;
	public var UNIFORM_BLOCK_ACTIVE_UNIFORMS:Int;
	public var UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES:Int;
	public var UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER:Int;
	public var UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER:Int;
	
	public var OBJECT_TYPE:Int;
	public var SYNC_CONDITION:Int;
	public var SYNC_STATUS:Int;
	public var SYNC_FLAGS:Int;
	public var SYNC_FENCE:Int;
	public var SYNC_GPU_COMMANDS_COMPLETE:Int;
	public var UNSIGNALED:Int;
	public var SIGNALED:Int;
	public var ALREADY_SIGNALED:Int;
	public var TIMEOUT_EXPIRED:Int;
	public var CONDITION_SATISFIED:Int;
	public var WAIT_FAILED:Int;
	public var SYNC_FLUSH_COMMANDS_BIT:Int;
	
	public var COLOR:Int;
	public var DEPTH:Int;
	public var STENCIL:Int;
	public var MIN:Int;
	public var MAX:Int;
	public var DEPTH_COMPONENT24:Int;
	public var STREAM_READ:Int;
	public var STREAM_COPY:Int;
	public var STATIC_READ:Int;
	public var STATIC_COPY:Int;
	public var DYNAMIC_READ:Int;
	public var DYNAMIC_COPY:Int;
	public var DEPTH_COMPONENT32F:Int;
	public var DEPTH32F_STENCIL8:Int;
	public var INVALID_INDEX:Int;
	public var TIMEOUT_IGNORED:Int;
	public var MAX_CLIENT_WAIT_TIMEOUT_WEBGL:Int;
	
	#if (js && html5)
	public var canvas (get, never):CanvasElement;
	public var drawingBufferHeight (get, never):Int;
	public var drawingBufferWidth (get, never):Int;
	
	private function get_canvas () { return null; }
	private function get_drawingBufferHeight () { return 0; }
	private function get_drawingBufferWidth () { return 0; }
	#end
	
	public var type (default, null):GLContextType;
	public var version (default, null):Float;
	
	private function new () {}
	
	public function activeTexture (texture:Int):Void {}
	public function attachShader (program:GLProgram, shader:GLShader):Void {}
	public function bindAttribLocation (program:GLProgram, index:Int, name:String):Void {}
	public function bindBuffer (target:Int, buffer:GLBuffer):Void {}
	public function bindFramebuffer (target:Int, framebuffer:GLFramebuffer):Void {}
	public function bindRenderbuffer (target:Int, renderbuffer:GLRenderbuffer):Void {}
	public function bindTexture (target:Int, texture:GLTexture):Void {}
	public function blendColor (red:Float, green:Float, blue:Float, alpha:Float):Void {}
	public function blendEquation (mode:Int):Void {}
	public function blendEquationSeparate (modeRGB:Int, modeAlpha:Int):Void {}
	public function blendFunc (sfactor:Int, dfactor:Int):Void {}
	public function blendFuncSeparate (srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int):Void {}
	public function bufferData (target:Int, size:Int, srcData:DataPointer, usage:Int, srcOffset:Int = 0, length:Int = 0):Void {}
	public function bufferSubData (target:Int, dstByteOffset:Int, size:Int, srcData:DataPointer, srcOffset:Int = 0, length:Int = 0):Void {}
	public function checkFramebufferStatus (target:Int):Int { return 0; }
	public function clear (mask:Int):Void {}
	public function clearColor (red:Float, green:Float, blue:Float, alpha:Float):Void {}
	public function clearDepth (depth:Float):Void {}
	public function clearStencil (s:Int):Void {}
	public function colorMask (red:Bool, green:Bool, blue:Bool, alpha:Bool):Void {}
	public function compileShader (shader:GLShader):Void {}
	public function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, imageSize:Int, srcData:DataPointer, srcOffset:Int = 0, length:Int = 0):Void {}
	public function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, imageSize:Int, srcData:DataPointer, srcOffset:Int = 0, length:Int = 0):Void {}
	public function copyTexImage2D (target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void {}
	public function copyTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {}
	public function createBuffer ():GLBuffer { return null; }
	public function createFramebuffer ():GLFramebuffer { return null; }
	public function createProgram ():GLProgram { return null; }
	public function createRenderbuffer ():GLRenderbuffer { return null; }
	public function createShader (type:Int):GLShader { return null; }
	public function createTexture ():GLTexture { return null; }
	public function cullFace (mode:Int):Void {}
	public function deleteBuffer (buffer:GLBuffer):Void {}
	public function deleteFramebuffer (framebuffer:GLFramebuffer):Void {}
	public function deleteProgram (program:GLProgram):Void {}
	public function deleteRenderbuffer (renderbuffer:GLRenderbuffer):Void {}
	public function deleteShader (shader:GLShader):Void {}
	public function deleteTexture (texture:GLTexture):Void {}
	public function depthFunc (func:Int):Void {}
	public function depthMask (flag:Bool):Void {}
	public function depthRange (zNear:Float, zFar:Float):Void {}
	public function detachShader (program:GLProgram, shader:GLShader):Void {}
	public function disable (cap:Int):Void {}
	public function disableVertexAttribArray (index:Int):Void {}
	public function drawArrays (mode:Int, first:Int, count:Int):Void {}
	public function drawElements (mode:Int, count:Int, type:Int, offset:Dynamic):Void {}
	public function enable (cap:Int):Void {}
	public function enableVertexAttribArray (index:Int):Void {}
	public function finish ():Void {}
	public function flush ():Void {}
	public function framebufferRenderbuffer (target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:GLRenderbuffer):Void {}
	public function framebufferTexture2D (target:Int, attachment:Int, textarget:Int, texture:GLTexture, level:Int):Void {}
	public function frontFace (mode:Int):Void {}
	public function generateMipmap (target:Int):Void {}
	public function getActiveAttrib (program:GLProgram, index:Int):GLActiveInfo { return null; }
	public function getActiveUniform (program:GLProgram, index:Int):GLActiveInfo { return null; }
	public function getAttachedShaders (program:GLProgram):Array<GLShader> { return null; }
	public function getAttribLocation (program:GLProgram, name:String):Int { return 0; }
	public function getBoolean (pname:Int):Bool { return false; }
	public function getBooleanv (pname:Int):Array<Bool> { return null; }
	public function getBufferParameter (target:Int, pname:Int):Dynamic { return null; }
	public function getContextAttributes ():GLContextAttributes { return null; }
	public function getError ():Int { return 0; }
	public function getExtension (name:String):Dynamic { return null; }
	public function getFloat (pname:Int):Float { return 0; }
	public function getFloatv (pname:Int):Array<Float> { return null; };
	public function getFramebufferAttachmentParameter (target:Int, attachment:Int, pname:Int):Dynamic { return null; }
	public function getInteger (pname:Int):Int { return 0; }
	public function getIntegerv (pname:Int):Array<Int> { return null; }
	public function getParameter (pname:Int):Dynamic { return null; }
	public function getProgramInfoLog (program:GLProgram):String { return null; }
	public function getProgramParameter (program:GLProgram, pname:Int):Dynamic { return null; }
	public function getRenderbufferParameter (target:Int, pname:Int):Dynamic { return null; }
	public function getShaderInfoLog (shader:GLShader):String { return null; }
	public function getShaderParameter (shader:GLShader, pname:Int):Dynamic { return null; }
	public function getShaderPrecisionFormat (shadertype:Int, precisiontype:Int):GLShaderPrecisionFormat { return null; }
	public function getShaderSource (shader:GLShader):String { return null; }
	public function getString (pname:Int):String { return null; }
	public function getSupportedExtensions ():Array<String> { return null; }
	public function getTexParameter (target:Int, pname:Int):Dynamic { return null; }
	public function getUniform (program:GLProgram, location:GLUniformLocation):Dynamic { return null; }
	public function getUniformLocation (program:GLProgram, name:String):GLUniformLocation { return 0; }
	public function getVertexAttrib (index:Int, pname:Int):Dynamic { return null; }
	public function getVertexAttribOffset (index:Int, pname:Int):Int { return 0; }
	public function hint (target:Int, mode:Int):Void {}
	public function isBuffer (buffer:GLBuffer):Bool { return false; }
	public function isContextLost ():Bool { return false; }
	public function isEnabled (cap:Int):Bool { return false; }
	public function isFramebuffer (framebuffer:GLFramebuffer):Bool { return false; }
	public function isProgram (program:GLProgram):Bool { return false; }
	public function isRenderbuffer (renderbuffer:GLRenderbuffer):Bool { return false; }
	public function isShader (shader:GLShader):Bool { return false; }
	public function isTexture (texture:GLTexture):Bool { return false; }
	public function lineWidth (width:Float):Void {}
	public function linkProgram (program:GLProgram):Void {}
	public function pixelStorei (pname:Int, param:Int):Void {}
	public function polygonOffset (factor:Float, units:Float):Void {}
	public function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:DataPointer, dstOffset:Int = 0):Void {}
	public function releaseShaderCompiler ():Void {}
	public function renderbufferStorage (target:Int, internalformat:Int, width:Int, height:Int):Void {}
	public function sampleCoverage (value:Float, invert:Bool):Void {}
	public function scissor (x:Int, y:Int, width:Int, height:Int):Void {}
	public function shaderSource (shader:GLShader, string:String):Void {}
	public function stencilFunc (func:Int, ref:Int, mask:Int):Void {}
	public function stencilFuncSeparate (face:Int, func:Int, ref:Int, mask:Int):Void {}
	public function stencilMask (mask:Int):Void {}
	public function stencilMaskSeparate (face:Int, mask:Int):Void {}
	public function stencilOp (fail:Int, zfail:Int, zpass:Int):Void {}
	public function stencilOpSeparate (face:Int, fail:Int, zfail:Int, zpass:Int):Void {}
	public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, srcData:DataPointer, srcOffset:Int = 0):Void {}
	public function texParameterf (target:Int, pname:Int, param:Float):Void {}
	public function texParameteri (target:Int, pname:Int, param:Int):Void {}
	public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, srcData:DataPointer, srcOffset:Int = 0):Void {}
	public function uniform1f (location:GLUniformLocation, x:Float):Void {}
	public function uniform1fv (location:GLUniformLocation, v:lime.utils.Float32Array):Void {}
	public function uniform1i (location:GLUniformLocation, x:Int):Void {}
	public function uniform1iv (location:GLUniformLocation, v:lime.utils.Int32Array):Void {}
	public function uniform2f (location:GLUniformLocation, x:Float, y:Float):Void {}
	public function uniform2fv (location:GLUniformLocation, v:lime.utils.Float32Array):Void {}
	public function uniform2i (location:GLUniformLocation, x:Int, y:Int):Void {}
	public function uniform2iv (location:GLUniformLocation, v:lime.utils.Int32Array):Void {}
	public function uniform3f (location:GLUniformLocation, x:Float, y:Float, z:Float):Void {}
	public function uniform3fv(location:GLUniformLocation, v:lime.utils.Float32Array):Void {}
	public function uniform3i (location:GLUniformLocation, x:Int, y:Int, z:Int):Void {}
	public function uniform3iv (location:GLUniformLocation, v:lime.utils.Int32Array):Void {}
	public function uniform4f (location:GLUniformLocation, x:Float, y:Float, z:Float, w:Float):Void {}
	public function uniform4fv (location:GLUniformLocation, v:lime.utils.Float32Array):Void {}
	public function uniform4i (location:GLUniformLocation, x:Int, y:Int, z:Int, w:Int):Void {}
	public function uniform4iv (location:GLUniformLocation, v:lime.utils.Int32Array):Void {}
	public function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, array:lime.utils.Float32Array):Void {}
	public function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, array:lime.utils.Float32Array):Void {}
	public function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, array:lime.utils.Float32Array):Void {}
	public function useProgram (program:GLProgram):Void {}
	public function validateProgram (program:GLProgram):Void {}
	public function vertexAttrib1f (indx:Int, x:Float):Void {}
	public function vertexAttrib1fv (indx:Int, values:lime.utils.Float32Array):Void {}
	public function vertexAttrib2f (indx:Int, x:Float, y:Float):Void {}
	public function vertexAttrib2fv (indx:Int, values:lime.utils.Float32Array):Void {}
	public function vertexAttrib3f (indx:Int, x:Float, y:Float, z:Float):Void {}
	public function vertexAttrib3fv (indx:Int, values:lime.utils.Float32Array):Void {}
	public function vertexAttrib4f (indx:Int, x:Float, y:Float, z:Float, w:Float):Void {}
	public function vertexAttrib4fv (indx:Int, values:lime.utils.Float32Array):Void {}
	public function vertexAttribPointer (indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:DataPointer):Void {}
	public function viewport (x:Int, y:Int, width:Int, height:Int):Void {}
	
}


#end