package lime.ui;

/**
	Where the focus enters a view that takes it, as `WebView.focus` uses it:
	at its first element, as when tabbing into it, its last, as when tabbing
	back into it, or wherever it was.

	The values are those of the WebView engine, and of AIR's
	`FocusDirection` in order.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract FocusDirection(Int) from Int to Int
{
	/**
		The last element that takes the focus, as Shift+Tab enters a view.
	**/
	var BOTTOM = 0;

	/**
		Wherever the focus was, without moving it within the view.
	**/
	var NONE = 1;

	/**
		The first element that takes the focus, as Tab enters a view.
	**/
	var TOP = 2;
}
