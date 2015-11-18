package lime.system;


#if flash
import flash.desktop.Clipboard in FlashClipboard;
#end

#if !macro
@:build(lime.system.CFFI.build())
#end


class Clipboard {
	
	
	public static var text (get, set):String;
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private static function get_text ():String {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_clipboard_get_text ();
		#elseif flash
		if (FlashClipboard.generalClipboard.hasFormat (TEXT_FORMAT)) {
			
			return FlashClipboard.generalClipboard.getData (TEXT_FORMAT);
			
		}
		#end
		
		return null;
		
	}
	
	
	private static function set_text (value:String):String {
		
		#if ((cpp || neko || nodejs) && !macro)
		lime_clipboard_set_text (value);
		return value;
		#elseif flash
		FlashClipboard.generalClipboard.setData (TEXT_FORMAT, value);
		return value;
		#end
		
		return null;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
	@:cffi private static function lime_clipboard_get_text ():Dynamic;
	@:cffi private static function lime_clipboard_set_text (text:String):Void;
	#end
	
	
}