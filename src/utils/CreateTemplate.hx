package utils;


import helpers.FileHelper;
import helpers.LogHelper;
import helpers.PathHelper;
import project.Haxelib;
import project.ProjectXMLParser;
import sys.FileSystem;


class CreateTemplate {
	
	
	public static function createExtension (words:Array <String>, userDefines:Map<String, Dynamic>):Void {
		
		var title = "Extension";
		
		if (words.length > 1) {
			
			title = words[1];
			
		}
		
		var file = StringTools.replace (title, " ", "");
		var extension = StringTools.replace (file, "-", "_");
		var className = extension.substr (0, 1).toUpperCase () + extension.substr (1);
		
		var context:Dynamic = { };
		context.file = file;
		context.extension = extension;
		context.className = className;
		context.extensionLowerCase = extension.toLowerCase ();
		context.extensionUpperCase = extension.toUpperCase ();
		
		PathHelper.mkdir (title);
		FileHelper.recursiveCopyTemplate ([ PathHelper.getHaxelib (new Haxelib ("lime-tools"), true)  + "/templates" ], "extension", title, context);
		
		if (FileSystem.exists (title + "/Extension.hx")) {
			
			FileSystem.rename (title + "/Extension.hx", title + "/" + className + ".hx");
			
		}
		
		if (FileSystem.exists (title + "/project/common/Extension.cpp")) {
			
			FileSystem.rename (title + "/project/common/Extension.cpp", title + "/project/common/" + file + ".cpp");
			
		}
		
		if (FileSystem.exists (title + "/project/include/Extension.h")) {
			
			FileSystem.rename (title + "/project/include/Extension.h", title + "/project/include/" + file + ".h");
			
		}
		
		if (FileSystem.exists (title)) {
			
			PathHelper.mkdir (title + "/ndll");
			PathHelper.mkdir (title + "/ndll/Linux");
			PathHelper.mkdir (title + "/ndll/Linux64");
			PathHelper.mkdir (title + "/ndll/Mac");
			PathHelper.mkdir (title + "/ndll/Mac64");
			PathHelper.mkdir (title + "/ndll/Windows");
			
		}
		
	}
	
	
	public static function createProject (words:Array <String>, userDefines:Map<String, Dynamic>):Void {
		
		var projectName = words[0].substring (0, words[0].indexOf (":"));
		var sampleName = words[0].substr (words[0].indexOf (":") + 1);
		
		var files = [ "include.lime", "include.nmml", "include.xml" ];
		var found = false;
		
		if (projectName == "") {
			
			projectName = "lime";
			
		}
		
		if (projectName != null && projectName != "" && sampleName == "project") {
			
			var path = PathHelper.getHaxelib (new Haxelib (projectName), true);
			
			for (file in files) {
				
				if (!found && FileSystem.exists (PathHelper.combine (path, file))) {
					
					found = true;
					path = PathHelper.combine (path, file);
					
				}
				
			}
			
			if (found) {
				
				var project = new ProjectXMLParser (path);
				var id = [ "com", "example", "project" ];
				
				if (words.length > 1) {
					
					var name = words[1];
					name = new EReg ("[^a-zA-Z0-9.]", "g").replace (name, "");
					id = name.split (".");
					
					if (id.length < 3) {
						
						id = [ "com", "example" ].concat (id);
						
					}
					
				}
				
				var company = "Company Name";
				
				if (words.length > 2) {
					
					company = words[2];
					
				}
				
				var context:Dynamic = { };
				
				var name = words[1].split (".").pop ();
				var alphaNumeric = new EReg ("[a-zA-Z0-9]", "g");
				var title = "";
				var capitalizeNext = true;
				
				for (i in 0...name.length) {
					
					if (alphaNumeric.match (name.charAt (i))) {
						
						if (capitalizeNext) {
							
							title += name.charAt (i).toUpperCase ();
							
						} else {
							
							title += name.charAt (i);
							
						}
						
						capitalizeNext = false;
						
					} else {
						
						capitalizeNext = true;
						
					}
					
				}
				
				var packageName = id.join (".").toLowerCase ();
				
				context.title = title;
				context.packageName = packageName;
				context.version = "1.0.0";
				context.company = company;
				context.file = StringTools.replace (title, " ", "");
				
				for (define in userDefines.keys ()) {
					
					Reflect.setField (context, define, userDefines.get (define));
					
				}
				
				var folder = name;
				
				PathHelper.mkdir (folder);
				FileHelper.recursiveCopyTemplate (project.templatePaths, "project", folder, context);
				
				if (FileSystem.exists (folder + "/Project.hxproj")) {
					
					FileSystem.rename (folder + "/Project.hxproj", folder + "/" + title + ".hxproj");
					
				}
				
			}
			
			return;
			
		}
		
		LogHelper.error ("Could not find project \"" + projectName + "\"");
	
	}
	
	
	public static function createSample (words:Array <String>, userDefines:Map<String, Dynamic>) {
		
		var projectName = words[0].substring (0, words[0].indexOf (":"));
		var sampleName = words[0].substr (words[0].indexOf (":") + 1);
		
		var files = [ "include.lime", "include.nmml", "include.xml" ];
		var found = false;
		
		if (projectName == "") {
			
			projectName = "lime";
			
		}
		
		if (projectName != null && projectName != "") {
			
			var path = PathHelper.getHaxelib (new Haxelib (projectName), true);
			
			if (sampleName != null && sampleName != "") {
				
				for (file in files) {
					
					if (!found && FileSystem.exists (PathHelper.combine (path, file))) {
						
						found = true;
						path = PathHelper.combine (path, file);
						
					}
					
				}
				
				if (found) {
					
					var defines = new Map <String, Dynamic> ();
					defines.set ("create", 1);
					
					var project = new ProjectXMLParser (path, defines);
					var samplePaths = project.samplePaths.copy ();
					samplePaths.reverse ();
					
					for (samplePath in samplePaths) {
						
						var sourcePath = PathHelper.combine (samplePath, sampleName);
						var targetName = sampleName;
						
						if (words.length > 1) {
							
							targetName = words[1];
							
						}
						
						if (FileSystem.exists (sourcePath)) {
							
							PathHelper.mkdir (targetName);
							FileHelper.recursiveCopy (sourcePath, PathHelper.tryFullPath (targetName));
							return;
							
						}
						
					}
					
				}
				
				LogHelper.error ("Could not find sample \"" + sampleName + "\" in project \"" + projectName + "\"");
				
			}
			
			LogHelper.error ("You must specify a sample name to copy when using \"lime create\"");
			
		}
		
		LogHelper.error ("You must specify a project name when using \"lime create\"");
		
	}
	
	
	public static function listSamples (projectName:String, userDefines:Map<String, Dynamic>) {
		
		Sys.println ("You must specify a template when using the 'create' command.");
		Sys.println ("");
		Sys.println ("Usage: lime create library:project \"com.package.name\" \"Company Name\"");
		Sys.println ("Usage: lime create library:sample \"OptionalOutputDirectory\"");
		Sys.println ("Usage: lime create extension \"ExtensionName\"");
		
		var files = [ "include.lime", "include.nmml", "include.xml" ];
		var found = false;
		
		if (projectName != null && projectName != "") {
			
			Sys.println ("");
			Sys.println (" Available samples: (" + projectName + ")");
			Sys.println ("");
			
			var path = PathHelper.getHaxelib (new Haxelib (projectName), true);
			
			for (file in files) {
				
				if (!found && FileSystem.exists (PathHelper.combine (path, file))) {
					
					found = true;
					path = PathHelper.combine (path, file);
					
				}
				
			}
			
			if (found) {
				
				var defines = new Map <String, Dynamic> ();
				defines.set ("create", 1);
				
				var project = new ProjectXMLParser (path, defines);
				var samplePaths = project.samplePaths.copy ();
				
				if (samplePaths.length > 0) {
					
					samplePaths.reverse ();
					
					for (samplePath in samplePaths) {
						
						var path = PathHelper.tryFullPath (samplePath);
						
						for (name in FileSystem.readDirectory (path)) {
							
							if (!StringTools.startsWith (name, ".") && FileSystem.isDirectory (path + "/" + name)) {
								
								Sys.println ("  - " + name);
								
							}
							
						}
						
					}
					
					Sys.println ("");
					
				} else {
					
					Sys.println ("  (None)");
					Sys.println ("");
					
				}
				
			}
			
		}
		
	}
	
	
}