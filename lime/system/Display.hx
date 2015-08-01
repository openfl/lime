package lime.system;


import lime.math.Rectangle;


class Display {
	
	
	/**
	 * The desktop area represented by this display, with the upper-leftmost display at 0,0
	 **/
	public var bounds (default, null):Rectangle;
	
	/**
	 * The current display mode
	 **/
	public var currentMode (default, null):DisplayMode;
	
	public var id (default, null):Int;
	
	/**
	 * The name of the device, such as "Samsung SyncMaster P2350", "iPhone 6", "Occulus Rift DK2", etc.
	 **/
	public var name (default, null):String;
	
	/**
	 * All of the display modes supported by this device
	 **/
	public var supportedModes (default, null):Array<DisplayMode>;
	
	
	private function new () {
		
		
		
	}
	
	
}