package lime.system;


import lime._backend.native.NativeCFFI;

#if flash
import flash.desktop.Clipboard in FlashClipboard;
#elseif js
import js.Browser.document;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)


class Clipboard {
	
	
	public static var text (get, set):String;

	#if js
	private static var _text : String;
	#end
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private static function get_text ():String {
		
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_clipboard_get_text ();
		#elseif flash
		if (FlashClipboard.generalClipboard.hasFormat (TEXT_FORMAT)) {
			
			return FlashClipboard.generalClipboard.getData (TEXT_FORMAT);
			
		}
		#elseif js
		return _text;
		#end
		
		return null;
		
	}
	
	
	private static function set_text (value:String):String {
		
		#if (lime_cffi && !macro)
		NativeCFFI.lime_clipboard_set_text (value);
		return value;
		
		#elseif flash
		FlashClipboard.generalClipboard.setData (TEXT_FORMAT, value);
		return value;
		
		#elseif js
		_text = value;
		
		#if html5
		if (document.queryCommandEnabled("copy"))
			document.execCommand("copy");
		#end
		
		return value;
		#end
		
		return null;
		
	}
	
	
}