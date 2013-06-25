import ::APP_MAIN::;

import lime.LiME;

class ApplicationMain {
		
	public static var _main_ : ::APP_MAIN::;
	public static var _lime : LiME;

	public static function main () {
			//Create the runtime
		_lime = new LiME();
			//Create the game class, give it the runtime
		_main_ = new ::APP_MAIN::();

		var config = {
			width : ::WIN_WIDTH::, 
			height : ::WIN_HEIGHT::, 
			title : "::APP_TITLE::"
		};

			//Start up
		_lime.init( _main_, config );
	}
	
}