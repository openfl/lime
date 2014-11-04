package helpers;


//import openfl.display.Bitmap;
//import openfl.display.BitmapData;
//import openfl.display.Shape;
//import openfl.geom.Matrix;
import lime.graphics.Image;
import project.Haxelib;
import project.Platform;
import sys.FileSystem;
//import format.SVG;


class ImageHelper {
	
	
	public static function rasterizeSVG (path:String, width:Int, height:Int, backgroundColor:Int = null):Image {
	//public static function rasterizeSVG (svg:Dynamic /*SVG*/, width:Int, height:Int, backgroundColor:Int = null):Image {
		
		var rasterizer = PathHelper.getHaxelib (new Haxelib ("lime")) + "/templates/bin/batik/batik-rasterizer.jar";
		var temp = PathHelper.getTemporaryFile (".png");
		var args = [ "-Dapple.awt.UIElement=true", "-jar", rasterizer, "-d", temp, "-w", Std.string (width), "-h", Std.string (height) ];
		
		if (backgroundColor != null) {
			
			var a:Int = (( backgroundColor >> 24) & 0xFF);
			var r:Int = (( backgroundColor >> 16) & 0xFF);
			var g:Int = (( backgroundColor >> 8) & 0xFF);
			var b:Int = (backgroundColor & 0xFF);
			
			args.push ("-bg");
			args.push (a + "." + r + "." + g + "." + b);
			
		}
		
		args.push (path);
		
		if (PlatformHelper.hostPlatform == Platform.MAC) {
			
			try {
				
				var found = false;
				
				if (FileSystem.exists ("/System/Library/Java/JavaVirtualMachines")) {
					
					found = (FileSystem.readDirectory ("/System/Library/Java/JavaVirtualMachines").length > 0);
					
				}
				
				if (!found && FileSystem.exists ("/Library/Java/JavaVirtualMachines")) {
					
					found = (FileSystem.readDirectory ("/Library/Java/JavaVirtualMachines").length > 0);
					
				}
				
				if (!found) {
					
					if (LogHelper.verbose) LogHelper.warn ("Skipping SVG to PNG rasterization step, no Java runtime detected");
					
					return null;
					
				}
				
			} catch (e:Dynamic) {}
			
		}
		
		if (LogHelper.verbose) {
			
			ProcessHelper.runCommand ("", "java", args, true, true);
			
		} else {
			
			ProcessHelper.runProcess ("", "java", args, true, true, true);
			
		}
		
		if (FileSystem.exists (temp)) {
			
			var image = Image.fromFile (temp);
			
			try {
				
				FileSystem.deleteFile (temp);
				
			} catch (e:Dynamic) {}
			
			if (image.buffer != null) {
				
				return image;
				
			}
			
		}
		
		return null;
		
		/*if (backgroundColor == null) {
			
			backgroundColor = 0x00FFFFFF;
			
		}
		
		var shape = new Shape ();
		svg.render (shape.graphics, 0, 0, width, height);
		
		var bitmapData = new BitmapData (width, height, true, backgroundColor);
		bitmapData.draw (shape);
		
		return bitmapData;*/
		
	}
	
	
	public static function resizeImage (image:Image, width:Int, height:Int):Image {
		
		if (image.width == width && image.height == height) {
			
			return image;
			
		}
		
		image.resize (width, height);
		
		return image;
		
	}
	
	
}