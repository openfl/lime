package lime._backend.native;


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
import lime.utils.ArrayBuffer;
import lime.utils.ArrayBufferView;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import lime.system.CFFIPointer;
import lime.system.System;

#if cpp
import cpp.Float32;
#else
typedef Float32 = Float;
#end

#if !macro
@:build(lime.system.CFFI.build())
#end

@:allow(lime.ui.Window)


class NativeGLRenderContext {
	
	
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
	public var BGR_EXT = 0x80E0;
	public var BGRA_EXT = 0x80E1;
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
	
	public var version (get, null):Int;
	
	private var __currentProgram:GLProgram;
	
	
	private function new () {
		
		
		
	}
	
	
	public function activeTexture (texture:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_active_texture (texture);
		#end
		
	}
	
	
	public function attachShader (program:GLProgram, shader:GLShader):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		program.attach (shader);
		lime_gl_attach_shader (program.id, shader.id);
		#end
		
	}
	
	
	public function bindAttribLocation (program:GLProgram, index:Int, name:String):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_bind_attrib_location (program.id, index, name);
		#end
		
	}
	
	
	public function bindBuffer (target:Int, buffer:GLBuffer):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_bind_buffer (target, buffer == null ? null : buffer.id);
		#end
		
	}
	
	
	public function bindFramebuffer (target:Int, framebuffer:GLFramebuffer):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_bind_framebuffer (target, framebuffer == null ? null : framebuffer.id);
		#end
		
	}
	
	
	public function bindRenderbuffer (target:Int, renderbuffer:GLRenderbuffer):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_bind_renderbuffer (target, renderbuffer == null ? null : renderbuffer.id);
		#end
		
	}
	
	
	public function bindTexture (target:Int, texture:GLTexture):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_bind_texture (target, texture == null ? null : texture.id);
		#end
		
	}
	
	
	public function blendColor (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_blend_color (red, green, blue, alpha);
		#end
		
	}
	
	
	public function blendEquation (mode:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_blend_equation (mode);
		#end
		
	}
	
	
	public function blendEquationSeparate (modeRGB:Int, modeAlpha:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_blend_equation_separate (modeRGB, modeAlpha);
		#end
		
	}
	
	
	public function blendFunc (sfactor:Int, dfactor:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_blend_func (sfactor, dfactor);
		#end
		
	}
	
	
	public function blendFuncSeparate (srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_blend_func_separate (srcRGB, dstRGB, srcAlpha, dstAlpha);
		#end
		
	}
	
	
	public function bufferData (target:Int, data:ArrayBufferView, usage:Int):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_buffer_data (target, data.buffer, data.byteOffset, data.byteLength, usage);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_buffer_data (target, data, data.byteOffset, data.byteLength, usage);
		#end
		
	}
	
	
	public function bufferSubData (target:Int, offset:Int, data:ArrayBufferView):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_buffer_sub_data (target, offset, data.buffer, data.byteOffset, data.byteLength);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_buffer_sub_data (target, offset, data, data.byteOffset, data.byteLength);
		#end
		
	}
	
	
	public function checkFramebufferStatus (target:Int):Int {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_check_framebuffer_status (target);
		#else
		return 0;
		#end
		
	}
	
	
	public function clear (mask:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_clear (mask);
		#end
		
	}
	
	
	public function clearColor (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_clear_color (red, green, blue, alpha);
		#end
		
	}
	
	
	public function clearDepth (depth:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_clear_depth (depth);
		#end
		
	}
	
	
	public function clearStencil (s:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_clear_stencil (s);
		#end
		
	}
	
	
	public function colorMask (red:Bool, green:Bool, blue:Bool, alpha:Bool):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_color_mask (red, green, blue, alpha);
		#end
		
	}
	
	
	public function compileShader (shader:GLShader):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_compile_shader (shader.id);
		#end
		
	}
	
	
	public function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, data:ArrayBufferView):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		var buffer = data == null ? null : data.buffer;
		lime_gl_compressed_tex_image_2d (target, level, internalformat, width, height, border, buffer, data == null ? 0 : data.byteOffset);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_compressed_tex_image_2d (target, level, internalformat, width, height, border, data == null ? null : data , data == null ? null : data.byteOffset);
		#end
		
	}
	
	
	public function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, data:ArrayBufferView):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		var buffer = data == null ? null : data.buffer;
		lime_gl_compressed_tex_sub_image_2d (target, level, xoffset, yoffset, width, height, format, buffer, data == null ? 0 : data.byteOffset);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_compressed_tex_sub_image_2d (target, level, xoffset, yoffset, width, height, format, data == null ? null : data, data == null ? null : data.byteOffset);
		#end
		
	}
	
	
	public function copyTexImage2D (target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_copy_tex_image_2d (target, level, internalformat, x, y, width, height, border);
		#end
		
	}
	
	
	public function copyTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_copy_tex_sub_image_2d (target, level, xoffset, yoffset, x, y, width, height);
		#end
		
	}
	
	
	public function createBuffer ():GLBuffer {
		
		#if (lime_cffi && lime_opengl && !macro)
		return new GLBuffer (version, lime_gl_create_buffer ());
		#else
		return null;
		#end
		
	}
	
	
	public function createFramebuffer ():GLFramebuffer {
		
		#if (lime_cffi && lime_opengl && !macro)
		return new GLFramebuffer (version, lime_gl_create_framebuffer ());
		#else
		return null;
		#end
		
	}
	
	
	public function createProgram ():GLProgram {
		
		#if (lime_cffi && lime_opengl && !macro)
		return new GLProgram (version, lime_gl_create_program ());
		#else
		return null;
		#end
		
	}
	
	
	public function createRenderbuffer ():GLRenderbuffer {
		
		#if (lime_cffi && lime_opengl && !macro)
		return new GLRenderbuffer (version, lime_gl_create_render_buffer ());
		#else
		return null;
		#end
		
	}
	
	
	public function createShader (type:Int):GLShader {
		
		#if (lime_cffi && lime_opengl && !macro)
		return new GLShader (version, lime_gl_create_shader (type));
		#else
		return null;
		#end
		
	}
	
	
	public function createTexture ():GLTexture {
		
		#if (lime_cffi && lime_opengl && !macro)
		return new GLTexture (version, lime_gl_create_texture ());
		#else
		return null;
		#end
		
	}
	
	
	public function cullFace (mode:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_cull_face (mode);
		#end
		
	}
	
	
	public function deleteBuffer (buffer:GLBuffer):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_delete_buffer (buffer.id);
		buffer.invalidate ();
		#end
		
	}
	
	
	public function deleteFramebuffer (framebuffer:GLFramebuffer):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_delete_framebuffer (framebuffer.id);
		framebuffer.invalidate ();
		#end
		
	}
	
	
	public function deleteProgram (program:GLProgram):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_delete_program (program.id);
		program.invalidate ();
		#end
		
	}
	
	
	public function deleteRenderbuffer (renderbuffer:GLRenderbuffer):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_delete_render_buffer (renderbuffer.id);
		renderbuffer.invalidate ();
		#end
		
	}
	
	
	public function deleteShader (shader:GLShader):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_delete_shader (shader.id);
		shader.invalidate ();
		#end
		
	}
	
	
	public function deleteTexture (texture:GLTexture):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_delete_texture (texture.id);
		texture.invalidate ();
		#end
		
	}
	
	
	public function depthFunc (func:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_depth_func (func);
		#end
		
	}
	
	
	public function depthMask (flag:Bool):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_depth_mask (flag);
		#end
		
	}
	
	
	public function depthRange (zNear:Float, zFar:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_depth_range (zNear, zFar);
		#end
		
	}
	
	
	public function detachShader (program:GLProgram, shader:GLShader):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_detach_shader (program.id, shader.id);
		#end
		
	}
	
	
	public function disable (cap:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_disable (cap);
		#end
		
	}
	
	
	public function disableVertexAttribArray (index:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_disable_vertex_attrib_array (index);
		#end
		
	}
	
	
	public function drawArrays (mode:Int, first:Int, count:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_draw_arrays (mode, first, count);
		#end
		
	}
	
	
	public function drawElements (mode:Int, count:Int, type:Int, offset:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_draw_elements (mode, count, type, offset);
		#end
		
	}
	
	
	public function enable (cap:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_enable (cap);
		#end
		
	}
	
	
	public function enableVertexAttribArray (index:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_enable_vertex_attrib_array (index);
		#end
		
	}
	
	
	public function finish ():Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_finish ();
		#end
		
	}
	
	
	public function flush ():Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_flush ();
		#end
		
	}
	
	
	public function framebufferRenderbuffer (target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:GLRenderbuffer):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_framebuffer_renderbuffer (target, attachment, renderbuffertarget, renderbuffer.id);
		#end
		
	}
	
	
	public function framebufferTexture2D (target:Int, attachment:Int, textarget:Int, texture:GLTexture, level:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_framebuffer_texture2D (target, attachment, textarget, texture.id, level);
		#end
		
	}
	
	
	public function frontFace (mode:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_front_face (mode);
		#end
		
	}
	
	
	public function generateMipmap (target:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_generate_mipmap (target);
		#end
		
	}
	
	
	public function getActiveAttrib (program:GLProgram, index:Int):GLActiveInfo {
		
		#if (lime_cffi && lime_opengl && !macro)
		var result:Dynamic = lime_gl_get_active_attrib (program.id, index);
		return result;
		#else
		return null;
		#end
		
	}
	
	
	public function getActiveUniform (program:GLProgram, index:Int):GLActiveInfo {
		
		#if (lime_cffi && lime_opengl && !macro)
		var result:Dynamic = lime_gl_get_active_uniform (program.id, index);
		return result;
		#else
		return null;
		#end
		
	}
	
	
	public function getAttachedShaders (program:GLProgram):Array<GLShader> {
		
		#if (lime_cffi && lime_opengl && !macro)
		return program.getShaders ();
		#else
		return null;
		#end
		
	}
	
	
	public function getAttribLocation (program:GLProgram, name:String):Int {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_attrib_location (program.id, name);
		#else
		return 0;
		#end
		
	}
	
	
	public function getBufferParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_buffer_parameter (target, pname);
		#else
		return 0;
		#end
		
	}
	
	
	public function getContextAttributes ():GLContextAttributes {
		
		#if (lime_cffi && lime_opengl && !macro)
		var base:Dynamic = lime_gl_get_context_attributes ();
		base.premultipliedAlpha = false;
		base.preserveDrawingBuffer = false;
		return base;
		#else
		return null;
		#end
		
	}
	
	
	public function getError ():Int {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_error ();
		#else
		return 0;
		#end
		
	}
	
	
	public function getExtension (name:String):Dynamic {
		
		#if (lime_cffi && lime_opengl && !macro)
		
		// TODO: Return extension objects
		
		return lime_gl_get_extension (name);
		#else
		return null;
		#end
		
	}
	
	
	public function getFramebufferAttachmentParameter (target:Int, attachment:Int, pname:Int):Int /*Dynamic*/ {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_framebuffer_attachment_parameter (target, attachment, pname);
		#else
		return 0;
		#end
		
	}
	
	
	public function getParameter (pname:Int):Dynamic {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_parameter (pname);
		#else
		return null;
		#end
		
	}
	
	
	public function getProgramInfoLog (program:GLProgram):String {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_program_info_log (program.id);
		#else
		return null;
		#end
		
	}
	
	
	public function getProgramParameter (program:GLProgram, pname:Int):Int {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_program_parameter (program.id, pname);
		#else
		return 0;
		#end
		
	}
	
	
	public function getRenderbufferParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_render_buffer_parameter (target, pname);
		#else
		return 0;
		#end
		
	}
	
	
	public function getShaderInfoLog (shader:GLShader):String {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_shader_info_log (shader.id);
		#else
		return null;
		#end
		
	}
	
	
	public function getShaderParameter (shader:GLShader, pname:Int):Int {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_shader_parameter (shader.id, pname);
		#else
		return 0;
		#end
		
	}
	
	
	public function getShaderPrecisionFormat (shadertype:Int, precisiontype:Int):GLShaderPrecisionFormat {
		
		#if (lime_cffi && lime_opengl && !macro)
		var result:Dynamic = lime_gl_get_shader_precision_format (shadertype, precisiontype);
		return result;
		#else
		return null;
		#end
		
	}
	
	
	public function getShaderSource (shader:GLShader):String {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_shader_source (shader.id);
		#else
		return null;
		#end
		
	}
	
	
	public function getSupportedExtensions ():Array<String> {
		
		#if (lime_cffi && lime_opengl && !macro)
		var result = new Array<String> ();
		lime_gl_get_supported_extensions (result);
		return result;
		#else
		return null;
		#end
		
	}
	
	
	public function getTexParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_tex_parameter (target, pname);
		#else
		return 0;
		#end
		
	}
	
	
	public function getUniform (program:GLProgram, location:GLUniformLocation):Dynamic {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_uniform (program.id, location);
		#else
		return null;
		#end
		
	}
	
	
	public function getUniformLocation (program:GLProgram, name:String):GLUniformLocation {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_uniform_location (program.id, name);
		#else
		return 0;
		#end
		
	}
	
	
	public function getVertexAttrib (index:Int, pname:Int):Int /*Dynamic*/ {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_vertex_attrib (index, pname);
		#else
		return 0;
		#end
		
	}
	
	
	public function getVertexAttribOffset (index:Int, pname:Int):Int {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_get_vertex_attrib_offset (index, pname);
		#else
		return 0;
		#end
		
	}
	
	
	public function hint (target:Int, mode:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_hint (target, mode);
		#end
		
	}
	
	
	public function isBuffer (buffer:GLBuffer):Bool {
		
		#if (lime_cffi && lime_opengl && !macro)
		return buffer != null && buffer.id > 0 && lime_gl_is_buffer (buffer.id);
		#else
		return false;
		#end
		
	}
	
	
	public function isContextLost ():Bool {
		
		return false;
		
	}
	
	
	public function isEnabled (cap:Int):Bool {
		
		#if (lime_cffi && lime_opengl && !macro)
		return lime_gl_is_enabled (cap);
		#else
		return false;
		#end
		
	}
	
	
	public function isFramebuffer (framebuffer:GLFramebuffer):Bool {
		
		#if (lime_cffi && lime_opengl && !macro)
		return framebuffer != null && framebuffer.id > 0 && lime_gl_is_framebuffer (framebuffer.id);
		#else
		return false;
		#end
		
	}
	
	
	public function isProgram (program:GLProgram):Bool {
		
		#if (lime_cffi && lime_opengl && !macro)
		return program != null && program.id > 0 && lime_gl_is_program (program.id);
		#else
		return false;
		#end
		
	}
	
	
	public function isRenderbuffer (renderbuffer:GLRenderbuffer):Bool {
		
		#if (lime_cffi && lime_opengl && !macro)
		return renderbuffer != null && renderbuffer.id > 0 && lime_gl_is_renderbuffer (renderbuffer.id);
		#else
		return false;
		#end
		
	}
	
	
	public function isShader (shader:GLShader):Bool {
		
		#if (lime_cffi && lime_opengl && !macro)
		return shader != null && shader.id > 0 && lime_gl_is_shader (shader.id);
		#else
		return false;
		#end
		
	}
	
	
	public function isTexture (texture:GLTexture):Bool {
		
		#if (lime_cffi && lime_opengl && !macro)
		return texture != null && texture.id > 0 && lime_gl_is_texture (texture.id);
		#else
		return false;
		#end
		
	}
	
	
	public function lineWidth (width:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_line_width (width);
		#end
		
	}
	
	
	public function linkProgram (program:GLProgram):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_link_program (program.id);
		#end
		
	}
	
	
	public function pixelStorei (pname:Int, param:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_pixel_storei (pname, param);
		#end
		
	}
	
	
	public function polygonOffset (factor:Float, units:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_polygon_offset (factor, units);
		#end
		
	}
	
	
	public function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		var buffer = pixels == null ? null : pixels.buffer;
		lime_gl_read_pixels (x, y, width, height, format, type, buffer, pixels == null ? 0 : pixels.byteOffset);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_read_pixels (x, y, width, height, format, type, pixels == null ? null : pixels, pixels == null ? null : pixels.byteOffset);
		#end
		
	}
	
	
	public function renderbufferStorage (target:Int, internalformat:Int, width:Int, height:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_renderbuffer_storage (target, internalformat, width, height);
		#end
		
	}
	
	
	public function sampleCoverage (value:Float, invert:Bool):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_sample_coverage (value, invert);
		#end
		
	}
	
	
	public function scissor (x:Int, y:Int, width:Int, height:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_scissor (x, y, width, height);
		#end
		
	}
	
	
	public function shaderSource (shader:GLShader, source:String):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_shader_source (shader.id, source);
		#end
		
	}
	
	
	public function stencilFunc (func:Int, ref:Int, mask:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_stencil_func (func, ref, mask);
		#end
		
	}
	
	
	public function stencilFuncSeparate (face:Int, func:Int, ref:Int, mask:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_stencil_func_separate (face, func, ref, mask);
		#end
		
	}
	
	
	public function stencilMask (mask:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_stencil_mask (mask);
		#end
		
	}
	
	
	public function stencilMaskSeparate (face:Int, mask:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_stencil_mask_separate (face, mask);
		#end
		
	}
	
	
	public function stencilOp (fail:Int, zfail:Int, zpass:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_stencil_op (fail, zfail, zpass);
		#end
		
	}
	
	
	public function stencilOpSeparate (face:Int, fail:Int, zfail:Int, zpass:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_stencil_op_separate (face, fail, zfail, zpass);
		#end
		
	}
	
	
	public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		var buffer = pixels == null ? null : pixels.buffer;
		lime_gl_tex_image_2d (target, level, internalformat, width, height, border, format, type, buffer, pixels == null ? 0 : pixels.byteOffset);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_tex_image_2d (target, level, internalformat, width, height, border, format, type, pixels == null ? null : pixels, pixels == null ? null : pixels.byteOffset);
		#end
		
	}
	
	
	public function texParameterf (target:Int, pname:Int, param:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_tex_parameterf (target, pname, param);
		#end
		
	}
	
	
	public function texParameteri (target:Int, pname:Int, param:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_tex_parameteri (target, pname, param);
		#end
		
	}
	
	
	public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		var buffer = pixels == null ? null : pixels.buffer;
		lime_gl_tex_sub_image_2d (target, level, xoffset, yoffset, width, height, format, type, buffer, pixels == null ? 0 : pixels.byteOffset);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_tex_sub_image_2d (target, level, xoffset, yoffset, width, height, format, type, pixels == null ? null : pixels, pixels == null ? null : pixels.byteOffset);
		#end
		
	}
	
	
	public function uniform1f (location:GLUniformLocation, x:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_uniform1f (location, x);
		#end
		
	}
	
	
	public function uniform1fv (location:GLUniformLocation, x:Float32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_uniform1fv (location, x.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform1fv (location, x);
		#end
		
	}
	
	
	public function uniform1i (location:GLUniformLocation, x:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_uniform1i (location, x);
		#end
		
	}
	
	
	public function uniform1iv (location:GLUniformLocation, v:Int32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_uniform1iv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform1iv (location, v);
		#end
		
	}
	
	
	public function uniform2f (location:GLUniformLocation, x:Float, y:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_uniform2f (location, x, y);
		#end
		
	}
	
	
	public function uniform2fv (location:GLUniformLocation, v:Float32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_uniform2fv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform2fv (location, v);
		#end
		
	}
	
	
	public function uniform2i (location:GLUniformLocation, x:Int, y:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_uniform2i (location, x, y);
		#end
		
	}
	
	
	public function uniform2iv (location:GLUniformLocation, v:Int32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_uniform2iv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform2iv (location, v);
		#end
		
	}
	
	
	public function uniform3f (location:GLUniformLocation, x:Float, y:Float, z:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_uniform3f (location, x, y, z);
		#end
		
	}
	
	
	public function uniform3fv (location:GLUniformLocation, v:Float32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_uniform3fv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform3fv (location, v);
		#end
		
	}
	
	
	public function uniform3i (location:GLUniformLocation, x:Int, y:Int, z:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_uniform3i (location, x, y, z);
		#end
		
	}
	
	
	public function uniform3iv (location:GLUniformLocation, v:Int32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_uniform3iv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform3iv (location, v);
		#end
		
	}
	
	
	public function uniform4f (location:GLUniformLocation, x:Float, y:Float, z:Float, w:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_uniform4f (location, x, y, z, w);
		#end
		
	}
	
	
	public function uniform4fv (location:GLUniformLocation, v:Float32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_uniform4fv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform4fv (location, v);
		#end
		
	}
	
	
	public function uniform4i (location:GLUniformLocation, x:Int, y:Int, z:Int, w:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_uniform4i (location, x, y, z, w);
		#end
		
	}
	
	
	public function uniform4iv (location:GLUniformLocation, v:Int32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_uniform4iv (location, v.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform4iv (location, v);
		#end
		
	}
	
	
	public function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_uniform_matrix (location, transpose, v.buffer, 2);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform_matrix (location, transpose, v, 2);
		#end
		
	}
	
	
	public function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_uniform_matrix (location, transpose, v.buffer, 3);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform_matrix (location, transpose, v, 3);
		#end
		
	}
	
	
	public function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_uniform_matrix (location, transpose, v.buffer, 4);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_uniform_matrix (location, transpose, v, 4);
		#end
		
	}
	
	
	/*public function uniformMatrix3D(location:GLUniformLocation, transpose:Bool, matrix:Matrix3D):Void {
		
		lime_gl_uniform_matrix(location, transpose, Float32Array.fromMatrix(matrix).getByteBuffer() , 4);
		
	}*/
	
	
	public function useProgram (program:GLProgram):Void {
		
		__currentProgram = program;
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_use_program (program == null ? null : program.id);
		#end
		
	}
	
	
	public function validateProgram (program:GLProgram):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_validate_program (program.id);
		#end
		
	}
	
	
	public function vertexAttrib1f (indx:Int, x:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_vertex_attrib1f (indx, x);
		#end
		
	}
	
	
	public function vertexAttrib1fv (indx:Int, values:Float32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_vertex_attrib1fv (indx, values.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_vertex_attrib1fv (indx, values);
		#end
		
	}
	
	
	public function vertexAttrib2f (indx:Int, x:Float, y:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_vertex_attrib2f (indx, x, y);
		#end
		
	}
	
	
	public function vertexAttrib2fv (indx:Int, values:Float32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_vertex_attrib2fv (indx, values.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_vertex_attrib2fv (indx, values);
		#end
		
	}
	
	
	public function vertexAttrib3f (indx:Int, x:Float, y:Float, z:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_vertex_attrib3f (indx, x, y, z);
		#end
		
	}
	
	
	public function vertexAttrib3fv (indx:Int, values:Float32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_vertex_attrib3fv (indx, values.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_vertex_attrib3fv (indx, values);
		#end
		
	}
	
	
	public function vertexAttrib4f (indx:Int, x:Float, y:Float, z:Float, w:Float):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_vertex_attrib4f (indx, x, y, z, w);
		#end
		
	}
	
	
	public function vertexAttrib4fv (indx:Int, values:Float32Array):Void {
		
		#if (lime_cffi && !nodejs && lime_opengl && !macro)
		lime_gl_vertex_attrib4fv (indx, values.buffer);
		#elseif (nodejs && lime_opengl && !macro)
		lime_gl_vertex_attrib4fv (indx, values);
		#end
		
	}
	
	
	public function vertexAttribPointer (indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_vertex_attrib_pointer (indx, size, type, normalized, stride, offset);
		#end
		
	}
	
	
	public function viewport (x:Int, y:Int, width:Int, height:Int):Void {
		
		#if (lime_cffi && lime_opengl && !macro)
		lime_gl_viewport (x, y, width, height);
		#end
		
	}
	
	
	private function get_version ():Int { return 2; }
	
	
	#if (lime_cffi && lime_opengl && !macro)
	@:cffi private static function lime_gl_active_texture (texture:Int):Void;
	@:cffi private static function lime_gl_attach_shader (program:CFFIPointer, shader:CFFIPointer):Void;
	@:cffi private static function lime_gl_bind_attrib_location (program:CFFIPointer, index:Int, name:String):Void;
	@:cffi private static function lime_gl_bind_buffer (target:Int, buffer:CFFIPointer):Void;
	@:cffi private static function lime_gl_bind_framebuffer (target:Int, framebuffer:CFFIPointer):Void;
	@:cffi private static function lime_gl_bind_renderbuffer (target:Int, renderbuffer:CFFIPointer):Void;
	@:cffi private static function lime_gl_bind_texture (target:Int, texture:CFFIPointer):Void;
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
	@:cffi private static function lime_gl_compile_shader (shader:CFFIPointer):Void;
	@:cffi private static function lime_gl_compressed_tex_image_2d (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, buffer:Dynamic, byteOffset:Int):Void;
	@:cffi private static function lime_gl_compressed_tex_sub_image_2d (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, buffer:Dynamic, byteOffset:Int):Void;
	@:cffi private static function lime_gl_copy_tex_image_2d (target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void;
	@:cffi private static function lime_gl_copy_tex_sub_image_2d (target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void;
	@:cffi private static function lime_gl_create_buffer ():CFFIPointer;
	@:cffi private static function lime_gl_create_framebuffer ():CFFIPointer;
	@:cffi private static function lime_gl_create_program ():CFFIPointer;
	@:cffi private static function lime_gl_create_render_buffer ():CFFIPointer;
	@:cffi private static function lime_gl_create_shader (type:Int):CFFIPointer;
	@:cffi private static function lime_gl_create_texture ():CFFIPointer;
	@:cffi private static function lime_gl_cull_face (mode:Int):Void;
	@:cffi private static function lime_gl_delete_buffer (buffer:CFFIPointer):Void;
	@:cffi private static function lime_gl_delete_framebuffer (framebuffer:CFFIPointer):Void;
	@:cffi private static function lime_gl_delete_program (program:CFFIPointer):Void;
	@:cffi private static function lime_gl_delete_render_buffer (renderbuffer:CFFIPointer):Void;
	@:cffi private static function lime_gl_delete_shader (shader:CFFIPointer):Void;
	@:cffi private static function lime_gl_delete_texture (texture:CFFIPointer):Void;
	@:cffi private static function lime_gl_depth_func (func:Int):Void;
	@:cffi private static function lime_gl_depth_mask (flag:Bool):Void;
	@:cffi private static function lime_gl_depth_range (zNear:Float32, zFar:Float32):Void;
	@:cffi private static function lime_gl_detach_shader (program:CFFIPointer, shader:CFFIPointer):Void;
	@:cffi private static function lime_gl_disable (cap:Int):Void;
	@:cffi private static function lime_gl_disable_vertex_attrib_array (index:Int):Void;
	@:cffi private static function lime_gl_draw_arrays (mode:Int, first:Int, count:Int):Void;
	@:cffi private static function lime_gl_draw_elements (mode:Int, count:Int, type:Int, offset:Int):Void;
	@:cffi private static function lime_gl_enable (cap:Int):Void;
	@:cffi private static function lime_gl_enable_vertex_attrib_array (index:Int):Void;
	@:cffi private static function lime_gl_finish ():Void;
	@:cffi private static function lime_gl_flush ():Void;
	@:cffi private static function lime_gl_framebuffer_renderbuffer (target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:CFFIPointer):Void;
	@:cffi private static function lime_gl_framebuffer_texture2D (target:Int, attachment:Int, textarget:Int, texture:CFFIPointer, level:Int):Void;
	@:cffi private static function lime_gl_front_face (mode:Int):Void;
	@:cffi private static function lime_gl_generate_mipmap (target:Int):Void;
	@:cffi private static function lime_gl_get_active_attrib (program:CFFIPointer, index:Int):Dynamic;
	@:cffi private static function lime_gl_get_active_uniform (program:CFFIPointer, index:Int):Dynamic;
	@:cffi private static function lime_gl_get_attrib_location (program:CFFIPointer, name:String):Int;
	@:cffi private static function lime_gl_get_buffer_parameter (target:Int, pname:Int):Int;
	@:cffi private static function lime_gl_get_context_attributes ():Dynamic;
	@:cffi private static function lime_gl_get_error ():Int;
	@:cffi private static function lime_gl_get_extension (name:String):Dynamic;
	@:cffi private static function lime_gl_get_framebuffer_attachment_parameter (target:Int, attachment:Int, pname:Int):Int;
	@:cffi private static function lime_gl_get_parameter (pname:Int):Dynamic;
	@:cffi private static function lime_gl_get_program_info_log (program:CFFIPointer):Dynamic;
	@:cffi private static function lime_gl_get_program_parameter (program:CFFIPointer, pname:Int):Int;
	@:cffi private static function lime_gl_get_render_buffer_parameter (target:Int, pname:Int):Int;
	@:cffi private static function lime_gl_get_shader_info_log (shader:CFFIPointer):Dynamic;
	@:cffi private static function lime_gl_get_shader_parameter (shader:CFFIPointer, pname:Int):Int;
	@:cffi private static function lime_gl_get_shader_precision_format (shadertype:Int, precisiontype:Int):Dynamic;
	@:cffi private static function lime_gl_get_shader_source (shader:CFFIPointer):Dynamic;
	@:cffi private static function lime_gl_get_supported_extensions (result:Dynamic):Void;
	@:cffi private static function lime_gl_get_tex_parameter (target:Int, pname:Int):Int;
	@:cffi private static function lime_gl_get_uniform (program:CFFIPointer, location:Int):Dynamic;
	@:cffi private static function lime_gl_get_uniform_location (program:CFFIPointer, name:String):Int;
	@:cffi private static function lime_gl_get_vertex_attrib (index:Int, pname:Int):Int;
	@:cffi private static function lime_gl_get_vertex_attrib_offset (index:Int, pname:Int):Int;
	@:cffi private static function lime_gl_hint (target:Int, mode:Int):Void;
	@:cffi private static function lime_gl_is_buffer (buffer:CFFIPointer):Bool;
	@:cffi private static function lime_gl_is_enabled (cap:Int):Bool;
	@:cffi private static function lime_gl_is_framebuffer (framebuffer:CFFIPointer):Bool;
	@:cffi private static function lime_gl_is_program (program:CFFIPointer):Bool;
	@:cffi private static function lime_gl_is_renderbuffer (renderbuffer:CFFIPointer):Bool;
	@:cffi private static function lime_gl_is_shader (shader:CFFIPointer):Bool;
	@:cffi private static function lime_gl_is_texture (texture:CFFIPointer):Bool;
	@:cffi private static function lime_gl_line_width (width:Float32):Void;
	@:cffi private static function lime_gl_link_program (program:CFFIPointer):Void;
	@:cffi private static function lime_gl_pixel_storei (pname:Int, param:Int):Void;
	@:cffi private static function lime_gl_polygon_offset (factor:Float32, units:Float32):Void;
	@:cffi private static function lime_gl_read_pixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, buffer:Dynamic, byteOffset:Int):Void;
	@:cffi private static function lime_gl_renderbuffer_storage (target:Int, internalformat:Int, width:Int, height:Int):Void;
	@:cffi private static function lime_gl_sample_coverage (value:Float32, invert:Bool):Void;
	@:cffi private static function lime_gl_scissor (x:Int, y:Int, width:Int, height:Int):Void;
	@:cffi private static function lime_gl_shader_source (shader:CFFIPointer, source:String):Void;
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
	@:cffi private static function lime_gl_use_program (program:CFFIPointer):Void;
	@:cffi private static function lime_gl_validate_program (program:CFFIPointer):Void;
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