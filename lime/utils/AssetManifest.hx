package lime.utils;


import haxe.io.Path;
import haxe.Serializer;
import haxe.Unserializer;
import lime.app.Future;
import lime.utils.Bytes;

#if !macro
import haxe.Json;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class AssetManifest {
	
	
	public var assets:Array<Dynamic>;
	public var basePath:String;
	public var libraryArgs:Array<String>;
	public var libraryType:String;
	public var name:String;
	public var version:Int;
	
	
	public function new () {
		
		assets = [];
		basePath = "";
		libraryArgs = [];
		version = 2;
		
	}
	
	
	public static function fromBytes (bytes:Bytes, basePath:String = null):AssetManifest {
		
		if (bytes != null) {
			
			return parse (bytes.getString (0, bytes.length), basePath);
			
		} else {
			
			return null;
			
		}
		
	}
	
	
	public static function fromFile (path:String, basePath:String = null):AssetManifest {
		
		if (path == null) return null;
		
		if (basePath == null) {
			
			if (path.indexOf ("?") > -1) {
				
				basePath = Path.directory (path.substr (0, path.indexOf ("?")));
				
			} else {
				
				basePath = Path.directory (path);
				
			}
			
		}
		
		return fromBytes (Bytes.fromFile (path), basePath);
		
	}
	
	
	public static function loadFromBytes (bytes:Bytes, basePath:String = null):Future<AssetManifest> {
		
		return Future.withValue (fromBytes (bytes, basePath));
		
	}
	
	
	public static function loadFromFile (path:String, basePath:String = null):Future<AssetManifest> {
		
		return Bytes.loadFromFile (path).then (function (bytes) {
			
			if (basePath == null) {
				
				if (path.indexOf ("?") > -1) {
					
					basePath = Path.directory (path.substr (0, path.indexOf ("?")));
					
				} else {
					
					basePath = Path.directory (path);
					
				}
				
			}
			
			return Future.withValue (fromBytes (bytes, basePath));
			
		});
		
	}
	
	
	public static function parse (data:String, basePath:String = null):AssetManifest {
		
		if (data == null || data == "") return null;
		
		#if !macro
		
		var manifestData = Json.parse (data);
		var manifest = new AssetManifest ();
		
		manifest.name = manifestData.name;
		manifest.libraryType = manifestData.libraryType;
		manifest.libraryArgs = manifestData.libraryArgs;
		manifest.assets = Unserializer.run (manifestData.assets);
		
		if (basePath != null) {
			
			manifest.basePath = basePath;
			
		}
		
		return manifest;
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public function serialize ():String {
		
		#if !macro
		
		var manifestData:Dynamic = {};
		manifestData.version = version;
		manifestData.libraryType = libraryType;
		manifestData.libraryArgs = libraryArgs;
		manifestData.name = name;
		manifestData.assets = Serializer.run (assets);
		
		return Json.stringify (manifestData);
		
		#else
		
		return null;
		
		#end
		
	}
	
	
}