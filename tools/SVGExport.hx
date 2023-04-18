package;

import format.SVG;
import hxp.*;
import lime.tools.Architecture;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.display.Shape;
import openfl.geom.Matrix;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class SVGExport
{
	#if (neko && (haxe_210 || haxe3))
	public static function __init__()
	{
		var haxePath = Sys.getEnv("HAXEPATH");
		var command = (haxePath != null && haxePath != "") ? haxePath + "/haxelib" : "haxelib";

		var path = "";

		if (FileSystem.exists("svg.n"))
		{
			path = Path.combine(Sys.getCwd(), "../ndll/");
		}

		if (path == "")
		{
			var process = new Process("haxelib", ["path", "lime"]);

			try
			{
				while (true)
				{
					var line = StringTools.trim(process.stdout.readLine());

					if (StringTools.startsWith(line, "-L "))
					{
						path = StringTools.trim(line.substr(2));
						break;
					}
				}
			}
			catch (e:Dynamic) {}

			process.close();
		}

		switch (System.hostPlatform)
		{
			case WINDOWS:
				// var is64 = neko.Lib.load("std", "sys_is64", 0)();
				untyped $loader.path = $array(path + "Windows/", $loader.path);
				// if (CFFI.enabled)
				// {
				try
				{
					neko.Lib.load("lime", "lime_application_create", 0);
				}
				catch (e:Dynamic)
				{
					untyped $loader.path = $array(path + "Windows64/", $loader.path);
				}
			// }

			case MAC:
				untyped $loader.path = $array(path + "Mac/", $loader.path);
				untyped $loader.path = $array(path + "Mac64/", $loader.path);

			case LINUX:
				var arguments = Sys.args();
				var raspberryPi = false;

				for (argument in arguments)
				{
					if (argument == "-rpi") raspberryPi = true;
				}

				if (raspberryPi)
				{
					untyped $loader.path = $array(path + "RPi/", $loader.path);
				}
				else if (System.hostArchitecture == X64)
				{
					untyped $loader.path = $array(path + "Linux64/", $loader.path);
				}
				else
				{
					untyped $loader.path = $array(path + "Linux/", $loader.path);
				}

			default:
		}
	}
	#end

	public static function main()
	{
		var arguments = Sys.args();

		/*if (arguments.length > 0) {

			// When the command-line tools are called from haxelib,
			// the last argument is the project directory and the
			// path SWF is the current working directory

			var lastArgument = "";

			for (i in 0...arguments.length) {

				lastArgument = arguments.pop ();
				if (lastArgument.length > 0) break;

			}

			lastArgument = new Path (lastArgument).toString ();

			if (((StringTools.endsWith (lastArgument, "/") && lastArgument != "/") || StringTools.endsWith (lastArgument, "\\")) && !StringTools.endsWith (lastArgument, ":\\")) {

				lastArgument = lastArgument.substr (0, lastArgument.length - 1);

			}

			if (FileSystem.exists (lastArgument) && FileSystem.isDirectory (lastArgument)) {

				Sys.setCwd (lastArgument);

			}

		}*/

		var words = new Array<String>();

		for (arg in arguments)
		{
			if (arg == "-verbose")
			{
				Log.verbose = true;
			}
			else
			{
				words.push(arg);
			}
		}

		if (words.length > 4 && words[0] == "process")
		{
			try
			{
				var inputPath = words[1];
				var width = Std.parseInt(words[2]);
				var height = Std.parseInt(words[3]);
				var outputPath = words[4];

				var svg = new SVG(File.getContent(inputPath));
				var backgroundColor = 0x00FFFFFF;

				var shape = new Shape();
				svg.render(shape.graphics, 0, 0, width, height);

				var bitmapData = new BitmapData(width, height, true, backgroundColor);
				bitmapData.draw(shape);

				File.saveBytes(outputPath, bitmapData.encode(bitmapData.rect, new PNGEncoderOptions()));
			}
			catch (e:Dynamic)
			{
				Log.error(e);
			}
		}
	}
}
