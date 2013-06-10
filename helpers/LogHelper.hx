package helpers;


import neko.Lib;


class LogHelper {
	
	
	public static var mute:Bool;
	public static var verbose:Bool = false;
	private static var sentWarnings:Map <String, Bool> = new Map <String, Bool> ();
	
	
	public static function error (message:String, verboseMessage:String = "", e:Dynamic = null):Void {
		
		if (message != "") {
			
			var output;
			
			if (verbose && verboseMessage != "") {
				
				output = "Error: " + verboseMessage + "\n";
				
			} else {
				
				output = "Error: " + message + "\n";
				
			}
			
			#if (nme || openfl)
			
			try {
				
				nme_error_output (output);
				
			} catch (e:Dynamic) { }
			
			#else
			
			Sys.print (output);
			
			#end
			
		}
		
		if (verbose && e != null) {
			
			Lib.rethrow (e);
			
		}
		
		Sys.exit (1);
		
	}
	
	
	public static function info (message:String, verboseMessage:String = ""):Void {
		
		if (verbose && verboseMessage != "") {
			
			Sys.println (verboseMessage);
			
		} else if (message != "") {
			
			Sys.println (message);
			
		}
		
	}
	
	
	public static function warn (message:String, verboseMessage:String = "", allowRepeat:Bool = false):Void {
		
		var output = "";
		
		if (verbose && verboseMessage != "") {
			
			output = "Warning: " + verboseMessage;
			
		} else if (message != "") {
			
			output = "Warning: " + message;
			
		}
		
		if (!allowRepeat && sentWarnings.exists (output)) {
			
			return;
			
		}
		
		sentWarnings.set (output, true);
		Sys.println (output);
		
	}
	
	
	#if openfl
	private static var nme_error_output = flash.Lib.load ("nme", "nme_error_output", 1);
	#elseif nme
	private static var nme_error_output = nme.Loader.load ("nme_error_output", 1);
	#end

}
