package lime.system;


import lime.math.Rectangle;
import lime.ui.Window;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class Display {
	
	
	/**
	 * Returns the display which intersects the upper-left hand corner of the given window
	 * @param	window
	 * @return
	 **/
	public static function atWindow(window:Window):Display {
		
		for (d in devices) {
			
			if ((d.bounds.left <= window.x && d.bounds.right  >= window.x) && 
			    (d.bounds.top  <= window.y && d.bounds.bottom >= window.y)) {
				
				return d;
				
			}
			
		}
		
		return null;
	}
	
	/**
	 * Returns ALL displays which intersect the given window
	 * @param	window
	 * @return
	 */
	public static function instersectingWindow(window:Window):Array<Display> {
		
		var arr = [];
		
		for (d in devices) {
			
			if ((d.bounds.left < window.x + window.width  && d.bounds.right  > window.x) &&
				(d.bounds.top  < window.y + window.height && d.bounds.bottom > window.y)) {
				
				arr.push(d);
				
			}
			
		}
		
		return arr;
	}
	
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
	 * Pixel density of the display
	 */
	public var dpi (default, null):Float;
	
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