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

		// An SVG sized only by its viewBox is drawn by svg.n at a default size, so most of the icon
		// lands outside the image. Rasterize a copy given the viewBox's width and height instead.
		var sizedPath = sizeFromViewBox(path);
		var image = rasterizeSVGFile(sizedPath != null ? sizedPath : path, width, height, backgroundColor);

		if (sizedPath != null)
		{
			try
			{
				FileSystem.deleteFile(sizedPath);
			}
			catch (e:Dynamic) {}
		}

		return image;
		#else
		return null;
		#end
	}

	/**
		Returns a temporary copy of the SVG at `path` with `width` and `height` taken from its
		`viewBox`, or null when the root sets either one or has no usable `viewBox`.
	**/
	private static function sizeFromViewBox(path:String):String
	{
		try
		{
			var xml = Xml.parse(File.getContent(path));
			var root = xml.firstElement();
			if (root == null || root.get("width") != null || root.get("height") != null) return null;

			var viewBox = root.get("viewBox");
			if (viewBox == null) return null;

			var values = [for (value in ~/[\s,]+/g.split(StringTools.trim(viewBox))) Std.parseFloat(value)];
			if (values.length != 4 || Math.isNaN(values[2]) || Math.isNaN(values[3]) || values[2] <= 0 || values[3] <= 0) return null;

			root.set("width", Std.string(values[2]));
			root.set("height", Std.string(values[3]));

			var sized = System.getTemporaryFile(".svg");
			File.saveContent(sized, xml.toString());
			return sized;
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	private static function rasterizeSVGFile(path:String, width:Int, height:Int,
			backgroundColor:Int = null):#if (lime && lime_cffi && !macro) Image #else Dynamic #end
	{
		#if (lime && lime_cffi && !macro)
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
