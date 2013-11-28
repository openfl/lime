package lime.gl.html5;

// import flash.display.BitmapData;
import lime.geometry.Matrix3D;
import lime.utils.ByteArray;
// import lime.Lib;
import js.html.webgl.RenderingContext;
import lime.utils.ArrayBuffer;
import lime.utils.ArrayBufferView;
import lime.utils.Int32Array;
import lime.utils.Float32Array;

class GL {
	
	
	/* ClearBufferMask */
	public static inline var DEPTH_BUFFER_BIT               = 0x00000100;
	public static inline var STENCIL_BUFFER_BIT             = 0x00000400;
	public static inline var COLOR_BUFFER_BIT               = 0x00004000;

	/* BeginMode */
	public static inline var POINTS                         = 0x0000;
	public static inline var LINES                          = 0x0001;
	public static inline var LINE_LOOP                      = 0x0002;
	public static inline var LINE_STRIP                     = 0x0003;
	public static inline var TRIANGLES                      = 0x0004;
	public static inline var TRIANGLE_STRIP                 = 0x0005;
	public static inline var TRIANGLE_FAN                   = 0x0006;

	/* AlphaFunction(not supported in ES20) */
	/*      NEVER */
	/*      LESS */
	/*      EQUAL */
	/*      LEQUAL */
	/*      GREATER */
	/*      NOTEQUAL */
	/*      GEQUAL */
	/*      ALWAYS */

	/* BlendingFactorDest */
	public static inline var ZERO                           = 0;
	public static inline var ONE                            = 1;
	public static inline var SRC_COLOR                      = 0x0300;
	public static inline var ONE_MINUS_SRC_COLOR            = 0x0301;
	public static inline var SRC_ALPHA                      = 0x0302;
	public static inline var ONE_MINUS_SRC_ALPHA            = 0x0303;
	public static inline var DST_ALPHA                      = 0x0304;
	public static inline var ONE_MINUS_DST_ALPHA            = 0x0305;

	/* BlendingFactorSrc */
	/*      ZERO */
	/*      ONE */
	public static inline var DST_COLOR                      = 0x0306;
	public static inline var ONE_MINUS_DST_COLOR            = 0x0307;
	public static inline var SRC_ALPHA_SATURATE             = 0x0308;
	/*      SRC_ALPHA */
	/*      ONE_MINUS_SRC_ALPHA */
	/*      DST_ALPHA */
	/*      ONE_MINUS_DST_ALPHA */

	/* BlendEquationSeparate */
	public static inline var FUNC_ADD                       = 0x8006;
	public static inline var BLEND_EQUATION                 = 0x8009;
	public static inline var BLEND_EQUATION_RGB             = 0x8009;   /* same as BLEND_EQUATION */
	public static inline var BLEND_EQUATION_ALPHA           = 0x883D;

	/* BlendSubtract */
	public static inline var FUNC_SUBTRACT                  = 0x800A;
	public static inline var FUNC_REVERSE_SUBTRACT          = 0x800B;

	/* Separate Blend Functions */
	public static inline var BLEND_DST_RGB                  = 0x80C8;
	public static inline var BLEND_SRC_RGB                  = 0x80C9;
	public static inline var BLEND_DST_ALPHA                = 0x80CA;
	public static inline var BLEND_SRC_ALPHA                = 0x80CB;
	public static inline var CONSTANT_COLOR                 = 0x8001;
	public static inline var ONE_MINUS_CONSTANT_COLOR       = 0x8002;
	public static inline var CONSTANT_ALPHA                 = 0x8003;
	public static inline var ONE_MINUS_CONSTANT_ALPHA       = 0x8004;
	public static inline var BLEND_COLOR                    = 0x8005;

	/* GLBuffer Objects */
	public static inline var ARRAY_BUFFER                   = 0x8892;
	public static inline var ELEMENT_ARRAY_BUFFER           = 0x8893;
	public static inline var ARRAY_BUFFER_BINDING           = 0x8894;
	public static inline var ELEMENT_ARRAY_BUFFER_BINDING   = 0x8895;

	public static inline var STREAM_DRAW                    = 0x88E0;
	public static inline var STATIC_DRAW                    = 0x88E4;
	public static inline var DYNAMIC_DRAW                   = 0x88E8;

	public static inline var BUFFER_SIZE                    = 0x8764;
	public static inline var BUFFER_USAGE                   = 0x8765;

	public static inline var CURRENT_VERTEX_ATTRIB          = 0x8626;

	/* CullFaceMode */
	public static inline var FRONT                          = 0x0404;
	public static inline var BACK                           = 0x0405;
	public static inline var FRONT_AND_BACK                 = 0x0408;

	/* DepthFunction */
	/*      NEVER */
	/*      LESS */
	/*      EQUAL */
	/*      LEQUAL */
	/*      GREATER */
	/*      NOTEQUAL */
	/*      GEQUAL */
	/*      ALWAYS */

	/* EnableCap */
	/* TEXTURE_2D */
	public static inline var CULL_FACE                      = 0x0B44;
	public static inline var BLEND                          = 0x0BE2;
	public static inline var DITHER                         = 0x0BD0;
	public static inline var STENCIL_TEST                   = 0x0B90;
	public static inline var DEPTH_TEST                     = 0x0B71;
	public static inline var SCISSOR_TEST                   = 0x0C11;
	public static inline var POLYGON_OFFSET_FILL            = 0x8037;
	public static inline var SAMPLE_ALPHA_TO_COVERAGE       = 0x809E;
	public static inline var SAMPLE_COVERAGE                = 0x80A0;

	/* ErrorCode */
	public static inline var NO_ERROR                       = 0;
	public static inline var INVALID_ENUM                   = 0x0500;
	public static inline var INVALID_VALUE                  = 0x0501;
	public static inline var INVALID_OPERATION              = 0x0502;
	public static inline var OUT_OF_MEMORY                  = 0x0505;

	/* FrontFaceDirection */
	public static inline var CW                             = 0x0900;
	public static inline var CCW                            = 0x0901;

	/* GetPName */
	public static inline var LINE_WIDTH                     = 0x0B21;
	public static inline var ALIASED_POINT_SIZE_RANGE       = 0x846D;
	public static inline var ALIASED_LINE_WIDTH_RANGE       = 0x846E;
	public static inline var CULL_FACE_MODE                 = 0x0B45;
	public static inline var FRONT_FACE                     = 0x0B46;
	public static inline var DEPTH_RANGE                    = 0x0B70;
	public static inline var DEPTH_WRITEMASK                = 0x0B72;
	public static inline var DEPTH_CLEAR_VALUE              = 0x0B73;
	public static inline var DEPTH_FUNC                     = 0x0B74;
	public static inline var STENCIL_CLEAR_VALUE            = 0x0B91;
	public static inline var STENCIL_FUNC                   = 0x0B92;
	public static inline var STENCIL_FAIL                   = 0x0B94;
	public static inline var STENCIL_PASS_DEPTH_FAIL        = 0x0B95;
	public static inline var STENCIL_PASS_DEPTH_PASS        = 0x0B96;
	public static inline var STENCIL_REF                    = 0x0B97;
	public static inline var STENCIL_VALUE_MASK             = 0x0B93;
	public static inline var STENCIL_WRITEMASK              = 0x0B98;
	public static inline var STENCIL_BACK_FUNC              = 0x8800;
	public static inline var STENCIL_BACK_FAIL              = 0x8801;
	public static inline var STENCIL_BACK_PASS_DEPTH_FAIL   = 0x8802;
	public static inline var STENCIL_BACK_PASS_DEPTH_PASS   = 0x8803;
	public static inline var STENCIL_BACK_REF               = 0x8CA3;
	public static inline var STENCIL_BACK_VALUE_MASK        = 0x8CA4;
	public static inline var STENCIL_BACK_WRITEMASK         = 0x8CA5;
	public static inline var VIEWPORT                       = 0x0BA2;
	public static inline var SCISSOR_BOX                    = 0x0C10;
	/*      SCISSOR_TEST */
	public static inline var COLOR_CLEAR_VALUE              = 0x0C22;
	public static inline var COLOR_WRITEMASK                = 0x0C23;
	public static inline var UNPACK_ALIGNMENT               = 0x0CF5;
	public static inline var PACK_ALIGNMENT                 = 0x0D05;
	public static inline var MAX_TEXTURE_SIZE               = 0x0D33;
	public static inline var MAX_VIEWPORT_DIMS              = 0x0D3A;
	public static inline var SUBPIXEL_BITS                  = 0x0D50;
	public static inline var RED_BITS                       = 0x0D52;
	public static inline var GREEN_BITS                     = 0x0D53;
	public static inline var BLUE_BITS                      = 0x0D54;
	public static inline var ALPHA_BITS                     = 0x0D55;
	public static inline var DEPTH_BITS                     = 0x0D56;
	public static inline var STENCIL_BITS                   = 0x0D57;
	public static inline var POLYGON_OFFSET_UNITS           = 0x2A00;
	/*      POLYGON_OFFSET_FILL */
	public static inline var POLYGON_OFFSET_FACTOR          = 0x8038;
	public static inline var TEXTURE_BINDING_2D             = 0x8069;
	public static inline var SAMPLE_BUFFERS                 = 0x80A8;
	public static inline var SAMPLES                        = 0x80A9;
	public static inline var SAMPLE_COVERAGE_VALUE          = 0x80AA;
	public static inline var SAMPLE_COVERAGE_INVERT         = 0x80AB;

	/* GetTextureParameter */
	/*      TEXTURE_MAG_FILTER */
	/*      TEXTURE_MIN_FILTER */
	/*      TEXTURE_WRAP_S */
	/*      TEXTURE_WRAP_T */

	public static inline var COMPRESSED_TEXTURE_FORMATS     = 0x86A3;

	/* HintMode */
	public static inline var DONT_CARE                      = 0x1100;
	public static inline var FASTEST                        = 0x1101;
	public static inline var NICEST                         = 0x1102;

	/* HintTarget */
	public static inline var GENERATE_MIPMAP_HINT            = 0x8192;

	/* DataType */
	public static inline var BYTE                           = 0x1400;
	public static inline var UNSIGNED_BYTE                  = 0x1401;
	public static inline var SHORT                          = 0x1402;
	public static inline var UNSIGNED_SHORT                 = 0x1403;
	public static inline var INT                            = 0x1404;
	public static inline var UNSIGNED_INT                   = 0x1405;
	public static inline var FLOAT                          = 0x1406;

	/* PixelFormat */
	public static inline var DEPTH_COMPONENT                = 0x1902;
	public static inline var ALPHA                          = 0x1906;
	public static inline var RGB                            = 0x1907;
	public static inline var RGBA                           = 0x1908;
	public static inline var LUMINANCE                      = 0x1909;
	public static inline var LUMINANCE_ALPHA                = 0x190A;

	/* PixelType */
	/*      UNSIGNED_BYTE */
	public static inline var UNSIGNED_SHORT_4_4_4_4         = 0x8033;
	public static inline var UNSIGNED_SHORT_5_5_5_1         = 0x8034;
	public static inline var UNSIGNED_SHORT_5_6_5           = 0x8363;

	/* Shaders */
	public static inline var FRAGMENT_SHADER                  = 0x8B30;
	public static inline var VERTEX_SHADER                    = 0x8B31;
	public static inline var MAX_VERTEX_ATTRIBS               = 0x8869;
	public static inline var MAX_VERTEX_UNIFORM_VECTORS       = 0x8DFB;
	public static inline var MAX_VARYING_VECTORS              = 0x8DFC;
	public static inline var MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;
	public static inline var MAX_VERTEX_TEXTURE_IMAGE_UNITS   = 0x8B4C;
	public static inline var MAX_TEXTURE_IMAGE_UNITS          = 0x8872;
	public static inline var MAX_FRAGMENT_UNIFORM_VECTORS     = 0x8DFD;
	public static inline var SHADER_TYPE                      = 0x8B4F;
	public static inline var DELETE_STATUS                    = 0x8B80;
	public static inline var LINK_STATUS                      = 0x8B82;
	public static inline var VALIDATE_STATUS                  = 0x8B83;
	public static inline var ATTACHED_SHADERS                 = 0x8B85;
	public static inline var ACTIVE_UNIFORMS                  = 0x8B86;
	public static inline var ACTIVE_ATTRIBUTES                = 0x8B89;
	public static inline var SHADING_LANGUAGE_VERSION         = 0x8B8C;
	public static inline var CURRENT_PROGRAM                  = 0x8B8D;

	/* StencilFunction */
	public static inline var NEVER                          = 0x0200;
	public static inline var LESS                           = 0x0201;
	public static inline var EQUAL                          = 0x0202;
	public static inline var LEQUAL                         = 0x0203;
	public static inline var GREATER                        = 0x0204;
	public static inline var NOTEQUAL                       = 0x0205;
	public static inline var GEQUAL                         = 0x0206;
	public static inline var ALWAYS                         = 0x0207;

	/* StencilOp */
	/*      ZERO */
	public static inline var KEEP                           = 0x1E00;
	public static inline var REPLACE                        = 0x1E01;
	public static inline var INCR                           = 0x1E02;
	public static inline var DECR                           = 0x1E03;
	public static inline var INVERT                         = 0x150A;
	public static inline var INCR_WRAP                      = 0x8507;
	public static inline var DECR_WRAP                      = 0x8508;

	/* StringName */
	public static inline var VENDOR                         = 0x1F00;
	public static inline var RENDERER                       = 0x1F01;
	public static inline var VERSION                        = 0x1F02;

	/* TextureMagFilter */
	public static inline var NEAREST                        = 0x2600;
	public static inline var LINEAR                         = 0x2601;

	/* TextureMinFilter */
	/*      NEAREST */
	/*      LINEAR */
	public static inline var NEAREST_MIPMAP_NEAREST         = 0x2700;
	public static inline var LINEAR_MIPMAP_NEAREST          = 0x2701;
	public static inline var NEAREST_MIPMAP_LINEAR          = 0x2702;
	public static inline var LINEAR_MIPMAP_LINEAR           = 0x2703;

	/* TextureParameterName */
	public static inline var TEXTURE_MAG_FILTER             = 0x2800;
	public static inline var TEXTURE_MIN_FILTER             = 0x2801;
	public static inline var TEXTURE_WRAP_S                 = 0x2802;
	public static inline var TEXTURE_WRAP_T                 = 0x2803;

	/* TextureTarget */
	public static inline var TEXTURE_2D                     = 0x0DE1;
	public static inline var TEXTURE                        = 0x1702;

	public static inline var TEXTURE_CUBE_MAP               = 0x8513;
	public static inline var TEXTURE_BINDING_CUBE_MAP       = 0x8514;
	public static inline var TEXTURE_CUBE_MAP_POSITIVE_X    = 0x8515;
	public static inline var TEXTURE_CUBE_MAP_NEGATIVE_X    = 0x8516;
	public static inline var TEXTURE_CUBE_MAP_POSITIVE_Y    = 0x8517;
	public static inline var TEXTURE_CUBE_MAP_NEGATIVE_Y    = 0x8518;
	public static inline var TEXTURE_CUBE_MAP_POSITIVE_Z    = 0x8519;
	public static inline var TEXTURE_CUBE_MAP_NEGATIVE_Z    = 0x851A;
	public static inline var MAX_CUBE_MAP_TEXTURE_SIZE      = 0x851C;

	/* TextureUnit */
	public static inline var TEXTURE0                       = 0x84C0;
	public static inline var TEXTURE1                       = 0x84C1;
	public static inline var TEXTURE2                       = 0x84C2;
	public static inline var TEXTURE3                       = 0x84C3;
	public static inline var TEXTURE4                       = 0x84C4;
	public static inline var TEXTURE5                       = 0x84C5;
	public static inline var TEXTURE6                       = 0x84C6;
	public static inline var TEXTURE7                       = 0x84C7;
	public static inline var TEXTURE8                       = 0x84C8;
	public static inline var TEXTURE9                       = 0x84C9;
	public static inline var TEXTURE10                      = 0x84CA;
	public static inline var TEXTURE11                      = 0x84CB;
	public static inline var TEXTURE12                      = 0x84CC;
	public static inline var TEXTURE13                      = 0x84CD;
	public static inline var TEXTURE14                      = 0x84CE;
	public static inline var TEXTURE15                      = 0x84CF;
	public static inline var TEXTURE16                      = 0x84D0;
	public static inline var TEXTURE17                      = 0x84D1;
	public static inline var TEXTURE18                      = 0x84D2;
	public static inline var TEXTURE19                      = 0x84D3;
	public static inline var TEXTURE20                      = 0x84D4;
	public static inline var TEXTURE21                      = 0x84D5;
	public static inline var TEXTURE22                      = 0x84D6;
	public static inline var TEXTURE23                      = 0x84D7;
	public static inline var TEXTURE24                      = 0x84D8;
	public static inline var TEXTURE25                      = 0x84D9;
	public static inline var TEXTURE26                      = 0x84DA;
	public static inline var TEXTURE27                      = 0x84DB;
	public static inline var TEXTURE28                      = 0x84DC;
	public static inline var TEXTURE29                      = 0x84DD;
	public static inline var TEXTURE30                      = 0x84DE;
	public static inline var TEXTURE31                      = 0x84DF;
	public static inline var ACTIVE_TEXTURE                 = 0x84E0;

	/* TextureWrapMode */
	public static inline var REPEAT                         = 0x2901;
	public static inline var CLAMP_TO_EDGE                  = 0x812F;
	public static inline var MIRRORED_REPEAT                = 0x8370;

	/* Uniform Types */
	public static inline var FLOAT_VEC2                     = 0x8B50;
	public static inline var FLOAT_VEC3                     = 0x8B51;
	public static inline var FLOAT_VEC4                     = 0x8B52;
	public static inline var INT_VEC2                       = 0x8B53;
	public static inline var INT_VEC3                       = 0x8B54;
	public static inline var INT_VEC4                       = 0x8B55;
	public static inline var BOOL                           = 0x8B56;
	public static inline var BOOL_VEC2                      = 0x8B57;
	public static inline var BOOL_VEC3                      = 0x8B58;
	public static inline var BOOL_VEC4                      = 0x8B59;
	public static inline var FLOAT_MAT2                     = 0x8B5A;
	public static inline var FLOAT_MAT3                     = 0x8B5B;
	public static inline var FLOAT_MAT4                     = 0x8B5C;
	public static inline var SAMPLER_2D                     = 0x8B5E;
	public static inline var SAMPLER_CUBE                   = 0x8B60;

	/* Vertex Arrays */
	public static inline var VERTEX_ATTRIB_ARRAY_ENABLED        = 0x8622;
	public static inline var VERTEX_ATTRIB_ARRAY_SIZE           = 0x8623;
	public static inline var VERTEX_ATTRIB_ARRAY_STRIDE         = 0x8624;
	public static inline var VERTEX_ATTRIB_ARRAY_TYPE           = 0x8625;
	public static inline var VERTEX_ATTRIB_ARRAY_NORMALIZED     = 0x886A;
	public static inline var VERTEX_ATTRIB_ARRAY_POINTER        = 0x8645;
	public static inline var VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;
	
	/* Point Size */
	public static inline var VERTEX_PROGRAM_POINT_SIZE       = 0x8642;
	public static inline var POINT_SPRITE                    = 0x8861;
	
	/* GLShader Source */
	public static inline var COMPILE_STATUS                 = 0x8B81;

	/* GLShader Precision-Specified Types */
	public static inline var LOW_FLOAT                      = 0x8DF0;
	public static inline var MEDIUM_FLOAT                   = 0x8DF1;
	public static inline var HIGH_FLOAT                     = 0x8DF2;
	public static inline var LOW_INT                        = 0x8DF3;
	public static inline var MEDIUM_INT                     = 0x8DF4;
	public static inline var HIGH_INT                       = 0x8DF5;

	/* GLFramebuffer Object. */
	public static inline var FRAMEBUFFER                    = 0x8D40;
	public static inline var RENDERBUFFER                   = 0x8D41;

	public static inline var RGBA4                          = 0x8056;
	public static inline var RGB5_A1                        = 0x8057;
	public static inline var RGB565                         = 0x8D62;
	public static inline var DEPTH_COMPONENT16              = 0x81A5;
	public static inline var STENCIL_INDEX                  = 0x1901;
	public static inline var STENCIL_INDEX8                 = 0x8D48;
	public static inline var DEPTH_STENCIL                  = 0x84F9;

	public static inline var RENDERBUFFER_WIDTH             = 0x8D42;
	public static inline var RENDERBUFFER_HEIGHT            = 0x8D43;
	public static inline var RENDERBUFFER_INTERNAL_FORMAT   = 0x8D44;
	public static inline var RENDERBUFFER_RED_SIZE          = 0x8D50;
	public static inline var RENDERBUFFER_GREEN_SIZE        = 0x8D51;
	public static inline var RENDERBUFFER_BLUE_SIZE         = 0x8D52;
	public static inline var RENDERBUFFER_ALPHA_SIZE        = 0x8D53;
	public static inline var RENDERBUFFER_DEPTH_SIZE        = 0x8D54;
	public static inline var RENDERBUFFER_STENCIL_SIZE      = 0x8D55;

	public static inline var FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE           = 0x8CD0;
	public static inline var FRAMEBUFFER_ATTACHMENT_OBJECT_NAME           = 0x8CD1;
	public static inline var FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL         = 0x8CD2;
	public static inline var FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

	public static inline var COLOR_ATTACHMENT0              = 0x8CE0;
	public static inline var DEPTH_ATTACHMENT               = 0x8D00;
	public static inline var STENCIL_ATTACHMENT             = 0x8D20;
	public static inline var DEPTH_STENCIL_ATTACHMENT       = 0x821A;

	public static inline var NONE                           = 0;

	public static inline var FRAMEBUFFER_COMPLETE                      = 0x8CD5;
	public static inline var FRAMEBUFFER_INCOMPLETE_ATTACHMENT         = 0x8CD6;
	public static inline var FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;
	public static inline var FRAMEBUFFER_INCOMPLETE_DIMENSIONS         = 0x8CD9;
	public static inline var FRAMEBUFFER_UNSUPPORTED                   = 0x8CDD;

	public static inline var FRAMEBUFFER_BINDING            = 0x8CA6;
	public static inline var RENDERBUFFER_BINDING           = 0x8CA7;
	public static inline var MAX_RENDERBUFFER_SIZE          = 0x84E8;

	public static inline var INVALID_FRAMEBUFFER_OPERATION  = 0x0506;

	/* WebGL-specific enums */
	public static inline var UNPACK_FLIP_Y_WEBGL            = 0x9240;
	public static inline var UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;
	public static inline var CONTEXT_LOST_WEBGL             = 0x9242;
	public static inline var UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;
	public static inline var BROWSER_DEFAULT_WEBGL          = 0x9244;
	
	
	public static var drawingBufferHeight(get_drawingBufferHeight, null):Int;
	public static var drawingBufferWidth(get_drawingBufferWidth, null):Int;
	public static var version(get_version, null):Int;
	
	public static var limeContext:RenderingContext;
	
	
	
	public static function activeTexture(texture:Int):Void {
		
		limeContext.activeTexture(texture);
		
	}
	
	
	public static function attachShader(program:GLProgram, shader:GLShader):Void {
		
		limeContext.attachShader(program, shader);
		
	}
	
	
	public static function bindAttribLocation(program:GLProgram, index:Int, name:String):Void {
		
		limeContext.bindAttribLocation(program, index, name);
		
	}
	
/*
	public static function bindBitmapDataTexture(texture:BitmapData):Void {
		
		if (texture.limeGLTexture == null) {
			
			texture.limeGLTexture = limeContext.createTexture();
			limeContext.bindTexture(TEXTURE_2D, texture.limeGLTexture);
			
			limeContext.texParameteri(TEXTURE_2D, TEXTURE_WRAP_S, CLAMP_TO_EDGE);
			limeContext.texParameteri(TEXTURE_2D, TEXTURE_WRAP_T, CLAMP_TO_EDGE);
			limeContext.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST);
			limeContext.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST);
			
			texture.lock();
			limeContext.texImage2D(TEXTURE_2D, 0, RGBA, RGBA, UNSIGNED_BYTE, texture.limeImageData);
			texture.unlock();
			
		} else {
			
			limeContext.bindTexture(TEXTURE_2D, texture.limeGLTexture);
			
		}
		
	}
*/
	
	public static function bindBuffer(target:Int, buffer:GLBuffer):Void {
		
		limeContext.bindBuffer(target, buffer);
		
	}
	
	
	public static function bindFramebuffer(target:Int, framebuffer:GLFramebuffer):Void {
		
		limeContext.bindFramebuffer(target, framebuffer);
		
	}
	
	
	public static function bindRenderbuffer(target:Int, renderbuffer:GLRenderbuffer):Void {
		
		limeContext.bindRenderbuffer(target, renderbuffer);
		
	}
	
	
	public static function bindTexture(target:Int, texture:GLTexture):Void {
		
		limeContext.bindTexture(target, texture);
		
	}
	
	
	public static function blendColor(red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		limeContext.blendColor(red, green, blue, alpha);
		
	}
	
	
	public static function blendEquation(mode:Int):Void {
		
		limeContext.blendEquation(mode);
		
	}
	
	
	public static function blendEquationSeparate(modeRGB:Int, modeAlpha:Int):Void {
		
		limeContext.blendEquationSeparate(modeRGB, modeAlpha);
		
	}
	
	
	public static function blendFunc(sfactor:Int, dfactor:Int):Void {
		
		limeContext.blendFunc(sfactor, dfactor);
		
	}
	
	
	public static function blendFuncSeparate(srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int):Void {
		
		limeContext.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
		
	}
	
	
	//public static function bufferData(target:Int, data:IMemoryRange, usage:Int):Void {
	public static function bufferData(target:Int, data:ArrayBufferView, usage:Int):Void {
		
		limeContext.bufferData(target, data, usage);
		
	}
	
	
	public static function bufferSubData(target:Int, offset:Int, data:ArrayBufferView):Void {
		
		limeContext.bufferSubData(target, offset, data);
		
	}
	
	
	public static function checkFramebufferStatus(target:Int):Int {
		
		return limeContext.checkFramebufferStatus(target);
		
	}
	
	
	public static function clear(mask:Int):Void {
		
		limeContext.clear(mask);
		
	}
	
	
	public static function clearColor(red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		limeContext.clearColor(red, green, blue, alpha);
		
	}
	
	
	public static function clearDepth(depth:Float):Void {
		
		limeContext.clearDepth(depth);
		
	}
	
	
	public static function clearStencil(s:Int):Void {
		
		limeContext.clearStencil(s);
		
	}
	
	
	public static function colorMask(red:Bool, green:Bool, blue:Bool, alpha:Bool):Void {
		
		limeContext.colorMask(red, green, blue, alpha);
		
	}
	
	
	public static function compileShader(shader:GLShader):Void {
		
		limeContext.compileShader(shader);
		
	}
	
	
	public static function compressedTexImage2D(target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, data:ArrayBufferView):Void {
		
		limeContext.compressedTexImage2D(target, level, internalformat, width, height, border, data);
		
	}
	
	
	public static function compressedTexSubImage2D(target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, data:ArrayBufferView):Void {
		
		limeContext.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data);
		
	}
	
	
	public static function copyTexImage2D(target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void {
		
		limeContext.copyTexImage2D(target, level, internalformat, x, y, width, height, border);
		
	}
	
	
	public static function copyTexSubImage2D(target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {
		
		limeContext.copyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
		
	}
	
	
	public static function createBuffer():GLBuffer {
		
		return limeContext.createBuffer();
		
	}
	
	
	public static function createFramebuffer():GLFramebuffer {
		
		return limeContext.createFramebuffer();
		
	}
	
	
	public static function createProgram():GLProgram {
		
		return limeContext.createProgram();
		
	}
	
	
	public static function createRenderbuffer():GLRenderbuffer {
		
		return limeContext.createRenderbuffer();
		
	}
	
	
	public static function createShader(type:Int):GLShader {
		
		return limeContext.createShader(type);
		
	}
	
	
	public static function createTexture():GLTexture {
		
		return limeContext.createTexture();
		
	}
	
	
	public static function cullFace(mode:Int):Void {
		
		limeContext.cullFace(mode);
		
	}
	
	
	public static function deleteBuffer(buffer:GLBuffer):Void {
		
		limeContext.deleteBuffer(buffer);
		
	}
	
	
	public static function deleteFramebuffer(framebuffer:GLFramebuffer):Void {
		
		limeContext.deleteFramebuffer(framebuffer);
		
	}
	
	
	public static function deleteProgram(program:GLProgram):Void {
		
		limeContext.deleteProgram(program);
		
	}
	
	
	public static function deleteRenderbuffer(renderbuffer:GLRenderbuffer):Void {
		
		limeContext.deleteRenderbuffer(renderbuffer);
		
	}
	
	
	public static function deleteShader(shader:GLShader):Void {
		
		limeContext.deleteShader(shader);
		
	}
	
	
	public static function deleteTexture(texture:GLTexture):Void {
		
		limeContext.deleteTexture(texture);
		
	}
	
	
	public static function depthFunc(func:Int):Void {
		
		limeContext.depthFunc(func);
		
	}
	
	
	public static function depthMask(flag:Bool):Void {
		
		limeContext.depthMask(flag);
		
	}
	
	
	public static function depthRange(zNear:Float, zFar:Float):Void {
		
		limeContext.depthRange(zNear, zFar);
		
	}
	
	
	public static function detachShader(program:GLProgram, shader:GLShader):Void {
		
		limeContext.detachShader(program, shader);
		
	}
	
	
	public static function disable(cap:Int):Void {
		
		limeContext.disable(cap);
		
	}
	
	
	public static function disableVertexAttribArray(index:Int):Void {
		
		limeContext.disableVertexAttribArray(index);
		
	}
	
	
	public static function drawArrays(mode:Int, first:Int, count:Int):Void {
		
		limeContext.drawArrays(mode, first, count);
		
	}
	
	
	public static function drawElements(mode:Int, count:Int, type:Int, offset:Int):Void {
		
		limeContext.drawElements(mode, count, type, offset);
		
	}
	
	
	public static function enable(cap:Int):Void {
		
		limeContext.enable(cap);
		
	}
	
	
	public static function enableVertexAttribArray(index:Int):Void {
		
		limeContext.enableVertexAttribArray(index);
		
	}
	
	
	public static function finish():Void {
		
		limeContext.finish();
		
	}
	
	
	public static function flush():Void {
		
		limeContext.flush();
		
	}
	
	
	public static function framebufferRenderbuffer(target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:GLRenderbuffer):Void {
		
		limeContext.framebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer);
		
	}
	
	
	public static function framebufferTexture2D(target:Int, attachment:Int, textarget:Int, texture:GLTexture, level:Int):Void {
		
		limeContext.framebufferTexture2D(target, attachment, textarget, texture, level);
		
	}
	
	
	public static function frontFace(mode:Int):Void {
		
		limeContext.frontFace(mode);
		
	}
	
	
	public static function generateMipmap(target:Int):Void {
		
		limeContext.generateMipmap(target);
		
	}
	
	
	public static function getActiveAttrib(program:GLProgram, index:Int):GLActiveInfo {
		
		return limeContext.getActiveAttrib(program, index);
		
	}
	
	
	public static function getActiveUniform(program:GLProgram, index:Int):GLActiveInfo {
		
		return limeContext.getActiveUniform(program, index);
		
	}
	
	
	public static function getAttachedShaders(program:GLProgram):Array<GLShader> {
		
		return limeContext.getAttachedShaders(program);
		
	}
	
	
	public static function getAttribLocation(program:GLProgram, name:String):Int {
		
		return limeContext.getAttribLocation(program, name);
		
	}
	
	
	public static function getBufferParameter(target:Int, pname:Int):Dynamic {
		
		return limeContext.getBufferParameter(target, pname);
		
	}
	
	
	public static function getContextAttributes():GLContextAttributes {
		
		return limeContext.getContextAttributes();
		
	}
	
	
	public static function getError():Int {
		
		return limeContext.getError();
		
	}
	
	
	public static function getExtension(name:String):Dynamic {
		
		return limeContext.getExtension(name);
		
	}
	
	
	public static function getFramebufferAttachmentParameter(target:Int, attachment:Int, pname:Int):Dynamic {
		
		return limeContext.getFramebufferAttachmentParameter(target, attachment, pname);
		
	}
	
	
	public static function getParameter(pname:Int):Dynamic {
		
		return limeContext.getParameter(pname);
		
	}
	
	
	public static function getProgramInfoLog(program:GLProgram):String {
		
		return limeContext.getProgramInfoLog(program);
		
	}
	
	
	public static function getProgramParameter(program:GLProgram, pname:Int):Int {
		
		return limeContext.getProgramParameter(program, pname);
		
	}
	
	
	public static function getRenderbufferParameter(target:Int, pname:Int):Dynamic {
		
		return limeContext.getRenderbufferParameter(target, pname);
		
	}
	
	
	public static function getShaderInfoLog(shader:GLShader):String {
		
		return limeContext.getShaderInfoLog(shader);
		
	}
	
	
	public static function getShaderParameter(shader:GLShader, pname:Int):Int {
		
		return limeContext.getShaderParameter(shader, pname);
		
	}
	
	
	public static function getShaderPrecisionFormat(shadertype:Int, precisiontype:Int):ShaderPrecisionFormat {
		
		// TODO
		
		return null;
		//return limeContext.getShader
		
	}
	
	
	public static function getShaderSource(shader:GLShader):String {
		
		return limeContext.getShaderSource(shader);
		
	}
	
	
	public static function getSupportedExtensions():Array<String> {
		
		// TODO
		
		return null;
		//return limeContext.getSuppo
		
	}
	
	
	public static function getTexParameter(target:Int, pname:Int):Dynamic {
		
		return limeContext.getTexParameter(target, pname);
		
	}
	
	
	public static function getUniform(program:GLProgram, location:GLUniformLocation):Dynamic { 
		
		return limeContext.getUniform(program, location);
		
	}
	
	
	public static function getUniformLocation(program:GLProgram, name:String):GLUniformLocation {
		
		return limeContext.getUniformLocation(program, name);
		
	}
	
	
	public static function getVertexAttrib(index:Int, pname:Int):Dynamic {
		
		return limeContext.getVertexAttrib(index, pname);
		
	}
	
	
	public static function getVertexAttribOffset(index:Int, pname:Int):Int {
		
		return limeContext.getVertexAttribOffset(index, pname);
		
	}
	
	
	public static function hint(target:Int, mode:Int):Void {
		
		limeContext.hint(target, mode);
		
	}
	
	
	public static function isBuffer(buffer:GLBuffer):Bool {
		
		return limeContext.isBuffer(buffer);
		
	}
	
	
	// This is non-static
	// public function isContextLost():Bool { return false; }
	
	
	public static function isEnabled(cap:Int):Bool {
		
		return limeContext.isEnabled(cap);
		
	}
	
	
	public static function isFramebuffer(framebuffer:GLFramebuffer):Bool {
		
		return limeContext.isFramebuffer(framebuffer);
		
	}
	
	
	public static function isProgram(program:GLProgram):Bool {
		
		return limeContext.isProgram(program);
		
	}
	
	
	public static function isRenderbuffer(renderbuffer:GLRenderbuffer):Bool {
		
		return limeContext.isRenderbuffer(renderbuffer);
		
	}
	
	
	public static function isShader(shader:GLShader):Bool {
		
		return limeContext.isShader(shader);
		
	}
	
	
	public static function isTexture(texture:GLTexture):Bool {
		
		return limeContext.isTexture(texture);
		
	}
	
	
	public static function lineWidth(width:Float):Void {
		
		limeContext.lineWidth(width);
		
	}
	
	
	public static function linkProgram(program:GLProgram):Void {
		
		limeContext.linkProgram(program);
		
	}
	
	
	public static function pixelStorei(pname:Int, param:Int):Void {
		
		limeContext.pixelStorei(pname, param);
		
	}
	
	
	public static function polygonOffset(factor:Float, units:Float):Void {
		
		limeContext.polygonOffset(factor, units);
		
	}
	
	
	public static function readPixels(x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		// TODO: pixels? May need setting to work (canvas.getContext("experimental-webgl", {preserveDrawingBuffer: true});)
		
		limeContext.readPixels(x, y, width, height, format, type, pixels);
		
	}
	
	
	public static function renderbufferStorage(target:Int, internalformat:Int, width:Int, height:Int):Void {
		
		limeContext.renderbufferStorage(target, internalformat, width, height);
		
	}
	
	
	public static function sampleCoverage(value:Float, invert:Bool):Void {
		
		limeContext.sampleCoverage(value, invert);
		
	}
	
	
	public static function scissor(x:Int, y:Int, width:Int, height:Int):Void {
		
		limeContext.scissor(x, y, width, height);
		
	}
	
	
	public static function shaderSource(shader:GLShader, source:String):Void {
		
		limeContext.shaderSource(shader, source);
		
	}
	
	
	public static function stencilFunc(func:Int, ref:Int, mask:Int):Void {
		
		limeContext.stencilFunc(func, ref, mask);
		
	}
	
	
	public static function stencilFuncSeparate(face:Int, func:Int, ref:Int, mask:Int):Void {
		
		limeContext.stencilFuncSeparate(face, func, ref, mask);
		
	}
	
	
	public static function stencilMask(mask:Int):Void {
		
		limeContext.stencilMask(mask);
		
	}
	
	
	public static function stencilMaskSeparate(face:Int, mask:Int):Void {
		
		limeContext.stencilMaskSeparate(face, mask);
		
	}
	
	
	public static function stencilOp(fail:Int, zfail:Int, zpass:Int):Void {
		
		limeContext.stencilOp(fail, zfail, zpass);
		
	}
	
	
	public static function stencilOpSeparate(face:Int, fail:Int, zfail:Int, zpass:Int):Void {
		
		limeContext.stencilOpSeparate(face, fail, zfail, zpass);
		
	}
	
	
	public static function texImage2D(target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		limeContext.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
		
	}
	
	
	public static function texParameterf(target:Int, pname:Int, param:Float):Void {
		
		limeContext.texParameterf(target, pname, param);
		
	}
	
	
	public static function texParameteri(target:Int, pname:Int, param:Int):Void {
		
		limeContext.texParameteri(target, pname, param);
		
	}
	
	
	public static function texSubImage2D(target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void {
		
		limeContext.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
		
	}
	
	
	public static function uniform1f(location:GLUniformLocation, x:Float):Void {
		
		limeContext.uniform1f(location, x);
		
	}
	
	
	public static function uniform1fv(location:GLUniformLocation, x:Float32Array):Void {
		
		limeContext.uniform1fv(location, x);
		
	}
	
	
	public static function uniform1i(location:GLUniformLocation, x:Int):Void {
		
		limeContext.uniform1i(location, x);
		
	}
	
	
	public static function uniform1iv(location:GLUniformLocation, v:Int32Array):Void {
		
		limeContext.uniform1iv(location, v);
		
	}
	
	
	public static function uniform2f(location:GLUniformLocation, x:Float, y:Float):Void {
		
		limeContext.uniform2f(location, x, y);
		
	}
	
	
	public static function uniform2fv(location:GLUniformLocation, v:Float32Array):Void {
		
		limeContext.uniform2fv(location, v);
		
	}
	
	
	public static function uniform2i(location:GLUniformLocation, x:Int, y:Int):Void {
		
		limeContext.uniform2i(location, x, y);
		
	}
	
	
	public static function uniform2iv(location:GLUniformLocation, v:Int32Array):Void {
		
		limeContext.uniform2iv(location, v);
		
	}
	
	
	public static function uniform3f(location:GLUniformLocation, x:Float, y:Float, z:Float):Void {
		
		limeContext.uniform3f(location, x, y, z);
		
	}
	
	
	public static function uniform3fv(location:GLUniformLocation, v:Float32Array):Void {
		
		limeContext.uniform3fv(location, v);
		
	}
	
	
	public static function uniform3i(location:GLUniformLocation, x:Int, y:Int, z:Int):Void {
		
		limeContext.uniform3i(location, x, y, z);
		
	}
	
	
	public static function uniform3iv(location:GLUniformLocation, v:Int32Array):Void {
		
		limeContext.uniform3iv(location, v);
		
	}
	
	
	public static function uniform4f(location:GLUniformLocation, x:Float, y:Float, z:Float, w:Float):Void {
		
		limeContext.uniform4f(location, x, y, z, w);
		
	}
	
	
	public static function uniform4fv(location:GLUniformLocation, v:Float32Array):Void {
		
		limeContext.uniform4fv(location, v);
		
	}
	
	
	public static function uniform4i(location:GLUniformLocation, x:Int, y:Int, z:Int, w:Int):Void {
		
		limeContext.uniform4i(location, x, y, z, w);
		
	}
	
	
	public static function uniform4iv(location:GLUniformLocation, v:Int32Array):Void {
		
		limeContext.uniform4iv(location, v);
		
	}
	
	
	public static function uniformMatrix2fv(location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		limeContext.uniformMatrix2fv(location, transpose, v);
		
	}
	
	
	public static function uniformMatrix3fv(location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		limeContext.uniformMatrix3fv(location, transpose, v);
		
	}
	
	
	public static function uniformMatrix4fv(location:GLUniformLocation, transpose:Bool, v:Float32Array):Void {
		
		limeContext.uniformMatrix4fv(location, transpose, v);
		
	}
	
	
	public static function uniformMatrix3D(location:GLUniformLocation, transpose:Bool, matrix:Matrix3D):Void {
		
		limeContext.uniformMatrix4fv(location, transpose, new Float32Array(matrix.rawData));
		
	}
	
	
	public static function useProgram(program:GLProgram):Void {
		
		limeContext.useProgram(program);
		
	}
	
	
	public static function validateProgram(program:GLProgram):Void {
		
		limeContext.validateProgram(program);
		
	}
	
	
	public static function vertexAttrib1f(indx:Int, x:Float):Void {
		
		limeContext.vertexAttrib1f(indx, x);
		
	}
	
	
	public static function vertexAttrib1fv(indx:Int, values:Float32Array):Void {
		
		limeContext.vertexAttrib1fv(indx, values);
		
	}
	
	
	public static function vertexAttrib2f(indx:Int, x:Float, y:Float):Void {
		
		limeContext.vertexAttrib2f(indx, x, y);
		
	}
	
	
	public static function vertexAttrib2fv(indx:Int, values:Float32Array):Void {
		
		limeContext.vertexAttrib2fv(indx, values);
		
	}
	
	
	public static function vertexAttrib3f(indx:Int, x:Float, y:Float, z:Float):Void {
		
		limeContext.vertexAttrib3f(indx, x, y, z);
		
	}
	
	
	public static function vertexAttrib3fv(indx:Int, values:Float32Array):Void {
		
		limeContext.vertexAttrib3fv(indx, values);
		
	}
	
	
	public static function vertexAttrib4f(indx:Int, x:Float, y:Float, z:Float, w:Float):Void {
		
		limeContext.vertexAttrib4f(indx, x, y, z, w);
		
	}
	
	
	public static function vertexAttrib4fv(indx:Int, values:Float32Array):Void {
		
		limeContext.vertexAttrib4fv(indx, values);
		
	}
	
	
	public static function vertexAttribPointer(indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int):Void {
		
		limeContext.vertexAttribPointer(indx, size, type, normalized, stride, offset);
		
	}
	
	
	public static function viewport(x:Int, y:Int, width:Int, height:Int):Void {
		
		limeContext.viewport(x, y, width, height);
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private static function get_drawingBufferHeight() { return 640; }
	private static function get_drawingBufferWidth() { return 960; }
	private static function get_version():Int { return RenderingContext.VERSION; }
	
	
   
}


typedef ShaderPrecisionFormat = {
	
   rangeMin : Int,
   rangeMax : Int,
   precision : Int,
   
};

