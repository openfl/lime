package utils;


import helpers.FileHelper;
import helpers.LogHelper;
import helpers.PathHelper;
import project.Haxelib;
import project.HXProject;
import sys.FileSystem;


class CreateTemplate {
	
	
	public static function createExtension (words:Array <String>, userDefines:Map<String, Dynamic>):Void {
		
		var title = "SampleExtension";
		
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
		context.ANDROID_TARGET_SDK_VERSION = "::ANDROID_TARGET_SDK_VERSION::";
		
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
		
		if (FileSystem.exists (title + "/dependencies/android/src/org/haxe/extension/Extension.java")) {
			
			FileSystem.rename (title + "/dependencies/android/src/org/haxe/extension/Extension.java", title + "/dependencies/android/src/org/haxe/extension/" + file + ".java");
			
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
		
		if (projectName != null && projectName != "" && sampleName == "project") {
			
			var defines = new Map <String, Dynamic> ();
			defines.set ("create", 1);
			var project = HXProject.fromHaxelib (new Haxelib (projectName), defines);
			
			if (project != null) {
				
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
				
				/*if (words.length > 2) {
					
					company = words[2];
					
				}*/
				
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
				
				if (words.length > 2) {
					
					folder = PathHelper.tryFullPath (words[2]);
					
				}
				
				PathHelper.mkdir (folder);
				FileHelper.recursiveCopyTemplate (project.templatePaths, "project", folder, context);
				
				if (FileSystem.exists (folder + "/Project.hxproj")) {
					
					FileSystem.rename (folder + "/Project.hxproj", folder + "/" + title + ".hxproj");
					
				}
				
				return;
				
			}
			
		}
		
		LogHelper.error ("Could not find project \"" + projectName + "\"");
	
	}
	
	
	public static function createSample (words:Array <String>, userDefines:Map<String, Dynamic>) {
		
		var projectName = words[0].substring (0, words[0].indexOf (":"));
		var sampleName = words[0].substr (words[0].indexOf (":") + 1);
		
		if (projectName == null && projectName == "") {
			
			LogHelper.error ("You must specify a project name when using \"lime create\"");
			return;
			
		}
		
		if (sampleName == null || sampleName == "") {
			
			LogHelper.error ("You must specify a sample name to copy when using \"lime create\"");
			return;
			
		}
		
		var defines = new Map <String, Dynamic> ();
		defines.set ("create", 1);
		var project = HXProject.fromHaxelib (new Haxelib (projectName), defines);
		
		if (project != null) {
			
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
	
	
	public static function listSamples (projectName:String, userDefines:Map<String, Dynamic>) {
		
		var templates = [];
		
		if (projectName != null && projectName != "") {
			
			var defines = new Map <String, Dynamic> ();
			defines.set ("create", 1);
			var project = HXProject.fromHaxelib (new Haxelib (projectName), defines);
			
			if (project != null) {
				
				var projectTemplate = PathHelper.findTemplate (project.templatePaths, "project", false);
				
				if (projectTemplate != null) {
					
					templates.push (projectName + ":project");
					
				}
				
				var samplePaths = project.samplePaths.copy ();
				
				if (samplePaths.length > 0) {
					
					samplePaths.reverse ();
					
					for (samplePath in samplePaths) {
						
						var path = PathHelper.tryFullPath (samplePath);
						
						for (name in FileSystem.readDirectory (path)) {
							
							if (!StringTools.startsWith (name, ".") && FileSystem.isDirectory (path + "/" + name)) {
								
								templates.push (projectName + ":" + name);
								
							}
							
						}
						
					}
					
				}
				
				templates.push ("extension");
				
			}
			
		}
		
		if (templates.length == 0) {
			
			projectName = "library";
			
		}
		
		LogHelper.println ("\x1b[1mYou must specify a template when using the 'create' command.\x1b[0m");
		LogHelper.println ("");
		LogHelper.println (" \x1b[32;1mUsage:\x1b[0m \x1b[1mlime\x1b[0m create " + projectName + ":project \"com.package.name\" \x1b[3;37m\"OutputDirectory\"\x1b[0m");
		LogHelper.println (" \x1b[32;1mUsage:\x1b[0m \x1b[1mlime\x1b[0m create " + projectName + ":(sample) \x1b[3;37m\"OutputDirectory\"\x1b[0m");
		LogHelper.println (" \x1b[32;1mUsage:\x1b[0m \x1b[1mlime\x1b[0m create extension \"ExtensionName\"");
		
		if (templates.length > 0) {
			
			LogHelper.println ("");
			LogHelper.println (" \x1b[32;1mAvailable Templates:\x1b[0m");
			LogHelper.println ("");
			
			for (template in templates) {
				
				Sys.println ("  * " + template);
				
			}
			
		}
		
		Sys.println ("");
		
	}
	
	
}