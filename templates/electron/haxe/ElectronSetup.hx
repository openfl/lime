import electron.main.App;
import electron.main.BrowserWindow;

class ElectronSetup {

	public static var window:BrowserWindow;

	static function main()
	{
		electron.main.App.commandLine.appendSwitch('ignore-gpu-blacklist', 'true');

		var windows:Array<OpenFLWindow> = [
			::foreach windows::
			{
				allowHighDPI: ::allowHighDPI::,
				alwaysOnTop: ::alwaysOnTop::,
				antialiasing: ::antialiasing::,
				background: ::background::,
				borderless: ::borderless::,
				colorDepth: ::colorDepth::,
				depthBuffer: ::depthBuffer::,
				display: ::display::,
				fullscreen: ::fullscreen::,
				hardware: ::hardware::,
				height: ::height::,
				hidden: #if munit true #else ::hidden:: #end,
				maximized: ::maximized::,
				minimized: ::minimized::,
				parameters: ::parameters::,
				resizable: ::resizable::,
				stencilBuffer: ::stencilBuffer::,
				title: "::title::",
				vsync: ::vsync::,
				width: ::width::,
				x: ::x::,
				y: ::y::
			},::end::
		];

		for (i in 0...windows.length)
		{
			var window:OpenFLWindow = windows[i];
			var width:Int = window.width;
			var height:Int = window.height;
			if (width == 0) width = 800;
			if (height == 0) height = 600;
			var frame:Bool = window.borderless == false;

			electron.main.App.commandLine.appendSwitch('--autoplay-policy','no-user-gesture-required');
			
			electron.main.App.on( 'ready', function(e) {
				var config:Dynamic = {
					fullscreen: window.fullscreen,
					frame:frame,
					resizable: window.resizable,
					alwaysOnTop: window.alwaysOnTop,
					width:width,
					height:height,
					webgl:window.hardware
				};
				ElectronSetup.window = new BrowserWindow(config);

				ElectronSetup.window.on( closed, function() {
					if( js.Node.process.platform != 'darwin' )
						electron.main.App.quit();
				});

				ElectronSetup.window.loadURL( 'file://' + js.Node.__dirname + '/index.html' );
				#if (debug && !suppress_devtools)
					ElectronSetup.window.webContents.openDevTools();
				#end
			});
		}
	}
}

typedef OpenFLWindow =
{
	allowHighDPI:Bool,
	alwaysOnTop:Bool,
	antialiasing:Int,
	background:UInt,
	borderless:Bool,
	colorDepth:Int,
	depthBuffer:Bool,
	display:Dynamic,
	fullscreen:Bool,
	hardware:Dynamic,
	height:Int,
	hidden: Bool,
	maximized:Bool,
	minimized:Bool,
	parameters:Dynamic,
	resizable:Bool,
	stencilBuffer:Bool,
	title:String,
	vsync:Bool,
	width:Int,
	x:Int,
	y:Int
}
