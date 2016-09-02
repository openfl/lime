package lime.system;


import lime.system.CFFI;

#if flash
import flash.system.Capabilities;
#end


abstract Locale(String) from String to String {
	
	
	public static var currentLocale:Locale;
	public static var systemLocale (default, null):Locale;
	
	public var language (get, never):String;
	public var region (get, never):String;
	
	
	private static function __init__ ():Void {
		
		var locale = null;
		
		#if flash
		locale = Capabilities.language;
		#elseif (js && html5)
		locale = untyped navigator.language;
		#elseif (lime_cffi && !macro)
		locale = CFFI.load ("lime", "lime_locale_get_system_locale", 0) ();
		#end
		
		if (locale != null) {
			
			systemLocale = locale;
			
		} else {
			
			systemLocale = "en-US";
			
		}
		
		currentLocale = systemLocale;
		
	}
	
	
	public function new (value:String) {
		
		this = value;
		
	}
	
	
	@:noCompletion @:op(A == B) private static function equals (a:Locale, b:Locale):Bool {
		
		var language = a.language;
		var region = a.region;
		
		var language2 = b.language;
		var region2 = b.region;
		
		var languageMatch = (language == language2);
		var regionMatch = (region == region2);
		
		if (!languageMatch && language != null && language2 != null) {
			
			languageMatch = (language.toLowerCase () == language2.toLowerCase ());
			
		}
		
		if (!regionMatch && region != null && region2 != null) {
			
			regionMatch = (region.toLowerCase () == region2.toLowerCase ());
			
		}
		
		return (languageMatch && regionMatch);
		
	}
	
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private function get_language ():String {
		
		if (this != null) {
			
			var index = this.indexOf ("_");
			
			if (index > -1) {
				
				return this.substring (0, index);
				
			}
			
			index = this.indexOf ("-");
			
			if (index > -1) {
				
				return this.substring (0, index);
				
			}
			
		}
		
		return this;
		
	}
	
	
	@:noCompletion private function get_region ():String {
		
		if (this != null) {
			
			var underscoreIndex = this.indexOf ("_");
			var dotIndex = this.indexOf (".");
			var dashIndex = this.indexOf ("-");
			
			if (underscoreIndex > -1) {
				
				if (dotIndex > -1) {
					
					return this.substring (underscoreIndex + 1, dotIndex);
					
				} else {
					
					return this.substring (underscoreIndex + 1);
					
				}
				
			} else if (dashIndex > -1) {
				
				if (dotIndex > -1) {
					
					return this.substring (dashIndex + 1, dotIndex);
					
				} else {
					
					return this.substring (dashIndex + 1);
					
				}
				
			}
			
		}
		
		return null;
		
	}
	
	
}