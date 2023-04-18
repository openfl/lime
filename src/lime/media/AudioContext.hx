package lime.media;

@:access(lime.media.FlashAudioContext)
@:access(lime.media.HTML5AudioContext)
@:access(lime.media.OpenALAudioContext)
@:access(lime.media.WebAudioContext)
class AudioContext
{
	public var custom:Dynamic;
	#if (!lime_doc_gen || flash)
	public var flash(default, null):FlashAudioContext;
	#end
	#if (!lime_doc_gen || (js && html5))
	public var html5(default, null):HTML5AudioContext;
	#end
	#if (!lime_doc_gen || lime_openal)
	public var openal(default, null):OpenALAudioContext;
	#end
	public var type(default, null):AudioContextType;
	#if (!lime_doc_gen || (js && html5))
	public var web(default, null):WebAudioContext;
	#end

	public function new(type:AudioContextType = null)
	{
		if (type != CUSTOM)
		{
			#if (js && html5)
			if (type == null || type == WEB)
			{
				try
				{
					untyped #if haxe4 js.Syntax.code #else __js__ #end ("window.AudioContext = window.AudioContext || window.webkitAudioContext;");
					web = cast untyped #if haxe4 js.Syntax.code #else __js__ #end ("new window.AudioContext ()");
					this.type = WEB;
				}
				catch (e:Dynamic) {}
			}

			if (web == null && type != WEB)
			{
				html5 = new HTML5AudioContext();
				this.type = HTML5;
			}
			#elseif flash
			flash = new FlashAudioContext();
			this.type = FLASH;
			#else
			openal = new OpenALAudioContext();
			this.type = OPENAL;
			#end
		}
		else
		{
			this.type = CUSTOM;
		}
	}
}
