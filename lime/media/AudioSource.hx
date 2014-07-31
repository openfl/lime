package lime.media;


import lime.media.openal.AL;

#if js
import js.html.Audio;
#elseif flash
import flash.media.Sound;
#end


class AudioSource {
	
	
	public var buffer:AudioBuffer;
	public var id:UInt;
	
	#if js
	public var src:Audio;
	#elseif flash
	public var src:Sound;
	#else
	public var src:Dynamic;
	#end
	
	
	public function new () {
		
		id = 0;
		
	}
	
	
	public function createALSource (buffer:AudioBuffer):Void {
		
		this.buffer = buffer;
		
		id = AL.genSource ();
		AL.sourcei (id, AL.BUFFER, buffer.id);
		
	}
	
	
}