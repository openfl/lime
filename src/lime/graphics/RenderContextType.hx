package lime.graphics;

/**
	An enum for possible render context types
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract RenderContextType(String) from String to String
{
	/**
		Describes a Cairo render context
	**/
	var CAIRO = "cairo";

	/**
		Describes an HTML5 canvas render context
	**/
	var CANVAS = "canvas";

	/**
		Describes an HTML5 DOM render context
	**/
	var DOM = "dom";

	/**
		Describes a Flash render context
	**/
	var FLASH = "flash";

	/**
		Describes an OpenGL render context
	**/
	var OPENGL = "opengl";

	/**
		Describes an OpenGL ES render context
	**/
	var OPENGLES = "opengles";

	/**
		Describes a WebGL render context
	**/
	var WEBGL = "webgl";

	/**
		Describes a custom render context
	**/
	var CUSTOM = "custom";
}
