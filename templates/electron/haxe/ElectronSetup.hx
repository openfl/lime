package;

class ElectronSetup
{
	public static var window:ElectronBrowserWindow;

	static function main()
	{
		ElectronApp.commandLine.appendSwitch('ignore-gpu-blacklist', 'true');

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

			ElectronApp.commandLine.appendSwitch('--autoplay-policy', 'no-user-gesture-required');

			ElectronApp.on('ready', function(e)
			{
				var config:Dynamic =
					{
						webPreferences:{
							nodeIntegration:true
						},
						fullscreen: window.fullscreen,
						frame: frame,
						resizable: window.resizable,
						alwaysOnTop: window.alwaysOnTop,
						width: width,
						height: height,
						webgl: window.hardware
					};
				ElectronSetup.window = new ElectronBrowserWindow(config);

				ElectronSetup.window.on('closed', function()
				{
					if (js.Node.process.platform != 'darwin')
					{
						ElectronApp.quit();
					}
				});

				ElectronSetup.window.loadURL('file://' + js.Node.__dirname + '/index.html');
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
	hidden:Bool,
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

// Externs to compile without requiring hxelectron

@:jsRequire("electron", "app") extern class ElectronApp
{
	public static var commandLine:Dynamic;
	public static function on(type:Dynamic, callback:Dynamic):Dynamic;
	public static function quit():Void;
}

@:jsRequire("electron", "BrowserWindow") extern class ElectronBrowserWindow
{
	public var webContents:Dynamic;
	public function new(?options:Dynamic);
	public function loadURL(url:String, ?options:Dynamic):Dynamic;
	public function on(type:Dynamic, callback:Dynamic):Dynamic;
}
