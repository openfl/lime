package lime.system;


import lime._backend.native.NativeCFFI;
import lime.app.Application;

#if flash
import flash.desktop.Clipboard in FlashClipboard;
#elseif js
import lime._backend.html5.HTML5Window;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)
@:access(lime.ui.Window)


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
		return null;
		#elseif js
		return _text;
		#else
		return null;
		#end
		
	}
	
	
	private static function set_text (value:String):String {
		
		#if (lime_cffi && !macro)
		NativeCFFI.lime_clipboard_set_text (value);
		return value;
		#elseif flash
		FlashClipboard.generalClipboard.setData (TEXT_FORMAT, value);
		return value;
		#elseif (js && html5)
		_text = value;
		var window = Application.current.window;
		if (window != null) {
			
			window.backend.setClipboard (value);
			
		}
		return value;
		#else
		return null;
		#end
		
	}
	
	
}