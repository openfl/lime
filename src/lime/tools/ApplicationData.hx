package lime.tools;

@:forward
abstract ApplicationData({
	@:optional var file:String;
	@:optional var init:String;
	@:optional var main:String;
	@:optional var path:String;
	@:optional var preloader:String;
	@:optional var swfVersion:Float;
	@:optional var url:String;
}) from Dynamic
{
	@:noCompletion
	public static var expectedFields:ApplicationData = {
		file: "",
		init: "",
		main: "",
		path: "",
		preloader: "",
		swfVersion: 0.0,
		url: ""
	};
}
