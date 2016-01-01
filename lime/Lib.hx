package lime;


class Lib {
	
	
	@:noCompletion private static var __sentWarnings = new Map<String, Bool> ();
	
	
	public static function notImplemented (api:String):Void {
		
		if (!__sentWarnings.exists (api)) {
			
			__sentWarnings.set (api, true);
			
			trace ("Warning: " + api + " is not implemented");
			
		}
		
	}
	
	
}
