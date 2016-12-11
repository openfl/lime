package lime.utils;


import lime.audio.AudioBuffer;
import lime.graphics.Image;


class AssetCache {
	
	
	public var audio:Map<String, AudioBuffer>;
	public var enabled:Bool = true;
	public var image:Map<String, Image>;
	public var font:Map<String, Dynamic /*Font*/>;
	public var version:Int;
	
	
	public function new () {
		
		audio = new Map<String, AudioBuffer> ();
		font = new Map<String, Dynamic /*Font*/> ();
		image = new Map<String, Image> ();
		version = AssetCache.cacheVersion ();
		
	}
	
	
	public static macro function cacheVersion () {
		
		return macro $v{Std.int (Math.random () * 1000000)};
		
	}
	
	
	public function clear (prefix:String = null):Void {
		
		if (prefix == null) {
			
			audio = new Map<String, AudioBuffer> ();
			font = new Map<String, Dynamic /*Font*/> ();
			image = new Map<String, Image> ();
			
		} else {
			
			var keys = audio.keys ();
			
			for (key in keys) {
				
				if (StringTools.startsWith (key, prefix)) {
					
					audio.remove (key);
					
				}
				
			}
			
			var keys = font.keys ();
			
			for (key in keys) {
				
				if (StringTools.startsWith (key, prefix)) {
					
					font.remove (key);
					
				}
				
			}
			
			var keys = image.keys ();
			
			for (key in keys) {
				
				if (StringTools.startsWith (key, prefix)) {
					
					image.remove (key);
					
				}
				
			}
			
		}
		
	}
	
	
}