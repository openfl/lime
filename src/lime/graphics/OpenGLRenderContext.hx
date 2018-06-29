package lime.graphics; #if (sys && lime_cffi && lime_opengl && !doc_gen)


import lime._internal.backend.native.NativeOpenGLRenderContext;

@:access(lime.graphics.RenderContext)
@:forward()


abstract OpenGLRenderContext(NativeOpenGLRenderContext) from NativeOpenGLRenderContext to NativeOpenGLRenderContext {
	
	
	@:from private static function fromRenderContext (context:RenderContext):OpenGLRenderContext {
		
		return context.gl;
		
	}
	
	
}


#else


@:forward()


abstract OpenGLRenderContext(Dynamic) from Dynamic to Dynamic {
	
	
	@:from private static function fromRenderContext (context:RenderContext):OpenGLRenderContext {
		
		return null;
		
	}
	
	
}


#end