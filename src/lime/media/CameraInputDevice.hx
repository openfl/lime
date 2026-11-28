package lime.media;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

/**
	A camera that `CameraInput` can capture from.

	@see lime.media.CameraInput
**/
class CameraInputDevice
{
	/**
		The system's identifier for the camera, which stays the same while it is
		connected.
	**/
	public var id(default, null):String;

	/**
		Whether this is the system's default camera, the first in
		`CameraInput.devices`.
	**/
	public var isDefault(default, null):Bool;

	/**
		The name the system shows for the camera.
	**/
	public var name(default, null):String;

	/**
		Which way the camera faces, on platforms that say.
	**/
	public var position(default, null):CameraPosition;

	/**
		Creates a new `CameraInputDevice` instance.
	**/
	public function new(name:String = null, id:String = null, position:CameraPosition = UNKNOWN, isDefault:Bool = false)
	{
		this.name = name;
		this.id = id != null ? id : name;
		this.position = position != null ? position : UNKNOWN;
		this.isDefault = isDefault;
	}
}
