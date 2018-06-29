package lime.graphics;


#if (js && html5 && !doc_gen)


import js.html.CanvasRenderingContext2D;


@:access(lime.graphics.RenderContext)

@:forward()

abstract Canvas2DRenderContext(CanvasRenderingContext2D) from CanvasRenderingContext2D to CanvasRenderingContext2D {
	
	
	@:from private static function fromRenderContext (context:RenderContext):Canvas2DRenderContext {
		
		return context.canvas2D;
		
	}
	
	
}


#else


@:forward()

abstract Canvas2DRenderContext(Dynamic) from Dynamic to Dynamic {
	
	
	@:from private static function fromRenderContext (context:RenderContext):Canvas2DRenderContext {
		
		return null;
		
	}
	
	
}


#end