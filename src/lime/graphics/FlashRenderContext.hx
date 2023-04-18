package lime.graphics;

#if (!lime_doc_gen || flash)
#if (flash && (lime_doc_gen || !doc_gen))
import flash.display.Sprite;

/**
	The `FlashRenderContext` represents the primary `flash.display.Sprite` instance when
	targeting Flash Player.

	You can convert from `lime.graphics.RenderContext` to `FlashRenderContext` directly
	if desired:

	```haxe
	var sprite:FlashRenderContext = window.context;
	```
**/
@:access(lime.graphics.RenderContext)
@:forward
abstract FlashRenderContext(Sprite) from Sprite to Sprite
{
	@:from private static function fromRenderContext(context:RenderContext):FlashRenderContext
	{
		return context.flash;
	}
}
#else
@:forward
@:transitive
abstract FlashRenderContext(Dynamic) from Dynamic to Dynamic
{
	@:from private static function fromRenderContext(context:RenderContext):FlashRenderContext
	{
		return null;
	}
}
#end
#end
