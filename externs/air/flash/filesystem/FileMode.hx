package flash.filesystem;

@:native("flash.filesystem.FileMode")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract FileMode(String)
{
	var APPEND;
	var READ;
	var UPDATE;
	var WRITE;
}
