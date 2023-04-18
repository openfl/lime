package lime.tools;

import hxp.ObjectTools;

class LaunchStoryboard
{
	public var assetsPath:String;
	public var assets:Array<LaunchStoryboardAsset>;
	public var path:String;

	public var template:String;
	public var templateContext:Dynamic;

	public function new()
	{
		assets = [];
		templateContext = {};
	}

	public function clone():LaunchStoryboard
	{
		var launchStoryboard = new LaunchStoryboard();
		launchStoryboard.assetsPath = assetsPath;
		launchStoryboard.assets = assets.copy();
		launchStoryboard.path = path;
		launchStoryboard.template = template;
		launchStoryboard.templateContext = ObjectTools.copyFields(templateContext, {});

		return launchStoryboard;
	}

	public function merge(launchStoryboard:LaunchStoryboard):Void
	{
		if (launchStoryboard != null)
		{
			if (launchStoryboard.assetsPath != null) assetsPath = launchStoryboard.assetsPath;
			if (launchStoryboard.assets != null) assets = launchStoryboard.assets;
			if (launchStoryboard.path != null) path = launchStoryboard.path;
			if (launchStoryboard.template != null) template = launchStoryboard.template;
			if (launchStoryboard.templateContext != null) templateContext = launchStoryboard.templateContext;
		}
	}
}

class LaunchStoryboardAsset
{
	public var type:String;

	public function new(type:String)
	{
		this.type = type;
	}
}

class ImageSet extends LaunchStoryboardAsset
{
	public var name:String;
	public var width = 0;
	public var height = 0;

	public function new(name:String)
	{
		super("imageset");
		this.name = name;
	}
}
