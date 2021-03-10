package lime._internal.backend.native;

import haxe.io.Bytes;
import haxe.Int64;
import lime.graphics.opengl.ext.*;
import lime.graphics.opengl.GLQuery;
import lime.graphics.opengl.GLSampler;
import lime.graphics.opengl.GLSync;
import lime.graphics.opengl.GLTransformFeedback;
import lime.graphics.opengl.GLVertexArrayObject;
import lime.graphics.opengl.GLActiveInfo;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLContextAttributes;
import lime.graphics.opengl.GLFramebuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLRenderbuffer;
import lime.graphics.opengl.GLShader;
import lime.graphics.opengl.GLShaderPrecisionFormat;
import lime.graphics.opengl.GLTexture;
import lime.graphics.opengl.GLUniformLocation;
import lime.graphics.opengl.GL;
import lime.graphics.RenderContextType;
import lime.utils.DataPointer;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import lime.utils.UInt32Array;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:dox(hide)
@:allow(lime.ui.Window)
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.graphics.opengl)
class NativeOpenGLRenderContext
{
	private static var __extensionObjects:Map<String, Dynamic>;
	private static var __extensionObjectConstructors = new Map<String, Void->Dynamic>();
	private static var __lastContextID = 0;
	private static var __supportedExtensions:Array<String>;

	public var DEPTH_BUFFER_BIT = 0x00000100;
	public var STENCIL_BUFFER_BIT = 0x00000400;
	public var COLOR_BUFFER_BIT = 0x00004000;
	public var POINTS = 0x0000;
	public var LINES = 0x0001;
	public var LINE_LOOP = 0x0002;
	public var LINE_STRIP = 0x0003;
	public var TRIANGLES = 0x0004;
	public var TRIANGLE_STRIP = 0x0005;
	public var TRIANGLE_FAN = 0x0006;
	public var ZERO = 0;
	public var ONE = 1;
	public var SRC_COLOR = 0x0300;
	public var ONE_MINUS_SRC_COLOR = 0x0301;
	public var SRC_ALPHA = 0x0302;
	public var ONE_MINUS_SRC_ALPHA = 0x0303;
	public var DST_ALPHA = 0x0304;
	public var ONE_MINUS_DST_ALPHA = 0x0305;
	public var DST_COLOR = 0x0306;
	public var ONE_MINUS_DST_COLOR = 0x0307;
	public var SRC_ALPHA_SATURATE = 0x0308;
	public var FUNC_ADD = 0x8006;
	public var BLEND_EQUATION = 0x8009;
	public var BLEND_EQUATION_RGB = 0x8009;
	public var BLEND_EQUATION_ALPHA = 0x883D;
	public var FUNC_SUBTRACT = 0x800A;
	public var FUNC_REVERSE_SUBTRACT = 0x800B;
	public var BLEND_DST_RGB = 0x80C8;
	public var BLEND_SRC_RGB = 0x80C9;
	public var BLEND_DST_ALPHA = 0x80CA;
	public var BLEND_SRC_ALPHA = 0x80CB;
	public var CONSTANT_COLOR = 0x8001;
	public var ONE_MINUS_CONSTANT_COLOR = 0x8002;
	public var CONSTANT_ALPHA = 0x8003;
	public var ONE_MINUS_CONSTANT_ALPHA = 0x8004;
	public var BLEND_COLOR = 0x8005;
	public var ARRAY_BUFFER = 0x8892;
	public var ELEMENT_ARRAY_BUFFER = 0x8893;
	public var ARRAY_BUFFER_BINDING = 0x8894;
	public var ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;
	public var STREAM_DRAW = 0x88E0;
	public var STATIC_DRAW = 0x88E4;
	public var DYNAMIC_DRAW = 0x88E8;
	public var BUFFER_SIZE = 0x8764;
	public var BUFFER_USAGE = 0x8765;
	public var CURRENT_VERTEX_ATTRIB = 0x8626;
	public var FRONT = 0x0404;
	public var BACK = 0x0405;
	public var FRONT_AND_BACK = 0x0408;
	public var TEXTURE_2D = 0x0DE1;
	public var CULL_FACE = 0x0B44;
	public var BLEND = 0x0BE2;
	public var DITHER = 0x0BD0;
	public var STENCIL_TEST = 0x0B90;
	public var DEPTH_TEST = 0x0B71;
	public var SCISSOR_TEST = 0x0C11;
	public var POLYGON_OFFSET_FILL = 0x8037;
	public var SAMPLE_ALPHA_TO_COVERAGE = 0x809E;
	public var SAMPLE_COVERAGE = 0x80A0;
	public var NO_ERROR = 0;
	public var INVALID_ENUM = 0x0500;
	public var INVALID_VALUE = 0x0501;
	public var INVALID_OPERATION = 0x0502;
	public var OUT_OF_MEMORY = 0x0505;
	public var CW = 0x0900;
	public var CCW = 0x0901;
	public var LINE_WIDTH = 0x0B21;
	public var ALIASED_POINT_SIZE_RANGE = 0x846D;
	public var ALIASED_LINE_WIDTH_RANGE = 0x846E;
	public var CULL_FACE_MODE = 0x0B45;
	public var FRONT_FACE = 0x0B46;
	public var DEPTH_RANGE = 0x0B70;
	public var DEPTH_WRITEMASK = 0x0B72;
	public var DEPTH_CLEAR_VALUE = 0x0B73;
	public var DEPTH_FUNC = 0x0B74;
	public var STENCIL_CLEAR_VALUE = 0x0B91;
	public var STENCIL_FUNC = 0x0B92;
	public var STENCIL_FAIL = 0x0B94;
	public var STENCIL_PASS_DEPTH_FAIL = 0x0B95;
	public var STENCIL_PASS_DEPTH_PASS = 0x0B96;
	public var STENCIL_REF = 0x0B97;
	public var STENCIL_VALUE_MASK = 0x0B93;
	public var STENCIL_WRITEMASK = 0x0B98;
	public var STENCIL_BACK_FUNC = 0x8800;
	public var STENCIL_BACK_FAIL = 0x8801;
	public var STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;
	public var STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;
	public var STENCIL_BACK_REF = 0x8CA3;
	public var STENCIL_BACK_VALUE_MASK = 0x8CA4;
	public var STENCIL_BACK_WRITEMASK = 0x8CA5;
	public var VIEWPORT = 0x0BA2;
	public var SCISSOR_BOX = 0x0C10;
	public var COLOR_CLEAR_VALUE = 0x0C22;
	public var COLOR_WRITEMASK = 0x0C23;
	public var UNPACK_ALIGNMENT = 0x0CF5;
	public var PACK_ALIGNMENT = 0x0D05;
	public var MAX_TEXTURE_SIZE = 0x0D33;
	public var MAX_VIEWPORT_DIMS = 0x0D3A;
	public var SUBPIXEL_BITS = 0x0D50;
	public var RED_BITS = 0x0D52;
	public var GREEN_BITS = 0x0D53;
	public var BLUE_BITS = 0x0D54;
	public var ALPHA_BITS = 0x0D55;
	public var DEPTH_BITS = 0x0D56;
	public var STENCIL_BITS = 0x0D57;
	public var POLYGON_OFFSET_UNITS = 0x2A00;
	public var POLYGON_OFFSET_FACTOR = 0x8038;
	public var TEXTURE_BINDING_2D = 0x8069;
	public var SAMPLE_BUFFERS = 0x80A8;
	public var SAMPLES = 0x80A9;
	public var SAMPLE_COVERAGE_VALUE = 0x80AA;
	public var SAMPLE_COVERAGE_INVERT = 0x80AB;
	public var NUM_COMPRESSED_TEXTURE_FORMATS = 0x86A2;
	public var COMPRESSED_TEXTURE_FORMATS = 0x86A3;
	public var DONT_CARE = 0x1100;
	public var FASTEST = 0x1101;
	public var NICEST = 0x1102;
	public var GENERATE_MIPMAP_HINT = 0x8192;
	public var BYTE = 0x1400;
	public var UNSIGNED_BYTE = 0x1401;
	public var SHORT = 0x1402;
	public var UNSIGNED_SHORT = 0x1403;
	public var INT = 0x1404;
	public var UNSIGNED_INT = 0x1405;
	public var FLOAT = 0x1406;
	public var FIXED = 0x0140C;
	public var DEPTH_COMPONENT = 0x1902;
	public var ALPHA = 0x1906;
	public var RGB = 0x1907;
	public var RGBA = 0x1908;
	public var LUMINANCE = 0x1909;
	public var LUMINANCE_ALPHA = 0x190A;
	public var UNSIGNED_SHORT_4_4_4_4 = 0x8033;
	public var UNSIGNED_SHORT_5_5_5_1 = 0x8034;
	public var UNSIGNED_SHORT_5_6_5 = 0x8363;
	public var FRAGMENT_SHADER = 0x8B30;
	public var VERTEX_SHADER = 0x8B31;
	public var MAX_VERTEX_ATTRIBS = 0x8869;
	public var MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;
	public var MAX_VARYING_VECTORS = 0x8DFC;
	public var MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;
	public var MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;
	public var MAX_TEXTURE_IMAGE_UNITS = 0x8872;
	public var MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;
	public var SHADER_TYPE = 0x8B4F;
	public var DELETE_STATUS = 0x8B80;
	public var LINK_STATUS = 0x8B82;
	public var VALIDATE_STATUS = 0x8B83;
	public var ATTACHED_SHADERS = 0x8B85;
	public var ACTIVE_UNIFORMS = 0x8B86;
	public var ACTIVE_UNIFORMS_MAX_LENGTH = 0x8B87;
	public var ACTIVE_ATTRIBUTES = 0x8B89;
	public var ACTIVE_ATTRIBUTES_MAX_LENGTH = 0x8B8A;
	public var SHADING_LANGUAGE_VERSION = 0x8B8C;
	public var CURRENT_PROGRAM = 0x8B8D;
	public var NEVER = 0x0200;
	public var LESS = 0x0201;
	public var EQUAL = 0x0202;
	public var LEQUAL = 0x0203;
	public var GREATER = 0x0204;
	public var NOTEQUAL = 0x0205;
	public var GEQUAL = 0x0206;
	public var ALWAYS = 0x0207;
	public var KEEP = 0x1E00;
	public var REPLACE = 0x1E01;
	public var INCR = 0x1E02;
	public var DECR = 0x1E03;
	public var INVERT = 0x150A;
	public var INCR_WRAP = 0x8507;
	public var DECR_WRAP = 0x8508;
	public var VENDOR = 0x1F00;
	public var RENDERER = 0x1F01;
	public var VERSION = 0x1F02;
	public var EXTENSIONS = 0x1F03;
	public var NEAREST = 0x2600;
	public var LINEAR = 0x2601;
	public var NEAREST_MIPMAP_NEAREST = 0x2700;
	public var LINEAR_MIPMAP_NEAREST = 0x2701;
	public var NEAREST_MIPMAP_LINEAR = 0x2702;
	public var LINEAR_MIPMAP_LINEAR = 0x2703;
	public var TEXTURE_MAG_FILTER = 0x2800;
	public var TEXTURE_MIN_FILTER = 0x2801;
	public var TEXTURE_WRAP_S = 0x2802;
	public var TEXTURE_WRAP_T = 0x2803;
	public var TEXTURE = 0x1702;
	public var TEXTURE_CUBE_MAP = 0x8513;
	public var TEXTURE_BINDING_CUBE_MAP = 0x8514;
	public var TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;
	public var TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;
	public var TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;
	public var TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;
	public var TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;
	public var TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;
	public var MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;
	public var TEXTURE0 = 0x84C0;
	public var TEXTURE1 = 0x84C1;
	public var TEXTURE2 = 0x84C2;
	public var TEXTURE3 = 0x84C3;
	public var TEXTURE4 = 0x84C4;
	public var TEXTURE5 = 0x84C5;
	public var TEXTURE6 = 0x84C6;
	public var TEXTURE7 = 0x84C7;
	public var TEXTURE8 = 0x84C8;
	public var TEXTURE9 = 0x84C9;
	public var TEXTURE10 = 0x84CA;
	public var TEXTURE11 = 0x84CB;
	public var TEXTURE12 = 0x84CC;
	public var TEXTURE13 = 0x84CD;
	public var TEXTURE14 = 0x84CE;
	public var TEXTURE15 = 0x84CF;
	public var TEXTURE16 = 0x84D0;
	public var TEXTURE17 = 0x84D1;
	public var TEXTURE18 = 0x84D2;
	public var TEXTURE19 = 0x84D3;
	public var TEXTURE20 = 0x84D4;
	public var TEXTURE21 = 0x84D5;
	public var TEXTURE22 = 0x84D6;
	public var TEXTURE23 = 0x84D7;
	public var TEXTURE24 = 0x84D8;
	public var TEXTURE25 = 0x84D9;
	public var TEXTURE26 = 0x84DA;
	public var TEXTURE27 = 0x84DB;
	public var TEXTURE28 = 0x84DC;
	public var TEXTURE29 = 0x84DD;
	public var TEXTURE30 = 0x84DE;
	public var TEXTURE31 = 0x84DF;
	public var ACTIVE_TEXTURE = 0x84E0;
	public var REPEAT = 0x2901;
	public var CLAMP_TO_EDGE = 0x812F;
	public var MIRRORED_REPEAT = 0x8370;
	public var FLOAT_VEC2 = 0x8B50;
	public var FLOAT_VEC3 = 0x8B51;
	public var FLOAT_VEC4 = 0x8B52;
	public var INT_VEC2 = 0x8B53;
	public var INT_VEC3 = 0x8B54;
	public var INT_VEC4 = 0x8B55;
	public var BOOL = 0x8B56;
	public var BOOL_VEC2 = 0x8B57;
	public var BOOL_VEC3 = 0x8B58;
	public var BOOL_VEC4 = 0x8B59;
	public var FLOAT_MAT2 = 0x8B5A;
	public var FLOAT_MAT3 = 0x8B5B;
	public var FLOAT_MAT4 = 0x8B5C;
	public var SAMPLER_2D = 0x8B5E;
	public var SAMPLER_CUBE = 0x8B60;
	public var VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;
	public var VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;
	public var VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;
	public var VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;
	public var VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;
	public var VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;
	public var VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;
	public var IMPLEMENTATION_COLOR_READ_TYPE = 0x8B9A;
	public var IMPLEMENTATION_COLOR_READ_FORMAT = 0x8B9B;
	public var VERTEX_PROGRAM_POINT_SIZE = 0x8642;
	public var POINT_SPRITE = 0x8861;
	public var COMPILE_STATUS = 0x8B81;
	public var INFO_LOG_LENGTH = 0x8B84;
	public var SHADER_SOURCE_LENGTH = 0x8B88;
	public var SHADER_COMPILER = 0x8DFA;
	public var SHADER_BINARY_FORMATS = 0x8DF8;
	public var NUM_SHADER_BINARY_FORMATS = 0x8DF9;
	public var LOW_FLOAT = 0x8DF0;
	public var MEDIUM_FLOAT = 0x8DF1;
	public var HIGH_FLOAT = 0x8DF2;
	public var LOW_INT = 0x8DF3;
	public var MEDIUM_INT = 0x8DF4;
	public var HIGH_INT = 0x8DF5;
	public var FRAMEBUFFER = 0x8D40;
	public var RENDERBUFFER = 0x8D41;
	public var RGBA4 = 0x8056;
	public var RGB5_A1 = 0x8057;
	public var RGB565 = 0x8D62;
	public var DEPTH_COMPONENT16 = 0x81A5;
	public var STENCIL_INDEX = 0x1901;
	public var STENCIL_INDEX8 = 0x8D48;
	public var DEPTH_STENCIL = 0x84F9;
	public var RENDERBUFFER_WIDTH = 0x8D42;
	public var RENDERBUFFER_HEIGHT = 0x8D43;
	public var RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;
	public var RENDERBUFFER_RED_SIZE = 0x8D50;
	public var RENDERBUFFER_GREEN_SIZE = 0x8D51;
	public var RENDERBUFFER_BLUE_SIZE = 0x8D52;
	public var RENDERBUFFER_ALPHA_SIZE = 0x8D53;
	public var RENDERBUFFER_DEPTH_SIZE = 0x8D54;
	public var RENDERBUFFER_STENCIL_SIZE = 0x8D55;
	public var FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;
	public var FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;
	public var FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;
	public var FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;
	public var COLOR_ATTACHMENT0 = 0x8CE0;
	public var DEPTH_ATTACHMENT = 0x8D00;
	public var STENCIL_ATTACHMENT = 0x8D20;
	public var DEPTH_STENCIL_ATTACHMENT = 0x821A;
	public var NONE = 0;
	public var FRAMEBUFFER_COMPLETE = 0x8CD5;
	public var FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;
	public var FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;
	public var FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;
	public var FRAMEBUFFER_UNSUPPORTED = 0x8CDD;
	public var FRAMEBUFFER_BINDING = 0x8CA6;
	public var RENDERBUFFER_BINDING = 0x8CA7;
	public var MAX_RENDERBUFFER_SIZE = 0x84E8;
	public var INVALID_FRAMEBUFFER_OPERATION = 0x0506;
	public var UNPACK_FLIP_Y_WEBGL = 0x9240;
	public var UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;
	public var CONTEXT_LOST_WEBGL = 0x9242;
	public var UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;
	public var BROWSER_DEFAULT_WEBGL = 0x9244;
	public var READ_BUFFER = 0x0C02;
	public var UNPACK_ROW_LENGTH = 0x0CF2;
	public var UNPACK_SKIP_ROWS = 0x0CF3;
	public var UNPACK_SKIP_PIXELS = 0x0CF4;
	public var PACK_ROW_LENGTH = 0x0D02;
	public var PACK_SKIP_ROWS = 0x0D03;
	public var PACK_SKIP_PIXELS = 0x0D04;
	public var TEXTURE_BINDING_3D = 0x806A;
	public var UNPACK_SKIP_IMAGES = 0x806D;
	public var UNPACK_IMAGE_HEIGHT = 0x806E;
	public var MAX_3D_TEXTURE_SIZE = 0x8073;
	public var MAX_ELEMENTS_VERTICES = 0x80E8;
	public var MAX_ELEMENTS_INDICES = 0x80E9;
	public var MAX_TEXTURE_LOD_BIAS = 0x84FD;
	public var MAX_FRAGMENT_UNIFORM_COMPONENTS = 0x8B49;
	public var MAX_VERTEX_UNIFORM_COMPONENTS = 0x8B4A;
	public var MAX_ARRAY_TEXTURE_LAYERS = 0x88FF;
	public var MIN_PROGRAM_TEXEL_OFFSET = 0x8904;
	public var MAX_PROGRAM_TEXEL_OFFSET = 0x8905;
	public var MAX_VARYING_COMPONENTS = 0x8B4B;
	public var FRAGMENT_SHADER_DERIVATIVE_HINT = 0x8B8B;
	public var RASTERIZER_DISCARD = 0x8C89;
	public var VERTEX_ARRAY_BINDING = 0x85B5;
	public var MAX_VERTEX_OUTPUT_COMPONENTS = 0x9122;
	public var MAX_FRAGMENT_INPUT_COMPONENTS = 0x9125;
	public var MAX_SERVER_WAIT_TIMEOUT = 0x9111;
	public var MAX_ELEMENT_INDEX = 0x8D6B;
	public var RED = 0x1903;
	public var RGB8 = 0x8051;
	public var RGBA8 = 0x8058;
	public var RGB10_A2 = 0x8059;
	public var TEXTURE_3D = 0x806F;
	public var TEXTURE_WRAP_R = 0x8072;
	public var TEXTURE_MIN_LOD = 0x813A;
	public var TEXTURE_MAX_LOD = 0x813B;
	public var TEXTURE_BASE_LEVEL = 0x813C;
	public var TEXTURE_MAX_LEVEL = 0x813D;
	public var TEXTURE_COMPARE_MODE = 0x884C;
	public var TEXTURE_COMPARE_FUNC = 0x884D;
	public var SRGB = 0x8C40;
	public var SRGB8 = 0x8C41;
	public var SRGB8_ALPHA8 = 0x8C43;
	public var COMPARE_REF_TO_TEXTURE = 0x884E;
	public var RGBA32F = 0x8814;
	public var RGB32F = 0x8815;
	public var RGBA16F = 0x881A;
	public var RGB16F = 0x881B;
	public var TEXTURE_2D_ARRAY = 0x8C1A;
	public var TEXTURE_BINDING_2D_ARRAY = 0x8C1D;
	public var R11F_G11F_B10F = 0x8C3A;
	public var RGB9_E5 = 0x8C3D;
	public var RGBA32UI = 0x8D70;
	public var RGB32UI = 0x8D71;
	public var RGBA16UI = 0x8D76;
	public var RGB16UI = 0x8D77;
	public var RGBA8UI = 0x8D7C;
	public var RGB8UI = 0x8D7D;
	public var RGBA32I = 0x8D82;
	public var RGB32I = 0x8D83;
	public var RGBA16I = 0x8D88;
	public var RGB16I = 0x8D89;
	public var RGBA8I = 0x8D8E;
	public var RGB8I = 0x8D8F;
	public var RED_INTEGER = 0x8D94;
	public var RGB_INTEGER = 0x8D98;
	public var RGBA_INTEGER = 0x8D99;
	public var R8 = 0x8229;
	public var RG8 = 0x822B;
	public var R16F = 0x822D;
	public var R32F = 0x822E;
	public var RG16F = 0x822F;
	public var RG32F = 0x8230;
	public var R8I = 0x8231;
	public var R8UI = 0x8232;
	public var R16I = 0x8233;
	public var R16UI = 0x8234;
	public var R32I = 0x8235;
	public var R32UI = 0x8236;
	public var RG8I = 0x8237;
	public var RG8UI = 0x8238;
	public var RG16I = 0x8239;
	public var RG16UI = 0x823A;
	public var RG32I = 0x823B;
	public var RG32UI = 0x823C;
	public var R8_SNORM = 0x8F94;
	public var RG8_SNORM = 0x8F95;
	public var RGB8_SNORM = 0x8F96;
	public var RGBA8_SNORM = 0x8F97;
	public var RGB10_A2UI = 0x906F;
	public var TEXTURE_IMMUTABLE_FORMAT = 0x912F;
	public var TEXTURE_IMMUTABLE_LEVELS = 0x82DF;
	public var UNSIGNED_INT_2_10_10_10_REV = 0x8368;
	public var UNSIGNED_INT_10F_11F_11F_REV = 0x8C3B;
	public var UNSIGNED_INT_5_9_9_9_REV = 0x8C3E;
	public var FLOAT_32_UNSIGNED_INT_24_8_REV = 0x8DAD;
	public var UNSIGNED_INT_24_8 = 0x84FA;
	public var HALF_FLOAT = 0x140B;
	public var RG = 0x8227;
	public var RG_INTEGER = 0x8228;
	public var INT_2_10_10_10_REV = 0x8D9F;
	public var CURRENT_QUERY = 0x8865;
	public var QUERY_RESULT = 0x8866;
	public var QUERY_RESULT_AVAILABLE = 0x8867;
	public var ANY_SAMPLES_PASSED = 0x8C2F;
	public var ANY_SAMPLES_PASSED_CONSERVATIVE = 0x8D6A;
	public var MAX_DRAW_BUFFERS = 0x8824;
	public var DRAW_BUFFER0 = 0x8825;
	public var DRAW_BUFFER1 = 0x8826;
	public var DRAW_BUFFER2 = 0x8827;
	public var DRAW_BUFFER3 = 0x8828;
	public var DRAW_BUFFER4 = 0x8829;
	public var DRAW_BUFFER5 = 0x882A;
	public var DRAW_BUFFER6 = 0x882B;
	public var DRAW_BUFFER7 = 0x882C;
	public var DRAW_BUFFER8 = 0x882D;
	public var DRAW_BUFFER9 = 0x882E;
	public var DRAW_BUFFER10 = 0x882F;
	public var DRAW_BUFFER11 = 0x8830;
	public var DRAW_BUFFER12 = 0x8831;
	public var DRAW_BUFFER13 = 0x8832;
	public var DRAW_BUFFER14 = 0x8833;
	public var DRAW_BUFFER15 = 0x8834;
	public var MAX_COLOR_ATTACHMENTS = 0x8CDF;
	public var COLOR_ATTACHMENT1 = 0x8CE1;
	public var COLOR_ATTACHMENT2 = 0x8CE2;
	public var COLOR_ATTACHMENT3 = 0x8CE3;
	public var COLOR_ATTACHMENT4 = 0x8CE4;
	public var COLOR_ATTACHMENT5 = 0x8CE5;
	public var COLOR_ATTACHMENT6 = 0x8CE6;
	public var COLOR_ATTACHMENT7 = 0x8CE7;
	public var COLOR_ATTACHMENT8 = 0x8CE8;
	public var COLOR_ATTACHMENT9 = 0x8CE9;
	public var COLOR_ATTACHMENT10 = 0x8CEA;
	public var COLOR_ATTACHMENT11 = 0x8CEB;
	public var COLOR_ATTACHMENT12 = 0x8CEC;
	public var COLOR_ATTACHMENT13 = 0x8CED;
	public var COLOR_ATTACHMENT14 = 0x8CEE;
	public var COLOR_ATTACHMENT15 = 0x8CEF;
	public var SAMPLER_3D = 0x8B5F;
	public var SAMPLER_2D_SHADOW = 0x8B62;
	public var SAMPLER_2D_ARRAY = 0x8DC1;
	public var SAMPLER_2D_ARRAY_SHADOW = 0x8DC4;
	public var SAMPLER_CUBE_SHADOW = 0x8DC5;
	public var INT_SAMPLER_2D = 0x8DCA;
	public var INT_SAMPLER_3D = 0x8DCB;
	public var INT_SAMPLER_CUBE = 0x8DCC;
	public var INT_SAMPLER_2D_ARRAY = 0x8DCF;
	public var UNSIGNED_INT_SAMPLER_2D = 0x8DD2;
	public var UNSIGNED_INT_SAMPLER_3D = 0x8DD3;
	public var UNSIGNED_INT_SAMPLER_CUBE = 0x8DD4;
	public var UNSIGNED_INT_SAMPLER_2D_ARRAY = 0x8DD7;
	public var MAX_SAMPLES = 0x8D57;
	public var SAMPLER_BINDING = 0x8919;
	public var PIXEL_PACK_BUFFER = 0x88EB;
	public var PIXEL_UNPACK_BUFFER = 0x88EC;
	public var PIXEL_PACK_BUFFER_BINDING = 0x88ED;
	public var PIXEL_UNPACK_BUFFER_BINDING = 0x88EF;
	public var COPY_READ_BUFFER = 0x8F36;
	public var COPY_WRITE_BUFFER = 0x8F37;
	public var COPY_READ_BUFFER_BINDING = 0x8F36;
	public var COPY_WRITE_BUFFER_BINDING = 0x8F37;
	public var FLOAT_MAT2x3 = 0x8B65;
	public var FLOAT_MAT2x4 = 0x8B66;
	public var FLOAT_MAT3x2 = 0x8B67;
	public var FLOAT_MAT3x4 = 0x8B68;
	public var FLOAT_MAT4x2 = 0x8B69;
	public var FLOAT_MAT4x3 = 0x8B6A;
	public var UNSIGNED_INT_VEC2 = 0x8DC6;
	public var UNSIGNED_INT_VEC3 = 0x8DC7;
	public var UNSIGNED_INT_VEC4 = 0x8DC8;
	public var UNSIGNED_NORMALIZED = 0x8C17;
	public var SIGNED_NORMALIZED = 0x8F9C;
	public var VERTEX_ATTRIB_ARRAY_INTEGER = 0x88FD;
	public var VERTEX_ATTRIB_ARRAY_DIVISOR = 0x88FE;
	public var TRANSFORM_FEEDBACK_BUFFER_MODE = 0x8C7F;
	public var MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS = 0x8C80;
	public var TRANSFORM_FEEDBACK_VARYINGS = 0x8C83;
	public var TRANSFORM_FEEDBACK_BUFFER_START = 0x8C84;
	public var TRANSFORM_FEEDBACK_BUFFER_SIZE = 0x8C85;
	public var TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN = 0x8C88;
	public var MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS = 0x8C8A;
	public var MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS = 0x8C8B;
	public var INTERLEAVED_ATTRIBS = 0x8C8C;
	public var SEPARATE_ATTRIBS = 0x8C8D;
	public var TRANSFORM_FEEDBACK_BUFFER = 0x8C8E;
	public var TRANSFORM_FEEDBACK_BUFFER_BINDING = 0x8C8F;
	public var TRANSFORM_FEEDBACK = 0x8E22;
	public var TRANSFORM_FEEDBACK_PAUSED = 0x8E23;
	public var TRANSFORM_FEEDBACK_ACTIVE = 0x8E24;
	public var TRANSFORM_FEEDBACK_BINDING = 0x8E25;
	public var FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING = 0x8210;
	public var FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE = 0x8211;
	public var FRAMEBUFFER_ATTACHMENT_RED_SIZE = 0x8212;
	public var FRAMEBUFFER_ATTACHMENT_GREEN_SIZE = 0x8213;
	public var FRAMEBUFFER_ATTACHMENT_BLUE_SIZE = 0x8214;
	public var FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE = 0x8215;
	public var FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE = 0x8216;
	public var FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE = 0x8217;
	public var FRAMEBUFFER_DEFAULT = 0x8218;
	public var DEPTH24_STENCIL8 = 0x88F0;
	public var DRAW_FRAMEBUFFER_BINDING = 0x8CA6;
	public var READ_FRAMEBUFFER = 0x8CA8;
	public var DRAW_FRAMEBUFFER = 0x8CA9;
	public var READ_FRAMEBUFFER_BINDING = 0x8CAA;
	public var RENDERBUFFER_SAMPLES = 0x8CAB;
	public var FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER = 0x8CD4;
	public var FRAMEBUFFER_INCOMPLETE_MULTISAMPLE = 0x8D56;
	public var UNIFORM_BUFFER = 0x8A11;
	public var UNIFORM_BUFFER_BINDING = 0x8A28;
	public var UNIFORM_BUFFER_START = 0x8A29;
	public var UNIFORM_BUFFER_SIZE = 0x8A2A;
	public var MAX_VERTEX_UNIFORM_BLOCKS = 0x8A2B;
	public var MAX_FRAGMENT_UNIFORM_BLOCKS = 0x8A2D;
	public var MAX_COMBINED_UNIFORM_BLOCKS = 0x8A2E;
	public var MAX_UNIFORM_BUFFER_BINDINGS = 0x8A2F;
	public var MAX_UNIFORM_BLOCK_SIZE = 0x8A30;
	public var MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS = 0x8A31;
	public var MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS = 0x8A33;
	public var UNIFORM_BUFFER_OFFSET_ALIGNMENT = 0x8A34;
	public var ACTIVE_UNIFORM_BLOCKS = 0x8A36;
	public var UNIFORM_TYPE = 0x8A37;
	public var UNIFORM_SIZE = 0x8A38;
	public var UNIFORM_BLOCK_INDEX = 0x8A3A;
	public var UNIFORM_OFFSET = 0x8A3B;
	public var UNIFORM_ARRAY_STRIDE = 0x8A3C;
	public var UNIFORM_MATRIX_STRIDE = 0x8A3D;
	public var UNIFORM_IS_ROW_MAJOR = 0x8A3E;
	public var UNIFORM_BLOCK_BINDING = 0x8A3F;
	public var UNIFORM_BLOCK_DATA_SIZE = 0x8A40;
	public var UNIFORM_BLOCK_ACTIVE_UNIFORMS = 0x8A42;
	public var UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES = 0x8A43;
	public var UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER = 0x8A44;
	public var UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER = 0x8A46;
	public var OBJECT_TYPE = 0x9112;
	public var SYNC_CONDITION = 0x9113;
	public var SYNC_STATUS = 0x9114;
	public var SYNC_FLAGS = 0x9115;
	public var SYNC_FENCE = 0x9116;
	public var SYNC_GPU_COMMANDS_COMPLETE = 0x9117;
	public var UNSIGNALED = 0x9118;
	public var SIGNALED = 0x9119;
	public var ALREADY_SIGNALED = 0x911A;
	public var TIMEOUT_EXPIRED = 0x911B;
	public var CONDITION_SATISFIED = 0x911C;
	public var WAIT_FAILED = 0x911D;
	public var SYNC_FLUSH_COMMANDS_BIT = 0x00000001;
	public var COLOR = 0x1800;
	public var DEPTH = 0x1801;
	public var STENCIL = 0x1802;
	public var MIN = 0x8007;
	public var MAX = 0x8008;
	public var DEPTH_COMPONENT24 = 0x81A6;
	public var STREAM_READ = 0x88E1;
	public var STREAM_COPY = 0x88E2;
	public var STATIC_READ = 0x88E5;
	public var STATIC_COPY = 0x88E6;
	public var DYNAMIC_READ = 0x88E9;
	public var DYNAMIC_COPY = 0x88EA;
	public var DEPTH_COMPONENT32F = 0x8CAC;
	public var DEPTH32F_STENCIL8 = 0x8CAD;
	public var INVALID_INDEX = 0xFFFFFFFF;
	public var TIMEOUT_IGNORED = -1;
	public var MAX_CLIENT_WAIT_TIMEOUT_WEBGL = 0x9247;
	public var type(default, null):RenderContextType;
	public var version(default, null):Float;

	private var __arrayBufferBinding:GLBuffer;
	private var __elementBufferBinding:GLBuffer;
	private var __contextID:Int;
	private var __currentProgram:GLProgram;
	private var __framebufferBinding:GLFramebuffer;
	private var __initialized:Bool;
	private var __isContextLost:Bool;
	private var __renderbufferBinding:GLRenderbuffer;
	private var __texture2DBinding:GLTexture;
	private var __textureCubeMapBinding:GLTexture;

	private function new()
	{
		__contextID = __lastContextID++;

		__initialize();

		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var versionString:String = getParameter(VERSION);
		if (versionString.indexOf("OpenGL ES") > -1)
		{
			type = OPENGLES;
		}
		else
		{
			type = OPENGL;
		}
		var ereg = ~/[0-9]+[.]?[0-9]?/i;
		if (ereg.match(versionString))
		{
			version = Std.parseFloat(ereg.matched(0));
		}
		else
		{
			version = 2;
		}
		#else
		type = OPENGL;
		version = 2;
		#end
	}

	public function activeTexture(texture:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_active_texture(texture);
		#end
	}

	public function attachShader(program:GLProgram, shader:GLShader):Void
	{
		if (program != null && shader != null)
		{
			if (program.refs == null)
			{
				program.refs = [shader];
			}
			else if (program.refs.indexOf(shader) == -1)
			{
				program.refs.push(shader);
			}
		}

		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_attach_shader(__getObjectID(program), __getObjectID(shader));
		#end
	}

	public function beginQuery(target:Int, query:GLQuery):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_begin_query(target, __getObjectID(query));
		#end
	}

	public function beginTransformFeedback(primitiveNode:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_begin_transform_feedback(primitiveNode);
		#end
	}

	public function bindAttribLocation(program:GLProgram, index:Int, name:String):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_bind_attrib_location(__getObjectID(program), index, name);
		#end
	}

	public function bindBuffer(target:Int, buffer:GLBuffer):Void
	{
		if (target == ARRAY_BUFFER) __arrayBufferBinding = buffer;
		if (target == ELEMENT_ARRAY_BUFFER) __elementBufferBinding = buffer;

		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_bind_buffer(target, __getObjectID(buffer));
		#end
	}

	public function bindBufferBase(target:Int, index:Int, buffer:GLBuffer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_bind_buffer_base(target, index, __getObjectID(buffer));
		#end
	}

	public function bindBufferRange(target:Int, index:Int, buffer:GLBuffer, offset:DataPointer, size:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_bind_buffer_range(target, index, __getObjectID(buffer), offset, size);
		#end
	}

	public function bindFramebuffer(target:Int, framebuffer:GLFramebuffer):Void
	{
		__framebufferBinding = framebuffer;

		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_bind_framebuffer(target, __getObjectID(framebuffer));
		#end
	}

	public function bindRenderbuffer(target:Int, renderbuffer:GLRenderbuffer):Void
	{
		__renderbufferBinding = renderbuffer;

		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_bind_renderbuffer(target, __getObjectID(renderbuffer));
		#end
	}

	public function bindSampler(unit:Int, sampler:GLSampler):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_bind_sampler(unit, __getObjectID(sampler));
		#end
	}

	public function bindTexture(target:Int, texture:GLTexture):Void
	{
		if (target == TEXTURE_2D) __texture2DBinding = texture;
		if (target == TEXTURE_CUBE_MAP) __textureCubeMapBinding = texture;

		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_bind_texture(target, __getObjectID(texture));
		#end
	}

	public function bindTransformFeedback(target:Int, transformFeedback:GLTransformFeedback):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_bind_transform_feedback(target, __getObjectID(transformFeedback));
		#end
	}

	public function bindVertexArray(vertexArray:GLVertexArrayObject):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_bind_vertex_array(__getObjectID(vertexArray));
		#end
	}

	public function blendColor(red:Float, green:Float, blue:Float, alpha:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_blend_color(red, green, blue, alpha);
		#end
	}

	public function blendEquation(mode:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_blend_equation(mode);
		#end
	}

	public function blendEquationSeparate(modeRGB:Int, modeAlpha:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_blend_equation_separate(modeRGB, modeAlpha);
		#end
	}

	public function blendFunc(sfactor:Int, dfactor:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_blend_func(sfactor, dfactor);
		#end
	}

	public function blendFuncSeparate(srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_blend_func_separate(srcRGB, dstRGB, srcAlpha, dstAlpha);
		#end
	}

	public function blitFramebuffer(srcX0:Int, srcY0:Int, srcX1:Int, srcY1:Int, dstX0:Int, dstY0:Int, dstX1:Int, dstY1:Int, mask:Int, filter:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_blit_framebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
		#end
	}

	public function bufferData(target:Int, size:Int, srcData:DataPointer, usage:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_buffer_data(target, size, srcData, usage);
		#end
	}

	public function bufferSubData(target:Int, dstByteOffset:Int, size:Int, srcData:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_buffer_sub_data(target, dstByteOffset, size, srcData);
		#end
	}

	public function checkFramebufferStatus(target:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_check_framebuffer_status(target);
		#else
		return 0;
		#end
	}

	public function clear(mask:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_clear(mask);
		#end
	}

	public function clearBufferfi(buffer:Int, drawbuffer:Int, depth:Float, stencil:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_clear_bufferfi(buffer, drawbuffer, depth, stencil);
		#end
	}

	public function clearBufferfv(buffer:Int, drawbuffer:Int, value:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_clear_bufferfv(buffer, drawbuffer, value);
		#end
	}

	public function clearBufferiv(buffer:Int, drawbuffer:Int, value:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_clear_bufferiv(buffer, drawbuffer, value);
		#end
	}

	public function clearBufferuiv(buffer:Int, drawbuffer:Int, value:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_clear_bufferuiv(buffer, drawbuffer, value);
		#end
	}

	public function clearColor(red:Float, green:Float, blue:Float, alpha:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_clear_color(red, green, blue, alpha);
		#end
	}

	public function clearDepthf(depth:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_clear_depthf(depth);
		#end
	}

	public function clearStencil(s:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_clear_stencil(s);
		#end
	}

	public function clientWaitSync(sync:GLSync, flags:Int, timeout:Int64):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_client_wait_sync(sync, flags, timeout.high, timeout.low);
		#else
		return 0;
		#end
	}

	public function colorMask(red:Bool, green:Bool, blue:Bool, alpha:Bool):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_color_mask(red, green, blue, alpha);
		#end
	}

	public function compileShader(shader:GLShader):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_compile_shader(__getObjectID(shader));
		#end
	}

	public function compressedTexImage2D(target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, imageSize:Int, data:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_compressed_tex_image_2d(target, level, internalformat, width, height, border, imageSize, data);
		#end
	}

	public function compressedTexImage3D(target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, imageSize:Int,
			data:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_compressed_tex_image_3d(target, level, internalformat, width, height, depth, border, imageSize, data);
		#end
	}

	public function compressedTexSubImage2D(target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, imageSize:Int,
			data:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_compressed_tex_sub_image_2d(target, level, xoffset, yoffset, width, height, format, imageSize, data);
		#end
	}

	public function compressedTexSubImage3D(target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int,
			imageSize:Int, data:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_compressed_tex_sub_image_3d(target, level, xoffset, yoffset, zoffset, width, height, depth, format, imageSize, data);
		#end
	}

	public function copyBufferSubData(readTarget:Int, writeTarget:Int, readOffset:DataPointer, writeOffset:DataPointer, size:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_copy_buffer_sub_data(readTarget, writeTarget, readOffset, writeOffset, size);
		#end
	}

	public function copyTexImage2D(target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_copy_tex_image_2d(target, level, internalformat, x, y, width, height, border);
		#end
	}

	public function copyTexSubImage2D(target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_copy_tex_sub_image_2d(target, level, xoffset, yoffset, x, y, width, height);
		#end
	}

	public function copyTexSubImage3D(target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, x:Int, y:Int, width:Int, height:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_copy_tex_sub_image_3d(target, level, xoffset, yoffset, zoffset, x, y, width, height);
		#end
	}

	public function createBuffer():GLBuffer
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var id = NativeCFFI.lime_gl_create_buffer();
		if (id == 0) return null;
		var object = new GLObject(id);
		object.ptr = NativeCFFI.lime_gl_object_register(id, GLObjectType.BUFFER, object);
		return object;
		#else
		return null;
		#end
	}

	public function createFramebuffer():GLFramebuffer
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var id = NativeCFFI.lime_gl_create_framebuffer();
		if (id == 0) return null;
		var object = new GLObject(id);
		object.ptr = NativeCFFI.lime_gl_object_register(id, GLObjectType.FRAMEBUFFER, object);
		return object;
		#else
		return null;
		#end
	}

	public function createProgram():GLProgram
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var id = NativeCFFI.lime_gl_create_program();
		if (id == 0) return null;
		var object = new GLObject(id);
		object.ptr = NativeCFFI.lime_gl_object_register(id, GLObjectType.PROGRAM, object);
		return object;
		#else
		return null;
		#end
	}

	public function createQuery():GLQuery
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var id = NativeCFFI.lime_gl_create_query();
		if (id == 0) return null;
		var object = new GLObject(id);
		object.ptr = NativeCFFI.lime_gl_object_register(id, GLObjectType.QUERY, object);
		return object;
		#else
		return null;
		#end
	}

	public function createRenderbuffer():GLRenderbuffer
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var id = NativeCFFI.lime_gl_create_renderbuffer();
		if (id == 0) return null;
		var object = new GLObject(id);
		object.ptr = NativeCFFI.lime_gl_object_register(id, GLObjectType.RENDERBUFFER, object);
		return object;
		#else
		return null;
		#end
	}

	public function createSampler():GLSampler
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var id = NativeCFFI.lime_gl_create_sampler();
		if (id == 0) return null;
		var object = new GLObject(id);
		object.ptr = NativeCFFI.lime_gl_object_register(id, GLObjectType.SAMPLER, object);
		return object;
		#else
		return null;
		#end
	}

	public function createShader(type:Int):GLShader
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var id = NativeCFFI.lime_gl_create_shader(type);
		if (id == 0) return null;
		var object = new GLObject(id);
		object.ptr = NativeCFFI.lime_gl_object_register(id, GLObjectType.SHADER, object);
		return object;
		#else
		return null;
		#end
	}

	public function createTexture():GLTexture
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var id = NativeCFFI.lime_gl_create_texture();
		if (id == 0) return null;
		var object = new GLObject(id);
		object.ptr = NativeCFFI.lime_gl_object_register(id, GLObjectType.TEXTURE, object);
		return object;
		#else
		return null;
		#end
	}

	public function createTransformFeedback():GLTransformFeedback
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var id = NativeCFFI.lime_gl_create_transform_feedback();
		if (id == 0) return null;
		var object = new GLObject(id);
		object.ptr = NativeCFFI.lime_gl_object_register(id, GLObjectType.TRANSFORM_FEEDBACK, object);
		return object;
		#else
		return null;
		#end
	}

	public function createVertexArray():GLVertexArrayObject
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var id = NativeCFFI.lime_gl_create_vertex_array();
		if (id == 0) return null;
		var object = new GLObject(id);
		object.ptr = NativeCFFI.lime_gl_object_register(id, GLObjectType.VERTEX_ARRAY_OBJECT, object);
		return object;
		#else
		return null;
		#end
	}

	public function cullFace(mode:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_cull_face(mode);
		#end
	}

	public function deleteBuffer(buffer:GLBuffer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		if (buffer != null) NativeCFFI.lime_gl_object_deregister(buffer);
		NativeCFFI.lime_gl_delete_buffer(__getObjectID(buffer));
		#end
	}

	public function deleteFramebuffer(framebuffer:GLFramebuffer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		if (framebuffer != null) NativeCFFI.lime_gl_object_deregister(framebuffer);
		NativeCFFI.lime_gl_delete_framebuffer(__getObjectID(framebuffer));
		#end
	}

	public function deleteProgram(program:GLProgram):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		if (program != null) NativeCFFI.lime_gl_object_deregister(program);
		NativeCFFI.lime_gl_delete_program(__getObjectID(program));
		#end
	}

	public function deleteQuery(query:GLQuery):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		if (query != null) NativeCFFI.lime_gl_object_deregister(query);
		NativeCFFI.lime_gl_delete_query(__getObjectID(query));
		#end
	}

	public function deleteRenderbuffer(renderbuffer:GLRenderbuffer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		if (renderbuffer != null) NativeCFFI.lime_gl_object_deregister(renderbuffer);
		NativeCFFI.lime_gl_delete_renderbuffer(__getObjectID(renderbuffer));
		#end
	}

	public function deleteSampler(sampler:GLSampler):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		if (sampler != null) NativeCFFI.lime_gl_object_deregister(sampler);
		NativeCFFI.lime_gl_delete_sampler(__getObjectID(sampler));
		#end
	}

	public function deleteShader(shader:GLShader):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		if (shader != null) NativeCFFI.lime_gl_object_deregister(shader);
		NativeCFFI.lime_gl_delete_shader(__getObjectID(shader));
		#end
	}

	public function deleteSync(sync:GLSync):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_delete_sync(sync);
		#end
	}

	public function deleteTexture(texture:GLTexture):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		if (texture != null) NativeCFFI.lime_gl_object_deregister(texture);
		NativeCFFI.lime_gl_delete_texture(__getObjectID(texture));
		#end
	}

	public function deleteTransformFeedback(transformFeedback:GLTransformFeedback):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		if (transformFeedback != null) NativeCFFI.lime_gl_object_deregister(transformFeedback);
		NativeCFFI.lime_gl_delete_transform_feedback(__getObjectID(transformFeedback));
		#end
	}

	public function deleteVertexArray(vertexArray:GLVertexArrayObject):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		if (vertexArray != null) NativeCFFI.lime_gl_object_deregister(vertexArray);
		NativeCFFI.lime_gl_delete_vertex_array(__getObjectID(vertexArray));
		#end
	}

	public function depthFunc(func:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_depth_func(func);
		#end
	}

	public function depthMask(flag:Bool):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_depth_mask(flag);
		#end
	}

	public function depthRangef(zNear:Float, zFar:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_depth_rangef(zNear, zFar);
		#end
	}

	public function detachShader(program:GLProgram, shader:GLShader):Void
	{
		if (program != null && program.refs != null)
		{
			program.refs.remove(shader);
		}

		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_detach_shader(__getObjectID(program), __getObjectID(shader));
		#end
	}

	public function disable(cap:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_disable(cap);
		#end
	}

	public function disableVertexAttribArray(index:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_disable_vertex_attrib_array(index);
		#end
	}

	public function drawArrays(mode:Int, first:Int, count:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_draw_arrays(mode, first, count);
		#end
	}

	public function drawArraysInstanced(mode:Int, first:Int, count:Int, instanceCount:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_draw_arrays_instanced(mode, first, count, instanceCount);
		#end
	}

	public function drawBuffers(buffers:Array<Int>):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		#if hl
		var _buffers = new hl.NativeArray<Int>(buffers.length);
		for (i in 0...buffers.length)
			_buffers[i] = buffers[i];
		var buffers = _buffers;
		#end
		NativeCFFI.lime_gl_draw_buffers(buffers);
		#end
	}

	public function drawElements(mode:Int, count:Int, type:Int, offset:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_draw_elements(mode, count, type, offset);
		#end
	}

	public function drawElementsInstanced(mode:Int, count:Int, type:Int, offset:DataPointer, instanceCount:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_draw_elements_instanced(mode, count, type, offset, instanceCount);
		#end
	}

	public function drawRangeElements(mode:Int, start:Int, end:Int, count:Int, type:Int, offset:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_draw_range_elements(mode, start, end, count, type, offset);
		#end
	}

	public function enable(cap:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_enable(cap);
		#end
	}

	public function enableVertexAttribArray(index:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_enable_vertex_attrib_array(index);
		#end
	}

	public function endQuery(target:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_end_query(target);
		#end
	}

	public function endTransformFeedback():Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_end_transform_feedback();
		#end
	}

	public function fenceSync(condition:Int, flags:Int):GLSync
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_fence_sync(condition, flags);
		#else
		return null;
		#end
	}

	public function finish():Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_finish();
		#end
	}

	public function flush():Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_flush();
		#end
	}

	public function framebufferRenderbuffer(target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:GLRenderbuffer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_framebuffer_renderbuffer(target, attachment, renderbuffertarget, __getObjectID(renderbuffer));
		#end
	}

	public function framebufferTexture2D(target:Int, attachment:Int, textarget:Int, texture:GLTexture, level:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_framebuffer_texture2D(target, attachment, textarget, __getObjectID(texture), level);
		#end
	}

	public function framebufferTextureLayer(target:Int, attachment:Int, texture:GLTexture, level:Int, layer:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_framebuffer_texture_layer(target, attachment, __getObjectID(texture), level, layer);
		#end
	}

	public function frontFace(mode:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_front_face(mode);
		#end
	}

	public function generateMipmap(target:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_generate_mipmap(target);
		#end
	}

	public function getActiveAttrib(program:GLProgram, index:Int):GLActiveInfo
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		#if hl
		var result = NativeCFFI.lime_gl_get_active_attrib(__getObjectID(program), index);
		if (result != null)
		{
			return {
				size: result.size,
				type: result.type,
				name: @:privateAccess String.fromUTF8(result.name)
			};
		}
		else
		{
			return null;
		}
		#else
		return NativeCFFI.lime_gl_get_active_attrib(__getObjectID(program), index);
		#end
		#else
		return null;
		#end
	}

	public function getActiveUniform(program:GLProgram, index:Int):GLActiveInfo
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		#if hl
		var result = NativeCFFI.lime_gl_get_active_uniform(__getObjectID(program), index);
		if (result != null)
		{
			return {
				size: result.size,
				type: result.type,
				name: @:privateAccess String.fromUTF8(result.name)
			};
		}
		else
		{
			return null;
		}
		#else
		return NativeCFFI.lime_gl_get_active_uniform(__getObjectID(program), index);
		#end
		#else
		return null;
		#end
	}

	public function getActiveUniformBlocki(program:GLProgram, uniformBlockIndex:Int, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_active_uniform_blocki(__getObjectID(program), uniformBlockIndex, pname);
		#else
		return 0;
		#end
	}

	public function getActiveUniformBlockiv(program:GLProgram, uniformBlockIndex:Int, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_active_uniform_blockiv(__getObjectID(program), uniformBlockIndex, pname, params);
		#end
	}

	public function getActiveUniformBlockName(program:GLProgram, uniformBlockIndex:Int):String
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var result = NativeCFFI.lime_gl_get_active_uniform_block_name(__getObjectID(program), uniformBlockIndex);
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public function getActiveUniformBlockParameter(program:GLProgram, uniformBlockIndex:Int, pname:Int):Dynamic
	{
		// TODO

		return null;
	}

	public function getActiveUniforms(program:GLProgram, uniformIndices:Array<Int>, pname:Int):Dynamic
	{
		// TODO

		return null;
	}

	public function getActiveUniformsiv(program:GLProgram, uniformIndices:Array<Int>, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		#if hl
		var _uniformIndices = new hl.NativeArray<Int>(uniformIndices.length);
		for (i in 0...uniformIndices.length)
			_uniformIndices[i] = uniformIndices[i];
		var uniformIndices = _uniformIndices;
		#end
		NativeCFFI.lime_gl_get_active_uniformsiv(__getObjectID(program), uniformIndices, pname, params);
		#end
	}

	public function getAttachedShaders(program:GLProgram):Array<GLShader>
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var result = NativeCFFI.lime_gl_get_attached_shaders(__getObjectID(program));
		#if hl
		var _result = new Array();
		for (i in 0...result.length)
		{
			_result.push(GLShader.fromInt(result[i]));
		}
		var result = _result;
		#end
		return result;
		#else
		return null;
		#end
	}

	public function getAttribLocation(program:GLProgram, name:String):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_attrib_location(__getObjectID(program), name);
		#else
		return 0;
		#end
	}

	public function getBoolean(pname:Int):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_boolean(pname);
		#else
		return false;
		#end
	}

	public function getBooleanv(pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_booleanv(pname, params);
		#end
	}

	public function getBufferParameter(target:Int, pname:Int):Dynamic
	{
		return getBufferParameteri(target, pname);
	}

	public function getBufferParameteri(target:Int, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_buffer_parameteri(target, pname);
		#else
		return 0;
		#end
	}

	public function getBufferParameteri64v(target:Int, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_buffer_parameteri64v(target, pname, params);
		#end
	}

	public function getBufferParameteriv(target:Int, pname:Int, data:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_buffer_parameteriv(target, pname, data);
		#end
	}

	public function getBufferPointerv(target:Int, pname:Int):DataPointer
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_buffer_pointerv(target, pname);
		#else
		return 0;
		#end
	}

	public function getBufferSubData(target:Int, offset:DataPointer, size:Int, data:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_buffer_sub_data(target, offset, size, data);
		#end
	}

	public function getContextAttributes():GLContextAttributes
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var base:Dynamic = NativeCFFI.lime_gl_get_context_attributes();
		base.premultipliedAlpha = false;
		base.preserveDrawingBuffer = false;
		return base;
		#else
		return null;
		#end
	}

	public function getError():Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_error();
		#else
		return 0;
		#end
	}

	public function getExtension(name:String):Dynamic
	{
		if (__extensionObjects == null)
		{
			__extensionObjects = new Map();
			var supportedExtensions = getSupportedExtensions();

			for (extension in supportedExtensions)
			{
				if (__extensionObjectConstructors.exists(extension))
				{
					__extensionObjects.set(extension, null);
				}
			}
		}

		if (__extensionObjects.exists(name))
		{
			var object = __extensionObjects.get(name);

			if (object == null)
			{
				object = __extensionObjectConstructors.get(name)();
				__extensionObjects.set(name, object);

				#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
				NativeCFFI.lime_gl_get_extension(name);
				#end
			}

			return object;
		}
		else
		{
			return null;
		}
	}

	public function getFloat(pname:Int):Float
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_float(pname);
		#else
		return 0;
		#end
	}

	public function getFloatv(pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_floatv(pname, params);
		#end
	}

	public function getFragDataLocation(program:GLProgram, name:String):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_frag_data_location(__getObjectID(program), name);
		#else
		return 0;
		#end
	}

	public function getFramebufferAttachmentParameter(target:Int, attachment:Int, pname:Int):Dynamic
	{
		var value = getFramebufferAttachmentParameteri(target, attachment, pname);

		if (pname == FRAMEBUFFER_ATTACHMENT_OBJECT_NAME)
		{
			var texture:GLTexture = value;
			if (texture != null) return texture;

			var renderbuffer:GLRenderbuffer = value;
			if (renderbuffer != null) return renderbuffer;
		}

		return value;
	}

	public function getFramebufferAttachmentParameteri(target:Int, attachment:Int, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_framebuffer_attachment_parameteri(target, attachment, pname);
		#else
		return 0;
		#end
	}

	public function getFramebufferAttachmentParameteriv(target:Int, attachment:Int, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_framebuffer_attachment_parameteriv(target, attachment, pname, params);
		#end
	}

	public function getIndexedParameter(target:Int, index:Int):Dynamic
	{
		// TODO

		return null;
	}

	public function getInteger(pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_integer(pname);
		#else
		return 0;
		#end
	}

	public function getInteger64(pname:Int):Int64
	{
		// TODO

		// #if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		// return NativeCFFI.lime_gl_get_integer64 (pname);
		// #else
		return Int64.ofInt(0);
		// #end
	}

	public function getInteger64i(pname:Int):Int64
	{
		// TODO

		// #if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		// return NativeCFFI.lime_gl_get_integer64i (pname);
		// #else
		return Int64.ofInt(0);
		// #end
	}

	public function getInteger64i_v(pname:Int, index:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_integer64i_v(pname, index, params);
		#end
	}

	public function getInteger64v(pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_integer64v(pname, params);
		#end
	}

	public function getIntegeri_v(pname:Int, index:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_integeri_v(pname, index, params);
		#end
	}

	public function getIntegerv(pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_integerv(pname, params);
		#end
	}

	public function getInternalformati(target:Int, internalformat:Int, pname:Int):Int
	{
		// TODO

		// #if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		// return NativeCFFI.lime_gl_get_internalformati (target, internalformat, pname);
		// #else
		return 0;
		// #end
	}

	public function getInternalformativ(target:Int, internalformat:Int, pname:Int, bufSize:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_internalformativ(target, internalformat, pname, bufSize, params);
		#end
	}

	public function getInternalformatParameter(target:Int, internalformat:Int, pname:Int):Dynamic
	{
		// TODO

		return null;
	}

	public function getParameter(pname:Int):Dynamic
	{
		switch (pname)
		{
			case GL.BLEND, GL.CULL_FACE, GL.DEPTH_TEST, GL.DEPTH_WRITEMASK, GL.DITHER, GL.POLYGON_OFFSET_FILL, GL.SAMPLE_COVERAGE_INVERT, GL.SCISSOR_TEST,
				GL.STENCIL_TEST, GL.UNPACK_FLIP_Y_WEBGL, GL.UNPACK_PREMULTIPLY_ALPHA_WEBGL:
				return getBoolean(pname);

			case GL.COLOR_WRITEMASK:
				var params = Bytes.alloc(4);
				getBooleanv(pname, params);

				var data = new Array<Bool>();
				for (i in 0...4)
					data[i] = params.get(i) != 0;
				return data;

			case GL.DEPTH_CLEAR_VALUE, GL.LINE_WIDTH, GL.POLYGON_OFFSET_FACTOR, GL.POLYGON_OFFSET_UNITS, GL.SAMPLE_COVERAGE_VALUE:
				return getFloat(pname);

			case GL.ALIASED_LINE_WIDTH_RANGE, GL.ALIASED_POINT_SIZE_RANGE, GL.DEPTH_RANGE:
				var params = new Float32Array(2);
				getFloatv(pname, params);
				return params;

			case GL.BLEND_COLOR, GL.COLOR_CLEAR_VALUE:
				var params = new Float32Array(4);
				getFloatv(pname, params);
				return params;

			case GL.ACTIVE_TEXTURE, GL.ALPHA_BITS, GL.BLEND_DST_ALPHA, GL.BLEND_DST_RGB, GL.BLEND_EQUATION, GL.BLEND_EQUATION_ALPHA,
				/*GL.BLEND_EQUATION_RGB,*/ GL.BLEND_SRC_ALPHA, GL.BLEND_SRC_RGB, GL.BLUE_BITS, GL.CULL_FACE_MODE, GL.DEPTH_BITS, GL.DEPTH_FUNC, GL.FRONT_FACE,
				GL.GENERATE_MIPMAP_HINT, GL.GREEN_BITS, GL.IMPLEMENTATION_COLOR_READ_FORMAT, GL.IMPLEMENTATION_COLOR_READ_TYPE,
				GL.MAX_COMBINED_TEXTURE_IMAGE_UNITS, GL.MAX_CUBE_MAP_TEXTURE_SIZE, GL.MAX_FRAGMENT_UNIFORM_VECTORS, GL.MAX_RENDERBUFFER_SIZE,
				GL.MAX_TEXTURE_IMAGE_UNITS, GL.MAX_TEXTURE_SIZE, GL.MAX_VARYING_VECTORS, GL.MAX_VERTEX_ATTRIBS, GL.MAX_VERTEX_TEXTURE_IMAGE_UNITS,
				GL.MAX_VERTEX_UNIFORM_VECTORS, GL.PACK_ALIGNMENT, GL.RED_BITS, GL.SAMPLE_BUFFERS, GL.SAMPLES, GL.STENCIL_BACK_FAIL, GL.STENCIL_BACK_FUNC,
				GL.STENCIL_BACK_PASS_DEPTH_FAIL, GL.STENCIL_BACK_PASS_DEPTH_PASS, GL.STENCIL_BACK_REF, GL.STENCIL_BACK_VALUE_MASK, GL.STENCIL_BACK_WRITEMASK,
				GL.STENCIL_BITS, GL.STENCIL_CLEAR_VALUE, GL.STENCIL_FAIL, GL.STENCIL_FUNC, GL.STENCIL_PASS_DEPTH_FAIL, GL.STENCIL_PASS_DEPTH_PASS,
				GL.STENCIL_REF, GL.STENCIL_VALUE_MASK, GL.STENCIL_WRITEMASK, GL.SUBPIXEL_BITS, GL.UNPACK_ALIGNMENT, GL.UNPACK_COLORSPACE_CONVERSION_WEBGL:
				return getInteger(pname);

			case GL.COMPRESSED_TEXTURE_FORMATS:
				var params = new UInt32Array(getInteger(GL.NUM_COMPRESSED_TEXTURE_FORMATS));
				getIntegerv(pname, params);
				return params;

			case GL.MAX_VIEWPORT_DIMS:
				var params = new Int32Array(2);
				getIntegerv(pname, params);
				return params;

			case GL.SCISSOR_BOX, GL.VIEWPORT:
				var params = new Int32Array(4);
				getIntegerv(pname, params);
				return params;

			case GL.RENDERER, GL.SHADING_LANGUAGE_VERSION, GL.VENDOR, GL.VERSION:
				return getString(pname);

			case GL.ARRAY_BUFFER_BINDING, GL.ELEMENT_ARRAY_BUFFER_BINDING:
				var data:GLBuffer = getInteger(pname);
				return data;

			case GL.CURRENT_PROGRAM:
				var data:GLProgram = getInteger(pname);
				return data;

			case GL.FRAMEBUFFER_BINDING:
				var data:GLFramebuffer = getInteger(pname);
				return data;

			case GL.RENDERBUFFER_BINDING:
				var data:GLRenderbuffer = getInteger(pname);
				return data;

			case GL.TEXTURE_BINDING_2D, GL.TEXTURE_BINDING_CUBE_MAP:
				var data:GLTexture = getInteger(pname);
				return data;

			default:
				return getInteger(pname);
				// return null;
		}
	}

	public function getProgrami(program:GLProgram, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_programi(__getObjectID(program), pname);
		#else
		return 0;
		#end
	}

	public function getProgramiv(program:GLProgram, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_programiv(__getObjectID(program), pname, params);
		#end
	}

	public function getProgramBinary(program:GLProgram, binaryFormat:Int):Bytes
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var bytes = Bytes.alloc(0);
		NativeCFFI.lime_gl_get_program_binary(__getObjectID(program), binaryFormat, bytes);
		return bytes;
		#else
		return null;
		#end
	}

	public function getProgramInfoLog(program:GLProgram):String
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var result = NativeCFFI.lime_gl_get_program_info_log(__getObjectID(program));
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public function getProgramParameter(program:GLProgram, pname:Int):Dynamic
	{
		return getProgrami(program, pname);
	}

	public function getQuery(target:Int, pname:Int):GLQuery
	{
		return getQueryi(target, pname);
	}

	public function getQueryi(target:Int, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_queryi(target, pname);
		#else
		return 0;
		#end
	}

	public function getQueryiv(target:Int, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_queryiv(target, pname, params);
		#end
	}

	public function getQueryObjectui(query:GLQuery, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_query_objectui(__getObjectID(query), pname);
		#else
		return 0;
		#end
	}

	public function getQueryObjectuiv(query:GLQuery, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_query_objectuiv(__getObjectID(query), pname, params);
		#end
	}

	public function getQueryParameter(query:GLQuery, pname:Int):Dynamic
	{
		// TODO

		return null;
	}

	public function getRenderbufferParameter(target:Int, pname:Int):Dynamic
	{
		return getRenderbufferParameteri(target, pname);
	}

	public function getRenderbufferParameteri(target:Int, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_renderbuffer_parameteri(target, pname);
		#else
		return 0;
		#end
	}

	public function getRenderbufferParameteriv(target:Int, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_renderbuffer_parameteriv(target, pname, params);
		#end
	}

	public function getSamplerParameter(sampler:GLSampler, pname:Int):Dynamic
	{
		// TODO

		return null;
	}

	public function getSamplerParameterf(sampler:GLSampler, pname:Int):Float
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_sampler_parameterf(__getObjectID(sampler), pname);
		#else
		return 0;
		#end
	}

	public function getSamplerParameterfv(sampler:GLSampler, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_sampler_parameterfv(__getObjectID(sampler), pname, params);
		#end
	}

	public function getSamplerParameteri(sampler:GLSampler, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_sampler_parameteri(__getObjectID(sampler), pname);
		#else
		return 0;
		#end
	}

	public function getSamplerParameteriv(sampler:GLSampler, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_sampler_parameteriv(__getObjectID(sampler), pname, params);
		#end
	}

	public function getShaderi(shader:GLShader, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_shaderi(__getObjectID(shader), pname);
		#else
		return 0;
		#end
	}

	public function getShaderiv(shader:GLShader, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_shaderiv(__getObjectID(shader), pname, params);
		#end
	}

	public function getShaderInfoLog(shader:GLShader):String
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var result = NativeCFFI.lime_gl_get_shader_info_log(__getObjectID(shader));
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public function getShaderParameter(shader:GLShader, pname:Int):Dynamic
	{
		return getShaderi(shader, pname);
	}

	public function getShaderPrecisionFormat(shadertype:Int, precisiontype:Int):GLShaderPrecisionFormat
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_shader_precision_format(shadertype, precisiontype);
		#else
		return null;
		#end
	}

	public function getShaderSource(shader:GLShader):String
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var result = NativeCFFI.lime_gl_get_shader_source(__getObjectID(shader));
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public function getString(name:Int):String
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var result = NativeCFFI.lime_gl_get_string(name);
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public function getStringi(name:Int, index:Int):String
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		var result = NativeCFFI.lime_gl_get_stringi(name, index);
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public function getSupportedExtensions():Array<String>
	{
		if (__supportedExtensions == null)
		{
			// TODO: getStringi for newer GL versions

			__supportedExtensions = new Array<String>();
			var extensions = getString(GL.EXTENSIONS);

			if (extensions != null)
			{
				var extensionList = extensions.split(" ");

				for (extension in extensionList)
				{
					if (StringTools.startsWith(extension, "GL_"))
					{
						__supportedExtensions.push(extension.substr(3));
					}
					else
					{
						__supportedExtensions.push(extension);
					}
				}
			}
		}

		return __supportedExtensions;
	}

	public function getSyncParameter(sync:GLSync, pname:Int):Dynamic
	{
		// TODO

		return null;
	}

	public function getSyncParameteri(sync:GLSync, pname:Int):Int
	{
		// TODO

		return 0;
	}

	public function getSyncParameteriv(sync:GLSync, pname:Int, params:DataPointer):Void
	{
		// TODO
	}

	public function getTexParameter(target:Int, pname:Int):Dynamic
	{
		switch (pname)
		{
			case GL.TEXTURE_MAX_LOD, GL.TEXTURE_MIN_LOD:
				return getTexParameterf(target, pname);

			case GL.TEXTURE_IMMUTABLE_FORMAT:
				return getTexParameterf(target, pname) != 0;

			default:
				return getTexParameteri(target, pname);
		}
	}

	public function getTexParameterf(target:Int, pname:Int):Float
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_tex_parameterf(target, pname);
		#else
		return 0;
		#end
	}

	public function getTexParameterfv(target:Int, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_tex_parameterfv(target, pname, params);
		#end
	}

	public function getTexParameteri(target:Int, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_tex_parameteri(target, pname);
		#else
		return 0;
		#end
	}

	public function getTexParameteriv(target:Int, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_tex_parameteriv(target, pname, params);
		#end
	}

	public function getTransformFeedbackVarying(program:GLProgram, index:Int):GLActiveInfo
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		#if hl
		var result = NativeCFFI.lime_gl_get_transform_feedback_varying(__getObjectID(program), index);
		if (result != null)
		{
			return {
				size: result.size,
				type: result.type,
				name: @:privateAccess String.fromUTF8(result.name)
			};
		}
		else
		{
			return null;
		}
		#else
		var result:Dynamic = NativeCFFI.lime_gl_get_transform_feedback_varying(__getObjectID(program), index);
		return result;
		#end
		#else
		return null;
		#end
	}

	public function getUniform(program:GLProgram, location:GLUniformLocation):Dynamic
	{
		var info = getActiveUniform(program, location);

		var bools = 0;
		var ints = 0;
		var floats = 0;

		switch (info.type)
		{
			case GL.BOOL:
				bools = 1;
			case GL.INT:
				ints = 1;
			case GL.FLOAT:
				floats = 1;
			case GL.FLOAT_VEC2:
				floats = 2;
			case GL.INT_VEC2:
				ints = 2;
			case GL.BOOL_VEC2:
				bools = 2;
			case GL.FLOAT_VEC3:
				floats = 3;
			case GL.INT_VEC3:
				ints = 3;
			case GL.BOOL_VEC3:
				bools = 3;
			case GL.FLOAT_VEC4:
				floats = 4;
			case GL.INT_VEC4:
				ints = 4;
			case GL.BOOL_VEC4:
				bools = 4;
			case GL.FLOAT_MAT2:
				floats = 4;
			case GL.FLOAT_MAT2x3:
				floats = 12;
			case GL.FLOAT_MAT2x4:
				floats = 16;
			case GL.FLOAT_MAT3:
				floats = 9;
			case GL.FLOAT_MAT3x2:
				floats = 18;
			case GL.FLOAT_MAT3x4:
				floats = 36;
			case GL.FLOAT_MAT4:
				floats = 16;
			case GL.FLOAT_MAT4x2:
				floats = 32;
			case GL.FLOAT_MAT4x3:
				floats = 48;
			case GL.SAMPLER_2D, GL.SAMPLER_3D, GL.SAMPLER_CUBE, GL.SAMPLER_2D_SHADOW:
				ints = 1;
			default:
				return null;
		}

		if (bools == 1)
		{
			return getUniformi(program, location) != 0;
		}
		else if (ints == 1)
		{
			return getUniformi(program, location);
		}
		else if (floats == 1)
		{
			return getUniformf(program, location);
		}
		else if (bools > 0)
		{
			var params = Bytes.alloc(bools);
			getUniformiv(program, location, params);

			var data = new Array<Bool>();

			for (i in 0...bools)
			{
				data[i] = params.get(i) != 0;
			}

			return data;
		}
		else if (ints > 0)
		{
			var params = new Int32Array(ints);
			getUniformiv(program, location, params);
			return params;
		}
		else if (floats > 0)
		{
			var params = new Float32Array(floats);
			getUniformfv(program, location, params);
			return params;
		}
		else
		{
			return null;
		}
	}

	public function getUniformf(program:GLProgram, location:GLUniformLocation):Float
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_uniformf(__getObjectID(program), location);
		#else
		return 0;
		#end
	}

	public function getUniformfv(program:GLProgram, location:GLUniformLocation, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_uniformfv(__getObjectID(program), location, params);
		#end
	}

	public function getUniformi(program:GLProgram, location:GLUniformLocation):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_uniformi(__getObjectID(program), location);
		#else
		return 0;
		#end
	}

	public function getUniformiv(program:GLProgram, location:GLUniformLocation, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_uniformiv(__getObjectID(program), location, params);
		#end
	}

	public function getUniformui(program:GLProgram, location:GLUniformLocation):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_uniformui(__getObjectID(program), location);
		#else
		return 0;
		#end
	}

	public function getUniformuiv(program:GLProgram, location:GLUniformLocation, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_uniformuiv(__getObjectID(program), location, params);
		#end
	}

	public function getUniformBlockIndex(program:GLProgram, uniformBlockName:String):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_uniform_block_index(__getObjectID(program), uniformBlockName);
		#else
		return 0;
		#end
	}

	public function getUniformIndices(program:GLProgram, uniformNames:Array<String>):Array<Int>
	{
		// TODO

		return null;
	}

	public function getUniformLocation(program:GLProgram, name:String):GLUniformLocation
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_uniform_location(__getObjectID(program), name);
		#else
		return 0;
		#end
	}

	public function getVertexAttrib(index:Int, pname:Int):Dynamic
	{
		return getVertexAttribi(index, pname);
	}

	public function getVertexAttribf(index:Int, pname:Int):Float
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_vertex_attribf(index, pname);
		#else
		return 0;
		#end
	}

	public function getVertexAttribfv(index:Int, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_vertex_attribfv(index, pname, params);
		#end
	}

	public function getVertexAttribi(index:Int, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_vertex_attribi(index, pname);
		#else
		return 0;
		#end
	}

	public function getVertexAttribIi(index:Int, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_vertex_attribii(index, pname);
		#else
		return 0;
		#end
	}

	public function getVertexAttribIiv(index:Int, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_vertex_attribiiv(index, pname, params);
		#end
	}

	public function getVertexAttribIui(index:Int, pname:Int):Int
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_vertex_attribiui(index, pname);
		#else
		return 0;
		#end
	}

	public function getVertexAttribIuiv(index:Int, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_vertex_attribiuiv(index, pname, params);
		#end
	}

	public function getVertexAttribiv(index:Int, pname:Int, params:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_get_vertex_attribiv(index, pname, params);
		#end
	}

	public function getVertexAttribPointerv(index:Int, pname:Int):DataPointer
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_get_vertex_attrib_pointerv(index, pname);
		#else
		return 0;
		#end
	}

	public function hint(target:Int, mode:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_hint(target, mode);
		#end
	}

	public function invalidateFramebuffer(target:Int, attachments:Array<Int>):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		#if hl
		var _attachments = new hl.NativeArray<Int>(attachments.length);
		for (i in 0...attachments.length)
			_attachments[i] = attachments[i];
		var attachments = _attachments;
		#end
		NativeCFFI.lime_gl_invalidate_framebuffer(target, attachments);
		#end
	}

	public function invalidateSubFramebuffer(target:Int, attachments:Array<Int>, x:Int, y:Int, width:Int, height:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		#if hl
		var _attachments = new hl.NativeArray<Int>(attachments.length);
		for (i in 0...attachments.length)
			_attachments[i] = attachments[i];
		var attachments = _attachments;
		#end
		NativeCFFI.lime_gl_invalidate_sub_framebuffer(target, attachments, x, y, width, height);
		#end
	}

	public function isBuffer(buffer:GLBuffer):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_is_buffer(__getObjectID(buffer));
		#else
		return false;
		#end
	}

	public function isContextLost():Bool
	{
		return __isContextLost;
	}

	public function isEnabled(cap:Int):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_is_enabled(cap);
		#else
		return false;
		#end
	}

	public function isFramebuffer(framebuffer:GLFramebuffer):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_is_framebuffer(__getObjectID(framebuffer));
		#else
		return false;
		#end
	}

	public function isProgram(program:GLProgram):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_is_program(__getObjectID(program));
		#else
		return false;
		#end
	}

	public function isQuery(query:GLQuery):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_is_query(__getObjectID(query));
		#else
		return false;
		#end
	}

	public function isRenderbuffer(renderbuffer:GLRenderbuffer):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_is_renderbuffer(__getObjectID(renderbuffer));
		#else
		return false;
		#end
	}

	public function isSampler(sampler:GLSampler):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_is_sampler(__getObjectID(sampler));
		#else
		return false;
		#end
	}

	public function isShader(shader:GLShader):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_is_shader(__getObjectID(shader));
		#else
		return false;
		#end
	}

	public function isSync(sync:GLSync):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_is_sync(sync);
		#else
		return false;
		#end
	}

	public function isTexture(texture:GLTexture):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_is_texture(__getObjectID(texture));
		#else
		return false;
		#end
	}

	public function isTransformFeedback(transformFeedback:GLTransformFeedback):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_is_transform_feedback(__getObjectID(transformFeedback));
		#else
		return false;
		#end
	}

	public function isVertexArray(vertexArray:GLVertexArrayObject):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_is_vertex_array(__getObjectID(vertexArray));
		#else
		return false;
		#end
	}

	public function lineWidth(width:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_line_width(width);
		#end
	}

	public function linkProgram(program:GLProgram):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_link_program(__getObjectID(program));
		#end
	}

	public function mapBufferRange(target:Int, offset:DataPointer, length:Int, access:Int):DataPointer
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_map_buffer_range(target, offset, length, access);
		#else
		return 0;
		#end
	}

	public function pauseTransformFeedback():Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_pause_transform_feedback();
		#end
	}

	public function pixelStorei(pname:Int, param:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_pixel_storei(pname, param);
		#end
	}

	public function polygonOffset(factor:Float, units:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_polygon_offset(factor, units);
		#end
	}

	public function programBinary(program:GLProgram, binaryFormat:Int, binary:DataPointer, length:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_program_binary(__getObjectID(program), binaryFormat, binary, length);
		#end
	}

	public function programParameteri(program:GLProgram, pname:Int, value:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_program_parameteri(__getObjectID(program), pname, value);
		#end
	}

	public function readBuffer(src:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_read_buffer(src);
		#end
	}

	public function readPixels(x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_read_pixels(x, y, width, height, format, type, pixels);
		#end
	}

	public function releaseShaderCompiler():Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_release_shader_compiler();
		#end
	}

	public function renderbufferStorage(target:Int, internalformat:Int, width:Int, height:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_renderbuffer_storage(target, internalformat, width, height);
		#end
	}

	public function renderbufferStorageMultisample(target:Int, samples:Int, internalformat:Int, width:Int, height:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_renderbuffer_storage_multisample(target, samples, internalformat, width, height);
		#end
	}

	public function resumeTransformFeedback():Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_resume_transform_feedback();
		#end
	}

	public function sampleCoverage(value:Float, invert:Bool):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_sample_coverage(value, invert);
		#end
	}

	public function samplerParameterf(sampler:GLSampler, pname:Int, param:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_sampler_parameterf(__getObjectID(sampler), pname, param);
		#end
	}

	public function samplerParameteri(sampler:GLSampler, pname:Int, param:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_sampler_parameteri(__getObjectID(sampler), pname, param);
		#end
	}

	public function scissor(x:Int, y:Int, width:Int, height:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_scissor(x, y, width, height);
		#end
	}

	public function shaderBinary(shaders:Array<GLShader>, binaryformat:Int, binary:DataPointer, length:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		#if hl
		var _shaders = new hl.NativeArray<Int>(shaders.length);
		for (i in 0...shaders.length)
			_shaders[i] = shaders[i].id;
		var shaders = _shaders;
		#end
		NativeCFFI.lime_gl_shader_binary(shaders, binaryformat, binary, length);
		#end
	}

	public function shaderSource(shader:GLShader, source:String):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_shader_source(__getObjectID(shader), source);
		#end
	}

	public function stencilFunc(func:Int, ref:Int, mask:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_stencil_func(func, ref, mask);
		#end
	}

	public function stencilFuncSeparate(face:Int, func:Int, ref:Int, mask:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_stencil_func_separate(face, func, ref, mask);
		#end
	}

	public function stencilMask(mask:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_stencil_mask(mask);
		#end
	}

	public function stencilMaskSeparate(face:Int, mask:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_stencil_mask_separate(face, mask);
		#end
	}

	public function stencilOp(fail:Int, zfail:Int, zpass:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_stencil_op(fail, zfail, zpass);
		#end
	}

	public function stencilOpSeparate(face:Int, fail:Int, zfail:Int, zpass:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_stencil_op_separate(face, fail, zfail, zpass);
		#end
	}

	public function texImage2D(target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, data:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_tex_image_2d(target, level, internalformat, width, height, border, format, type, data);
		#end
	}

	public function texImage3D(target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int,
			data:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_tex_image_3d(target, level, internalformat, width, height, depth, border, format, type, data);
		#end
	}

	public function texStorage2D(target:Int, level:Int, internalformat:Int, width:Int, height:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_tex_storage_2d(target, level, internalformat, width, height);
		#end
	}

	public function texStorage3D(target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_tex_storage_3d(target, level, internalformat, width, height, depth);
		#end
	}

	public function texParameterf(target:Int, pname:Int, param:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_tex_parameterf(target, pname, param);
		#end
	}

	public function texParameteri(target:Int, pname:Int, param:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_tex_parameteri(target, pname, param);
		#end
	}

	public function texSubImage2D(target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_tex_sub_image_2d(target, level, xoffset, yoffset, width, height, format, type, pixels);
		#end
	}

	public function texSubImage3D(target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int,
			data:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_tex_sub_image_3d(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, data);
		#end
	}

	@:noCompletion @:dox(hide) public function toString():String
	{
		return "NativeOpenGLRenderContext";
	}

	public function transformFeedbackVaryings(program:GLProgram, varyings:Array<String>, bufferMode:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		#if hl
		var _varyings = new hl.NativeArray<Int>(varyings.length);
		for (i in 0...varyings.length)
			_varyings[i] = varyings[i].charCodeAt(0);
		var varyings = _varyings;
		#end
		NativeCFFI.lime_gl_transform_feedback_varyings(__getObjectID(program), varyings, bufferMode);
		#end
	}

	public function uniform1f(location:GLUniformLocation, v0:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform1f(location, v0);
		#end
	}

	public function uniform1fv(location:GLUniformLocation, count:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform1fv(location, count, v);
		#end
	}

	public function uniform1i(location:GLUniformLocation, v0:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform1i(location, v0);
		#end
	}

	public function uniform1iv(location:GLUniformLocation, count:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform1iv(location, count, v);
		#end
	}

	public function uniform1ui(location:GLUniformLocation, v0:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform1ui(location, v0);
		#end
	}

	public function uniform1uiv(location:GLUniformLocation, count:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform1uiv(location, count, v);
		#end
	}

	public function uniform2f(location:GLUniformLocation, v0:Float, v1:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform2f(location, v0, v1);
		#end
	}

	public function uniform2fv(location:GLUniformLocation, count:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform2fv(location, count, v);
		#end
	}

	public function uniform2i(location:GLUniformLocation, v0:Int, v1:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform2i(location, v0, v1);
		#end
	}

	public function uniform2iv(location:GLUniformLocation, count:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform2iv(location, count, v);
		#end
	}

	public function uniform2ui(location:GLUniformLocation, v0:Int, v1:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform2ui(location, v0, v1);
		#end
	}

	public function uniform2uiv(location:GLUniformLocation, count:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform2uiv(location, count, v);
		#end
	}

	public function uniform3f(location:GLUniformLocation, v0:Float, v1:Float, v2:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform3f(location, v0, v1, v2);
		#end
	}

	public function uniform3fv(location:GLUniformLocation, count:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform3fv(location, count, v);
		#end
	}

	public function uniform3i(location:GLUniformLocation, v0:Int, v1:Int, v2:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform3i(location, v0, v1, v2);
		#end
	}

	public function uniform3iv(location:GLUniformLocation, count:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform3iv(location, count, v);
		#end
	}

	public function uniform3ui(location:GLUniformLocation, v0:Int, v1:Int, v2:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform3ui(location, v0, v1, v2);
		#end
	}

	public function uniform3uiv(location:GLUniformLocation, count:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform3uiv(location, count, v);
		#end
	}

	public function uniform4f(location:GLUniformLocation, v0:Float, v1:Float, v2:Float, v3:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform4f(location, v0, v1, v2, v3);
		#end
	}

	public function uniform4fv(location:GLUniformLocation, count:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform4fv(location, count, v);
		#end
	}

	public function uniform4i(location:GLUniformLocation, v0:Int, v1:Int, v2:Int, v3:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform4i(location, v0, v1, v2, v3);
		#end
	}

	public function uniform4iv(location:GLUniformLocation, count:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform4iv(location, count, v);
		#end
	}

	public function uniform4ui(location:GLUniformLocation, v0:Int, v1:Int, v2:Int, v3:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform4ui(location, v0, v1, v2, v3);
		#end
	}

	public function uniform4uiv(location:GLUniformLocation, count:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform4uiv(location, count, v);
		#end
	}

	public function uniformBlockBinding(program:GLProgram, uniformBlockIndex:Int, uniformBlockBinding:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform_block_binding(__getObjectID(program), uniformBlockIndex, uniformBlockBinding);
		#end
	}

	public function uniformMatrix2fv(location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform_matrix2fv(location, count, transpose, v);
		#end
	}

	public function uniformMatrix2x3fv(location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform_matrix2x3fv(location, count, transpose, v);
		#end
	}

	public function uniformMatrix2x4fv(location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform_matrix2x4fv(location, count, transpose, v);
		#end
	}

	public function uniformMatrix3fv(location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform_matrix3fv(location, count, transpose, v);
		#end
	}

	public function uniformMatrix3x2fv(location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform_matrix3x2fv(location, count, transpose, v);
		#end
	}

	public function uniformMatrix3x4fv(location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform_matrix3x4fv(location, count, transpose, v);
		#end
	}

	public function uniformMatrix4fv(location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform_matrix4fv(location, count, transpose, v);
		#end
	}

	public function uniformMatrix4x2fv(location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform_matrix4x2fv(location, count, transpose, v);
		#end
	}

	public function uniformMatrix4x3fv(location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_uniform_matrix4x3fv(location, count, transpose, v);
		#end
	}

	public function unmapBuffer(target:Int):Bool
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		return NativeCFFI.lime_gl_unmap_buffer(target);
		#else
		return false;
		#end
	}

	public function useProgram(program:GLProgram):Void
	{
		__currentProgram = program;

		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_use_program(__getObjectID(program));
		#end
	}

	public function validateProgram(program:GLProgram):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_validate_program(__getObjectID(program));
		#end
	}

	public function vertexAttrib1f(index:Int, v0:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attrib1f(index, v0);
		#end
	}

	public function vertexAttrib1fv(index:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attrib1fv(index, v);
		#end
	}

	public function vertexAttrib2f(index:Int, v0:Float, y:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attrib2f(index, v0, y);
		#end
	}

	public function vertexAttrib2fv(index:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attrib2fv(index, v);
		#end
	}

	public function vertexAttrib3f(index:Int, v0:Float, v1:Float, v2:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attrib3f(index, v0, v1, v2);
		#end
	}

	public function vertexAttrib3fv(index:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attrib3fv(index, v);
		#end
	}

	public function vertexAttrib4f(index:Int, v0:Float, v1:Float, v2:Float, v3:Float):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attrib4f(index, v0, v1, v2, v3);
		#end
	}

	public function vertexAttrib4fv(index:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attrib4fv(index, v);
		#end
	}

	public function vertexAttribDivisor(index:Int, divisor:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attrib_divisor(index, divisor);
		#end
	}

	public function vertexAttribI4i(index:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attribi4i(index, v0, v1, v2, v3);
		#end
	}

	// public function vertexAttribI4iv (index:Int, value:js.html.Int32Array) {
	// public function vertexAttribI4iv (index:Int, value:Array<Int>) {
	public function vertexAttribI4iv(index:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attribi4iv(index, v);
		#end
	}

	public function vertexAttribI4ui(index:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attribi4ui(index, v0, v1, v2, v3);
		#end
	}

	// public function vertexAttribI4iv (index:Int, value:js.html.Int32Array) {
	// public function vertexAttribI4iv (index:Int, value:Array<Int>) {
	public function vertexAttribI4uiv(index:Int, v:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attribi4uiv(index, v);
		#end
	}

	public function vertexAttribIPointer(index:Int, size:Int, type:Int, stride:Int, offset:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attrib_ipointer(index, size, type, stride, offset);
		#end
	}

	public function vertexAttribPointer(index:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:DataPointer):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_vertex_attrib_pointer(index, size, type, normalized, stride, offset);
		#end
	}

	public function viewport(x:Int, y:Int, width:Int, height:Int):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_viewport(x, y, width, height);
		#end
	}

	public function waitSync(sync:GLSync, flags:Int, timeout:Int64):Void
	{
		#if (lime_cffi && (lime_opengl || lime_opengles) && !macro)
		NativeCFFI.lime_gl_wait_sync(sync, flags, timeout.high, timeout.low);
		#end
	}

	private function __contextLost():Void
	{
		__isContextLost = true;
		__arrayBufferBinding = null;
		__elementBufferBinding = null;
		__currentProgram = null;
		__framebufferBinding = null;
		__renderbufferBinding = null;
		__texture2DBinding = null;
		__textureCubeMapBinding = null;
	}

	#if (!js || !html5 || doc_gen)
	private function __createObject(id:Int):GLObject
	{
		return new GLObject(id);
	}

	private function __getObjectID(object:GLObject):Int
	{
		return (object == null) ? 0 : object.id;
	}
	#end

	private function __initialize():Void
	{
		if (!__initialized)
		{
			__extensionObjectConstructors["AMD_compressed_3DC_texture"] = AMD_compressed_3DC_texture.new;
			__extensionObjectConstructors["AMD_compressed_ATC_texture"] = AMD_compressed_ATC_texture.new;
			__extensionObjectConstructors["AMD_performance_monitor"] = AMD_performance_monitor.new;
			__extensionObjectConstructors["AMD_program_binary_Z400"] = AMD_program_binary_Z400.new;
			__extensionObjectConstructors["ANGLE_framebuffer_blit"] = ANGLE_framebuffer_blit.new;
			__extensionObjectConstructors["ANGLE_framebuffer_multisample"] = ANGLE_framebuffer_multisample.new;
			__extensionObjectConstructors["ANGLE_instanced_arrays"] = ANGLE_instanced_arrays.new;
			__extensionObjectConstructors["ANGLE_pack_reverse_row_order"] = ANGLE_pack_reverse_row_order.new;
			__extensionObjectConstructors["ANGLE_texture_compression_dxt3"] = ANGLE_texture_compression_dxt3.new;
			__extensionObjectConstructors["ANGLE_texture_compression_dxt5"] = ANGLE_texture_compression_dxt5.new;
			__extensionObjectConstructors["ANGLE_texture_usage"] = ANGLE_texture_usage.new;
			__extensionObjectConstructors["ANGLE_translated_shader_source"] = ANGLE_translated_shader_source.new;
			__extensionObjectConstructors["APPLE_copy_texture_levels"] = APPLE_copy_texture_levels.new;
			__extensionObjectConstructors["APPLE_framebuffer_multisample"] = APPLE_framebuffer_multisample.new;
			__extensionObjectConstructors["APPLE_rgb_422"] = APPLE_rgb_422.new;
			__extensionObjectConstructors["APPLE_sync"] = APPLE_sync.new;
			__extensionObjectConstructors["APPLE_texture_format_BGRA8888"] = APPLE_texture_format_BGRA8888.new;
			__extensionObjectConstructors["APPLE_texture_max_level"] = APPLE_texture_max_level.new;
			__extensionObjectConstructors["ARM_mali_program_binary"] = ARM_mali_program_binary.new;
			__extensionObjectConstructors["ARM_mali_shader_binary"] = ARM_mali_shader_binary.new;
			__extensionObjectConstructors["ARM_rgba8"] = ARM_rgba8.new;
			__extensionObjectConstructors["DMP_shader_binary"] = DMP_shader_binary.new;
			__extensionObjectConstructors["EXT_bgra"] = EXT_bgra.new;
			__extensionObjectConstructors["EXT_blend_minmax"] = EXT_blend_minmax.new;
			__extensionObjectConstructors["EXT_color_buffer_float"] = EXT_color_buffer_float.new;
			__extensionObjectConstructors["EXT_color_buffer_half_float"] = EXT_color_buffer_half_float.new;
			__extensionObjectConstructors["EXT_debug_label"] = EXT_debug_label.new;
			__extensionObjectConstructors["EXT_debug_marker"] = EXT_debug_marker.new;
			__extensionObjectConstructors["EXT_discard_framebuffer"] = EXT_discard_framebuffer.new;
			__extensionObjectConstructors["EXT_map_buffer_range"] = EXT_map_buffer_range.new;
			__extensionObjectConstructors["EXT_multi_draw_arrays"] = EXT_multi_draw_arrays.new;
			__extensionObjectConstructors["EXT_multisampled_render_to_texture"] = EXT_multisampled_render_to_texture.new;
			__extensionObjectConstructors["EXT_multiview_draw_buffers"] = EXT_multiview_draw_buffers.new;
			__extensionObjectConstructors["EXT_occlusion_query_boolean"] = EXT_occlusion_query_boolean.new;
			__extensionObjectConstructors["EXT_packed_depth_stencil"] = EXT_packed_depth_stencil.new;
			__extensionObjectConstructors["EXT_read_format_bgra"] = EXT_read_format_bgra.new;
			__extensionObjectConstructors["EXT_robustness"] = EXT_robustness.new;
			__extensionObjectConstructors["EXT_sRGB"] = EXT_sRGB.new;
			__extensionObjectConstructors["EXT_separate_shader_objects"] = EXT_separate_shader_objects.new;
			__extensionObjectConstructors["EXT_shader_framebuffer_fetch"] = EXT_shader_framebuffer_fetch.new;
			__extensionObjectConstructors["EXT_shader_texture_lod"] = EXT_shader_texture_lod.new;
			__extensionObjectConstructors["EXT_shadow_samplers"] = EXT_shadow_samplers.new;
			__extensionObjectConstructors["EXT_texture_compression_dxt1"] = EXT_texture_compression_dxt1.new;
			__extensionObjectConstructors["EXT_texture_compression_s3tc"] = EXT_texture_compression_s3tc.new;
			__extensionObjectConstructors["EXT_texture_filter_anisotropic"] = EXT_texture_filter_anisotropic.new;
			__extensionObjectConstructors["EXT_texture_format_BGRA8888"] = EXT_texture_format_BGRA8888.new;
			__extensionObjectConstructors["EXT_texture_rg"] = EXT_texture_rg.new;
			__extensionObjectConstructors["EXT_texture_storage"] = EXT_texture_storage.new;
			__extensionObjectConstructors["EXT_texture_type_2_10_10_10_REV"] = EXT_texture_type_2_10_10_10_REV.new;
			__extensionObjectConstructors["EXT_unpack_subimage"] = EXT_unpack_subimage.new;
			__extensionObjectConstructors["FJ_shader_binary_GCCSO"] = FJ_shader_binary_GCCSO.new;
			__extensionObjectConstructors["IMG_multisampled_render_to_texture"] = IMG_multisampled_render_to_texture.new;
			__extensionObjectConstructors["IMG_program_binary"] = IMG_program_binary.new;
			__extensionObjectConstructors["IMG_read_format"] = IMG_read_format.new;
			__extensionObjectConstructors["IMG_shader_binary"] = IMG_shader_binary.new;
			__extensionObjectConstructors["IMG_texture_compression_pvrtc"] = IMG_texture_compression_pvrtc.new;
			__extensionObjectConstructors["KHR_debug"] = KHR_debug.new;
			__extensionObjectConstructors["KHR_texture_compression_astc_ldr"] = KHR_texture_compression_astc_ldr.new;
			__extensionObjectConstructors["NV_coverage_sample"] = NV_coverage_sample.new;
			__extensionObjectConstructors["NV_depth_nonlinear"] = NV_depth_nonlinear.new;
			__extensionObjectConstructors["NV_draw_buffers"] = NV_draw_buffers.new;
			__extensionObjectConstructors["NV_fbo_color_attachments"] = NV_fbo_color_attachments.new;
			__extensionObjectConstructors["NV_fence"] = NV_fence.new;
			__extensionObjectConstructors["NV_read_buffer"] = NV_read_buffer.new;
			__extensionObjectConstructors["NV_read_buffer_front"] = NV_read_buffer_front.new;
			__extensionObjectConstructors["NV_read_depth"] = NV_read_depth.new;
			__extensionObjectConstructors["NV_read_depth_stencil"] = NV_read_depth_stencil.new;
			__extensionObjectConstructors["NV_read_stencil"] = NV_read_stencil.new;
			__extensionObjectConstructors["NV_texture_compression_s3tc_update"] = NV_texture_compression_s3tc_update.new;
			__extensionObjectConstructors["NV_texture_npot_2D_mipmap"] = NV_texture_npot_2D_mipmap.new;
			__extensionObjectConstructors["NVX_gpu_memory_info"] = NVX_gpu_memory_info.new;
			__extensionObjectConstructors["OES_EGL_image"] = OES_EGL_image.new;
			__extensionObjectConstructors["OES_EGL_image_external"] = OES_EGL_image_external.new;
			__extensionObjectConstructors["OES_compressed_ETC1_RGB8_texture"] = OES_compressed_ETC1_RGB8_texture.new;
			__extensionObjectConstructors["OES_compressed_paletted_texture"] = OES_compressed_paletted_texture.new;
			__extensionObjectConstructors["OES_depth24"] = OES_depth24.new;
			__extensionObjectConstructors["OES_depth32"] = OES_depth32.new;
			__extensionObjectConstructors["OES_depth_texture"] = OES_depth_texture.new;
			__extensionObjectConstructors["OES_element_index_uint"] = OES_element_index_uint.new;
			__extensionObjectConstructors["OES_get_program_binary"] = OES_get_program_binary.new;
			__extensionObjectConstructors["OES_mapbuffer"] = OES_mapbuffer.new;
			__extensionObjectConstructors["OES_packed_depth_stencil"] = OES_packed_depth_stencil.new;
			__extensionObjectConstructors["OES_required_internalformat"] = OES_required_internalformat.new;
			__extensionObjectConstructors["OES_rgb8_rgba8"] = OES_rgb8_rgba8.new;
			__extensionObjectConstructors["OES_standard_derivatives"] = OES_standard_derivatives.new;
			__extensionObjectConstructors["OES_stencil1"] = OES_stencil1.new;
			__extensionObjectConstructors["OES_stencil4"] = OES_stencil4.new;
			__extensionObjectConstructors["OES_surfaceless_context"] = OES_surfaceless_context.new;
			__extensionObjectConstructors["OES_texture_3D"] = OES_texture_3D.new;
			__extensionObjectConstructors["OES_texture_float"] = OES_texture_float.new;
			__extensionObjectConstructors["OES_texture_float_linear"] = OES_texture_float_linear.new;
			__extensionObjectConstructors["OES_texture_half_float"] = OES_texture_half_float.new;
			__extensionObjectConstructors["OES_texture_half_float_linear"] = OES_texture_half_float_linear.new;
			__extensionObjectConstructors["OES_texture_npot"] = OES_texture_npot.new;
			__extensionObjectConstructors["OES_vertex_array_object"] = OES_vertex_array_object.new;
			__extensionObjectConstructors["OES_vertex_half_float"] = OES_vertex_half_float.new;
			__extensionObjectConstructors["OES_vertex_type_10_10_10_2"] = OES_vertex_type_10_10_10_2.new;
			__extensionObjectConstructors["QCOM_alpha_test"] = QCOM_alpha_test.new;
			__extensionObjectConstructors["QCOM_binning_control"] = QCOM_binning_control.new;
			__extensionObjectConstructors["QCOM_driver_control"] = QCOM_driver_control.new;
			__extensionObjectConstructors["QCOM_extended_get"] = QCOM_extended_get.new;
			__extensionObjectConstructors["QCOM_extended_get2"] = QCOM_extended_get2.new;
			__extensionObjectConstructors["QCOM_perfmon_global_mode"] = QCOM_perfmon_global_mode.new;
			__extensionObjectConstructors["QCOM_tiled_rendering"] = QCOM_tiled_rendering.new;
			__extensionObjectConstructors["QCOM_writeonly_rendering"] = QCOM_writeonly_rendering.new;
			__extensionObjectConstructors["VIV_shader_binary"] = VIV_shader_binary.new;
		}

		__initialized = true;
	}
}
