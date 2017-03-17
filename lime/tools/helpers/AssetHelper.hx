package lime.tools.helpers;


import haxe.io.Path;
import haxe.Serializer;
import haxe.Unserializer;
import lime.tools.helpers.PathHelper;
import lime.project.AssetType;
import lime.project.Asset;
import lime.project.HXProject;
import lime.project.Library;
import lime.utils.AssetManifest;
import sys.io.File;
import sys.FileSystem;


class AssetHelper {
	
	
	public static function createManifest (project:HXProject, library:String = null, targetPath:String = null):AssetManifest {
		
		var manifest = new AssetManifest ();
		var pathGroups = new Map<String, Array<String>> ();
		var size, soundName;
		var assetData:Dynamic;
		
		for (asset in project.assets) {
			
			if (asset.library != library || asset.type == TEMPLATE) continue;
			
			size = 100;
			
			if (FileSystem.exists (asset.sourcePath)) {
				
				size = FileSystem.stat (asset.sourcePath).size;
				
			}
			
			assetData = {
				
				id: asset.id,
				size: size,
				type: Std.string (asset.type)
				
			};
			
			if (project.target != HTML5) {
				
				if (asset.embed == true || asset.type == FONT || (asset.embed == null && (project.platformType == WEB))) {
					
					assetData.className = "__ASSET__" + asset.flatName;
					
				} else {
					
					assetData.path = asset.resourceName;
					
				}
				
			} else {
				
				if (asset.type == FONT) {
					
					assetData.className = "__ASSET__" + asset.flatName;
					assetData.preload = true;
					
				} else {
					
					assetData.path = asset.resourceName;
					
					if (asset.embed != false) {
						
						assetData.preload = true;
						
					}
					
					if (asset.type == MUSIC || asset.type == SOUND) {
						
						soundName = Path.withoutExtension (assetData.path);
						
						if (!pathGroups.exists (soundName)) {
							
							pathGroups.set (soundName, [ assetData.path ]);
							
						} else {
							
							pathGroups[soundName].push (assetData.path);
							Reflect.deleteField (assetData, "preload");
							
						}
						
						Reflect.deleteField (assetData, "path");
						assetData.pathGroup = pathGroups[soundName];
						
					}
					
				}
				
			}
			
			manifest.assets.push (assetData);
			
		}
		
		if (targetPath != null) {
			
			PathHelper.mkdir (Path.directory (targetPath));
			File.saveContent (targetPath, manifest.serialize ());
			
		}
		
		return manifest;
		
	}
	
	
	public static function createManifests (project:HXProject, targetDirectory:String = null):Array<AssetManifest> {
		
		var libraryNames = new Map<String, Bool> ();
		
		for (asset in project.assets) {
			
			if (asset.library != null && !libraryNames.exists (asset.library)) {
				
				libraryNames[asset.library] = true;
				
			}
			
		}
		
		var manifest = createManifest (project);
		manifest.name = "default";
		var manifests = [ manifest ];
		
		for (library in libraryNames.keys ()) {
			
			manifest = createManifest (project, library);
			manifest.name = library;
			manifests.push (manifest);
			
		}
		
		if (targetDirectory != null) {
			
			PathHelper.mkdir (targetDirectory);
			
			for (manifest in manifests) {
				
				File.saveContent (PathHelper.combine (targetDirectory, manifest.name + ".json"), manifest.serialize ());
				
			}
			
		}
		
		return manifests;
		
	}
	
	
	public static function processLibraries (project:HXProject, targetDirectory:String = null):Void {
		
		var libraryMap = new Map<String, Bool> ();
		
		for (library in project.libraries) {
			
			libraryMap[library.name] = true;
			
		}
		
		var library;
		
		for (asset in project.assets) {
			
			if (asset.library != null && !libraryMap.exists (asset.library)) {
				
				library = new Library (null, asset.library);
				project.libraries.push (library);
				
				libraryMap[asset.library] = true;
				
			}
			
		}
		
		if (!libraryMap.exists ("default")) {
			
			library = new Library (null, "default");
			project.libraries.push (library);
			
		}
		
		var handlers = new Array<String> ();
		var type;
		
		for (library in project.libraries) {
			
			type = library.type;
			
			if (library.sourcePath != null || type != null) {
				
				if (type == null) {
					
					type = Path.extension (library.sourcePath).toLowerCase ();
					
				}
				
				if (project.libraryHandlers.exists (type)) {
					
					var handler = project.libraryHandlers.get (type);
					
					handlers.remove (handler);
					handlers.push (handler);
					
					library.type = type;
					
				}
				
			}
			
		}
		
		if (handlers.length > 0) {
			
			var projectData = Serializer.run (project);
			var temporaryFile = PathHelper.getTemporaryFile ();
			
			File.saveContent (temporaryFile, projectData);
			
			for (handler in handlers) {
				
				var outputFile = PathHelper.getTemporaryFile ();
				var args = [ "run", handler, "process", temporaryFile, outputFile ];
				
				if (LogHelper.verbose) {
					
					args.push ("-verbose");
					
				}
				
				if (targetDirectory != null) {
					
					args.push ("--targetDirectory=" + PathHelper.tryFullPath (targetDirectory));
					
				}
				
				ProcessHelper.runCommand ("", "haxelib", args);
				
				if (FileSystem.exists (outputFile)) {
					
					try {
						
						var output = File.getContent (outputFile);
						var data:HXProject = Unserializer.run (output);
						project.merge (data);
						
					} catch (e:Dynamic) {
						
						LogHelper.error (e);
						
					}
					
					try {
						
						FileSystem.deleteFile (outputFile);
						
					} catch (e:Dynamic) {}
					
				}
				
			}
			
			try {
				
				FileSystem.deleteFile (temporaryFile);
				
			} catch (e:Dynamic) {}
			
		}
		
		var manifest, asset;
		
		for (library in project.libraries) {
			
			if (library.type == null) {
				
				manifest = createManifest (project, library.name != "default" ? library.name : null);
				
				if (library.name == "default") {
					
					library.preload = true;
					
				}
				
				asset = new Asset ("", "manifest/" + library.name + ".json", AssetType.MANIFEST);
				asset.library = library.name;
				asset.data = manifest.serialize ();
				if (manifest.assets.length == 0) asset.embed = true;
				project.assets.push (asset);
				
			}
			
		}
		
	}
	
	
}