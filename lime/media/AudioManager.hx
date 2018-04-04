package lime.media;


import lime.media.openal.AL;
import lime.media.openal.ALC;
import lime.media.openal.ALContext;
import lime.media.openal.ALDevice;

#if (js && html5)
import js.Browser;
#end

#if (ios || tvos)
import haxe.Timer;
import lime._backend.native.NativeCFFI;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)


class AudioManager {
	
	
	public static var context:AudioContext;
	
	
	public static function init (context:AudioContext = null) {
		
		if (AudioManager.context == null) {
			
			if (context == null) {
				
				#if (js && html5)
					
					try {
						
						untyped __js__ ("window.AudioContext = window.AudioContext || window.webkitAudioContext;");
						AudioManager.context = WEB (cast untyped __js__ ("new AudioContext ()"));
						
					} catch (e:Dynamic) {
						
						AudioManager.context = HTML5 (new HTML5AudioContext ());
						
					}
					
				#elseif flash
					
					AudioManager.context = FLASH (new FlashAudioContext ());
					
				#elseif lime_console
					
					// TODO
					AudioManager.context = CUSTOM (null);
				
				#else
					
					AudioManager.context = OPENAL (new ALCAudioContext (), new ALAudioContext ());
					
					var device = ALC.openDevice ();
					var ctx = ALC.createContext (device);
					ALC.makeContextCurrent (ctx);
					ALC.processContext (ctx);
					
				#end
				
			} else {
				
				AudioManager.context = context;
				
			}
			
			#if (ios || tvos || mac)
			var timer = new Timer (100);
			timer.run = function () {
				
				NativeCFFI.lime_al_cleanup ();
				
			};
			#end
			
		}
		
	}
	
	
	public static function resume ():Void {
		
		if (context != null) {
			
			switch (context) {
				
				case OPENAL (alc, al):
					
					var currentContext = alc.getCurrentContext ();
					
					if (currentContext != null) {
						
						var device = alc.getContextsDevice (currentContext);
						alc.resumeDevice (device);
						alc.processContext (currentContext);
						
					}
				
				default:
				
			}
			
		}
		
	}
	
	
	public static function shutdown ():Void {
		
		if (context != null) {
			
			switch (context) {
				
				case OPENAL (alc, al):
					
					var currentContext = alc.getCurrentContext ();
					
					if (currentContext != null) {
						
						var device = alc.getContextsDevice (currentContext);
						alc.makeContextCurrent (null);
						alc.destroyContext (currentContext);
						
						if (device != null) {
							
							alc.closeDevice (device);
							
						}
						
					}
				
				default:
				
			}
			
			context = null;
			
		}
		
	}
	
	
	public static function suspend ():Void {
		
		if (context != null) {
			
			switch (context) {
				
				case OPENAL (alc, al):
					
					var currentContext = alc.getCurrentContext ();
					
					if (currentContext != null) {
						
						alc.suspendContext (currentContext);
						var device = alc.getContextsDevice (currentContext);
						alc.pauseDevice (device);
						
					}
				
				default:
				
			}
			
		}
		
	}
	
	
}
