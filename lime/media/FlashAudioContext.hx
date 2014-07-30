package lime.media; #if !flash


class FlashAudioContext {
	
	
	// Need to come up with an API that allows for management of multiple Sound instances?
	
	
	public function new () {
		
		
		
	}
	
	
}


#else
typedef FlashAudioContext = flash.media.Sound;
#end