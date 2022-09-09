import hxp.*;

class Build extends Script
{
	public function new()
	{
		super();

		var base = new HXML(
			{
				defines: ["display", "doc-gen", "lime-doc-gen"],
				classNames: ["ImportAll"],
				libs: ["lime"],
				noOutput: true
			});

		var flash = base.clone();
		flash.xml = "xml/Flash.xml";
		flash.swf = "obj/docs";
		flash.swfVersion = "17.0";
		flash.build();

		var native = base.clone();
		native.cpp = "obj/docs";
		native.define("native");
		native.define("lime-cffi");

		var windows = native.clone();
		windows.xml = "xml/Windows.xml";
		windows.define("windows");
		windows.build();

		var mac = native.clone();
		mac.xml = "xml/macOS.xml";
		mac.define("mac");
		mac.build();

		var linux = native.clone();
		linux.xml = "xml/Linux.xml";
		linux.define("linux");
		linux.build();

		var ios = native.clone();
		ios.xml = "xml/iOS.xml";
		ios.define("ios");
		ios.build();

		var android = native.clone();
		android.xml = "xml/Android.xml";
		android.define("android");
		android.build();

		var html5 = base.clone();
		html5.xml = "xml/HTML5.xml";
		html5.js = "obj/docs";
		html5.define("html5");
		html5.build();

		System.runCommand("", "haxelib", [
			"run",
			"dox",
			"-i",
			"xml",
			"-in",
			"lime",
			"--title",
			"Lime API Reference",
			"-D",
			"source-path",
			"https://github.com/openfl/lime/tree/develop/src/",
			"-D",
			"website",
			"https://lime.openfl.org",
			"-D",
			"textColor",
			"0x777777",
			"-theme",
			"../assets/docs-theme",
			"--toplevel-package",
			"lime"
		]);
	}
}
