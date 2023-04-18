package flash.text;

@:native("flash.text.StageTextClearButtonMode")
@:enum extern abstract StageTextClearButtonMode(String)
{
	var ALWAYS;
	var NEVER;
	var UNLESS_EDITING;
	var WHILE_EDITING;
}
