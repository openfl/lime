package lime._backend.html5;


import haxe.io.Bytes;
import js.html.webgl.RenderingContext in WebGLRenderingContext;
import js.html.CanvasElement;
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
import lime.utils.ArrayBuffer;
import lime.utils.ArrayBufferView;
import lime.utils.BytePointer;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import lime.utils.UInt8Array;

@:allow(lime.ui.Window)


class HTML5GLRenderContext {
	
	
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
	
	#if (js && html5)
	public var canvas (get, never):CanvasElement;
	public var drawingBufferHeight (get, never):Int;
	public var drawingBufferWidth (get, never):Int;
	#end
	
	public var type:GLContextType;
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
				
				if (Std.is (gl, WebGL2RenderingContext)) {
					
					version = 2;
					
				}
				
			}
			
		}
		
	}
	
	
	public inline function activeTexture (texture:Int):Void {
		
		__context.activeTexture (texture);
		
	}
	
	
	public inline function attachShader (program:GLProgram, shader:GLShader):Void {
		
		__context.attachShader (program, shader);
		
	}
	
	
	public inline function bindAttribLocation (program:GLProgram, index:Int, name:String):Void {
		
		__context.bindAttribLocation (program, index, name);
		
	}
	
	
	public inline function bindBuffer (target:Int, buffer:GLBuffer):Void {
		
		__context.bindBuffer (target, buffer);
		
	}
	
	
	public inline function bindFramebuffer (target:Int, framebuffer:GLFramebuffer):Void {
		
		__context.bindFramebuffer (target, framebuffer);
		
	}
	
	
	public inline function bindRenderbuffer (target:Int, renderbuffer:GLRenderbuffer):Void {
		
		__context.bindRenderbuffer (target, renderbuffer);
		
	}
	
	
	public inline function bindTexture (target:Int, texture:GLTexture):Void {
		
		__context.bindTexture (target, texture);
		
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
	
	
	//public function bufferData (target:Int, srcData:ArrayBufferView, usage:Int):Void {
	//public function bufferData (target:Int, srcData:ArrayBuffer, usage:Int):Void {
	//public function bufferData (target:Int, size:Int, usage:Int):Void {
	//public function bufferData (target:Int, srcData:ArrayBufferView, usage:Int, srcOffset:Int = 0, length:Int = 0):Void {
	public function bufferData (target:Int, size:Dynamic, srcData:Dynamic, ?usage:Int, ?srcOffset:Int, ?length:Int):Void {
		
		if (!Std.is (srcData, Int)) {
			
			srcData = __prepareData (size, srcData);
			if (srcData == null) return;
			
			if (version > 1) {
				
				__context.bufferData (target, srcData, usage, srcOffset, length);
				
			} else {
				
				__context.bufferData (target, srcData, usage);
				
			}
			
		} else {
			
			if (version > 1) {
				
				__context.bufferData (target, size, srcData, usage, srcOffset); // target, srcData, usage, srcOffset, length
				
			} else {
				
				__context.bufferData (target, size, srcData); // target, srcData, usage
				
			}
			
		}
		
	}
	
	
	//public function bufferSubData (target:Int, dstByteOffset:Int, srcData:ArrayBufferView):Void {
	//public function bufferSubData (target:Int, dstByteOffset:Int, srcData:ArrayBuffer):Void {
	//public function bufferSubData (target:Int, dstByteOffset:Int, srcData:ArrayBufferView, srcOffset:Int = 0, length:Int = 0):Void {
	public function bufferSubData (target:Int, dstByteOffset:Int, size:Dynamic, ?srcData:Dynamic, ?srcOffset:Int, ?length:Int):Void {
		
		if (Std.is (size, Int)) {
			
			srcData = __prepareData (size, srcData);
			if (srcData == null) return;
			
			if (version > 1) {
				
				__context.bufferSubData (target, dstByteOffset, srcData, srcOffset, length);
				
			} else {
				
				__context.bufferSubData (target, dstByteOffset, srcData);
				
			}
			
		} else {
			
			if (version > 1) {
				
				__context.bufferSubData (target, dstByteOffset, size, srcData, srcOffset); // target, dstByteOffset, srcData, srcOffset, length
				
			} else {
				
				__context.bufferSubData (target, dstByteOffset, srcData); // target, dstByteOffset, srcData
				
			}
			
		}
		
	}
	
	
	public inline function checkFramebufferStatus (target:Int):Int {
		
		return __context.checkFramebufferStatus (target);
		
	}
	
	
	public inline function clear (mask:Int):Void {
		
		__context.clear (mask);
		
	}
	
	
	public inline function clearColor (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		__context.clearColor (red, green, blue, alpha);
		
	}
	
	
	public inline function clearDepth (depth:Float):Void {
		
		__context.clearDepth (depth);
		
	}
	
	
	public inline function clearStencil (s:Int):Void {
		
		__context.clearStencil (s);
		
	}
	
	
	public inline function colorMask (red:Bool, green:Bool, blue:Bool, alpha:Bool):Void {
		
		__context.colorMask (red, green, blue, alpha);
		
	}
	
	
	public inline function compileShader (shader:GLShader):Void {
		
		__context.compileShader (shader);
		
	}
	
	
	//public function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, srcData:ArrayBufferView):Void {
	//public function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, srcData:ArrayBufferView, srcOffset:Int = 0, srcLengthOverride:Int = 0):Void {
	//public function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, offset:Int):Void {
	public function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, srcData:Dynamic, ?srcOffset:Int, ?srcLengthOverride:Int):Void {
		
		srcData = __prepareData (null, srcData);
		if (srcData == null) return;
		
		if (version > 1) {
			
			__context.compressedTexImage2D (target, level, internalformat, width, height, border, srcData, srcOffset, srcLengthOverride);
			
		} else {
			
			__context.compressedTexImage2D (target, level, internalformat, width, height, border, srcData);
			
		}
		
	}
	
	
	//public function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, srcData:ArrayBufferView):Void {
	//public function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, srcData:ArrayBufferView, srcOffset:Int = 0, srcLengthOverride:Int = 0):Void {
	//public function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, offset::Int):Void {
	public function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, srcData:Dynamic, ?srcOffset:Int, ?srcLengthOverride:Int):Void {
		
		srcData = __prepareData (null, srcData);
		if (srcData == null) return;
		
		if (version > 1) {
			
			__context.compressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, srcData, srcOffset, srcLengthOverride);
			
		} else {
			
			__context.compressedTexSubImage2D (target, level, xoffset, yoffset, width, height, format, srcData);
			
		}
		
	}
	
	
	public inline function copyTexImage2D (target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void {
		
		__context.copyTexImage2D (target, level, internalformat, x, y, width, height, border);
		
	}
	 
	
	public inline function copyTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {
		
		__context.copyTexSubImage2D (target, level, xoffset, yoffset, x, y, width, height);
		
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
	
	
	public inline function createRenderbuffer ():GLRenderbuffer {
		
		return __context.createRenderbuffer ();
		
	}
	
	
	public inline function createShader (type:Int):GLShader {
		
		return __context.createShader (type);
		
	}
	
	
	public inline function createTexture ():GLTexture {
		
		return __context.createTexture ();
		
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
	
	
	public inline function deleteRenderbuffer (renderbuffer:GLRenderbuffer):Void {
		
		__context.deleteRenderbuffer (renderbuffer);
		
	}
	
	
	public inline function deleteShader (shader:GLShader):Void {
		
		__context.deleteShader (shader);
		
	}
	
	
	public inline function deleteTexture (texture:GLTexture):Void {
		
		__context.deleteTexture (texture);
		
	}
	
	
	public inline function depthFunc (func:Int):Void {
		
		__context.depthFunc (func);
		
	}
	
	
	public inline function depthMask (flag:Bool):Void {
		
		__context.depthMask (flag);
		
	}
	
	
	public inline function depthRange (zNear:Float, zFar:Float):Void {
		
		__context.depthRange (zNear, zFar);
		
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
	
	
	public inline function drawElements (mode:Int, count:Int, type:Int, offset:Dynamic /*GLintptr*/):Void {
		
		__context.drawElements (mode, count, type, offset);
		
	}
	
	
	public inline function enable (cap:Int):Void {
		
		__context.enable (cap);
		
	}
	
	
	public inline function enableVertexAttribArray (index:Int):Void {
		
		__context.enableVertexAttribArray (index);
		
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
	
	
	public inline function getAttachedShaders (program:GLProgram):Array<GLShader> {
		
		return __context.getAttachedShaders (program);
		
	}
	
	
	public inline function getAttribLocation (program:GLProgram, name:String):Int {
		
		return __context.getAttribLocation (program, name);
		
	}
	
	
	public inline function getBoolean (pname:Int):Bool {
		
		return __context.getParameter (pname);
		
	}
	
	
	public function getBooleanv (pname:Int):Array<Bool> {
		
		var result = __context.getParameter (pname);
		if (result == null) return null;
		
		return untyped __js__("Array.prototype.slice.call (result)");
		
	}
	
	
	public inline function getBufferParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		return __context.getBufferParameter (target, pname);
		
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
		
		return __context.getParameter (pname);
		
	}
	
	
	public function getFloatv (pname:Int):Array<Float> {
		
		var result:Float32Array = __context.getParameter (pname);
		if (result == null) return null;
		
		return untyped __js__("Array.prototype.slice.call (result)");
		
	}
	
	
	public inline function getFramebufferAttachmentParameter (target:Int, attachment:Int, pname:Int):Int /*Dynamic*/ {
		
		return __context.getFramebufferAttachmentParameter (target, attachment, pname);
		
	}
	
	
	public inline function getInteger (pname:Int):Int {
		
		return __context.getParameter (pname);
		
	}
	
	
	public function getIntegerv (pname:Int):Array<Int> {
		
		var result:Int32Array = __context.getParameter (pname);
		if (result == null) return null;
		
		return untyped __js__("Array.prototype.slice.call (result)");
		
	}
	
	
	public inline function getParameter (pname:Int):Dynamic {
		
		return __context.getParameter (pname);
		
	}
	
	
	public inline function getProgramInfoLog (program:GLProgram):String {
		
		return __context.getProgramInfoLog (program);
		
	}
	
	
	public inline function getProgramParameter (program:GLProgram, pname:Int):Int {
		
		return __context.getProgramParameter (program, pname);
		
	}
	
	
	public inline function getRenderbufferParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		return __context.getRenderbufferParameter (target, pname);
		
	}
	
	
	public inline function getShaderInfoLog (shader:GLShader):String {
		
		return __context.getShaderInfoLog (shader);
		
	}
	
	
	public inline function getShaderParameter (shader:GLShader, pname:Int):Int {
		
		return __context.getShaderParameter (shader, pname);
		
	}
	
	
	public inline function getShaderPrecisionFormat (shadertype:Int, precisiontype:Int):GLShaderPrecisionFormat {
		
		return __context.getShaderPrecisionFormat (shadertype, precisiontype);
		
	}
	
	
	public inline function getShaderSource (shader:GLShader):String {
		
		return __context.getShaderSource (shader);
		
	}
	
	
	public inline function getString (pname:Int):String {
		
		return __context.getParameter (pname);
		
	}
	
	
	public inline function getSupportedExtensions ():Array<String> {
		
		return __context.getSupportedExtensions ();
		
	}
	
	
	public inline function getTexParameter (target:Int, pname:Int):Int /*Dynamic*/ {
		
		return __context.getTexParameter (target, pname);
		
	}
	
	
	public inline function getUniform (program:GLProgram, location:GLUniformLocation):Dynamic {
		
		return __context.getUniform (program, location);
		
	}
	
	
	public inline function getUniformLocation (program:GLProgram, name:String):GLUniformLocation {
		
		return __context.getUniformLocation (program, name);
		
	}
	
	
	public inline function getVertexAttrib (index:Int, pname:Int):Int /*Dynamic*/ {
		
		return __context.getVertexAttrib (index, pname);
		
	}
	
	
	public inline function getVertexAttribOffset (index:Int, pname:Int):Dynamic /*GLintptr*/ {
		
		return __context.getVertexAttribOffset (index, pname);
		
	}
	
	
	public inline function hint (target:Int, mode:Int):Void {
		
		__context.hint (target, mode);
		
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
	
	
	public inline function isRenderbuffer (renderbuffer:GLRenderbuffer):Bool {
		
		return __context.isRenderbuffer (renderbuffer);
		
	}
	
	
	public inline function isShader (shader:GLShader):Bool {
		
		return __context.isShader (shader);
		
	}
	
	
	public inline function isTexture (texture:GLTexture):Bool {
		
		return __context.isTexture (texture);
		
	}
	
	
	public inline function lineWidth (width:Float):Void {
		
		__context.lineWidth (width);
		
	}
	
	
	public inline function linkProgram (program:GLProgram):Void {
		
		__context.linkProgram (program);
		
	}
	
	
	public inline function pixelStorei (pname:Int, param:Int):Void {
		
		__context.pixelStorei (pname, param);
		
	}
	
	
	public inline function polygonOffset (factor:Float, units:Float):Void {
		
		__context.polygonOffset (factor, units);
		
	}
	
	
	//public function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
	//public function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, offset:Int):Void {
	//public function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView, ?dstOffset:Int):Void {
	public function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:Dynamic, ?dstOffset:Int):Void {
		
		pixels = __prepareData (null, pixels);
		if (pixels == null) return;
		if (Std.is (pixels, ArrayBuffer)) pixels = new UInt8Array (pixels);
		
		if (version > 1) {
			
			__context.readPixels (x, y, width, height, format, type, pixels, dstOffset);
			
		} else {
			
			__context.readPixels (x, y, width, height, format, type, pixels);
			
		}
		
	}
	
	
	public inline function renderbufferStorage (target:Int, internalformat:Int, width:Int, height:Int):Void {
		
		__context.renderbufferStorage (target, internalformat, width, height);
		
	}
	
	
	public inline function sampleCoverage (value:Float, invert:Bool):Void {
		
		__context.sampleCoverage (value, invert);
		
	}
	
	
	public inline function scissor (x:Int, y:Int, width:Int, height:Int):Void {
		
		__context.scissor (x, y, width, height);
		
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
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, offset:Int):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:VideoElement):Void {
	//public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, srcData:ArrayBufferView, srcOffset:Int):Void {
	public function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Dynamic, ?format:Int, ?type:Int, ?srcData:Dynamic, ?srcOffset:Int):Void {
		
		if (version > 1) {
			
			if (format == null) {
				
				var format:Int = width;
				var type:Int = height;
				var element:Dynamic = border;
				
				__context.texImage2D (target, level, internalformat, element.width, element.height, 0, format, type, element);
				
			} else {
				
				srcData = __prepareData (null, srcData);
				if (srcData == null) return;
				if (Std.is (srcData, ArrayBuffer)) srcData = new UInt8Array (srcData);
				
				__context.texImage2D (target, level, internalformat, width, height, border, format, type, srcData, srcOffset);
				
			}
			
		} else {
			
			if (format == null) {
				
				__context.texImage2D (target, level, internalformat, width, height, border); // target, level, internalformat, format, type, pixels
				
			} else {
				
				srcData = __prepareData (null, srcData);
				if (srcData == null) return;
				if (Std.is (srcData, ArrayBuffer)) srcData = new UInt8Array (srcData);
				
				__context.texImage2D (target, level, internalformat, width, height, border, format, type, srcData);
				
			}
			
		}
		
	}
	
	
	public inline function texParameterf (target:Int, pname:Int, param:Float):Void {
		
		__context.texParameterf (target, pname, param);
		
	}
	
	
	public inline function texParameteri (target:Int, pname:Int, param:Int):Void {
		
		__context.texParameteri (target, pname, param);
		
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
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, offset:Int):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:VideoElement):Void {
	//public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, srcData:ArrayBufferView, srcOffset:Int):Void {
	public function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Dynamic, ?type:Int, ?srcData:ArrayBufferView, ?srcOffset:Int):Void {
		
		if (version > 1) {
			
			if (type == null) {
				
				__context.texSubImage2D (target, level, xoffset, yoffset, width, height, format); // target, level, xoffset, yoffset, format, type, pixels
				
			} else {
				
				srcData = __prepareData (null, srcData);
				if (srcData == null) return;
				if (Std.is (srcData, ArrayBuffer)) srcData = new UInt8Array (srcData);
				
				__context.texSubImage2D (target, level, xoffset, yoffset, width, height, format, type, srcData, srcOffset);
				
			}
			
		} else {
			
			if (type == null) {
				
				__context.texSubImage2D (target, level, xoffset, yoffset, width, height, format); // target, level, xoffset, yoffset, format, type, pixels
				
			} else {
				
				srcData = __prepareData (null, srcData);
				if (srcData == null) return;
				if (Std.is (srcData, ArrayBuffer)) srcData = new UInt8Array (srcData);
				
				__context.texSubImage2D (target, level, xoffset, yoffset, width, height, format, type, srcData);
				
			}
			
		}
		
	}
	
	
	public inline function uniform1f (location:GLUniformLocation, x:Float):Void {
		
		__context.uniform1f (location, x);
		
	}
	
	
	public inline function uniform1fv (location:GLUniformLocation, x:Float32Array):Void {
		
		__context.uniform1fv (location, x);
		
	}
	
	
	public inline function uniform1i (location:GLUniformLocation, x:Int):Void {
		
		__context.uniform1i (location, x);
		
	}
	
	
	public inline function uniform1iv (location:GLUniformLocation, v:Int32Array):Void {
		
		__context.uniform1iv (location, v);
		
	}
	
	
	public inline function uniform2f (location:GLUniformLocation, x:Float, y:Float):Void {
		
		__context.uniform2f (location, x, y);
		
	}
	
	
	public inline function uniform2fv (location:GLUniformLocation, v:Float32Array):Void {
		
		__context.uniform2fv (location, v);
		
	}
	
	
	public inline function uniform2i (location:GLUniformLocation, x:Int, y:Int):Void {
		
		__context.uniform2i (location, x, y);
		
	}
	
	
	public inline function uniform2iv (location:GLUniformLocation, v:Int32Array):Void {
		
		__context.uniform2iv (location, v);
		
	}
	
	
	public inline function uniform3f (location:GLUniformLocation, x:Float, y:Float, z:Float):Void {
		
		__context.uniform3f (location, x, y, z);
		
	}
	
	
	public inline function uniform3fv (location:GLUniformLocation, v:Float32Array):Void {
		
		__context.uniform3fv (location, v);
		
	}
	
	
	public inline function uniform3i (location:GLUniformLocation, x:Int, y:Int, z:Int):Void {
		
		__context.uniform3i (location, x, y, z);
		
	}
	
	
	public inline function uniform3iv (location:GLUniformLocation, v:Int32Array):Void {
		
		__context.uniform3iv (location, v);
		
	}
	
	
	public inline function uniform4f (location:GLUniformLocation, x:Float, y:Float, z:Float, w:Float):Void {
		
		__context.uniform4f (location, x, y, z, w);
		
	}
	
	
	public inline function uniform4fv (location:GLUniformLocation, v:Float32Array):Void {
		
		__context.uniform4fv (location, v);
		
	}
	
	
	public inline function uniform4i (location:GLUniformLocation, x:Int, y:Int, z:Int, w:Int):Void {
		
		__context.uniform4i (location, x, y, z, w);
		
	}
	
	
	public inline function uniform4iv (location:GLUniformLocation, v:Int32Array):Void {
		
		__context.uniform4iv (location, v);
		
	}
	
	
	public inline function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		__context.uniformMatrix2fv (location, transpose, v);
		
	}
	
	
	public inline function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		__context.uniformMatrix3fv (location, transpose, v);
		
	}
	
	
	public inline function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		__context.uniformMatrix4fv (location, transpose, v);
		
	}
	
	
	public inline function useProgram (program:GLProgram):Void {
		
		__context.useProgram (program);
		
	}
	
	
	public inline function validateProgram (program:GLProgram):Void {
		
		__context.validateProgram (program);
		
	}
	
	
	public inline function vertexAttrib1f (indx:Int, x:Float):Void {
		
		__context.vertexAttrib1f (indx, x);
		
	}
	
	
	public inline function vertexAttrib1fv (indx:Int, values:Float32Array):Void {
		
		__context.vertexAttrib1fv (indx, values);
		
	}
	
	
	public inline function vertexAttrib2f (indx:Int, x:Float, y:Float):Void {
		
		__context.vertexAttrib2f (indx, x, y);
		
	}
	
	
	public inline function vertexAttrib2fv (indx:Int, values:Float32Array):Void {
		
		__context.vertexAttrib2fv (indx, values);
		
	}
	
	
	public inline function vertexAttrib3f (indx:Int, x:Float, y:Float, z:Float):Void {
		
		__context.vertexAttrib3f (indx, x, y, z);
		
	}
	
	
	public inline function vertexAttrib3fv (indx:Int, values:Float32Array):Void {
		
		__context.vertexAttrib3fv (indx, values);
		
	}
	
	
	public inline function vertexAttrib4f (indx:Int, x:Float, y:Float, z:Float, w:Float):Void {
		
		__context.vertexAttrib4f (indx, x, y, z, w);
		
	}
	
	
	public inline function vertexAttrib4fv (indx:Int, values:Float32Array):Void {
		
		__context.vertexAttrib4fv (indx, values);
		
	}
	
	
	public inline function vertexAttribPointer (indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int):Void {
		
		__context.vertexAttribPointer (indx, size, type, normalized, stride, offset);
		
	}
	
	
	public inline function viewport (x:Int, y:Int, width:Int, height:Int):Void {
		
		__context.viewport (x, y, width, height);
		
	}
	
	
	private function __isArrayBufferView (object:Dynamic):Bool {
		
		return untyped __js__ ("object && object.buffer instanceof ArrayBuffer && object.byteLength !== undefined");
		
	}
	
	
	private function __prepareData (size:Null<Int>, data:Dynamic):Dynamic {
		
		if (data != null) {
			
			if (size != null) {
				
				if (size <= 0) {
					
					return null;
					
				} else if (__isArrayBufferView (data)) {
					
					var arrayBufferView:ArrayBufferView = data;
					return new UInt8Array (arrayBufferView.buffer, arrayBufferView.byteOffset, size);
					
				} else if (Std.is (data, ArrayBuffer)) {
					
					var arrayBuffer:ArrayBuffer = data;
					return new UInt8Array (arrayBuffer, 0, size);
					
				} else if (Std.is (data, BytePointerData)) {
					
					var bytePointer:BytePointer = data;
					return new UInt8Array (bytePointer.bytes.getData (), bytePointer.offset, size);
					
				} else if (Std.is (data, Bytes)) {
					
					var bytes:Bytes = data;
					return new UInt8Array (bytes.getData (), 0, size);
					
				}
				
			} else {
				
				if (Std.is (data, BytePointerData)) {
					
					var bytePointer:BytePointer = data;
					
					if (bytePointer.offset != 0) {
						
						return new UInt8Array (bytePointer.bytes.getData (), bytePointer.offset);
						
					} else {
						
						return bytePointer.bytes.getData ();
						
					}
					
				} else if (Std.is (data, Bytes)) {
					
					var bytes:Bytes = data;
					return bytes.getData ();
					
				}
				
			}
			
		}
		
		return data;
		
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
	
	
	@:overload(function (target:Int, data:js.html.ArrayBufferView, usage:Int, srcOffset:Int, ?length:Int):Void {})
	@:overload(function (target:Int, size:Int, usage:Int):Void {})
	@:overload(function (target:Int, data:js.html.ArrayBufferView, usage:Int):Void {})
	@:overload(function (target:Int, data:js.html.ArrayBuffer, usage:Int):Void {})
	override function bufferData (target:Int, data:Dynamic /*MISSING SharedArrayBuffer*/, usage:Int):Void;
	
	@:overload(function (target:Int, dstByteOffset:Int, srcData:js.html.ArrayBufferView, srcOffset:Int, ?length:Int):Void {})
	@:overload(function (target:Int, offset:Int, data:js.html.ArrayBufferView):Void {})
	@:overload(function (target:Int, offset:Int, data:js.html.ArrayBuffer):Void {})
	override function bufferSubData (target:Int, offset:Int, data:Dynamic /*MISSING SharedArrayBuffer*/):Void;
	
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, offset:Int):Void {})
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, srcData:js.html.ArrayBufferView, ?srcOffset:Int, ?srcLengthOverride:Int):Void {})
	override function compressedTexImage2D( target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, data:js.html.ArrayBufferView):Void;
	
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, offset:Int):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, srcData:js.html.ArrayBufferView, ?srcOffset:Int, ?srcLengthOverride:Int):Void {})
	override function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, data:js.html.ArrayBufferView):Void;
	
	@:overload(function (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:js.html.ArrayBufferView):Void {})
	@:overload(function (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, offset:Int):Void {})
	@:overload(function (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:js.html.ArrayBufferView, dstOffset:Int):Void {})
	override function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:js.html.ArrayBufferView):Void;
	
	@:overload(function (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, offset:Int):Void {})
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
	
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, srcData:js.html.ArrayBufferView, srcOffset:Int):Void {})
	@:overload(function (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, offset:Int):Void {})
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
	
	
}