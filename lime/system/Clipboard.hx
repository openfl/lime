package lime.system;


import lime._backend.native.NativeCFFI;

#if flash
import flash.desktop.Clipboard in FlashClipboard;
#elseif js
import lime._backend.html5.HTML5Window;
import js.Browser.document;

@:access(lime._backend.html5.HTML5Window)
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
		
		#if html5 // HTML5 needs focus on <input> field for clipboard events to work
		if  (HTML5Window.textInput != null) {
			
			HTML5Window.textInput.focus();
			HTML5Window.textInput.value = _text;
			HTML5Window.textInput.select();
			
		}
		
		if (document.queryCommandEnabled("copy")) {
			
			document.execCommand("copy");
			
		}
		#end
		
		return value;
		#end
		
		return null;
		
	}
	
	
}