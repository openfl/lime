package flash.text;

@:native("flash.text.StageTextClearButtonMode")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract StageTextClearButtonMode(String)
{
	var ALWAYS = "always";
	var NEVER = "never";
	var UNLESS_EDITING = "unlessEditing";
	var WHILE_EDITING = "whileEditing";
}
