package lime.tools._types;

import lime.tools.WindowData;

class WindowDataType
{
	public static var fields:WindowData =
		{
			width: 0,
			height: 0,
			x: 0.0,
			y: 0.0,
			background: 0,
			parameters: "",
			fps: 0,
			hardware: false,
			display: 0,
			resizable: false,
			borderless: false,
			vsync: false,
			fullscreen: false,
			allowHighDPI: false,
			alwaysOnTop: false,
			antialiasing: 0,
			orientation: Orientation.AUTO,
			allowShaders: false,
			requireShaders: false,
			depthBuffer: false,
			stencilBuffer: false,
			title: "",
			#if (js && html5)
			element: null,
			#end
			colorDepth: 0,
			minimized: false,
			maximized: false,
			hidden: false
		}
}