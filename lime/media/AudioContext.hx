package lime.media;


import lime.media.ALAudioContext;
import lime.media.FlashAudioContext;
import lime.media.HTML5AudioContext;
import lime.media.WebAudioContext;


enum AudioContext {
	
	OPENAL (al:ALAudioContext);
	HTML5 (audio:HTML5AudioContext);
	WEB (context:WebAudioContext);
	FLASH (sound:FlashRenderContext);
	CUSTOM (data:Dynamic);
	
}