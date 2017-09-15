package lime.tools.helpers;


import haxe.io.Path;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.ProcessHelper;
import lime.project.Architecture;
import lime.project.Haxelib;
import lime.project.NDLL;
import lime.project.Platform;
import sys.io.Process;
import sys.FileSystem;


class PathHelper {
	
	
	public static function combine (firstPath:String, secondPath:String):String {
		
		if (firstPath == null || firstPath == "") {
			
			return secondPath;
			
		} else if (secondPath != null && secondPath != "") {
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				if (secondPath.indexOf (":") == 1) {
					
					return secondPath;
					
				}
				
			} else {
				
				if (secondPath.substr (0, 1) == "/") {
					
					return secondPath;
					
				}
				
			}
			
			var firstSlash = (firstPath.substr (-1) == "/" || firstPath.substr (-1) == "\\");
			var secondSlash = (secondPath.substr (0, 1) == "/" || secondPath.substr (0, 1) == "\\");
			
			if (firstSlash && secondSlash) {
				
				return firstPath + secondPath.substr (1);
				
			} else if (!firstSlash && !secondSlash) {
				
				return firstPath + "/" + secondPath;
				
			} else {
				
				return firstPath + secondPath;
				
			}
			
		} else {
			
			return firstPath;
			
		}
		
	}
	
	
	public static function escape (path:String):String {
		
		if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
			
			path = StringTools.replace (path, "\\ ", " ");
			path = StringTools.replace (path, " ", "\\ ");
			path = StringTools.replace (path, "\\'", "'");
			path = StringTools.replace (path, "'", "\\'");
			
		} else {
			
			path = StringTools.replace (path, "^,", ",");
			path = StringTools.replace (path, ",", "^,");
			path = StringTools.replace (path, "^ ", " ");
			path = StringTools.replace (path, " ", "^ ");
			
		}
		
		return expand (path);
		
	}
	
	
	public static function expand (path:String):String {
		
		if (path == null) {
			
			path = "";
			
		}
		
		if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
			
			if (StringTools.startsWith (path, "~/")) {
				
				path = Sys.getEnv ("HOME") + "/" + path.substr (2);
				
			}
			
		}
		
		return path;
		
	}
	
	
	public static function findTemplate (templatePaths:Array<String>, path:String, warnIfNotFound:Bool = true):String {
		
		var matches = findTemplates (templatePaths, path, warnIfNotFound);
		
		if (matches.length > 0) {
			
			return matches[matches.length - 1];
			
		}
		
		return null;
		
	}
	
	
	public static function findTemplateRecursive (templatePaths:Array<String>, path:String, warnIfNotFound:Bool = true, destinationPaths:Array<String> = null):Array<String> {
		
		var paths = findTemplates (templatePaths, path, warnIfNotFound);
		if (paths.length == 0) return null;
		
		try {
			
			if (FileSystem.isDirectory (paths[0])) {
				
				var templateFiles = new Array<String> ();
				var templateMatched = new Map<String, Bool> ();
				
				paths.reverse ();
				
				findTemplateRecursive_ (paths, "", templateFiles, templateMatched, destinationPaths);
				return templateFiles;
				
			}
			
		} catch (e:Dynamic) {}
		
		paths.splice (0, paths.length - 1);
		
		if (destinationPaths != null) {
			
			destinationPaths.push (paths[0]);
			
		}
		
		return paths;
		
	}
	
	
	private static function findTemplateRecursive_ (templatePaths:Array<String>, source:String, templateFiles:Array<String>, templateMatched:Map<String, Bool>, destinationPaths:Array<String>):Void {
		
		var files:Array<String>;
		
		for (templatePath in templatePaths) {
			
			try {
				
				files = FileSystem.readDirectory (PathHelper.combine (templatePath, source));
				
				for (file in files) {
					
					//if (file.substr (0, 1) != ".") {
						
						var itemSource = PathHelper.combine (source, file);
						
						if (!templateMatched.exists (itemSource)) {
							
							templateMatched.set (itemSource, true);
							var path = PathHelper.combine (templatePath, itemSource);
							
							if (FileSystem.isDirectory (path)) {
								
								findTemplateRecursive_ (templatePaths, itemSource, templateFiles, templateMatched, destinationPaths);
								
							} else {
								
								templateFiles.push (path);
								
								if (destinationPaths != null) {
									
									destinationPaths.push (itemSource);
									
								}
								
							}
							
						}
						
					//}
					
				}
				
			} catch (e:Dynamic) {}
			
		}
		
	}
	
	
	public static function findTemplates (templatePaths:Array<String>, path:String, warnIfNotFound:Bool = true):Array<String> {
		
		var matches = [];
		
		for (templatePath in templatePaths) {
			
			var targetPath = combine (templatePath, path);
			
			if (FileSystem.exists (targetPath)) {
				
				matches.push (targetPath);
				
			}
			
		}
		
		if (matches.length == 0 && warnIfNotFound) {
			
			LogHelper.warn ("Could not find template file: " + path);
			
		}
		
		return matches;
		
	}
	
	
	public static function getHaxelib (haxelib:Haxelib, validate:Bool = false, clearCache:Bool = false):String {
		
		return HaxelibHelper.getPath (haxelib, validate, clearCache);
		
	}
	
	
	public static function getLibraryPath (ndll:NDLL, directoryName:String, namePrefix:String = "", nameSuffix:String = ".ndll", allowDebug:Bool = false):String {
		
		var usingDebug = false;
		var path = "";
		
		if (allowDebug) {
			
			path = searchForLibrary (ndll, directoryName, namePrefix + ndll.name + "-debug" + nameSuffix);
			usingDebug = FileSystem.exists (path);
			
		}
		
		if (!usingDebug) {
			
			path = searchForLibrary (ndll, directoryName, namePrefix + ndll.name + nameSuffix);
			
		}
		
		return path;
		
	}
	
	
	public static function getTemporaryFile (extension:String = ""):String {
		
		var path = "";
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			path = Sys.getEnv ("TEMP");
			
		} else {
			
			path = Sys.getEnv ("TMPDIR");
			
			if (path == null) {
				
				path = "/tmp";
				
			}
			
		}
		
		path += "/temp_" + Math.round (0xFFFFFF * Math.random ()) + extension;
		
		if (FileSystem.exists (path)) {
			
			return getTemporaryFile (extension);
			
		}
		
		return path;
		
	}
	
	
	public static function getTemporaryDirectory ():String {
		
		var path = getTemporaryFile ();
		mkdir (path);
		return path;
		
	}
	
	
	public static function isAbsolute (path:String):Bool {
		
		if (StringTools.startsWith (path, "/") || StringTools.startsWith (path, "\\")) {
			
			return true;
			
		}
		
		return false;
		
	}
	
	
	public static function isRelative (path:String):Bool {
		
		return !isAbsolute (path);
		
	}
	
	
	public static function mkdir (directory:String):Void {
		
		directory = StringTools.replace (directory, "\\", "/");
		var total = "";
		
		if (directory.substr (0, 1) == "/") {
			
			total = "/";
			
		}
		
		var parts = directory.split("/");
		var oldPath = "";
		
		if (parts.length > 0 && parts[0].indexOf (":") > -1) {
			
			try {
				
				oldPath = Sys.getCwd ();
				Sys.setCwd (parts[0] + "\\");
				parts.shift ();
				
			} catch (e:Dynamic) {
				
				LogHelper.error ("Cannot create directory \"" + directory + "\"");
				
			}
			
		}
		
		for (part in parts) {
			
			if (part != "." && part != "") {
				
				if (total != "" && total != "/") {
					
					total += "/";
					
				}
				
				total += part;
				
				if (FileSystem.exists (total) && !FileSystem.isDirectory (total)) {
					
					LogHelper.info ("", " - \x1b[1mRemoving file:\x1b[0m " + total);
					
					FileSystem.deleteFile (total);
					
				}
				
				if (!FileSystem.exists (total)) {
					
					LogHelper.info ("", " - \x1b[1mCreating directory:\x1b[0m " + total);
					
					FileSystem.createDirectory (total);
					
				}
				
			}
			
		}
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
	}
	
	
	public static function readDirectory (directory:String, ignore:Array<String> = null, paths:Array<String> = null):Array<String> {
		
		if (FileSystem.exists (directory)) {
			
			if (paths == null) {
				
				paths = [];
				
			}
			
			var files;
			
			try {
				
				files = FileSystem.readDirectory (directory);
				
			} catch (e:Dynamic) {
				
				return paths;
				
			}
			
			for (file in FileSystem.readDirectory (directory)) {
				
				if (ignore != null) {
					
					var filtered = false;
					
					for (filter in ignore) {
						
						if (filter == file) {
							
							filtered = true;
							
						}
						
					}
					
					if (filtered) continue;
					
				}
				
				var path = directory + "/" + file;
				
				try {
					
					if (FileSystem.isDirectory (path)) {
						
						readDirectory (path, ignore, paths);
						
					} else {
						
						paths.push (path);
						
					}
					
				} catch (e:Dynamic) {
					
					return paths;
					
				}
				
			}
			
			return paths;
			
		}
		
		return null;
		
	}
	
	
	public static function relocatePath (path:String, targetDirectory:String):String {
		
		// this should be improved for target directories that are outside the current working path
		
		if (isAbsolute (path) || targetDirectory == "") {
			
			return path;
			
		} else if (isAbsolute (targetDirectory)) {
			
			return combine (Sys.getCwd (), path);
			
		} else {
			
			targetDirectory = StringTools.replace (targetDirectory, "\\", "/");
			
			var splitTarget = targetDirectory.split ("/");
			var directories = 0;
			
			while (splitTarget.length > 0) {
				
				switch (splitTarget.shift ()) {
					
					case ".", "":
						
						// ignore
					
					case "..":
						
						directories--;
						
					default:
						
						directories++;
						
				}
				
			}
			
			var adjust = "";
			
			for (i in 0...directories) {
				
				adjust += "../";
				
			}
			
			return adjust + path;
			
		}
		
	}
	
	
	public static function relocatePaths (paths:Array<String>, targetDirectory:String):Array<String> {
		
		var relocatedPaths = paths.copy ();
		
		for (i in 0...paths.length) {
			
			relocatedPaths[i] = relocatePath (paths[i], targetDirectory);
			
		}
		
		return relocatedPaths;
		
	}
	
	
	public static function removeDirectory (directory:String):Void {
		
		if (FileSystem.exists (directory)) {
			
			var files;
			
			try {
				
				files = FileSystem.readDirectory (directory);
				
			} catch (e:Dynamic) {
				
				return;
				
			}
			
			for (file in FileSystem.readDirectory (directory)) {
				
				var path = directory + "/" + file;
				
				try {
					
					if (FileSystem.isDirectory (path)) {
						
						removeDirectory (path);
						
					} else {
						
						FileSystem.deleteFile (path);
						
					}
					
				} catch (e:Dynamic) {}
				
			}
			
			LogHelper.info ("", " - \x1b[1mRemoving directory:\x1b[0m " + directory);
			
			try {
				
				FileSystem.deleteDirectory (directory);
				
			} catch (e:Dynamic) {}
			
		}
		
	}
	
	
	public static function safeFileName (name:String):String {
		
		var safeName = StringTools.replace (name, " ", "");
		return safeName;
		
	}
	
	
	private static function searchForLibrary (ndll:NDLL, directoryName:String, filename:String):String {
		
		if (ndll.path != null && ndll.path != "") {
			
			return ndll.path;
			
		} else if (ndll.haxelib == null) {
			
			if (ndll.extensionPath != null && ndll.extensionPath != "") {
				
				var subdirectory = "ndll/";
				
				if (ndll.subdirectory != null) {
					
					if (ndll.subdirectory != "") {
						
						subdirectory = ndll.subdirectory + "/";
						
					} else {
						
						subdirectory = "";
						
					}
					
				}
				
				return combine (ndll.extensionPath, subdirectory + directoryName + "/" + filename);
				
			} else {
				
				return filename;
				
			}
			
		} else if (ndll.haxelib.name == "hxcpp") {
			
			var extension = Path.extension (filename);
			
			if (extension == "a" || extension == "lib") {
				
				return combine (getHaxelib (ndll.haxelib, true), "lib/" + directoryName + "/" + filename);
				
			} else {
				
				return combine (getHaxelib (ndll.haxelib, true), "bin/" + directoryName + "/" + filename);
				
			}
			
		} else {
			
			var subdirectory = "ndll/";
			
			if (ndll.subdirectory != null) {
				
				if (ndll.subdirectory != "") {
					
					subdirectory = ndll.subdirectory + "/";
					
				} else {
					
					subdirectory = "";
					
				}
				
			}
			
			return combine (getHaxelib (ndll.haxelib, true), subdirectory + directoryName + "/" + filename);
			
		}
		
	}
	
	
	public static function standardize (path:String, trailingSlash:Bool = false):String {
		
		path = StringTools.replace (path, "\\", "/");
		path = StringTools.replace (path, "//", "/");
		path = StringTools.replace (path, "//", "/");
		
		if (!trailingSlash && StringTools.endsWith (path, "/")) {
			
			path = path.substr (0, path.length - 1);
			
		} else if (trailingSlash && !StringTools.endsWith (path, "/")) {
			
			path += "/";
			
		}
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS && path.charAt (1) == ":") {
			
			path = path.charAt (0).toUpperCase () + ":" + path.substr (2);
			
		}
		
		return path;
		
	}
	
	
	public static function tryFullPath (path:String):String {
		
		try {
			
			return FileSystem.fullPath (path);
			
		} catch (e:Dynamic) {
			
			return expand (path);
			
		}
		
	}
	
	
}
