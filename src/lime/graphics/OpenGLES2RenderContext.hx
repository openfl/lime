package lime.graphics;

#if (!lime_doc_gen || lime_opengl || lime_opengles)
#if (doc_gen || (sys && lime_cffi))
import lime.graphics.opengl.*;

/**
	The `OpenGLES2RenderContext` allows access to OpenGL ES 2.0 features when OpenGL or
	OpenGL ES is the render context type of the `Window`.

	Using an OpenGL ES context on a desktop platform enables support for cross-platform
	code that should run on the majority of desktop and mobile platforms (when using
	hardware acceleration).

	Platforms supporting an OpenGL ES context are compatible with the Lime
	`WebGLRenderContext` if you would prefer to write WebGL-style code, or support web
	browsers with the same code.

	You can convert from `lime.graphics.RenderContext`, `lime.graphics.OpenGLRenderContext`,
	`lime.graphics.OpenGLES3RenderContext`, `lime.graphics.opengl.GL`, and can convert to
	`lime.graphics.WebGLRenderContext` directly if desired:

	```haxe
	var gles2:OpenGLES2RenderContext = window.context;
	var gles2:OpenGLES2RenderContext = gl;
	var gles2:OpenGLES2RenderContext = gles3;
	var gles2:OpenGLES2RenderContext = GL;

	var webgl:WebGLRenderContext = gles2;
	```
**/
@:forward(ACTIVE_ATTRIBUTES, ACTIVE_TEXTURE, ACTIVE_UNIFORMS, ALIASED_LINE_WIDTH_RANGE, ALIASED_POINT_SIZE_RANGE, ALPHA, ALPHA_BITS, ALWAYS, ARRAY_BUFFER,
	ARRAY_BUFFER_BINDING, ATTACHED_SHADERS, BACK, BLEND, BLEND_COLOR, BLEND_DST_ALPHA, BLEND_DST_RGB, BLEND_EQUATION, BLEND_EQUATION_ALPHA,
	BLEND_EQUATION_RGB, BLEND_SRC_ALPHA, BLEND_SRC_RGB, BLUE_BITS, BOOL, BOOL_VEC2, BOOL_VEC3, BOOL_VEC4, BROWSER_DEFAULT_WEBGL, BUFFER_SIZE, BUFFER_USAGE,
	BYTE, CCW, CLAMP_TO_EDGE, COLOR_ATTACHMENT0, COLOR_BUFFER_BIT, COLOR_CLEAR_VALUE, COLOR_WRITEMASK, COMPILE_STATUS, COMPRESSED_TEXTURE_FORMATS,
	CONSTANT_ALPHA, CONSTANT_COLOR, CULL_FACE, CULL_FACE_MODE, CURRENT_PROGRAM, CURRENT_VERTEX_ATTRIB, CW, DECR, DECR_WRAP, DELETE_STATUS, DEPTH_ATTACHMENT,
	DEPTH_BITS, DEPTH_BUFFER_BIT, DEPTH_CLEAR_VALUE, DEPTH_COMPONENT, DEPTH_COMPONENT16, DEPTH_FUNC, DEPTH_RANGE, DEPTH_STENCIL, DEPTH_STENCIL_ATTACHMENT,
	DEPTH_TEST, DEPTH_WRITEMASK, DITHER, DONT_CARE, DST_ALPHA, DST_COLOR, DYNAMIC_DRAW, ELEMENT_ARRAY_BUFFER, ELEMENT_ARRAY_BUFFER_BINDING, EQUAL, FASTEST,
	FLOAT, FLOAT_MAT2, FLOAT_MAT3, FLOAT_MAT4, FLOAT_VEC2, FLOAT_VEC3, FLOAT_VEC4, FRAGMENT_SHADER, FRAMEBUFFER, FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
	FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE, FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE, FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL, FRAMEBUFFER_BINDING,
	FRAMEBUFFER_COMPLETE, FRAMEBUFFER_INCOMPLETE_ATTACHMENT, FRAMEBUFFER_INCOMPLETE_DIMENSIONS, FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT,
	FRAMEBUFFER_UNSUPPORTED, FRONT, FRONT_AND_BACK, FRONT_FACE, FUNC_ADD, FUNC_REVERSE_SUBTRACT, FUNC_SUBTRACT, GENERATE_MIPMAP_HINT, GEQUAL, GREATER,
	GREEN_BITS, HIGH_FLOAT, HIGH_INT, INCR, INCR_WRAP, INT, INT_VEC2, INT_VEC3, INT_VEC4, INVALID_ENUM, INVALID_FRAMEBUFFER_OPERATION, INVALID_OPERATION,
	INVALID_VALUE, INVERT, KEEP, LEQUAL, LESS, LINEAR, LINEAR_MIPMAP_LINEAR, LINEAR_MIPMAP_NEAREST, LINES, LINE_LOOP, LINE_STRIP, LINE_WIDTH, LINK_STATUS,
	LOW_FLOAT, LOW_INT, LUMINANCE, LUMINANCE_ALPHA, MAX_COMBINED_TEXTURE_IMAGE_UNITS, MAX_CUBE_MAP_TEXTURE_SIZE, MAX_FRAGMENT_UNIFORM_VECTORS,
	MAX_RENDERBUFFER_SIZE, MAX_TEXTURE_IMAGE_UNITS, MAX_TEXTURE_SIZE, MAX_VARYING_VECTORS, MAX_VERTEX_ATTRIBS, MAX_VERTEX_TEXTURE_IMAGE_UNITS,
	MAX_VERTEX_UNIFORM_VECTORS, MAX_VIEWPORT_DIMS, MEDIUM_FLOAT, MEDIUM_INT, MIRRORED_REPEAT, NEAREST, NEAREST_MIPMAP_LINEAR, NEAREST_MIPMAP_NEAREST, NEVER,
	NICEST, NONE, NOTEQUAL, NO_ERROR, ONE, ONE_MINUS_CONSTANT_ALPHA, ONE_MINUS_CONSTANT_COLOR, ONE_MINUS_DST_ALPHA, ONE_MINUS_DST_COLOR, ONE_MINUS_SRC_ALPHA,
	ONE_MINUS_SRC_COLOR, OUT_OF_MEMORY, PACK_ALIGNMENT, POINTS, POLYGON_OFFSET_FACTOR, POLYGON_OFFSET_FILL, POLYGON_OFFSET_UNITS, RED_BITS, RENDERBUFFER,
	RENDERBUFFER_ALPHA_SIZE, RENDERBUFFER_BINDING, RENDERBUFFER_BLUE_SIZE, RENDERBUFFER_DEPTH_SIZE, RENDERBUFFER_GREEN_SIZE, RENDERBUFFER_HEIGHT,
	RENDERBUFFER_INTERNAL_FORMAT, RENDERBUFFER_RED_SIZE, RENDERBUFFER_STENCIL_SIZE, RENDERBUFFER_WIDTH, RENDERER, REPEAT, REPLACE, RGB, RGB565, RGB5_A1, RGBA,
	RGBA4, SAMPLER_2D, SAMPLER_CUBE, SAMPLES, SAMPLE_ALPHA_TO_COVERAGE, SAMPLE_BUFFERS, SAMPLE_COVERAGE, SAMPLE_COVERAGE_INVERT, SAMPLE_COVERAGE_VALUE,
	SCISSOR_BOX, SCISSOR_TEST, SHADER_TYPE, SHADING_LANGUAGE_VERSION, SHORT, SRC_ALPHA, SRC_ALPHA_SATURATE, SRC_COLOR, STATIC_DRAW, STENCIL_ATTACHMENT,
	STENCIL_BACK_FAIL, STENCIL_BACK_FUNC, STENCIL_BACK_PASS_DEPTH_FAIL, STENCIL_BACK_PASS_DEPTH_PASS, STENCIL_BACK_REF, STENCIL_BACK_VALUE_MASK,
	STENCIL_BACK_WRITEMASK, STENCIL_BITS, STENCIL_BUFFER_BIT, STENCIL_CLEAR_VALUE, STENCIL_FAIL, STENCIL_FUNC, STENCIL_INDEX, STENCIL_INDEX8,
	STENCIL_PASS_DEPTH_FAIL, STENCIL_PASS_DEPTH_PASS, STENCIL_REF, STENCIL_TEST, STENCIL_VALUE_MASK, STENCIL_WRITEMASK, STREAM_DRAW, SUBPIXEL_BITS, TEXTURE,
	TEXTURE0, TEXTURE1, TEXTURE10, TEXTURE11, TEXTURE12, TEXTURE13, TEXTURE14, TEXTURE15, TEXTURE16, TEXTURE17, TEXTURE18, TEXTURE19, TEXTURE2, TEXTURE20,
	TEXTURE21, TEXTURE22, TEXTURE23, TEXTURE24, TEXTURE25, TEXTURE26, TEXTURE27, TEXTURE28, TEXTURE29, TEXTURE3, TEXTURE30, TEXTURE31, TEXTURE4, TEXTURE5,
	TEXTURE6, TEXTURE7, TEXTURE8, TEXTURE9, TEXTURE_2D, TEXTURE_BINDING_2D, TEXTURE_BINDING_CUBE_MAP, TEXTURE_CUBE_MAP, TEXTURE_CUBE_MAP_NEGATIVE_X,
	TEXTURE_CUBE_MAP_NEGATIVE_Y, TEXTURE_CUBE_MAP_NEGATIVE_Z, TEXTURE_CUBE_MAP_POSITIVE_X, TEXTURE_CUBE_MAP_POSITIVE_Y, TEXTURE_CUBE_MAP_POSITIVE_Z,
	TEXTURE_MAG_FILTER, TEXTURE_MIN_FILTER, TEXTURE_WRAP_S, TEXTURE_WRAP_T, TRIANGLES, TRIANGLE_FAN, TRIANGLE_STRIP, UNPACK_ALIGNMENT, UNSIGNED_BYTE,
	UNSIGNED_INT, UNSIGNED_SHORT, UNSIGNED_SHORT_4_4_4_4, UNSIGNED_SHORT_5_5_5_1, UNSIGNED_SHORT_5_6_5, VALIDATE_STATUS, VENDOR, VERSION,
	VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, VERTEX_ATTRIB_ARRAY_ENABLED, VERTEX_ATTRIB_ARRAY_NORMALIZED, VERTEX_ATTRIB_ARRAY_POINTER, VERTEX_ATTRIB_ARRAY_SIZE,
	VERTEX_ATTRIB_ARRAY_STRIDE, VERTEX_ATTRIB_ARRAY_TYPE, VERTEX_SHADER, VIEWPORT, ZERO, activeTexture, attachShader, bindAttribLocation, bindBuffer,
	bindFramebuffer, bindTexture, blendColor, blendEquation, blendEquationSeparate, blendFunc, blendFuncSeparate, bufferData, bufferSubData,
	checkFramebufferStatus, clear, clearColor, clearDepthf, clearStencil, colorMask, compileShader, compressedTexImage2D, compressedTexSubImage2D,
	copyTexImage2D, copyTexSubImage2D, createBuffer, createFramebuffer, createProgram, createRenderbuffer, createShader, createTexture, cullFace,
	deleteBuffer, deleteFramebuffer, deleteProgram, deleteRenderbuffer, deleteShader, deleteTexture, depthFunc, depthMask, depthRangef, detachShader, disable,
	disableVertexAttribArray, drawArrays, drawElements, enable, enableVertexAttribArray, finish, flush, framebufferRenderbuffer, framebufferTexture2D,
	frontFace, genBuffers, generateMipmap, genFramebuffers, genRenderbuffers, genTextures, getActiveAttrib, getActiveUniform, getAttachedShaders,
	getAttribLocation, getBoolean, getBooleanv, getBufferParameteri, getBufferParameteriv, getError, getFloat, getFloatv, getFramebufferAttachmentParameteri,
	getFramebufferAttachmentParameteriv, getInteger, getIntegerv, getProgramInfoLog, getProgrami, getProgramiv, getRenderbufferParameteri,
	getRenderbufferParameteriv, getShaderi, getShaderInfoLog, getShaderiv, getShaderPrecisionFormat, getShaderSource, getString, getTexParameterf,
	getTexParameterfv, getTexParameteri, getTexParameteriv, getUniform, getUniformLocation, getVertexAttribf, getVertexAttribfv, getVertexAttribi,
	getVertexAttribiv, getVertexAttribPointerv, hint, isBuffer, isEnabled, isFramebuffer, isProgram, isRenderbuffer, isShader, isTexture, lineWidth,
	linkProgram, pixelStorei, polygonOffset, readPixels, releaseShaderCompiler, renderbufferStorage, sampleCoverage, scissor, shaderBinary, shaderSource,
	stencilFunc, stencilFuncSeparate, stencilMask, stencilMaskSeparate, stencilOp, stencilOpSeparate, texImage2D, texParameterf, texParameteri, texSubImage2D,
	uniform1f, uniform1fv, uniform1i, uniform1iv, uniform2f, uniform2fv, uniform2i, uniform2iv, uniform3f, uniform3fv, uniform3i, uniform3iv, uniform4f,
	uniform4fv, uniform4i, uniform4iv, uniformMatrix2fv, uniformMatrix3fv, uniformMatrix4fv, useProgram, validateProgram, vertexAttrib1f, vertexAttrib1fv,
	vertexAttrib2f, vertexAttrib2fv, vertexAttrib3f, vertexAttrib3fv, vertexAttrib4f, vertexAttrib4fv, vertexAttribPointer, viewport, EXTENSIONS, type, version)
@:transitive
abstract OpenGLES2RenderContext(OpenGLES3RenderContext) from OpenGLES3RenderContext
	#if (!doc_gen && lime_opengl) from OpenGLRenderContext #end
{
	@:from private static function fromGL(gl:Class<GL>):OpenGLES2RenderContext
	{
		return cast GL.context;
	}

	@:from private static function fromRenderContext(context:RenderContext):OpenGLES2RenderContext
	{
		return context.gles2;
	}
}
#else
import lime.graphics.opengl.GL;

@:forward()
@:transitive
abstract OpenGLES2RenderContext(Dynamic) from Dynamic to Dynamic
{
	@:from private static function fromGL(gl:Class<GL>):OpenGLES2RenderContext
	{
		return null;
	}

	@:from private static function fromOpenGLES3RenderContext(gl:OpenGLES3RenderContext):OpenGLES2RenderContext
	{
		return null;
	}

	#if (!doc_gen && lime_opengl)
	@:from private static function fromOpenGLRenderContext(gl:OpenGLRenderContext):OpenGLES2RenderContext
	{
		return null;
	}
	#end

	@:from private static function fromRenderContext(context:RenderContext):OpenGLES2RenderContext
	{
		return null;
	}

	@:from private static function fromWebGLRenderContext(gl:WebGLRenderContext):OpenGLES2RenderContext
	{
		return null;
	}
}
#end
#end
