package lime.ui;

/**
	The edge or corner of a window that `Window.startResize` moves.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract WindowEdge(Int) from Int to Int
{
	var TOP = 1;
	var BOTTOM = 2;
	var LEFT = 4;
	var RIGHT = 8;
	var TOP_LEFT = 5;
	var TOP_RIGHT = 9;
	var BOTTOM_LEFT = 6;
	var BOTTOM_RIGHT = 10;
}
