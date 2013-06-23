import ::APP_MAIN::;

import nmegl.NMEGL;

class ApplicationMain {
		
	public static var _main_ : ::APP_MAIN::;
	public static var _nmegl : NMEGL;

	public static function main () {
			//Create the runtime
		_nmegl = new NMEGL();
			//Create the game class, give it the runtime
		_main_ = new ::APP_MAIN::();

		var config = {
			width : ::WIN_WIDTH::, 
			height : ::WIN_HEIGHT::, 
			title : "::APP_TITLE::"
		};

			//Start up
		_nmegl.init( _main_, config );
	}
	
}