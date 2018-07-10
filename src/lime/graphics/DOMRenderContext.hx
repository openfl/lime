package lime.graphics; #if (!lime_doc_gen || lime_dom) #if (lime_dom && (lime_doc_gen || !doc_gen))


import js.html.Element;

@:access(lime.graphics.RenderContext)
@:forward


abstract DOMRenderContext(Element) from Element to Element {
	
	
	@:from private static function fromRenderContext (context:RenderContext):DOMRenderContext {
		
		return context.dom;
		
	}
	
	
}


#else


@:forward


abstract DOMRenderContext(Dynamic) from Dynamic to Dynamic {
	
	
	@:from private static function fromRenderContext (context:RenderContext):DOMRenderContext {
		
		return null;
		
	}
	
	
}


#end
#end