package helpers;


import haxe.io.Bytes;
import haxe.io.Path;
import haxe.Template;
import helpers.StringHelper;
import project.Asset;
import project.AssetEncoding;
import project.NDLL;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
import neko.Lib;


class FileHelper {
	
	
	private static var binaryExtensions = [ "jpg", "jpeg", "png", "exe", "gif", "ini", "zip", "tar", "gz", "fla", "swf" ];
	private static var textExtensions = [ "xml", "java", "hx", "hxml", "html", "ini", "gpe", "pch", "pbxproj", "plist", "json", "cpp", "mm", "properties", "hxproj", "nmml", "lime" ];
	
	
	public static function copyAsset (asset:Asset, destination:String, context:Dynamic = null) {
		
		if (asset.sourcePath != "") {
			
			copyFile (asset.sourcePath, destination, context);
			
		} else {
			
			if (asset.encoding == AssetEncoding.BASE64) {
				
				File.saveBytes (destination, StringHelper.base64Decode (asset.data));
				
			} else if (Std.is (asset.data, Bytes)) {
				
				File.saveBytes (destination, cast asset.data);
				
			} else {
				
				File.saveContent (destination, Std.string (asset.data));
				
			}
			
		}
		
	}
	
	
	public static function copyAssetIfNewer (asset:Asset, destination:String) {
		
		if (asset.sourcePath != "") {
			
			if (isNewer (asset.sourcePath, destination)) {
				
				copyFile (asset.sourcePath, destination, null, false);
				
			}
			
		} else {
			
			PathHelper.mkdir (Path.directory (destination));
			
			if (asset.encoding == AssetEncoding.BASE64) {
				
				File.saveBytes (destination, StringHelper.base64Decode (asset.data));
				
			} else if (Std.is (asset.data, Bytes)) {
				
				File.saveBytes (destination, cast asset.data);
				
			} else {
				
				File.saveContent (destination, Std.string (asset.data));
				
			}
			
		}
		
	}
	
	
	public static function copyFile (source:String, destination:String, context:Dynamic = null, process:Bool = true) {
		
		var extension = Path.extension (source);
		
		if (process && context != null) {
			
			for (binary in binaryExtensions) {
				
				if (extension == binary) {
					
					copyIfNewer (source, destination);
					return;
					
				}
				
			}
			
			var match = false;
			
			for (text in textExtensions) {
				
				if (extension == text) {
					
					match = true;
					break;
					
				}
				
			}
			
			if (!match) {
				
				match = isText (source);
				
			}
			
			if (match) {
				
				LogHelper.info ("", " - \x1b[1mCopying template file:\x1b[0m " + source + " \x1b[3;37m->\x1b[0m " + destination);
				
				var fileContents:String = File.getContent (source);
				var template:Template = new Template (fileContents);
				var result:String = template.execute (context);
				var fileOutput:FileOutput = File.write (destination, true);
				fileOutput.writeString (result);
				fileOutput.close ();
				return;
				
			}
			
		}
		
		copyIfNewer (source, destination);
		
	}
	
	
	public static function copyFileTemplate (templatePaths:Array <String>, source:String, destination:String, context:Dynamic = null, process:Bool = true) {
		
		var path = PathHelper.findTemplate (templatePaths, source);
		
		if (path != null) {
			
			copyFile (path, destination, context, process);
			
		}
		
	}
	
	
	public static function copyIfNewer (source:String, destination:String) {
      
		//allFiles.push (destination);
		
		if (!isNewer (source, destination)) {
			
			return;
			
		}
		
		PathHelper.mkdir (Path.directory (destination));
		
		LogHelper.info ("", " - \x1b[1mCopying file:\x1b[0m " + source + " \x1b[3;37m->\x1b[0m " + destination);
		File.copy (source, destination);
		
	}
	
	
	public static function copyLibrary (ndll:NDLL, directoryName:String, namePrefix:String, nameSuffix:String, targetDirectory:String, allowDebug:Bool = false, targetSuffix:String = null) {
		
		var path = PathHelper.getLibraryPath (ndll, directoryName, namePrefix, nameSuffix, allowDebug);
		
		if (FileSystem.exists (path)) {
			
			var targetPath = PathHelper.combine (targetDirectory, namePrefix + ndll.name);
			
			if (targetSuffix != null) {
				
				targetPath += targetSuffix;
				
			} else {
				
				targetPath += nameSuffix;
				
			}
			
			PathHelper.mkdir (targetDirectory);
			LogHelper.info ("", " - \x1b[1mCopying library file:\x1b[0m " + path + " \x1b[3;37m->\x1b[0m " + targetPath);
			File.copy (path, targetPath);
			
		} else {
			
			LogHelper.error ("Source path \"" + path + "\" does not exist");
			
		}
		
	}
	
	
	public static function linkFile (source:String, destination:String, symbolic:Bool = true, overwrite:Bool = false) {
		
		if (!isNewer (source, destination)) {
			
			return;
			
		}
		
		if (FileSystem.exists (destination)) {
			
			FileSystem.deleteFile (destination);
			
		}
		
		if (!FileSystem.exists (destination)) {
			
			try {
				
				var command = "/bin/ln";
				var args = [];
				
				if (symbolic) {
					
					args.push ("-s");
					
				}
				
				if(overwrite){
					
					args.push("-f");
					
				}
				
				args.push (source);
				args.push (destination);
				
				ProcessHelper.runCommand (".", command, args);
				
			} catch (e:Dynamic) {}
			
		}
		
	}
	
	
	public static function recursiveCopy (source:String, destination:String, context:Dynamic = null, process:Bool = true) {
		
		PathHelper.mkdir (destination);
		
		var files:Array <String> = null;
		
		try {
			
			files = FileSystem.readDirectory (source);
			
		} catch (e:Dynamic) {
			
			LogHelper.error ("Could not find source directory \"" + source + "\"");
			
		}
		
		for (file in files) {
			
			if (file.substr (0, 1) != ".") {
				
				var itemDestination:String = destination + "/" + file;
				var itemSource:String = source + "/" + file;
				
				if (FileSystem.isDirectory (itemSource)) {
					
					recursiveCopy (itemSource, itemDestination, context, process);
					
				} else {
					
					copyFile (itemSource, itemDestination, context, process);
					
				}
				
			}
			
		}
		
	}
	
	
	public static function recursiveCopyTemplate (templatePaths:Array <String>, source:String, destination:String, context:Dynamic = null, process:Bool = true) {
		
		var paths = PathHelper.findTemplates (templatePaths, source);
		
		for (path in paths) {
			
			recursiveCopy (path, destination, context, process);
			
		}
		
	}
	
	
	public static function isNewer (source:String, destination:String):Bool {
		
		if (source == null || !FileSystem.exists (source)) {
			
			LogHelper.error ("Source path \"" + source + "\" does not exist");
			return false;
			
		}
		
		if (FileSystem.exists (destination)) {
			
			if (FileSystem.stat (source).mtime.getTime () < FileSystem.stat (destination).mtime.getTime ()) {
				
				return false;
				
			}
			
		}
		
		return true;
		
	}
	
	
	public static function isText (source:String):Bool {
		
		if (!FileSystem.exists (source)) {
			
			return false;
			
		}
		
		var input = File.read (source, true);
		
		var numChars = 0;
		var numBytes = 0;
		
		try {
			
			while (numBytes < 512) {
				
				var byte = input.readByte ();
				
				numBytes++;
				
				if (byte == 0) {
					
					input.close ();
					return false;
					
				}
				
				if ((byte > 8 && byte < 16) || (byte > 32 && byte < 256) || byte > 287) {
					
					numChars++;
					
				}
				
			}
			
		} catch (e:Dynamic) { }
		
		input.close ();
		
		if (numBytes == 0 || (numChars / numBytes) > 0.7) {
			
			return true;
			
		}
		
		return false;
		
	}
	

}
