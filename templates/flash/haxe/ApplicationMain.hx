import ::APP_MAIN::;


class ApplicationMain {
	
	
	private static var app:lime.app.Application;
	private static var config:lime.app.Config;
	private static var preloader:lime.app.Preloader;
	
	
	public static function main () {
		
		flash.Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		
		preloader = new ::if (PRELOADER_NAME != "")::::PRELOADER_NAME::::else::lime.app.Preloader::end:: ();
		preloader.onComplete = start;
		
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
		
		preloader.init (config);
		
	}
	
	
	private static function start ():Void {
		
		app = new ::APP_MAIN:: ();
		app.create (config);
		
		var result = app.exec ();
		
		//#if sys
		//Sys.exit (result);
		//#end
		
	}
	
	
}