package lime.media;


#if js
import js.html.Audio;
#elseif flash
import flash.media.Sound;
#end


class AudioSource {
	
	
	public var id:Int;
	
	#if js
	public var src:Audio;
	#elseif flash
	public var src:Sound;
	#else
	public var src:Dynamic;
	#end
	
	
	public function new () {
		
		
		
	}
	
	
}