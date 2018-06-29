package lime.app;


typedef Config = {
	
	/**
	 * A build number
	 *
	 * The build number is a unique, integer-based value which increases
	 * upon each build or release of an application. This is distinct from
	 * the version number.
	 *
	 * In the default generated config for Lime applications, this is often
	 * updated automatically, or can be overriden in XML project files using
	 * the `<app build="" />` attribute
	**/
	@:optional var build:String;
	
	/**
	 * A company name
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<meta company="" />` attribute in XML
	**/
	@:optional var company:String;
	
	/**
	 * An application file name, without a file extension
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<app file="" />` attribute in XML
	**/
	@:optional var file:String;
	
	/**
	 * An application name, used as the default Window title
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<meta title="" />` attribute in XML
	**/
	@:optional var name:String;
	
	/**
	 * An application orientation
	 *
	 * Expected values include "portrait", "landscape" or an empty string
	 * for all orientations.
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<window orientation="" />` attribute in XML
	**/
	@:optional var orientation:String;
	
	/**
	 * A package name, this usually corresponds to the unique ID used
	 * in application stores to identify the current application
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<meta package="" />` attribute in XML
	**/
	@:optional var packageName:String;
	
	/**
	 * A root path for application assets
	 *
	 * The default value is an empty string, but this can be used when
	 * bundled application assets are located in a different directory.
	 *
	 * This value is not exposed in Lime project files, but is available
	 * using the `lime.embed` function in HTML5 project embeds, and may
	 * behave similarly to the Flash "base" embed parameter
	**/
	@:optional var rootPath:String;
	
	/**
	 * A version number
	 *
	 * The version number is what normally corresponds to the user-facing
	 * version for an application, such as "1.0.0" or "12.2.5". This is 
	 * distinct from the build number. Many application stores expect the
	 * version number to include three segments.
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<meta title="" />` attribute in XML
	**/
	@:optional var version:String;
	
	/**
	 * A set of configuration objects for each initial application Window
	**/
	@:optional var windows:Array<WindowConfig>;
	
}


typedef WindowConfig = { 
	
	@:optional var allowHighDPI:Bool;
	@:optional var alwaysOnTop:Bool;
	@:optional var antialiasing:Int;
	@:optional var background:Null<Int>;
	@:optional var borderless:Bool;
	@:optional var colorDepth:Int;
	@:optional var depthBuffer:Bool;
	@:optional var display:Int;
	#if (js && html5)
	@:optional var element:js.html.Element;
	#end
	
	/**
	 * A requested frame rate
	 *
	 * In the default generated config for Lime applications, the default value
	 * is 30 FPS on many platforms, or vsync for HTML5. It can be overriden in 
	 * XML project files using the `<window fps="" />` attribute
	**/
	@:optional var fps:Int;
	
	@:optional var fullscreen:Bool;
	@:optional var hardware:Bool;
	@:optional var height:Int;
	@:optional var hidden:Bool;
	@:optional var maximized:Bool;
	@:optional var minimized:Bool;
	@:optional var parameters:Dynamic;
	@:optional var renderer:String;
	@:optional var resizable:Bool;
	@:optional var stencilBuffer:Bool;
	@:optional var title:String;
	@:optional var vsync:Bool;
	@:optional var width:Int;
	@:optional var x:Int;
	@:optional var y:Int;
	
}