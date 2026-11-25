package lime.tools;

class Icon
{
	/**
		On Android, the layer of the adaptive icon this image is: `"foreground"`, `"background"` or
		`"monochrome"`, drawn on 108 dp, of which launchers show the middle 72 dp. Such an image is only
		used for that layer, not as the application's icon, and `null` is an ordinary icon.
	**/
	public var adaptive:String;

	public var height:Int;
	public var path:String;
	public var size:Int;
	public var width:Int;
	public var priority:Int;

	public function new(path:String, size:Int = 0, priority:Int = 0)
	{
		this.path = path;
		this.size = height = width = size;
		this.priority = priority;
	}

	public function clone():Icon
	{
		var icon = new Icon(path);
		icon.size = size;
		icon.width = width;
		icon.height = height;
		icon.priority = priority;
		icon.adaptive = adaptive;

		return icon;
	}
}
