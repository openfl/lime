#if lime_html5

	import ::APP_MAIN_PACKAGE::::APP_MAIN_CLASS::;
	import lime.Lime;

	class ApplicationMain {
		
		public static function main () {


			
				//Create the game class, give it the runtime			
			var _main_ = Type.createInstance (::APP_MAIN::, []);
				//Create an instance of lime
			var _lime = new Lime();

				//Create the config from the project.nmml info
			var config = {
				fullscreen		: ::WIN_FULLSCREEN::,
				resizable 		: ::WIN_RESIZABLE::,
				borderless		: ::WIN_BORDERLESS::,
				antialiasing	: ::WIN_ANTIALIASING::,
				stencil_buffer 	: ::WIN_STENCIL_BUFFER::,
				depth_buffer 	: ::WIN_DEPTH_BUFFER::,
				vsync 			: ::WIN_VSYNC::,
				width 			: ::WIN_WIDTH::, 
				height 			: ::WIN_HEIGHT::, 
				title 			: "::APP_TITLE::"
			};

				//Start up
			_lime.init( _main_, config );
			
		} //main
	} //ApplicationMain


#end //lime_html5
