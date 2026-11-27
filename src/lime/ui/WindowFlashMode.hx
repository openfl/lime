package lime.ui;

/**
	How long `Window.flash()` asks for the user's attention.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract WindowFlashMode(Int) from Int to Int
{
	/**
		Stops a flash that is going on.
	**/
	var CANCEL = 0;

	/**
		Flashes briefly.
	**/
	var BRIEFLY = 1;

	/**
		Flashes until the window is focused.
	**/
	var UNTIL_FOCUSED = 2;
}
