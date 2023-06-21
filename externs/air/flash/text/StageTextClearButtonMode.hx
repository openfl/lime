package flash.text;

@:native("flash.text.StageTextClearButtonMode")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract StageTextClearButtonMode(String)
{
	var ALWAYS;
	var NEVER;
	var UNLESS_EDITING;
	var WHILE_EDITING;
}
