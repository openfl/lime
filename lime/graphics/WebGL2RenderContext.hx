package lime.graphics;


import haxe.Int64;
import lime.graphics.opengl.*;
import lime.utils.ArrayBuffer;
import lime.utils.ArrayBufferView;
import lime.utils.BytePointer;
import lime.utils.DataPointer;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import lime.utils.UInt32Array;


abstract WebGL2RenderContext(GLRenderContext) from GLRenderContext to GLRenderContext {
	
	
	private static var __tempPointer = new BytePointer ();
	
	public var DEPTH_BUFFER_BIT (get, never):Int;
	public var STENCIL_BUFFER_BIT (get, never):Int;
	public var COLOR_BUFFER_BIT (get, never):Int;
	
	public var POINTS (get, never):Int;
	public var LINES (get, never):Int;
	public var LINE_LOOP (get, never):Int;
	public var LINE_STRIP (get, never):Int;
	public var TRIANGLES (get, never):Int;
	public var TRIANGLE_STRIP (get, never):Int;
	public var TRIANGLE_FAN (get, never):Int;
	
	public var ZERO (get, never):Int;
	public var ONE (get, never):Int;
	public var SRC_COLOR (get, never):Int;
	public var ONE_MINUS_SRC_COLOR (get, never):Int;
	public var SRC_ALPHA (get, never):Int;
	public var ONE_MINUS_SRC_ALPHA (get, never):Int;
	public var DST_ALPHA (get, never):Int;
	public var ONE_MINUS_DST_ALPHA (get, never):Int;
	
	public var DST_COLOR (get, never):Int;
	public var ONE_MINUS_DST_COLOR (get, never):Int;
	public var SRC_ALPHA_SATURATE (get, never):Int;
	
	public var FUNC_ADD (get, never):Int;
	public var BLEND_EQUATION (get, never):Int;
	public var BLEND_EQUATION_RGB (get, never):Int;
	public var BLEND_EQUATION_ALPHA (get, never):Int;
	
	public var FUNC_SUBTRACT (get, never):Int;
	public var FUNC_REVERSE_SUBTRACT (get, never):Int;
	
	public var BLEND_DST_RGB (get, never):Int;
	public var BLEND_SRC_RGB (get, never):Int;
	public var BLEND_DST_ALPHA (get, never):Int;
	public var BLEND_SRC_ALPHA (get, never):Int;
	public var CONSTANT_COLOR (get, never):Int;
	public var ONE_MINUS_CONSTANT_COLOR (get, never):Int;
	public var CONSTANT_ALPHA (get, never):Int;
	public var ONE_MINUS_CONSTANT_ALPHA (get, never):Int;
	public var BLEND_COLOR (get, never):Int;
	
	public var ARRAY_BUFFER (get, never):Int;
	public var ELEMENT_ARRAY_BUFFER (get, never):Int;
	public var ARRAY_BUFFER_BINDING (get, never):Int;
	public var ELEMENT_ARRAY_BUFFER_BINDING (get, never):Int;
	
	public var STREAM_DRAW (get, never):Int;
	public var STATIC_DRAW (get, never):Int;
	public var DYNAMIC_DRAW (get, never):Int;
	
	public var BUFFER_SIZE (get, never):Int;
	public var BUFFER_USAGE (get, never):Int;
	
	public var CURRENT_VERTEX_ATTRIB (get, never):Int;
	
	public var FRONT (get, never):Int;
	public var BACK (get, never):Int;
	public var FRONT_AND_BACK (get, never):Int;
	
	public var CULL_FACE (get, never):Int;
	public var BLEND (get, never):Int;
	public var DITHER (get, never):Int;
	public var STENCIL_TEST (get, never):Int;
	public var DEPTH_TEST (get, never):Int;
	public var SCISSOR_TEST (get, never):Int;
	public var POLYGON_OFFSET_FILL (get, never):Int;
	public var SAMPLE_ALPHA_TO_COVERAGE (get, never):Int;
	public var SAMPLE_COVERAGE (get, never):Int;
	
	public var NO_ERROR (get, never):Int;
	public var INVALID_ENUM (get, never):Int;
	public var INVALID_VALUE (get, never):Int;
	public var INVALID_OPERATION (get, never):Int;
	public var OUT_OF_MEMORY (get, never):Int;
	
	public var CW  (get, never):Int;
	public var CCW (get, never):Int;
	
	public var LINE_WIDTH (get, never):Int;
	public var ALIASED_POINT_SIZE_RANGE (get, never):Int;
	public var ALIASED_LINE_WIDTH_RANGE (get, never):Int;
	public var CULL_FACE_MODE (get, never):Int;
	public var FRONT_FACE (get, never):Int;
	public var DEPTH_RANGE (get, never):Int;
	public var DEPTH_WRITEMASK (get, never):Int;
	public var DEPTH_CLEAR_VALUE (get, never):Int;
	public var DEPTH_FUNC (get, never):Int;
	public var STENCIL_CLEAR_VALUE (get, never):Int;
	public var STENCIL_FUNC (get, never):Int;
	public var STENCIL_FAIL (get, never):Int;
	public var STENCIL_PASS_DEPTH_FAIL (get, never):Int;
	public var STENCIL_PASS_DEPTH_PASS (get, never):Int;
	public var STENCIL_REF (get, never):Int;
	public var STENCIL_VALUE_MASK (get, never):Int;
	public var STENCIL_WRITEMASK (get, never):Int;
	public var STENCIL_BACK_FUNC (get, never):Int;
	public var STENCIL_BACK_FAIL (get, never):Int;
	public var STENCIL_BACK_PASS_DEPTH_FAIL (get, never):Int;
	public var STENCIL_BACK_PASS_DEPTH_PASS (get, never):Int;
	public var STENCIL_BACK_REF (get, never):Int;
	public var STENCIL_BACK_VALUE_MASK (get, never):Int;
	public var STENCIL_BACK_WRITEMASK (get, never):Int;
	public var VIEWPORT (get, never):Int;
	public var SCISSOR_BOX (get, never):Int;
	
	public var COLOR_CLEAR_VALUE (get, never):Int;
	public var COLOR_WRITEMASK (get, never):Int;
	public var UNPACK_ALIGNMENT (get, never):Int;
	public var PACK_ALIGNMENT (get, never):Int;
	public var MAX_TEXTURE_SIZE (get, never):Int;
	public var MAX_VIEWPORT_DIMS (get, never):Int;
	public var SUBPIXEL_BITS (get, never):Int;
	public var RED_BITS (get, never):Int;
	public var GREEN_BITS (get, never):Int;
	public var BLUE_BITS (get, never):Int;
	public var ALPHA_BITS (get, never):Int;
	public var DEPTH_BITS (get, never):Int;
	public var STENCIL_BITS (get, never):Int;
	public var POLYGON_OFFSET_UNITS (get, never):Int;
	
	public var POLYGON_OFFSET_FACTOR (get, never):Int;
	public var TEXTURE_BINDING_2D (get, never):Int;
	public var SAMPLE_BUFFERS (get, never):Int;
	public var SAMPLES (get, never):Int;
	public var SAMPLE_COVERAGE_VALUE (get, never):Int;
	public var SAMPLE_COVERAGE_INVERT (get, never):Int;
	
	public var COMPRESSED_TEXTURE_FORMATS (get, never):Int;
	
	public var DONT_CARE (get, never):Int;
	public var FASTEST (get, never):Int;
	public var NICEST (get, never):Int;
	
	public var GENERATE_MIPMAP_HINT (get, never):Int;
	
	public var BYTE (get, never):Int;
	public var UNSIGNED_BYTE (get, never):Int;
	public var SHORT (get, never):Int;
	public var UNSIGNED_SHORT (get, never):Int;
	public var INT (get, never):Int;
	public var UNSIGNED_INT (get, never):Int;
	public var FLOAT (get, never):Int;
	
	public var DEPTH_COMPONENT (get, never):Int;
	public var ALPHA (get, never):Int;
	public var RGB (get, never):Int;
	public var RGBA (get, never):Int;
	public var LUMINANCE (get, never):Int;
	public var LUMINANCE_ALPHA (get, never):Int;
	
	public var UNSIGNED_SHORT_4_4_4_4 (get, never):Int;
	public var UNSIGNED_SHORT_5_5_5_1 (get, never):Int;
	public var UNSIGNED_SHORT_5_6_5 (get, never):Int;
	
	public var FRAGMENT_SHADER (get, never):Int;
	public var VERTEX_SHADER (get, never):Int;
	public var MAX_VERTEX_ATTRIBS (get, never):Int;
	public var MAX_VERTEX_UNIFORM_VECTORS (get, never):Int;
	public var MAX_VARYING_VECTORS (get, never):Int;
	public var MAX_COMBINED_TEXTURE_IMAGE_UNITS (get, never):Int;
	public var MAX_VERTEX_TEXTURE_IMAGE_UNITS (get, never):Int;
	public var MAX_TEXTURE_IMAGE_UNITS (get, never):Int;
	public var MAX_FRAGMENT_UNIFORM_VECTORS (get, never):Int;
	public var SHADER_TYPE (get, never):Int;
	public var DELETE_STATUS (get, never):Int;
	public var LINK_STATUS (get, never):Int;
	public var VALIDATE_STATUS (get, never):Int;
	public var ATTACHED_SHADERS (get, never):Int;
	public var ACTIVE_UNIFORMS (get, never):Int;
	public var ACTIVE_ATTRIBUTES (get, never):Int;
	public var SHADING_LANGUAGE_VERSION (get, never):Int;
	public var CURRENT_PROGRAM (get, never):Int;
	
	public var NEVER (get, never):Int;
	public var LESS (get, never):Int;
	public var EQUAL (get, never):Int;
	public var LEQUAL (get, never):Int;
	public var GREATER (get, never):Int;
	public var NOTEQUAL (get, never):Int;
	public var GEQUAL (get, never):Int;
	public var ALWAYS (get, never):Int;
	
	public var KEEP (get, never):Int;
	public var REPLACE (get, never):Int;
	public var INCR (get, never):Int;
	public var DECR (get, never):Int;
	public var INVERT (get, never):Int;
	public var INCR_WRAP (get, never):Int;
	public var DECR_WRAP (get, never):Int;
	
	public var VENDOR (get, never):Int;
	public var RENDERER (get, never):Int;
	public var VERSION (get, never):Int;
	
	public var NEAREST (get, never):Int;
	public var LINEAR (get, never):Int;
	
	public var NEAREST_MIPMAP_NEAREST (get, never):Int;
	public var LINEAR_MIPMAP_NEAREST (get, never):Int;
	public var NEAREST_MIPMAP_LINEAR (get, never):Int;
	public var LINEAR_MIPMAP_LINEAR (get, never):Int;
	
	public var TEXTURE_MAG_FILTER (get, never):Int;
	public var TEXTURE_MIN_FILTER (get, never):Int;
	public var TEXTURE_WRAP_S (get, never):Int;
	public var TEXTURE_WRAP_T (get, never):Int;
	
	public var TEXTURE_2D (get, never):Int;
	public var TEXTURE (get, never):Int;
	
	public var TEXTURE_CUBE_MAP (get, never):Int;
	public var TEXTURE_BINDING_CUBE_MAP (get, never):Int;
	public var TEXTURE_CUBE_MAP_POSITIVE_X (get, never):Int;
	public var TEXTURE_CUBE_MAP_NEGATIVE_X (get, never):Int;
	public var TEXTURE_CUBE_MAP_POSITIVE_Y (get, never):Int;
	public var TEXTURE_CUBE_MAP_NEGATIVE_Y (get, never):Int;
	public var TEXTURE_CUBE_MAP_POSITIVE_Z (get, never):Int;
	public var TEXTURE_CUBE_MAP_NEGATIVE_Z (get, never):Int;
	public var MAX_CUBE_MAP_TEXTURE_SIZE (get, never):Int;
	
	public var TEXTURE0 (get, never):Int;
	public var TEXTURE1 (get, never):Int;
	public var TEXTURE2 (get, never):Int;
	public var TEXTURE3 (get, never):Int;
	public var TEXTURE4 (get, never):Int;
	public var TEXTURE5 (get, never):Int;
	public var TEXTURE6 (get, never):Int;
	public var TEXTURE7 (get, never):Int;
	public var TEXTURE8 (get, never):Int;
	public var TEXTURE9 (get, never):Int;
	public var TEXTURE10 (get, never):Int;
	public var TEXTURE11 (get, never):Int;
	public var TEXTURE12 (get, never):Int;
	public var TEXTURE13 (get, never):Int;
	public var TEXTURE14 (get, never):Int;
	public var TEXTURE15 (get, never):Int;
	public var TEXTURE16 (get, never):Int;
	public var TEXTURE17 (get, never):Int;
	public var TEXTURE18 (get, never):Int;
	public var TEXTURE19 (get, never):Int;
	public var TEXTURE20 (get, never):Int;
	public var TEXTURE21 (get, never):Int;
	public var TEXTURE22 (get, never):Int;
	public var TEXTURE23 (get, never):Int;
	public var TEXTURE24 (get, never):Int;
	public var TEXTURE25 (get, never):Int;
	public var TEXTURE26 (get, never):Int;
	public var TEXTURE27 (get, never):Int;
	public var TEXTURE28 (get, never):Int;
	public var TEXTURE29 (get, never):Int;
	public var TEXTURE30 (get, never):Int;
	public var TEXTURE31 (get, never):Int;
	public var ACTIVE_TEXTURE (get, never):Int;
	
	public var REPEAT (get, never):Int;
	public var CLAMP_TO_EDGE (get, never):Int;
	public var MIRRORED_REPEAT (get, never):Int;
	
	public var FLOAT_VEC2 (get, never):Int;
	public var FLOAT_VEC3 (get, never):Int;
	public var FLOAT_VEC4 (get, never):Int;
	public var INT_VEC2 (get, never):Int;
	public var INT_VEC3 (get, never):Int;
	public var INT_VEC4 (get, never):Int;
	public var BOOL (get, never):Int;
	public var BOOL_VEC2 (get, never):Int;
	public var BOOL_VEC3 (get, never):Int;
	public var BOOL_VEC4 (get, never):Int;
	public var FLOAT_MAT2 (get, never):Int;
	public var FLOAT_MAT3 (get, never):Int;
	public var FLOAT_MAT4 (get, never):Int;
	public var SAMPLER_2D (get, never):Int;
	public var SAMPLER_CUBE (get, never):Int;
	
	public var VERTEX_ATTRIB_ARRAY_ENABLED (get, never):Int;
	public var VERTEX_ATTRIB_ARRAY_SIZE (get, never):Int;
	public var VERTEX_ATTRIB_ARRAY_STRIDE (get, never):Int;
	public var VERTEX_ATTRIB_ARRAY_TYPE (get, never):Int;
	public var VERTEX_ATTRIB_ARRAY_NORMALIZED (get, never):Int;
	public var VERTEX_ATTRIB_ARRAY_POINTER (get, never):Int;
	public var VERTEX_ATTRIB_ARRAY_BUFFER_BINDING (get, never):Int;
	
	public var COMPILE_STATUS (get, never):Int;
	
	public var LOW_FLOAT (get, never):Int;
	public var MEDIUM_FLOAT (get, never):Int;
	public var HIGH_FLOAT (get, never):Int;
	public var LOW_INT (get, never):Int;
	public var MEDIUM_INT (get, never):Int;
	public var HIGH_INT (get, never):Int;
	
	public var FRAMEBUFFER (get, never):Int;
	public var RENDERBUFFER (get, never):Int;
	
	public var RGBA4 (get, never):Int;
	public var RGB5_A1 (get, never):Int;
	public var RGB565 (get, never):Int;
	public var DEPTH_COMPONENT16 (get, never):Int;
	public var STENCIL_INDEX (get, never):Int;
	public var STENCIL_INDEX8 (get, never):Int;
	public var DEPTH_STENCIL (get, never):Int;
	
	public var RENDERBUFFER_WIDTH (get, never):Int;
	public var RENDERBUFFER_HEIGHT (get, never):Int;
	public var RENDERBUFFER_INTERNAL_FORMAT (get, never):Int;
	public var RENDERBUFFER_RED_SIZE (get, never):Int;
	public var RENDERBUFFER_GREEN_SIZE (get, never):Int;
	public var RENDERBUFFER_BLUE_SIZE (get, never):Int;
	public var RENDERBUFFER_ALPHA_SIZE (get, never):Int;
	public var RENDERBUFFER_DEPTH_SIZE (get, never):Int;
	public var RENDERBUFFER_STENCIL_SIZE (get, never):Int;
	
	public var FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE (get, never):Int;
	public var FRAMEBUFFER_ATTACHMENT_OBJECT_NAME (get, never):Int;
	public var FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL (get, never):Int;
	public var FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE (get, never):Int;
	
	public var COLOR_ATTACHMENT0 (get, never):Int;
	public var DEPTH_ATTACHMENT (get, never):Int;
	public var STENCIL_ATTACHMENT (get, never):Int;
	public var DEPTH_STENCIL_ATTACHMENT (get, never):Int;
	
	public var NONE (get, never):Int;
	
	public var FRAMEBUFFER_COMPLETE (get, never):Int;
	public var FRAMEBUFFER_INCOMPLETE_ATTACHMENT (get, never):Int;
	public var FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT (get, never):Int;
	public var FRAMEBUFFER_INCOMPLETE_DIMENSIONS (get, never):Int;
	public var FRAMEBUFFER_UNSUPPORTED (get, never):Int;
	
	public var FRAMEBUFFER_BINDING (get, never):Int;
	public var RENDERBUFFER_BINDING (get, never):Int;
	public var MAX_RENDERBUFFER_SIZE (get, never):Int;
	
	public var INVALID_FRAMEBUFFER_OPERATION (get, never):Int;
	
	public var UNPACK_FLIP_Y_WEBGL (get, never):Int;
	public var UNPACK_PREMULTIPLY_ALPHA_WEBGL (get, never):Int;
	public var CONTEXT_LOST_WEBGL (get, never):Int;
	public var UNPACK_COLORSPACE_CONVERSION_WEBGL (get, never):Int;
	public var BROWSER_DEFAULT_WEBGL (get, never):Int;
	
	public var READ_BUFFER (get, never):Int;
	public var UNPACK_ROW_LENGTH (get, never):Int;
	public var UNPACK_SKIP_ROWS (get, never):Int;
	public var UNPACK_SKIP_PIXELS (get, never):Int;
	public var PACK_ROW_LENGTH (get, never):Int;
	public var PACK_SKIP_ROWS (get, never):Int;
	public var PACK_SKIP_PIXELS (get, never):Int;
	public var TEXTURE_BINDING_3D (get, never):Int;
	public var UNPACK_SKIP_IMAGES (get, never):Int;
	public var UNPACK_IMAGE_HEIGHT (get, never):Int;
	public var MAX_3D_TEXTURE_SIZE (get, never):Int;
	public var MAX_ELEMENTS_VERTICES (get, never):Int;
	public var MAX_ELEMENTS_INDICES (get, never):Int;
	public var MAX_TEXTURE_LOD_BIAS (get, never):Int;
	public var MAX_FRAGMENT_UNIFORM_COMPONENTS (get, never):Int;
	public var MAX_VERTEX_UNIFORM_COMPONENTS (get, never):Int;
	public var MAX_ARRAY_TEXTURE_LAYERS (get, never):Int;
	public var MIN_PROGRAM_TEXEL_OFFSET (get, never):Int;
	public var MAX_PROGRAM_TEXEL_OFFSET (get, never):Int;
	public var MAX_VARYING_COMPONENTS (get, never):Int;
	public var FRAGMENT_SHADER_DERIVATIVE_HINT (get, never):Int;
	public var RASTERIZER_DISCARD (get, never):Int;
	public var VERTEX_ARRAY_BINDING (get, never):Int;
	public var MAX_VERTEX_OUTPUT_COMPONENTS (get, never):Int;
	public var MAX_FRAGMENT_INPUT_COMPONENTS (get, never):Int;
	public var MAX_SERVER_WAIT_TIMEOUT (get, never):Int;
	public var MAX_ELEMENT_INDEX (get, never):Int;
	
	public var RED (get, never):Int;
	public var RGB8 (get, never):Int;
	public var RGBA8 (get, never):Int;
	public var RGB10_A2 (get, never):Int;
	public var TEXTURE_3D (get, never):Int;
	public var TEXTURE_WRAP_R (get, never):Int;
	public var TEXTURE_MIN_LOD (get, never):Int;
	public var TEXTURE_MAX_LOD (get, never):Int;
	public var TEXTURE_BASE_LEVEL (get, never):Int;
	public var TEXTURE_MAX_LEVEL (get, never):Int;
	public var TEXTURE_COMPARE_MODE (get, never):Int;
	public var TEXTURE_COMPARE_FUNC (get, never):Int;
	public var SRGB (get, never):Int;
	public var SRGB8 (get, never):Int;
	public var SRGB8_ALPHA8 (get, never):Int;
	public var COMPARE_REF_TO_TEXTURE (get, never):Int;
	public var RGBA32F (get, never):Int;
	public var RGB32F (get, never):Int;
	public var RGBA16F (get, never):Int;
	public var RGB16F (get, never):Int;
	public var TEXTURE_2D_ARRAY (get, never):Int;
	public var TEXTURE_BINDING_2D_ARRAY (get, never):Int;
	public var R11F_G11F_B10F (get, never):Int;
	public var RGB9_E5 (get, never):Int;
	public var RGBA32UI (get, never):Int;
	public var RGB32UI (get, never):Int;
	public var RGBA16UI (get, never):Int;
	public var RGB16UI (get, never):Int;
	public var RGBA8UI (get, never):Int;
	public var RGB8UI (get, never):Int;
	public var RGBA32I (get, never):Int;
	public var RGB32I (get, never):Int;
	public var RGBA16I (get, never):Int;
	public var RGB16I (get, never):Int;
	public var RGBA8I (get, never):Int;
	public var RGB8I (get, never):Int;
	public var RED_INTEGER (get, never):Int;
	public var RGB_INTEGER (get, never):Int;
	public var RGBA_INTEGER (get, never):Int;
	public var R8 (get, never):Int;
	public var RG8 (get, never):Int;
	public var R16F (get, never):Int;
	public var R32F (get, never):Int;
	public var RG16F (get, never):Int;
	public var RG32F (get, never):Int;
	public var R8I (get, never):Int;
	public var R8UI (get, never):Int;
	public var R16I (get, never):Int;
	public var R16UI (get, never):Int;
	public var R32I (get, never):Int;
	public var R32UI (get, never):Int;
	public var RG8I (get, never):Int;
	public var RG8UI (get, never):Int;
	public var RG16I (get, never):Int;
	public var RG16UI (get, never):Int;
	public var RG32I (get, never):Int;
	public var RG32UI (get, never):Int;
	public var R8_SNORM (get, never):Int;
	public var RG8_SNORM (get, never):Int;
	public var RGB8_SNORM (get, never):Int;
	public var RGBA8_SNORM (get, never):Int;
	public var RGB10_A2UI (get, never):Int;
	public var TEXTURE_IMMUTABLE_FORMAT (get, never):Int;
	public var TEXTURE_IMMUTABLE_LEVELS (get, never):Int;
	
	public var UNSIGNED_INT_2_10_10_10_REV (get, never):Int;
	public var UNSIGNED_INT_10F_11F_11F_REV (get, never):Int;
	public var UNSIGNED_INT_5_9_9_9_REV (get, never):Int;
	public var FLOAT_32_UNSIGNED_INT_24_8_REV (get, never):Int;
	public var UNSIGNED_INT_24_8 (get, never):Int;
	public var HALF_FLOAT (get, never):Int;
	public var RG (get, never):Int;
	public var RG_INTEGER (get, never):Int;
	public var INT_2_10_10_10_REV (get, never):Int;
	
	public var CURRENT_QUERY (get, never):Int;
	public var QUERY_RESULT (get, never):Int;
	public var QUERY_RESULT_AVAILABLE (get, never):Int;
	public var ANY_SAMPLES_PASSED (get, never):Int;
	public var ANY_SAMPLES_PASSED_CONSERVATIVE (get, never):Int;
	
	public var MAX_DRAW_BUFFERS (get, never):Int;
	public var DRAW_BUFFER0 (get, never):Int;
	public var DRAW_BUFFER1 (get, never):Int;
	public var DRAW_BUFFER2 (get, never):Int;
	public var DRAW_BUFFER3 (get, never):Int;
	public var DRAW_BUFFER4 (get, never):Int;
	public var DRAW_BUFFER5 (get, never):Int;
	public var DRAW_BUFFER6 (get, never):Int;
	public var DRAW_BUFFER7 (get, never):Int;
	public var DRAW_BUFFER8 (get, never):Int;
	public var DRAW_BUFFER9 (get, never):Int;
	public var DRAW_BUFFER10 (get, never):Int;
	public var DRAW_BUFFER11 (get, never):Int;
	public var DRAW_BUFFER12 (get, never):Int;
	public var DRAW_BUFFER13 (get, never):Int;
	public var DRAW_BUFFER14 (get, never):Int;
	public var DRAW_BUFFER15 (get, never):Int;
	public var MAX_COLOR_ATTACHMENTS (get, never):Int;
	public var COLOR_ATTACHMENT1 (get, never):Int;
	public var COLOR_ATTACHMENT2 (get, never):Int;
	public var COLOR_ATTACHMENT3 (get, never):Int;
	public var COLOR_ATTACHMENT4 (get, never):Int;
	public var COLOR_ATTACHMENT5 (get, never):Int;
	public var COLOR_ATTACHMENT6 (get, never):Int;
	public var COLOR_ATTACHMENT7 (get, never):Int;
	public var COLOR_ATTACHMENT8 (get, never):Int;
	public var COLOR_ATTACHMENT9 (get, never):Int;
	public var COLOR_ATTACHMENT10 (get, never):Int;
	public var COLOR_ATTACHMENT11 (get, never):Int;
	public var COLOR_ATTACHMENT12 (get, never):Int;
	public var COLOR_ATTACHMENT13 (get, never):Int;
	public var COLOR_ATTACHMENT14 (get, never):Int;
	public var COLOR_ATTACHMENT15 (get, never):Int;
	
	public var SAMPLER_3D (get, never):Int;
	public var SAMPLER_2D_SHADOW (get, never):Int;
	public var SAMPLER_2D_ARRAY (get, never):Int;
	public var SAMPLER_2D_ARRAY_SHADOW (get, never):Int;
	public var SAMPLER_CUBE_SHADOW (get, never):Int;
	public var INT_SAMPLER_2D (get, never):Int;
	public var INT_SAMPLER_3D (get, never):Int;
	public var INT_SAMPLER_CUBE (get, never):Int;
	public var INT_SAMPLER_2D_ARRAY (get, never):Int;
	public var UNSIGNED_INT_SAMPLER_2D (get, never):Int;
	public var UNSIGNED_INT_SAMPLER_3D (get, never):Int;
	public var UNSIGNED_INT_SAMPLER_CUBE (get, never):Int;
	public var UNSIGNED_INT_SAMPLER_2D_ARRAY (get, never):Int;
	public var MAX_SAMPLES (get, never):Int;
	public var SAMPLER_BINDING (get, never):Int;
	
	public var PIXEL_PACK_BUFFER (get, never):Int;
	public var PIXEL_UNPACK_BUFFER (get, never):Int;
	public var PIXEL_PACK_BUFFER_BINDING (get, never):Int;
	public var PIXEL_UNPACK_BUFFER_BINDING (get, never):Int;
	public var COPY_READ_BUFFER (get, never):Int;
	public var COPY_WRITE_BUFFER (get, never):Int;
	public var COPY_READ_BUFFER_BINDING (get, never):Int;
	public var COPY_WRITE_BUFFER_BINDING (get, never):Int;
	
	public var FLOAT_MAT2x3 (get, never):Int;
	public var FLOAT_MAT2x4 (get, never):Int;
	public var FLOAT_MAT3x2 (get, never):Int;
	public var FLOAT_MAT3x4 (get, never):Int;
	public var FLOAT_MAT4x2 (get, never):Int;
	public var FLOAT_MAT4x3 (get, never):Int;
	public var UNSIGNED_INT_VEC2 (get, never):Int;
	public var UNSIGNED_INT_VEC3 (get, never):Int;
	public var UNSIGNED_INT_VEC4 (get, never):Int;
	public var UNSIGNED_NORMALIZED (get, never):Int;
	public var SIGNED_NORMALIZED (get, never):Int;
	
	public var VERTEX_ATTRIB_ARRAY_INTEGER (get, never):Int;
	public var VERTEX_ATTRIB_ARRAY_DIVISOR (get, never):Int;
	
	public var TRANSFORM_FEEDBACK_BUFFER_MODE (get, never):Int;
	public var MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS (get, never):Int;
	public var TRANSFORM_FEEDBACK_VARYINGS (get, never):Int;
	public var TRANSFORM_FEEDBACK_BUFFER_START (get, never):Int;
	public var TRANSFORM_FEEDBACK_BUFFER_SIZE (get, never):Int;
	public var TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN (get, never):Int;
	public var MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS (get, never):Int;
	public var MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS (get, never):Int;
	public var INTERLEAVED_ATTRIBS (get, never):Int;
	public var SEPARATE_ATTRIBS (get, never):Int;
	public var TRANSFORM_FEEDBACK_BUFFER (get, never):Int;
	public var TRANSFORM_FEEDBACK_BUFFER_BINDING (get, never):Int;
	public var TRANSFORM_FEEDBACK (get, never):Int;
	public var TRANSFORM_FEEDBACK_PAUSED (get, never):Int;
	public var TRANSFORM_FEEDBACK_ACTIVE (get, never):Int;
	public var TRANSFORM_FEEDBACK_BINDING (get, never):Int;
	
	public var FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING (get, never):Int;
	public var FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE (get, never):Int;
	public var FRAMEBUFFER_ATTACHMENT_RED_SIZE (get, never):Int;
	public var FRAMEBUFFER_ATTACHMENT_GREEN_SIZE (get, never):Int;
	public var FRAMEBUFFER_ATTACHMENT_BLUE_SIZE (get, never):Int;
	public var FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE (get, never):Int;
	public var FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE (get, never):Int;
	public var FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE (get, never):Int;
	public var FRAMEBUFFER_DEFAULT (get, never):Int;
	public var DEPTH24_STENCIL8 (get, never):Int;
	public var DRAW_FRAMEBUFFER_BINDING (get, never):Int;
	public var READ_FRAMEBUFFER (get, never):Int;
	public var DRAW_FRAMEBUFFER (get, never):Int;
	public var READ_FRAMEBUFFER_BINDING (get, never):Int;
	public var RENDERBUFFER_SAMPLES (get, never):Int;
	public var FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER (get, never):Int;
	public var FRAMEBUFFER_INCOMPLETE_MULTISAMPLE (get, never):Int;
	
	public var UNIFORM_BUFFER (get, never):Int;
	public var UNIFORM_BUFFER_BINDING (get, never):Int;
	public var UNIFORM_BUFFER_START (get, never):Int;
	public var UNIFORM_BUFFER_SIZE (get, never):Int;
	public var MAX_VERTEX_UNIFORM_BLOCKS (get, never):Int;
	public var MAX_FRAGMENT_UNIFORM_BLOCKS (get, never):Int;
	public var MAX_COMBINED_UNIFORM_BLOCKS (get, never):Int;
	public var MAX_UNIFORM_BUFFER_BINDINGS (get, never):Int;
	public var MAX_UNIFORM_BLOCK_SIZE (get, never):Int;
	public var MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS (get, never):Int;
	public var MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS (get, never):Int;
	public var UNIFORM_BUFFER_OFFSET_ALIGNMENT (get, never):Int;
	public var ACTIVE_UNIFORM_BLOCKS (get, never):Int;
	public var UNIFORM_TYPE (get, never):Int;
	public var UNIFORM_SIZE (get, never):Int;
	public var UNIFORM_BLOCK_INDEX (get, never):Int;
	public var UNIFORM_OFFSET (get, never):Int;
	public var UNIFORM_ARRAY_STRIDE (get, never):Int;
	public var UNIFORM_MATRIX_STRIDE (get, never):Int;
	public var UNIFORM_IS_ROW_MAJOR (get, never):Int;
	public var UNIFORM_BLOCK_BINDING (get, never):Int;
	public var UNIFORM_BLOCK_DATA_SIZE (get, never):Int;
	public var UNIFORM_BLOCK_ACTIVE_UNIFORMS (get, never):Int;
	public var UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES (get, never):Int;
	public var UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER (get, never):Int;
	public var UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER (get, never):Int;
	
	public var OBJECT_TYPE (get, never):Int;
	public var SYNC_CONDITION (get, never):Int;
	public var SYNC_STATUS (get, never):Int;
	public var SYNC_FLAGS (get, never):Int;
	public var SYNC_FENCE (get, never):Int;
	public var SYNC_GPU_COMMANDS_COMPLETE (get, never):Int;
	public var UNSIGNALED (get, never):Int;
	public var SIGNALED (get, never):Int;
	public var ALREADY_SIGNALED (get, never):Int;
	public var TIMEOUT_EXPIRED (get, never):Int;
	public var CONDITION_SATISFIED (get, never):Int;
	public var WAIT_FAILED (get, never):Int;
	public var SYNC_FLUSH_COMMANDS_BIT (get, never):Int;
	
	public var COLOR (get, never):Int;
	public var DEPTH (get, never):Int;
	public var STENCIL (get, never):Int;
	public var MIN (get, never):Int;
	public var MAX (get, never):Int;
	public var DEPTH_COMPONENT24 (get, never):Int;
	public var STREAM_READ (get, never):Int;
	public var STREAM_COPY (get, never):Int;
	public var STATIC_READ (get, never):Int;
	public var STATIC_COPY (get, never):Int;
	public var DYNAMIC_READ (get, never):Int;
	public var DYNAMIC_COPY (get, never):Int;
	public var DEPTH_COMPONENT32F (get, never):Int;
	public var DEPTH32F_STENCIL8 (get, never):Int;
	public var INVALID_INDEX (get, never):Int;
	public var TIMEOUT_IGNORED (get, never):Int;
	public var MAX_CLIENT_WAIT_TIMEOUT_WEBGL (get, never):Int;
	
	public var type (get, never):RenderContextType;
	public var version (get, never):Float;
	
	private inline function get_DEPTH_BUFFER_BIT ():Int { return this.DEPTH_BUFFER_BIT; }
	private inline function get_STENCIL_BUFFER_BIT ():Int { return this.STENCIL_BUFFER_BIT; }
	private inline function get_COLOR_BUFFER_BIT ():Int { return this.COLOR_BUFFER_BIT; }
	private inline function get_POINTS ():Int { return this.POINTS; }
	private inline function get_LINES ():Int { return this.LINES; }
	private inline function get_LINE_LOOP ():Int { return this.LINE_LOOP; }
	private inline function get_LINE_STRIP ():Int { return this.LINE_STRIP; }
	private inline function get_TRIANGLES ():Int { return this.TRIANGLES; }
	private inline function get_TRIANGLE_STRIP ():Int { return this.TRIANGLE_STRIP; }
	private inline function get_TRIANGLE_FAN ():Int { return this.TRIANGLE_FAN; }
	private inline function get_ZERO ():Int { return this.ZERO; }
	private inline function get_ONE ():Int { return this.ONE; }
	private inline function get_SRC_COLOR ():Int { return this.SRC_COLOR; }
	private inline function get_ONE_MINUS_SRC_COLOR ():Int { return this.ONE_MINUS_SRC_COLOR; }
	private inline function get_SRC_ALPHA ():Int { return this.SRC_ALPHA; }
	private inline function get_ONE_MINUS_SRC_ALPHA ():Int { return this.ONE_MINUS_SRC_ALPHA; }
	private inline function get_DST_ALPHA ():Int { return this.DST_ALPHA; }
	private inline function get_ONE_MINUS_DST_ALPHA ():Int { return this.ONE_MINUS_DST_ALPHA; }
	private inline function get_DST_COLOR ():Int { return this.DST_COLOR; }
	private inline function get_ONE_MINUS_DST_COLOR ():Int { return this.ONE_MINUS_DST_COLOR; }
	private inline function get_SRC_ALPHA_SATURATE ():Int { return this.SRC_ALPHA_SATURATE; }
	private inline function get_FUNC_ADD ():Int { return this.FUNC_ADD; }
	private inline function get_BLEND_EQUATION ():Int { return this.BLEND_EQUATION; }
	private inline function get_BLEND_EQUATION_RGB ():Int { return this.BLEND_EQUATION_RGB; }
	private inline function get_BLEND_EQUATION_ALPHA ():Int { return this.BLEND_EQUATION_ALPHA; }
	private inline function get_FUNC_SUBTRACT ():Int { return this.FUNC_SUBTRACT; }
	private inline function get_FUNC_REVERSE_SUBTRACT ():Int { return this.FUNC_REVERSE_SUBTRACT; }
	private inline function get_BLEND_DST_RGB ():Int { return this.BLEND_DST_RGB; }
	private inline function get_BLEND_SRC_RGB ():Int { return this.BLEND_SRC_RGB; }
	private inline function get_BLEND_DST_ALPHA ():Int { return this.BLEND_DST_ALPHA; }
	private inline function get_BLEND_SRC_ALPHA ():Int { return this.BLEND_SRC_ALPHA; }
	private inline function get_CONSTANT_COLOR ():Int { return this.CONSTANT_COLOR; }
	private inline function get_ONE_MINUS_CONSTANT_COLOR ():Int { return this.ONE_MINUS_CONSTANT_COLOR; }
	private inline function get_CONSTANT_ALPHA ():Int { return this.CONSTANT_ALPHA; }
	private inline function get_ONE_MINUS_CONSTANT_ALPHA ():Int { return this.ONE_MINUS_CONSTANT_ALPHA; }
	private inline function get_BLEND_COLOR ():Int { return this.BLEND_COLOR; }
	private inline function get_ARRAY_BUFFER ():Int { return this.ARRAY_BUFFER; }
	private inline function get_ELEMENT_ARRAY_BUFFER ():Int { return this.ELEMENT_ARRAY_BUFFER; }
	private inline function get_ARRAY_BUFFER_BINDING ():Int { return this.ARRAY_BUFFER_BINDING; }
	private inline function get_ELEMENT_ARRAY_BUFFER_BINDING ():Int { return this.ELEMENT_ARRAY_BUFFER_BINDING; }
	private inline function get_STREAM_DRAW ():Int { return this.STREAM_DRAW; }
	private inline function get_STATIC_DRAW ():Int { return this.STATIC_DRAW; }
	private inline function get_DYNAMIC_DRAW ():Int { return this.DYNAMIC_DRAW; }
	private inline function get_BUFFER_SIZE ():Int { return this.BUFFER_SIZE; }
	private inline function get_BUFFER_USAGE ():Int { return this.BUFFER_USAGE; }
	private inline function get_CURRENT_VERTEX_ATTRIB ():Int { return this.CURRENT_VERTEX_ATTRIB; }
	private inline function get_FRONT ():Int { return this.FRONT; }
	private inline function get_BACK ():Int { return this.BACK; }
	private inline function get_FRONT_AND_BACK ():Int { return this.FRONT_AND_BACK; }
	private inline function get_CULL_FACE ():Int { return this.CULL_FACE; }
	private inline function get_BLEND ():Int { return this.BLEND; }
	private inline function get_DITHER ():Int { return this.DITHER; }
	private inline function get_STENCIL_TEST ():Int { return this.STENCIL_TEST; }
	private inline function get_DEPTH_TEST ():Int { return this.DEPTH_TEST; }
	private inline function get_SCISSOR_TEST ():Int { return this.SCISSOR_TEST; }
	private inline function get_POLYGON_OFFSET_FILL ():Int { return this.POLYGON_OFFSET_FILL; }
	private inline function get_SAMPLE_ALPHA_TO_COVERAGE ():Int { return this.SAMPLE_ALPHA_TO_COVERAGE; }
	private inline function get_SAMPLE_COVERAGE ():Int { return this.SAMPLE_COVERAGE; }
	private inline function get_NO_ERROR ():Int { return this.NO_ERROR; }
	private inline function get_INVALID_ENUM ():Int { return this.INVALID_ENUM; }
	private inline function get_INVALID_VALUE ():Int { return this.INVALID_VALUE; }
	private inline function get_INVALID_OPERATION ():Int { return this.INVALID_OPERATION; }
	private inline function get_OUT_OF_MEMORY ():Int { return this.OUT_OF_MEMORY; }
	private inline function get_CW ():Int { return this.CW; }
	private inline function get_CCW ():Int { return this.CCW; }
	private inline function get_LINE_WIDTH ():Int { return this.LINE_WIDTH; }
	private inline function get_ALIASED_POINT_SIZE_RANGE ():Int { return this.ALIASED_POINT_SIZE_RANGE; }
	private inline function get_ALIASED_LINE_WIDTH_RANGE ():Int { return this.ALIASED_LINE_WIDTH_RANGE; }
	private inline function get_CULL_FACE_MODE ():Int { return this.CULL_FACE_MODE; }
	private inline function get_FRONT_FACE ():Int { return this.FRONT_FACE; }
	private inline function get_DEPTH_RANGE ():Int { return this.DEPTH_RANGE; }
	private inline function get_DEPTH_WRITEMASK ():Int { return this.DEPTH_WRITEMASK; }
	private inline function get_DEPTH_CLEAR_VALUE ():Int { return this.DEPTH_CLEAR_VALUE; }
	private inline function get_DEPTH_FUNC ():Int { return this.DEPTH_FUNC; }
	private inline function get_STENCIL_CLEAR_VALUE ():Int { return this.STENCIL_CLEAR_VALUE; }
	private inline function get_STENCIL_FUNC ():Int { return this.STENCIL_FUNC; }
	private inline function get_STENCIL_FAIL ():Int { return this.STENCIL_FAIL; }
	private inline function get_STENCIL_PASS_DEPTH_FAIL ():Int { return this.STENCIL_PASS_DEPTH_FAIL; }
	private inline function get_STENCIL_PASS_DEPTH_PASS ():Int { return this.STENCIL_PASS_DEPTH_PASS; }
	private inline function get_STENCIL_REF ():Int { return this.STENCIL_REF; }
	private inline function get_STENCIL_VALUE_MASK ():Int { return this.STENCIL_VALUE_MASK; }
	private inline function get_STENCIL_WRITEMASK ():Int { return this.STENCIL_WRITEMASK; }
	private inline function get_STENCIL_BACK_FUNC ():Int { return this.STENCIL_BACK_FUNC; }
	private inline function get_STENCIL_BACK_FAIL ():Int { return this.STENCIL_BACK_FAIL; }
	private inline function get_STENCIL_BACK_PASS_DEPTH_FAIL ():Int { return this.STENCIL_BACK_PASS_DEPTH_FAIL; }
	private inline function get_STENCIL_BACK_PASS_DEPTH_PASS ():Int { return this.STENCIL_BACK_PASS_DEPTH_PASS; }
	private inline function get_STENCIL_BACK_REF ():Int { return this.STENCIL_BACK_REF; }
	private inline function get_STENCIL_BACK_VALUE_MASK ():Int { return this.STENCIL_BACK_VALUE_MASK; }
	private inline function get_STENCIL_BACK_WRITEMASK ():Int { return this.STENCIL_BACK_WRITEMASK; }
	private inline function get_VIEWPORT ():Int { return this.VIEWPORT; }
	private inline function get_SCISSOR_BOX ():Int { return this.SCISSOR_BOX; }
	private inline function get_COLOR_CLEAR_VALUE ():Int { return this.COLOR_CLEAR_VALUE; }
	private inline function get_COLOR_WRITEMASK ():Int { return this.COLOR_WRITEMASK; }
	private inline function get_UNPACK_ALIGNMENT ():Int { return this.UNPACK_ALIGNMENT; }
	private inline function get_PACK_ALIGNMENT ():Int { return this.PACK_ALIGNMENT; }
	private inline function get_MAX_TEXTURE_SIZE ():Int { return this.MAX_TEXTURE_SIZE; }
	private inline function get_MAX_VIEWPORT_DIMS ():Int { return this.MAX_VIEWPORT_DIMS; }
	private inline function get_SUBPIXEL_BITS ():Int { return this.SUBPIXEL_BITS; }
	private inline function get_RED_BITS ():Int { return this.RED_BITS; }
	private inline function get_GREEN_BITS ():Int { return this.GREEN_BITS; }
	private inline function get_BLUE_BITS ():Int { return this.BLUE_BITS; }
	private inline function get_ALPHA_BITS ():Int { return this.ALPHA_BITS; }
	private inline function get_DEPTH_BITS ():Int { return this.DEPTH_BITS; }
	private inline function get_STENCIL_BITS ():Int { return this.STENCIL_BITS; }
	private inline function get_POLYGON_OFFSET_UNITS ():Int { return this.POLYGON_OFFSET_UNITS; }
	private inline function get_POLYGON_OFFSET_FACTOR ():Int { return this.POLYGON_OFFSET_FACTOR; }
	private inline function get_TEXTURE_BINDING_2D ():Int { return this.TEXTURE_BINDING_2D; }
	private inline function get_SAMPLE_BUFFERS ():Int { return this.SAMPLE_BUFFERS; }
	private inline function get_SAMPLES ():Int { return this.SAMPLES; }
	private inline function get_SAMPLE_COVERAGE_VALUE ():Int { return this.SAMPLE_COVERAGE_VALUE; }
	private inline function get_SAMPLE_COVERAGE_INVERT ():Int { return this.SAMPLE_COVERAGE_INVERT; }
	private inline function get_COMPRESSED_TEXTURE_FORMATS ():Int { return this.COMPRESSED_TEXTURE_FORMATS; }
	private inline function get_DONT_CARE ():Int { return this.DONT_CARE; }
	private inline function get_FASTEST ():Int { return this.FASTEST; }
	private inline function get_NICEST ():Int { return this.NICEST; }
	private inline function get_GENERATE_MIPMAP_HINT ():Int { return this.GENERATE_MIPMAP_HINT; }
	private inline function get_BYTE ():Int { return this.BYTE; }
	private inline function get_UNSIGNED_BYTE ():Int { return this.UNSIGNED_BYTE; }
	private inline function get_SHORT ():Int { return this.SHORT; }
	private inline function get_UNSIGNED_SHORT ():Int { return this.UNSIGNED_SHORT; }
	private inline function get_INT ():Int { return this.INT; }
	private inline function get_UNSIGNED_INT ():Int { return this.UNSIGNED_INT; }
	private inline function get_FLOAT ():Int { return this.FLOAT; }
	private inline function get_DEPTH_COMPONENT ():Int { return this.DEPTH_COMPONENT; }
	private inline function get_ALPHA ():Int { return this.ALPHA; }
	private inline function get_RGB ():Int { return this.RGB; }
	private inline function get_RGBA ():Int { return this.RGBA; }
	private inline function get_LUMINANCE ():Int { return this.LUMINANCE; }
	private inline function get_LUMINANCE_ALPHA ():Int { return this.LUMINANCE_ALPHA; }
	private inline function get_UNSIGNED_SHORT_4_4_4_4 ():Int { return this.UNSIGNED_SHORT_4_4_4_4; }
	private inline function get_UNSIGNED_SHORT_5_5_5_1 ():Int { return this.UNSIGNED_SHORT_5_5_5_1; }
	private inline function get_UNSIGNED_SHORT_5_6_5 ():Int { return this.UNSIGNED_SHORT_5_6_5; }
	private inline function get_FRAGMENT_SHADER ():Int { return this.FRAGMENT_SHADER; }
	private inline function get_VERTEX_SHADER ():Int { return this.VERTEX_SHADER; }
	private inline function get_MAX_VERTEX_ATTRIBS ():Int { return this.MAX_VERTEX_ATTRIBS; }
	private inline function get_MAX_VERTEX_UNIFORM_VECTORS ():Int { return this.MAX_VERTEX_UNIFORM_VECTORS; }
	private inline function get_MAX_VARYING_VECTORS ():Int { return this.MAX_VARYING_VECTORS; }
	private inline function get_MAX_COMBINED_TEXTURE_IMAGE_UNITS ():Int { return this.MAX_COMBINED_TEXTURE_IMAGE_UNITS; }
	private inline function get_MAX_VERTEX_TEXTURE_IMAGE_UNITS ():Int { return this.MAX_VERTEX_TEXTURE_IMAGE_UNITS; }
	private inline function get_MAX_TEXTURE_IMAGE_UNITS ():Int { return this.MAX_TEXTURE_IMAGE_UNITS; }
	private inline function get_MAX_FRAGMENT_UNIFORM_VECTORS ():Int { return this.MAX_FRAGMENT_UNIFORM_VECTORS; }
	private inline function get_SHADER_TYPE ():Int { return this.SHADER_TYPE; }
	private inline function get_DELETE_STATUS ():Int { return this.DELETE_STATUS; }
	private inline function get_LINK_STATUS ():Int { return this.LINK_STATUS; }
	private inline function get_VALIDATE_STATUS ():Int { return this.VALIDATE_STATUS; }
	private inline function get_ATTACHED_SHADERS ():Int { return this.ATTACHED_SHADERS; }
	private inline function get_ACTIVE_UNIFORMS ():Int { return this.ACTIVE_UNIFORMS; }
	private inline function get_ACTIVE_ATTRIBUTES ():Int { return this.ACTIVE_ATTRIBUTES; }
	private inline function get_SHADING_LANGUAGE_VERSION ():Int { return this.SHADING_LANGUAGE_VERSION; }
	private inline function get_CURRENT_PROGRAM ():Int { return this.CURRENT_PROGRAM; }
	private inline function get_NEVER ():Int { return this.NEVER; }
	private inline function get_LESS ():Int { return this.LESS; }
	private inline function get_EQUAL ():Int { return this.EQUAL; }
	private inline function get_LEQUAL ():Int { return this.LEQUAL; }
	private inline function get_GREATER ():Int { return this.GREATER; }
	private inline function get_NOTEQUAL ():Int { return this.NOTEQUAL; }
	private inline function get_GEQUAL ():Int { return this.GEQUAL; }
	private inline function get_ALWAYS ():Int { return this.ALWAYS; }
	private inline function get_KEEP ():Int { return this.KEEP; }
	private inline function get_REPLACE ():Int { return this.REPLACE; }
	private inline function get_INCR ():Int { return this.INCR; }
	private inline function get_DECR ():Int { return this.DECR; }
	private inline function get_INVERT ():Int { return this.INVERT; }
	private inline function get_INCR_WRAP ():Int { return this.INCR_WRAP; }
	private inline function get_DECR_WRAP ():Int { return this.DECR_WRAP; }
	private inline function get_VENDOR ():Int { return this.VENDOR; }
	private inline function get_RENDERER ():Int { return this.RENDERER; }
	private inline function get_VERSION ():Int { return this.VERSION; }
	private inline function get_NEAREST ():Int { return this.NEAREST; }
	private inline function get_LINEAR ():Int { return this.LINEAR; }
	private inline function get_NEAREST_MIPMAP_NEAREST ():Int { return this.NEAREST_MIPMAP_NEAREST; }
	private inline function get_LINEAR_MIPMAP_NEAREST ():Int { return this.LINEAR_MIPMAP_NEAREST; }
	private inline function get_NEAREST_MIPMAP_LINEAR ():Int { return this.NEAREST_MIPMAP_LINEAR; }
	private inline function get_LINEAR_MIPMAP_LINEAR ():Int { return this.LINEAR_MIPMAP_LINEAR; }
	private inline function get_TEXTURE_MAG_FILTER ():Int { return this.TEXTURE_MAG_FILTER; }
	private inline function get_TEXTURE_MIN_FILTER ():Int { return this.TEXTURE_MIN_FILTER; }
	private inline function get_TEXTURE_WRAP_S ():Int { return this.TEXTURE_WRAP_S; }
	private inline function get_TEXTURE_WRAP_T ():Int { return this.TEXTURE_WRAP_T; }
	private inline function get_TEXTURE_2D ():Int { return this.TEXTURE_2D; }
	private inline function get_TEXTURE ():Int { return this.TEXTURE; }
	private inline function get_TEXTURE_CUBE_MAP ():Int { return this.TEXTURE_CUBE_MAP; }
	private inline function get_TEXTURE_BINDING_CUBE_MAP ():Int { return this.TEXTURE_BINDING_CUBE_MAP; }
	private inline function get_TEXTURE_CUBE_MAP_POSITIVE_X ():Int { return this.TEXTURE_CUBE_MAP_POSITIVE_X; }
	private inline function get_TEXTURE_CUBE_MAP_NEGATIVE_X ():Int { return this.TEXTURE_CUBE_MAP_NEGATIVE_X; }
	private inline function get_TEXTURE_CUBE_MAP_POSITIVE_Y ():Int { return this.TEXTURE_CUBE_MAP_POSITIVE_Y; }
	private inline function get_TEXTURE_CUBE_MAP_NEGATIVE_Y ():Int { return this.TEXTURE_CUBE_MAP_NEGATIVE_Y; }
	private inline function get_TEXTURE_CUBE_MAP_POSITIVE_Z ():Int { return this.TEXTURE_CUBE_MAP_POSITIVE_Z; }
	private inline function get_TEXTURE_CUBE_MAP_NEGATIVE_Z ():Int { return this.TEXTURE_CUBE_MAP_NEGATIVE_Z; }
	private inline function get_MAX_CUBE_MAP_TEXTURE_SIZE ():Int { return this.MAX_CUBE_MAP_TEXTURE_SIZE; }
	private inline function get_TEXTURE0 ():Int { return this.TEXTURE0; }
	private inline function get_TEXTURE1 ():Int { return this.TEXTURE1; }
	private inline function get_TEXTURE2 ():Int { return this.TEXTURE2; }
	private inline function get_TEXTURE3 ():Int { return this.TEXTURE3; }
	private inline function get_TEXTURE4 ():Int { return this.TEXTURE4; }
	private inline function get_TEXTURE5 ():Int { return this.TEXTURE5; }
	private inline function get_TEXTURE6 ():Int { return this.TEXTURE6; }
	private inline function get_TEXTURE7 ():Int { return this.TEXTURE7; }
	private inline function get_TEXTURE8 ():Int { return this.TEXTURE8; }
	private inline function get_TEXTURE9 ():Int { return this.TEXTURE9; }
	private inline function get_TEXTURE10 ():Int { return this.TEXTURE10; }
	private inline function get_TEXTURE11 ():Int { return this.TEXTURE11; }
	private inline function get_TEXTURE12 ():Int { return this.TEXTURE12; }
	private inline function get_TEXTURE13 ():Int { return this.TEXTURE13; }
	private inline function get_TEXTURE14 ():Int { return this.TEXTURE14; }
	private inline function get_TEXTURE15 ():Int { return this.TEXTURE15; }
	private inline function get_TEXTURE16 ():Int { return this.TEXTURE16; }
	private inline function get_TEXTURE17 ():Int { return this.TEXTURE17; }
	private inline function get_TEXTURE18 ():Int { return this.TEXTURE18; }
	private inline function get_TEXTURE19 ():Int { return this.TEXTURE19; }
	private inline function get_TEXTURE20 ():Int { return this.TEXTURE20; }
	private inline function get_TEXTURE21 ():Int { return this.TEXTURE21; }
	private inline function get_TEXTURE22 ():Int { return this.TEXTURE22; }
	private inline function get_TEXTURE23 ():Int { return this.TEXTURE23; }
	private inline function get_TEXTURE24 ():Int { return this.TEXTURE24; }
	private inline function get_TEXTURE25 ():Int { return this.TEXTURE25; }
	private inline function get_TEXTURE26 ():Int { return this.TEXTURE26; }
	private inline function get_TEXTURE27 ():Int { return this.TEXTURE27; }
	private inline function get_TEXTURE28 ():Int { return this.TEXTURE28; }
	private inline function get_TEXTURE29 ():Int { return this.TEXTURE29; }
	private inline function get_TEXTURE30 ():Int { return this.TEXTURE30; }
	private inline function get_TEXTURE31 ():Int { return this.TEXTURE31; }
	private inline function get_ACTIVE_TEXTURE ():Int { return this.ACTIVE_TEXTURE; }
	private inline function get_REPEAT ():Int { return this.REPEAT; }
	private inline function get_CLAMP_TO_EDGE ():Int { return this.CLAMP_TO_EDGE; }
	private inline function get_MIRRORED_REPEAT ():Int { return this.MIRRORED_REPEAT; }
	private inline function get_FLOAT_VEC2 ():Int { return this.FLOAT_VEC2; }
	private inline function get_FLOAT_VEC3 ():Int { return this.FLOAT_VEC3; }
	private inline function get_FLOAT_VEC4 ():Int { return this.FLOAT_VEC4; }
	private inline function get_INT_VEC2 ():Int { return this.INT_VEC2; }
	private inline function get_INT_VEC3 ():Int { return this.INT_VEC3; }
	private inline function get_INT_VEC4 ():Int { return this.INT_VEC4; }
	private inline function get_BOOL ():Int { return this.BOOL; }
	private inline function get_BOOL_VEC2 ():Int { return this.BOOL_VEC2; }
	private inline function get_BOOL_VEC3 ():Int { return this.BOOL_VEC3; }
	private inline function get_BOOL_VEC4 ():Int { return this.BOOL_VEC4; }
	private inline function get_FLOAT_MAT2 ():Int { return this.FLOAT_MAT2; }
	private inline function get_FLOAT_MAT3 ():Int { return this.FLOAT_MAT3; }
	private inline function get_FLOAT_MAT4 ():Int { return this.FLOAT_MAT4; }
	private inline function get_SAMPLER_2D ():Int { return this.SAMPLER_2D; }
	private inline function get_SAMPLER_CUBE ():Int { return this.SAMPLER_CUBE; }
	private inline function get_VERTEX_ATTRIB_ARRAY_ENABLED ():Int { return this.VERTEX_ATTRIB_ARRAY_ENABLED; }
	private inline function get_VERTEX_ATTRIB_ARRAY_SIZE ():Int { return this.VERTEX_ATTRIB_ARRAY_SIZE; }
	private inline function get_VERTEX_ATTRIB_ARRAY_STRIDE ():Int { return this.VERTEX_ATTRIB_ARRAY_STRIDE; }
	private inline function get_VERTEX_ATTRIB_ARRAY_TYPE ():Int { return this.VERTEX_ATTRIB_ARRAY_TYPE; }
	private inline function get_VERTEX_ATTRIB_ARRAY_NORMALIZED ():Int { return this.VERTEX_ATTRIB_ARRAY_NORMALIZED; }
	private inline function get_VERTEX_ATTRIB_ARRAY_POINTER ():Int { return this.VERTEX_ATTRIB_ARRAY_POINTER; }
	private inline function get_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING ():Int { return this.VERTEX_ATTRIB_ARRAY_BUFFER_BINDING; }
	private inline function get_COMPILE_STATUS ():Int { return this.COMPILE_STATUS; }
	private inline function get_LOW_FLOAT ():Int { return this.LOW_FLOAT; }
	private inline function get_MEDIUM_FLOAT ():Int { return this.MEDIUM_FLOAT; }
	private inline function get_HIGH_FLOAT ():Int { return this.HIGH_FLOAT; }
	private inline function get_LOW_INT ():Int { return this.LOW_INT; }
	private inline function get_MEDIUM_INT ():Int { return this.MEDIUM_INT; }
	private inline function get_HIGH_INT ():Int { return this.HIGH_INT; }
	private inline function get_FRAMEBUFFER ():Int { return this.FRAMEBUFFER; }
	private inline function get_RENDERBUFFER ():Int { return this.RENDERBUFFER; }
	private inline function get_RGBA4 ():Int { return this.RGBA4; }
	private inline function get_RGB5_A1 ():Int { return this.RGB5_A1; }
	private inline function get_RGB565 ():Int { return this.RGB565; }
	private inline function get_DEPTH_COMPONENT16 ():Int { return this.DEPTH_COMPONENT16; }
	private inline function get_STENCIL_INDEX ():Int { return this.STENCIL_INDEX; }
	private inline function get_STENCIL_INDEX8 ():Int { return this.STENCIL_INDEX8; }
	private inline function get_DEPTH_STENCIL ():Int { return this.DEPTH_STENCIL; }
	private inline function get_RENDERBUFFER_WIDTH ():Int { return this.RENDERBUFFER_WIDTH; }
	private inline function get_RENDERBUFFER_HEIGHT ():Int { return this.RENDERBUFFER_HEIGHT; }
	private inline function get_RENDERBUFFER_INTERNAL_FORMAT ():Int { return this.RENDERBUFFER_INTERNAL_FORMAT; }
	private inline function get_RENDERBUFFER_RED_SIZE ():Int { return this.RENDERBUFFER_RED_SIZE; }
	private inline function get_RENDERBUFFER_GREEN_SIZE ():Int { return this.RENDERBUFFER_GREEN_SIZE; }
	private inline function get_RENDERBUFFER_BLUE_SIZE ():Int { return this.RENDERBUFFER_BLUE_SIZE; }
	private inline function get_RENDERBUFFER_ALPHA_SIZE ():Int { return this.RENDERBUFFER_ALPHA_SIZE; }
	private inline function get_RENDERBUFFER_DEPTH_SIZE ():Int { return this.RENDERBUFFER_DEPTH_SIZE; }
	private inline function get_RENDERBUFFER_STENCIL_SIZE ():Int { return this.RENDERBUFFER_STENCIL_SIZE; }
	private inline function get_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE ():Int { return this.FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE; }
	private inline function get_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME ():Int { return this.FRAMEBUFFER_ATTACHMENT_OBJECT_NAME; }
	private inline function get_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL ():Int { return this.FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL; }
	private inline function get_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE ():Int { return this.FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE; }
	private inline function get_COLOR_ATTACHMENT0 ():Int { return this.COLOR_ATTACHMENT0; }
	private inline function get_DEPTH_ATTACHMENT ():Int { return this.DEPTH_ATTACHMENT; }
	private inline function get_STENCIL_ATTACHMENT ():Int { return this.STENCIL_ATTACHMENT; }
	private inline function get_DEPTH_STENCIL_ATTACHMENT ():Int { return this.DEPTH_STENCIL_ATTACHMENT; }
	private inline function get_NONE ():Int { return this.NONE; }
	private inline function get_FRAMEBUFFER_COMPLETE ():Int { return this.FRAMEBUFFER_COMPLETE; }
	private inline function get_FRAMEBUFFER_INCOMPLETE_ATTACHMENT ():Int { return this.FRAMEBUFFER_INCOMPLETE_ATTACHMENT; }
	private inline function get_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT ():Int { return this.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT; }
	private inline function get_FRAMEBUFFER_INCOMPLETE_DIMENSIONS ():Int { return this.FRAMEBUFFER_INCOMPLETE_DIMENSIONS; }
	private inline function get_FRAMEBUFFER_UNSUPPORTED ():Int { return this.FRAMEBUFFER_UNSUPPORTED; }
	private inline function get_FRAMEBUFFER_BINDING ():Int { return this.FRAMEBUFFER_BINDING; }
	private inline function get_RENDERBUFFER_BINDING ():Int { return this.RENDERBUFFER_BINDING; }
	private inline function get_MAX_RENDERBUFFER_SIZE ():Int { return this.MAX_RENDERBUFFER_SIZE; }
	private inline function get_INVALID_FRAMEBUFFER_OPERATION ():Int { return this.INVALID_FRAMEBUFFER_OPERATION; }
	private inline function get_UNPACK_FLIP_Y_WEBGL ():Int { return this.UNPACK_FLIP_Y_WEBGL; }
	private inline function get_UNPACK_PREMULTIPLY_ALPHA_WEBGL ():Int { return this.UNPACK_PREMULTIPLY_ALPHA_WEBGL; }
	private inline function get_CONTEXT_LOST_WEBGL ():Int { return this.CONTEXT_LOST_WEBGL; }
	private inline function get_UNPACK_COLORSPACE_CONVERSION_WEBGL ():Int { return this.UNPACK_COLORSPACE_CONVERSION_WEBGL; }
	private inline function get_BROWSER_DEFAULT_WEBGL ():Int { return this.BROWSER_DEFAULT_WEBGL; }
	private inline function get_type ():RenderContextType { return this.type; }
	private inline function get_version ():Float { return this.version; }
	
	private inline function get_READ_BUFFER ():Int { return this.READ_BUFFER; }
	private inline function get_UNPACK_ROW_LENGTH ():Int { return this.UNPACK_ROW_LENGTH; }
	private inline function get_UNPACK_SKIP_ROWS ():Int { return this.UNPACK_SKIP_ROWS; }
	private inline function get_UNPACK_SKIP_PIXELS ():Int { return this.UNPACK_SKIP_PIXELS; }
	private inline function get_PACK_ROW_LENGTH ():Int { return this.PACK_ROW_LENGTH; }
	private inline function get_PACK_SKIP_ROWS ():Int { return this.PACK_SKIP_ROWS; }
	private inline function get_PACK_SKIP_PIXELS ():Int { return this.PACK_SKIP_PIXELS; }
	private inline function get_TEXTURE_BINDING_3D ():Int { return this.TEXTURE_BINDING_3D; }
	private inline function get_UNPACK_SKIP_IMAGES ():Int { return this.UNPACK_SKIP_IMAGES; }
	private inline function get_UNPACK_IMAGE_HEIGHT ():Int { return this.UNPACK_IMAGE_HEIGHT; }
	private inline function get_MAX_3D_TEXTURE_SIZE ():Int { return this.MAX_3D_TEXTURE_SIZE; }
	private inline function get_MAX_ELEMENTS_VERTICES ():Int { return this.MAX_ELEMENTS_VERTICES; }
	private inline function get_MAX_ELEMENTS_INDICES ():Int { return this.MAX_ELEMENTS_INDICES; }
	private inline function get_MAX_TEXTURE_LOD_BIAS ():Int { return this.MAX_TEXTURE_LOD_BIAS; }
	private inline function get_MAX_FRAGMENT_UNIFORM_COMPONENTS ():Int { return this.MAX_FRAGMENT_UNIFORM_COMPONENTS; }
	private inline function get_MAX_VERTEX_UNIFORM_COMPONENTS ():Int { return this.MAX_VERTEX_UNIFORM_COMPONENTS; }
	private inline function get_MAX_ARRAY_TEXTURE_LAYERS ():Int { return this.MAX_ARRAY_TEXTURE_LAYERS; }
	private inline function get_MIN_PROGRAM_TEXEL_OFFSET ():Int { return this.MIN_PROGRAM_TEXEL_OFFSET; }
	private inline function get_MAX_PROGRAM_TEXEL_OFFSET ():Int { return this.MAX_PROGRAM_TEXEL_OFFSET; }
	private inline function get_MAX_VARYING_COMPONENTS ():Int { return this.MAX_VARYING_COMPONENTS; }
	private inline function get_FRAGMENT_SHADER_DERIVATIVE_HINT ():Int { return this.FRAGMENT_SHADER_DERIVATIVE_HINT; }
	private inline function get_RASTERIZER_DISCARD ():Int { return this.RASTERIZER_DISCARD; }
	private inline function get_VERTEX_ARRAY_BINDING ():Int { return this.VERTEX_ARRAY_BINDING; }
	private inline function get_MAX_VERTEX_OUTPUT_COMPONENTS ():Int { return this.MAX_VERTEX_OUTPUT_COMPONENTS; }
	private inline function get_MAX_FRAGMENT_INPUT_COMPONENTS ():Int { return this.MAX_FRAGMENT_INPUT_COMPONENTS; }
	private inline function get_MAX_SERVER_WAIT_TIMEOUT ():Int { return this.MAX_SERVER_WAIT_TIMEOUT; }
	private inline function get_MAX_ELEMENT_INDEX ():Int { return this.MAX_ELEMENT_INDEX; }
	
	private inline function get_RED ():Int { return this.RED; }
	private inline function get_RGB8 ():Int { return this.RGB8; }
	private inline function get_RGBA8 ():Int { return this.RGBA8; }
	private inline function get_RGB10_A2 ():Int { return this.RGB10_A2; }
	private inline function get_TEXTURE_3D ():Int { return this.TEXTURE_3D; }
	private inline function get_TEXTURE_WRAP_R ():Int { return this.TEXTURE_WRAP_R; }
	private inline function get_TEXTURE_MIN_LOD ():Int { return this.TEXTURE_MIN_LOD; }
	private inline function get_TEXTURE_MAX_LOD ():Int { return this.TEXTURE_MAX_LOD; }
	private inline function get_TEXTURE_BASE_LEVEL ():Int { return this.TEXTURE_BASE_LEVEL; }
	private inline function get_TEXTURE_MAX_LEVEL ():Int { return this.TEXTURE_MAX_LEVEL; }
	private inline function get_TEXTURE_COMPARE_MODE ():Int { return this.TEXTURE_COMPARE_MODE; }
	private inline function get_TEXTURE_COMPARE_FUNC ():Int { return this.TEXTURE_COMPARE_FUNC; }
	private inline function get_SRGB ():Int { return this.SRGB; }
	private inline function get_SRGB8 ():Int { return this.SRGB8; }
	private inline function get_SRGB8_ALPHA8 ():Int { return this.SRGB8_ALPHA8; }
	private inline function get_COMPARE_REF_TO_TEXTURE ():Int { return this.COMPARE_REF_TO_TEXTURE; }
	private inline function get_RGBA32F ():Int { return this.RGBA32F; }
	private inline function get_RGB32F ():Int { return this.RGB32F; }
	private inline function get_RGBA16F ():Int { return this.RGBA16F; }
	private inline function get_RGB16F ():Int { return this.RGB16F; }
	private inline function get_TEXTURE_2D_ARRAY ():Int { return this.TEXTURE_2D_ARRAY; }
	private inline function get_TEXTURE_BINDING_2D_ARRAY ():Int { return this.TEXTURE_BINDING_2D_ARRAY; }
	private inline function get_R11F_G11F_B10F ():Int { return this.R11F_G11F_B10F; }
	private inline function get_RGB9_E5 ():Int { return this.RGB9_E5; }
	private inline function get_RGBA32UI ():Int { return this.RGBA32UI; }
	private inline function get_RGB32UI ():Int { return this.RGB32UI; }
	private inline function get_RGBA16UI ():Int { return this.RGBA16UI; }
	private inline function get_RGB16UI ():Int { return this.RGB16UI; }
	private inline function get_RGBA8UI ():Int { return this.RGBA8UI; }
	private inline function get_RGB8UI ():Int { return this.RGB8UI; }
	private inline function get_RGBA32I ():Int { return this.RGBA32I; }
	private inline function get_RGB32I ():Int { return this.RGB32I; }
	private inline function get_RGBA16I ():Int { return this.RGBA16I; }
	private inline function get_RGB16I ():Int { return this.RGB16I; }
	private inline function get_RGBA8I ():Int { return this.RGBA8I; }
	private inline function get_RGB8I ():Int { return this.RGB8I; }
	private inline function get_RED_INTEGER ():Int { return this.RED_INTEGER; }
	private inline function get_RGB_INTEGER ():Int { return this.RGB_INTEGER; }
	private inline function get_RGBA_INTEGER ():Int { return this.RGBA_INTEGER; }
	private inline function get_R8 ():Int { return this.R8; }
	private inline function get_RG8 ():Int { return this.RG8; }
	private inline function get_R16F ():Int { return this.R16F; }
	private inline function get_R32F ():Int { return this.R32F; }
	private inline function get_RG16F ():Int { return this.RG16F; }
	private inline function get_RG32F ():Int { return this.RG32F; }
	private inline function get_R8I ():Int { return this.R8I; }
	private inline function get_R8UI ():Int { return this.R8UI; }
	private inline function get_R16I ():Int { return this.R16I; }
	private inline function get_R16UI ():Int { return this.R16UI; }
	private inline function get_R32I ():Int { return this.R32I; }
	private inline function get_R32UI ():Int { return this.R32UI; }
	private inline function get_RG8I ():Int { return this.RG8I; }
	private inline function get_RG8UI ():Int { return this.RG8UI; }
	private inline function get_RG16I ():Int { return this.RG16I; }
	private inline function get_RG16UI ():Int { return this.RG16UI; }
	private inline function get_RG32I ():Int { return this.RG32I; }
	private inline function get_RG32UI ():Int { return this.RG32UI; }
	private inline function get_R8_SNORM ():Int { return this.R8_SNORM; }
	private inline function get_RG8_SNORM ():Int { return this.RG8_SNORM; }
	private inline function get_RGB8_SNORM ():Int { return this.RGB8_SNORM; }
	private inline function get_RGBA8_SNORM ():Int { return this.RGBA8_SNORM; }
	private inline function get_RGB10_A2UI ():Int { return this.RGB10_A2UI; }
	private inline function get_TEXTURE_IMMUTABLE_FORMAT ():Int { return this.TEXTURE_IMMUTABLE_FORMAT; }
	private inline function get_TEXTURE_IMMUTABLE_LEVELS ():Int { return this.TEXTURE_IMMUTABLE_LEVELS; }
	
	private inline function get_UNSIGNED_INT_2_10_10_10_REV ():Int { return this.UNSIGNED_INT_2_10_10_10_REV; }
	private inline function get_UNSIGNED_INT_10F_11F_11F_REV ():Int { return this.UNSIGNED_INT_10F_11F_11F_REV; }
	private inline function get_UNSIGNED_INT_5_9_9_9_REV ():Int { return this.UNSIGNED_INT_5_9_9_9_REV; }
	private inline function get_FLOAT_32_UNSIGNED_INT_24_8_REV ():Int { return this.FLOAT_32_UNSIGNED_INT_24_8_REV; }
	private inline function get_UNSIGNED_INT_24_8 ():Int { return this.UNSIGNED_INT_24_8; }
	private inline function get_HALF_FLOAT ():Int { return this.HALF_FLOAT; }
	private inline function get_RG ():Int { return this.RG; }
	private inline function get_RG_INTEGER ():Int { return this.RG_INTEGER; }
	private inline function get_INT_2_10_10_10_REV ():Int { return this.INT_2_10_10_10_REV; }
	
	private inline function get_CURRENT_QUERY ():Int { return this.CURRENT_QUERY; }
	private inline function get_QUERY_RESULT ():Int { return this.QUERY_RESULT; }
	private inline function get_QUERY_RESULT_AVAILABLE ():Int { return this.QUERY_RESULT_AVAILABLE; }
	private inline function get_ANY_SAMPLES_PASSED ():Int { return this.ANY_SAMPLES_PASSED; }
	private inline function get_ANY_SAMPLES_PASSED_CONSERVATIVE ():Int { return this.ANY_SAMPLES_PASSED_CONSERVATIVE; }
	
	private inline function get_MAX_DRAW_BUFFERS ():Int { return this.MAX_DRAW_BUFFERS; }
	private inline function get_DRAW_BUFFER0 ():Int { return this.DRAW_BUFFER0; }
	private inline function get_DRAW_BUFFER1 ():Int { return this.DRAW_BUFFER1; }
	private inline function get_DRAW_BUFFER2 ():Int { return this.DRAW_BUFFER2; }
	private inline function get_DRAW_BUFFER3 ():Int { return this.DRAW_BUFFER3; }
	private inline function get_DRAW_BUFFER4 ():Int { return this.DRAW_BUFFER4; }
	private inline function get_DRAW_BUFFER5 ():Int { return this.DRAW_BUFFER5; }
	private inline function get_DRAW_BUFFER6 ():Int { return this.DRAW_BUFFER6; }
	private inline function get_DRAW_BUFFER7 ():Int { return this.DRAW_BUFFER7; }
	private inline function get_DRAW_BUFFER8 ():Int { return this.DRAW_BUFFER8; }
	private inline function get_DRAW_BUFFER9 ():Int { return this.DRAW_BUFFER9; }
	private inline function get_DRAW_BUFFER10 ():Int { return this.DRAW_BUFFER10; }
	private inline function get_DRAW_BUFFER11 ():Int { return this.DRAW_BUFFER11; }
	private inline function get_DRAW_BUFFER12 ():Int { return this.DRAW_BUFFER12; }
	private inline function get_DRAW_BUFFER13 ():Int { return this.DRAW_BUFFER13; }
	private inline function get_DRAW_BUFFER14 ():Int { return this.DRAW_BUFFER14; }
	private inline function get_DRAW_BUFFER15 ():Int { return this.DRAW_BUFFER15; }
	private inline function get_MAX_COLOR_ATTACHMENTS ():Int { return this.MAX_COLOR_ATTACHMENTS; }
	private inline function get_COLOR_ATTACHMENT1 ():Int { return this.COLOR_ATTACHMENT1; }
	private inline function get_COLOR_ATTACHMENT2 ():Int { return this.COLOR_ATTACHMENT2; }
	private inline function get_COLOR_ATTACHMENT3 ():Int { return this.COLOR_ATTACHMENT3; }
	private inline function get_COLOR_ATTACHMENT4 ():Int { return this.COLOR_ATTACHMENT4; }
	private inline function get_COLOR_ATTACHMENT5 ():Int { return this.COLOR_ATTACHMENT5; }
	private inline function get_COLOR_ATTACHMENT6 ():Int { return this.COLOR_ATTACHMENT6; }
	private inline function get_COLOR_ATTACHMENT7 ():Int { return this.COLOR_ATTACHMENT7; }
	private inline function get_COLOR_ATTACHMENT8 ():Int { return this.COLOR_ATTACHMENT8; }
	private inline function get_COLOR_ATTACHMENT9 ():Int { return this.COLOR_ATTACHMENT9; }
	private inline function get_COLOR_ATTACHMENT10 ():Int { return this.COLOR_ATTACHMENT10; }
	private inline function get_COLOR_ATTACHMENT11 ():Int { return this.COLOR_ATTACHMENT11; }
	private inline function get_COLOR_ATTACHMENT12 ():Int { return this.COLOR_ATTACHMENT12; }
	private inline function get_COLOR_ATTACHMENT13 ():Int { return this.COLOR_ATTACHMENT13; }
	private inline function get_COLOR_ATTACHMENT14 ():Int { return this.COLOR_ATTACHMENT14; }
	private inline function get_COLOR_ATTACHMENT15 ():Int { return this.COLOR_ATTACHMENT15; }
	
	private inline function get_SAMPLER_3D ():Int { return this.SAMPLER_3D; }
	private inline function get_SAMPLER_2D_SHADOW ():Int { return this.SAMPLER_2D_SHADOW; }
	private inline function get_SAMPLER_2D_ARRAY ():Int { return this.SAMPLER_2D_ARRAY; }
	private inline function get_SAMPLER_2D_ARRAY_SHADOW ():Int { return this.SAMPLER_2D_ARRAY_SHADOW; }
	private inline function get_SAMPLER_CUBE_SHADOW ():Int { return this.SAMPLER_CUBE_SHADOW; }
	private inline function get_INT_SAMPLER_2D ():Int { return this.INT_SAMPLER_2D; }
	private inline function get_INT_SAMPLER_3D ():Int { return this.INT_SAMPLER_3D; }
	private inline function get_INT_SAMPLER_CUBE ():Int { return this.INT_SAMPLER_CUBE; }
	private inline function get_INT_SAMPLER_2D_ARRAY ():Int { return this.INT_SAMPLER_2D_ARRAY; }
	private inline function get_UNSIGNED_INT_SAMPLER_2D ():Int { return this.UNSIGNED_INT_SAMPLER_2D; }
	private inline function get_UNSIGNED_INT_SAMPLER_3D ():Int { return this.UNSIGNED_INT_SAMPLER_3D; }
	private inline function get_UNSIGNED_INT_SAMPLER_CUBE ():Int { return this.UNSIGNED_INT_SAMPLER_CUBE; }
	private inline function get_UNSIGNED_INT_SAMPLER_2D_ARRAY ():Int { return this.UNSIGNED_INT_SAMPLER_2D_ARRAY; }
	private inline function get_MAX_SAMPLES ():Int { return this.MAX_SAMPLES; }
	private inline function get_SAMPLER_BINDING ():Int { return this.SAMPLER_BINDING; }
	
	private inline function get_PIXEL_PACK_BUFFER ():Int { return this.PIXEL_PACK_BUFFER; }
	private inline function get_PIXEL_UNPACK_BUFFER ():Int { return this.PIXEL_UNPACK_BUFFER; }
	private inline function get_PIXEL_PACK_BUFFER_BINDING ():Int { return this.PIXEL_PACK_BUFFER_BINDING; }
	private inline function get_PIXEL_UNPACK_BUFFER_BINDING ():Int { return this.PIXEL_UNPACK_BUFFER_BINDING; }
	private inline function get_COPY_READ_BUFFER ():Int { return this.COPY_READ_BUFFER; }
	private inline function get_COPY_WRITE_BUFFER ():Int { return this.COPY_WRITE_BUFFER; }
	private inline function get_COPY_READ_BUFFER_BINDING ():Int { return this.COPY_READ_BUFFER_BINDING; }
	private inline function get_COPY_WRITE_BUFFER_BINDING ():Int { return this.COPY_WRITE_BUFFER_BINDING; }
	
	private inline function get_FLOAT_MAT2x3 ():Int { return this.FLOAT_MAT2x3; }
	private inline function get_FLOAT_MAT2x4 ():Int { return this.FLOAT_MAT2x4; }
	private inline function get_FLOAT_MAT3x2 ():Int { return this.FLOAT_MAT3x2; }
	private inline function get_FLOAT_MAT3x4 ():Int { return this.FLOAT_MAT3x4; }
	private inline function get_FLOAT_MAT4x2 ():Int { return this.FLOAT_MAT4x2; }
	private inline function get_FLOAT_MAT4x3 ():Int { return this.FLOAT_MAT4x3; }
	private inline function get_UNSIGNED_INT_VEC2 ():Int { return this.UNSIGNED_INT_VEC2; }
	private inline function get_UNSIGNED_INT_VEC3 ():Int { return this.UNSIGNED_INT_VEC3; }
	private inline function get_UNSIGNED_INT_VEC4 ():Int { return this.UNSIGNED_INT_VEC4; }
	private inline function get_UNSIGNED_NORMALIZED ():Int { return this.UNSIGNED_NORMALIZED; }
	private inline function get_SIGNED_NORMALIZED ():Int { return this.SIGNED_NORMALIZED; }
	
	private inline function get_VERTEX_ATTRIB_ARRAY_INTEGER ():Int { return this.VERTEX_ATTRIB_ARRAY_INTEGER; }
	private inline function get_VERTEX_ATTRIB_ARRAY_DIVISOR ():Int { return this.VERTEX_ATTRIB_ARRAY_DIVISOR; }
	
	private inline function get_TRANSFORM_FEEDBACK_BUFFER_MODE ():Int { return this.TRANSFORM_FEEDBACK_BUFFER_MODE; }
	private inline function get_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS ():Int { return this.MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS; }
	private inline function get_TRANSFORM_FEEDBACK_VARYINGS ():Int { return this.TRANSFORM_FEEDBACK_VARYINGS; }
	private inline function get_TRANSFORM_FEEDBACK_BUFFER_START ():Int { return this.TRANSFORM_FEEDBACK_BUFFER_START; }
	private inline function get_TRANSFORM_FEEDBACK_BUFFER_SIZE ():Int { return this.TRANSFORM_FEEDBACK_BUFFER_SIZE; }
	private inline function get_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN ():Int { return this.TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN; }
	private inline function get_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS ():Int { return this.MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS; }
	private inline function get_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS ():Int { return this.MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS; }
	private inline function get_INTERLEAVED_ATTRIBS ():Int { return this.INTERLEAVED_ATTRIBS; }
	private inline function get_SEPARATE_ATTRIBS ():Int { return this.SEPARATE_ATTRIBS; }
	private inline function get_TRANSFORM_FEEDBACK_BUFFER ():Int { return this.TRANSFORM_FEEDBACK_BUFFER; }
	private inline function get_TRANSFORM_FEEDBACK_BUFFER_BINDING ():Int { return this.TRANSFORM_FEEDBACK_BUFFER_BINDING; }
	private inline function get_TRANSFORM_FEEDBACK ():Int { return this.TRANSFORM_FEEDBACK; }
	private inline function get_TRANSFORM_FEEDBACK_PAUSED ():Int { return this.TRANSFORM_FEEDBACK_PAUSED; }
	private inline function get_TRANSFORM_FEEDBACK_ACTIVE ():Int { return this.TRANSFORM_FEEDBACK_ACTIVE; }
	private inline function get_TRANSFORM_FEEDBACK_BINDING ():Int { return this.TRANSFORM_FEEDBACK_BINDING; }
	
	private inline function get_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING ():Int { return this.FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING; }
	private inline function get_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE ():Int { return this.FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE; }
	private inline function get_FRAMEBUFFER_ATTACHMENT_RED_SIZE ():Int { return this.FRAMEBUFFER_ATTACHMENT_RED_SIZE; }
	private inline function get_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE ():Int { return this.FRAMEBUFFER_ATTACHMENT_GREEN_SIZE; }
	private inline function get_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE ():Int { return this.FRAMEBUFFER_ATTACHMENT_BLUE_SIZE; }
	private inline function get_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE ():Int { return this.FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE; }
	private inline function get_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE ():Int { return this.FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE; }
	private inline function get_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE ():Int { return this.FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE; }
	private inline function get_FRAMEBUFFER_DEFAULT ():Int { return this.FRAMEBUFFER_DEFAULT; }
	private inline function get_DEPTH24_STENCIL8 ():Int { return this.DEPTH24_STENCIL8; }
	private inline function get_DRAW_FRAMEBUFFER_BINDING ():Int { return this.DRAW_FRAMEBUFFER_BINDING; }
	private inline function get_READ_FRAMEBUFFER ():Int { return this.READ_FRAMEBUFFER; }
	private inline function get_DRAW_FRAMEBUFFER ():Int { return this.DRAW_FRAMEBUFFER; }
	private inline function get_READ_FRAMEBUFFER_BINDING ():Int { return this.READ_FRAMEBUFFER_BINDING; }
	private inline function get_RENDERBUFFER_SAMPLES ():Int { return this.RENDERBUFFER_SAMPLES; }
	private inline function get_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER ():Int { return this.FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER; }
	private inline function get_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE ():Int { return this.FRAMEBUFFER_INCOMPLETE_MULTISAMPLE; }
	
	private inline function get_UNIFORM_BUFFER ():Int { return this.UNIFORM_BUFFER; }
	private inline function get_UNIFORM_BUFFER_BINDING ():Int { return this.UNIFORM_BUFFER_BINDING; }
	private inline function get_UNIFORM_BUFFER_START ():Int { return this.UNIFORM_BUFFER_START; }
	private inline function get_UNIFORM_BUFFER_SIZE ():Int { return this.UNIFORM_BUFFER_SIZE; }
	private inline function get_MAX_VERTEX_UNIFORM_BLOCKS ():Int { return this.MAX_VERTEX_UNIFORM_BLOCKS; }
	private inline function get_MAX_FRAGMENT_UNIFORM_BLOCKS ():Int { return this.MAX_FRAGMENT_UNIFORM_BLOCKS; }
	private inline function get_MAX_COMBINED_UNIFORM_BLOCKS ():Int { return this.MAX_COMBINED_UNIFORM_BLOCKS; }
	private inline function get_MAX_UNIFORM_BUFFER_BINDINGS ():Int { return this.MAX_UNIFORM_BUFFER_BINDINGS; }
	private inline function get_MAX_UNIFORM_BLOCK_SIZE ():Int { return this.MAX_UNIFORM_BLOCK_SIZE; }
	private inline function get_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS ():Int { return this.MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS; }
	private inline function get_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS ():Int { return this.MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS; }
	private inline function get_UNIFORM_BUFFER_OFFSET_ALIGNMENT ():Int { return this.UNIFORM_BUFFER_OFFSET_ALIGNMENT; }
	private inline function get_ACTIVE_UNIFORM_BLOCKS ():Int { return this.ACTIVE_UNIFORM_BLOCKS; }
	private inline function get_UNIFORM_TYPE ():Int { return this.UNIFORM_TYPE; }
	private inline function get_UNIFORM_SIZE ():Int { return this.UNIFORM_SIZE; }
	private inline function get_UNIFORM_BLOCK_INDEX ():Int { return this.UNIFORM_BLOCK_INDEX; }
	private inline function get_UNIFORM_OFFSET ():Int { return this.UNIFORM_OFFSET; }
	private inline function get_UNIFORM_ARRAY_STRIDE ():Int { return this.UNIFORM_ARRAY_STRIDE; }
	private inline function get_UNIFORM_MATRIX_STRIDE ():Int { return this.UNIFORM_MATRIX_STRIDE; }
	private inline function get_UNIFORM_IS_ROW_MAJOR ():Int { return this.UNIFORM_IS_ROW_MAJOR; }
	private inline function get_UNIFORM_BLOCK_BINDING ():Int { return this.UNIFORM_BLOCK_BINDING; }
	private inline function get_UNIFORM_BLOCK_DATA_SIZE ():Int { return this.UNIFORM_BLOCK_DATA_SIZE; }
	private inline function get_UNIFORM_BLOCK_ACTIVE_UNIFORMS ():Int { return this.UNIFORM_BLOCK_ACTIVE_UNIFORMS; }
	private inline function get_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES ():Int { return this.UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES; }
	private inline function get_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER ():Int { return this.UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER; }
	private inline function get_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER ():Int { return this.UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER; }
	
	private inline function get_OBJECT_TYPE ():Int { return this.OBJECT_TYPE; }
	private inline function get_SYNC_CONDITION ():Int { return this.SYNC_CONDITION; }
	private inline function get_SYNC_STATUS ():Int { return this.SYNC_STATUS; }
	private inline function get_SYNC_FLAGS ():Int { return this.SYNC_FLAGS; }
	private inline function get_SYNC_FENCE ():Int { return this.SYNC_FENCE; }
	private inline function get_SYNC_GPU_COMMANDS_COMPLETE ():Int { return this.SYNC_GPU_COMMANDS_COMPLETE; }
	private inline function get_UNSIGNALED ():Int { return this.UNSIGNALED; }
	private inline function get_SIGNALED ():Int { return this.SIGNALED; }
	private inline function get_ALREADY_SIGNALED ():Int { return this.ALREADY_SIGNALED; }
	private inline function get_TIMEOUT_EXPIRED ():Int { return this.TIMEOUT_EXPIRED; }
	private inline function get_CONDITION_SATISFIED ():Int { return this.CONDITION_SATISFIED; }
	private inline function get_WAIT_FAILED ():Int { return this.WAIT_FAILED; }
	private inline function get_SYNC_FLUSH_COMMANDS_BIT ():Int { return this.SYNC_FLUSH_COMMANDS_BIT; }
	
	private inline function get_COLOR ():Int { return this.COLOR; }
	private inline function get_DEPTH ():Int { return this.DEPTH; }
	private inline function get_STENCIL ():Int { return this.STENCIL; }
	private inline function get_MIN ():Int { return this.MIN; }
	private inline function get_MAX ():Int { return this.MAX; }
	private inline function get_DEPTH_COMPONENT24 ():Int { return this.DEPTH_COMPONENT24; }
	private inline function get_STREAM_READ ():Int { return this.STREAM_READ; }
	private inline function get_STREAM_COPY ():Int { return this.STREAM_COPY; }
	private inline function get_STATIC_READ ():Int { return this.STATIC_READ; }
	private inline function get_STATIC_COPY ():Int { return this.STATIC_COPY; }
	private inline function get_DYNAMIC_READ ():Int { return this.DYNAMIC_READ; }
	private inline function get_DYNAMIC_COPY ():Int { return this.DYNAMIC_COPY; }
	private inline function get_DEPTH_COMPONENT32F ():Int { return this.DEPTH_COMPONENT32F; }
	private inline function get_DEPTH32F_STENCIL8 ():Int { return this.DEPTH32F_STENCIL8; }
	private inline function get_INVALID_INDEX ():Int { return this.INVALID_INDEX; }
	private inline function get_TIMEOUT_IGNORED ():Int { return this.TIMEOUT_IGNORED; }
	private inline function get_MAX_CLIENT_WAIT_TIMEOUT_WEBGL ():Int { return this.MAX_CLIENT_WAIT_TIMEOUT_WEBGL; }
	
	
	public inline function activeTexture (texture:Int):Void {
		
		this.activeTexture (texture);
		
	}
	
	
	public inline function attachShader (program:GLProgram, shader:GLShader):Void {
		
		this.attachShader (program, shader);
		
	}
	
	
	public inline function beginQuery (target:Int, query:GLQuery):Void {
		
		this.beginQuery (target, query);
		
	}
	
	
	public inline function beginTransformFeedback (primitiveNode:Int):Void {
		
		this.beginTransformFeedback (primitiveNode);
		
	}
	
	
	public inline function bindAttribLocation (program:GLProgram, index:Int, name:String):Void {
		
		this.bindAttribLocation (program, index, name);
		
	}
	
	
	public inline function bindBuffer (target:Int, buffer:GLBuffer):Void {
		
		this.bindBuffer (target, buffer);
		
	}
	
	
	public inline function bindBufferBase (target:Int, index:Int, buffer:GLBuffer):Void {
		
		this.bindBufferBase (target, index, buffer);
		
	}
	
	
	public inline function bindBufferRange (target:Int, index:Int, buffer:GLBuffer, offset:DataPointer, size:Int):Void {
		
		this.bindBufferRange (target, index, buffer, offset, size);
		
	}
	
	
	public inline function bindFramebuffer (target:Int, framebuffer:GLFramebuffer):Void {
		
		this.bindFramebuffer (target, framebuffer);
		
	}
	
	
	public inline function bindRenderbuffer (target:Int, renderbuffer:GLRenderbuffer):Void {
		
		this.bindRenderbuffer (target, renderbuffer);
		
	}
	
	
	public inline function bindSampler (unit:Int, sampler:GLSampler):Void {
		
		this.bindSampler (unit, sampler);
		
	}
	
	
	public inline function bindTexture (target:Int, texture:GLTexture):Void {
		
		this.bindTexture (target, texture);
		
	}
	
	
	public inline function bindTransformFeedback (target:Int, transformFeedback:GLTransformFeedback):Void {
		
		this.bindTransformFeedback (target, transformFeedback);
		
	}
	
	
	public inline function bindVertexArray (vertexArray:GLVertexArrayObject):Void {
		
		this.bindVertexArray (vertexArray);
		
	}
	
	
	public inline function blendColor (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		this.blendColor (red, green, blue, alpha);
		
	}
	
	
	public inline function blendEquation (mode:Int):Void {
		
		this.blendEquation (mode);
		
	}
	
	
	public inline function blendEquationSeparate (modeRGB:Int, modeAlpha:Int):Void {
		
		this.blendEquationSeparate (modeRGB, modeAlpha);
		
	}
	
	
	public inline function blendFunc (sfactor:Int, dfactor:Int):Void {
		
		this.blendFunc (sfactor, dfactor);
		
	}
	
	
	public inline function blendFuncSeparate (srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int):Void {
		
		this.blendFuncSeparate (srcRGB, dstRGB, srcAlpha, dstAlpha);
		
	}
	
	
	public inline function blitFramebuffer (srcX0:Int, srcY0:Int, srcX1:Int, srcY1:Int, dstX0:Int, dstY0:Int, dstX1:Int, dstY1:Int, mask:Int, filter:Int):Void {
		
		this.blitFramebuffer (srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
		
	}
	
	
	#if (!js || !html5 || display)
	public function bufferData (target:Int, srcData:ArrayBufferView, usage:Int, srcOffset:Int = 0, length:Int = 0):Void {
		
		var size = (srcData != null) ? srcData.byteLength : 0;
		__tempPointer.set (srcData, srcOffset);
		this.bufferData (target, size, __tempPointer, usage);
		
	}
	#else
	public inline function bufferData (target:Int, srcData:Dynamic, usage:Int, ?srcOffset:Int, ?length:Int):Void {
		
		this.bufferDataWEBGL (target, srcData, usage, srcOffset, length);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public inline function bufferSubData (target:Int, offset:Int, srcData:ArrayBufferView, srcOffset:Int = 0, ?length:Int):Void {
		
		var size = (length != null) ? length : (srcData != null) ? srcData.byteLength : 0;
		__tempPointer.set (srcData, srcOffset);
		this.bufferSubData (target, offset, size, __tempPointer);
		
	}
	#else
	public inline function bufferSubData (target:Int, offset:Int, srcData:Dynamic, ?srcOffset:Int, ?length:Int):Void {
		
		this.bufferSubDataWEBGL (target, offset, srcData, srcOffset, length);
		
	}
	#end
	
	
	public inline function checkFramebufferStatus (target:Int):Int {
		
		return this.checkFramebufferStatus (target);
		
	}
	
	
	public inline function clear (mask:Int):Void {
		
		this.clear (mask);
		
	}
	
	
	public inline function clearBufferfi (buffer:Int, drawbuffer:Int, depth:Float, stencil:Int):Void {
		
		this.clearBufferfi (buffer, drawbuffer, depth, stencil);
		
	}
	
	
	#if (!js || !html5 || display)
	public function clearBufferfv (buffer:Int, drawbuffer:Int, values:ArrayBufferView, srcOffset:Int = 0):Void {
		
		__tempPointer.set (values, srcOffset);
		this.clearBufferfv (buffer, drawbuffer, __tempPointer);
		
	}
	#else
	public inline function clearBufferfv (buffer:Int, drawbuffer:Int, values:Dynamic, ?srcOffset:Int):Void {
		
		this.clearBufferfvWEBGL (buffer, drawbuffer, values, srcOffset);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public function clearBufferiv (buffer:Int, drawbuffer:Int, values:ArrayBufferView, ?srcOffset:Int):Void {
		
		__tempPointer.set (values, srcOffset);
		this.clearBufferiv (buffer, drawbuffer, __tempPointer);
		
	}
	#else
	public inline function clearBufferiv (buffer:Int, drawbuffer:Int, values:Dynamic, ?srcOffset:Int):Void {
		
		this.clearBufferivWEBGL (buffer, drawbuffer, values, srcOffset);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public function clearBufferuiv (buffer:Int, drawbuffer:Int, values:ArrayBufferView, ?srcOffset:Int):Void {
		
		__tempPointer.set (values, srcOffset);
		this.clearBufferuiv (buffer, drawbuffer, __tempPointer);
		
	}
	#else
	public inline function clearBufferuiv (buffer:Int, drawbuffer:Int, values:Dynamic, ?srcOffset:Int):Void {
		
		this.clearBufferuivWEBGL (buffer, drawbuffer, values, srcOffset);
		
	}
	#end
	
	
	public inline function clearColor (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		this.clearColor (red, green, blue, alpha);
		
	}
	
	
	public inline function clearDepth (depth:Float):Void {
		
		this.clearDepthf (depth);
		
	}
	
	
	public inline function clearStencil (s:Int):Void {
		
		this.clearStencil (s);
		
	}
	
	
	#if (!js || !html5 || display)
	public inline function clientWaitSync (sync:GLSync, flags:Int, timeout:Int64):Int {
		
		return this.clientWaitSync (sync, flags, timeout);
		
	}
	#else
	public inline function clientWaitSync (sync:GLSync, flags:Int, timeout:Dynamic):Int {
		
		return this.clientWaitSync (sync, flags, timeout);
		
	}
	#end
	
	
	public inline function colorMask (red:Bool, green:Bool, blue:Bool, alpha:Bool):Void {
		
		this.colorMask (red, green, blue, alpha);
		
	}
	
	
	public inline function compileShader (shader:GLShader):Void {
		
		this.compileShader (shader);
		
	}
	
	
	#if (!js || !html5 || display)
	public function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, srcData:ArrayBufferView, srcOffset:Int = 0, ?srcLengthOverride:Int):Void {
		
		var imageSize = (srcLengthOverride != null) ? srcLengthOverride : (srcData != null) ? srcData.byteLength : 0;
		__tempPointer.set (srcData, srcOffset);
		this.compressedTexImage2D (target, level, internalformat, width, height, border, imageSize, __tempPointer);
		
	}
	#else
	//public function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, offset:Int):Void {
	//public function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, srcData:ArrayBufferView, srcOffset:Int = 0, srcLengthOverride:Int = 0):Void {
	public inline function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, srcData:Dynamic, ?srcOffset:Int, ?srcLengthOverride:Int):Void {
		
		this.compressedTexImage2DWEBGL (target, level, internalformat, width, height, border, srcData, srcOffset, srcLengthOverride);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public function compressedTexImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, srcData:ArrayBufferView, srcOffset:Int = 0, ?srcLengthOverride:Int):Void {
		
		var imageSize = (srcLengthOverride != null) ? srcLengthOverride : (srcData != null) ? srcData.byteLength : 0;
		__tempPointer.set (srcData, srcOffset);
		this.compressedTexImage3D (target, level, internalformat, width, height, depth, border, imageSize, __tempPointer);
		
	}
	#else
	//public function compressedTexImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, offset:DataPointer):Void {
	//public function compressedTexImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, srcData:ArrayBufferView, ?srcOffset:Int, ?srcLengthOverride:Int):Void {
	public inline function compressedTexImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, srcData:Dynamic, ?srcOffset:Int, ?srcLengthOverride:Int):Void {
		
		this.compressedTexImage3DWEBGL (target, level, internalformat, width, height, depth, border, srcData, srcOffset, srcLengthOverride);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public inline function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, srcData:ArrayBufferView, srcOffset:Int = 0, ?srcLengthOverride:Int):Void {
		
		var imageSize = (srcLengthOverride != null) ? srcLengthOverride : (srcData != null) ? srcData.byteLength : 0;
		__tempPointer.set (srcData, srcOffset);
		this.compressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, imageSize, __tempPointer);
		
	}
	#else
	//public function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, offset:Int):Void {
	//public function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, srcData:ArrayBufferView, srcOffset:Int = 0, srcLengthOverride:Int = 0):Void {
	public inline function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, srcData:Dynamic, ?srcOffset:Int, ?srcLengthOverride:Int):Void {
		
		this.compressedTexSubImage2DWEBGL (target, level, xoffset, yoffset, width, height, format, srcData, srcOffset, srcLengthOverride);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public inline function compressedTexSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, srcData:ArrayBufferView, srcOffset:Int = 0, ?srcLengthOverride:Int):Void {
		
		var imageSize = (srcLengthOverride != null) ? srcLengthOverride : (srcData != null) ? srcData.byteLength : 0;
		__tempPointer.set (srcData, srcOffset);
		this.compressedTexSubImage3D (target, level, xoffset, yoffset, zoffset, width, height, depth, format, imageSize, __tempPointer);
		
	}
	#else
	//public function compressedTexSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, offset:DataPointer):Void {
	//public function compressedTexSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, srcData:ArrayBufferView, ?srcOffset:Int, ?srcLengthOverride:Int):Void {
	public inline function compressedTexSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, srcData:Dynamic, ?srcOffset:Int, ?srcLengthOverride:Int):Void {
		
		this.compressedTexSubImage3DWEBGL (target, level, xoffset, yoffset, zoffset, width, height, depth, format, srcData, srcOffset, srcLengthOverride);
		
	}
	#end
	
	
	public inline function copyBufferSubData (readTarget:Int, writeTarget:Int, readOffset:DataPointer, writeOffset:DataPointer, size:Int):Void {
		
		this.copyBufferSubData (readTarget, writeTarget, readOffset, writeOffset, size);
		
	}
	
	
	public inline function copyTexImage2D (target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void {
		
		this.copyTexImage2D (target, level, internalformat, x, y, width, height, border);
		
	}
	
	
	public inline function copyTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {
		
		this.copyTexSubImage2D (target, level, xoffset, yoffset, x, y, width, height);
		
	}
	
	
	public inline function copyTexSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {
		
		this.copyTexSubImage3D (target, level, xoffset, yoffset, zoffset, x, y, width, height);
		
	}
	
	
	public inline function createBuffer ():GLBuffer {
		
		return this.createBuffer ();
		
	}
	
	
	public inline function createFramebuffer ():GLFramebuffer {
		
		return this.createFramebuffer ();
		
	}
	
	
	public inline function createProgram ():GLProgram {
		
		return this.createProgram ();
		
	}
	
	
	public inline function createQuery ():GLQuery {
		
		return this.createQuery ();
		
	}
	
	
	public inline function createRenderbuffer ():GLRenderbuffer {
		
		return this.createRenderbuffer ();
		
	}
	
	
	public inline function createSampler ():GLSampler {
		
		return this.createSampler ();
		
	}
	
	
	public inline function createShader (type:Int):GLShader {
		
		return this.createShader (type);
		
	}
	
	
	public inline function createTexture ():GLTexture {
		
		return this.createTexture ();
		
	}
	
	
	public inline function createTransformFeedback ():GLTransformFeedback {
		
		return this.createTransformFeedback ();
		
	}
	
	
	public inline function createVertexArray ():GLVertexArrayObject {
		
		return this.createVertexArray ();
		
	}
	
	
	public inline function cullFace (mode:Int):Void {
		
		this.cullFace (mode);
		
	}
	
	
	public inline function deleteBuffer (buffer:GLBuffer):Void {
		
		this.deleteBuffer (buffer);
		
	}
	
	
	public inline function deleteFramebuffer (framebuffer:GLFramebuffer):Void {
		
		this.deleteFramebuffer (framebuffer);
		
	}
	
	
	public inline function deleteProgram (program:GLProgram):Void {
		
		this.deleteProgram (program);
		
	}
	
	
	public inline function deleteQuery (query:GLQuery):Void {
		
		this.deleteQuery (query);
		
	}
	
	
	public inline function deleteRenderbuffer (renderbuffer:GLRenderbuffer):Void {
		
		this.deleteRenderbuffer (renderbuffer);
		
	}
	
	
	public inline function deleteSampler (sampler:GLSampler):Void {
		
		this.deleteSampler (sampler);
		
	}
	
	
	public inline function deleteShader (shader:GLShader):Void {
		
		this.deleteShader (shader);
		
	}
	
	
	public inline function deleteSync (sync:GLSync):Void {
		
		this.deleteSync (sync);
		
	}
	
	
	public inline function deleteTexture (texture:GLTexture):Void {
		
		this.deleteTexture (texture);
		
	}
	
	
	public inline function deleteTransformFeedback (transformFeedback:GLTransformFeedback):Void {
		
		this.deleteTransformFeedback (transformFeedback);
		
	}
	
	
	public inline function deleteVertexArray (vertexArray:GLVertexArrayObject):Void {
		
		this.deleteVertexArray (vertexArray);
		
	}
	
	
	public inline function depthFunc (func:Int):Void {
		
		this.depthFunc (func);
		
	}
	
	
	public inline function depthMask (flag:Bool):Void {
		
		this.depthMask (flag);
		
	}
	
	
	public inline function depthRange (zNear:Float, zFar:Float):Void {
		
		this.depthRangef (zNear, zFar);
		
	}
	
	
	public inline function detachShader (program:GLProgram, shader:GLShader):Void {
		
		this.detachShader (program, shader);
		
	}
	
	
	public inline function disable (cap:Int):Void {
		
		this.disable (cap);
		
	}
	
	
	public inline function disableVertexAttribArray (index:Int):Void {
		
		this.disableVertexAttribArray (index);
		
	}
	
	
	public inline function drawArrays (mode:Int, first:Int, count:Int):Void {
		
		this.drawArrays (mode, first, count);
		
	}
	
	
	public inline function drawArraysInstanced (mode:Int, first:Int, count:Int, instanceCount:Int):Void {
		
		this.drawArraysInstanced (mode, first, count, instanceCount);
		
	}
	
	
	public inline function drawBuffers (buffers:Array<Int>):Void {
		
		this.drawBuffers (buffers);
		
	}
	
	
	public inline function drawElements (mode:Int, count:Int, type:Int, offset:DataPointer):Void {
		
		this.drawElements (mode, count, type, offset);
		
	}
	
	
	public inline function drawElementsInstanced (mode:Int, count:Int, type:Int, offset:DataPointer, instanceCount:Int):Void {
		
		this.drawElementsInstanced (mode, count, type, offset, instanceCount);
		
	}
	
	
	public inline function drawRangeElements (mode:Int, start:Int, end:Int, count:Int, type:Int, offset:DataPointer):Void {
		
		this.drawRangeElements (mode, start, end, count, type, offset);
		
	}
	
	
	public inline function enable (cap:Int):Void {
		
		this.enable (cap);
		
	}
	
	
	public inline function enableVertexAttribArray (index:Int):Void {
		
		this.enableVertexAttribArray (index);
		
	}
	
	
	public inline function endQuery (target:Int):Void {
		
		this.endQuery (target);
		
	}
	
	
	public inline function endTransformFeedback ():Void {
		
		this.endTransformFeedback ();
		
	}
	
	
	public inline function fenceSync (condition:Int, flags:Int):GLSync {
		
		return this.fenceSync (condition, flags);
		
	}
	
	
	public inline function finish ():Void {
		
		this.finish ();
		
	}
	
	
	public inline function flush ():Void {
		
		this.flush ();
		
	}
	
	
	public inline function framebufferRenderbuffer (target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:GLRenderbuffer):Void {
		
		this.framebufferRenderbuffer (target, attachment, renderbuffertarget, renderbuffer);
		
	}
	
	
	public inline function framebufferTexture2D (target:Int, attachment:Int, textarget:Int, texture:GLTexture, level:Int):Void {
		
		this.framebufferTexture2D (target, attachment, textarget, texture, level);
		
	}
	
	
	public inline function framebufferTextureLayer (target:Int, attachment:Int, texture:GLTexture, level:Int, layer:Int):Void {
		
		this.framebufferTextureLayer (target, attachment, texture, level, layer);
		
	}
	
	
	public inline function frontFace (mode:Int):Void {
		
		this.frontFace (mode);
		
	}
	
	
	public inline function generateMipmap (target:Int):Void {
		
		this.generateMipmap (target);
		
	}
	
	
	public inline function getActiveAttrib (program:GLProgram, index:Int):GLActiveInfo {
		
		return this.getActiveAttrib (program, index);
		
	}
	
	
	public inline function getActiveUniform (program:GLProgram, index:Int):GLActiveInfo {
		
		return this.getActiveUniform (program, index);
		
	}
	
	
	public inline function getActiveUniformBlockName (program:GLProgram, uniformBlockIndex:Int):String {
		
		return this.getActiveUniformBlockName (program, uniformBlockIndex);
		
	}
	
	
	public inline function getActiveUniformBlockParameter (program:GLProgram, uniformBlockIndex:Int, pname:Int):Dynamic {
		
		return this.getActiveUniformBlockParameter (program, uniformBlockIndex, pname);
		
	}
	
	
	public inline function getActiveUniforms (program:GLProgram, uniformIndices:Array<Int>, pname:Int):Dynamic {
		
		return this.getActiveUniforms (program, uniformIndices, pname);
		
	}
	
	
	public inline function getAttachedShaders (program:GLProgram):Array<GLShader> {
		
		return this.getAttachedShaders (program);
		
	}
	
	
	public inline function getAttribLocation (program:GLProgram, name:String):Int {
		
		return this.getAttribLocation (program, name);
		
	}
	
	
	public inline function getBufferParameter (target:Int, pname:Int):Dynamic {
		
		return this.getBufferParameter (target, pname);
		
	}
	
	
	#if (!js || !html5 || display)
	public inline function getBufferSubData (target:Int, srcByteOffset:DataPointer, dstData:ArrayBuffer, srcOffset:Int = 0, ?length:Int):Void {
		
		var size = (length != null) ? length : (dstData != null) ? #if (js && !display) dstData.byteLength #else dstData.length #end : 0;
		this.getBufferSubData (target, srcByteOffset + srcOffset, size, dstData);
		
	}
	#else
	//public function getBufferSubData (target:Int, srcByteOffset:DataPointer, dstData:js.html.ArrayBuffer, ?srcOffset:Int, ?length:Int):Void {
	//public function getBufferSubData (target:Int, srcByteOffset:DataPointer, dstData:Dynamic /*SharedArrayBuffer*/, ?srcOffset:Int, ?length:Int):Void {
	public inline function getBufferSubData (target:Int, srcByteOffset:DataPointer, dstData:Dynamic, ?srcOffset:Int, ?length:Int):Void {
		
		this.getBufferSubDataWEBGL (target, srcByteOffset, dstData, srcOffset, length);
		
	}
	#end
	
	
	public inline function getContextAttributes ():GLContextAttributes {
		
		return this.getContextAttributes ();
		
	}
	
	
	public inline function getError ():Int {
		
		return this.getError ();
		
	}
	
	
	public inline function getExtension (name:String):Dynamic {
		
		return this.getExtension (name);
		
	}
	
	
	public inline function getFragDataLocation (program:GLProgram, name:String):Int {
		
		return this.getFragDataLocation (program, name);
		
	}
	
	
	public inline function getFramebufferAttachmentParameter (target:Int, attachment:Int, pname:Int):Dynamic {
		
		return this.getFramebufferAttachmentParameter (target, attachment, pname);
		
	}
	
	
	public inline function getIndexedParameter (target:Int, index:Int):Dynamic {
		
		return this.getIndexedParameter (target, index);
		
	}
	
	
	public inline function getInternalformatParameter (target:Int, internalformat:Int, pname:Int):Dynamic {
		
		return this.getInternalformatParameter (target, internalformat, pname);
		
	}
	
	
	public inline function getParameter (pname:Int):Dynamic {
		
		return this.getParameter (pname);
		
	}
	
	
	public inline function getProgramInfoLog (program:GLProgram):String {
		
		return this.getProgramInfoLog (program);
		
	}
	
	
	public inline function getProgramParameter (program:GLProgram, pname:Int):Dynamic {
		
		return this.getProgramParameter (program, pname);
		
	}
	
	
	public inline function getQuery (target:Int, pname:Int):GLQuery {
		
		return this.getQuery (target, pname);
		
	}
	
	
	public inline function getQueryParameter (query:GLQuery, pname:Int):Dynamic {
		
		return this.getQueryParameter (query, pname);
		
	}
	
	
	public inline function getRenderbufferParameter (target:Int, pname:Int):Dynamic {
		
		return this.getRenderbufferParameter (target, pname);
		
	}
	
	
	public inline function getSamplerParameter (sampler:GLSampler, pname:Int):Dynamic {
		
		return this.getSamplerParameter (sampler, pname);
		
	}
	
	
	public inline function getShaderInfoLog (shader:GLShader):String {
		
		return this.getShaderInfoLog (shader);
		
	}
	
	
	public inline function getShaderParameter (shader:GLShader, pname:Int):Dynamic {
		
		return this.getShaderParameter (shader, pname);
		
	}
	
	
	public inline function getShaderPrecisionFormat (shadertype:Int, precisiontype:Int):GLShaderPrecisionFormat {
		
		return this.getShaderPrecisionFormat (shadertype, precisiontype);
		
	}
	
	
	public inline function getShaderSource (shader:GLShader):String {
		
		return this.getShaderSource (shader);
		
	}
	
	
	public inline function getSupportedExtensions ():Array<String> {
		
		return this.getSupportedExtensions ();
		
	}
	
	
	public inline function getSyncParameter (sync:GLSync, pname:Int):Dynamic {
		
		return this.getSyncParameter (sync, pname);
		
	}
	
	
	public inline function getTexParameter (target:Int, pname:Int):Dynamic {
		
		return this.getTexParameter (target, pname);
		
	}
	
	
	public inline function getTransformFeedbackVarying (program:GLProgram, index:Int):GLActiveInfo {
		
		return this.getTransformFeedbackVarying (program, index);
		
	}
	
	
	public inline function getUniform (program:GLProgram, location:GLUniformLocation):Dynamic {
		
		return this.getUniform (program, location);
		
	}
	
	
	public inline function getUniformBlockIndex (program:GLProgram, uniformBlockName:String):Int {
		
		return this.getUniformBlockIndex (program, uniformBlockName);
		
	}
	
	
	#if (!js || !html5 || display)
	public inline function getUniformIndices (program:GLProgram, uniformNames:Array<String>):Array<Int> {
		
		return this.getUniformIndices (program, uniformNames);
		
	}
	#else
	//public inline function getUniformIndices (program:GLProgram, uniformNames:String):Array<Int> {
	//public inline function getUniformIndices (program:GLProgram, uniformNames:Array<String>):Array<Int> {
	public inline function getUniformIndices (program:GLProgram, uniformNames:Dynamic):Array<Int> {
		
		return this.getUniformIndices (program, uniformNames);
		
	}
	#end
	
	
	public inline function getUniformLocation (program:GLProgram, name:String):GLUniformLocation {
		
		return this.getUniformLocation (program, name);
		
	}
	
	
	public inline function getVertexAttrib (index:Int, pname:Int):Dynamic {
		
		return this.getVertexAttrib (index, pname);
		
	}
	
	
	public inline function getVertexAttribOffset (index:Int, pname:Int):DataPointer {
		
		return this.getVertexAttribPointerv (index, pname);
		
	}
	
	
	public inline function hint (target:Int, mode:Int):Void {
		
		this.hint (target, mode);
		
	}
	
	
	public inline function invalidateFramebuffer (target:Int, attachments:Array<Int>):Void {
		
		this.invalidateFramebuffer (target, attachments);
		
	}
	
	
	public inline function invalidateSubFramebuffer (target:Int, attachments:Array<Int>, x:Int, y:Int, width:Int, height:Int):Void {
		
		this.invalidateSubFramebuffer (target, attachments, x, y, width, height);
		
	}
	
	
	public inline function isBuffer (buffer:GLBuffer):Bool {
		
		return this.isBuffer (buffer);
		
	}
	
	
	public inline function isContextLost ():Bool {
		
		return this.isContextLost ();
		
	}
	
	
	public inline function isEnabled (cap:Int):Bool {
		
		return this.isEnabled (cap);
		
	}
	
	
	public inline function isFramebuffer (framebuffer:GLFramebuffer):Bool {
		
		return this.isFramebuffer (framebuffer);
		
	}
	
	
	public inline function isProgram (program:GLProgram):Bool {
		
		return this.isProgram (program);
		
	}
	
	
	public inline function isQuery (query:GLQuery):Bool {
		
		return this.isQuery (query);
		
	}
	
	
	public inline function isRenderbuffer (renderbuffer:GLRenderbuffer):Bool {
		
		return this.isRenderbuffer (renderbuffer);
		
	}
	
	
	public inline function isSampler (sampler:GLSampler):Bool {
		
		return this.isSampler (sampler);
		
	}
	
	
	public inline function isShader (shader:GLShader):Bool {
		
		return this.isShader (shader);
		
	}
	
	
	public inline function isTexture (texture:GLTexture):Bool {
		
		return this.isTexture (texture);
		
	}
	
	
	public inline function isTransformFeedback (transformFeedback:GLTransformFeedback):Bool {
		
		return this.isTransformFeedback (transformFeedback);
		
	}
	
	
	public inline function isVertexArray (vertexArray:GLVertexArrayObject):Bool {
		
		return this.isVertexArray (vertexArray);
		
	}
	
	
	public inline function lineWidth (width:Float):Void {
		
		this.lineWidth (width);
		
	}
	
	
	public inline function linkProgram (program:GLProgram):Void {
		
		this.linkProgram (program);
		
	}
	
	
	public inline function pauseTransformFeedback ():Void {
		
		this.pauseTransformFeedback ();
		
	}
	
	
	public inline function pixelStorei (pname:Int, param:Int):Void {
		
		this.pixelStorei (pname, param);
		
	}
	
	
	public inline function polygonOffset (factor:Float, units:Float):Void {
		
		this.polygonOffset (factor, units);
		
	}
	
	
	public inline function readBuffer (src:Int):Void {
		
		this.readBuffer (src);
		
	}
	
	
	#if (!js || !html5 || display)
	public inline function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView, dstOffset:Int = 0):Void {
		
		__tempPointer.set (pixels, dstOffset);
		this.readPixels (x, y, width, height, format, type, __tempPointer);
		
	}
	#else
	//public function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
	//public function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, offset:DataPointer):Void {
	//public function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView, ?dstOffset:Int):Void {
	public inline function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:Dynamic, ?dstOffset:Int):Void {
		
		this.readPixelsWEBGL (x, y, width, height, format, type, pixels, dstOffset);
		
	}
	#end
	
	
	public inline function renderbufferStorage (target:Int, internalformat:Int, width:Int, height:Int):Void {
		
		this.renderbufferStorage (target, internalformat, width, height);
		
	}
	
	
	public inline function renderbufferStorageMultisample (target:Int, samples:Int, internalformat:Int, width:Int, height:Int):Void {
		
		this.renderbufferStorageMultisample (target, samples, internalformat, width, height);
		
	}
	
	
	public inline function resumeTransformFeedback ():Void {
		
		this.resumeTransformFeedback ();
		
	}
	
	
	public inline function sampleCoverage (value:Float, invert:Bool):Void {
		
		this.sampleCoverage (value, invert);
		
	}
	
	
	public inline function samplerParameterf (sampler:GLSampler, pname:Int, param:Float):Void {
		
		this.samplerParameterf (sampler, pname, param);
		
	}
	
	
	public inline function samplerParameteri (sampler:GLSampler, pname:Int, param:Int):Void {
		
		this.samplerParameteri (sampler, pname, param);
		
	}
	
	
	public inline function scissor (x:Int, y:Int, width:Int, height:Int):Void {
		
		this.scissor (x, y, width, height);
		
	}
	
	
	public inline function shaderSource (shader:GLShader, source:String):Void {
		
		this.shaderSource (shader, source);
		
	}
	
	
	public inline function stencilFunc (func:Int, ref:Int, mask:Int):Void {
		
		this.stencilFunc (func, ref, mask);
		
	}
	
	
	public inline function stencilFuncSeparate (face:Int, func:Int, ref:Int, mask:Int):Void {
		
		this.stencilFuncSeparate (face, func, ref, mask);
		
	}
	
	
	public inline function stencilMask (mask:Int):Void {
		
		this.stencilMask (mask);
		
	}
	
	
	public inline function stencilMaskSeparate (face:Int, mask:Int):Void {
		
		this.stencilMaskSeparate (face, mask);
		
	}
	
	
	public inline function stencilOp (fail:Int, zfail:Int, zpass:Int):Void {
		
		this.stencilOp (fail, zfail, zpass);
		
	}
	
	
	public inline function stencilOpSeparate (face:Int, fail:Int, zfail:Int, zpass:Int):Void {
		
		this.stencilOpSeparate (face, fail, zfail, zpass);
		
	}
	
	
	#if (!js || !html5 || display)
	public inline function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, srcData:ArrayBufferView, srcOffset:Int = 0):Void {
		
		__tempPointer.set (srcData, srcOffset);
		this.texImage2D (target, level, internalformat, width, height, border, format, type, __tempPointer);
		
	}
	#else
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:CanvasElement):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:Dynamic /*ImageBitmap*/):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:ImageData):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:ImageElement):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, offset:DataPointer):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:VideoElement):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, srcData:ArrayBufferView, srcOffset:Int):Void {
	public inline function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, srcData:Dynamic, ?srcOffset:Int):Void {
		
		this.texImage2DWEBGL (target, level, internalformat, width, height, border, format, type, srcData, srcOffset);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, srcData:ArrayBufferView, srcOffset:Int = 0):Void {
		
		__tempPointer.set (srcData, srcOffset);
		this.texImage3D (target, level, internalformat, width, height, depth, border, format, type, __tempPointer);
		
	}
	#else
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.CanvasElement):Void {
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.ImageElement):Void {
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.VideoElement):Void {
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:Dynamic /*js.html.ImageBitmap*/):Void {
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.ImageData):Void {
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, offset:DataPointer):Void {
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, srcData:js.html.ArrayBufferView, ?srcOffset:Int):Void {
	public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, srcData:Dynamic, ?srcOffset:Int):Void {
		
		this.texImage3DWEBGL (target, level, internalformat, width, height, depth, border, format, type, srcData, srcOffset);
		
	}
	#end
	
	
	public inline function texStorage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int):Void {
		
		this.texStorage2D (target, level, internalformat, width, height);
		
	}
	
	
	public inline function texStorage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int):Void {
		
		this.texStorage3D (target, level, internalformat, width, height, depth);
		
	}
	
	
	public inline function texParameterf (target:Int, pname:Int, param:Float):Void {
		
		this.texParameterf (target, pname, param);
		
	}
	
	
	public inline function texParameteri (target:Int, pname:Int, param:Int):Void {
		
		this.texParameteri (target, pname, param);
		
	}
	
	
	#if (!js || !html5 || display)
	public inline function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, srcData:ArrayBufferView, srcOffset:Int = 0):Void {
		
		__tempPointer.set (srcData, srcOffset);
		this.texSubImage2D (target, level, xoffset, yoffset, width, height, format, type, __tempPointer);
		
	}
	#else
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:CanvasElement):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:Dynamic /*ImageBitmap*/):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ImageData):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ImageElement):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, offset:Int):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:VideoElement):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, srcData:ArrayBufferView, srcOffset:Int):Void {
	public inline function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, srcData:Dynamic, ?srcOffset:Int):Void {
		
		this.texSubImage2DWEBGL (target, level, xoffset, yoffset, width, height, format, type, srcData, srcOffset);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public inline function texSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, srcData:ArrayBufferView, srcOffset:Int = 0):Void {
		
		__tempPointer.set (srcData, srcOffset);
		this.texSubImage3D (target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, __tempPointer);
		
	}
	#else
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:CanvasElement):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:Dynamic /*ImageBitmap*/):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ImageData):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ImageElement):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, offset:Int):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:VideoElement):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, srcData:ArrayBufferView, srcOffset:Int):Void {
	public inline function texSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, srcData:Dynamic, ?srcOffset:Int):Void {
		
		this.texSubImage3DWEBGL (target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, srcData, srcOffset);
		
	}
	#end
	
	
	public inline function transformFeedbackVaryings (program:GLProgram, varyings:Array<String>, bufferMode:Int):Void {
		
		this.transformFeedbackVaryings (program, varyings, bufferMode);
		
	}
	
	
	public inline function uniform1f (location:GLUniformLocation, v0:Float):Void {
		
		this.uniform1f (location, v0);
		
	}
	
	
	public inline function uniform1fv (location:GLUniformLocation, v:Float32Array):Void {
		
		#if (!js || !html5 || display)
		this.uniform1fv (location, v != null ? v.length : 0, v);
		#else
		this.uniform1fvWEBGL (location, v);
		#end
		
	}
	
	
	public inline function uniform1i (location:GLUniformLocation, v0:Int):Void {
		
		this.uniform1i (location, v0);
		
	}
	
	
	public inline function uniform1iv (location:GLUniformLocation, v:Int32Array):Void {
		
		#if (!js || !html5 || display)
		this.uniform1iv (location, v != null ? v.length : 0, v);
		#else
		this.uniform1ivWEBGL (location, v);
		#end
		
	}
	
	
	public inline function uniform1ui (location:GLUniformLocation, v0:Int):Void {
		
		this.uniform1ui (location, v0);
		
	}
	
	
	public inline function uniform1uiv (location:GLUniformLocation, v:UInt32Array):Void {
		
		#if (!js || !html5 || display)
		this.uniform1uiv (location, v != null ? v.length : 0, v);
		#else
		this.uniform1uivWEBGL (location, v);
		#end
		
	}
	
	
	public inline function uniform2f (location:GLUniformLocation, v0:Float, v1:Float):Void {
		
		this.uniform2f (location, v0, v1);
		
	}
	
	
	public inline function uniform2fv (location:GLUniformLocation, v:Float32Array):Void {
		
		
		#if (!js || !html5 || display)
		this.uniform2fv (location, v != null ? v.length >> 1 : 0, v);
		#else
		this.uniform2fvWEBGL (location, v);
		#end
		
	}
	
	
	public inline function uniform2i (location:GLUniformLocation, v0:Int, v1:Int):Void {
		
		this.uniform2i (location, v0, v1);
		
	}
	
	
	public inline function uniform2iv (location:GLUniformLocation, v:Int32Array):Void {
		
		#if (!js || !html5 || display)
		this.uniform2iv (location, v != null ? v.length >> 1 : 0, v);
		#else
		this.uniform2fvWEBGL (location, v);
		#end
		
	}
	
	
	public inline function uniform2ui (location:GLUniformLocation, v0:Int, v1:Int):Void {
		
		this.uniform2ui (location, v0, v1);
		
	}
	
	
	public inline function uniform2uiv (location:GLUniformLocation, v:UInt32Array):Void {
		
		#if (!js || !html5 || display)
		this.uniform2uiv (location, v != null ? v.length >> 1 : 0, v);
		#else
		this.uniform2uivWEBGL (location, v);
		#end
		
	}
	
	
	public inline function uniform3f (location:GLUniformLocation, v0:Float, v1:Float, v2:Float):Void {
		
		this.uniform3f (location, v0, v1, v2);
		
	}
	
	
	public inline function uniform3fv (location:GLUniformLocation, v:Float32Array):Void {
		
		#if (!js || !html5 || display)
		this.uniform3fv (location, v != null ? Std.int (v.length / 3) : 0, v);
		#else
		this.uniform3fvWEBGL (location, v);
		#end
		
	}
	
	
	public inline function uniform3i (location:GLUniformLocation, v0:Int, v1:Int, v2:Int):Void {
		
		this.uniform3i (location, v0, v1, v2);
		
	}
	
	
	public inline function uniform3iv (location:GLUniformLocation, v:Int32Array):Void {
		
		#if (!js || !html5 || display)
		this.uniform3iv (location, v != null ? Std.int (v.length / 3) : 0, v);
		#else
		this.uniform3ivWEBGL (location, v);
		#end
		
	}
	
	
	public inline function uniform3ui (location:GLUniformLocation, v0:Int, v1:Int, v2:Int):Void {
		
		this.uniform3ui (location, v0, v1, v2);
		
	}
	
	
	public inline function uniform3uiv (location:GLUniformLocation, v:UInt32Array):Void {
		
		#if (!js || !html5 || display)
		this.uniform3uiv (location, v != null ? Std.int (v.length / 3) : 0, v);
		#else
		this.uniform3uivWEBGL (location, v);
		#end
		
	}
	
	
	public inline function uniform4f (location:GLUniformLocation, v0:Float, v1:Float, v2:Float, v3:Float):Void {
		
		this.uniform4f (location, v0, v1, v2, v3);
		
	}
	
	
	public inline function uniform4fv (location:GLUniformLocation, v:Float32Array):Void {
		
		#if (!js || !html5 || display)
		this.uniform4fv (location, v != null ? v.length >> 2 : 0, v);
		#else
		this.uniform4fvWEBGL (location, v);
		#end
		
	}
	
	
	public inline function uniform4i (location:GLUniformLocation, v0:Int, v1:Int, v2:Int, v3:Int):Void {
		
		this.uniform4i (location, v0, v1, v2, v3);
		
	}
	
	
	public inline function uniform4iv (location:GLUniformLocation, v:Int32Array):Void {
		
		#if (!js || !html5 || display)
		this.uniform4iv (location, v != null ? v.length >> 2 : 0, v);
		#else
		this.uniform4ivWEBGL (location, v);
		#end
		
	}
	
	
	public inline function uniform4ui (location:GLUniformLocation, v0:Int, v1:Int, v2:Int, v3:Int):Void {
		
		this.uniform4ui (location, v0, v1, v2, v3);
		
	}
	
	
	public inline function uniform4uiv (location:GLUniformLocation, v:UInt32Array):Void {
		
		#if (!js || !html5 || display)
		this.uniform4uiv (location, v != null ? v.length >> 2 : 0, v);
		#else
		this.uniform4uivWEBGL (location, v);
		#end
		
	}
	
	
	public inline function uniformBlockBinding (program:GLProgram, uniformBlockIndex:Int, uniformBlockBinding:Int):Void {
		
		this.uniformBlockBinding (program, uniformBlockIndex, uniformBlockBinding);
		
	}
	
	
	
	#if (!js || !html5 || display)
	public function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, srcOffset:Int = 0, ?srcLength:Int):Void {
		
		var count = 0;
		if (srcLength != null) count = srcLength;
		else if (v != null) count = v.length >> 2;
		
		__tempPointer.set (v, srcOffset);
		
		this.uniformMatrix2fv (location, count, transpose, __tempPointer);
		
	}
	#else
	public inline function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		this.uniformMatrix2fvWEBGL (location, transpose, v, srcOffset, srcLength);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public function uniformMatrix2x3fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, srcOffset:Int = 0, ?srcLength:Int):Void {
		
		var count = 0;
		if (srcLength != null) count = srcLength;
		else if (v != null) count = Std.int (v.length / 6);
		
		__tempPointer.set (v, srcOffset);
		
		this.uniformMatrix2x3fv (location, count, transpose, __tempPointer);
		
	}
	#else
	public inline function uniformMatrix2x3fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		this.uniformMatrix2x3fvWEBGL (location, transpose, v, srcOffset, srcLength);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public function uniformMatrix2x4fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, srcOffset:Int = 0, ?srcLength:Int):Void {
		
		var count = 0;
		if (srcLength != null) count = srcLength;
		else if (v != null) count = Std.int (v.length / 8);
		
		__tempPointer.set (v, srcOffset);
		
		this.uniformMatrix2x4fv (location, count, transpose, __tempPointer);
		
	}
	#else
	public inline function uniformMatrix2x4fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		this.uniformMatrix2x4fvWEBGL (location, transpose, v, srcOffset, srcLength);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, srcOffset:Int = 0, ?srcLength:Int):Void {
		
		var count = 0;
		if (srcLength != null) count = srcLength;
		else if (v != null) count = Std.int (v.length / 9);
		
		__tempPointer.set (v, srcOffset);
		
		this.uniformMatrix3fv (location, count, transpose, __tempPointer);
		
	}
	#else
	public inline function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		this.uniformMatrix3fvWEBGL (location, transpose, v, srcOffset, srcLength);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public function uniformMatrix3x2fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, srcOffset:Int = 0, ?srcLength:Int):Void {
		
		var count = 0;
		if (srcLength != null) count = srcLength;
		else if (v != null) count = Std.int (v.length / 6);
		
		__tempPointer.set (v, srcOffset);
		
		this.uniformMatrix3x2fv (location, count, transpose, __tempPointer);
		
	}
	#else
	public inline function uniformMatrix3x2fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		this.uniformMatrix3x2fvWEBGL (location, transpose, v, srcOffset, srcLength);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public function uniformMatrix3x4fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, srcOffset:Int = 0, ?srcLength:Int):Void {
		
		var count = 0;
		if (srcLength != null) count = srcLength;
		else if (v != null) count = Std.int (v.length / 12);
		
		__tempPointer.set (v, srcOffset);
		
		this.uniformMatrix3x4fv (location, count, transpose, __tempPointer);
		
	}
	#else
	public inline function uniformMatrix3x4fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		this.uniformMatrix3x4fvWEBGL (location, transpose, v, srcOffset, srcLength);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, srcOffset:Int = 0, ?srcLength:Int):Void {
		
		var count = 0;
		if (srcLength != null) count = srcLength;
		else if (v != null) count = v.length >> 4;
		
		__tempPointer.set (v, srcOffset);
		
		this.uniformMatrix4fv (location, count, transpose, __tempPointer);
		
	}
	#else
	public inline function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		this.uniformMatrix4fvWEBGL (location, transpose, v, srcOffset, srcLength);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public function uniformMatrix4x2fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, srcOffset:Int = 0, ?srcLength:Int):Void {
		
		var count = 0;
		if (srcLength != null) count = srcLength;
		else if (v != null) count = Std.int (v.length / 8);
		
		__tempPointer.set (v, srcOffset);
		
		this.uniformMatrix4x2fv (location, count, transpose, __tempPointer);
		
	}
	#else
	public inline function uniformMatrix4x2fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		this.uniformMatrix4x2fvWEBGL (location, transpose, v, srcOffset, srcLength);
		
	}
	#end
	
	
	#if (!js || !html5 || display)
	public function uniformMatrix4x3fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, srcOffset:Int = 0, ?srcLength:Int):Void {
		
		var count = 0;
		if (srcLength != null) count = srcLength;
		else if (v != null) count = Std.int (v.length / 12);
		
		__tempPointer.set (v, srcOffset);
		
		this.uniformMatrix4x3fv (location, count, transpose, __tempPointer);
		
	}
	#else
	public inline function uniformMatrix4x3fv (location:GLUniformLocation, transpose:Bool, v:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		this.uniformMatrix4x3fvWEBGL (location, transpose, v, srcOffset, srcLength);
		
	}
	#end
	
	
	public inline function useProgram (program:GLProgram):Void {
		
		this.useProgram (program);
		
	}
	
	
	public inline function validateProgram (program:GLProgram):Void {
		
		this.validateProgram (program);
		
	}
	
	
	public inline function vertexAttrib1f (indx:Int, x:Float):Void {
		
		this.vertexAttrib1f (indx, x);
		
	}
	
	
	public inline function vertexAttrib1fv (indx:Int, values:Float32Array):Void {
		
		this.vertexAttrib1fv (indx, values);
		
	}
	
	
	public inline function vertexAttrib2f (indx:Int, x:Float, y:Float):Void {
		
		this.vertexAttrib2f (indx, x, y);
		
	}
	
	
	public inline function vertexAttrib2fv (indx:Int, values:Float32Array):Void {
		
		this.vertexAttrib2fv (indx, values);
		
	}
	
	
	public inline function vertexAttrib3f (indx:Int, x:Float, y:Float, z:Float):Void {
		
		this.vertexAttrib3f (indx, x, y, z);
		
	}
	
	
	public inline function vertexAttrib3fv (indx:Int, values:Float32Array):Void {
		
		this.vertexAttrib3fv (indx, values);
		
	}
	
	
	public inline function vertexAttrib4f (indx:Int, x:Float, y:Float, z:Float, w:Float):Void {
		
		this.vertexAttrib4f (indx, x, y, z, w);
		
	}
	
	
	public inline function vertexAttrib4fv (indx:Int, values:Float32Array):Void {
		
		this.vertexAttrib4fv (indx, values);
		
	}
	
	
	public inline function vertexAttribDivisor (index:Int, divisor:Int):Void {
		
		this.vertexAttribDivisor (index, divisor);
		
	}
	
	
	public inline function vertexAttribI4i (indx:Int, x:Int, y:Int, z:Int, w:Int):Void {
		
		this.vertexAttribI4i (indx, x, y, z, w);
		
	}
	
	
	public inline function vertexAttribI4iv (indx:Int, values:Float32Array):Void {
		
		this.vertexAttribI4iv (indx, values);
		
	}
	
	
	public inline function vertexAttribI4ui (indx:Int, x:Int, y:Int, z:Int, w:Int):Void {
		
		this.vertexAttribI4ui (indx, x, y, z, w);
		
	}
	
	
	public inline function vertexAttribI4uiv (indx:Int, values:Float32Array):Void {
		
		this.vertexAttribI4uiv (indx, values);
		
	}
	
	
	public inline function vertexAttribPointer (indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:DataPointer):Void {
		
		this.vertexAttribPointer (indx, size, type, normalized, stride, offset);
		
	}
	
	
	public inline function viewport (x:Int, y:Int, width:Int, height:Int):Void {
		
		this.viewport (x, y, width, height);
		
	}
	
	
	public inline function waitSync (sync:GLSync, flags:Int, timeout:Int64):Void {
		
		this.waitSync (sync, flags, timeout);
		
	}
	
	
	@:from private static function fromGL (gl:#if lime_opengl Class<GL> #else Dynamic #end):WebGL2RenderContext {
		
		#if lime_opengl
		return cast GL.context;
		#else
		return null;
		#end
		
	}
	
	
	@:from private static function fromGLES3RenderContext (gl:GLES3RenderContext):WebGL2RenderContext {
		
		return (gl:GLRenderContext);
		
	}
	
	
	@:from private static function toWebGLRenderContext (gl:WebGLRenderContext):WebGL2RenderContext {
		
		return cast gl;
		
	}
	
	
}