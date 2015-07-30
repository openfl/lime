package lime.system;
import lime.math.Vector2;
import lime.system.Display;

/**
 * ...
 * @author larsiusprime
 */
class Display {

	/********STATIC*********/
	
	public static var devices = new Map<Int, Display> ();
	public static var numDisplays(get, null):Int;
	
	/**
	 * Sync with the OS to get the current display device information
	 */
	
	public static function init():Void {
		
		for (i in 0...numDisplays) {
			
			var d = new Display(i);
			d.sync();
			devices.set(i, d);
			
		}
		
	}
	
	/**
	 * Get the total number of connected displays
	 * @return
	 */
	
	public static function get_numDisplays():Int {
		
		return lime_display_get_num_video_displays();
		
	}
	
	/**
	 * Get the display device with the given id
	 * @param	id
	 * @return
	 */
	
	public static function get(id:Int):Display {
		
		if (devices.exists(id)) {
		
			return devices.get(id);
			
		}
		
		return null;
	}
	
	
	/*********INSTANCE**********/
	
	
	/**Which number is assigned to the display device by the OS**/
	public var id (default, null):Int;
	
	/**The name of the device, such as "Samsung SyncMaster P2350", "iPhone 6", "Occulus Rift DK2", etc.**/
	public var name (default, null):String;
	
	/**Number of horizontal and vertical pixels currently being displayed**/
	public var resolution(default, null):ConstVector2;
	
	/**Horizontal resolution / Vertical resolution**/
	public var aspectRatio(get, null):Float;
	
	/**The current display mode**/
	public var mode(default, null):DisplayMode;
	
	public var modes(default, null):Array<DisplayMode>;
	
	private function new(id:Int) {
		
		this.id = id;
		sync();
		
	}
	
	
	/**
	 * Updates this object's data with the latest information from the OS about the device
	 */
	public function sync():Void {
		
		name = lime_display_get_name(id);
		
		mode = lime_display_get_current_display_mode(id);
		
		resolution = new ConstVector2(mode.width, mode.height);
		
		modes = [];
		var numModes = lime_display_get_num_display_modes(id);
		
		for (i in 0...numModes) {
			
			modes.push(lime_display_get_display_mode(id, i));
			
		}
	}
	
	/**GET / SET**/
	
	private function get_aspectRatio():Float {
		
		if (resolution.y != 0) {
		
			return resolution.x / resolution.y;
		
		}
		
		return 0;
	}
	
	// Native Methods (stubs)
	
	#if (cpp || neko || nodejs)
	private static var lime_display_get_num_video_displays = function():Int { 
		return 1;
	};
	private static var lime_display_get_name = function(i:Int) { 
		return "fake"; 
	};
	private static var lime_display_get_num_display_modes = function(i:Int) { 
		return 1; 
	};
	private static var lime_display_get_display_mode = function(display:Int, mode:Int):DisplayMode {
		return new DisplayMode(1024, 768, 60, 0);
	};
	private static var lime_display_get_current_display_mode = function(display:Int):DisplayMode {
		return new DisplayMode(1024, 768, 60, 0);
	};
	#end
	
	/*
	#if (cpp || neko || nodejs)
	private static var lime_display_get_num_video_displays = System.load("lime", "lime_display_get_num_video_displays", 0);
	
	private static var lime_display_get_name = System.load ("lime", "lime_display_get_name", 1);
	private static var lime_display_get_num_display_modes = System.load ("lime", "lime_display_get_num_display_modes", 1);
	private static var lime_display_get_display_mode = System.load ("lime", "lime_display_get_display_mode", 2);
	private static var lime_display_get_current_display_mode = System.load ("lime", "lime_display_get_current_display_mode", 1);
	#end
	*/
}

class DisplayMode {
	
	/**horizontal resolution**/
	public var width(default, null):Int;
	
	/**vertical resolution**/
	public var height(default, null):Int;
	
	/**refresh rate in Hz**/
	public var refreshRate(default, null):Int;
	
	/**pixel color format**/
	public var format(default, null):Int;
	
	public function new(width:Int, height:Int, refreshRate:Int, format:Int) {
		
		this.width = width;
		this.height = height;
		this.refreshRate = refreshRate;
		this.format = format;
		
	}
	
}

abstract ConstVector2 (Vector2) from Vector2 {
	
	public inline function new (x:Float = 0, y:Float = 0) this = new Vector2(x, y);
	
	public var x(get, never):Float;
	public var y(get, never):Float;
	
	inline function get_x ():Float return this.x;
	inline function get_y ():Float return this.y;
	
}