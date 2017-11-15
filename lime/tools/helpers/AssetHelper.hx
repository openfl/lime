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
	
	
	private static var DEFAULT_LIBRARY_NAME = "default";
	
	
	public static function createManifest (project:HXProject, library:String = null, targetPath:String = null):AssetManifest {
		
		var manifest = new AssetManifest ();
		var pathGroups = new Map<String, Array<String>> ();
		var size, soundName;
		var assetData:Dynamic;
		
		var libraries = new Map<String, Library> ();
		
		if (library == null) library = DEFAULT_LIBRARY_NAME;
		
		for (lib in project.libraries) {
			
			libraries[lib.name] = lib;
			
		}
		
		for (asset in project.assets) {
			
			if ((asset.library != null && asset.library != library) || asset.type == TEMPLATE) continue;
			if (asset.library == null && library != DEFAULT_LIBRARY_NAME) continue;
			
			size = 100;
			
			if (FileSystem.exists (asset.sourcePath)) {
				
				size = FileSystem.stat (asset.sourcePath).size;
				
			}
			
			assetData = {
				
				id: asset.id,
				size: size,
				type: Std.string (asset.type)
				
			};
			
			if (project.target == FLASH || project.target == AIR) {
				
				if (asset.embed != false || asset.type == FONT) {
					
					assetData.className = "__ASSET__" + asset.flatName;
					
				} else {
					
					assetData.path = asset.resourceName;
					
				}
				
				if (asset.embed == false && asset.library != null && libraries.exists (asset.library)) {
					
					assetData.preload = libraries[asset.library].preload;
					
				}
				
			} else if (project.target == HTML5) {
				
				if (asset.type == FONT) {
					
					assetData.className = "__ASSET__" + asset.flatName;
					assetData.preload = true;
					
				} else {
					
					assetData.path = asset.resourceName;
					
					if (asset.embed != false || (asset.library != null && libraries.exists (asset.library) && libraries[asset.library].preload)) {
						
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
				
			} else {
				
				if (project.target == EMSCRIPTEN && (asset.embed != false || (asset.library != null && libraries.exists (asset.library) && libraries[asset.library].preload))) {
					
					assetData.preload = true;
					
				}
				
				if (asset.embed == true || asset.type == FONT) {
					
					assetData.className = "__ASSET__" + asset.flatName;
					
				} else {
					
					assetData.path = asset.resourceName;
					
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
		manifest.name = DEFAULT_LIBRARY_NAME;
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
			
			if (asset.library != null && asset.library != DEFAULT_LIBRARY_NAME && !libraryMap.exists (asset.library)) {
				
				library = new Library (null, asset.library);
				project.libraries.push (library);
				
				libraryMap[asset.library] = true;
				
			}
			
		}
		
		if (!libraryMap.exists (DEFAULT_LIBRARY_NAME)) {
			
			library = new Library (null, DEFAULT_LIBRARY_NAME);
			project.libraries.push (library);
			
		}
		
		var handlers = new Array<String> ();
		var hasPackedLibraries = false;
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
					
				} else if (type == "pak" || type == "pack") {
					
					hasPackedLibraries = true;
					
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
				
				HaxelibHelper.runCommand ("", args);
				
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
		
		if (hasPackedLibraries) {
			
			processPackedLibraries (project, targetDirectory);
			
		}
		
		var manifest, asset;
		
		for (library in project.libraries) {
			
			if (library.type == null) {
				
				manifest = createManifest (project, library.name != DEFAULT_LIBRARY_NAME ? library.name : null);
				
				if (library.name == DEFAULT_LIBRARY_NAME) {
					
					library.preload = true;
					
				}
				
				asset = new Asset ("", "manifest/" + library.name + ".json", AssetType.MANIFEST);
				asset.library = library.name;
				asset.data = manifest.serialize ();
				
				if (manifest.assets.length == 0) {
					
					asset.embed = true;
					
				} else {
					
					// TODO: Make this assumption elsewhere?
					
					var allEmbedded = true;
					
					for (childAsset in manifest.assets) {
						
						if (!Reflect.hasField (childAsset, "className") || childAsset.className == null) {
							
							allEmbedded = false;
							break;
							
						}
						
					}
					
					if (allEmbedded) asset.embed = true;
					
				}
				
				project.assets.push (asset);
				
			}
			
		}
		
	}
	
	
	public static function processPackedLibraries (project:HXProject, targetDirectory:String = null):Void {
		
		var asset, cacheAvailable, cacheDirectory, filename;
		var output, manifest, position, assetData:Dynamic, input;
		var embeddedLibrary = false;
		
		for (library in project.libraries) {
			
			if (library.type == "pak" || library.type == "pack") {
				
				// TODO: Support library.embed=true by embedding all the assets instead of packing
				
				cacheAvailable = false;
				cacheDirectory = null;
				
				if (targetDirectory != null) {
					
					manifest = new AssetManifest ();
					
					cacheDirectory = targetDirectory + "/obj/libraries/";
					filename = library.name + ".pak";
					
					// TODO: Support caching
					
					PathHelper.mkdir (cacheDirectory);
					
					if (FileSystem.exists (cacheDirectory + filename)) {
						
						FileSystem.deleteFile (cacheDirectory + filename);
						
					}
					
					output = File.write (cacheDirectory + filename, true);
					position = 0;
					
					try {
						
						for (asset in project.assets) {
							
							if (asset.library == library.name || (asset.library == null && library.name == DEFAULT_LIBRARY_NAME)) {
								
								assetData = {
									
									id: asset.id,
									size: 0,
									type: Std.string (asset.type),
									position: position
									
								};
								
								if (asset.data != null) {
									
									output.writeBytes (asset.data, 0, asset.data.length);
									
								} else if (asset.sourcePath != null) {
									
									input = File.read (asset.sourcePath, true);
									output.writeInput (input);
									
								}
								
								position = output.tell ();
								assetData.length = position - assetData.position;
								
								manifest.assets.push (assetData);
								
								asset.library = library.name;
								
								// asset.sourcePath = "";
								asset.targetPath = null;
								asset.data = null;
								
							}
							
						}
						
					} catch (e:Dynamic) {
						
						output.close ();
						FileSystem.deleteFile (cacheDirectory + filename);
						
						#if neko
						neko.Lib.rethrow (e);
						#end
						
					}
					
					output.close ();
					
					var libraryAsset = new Asset (cacheDirectory + filename, "lib/" + filename, AssetType.BINARY);
					libraryAsset.library = library.name;
					project.assets.push (libraryAsset);
					
					var data = new Asset ("", "manifest/" + library.name + ".json", AssetType.MANIFEST);
					data.library = library.name;
					manifest.libraryType = "lime.utils.PackedAssetLibrary";
					manifest.libraryArgs = [ "lib/" + filename ];
					data.data = manifest.serialize ();
					data.embed = true;
					
					project.assets.push (data);
					embeddedLibrary = true;
					
				}
				
				if (library.name == DEFAULT_LIBRARY_NAME) {
					
					library.preload = true;
					
				}
				
			}
			
		}
		
		if (embeddedLibrary) {
			
			project.haxeflags.push ("lime.utils.PackedAssetLibrary");
			
		}
		
	}
	
	
}