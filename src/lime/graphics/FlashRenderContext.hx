package lime.graphics; #if (!lime_doc_gen || flash) #if (flash && (lime_doc_gen || !doc_gen))


import flash.display.Sprite;

@:access(lime.graphics.RenderContext)
@:forward


abstract FlashRenderContext(Sprite) from Sprite to Sprite {
	
	
	@:from private static function fromRenderContext (context:RenderContext):FlashRenderContext {
		
		return context.flash;
		
	}
	
	
}


#else


@:forward


abstract FlashRenderContext(Dynamic) from Dynamic to Dynamic {
	
	
	@:from private static function fromRenderContext (context:RenderContext):FlashRenderContext {
		
		return null;
		
	}
	
	
}


#end
#end