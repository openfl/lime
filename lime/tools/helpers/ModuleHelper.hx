package lime.tools.helpers; #if !macro


import lime.project.Dependency;
import lime.project.Haxelib;
import lime.project.HXProject;
import sys.io.File;


class ModuleHelper {
	
	
	public static function buildModules (project:HXProject, tempDirectory:String, outputDirectory:String):Void {
		
		tempDirectory = PathHelper.combine (tempDirectory, "lib");
		outputDirectory = PathHelper.combine (outputDirectory, "lib");
		
		PathHelper.mkdir (tempDirectory);
		PathHelper.mkdir (outputDirectory);
		
		var importName, hxmlPath, importPath, outputPath, moduleImport, hxml;
		
		for (module in project.modules) {
			
			if (module.classNames.length > 0) {
				
				importName = "Module" + module.name.charAt (0).toUpperCase () + module.name.substr (1);
				
				hxmlPath = PathHelper.combine (tempDirectory, module.name + ".hxml");
				importPath = PathHelper.combine (tempDirectory, importName + ".hx");
				
				if (project.targetFlags.exists ("final")) {
					
					outputPath = PathHelper.combine (outputDirectory, module.name + ".min.js");
					
				} else {
					
					outputPath = PathHelper.combine (outputDirectory, module.name + ".js");
					
				}
				
				moduleImport = "package;\n\nimport " + module.classNames.join (";\nimport ") + ";";
				
				hxml = "-cp " + tempDirectory;
				
				hxml += "\n" + module.haxeflags.join ("\n");
				hxml += "\n-cp " + PathHelper.getHaxelib (new Haxelib ("lime"));
				
				for (key in project.haxedefs.keys ()) {
					
					if (key != "no-compilation") {
						
						var value = project.haxedefs.get (key);
						
						if (value == null || value == "") {
							
							hxml += "\n-D " + key;
							
						} else {
							
							hxml += "\n-D " + key + "=" + value;
							
						}
						
					}
					
				}
				
				hxml += "\n-D html5";
				hxml += "\n-D html";
				hxml += "\n--no-inline";
				hxml += "\n-dce no";
				hxml += "\n-js " + outputPath;
				
				var includeTypes = module.classNames.concat (module.includeTypes);
				var excludeTypes = module.excludeTypes;
				
				for (otherModule in project.modules) {
					
					if (otherModule != module) {
						
						excludeTypes = excludeTypes.concat (ArrayHelper.getUnique (includeTypes, otherModule.classNames));
						excludeTypes = excludeTypes.concat (ArrayHelper.getUnique (includeTypes, otherModule.includeTypes));
						
					}
					
				}
				
				if (excludeTypes.length > 0) {
					
					hxml += "\n--macro lime.tools.helpers.ModuleHelper.exclude(['" + excludeTypes.join ("','") + "'])";
					
				}
				
				hxml += "\n--macro lime.tools.helpers.ModuleHelper.expose(['" + includeTypes.join ("','") + "'])";
				
				hxml += "\n" + importName;
				
				File.saveContent (importPath, moduleImport);
				File.saveContent (hxmlPath, hxml);
				
				ProcessHelper.runCommand ("", "haxe", [ hxmlPath ]);
				
				if (project.targetFlags.exists ("final")) {
					
					HTML5Helper.minify (project, outputPath);
					
				}
				
			}
			
		}
		
	}
	
	
	public static function updateProject (project:HXProject):Void {
		
		var excludeTypes = [];
		var suffix = (project.targetFlags.exists ("final") ? ".min" : "") + ".js";
		
		for (module in project.modules) {
			
			project.dependencies.push (new Dependency ("./lib/" + module.name + suffix, null));
			
			excludeTypes = ArrayHelper.concatUnique (excludeTypes, module.classNames);
			excludeTypes = ArrayHelper.concatUnique (excludeTypes, module.excludeTypes);
			excludeTypes = ArrayHelper.concatUnique (excludeTypes, module.includeTypes);
			
		}
		
		if (excludeTypes.length > 0) {
			
			project.haxeflags.push ("--macro lime.tools.helpers.ModuleHelper.exclude(['" + excludeTypes.join ("','") + "'])");
			
		}
		
	}
	
	
}


#else


import haxe.macro.Compiler;


class ModuleHelper {
	
	
	public static function exclude (types:Array<String>):Void {
		
		for (type in types) {
			
			Compiler.exclude (type);
			Compiler.addMetadata ("@:native(\"$hx_exports." + type + "\")", type);
			
		}
		
	}
	
	
	public static function expose (classNames:Array<String>):Void {
		
		for (className in classNames) {
			
			Compiler.addMetadata ("@:expose('" + className + "')", className);
			
		}
		
	}
	
	
}


#end