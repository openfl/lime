package flash.filesystem;

@:native("flash.filesystem.FileMode")
@:enum extern abstract FileMode(String)
{
	var APPEND;
	var READ;
	var UPDATE;
	var WRITE;
}
