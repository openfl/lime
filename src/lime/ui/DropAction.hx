package lime.ui;

/**
	What a drop does with the data dragged, as chosen by the drop target
	from the actions the drag's source allows.

	The values are flags, so a source passes several to `Window.doDragDrop`
	as `COPY | MOVE`. A target chooses one, in `Window.dropAction`.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract DropAction(Int) from Int to Int
{
	/**
		No drop: the target refuses the data, or the drag was canceled.
	**/
	var NONE = 0;

	/**
		The target copies the data.
	**/
	var COPY = 1;

	/**
		The target takes the data, and the source removes it.
	**/
	var MOVE = 2;

	/**
		The target keeps a link to the data, such as a shortcut to a file.
	**/
	var LINK = 4;

	@:op(A | B) private static function or(a:DropAction, b:DropAction):DropAction;

	@:op(A & B) private static function and(a:DropAction, b:DropAction):DropAction;
}
