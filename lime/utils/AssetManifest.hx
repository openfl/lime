package lime.utils;


import haxe.Serializer;
import haxe.Unserializer;
import lime.utils.Bytes;

#if !macro
import haxe.Json;
#end


class AssetManifest {
	
	
	public var assets:Array<Dynamic>;
	public var libraryArgs:Array<String>;
	public var libraryType:String;
	public var version:Int;
	
	
	public function new () {
		
		assets = [];
		libraryArgs = [];
		version = 1;
		
	}
	
	
	public static function fromFile (path:String):AssetManifest {
		
		var bytes = Bytes.fromFile (path);
		
		if (bytes != null) {
			
			return parse (bytes.getString (0, bytes.length));
			
		} else {
			
			return null;
			
		}
		
	}
	
	
	public static function parse (data:String):AssetManifest {
		
		#if !macro
		
		var manifestData = Json.parse (data);
		var manifest = new AssetManifest ();
		
		if (manifestData.version == 1) {
			
			manifest.libraryType = manifestData.libraryType;
			manifest.libraryArgs = manifestData.libraryArgs;
			manifest.assets = Unserializer.run (manifestData.assets);
			
		}
		
		return manifest;
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public function serialize ():String {
		
		var manifestData:Dynamic = {};
		manifestData.version = version;
		manifestData.libraryType = libraryType;
		manifestData.libraryArgs = libraryArgs;
		manifestData.assets = Serializer.run (assets);
		
		return Json.stringify (manifestData);
		
	}
	
	
}