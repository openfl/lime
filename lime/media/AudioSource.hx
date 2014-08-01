package lime.media;


import lime.media.openal.AL;


class AudioSource {
	
	
	public var buffer:AudioBuffer;
	
	private var id:UInt;
	
	
	public function new (buffer:AudioBuffer = null) {
		
		this.buffer = buffer;
		id = 0;
		
		if (buffer != null) {
			
			init ();
			
		}
		
	}
	
	
	private function init ():Void {
		
		switch (AudioManager.context) {
			
			case OPENAL (alc, al):
				
				if (buffer.id == 0) {
					
					buffer.id = al.genBuffer ();
					
					var format = 0;
					
					if (buffer.channels == 1) {
						
						if (buffer.bitsPerSample == 8) {
							
							format = al.FORMAT_MONO8;
							
						} else if (buffer.bitsPerSample == 16) {
							
							format = al.FORMAT_MONO16;
							
						}
						
					} else if (buffer.channels == 2) {
						
						if (buffer.bitsPerSample == 8) {
							
							format = al.FORMAT_STEREO8;
							
						} else if (buffer.bitsPerSample == 16) {
							
							format = al.FORMAT_STEREO16;
							
						}
						
					}
					
					al.bufferData (buffer.id, format, buffer.data, buffer.data.length << 2, buffer.sampleRate);
					
				}
				
				id = al.genSource ();
				al.sourcei (id, al.BUFFER, buffer.id);
			
			default:
			
		}
		
	}
	
	
	public function play ():Void {
		
		#if js
		#elseif flash
		buffer.src.play ();
		#else
		AL.sourcePlay (id);
		#end
		
	}
	
	
	public function pause ():Void {
		
		#if js
		#elseif flash
		buffer.src.pause ();
		#else
		AL.sourcePause (id);
		#end
		
	}
	
	
	public function stop ():Void {
		
		#if js
		#elseif flash
		buffer.src.stop ();
		#else
		AL.sourceStop (id);
		#end
		
	}
	
	
}