package lime.tools;

import hxp.*;
#if (lime && lime_cffi && !macro)
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.utils.UInt8Array;
#end
import lime.tools.Platform;
import sys.io.File;
import sys.io.FileSeek;
import sys.FileSystem;

class ImageHelper
{
	public static function rasterizeSVG(path:String, width:Int, height:Int,
			backgroundColor:Int = null):#if (lime && lime_cffi && !macro) Image #else Dynamic #end
	{
		// public static function rasterizeSVG (svg:Dynamic /*SVG*/, width:Int, height:Int, backgroundColor:Int = null):Image {

		#if (lime && lime_cffi && !macro)
		if (path == null) return null;

		var temp = System.getTemporaryFile(".png");

		try
		{
			System.runCommand("", "neko", [
				Path.combine(Haxelib.getPath(new Haxelib(#if lime "lime" #else "hxp" #end)), "svg.n"),
				"process",
				path,
				Std.string(width),
				Std.string(height),
				temp
			], true, true);

			if (FileSystem.exists(temp))
			{
				var image = Image.fromFile(temp);

				try
				{
					FileSystem.deleteFile(temp);
				}
				catch (e:Dynamic) {}

				if (image.buffer != null)
				{
					return image;
				}
			}
		}
		catch (e:Dynamic) {}

		var rasterizer = Haxelib.getPath(new Haxelib("lime")) + "/templates/bin/batik/batik-rasterizer.jar";
		var args = [
			"-Dapple.awt.UIElement=true",
			"-jar",
			rasterizer,
			"-d",
			temp,
			"-w",
			Std.string(width),
			"-h",
			Std.string(height)
		];

		if (backgroundColor != null)
		{
			var a:Int = ((backgroundColor >> 24) & 0xFF);
			var r:Int = ((backgroundColor >> 16) & 0xFF);
			var g:Int = ((backgroundColor >> 8) & 0xFF);
			var b:Int = (backgroundColor & 0xFF);

			args.push("-bg");
			args.push(a + "." + r + "." + g + "." + b);
		}

		args.push(path);

		if (System.hostPlatform == MAC)
		{
			try
			{
				var found = false;

				if (FileSystem.exists("/System/Library/Java/JavaVirtualMachines"))
				{
					found = (FileSystem.readDirectory("/System/Library/Java/JavaVirtualMachines").length > 0);
				}

				if (!found && FileSystem.exists("/Library/Java/JavaVirtualMachines"))
				{
					found = (FileSystem.readDirectory("/Library/Java/JavaVirtualMachines").length > 0);
				}

				if (!found)
				{
					if (Log.verbose) Log.warn("Skipping SVG to PNG rasterization step, no Java runtime detected");

					return null;
				}
			}
			catch (e:Dynamic) {}
		}

		if (Log.verbose)
		{
			System.runCommand("", "java", args, true, true);
		}
		else
		{
			System.runProcess("", "java", args, true, true, true);
		}

		if (FileSystem.exists(temp))
		{
			var image = Image.fromFile(temp);

			try
			{
				FileSystem.deleteFile(temp);
			}
			catch (e:Dynamic) {}

			if (image.buffer != null)
			{
				return image;
			}
		}
		#end

		return null;
	}

	public static function readPNGImageSize(path:String)
	{
		var toReturn = {width: 0, height: 0};
		var fileInput = File.read(path);
		var header = (fileInput.readByte() << 8) | fileInput.readByte();

		if (header == 0x8950)
		{
			fileInput.seek(8 + 4 + 4, FileSeek.SeekBegin);

			var width = (fileInput.readByte() << 24) | (fileInput.readByte() << 16) | (fileInput.readByte() << 8) | fileInput.readByte();
			var height = (fileInput.readByte() << 24) | (fileInput.readByte() << 16) | (fileInput.readByte() << 8) | fileInput.readByte();

			toReturn =
				{
					width: width,
					height: height
				};
		}

		fileInput.close();

		return toReturn;
	}

	public static function resizeImage(image:#if (lime && lime_cffi && !macro) Image #else Dynamic #end, width:Int,
			height:Int):#if (lime && lime_cffi && !macro) Image #else Dynamic #end
	{
		#if (lime && lime_cffi && !macro)
		if (image == null) return null;

		if (image.width == width && image.height == height)
		{
			return image;
		}

		image.resize(width, height);
		#end

		return image;
	}
}
