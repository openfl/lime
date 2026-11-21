package lime.system;

/**
	The kinds of data the clipboard holds besides plain text, for
	`Clipboard.hasFormat`, `getData` and `setData`.

	Each format's data is a `String`, except `FILE_LIST`, an `Array<String>`
	of native paths, and `IMAGE`, a `lime.graphics.Image`.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract ClipboardFormat(Int) from Int to Int
{
	/**
		Plain text, as `Clipboard.text` reads and writes it.
	**/
	var TEXT = 0;

	/**
		HTML, the fragment that was copied.
	**/
	var HTML = 1;

	/**
		Rich text, in RTF.
	**/
	var RICH_TEXT = 2;

	/**
		A URL, such as a link copied from a browser.
	**/
	var URL = 3;

	/**
		Files copied in a file manager, as native paths.
	**/
	var FILE_LIST = 4;

	/**
		A picture, as an `Image`.
	**/
	var IMAGE = 5;
}
