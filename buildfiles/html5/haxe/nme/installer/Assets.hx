package nme.installer;


import format.display.MovieClip;
import haxe.Unserializer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.media.Sound;
import nme.net.URLRequest;
import nme.text.Font;
import nme.utils.ByteArray;
import ApplicationMain;

#if swfdev
import format.swf.lite.SWFLite;
#end

#if xfl
import format.XFL;
#end


/**
 * ...
 * @author Joshua Granick
 */

class Assets {
	
	
	public static var cachedBitmapData:Hash<BitmapData> = new Hash<BitmapData>();
	#if swfdev private static var cachedSWFLibraries:Hash <SWFLite> = new Hash <SWFLite> (); #end
	#if xfl private static var cachedXFLLibraries:Hash <XFL> = new Hash <XFL> (); #end
	
	private static var initialized:Bool = false;
	private static var libraryTypes:Hash <String> = new Hash <String> ();
	private static var resourceClasses:Hash <Dynamic> = new Hash <Dynamic> ();
	private static var resourceNames:Hash <String> = new Hash <String> ();
	private static var resourceTypes:Hash <String> = new Hash <String> ();
	
	
	private static function initialize ():Void {
		
		if (!initialized) {
			
			::foreach assets::
			::if (type == "font")::resourceClasses.set ("::id::", NME_::flatName::);::end::
			resourceNames.set ("::id::", "::resourceName::");
			resourceTypes.set ("::id::", "::type::");
			::end::
			::foreach libraries::libraryTypes.set ("::name::", "::type::");::end::
			initialized = true;
			
		}
		
	}
	
	
	public static function getBitmapData (id:String, useCache:Bool = true):BitmapData {
		
		initialize ();
		
		if (resourceNames.exists(id) && resourceTypes.exists (id) && resourceTypes.get (id).toLowerCase () == "image") {
			
			if (useCache && cachedBitmapData.exists (id)) {
				
				return cachedBitmapData.get (id);
				
			} else {
				
				// Should be bitmapData.clone (), but stopped working in recent Jeash builds
				// Without clone, BitmapData is already cached, so ignoring the hash table for now
				
				var data = cast (ApplicationMain.loaders.get (resourceNames.get(id)).contentLoaderInfo.content, Bitmap).bitmapData;
				
				if (useCache) {
					
					cachedBitmapData.set (id, data);
					
				}
				
				return data;
				
			}
			
		}  else if (id.indexOf (":") > -1) {
			
			var libraryName = id.substr (0, id.indexOf (":"));
			var symbolName = id.substr (id.indexOf (":") + 1);
			
			if (libraryTypes.exists (libraryName)) {
				
				#if swfdev
				
				if (libraryTypes.get (libraryName) == "swf") {
					
					if (!cachedSWFLibraries.exists (libraryName)) {
						
						var unserializer = new Unserializer (getText ("libraries/" + libraryName + ".dat"));
						unserializer.setResolver (cast { resolveEnum: resolveEnum, resolveClass: resolveClass });
						cachedSWFLibraries.set (libraryName, unserializer.unserialize());
						
					}
					
					return cachedSWFLibraries.get (libraryName).getBitmapData (symbolName);
					
				}
				
				#end
				
				#if xfl
				
				if (libraryTypes.get (libraryName) == "xfl") {
					
					if (!cachedXFLLibraries.exists (libraryName)) {
						
						cachedXFLLibraries.set (libraryName, Unserializer.run (getText ("libraries/" + libraryName + "/" + libraryName + ".dat")));
						
					}
					
					return cachedXFLLibraries.get (libraryName).getBitmapData (symbolName);
					
				}
				
				#end
				
			} else {
				
				trace ("[nme.Assets] There is no asset library named \"" + libraryName + "\"");
				
			}
			
		} else {
			
			trace ("[nme.Assets] There is no BitmapData asset with an ID of \"" + id + "\"");
			
		}
		
		return null;
		
	}
	
	
	public static function getBytes (id:String):ByteArray {
		
		initialize ();
		
		if (resourceNames.exists (id)) {
			
			return cast ApplicationMain.urlLoaders.get (getResourceName(id)).data;
			
		}
		
		trace ("[nme.Assets] There is no String or ByteArray asset with an ID of \"" + id + "\"");
		
		return null;
		
	}
	
	
	public static function getFont (id:String):Font {
		
		initialize ();
		
		if (resourceNames.exists(id) && resourceTypes.exists (id)) {
			
			if (resourceTypes.get (id).toLowerCase () == "font") {
				
				return cast (Type.createInstance (resourceClasses.get (id), []), Font);
				
			}
			
		}
		
		trace ("[nme.Assets] There is no Font asset with an ID of \"" + id + "\"");
		
		return null;
		
	}
	
	
	public static function getMovieClip (id:String):MovieClip {
		
		initialize ();
		
		var libraryName = id.substr (0, id.indexOf (":"));
		var symbolName = id.substr (id.indexOf (":") + 1);
		
		if (libraryTypes.exists (libraryName)) {
			
			#if swfdev
			
			if (libraryTypes.get (libraryName) == "swf") {
				
				if (!cachedSWFLibraries.exists (libraryName)) {
					
					var unserializer = new Unserializer (getText ("libraries/" + libraryName + ".dat"));
					unserializer.setResolver (cast { resolveEnum: resolveEnum, resolveClass: resolveClass });
					cachedSWFLibraries.set (libraryName, unserializer.unserialize());
					
				}
				
				return cachedSWFLibraries.get (libraryName).createMovieClip (symbolName);
				
			}
			
			#end
			
			#if xfl
			
			if (libraryTypes.get (libraryName) == "xfl") {
				
				if (!cachedXFLLibraries.exists (libraryName)) {
					
					cachedXFLLibraries.set (libraryName, Unserializer.run (getText ("libraries/" + libraryName + "/" + libraryName + ".dat")));
					
				}
				
				return cachedXFLLibraries.get (libraryName).createMovieClip (symbolName);
				
			}
			
			#end
			
		} else {
			
			trace ("[nme.Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		return null;
		
	}
	
	
	public static function getResourceName (id:String):String {
		
		initialize ();
		
		return resourceNames.get (id);
		
	}
	
	
	public static function getSound (id:String):Sound {
		
		initialize ();
		
		if (resourceNames.exists(id) && resourceTypes.exists (id)) {
			
			if (resourceTypes.get (id).toLowerCase () == "sound") {
				
				return new Sound (new URLRequest (resourceNames.get(id)));
				
			} else if (resourceTypes.get (id).toLowerCase () == "music") {
				
				return new Sound (new URLRequest (resourceNames.get(id)));
				
			}
			
		}
		
		trace ("[nme.Assets] There is no Sound asset with an ID of \"" + id + "\"");
		
		return null;
		
	}
	
	
	public static function getText (id:String):String {
		
		initialize ();
		
		if (resourceNames.exists(id) && resourceTypes.exists (id)) {
			
			if (resourceTypes.get (id).toLowerCase () == "text") {
				
				return ApplicationMain.urlLoaders.get (resourceNames.get(id)).data;
				
			}
			
		}
		
		var bytes = getBytes (id);
		return null;
		
	}
	
	
	//public static function loadBitmapData(id:String, handler:BitmapData -> Void, useCache:Bool = true):BitmapData
	//{
		//return null;
	//}
	//
	//
	//public static function loadBytes(id:String, handler:ByteArray -> Void):ByteArray
	//{	
		//return null;
	//}
	//
	//
	//public static function loadText(id:String, handler:String -> Void):String
	//{
		//return null;
	//}
	
	
	private static function resolveClass (name:String):Class <Dynamic> {
		
		name = StringTools.replace (name, "native.", "browser.");
		return Type.resolveClass (name);
		
	}
	
	
	private static function resolveEnum (name:String):Enum <Dynamic> {
		
		name = StringTools.replace (name, "native.", "browser.");
		return Type.resolveEnum (name);
		
	}
	
	
}