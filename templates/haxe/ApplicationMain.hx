import ::APP_MAIN::;


class ApplicationMain {
	
	
	private var app:lime.app.Application;
	
	
	public static function main () {
		
		var app = new ::APP_MAIN:: ();
		
		var config:lime.app.Config = {
			
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
		
		app.create (config);
		
		var result = app.exec ();
		
		#if sys
		Sys.exit (result);
		#end
		
	}
	
	
}