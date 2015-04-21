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
	
	
	public static var haxelibOverrides = new Map<String, String> ();
	
	private static var haxelibPaths = new Map<String, String> ();
	
	
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
	
	
	public static function findTemplate (templatePaths:Array <String>, path:String, warnIfNotFound:Bool = true):String {
		
		var matches = findTemplates (templatePaths, path, warnIfNotFound);
		
		if (matches.length > 0) {
			
			return matches[matches.length - 1];
			
		}
		
		return null;
		
	}
	
	
	public static function findTemplates (templatePaths:Array <String>, path:String, warnIfNotFound:Bool = true):Array <String> {
		
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
		
		var name = haxelib.name;
		
		if (haxelibOverrides.exists (name)) {
			
			return haxelibOverrides.get (name);
			
		}
		
		if (haxelib.version != "") {
			
			name += ":" + haxelib.version;
			
		}
		
		if (clearCache) {
			
			haxelibPaths.remove (name);
			
		}
		
		if (!haxelibPaths.exists (name)) {
			
			var cache = LogHelper.verbose;
			LogHelper.verbose = false;
			var output = "";
			
			try {
				
				var cacheDryRun = ProcessHelper.dryRun;
				ProcessHelper.dryRun = false;
				
				output = ProcessHelper.runProcess (Sys.getEnv ("HAXEPATH"), "haxelib", [ "path", name ], true, true, true);
				
				ProcessHelper.dryRun = cacheDryRun;
				
			} catch (e:Dynamic) { }
			
			LogHelper.verbose = cache;
			
			var lines = output.split ("\n");
			var result = "";
			
			for (i in 1...lines.length) {
				
				var trim = StringTools.trim (lines[i]);
				
				if (trim == "-D " + haxelib.name || StringTools.startsWith (trim, "-D " + haxelib.name + "=")) {
					
					result = StringTools.trim (lines[i - 1]);
					
				}
				
			}
			
			if (result == "") {
				
				try {
					
					for (line in lines) {
						
						if (line != "" && line.substr (0, 1) != "-") {
							
							if (FileSystem.exists (line)) {
								
								result = line;
								break;
								
							}
							
						}
						
					}
					
				} catch (e:Dynamic) {}
				
			}
			
			if (validate) {
				
				if (result == "") {
					
					if (output.indexOf ("does not have") > -1) {
						
						var directoryName = "";
						
						if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
							
							directoryName = "Windows";
							
						} else if (PlatformHelper.hostPlatform == Platform.MAC) {
							
							directoryName = PlatformHelper.hostArchitecture == Architecture.X64 ? "Mac64" : "Mac";
							
						} else {
							
							directoryName = PlatformHelper.hostArchitecture == Architecture.X64 ? "Linux64" : "Linux";
							
						}
						
						LogHelper.error ("haxelib \"" + haxelib.name + "\" does not have an \"ndll/" + directoryName + "\" directory");
						
					} else if (output.indexOf ("haxelib install ") > -1 && output.indexOf ("haxelib install " + haxelib.name) == -1) {
						
						var start = output.indexOf ("haxelib install ") + 16;
						var end = output.lastIndexOf ("'");
						var dependencyName = output.substring (start, end);
						
						LogHelper.error ("Could not find haxelib \"" + dependencyName + "\" (dependency of \"" + haxelib.name + "\"), does it need to be installed?");
						
					} else {
						
						if (haxelib.version != "") {
							
							LogHelper.error ("Could not find haxelib \"" + haxelib.name + "\" version \"" + haxelib.version + "\", does it need to be installed?");
							
						} else {
							
							LogHelper.error ("Could not find haxelib \"" + haxelib.name + "\", does it need to be installed?");
							
						}
						
					}
					
				}
				
			}
			
			haxelibPaths.set (name, result);
			
		}
		
		return haxelibPaths.get (name);
		
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
			
			oldPath = Sys.getCwd ();
			Sys.setCwd (parts[0] + "\\");
			parts.shift ();
			
		}
		
		for (part in parts) {
			
			if (part != "." && part != "") {
				
				if (total != "" && total != "/") {
					
					total += "/";
					
				}
				
				total += part;
				
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
	
	
	public static function relocatePaths (paths:Array <String>, targetDirectory:String):Array <String> {
		
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