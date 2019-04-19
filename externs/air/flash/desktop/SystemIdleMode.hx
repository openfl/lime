package flash.desktop;

@:native("flash.data.SQLCollationType")
@:enum extern abstract SystemIdleMode(String)
{
	var KEEP_AWAKE;
	var NORMAL;
}
