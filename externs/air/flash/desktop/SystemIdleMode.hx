package flash.desktop;

@:native("flash.desktop.SystemIdleMode")
@:enum extern abstract SystemIdleMode(String)
{
	var KEEP_AWAKE;
	var NORMAL;
}
