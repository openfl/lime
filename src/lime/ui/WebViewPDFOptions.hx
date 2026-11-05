package lime.ui;

/**
	How `WebView.printToPDF` lays the page out. Sizes are in inches, and
	everything is optional: the defaults are US Letter with 0.4 inch margins.
**/
typedef WebViewPDFOptions =
{
	/**
		Whether the page is turned on its side. `false` by default.
	**/
	@:optional var landscape:Bool;

	@:optional var marginBottom:Float;

	@:optional var marginLeft:Float;

	@:optional var marginRight:Float;

	@:optional var marginTop:Float;

	@:optional var pageHeight:Float;

	@:optional var pageWidth:Float;

	/**
		Whether backgrounds are printed. `true` by default.
	**/
	@:optional var printBackground:Bool;

	/**
		Whether a table's header repeats on each page it runs onto, which WebKit
		does not do by itself. `true` by default.
	**/
	@:optional var repeatTableHeaders:Bool;

	/**
		The size of the page's content, where `1` is its own size. `1` by default.
	**/
	@:optional var scale:Float;
}
