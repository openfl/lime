package lime.media;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
/**
	The `AudioInputDevice` class describes an audio capture device that can be
	used with `AudioInput`.

	@see lime.media.AudioInput
**/
class AudioInputDevice
{
	/**
		The backend identifier for this device, when one is available.
	**/
	public var id(default, null):String;

	/**
		Whether this device is the backend's default audio input device.
	**/
	public var isDefault(default, null):Bool;

	/**
		The user-visible name of this audio input device.
	**/
	public var name(default, null):String;

	/**
		Creates a new `AudioInputDevice` instance.
	**/
	public function new(name:String = null, id:String = null, isDefault:Bool = false)
	{
		this.name = name;
		this.id = id != null ? id : name;
		this.isDefault = isDefault;
	}
}
