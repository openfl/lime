package lime.audio;


import lime.audio.ALAudioContext;
import lime.audio.FlashAudioContext;
import lime.audio.HTML5AudioContext;
import lime.audio.WebAudioContext;


enum AudioContext {
	
	OPENAL (alc:ALCAudioContext, al:ALAudioContext);
	HTML5 (context:HTML5AudioContext);
	WEB (context:WebAudioContext);
	FLASH (context:FlashAudioContext);
	CUSTOM (data:Dynamic);
	
}