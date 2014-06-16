import ::APP_MAIN::;


class ApplicationMain {
	
	
	public static var config:lime.app.Config;
	public static var preloader:lime.app.Preloader;
	
	private static var app:lime.app.Application;
	
	
	public static function init ():Void {
		
		preloader = new ::if (PRELOADER_NAME != "")::::PRELOADER_NAME::::else::lime.app.Preloader::end:: ();
		preloader.onComplete = start;
		preloader.init (config);
		
	}
	
	
	public static function main () {
		
		config = {
			
			antialiasing: Std.int (::WIN_ANTIALIASING::),
			borderless: ::WIN_BORDERLESS::,
			depthBuffer: ::WIN_DEPTH_BUFFER::,
			fps: Std.int (::WIN_FPS::),
			fullscreen: ::WIN_FULLSCREEN::,
			height: Std.int (::WIN_HEIGHT::),
			orientation: "::WIN_ORIENTATION::",
			resizable: ::WIN_RESIZABLE::,
			stencilBuffer: ::WIN_STENCIL_BUFFER::,
			title: "::APP_TITLE::",
			vsync: ::WIN_VSYNC::,
			width: Std.int (::WIN_WIDTH::),
			
		}
		
		#if (js && munit)
		embed (null, ::WIN_WIDTH::, ::WIN_HEIGHT::, "::WIN_FLASHBACKGROUND::");
		#else
		init ();
		#end
		
	}
	
	
	public static function start ():Void {
		
		app = new ::APP_MAIN:: ();
		app.create (config);
		
		var result = app.exec ();
		
		#if sys
		Sys.exit (result);
		#end
		
	}
	
	
}