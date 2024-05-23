package lime.media.howlerjs;

#if (!lime_doc_gen || lime_howlerjs)
#if (!lime_howlerjs || display)
import haxe.Constraints.Function;
class Howl
{
	public function new(options:HowlOptions) {}

	/**
	 * Get the duration of this sound. Passing a sound id will return the sprite duration.
	 * @param	id		The sound id to check. If none is passed, return full source duration.
	 * @return	Audio duration in seconds.
	 */
	public function duration(?id:Int):Int
	{
		return 0;
	}

	/**
	 * Fade a currently playing sound between two volumes (if no id is passsed, all sounds will fade).
	 * @param	from		The value to fade from (0.0 to 1.0).
	 * @param	to		The volume to fade to (0.0 to 1.0).
	 * @param	len		Time in milliseconds to fade.
	 * @param	id		The sound id (omit to fade all sounds).
	 * @return
	 */
	public function fade(from:Float, to:Float, len:Int, ?id:Int):Howl
	{
		return this;
	}

	/**
	 * Load the audio file.
	 * @return
	 */
	public function load():Howl
	{
		return this;
	}

	/**
	 * Get/set the loop parameter on a sound. This method can optionally take 0, 1 or 2 arguments.
	 * 	loop() -> Returns the group's loop value.
	 * 	loop(id) -> Returns the sound id's loop value.
	 * 	loop(loop) -> Sets the loop value for all sounds in this Howl group.
	 * 	loop(loop, id) -> Sets the loop value of passed sound id.
	 * @return	Returns self or current loop value.
	 */
	public function loop(?loop:Dynamic, ?id:Int):Dynamic
	{
		return null;
	}

	/**
	 * Mute/unmute a single sound or all sounds in this Howl group.
	 * @param	muted		Set to true to mute and false to unmute.
	 * @param	id		The sound ID to update (omit to mute/unmute all).
	 * @return
	 */
	public function mute(muted:Bool, ?id:Int):Howl
	{
		return this;
	}

	/**
	 * Remove a custom event. Call without parameters to remove all events.
	 * @param	event		Event name.
	 * @param	fn		Listener to remove. Leave empty to remove all.
	 * @param	id		(optional) Only remove events for this sound.
	 * @return
	 */
	public function off(event:String, fn:Function, ?id:Int):Howl
	{
		return this;
	}

	/**
	 * Listen to a custom event.
	 * @param	event		Event name.
	 * @param	fn		Listener to call.
	 * @param	id		(optional) Only listen to events for this sound.
	 * @return
	 */
	public function on(event:String, fn:Function, ?id:Int):Howl
	{
		return this;
	}

	/**
	 * Listen to a custom event and remove it once fired.
	 * @param	event		Event name.
	 * @param	fn		Listener to call.
	 * @param	id		(optional) Only listen to events for this sound.
	 * @return
	 */
	public function once(event:String, fn:Function, ?id:Int):Howl
	{
		return this;
	}

	/**
	 * Pause playback and save current position.
	 * @param	id		The sound ID (empty to pause all in group).
	 * @return
	 */
	public function pause(?id:Int):Howl
	{
		return this;
	}

	/**
	 * Play a sound or resume previous playback.
	 * @param	sprite		Sprite name for sprite playback or sound id to continue previous.
	 * @return	Sound ID.
	 */
	public function play(?sprite:Dynamic):Int
	{
		return 0;
	}

	/**
	 * Check if a specific sound is currently playing or not (if id is provided), or check if at least one of the sounds in the group is playing or not.
	 * @param	id		The sound id to check. If none is passed, the whole sound group is checked.
	 * @return	True if playing and false if not.
	 */
	public function playing(?id:Int):Bool
	{
		return false;
	}

	/**
	 * Get/set the playback rate of a sound. This method can optionally take 0, 1 or 2 arguments.
	 * 	rate() -> Returns the first sound node's current playback rate.
	 * 	rate(id) -> Returns the sound id's current playback rate.
	 * 	rate(rate) -> Sets the playback rate of all sounds in this Howl group.
	 * 	rate(rate, id) -> Sets the playback rate of passed sound id.
	 * @return	Returns self or the current playback rate.
	 */
	public function rate(?rate:Float, ?id:Int):Dynamic
	{
		return null;
	}

	/**
	 * Get/set the seek position of a sound (in seconds). This method can optionally take 0, 1 or 2 arguments.
	 * 	seek() -> Returns the first sound node's current seek position.
	 * 	seek(id) -> Returns the sound id's current seek position.
	 * 	seek(seek) -> Sets the seek position of the first sound node.
	 * 	seek(seek, id) -> Sets the seek position of passed sound id.
	 * @return	Returns self or the current seek position.
	 */
	public function seek(?seek:Float, ?id:Int):Dynamic
	{
		return null;
	}

	/**
	 * Returns the current loaded state of this Howl.
	 * @return	'unloaded', 'loading', 'loaded'
	 */
	public function state():String
	{
		return null;
	}

	/**
	 * Stop playback and reset to start.
	 * @param	id		The sound ID (empty to stop all in group).
	 * @return
	 */
	public function stop(?id:Int):Howl
	{
		return this;
	}

	/**
	 * Unload and destroy the current Howl object.
	 * This will immediately stop all sound instances attached to this group.
	 */
	public function unload():Void {}

	/**
	 * Get/set the volume of this sound or of the Howl group. This method can optionally take 0, 1 or 2 arguments.
	 * 	volume() -> Returns the group's volume value.
	 * 	volume(id) -> Returns the sound id's current volume.
	 * 	volume(vol) -> Sets the volume of all sounds in this Howl group.
	 * 	volume(vol, id) -> Sets the volume of passed sound id.
	 * @return	Returns self or current volume.
	 */
	public function volume(?vol:Float, ?id:Int):Dynamic
	{
		return null;
	}

	/**
	 * Get/set the 3D spatial position of the audio source for this sound or group relative to the global listener.
	 * @param  x  The x-position of the audio source.
	 * @param  y  The y-position of the audio source.
	 * @param  z  The z-position of the audio source.
	 * @param  id The sound ID. If none is passed, all in group will be updated.
	 * @return Returns self or the current 3D spatial position: [x, y, z].
	 */
	public function pos(?x:Float, ?y:Float, ?z:Float, ?id:Int):Dynamic
	{
		return null;
	}

	/**
	 * Get/set the stereo panning of the audio source for this sound or all in the group.
	 * @param  pan  A value of -1.0 is all the way left and 1.0 is all the way right.
	 * @param  id (optional) The sound ID. If none is passed, all in group will be updated.
	 * @return Returns self or the current stereo panning value.
	 */
	public function stereo(?pan:Float, ?id:Int):Dynamic
	{
		return null;
	}

	/**
	 * Get/set the panner node's attributes for a sound or group of sounds. This method can optionally take 0, 1 or 2 arguments.
	 *   pannerAttr() -> Returns the group's values.
	 *   pannerAttr(id) -> Returns the sound id's values.
	 *   pannerAttr(o) -> Set's the values of all sounds in this Howl group.
	 *   pannerAttr(o, id) -> Set's the values of passed sound id.
	 *
	 *   Attributes:
	 *     coneInnerAngle - (360 by default) A parameter for directional audio sources, this is an angle, in degrees,
	 *                      inside of which there will be no volume reduction.
	 *     coneOuterAngle - (360 by default) A parameter for directional audio sources, this is an angle, in degrees,
	 *                      outside of which the volume will be reduced to a constant value of coneOuterGain.
	 *     coneOuterGain - (0 by default) A parameter for directional audio sources, this is the gain outside of the
	 *                     coneOuterAngle. It is a linear value in the range [0, 1].
	 *     distanceModel - ('inverse' by default) Determines algorithm used to reduce volume as audio moves away from
	 *                     listener. Can be linear, inverse or `exponential.
	 *     maxDistance - (10000 by default) The maximum distance between source and listener, after which the volume
	 *                   will not be reduced any further.
	 *     refDistance - (1 by default) A reference distance for reducing volume as source moves further from the listener.
	 *                   This is simply a variable of the distance model and has a different effect depending on which model
	 *                   is used and the scale of your coordinates. Generally, volume will be equal to 1 at this distance.
	 *     rolloffFactor - (1 by default) How quickly the volume reduces as source moves from listener. This is simply a
	 *                     variable of the distance model and can be in the range of [0, 1] with linear and [0, ∞]
	 *                     with inverse and exponential.
	 *     panningModel - ('HRTF' by default) Determines which spatialization algorithm is used to position audio.
	 *                     Can be HRTF or equalpower.
	 *
	 * @return Returns self or current panner attributes.
	 */
	public function pannerAttr(args:PannerAttr, ?id:Int):Howl
	{
		return this;
	}
}
#else
import haxe.Constraints.Function;
import haxe.extern.EitherType;

#if commonjs
@:jsRequire("howler", "Howl")
#else
@:native("Howl")
#end
extern class Howl
{
	public function new(options:HowlOptions);
	public function duration(?id:Int):Int;
	public function fade(from:Float, to:Float, len:Int, ?id:Int):Howl;
	public function load():Howl;
	@:overload(function(id:Int):Bool {})
	@:overload(function(loop:Bool):Howl {})
	@:overload(function(loop:Bool, id:Int):Howl {})
	public function loop():Bool;
	public function mute(muted:Bool, ?id:Int):Howl;
	public function off(event:String, fn:Function, ?id:Int):Howl;
	public function on(event:String, fn:Function, ?id:Int):Howl;
	public function once(event:String, fn:Function, ?id:Int):Howl;
	public function pause(?id:Int):Howl;
	@:overload(function(id:Int):Int {})
	public function play(?sprite:String):Int;
	public function playing(?id:Int):Bool;
	@:overload(function(id:Int):Float {})
	@:overload(function(rate:Float):Howl {})
	@:overload(function(rate:Float, id:Int):Howl {})
	public function rate():Float;
	public function state():String;
	@:overload(function(id:Int):Float {})
	@:overload(function(seek:Float):Howl {})
	@:overload(function(seek:Float, id:Int):Howl {})
	public function seek():Float;
	public function stop(?id:Int):Howl;
	public function unload():Void;
	@:overload(function(id:Int):Float {})
	@:overload(function(vol:Float):Howl {})
	@:overload(function(vol:Float, id:Int):Howl {})
	public function volume():Float;
	@:overload(function(pan:Float):Howl {})
	@:overload(function(pan:Float, id:Int):Howl {})
	public function stereo():Float;
	@:overload(function(x:Float):Howl {})
	@:overload(function(x:Float, y:Float):Howl {})
	@:overload(function(x:Float, y:Float, z:Float):Howl {})
	@:overload(function(x:Float, y:Float, z:Float, id:Int):Howl {})
	public function pos():Array<Float>;
	public function pannerAttr(args:PannerAttr, ?id:Int):Howl;
}
#end

typedef HowlOptions =
{
	src:Array<String>,
	?volume:Float,
	?html5:Bool,
	?loop:Bool,
	?preload:Bool,
	?autoplay:Bool,
	?mute:Bool,
	?sprite:Dynamic,
	?rate:Float,
	?pool:Float,
	?format:Array<String>,
	?onload:Function,
	?onloaderror:Function,
	?onplay:Function,
	?onend:Function,
	?onpause:Function,
	?onstop:Function,
	?onmute:Function,
	?onvolume:Function,
	?onrate:Function,
	?onseek:Function,
	?onfade:Function
}

typedef PannerAttr =
{
	?coneInnerAngle:Float,
	?coneOuterAngle:Float,
	?coneOuterGain:Float,
	?distanceModel:String,
	?maxDistance:Float,
	?refDistance:Float,
	?rolloffFactor:Float,
	?panningModel:String
}
#end
