package lime.graphics; #if (!lime_doc_gen || lime_cairo)


import lime.graphics.cairo.Cairo;

@:access(lime.graphics.RenderContext)
@:forward


abstract CairoRenderContext(Cairo) from Cairo to Cairo {
	
	
	@:from private static function fromRenderContext (context:RenderContext):CairoRenderContext {
		
		return context.cairo;
		
	}
	
	
}


#end