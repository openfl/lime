package lime.tools.helpers;


import haxe.Json;
import lime.project.Architecture;
import lime.project.Haxelib;
import lime.project.Platform;
import sys.io.File;
import sys.FileSystem;


class HaxelibHelper {
	
	
	public static var pathOverrides = new Map<String, String> ();
	
	private static var repositoryPath:String;
	private static var paths = new Map<String, String> ();
	private static var versions = new Map<String, String> ();
	
	
	public static function getRepositoryPath ():String {
		
		if (repositoryPath == null) {
			
			var cache = LogHelper.verbose;
			LogHelper.verbose = false;
			var output = "";
			
			try {
				
				var cacheDryRun = ProcessHelper.dryRun;
				ProcessHelper.dryRun = false;
				
				output = ProcessHelper.runProcess (Sys.getEnv ("HAXEPATH"), "haxelib", [ "config" ], true, true, true);
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
		
		if (haxelib.version != "") {
			
			name += ":" + haxelib.version;
			
		}
		
		if (pathOverrides.exists (name)) {
			
			if (!versions.exists (name)) {
				
				versions.set (haxelib.name, haxelib.version);
				versions.set (name, haxelib.version);
				
			}
			
			return pathOverrides.get (name);
			
		}
		
		if (clearCache) {
			
			paths.remove (name);
			versions.remove (name);
			
		}
		
		if (!paths.exists (name)) {
			
			var libraryPath = PathHelper.combine (getRepositoryPath (), haxelib.name);
			var result = "";
			
			if (FileSystem.exists (libraryPath)) {
				
				var devPath = PathHelper.combine (libraryPath, ".dev");
				var currentPath = PathHelper.combine (libraryPath, ".current");
				
				if (haxelib.version != "") {
					
					if (FileSystem.exists (devPath)) {
						
						result = StringTools.trim (File.getContent (devPath));
						
						if (!FileSystem.exists (result) || getPathVersion (result) != haxelib.version) {
							
							result = PathHelper.combine (libraryPath, StringTools.replace (haxelib.version, ".", ","));
							
						}
						
					} else {
						
						result = PathHelper.combine (libraryPath, StringTools.replace (haxelib.version, ".", ","));
						
					}
					
				} else {
					
					if (FileSystem.exists (devPath)) {
						
						result = StringTools.trim (File.getContent (devPath));
						
					} else {
						
						result = StringTools.trim (File.getContent (currentPath));
						result = PathHelper.combine (libraryPath, StringTools.replace (result, ".", ","));
						
					}
					
				}
				
				if (!FileSystem.exists (result)) result = "";
				
			}
			
			if (validate && result == "") {
				
				if (haxelib.version != "") {
					
					LogHelper.error ("Could not find haxelib \"" + haxelib.name + "\" version \"" + haxelib.version + "\", does it need to be installed?");
					
				} else {
					
					LogHelper.error ("Could not find haxelib \"" + haxelib.name + "\", does it need to be installed?");
					
				}
				
			}
			
			// if (validate) {
				
			// 	if (result == "") {
					
			// 		if (output.indexOf ("does not have") > -1) {
						
			// 			var directoryName = "";
						
			// 			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
							
			// 				directoryName = "Windows";
							
			// 			} else if (PlatformHelper.hostPlatform == Platform.MAC) {
							
			// 				directoryName = PlatformHelper.hostArchitecture == Architecture.X64 ? "Mac64" : "Mac";
							
			// 			} else {
							
			// 				directoryName = PlatformHelper.hostArchitecture == Architecture.X64 ? "Linux64" : "Linux";
							
			// 			}
						
			// 			LogHelper.error ("haxelib \"" + haxelib.name + "\" does not have an \"ndll/" + directoryName + "\" directory");
						
			// 		} else if (output.indexOf ("haxelib install ") > -1 && output.indexOf ("haxelib install " + haxelib.name) == -1) {
						
			// 			var start = output.indexOf ("haxelib install ") + 16;
			// 			var end = output.lastIndexOf ("'");
			// 			var dependencyName = output.substring (start, end);
						
			// 			LogHelper.error ("Could not find haxelib \"" + dependencyName + "\" (dependency of \"" + haxelib.name + "\"), does it need to be installed?");
						
			// 		} else {
						
			// 			if (haxelib.version != "") {
							
			// 				LogHelper.error ("Could not find haxelib \"" + haxelib.name + "\" version \"" + haxelib.version + "\", does it need to be installed?");
							
			// 			} else {
							
			// 				LogHelper.error ("Could not find haxelib \"" + haxelib.name + "\", does it need to be installed?");
							
			// 			}
						
			// 		}
					
			// 	}
				
			// }
			
			paths.set (name, result);
			
			if (haxelib.version != "") {
				
				paths.set (haxelib.name, result);
				
				versions.set (name, haxelib.version);
				versions.set (haxelib.name, haxelib.version);
				
			} else {
				
				versions.set (name, getPathVersion (result));
				
			}
			
		}
		
		return paths.get (name);
		
	}
	
	
	public static function getPathVersion (path:String):String {
		
		path = PathHelper.combine (path, "haxelib.json");
		
		if (FileSystem.exists (path)) {
			
			var json = Json.parse (File.getContent (path));
			return json.version;
			
		}
		
		return "";
		
	}
	
	
	public static function getVersion (haxelib:Haxelib = null):String {
		
		var clearCache = false;
		
		if (haxelib == null) {
			
			haxelib = new Haxelib ("lime");
			clearCache = true;
			
		}
		
		if (haxelib.version != "") {
			
			return haxelib.version;
			
		}
		
		getPath (haxelib, true, clearCache);
		
		return versions.get (haxelib.name);
		
	}
	
	
	public static function setOverridePath (haxelib:Haxelib, path:String):Void {
		
		var name = haxelib.name;
		var version = haxelib.version;
		
		if (version == "") {
			
			version = getPathVersion (path);
			
		}
		
		pathOverrides.set (name, path);
		pathOverrides.set (name + ":" + version, path);
		versions.set (name, version);
		versions.set (name + ":" + version, version);
		
	}
	
	
}