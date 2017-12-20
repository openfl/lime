package lime.tools.helpers;


import haxe.Json;
import lime.project.Architecture;
import lime.project.Haxelib;
import lime.project.Platform;
import lime.project.Version;
import sys.io.File;
import sys.FileSystem;


class HaxelibHelper {
	
	
	public static var debug = false;
	public static var pathOverrides = new Map<String, String> ();
	public static var workingDirectory = "";
	
	private static var repositoryPath:String;
	private static var paths = new Map<String, String> ();
	private static var toolPath = null;
	private static var versions = new Map<String, Version> ();
	
	
	public static function findFolderMatch (haxelib:Haxelib, directory:String):Version {
		
		var versions = new Array<Version> ();
		var version:Version;
		
		try {
			
			for (file in FileSystem.readDirectory (directory)) {
				
				try {
					
					version = StringTools.replace (file, ",", ".");
					versions.push (version);
					
				} catch (e:Dynamic) {}
				
			}
			
		} catch (e:Dynamic) {}
		
		return findMatch (haxelib, versions);
		
	}
	
	
	public static function findMatch (haxelib:Haxelib, otherVersions:Array<Version>):Version {
		
		var matches = [];
		
		for (otherVersion in otherVersions) {
			
			if (haxelib.versionMatches (otherVersion)) {
				
				matches.push (otherVersion);
				
			}
			
		}
		
		if (matches.length == 0) return null;
		
		var bestMatch = null;
		
		for (match in matches) {
			
			if (bestMatch == null || match > bestMatch) {
				
				bestMatch = match;
				
			}
			
		}
		
		return bestMatch;
		
	}
	
	
	public static function getRepositoryPath (clearCache:Bool = false):String {
		
		if (repositoryPath == null || clearCache) {
			
			var cache = LogHelper.verbose;
			LogHelper.verbose = debug;
			var output = "";
			
			try {
				
				var cacheDryRun = ProcessHelper.dryRun;
				ProcessHelper.dryRun = false;
				output = HaxelibHelper.runProcess (workingDirectory, [ "config" ], true, true, true);
				if (output == null) output = "";
				
				ProcessHelper.dryRun = cacheDryRun;
				
			} catch (e:Dynamic) { }
			
			LogHelper.verbose = cache;
			
			repositoryPath = StringTools.trim (output);
			
		}
		
		return repositoryPath;
		
	}
	
	
	public static function getPath (haxelib:Haxelib, validate:Bool = false, clearCache:Bool = false):String {
		
		var name = haxelib.name;
		
		if (pathOverrides.exists (name)) {
			
			if (!versions.exists (name)) {
				
				versions.set (name, getPathVersion (pathOverrides.get (name)));
				
			}
			
			return pathOverrides.get (name);
			
		}
		
		if (haxelib.version != null && haxelib.version != "") {
			
			name += ":" + haxelib.version;
			
		}
		
		if (pathOverrides.exists (name)) {
			
			if (!versions.exists (name)) {
				
				var version = getPathVersion (pathOverrides.get (name));
				versions.set (haxelib.name, version);
				versions.set (name, version);
				
			}
			
			return pathOverrides.get (name);
			
		}
		
		if (clearCache) {
			
			paths.remove (name);
			versions.remove (name);
			
		}
		
		if (!paths.exists (name)) {
			
			var cache = LogHelper.verbose;
			LogHelper.verbose = debug;
			var output = "";
			
			try {
				
				var cacheDryRun = ProcessHelper.dryRun;
				ProcessHelper.dryRun = false;
				
				output = HaxelibHelper.runProcess (workingDirectory, [ "path", name ], true, true, true);
				if (output == null) output = "";
				
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
			
			/*var libraryPath = PathHelper.combine (getRepositoryPath (), haxelib.name);
			var result = "";
			
			if (FileSystem.exists (libraryPath)) {
				
				var devPath = PathHelper.combine (libraryPath, ".dev");
				var currentPath = PathHelper.combine (libraryPath, ".current");
				var matched = false, version;
				
				if (haxelib.version != "" && haxelib.version != null) {
					
					if (FileSystem.exists (devPath)) {
						
						result = StringTools.trim (File.getContent (devPath));
						
						if (FileSystem.exists (result)) {
							
							version = getPathVersion (result);
							
							if (haxelib.version == "dev" || haxelib.versionMatches (version)) {
								
								matched = true;
								
							}
							
						}
						
					}
					
					if (!matched) {
						
						var match = findFolderMatch (haxelib, libraryPath);
						
						if (match != null) {
							
							result = PathHelper.combine (libraryPath, StringTools.replace (match, ".", ","));
							
						} else {
							
							result = "";
							
						}
						
					}
					
				} else {
					
					if (FileSystem.exists (devPath)) {
						
						result = StringTools.trim (File.getContent (devPath));
						
					} else {
						
						result = StringTools.trim (File.getContent (currentPath));
						result = PathHelper.combine (libraryPath, StringTools.replace (result, ".", ","));
						
					}
					
				}
				
				if (result == null) result == "";
				if (result != "" && !FileSystem.exists (result)) result = "";
				
			}
			
			if (validate && result == "") {
				
				if (haxelib.version != "") {
					
					LogHelper.error ("Could not find haxelib \"" + haxelib.name + "\" version \"" + haxelib.version + "\", does it need to be installed?");
					
				} else {
					
					LogHelper.error ("Could not find haxelib \"" + haxelib.name + "\", does it need to be installed?");
					
				}
				
			}*/
			
			var standardizedPath = PathHelper.standardize (result, false);
			var pathSplit = standardizedPath.split ("/");
			var hasHaxelibJSON = false;
			
			while (!hasHaxelibJSON && pathSplit.length > 0) {
				
				var path = pathSplit.join ("/");
				var jsonPath = PathHelper.combine (path, "haxelib.json");
				
				if (FileSystem.exists (jsonPath)) {
					
					paths.set (name, path);
					
					if (haxelib.version != "" && haxelib.version != null) {
						
						paths.set (haxelib.name, path);
						var version = getPathVersion (path);
						
						versions.set (name, version);
						versions.set (haxelib.name, version);
						
					} else {
						
						versions.set (name, getPathVersion (path));
						
					}
					
					hasHaxelibJSON = true;
					
				} else {
					
					pathSplit.pop ();
					
				}
				
			}
			
			if (!hasHaxelibJSON) {
				
				paths.set (name, result);
				
			}
			
		}
		
		return paths.get (name);
		
	}
	
	
	public static function getPathVersion (path:String):Version {
		
		path = PathHelper.combine (path, "haxelib.json");
		
		if (FileSystem.exists (path)) {
			
			try {
				
				var json = Json.parse (File.getContent (path));
				var versionString:String = json.version;
				var version:Version = versionString;
				return version;
				
			} catch (e:Dynamic) {}
			
		}
		
		return null;
		
	}
	
	
	public static function getVersion (haxelib:Haxelib = null):Version {
		
		var clearCache = false;
		
		if (haxelib == null) {
			
			haxelib = new Haxelib ("lime");
			clearCache = true;
			
		}
		
		getPath (haxelib, true, clearCache);
		
		//if (haxelib.version != "") {
			
			//return haxelib.version;
			
		//}
		
		return versions.get (haxelib.name);
		
	}
	
	
	public static function runCommand (path:String, args:Array<String>, safeExecute:Bool = true, ignoreErrors:Bool = false, print:Bool = false):Int {
		
		if (pathOverrides.exists ("haxelib")) {
			
			var script = PathHelper.combine (pathOverrides.get ("haxelib"), "run.n");
			
			if (!FileSystem.exists (script)) {
				
				LogHelper.error ("Cannot find haxelib script: " + script);
				
			}
			
			return ProcessHelper.runCommand (path, "neko", [ script ].concat (args), safeExecute, ignoreErrors, print);
			
		} else {
			
			// var haxe = Sys.getEnv ("HAXEPATH");
			var command = "haxelib";
			
			// if (haxe != null) {
				
			// 	command = PathHelper.combine (haxe, command);
				
			// }
			
			return ProcessHelper.runCommand (path, command, args, safeExecute, ignoreErrors, print);
			
		}
		
	}
	
	
	public static function runProcess (path:String, args:Array<String>, waitForOutput:Bool = true, safeExecute:Bool = true, ignoreErrors:Bool = false, print:Bool = false, returnErrorValue:Bool = false):String {
		
		if (pathOverrides.exists ("haxelib")) {
			
			var script = PathHelper.combine (pathOverrides.get ("haxelib"), "run.n");
			
			if (!FileSystem.exists (script)) {
				
				LogHelper.error ("Cannot find haxelib script: " + script);
				
			}
			
			return ProcessHelper.runProcess (path, "neko", [ script ].concat (args), waitForOutput, safeExecute, ignoreErrors, print, returnErrorValue);
			
		} else {
			
			// var haxe = Sys.getEnv ("HAXEPATH");
			var command = "haxelib";
			
			// if (haxe != null) {
				
			// 	command = PathHelper.combine (haxe, command);
				
			// }
			
			return ProcessHelper.runProcess (path, command, args, waitForOutput, safeExecute, ignoreErrors, print, returnErrorValue);
			
		}
		
	}
	
	
	public static function setOverridePath (haxelib:Haxelib, path:String):Void {
		
		var name = haxelib.name;
		var version = getPathVersion (path);
		
		pathOverrides.set (name, path);
		pathOverrides.set (name + ":" + version, path);
		
		versions.set (name, version);
		versions.set (name + ":" + version, version);
		
	}
	
	
}