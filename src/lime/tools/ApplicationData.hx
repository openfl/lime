package lime.tools;

typedef ApplicationData =
{
	@:optional var file:String;
	@:optional var init:String;
	@:optional var main:String;
	@:optional var path:String;
	@:optional var preloader:String;
	@:optional var swfVersion:Float;
	@:optional var url:String;
}

@:dox(hide) class _ApplicationDataType
{
	public static var fields:ApplicationData =
		{
			file: "",
			init: "",
			main: "",
			path: "",
			preloader: "",
			swfVersion: 0.0,
			url: ""
		}
}
