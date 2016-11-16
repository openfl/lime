package lime.graphics;


#if (sys && !display)
typedef GLRenderContext = lime._backend.native.NativeGLRenderContext;
#else


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

#if (js && html5)
import js.html.CanvasElement;
#end

#if (js && html5)
@:native("WebGLRenderingContext")
#end

extern class GLRenderContext {
	
	
	var ACTIVE_ATTRIBUTES:Int;
	var ACTIVE_TEXTURE:Int;
	var ACTIVE_UNIFORMS:Int;
	var ALIASED_LINE_WIDTH_RANGE:Int;
	var ALIASED_POINT_SIZE_RANGE:Int;
	var ALPHA:Int;
	var ALPHA_BITS:Int;
	var ALWAYS:Int;
	var ARRAY_BUFFER:Int;
	var ARRAY_BUFFER_BINDING:Int;
	var ATTACHED_SHADERS:Int;
	var BACK:Int;
	var BLEND:Int;
	var BLEND_COLOR:Int;
	var BLEND_DST_ALPHA:Int;
	var BLEND_DST_RGB:Int;
	var BLEND_EQUATION:Int;
	var BLEND_EQUATION_ALPHA:Int;
	var BLEND_EQUATION_RGB:Int;
	var BLEND_SRC_ALPHA:Int;
	var BLEND_SRC_RGB:Int;
	var BLUE_BITS:Int;
	var BOOL:Int;
	var BOOL_VEC2:Int;
	var BOOL_VEC3:Int;
	var BOOL_VEC4:Int;
	var BROWSER_DEFAULT_WEBGL:Int;
	var BUFFER_SIZE:Int;
	var BUFFER_USAGE:Int;
	var BYTE:Int;
	var CCW:Int;
	var CLAMP_TO_EDGE:Int;
	var COLOR_ATTACHMENT0:Int;
	var COLOR_BUFFER_BIT:Int;
	var COLOR_CLEAR_VALUE:Int;
	var COLOR_WRITEMASK:Int;
	var COMPILE_STATUS:Int;
	var COMPRESSED_TEXTURE_FORMATS:Int;
	var CONSTANT_ALPHA:Int;
	var CONSTANT_COLOR:Int;
	var CONTEXT_LOST_WEBGL:Int;
	var CULL_FACE:Int;
	var CULL_FACE_MODE:Int;
	var CURRENT_PROGRAM:Int;
	var CURRENT_VERTEX_ATTRIB:Int;
	var CW:Int;
	var DECR:Int;
	var DECR_WRAP:Int;
	var DELETE_STATUS:Int;
	var DEPTH_ATTACHMENT:Int;
	var DEPTH_BITS:Int;
	var DEPTH_BUFFER_BIT:Int;
	var DEPTH_CLEAR_VALUE:Int;
	var DEPTH_COMPONENT:Int;
	var DEPTH_COMPONENT16:Int;
	var DEPTH_FUNC:Int;
	var DEPTH_RANGE:Int;
	var DEPTH_STENCIL:Int;
	var DEPTH_STENCIL_ATTACHMENT:Int;
	var DEPTH_TEST:Int;
	var DEPTH_WRITEMASK:Int;
	var DITHER:Int;
	var DONT_CARE:Int;
	var DST_ALPHA:Int;
	var DST_COLOR:Int;
	var DYNAMIC_DRAW:Int;
	var ELEMENT_ARRAY_BUFFER:Int;
	var ELEMENT_ARRAY_BUFFER_BINDING:Int;
	var EQUAL:Int;
	var FASTEST:Int;
	var FLOAT:Int;
	var FLOAT_MAT2:Int;
	var FLOAT_MAT3:Int;
	var FLOAT_MAT4:Int;
	var FLOAT_VEC2:Int;
	var FLOAT_VEC3:Int;
	var FLOAT_VEC4:Int;
	var FRAGMENT_SHADER:Int;
	var FRAMEBUFFER:Int;
	var FRAMEBUFFER_ATTACHMENT_OBJECT_NAME:Int;
	var FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE:Int;
	var FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE:Int;
	var FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL:Int;
	var FRAMEBUFFER_BINDING:Int;
	var FRAMEBUFFER_COMPLETE:Int;
	var FRAMEBUFFER_INCOMPLETE_ATTACHMENT:Int;
	var FRAMEBUFFER_INCOMPLETE_DIMENSIONS:Int;
	var FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:Int;
	var FRAMEBUFFER_UNSUPPORTED:Int;
	var FRONT:Int;
	var FRONT_AND_BACK:Int;
	var FRONT_FACE:Int;
	var FUNC_ADD:Int;
	var FUNC_REVERSE_SUBTRACT:Int;
	var FUNC_SUBTRACT:Int;
	var GENERATE_MIPMAP_HINT:Int;
	var GEQUAL:Int;
	var GREATER:Int;
	var GREEN_BITS:Int;
	var HIGH_FLOAT:Int;
	var HIGH_INT:Int;
	var INCR:Int;
	var INCR_WRAP:Int;
	var INT:Int;
	var INT_VEC2:Int;
	var INT_VEC3:Int;
	var INT_VEC4:Int;
	var INVALID_ENUM:Int;
	var INVALID_FRAMEBUFFER_OPERATION:Int;
	var INVALID_OPERATION:Int;
	var INVALID_VALUE:Int;
	var INVERT:Int;
	var KEEP:Int;
	var LEQUAL:Int;
	var LESS:Int;
	var LINEAR:Int;
	var LINEAR_MIPMAP_LINEAR:Int;
	var LINEAR_MIPMAP_NEAREST:Int;
	var LINES:Int;
	var LINE_LOOP:Int;
	var LINE_STRIP:Int;
	var LINE_WIDTH:Int;
	var LINK_STATUS:Int;
	var LOW_FLOAT:Int;
	var LOW_INT:Int;
	var LUMINANCE:Int;
	var LUMINANCE_ALPHA:Int;
	var MAX_COMBINED_TEXTURE_IMAGE_UNITS:Int;
	var MAX_CUBE_MAP_TEXTURE_SIZE:Int;
	var MAX_FRAGMENT_UNIFORM_VECTORS:Int;
	var MAX_RENDERBUFFER_SIZE:Int;
	var MAX_TEXTURE_IMAGE_UNITS:Int;
	var MAX_TEXTURE_SIZE:Int;
	var MAX_VARYING_VECTORS:Int;
	var MAX_VERTEX_ATTRIBS:Int;
	var MAX_VERTEX_TEXTURE_IMAGE_UNITS:Int;
	var MAX_VERTEX_UNIFORM_VECTORS:Int;
	var MAX_VIEWPORT_DIMS:Int;
	var MEDIUM_FLOAT:Int;
	var MEDIUM_INT:Int;
	var MIRRORED_REPEAT:Int;
	var NEAREST:Int;
	var NEAREST_MIPMAP_LINEAR:Int;
	var NEAREST_MIPMAP_NEAREST:Int;
	var NEVER:Int;
	var NICEST:Int;
	var NONE:Int;
	var NOTEQUAL:Int;
	var NO_ERROR:Int;
	var ONE:Int;
	var ONE_MINUS_CONSTANT_ALPHA:Int;
	var ONE_MINUS_CONSTANT_COLOR:Int;
	var ONE_MINUS_DST_ALPHA:Int;
	var ONE_MINUS_DST_COLOR:Int;
	var ONE_MINUS_SRC_ALPHA:Int;
	var ONE_MINUS_SRC_COLOR:Int;
	var OUT_OF_MEMORY:Int;
	var PACK_ALIGNMENT:Int;
	var POINTS:Int;
	var POLYGON_OFFSET_FACTOR:Int;
	var POLYGON_OFFSET_FILL:Int;
	var POLYGON_OFFSET_UNITS:Int;
	var RED_BITS:Int;
	var RENDERBUFFER:Int;
	var RENDERBUFFER_ALPHA_SIZE:Int;
	var RENDERBUFFER_BINDING:Int;
	var RENDERBUFFER_BLUE_SIZE:Int;
	var RENDERBUFFER_DEPTH_SIZE:Int;
	var RENDERBUFFER_GREEN_SIZE:Int;
	var RENDERBUFFER_HEIGHT:Int;
	var RENDERBUFFER_INTERNAL_FORMAT:Int;
	var RENDERBUFFER_RED_SIZE:Int;
	var RENDERBUFFER_STENCIL_SIZE:Int;
	var RENDERBUFFER_WIDTH:Int;
	var RENDERER:Int;
	var REPEAT:Int;
	var REPLACE:Int;
	var RGB:Int;
	var RGB565:Int;
	var RGB5_A1:Int;
	var RGBA:Int;
	var RGBA4:Int;
	var SAMPLER_2D:Int;
	var SAMPLER_CUBE:Int;
	var SAMPLES:Int;
	var SAMPLE_ALPHA_TO_COVERAGE:Int;
	var SAMPLE_BUFFERS:Int;
	var SAMPLE_COVERAGE:Int;
	var SAMPLE_COVERAGE_INVERT:Int;
	var SAMPLE_COVERAGE_VALUE:Int;
	var SCISSOR_BOX:Int;
	var SCISSOR_TEST:Int;
	var SHADER_TYPE:Int;
	var SHADING_LANGUAGE_VERSION:Int;
	var SHORT:Int;
	var SRC_ALPHA:Int;
	var SRC_ALPHA_SATURATE:Int;
	var SRC_COLOR:Int;
	var STATIC_DRAW:Int;
	var STENCIL_ATTACHMENT:Int;
	var STENCIL_BACK_FAIL:Int;
	var STENCIL_BACK_FUNC:Int;
	var STENCIL_BACK_PASS_DEPTH_FAIL:Int;
	var STENCIL_BACK_PASS_DEPTH_PASS:Int;
	var STENCIL_BACK_REF:Int;
	var STENCIL_BACK_VALUE_MASK:Int;
	var STENCIL_BACK_WRITEMASK:Int;
	var STENCIL_BITS:Int;
	var STENCIL_BUFFER_BIT:Int;
	var STENCIL_CLEAR_VALUE:Int;
	var STENCIL_FAIL:Int;
	var STENCIL_FUNC:Int;
	var STENCIL_INDEX:Int;
	var STENCIL_INDEX8:Int;
	var STENCIL_PASS_DEPTH_FAIL:Int;
	var STENCIL_PASS_DEPTH_PASS:Int;
	var STENCIL_REF:Int;
	var STENCIL_TEST:Int;
	var STENCIL_VALUE_MASK:Int;
	var STENCIL_WRITEMASK:Int;
	var STREAM_DRAW:Int;
	var SUBPIXEL_BITS:Int;
	var TEXTURE:Int;
	var TEXTURE0:Int;
	var TEXTURE1:Int;
	var TEXTURE10:Int;
	var TEXTURE11:Int;
	var TEXTURE12:Int;
	var TEXTURE13:Int;
	var TEXTURE14:Int;
	var TEXTURE15:Int;
	var TEXTURE16:Int;
	var TEXTURE17:Int;
	var TEXTURE18:Int;
	var TEXTURE19:Int;
	var TEXTURE2:Int;
	var TEXTURE20:Int;
	var TEXTURE21:Int;
	var TEXTURE22:Int;
	var TEXTURE23:Int;
	var TEXTURE24:Int;
	var TEXTURE25:Int;
	var TEXTURE26:Int;
	var TEXTURE27:Int;
	var TEXTURE28:Int;
	var TEXTURE29:Int;
	var TEXTURE3:Int;
	var TEXTURE30:Int;
	var TEXTURE31:Int;
	var TEXTURE4:Int;
	var TEXTURE5:Int;
	var TEXTURE6:Int;
	var TEXTURE7:Int;
	var TEXTURE8:Int;
	var TEXTURE9:Int;
	var TEXTURE_2D:Int;
	var TEXTURE_BINDING_2D:Int;
	var TEXTURE_BINDING_CUBE_MAP:Int;
	var TEXTURE_CUBE_MAP:Int;
	var TEXTURE_CUBE_MAP_NEGATIVE_X:Int;
	var TEXTURE_CUBE_MAP_NEGATIVE_Y:Int;
	var TEXTURE_CUBE_MAP_NEGATIVE_Z:Int;
	var TEXTURE_CUBE_MAP_POSITIVE_X:Int;
	var TEXTURE_CUBE_MAP_POSITIVE_Y:Int;
	var TEXTURE_CUBE_MAP_POSITIVE_Z:Int;
	var TEXTURE_MAG_FILTER:Int;
	var TEXTURE_MIN_FILTER:Int;
	var TEXTURE_WRAP_S:Int;
	var TEXTURE_WRAP_T:Int;
	var TRIANGLES:Int;
	var TRIANGLE_FAN:Int;
	var TRIANGLE_STRIP:Int;
	var UNPACK_ALIGNMENT:Int;
	var UNPACK_COLORSPACE_CONVERSION_WEBGL:Int;
	var UNPACK_FLIP_Y_WEBGL:Int;
	var UNPACK_PREMULTIPLY_ALPHA_WEBGL:Int;
	var UNSIGNED_BYTE:Int;
	var UNSIGNED_INT:Int;
	var UNSIGNED_SHORT:Int;
	var UNSIGNED_SHORT_4_4_4_4:Int;
	var UNSIGNED_SHORT_5_5_5_1:Int;
	var UNSIGNED_SHORT_5_6_5:Int;
	var VALIDATE_STATUS:Int;
	var VENDOR:Int;
	var VERSION:Int;
	var VERTEX_ATTRIB_ARRAY_BUFFER_BINDING:Int;
	var VERTEX_ATTRIB_ARRAY_ENABLED:Int;
	var VERTEX_ATTRIB_ARRAY_NORMALIZED:Int;
	var VERTEX_ATTRIB_ARRAY_POINTER:Int;
	var VERTEX_ATTRIB_ARRAY_SIZE:Int;
	var VERTEX_ATTRIB_ARRAY_STRIDE:Int;
	var VERTEX_ATTRIB_ARRAY_TYPE:Int;
	var VERTEX_SHADER:Int;
	var VIEWPORT:Int;
	var ZERO:Int;
	
	#if (js && html5)
	var canvas (default, null):CanvasElement;
	var drawingBufferHeight (default,null):Int;
	var drawingBufferWidth (default, null):Int;
	#end
	
	#if (!js || !html5)
	function new();
	#end
	
	function activeTexture (texture:Int):Void;
	function attachShader (program:GLProgram, shader:GLShader):Void;
	function bindAttribLocation (program:GLProgram, index:Int, name:String):Void;
	function bindBuffer (target:Int, buffer:GLBuffer):Void;
	function bindFramebuffer (target:Int, framebuffer:GLFramebuffer):Void;
	function bindRenderbuffer (target:Int, renderbuffer:GLRenderbuffer):Void;
	function bindTexture (target:Int, texture:GLTexture):Void;
	function blendColor (red:Float, green:Float, blue:Float, alpha:Float):Void;
	function blendEquation (mode:Int):Void;
	function blendEquationSeparate (modeRGB:Int, modeAlpha:Int):Void;
	function blendFunc (sfactor:Int, dfactor:Int):Void;
	function blendFuncSeparate (srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int):Void;
	/** Throws DOMException. */
	@:overload(function(target:Int, data:lime.utils.ArrayBuffer, usage:Int):Void {})
	@:overload(function(target:Int, data:lime.utils.ArrayBufferView, usage:Int):Void {})
	function bufferData (target:Int, size:Int, usage:Int):Void;
	/** Throws DOMException. */
	@:overload(function(target:Int, offset:Int, data:lime.utils.ArrayBuffer):Void {})
	function bufferSubData (target:Int, offset:Int, data:lime.utils.ArrayBufferView):Void;
	function checkFramebufferStatus (target:Int):Int;
	function clear (mask:Int):Void;
	function clearColor (red:Float, green:Float, blue:Float, alpha:Float):Void;
	function clearDepth (depth:Float):Void;
	function clearStencil (s:Int):Void;
	function colorMask (red:Bool, green:Bool, blue:Bool, alpha:Bool):Void;
	function compileShader (shader:GLShader):Void;
	function compressedTexImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, data:lime.utils.ArrayBufferView):Void;
	function compressedTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, data:lime.utils.ArrayBufferView):Void;
	function copyTexImage2D (target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void;
	function copyTexSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void;
	function createBuffer ():GLBuffer;
	function createFramebuffer ():GLFramebuffer;
	function createProgram ():GLProgram;
	function createRenderbuffer ():GLRenderbuffer;
	function createShader (type:Int):GLShader;
	function createTexture ():GLTexture;
	function cullFace (mode:Int):Void;
	function deleteBuffer (buffer:GLBuffer):Void;
	function deleteFramebuffer (framebuffer:GLFramebuffer):Void;
	function deleteProgram (program:GLProgram):Void;
	function deleteRenderbuffer (renderbuffer:GLRenderbuffer):Void;
	function deleteShader (shader:GLShader):Void;
	function deleteTexture (texture:GLTexture):Void;
	function depthFunc (func:Int):Void;
	function depthMask (flag:Bool):Void;
	function depthRange (zNear:Float, zFar:Float):Void;
	function detachShader (program:GLProgram, shader:GLShader):Void;
	function disable (cap:Int):Void;
	function disableVertexAttribArray (index:Int):Void;
	function drawArrays (mode:Int, first:Int, count:Int):Void;
	function drawElements (mode:Int, count:Int, type:Int, offset:Int):Void;
	function enable (cap:Int):Void;
	function enableVertexAttribArray (index:Int):Void;
	function finish ():Void;
	function flush ():Void;
	function framebufferRenderbuffer (target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:GLRenderbuffer):Void;
	function framebufferTexture2D (target:Int, attachment:Int, textarget:Int, texture:GLTexture, level:Int):Void;
	function frontFace (mode:Int):Void;
	function generateMipmap (target:Int):Void;
	function getActiveAttrib (program:GLProgram, index:Int):GLActiveInfo;
	function getActiveUniform (program:GLProgram, index:Int):GLActiveInfo;
	/** Throws DOMException. */
	@:overload(function(program:GLProgram):Void {})
	function getAttachedShaders (program:GLProgram):Array<GLShader>;
	function getAttribLocation (program:GLProgram, name:String):Int;
	@:overload(function():Void {})
	function getBufferParameter (target:Int, pname:Int):Dynamic;
	function getContextAttributes ():GLContextAttributes;
	function getError ():Int;
	function getExtension (name:String):Dynamic;
	@:overload(function():Void {})
	function getFramebufferAttachmentParameter (target:Int, attachment:Int, pname:Int):Dynamic;
	@:overload(function():Void {})
	function getParameter (pname:Int):Dynamic;
	function getProgramInfoLog (program:GLProgram):String;
	@:overload(function():Void {})
	function getProgramParameter (program:GLProgram, pname:Int):Dynamic;
	@:overload(function():Void {})
	function getRenderbufferParameter (target:Int, pname:Int):Dynamic;
	function getShaderInfoLog (shader:GLShader):String;
	/** Throws DOMException. */
	@:overload(function():Void {})
	function getShaderParameter (shader:GLShader, pname:Int):Dynamic;
	function getShaderPrecisionFormat (shadertype:Int, precisiontype:Int):GLShaderPrecisionFormat;
	function getShaderSource (shader:GLShader):String;
	function getSupportedExtensions ():Array<String>;
	@:overload(function():Void {})
	function getTexParameter (target:Int, pname:Int):Dynamic;
	@:overload(function():Void {})
	function getUniform (program:GLProgram, location:GLUniformLocation):Dynamic;
	function getUniformLocation (program:GLProgram, name:String):GLUniformLocation;
	@:overload(function():Void {})
	function getVertexAttrib (index:Int, pname:Int):Dynamic;
	function getVertexAttribOffset (index:Int, pname:Int):Int;
	function hint (target:Int, mode:Int):Void;
	function isBuffer (buffer:GLBuffer):Bool;
	function isContextLost ():Bool;
	function isEnabled (cap:Int):Bool;
	function isFramebuffer (framebuffer:GLFramebuffer):Bool;
	function isProgram (program:GLProgram):Bool;
	function isRenderbuffer (renderbuffer:GLRenderbuffer):Bool;
	function isShader (shader:GLShader):Bool;
	function isTexture (texture:GLTexture):Bool;
	function lineWidth (width:Float):Void;
	function linkProgram (program:GLProgram):Void;
	function pixelStorei (pname:Int, param:Int):Void;
	function polygonOffset (factor:Float, units:Float):Void;
	function readPixels (x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:lime.utils.ArrayBufferView):Void;
	function releaseShaderCompiler ():Void;
	function renderbufferStorage (target:Int, internalformat:Int, width:Int, height:Int):Void;
	function sampleCoverage (value:Float, invert:Bool):Void;
	function scissor (x:Int, y:Int, width:Int, height:Int):Void;
	function shaderSource (shader:GLShader, string:String):Void;
	function stencilFunc (func:Int, ref:Int, mask:Int):Void;
	function stencilFuncSeparate (face:Int, func:Int, ref:Int, mask:Int):Void;
	function stencilMask (mask:Int):Void;
	function stencilMaskSeparate (face:Int, mask:Int):Void;
	function stencilOp (fail:Int, zfail:Int, zpass:Int):Void;
	function stencilOpSeparate (face:Int, fail:Int, zfail:Int, zpass:Int):Void;
	/** Throws DOMException. */
	#if (js && html5)
	@:overload(function(target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:lime.utils.ArrayBufferView):Void {})
	@:overload(function(target:Int, level:Int, internalformat:Int, format:Int, type:Int, pixels:js.html.ImageData):Void {})
	@:overload(function(target:Int, level:Int, internalformat:Int, format:Int, type:Int, image:js.html.ImageElement):Void {})
	@:overload(function(target:Int, level:Int, internalformat:Int, format:Int, type:Int, canvas:js.html.CanvasElement):Void {})
	function texImage2D (target:Int, level:Int, internalformat:Int, format:Int, type:Int, video:js.html.VideoElement):Void;
	#else
	function texImage2D (target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:lime.utils.ArrayBufferView):Void;
	#end
	function texParameterf (target:Int, pname:Int, param:Float):Void;
	function texParameteri (target:Int, pname:Int, param:Int):Void;
	/** Throws DOMException. */
	#if (js && html5)
	@:overload(function(target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:lime.utils.ArrayBufferView):Void {})
	@:overload(function(target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, pixels:js.html.ImageData):Void {})
	@:overload(function(target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, image:js.html.ImageElement):Void {})
	@:overload(function(target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, canvas:js.html.CanvasElement):Void {})
	function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, format:Int, type:Int, video:js.html.VideoElement):Void;
	#else
	function texSubImage2D (target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:lime.utils.ArrayBufferView):Void;
	#end
	function uniform1f (location:GLUniformLocation, x:Float):Void;
	function uniform1fv (location:GLUniformLocation, v:lime.utils.Float32Array):Void;
	function uniform1i (location:GLUniformLocation, x:Int):Void;
	function uniform1iv (location:GLUniformLocation, v:lime.utils.Int32Array):Void;
	function uniform2f (location:GLUniformLocation, x:Float, y:Float):Void;
	function uniform2fv (location:GLUniformLocation, v:lime.utils.Float32Array):Void;
	function uniform2i (location:GLUniformLocation, x:Int, y:Int):Void;
	function uniform2iv (location:GLUniformLocation, v:lime.utils.Int32Array):Void;
	function uniform3f (location:GLUniformLocation, x:Float, y:Float, z:Float):Void;
	function uniform3fv(location:GLUniformLocation, v:lime.utils.Float32Array):Void;
	function uniform3i (location:GLUniformLocation, x:Int, y:Int, z:Int):Void;
	function uniform3iv (location:GLUniformLocation, v:lime.utils.Int32Array):Void;
	function uniform4f (location:GLUniformLocation, x:Float, y:Float, z:Float, w:Float):Void;
	function uniform4fv (location:GLUniformLocation, v:lime.utils.Float32Array):Void;
	function uniform4i (location:GLUniformLocation, x:Int, y:Int, z:Int, w:Int):Void;
	function uniform4iv (location:GLUniformLocation, v:lime.utils.Int32Array):Void;
	function uniformMatrix2fv (location:GLUniformLocation, transpose:Bool, array:lime.utils.Float32Array):Void;
	function uniformMatrix3fv (location:GLUniformLocation, transpose:Bool, array:lime.utils.Float32Array):Void;
	function uniformMatrix4fv (location:GLUniformLocation, transpose:Bool, array:lime.utils.Float32Array):Void;
	function useProgram (program:GLProgram):Void;
	function validateProgram (program:GLProgram):Void;
	function vertexAttrib1f (indx:Int, x:Float):Void;
	function vertexAttrib1fv (indx:Int, values:lime.utils.Float32Array):Void;
	function vertexAttrib2f (indx:Int, x:Float, y:Float):Void;
	function vertexAttrib2fv (indx:Int, values:lime.utils.Float32Array):Void;
	function vertexAttrib3f (indx:Int, x:Float, y:Float, z:Float):Void;
	function vertexAttrib3fv (indx:Int, values:lime.utils.Float32Array):Void;
	function vertexAttrib4f (indx:Int, x:Float, y:Float, z:Float, w:Float):Void;
	function vertexAttrib4fv (indx:Int, values:lime.utils.Float32Array):Void;
	function vertexAttribPointer (indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int):Void;
	function viewport (x:Int, y:Int, width:Int, height:Int):Void;
}


#end