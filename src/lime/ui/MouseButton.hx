package lime.ui;

#if (haxe_ver >= 4.0) enum #else @:enum #end abstract MouseButton(Int) from Int to Int
{
	var LEFT = 0;
	var MIDDLE = 1;
	var RIGHT = 2;
}
