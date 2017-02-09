package lime.graphics.opengl;


import lime.utils.ArrayBuffer;
import lime.utils.ArrayBufferView;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import lime.system.System;

#if (js && html5)
import js.html.webgl.RenderingContext;
#elseif java
import org.lwjgl.opengl.EXTBlendColor;
import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.GL13;
import org.lwjgl.opengl.GL14;
import org.lwjgl.opengl.GL15;
import org.lwjgl.opengl.GL20;
import org.lwjgl.opengl.GL30;
#end

#if ((haxe_ver >= 3.2) && cpp)
import cpp.Float32;
#else
typedef Float32 = Float;
#end

#if !macro
@:build(lime.system.CFFI.build())
#end

@:allow(lime.ui.Window)


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
	
	#if (js && html5)
	private static var context:RenderingContext;
	#end
	
	
	public static inline function activeTexture (texture:Int):Void {
		
		#if (js && html5 && !display)
		context.activeTexture (texture);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_active_texture (texture);
		#elseif java
		GL13.glActiveTexture (texture);
		#end
		
	}
	
	
	public static inline function attachShader (program:GLProgram, shader:GLShader):Void {
		
		#if (js && html5 && !display)
		context.attachShader (program, shader);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		program.attach (shader);
		lime_gl_attach_shader (program.id, shader.id);
		#elseif java
		program.attach (shader);
		GL20.glAttachShader (program.id, shader.id);
		#end
		
	}
	
	
	public static inline function bindAttribLocation (program:GLProgram, index:Int, name:String):Void {
		
		#if (js && html5 && !display)
		context.bindAttribLocation (program, index, name);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_bind_attrib_location (program.id, index, name);
		#elseif java
		GL20.glBindAttribLocation (program.id, index, name);
		#end
		
	}
	
	
	public static inline function bindBuffer (target:Int, buffer:GLBuffer):Void {
		
		#if (js && html5 && !display)
		context.bindBuffer (target, buffer);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_bind_buffer (target, buffer == null ? 0 : buffer.id);
		#elseif java
		GL15.glBindBuffer (target, buffer == null ? 0 : buffer.id);
		#end
		
	}
	
	
	public static inline function bindFramebuffer (target:Int, framebuffer:GLFramebuffer):Void {
		
		#if (js && html5 && !display)
		context.bindFramebuffer (target, framebuffer);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_bind_framebuffer (target, framebuffer == null ? 0 : framebuffer.id);
		#elseif java
		GL30.glBindFramebuffer (target, framebuffer == null ? 0 : framebuffer.id);
		#end
		
	}
	
	
	public static inline function bindRenderbuffer (target:Int, renderbuffer:GLRenderbuffer):Void {
		
		#if (js && html5 && !display)
		context.bindRenderbuffer (target, renderbuffer);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_bind_renderbuffer (target, renderbuffer == null ? 0 : renderbuffer.id);
		#elseif java
		GL30.glBindRenderbuffer (target, renderbuffer == null ? 0 : renderbuffer.id);
		#end
		
	}
	
	
	public static inline function bindTexture (target:Int, texture:GLTexture):Void {
		
		#if (js && html5 && !display)
		context.bindTexture (target, texture);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_bind_texture (target, texture == null ? 0 : texture.id);
		#elseif java
		GL11.glBindTexture (target, texture == null ? 0 : texture.id);
		#end
		
	}
	
	
	public static inline function blendColor (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		#if (js && html5 && !display)
		context.blendColor (red, green, blue, alpha);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_blend_color (red, green, blue, alpha);
		#elseif java
		EXTBlendColor.glBlendColorEXT (red, green, blue, alpha);
		#end
		
	}
	
	
	public static inline function blendEquation (mode:Int):Void {
		
		#if (js && html5 && !display)
		context.blendEquation (mode);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_blend_equation (mode);
		#elseif java
		GL14.glBlendEquation (mode);
		#end
		
	}
	
	
	public static inline function blendEquationSeparate (modeRGB:Int, modeAlpha:Int):Void {
		
		#if (js && html5 && !display)
		context.blendEquationSeparate (modeRGB, modeAlpha);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_blend_equation_separate (modeRGB, modeAlpha);
		#elseif java
		GL20.glBlendEquationSeparate (modeRGB, modeAlpha);
		#end
		
	}
	
	
	public static inline function blendFunc (sfactor:Int, dfactor:Int):Void {
		
		#if (js && html5 && !display)
		context.blendFunc (sfactor, dfactor);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_blend_func (sfactor, dfactor);
		#elseif java
		GL11.glBlendFunc (sfactor, dfactor);
		#end
		
	}
	
	
	public static inline function blendFuncSeparate (srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int):Void {
		
		#if (js && html5 && !display)
		context.blendFuncSeparate (srcRGB, dstRGB, srcAlpha, dstAlpha);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_blend_func_separate (srcRGB, dstRGB, srcAlpha, dstAlpha);
		#elseif java
		GL14.glBlendFuncSeparate (srcRGB, dstRGB, srcAlpha, dstAlpha);
		#end
		
	}
	
	
	public static inline function bufferData (target:Int, data:ArrayBufferView, usage:Int):Void {
		
		#if (js && html5 && !display)
		context.bufferData (target, data, usage);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_buffer_data (target, data.buffer, data.byteOffset, data.byteLength, usage);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_buffer_data (target, data, data.byteOffset, data.byteLength, usage);
		#elseif java
		//GL15.glBufferData (target, data.buffer, data.byteOffset, data.byteLength, usage);
		#end
		
	}
	
	
	public static inline function bufferSubData (target:Int, offset:Int, data:ArrayBufferView):Void {
		
		#if (js && html5 && !display)
		context.bufferSubData (target, offset, data);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_buffer_sub_data (target, offset, data.buffer, data.byteOffset, data.byteLength);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_buffer_sub_data (target, offset, data, data.byteOffset, data.byteLength);
		#elseif java
		//GL15.glBufferSubData (target, offset, data.buffer, data.byteOffset, data.byteLength);
		#end
		
	}
	
	
	public static inline function checkFramebufferStatus (target:Int):Int {
		
		#if (js && html5 && !display)
		return context.checkFramebufferStatus (target);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_check_framebuffer_status (target);
		#elseif java
		return GL30.glCheckFramebufferStatus (target);
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function clear (mask:Int):Void {
		
		#if (js && html5 && !display)
		context.clear (mask);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_clear (mask);
		#elseif java
		GL11.glClear (mask);
		#end
		
	}
	
	
	public static inline function clearColor (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		#if (js && html5 && !display)
		context.clearColor (red, green, blue, alpha);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_clear_color (red, green, blue, alpha);
		#elseif java
		GL11.glClearColor (red, green, blue, alpha);
		#end
		
	}
	
	
	public static inline function clearDepth (depth:Float):Void {
		
		#if (js && html5 && !display)
		context.clearDepth (depth);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_clear_depth (depth);
		#elseif java
		GL11.glClearDepth (depth);
		#end
		
	}
	
	
	public static inline function clearStencil (s:Int):Void {
		
		#if (js && html5 && !display)
		context.clearStencil (s);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_clear_stencil (s);
		#elseif java
		GL11.glClearStencil (s);
		#end
		
	}
	
	
	public static inline function colorMask (red:Bool, green:Bool, blue:Bool, alpha:Bool):Void {
		
		#if (js && html5 && !display)
		context.colorMask (red, green, blue, alpha);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_color_mask (red, green, blue, alpha);
		#elseif java
		GL11.glColorMask (red, green, blue, alpha);
		#end
		
	}
	
	
	public static inline function compileShader (shader:GLShader):Void {
		
		#if (js && html5 && !display)
		context.compileShader (shader);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_compile_shader (shader.id);
		#elseif java
		GL20.glCompileShader (shader.id);
		#end
		
	}
	
	
	public static inline function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, data:ArrayBufferView):Void {
		
		#if (js && html5 && !display)
		context.compressedTexImage2D (target, level, internalformat, width, height, border, data);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		var buffer = data == null ? null : data.buffer;
		lime_gl_compressed_tex_image_2d (target, level, internalformat, width, height, border, buffer, data == null ? 0 : data.byteOffset);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_compressed_tex_image_2d (target, level, internalformat, width, height, border, data == null ? null : data , data == null ? null : data.byteOffset);
		#elseif java
		//GL13.glCompressedTexImage2D (target, level, internalformat, width, height, border, data == null ? null : data.buffer, data == null ? null : data.byteOffset);
		#end
		
	}
	
	
	public static inline function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, data:ArrayBufferView):Void {
		
		#if (js && html5 && !display)
		context.compressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, data);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		var buffer = data == null ? null : data.buffer;
		lime_gl_compressed_tex_sub_image_2d (target, level, xoffset, yoffset, width, height, format, buffer, data == null ? 0 : data.byteOffset);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_compressed_tex_sub_image_2d (target, level, xoffset, yoffset, width, height, format, data == null ? null : data, data == null ? null : data.byteOffset);
		#elseif java
		//GL13.glCompressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, data == null ? null : data.buffer, data == null ? null : data.byteOffset);
		#end
		
	}
	
	
	public static inline function copyTexImage2D (target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void {
		
		#if (js && html5 && !display)
		context.copyTexImage2D (target, level, internalformat, x, y, width, height, border);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_copy_tex_image_2d (target, level, internalformat, x, y, width, height, border);
		#elseif java
		GL11.glCopyTexImage2D (target, level, internalformat, x, y, width, height, border);
		#end
		
	}
	
	
	public static inline function copyTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {
		
		#if (js && html5 && !display)
		context.copyTexSubImage2D (target, level, xoffset, yoffset, x, y, width, height);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_copy_tex_sub_image_2d (target, level, xoffset, yoffset, x, y, width, height);
		#elseif java
		GL11.glCopyTexSubImage2D (target, level, xoffset, yoffset, x, y, width, height);
		#end
		
	}
	
	
	public static inline function createBuffer ():GLBuffer {
		
		#if (js && html5 && !display)
		return context.createBuffer ();
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return new GLBuffer (version, lime_gl_create_buffer ());
		#elseif java
		//return new GLBuffer (version, GL15.glGenBuffers (1));
		return null;
		#else
		return null;
		#end
		
	}
	
	
	public static inline function createFramebuffer ():GLFramebuffer {
		
		#if (js && html5 && !display)
		return context.createFramebuffer ();
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return new GLFramebuffer (version, lime_gl_create_framebuffer ());
		#elseif java
		//return new GLFramebuffer (version, GL30.glGenFramebuffers (1));
		return null;
		#else
		return null;
		#end
		
	}
	
	
	public static inline function createProgram ():GLProgram {
		
		#if (js && html5 && !display)
		return context.createProgram ();
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return new GLProgram (version, lime_gl_create_program ());
		#elseif java
		return new GLProgram (version, GL20.glCreateProgram ());
		#else
		return null;
		#end
		
	}
	
	
	public static inline function createRenderbuffer ():GLRenderbuffer {
		
		#if (js && html5 && !display)
		return context.createRenderbuffer ();
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return new GLRenderbuffer (version, lime_gl_create_render_buffer ());
		#elseif java
		//return new GLRenderbuffer (version, GL30.glGenRenderbuffers (1));
		return null;
		#else
		return null;
		#end
		
	}
	
	
	public static inline function createShader (type:Int):GLShader {
		
		#if (js && html5 && !display)
		return context.createShader (type);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return new GLShader (version, lime_gl_create_shader (type));
		#elseif java
		return new GLShader (version, GL20.glCreateShader (type));
		#else
		return null;
		#end
		
	}
	
	
	public static inline function createTexture ():GLTexture {
		
		#if (js && html5 && !display)
		return context.createTexture ();
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return new GLTexture (version, lime_gl_create_texture ());
		#elseif java
		//return new GLTexture (version, GL11.glGenTextures (1));
		return null;
		#else
		return null;
		#end
		
	}
	
	
	public static inline function cullFace (mode:Int):Void {
		
		#if (js && html5 && !display)
		context.cullFace (mode);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_cull_face (mode);
		#elseif java
		GL11.glCullFace (mode);
		#end
		
	}
	
	
	public static inline function deleteBuffer (buffer:GLBuffer):Void {
		
		#if (js && html5 && !display)
		context.deleteBuffer (buffer);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_delete_buffer (buffer.id);
		buffer.invalidate ();
		#elseif java
		GL15.glDeleteBuffers (buffer.id);
		buffer.invalidate ();
		#end
		
	}
	
	
	public static inline function deleteFramebuffer (framebuffer:GLFramebuffer):Void {
		
		#if (js && html5 && !display)
		context.deleteFramebuffer (framebuffer);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_delete_framebuffer (framebuffer.id);
		framebuffer.invalidate ();
		#elseif
		GL30.glDeleteFramebuffers (framebuffer.id);
		framebuffer.invalidate ();
		#end
		
	}
	
	
	public static inline function deleteProgram (program:GLProgram):Void {
		
		#if (js && html5 && !display)
		context.deleteProgram (program);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_delete_program (program.id);
		program.invalidate ();
		#elseif java
		GL20.glDeleteProgram (program.id);
		program.invalidate ();
		#end
		
	}
	
	
	public static inline function deleteRenderbuffer (renderbuffer:GLRenderbuffer):Void {
		
		#if (js && html5 && !display)
		context.deleteRenderbuffer (renderbuffer);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_delete_render_buffer (renderbuffer.id);
		renderbuffer.invalidate ();
		#elseif java
		GL30.glDeleteRenderbuffers (renderbuffer.id);
		renderbuffer.invalidate ();
		#end
		
	}
	
	
	public static inline function deleteShader (shader:GLShader):Void {
		
		#if (js && html5 && !display)
		context.deleteShader (shader);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_delete_shader (shader.id);
		shader.invalidate ();
		#elseif java
		GL20.glDeleteShader (shader.id);
		shader.invalidate ();
		#end
		
	}
	
	
	public static inline function deleteTexture (texture:GLTexture):Void {
		
		#if (js && html5 && !display)
		context.deleteTexture (texture);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_delete_texture (texture.id);
		texture.invalidate ();
		#elseif java
		GL11.glDeleteTextures (texture.id);
		texture.invalidate ();
		#end
		
	}
	
	
	public static inline function depthFunc (func:Int):Void {
		
		#if (js && html5 && !display)
		context.depthFunc (func);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_depth_func (func);
		#elseif java
		GL11.glDepthFunc (func);
		#end
		
	}
	
	
	public static inline function depthMask (flag:Bool):Void {
		
		#if (js && html5 && !display)
		context.depthMask (flag);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_depth_mask (flag);
		#elseif java
		GL11.glDepthMask (flag);
		#end
		
	}
	
	
	public static inline function depthRange (zNear:Float, zFar:Float):Void {
		
		#if (js && html5 && !display)
		context.depthRange (zNear, zFar);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_depth_range (zNear, zFar);
		#elseif java
		GL11.glDepthRange (zNear, zFar);
		#end
		
	}
	
	
	public static inline function detachShader (program:GLProgram, shader:GLShader):Void {
		
		#if (js && html5 && !display)
		context.detachShader (program, shader);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_detach_shader (program.id, shader.id);
		#elseif java
		GL20.glDetachShader (program.id, shader.id);
		#end
		
	}
	
	
	public static inline function disable (cap:Int):Void {
		
		#if (js && html5 && !display)
		context.disable (cap);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_disable (cap);
		#elseif java
		GL11.glDisable (cap);
		#end
		
	}
	
	
	public static inline function disableVertexAttribArray (index:Int):Void {
		
		#if (js && html5 && !display)
		context.disableVertexAttribArray (index);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_disable_vertex_attrib_array (index);
		#elseif java
		GL20.glDisableVertexAttribArray (index);
		#end
		
	}
	
	
	public static inline function drawArrays (mode:Int, first:Int, count:Int):Void {
		
		#if (js && html5 && !display)
		context.drawArrays (mode, first, count);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_draw_arrays (mode, first, count);
		#elseif java
		GL11.glDrawArrays (mode, first, count);
		#end
		
	}
	
	
	public static inline function drawElements (mode:Int, count:Int, type:Int, offset:Int):Void {
		
		#if (js && html5 && !display)
		context.drawElements (mode, count, type, offset);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_draw_elements (mode, count, type, offset);
		#elseif java
		//GL11.glDrawElements (mode, count, type, offset);
		#end
		
	}
	
	
	public static inline function enable (cap:Int):Void {
		
		#if (js && html5 && !display)
		context.enable (cap);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_enable (cap);
		#elseif java
		GL11.glEnable (cap);
		#end
		
	}
	
	
	public static inline function enableVertexAttribArray (index:Int):Void {
		
		#if (js && html5 && !display)
		context.enableVertexAttribArray (index);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_enable_vertex_attrib_array (index);
		#elseif java
		GL20.glEnableVertexAttribArray (index);
		#end
		
	}
	
	
	public static inline function finish ():Void {
		
		#if (js && html5 && !display)
		context.finish ();
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_finish ();
		#elseif java
		GL11.glFinish ();
		#end
		
	}
	
	
	public static inline function flush ():Void {
		
		#if (js && html5 && !display)
		context.flush ();
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_flush ();
		#elseif java
		GL11.glFlush ();
		#end
		
	}
	
	
	public static inline function framebufferRenderbuffer (target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:GLRenderbuffer):Void {
		
		#if (js && html5 && !display)
		context.framebufferRenderbuffer (target, attachment, renderbuffertarget, renderbuffer);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_framebuffer_renderbuffer (target, attachment, renderbuffertarget, renderbuffer.id);
		#elseif java
		GL30.glFramebufferRenderbuffer (target, attachment, renderbuffertarget, renderbuffer.id);
		#end
		
	}
	
	
	public static inline function framebufferTexture2D (target:Int, attachment:Int, textarget:Int, texture:GLTexture, level:Int):Void {
		
		#if (js && html5 && !display)
		context.framebufferTexture2D (target, attachment, textarget, texture, level);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_framebuffer_texture2D (target, attachment, textarget, texture.id, level);
		#elseif java
		GL30.glFramebufferTexture2D (target, attachment, textarget, texture.id, level);
		#end
		
	}
	
	
	public static inline function frontFace (mode:Int):Void {
		
		#if (js && html5 && !display)
		context.frontFace (mode);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_front_face (mode);
		#elseif java
		GL11.glFrontFace (mode);
		#end
		
	}
	
	
	public static inline function generateMipmap (target:Int):Void {
		
		#if (js && html5 && !display)
		context.generateMipmap (target);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_generate_mipmap (target);
		#elseif java
		GL30.glGenerateMipmap (target);
		#end
		
	}
	
	
	public static inline function getActiveAttrib (program:GLProgram, index:Int):GLActiveInfo {
		
		#if (js && html5 && !display)
		return context.getActiveAttrib (program, index);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		var result:Dynamic = lime_gl_get_active_attrib (program.id, index);
		return result;
		#elseif java
		//return GL20.glGetActiveAttrib (program.id, index);
		return null;
		#else
		return null;
		#end
		
	}
	
	
	public static inline function getActiveUniform (program:GLProgram, index:Int):GLActiveInfo {
		
		#if (js && html5 && !display)
		return context.getActiveUniform (program, index);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		var result:Dynamic = lime_gl_get_active_uniform (program.id, index);
		return result;
		#elseif java
		//return GL20.glGetActiveUniform (program.id, index);
		return null;
		#else
		return null;
		#end
		
	}
	
	
	public static inline function getAttachedShaders (program:GLProgram):Array<GLShader> {
		
		#if (js && html5 && !display)
		return context.getAttachedShaders (program);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return program.getShaders ();
		#elseif java
		return program.getShaders ();
		#else
		return null;
		#end
		
	}
	
	
	public static inline function getAttribLocation (program:GLProgram, name:String):Int {
		
		#if (js && html5 && !display)
		return context.getAttribLocation (program, name);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_attrib_location (program.id, name);
		#elseif java
		return GL20.glGetAttribLocation (program.id, name);
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function getBufferParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		#if (js && html5 && !display)
		return context.getBufferParameter (target, pname);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_buffer_parameter (target, pname);
		#elseif java
		//return GL15.glGetBufferParameter (target, pname);
		return 0;
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function getContextAttributes ():GLContextAttributes {
		
		#if (js && html5 && !display)
		return context.getContextAttributes ();
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		var base:Dynamic = lime_gl_get_context_attributes ();
		base.premultipliedAlpha = false;
		base.preserveDrawingBuffer = false;
		return base;
		#elseif java
		//var base = lime_gl_get_context_attributes ();
		var base:Dynamic = {};
		base.premultipliedAlpha = false;
		base.preserveDrawingBuffer = false;
		return base;
		#else
		return null;
		#end
		
	}
	
	
	public static inline function getError ():Int {
		
		#if (js && html5 && !display)
		return context.getError ();
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_error ();
		#elseif java
		return GL11.glGetError ();
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function getExtension (name:String):Dynamic {
		
		#if (js && html5 && !display)
		return context.getExtension (name);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_extension (name);
		#else
		return null;
		#end
		
	}
	
	
	public static inline function getFramebufferAttachmentParameter (target:Int, attachment:Int, pname:Int):Int /*Dynamic*/ {
		
		#if (js && html5 && !display)
		return context.getFramebufferAttachmentParameter (target, attachment, pname);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_framebuffer_attachment_parameter (target, attachment, pname);
		#elseif java
		//return GL30.glGetFramebufferAttachmentParameter (target, attachment, pname);
		return 0;
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function getParameter (pname:Int):Dynamic {
		
		#if (js && html5 && !display)
		return context.getParameter (pname);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_parameter (pname);
		#elseif java
		return null;
		#else
		return null;
		#end
		
	}
	
	
	public static inline function getProgramInfoLog (program:GLProgram):String {
		
		#if (js && html5 && !display)
		return context.getProgramInfoLog (program);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_program_info_log (program.id);
		#elseif java
		return GL20.glGetProgramInfoLog (program.id);
		#else
		return null;
		#end
		
	}
	
	
	public static inline function getProgramParameter (program:GLProgram, pname:Int):Int {
		
		#if (js && html5 && !display)
		return context.getProgramParameter (program, pname);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_program_parameter (program.id, pname);
		#elseif java
		//return GL20.glGetProgramParameter (program.id, pname);
		return 0;
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function getRenderbufferParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		#if (js && html5 && !display)
		return context.getRenderbufferParameter (target, pname);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_render_buffer_parameter (target, pname);
		#elseif java
		//return GL30.glGetRenderbufferParameter (target, pname);
		return 0;
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function getShaderInfoLog (shader:GLShader):String {
		
		#if (js && html5 && !display)
		return context.getShaderInfoLog (shader);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_shader_info_log (shader.id);
		#elseif java
		return GL20.glGetShaderInfoLog (shader.id);
		#else
		return null;
		#end
		
	}
	
	
	public static inline function getShaderParameter (shader:GLShader, pname:Int):Int {
		
		#if (js && html5 && !display)
		return context.getShaderParameter (shader, pname);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_shader_parameter (shader.id, pname);
		#elseif java
		//return GL20.glGetShaderParameter (shader.id, pname);
		return 0;
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function getShaderPrecisionFormat (shadertype:Int, precisiontype:Int):GLShaderPrecisionFormat {
		
		#if (js && html5 && !display)
		return context.getShaderPrecisionFormat (shadertype, precisiontype);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		var result:Dynamic = lime_gl_get_shader_precision_format (shadertype, precisiontype);
		return result;
		#elseif java
		//return GL20.glGetShaderPrecisionFormat (shadertype, precisiontype);
		return null;
		#else
		return null;
		#end
		
	}
	
	
	public static inline function getShaderSource (shader:GLShader):String {
		
		#if (js && html5 && !display)
		return context.getShaderSource (shader);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_shader_source (shader.id);
		#elseif java
		return GL20.glGetShaderSource (shader.id);
		#else
		return null;
		#end
		
	}
	
	
	public static inline function getSupportedExtensions ():Array<String> {
		
		#if (js && html5 && !display)
		return context.getSupportedExtensions ();
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		var result = new Array<String> ();
		lime_gl_get_supported_extensions (result);
		return result;
		#elseif java
		return null;
		#else
		return null;
		#end
		
	}
	
	
	public static inline function getTexParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		#if (js && html5 && !display)
		return context.getTexParameter (target, pname);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_tex_parameter (target, pname);
		#elseif java
		//return GL11.nglGetTexParameteriv (target, pname);
		return 0;
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function getUniform (program:GLProgram, location:GLUniformLocation):Dynamic {
		
		#if (js && html5 && !display)
		return context.getUniform (program, location);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_uniform (program.id, location);
		#elseif java
		//return GL20.glGetUniform (program.id, location);
		return null;
		#else
		return null;
		#end
		
	}
	
	
	public static inline function getUniformLocation (program:GLProgram, name:String):GLUniformLocation {
		
		#if (js && html5 && !display)
		return context.getUniformLocation (program, name);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_uniform_location (program.id, name);
		#elseif java
		return GL20.glGetUniformLocation (program.id, name);
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function getVertexAttrib (index:Int, pname:Int):Int /*Dynamic*/ {
		
		#if (js && html5 && !display)
		return context.getVertexAttrib (index, pname);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_vertex_attrib (index, pname);
		#elseif java
		return 0;
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function getVertexAttribOffset (index:Int, pname:Int):Int {
		
		#if (js && html5 && !display)
		return context.getVertexAttribOffset (index, pname);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_get_vertex_attrib_offset (index, pname);
		#elseif java
		return 0;
		#else
		return 0;
		#end
		
	}
	
	
	public static inline function hint (target:Int, mode:Int):Void {
		
		#if (js && html5 && !display)
		context.hint (target, mode);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_hint (target, mode);
		#end
		
	}
	
	
	public static inline function isBuffer (buffer:GLBuffer):Bool {
		
		#if (js && html5 && !display)
		return context.isBuffer (buffer);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return buffer != null && buffer.id > 0 && lime_gl_is_buffer (buffer.id);
		#else
		return false;
		#end
		
	}
	
	
	public static inline function isContextLost ():Bool {
		
		#if (js && html5 && !display)
		return context.isContextLost ();
		#else
		return false;
		#end
		
	}
	
	
	public static inline function isEnabled (cap:Int):Bool {
		
		#if (js && html5 && !display)
		return context.isEnabled (cap);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return lime_gl_is_enabled (cap);
		#else
		return false;
		#end
		
	}
	
	
	public static inline function isFramebuffer (framebuffer:GLFramebuffer):Bool {
		
		#if (js && html5 && !display)
		return context.isFramebuffer (framebuffer);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return framebuffer != null && framebuffer.id > 0 && lime_gl_is_framebuffer (framebuffer.id);
		#else
		return false;
		#end
		
	}
	
	
	public static inline function isProgram (program:GLProgram):Bool {
		
		#if (js && html5 && !display)
		return context.isProgram (program);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return program != null && program.id > 0 && lime_gl_is_program (program.id);
		#else
		return false;
		#end
		
	}
	
	
	public static inline function isRenderbuffer (renderbuffer:GLRenderbuffer):Bool {
		
		#if (js && html5 && !display)
		return context.isRenderbuffer (renderbuffer);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return renderbuffer != null && renderbuffer.id > 0 && lime_gl_is_renderbuffer (renderbuffer.id);
		#else
		return false;
		#end
		
	}
	
	
	public static inline function isShader (shader:GLShader):Bool {
		
		#if (js && html5 && !display)
		return context.isShader (shader);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return shader != null && shader.id > 0 && lime_gl_is_shader (shader.id);
		#else
		return false;
		#end
		
	}
	
	
	public static inline function isTexture (texture:GLTexture):Bool {
		
		#if (js && html5 && !display)
		return context.isTexture (texture);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		return texture != null && texture.id > 0 && lime_gl_is_texture (texture.id);
		#else
		return false;
		#end
		
	}
	
	
	public static inline function lineWidth (width:Float):Void {
		
		#if (js && html5 && !display)
		context.lineWidth (width);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_line_width (width);
		#end
		
	}
	
	
	public static inline function linkProgram (program:GLProgram):Void {
		
		#if (js && html5 && !display)
		context.linkProgram (program);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_link_program (program.id);
		#end
		
	}
	
	
	public static inline function pixelStorei (pname:Int, param:Int):Void {
		
		#if (js && html5 && !display)
		context.pixelStorei (pname, param);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_pixel_storei (pname, param);
		#end
		
	}
	
	
	public static inline function polygonOffset (factor:Float, units:Float):Void {
		
		#if (js && html5 && !display)
		context.polygonOffset (factor, units);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_polygon_offset (factor, units);
		#end
		
	}
	
	
	public static inline function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		#if (js && html5 && !display)
		context.readPixels (x, y, width, height, format, type, pixels);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		var buffer = pixels == null ? null : pixels.buffer;
		lime_gl_read_pixels (x, y, width, height, format, type, buffer, pixels == null ? 0 : pixels.byteOffset);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_read_pixels (x, y, width, height, format, type, pixels == null ? null : pixels, pixels == null ? null : pixels.byteOffset);
		#end
		
	}
	
	
	public static inline function renderbufferStorage (target:Int, internalformat:Int, width:Int, height:Int):Void {
		
		#if (js && html5 && !display)
		context.renderbufferStorage (target, internalformat, width, height);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_renderbuffer_storage (target, internalformat, width, height);
		#end
		
	}
	
	
	public static inline function sampleCoverage (value:Float, invert:Bool):Void {
		
		#if (js && html5 && !display)
		context.sampleCoverage (value, invert);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_sample_coverage (value, invert);
		#end
		
	}
	
	
	public static inline function scissor (x:Int, y:Int, width:Int, height:Int):Void {
		
		#if (js && html5 && !display)
		context.scissor (x, y, width, height);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_scissor (x, y, width, height);
		#end
		
	}
	
	
	public static inline function shaderSource (shader:GLShader, source:String):Void {
		
		#if (js && html5 && !display)
		context.shaderSource (shader, source);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_shader_source (shader.id, source);
		#end
		
	}
	
	
	public static inline function stencilFunc (func:Int, ref:Int, mask:Int):Void {
		
		#if (js && html5 && !display)
		context.stencilFunc (func, ref, mask);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_stencil_func (func, ref, mask);
		#end
		
	}
	
	
	public static inline function stencilFuncSeparate (face:Int, func:Int, ref:Int, mask:Int):Void {
		
		#if (js && html5 && !display)
		context.stencilFuncSeparate (face, func, ref, mask);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_stencil_func_separate (face, func, ref, mask);
		#end
		
	}
	
	
	public static inline function stencilMask (mask:Int):Void {
		
		#if (js && html5 && !display)
		context.stencilMask (mask);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_stencil_mask (mask);
		#end
		
	}
	
	
	public static inline function stencilMaskSeparate (face:Int, mask:Int):Void {
		
		#if (js && html5 && !display)
		context.stencilMaskSeparate (face, mask);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_stencil_mask_separate (face, mask);
		#end
		
	}
	
	
	public static inline function stencilOp (fail:Int, zfail:Int, zpass:Int):Void {
		
		#if (js && html5 && !display)
		context.stencilOp (fail, zfail, zpass);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_stencil_op (fail, zfail, zpass);
		#end
		
	}
	
	
	public static inline function stencilOpSeparate (face:Int, fail:Int, zfail:Int, zpass:Int):Void {
		
		#if (js && html5 && !display)
		context.stencilOpSeparate (face, fail, zfail, zpass);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_stencil_op_separate (face, fail, zfail, zpass);
		#end
		
	}
	
	
	public static inline function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		#if (js && html5 && !display)
		context.texImage2D (target, level, internalformat, width, height, border, format, type, pixels);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		var buffer = pixels == null ? null : pixels.buffer;
		lime_gl_tex_image_2d (target, level, internalformat, width, height, border, format, type, buffer, pixels == null ? 0 : pixels.byteOffset);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_tex_image_2d (target, level, internalformat, width, height, border, format, type, pixels == null ? null : pixels, pixels == null ? null : pixels.byteOffset);
		#end
		
	}

	#if (js && html5)
		public static inline function texImage2DWeb (target:Int, level:Int, internalformat:Int, format:Int, type:Int, data:Dynamic):Void {
			
			context.texImage2D (target, level, internalformat, format, type, data);
			
		}
	#end
	
	public static inline function texParameterf (target:Int, pname:Int, param:Float):Void {
		
		#if (js && html5 && !display)
		context.texParameterf (target, pname, param);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_tex_parameterf (target, pname, param);
		#end
		
	}
	
	
	public static inline function texParameteri (target:Int, pname:Int, param:Int):Void {
		
		#if (js && html5 && !display)
		context.texParameteri (target, pname, param);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_tex_parameteri (target, pname, param);
		#end
		
	}
	
	
	public static inline function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		#if (js && html5 && !display)
		context.texSubImage2D (target, level, xoffset, yoffset, width, height, format, type, pixels);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		var buffer = pixels == null ? null : pixels.buffer;
		lime_gl_tex_sub_image_2d (target, level, xoffset, yoffset, width, height, format, type, buffer, pixels == null ? 0 : pixels.byteOffset);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_tex_sub_image_2d (target, level, xoffset, yoffset, width, height, format, type, pixels == null ? null : pixels, pixels == null ? null : pixels.byteOffset);
		#end
		
	}
	
	
	public static inline function uniform1f (location:GLUniformLocation, x:Float):Void {
		
		#if (js && html5 && !display)
		context.uniform1f (location, x);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_uniform1f (location, x);
		#end
		
	}
	
	
	public static inline function uniform1fv (location:GLUniformLocation, x:Float32Array):Void {
		
		#if (js && html5 && !display)
		context.uniform1fv (location, x);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_uniform1fv (location, x.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform1fv (location, x);
		#end
		
	}
	
	
	public static inline function uniform1i (location:GLUniformLocation, x:Int):Void {
		
		#if (js && html5 && !display)
		context.uniform1i (location, x);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_uniform1i (location, x);
		#end
		
	}
	
	
	public static inline function uniform1iv (location:GLUniformLocation, v:Int32Array):Void {
		
		#if (js && html5 && !display)
		context.uniform1iv (location, v);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_uniform1iv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform1iv (location, v);
		#end
		
	}
	
	
	public static inline function uniform2f (location:GLUniformLocation, x:Float, y:Float):Void {
		
		#if (js && html5 && !display)
		context.uniform2f (location, x, y);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_uniform2f (location, x, y);
		#end
		
	}
	
	
	public static inline function uniform2fv (location:GLUniformLocation, v:Float32Array):Void {
		
		#if (js && html5 && !display)
		context.uniform2fv (location, v);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_uniform2fv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform2fv (location, v);
		#end
		
	}
	
	
	public static inline function uniform2i (location:GLUniformLocation, x:Int, y:Int):Void {
		
		#if (js && html5 && !display)
		context.uniform2i (location, x, y);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_uniform2i (location, x, y);
		#end
		
	}
	
	
	public static inline function uniform2iv (location:GLUniformLocation, v:Int32Array):Void {
		
		#if (js && html5 && !display)
		context.uniform2iv (location, v);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_uniform2iv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform2iv (location, v);
		#end
		
	}
	
	
	public static inline function uniform3f (location:GLUniformLocation, x:Float, y:Float, z:Float):Void {
		
		#if (js && html5 && !display)
		context.uniform3f (location, x, y, z);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_uniform3f (location, x, y, z);
		#end
		
	}
	
	
	public static inline function uniform3fv (location:GLUniformLocation, v:Float32Array):Void {
		
		#if (js && html5 && !display)
		context.uniform3fv (location, v);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_uniform3fv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform3fv (location, v);
		#end
		
	}
	
	
	public static inline function uniform3i (location:GLUniformLocation, x:Int, y:Int, z:Int):Void {
		
		#if (js && html5 && !display)
		context.uniform3i (location, x, y, z);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_uniform3i (location, x, y, z);
		#end
		
	}
	
	
	public static inline function uniform3iv (location:GLUniformLocation, v:Int32Array):Void {
		
		#if (js && html5 && !display)
		context.uniform3iv (location, v);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_uniform3iv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform3iv (location, v);
		#end
		
	}
	
	
	public static inline function uniform4f (location:GLUniformLocation, x:Float, y:Float, z:Float, w:Float):Void {
		
		#if (js && html5 && !display)
		context.uniform4f (location, x, y, z, w);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_uniform4f (location, x, y, z, w);
		#end
		
	}
	
	
	public static inline function uniform4fv (location:GLUniformLocation, v:Float32Array):Void {
		
		#if (js && html5 && !display)
		context.uniform4fv (location, v);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_uniform4fv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform4fv (location, v);
		#end
		
	}
	
	
	public static inline function uniform4i (location:GLUniformLocation, x:Int, y:Int, z:Int, w:Int):Void {
		
		#if (js && html5 && !display)
		context.uniform4i (location, x, y, z, w);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_uniform4i (location, x, y, z, w);
		#end
		
	}
	
	
	public static inline function uniform4iv (location:GLUniformLocation, v:Int32Array):Void {
		
		#if (js && html5 && !display)
		context.uniform4iv (location, v);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_uniform4iv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform4iv (location, v);
		#end
		
	}
	
	
	public static inline function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		#if (js && html5 && !display)
		context.uniformMatrix2fv (location, transpose, v);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_uniform_matrix (location, transpose, v.buffer, 2);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform_matrix (location, transpose, v, 2);
		#end
		
	}
	
	
	public static inline function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		#if (js && html5 && !display)
		context.uniformMatrix3fv (location, transpose, v);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_uniform_matrix (location, transpose, v.buffer, 3);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform_matrix (location, transpose, v, 3);
		#end
		
	}
	
	
	public static inline function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		#if (js && html5 && !display)
		context.uniformMatrix4fv (location, transpose, v);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_uniform_matrix (location, transpose, v.buffer, 4);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform_matrix (location, transpose, v, 4);
		#end
		
	}
	
	
	/*public static inline function uniformMatrix3D(location:GLUniformLocation, transpose:Bool, matrix:Matrix3D):Void {
		
		lime_gl_uniform_matrix(location, transpose, Float32Array.fromMatrix(matrix).getByteBuffer() , 4);
		
	}*/
	
	
	public static inline function useProgram (program:GLProgram):Void {
		
		#if (js && html5 && !display)
		context.useProgram (program);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_use_program (program == null ? 0 : program.id);
		#end
		
	}
	
	
	public static inline function validateProgram (program:GLProgram):Void {
		
		#if (js && html5 && !display)
		context.validateProgram (program);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_validate_program (program.id);
		#end
		
	}
	
	
	public static inline function vertexAttrib1f (indx:Int, x:Float):Void {
		
		#if (js && html5 && !display)
		context.vertexAttrib1f (indx, x);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_vertex_attrib1f (indx, x);
		#end
		
	}
	
	
	public static inline function vertexAttrib1fv (indx:Int, values:Float32Array):Void {
		
		#if (js && html5 && !display)
		context.vertexAttrib1fv (indx, values);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_vertex_attrib1fv (indx, values.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_vertex_attrib1fv (indx, values);
		#end
		
	}
	
	
	public static inline function vertexAttrib2f (indx:Int, x:Float, y:Float):Void {
		
		#if (js && html5 && !display)
		context.vertexAttrib2f (indx, x, y);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_vertex_attrib2f (indx, x, y);
		#end
		
	}
	
	
	public static inline function vertexAttrib2fv (indx:Int, values:Float32Array):Void {
		
		#if (js && html5 && !display)
		context.vertexAttrib2fv (indx, values);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_vertex_attrib2fv (indx, values.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_vertex_attrib2fv (indx, values);
		#end
		
	}
	
	
	public static inline function vertexAttrib3f (indx:Int, x:Float, y:Float, z:Float):Void {
		
		#if (js && html5 && !display)
		context.vertexAttrib3f (indx, x, y, z);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_vertex_attrib3f (indx, x, y, z);
		#end
		
	}
	
	
	public static inline function vertexAttrib3fv (indx:Int, values:Float32Array):Void {
		
		#if (js && html5 && !display)
		context.vertexAttrib3fv (indx, values);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_vertex_attrib3fv (indx, values.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_vertex_attrib3fv (indx, values);
		#end
		
	}
	
	
	public static inline function vertexAttrib4f (indx:Int, x:Float, y:Float, z:Float, w:Float):Void {
		
		#if (js && html5 && !display)
		context.vertexAttrib4f (indx, x, y, z, w);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_vertex_attrib4f (indx, x, y, z, w);
		#end
		
	}
	
	
	public static inline function vertexAttrib4fv (indx:Int, values:Float32Array):Void {
		
		#if (js && html5 && !display)
		context.vertexAttrib4fv (indx, values);
		#elseif ((cpp || neko) && lime_opengl && !macro)
		lime_gl_vertex_attrib4fv (indx, values.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_vertex_attrib4fv (indx, values);
		#end
		
	}
	
	
	public static inline function vertexAttribPointer (indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int):Void {
		
		#if (js && html5 && !display)
		context.vertexAttribPointer (indx, size, type, normalized, stride, offset);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_vertex_attrib_pointer (indx, size, type, normalized, stride, offset);
		#end
		
	}
	
	
	public static inline function viewport (x:Int, y:Int, width:Int, height:Int):Void {
		
		#if (js && html5 && !display)
		context.viewport (x, y, width, height);
		#elseif ((cpp || neko || nodejs) && lime_opengl && !macro)
		lime_gl_viewport (x, y, width, height);
		#end
		
	}
	
	
	private static function get_version ():Int { return 2; }
	
	
	#if ((cpp || neko || nodejs) && lime_opengl && !macro)
	@:cffi private static function lime_gl_active_texture (texture:Int):Void;
	@:cffi private static function lime_gl_attach_shader (program:Int, shader:Int):Void;
	@:cffi private static function lime_gl_bind_attrib_location (program:Int, index:Int, name:String):Void;
	@:cffi private static function lime_gl_bind_buffer (target:Int, buffer:Int):Void;
	@:cffi private static function lime_gl_bind_framebuffer (target:Int, framebuffer:Int):Void;
	@:cffi private static function lime_gl_bind_renderbuffer (target:Int, renderbuffer:Int):Void;
	@:cffi private static function lime_gl_bind_texture (target:Int, texture:Int):Void;
	@:cffi private static function lime_gl_blend_color (red:Float32, green:Float32, blue:Float32, alpha:Float32):Void;
	@:cffi private static function lime_gl_blend_equation (mode:Int):Void;
	@:cffi private static function lime_gl_blend_equation_separate (modeRGB:Int, modeAlpha:Int):Void;
	@:cffi private static function lime_gl_blend_func (sfactor:Int, dfactor:Int):Void;
	@:cffi private static function lime_gl_blend_func_separate (srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int):Void;
	@:cffi private static function lime_gl_buffer_data (target:Int, buffer:Dynamic, byteOffset:Int, size:Int, usage:Int):Void;
	@:cffi private static function lime_gl_buffer_sub_data (target:Int, offset:Int, buffer:Dynamic, byteOffset:Int, size:Int):Void;
	@:cffi private static function lime_gl_check_framebuffer_status (target:Int):Int;
	@:cffi private static function lime_gl_clear (mask:Int):Void;
	@:cffi private static function lime_gl_clear_color (red:Float32, green:Float32, blue:Float32, alpha:Float32):Void;
	@:cffi private static function lime_gl_clear_depth (depth:Float32):Void;
	@:cffi private static function lime_gl_clear_stencil (s:Int):Void;
	@:cffi private static function lime_gl_color_mask (red:Bool, green:Bool, blue:Bool, alpha:Bool):Void;
	@:cffi private static function lime_gl_compile_shader (shader:Int):Void;
	@:cffi private static function lime_gl_compressed_tex_image_2d (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, buffer:Dynamic, byteOffset:Int):Void;
	@:cffi private static function lime_gl_compressed_tex_sub_image_2d (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, buffer:Dynamic, byteOffset:Int):Void;
	@:cffi private static function lime_gl_copy_tex_image_2d (target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void;
	@:cffi private static function lime_gl_copy_tex_sub_image_2d (target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void;
	@:cffi private static function lime_gl_create_buffer ():Int;
	@:cffi private static function lime_gl_create_framebuffer ():Int;
	@:cffi private static function lime_gl_create_program ():Int;
	@:cffi private static function lime_gl_create_render_buffer ():Int;
	@:cffi private static function lime_gl_create_shader (type:Int):Int;
	@:cffi private static function lime_gl_create_texture ():Int;
	@:cffi private static function lime_gl_cull_face (mode:Int):Void;
	@:cffi private static function lime_gl_delete_buffer (buffer:Int):Void;
	@:cffi private static function lime_gl_delete_framebuffer (framebuffer:Int):Void;
	@:cffi private static function lime_gl_delete_program (program:Int):Void;
	@:cffi private static function lime_gl_delete_render_buffer (renderbuffer:Int):Void;
	@:cffi private static function lime_gl_delete_shader (shader:Int):Void;
	@:cffi private static function lime_gl_delete_texture (texture:Int):Void;
	@:cffi private static function lime_gl_depth_func (func:Int):Void;
	@:cffi private static function lime_gl_depth_mask (flag:Bool):Void;
	@:cffi private static function lime_gl_depth_range (zNear:Float32, zFar:Float32):Void;
	@:cffi private static function lime_gl_detach_shader (program:Int, shader:Int):Void;
	@:cffi private static function lime_gl_disable (cap:Int):Void;
	@:cffi private static function lime_gl_disable_vertex_attrib_array (index:Int):Void;
	@:cffi private static function lime_gl_draw_arrays (mode:Int, first:Int, count:Int):Void;
	@:cffi private static function lime_gl_draw_elements (mode:Int, count:Int, type:Int, offset:Int):Void;
	@:cffi private static function lime_gl_enable (cap:Int):Void;
	@:cffi private static function lime_gl_enable_vertex_attrib_array (index:Int):Void;
	@:cffi private static function lime_gl_finish ():Void;
	@:cffi private static function lime_gl_flush ():Void;
	@:cffi private static function lime_gl_framebuffer_renderbuffer (target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:Int):Void;
	@:cffi private static function lime_gl_framebuffer_texture2D (target:Int, attachment:Int, textarget:Int, texture:Int, level:Int):Void;
	@:cffi private static function lime_gl_front_face (mode:Int):Void;
	@:cffi private static function lime_gl_generate_mipmap (target:Int):Void;
	@:cffi private static function lime_gl_get_active_attrib (program:Int, index:Int):Dynamic;
	@:cffi private static function lime_gl_get_active_uniform (program:Int, index:Int):Dynamic;
	@:cffi private static function lime_gl_get_attrib_location (program:Int, name:String):Int;
	@:cffi private static function lime_gl_get_buffer_parameter (target:Int, pname:Int):Int;
	@:cffi private static function lime_gl_get_context_attributes ():Dynamic;
	@:cffi private static function lime_gl_get_error ():Int;
	@:cffi private static function lime_gl_get_extension (name:String):Dynamic;
	@:cffi private static function lime_gl_get_framebuffer_attachment_parameter (target:Int, attachment:Int, pname:Int):Int;
	@:cffi private static function lime_gl_get_parameter (pname:Int):Dynamic;
	@:cffi private static function lime_gl_get_program_info_log (program:Int):String;
	@:cffi private static function lime_gl_get_program_parameter (program:Int, pname:Int):Int;
	@:cffi private static function lime_gl_get_render_buffer_parameter (target:Int, pname:Int):Int;
	@:cffi private static function lime_gl_get_shader_info_log (shader:Int):String;
	@:cffi private static function lime_gl_get_shader_parameter (shader:Int, pname:Int):Int;
	@:cffi private static function lime_gl_get_shader_precision_format (shadertype:Int, precisiontype:Int):Dynamic;
	@:cffi private static function lime_gl_get_shader_source (shader:Int):Dynamic;
	@:cffi private static function lime_gl_get_supported_extensions (result:Dynamic):Void;
	@:cffi private static function lime_gl_get_tex_parameter (target:Int, pname:Int):Int;
	@:cffi private static function lime_gl_get_uniform (program:Int, location:Int):Dynamic;
	@:cffi private static function lime_gl_get_uniform_location (program:Int, name:String):Int;
	@:cffi private static function lime_gl_get_vertex_attrib (index:Int, pname:Int):Int;
	@:cffi private static function lime_gl_get_vertex_attrib_offset (index:Int, pname:Int):Int;
	@:cffi private static function lime_gl_hint (target:Int, mode:Int):Void;
	@:cffi private static function lime_gl_is_buffer (buffer:Int):Bool;
	@:cffi private static function lime_gl_is_enabled (cap:Int):Bool;
	@:cffi private static function lime_gl_is_framebuffer (framebuffer:Int):Bool;
	@:cffi private static function lime_gl_is_program (program:Int):Bool;
	@:cffi private static function lime_gl_is_renderbuffer (renderbuffer:Int):Bool;
	@:cffi private static function lime_gl_is_shader (shader:Int):Bool;
	@:cffi private static function lime_gl_is_texture (texture:Int):Bool;
	@:cffi private static function lime_gl_line_width (width:Float32):Void;
	@:cffi private static function lime_gl_link_program (program:Int):Void;
	@:cffi private static function lime_gl_pixel_storei (pname:Int, param:Int):Void;
	@:cffi private static function lime_gl_polygon_offset (factor:Float32, units:Float32):Void;
	@:cffi private static function lime_gl_read_pixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, buffer:Dynamic, byteOffset:Int):Void;
	@:cffi private static function lime_gl_renderbuffer_storage (target:Int, internalformat:Int, width:Int, height:Int):Void;
	@:cffi private static function lime_gl_sample_coverage (value:Float32, invert:Bool):Void;
	@:cffi private static function lime_gl_scissor (x:Int, y:Int, width:Int, height:Int):Void;
	@:cffi private static function lime_gl_shader_source (shader:Int, source:String):Void;
	@:cffi private static function lime_gl_stencil_func (func:Int, ref:Int, mask:Int):Void;
	@:cffi private static function lime_gl_stencil_func_separate (face:Int, func:Int, ref:Int, mask:Int):Void;
	@:cffi private static function lime_gl_stencil_mask (mask:Int):Void;
	@:cffi private static function lime_gl_stencil_mask_separate (face:Int, mask:Int):Void;
	@:cffi private static function lime_gl_stencil_op (fail:Int, zfail:Int, zpass:Int):Void;
	@:cffi private static function lime_gl_stencil_op_separate (face:Int, fail:Int, zfail:Int, zpass:Int):Void;
	@:cffi private static function lime_gl_tex_image_2d (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, buffer:Dynamic, byteOffset:Int):Void;
	@:cffi private static function lime_gl_tex_parameterf (target:Int, pname:Int, param:Float32):Void;
	@:cffi private static function lime_gl_tex_parameteri (target:Int, pname:Int, param:Int):Void;
	@:cffi private static function lime_gl_tex_sub_image_2d (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, buffer:Dynamic, byteOffset:Int):Void;
	@:cffi private static function lime_gl_uniform1f (location:Int, x:Float32):Void;
	@:cffi private static function lime_gl_uniform1fv (location:Int, v:Dynamic):Void;
	@:cffi private static function lime_gl_uniform1i (location:Int, x:Int):Void;
	@:cffi private static function lime_gl_uniform1iv (location:Int, v:Dynamic):Void;
	@:cffi private static function lime_gl_uniform2f (location:Int, x:Float32, y:Float32):Void;
	@:cffi private static function lime_gl_uniform2fv (location:Int, v:Dynamic):Void;
	@:cffi private static function lime_gl_uniform2i (location:Int, x:Int, y:Int):Void;
	@:cffi private static function lime_gl_uniform2iv (location:Int, v:Dynamic):Void;
	@:cffi private static function lime_gl_uniform3f (location:Int, x:Float32, y:Float32, z:Float32):Void;
	@:cffi private static function lime_gl_uniform3fv (location:Int, v:Dynamic):Void;
	@:cffi private static function lime_gl_uniform3i (location:Int, x:Int, y:Int, z:Int):Void;
	@:cffi private static function lime_gl_uniform3iv (location:Int, v:Dynamic):Void;
	@:cffi private static function lime_gl_uniform4f (location:Int, x:Float32, y:Float32, z:Float32, w:Float32):Void;
	@:cffi private static function lime_gl_uniform4fv (location:Int, v:Dynamic):Void;
	@:cffi private static function lime_gl_uniform4i (location:Int, x:Int, y:Int, z:Int, w:Int):Void;
	@:cffi private static function lime_gl_uniform4iv (location:Int, v:Dynamic):Void;
	@:cffi private static function lime_gl_uniform_matrix (location:Int, transpose:Bool, buffer:Dynamic, count:Int):Void;
	@:cffi private static function lime_gl_use_program (program:Int):Void;
	@:cffi private static function lime_gl_validate_program (program:Int):Void;
	@:cffi private static function lime_gl_version ():String;
	@:cffi private static function lime_gl_vertex_attrib1f (indx:Int, x:Float32):Void;
	@:cffi private static function lime_gl_vertex_attrib1fv (indx:Int, values:Dynamic):Void;
	@:cffi private static function lime_gl_vertex_attrib2f (indx:Int, x:Float32, y:Float32):Void;
	@:cffi private static function lime_gl_vertex_attrib2fv (indx:Int, values:Dynamic):Void;
	@:cffi private static function lime_gl_vertex_attrib3f (indx:Int, x:Float32, y:Float32, z:Float32):Void;
	@:cffi private static function lime_gl_vertex_attrib3fv (indx:Int, values:Dynamic):Void;
	@:cffi private static function lime_gl_vertex_attrib4f (indx:Int, x:Float32, y:Float32, z:Float32, w:Float32):Void;
	@:cffi private static function lime_gl_vertex_attrib4fv (indx:Int, values:Dynamic):Void;
	@:cffi private static function lime_gl_vertex_attrib_pointer (indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int):Void;
	@:cffi private static function lime_gl_viewport (x:Int, y:Int, width:Int, height:Int):Void;
	#end
	
	
}
