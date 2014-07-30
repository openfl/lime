package lime.media; #if !js


class HTML5AudioContext {
	
	
	// Need to come up with an API that allows for management of multiple Audio instances?
	
	
	public function new () {
		
		
		
	}
	
	
}


#else
typedef HTML5AudioContext = js.html.Audio;
#end