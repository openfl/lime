package lime.graphics;

#if (!lime_doc_gen || lime_opengl)
#if (lime_doc_gen || (sys && lime_cffi && !doc_gen))
import lime._internal.backend.native.NativeOpenGLRenderContext;

/**
	The `OpenGLRenderContext` allows access to OpenGL features when OpenGL is the render
	context type of the `Window`. Historically, Lime was designed for WebGL render support
	on all platforms, and support has expanded to provide additional OpenGL ES native APIs.

	Support for desktop OpenGL-specific features is currently sparse, but the
	`OpenGLRenderContext` provides the platform for us to add additional desktop specific
	features.

	The `OpenGLRenderContext` is not compatible with mobile or web targets, but it can be
	converted to an OpenGL ES or a WebGL-style context for cross-platform development.

	You can convert from `lime.graphics.RenderContext` or `lime.graphics.opengl.GL`, and
	can convert to `lime.graphics.OpenGLES3RenderContext`,
	`lime.graphics.OpenGLES2RenderContext`, `lime.graphics.WebGL2RenderContext`, or
	`lime.graphics.WebGLRenderContext` directly if desired:

	```haxe
	var gl:OpenGLRenderContext = window.context;
	var gl:OpenGLRenderContext = GL;

	var gles3:OpenGLES3RenderContext = gl;
	var gles2:OpenGLES2RenderContext = gl;
	var webgl2:WebGL2RenderContext = gl;
	var webgl:WebGLRenderContext = gl;
	```
**/
@:access(lime.graphics.RenderContext)
@:forward()
@:transitive
abstract OpenGLRenderContext(NativeOpenGLRenderContext) from NativeOpenGLRenderContext to NativeOpenGLRenderContext
{
	@:from private static function fromRenderContext(context:RenderContext):OpenGLRenderContext
	{
		return context.gl;
	}
}
#else
@:forward()
@:transitive
abstract OpenGLRenderContext(Dynamic) from Dynamic to Dynamic
{
	@:from private static function fromRenderContext(context:RenderContext):OpenGLRenderContext
	{
		return null;
	}
}
#end
#end
