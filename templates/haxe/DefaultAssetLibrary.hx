package;


import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.text.Font;
import flash.media.Sound;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import haxe.Unserializer;
import openfl.Assets;


class DefaultAssetLibrary extends AssetLibrary {
	
	
	public static var className (default, null) = new Map <String, Dynamic> ();
	public static var path (default, null) = new Map <String, String> ();
	public static var type (default, null) = new Map <String, AssetType> ();
	
	
	public function new () {
		
		super ();
		
		#if flash
		
		::if (assets != null)::::foreach assets::::if (embed)::className.set ("::id::", __ASSET__::flatName::);
		type.set ("::id::", Reflect.field (AssetType, "::type::".toUpperCase ()));
		::end::::end::::end::
		
		#elseif html5
		
		::if (assets != null)::::foreach assets::::if (embed)::::if (type == "font")::className.set ("::id::", nme.NME_::flatName::);::else::path.set ("::id::", "::resourceName::");::end::
		type.set ("::id::", Reflect.field (AssetType, "::type::".toUpperCase ()));
		::end::::end::::end::
		
		#else
		
		try {
			
			var bytes = ByteArray.readFile ("manifest");
			bytes.position = 0;
			
			var data = bytes.readUTFBytes (bytes.length);
			var manifest:Array<AssetData> = Unserializer.run (data);
			
			for (asset in manifest) {
				
				path.set (asset.id, asset.path);
				type.set (asset.id, asset.type);
				
			}
			
		} catch (e:Dynamic) {
			
			trace ("Warning: Could not load asset manifest");
			
		}
		
		#end
		
	}
	
	
	public override function exists (id:String, type:AssetType):Bool {
		
		var assetType = DefaultAssetLibrary.type.get (id);
		
		if (assetType != null) {
			
			
			if (type == BINARY || assetType == type || type == SOUND && (assetType == MUSIC || assetType == SOUND)) {
				
				return true;
				
			}
			
		}
		
		return false;
		
	}
	
	
	public override function getBitmapData (id:String):BitmapData {
		
		#if flash
		
		return cast (Type.createInstance (className.get (id), []), BitmapData);
		
		#elseif js
		
		return cast (ApplicationMain.loaders.get (path.get (id)).contentLoaderInfo.content, Bitmap).bitmapData;
		
		#else
		
		return BitmapData.load (path.get (id));
		
		#end
		
	}
	
	
	public override function getBytes (id:String):ByteArray {
		
		#if flash
		
		return Type.createInstance (className.get (id), []);
		
		#elseif js

		var bytes:ByteArray = null;
		var data = ApplicationMain.urlLoaders.get (path.get (id)).data;
		
		if (Std.is (data, String)) {
			
			bytes = new ByteArray ();
			bytes.writeUTFBytes (data);
			
		} else if (Std.is (data, ByteArray)) {
			
			bytes = cast data;
			
		} else {
			
			bytes = null;
			
		}

		if (bytes != null) {
			
			bytes.position = 0;
			return bytes;
			
		} else {
			
			return null;
		}
		
		#else
		
		return ByteArray.readFile (path.get (id));
		
		#end
		
	}
	
	
	public override function getFont (id:String):Font {
		
		#if (flash || js)
		
		return cast (Type.createInstance (className.get (id), []), Font);
		
		#else
		
		return new Font (path.get (id));
		
		#end
		
	}
	
	
	public override function getSound (id:String):Sound {
		
		#if flash
		
		return cast (Type.createInstance (className.get (id), []), Sound);
		
		#elseif js
		
		return new Sound (new URLRequest (path.get (id)));
		
		#else
		
		return new Sound (new URLRequest (path.get (id)), null, type.get (id) == MUSIC);
		
		#end
		
	}
	
	
}


#if flash

::foreach assets::::if (embed)::::if (type == "image")::class __ASSET__::flatName:: extends flash.display.BitmapData { public function new () { super (0, 0); } }::else::class __ASSET__::flatName:: extends ::flashClass:: { }::end::::end::
::end::

#elseif html5

::foreach assets::::if (type == "font")::class NME_::flatName:: extends flash.text.Font { }::end::
::end::

#end