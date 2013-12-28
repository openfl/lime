import ::APP_MAIN::;

import lime.Lime;

class ApplicationMain {
		
	public static var _main_ : ::APP_MAIN::;
	public static var _lime : Lime;

	public static function main () {
			//Create the runtime
		_lime = new Lime();
			//Create the game class, give it the runtime
		_main_ = new ::APP_MAIN::();

		var config = {
			fullscreen		: ::WIN_FULLSCREEN::,
			resizable 		: ::WIN_RESIZABLE::,
			borderless		: ::WIN_BORDERLESS::,
			antialiasing    : ::WIN_ANTIALIASING::,
			stencil_buffer 	: ::WIN_STENCIL_BUFFER::,
			depth_buffer 	: ::WIN_DEPTH_BUFFER::,
			vsync 			: ::WIN_VSYNC::,
			fps				: ::WIN_FPS::,
			width 			: ::WIN_WIDTH::, 
			height 			: ::WIN_HEIGHT::, 
			title 			: "::APP_TITLE::"
		};

			//Start up
		_lime.init( _main_, config );
	}
	
}