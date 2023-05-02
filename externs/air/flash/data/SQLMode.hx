package flash.data;

@:native("flash.data.SQLMode")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract SQLMode(String)
{
	var CREATE;
	var READ;
	var UPDATE;
}
