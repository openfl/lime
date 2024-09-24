package lime.graphics;

/**
	Additional options possible for a render context
**/
typedef RenderContextAttributes =
{
	/**
		Whether to enable anti-aliasing, `0` is disabled, `2` enables
		2x2 anti-aliasing or `4` enables 4x4 anti-aliasing.
	**/
	@:optional var antialiasing:Int;

	/**
		An optional `background` property to be provided to rendering,
		a value of `null` means no background color.
	**/
	@:optional var background:Null<Int>;

	/**
		The color depth of the rendering context in bits
	**/
	@:optional var colorDepth:Int;

	/**
		Whether a depth buffer is enabled
	**/
	@:optional var depth:Bool;

	/**
		Whether hardware acceleration is allowed
	**/
	@:optional var hardware:Bool;

	#if html5
	/**
		Whether to preserve the `HTMLCanvas`'s image data after rendering
	**/
	@:optional var preserveDrawingBuffer:Bool;
	#end

	/**
		Whether a stencil buffer is enabled
	**/
	@:optional var stencil:Bool;

	/**
		The type of render context requested
	**/
	@:optional var type:RenderContextType;

	@:optional var version:String;

	/**
		Whether vertical-sync (VSync) is enabled
	**/
	@:optional var vsync:Bool;
}
