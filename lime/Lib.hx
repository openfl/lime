package lime;


import haxe.PosInfos;
import lime.utils.Log;


class Lib {
	
	
	@:noCompletion private static var __sentWarnings = new Map<String, Bool> ();
	
	
	public static function notImplemented (api:String, ?posInfo:PosInfos):Void {
		
		if (!__sentWarnings.exists (api)) {
			
			__sentWarnings.set (api, true);
			
			Log.warn (api + " is not implemented", posInfo);
			
		}
		
	}
	
	
}
