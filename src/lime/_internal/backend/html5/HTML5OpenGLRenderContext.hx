package lime._internal.backend.html5;


import haxe.io.Bytes;
import haxe.Int64;
import js.html.webgl.RenderingContext in WebGLRenderingContext;
import js.html.CanvasElement;
import js.Browser;
import lime.graphics.opengl.*;
import lime.graphics.RenderContextType;
import lime.utils.ArrayBuffer;
import lime.utils.ArrayBufferView;
import lime.utils.BytePointer;
import lime.utils.DataPointer;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import lime.utils.UInt8Array;
import lime.utils.UInt32Array;

@:allow(lime.ui.Window)


class HTML5OpenGLRenderContext {
	
	
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
	
	public var CW  = 0x0900;
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
	public var ACTIVE_ATTRIBUTES = 0x8B89;
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
	
	public var TEXTURE_2D = 0x0DE1;
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
	
	public var VERTEX_PROGRAM_POINT_SIZE = 0x8642;
	public var POINT_SPRITE = 0x8861;
	
	public var COMPILE_STATUS = 0x8B81;
	
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
	
	#if (js && html5)
	public var canvas (get, never):CanvasElement;
	public var drawingBufferHeight (get, never):Int;
	public var drawingBufferWidth (get, never):Int;
	#end
	
	public var type:RenderContextType;
	public var version (default, null):Int;
	
	private var __context:WebGL2RenderingContext;
	private var __contextLost:Bool;
	
	
	private function new (context:WebGL2RenderingContext) {
		
		__context = context;
		version = 1;
		type = WEBGL;
		
		if (context != null) {
			
			var gl = context;
			
			if (Reflect.hasField (gl, "rawgl")) {
				
				gl = Reflect.field (context, "rawgl");
				
			}
			
			if (Reflect.hasField (Browser.window, "WebGL2RenderingContext") && Std.is (gl, WebGL2RenderingContext)) {
				
				version = 2;
				
			}
			
		}
		
	}
	
	
	public inline function activeTexture (texture:Int):Void {
		
		__context.activeTexture (texture);
		
	}
	
	
	public inline function attachShader (program:GLProgram, shader:GLShader):Void {
		
		__context.attachShader (program, shader);
		
	}
	
	
	public inline function beginQuery (target:Int, query:GLQuery):Void {
		
		__context.beginQuery (target, query);
		
	}
	
	
	public inline function beginTransformFeedback (primitiveNode:Int):Void {
		
		__context.beginTransformFeedback (primitiveNode);
		
	}
	
	
	public inline function bindAttribLocation (program:GLProgram, index:Int, name:String):Void {
		
		__context.bindAttribLocation (program, index, name);
		
	}
	
	
	public inline function bindBuffer (target:Int, buffer:GLBuffer):Void {
		
		__context.bindBuffer (target, buffer);
		
	}
	
	
	public inline function bindBufferBase (target:Int, index:Int, buffer:GLBuffer):Void {
		
		__context.bindBufferBase (target, index, buffer);
		
	}
	
	
	public inline function bindBufferRange (target:Int, index:Int, buffer:GLBuffer, offset:DataPointer, size:Int):Void {
		
		__context.bindBufferRange (target, index, buffer, offset.toValue (), size);
		
	}
	
	
	public inline function bindFramebuffer (target:Int, framebuffer:GLFramebuffer):Void {
		
		__context.bindFramebuffer (target, framebuffer);
		
	}
	
	
	public inline function bindRenderbuffer (target:Int, renderbuffer:GLRenderbuffer):Void {
		
		__context.bindRenderbuffer (target, renderbuffer);
		
	}
	
	
	public inline function bindSampler (unit:Int, sampler:GLSampler):Void {
		
		__context.bindSampler (unit, sampler);
		
	}
	
	
	public inline function bindTexture (target:Int, texture:GLTexture):Void {
		
		__context.bindTexture (target, texture);
		
	}
	
	
	public inline function bindTransformFeedback (target:Int, transformFeedback:GLTransformFeedback):Void {
		
		__context.bindTransformFeedback (target, transformFeedback);
		
	}
	
	
	public inline function bindVertexArray (vertexArray:GLVertexArrayObject):Void {
		
		__context.bindVertexArray (vertexArray);
		
	}
	
	
	public inline function blendColor (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		__context.blendColor (red, green, blue, alpha);
		
	}
	
	
	public inline function blendEquation (mode:Int):Void {
		
		__context.blendEquation (mode);
		
	}
	
	
	public inline function blendEquationSeparate (modeRGB:Int, modeAlpha:Int):Void {
		
		__context.blendEquationSeparate (modeRGB, modeAlpha);
		
	}
	
	
	public inline function blendFunc (sfactor:Int, dfactor:Int):Void {
		
		__context.blendFunc (sfactor, dfactor);
		
	}
	
	
	public inline function blendFuncSeparate (srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int):Void {
		
		__context.blendFuncSeparate (srcRGB, dstRGB, srcAlpha, dstAlpha);
		
	}
	
	
	public inline function blitFramebuffer (srcX0:Int, srcY0:Int, srcX1:Int, srcY1:Int, dstX0:Int, dstY0:Int, dstX1:Int, dstY1:Int, mask:Int, filter:Int):Void {
		
		__context.blitFramebuffer (srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
		
	}
	
	
	public inline function bufferData (target:Int, size:Int, data:DataPointer, usage:Int):Void {
		
		__context.bufferData (target, data.toBufferView (size), usage);
		
	}
	
	
	//public function bufferData (target:Int, srcData:ArrayBufferView, usage:Int):Void {
	//public function bufferData (target:Int, srcData:ArrayBuffer, usage:Int):Void {
	//public function bufferData (target:Int, size:Int, usage:Int):Void {
	//public function bufferData (target:Int, srcData:ArrayBufferView, usage:Int, srcOffset:Int = 0, length:Int = 0):Void {
	public function bufferDataWEBGL (target:Int, srcData:Dynamic, usage:Int, ?srcOffset:Int, ?length:Int):Void {
		
		if (srcOffset != null) {
			
			__context.bufferData (target, srcData, usage, srcOffset, length);
			
		} else {
			
			__context.bufferData (target, srcData, usage);
			
		}
		
	}
	
	
	public inline function bufferSubData (target:Int, dstByteOffset:Int, size:Int, data:DataPointer):Void {
		
		__context.bufferSubData (target, dstByteOffset, data.toBufferView (size));
		
	}
	
	
	//public function bufferSubData (target:Int, dstByteOffset:Int, srcData:ArrayBufferView):Void {
	//public function bufferSubData (target:Int, dstByteOffset:Int, srcData:ArrayBuffer):Void {
	//public function bufferSubData (target:Int, dstByteOffset:Int, srcData:ArrayBufferView, srcOffset:Int = 0, length:Int = 0):Void {
	public function bufferSubDataWEBGL (target:Int, dstByteOffset:Int, srcData:Dynamic, ?srcOffset:Int, ?length:Int):Void {
		
		if (srcOffset != null) {
			
			__context.bufferSubData (target, dstByteOffset, srcData, srcOffset, length);
			
		} else {
			
			__context.bufferSubData (target, dstByteOffset, srcData);
			
		}
		
	}
	
	
	public inline function checkFramebufferStatus (target:Int):Int {
		
		return __context.checkFramebufferStatus (target);
		
	}
	
	
	public inline function clear (mask:Int):Void {
		
		__context.clear (mask);
		
	}
	
	
	public inline function clearBufferfi (buffer:Int, drawbuffer:Int, depth:Float, stencil:Int):Void {
		
		__context.clearBufferfi (buffer, drawbuffer, depth, stencil);
		
	}
	
	
	public inline function clearBufferfv (buffer:Int, drawbuffer:Int, values:DataPointer):Void {
		
		__context.clearBufferfv (buffer, drawbuffer, values.toFloat32Array ());
		
	}
	
	
	public inline function clearBufferfvWEBGL (buffer:Int, drawbuffer:Int, values:Dynamic, ?srcOffset:Int):Void {
		
		__context.clearBufferfv (buffer, drawbuffer, values, srcOffset);
		
	}
	
	
	public inline function clearBufferiv (buffer:Int, drawbuffer:Int, values:DataPointer):Void {
		
		__context.clearBufferiv (buffer, drawbuffer, values.toInt32Array ());
		
	}
	
	
	public inline function clearBufferivWEBGL (buffer:Int, drawbuffer:Int, values:Dynamic, ?srcOffset:Int):Void {
		
		__context.clearBufferiv (buffer, drawbuffer, values, srcOffset);
		
	}
	
	
	public inline function clearBufferuiv (buffer:Int, drawbuffer:Int, values:DataPointer):Void {
		
		__context.clearBufferuiv (buffer, drawbuffer, values.toUInt32Array ());
		
	}
	
	
	public inline function clearBufferuivWEBGL (buffer:Int, drawbuffer:Int, values:Dynamic, ?srcOffset:Int):Void {
		
		__context.clearBufferuiv (buffer, drawbuffer, values, srcOffset);
		
	}
	
	
	public inline function clearColor (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		__context.clearColor (red, green, blue, alpha);
		
	}
	
	
	@:dox(hide) @:noCompletion public inline function clearDepth (depth:Float):Void {
		
		__context.clearDepth (depth);
		
	}
	
	
	public inline function clearDepthf (depth:Float):Void {
		
		clearDepth (depth);
		
	}
	
	
	public inline function clearStencil (s:Int):Void {
		
		__context.clearStencil (s);
		
	}
	
	
	//public inline function clientWaitSync (sync:GLSync, flags:Int, timeout:Dynamic /*int64*/):Int {
	//public inline function clientWaitSync (sync:GLSync, flags:Int, timeout:Int64):Int {
	public inline function clientWaitSync (sync:GLSync, flags:Int, timeout:Dynamic):Int {
		
		return __context.clientWaitSync (sync, flags, timeout);
		
	}
	
	
	public inline function copyBufferSubData (readTarget:Int, writeTarget:Int, readOffset:DataPointer, writeOffset:DataPointer, size:Int):Void {
		
		
	}
	
	
	public inline function colorMask (red:Bool, green:Bool, blue:Bool, alpha:Bool):Void {
		
		__context.colorMask (red, green, blue, alpha);
		
	}
	
	
	public inline function compileShader (shader:GLShader):Void {
		
		__context.compileShader (shader);
		
	}
	
	
	public inline function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, imageSize:Int, data:DataPointer):Void {
		
		__context.compressedTexImage2D (target, level, internalformat, width, height, border, data.toBufferView (imageSize));
		
	}
	
	
	//public function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, srcData:ArrayBufferView):Void {
	//public function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, offset:Int):Void {
	//public function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, srcData:ArrayBufferView, srcOffset:Int = 0, srcLengthOverride:Int = 0):Void {
	public function compressedTexImage2DWEBGL (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, srcData:Dynamic, ?srcOffset:Int, ?srcLengthOverride:Int):Void {
		
		if (srcOffset != null) {
			
			__context.compressedTexImage2D (target, level, internalformat, width, height, border, srcData, srcOffset, srcLengthOverride);
			
		} else {
			
			__context.compressedTexImage2D (target, level, internalformat, width, height, border, srcData);
			
		}
		
	}
	
	
	public inline function compressedTexImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, imageSize:Int, data:DataPointer):Void {
		
		__context.compressedTexImage3D (target, level, internalformat, width, height, depth, border, data.toBufferView (imageSize));
		
	}
	
	
	public inline function compressedTexImage3DWEBGL (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, srcData:Dynamic, ?srcOffset:Int, ?srcLengthOverride:Int):Void {
		
		__context.compressedTexImage3D (target, level, internalformat, width, height, depth, border, srcData, srcOffset, srcLengthOverride);
		
	}
	
	
	public inline function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, imageSize:Int, data:DataPointer):Void {
		
		__context.compressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, data.toBufferView (imageSize));
		
	}
	
	
	//public function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, srcData:ArrayBufferView):Void {
	//public function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, offset:Int):Void {
	//public function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, srcData:ArrayBufferView, srcOffset:Int = 0, srcLengthOverride:Int = 0):Void {
	public function compressedTexSubImage2DWEBGL (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, srcData:Dynamic, ?srcOffset:Int, ?srcLengthOverride:Int):Void {
		
		if (srcOffset != null) {
			
			__context.compressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, srcData, srcOffset, srcLengthOverride);
			
		} else {
			
			__context.compressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, srcData);
			
		}
		
	}
	
	
	public inline function compressedTexSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, imageSize:Int, data:DataPointer):Void {
		
		__context.compressedTexSubImage3D (target, level, xoffset, yoffset, zoffset, width, height, depth, format, data.toBufferView (imageSize));
		
	}
	
	
	public inline function compressedTexSubImage3DWEBGL (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, srcData:ArrayBufferView, ?srcOffset:Int, ?srcLengthOverride:Int):Void {
		
		__context.compressedTexSubImage3D (target, level, xoffset, yoffset, zoffset, width, height, depth, format, srcData, srcOffset, srcLengthOverride);
		
	}
	
	
	public inline function copySubBufferData (readTarget:Int, writeTarget:Int, readOffset:DataPointer, writeOffset:DataPointer, size:Int):Void {
		
		__context.copySubBufferData (readTarget, writeTarget, readOffset.toValue (), writeOffset.toValue (), size);
		
	}
	
	
	public inline function copyTexImage2D (target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void {
		
		__context.copyTexImage2D (target, level, internalformat, x, y, width, height, border);
		
	}
	 
	
	public inline function copyTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {
		
		__context.copyTexSubImage2D (target, level, xoffset, yoffset, x, y, width, height);
		
	}
	
	
	public inline function copyTexSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {
		
		__context.copyTexSubImage3D (target, level, xoffset, yoffset, zoffset, x, y, width, height);
		
	}
	
	
	public inline function createBuffer ():GLBuffer {
		
		return __context.createBuffer ();
		
	}
	
	
	public inline function createFramebuffer ():GLFramebuffer {
		
		return __context.createFramebuffer ();
		
	}
	
	
	public inline function createProgram ():GLProgram {
		
		return __context.createProgram ();
		
	}
	
	
	public inline function createQuery ():GLQuery {
		
		return __context.createQuery ();
		
	}
	
	
	public inline function createRenderbuffer ():GLRenderbuffer {
		
		return __context.createRenderbuffer ();
		
	}
	
	
	public inline function createSampler ():GLSampler {
		
		return __context.createSampler ();
		
	}
	
	
	public inline function createShader (type:Int):GLShader {
		
		return __context.createShader (type);
		
	}
	
	
	public inline function createTexture ():GLTexture {
		
		return __context.createTexture ();
		
	}
	
	
	public inline function createTransformFeedback ():GLTransformFeedback {
		
		return __context.createTransformFeedback ();
		
	}
	
	
	public inline function createVertexArray ():GLVertexArrayObject {
		
		return __context.createVertexArray ();
		
	}
	
	
	public inline function cullFace (mode:Int):Void {
		
		__context.cullFace (mode);
		
	}
	
	
	public inline function deleteBuffer (buffer:GLBuffer):Void {
		
		__context.deleteBuffer (buffer);
		
	}
	
	
	public inline function deleteFramebuffer (framebuffer:GLFramebuffer):Void {
		
		__context.deleteFramebuffer (framebuffer);
		
	}
	
	
	public inline function deleteProgram (program:GLProgram):Void {
		
		__context.deleteProgram (program);
		
	}
	
	
	public inline function deleteQuery (query:GLQuery):Void {
		
		__context.deleteQuery (query);
		
	}
	
	
	public inline function deleteRenderbuffer (renderbuffer:GLRenderbuffer):Void {
		
		__context.deleteRenderbuffer (renderbuffer);
		
	}
	
	
	public inline function deleteSampler (sampler:GLSampler):Void {
		
		__context.deleteSampler (sampler);
		
	}
	
	
	public inline function deleteShader (shader:GLShader):Void {
		
		__context.deleteShader (shader);
		
	}
	
	
	public inline function deleteSync (sync:GLSync):Void {
		
		__context.deleteSync (sync);
		
	}
	
	
	public inline function deleteTexture (texture:GLTexture):Void {
		
		__context.deleteTexture (texture);
		
	}
	
	
	public inline function deleteTransformFeedback (transformFeedback:GLTransformFeedback):Void {
		
		__context.deleteTransformFeedback (transformFeedback);
		
	}
	
	
	public inline function deleteVertexArray (vertexArray:GLVertexArrayObject):Void {
		
		__context.deleteVertexArray (vertexArray);
		
	}
	
	
	public inline function depthFunc (func:Int):Void {
		
		__context.depthFunc (func);
		
	}
	
	
	public inline function depthMask (flag:Bool):Void {
		
		__context.depthMask (flag);
		
	}
	
	
	@:dox(hide) @:noCompletion public inline function depthRange (zNear:Float, zFar:Float):Void {
		
		__context.depthRange (zNear, zFar);
		
	}
	
	
	public inline function depthRangef (zNear:Float, zFar:Float):Void {
		
		depthRange (zNear, zFar);
		
	}
	
	
	public inline function detachShader (program:GLProgram, shader:GLShader):Void {
		
		__context.detachShader (program, shader);
		
	}
	
	
	public inline function disable (cap:Int):Void {
		
		__context.disable (cap);
		
	}
	
	
	public inline function disableVertexAttribArray (index:Int):Void {
		
		__context.disableVertexAttribArray (index);
		
	}
	
	
	public inline function drawArrays (mode:Int, first:Int, count:Int):Void {
		
		__context.drawArrays (mode, first, count);
		
	}
	
	
	public inline function drawArraysInstanced (mode:Int, first:Int, count:Int, instanceCount:Int):Void {
		
		__context.drawArraysInstanced (mode, first, count, instanceCount);
		
	}
	
	
	public inline function drawBuffers (buffers:Array<Int>):Void {
		
		__context.drawBuffers (buffers);
		
	}
	
	
	public inline function drawElements (mode:Int, count:Int, type:Int, offset:DataPointer):Void {
		
		__context.drawElements (mode, count, type, offset.toValue ());
		
	}
	
	
	public inline function drawElementsInstanced (mode:Int, count:Int, type:Int, offset:DataPointer, instanceCount:Int):Void {
		
		__context.drawElementsInstanced (mode, count, type, offset.toValue (), instanceCount);
		
	}
	
	
	public inline function drawRangeElements (mode:Int, start:Int, end:Int, count:Int, type:Int, offset:DataPointer):Void {
		
		__context.drawRangeElements (mode, start, end, count, type, offset.toValue ());
		
	}
	
	
	public inline function enable (cap:Int):Void {
		
		__context.enable (cap);
		
	}
	
	
	public inline function enableVertexAttribArray (index:Int):Void {
		
		__context.enableVertexAttribArray (index);
		
	}
	
	
	public inline function endQuery (target:Int):Void {
		
		__context.endQuery (target);
		
	}
	
	
	public inline function endTransformFeedback ():Void {
		
		__context.endTransformFeedback ();
		
	}
	
	
	public inline function fenceSync (condition:Int, flags:Int):GLSync {
		
		return __context.fenceSync (condition, flags);
		
	}
	
	
	public inline function finish ():Void {
		
		__context.finish ();
		
	}
	
	
	public inline function flush ():Void {
		
		__context.flush ();
		
	}
	
	
	public inline function framebufferRenderbuffer (target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:GLRenderbuffer):Void {
		
		__context.framebufferRenderbuffer (target, attachment, renderbuffertarget, renderbuffer);
		
	}
	
	
	public inline function framebufferTexture2D (target:Int, attachment:Int, textarget:Int, texture:GLTexture, level:Int):Void {
		
		__context.framebufferTexture2D (target, attachment, textarget, texture, level);
		
	}
	
	
	public inline function framebufferTextureLayer (target:Int, attachment:Int, texture:GLTexture, level:Int, layer:Int):Void {
		
		__context.framebufferTextureLayer (target, attachment, texture, level, layer);
		
	}
	
	
	public inline function frontFace (mode:Int):Void {
		
		__context.frontFace (mode);
		
	}
	
	
	public inline function generateMipmap (target:Int):Void {
		
		__context.generateMipmap (target);
		
	}
	
	
	public inline function getActiveAttrib (program:GLProgram, index:Int):GLActiveInfo {
		
		return __context.getActiveAttrib (program, index);
		
	}
	
	
	public inline function getActiveUniform (program:GLProgram, index:Int):GLActiveInfo {
		
		return __context.getActiveUniform (program, index);
		
	}
	
	
	public inline function getActiveUniformBlocki (program:GLProgram, uniformBlockIndex:Int, pname:Int):Dynamic {
		
		return getActiveUniformBlockParameter (program, uniformBlockIndex, pname);
		
	}
	
	
	public function getActiveUniformBlockiv (program:GLProgram, uniformBlockIndex:Int, pname:Int, params:DataPointer):Void {
		
		var view = params.toInt32Array ();
		view[0] = getActiveUniformBlockParameter (program, uniformBlockIndex, pname);
		
	}
	
	
	public inline function getActiveUniformBlockName (program:GLProgram, uniformBlockIndex:Int):String {
		
		return __context.getActiveUniformBlockName (program, uniformBlockIndex);
		
	}
	
	
	public inline function getActiveUniformBlockParameter (program:GLProgram, uniformBlockIndex:Int, pname:Int):Dynamic {
		
		return __context.getActiveUniformBlockParameter (program, uniformBlockIndex, pname);
		
	}
	
	
	public inline function getActiveUniforms (program:GLProgram, uniformIndices:Array<Int>, pname:Int):Dynamic {
		
		return __context.getActiveUniforms (program, uniformIndices, pname);
		
	}
	
	
	public inline function getActiveUniformsiv (program:GLProgram, uniformIndices:Array<Int>, pname:Int, params:DataPointer):Void {
		
		
	}
	
	
	public inline function getAttachedShaders (program:GLProgram):Array<GLShader> {
		
		return __context.getAttachedShaders (program);
		
	}
	
	
	public inline function getAttribLocation (program:GLProgram, name:String):Int {
		
		return __context.getAttribLocation (program, name);
		
	}
	
	
	public inline function getBoolean (pname:Int):Bool {
		
		return getParameter (pname);
		
	}
	
	
	public function getBooleanv (pname:Int, params:DataPointer):Void {
		
		var view = params.toUInt8Array ();
		var result = getParameter (pname);
		
		if (Std.is (result, Array)) {
			
			var data:Array<Bool> = result;
			
			for (i in 0...data.length) {
				
				view[i] = data[i] ? 1 : 0;
				
			}
			
		} else {
			
			view[0] = cast (result, Bool) ? 1 : 0;
			
		}
		
	}
	
	
	public inline function getBufferParameter (target:Int, pname:Int):Dynamic {
		
		return __context.getBufferParameter (target, pname);
		
	}
	
	
	public inline function getBufferParameteri (target:Int, pname:Int):Int {
		
		return getBufferParameter (target, pname);
		
	}
	
	
	public function getBufferParameteri64v (target:Int, pname:Int, params:DataPointer):Void{
		
		
	}
	
	
	public function getBufferParameteriv (target:Int, pname:Int, data:DataPointer):Void {
		
		var view = data.toInt32Array ();
		view[0] = getBufferParameter (target, pname);
		
	}
	
	
	public inline function getBufferPointerv (target:Int, pname:Int):DataPointer {
		
		return 0;
		
	}
	
	
	public inline function getBufferSubData (target:Int, offset:DataPointer, size:Int /*GLsizeiptr*/, data:DataPointer):Void {
		
		__context.getBufferSubData (target, offset.toValue (), data.toBufferView (size));
		
	}
	
	
	//public function getBufferSubData (target:Int, srcByteOffset:DataPointer, dstData:js.html.ArrayBuffer, ?srcOffset:Int, ?length:Int):Void {
	//public function getBufferSubData (target:Int, srcByteOffset:DataPointer, dstData:Dynamic /*SharedArrayBuffer*/, ?srcOffset:Int, ?length:Int):Void {
	public function getBufferSubDataWEBGL (target:Int, srcByteOffset:DataPointer, dstData:Dynamic, ?srcOffset:Int, ?length:Int):Void {
		
		if (srcOffset != null) {
			
			__context.getBufferSubData (target, srcByteOffset, dstData, srcOffset, length);
			
		} else {
			
			__context.getBufferSubData (target, srcByteOffset, dstData);
			
		}
		
	}
	
	
	public inline function getContextAttributes ():GLContextAttributes {
		
		return __context.getContextAttributes ();
		
	}
	
	
	public inline function getError ():Int {
		
		return __context.getError ();
		
	}
	
	
	public inline function getExtension (name:String):Dynamic {
		
		return __context.getExtension (name);
		
	}
	
	
	public inline function getFloat (pname:Int):Float {
		
		return getParameter (pname);
		
	}
	
	
	public function getFloatv (pname:Int, params:DataPointer):Void {
		
		var view = params.toFloat32Array ();
		
		var result = getParameter (pname);
		
		if (Std.is (result, ArrayBufferView)) {
			
			var data:Float32Array = result;
			
			for (i in 0...data.length) {
				
				view[i] = data[i];
				
			}
			
		} else {
			
			view[0] = cast (result, Float);
			
		}
		
	}
	
	
	public inline function getFragDataLocation (program:GLProgram, name:String):Int {
		
		return __context.getFragDataLocation (program, name);
		
	}
	
	
	public inline function getFramebufferAttachmentParameter (target:Int, attachment:Int, pname:Int):Dynamic {
		
		return __context.getFramebufferAttachmentParameter (target, attachment, pname);
		
	}
	
	
	public inline function getFramebufferAttachmentParameteri (target:Int, attachment:Int, pname:Int):Dynamic {
		
		return getFramebufferAttachmentParameter (target, attachment, pname);
		
	}
	
	
	public function getFramebufferAttachmentParameteriv (target:Int, attachment:Int, pname:Int, params:DataPointer):Void {
		
		var value = getFramebufferAttachmentParameteri (target, attachment, pname);
		
		var view = params.toInt32Array ();
		view[0] = value;
		
	}
	
	
	public inline function getIndexedParameter (target:Int, index:Int):Dynamic {
		
		return __context.getIndexedParameter (target, index);
		
	}
	
	
	public inline function getInteger (pname:Int):Int {
		
		return getParameter (pname);
		
	}
	
	
	public inline function getInteger64 (pname:Int):Int64 {
		
		return Int64.ofInt (0);
		
	}
	
	
	public inline function getInteger64i (pname:Int):Int64 {
		
		return Int64.ofInt (0);
		
	}
	
	
	public inline function getInteger64i_v (pname:Int, index:Int, params:DataPointer):Void {
		
		
	}
	
	
	public function getInteger64v (pname:Int, params:DataPointer):Void {
		
		
	}
	
	
	public inline function getIntegeri (pname:Int):Int {
		
		return 0;
		
	}
	
	
	public inline function getIntegeri_v (pname:Int, index:Int, params:DataPointer):Void {
		
		
	}
	
	
	public function getIntegerv (pname:Int, params:DataPointer):Void {
		
		var view = params.toInt32Array ();
		var result = getParameter (pname);
		
		if (Std.is (result, ArrayBufferView)) {
			
			var data:Int32Array = result;
			
			for (i in 0...data.length) {
				
				view[i] = data[i];
				
			}
			
		} else {
			
			view[0] = cast (result, Int);
			
		}
		
	}
	
	
	public inline function getInternalformati (target:Int, internalformat:Int, pname:Int):Int {
		
		return 0;
		
	}
	
	
	public function getInternalformativ (target:Int, internalformat:Int, pname:Int, bufSize:Int, params:DataPointer):Void {
		
		
	}
	
	
	public inline function getInternalformatParameter (target:Int, internalformat:Int, pname:Int):Dynamic {
		
		return __context.getInternalformatParameter (target, internalformat, pname);
		
	}
	
	
	public inline function getParameter (pname:Int):Dynamic {
		
		return __context.getParameter (pname);
		
	}
	
	
	public inline function getProgramBinary (program:GLProgram, binaryFormat:Int):Bytes {
		
		return null;
		
	}
	
	
	public inline function getProgrami (program:GLProgram, pname:Int):Int {
		
		return getProgramParameter (program, pname);
		
	}
	
	
	public function getProgramiv (program:GLProgram, pname:Int, params:DataPointer):Void {
		
		var view = params.toInt32Array ();
		view[0] = getProgramParameter (program, pname);
		
	}
	
	
	public inline function getProgramInfoLog (program:GLProgram):String {
		
		return __context.getProgramInfoLog (program);
		
	}
	
	
	public inline function getProgramParameter (program:GLProgram, pname:Int):Dynamic {
		
		return __context.getProgramParameter (program, pname);
		
	}
	
	
	public inline function getQuery (target:Int, pname:Int):GLQuery {
		
		return __context.getQuery (target, pname);
		
	}
	
	
	public inline function getQueryi (target:Int, pname:Int):Int {
		
		return 0;
		
	}
	
	
	public function getQueryiv (target:Int, pname:Int, params:DataPointer):Void {
		
		
		
	}
	
	
	public inline function getQueryObjectui (query:GLQuery, pname:Int):Int {
		
		return 0;
		
	}
	
	
	public function getQueryObjectuiv (query:GLQuery, pname:Int, params:DataPointer):Void {
		
		
		
	}
	
	
	public inline function getQueryParameter (query:GLQuery, pname:Int):Dynamic {
		
		return __context.getQueryParameter (query, pname);
		
	}
	
	
	public inline function getRenderbufferParameter (target:Int, pname:Int):Dynamic {
		
		return __context.getRenderbufferParameter (target, pname);
		
	}
	
	
	public inline function getRenderbufferParameteri (target:Int, pname:Int):Int {
		
		return getRenderbufferParameter (target, pname);
		
	}
	
	
	public function getRenderbufferParameteriv (target:Int, pname:Int, params:DataPointer):Void {
		
		var view = params.toInt32Array ();
		view[0] = getRenderbufferParameter (target, pname);
		
	}
	
	
	public inline function getSamplerParameter (sampler:GLSampler, pname:Int):Dynamic {
		
		return __context.getSamplerParameter (sampler, pname);
		
	}
	
	
	public inline function getSamplerParameterf (sampler:GLSampler, pname:Int):Float {
		
		return 0;
		
	}
	
	
	public function getSamplerParameterfv (sampler:GLSampler, pname:Int, params:DataPointer):Void {
		
		
	}
	
	
	public inline function getSamplerParameteri (sampler:GLSampler, pname:Int):Int {
		
		return 0;
		
	}
	
	
	public function getSamplerParameteriv (sampler:GLSampler, pname:Int, params:DataPointer):Void {
		
		
	}
	
	
	public inline function getShaderi (shader:GLShader, pname:Int):Int {
		
		return getShaderParameter (shader, pname);
		
	}
	
	
	public function getShaderiv (shader:GLShader, pname:Int, params:DataPointer):Void {
		
		var view = params.toInt32Array ();
		view[0] = getShaderParameter (shader, pname);
		
	}
	
	
	public inline function getShaderInfoLog (shader:GLShader):String {
		
		return __context.getShaderInfoLog (shader);
		
	}
	
	
	public inline function getShaderParameter (shader:GLShader, pname:Int):Dynamic {
		
		return __context.getShaderParameter (shader, pname);
		
	}
	
	
	public inline function getShaderPrecisionFormat (shadertype:Int, precisiontype:Int):GLShaderPrecisionFormat {
		
		return __context.getShaderPrecisionFormat (shadertype, precisiontype);
		
	}
	
	
	public inline function getShaderSource (shader:GLShader):String {
		
		return __context.getShaderSource (shader);
		
	}
	
	
	public function getString (pname:Int):String {
		
		if (pname == GL.EXTENSIONS) {
			
			return getSupportedExtensions ().join (" ");
			
		} else {
			
			return getParameter (pname);
			
		}
		
	}
	
	
	public inline function getStringi (name:Int, index:Int):String {
		
		return null;
		
	}
	
	
	public inline function getSupportedExtensions ():Array<String> {
		
		return __context.getSupportedExtensions ();
		
	}
	
	
	public inline function getSyncParameter (sync:GLSync, pname:Int):Dynamic {
		
		return __context.getSyncParameter (sync, pname);
		
	}
	
	
	public inline function getSyncParameteri (sync:GLSync, pname:Int):Int {
		
		return 0;
		
	}
	
	
	public function getSyncParameteriv (sync:GLSync, pname:Int, params:DataPointer):Void {
		
		
	}
	
	
	public inline function getTexParameter (target:Int, pname:Int):Dynamic {
		
		return __context.getTexParameter (target, pname);
		
	}
	
	
	public inline function getTexParameterf (target:Int, pname:Int):Float {
		
		return getTexParameter (target, pname);
		
	}
	
	
	public function getTexParameterfv (target:Int, pname:Int, params:DataPointer):Void {
		
		var view = params.toFloat32Array ();
		view[0] = getTexParameter (target, pname);
		
	}
	
	
	public inline function getTexParameteri (target:Int, pname:Int):Int {
		
		return getTexParameter (target, pname);
		
	}
	
	
	public function getTexParameteriv (target:Int, pname:Int, params:DataPointer):Void {
		
		var view = params.toInt32Array ();
		view[0] = getTexParameter (target, pname);
		
	}
	
	
	public inline function getTransformFeedbackVarying (program:GLProgram, index:Int):GLActiveInfo {
		
		return __context.getTransformFeedbackVarying (program, index);
		
	}
	
	
	public inline function getUniform (program:GLProgram, location:GLUniformLocation):Dynamic {
		
		return __context.getUniform (program, location);
		
	}
	
	
	public inline function getUniformf (program:GLProgram, location:GLUniformLocation):Float {
		
		return getUniform (program, location);
		
	}
	
	
	public function getUniformfv (program:GLProgram, location:GLUniformLocation, params:DataPointer):Void {
		
		var view = params.toFloat32Array ();
		view[0] = getUniformf (program, location);
		
	}
	
	
	public inline function getUniformi (program:GLProgram, location:GLUniformLocation):Dynamic {
		
		return getUniform (program, location);
		
	}
	
	
	public function getUniformiv (program:GLProgram, location:GLUniformLocation, params:DataPointer):Void {
		
		var value = getUniformi (program, location);
		
		var view = params.toInt32Array ();
		view[0] = value;
		
	}
	
	
	public inline function getUniformui (program:GLProgram, location:GLUniformLocation):Int {
		
		return 0;
		
	}
	
	
	public function getUniformuiv (program:GLProgram, location:GLUniformLocation, params:DataPointer):Void {
		
		
	}
	
	
	public inline function getUniformBlockIndex (program:GLProgram, uniformBlockName:String):Int {
		
		return __context.getUniformBlockIndex (program, uniformBlockName);
		
	}
	
	
	//public inline function getUniformIndices (program:GLProgram, uniformNames:String):Array<Int> {
	//public inline function getUniformIndices (program:GLProgram, uniformNames:Array<String>):Array<Int> {
	public inline function getUniformIndices (program:GLProgram, uniformNames:Dynamic):Array<Int> {
		
		return __context.getUniformIndices (program, uniformNames);
		
	}
	
	
	public inline function getUniformLocation (program:GLProgram, name:String):GLUniformLocation {
		
		return __context.getUniformLocation (program, name);
		
	}
	
	
	public inline function getVertexAttrib (index:Int, pname:Int):Dynamic {
		
		return __context.getVertexAttrib (index, pname);
		
	}
	
	
	public inline function getVertexAttribf (index:Int, pname:Int):Float {
		
		return 0;
		
	}
	
	
	public function getVertexAttribfv (index:Int, pname:Int, params:DataPointer):Void {
		
		
		
	}
	
	
	public inline function getVertexAttribi (index:Int, pname:Int):Int {
		
		return 0;
		
	}
	
	
	public inline function getVertexAttribIi (index:Int, pname:Int):Int {
		
		return 0;
		
	}
	
	
	public inline function getVertexAttribIiv (index:Int, pname:Int, params:DataPointer):Void {
		
		
	}
	
	
	public inline function getVertexAttribIui (index:Int, pname:Int):Int {
		
		return 0;
		
	}
	
	
	public inline function getVertexAttribIuiv (index:Int, pname:Int, params:DataPointer):Void {
		
		
	}
	
	
	public function getVertexAttribiv (index:Int, pname:Int, params:DataPointer):Void {
		
		
		
	}
	
	
	@:dox(hide) @:noCompletion public inline function getVertexAttribOffset (index:Int, pname:Int):DataPointer {
		
		return __context.getVertexAttribOffset (index, pname);
		
	}
	
	
	public inline function getVertexAttribPointerv (index:Int, pname:Int):DataPointer {
		
		return getVertexAttribOffset (index, pname);
		
	}
	
	
	public inline function hint (target:Int, mode:Int):Void {
		
		__context.hint (target, mode);
		
	}
	
	
	public inline function invalidateFramebuffer (target:Int, attachments:Array<Int>):Void {
		
		__context.invalidateFramebuffer (target, attachments);
		
	}
	
	
	public inline function invalidateSubFramebuffer (target:Int, attachments:Array<Int>, x:Int, y:Int, width:Int, height:Int):Void {
		
		__context.invalidateSubFramebuffer (target, attachments, x, y, width, height);
		
	}
	
	
	public inline function isBuffer (buffer:GLBuffer):Bool {
		
		return __context.isBuffer (buffer);
		
	}
	
	
	public inline function isContextLost ():Bool {
		
		return __contextLost || __context.isContextLost ();
		
	}
	
	
	public inline function isEnabled (cap:Int):Bool {
		
		return __context.isEnabled (cap);
		
	}
	
	
	public inline function isFramebuffer (framebuffer:GLFramebuffer):Bool {
		
		return __context.isFramebuffer (framebuffer);
		
	}
	
	
	public inline function isProgram (program:GLProgram):Bool {
		
		return __context.isProgram (program);
		
	}
	
	
	public inline function isQuery (query:GLQuery):Bool {
		
		return __context.isQuery (query);
		
	}
	
	
	public inline function isRenderbuffer (renderbuffer:GLRenderbuffer):Bool {
		
		return __context.isRenderbuffer (renderbuffer);
		
	}
	
	
	public inline function isSampler (sampler:GLSampler):Bool {
		
		return __context.isSampler (sampler);
		
	}
	
	
	public inline function isShader (shader:GLShader):Bool {
		
		return __context.isShader (shader);
		
	}
	
	
	public inline function isSync (sync:GLSync):Bool {
		
		return __context.isSync (sync);
		
	}
	
	
	public inline function isTexture (texture:GLTexture):Bool {
		
		return __context.isTexture (texture);
		
	}
	
	
	public inline function isTransformFeedback (transformFeedback:GLTransformFeedback):Bool {
		
		return __context.isTransformFeedback (transformFeedback);
		
	}
	
	
	public inline function isVertexArray (vertexArray:GLVertexArrayObject):Bool {
		
		return __context.isVertexArray (vertexArray);
		
	}
	
	
	public inline function lineWidth (width:Float):Void {
		
		__context.lineWidth (width);
		
	}
	
	
	public inline function linkProgram (program:GLProgram):Void {
		
		__context.linkProgram (program);
		
	}
	
	
	public inline function mapBufferRange (target:Int, offset:DataPointer, length:Int, access:Int):DataPointer {
		
		return 0;
		
	}
	
	
	public inline function pauseTransformFeedback ():Void {
		
		__context.pauseTransformFeedback ();
		
	}
	
	
	public inline function pixelStorei (pname:Int, param:Int):Void {
		
		__context.pixelStorei (pname, param);
		
	}
	
	
	public inline function polygonOffset (factor:Float, units:Float):Void {
		
		__context.polygonOffset (factor, units);
		
	}
	
	
	public inline function programBinary (program:GLProgram, binaryFormat:Int, binary:DataPointer, length:Int):Void {
		
		
		
	}
	
	
	public inline function programParameteri (program:GLProgram, pname:Int, value:Int):Void {
		
		
		
	}
	
	
	public inline function readBuffer (src:Int):Void {
		
		__context.readBuffer (src);
		
	}
	
	
	public inline function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:DataPointer):Void {
		
		__context.readPixels (x, y, width, height, format, type, pixels.toBufferView ());
		
	}
	
	
	//public function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
	//public function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView, ?dstOffset:Int):Void {
	public function readPixelsWEBGL (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView, ?dstOffset:Int):Void {
		
		if (dstOffset != null) {
			
			__context.readPixels (x, y, width, height, format, type, pixels, dstOffset);
			
		} else {
			
			__context.readPixels (x, y, width, height, format, type, pixels);
			
		}
		
	}
	
	
	public inline function releaseShaderCompiler ():Void {
		
		
		
	}
	
	
	public inline function renderbufferStorage (target:Int, internalformat:Int, width:Int, height:Int):Void {
		
		__context.renderbufferStorage (target, internalformat, width, height);
		
	}
	
	
	public inline function renderbufferStorageMultisample (target:Int, samples:Int, internalFormat:Int, width:Int, height:Int):Void {
		
		__context.renderbufferStorageMultisample (target, samples, internalFormat, width, height);
		
	}
	
	
	public inline function resumeTransformFeedback ():Void {
		
		__context.resumeTransformFeedback ();
		
	}
	
	
	public inline function sampleCoverage (value:Float, invert:Bool):Void {
		
		__context.sampleCoverage (value, invert);
		
	}
	
	
	public inline function samplerParameterf (sampler:GLSampler, pname:Int, param:Float):Void {
		
		__context.samplerParameterf (sampler, pname, param);
		
	}
	
	
	public inline function samplerParameteri (sampler:GLSampler, pname:Int, param:Int):Void {
		
		__context.samplerParameteri (sampler, pname, param);
		
	}
	
	
	public inline function scissor (x:Int, y:Int, width:Int, height:Int):Void {
		
		__context.scissor (x, y, width, height);
		
	}
	
	
	public inline function shaderBinary (shaders:Array<GLShader>, binaryformat:Int, binary:DataPointer, length:Int):Void {
		
		
		
	}
	
	
	public inline function shaderSource (shader:GLShader, source:String):Void {
		
		__context.shaderSource (shader, source);
		
	}
	
	
	public inline function stencilFunc (func:Int, ref:Int, mask:Int):Void {
		
		__context.stencilFunc (func, ref, mask);
		
	}
	
	
	public inline function stencilFuncSeparate (face:Int, func:Int, ref:Int, mask:Int):Void {
		
		__context.stencilFuncSeparate (face, func, ref, mask);
		
	}
	
	
	public inline function stencilMask (mask:Int):Void {
		
		__context.stencilMask (mask);
		
	}
	
	
	public inline function stencilMaskSeparate (face:Int, mask:Int):Void {
		
		__context.stencilMaskSeparate (face, mask);
		
	}
	
	
	public inline function stencilOp (fail:Int, zfail:Int, zpass:Int):Void {
		
		__context.stencilOp (fail, zfail, zpass);
		
	}
	
	
	public inline function stencilOpSeparate (face:Int, fail:Int, zfail:Int, zpass:Int):Void {
		
		__context.stencilOpSeparate (face, fail, zfail, zpass);
		
	}
	
	
	public inline function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, data:DataPointer):Void {
		
		__context.texImage2D (target, level, internalformat, width, height, border, format, type, data.toBufferView ());
		
	}
	
	
	//public function texImage2D (target:Int, level:Int, internalformat:Int, format:Int, type:Int, pixels:Dynamic /*ImageBitmap*/):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, format:Int, type:Int, pixels:#if (js && html5) CanvasElement #else Dynamic #end):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, format:Int, type:Int, pixels:#if (js && html5) ImageData #else Dynamic #end):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, format:Int, type:Int, pixels:#if (js && html5) ImageElement #else Dynamic #end):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, format:Int, type:Int, pixels:#if (js && html5) VideoElement #else Dynamic #end):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:CanvasElement):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:Dynamic /*ImageBitmap*/):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:ImageData):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:ImageElement):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, offset:DataPointer):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:VideoElement):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, srcData:ArrayBufferView, srcOffset:Int):Void {
	public function texImage2DWEBGL (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Dynamic, ?format:Int, ?type:Int, ?srcData:Dynamic, ?srcOffset:Int):Void {
		
		if (srcOffset != null) {
			
			__context.texImage2D (target, level, internalformat, width, height, border, format, type, srcData, srcOffset);
			
		} else if (format != null) {
			
			__context.texImage2D (target, level, internalformat, width, height, border, format, type, srcData);
			
		} else {
			
			__context.texImage2D (target, level, internalformat, width, height, border); // target, level, internalformat, format, type, pixels
			
		}
		
	}
	
	
	public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, data:DataPointer):Void {
		
		__context.texImage3D (target, level, internalformat, width, height, depth, border, format, type, data.toBufferView ());
		
	}
	
	
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.CanvasElement):Void {
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.ImageElement):Void {
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.VideoElement):Void {
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:Dynamic /*js.html.ImageBitmap*/):Void {
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.ImageData):Void {
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, offset:DataPointer):Void {
	//public inline function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, srcData:js.html.ArrayBufferView, ?srcOffset:Int):Void {
	public inline function texImage3DWEBGL (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, srcData:Dynamic, ?srcOffset:Int):Void {
		
		__context.texImage3D (target, level, internalformat, width, height, depth, border, format, type, srcData, srcOffset);
		
	}
	
	
	public inline function texStorage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int):Void {
		
		__context.texStorage2D (target, level, internalformat, width, height);
		
	}
	
	
	public inline function texStorage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int):Void {
		
		__context.texStorage3D (target, level, internalformat, width, height, depth);
		
	}
	
	
	public inline function texParameterf (target:Int, pname:Int, param:Float):Void {
		
		__context.texParameterf (target, pname, param);
		
	}
	
	
	public inline function texParameteri (target:Int, pname:Int, param:Int):Void {
		
		__context.texParameteri (target, pname, param);
		
	}
	
	
	public inline function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, data:DataPointer):Void {
		
		__context.texSubImage2D (target, level, xoffset, yoffset, width, height, format, type, data.toBufferView ());
		
	}
	
	
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, pixels:#if (js && html5) CanvasElement #else Dynamic #end):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, pixels:Dynamic /*ImageBitmap*/):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, pixels:#if (js && html5) ImageData #else Dynamic #end):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, pixels:#if (js && html5) ImageElement #else Dynamic #end):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, pixels:#if (js && html5) VideoElement #else Dynamic #end):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:CanvasElement):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:Dynamic /*ImageBitmap*/):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ImageData):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ImageElement):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, offset:DataPointer):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:VideoElement):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, srcData:ArrayBufferView, srcOffset:Int):Void {
	public function texSubImage2DWEBGL (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Dynamic, ?type:Int, ?srcData:Dynamic, ?srcOffset:Int):Void {
		
		if (srcOffset != null) {
			
			__context.texSubImage2D (target, level, xoffset, yoffset, width, height, format, type, srcData, srcOffset);
			
		} else if (type != null) {
			
			__context.texSubImage2D (target, level, xoffset, yoffset, width, height, format, type, srcData);
			
		} else {
			
			__context.texSubImage2D (target, level, xoffset, yoffset, width, height, format); // target, level, xoffset, yoffset, format, type, pixels
			
		}
		
	}
	
	
	public inline function texSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, data:DataPointer):Void {
		
		__context.texSubImage3D (target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, data.toBufferView ());
		
	}
	
	
	//public inline function texSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, offset:DataPointer):Void {
	//public inline function texSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, source:js.html.ImageData):Void {
	//public inline function texSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, source:js.html.ImageElement):Void {
	//public inline function texSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, source:js.html.CanvasElement):Void {
	//public inline function texSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, source:js.html.VideoElement):Void {
	//public inline function texSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, source:Dynamic /*ImageBitmap*/):Void {
	//public inline function texSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, pixels:js.html.ArrayBufferView):Void {
	public inline function texSubImage3DWEBGL (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, source:Dynamic, ?srcOffset:Int):Void {
		
		__context.texSubImage3D (target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, source, srcOffset);
		
	}
	
	
	public inline function transformFeedbackVaryings (program:GLProgram, varyings:Array<String>, bufferMode:Int):Void {
		
		__context.transformFeedbackVaryings (program, varyings, bufferMode);
		
	}
	
	
	public inline function uniform1f (location:GLUniformLocation, v0:Float):Void {
		
		__context.uniform1f (location, v0);
		
	}
	
	
	public inline function uniform1fv (location:GLUniformLocation, count:Int, v:DataPointer):Void {
		
		__context.uniform1fv (location, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT));
		
	}
	
	
	//public function uniform1fv (location:GLUniformLocation, data:Float32Array):Void {
	//public function uniform1fv (location:GLUniformLocation, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
	//public function uniform1fv (location:GLUniformLocation, data:Array<Float>):Void {
	public function uniform1fvWEBGL (location:GLUniformLocation, data:Dynamic, ?srcOffset:Int, ?srcLength:Int):Void {
		
		if (srcOffset != null) {
			
			__context.uniform1fv (location, data, srcOffset, srcLength);
			
		} else {
			
			__context.uniform1fv (location, data);
			
		}
		
	}
	
	
	public inline function uniform1i (location:GLUniformLocation, v0:Int):Void {
		
		__context.uniform1i (location, v0);
		
	}
	
	
	public inline function uniform1iv (location:GLUniformLocation, count:Int, v:DataPointer):Void {
		
		__context.uniform1iv (location, v.toInt32Array (count * Int32Array.BYTES_PER_ELEMENT));
		
	}
	
	
	//public function uniform1iv (location:GLUniformLocation, data:Int32Array):Void {
	//public function uniform1iv (location:GLUniformLocation, data:Int32Array, ?srcOffset:Int, ?srcLength:Int):Void {
	//public function uniform1iv (location:GLUniformLocation, data:Array<Int>):Void {
	public function uniform1ivWEBGL (location:GLUniformLocation, data:Dynamic, ?srcOffset:Int, ?srcLength:Int):Void {
		
		if (srcOffset != null) {
			
			__context.uniform1iv (location, data, srcOffset, srcLength);
			
		} else {
			
			__context.uniform1iv (location, data);
			
		}
		
	}
	
	
	public inline function uniform1ui (location:GLUniformLocation, v0:Int):Void {
		
		return __context.uniform1ui (location, v0);
		
	}
	
	
	public inline function uniform1uiv (location:GLUniformLocation, count:Int, v:DataPointer):Void {
		
		__context.uniform1uiv (location, v.toUInt32Array (count * UInt32Array.BYTES_PER_ELEMENT));
		
	}
	
	
	public inline function uniform1uivWEBGL (location:GLUniformLocation, data:UInt32Array, ?srcOffset:Dynamic, ?srcLength:Int):Void {
		
		__context.uniform1uiv (location, data, srcOffset, srcLength);
		
	}
	
	
	public inline function uniform2f (location:GLUniformLocation, v0:Float, v1:Float):Void {
		
		__context.uniform2f (location, v0, v1);
		
	}
	
	
	public inline function uniform2fv (location:GLUniformLocation, count:Int, v:DataPointer):Void {
		
		__context.uniform2fv (location, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT * 2));
		
	}
	
	
	//public function uniform2fv (location:GLUniformLocation, data:Float32Array):Void {
	//public function uniform2fv (location:GLUniformLocation, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
	//public function uniform2fv (location:GLUniformLocation, data:Array<Float>):Void {
	public function uniform2fvWEBGL (location:GLUniformLocation, data:Dynamic, ?srcOffset:Int, ?srcLength:Int):Void {
		
		if (srcOffset != null) {
			
			__context.uniform2fv (location, data, srcOffset, srcLength);
			
		} else {
			
			__context.uniform2fv (location, data);
			
		}
		
	}
	
	
	public inline function uniform2i (location:GLUniformLocation, x:Int, y:Int):Void {
		
		__context.uniform2i (location, x, y);
		
	}
	
	
	public inline function uniform2iv (location:GLUniformLocation, count:Int, v:DataPointer):Void {
		
		__context.uniform2iv (location, v.toInt32Array (count * Int32Array.BYTES_PER_ELEMENT * 2));
		
	}
	
	
	//public function uniform2iv (location:GLUniformLocation, data:Int32Array):Void {
	//public function uniform2iv (location:GLUniformLocation, data:Int32Array, ?srcOffset:Int, ?srcLength:Int):Void {
	//public function uniform2iv (location:GLUniformLocation, data:Array<Int>):Void {
	public function uniform2ivWEBGL (location:GLUniformLocation, data:Dynamic, ?srcOffset:Int, ?srcLength:Int):Void {
		
		if (srcOffset != null) {
			
			__context.uniform2iv (location, data, srcOffset, srcLength);
			
		} else {
			
			__context.uniform2iv (location, data);
			
		}
		
	}
	
	
	public inline function uniform2ui (location:GLUniformLocation, v0:Int, v1:Int):Void {
		
		__context.uniform2ui (location, v0, v1);
		
	}
	
	
	public inline function uniform2uiv (location:GLUniformLocation, count:Int, v:DataPointer):Void {
		
		__context.uniform2uiv (location, v.toUInt32Array (count * UInt32Array.BYTES_PER_ELEMENT * 2));
		
	}
	
	
	public inline function uniform2uivWEBGL (location:GLUniformLocation, data:UInt32Array, ?srcOffset:Dynamic, ?srcLength:Int):Void {
		
		__context.uniform2uiv (location, data, srcOffset, srcLength);
		
	}
	
	
	public inline function uniform3f (location:GLUniformLocation, v0:Float, v1:Float, v2:Float):Void {
		
		__context.uniform3f (location, v0, v1, v2);
		
	}
	
	
	public inline function uniform3fv (location:GLUniformLocation, count:Int, v:DataPointer):Void {
		
		__context.uniform3fv (location, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT * 3));
		
	}
	
	
	//public function uniform3fv (location:GLUniformLocation, data:Float32Array):Void {
	//public function uniform3fv (location:GLUniformLocation, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
	//public function uniform3fv (location:GLUniformLocation, data:Array<Float>):Void {
	public function uniform3fvWEBGL (location:GLUniformLocation, data:Dynamic, ?srcOffset:Int, ?srcLength:Int):Void {
		
		if (srcOffset != null) {
			
			__context.uniform3fv (location, data, srcOffset, srcLength);
			
		} else {
			
			__context.uniform3fv (location, data);
			
		}
		
	}
	
	
	public inline function uniform3i (location:GLUniformLocation, x:Int, y:Int, z:Int):Void {
		
		__context.uniform3i (location, x, y, z);
		
	}
	
	
	public inline function uniform3iv (location:GLUniformLocation, count:Int, v:DataPointer):Void {
		
		__context.uniform3iv (location, v.toInt32Array (count * Int32Array.BYTES_PER_ELEMENT * 3));
		
	}
	
	
	//public function uniform3iv (location:GLUniformLocation, data:Int32Array):Void {
	//public function uniform3iv (location:GLUniformLocation, data:Int32Array, ?srcOffset:Int, ?srcLength:Int):Void {
	//public function uniform3iv (location:GLUniformLocation, data:Array<Int>):Void {
	public function uniform3ivWEBGL (location:GLUniformLocation, data:Dynamic, ?srcOffset:Int, ?srcLength:Int):Void {
		
		if (srcOffset != null) {
			
			__context.uniform3iv (location, data, srcOffset, srcLength);
			
		} else {
			
			__context.uniform3iv (location, data);
			
		}
		
	}
	
	
	public inline function uniform3ui (location:GLUniformLocation, v0:Int, v1:Int, v2:Int):Void {
		
		__context.uniform3ui (location, v0, v1, v2);
		
	}
	
	
	public inline function uniform3uiv (location:GLUniformLocation, count:Int, v:DataPointer):Void {
		
		__context.uniform3uiv (location, v.toUInt32Array (count * UInt32Array.BYTES_PER_ELEMENT * 3));
		
	}
	
	
	public inline function uniform3uivWEBGL (location:GLUniformLocation, data:UInt32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		__context.uniform3uiv (location, data, srcOffset, srcLength);
		
	}
	
	
	public inline function uniform4f (location:GLUniformLocation, v0:Float, v1:Float, v2:Float, v3:Float):Void {
		
		__context.uniform4f (location, v0, v1, v2, v3);
		
	}
	
	
	public inline function uniform4fv (location:GLUniformLocation, count:Int, v:DataPointer):Void {
		
		__context.uniform4fv (location, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT * 4));
		
	}
	
	
	//public function uniform4fv (location:GLUniformLocation, data:Float32Array):Void {
	//public function uniform4fv (location:GLUniformLocation, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
	//public function uniform4fv (location:GLUniformLocation, data:Array<Float>):Void {
	public function uniform4fvWEBGL (location:GLUniformLocation, data:Dynamic, ?srcOffset:Int, ?srcLength:Int):Void {
		
		if (srcOffset != null) {
			
			__context.uniform4fv (location, data, srcOffset, srcLength);
			
		} else {
			
			__context.uniform4fv (location, data);
			
		}
		
	}
	
	
	public inline function uniform4i (location:GLUniformLocation, v0:Int, v1:Int, v2:Int, v3:Int):Void {
		
		__context.uniform4i (location, v0, v1, v2, v3);
		
	}
	
	
	public inline function uniform4iv (location:GLUniformLocation, count:Int, v:DataPointer):Void {
		
		__context.uniform4iv (location, v.toInt32Array (count * Int32Array.BYTES_PER_ELEMENT * 4));
		
	}
	
	
	//public function uniform4iv (location:GLUniformLocation, data:Int32Array):Void {
	//public function uniform4iv (location:GLUniformLocation, data:Int32Array, ?srcOffset:Int, ?srcLength:Int):Void {
	//public function uniform4iv (location:GLUniformLocation, data:Array<Int>):Void {
	public function uniform4ivWEBGL (location:GLUniformLocation, data:Dynamic, ?srcOffset:Int, ?srcLength:Int):Void {
		
		if (srcOffset != null) {
			
			__context.uniform4iv (location, data, srcOffset, srcLength);
			
		} else {
			
			__context.uniform4iv (location, data);
			
		}
		
	}
	
	
	public inline function uniform4ui (location:GLUniformLocation, v0:Int, v1:Int, v2:Int, v3:Int):Void {
		
		__context.uniform4ui (location, v0, v1, v2, v3);
		
	}
	
	
	public inline function uniform4uiv (location:GLUniformLocation, count:Int, v:DataPointer):Void {
		
		__context.uniform4uiv (location, v.toUInt32Array (count * UInt32Array.BYTES_PER_ELEMENT * 4));
		
	}
	
	
	public inline function uniform4uivWEBGL (location:GLUniformLocation, data:UInt32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		__context.uniform4uiv (location, data, srcOffset, srcLength);
		
	}
	
	
	public inline function uniformBlockBinding (program:GLProgram, uniformBlockIndex:Int, uniformBlockBinding:Int):Void {
		
		__context.uniformBlockBinding (program, uniformBlockIndex, uniformBlockBinding);
		
	}
	
	
	public inline function uniformMatrix2fv (location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void {
		
		__context.uniformMatrix2fv (location, transpose, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT * 4));
		
	}
	
	
	//public function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, data:Float32Array):Void {
	//public function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
	//public function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, data:Array<Float>):Void {
	public function uniformMatrix2fvWEBGL (location:GLUniformLocation, transpose:Bool, ?data:Dynamic, ?srcOffset:Int, ?srcLength:Int):Void {
		
		if (srcOffset != null) {
			
			__context.uniformMatrix2fv (location, transpose, data, srcOffset, srcLength);
			
		} else {
			
			__context.uniformMatrix2fv (location, transpose, data);
			
		}
		
	}
	
	
	public inline function uniformMatrix2x3fv (location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void {
		
		__context.uniformMatrix2x3fv (location, transpose, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT * 6));
		
	}
	
	
	public inline function uniformMatrix2x3fvWEBGL (location:GLUniformLocation, transpose:Bool, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		__context.uniformMatrix2x3fv (location, transpose, data, srcOffset, srcLength);
		
	}
	
	
	public inline function uniformMatrix2x4fv (location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void {
		
		__context.uniformMatrix2x4fv (location, transpose, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT * 8));
		
	}
	
	
	public inline function uniformMatrix2x4fvWEBGL (location:GLUniformLocation, transpose:Bool, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		__context.uniformMatrix2x4fv (location, transpose, data, srcOffset, srcLength);
		
	}
	
	
	public inline function uniformMatrix3fv (location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void {
		
		__context.uniformMatrix3fv (location, transpose, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT * 9));
		
	}
	
	
	//public function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, data:Float32Array):Void {
	//public function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
	//public function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, data:Array<Float>):Void {
	public function uniformMatrix3fvWEBGL (location:GLUniformLocation, transpose:Bool, ?data:Dynamic, ?srcOffset:Int, ?srcLength:Int):Void {
		
		if (srcOffset != null) {
			
			__context.uniformMatrix3fv (location, transpose, data, srcOffset, srcLength);
			
		} else {
			
			__context.uniformMatrix3fv (location, transpose, data);
			
		}
		
	}
	
	
	public inline function uniformMatrix3x2fv (location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void {
		
		__context.uniformMatrix3x2fv (location, transpose, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT * 6));
		
	}
	
	
	public inline function uniformMatrix3x2fvWEBGL (location:GLUniformLocation, transpose:Bool, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		__context.uniformMatrix3x2fv (location, transpose, data, srcOffset, srcLength);
		
	}
	
	
	public inline function uniformMatrix3x4fv (location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void {
		
		__context.uniformMatrix3x4fv (location, transpose, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT * 12));
		
	}
	
	
	public inline function uniformMatrix3x4fvWEBGL (location:GLUniformLocation, transpose:Bool, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		__context.uniformMatrix3x4fv (location, transpose, data, srcOffset, srcLength);
		
	}
	
	
	public inline function uniformMatrix4fv (location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void {
		
		__context.uniformMatrix4fv (location, transpose, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT * 16));
		
	}
	
	
	//public function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, data:Float32Array):Void {
	//public function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
	//public function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, data:Array<Float>):Void {
	public function uniformMatrix4fvWEBGL (location:GLUniformLocation, transpose:Bool, ?data:Dynamic, ?srcOffset:Int, ?srcLength:Int):Void {
		
		if (srcOffset != null) {
			
			__context.uniformMatrix4fv (location, transpose, data, srcOffset, srcLength);
			
		} else {
			
			__context.uniformMatrix4fv (location, transpose, data);
			
		}
		
	}
	
	
	public inline function uniformMatrix4x2fv (location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void {
		
		__context.uniformMatrix4x2fv (location, transpose, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT * 8));
		
	}
	
	
	public function uniformMatrix4x2fvWEBGL (location:GLUniformLocation, transpose:Bool, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		if (srcOffset != null) {
			
			__context.uniformMatrix4x2fv (location, transpose, data, srcOffset, srcLength);
			
		} else {
			
			__context.uniformMatrix4x2fv (location, transpose, data);
			
		}
		
	}
	
	
	public inline function uniformMatrix4x3fv (location:GLUniformLocation, count:Int, transpose:Bool, v:DataPointer):Void {
		
		__context.uniformMatrix4x3fv (location, transpose, v.toFloat32Array (count * Float32Array.BYTES_PER_ELEMENT * 12));
		
	}
	
	
	public inline function uniformMatrix4x3fvWEBGL (location:GLUniformLocation, transpose:Bool, data:Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {
		
		__context.uniformMatrix4x3fv (location, transpose, data, srcOffset, srcLength);
		
	}
	
	
	public inline function unmapBuffer (target:Int):Bool {
		
		return false;
		
	}
	
	
	public inline function useProgram (program:GLProgram):Void {
		
		__context.useProgram (program);
		
	}
	
	
	public inline function validateProgram (program:GLProgram):Void {
		
		__context.validateProgram (program);
		
	}
	
	
	public inline function vertexAttrib1f (index:Int, v0:Float):Void {
		
		__context.vertexAttrib1f (index, v0);
		
	}
	
	
	public inline function vertexAttrib1fv (index:Int, v:DataPointer):Void {
		
		__context.vertexAttrib1fv (index, v.toFloat32Array ());
		
	}
	
	
	//public function vertexAttrib1fv (index:Int, v:Float32Array):Void {
	//public function vertexAttrib1fv (index:Int, v:Array<Float>):Void {
	public inline function vertexAttrib1fvWEBGL (index:Int, v:Dynamic):Void {
		
		__context.vertexAttrib1fv (index, v);
		
	}
	
	
	public inline function vertexAttrib2f (index:Int, v0:Float, v1:Float):Void {
		
		__context.vertexAttrib2f (index, v0, v1);
		
	}
	
	
	public inline function vertexAttrib2fv (index:Int, v:DataPointer):Void {
		
		__context.vertexAttrib2fv (index, v.toFloat32Array ());
		
	}
	
	
	//public function vertexAttrib2fv (index:Int, v:Float32Array):Void {
	//public function vertexAttrib2fv (index:Int, v:Array<Float>):Void {
	public inline function vertexAttrib2fvWEBGL (index:Int, v:Dynamic):Void {
		
		__context.vertexAttrib2fv (index, v);
		
	}
	
	
	public inline function vertexAttrib3f (index:Int, v0:Float, v1:Float, v2:Float):Void {
		
		__context.vertexAttrib3f (index, v0, v1, v2);
		
	}
	
	
	public inline function vertexAttrib3fv (index:Int, v:DataPointer):Void {
		
		__context.vertexAttrib3fv (index, v.toFloat32Array ());
		
	}
	
	
	//public function vertexAttrib3fv (index:Int, v:Float32Array):Void {
	//public function vertexAttrib3fv (index:Int, v:Array<Float>):Void {
	public inline function vertexAttrib3fvWEBGL (index:Int, v:Dynamic):Void {
		
		__context.vertexAttrib3fv (index, v);
		
	}
	
	
	public inline function vertexAttrib4f (index:Int, v0:Float, v1:Float, v2:Float, v3:Float):Void {
		
		__context.vertexAttrib4f (index, v0, v1, v2, v3);
		
	}
	
	
	public inline function vertexAttrib4fv (index:Int, v:DataPointer):Void {
		
		__context.vertexAttrib4fv (index, v.toFloat32Array ());
		
	}
	
	
	//public function vertexAttrib4fv (index:Int, v:Float32Array):Void {
	//public function vertexAttrib4fv (index:Int, v:Array<Float>):Void {
	public inline function vertexAttrib4fvWEBGL (index:Int, v:Dynamic):Void {
		
		__context.vertexAttrib4fv (index, v);
		
	}
	
	
	public inline function vertexAttribDivisor (index:Int, divisor:Int):Void {
		
		__context.vertexAttribDivisor (index, divisor);
		
	}
	
	
	public inline function vertexAttribI4i (index:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void {
		
		__context.vertexAttribI4i (index, v0, v1, v2, v3);
		
	}
	
	
	public inline function vertexAttribI4iv (index:Int, v:DataPointer):Void {
		
		__context.vertexAttribI4iv (index, v.toInt32Array ());
		
	}
	
	
	//public function vertexAttribI4iv (index:Int, v:js.html.Int32Array) {
	//public function vertexAttribI4iv (index:Int, v:Array<Int>) {
	public inline function vertexAttribI4ivWEBGL (index:Int, v:Dynamic):Void {
		
		__context.vertexAttribI4iv (index, v);
		
	}
	
	
	public inline function vertexAttribI4ui (index:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void {
		
		__context.vertexAttribI4ui (index, v0, v1, v2, v3);
		
	}
	
	
	public inline function vertexAttribI4uiv (index:Int, v:DataPointer):Void {
		
		__context.vertexAttribI4uiv (index, v.toUInt32Array ());
		
	}
	
	
	//public function vertexAttribI4iv (index:Int, v:js.html.Uint32Array) {
	//public function vertexAttribI4iv (index:Int, v:Array<Int>) {
	public inline function vertexAttribI4uivWEBGL (index:Int, v:Dynamic):Void {
		
		__context.vertexAttribI4uiv (index, v);
		
	}
	
	
	public inline function vertexAttribIPointer (index:Int, size:Int, type:Int, stride:Int, offset:DataPointer):Void {
		
		__context.vertexAttribIPointer (index, size, type, stride, offset.toValue ());
		
	}
	
	
	public inline function vertexAttribPointer (index:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:DataPointer):Void {
		
		__context.vertexAttribPointer (index, size, type, normalized, stride, offset.toValue ());
		
	}
	
	
	public inline function viewport (x:Int, y:Int, width:Int, height:Int):Void {
		
		__context.viewport (x, y, width, height);
		
	}
	
	
	//public inline function waitSync (sync:GLSync, flags:Int, timeout:Dynamic):Void {
	//public inline function waitSync (sync:GLSync, flags:Int, timeout:Int64):Void {
	public inline function waitSync (sync:GLSync, flags:Int, timeout:Dynamic /*int64*/):Void {
		
		__context.waitSync (sync, flags, timeout);
		
	}
	
	
	#if (js && html5)
	private function get_canvas ():CanvasElement {
		
		return __context.canvas;
		
	}
	
	
	private function get_drawingBufferHeight ():Int {
		
		return __context.drawingBufferHeight;
		
	}
	
	
	private function get_drawingBufferWidth ():Int {
		
		return __context.drawingBufferWidth;
		
	}
	#end
	
	
}


@:native("WebGL2RenderingContext")
extern class WebGL2RenderingContext extends WebGLRenderingContext {
	
	
	public static inline var DEPTH_BUFFER_BIT:Int = 256;
	public static inline var STENCIL_BUFFER_BIT:Int = 1024;
	public static inline var COLOR_BUFFER_BIT:Int = 16384;
	public static inline var POINTS:Int = 0;
	public static inline var LINES:Int = 1;
	public static inline var LINE_LOOP:Int = 2;
	public static inline var LINE_STRIP:Int = 3;
	public static inline var TRIANGLES:Int = 4;
	public static inline var TRIANGLE_STRIP:Int = 5;
	public static inline var TRIANGLE_FAN:Int = 6;
	public static inline var ZERO:Int = 0;
	public static inline var ONE:Int = 1;
	public static inline var SRC_COLOR:Int = 768;
	public static inline var ONE_MINUS_SRC_COLOR:Int = 769;
	public static inline var SRC_ALPHA:Int = 770;
	public static inline var ONE_MINUS_SRC_ALPHA:Int = 771;
	public static inline var DST_ALPHA:Int = 772;
	public static inline var ONE_MINUS_DST_ALPHA:Int = 773;
	public static inline var DST_COLOR:Int = 774;
	public static inline var ONE_MINUS_DST_COLOR:Int = 775;
	public static inline var SRC_ALPHA_SATURATE:Int = 776;
	public static inline var FUNC_ADD:Int = 32774;
	public static inline var BLEND_EQUATION:Int = 32777;
	public static inline var BLEND_EQUATION_RGB:Int = 32777;
	public static inline var BLEND_EQUATION_ALPHA:Int = 34877;
	public static inline var FUNC_SUBTRACT:Int = 32778;
	public static inline var FUNC_REVERSE_SUBTRACT:Int = 32779;
	public static inline var BLEND_DST_RGB:Int = 32968;
	public static inline var BLEND_SRC_RGB:Int = 32969;
	public static inline var BLEND_DST_ALPHA:Int = 32970;
	public static inline var BLEND_SRC_ALPHA:Int = 32971;
	public static inline var CONSTANT_COLOR:Int = 32769;
	public static inline var ONE_MINUS_CONSTANT_COLOR:Int = 32770;
	public static inline var CONSTANT_ALPHA:Int = 32771;
	public static inline var ONE_MINUS_CONSTANT_ALPHA:Int = 32772;
	public static inline var BLEND_COLOR:Int = 32773;
	public static inline var ARRAY_BUFFER:Int = 34962;
	public static inline var ELEMENT_ARRAY_BUFFER:Int = 34963;
	public static inline var ARRAY_BUFFER_BINDING:Int = 34964;
	public static inline var ELEMENT_ARRAY_BUFFER_BINDING:Int = 34965;
	public static inline var STREAM_DRAW:Int = 35040;
	public static inline var STATIC_DRAW:Int = 35044;
	public static inline var DYNAMIC_DRAW:Int = 35048;
	public static inline var BUFFER_SIZE:Int = 34660;
	public static inline var BUFFER_USAGE:Int = 34661;
	public static inline var CURRENT_VERTEX_ATTRIB:Int = 34342;
	public static inline var FRONT:Int = 1028;
	public static inline var BACK:Int = 1029;
	public static inline var FRONT_AND_BACK:Int = 1032;
	public static inline var CULL_FACE:Int = 2884;
	public static inline var BLEND:Int = 3042;
	public static inline var DITHER:Int = 3024;
	public static inline var STENCIL_TEST:Int = 2960;
	public static inline var DEPTH_TEST:Int = 2929;
	public static inline var SCISSOR_TEST:Int = 3089;
	public static inline var POLYGON_OFFSET_FILL:Int = 32823;
	public static inline var SAMPLE_ALPHA_TO_COVERAGE:Int = 32926;
	public static inline var SAMPLE_COVERAGE:Int = 32928;
	public static inline var NO_ERROR:Int = 0;
	public static inline var INVALID_ENUM:Int = 1280;
	public static inline var INVALID_VALUE:Int = 1281;
	public static inline var INVALID_OPERATION:Int = 1282;
	public static inline var OUT_OF_MEMORY:Int = 1285;
	public static inline var CW:Int = 2304;
	public static inline var CCW:Int = 2305;
	public static inline var LINE_WIDTH:Int = 2849;
	public static inline var ALIASED_POINT_SIZE_RANGE:Int = 33901;
	public static inline var ALIASED_LINE_WIDTH_RANGE:Int = 33902;
	public static inline var CULL_FACE_MODE:Int = 2885;
	public static inline var FRONT_FACE:Int = 2886;
	public static inline var DEPTH_RANGE:Int = 2928;
	public static inline var DEPTH_WRITEMASK:Int = 2930;
	public static inline var DEPTH_CLEAR_VALUE:Int = 2931;
	public static inline var DEPTH_FUNC:Int = 2932;
	public static inline var STENCIL_CLEAR_VALUE:Int = 2961;
	public static inline var STENCIL_FUNC:Int = 2962;
	public static inline var STENCIL_FAIL:Int = 2964;
	public static inline var STENCIL_PASS_DEPTH_FAIL:Int = 2965;
	public static inline var STENCIL_PASS_DEPTH_PASS:Int = 2966;
	public static inline var STENCIL_REF:Int = 2967;
	public static inline var STENCIL_VALUE_MASK:Int = 2963;
	public static inline var STENCIL_WRITEMASK:Int = 2968;
	public static inline var STENCIL_BACK_FUNC:Int = 34816;
	public static inline var STENCIL_BACK_FAIL:Int = 34817;
	public static inline var STENCIL_BACK_PASS_DEPTH_FAIL:Int = 34818;
	public static inline var STENCIL_BACK_PASS_DEPTH_PASS:Int = 34819;
	public static inline var STENCIL_BACK_REF:Int = 36003;
	public static inline var STENCIL_BACK_VALUE_MASK:Int = 36004;
	public static inline var STENCIL_BACK_WRITEMASK:Int = 36005;
	public static inline var VIEWPORT:Int = 2978;
	public static inline var SCISSOR_BOX:Int = 3088;
	public static inline var COLOR_CLEAR_VALUE:Int = 3106;
	public static inline var COLOR_WRITEMASK:Int = 3107;
	public static inline var UNPACK_ALIGNMENT:Int = 3317;
	public static inline var PACK_ALIGNMENT:Int = 3333;
	public static inline var MAX_TEXTURE_SIZE:Int = 3379;
	public static inline var MAX_VIEWPORT_DIMS:Int = 3386;
	public static inline var SUBPIXEL_BITS:Int = 3408;
	public static inline var RED_BITS:Int = 3410;
	public static inline var GREEN_BITS:Int = 3411;
	public static inline var BLUE_BITS:Int = 3412;
	public static inline var ALPHA_BITS:Int = 3413;
	public static inline var DEPTH_BITS:Int = 3414;
	public static inline var STENCIL_BITS:Int = 3415;
	public static inline var POLYGON_OFFSET_UNITS:Int = 10752;
	public static inline var POLYGON_OFFSET_FACTOR:Int = 32824;
	public static inline var TEXTURE_BINDING_2D:Int = 32873;
	public static inline var SAMPLE_BUFFERS:Int = 32936;
	public static inline var SAMPLES:Int = 32937;
	public static inline var SAMPLE_COVERAGE_VALUE:Int = 32938;
	public static inline var SAMPLE_COVERAGE_INVERT:Int = 32939;
	public static inline var COMPRESSED_TEXTURE_FORMATS:Int = 34467;
	public static inline var DONT_CARE:Int = 4352;
	public static inline var FASTEST:Int = 4353;
	public static inline var NICEST:Int = 4354;
	public static inline var GENERATE_MIPMAP_HINT:Int = 33170;
	public static inline var BYTE:Int = 5120;
	public static inline var UNSIGNED_BYTE:Int = 5121;
	public static inline var SHORT:Int = 5122;
	public static inline var UNSIGNED_SHORT:Int = 5123;
	public static inline var INT:Int = 5124;
	public static inline var UNSIGNED_INT:Int = 5125;
	public static inline var FLOAT:Int = 5126;
	public static inline var DEPTH_COMPONENT:Int = 6402;
	public static inline var ALPHA:Int = 6406;
	public static inline var RGB:Int = 6407;
	public static inline var RGBA:Int = 6408;
	public static inline var LUMINANCE:Int = 6409;
	public static inline var LUMINANCE_ALPHA:Int = 6410;
	public static inline var UNSIGNED_SHORT_4_4_4_4:Int = 32819;
	public static inline var UNSIGNED_SHORT_5_5_5_1:Int = 32820;
	public static inline var UNSIGNED_SHORT_5_6_5:Int = 33635;
	public static inline var FRAGMENT_SHADER:Int = 35632;
	public static inline var VERTEX_SHADER:Int = 35633;
	public static inline var MAX_VERTEX_ATTRIBS:Int = 34921;
	public static inline var MAX_VERTEX_UNIFORM_VECTORS:Int = 36347;
	public static inline var MAX_VARYING_VECTORS:Int = 36348;
	public static inline var MAX_COMBINED_TEXTURE_IMAGE_UNITS:Int = 35661;
	public static inline var MAX_VERTEX_TEXTURE_IMAGE_UNITS:Int = 35660;
	public static inline var MAX_TEXTURE_IMAGE_UNITS:Int = 34930;
	public static inline var MAX_FRAGMENT_UNIFORM_VECTORS:Int = 36349;
	public static inline var SHADER_TYPE:Int = 35663;
	public static inline var DELETE_STATUS:Int = 35712;
	public static inline var LINK_STATUS:Int = 35714;
	public static inline var VALIDATE_STATUS:Int = 35715;
	public static inline var ATTACHED_SHADERS:Int = 35717;
	public static inline var ACTIVE_UNIFORMS:Int = 35718;
	public static inline var ACTIVE_ATTRIBUTES:Int = 35721;
	public static inline var SHADING_LANGUAGE_VERSION:Int = 35724;
	public static inline var CURRENT_PROGRAM:Int = 35725;
	public static inline var NEVER:Int = 512;
	public static inline var LESS:Int = 513;
	public static inline var EQUAL:Int = 514;
	public static inline var LEQUAL:Int = 515;
	public static inline var GREATER:Int = 516;
	public static inline var NOTEQUAL:Int = 517;
	public static inline var GEQUAL:Int = 518;
	public static inline var ALWAYS:Int = 519;
	public static inline var KEEP:Int = 7680;
	public static inline var REPLACE:Int = 7681;
	public static inline var INCR:Int = 7682;
	public static inline var DECR:Int = 7683;
	public static inline var INVERT:Int = 5386;
	public static inline var INCR_WRAP:Int = 34055;
	public static inline var DECR_WRAP:Int = 34056;
	public static inline var VENDOR:Int = 7936;
	public static inline var RENDERER:Int = 7937;
	public static inline var VERSION:Int = 7938;
	public static inline var NEAREST:Int = 9728;
	public static inline var LINEAR:Int = 9729;
	public static inline var NEAREST_MIPMAP_NEAREST:Int = 9984;
	public static inline var LINEAR_MIPMAP_NEAREST:Int = 9985;
	public static inline var NEAREST_MIPMAP_LINEAR:Int = 9986;
	public static inline var LINEAR_MIPMAP_LINEAR:Int = 9987;
	public static inline var TEXTURE_MAG_FILTER:Int = 10240;
	public static inline var TEXTURE_MIN_FILTER:Int = 10241;
	public static inline var TEXTURE_WRAP_S:Int = 10242;
	public static inline var TEXTURE_WRAP_T:Int = 10243;
	public static inline var TEXTURE_2D:Int = 3553;
	public static inline var TEXTURE:Int = 5890;
	public static inline var TEXTURE_CUBE_MAP:Int = 34067;
	public static inline var TEXTURE_BINDING_CUBE_MAP:Int = 34068;
	public static inline var TEXTURE_CUBE_MAP_POSITIVE_X:Int = 34069;
	public static inline var TEXTURE_CUBE_MAP_NEGATIVE_X:Int = 34070;
	public static inline var TEXTURE_CUBE_MAP_POSITIVE_Y:Int = 34071;
	public static inline var TEXTURE_CUBE_MAP_NEGATIVE_Y:Int = 34072;
	public static inline var TEXTURE_CUBE_MAP_POSITIVE_Z:Int = 34073;
	public static inline var TEXTURE_CUBE_MAP_NEGATIVE_Z:Int = 34074;
	public static inline var MAX_CUBE_MAP_TEXTURE_SIZE:Int = 34076;
	public static inline var TEXTURE0:Int = 33984;
	public static inline var TEXTURE1:Int = 33985;
	public static inline var TEXTURE2:Int = 33986;
	public static inline var TEXTURE3:Int = 33987;
	public static inline var TEXTURE4:Int = 33988;
	public static inline var TEXTURE5:Int = 33989;
	public static inline var TEXTURE6:Int = 33990;
	public static inline var TEXTURE7:Int = 33991;
	public static inline var TEXTURE8:Int = 33992;
	public static inline var TEXTURE9:Int = 33993;
	public static inline var TEXTURE10:Int = 33994;
	public static inline var TEXTURE11:Int = 33995;
	public static inline var TEXTURE12:Int = 33996;
	public static inline var TEXTURE13:Int = 33997;
	public static inline var TEXTURE14:Int = 33998;
	public static inline var TEXTURE15:Int = 33999;
	public static inline var TEXTURE16:Int = 34000;
	public static inline var TEXTURE17:Int = 34001;
	public static inline var TEXTURE18:Int = 34002;
	public static inline var TEXTURE19:Int = 34003;
	public static inline var TEXTURE20:Int = 34004;
	public static inline var TEXTURE21:Int = 34005;
	public static inline var TEXTURE22:Int = 34006;
	public static inline var TEXTURE23:Int = 34007;
	public static inline var TEXTURE24:Int = 34008;
	public static inline var TEXTURE25:Int = 34009;
	public static inline var TEXTURE26:Int = 34010;
	public static inline var TEXTURE27:Int = 34011;
	public static inline var TEXTURE28:Int = 34012;
	public static inline var TEXTURE29:Int = 34013;
	public static inline var TEXTURE30:Int = 34014;
	public static inline var TEXTURE31:Int = 34015;
	public static inline var ACTIVE_TEXTURE:Int = 34016;
	public static inline var REPEAT:Int = 10497;
	public static inline var CLAMP_TO_EDGE:Int = 33071;
	public static inline var MIRRORED_REPEAT:Int = 33648;
	public static inline var FLOAT_VEC2:Int = 35664;
	public static inline var FLOAT_VEC3:Int = 35665;
	public static inline var FLOAT_VEC4:Int = 35666;
	public static inline var INT_VEC2:Int = 35667;
	public static inline var INT_VEC3:Int = 35668;
	public static inline var INT_VEC4:Int = 35669;
	public static inline var BOOL:Int = 35670;
	public static inline var BOOL_VEC2:Int = 35671;
	public static inline var BOOL_VEC3:Int = 35672;
	public static inline var BOOL_VEC4:Int = 35673;
	public static inline var FLOAT_MAT2:Int = 35674;
	public static inline var FLOAT_MAT3:Int = 35675;
	public static inline var FLOAT_MAT4:Int = 35676;
	public static inline var SAMPLER_2D:Int = 35678;
	public static inline var SAMPLER_CUBE:Int = 35680;
	public static inline var VERTEX_ATTRIB_ARRAY_ENABLED:Int = 34338;
	public static inline var VERTEX_ATTRIB_ARRAY_SIZE:Int = 34339;
	public static inline var VERTEX_ATTRIB_ARRAY_STRIDE:Int = 34340;
	public static inline var VERTEX_ATTRIB_ARRAY_TYPE:Int = 34341;
	public static inline var VERTEX_ATTRIB_ARRAY_NORMALIZED:Int = 34922;
	public static inline var VERTEX_ATTRIB_ARRAY_POINTER:Int = 34373;
	public static inline var VERTEX_ATTRIB_ARRAY_BUFFER_BINDING:Int = 34975;
	public static inline var IMPLEMENTATION_COLOR_READ_TYPE:Int = 35738;
	public static inline var IMPLEMENTATION_COLOR_READ_FORMAT:Int = 35739;
	public static inline var COMPILE_STATUS:Int = 35713;
	public static inline var LOW_FLOAT:Int = 36336;
	public static inline var MEDIUM_FLOAT:Int = 36337;
	public static inline var HIGH_FLOAT:Int = 36338;
	public static inline var LOW_INT:Int = 36339;
	public static inline var MEDIUM_INT:Int = 36340;
	public static inline var HIGH_INT:Int = 36341;
	public static inline var FRAMEBUFFER:Int = 36160;
	public static inline var RENDERBUFFER:Int = 36161;
	public static inline var RGBA4:Int = 32854;
	public static inline var RGB5_A1:Int = 32855;
	public static inline var RGB565:Int = 36194;
	public static inline var DEPTH_COMPONENT16:Int = 33189;
	public static inline var STENCIL_INDEX:Int = 6401;
	public static inline var STENCIL_INDEX8:Int = 36168;
	public static inline var DEPTH_STENCIL:Int = 34041;
	public static inline var RENDERBUFFER_WIDTH:Int = 36162;
	public static inline var RENDERBUFFER_HEIGHT:Int = 36163;
	public static inline var RENDERBUFFER_INTERNAL_FORMAT:Int = 36164;
	public static inline var RENDERBUFFER_RED_SIZE:Int = 36176;
	public static inline var RENDERBUFFER_GREEN_SIZE:Int = 36177;
	public static inline var RENDERBUFFER_BLUE_SIZE:Int = 36178;
	public static inline var RENDERBUFFER_ALPHA_SIZE:Int = 36179;
	public static inline var RENDERBUFFER_DEPTH_SIZE:Int = 36180;
	public static inline var RENDERBUFFER_STENCIL_SIZE:Int = 36181;
	public static inline var FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE:Int = 36048;
	public static inline var FRAMEBUFFER_ATTACHMENT_OBJECT_NAME:Int = 36049;
	public static inline var FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL:Int = 36050;
	public static inline var FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE:Int = 36051;
	public static inline var COLOR_ATTACHMENT0:Int = 36064;
	public static inline var DEPTH_ATTACHMENT:Int = 36096;
	public static inline var STENCIL_ATTACHMENT:Int = 36128;
	public static inline var DEPTH_STENCIL_ATTACHMENT:Int = 33306;
	public static inline var NONE:Int = 0;
	public static inline var FRAMEBUFFER_COMPLETE:Int = 36053;
	public static inline var FRAMEBUFFER_INCOMPLETE_ATTACHMENT:Int = 36054;
	public static inline var FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:Int = 36055;
	public static inline var FRAMEBUFFER_INCOMPLETE_DIMENSIONS:Int = 36057;
	public static inline var FRAMEBUFFER_UNSUPPORTED:Int = 36061;
	public static inline var FRAMEBUFFER_BINDING:Int = 36006;
	public static inline var RENDERBUFFER_BINDING:Int = 36007;
	public static inline var MAX_RENDERBUFFER_SIZE:Int = 34024;
	public static inline var INVALID_FRAMEBUFFER_OPERATION:Int = 1286;
	public static inline var UNPACK_FLIP_Y_WEBGL:Int = 37440;
	public static inline var UNPACK_PREMULTIPLY_ALPHA_WEBGL:Int = 37441;
	public static inline var CONTEXT_LOST_WEBGL:Int = 37442;
	public static inline var UNPACK_COLORSPACE_CONVERSION_WEBGL:Int = 37443;
	public static inline var BROWSER_DEFAULT_WEBGL:Int = 37444;
	
	public static inline var READ_BUFFER = 0x0C02;
	public static inline var UNPACK_ROW_LENGTH = 0x0CF2;
	public static inline var UNPACK_SKIP_ROWS = 0x0CF3;
	public static inline var UNPACK_SKIP_PIXELS = 0x0CF4;
	public static inline var PACK_ROW_LENGTH = 0x0D02;
	public static inline var PACK_SKIP_ROWS = 0x0D03;
	public static inline var PACK_SKIP_PIXELS = 0x0D04;
	public static inline var TEXTURE_BINDING_3D = 0x806A;
	public static inline var UNPACK_SKIP_IMAGES = 0x806D;
	public static inline var UNPACK_IMAGE_HEIGHT = 0x806E;
	public static inline var MAX_3D_TEXTURE_SIZE = 0x8073;
	public static inline var MAX_ELEMENTS_VERTICES = 0x80E8;
	public static inline var MAX_ELEMENTS_INDICES = 0x80E9;
	public static inline var MAX_TEXTURE_LOD_BIAS = 0x84FD;
	public static inline var MAX_FRAGMENT_UNIFORM_COMPONENTS = 0x8B49;
	public static inline var MAX_VERTEX_UNIFORM_COMPONENTS = 0x8B4A;
	public static inline var MAX_ARRAY_TEXTURE_LAYERS = 0x88FF;
	public static inline var MIN_PROGRAM_TEXEL_OFFSET = 0x8904;
	public static inline var MAX_PROGRAM_TEXEL_OFFSET = 0x8905;
	public static inline var MAX_VARYING_COMPONENTS = 0x8B4B;
	public static inline var FRAGMENT_SHADER_DERIVATIVE_HINT = 0x8B8B;
	public static inline var RASTERIZER_DISCARD = 0x8C89;
	public static inline var VERTEX_ARRAY_BINDING = 0x85B5;
	public static inline var MAX_VERTEX_OUTPUT_COMPONENTS = 0x9122;
	public static inline var MAX_FRAGMENT_INPUT_COMPONENTS = 0x9125;
	public static inline var MAX_SERVER_WAIT_TIMEOUT = 0x9111;
	public static inline var MAX_ELEMENT_INDEX = 0x8D6B;
	
	public static inline var RED = 0x1903;
	public static inline var RGB8 = 0x8051;
	public static inline var RGBA8 = 0x8058;
	public static inline var RGB10_A2 = 0x8059;
	public static inline var TEXTURE_3D = 0x806F;
	public static inline var TEXTURE_WRAP_R = 0x8072;
	public static inline var TEXTURE_MIN_LOD = 0x813A;
	public static inline var TEXTURE_MAX_LOD = 0x813B;
	public static inline var TEXTURE_BASE_LEVEL = 0x813C;
	public static inline var TEXTURE_MAX_LEVEL = 0x813D;
	public static inline var TEXTURE_COMPARE_MODE = 0x884C;
	public static inline var TEXTURE_COMPARE_FUNC = 0x884D;
	public static inline var SRGB = 0x8C40;
	public static inline var SRGB8 = 0x8C41;
	public static inline var SRGB8_ALPHA8 = 0x8C43;
	public static inline var COMPARE_REF_TO_TEXTURE = 0x884E;
	public static inline var RGBA32F = 0x8814;
	public static inline var RGB32F = 0x8815;
	public static inline var RGBA16F = 0x881A;
	public static inline var RGB16F = 0x881B;
	public static inline var TEXTURE_2D_ARRAY = 0x8C1A;
	public static inline var TEXTURE_BINDING_2D_ARRAY = 0x8C1D;
	public static inline var R11F_G11F_B10F = 0x8C3A;
	public static inline var RGB9_E5 = 0x8C3D;
	public static inline var RGBA32UI = 0x8D70;
	public static inline var RGB32UI = 0x8D71;
	public static inline var RGBA16UI = 0x8D76;
	public static inline var RGB16UI = 0x8D77;
	public static inline var RGBA8UI = 0x8D7C;
	public static inline var RGB8UI = 0x8D7D;
	public static inline var RGBA32I = 0x8D82;
	public static inline var RGB32I = 0x8D83;
	public static inline var RGBA16I = 0x8D88;
	public static inline var RGB16I = 0x8D89;
	public static inline var RGBA8I = 0x8D8E;
	public static inline var RGB8I = 0x8D8F;
	public static inline var RED_INTEGER = 0x8D94;
	public static inline var RGB_INTEGER = 0x8D98;
	public static inline var RGBA_INTEGER = 0x8D99;
	public static inline var R8 = 0x8229;
	public static inline var RG8 = 0x822B;
	public static inline var R16F = 0x822D;
	public static inline var R32F = 0x822E;
	public static inline var RG16F = 0x822F;
	public static inline var RG32F = 0x8230;
	public static inline var R8I = 0x8231;
	public static inline var R8UI = 0x8232;
	public static inline var R16I = 0x8233;
	public static inline var R16UI = 0x8234;
	public static inline var R32I = 0x8235;
	public static inline var R32UI = 0x8236;
	public static inline var RG8I = 0x8237;
	public static inline var RG8UI = 0x8238;
	public static inline var RG16I = 0x8239;
	public static inline var RG16UI = 0x823A;
	public static inline var RG32I = 0x823B;
	public static inline var RG32UI = 0x823C;
	public static inline var R8_SNORM = 0x8F94;
	public static inline var RG8_SNORM = 0x8F95;
	public static inline var RGB8_SNORM = 0x8F96;
	public static inline var RGBA8_SNORM = 0x8F97;
	public static inline var RGB10_A2UI = 0x906F;
	public static inline var TEXTURE_IMMUTABLE_FORMAT = 0x912F;
	public static inline var TEXTURE_IMMUTABLE_LEVELS = 0x82DF;
	
	public static inline var UNSIGNED_INT_2_10_10_10_REV = 0x8368;
	public static inline var UNSIGNED_INT_10F_11F_11F_REV = 0x8C3B;
	public static inline var UNSIGNED_INT_5_9_9_9_REV = 0x8C3E;
	public static inline var FLOAT_32_UNSIGNED_INT_24_8_REV = 0x8DAD;
	public static inline var UNSIGNED_INT_24_8 = 0x84FA;
	public static inline var HALF_FLOAT = 0x140B;
	public static inline var RG = 0x8227;
	public static inline var RG_INTEGER = 0x8228;
	public static inline var INT_2_10_10_10_REV = 0x8D9F;
	
	public static inline var CURRENT_QUERY = 0x8865;
	public static inline var QUERY_RESULT = 0x8866;
	public static inline var QUERY_RESULT_AVAILABLE = 0x8867;
	public static inline var ANY_SAMPLES_PASSED = 0x8C2F;
	public static inline var ANY_SAMPLES_PASSED_CONSERVATIVE = 0x8D6A;
	
	public static inline var MAX_DRAW_BUFFERS = 0x8824;
	public static inline var DRAW_BUFFER0 = 0x8825;
	public static inline var DRAW_BUFFER1 = 0x8826;
	public static inline var DRAW_BUFFER2 = 0x8827;
	public static inline var DRAW_BUFFER3 = 0x8828;
	public static inline var DRAW_BUFFER4 = 0x8829;
	public static inline var DRAW_BUFFER5 = 0x882A;
	public static inline var DRAW_BUFFER6 = 0x882B;
	public static inline var DRAW_BUFFER7 = 0x882C;
	public static inline var DRAW_BUFFER8 = 0x882D;
	public static inline var DRAW_BUFFER9 = 0x882E;
	public static inline var DRAW_BUFFER10 = 0x882F;
	public static inline var DRAW_BUFFER11 = 0x8830;
	public static inline var DRAW_BUFFER12 = 0x8831;
	public static inline var DRAW_BUFFER13 = 0x8832;
	public static inline var DRAW_BUFFER14 = 0x8833;
	public static inline var DRAW_BUFFER15 = 0x8834;
	public static inline var MAX_COLOR_ATTACHMENTS = 0x8CDF;
	public static inline var COLOR_ATTACHMENT1 = 0x8CE1;
	public static inline var COLOR_ATTACHMENT2 = 0x8CE2;
	public static inline var COLOR_ATTACHMENT3 = 0x8CE3;
	public static inline var COLOR_ATTACHMENT4 = 0x8CE4;
	public static inline var COLOR_ATTACHMENT5 = 0x8CE5;
	public static inline var COLOR_ATTACHMENT6 = 0x8CE6;
	public static inline var COLOR_ATTACHMENT7 = 0x8CE7;
	public static inline var COLOR_ATTACHMENT8 = 0x8CE8;
	public static inline var COLOR_ATTACHMENT9 = 0x8CE9;
	public static inline var COLOR_ATTACHMENT10 = 0x8CEA;
	public static inline var COLOR_ATTACHMENT11 = 0x8CEB;
	public static inline var COLOR_ATTACHMENT12 = 0x8CEC;
	public static inline var COLOR_ATTACHMENT13 = 0x8CED;
	public static inline var COLOR_ATTACHMENT14 = 0x8CEE;
	public static inline var COLOR_ATTACHMENT15 = 0x8CEF;
	
	public static inline var SAMPLER_3D = 0x8B5F;
	public static inline var SAMPLER_2D_SHADOW = 0x8B62;
	public static inline var SAMPLER_2D_ARRAY = 0x8DC1;
	public static inline var SAMPLER_2D_ARRAY_SHADOW = 0x8DC4;
	public static inline var SAMPLER_CUBE_SHADOW = 0x8DC5;
	public static inline var INT_SAMPLER_2D = 0x8DCA;
	public static inline var INT_SAMPLER_3D = 0x8DCB;
	public static inline var INT_SAMPLER_CUBE = 0x8DCC;
	public static inline var INT_SAMPLER_2D_ARRAY = 0x8DCF;
	public static inline var UNSIGNED_INT_SAMPLER_2D = 0x8DD2;
	public static inline var UNSIGNED_INT_SAMPLER_3D = 0x8DD3;
	public static inline var UNSIGNED_INT_SAMPLER_CUBE = 0x8DD4;
	public static inline var UNSIGNED_INT_SAMPLER_2D_ARRAY = 0x8DD7;
	public static inline var MAX_SAMPLES = 0x8D57;
	public static inline var SAMPLER_BINDING = 0x8919;
	
	public static inline var PIXEL_PACK_BUFFER = 0x88EB;
	public static inline var PIXEL_UNPACK_BUFFER = 0x88EC;
	public static inline var PIXEL_PACK_BUFFER_BINDING = 0x88ED;
	public static inline var PIXEL_UNPACK_BUFFER_BINDING = 0x88EF;
	public static inline var COPY_READ_BUFFER = 0x8F36;
	public static inline var COPY_WRITE_BUFFER = 0x8F37;
	public static inline var COPY_READ_BUFFER_BINDING = 0x8F36;
	public static inline var COPY_WRITE_BUFFER_BINDING = 0x8F37;
	
	public static inline var FLOAT_MAT2x3 = 0x8B65;
	public static inline var FLOAT_MAT2x4 = 0x8B66;
	public static inline var FLOAT_MAT3x2 = 0x8B67;
	public static inline var FLOAT_MAT3x4 = 0x8B68;
	public static inline var FLOAT_MAT4x2 = 0x8B69;
	public static inline var FLOAT_MAT4x3 = 0x8B6A;
	public static inline var UNSIGNED_INT_VEC2 = 0x8DC6;
	public static inline var UNSIGNED_INT_VEC3 = 0x8DC7;
	public static inline var UNSIGNED_INT_VEC4 = 0x8DC8;
	public static inline var UNSIGNED_NORMALIZED = 0x8C17;
	public static inline var SIGNED_NORMALIZED = 0x8F9C;

	public static inline var VERTEX_ATTRIB_ARRAY_INTEGER = 0x88FD;
	public static inline var VERTEX_ATTRIB_ARRAY_DIVISOR = 0x88FE;
	
	public static inline var TRANSFORM_FEEDBACK_BUFFER_MODE = 0x8C7F;
	public static inline var MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS = 0x8C80;
	public static inline var TRANSFORM_FEEDBACK_VARYINGS = 0x8C83;
	public static inline var TRANSFORM_FEEDBACK_BUFFER_START = 0x8C84;
	public static inline var TRANSFORM_FEEDBACK_BUFFER_SIZE = 0x8C85;
	public static inline var TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN = 0x8C88;
	public static inline var MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS = 0x8C8A;
	public static inline var MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS = 0x8C8B;
	public static inline var INTERLEAVED_ATTRIBS = 0x8C8C;
	public static inline var SEPARATE_ATTRIBS = 0x8C8D;
	public static inline var TRANSFORM_FEEDBACK_BUFFER = 0x8C8E;
	public static inline var TRANSFORM_FEEDBACK_BUFFER_BINDING = 0x8C8F;
	public static inline var TRANSFORM_FEEDBACK = 0x8E22;
	public static inline var TRANSFORM_FEEDBACK_PAUSED = 0x8E23;
	public static inline var TRANSFORM_FEEDBACK_ACTIVE = 0x8E24;
	public static inline var TRANSFORM_FEEDBACK_BINDING = 0x8E25;
	
	public static inline var FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING = 0x8210;
	public static inline var FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE = 0x8211;
	public static inline var FRAMEBUFFER_ATTACHMENT_RED_SIZE = 0x8212;
	public static inline var FRAMEBUFFER_ATTACHMENT_GREEN_SIZE = 0x8213;
	public static inline var FRAMEBUFFER_ATTACHMENT_BLUE_SIZE = 0x8214;
	public static inline var FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE = 0x8215;
	public static inline var FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE = 0x8216;
	public static inline var FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE = 0x8217;
	public static inline var FRAMEBUFFER_DEFAULT = 0x8218;
	public static inline var DEPTH24_STENCIL8 = 0x88F0;
	public static inline var DRAW_FRAMEBUFFER_BINDING = 0x8CA6;
	public static inline var READ_FRAMEBUFFER = 0x8CA8;
	public static inline var DRAW_FRAMEBUFFER = 0x8CA9;
	public static inline var READ_FRAMEBUFFER_BINDING = 0x8CAA;
	public static inline var RENDERBUFFER_SAMPLES = 0x8CAB;
	public static inline var FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER = 0x8CD4;
	public static inline var FRAMEBUFFER_INCOMPLETE_MULTISAMPLE = 0x8D56;
	
	public static inline var UNIFORM_BUFFER = 0x8A11;
	public static inline var UNIFORM_BUFFER_BINDING = 0x8A28;
	public static inline var UNIFORM_BUFFER_START = 0x8A29;
	public static inline var UNIFORM_BUFFER_SIZE = 0x8A2A;
	public static inline var MAX_VERTEX_UNIFORM_BLOCKS = 0x8A2B;
	public static inline var MAX_FRAGMENT_UNIFORM_BLOCKS = 0x8A2D;
	public static inline var MAX_COMBINED_UNIFORM_BLOCKS = 0x8A2E;
	public static inline var MAX_UNIFORM_BUFFER_BINDINGS = 0x8A2F;
	public static inline var MAX_UNIFORM_BLOCK_SIZE = 0x8A30;
	public static inline var MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS = 0x8A31;
	public static inline var MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS = 0x8A33;
	public static inline var UNIFORM_BUFFER_OFFSET_ALIGNMENT = 0x8A34;
	public static inline var ACTIVE_UNIFORM_BLOCKS = 0x8A36;
	public static inline var UNIFORM_TYPE = 0x8A37;
	public static inline var UNIFORM_SIZE = 0x8A38;
	public static inline var UNIFORM_BLOCK_INDEX = 0x8A3A;
	public static inline var UNIFORM_OFFSET = 0x8A3B;
	public static inline var UNIFORM_ARRAY_STRIDE = 0x8A3C;
	public static inline var UNIFORM_MATRIX_STRIDE = 0x8A3D;
	public static inline var UNIFORM_IS_ROW_MAJOR = 0x8A3E;
	public static inline var UNIFORM_BLOCK_BINDING = 0x8A3F;
	public static inline var UNIFORM_BLOCK_DATA_SIZE = 0x8A40;
	public static inline var UNIFORM_BLOCK_ACTIVE_UNIFORMS = 0x8A42;
	public static inline var UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES = 0x8A43;
	public static inline var UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER = 0x8A44;
	public static inline var UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER = 0x8A46;
	
	public static inline var OBJECT_TYPE = 0x9112;
	public static inline var SYNC_CONDITION = 0x9113;
	public static inline var SYNC_STATUS = 0x9114;
	public static inline var SYNC_FLAGS = 0x9115;
	public static inline var SYNC_FENCE = 0x9116;
	public static inline var SYNC_GPU_COMMANDS_COMPLETE = 0x9117;
	public static inline var UNSIGNALED = 0x9118;
	public static inline var SIGNALED = 0x9119;
	public static inline var ALREADY_SIGNALED = 0x911A;
	public static inline var TIMEOUT_EXPIRED = 0x911B;
	public static inline var CONDITION_SATISFIED = 0x911C;
	public static inline var WAIT_FAILED = 0x911D;
	public static inline var SYNC_FLUSH_COMMANDS_BIT = 0x00000001;
	
	public static inline var COLOR = 0x1800;
	public static inline var DEPTH = 0x1801;
	public static inline var STENCIL = 0x1802;
	public static inline var MIN = 0x8007;
	public static inline var MAX = 0x8008;
	public static inline var DEPTH_COMPONENT24 = 0x81A6;
	public static inline var STREAM_READ = 0x88E1;
	public static inline var STREAM_COPY = 0x88E2;
	public static inline var STATIC_READ = 0x88E5;
	public static inline var STATIC_COPY = 0x88E6;
	public static inline var DYNAMIC_READ = 0x88E9;
	public static inline var DYNAMIC_COPY = 0x88EA;
	public static inline var DEPTH_COMPONENT32F = 0x8CAC;
	public static inline var DEPTH32F_STENCIL8 = 0x8CAD;
	public static inline var INVALID_INDEX = 0xFFFFFFFF;
	public static inline var TIMEOUT_IGNORED = -1;
	public static inline var MAX_CLIENT_WAIT_TIMEOUT_WEBGL = 0x9247;
	
	public function beginQuery (target:Int, query:GLQuery):Void;
	public function beginTransformFeedback (primitiveNode:Int):Void;
	public function bindBufferBase (target:Int, index:Int, buffer:GLBuffer):Void;
	public function bindBufferRange (target:Int, index:Int, buffer:GLBuffer, offset:DataPointer, size:DataPointer):Void;
	public function bindSampler (unit:Int, sampler:GLSampler):Void;
	public function bindTransformFeedback (target:Int, transformFeedback:GLTransformFeedback):Void;
	public function bindVertexArray (vertexArray:GLVertexArrayObject):Void;
	public function blitFramebuffer (srcX0:Int, srcY0:Int, srcX1:Int, srcY1:Int, dstX0:Int, dstY0:Int, dstX1:Int, dstY1:Int, mask:Int, filter:Int):Void;
	
	@:overload(function (target:Int, data:js.html.ArrayBufferView, usage:Int, srcOffset:Int, ?length:Int):Void {})
	@:overload(function (target:Int, size:Int, usage:Int):Void {})
	@:overload(function (target:Int, data:js.html.ArrayBufferView, usage:Int):Void {})
	@:overload(function (target:Int, data:js.html.ArrayBuffer, usage:Int):Void {})
	override function bufferData (target:Int, data:Dynamic /*MISSING SharedArrayBuffer*/, usage:Int):Void;
	
	@:overload(function (target:Int, dstByteOffset:Int, srcData:js.html.ArrayBufferView, srcOffset:Int, ?length:Int):Void {})
	@:overload(function (target:Int, offset:Int, data:js.html.ArrayBufferView):Void {})
	@:overload(function (target:Int, offset:Int, data:js.html.ArrayBuffer):Void {})
	override function bufferSubData (target:Int, offset:Int, data:Dynamic /*MISSING SharedArrayBuffer*/):Void;
	
	public function clearBufferfi (buffer:Int, drawbuffer:Int, depth:Float, stencil:Int):Void;
	
	@:overload(function (buffer:Int, drawbuffer:Int, values:js.html.Float32Array, ?srcOffset:Int):Void {})
	@:overload(function (buffer:Int, drawbuffer:Int, depth:Float, stencil:Int):Void {})
	public function clearBufferfv (buffer:Int, drawbuffer:Int, values:Array<Float>, ?srcOffset:Int):Void;
	
	@:overload(function (buffer:Int, drawbuffer:Int, values:js.html.Int32Array, ?srcOffset:Int):Void {})
	@:overload(function (buffer:Int, drawbuffer:Int, depth:Float, stencil:Int):Void {})
	public function clearBufferiv (buffer:Int, drawbuffer:Int, values:Array<Int>, ?srcOffset:Int):Void;
	
	@:overload(function (buffer:Int, drawbuffer:Int, values:js.html.Uint32Array, ?srcOffset:Int):Void {})
	@:overload(function (buffer:Int, drawbuffer:Int, depth:Float, stencil:Int):Void {})
	public function clearBufferuiv (buffer:Int, drawbuffer:Int, values:Array<Int>, ?srcOffset:Int):Void;
	
	public function clientWaitSync (sync:GLSync, flags:Int, timeout:Dynamic /*Int64*/):Int;
	
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, offset:Int):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, srcData:js.html.ArrayBufferView, ?srcOffset:Int, ?srcLengthOverride:Int):Void {})
	override function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, data:js.html.ArrayBufferView):Void;
	
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, offset:Int):Void {})
	public function compressedTexImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, srcData:ArrayBufferView, ?srcOffset:Int, ?srcLengthOverride:Int):Void;
	
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, offset:Int):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, srcData:js.html.ArrayBufferView, ?srcOffset:Int, ?srcLengthOverride:Int):Void {})
	override function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, data:js.html.ArrayBufferView):Void;
	
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, offset:Int):Void {})
	public function compressedTexSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, srcData:ArrayBufferView, ?srcOffset:Int, ?srcLengthOverride:Int):Void;
	
	public function copySubBufferData (readTarget:Int, writeTarget:Int, readOffset:DataPointer, writeOffset:DataPointer, size:Int):Void;
	public function copyTexSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, x:Int, y:Int, width:Int, height:Int):Void;
	public function createQuery ():GLQuery;
	public function createSampler ():GLSampler;
	public function createTransformFeedback ():GLTransformFeedback;
	public function createVertexArray ():GLVertexArrayObject;
	public function deleteQuery (query:GLQuery):Void;
	public function deleteSampler (sampler:GLSampler):Void;
	public function deleteSync (sync:GLSync):Void;
	public function deleteTransformFeedback (transformFeedback:GLTransformFeedback):Void;
	public function deleteVertexArray (vertexArray:GLVertexArrayObject):Void;
	public function drawArraysInstanced (mode:Int, first:Int, count:Int, instanceCount:Int):Void;
	public function drawBuffers (buffers:Array<Int>):Void;
	public function drawElementsInstanced (mode:Int, count:Int, type:Int, offset:DataPointer, instanceCount:Int):Void;
	public function drawRangeElements (mode:Int, start:Int, end:Int, count:Int, type:Int, offset:DataPointer):Void;
	public function endQuery (target:Int):Void;
	public function endTransformFeedback ():Void;
	public function fenceSync (condition:Int, flags:Int):GLSync;
	public function framebufferTextureLayer (target:Int, attachment:Int, texture:GLTexture, level:Int, layer:Int):Void;
	public function getActiveUniformBlockName (program:GLProgram, uniformBlockIndex:Int):String;
	public function getActiveUniformBlockParameter (program:GLProgram, uniformBlockIndex:Int, pname:Int):Dynamic;
	public function getActiveUniforms (program:GLProgram, uniformIndices:Array<Int>, pname:Int):Dynamic;
	
	@:overload(function (target:Int, srcByteOffset:DataPointer, dstData:js.html.ArrayBuffer, ?srcOffset:Int, ?length:Int):Void {})
	public function getBufferSubData (target:Int, srcByteOffset:DataPointer, dstData:Dynamic /*SharedArrayBuffer*/, ?srcOffset:Int, ?length:Int):Void;
	
	public function getFragDataLocation (program:GLProgram, name:String):Int;
	public function getIndexedParameter (target:Int, index:Int):Dynamic;
	public function getInternalformatParameter (target:Int, internalformat:Int, pname:Int):Dynamic;
	public function getQuery (target:Int, pname:Int):GLQuery;
	public function getQueryParameter (query:GLQuery, pname:Int):Dynamic;
	public function getSamplerParameter (sampler:GLSampler, pname:Int):Dynamic;
	public function getSyncParameter (sync:GLSync, pname:Int):Dynamic;
	public function getTransformFeedbackVarying (program:GLProgram, index:Int):GLActiveInfo;
	public function getUniformBlockIndex (program:GLProgram, uniformBlockName:String):Int;
	
	@:overload(function (program:GLProgram, uniformNames:String):Array<Int> {})
	public function getUniformIndices (program:GLProgram, uniformNames:Array<String>):Array<Int>;
	
	public function invalidateFramebuffer (target:Int, attachments:Array<Int>):Void;
	public function invalidateSubFramebuffer (target:Int, attachments:Array<Int>, x:Int, y:Int, width:Int, height:Int):Void;
	public function isQuery (query:GLQuery):Bool;
	public function isSampler (sampler:GLSampler):Bool;
	public function isSync (sync:GLSync):Bool;
	public function isTransformFeedback (transformFeedback:GLTransformFeedback):Bool;
	public function isVertexArray (vertexArray:GLVertexArrayObject):Bool;
	public function pauseTransformFeedback ():Void;
	public function readBuffer (src:Int):Void;
	
	@:overload(function (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:js.html.ArrayBufferView):Void {})
	@:overload(function (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, offset:Int):Void {})
	@:overload(function (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:js.html.ArrayBufferView, dstOffset:Int):Void {})
	override function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:js.html.ArrayBufferView):Void;
	
	public function renderbufferStorageMultisample (target:Int, samples:Int, internalFormat:Int, width:Int, height:Int):Void;
	public function resumeTransformFeedback ():Void;
	public function samplerParameterf (sampler:GLSampler, pname:Int, param:Float):Void;
	public function samplerParameteri (sampler:GLSampler, pname:Int, param:Int):Void;
	
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, offset:DataPointer):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, srcData:js.html.ArrayBufferView, srcOffset:Int):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, source:Dynamic /*js.html.ImageBitmap*/):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, source:js.html.ImageData):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, source:js.html.ImageElement):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, source:js.html.CanvasElement):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, source:js.html.VideoElement):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:js.html.ArrayBufferView):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, format:Int, type:Int, pixels:js.html.ImageData):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, format:Int, type:Int, image:js.html.ImageElement):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, format:Int, type:Int, canvas:js.html.CanvasElement):Void {})
	override function texImage2D (target:Int, level:Int, internalformat:Int, format:Int, type:Int, video:js.html.VideoElement):Void;
	
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.CanvasElement):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.ImageElement):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.VideoElement):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:Dynamic /*js.html.ImageBitmap*/):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.ImageData):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, source:js.html.ArrayBufferView):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, offset:DataPointer):Void {})
	public function texImage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, srcData:js.html.ArrayBufferView, ?srcOffset:Int):Void;
	
	public function texStorage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int):Void;
	public function texStorage3D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int):Void;
	
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, srcData:js.html.ArrayBufferView, srcOffset:Int):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, offset:DataPointer):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, source:js.html.ImageData):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, source:js.html.ImageElement):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, source:js.html.CanvasElement):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, source:js.html.VideoElement):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, source:Dynamic /*ImageBitmap*/):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:js.html.ArrayBufferView):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, pixels:js.html.ImageData):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, image:js.html.ImageElement):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, canvas:js.html.CanvasElement):Void {})
	override function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, video:js.html.VideoElement):Void;
	
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, offset:DataPointer):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, source:js.html.ImageData):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, source:js.html.ImageElement):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, source:js.html.CanvasElement):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, source:js.html.VideoElement):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, source:Dynamic /*ImageBitmap*/):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, pixels:js.html.ArrayBufferView, ?srcOffset:Int):Void {})
	public function texSubImage3D (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, video:js.html.VideoElement):Void;
	
	public function transformFeedbackVaryings (program:GLProgram, varyings:Array<String>, bufferMode:Int):Void;
	public function uniform1ui (location:GLUniformLocation, v0:Int):Void;
	public function uniform2ui (location:GLUniformLocation, v0:Int, v1:Int):Void;
	public function uniform3ui (location:GLUniformLocation, v0:Int, v1:Int, v2:Int):Void;
	public function uniform4ui (location:GLUniformLocation, v0:Int, v1:Int, v2:Int, v3:Int):Void;
	
	@:overload(function (location:GLUniformLocation, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {})
	@:overload(function (location:GLUniformLocation, data:Array<Float>, ?srcOffset:Int, ?srcLength:Int):Void {})
	override function uniform1fv (location:GLUniformLocation, data:Array<Float>):Void;
	
	@:overload(function (location:GLUniformLocation, data:js.html.Int32Array, ?srcOffset:Int, ?srcLength:Int):Void {})
	@:overload(function (location:GLUniformLocation, data:Array<Int>, ?srcOffset:Int, ?srcLength:Int):Void {})
	override function uniform1iv (location:GLUniformLocation, data:Array<Int>):Void;
	
	public function uniform1uiv (location:GLUniformLocation, data:js.html.Uint32Array, ?srcOffset:Int, ?srcLength:Int):Void;
	
	@:overload(function (location:GLUniformLocation, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {})
	@:overload(function (location:GLUniformLocation, data:Array<Float>, ?srcOffset:Int, ?srcLength:Int):Void {})
	override function uniform2fv (location:GLUniformLocation, data:Array<Float>):Void;
	
	@:overload(function (location:GLUniformLocation, data:js.html.Int32Array, ?srcOffset:Int, ?srcLength:Int):Void {})
	@:overload(function (location:GLUniformLocation, data:Array<Int>, ?srcOffset:Int, ?srcLength:Int):Void {})
	override function uniform2iv (location:GLUniformLocation, data:Array<Int>):Void;
	
	public function uniform2uiv (location:GLUniformLocation, data:js.html.Uint32Array, ?srcOffset:Int, ?srcLength:Int):Void;
	
	@:overload(function (location:GLUniformLocation, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {})
	@:overload(function (location:GLUniformLocation, data:Array<Float>, ?srcOffset:Int, ?srcLength:Int):Void {})
	override function uniform3fv (location:GLUniformLocation, data:Array<Float>):Void;
	
	@:overload(function (location:GLUniformLocation, data:js.html.Int32Array, ?srcOffset:Int, ?srcLength:Int):Void {})
	@:overload(function (location:GLUniformLocation, data:Array<Int>, ?srcOffset:Int, ?srcLength:Int):Void {})
	override function uniform3iv (location:GLUniformLocation, data:Array<Int>):Void;
	
	public function uniform3uiv (location:GLUniformLocation, data:js.html.Uint32Array, ?srcOffset:Int, ?srcLength:Int):Void;
	
	@:overload(function (location:GLUniformLocation, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {})
	@:overload(function (location:GLUniformLocation, data:Array<Float>, ?srcOffset:Int, ?srcLength:Int):Void {})
	override function uniform4fv (location:GLUniformLocation, data:Array<Float>):Void;
	
	@:overload(function (location:GLUniformLocation, data:js.html.Int32Array, ?srcOffset:Int, ?srcLength:Int):Void {})
	@:overload(function (location:GLUniformLocation, data:Array<Int>, ?srcOffset:Int, ?srcLength:Int):Void {})
	override function uniform4iv (location:GLUniformLocation, data:Array<Int>):Void;
	
	public function uniform4uiv (location:GLUniformLocation, data:js.html.Uint32Array, ?srcOffset:Int, ?srcLength:Int):Void;
	
	public function uniformBlockBinding (program:GLProgram, uniformBlockIndex:Int, uniformBlockBinding:Int):Void;
	
	@:overload(function (location:GLUniformLocation, transpose:Bool, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {})
	@:overload(function (location:GLUniformLocation, transpose:Bool, data:Array<Float>, ?srcOffset:Int, ?srcLength:Int):Void {})
	override function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, data:Array<Float>):Void;
	
	public function uniformMatrix2x3fv (location:GLUniformLocation, transpose:Bool, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void;
	public function uniformMatrix2x4fv (location:GLUniformLocation, transpose:Bool, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void;
	
	@:overload(function (location:GLUniformLocation, transpose:Bool, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {})
	@:overload(function (location:GLUniformLocation, transpose:Bool, data:Array<Float>, ?srcOffset:Int, ?srcLength:Int):Void {})
	override function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, data:Array<Float>):Void;
	
	public function uniformMatrix3x2fv (location:GLUniformLocation, transpose:Bool, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void;
	public function uniformMatrix3x4fv (location:GLUniformLocation, transpose:Bool, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void;
	
	@:overload(function (location:GLUniformLocation, transpose:Bool, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void {})
	@:overload(function (location:GLUniformLocation, transpose:Bool, data:Array<Float>, ?srcOffset:Int, ?srcLength:Int):Void {})
	override function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, data:Array<Float>):Void;
	
	public function uniformMatrix4x2fv (location:GLUniformLocation, transpose:Bool, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void;
	public function uniformMatrix4x3fv (location:GLUniformLocation, transpose:Bool, data:js.html.Float32Array, ?srcOffset:Int, ?srcLength:Int):Void;
	public function vertexAttribDivisor (index:Int, divisor:Int):Void;
	public function vertexAttribI4i (index:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void;
	public function vertexAttribI4ui (index:Int, v0:Int, v1:Int, v2:Int, v3:Int):Void;
	
	@:overload(function (index:Int, value:js.html.Int32Array):Void {})
	public function vertexAttribI4iv (index:Int, value:Array<Int>):Void;
	
	@:overload(function (index:Int, value:js.html.Uint32Array):Void {})
	public function vertexAttribI4uiv (index:Int, value:Array<Int>):Void;
	
	public function vertexAttribIPointer (index:Int, size:Int, type:Int, stride:Int, offset:DataPointer):Void;
	public function waitSync (sync:GLSync, flags:Int, timeout:Dynamic /*int64*/):Void;
	
	
}