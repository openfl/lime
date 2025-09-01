package lime.graphics;

#if (!lime_doc_gen || lime_cairo)
import lime.graphics.cairo.Cairo;

/**
	The `CairoRenderContext` represents the primary `lime.graphics.Cairo` instance when Cairo
	is the render context type of the `Window`.

	You can convert from `lime.graphics.RenderContext` to `CairoRenderContext` directly
	if desired:

	```haxe
	var cairo:CairoRenderContext = window.context;
	```
**/
@:access(lime.graphics.RenderContext)
@:forward
@:transitive
abstract CairoRenderContext(Cairo) from Cairo to Cairo
{
	@:from private static function fromRenderContext(context:RenderContext):CairoRenderContext
	{
		return context.cairo;
	}
}
#end
