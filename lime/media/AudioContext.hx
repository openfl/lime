package lime.media;


import lime.media.ALAudioContext;
import lime.media.FlashAudioContext;
import lime.media.HTML5AudioContext;
import lime.media.WebAudioContext;


enum AudioContext {
	
	OPENAL (alc:ALCAudioContext, al:ALAudioContext);
	HTML5 (context:HTML5AudioContext);
	WEB (context:WebAudioContext);
	FLASH (context:FlashAudioContext);
	CUSTOM (data:Dynamic);
	
}