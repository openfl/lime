package flash.data;

@:native("flash.data.SQLMode")
@:enum extern abstract SQLMode(String)
{
	var CREATE;
	var READ;
	var UPDATE;
}
