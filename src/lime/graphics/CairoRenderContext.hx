package lime.graphics; #if (sys && lime_cairo && !doc_gen)


import lime.graphics.cairo.Cairo;

@:access(lime.graphics.RenderContext)
@:forward()


abstract CairoRenderContext(Cairo) from Cairo to Cairo {
	
	
	@:from private static function fromRenderContext (context:RenderContext):CairoRenderContext {
		
		return context.cairo;
		
	}
	
	
}


#else


@:forward()


abstract CairoRenderContext(Dynamic) from Dynamic to Dynamic {
	
	
	@:from private static function fromRenderContext (context:RenderContext):CairoRenderContext {
		
		return null;
		
	}
	
	
}


#end