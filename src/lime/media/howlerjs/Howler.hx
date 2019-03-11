package lime.media.howlerjs;

#if (!lime_doc_gen || lime_howlerjs)
#if (!lime_howlerjs || display)
class Howler
{
	public static var autoSuspend:Bool;
	public static var ctx:WebAudioContext;
	public static var masterGain:Dynamic;
	public static var mobileAutoEnable:Bool;
	public static var noAudio:Bool;
	public static var usingWebAudio:Bool;

	/**
	 * Check for codec support of specific extension.
	 * @param	ext		Audio file extention.
	 * @return
	 */
	public static function codecs(ext:String):Bool
	{
		return false;
	}

	/**
	 * Handle muting and unmuting globally.
	 * @param	muted		Is muted or not.
	 */
	public static function mute(muted:Bool):Class<Howler>
	{
		return Howler;
	}

	/**
	 * Unload and destroy all currently loaded Howl objects.
	 * @return
	 */
	public static function unload():Class<Howler>
	{
		return Howler;
	}

	/**
	 * Get/set the global volume for all sounds.
	 * @param	vol		Volume from 0.0 to 1.0.
	 * @return	Returns self or current volume.
	 */
	public static function volume(?vol:Float):Dynamic
	{
		if (vol != null) return Howler;
		return vol;
	}
}
#else
import haxe.extern.EitherType;
import js.html.audio.GainNode;
import lime.media.WebAudioContext;

#if commonjs
@:jsRequire("howler")
#else
@:native("Howler")
#end
extern class Howler
{
	public static var autoSuspend:Bool;
	public static var ctx:WebAudioContext;
	public static var masterGain:GainNode;
	public static var mobileAutoEnable:Bool;
	public static var noAudio:Bool;
	public static var usingWebAudio:Bool;
	public static function codecs(ext:String):Bool;
	public static function mute(muted:Bool):Howler;
	public static function unload():Howler;
	public static function volume(?vol:Float):EitherType<Int, Howler>;
}
#end
#end
