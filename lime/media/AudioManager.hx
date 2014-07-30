package lime.media;


#if js
import js.Browser;
#end


class AudioManager {
	
	
	public static var context:AudioContext;
	
	
	public static function init (context:AudioContext = null) {
		
		if (context == null) {
			
			#if js
			try {
				
				untyped __js__ ("window.AudioContext = window.AudioContext || window.webkitAudioContext;");
				context = WEB (cast untyped __js__ ("new AudioContext ()"));
				
			} catch (e:Dynamic) {
				
				context = HTML5 (new HTML5AudioContext ());
				
			}
			#elseif flash
			context = FLASH (new FlashAudioContext ());
			#else
			context = OPENAL (new ALCAudioContext (), new ALAudioContext ());
			#end
			
		} else {
			
			AudioManager.context = context;
			
		}
		
	}
	
	
}