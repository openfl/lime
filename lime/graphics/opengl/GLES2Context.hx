package lime.graphics.opengl;


import lime.utils.ArrayBufferView;
import lime.utils.Float32Array;
import lime.utils.Int32Array;


abstract GLES2Context(GLRenderContext) from GLRenderContext to GLRenderContext {
	
	
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
	public var BGR_EXT (get, never):Int;
	public var BGRA_EXT (get, never):Int;
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
	
	public var VERTEX_PROGRAM_POINT_SIZE (get, never):Int;
	public var POINT_SPRITE (get, never):Int;
	
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
	
	public var version (get, never):Int;
	
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
	private inline function get_BGR_EXT ():Int { #if (js && html5) return 0; #else return this.BGR_EXT; #end } // TODO
	private inline function get_BGRA_EXT ():Int { #if (js && html5) return 0; #else return this.BGRA_EXT; #end } // TODO
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
	private inline function get_VERTEX_PROGRAM_POINT_SIZE ():Int { #if (js && html5) return 0; #else return this.VERTEX_PROGRAM_POINT_SIZE; #end } // TODO
	private inline function get_POINT_SPRITE ():Int { #if (js && html5) return 0; #else return this.POINT_SPRITE; #end } // TODO
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
	private inline function get_version ():Int { #if (js && html5) return 2; #else return this.version; #end } // TODO
	
	
	public inline function activeTexture (texture:Int):Void {
		
		this.activeTexture (texture);
		
	}
	
	
	public inline function attachShader (program:GLProgram, shader:GLShader):Void {
		
		this.attachShader (program, shader);
		
	}
	
	
	public inline function bindAttribLocation (program:GLProgram, index:Int, name:String):Void {
		
		this.bindAttribLocation (program, index, name);
		
	}
	
	
	public inline function bindBuffer (target:Int, buffer:GLBuffer):Void {
		
		this.bindBuffer (target, buffer);
		
	}
	
	
	public inline function bindFramebuffer (target:Int, framebuffer:GLFramebuffer):Void {
		
		this.bindFramebuffer (target, framebuffer);
		
	}
	
	
	public inline function bindRenderbuffer (target:Int, renderbuffer:GLRenderbuffer):Void {
		
		this.bindRenderbuffer (target, renderbuffer);
		
	}
	
	
	public inline function bindTexture (target:Int, texture:GLTexture):Void {
		
		this.bindTexture (target, texture);
		
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
	
	
	public inline function bufferData (target:Int, data:ArrayBufferView, usage:Int):Void {
		
		this.bufferData (target, data, usage);
		
	}
	
	
	public inline function bufferSubData (target:Int, offset:Int, data:ArrayBufferView):Void {
		
		this.bufferSubData (target, offset, data);
		
	}
	
	
	public inline function checkFramebufferStatus (target:Int):Int {
		
		return this.checkFramebufferStatus (target);
		
	}
	
	
	public inline function clear (mask:Int):Void {
		
		this.clear (mask);
		
	}
	
	
	public inline function clearColor (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		this.clearColor (red, green, blue, alpha);
		
	}
	
	
	public inline function clearDepth (depth:Float):Void {
		
		this.clearDepth (depth);
		
	}
	
	
	public inline function clearStencil (s:Int):Void {
		
		this.clearStencil (s);
		
	}
	
	
	public inline function colorMask (red:Bool, green:Bool, blue:Bool, alpha:Bool):Void {
		
		this.colorMask (red, green, blue, alpha);
		
	}
	
	
	public inline function compileShader (shader:GLShader):Void {
		
		this.compileShader (shader);
		
	}
	
	
	public inline function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, data:ArrayBufferView):Void {
		
		this.compressedTexImage2D (target, level, internalformat, width, height, border, data);
		
	}
	
	
	public inline function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, data:ArrayBufferView):Void {
		
		this.compressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, data);
		
	}
	
	
	public inline function copyTexImage2D (target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void {
		
		this.copyTexImage2D (target, level, internalformat, x, y, width, height, border);
		
	}
	
	
	public inline function copyTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {
		
		this.copyTexSubImage2D (target, level, xoffset, yoffset, x, y, width, height);
		
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
	
	
	public inline function createRenderbuffer ():GLRenderbuffer {
		
		return this.createRenderbuffer ();
		
	}
	
	
	public inline function createShader (type:Int):GLShader {
		
		return this.createShader (type);
		
	}
	
	
	public inline function createTexture ():GLTexture {
		
		return this.createTexture ();
		
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
	
	
	public inline function deleteRenderbuffer (renderbuffer:GLRenderbuffer):Void {
		
		this.deleteRenderbuffer (renderbuffer);
		
	}
	
	
	public inline function deleteShader (shader:GLShader):Void {
		
		this.deleteShader (shader);
		
	}
	
	
	public inline function deleteTexture (texture:GLTexture):Void {
		
		this.deleteTexture (texture);
		
	}
	
	
	public inline function depthFunc (func:Int):Void {
		
		this.depthFunc (func);
		
	}
	
	
	public inline function depthMask (flag:Bool):Void {
		
		this.depthMask (flag);
		
	}
	
	
	public inline function depthRange (zNear:Float, zFar:Float):Void {
		
		this.depthRange (zNear, zFar);
		
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
	
	
	public inline function drawElements (mode:Int, count:Int, type:Int, offset:Int):Void {
		
		this.drawElements (mode, count, type, offset);
		
	}
	
	
	public inline function enable (cap:Int):Void {
		
		this.enable (cap);
		
	}
	
	
	public inline function enableVertexAttribArray (index:Int):Void {
		
		this.enableVertexAttribArray (index);
		
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
	
	
	public inline function getAttachedShaders (program:GLProgram):Array<GLShader> {
		
		return this.getAttachedShaders (program);
		
	}
	
	
	public inline function getAttribLocation (program:GLProgram, name:String):Int {
		
		return this.getAttribLocation (program, name);
		
	}
	
	
	public inline function getBufferParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		return this.getBufferParameter (target, pname);
		
	}
	
	
	public inline function getContextAttributes ():GLContextAttributes {
		
		return this.getContextAttributes ();
		
	}
	
	
	public inline function getError ():Int {
		
		return this.getError ();
		
	}
	
	
	public inline function getExtension (name:String):Dynamic {
		
		return this.getExtension (name);
		
	}
	
	
	public inline function getFramebufferAttachmentParameter (target:Int, attachment:Int, pname:Int):Int /*Dynamic*/ {
		
		return this.getFramebufferAttachmentParameter (target, attachment, pname);
		
	}
	
	
	public inline function getParameter (pname:Int):Dynamic {
		
		return this.getParameter (pname);
		
	}
	
	
	public inline function getProgramInfoLog (program:GLProgram):String {
		
		return this.getProgramInfoLog (program);
		
	}
	
	
	public inline function getProgramParameter (program:GLProgram, pname:Int):Int {
		
		return this.getProgramParameter (program, pname);
		
	}
	
	
	public inline function getRenderbufferParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		return this.getRenderbufferParameter (target, pname);
		
	}
	
	
	public inline function getShaderInfoLog (shader:GLShader):String {
		
		return this.getShaderInfoLog (shader);
		
	}
	
	
	public inline function getShaderParameter (shader:GLShader, pname:Int):Int {
		
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
	
	
	public inline function getTexParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		return this.getTexParameter (target, pname);
		
	}
	
	
	public inline function getUniform (program:GLProgram, location:GLUniformLocation):Dynamic {
		
		return this.getUniform (program, location);
		
	}
	
	
	public inline function getUniformLocation (program:GLProgram, name:String):GLUniformLocation {
		
		return this.getUniformLocation (program, name);
		
	}
	
	
	public inline function getVertexAttrib (index:Int, pname:Int):Int /*Dynamic*/ {
		
		return this.getVertexAttrib (index, pname);
		
	}
	
	
	public inline function getVertexAttribOffset (index:Int, pname:Int):Int {
		
		return this.getVertexAttribOffset (index, pname);
		
	}
	
	
	public inline function hint (target:Int, mode:Int):Void {
		
		this.hint (target, mode);
		
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
	
	
	public inline function isRenderbuffer (renderbuffer:GLRenderbuffer):Bool {
		
		return this.isRenderbuffer (renderbuffer);
		
	}
	
	
	public inline function isShader (shader:GLShader):Bool {
		
		return this.isShader (shader);
		
	}
	
	
	public inline function isTexture (texture:GLTexture):Bool {
		
		return this.isTexture (texture);
		
	}
	
	
	public inline function lineWidth (width:Float):Void {
		
		this.lineWidth (width);
		
	}
	
	
	public inline function linkProgram (program:GLProgram):Void {
		
		this.linkProgram (program);
		
	}
	
	
	public inline function pixelStorei (pname:Int, param:Int):Void {
		
		this.pixelStorei (pname, param);
		
	}
	
	
	public inline function polygonOffset (factor:Float, units:Float):Void {
		
		this.polygonOffset (factor, units);
		
	}
	
	
	public inline function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		this.readPixels (x, y, width, height, format, type, pixels);
		
	}
	
	
	public inline function renderbufferStorage (target:Int, internalformat:Int, width:Int, height:Int):Void {
		
		this.renderbufferStorage (target, internalformat, width, height);
		
	}
	
	
	public inline function sampleCoverage (value:Float, invert:Bool):Void {
		
		this.sampleCoverage (value, invert);
		
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
	
	
	public inline function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		this.texImage2D (target, level, internalformat, width, height, border, format, type, pixels);
		
	}
	
	
	public inline function texParameterf (target:Int, pname:Int, param:Float):Void {
		
		this.texParameterf (target, pname, param);
		
	}
	
	
	public inline function texParameteri (target:Int, pname:Int, param:Int):Void {
		
		this.texParameteri (target, pname, param);
		
	}
	
	
	public inline function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		this.texSubImage2D (target, level, xoffset, yoffset, width, height, format, type, pixels);
		
	}
	
	
	public inline function uniform1f (location:GLUniformLocation, x:Float):Void {
		
		this.uniform1f (location, x);
		
	}
	
	
	public inline function uniform1fv (location:GLUniformLocation, x:Float32Array):Void {
		
		this.uniform1fv (location, x);
		
	}
	
	
	public inline function uniform1i (location:GLUniformLocation, x:Int):Void {
		
		this.uniform1i (location, x);
		
	}
	
	
	public inline function uniform1iv (location:GLUniformLocation, v:Int32Array):Void {
		
		this.uniform1iv (location, v);
		
	}
	
	
	public inline function uniform2f (location:GLUniformLocation, x:Float, y:Float):Void {
		
		this.uniform2f (location, x, y);
		
	}
	
	
	public inline function uniform2fv (location:GLUniformLocation, v:Float32Array):Void {
		
		this.uniform2fv (location, v);
		
	}
	
	
	public inline function uniform2i (location:GLUniformLocation, x:Int, y:Int):Void {
		
		this.uniform2i (location, x, y);
		
	}
	
	
	public inline function uniform2iv (location:GLUniformLocation, v:Int32Array):Void {
		
		this.uniform2iv (location, v);
		
	}
	
	
	public inline function uniform3f (location:GLUniformLocation, x:Float, y:Float, z:Float):Void {
		
		this.uniform3f (location, x, y, z);
		
	}
	
	
	public inline function uniform3fv (location:GLUniformLocation, v:Float32Array):Void {
		
		this.uniform3fv (location, v);
		
	}
	
	
	public inline function uniform3i (location:GLUniformLocation, x:Int, y:Int, z:Int):Void {
		
		this.uniform3i (location, x, y, z);
		
	}
	
	
	public inline function uniform3iv (location:GLUniformLocation, v:Int32Array):Void {
		
		this.uniform3iv (location, v);
		
	}
	
	
	public inline function uniform4f (location:GLUniformLocation, x:Float, y:Float, z:Float, w:Float):Void {
		
		this.uniform4f (location, x, y, z, w);
		
	}
	
	
	public inline function uniform4fv (location:GLUniformLocation, v:Float32Array):Void {
		
		this.uniform4fv (location, v);
		
	}
	
	
	public inline function uniform4i (location:GLUniformLocation, x:Int, y:Int, z:Int, w:Int):Void {
		
		this.uniform4i (location, x, y, z, w);
		
	}
	
	
	public inline function uniform4iv (location:GLUniformLocation, v:Int32Array):Void {
		
		this.uniform4iv (location, v);
		
	}
	
	
	public inline function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		this.uniformMatrix2fv (location, transpose, v);
		
	}
	
	
	public inline function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		this.uniformMatrix3fv (location, transpose, v);
		
	}
	
	
	public inline function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		this.uniformMatrix4fv (location, transpose, v);
		
	}
	
	
	/*public inline function uniformMatrix3D(location:GLUniformLocation, transpose:Bool, matrix:Matrix3D):Void {
		
		lime_gl_uniform_matrix(location, transpose, Float32Array.fromMatrix(matrix).getByteBuffer() , 4);
		
	}*/
	
	
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
	
	
	public inline function vertexAttribPointer (indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int):Void {
		
		this.vertexAttribPointer (indx, size, type, normalized, stride, offset);
		
	}
	
	
	public inline function viewport (x:Int, y:Int, width:Int, height:Int):Void {
		
		this.viewport (x, y, width, height);
		
	}
	
	
}