package lime.graphics.opengl;


import lime.utils.ArrayBufferView;
import lime.utils.Float32Array;
import lime.utils.Int32Array;

@:allow(lime.ui.Window)

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class GL {
	
	
	public static inline var DEPTH_BUFFER_BIT = 0x00000100;
	public static inline var STENCIL_BUFFER_BIT = 0x00000400;
	public static inline var COLOR_BUFFER_BIT = 0x00004000;
	
	public static inline var POINTS = 0x0000;
	public static inline var LINES = 0x0001;
	public static inline var LINE_LOOP = 0x0002;
	public static inline var LINE_STRIP = 0x0003;
	public static inline var TRIANGLES = 0x0004;
	public static inline var TRIANGLE_STRIP = 0x0005;
	public static inline var TRIANGLE_FAN = 0x0006;
	
	public static inline var ZERO = 0;
	public static inline var ONE = 1;
	public static inline var SRC_COLOR = 0x0300;
	public static inline var ONE_MINUS_SRC_COLOR = 0x0301;
	public static inline var SRC_ALPHA = 0x0302;
	public static inline var ONE_MINUS_SRC_ALPHA = 0x0303;
	public static inline var DST_ALPHA = 0x0304;
	public static inline var ONE_MINUS_DST_ALPHA = 0x0305;
	
	public static inline var DST_COLOR = 0x0306;
	public static inline var ONE_MINUS_DST_COLOR = 0x0307;
	public static inline var SRC_ALPHA_SATURATE = 0x0308;
	
	public static inline var FUNC_ADD = 0x8006;
	public static inline var BLEND_EQUATION = 0x8009;
	public static inline var BLEND_EQUATION_RGB = 0x8009;
	public static inline var BLEND_EQUATION_ALPHA = 0x883D;
	
	public static inline var FUNC_SUBTRACT = 0x800A;
	public static inline var FUNC_REVERSE_SUBTRACT = 0x800B;
	
	public static inline var BLEND_DST_RGB = 0x80C8;
	public static inline var BLEND_SRC_RGB = 0x80C9;
	public static inline var BLEND_DST_ALPHA = 0x80CA;
	public static inline var BLEND_SRC_ALPHA = 0x80CB;
	public static inline var CONSTANT_COLOR = 0x8001;
	public static inline var ONE_MINUS_CONSTANT_COLOR = 0x8002;
	public static inline var CONSTANT_ALPHA = 0x8003;
	public static inline var ONE_MINUS_CONSTANT_ALPHA = 0x8004;
	public static inline var BLEND_COLOR = 0x8005;
	
	public static inline var ARRAY_BUFFER = 0x8892;
	public static inline var ELEMENT_ARRAY_BUFFER = 0x8893;
	public static inline var ARRAY_BUFFER_BINDING = 0x8894;
	public static inline var ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;
	
	public static inline var STREAM_DRAW = 0x88E0;
	public static inline var STATIC_DRAW = 0x88E4;
	public static inline var DYNAMIC_DRAW = 0x88E8;
	
	public static inline var BUFFER_SIZE = 0x8764;
	public static inline var BUFFER_USAGE = 0x8765;
	
	public static inline var CURRENT_VERTEX_ATTRIB = 0x8626;
	
	public static inline var FRONT = 0x0404;
	public static inline var BACK = 0x0405;
	public static inline var FRONT_AND_BACK = 0x0408;
	
	public static inline var CULL_FACE = 0x0B44;
	public static inline var BLEND = 0x0BE2;
	public static inline var DITHER = 0x0BD0;
	public static inline var STENCIL_TEST = 0x0B90;
	public static inline var DEPTH_TEST = 0x0B71;
	public static inline var SCISSOR_TEST = 0x0C11;
	public static inline var POLYGON_OFFSET_FILL = 0x8037;
	public static inline var SAMPLE_ALPHA_TO_COVERAGE = 0x809E;
	public static inline var SAMPLE_COVERAGE = 0x80A0;
	
	public static inline var NO_ERROR = 0;
	public static inline var INVALID_ENUM = 0x0500;
	public static inline var INVALID_VALUE = 0x0501;
	public static inline var INVALID_OPERATION = 0x0502;
	public static inline var OUT_OF_MEMORY = 0x0505;
	
	public static inline var CW  = 0x0900;
	public static inline var CCW = 0x0901;
	
	public static inline var LINE_WIDTH = 0x0B21;
	public static inline var ALIASED_POINT_SIZE_RANGE = 0x846D;
	public static inline var ALIASED_LINE_WIDTH_RANGE = 0x846E;
	public static inline var CULL_FACE_MODE = 0x0B45;
	public static inline var FRONT_FACE = 0x0B46;
	public static inline var DEPTH_RANGE = 0x0B70;
	public static inline var DEPTH_WRITEMASK = 0x0B72;
	public static inline var DEPTH_CLEAR_VALUE = 0x0B73;
	public static inline var DEPTH_FUNC = 0x0B74;
	public static inline var STENCIL_CLEAR_VALUE = 0x0B91;
	public static inline var STENCIL_FUNC = 0x0B92;
	public static inline var STENCIL_FAIL = 0x0B94;
	public static inline var STENCIL_PASS_DEPTH_FAIL = 0x0B95;
	public static inline var STENCIL_PASS_DEPTH_PASS = 0x0B96;
	public static inline var STENCIL_REF = 0x0B97;
	public static inline var STENCIL_VALUE_MASK = 0x0B93;
	public static inline var STENCIL_WRITEMASK = 0x0B98;
	public static inline var STENCIL_BACK_FUNC = 0x8800;
	public static inline var STENCIL_BACK_FAIL = 0x8801;
	public static inline var STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;
	public static inline var STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;
	public static inline var STENCIL_BACK_REF = 0x8CA3;
	public static inline var STENCIL_BACK_VALUE_MASK = 0x8CA4;
	public static inline var STENCIL_BACK_WRITEMASK = 0x8CA5;
	public static inline var VIEWPORT = 0x0BA2;
	public static inline var SCISSOR_BOX = 0x0C10;
	
	public static inline var COLOR_CLEAR_VALUE = 0x0C22;
	public static inline var COLOR_WRITEMASK = 0x0C23;
	public static inline var UNPACK_ALIGNMENT = 0x0CF5;
	public static inline var PACK_ALIGNMENT = 0x0D05;
	public static inline var MAX_TEXTURE_SIZE = 0x0D33;
	public static inline var MAX_VIEWPORT_DIMS = 0x0D3A;
	public static inline var SUBPIXEL_BITS = 0x0D50;
	public static inline var RED_BITS = 0x0D52;
	public static inline var GREEN_BITS = 0x0D53;
	public static inline var BLUE_BITS = 0x0D54;
	public static inline var ALPHA_BITS = 0x0D55;
	public static inline var DEPTH_BITS = 0x0D56;
	public static inline var STENCIL_BITS = 0x0D57;
	public static inline var POLYGON_OFFSET_UNITS = 0x2A00;
	
	public static inline var POLYGON_OFFSET_FACTOR = 0x8038;
	public static inline var TEXTURE_BINDING_2D = 0x8069;
	public static inline var SAMPLE_BUFFERS = 0x80A8;
	public static inline var SAMPLES = 0x80A9;
	public static inline var SAMPLE_COVERAGE_VALUE = 0x80AA;
	public static inline var SAMPLE_COVERAGE_INVERT = 0x80AB;
	
	public static inline var COMPRESSED_TEXTURE_FORMATS = 0x86A3;
	
	public static inline var DONT_CARE = 0x1100;
	public static inline var FASTEST = 0x1101;
	public static inline var NICEST = 0x1102;
	
	public static inline var GENERATE_MIPMAP_HINT = 0x8192;
	
	public static inline var BYTE = 0x1400;
	public static inline var UNSIGNED_BYTE = 0x1401;
	public static inline var SHORT = 0x1402;
	public static inline var UNSIGNED_SHORT = 0x1403;
	public static inline var INT = 0x1404;
	public static inline var UNSIGNED_INT = 0x1405;
	public static inline var FLOAT = 0x1406;
	
	public static inline var DEPTH_COMPONENT = 0x1902;
	public static inline var ALPHA = 0x1906;
	public static inline var RGB = 0x1907;
	public static inline var RGBA = 0x1908;
	public static inline var BGR_EXT = 0x80E0;
	public static inline var BGRA_EXT = 0x80E1;
	public static inline var LUMINANCE = 0x1909;
	public static inline var LUMINANCE_ALPHA = 0x190A;
	
	public static inline var UNSIGNED_SHORT_4_4_4_4 = 0x8033;
	public static inline var UNSIGNED_SHORT_5_5_5_1 = 0x8034;
	public static inline var UNSIGNED_SHORT_5_6_5 = 0x8363;
	
	public static inline var FRAGMENT_SHADER = 0x8B30;
	public static inline var VERTEX_SHADER = 0x8B31;
	public static inline var MAX_VERTEX_ATTRIBS = 0x8869;
	public static inline var MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;
	public static inline var MAX_VARYING_VECTORS = 0x8DFC;
	public static inline var MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;
	public static inline var MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;
	public static inline var MAX_TEXTURE_IMAGE_UNITS = 0x8872;
	public static inline var MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;
	public static inline var SHADER_TYPE = 0x8B4F;
	public static inline var DELETE_STATUS = 0x8B80;
	public static inline var LINK_STATUS = 0x8B82;
	public static inline var VALIDATE_STATUS = 0x8B83;
	public static inline var ATTACHED_SHADERS = 0x8B85;
	public static inline var ACTIVE_UNIFORMS = 0x8B86;
	public static inline var ACTIVE_ATTRIBUTES = 0x8B89;
	public static inline var SHADING_LANGUAGE_VERSION = 0x8B8C;
	public static inline var CURRENT_PROGRAM = 0x8B8D;
	
	public static inline var NEVER = 0x0200;
	public static inline var LESS = 0x0201;
	public static inline var EQUAL = 0x0202;
	public static inline var LEQUAL = 0x0203;
	public static inline var GREATER = 0x0204;
	public static inline var NOTEQUAL = 0x0205;
	public static inline var GEQUAL = 0x0206;
	public static inline var ALWAYS = 0x0207;
	
	public static inline var KEEP = 0x1E00;
	public static inline var REPLACE = 0x1E01;
	public static inline var INCR = 0x1E02;
	public static inline var DECR = 0x1E03;
	public static inline var INVERT = 0x150A;
	public static inline var INCR_WRAP = 0x8507;
	public static inline var DECR_WRAP = 0x8508;
	
	public static inline var VENDOR = 0x1F00;
	public static inline var RENDERER = 0x1F01;
	public static inline var VERSION = 0x1F02;
	
	public static inline var NEAREST = 0x2600;
	public static inline var LINEAR = 0x2601;
	
	public static inline var NEAREST_MIPMAP_NEAREST = 0x2700;
	public static inline var LINEAR_MIPMAP_NEAREST = 0x2701;
	public static inline var NEAREST_MIPMAP_LINEAR = 0x2702;
	public static inline var LINEAR_MIPMAP_LINEAR = 0x2703;
	
	public static inline var TEXTURE_MAG_FILTER = 0x2800;
	public static inline var TEXTURE_MIN_FILTER = 0x2801;
	public static inline var TEXTURE_WRAP_S = 0x2802;
	public static inline var TEXTURE_WRAP_T = 0x2803;
	
	public static inline var TEXTURE_2D = 0x0DE1;
	public static inline var TEXTURE = 0x1702;
	
	public static inline var TEXTURE_CUBE_MAP = 0x8513;
	public static inline var TEXTURE_BINDING_CUBE_MAP = 0x8514;
	public static inline var TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;
	public static inline var TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;
	public static inline var TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;
	public static inline var TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;
	public static inline var TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;
	public static inline var TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;
	public static inline var MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;
	
	public static inline var TEXTURE0 = 0x84C0;
	public static inline var TEXTURE1 = 0x84C1;
	public static inline var TEXTURE2 = 0x84C2;
	public static inline var TEXTURE3 = 0x84C3;
	public static inline var TEXTURE4 = 0x84C4;
	public static inline var TEXTURE5 = 0x84C5;
	public static inline var TEXTURE6 = 0x84C6;
	public static inline var TEXTURE7 = 0x84C7;
	public static inline var TEXTURE8 = 0x84C8;
	public static inline var TEXTURE9 = 0x84C9;
	public static inline var TEXTURE10 = 0x84CA;
	public static inline var TEXTURE11 = 0x84CB;
	public static inline var TEXTURE12 = 0x84CC;
	public static inline var TEXTURE13 = 0x84CD;
	public static inline var TEXTURE14 = 0x84CE;
	public static inline var TEXTURE15 = 0x84CF;
	public static inline var TEXTURE16 = 0x84D0;
	public static inline var TEXTURE17 = 0x84D1;
	public static inline var TEXTURE18 = 0x84D2;
	public static inline var TEXTURE19 = 0x84D3;
	public static inline var TEXTURE20 = 0x84D4;
	public static inline var TEXTURE21 = 0x84D5;
	public static inline var TEXTURE22 = 0x84D6;
	public static inline var TEXTURE23 = 0x84D7;
	public static inline var TEXTURE24 = 0x84D8;
	public static inline var TEXTURE25 = 0x84D9;
	public static inline var TEXTURE26 = 0x84DA;
	public static inline var TEXTURE27 = 0x84DB;
	public static inline var TEXTURE28 = 0x84DC;
	public static inline var TEXTURE29 = 0x84DD;
	public static inline var TEXTURE30 = 0x84DE;
	public static inline var TEXTURE31 = 0x84DF;
	public static inline var ACTIVE_TEXTURE = 0x84E0;
	
	public static inline var REPEAT = 0x2901;
	public static inline var CLAMP_TO_EDGE = 0x812F;
	public static inline var MIRRORED_REPEAT = 0x8370;
	
	public static inline var FLOAT_VEC2 = 0x8B50;
	public static inline var FLOAT_VEC3 = 0x8B51;
	public static inline var FLOAT_VEC4 = 0x8B52;
	public static inline var INT_VEC2 = 0x8B53;
	public static inline var INT_VEC3 = 0x8B54;
	public static inline var INT_VEC4 = 0x8B55;
	public static inline var BOOL = 0x8B56;
	public static inline var BOOL_VEC2 = 0x8B57;
	public static inline var BOOL_VEC3 = 0x8B58;
	public static inline var BOOL_VEC4 = 0x8B59;
	public static inline var FLOAT_MAT2 = 0x8B5A;
	public static inline var FLOAT_MAT3 = 0x8B5B;
	public static inline var FLOAT_MAT4 = 0x8B5C;
	public static inline var SAMPLER_2D = 0x8B5E;
	public static inline var SAMPLER_CUBE = 0x8B60;
	
	public static inline var VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;
	public static inline var VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;
	public static inline var VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;
	public static inline var VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;
	public static inline var VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;
	public static inline var VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;
	public static inline var VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;
	
	public static inline var VERTEX_PROGRAM_POINT_SIZE = 0x8642;
	public static inline var POINT_SPRITE = 0x8861;
	
	public static inline var COMPILE_STATUS = 0x8B81;
	
	public static inline var LOW_FLOAT = 0x8DF0;
	public static inline var MEDIUM_FLOAT = 0x8DF1;
	public static inline var HIGH_FLOAT = 0x8DF2;
	public static inline var LOW_INT = 0x8DF3;
	public static inline var MEDIUM_INT = 0x8DF4;
	public static inline var HIGH_INT = 0x8DF5;
	
	public static inline var FRAMEBUFFER = 0x8D40;
	public static inline var RENDERBUFFER = 0x8D41;
	
	public static inline var RGBA4 = 0x8056;
	public static inline var RGB5_A1 = 0x8057;
	public static inline var RGB565 = 0x8D62;
	public static inline var DEPTH_COMPONENT16 = 0x81A5;
	public static inline var STENCIL_INDEX = 0x1901;
	public static inline var STENCIL_INDEX8 = 0x8D48;
	public static inline var DEPTH_STENCIL = 0x84F9;
	
	public static inline var RENDERBUFFER_WIDTH = 0x8D42;
	public static inline var RENDERBUFFER_HEIGHT = 0x8D43;
	public static inline var RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;
	public static inline var RENDERBUFFER_RED_SIZE = 0x8D50;
	public static inline var RENDERBUFFER_GREEN_SIZE = 0x8D51;
	public static inline var RENDERBUFFER_BLUE_SIZE = 0x8D52;
	public static inline var RENDERBUFFER_ALPHA_SIZE = 0x8D53;
	public static inline var RENDERBUFFER_DEPTH_SIZE = 0x8D54;
	public static inline var RENDERBUFFER_STENCIL_SIZE = 0x8D55;
	
	public static inline var FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;
	public static inline var FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;
	public static inline var FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;
	public static inline var FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;
	
	public static inline var COLOR_ATTACHMENT0 = 0x8CE0;
	public static inline var DEPTH_ATTACHMENT = 0x8D00;
	public static inline var STENCIL_ATTACHMENT = 0x8D20;
	public static inline var DEPTH_STENCIL_ATTACHMENT = 0x821A;
	
	public static inline var NONE = 0;
	
	public static inline var FRAMEBUFFER_COMPLETE = 0x8CD5;
	public static inline var FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;
	public static inline var FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;
	public static inline var FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;
	public static inline var FRAMEBUFFER_UNSUPPORTED = 0x8CDD;
	
	public static inline var FRAMEBUFFER_BINDING = 0x8CA6;
	public static inline var RENDERBUFFER_BINDING = 0x8CA7;
	public static inline var MAX_RENDERBUFFER_SIZE = 0x84E8;
	
	public static inline var INVALID_FRAMEBUFFER_OPERATION = 0x0506;
	
	public static inline var UNPACK_FLIP_Y_WEBGL = 0x9240;
	public static inline var UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;
	public static inline var CONTEXT_LOST_WEBGL = 0x9242;
	public static inline var UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;
	public static inline var BROWSER_DEFAULT_WEBGL = 0x9244;
	
	public static var version (get, null):Int;
	
	private static var context:GLRenderContext;
	
	private static var __currentProgram:GLProgram;
	
	
	public static inline function activeTexture (texture:Int):Void {
		
		context.activeTexture (texture);
		
	}
	
	
	public static inline function attachShader (program:GLProgram, shader:GLShader):Void {
		
		context.attachShader (program, shader);
		
	}
	
	
	public static inline function bindAttribLocation (program:GLProgram, index:Int, name:String):Void {
		
		context.bindAttribLocation (program, index, name);
		
	}
	
	
	public static inline function bindBuffer (target:Int, buffer:GLBuffer):Void {
		
		context.bindBuffer (target, buffer);
		
	}
	
	
	public static inline function bindFramebuffer (target:Int, framebuffer:GLFramebuffer):Void {
		
		context.bindFramebuffer (target, framebuffer);
		
	}
	
	
	public static inline function bindRenderbuffer (target:Int, renderbuffer:GLRenderbuffer):Void {
		
		context.bindRenderbuffer (target, renderbuffer);
		
	}
	
	
	public static inline function bindTexture (target:Int, texture:GLTexture):Void {
		
		context.bindTexture (target, texture);
		
	}
	
	
	public static inline function blendColor (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		context.blendColor (red, green, blue, alpha);
		
	}
	
	
	public static inline function blendEquation (mode:Int):Void {
		
		context.blendEquation (mode);
		
	}
	
	
	public static inline function blendEquationSeparate (modeRGB:Int, modeAlpha:Int):Void {
		
		context.blendEquationSeparate (modeRGB, modeAlpha);
		
	}
	
	
	public static inline function blendFunc (sfactor:Int, dfactor:Int):Void {
		
		context.blendFunc (sfactor, dfactor);
		
	}
	
	
	public static inline function blendFuncSeparate (srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int):Void {
		
		context.blendFuncSeparate (srcRGB, dstRGB, srcAlpha, dstAlpha);
		
	}
	
	
	public static inline function bufferData (target:Int, data:ArrayBufferView, usage:Int):Void {
		
		context.bufferData (target, data, usage);
		
	}
	
	
	public static inline function bufferSubData (target:Int, offset:Int, data:ArrayBufferView):Void {
		
		context.bufferSubData (target, offset, data);
		
	}
	
	
	public static inline function checkFramebufferStatus (target:Int):Int {
		
		return context.checkFramebufferStatus (target);
		
	}
	
	
	public static inline function clear (mask:Int):Void {
		
		context.clear (mask);
		
	}
	
	
	public static inline function clearColor (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		context.clearColor (red, green, blue, alpha);
		
	}
	
	
	public static inline function clearDepth (depth:Float):Void {
		
		context.clearDepth (depth);
		
	}
	
	
	public static inline function clearStencil (s:Int):Void {
		
		context.clearStencil (s);
		
	}
	
	
	public static inline function colorMask (red:Bool, green:Bool, blue:Bool, alpha:Bool):Void {
		
		context.colorMask (red, green, blue, alpha);
		
	}
	
	
	public static inline function compileShader (shader:GLShader):Void {
		
		context.compileShader (shader);
		
	}
	
	
	public static inline function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, data:ArrayBufferView):Void {
		
		context.compressedTexImage2D (target, level, internalformat, width, height, border, data);
		
	}
	
	
	public static inline function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, data:ArrayBufferView):Void {
		
		context.compressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, data);
		
	}
	
	
	public static inline function copyTexImage2D (target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void {
		
		context.copyTexImage2D (target, level, internalformat, x, y, width, height, border);
		
	}
	
	
	public static inline function copyTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {
		
		context.copyTexSubImage2D (target, level, xoffset, yoffset, x, y, width, height);
		
	}
	
	
	public static inline function createBuffer ():GLBuffer {
		
		return context.createBuffer ();
		
	}
	
	
	public static inline function createFramebuffer ():GLFramebuffer {
		
		return context.createFramebuffer ();
		
	}
	
	
	public static inline function createProgram ():GLProgram {
		
		return context.createProgram ();
		
	}
	
	
	public static inline function createRenderbuffer ():GLRenderbuffer {
		
		return context.createRenderbuffer ();
		
	}
	
	
	public static inline function createShader (type:Int):GLShader {
		
		return context.createShader (type);
		
	}
	
	
	public static inline function createTexture ():GLTexture {
		
		return context.createTexture ();
		
	}
	
	
	public static inline function cullFace (mode:Int):Void {
		
		context.cullFace (mode);
		
	}
	
	
	public static inline function deleteBuffer (buffer:GLBuffer):Void {
		
		context.deleteBuffer (buffer);
		
	}
	
	
	public static inline function deleteFramebuffer (framebuffer:GLFramebuffer):Void {
		
		context.deleteFramebuffer (framebuffer);
		
	}
	
	
	public static inline function deleteProgram (program:GLProgram):Void {
		
		context.deleteProgram (program);
		
	}
	
	
	public static inline function deleteRenderbuffer (renderbuffer:GLRenderbuffer):Void {
		
		context.deleteRenderbuffer (renderbuffer);
		
	}
	
	
	public static inline function deleteShader (shader:GLShader):Void {
		
		context.deleteShader (shader);
		
	}
	
	
	public static inline function deleteTexture (texture:GLTexture):Void {
		
		context.deleteTexture (texture);
		
	}
	
	
	public static inline function depthFunc (func:Int):Void {
		
		context.depthFunc (func);
		
	}
	
	
	public static inline function depthMask (flag:Bool):Void {
		
		context.depthMask (flag);
		
	}
	
	
	public static inline function depthRange (zNear:Float, zFar:Float):Void {
		
		context.depthRange (zNear, zFar);
		
	}
	
	
	public static inline function detachShader (program:GLProgram, shader:GLShader):Void {
		
		context.detachShader (program, shader);
		
	}
	
	
	public static inline function disable (cap:Int):Void {
		
		context.disable (cap);
		
	}
	
	
	public static inline function disableVertexAttribArray (index:Int):Void {
		
		context.disableVertexAttribArray (index);
		
	}
	
	
	public static inline function drawArrays (mode:Int, first:Int, count:Int):Void {
		
		context.drawArrays (mode, first, count);
		
	}
	
	
	public static inline function drawElements (mode:Int, count:Int, type:Int, offset:Int):Void {
		
		context.drawElements (mode, count, type, offset);
		
	}
	
	
	public static inline function enable (cap:Int):Void {
		
		context.enable (cap);
		
	}
	
	
	public static inline function enableVertexAttribArray (index:Int):Void {
		
		context.enableVertexAttribArray (index);
		
	}
	
	
	public static inline function finish ():Void {
		
		context.finish ();
		
	}
	
	
	public static inline function flush ():Void {
		
		context.flush ();
		
	}
	
	
	public static inline function framebufferRenderbuffer (target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:GLRenderbuffer):Void {
		
		context.framebufferRenderbuffer (target, attachment, renderbuffertarget, renderbuffer);
		
	}
	
	
	public static inline function framebufferTexture2D (target:Int, attachment:Int, textarget:Int, texture:GLTexture, level:Int):Void {
		
		context.framebufferTexture2D (target, attachment, textarget, texture, level);
		
	}
	
	
	public static inline function frontFace (mode:Int):Void {
		
		context.frontFace (mode);
		
	}
	
	
	public static inline function generateMipmap (target:Int):Void {
		
		context.generateMipmap (target);
		
	}
	
	
	public static inline function getActiveAttrib (program:GLProgram, index:Int):GLActiveInfo {
		
		return context.getActiveAttrib (program, index);
		
	}
	
	
	public static inline function getActiveUniform (program:GLProgram, index:Int):GLActiveInfo {
		
		return context.getActiveUniform (program, index);
		
	}
	
	
	public static inline function getAttachedShaders (program:GLProgram):Array<GLShader> {
		
		return context.getAttachedShaders (program);
		
	}
	
	
	public static inline function getAttribLocation (program:GLProgram, name:String):Int {
		
		return context.getAttribLocation (program, name);
		
	}
	
	
	public static inline function getBufferParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		return context.getBufferParameter (target, pname);
		
	}
	
	
	public static inline function getContextAttributes ():GLContextAttributes {
		
		return context.getContextAttributes ();
		
	}
	
	
	public static inline function getError ():Int {
		
		return context.getError ();
		
	}
	
	
	public static inline function getExtension (name:String):Dynamic {
		
		return context.getExtension (name);
		
	}
	
	
	public static inline function getFramebufferAttachmentParameter (target:Int, attachment:Int, pname:Int):Int /*Dynamic*/ {
		
		return context.getFramebufferAttachmentParameter (target, attachment, pname);
		
	}
	
	
	public static inline function getParameter (pname:Int):Dynamic {
		
		return context.getParameter (pname);
		
	}
	
	
	public static inline function getProgramInfoLog (program:GLProgram):String {
		
		return context.getProgramInfoLog (program);
		
	}
	
	
	public static inline function getProgramParameter (program:GLProgram, pname:Int):Int {
		
		return context.getProgramParameter (program, pname);
		
	}
	
	
	public static inline function getRenderbufferParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		return context.getRenderbufferParameter (target, pname);
		
	}
	
	
	public static inline function getShaderInfoLog (shader:GLShader):String {
		
		return context.getShaderInfoLog (shader);
		
	}
	
	
	public static inline function getShaderParameter (shader:GLShader, pname:Int):Int {
		
		return context.getShaderParameter (shader, pname);
		
	}
	
	
	public static inline function getShaderPrecisionFormat (shadertype:Int, precisiontype:Int):GLShaderPrecisionFormat {
		
		return context.getShaderPrecisionFormat (shadertype, precisiontype);
		
	}
	
	
	public static inline function getShaderSource (shader:GLShader):String {
		
		return context.getShaderSource (shader);
		
	}
	
	
	public static inline function getSupportedExtensions ():Array<String> {
		
		return context.getSupportedExtensions ();
		
	}
	
	
	public static inline function getTexParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		return context.getTexParameter (target, pname);
		
	}
	
	
	public static inline function getUniform (program:GLProgram, location:GLUniformLocation):Dynamic {
		
		return context.getUniform (program, location);
		
	}
	
	
	public static inline function getUniformLocation (program:GLProgram, name:String):GLUniformLocation {
		
		return context.getUniformLocation (program, name);
		
	}
	
	
	public static inline function getVertexAttrib (index:Int, pname:Int):Int /*Dynamic*/ {
		
		return context.getVertexAttrib (index, pname);
		
	}
	
	
	public static inline function getVertexAttribOffset (index:Int, pname:Int):Int {
		
		return context.getVertexAttribOffset (index, pname);
		
	}
	
	
	public static inline function hint (target:Int, mode:Int):Void {
		
		context.hint (target, mode);
		
	}
	
	
	public static inline function isBuffer (buffer:GLBuffer):Bool {
		
		return context.isBuffer (buffer);
		
	}
	
	
	public static inline function isContextLost ():Bool {
		
		return context.isContextLost ();
		
	}
	
	
	public static inline function isEnabled (cap:Int):Bool {
		
		return context.isEnabled (cap);
		
	}
	
	
	public static inline function isFramebuffer (framebuffer:GLFramebuffer):Bool {
		
		return context.isFramebuffer (framebuffer);
		
	}
	
	
	public static inline function isProgram (program:GLProgram):Bool {
		
		return context.isProgram (program);
		
	}
	
	
	public static inline function isRenderbuffer (renderbuffer:GLRenderbuffer):Bool {
		
		return context.isRenderbuffer (renderbuffer);
		
	}
	
	
	public static inline function isShader (shader:GLShader):Bool {
		
		return context.isShader (shader);
		
	}
	
	
	public static inline function isTexture (texture:GLTexture):Bool {
		
		return context.isTexture (texture);
		
	}
	
	
	public static inline function lineWidth (width:Float):Void {
		
		context.lineWidth (width);
		
	}
	
	
	public static inline function linkProgram (program:GLProgram):Void {
		
		context.linkProgram (program);
		
	}
	
	
	public static inline function pixelStorei (pname:Int, param:Int):Void {
		
		context.pixelStorei (pname, param);
		
	}
	
	
	public static inline function polygonOffset (factor:Float, units:Float):Void {
		
		context.polygonOffset (factor, units);
		
	}
	
	
	public static inline function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		context.readPixels (x, y, width, height, format, type, pixels);
		
	}
	
	
	public static inline function renderbufferStorage (target:Int, internalformat:Int, width:Int, height:Int):Void {
		
		context.renderbufferStorage (target, internalformat, width, height);
		
	}
	
	
	public static inline function sampleCoverage (value:Float, invert:Bool):Void {
		
		context.sampleCoverage (value, invert);
		
	}
	
	
	public static inline function scissor (x:Int, y:Int, width:Int, height:Int):Void {
		
		context.scissor (x, y, width, height);
		
	}
	
	
	public static inline function shaderSource (shader:GLShader, source:String):Void {
		
		context.shaderSource (shader, source);
		
	}
	
	
	public static inline function stencilFunc (func:Int, ref:Int, mask:Int):Void {
		
		context.stencilFunc (func, ref, mask);
		
	}
	
	
	public static inline function stencilFuncSeparate (face:Int, func:Int, ref:Int, mask:Int):Void {
		
		context.stencilFuncSeparate (face, func, ref, mask);
		
	}
	
	
	public static inline function stencilMask (mask:Int):Void {
		
		context.stencilMask (mask);
		
	}
	
	
	public static inline function stencilMaskSeparate (face:Int, mask:Int):Void {
		
		context.stencilMaskSeparate (face, mask);
		
	}
	
	
	public static inline function stencilOp (fail:Int, zfail:Int, zpass:Int):Void {
		
		context.stencilOp (fail, zfail, zpass);
		
	}
	
	
	public static inline function stencilOpSeparate (face:Int, fail:Int, zfail:Int, zpass:Int):Void {
		
		context.stencilOpSeparate (face, fail, zfail, zpass);
		
	}
	
	
	public static inline function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		context.texImage2D (target, level, internalformat, width, height, border, format, type, pixels);
		
	}
	
	
	public static inline function texParameterf (target:Int, pname:Int, param:Float):Void {
		
		context.texParameterf (target, pname, param);
		
	}
	
	
	public static inline function texParameteri (target:Int, pname:Int, param:Int):Void {
		
		context.texParameteri (target, pname, param);
		
	}
	
	
	public static inline function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		context.texSubImage2D (target, level, xoffset, yoffset, width, height, format, type, pixels);
		
	}
	
	
	public static inline function uniform1f (location:GLUniformLocation, x:Float):Void {
		
		context.uniform1f (location, x);
		
	}
	
	
	public static inline function uniform1fv (location:GLUniformLocation, x:Float32Array):Void {
		
		context.uniform1fv (location, x);
		
	}
	
	
	public static inline function uniform1i (location:GLUniformLocation, x:Int):Void {
		
		context.uniform1i (location, x);
		
	}
	
	
	public static inline function uniform1iv (location:GLUniformLocation, v:Int32Array):Void {
		
		context.uniform1iv (location, v);
		
	}
	
	
	public static inline function uniform2f (location:GLUniformLocation, x:Float, y:Float):Void {
		
		context.uniform2f (location, x, y);
		
	}
	
	
	public static inline function uniform2fv (location:GLUniformLocation, v:Float32Array):Void {
		
		context.uniform2fv (location, v);
		
	}
	
	
	public static inline function uniform2i (location:GLUniformLocation, x:Int, y:Int):Void {
		
		context.uniform2i (location, x, y);
		
	}
	
	
	public static inline function uniform2iv (location:GLUniformLocation, v:Int32Array):Void {
		
		context.uniform2iv (location, v);
		
	}
	
	
	public static inline function uniform3f (location:GLUniformLocation, x:Float, y:Float, z:Float):Void {
		
		context.uniform3f (location, x, y, z);
		
	}
	
	
	public static inline function uniform3fv (location:GLUniformLocation, v:Float32Array):Void {
		
		context.uniform3fv (location, v);
		
	}
	
	
	public static inline function uniform3i (location:GLUniformLocation, x:Int, y:Int, z:Int):Void {
		
		context.uniform3i (location, x, y, z);
		
	}
	
	
	public static inline function uniform3iv (location:GLUniformLocation, v:Int32Array):Void {
		
		context.uniform3iv (location, v);
		
	}
	
	
	public static inline function uniform4f (location:GLUniformLocation, x:Float, y:Float, z:Float, w:Float):Void {
		
		context.uniform4f (location, x, y, z, w);
		
	}
	
	
	public static inline function uniform4fv (location:GLUniformLocation, v:Float32Array):Void {
		
		context.uniform4fv (location, v);
		
	}
	
	
	public static inline function uniform4i (location:GLUniformLocation, x:Int, y:Int, z:Int, w:Int):Void {
		
		context.uniform4i (location, x, y, z, w);
		
	}
	
	
	public static inline function uniform4iv (location:GLUniformLocation, v:Int32Array):Void {
		
		context.uniform4iv (location, v);
		
	}
	
	
	public static inline function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		context.uniformMatrix2fv (location, transpose, v);
		
	}
	
	
	public static inline function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		context.uniformMatrix3fv (location, transpose, v);
		
	}
	
	
	public static inline function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		context.uniformMatrix4fv (location, transpose, v);
		
	}
	
	
	/*public static inline function uniformMatrix3D(location:GLUniformLocation, transpose:Bool, matrix:Matrix3D):Void {
		
		lime_gl_uniform_matrix(location, transpose, Float32Array.fromMatrix(matrix).getByteBuffer() , 4);
		
	}*/
	
	
	public static inline function useProgram (program:GLProgram):Void {
		
		__currentProgram = program;
		
		context.useProgram (program);
		
	}
	
	
	public static inline function validateProgram (program:GLProgram):Void {
		
		context.validateProgram (program);
		
	}
	
	
	public static inline function vertexAttrib1f (indx:Int, x:Float):Void {
		
		context.vertexAttrib1f (indx, x);
		
	}
	
	
	public static inline function vertexAttrib1fv (indx:Int, values:Float32Array):Void {
		
		context.vertexAttrib1fv (indx, values);
		
	}
	
	
	public static inline function vertexAttrib2f (indx:Int, x:Float, y:Float):Void {
		
		context.vertexAttrib2f (indx, x, y);
		
	}
	
	
	public static inline function vertexAttrib2fv (indx:Int, values:Float32Array):Void {
		
		context.vertexAttrib2fv (indx, values);
		
	}
	
	
	public static inline function vertexAttrib3f (indx:Int, x:Float, y:Float, z:Float):Void {
		
		context.vertexAttrib3f (indx, x, y, z);
		
	}
	
	
	public static inline function vertexAttrib3fv (indx:Int, values:Float32Array):Void {
		
		context.vertexAttrib3fv (indx, values);
		
	}
	
	
	public static inline function vertexAttrib4f (indx:Int, x:Float, y:Float, z:Float, w:Float):Void {
		
		context.vertexAttrib4f (indx, x, y, z, w);
		
	}
	
	
	public static inline function vertexAttrib4fv (indx:Int, values:Float32Array):Void {
		
		context.vertexAttrib4fv (indx, values);
		
	}
	
	
	public static inline function vertexAttribPointer (indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int):Void {
		
		context.vertexAttribPointer (indx, size, type, normalized, stride, offset);
		
	}
	
	
	public static inline function viewport (x:Int, y:Int, width:Int, height:Int):Void {
		
		context.viewport (x, y, width, height);
		
	}
	
	
	private static function get_version ():Int { return 2; }
	
	
}