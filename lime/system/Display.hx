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
		
		return lime_display_get_num_devices();
		
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
	public var resolution(default, null):Resolution;
	
	/**Horizontal resolution / Vertical resolution**/
	public var aspectRatio(get, null):Float;
	
	/**The current display mode**/
	public var mode(default, null):DisplayMode;
	
	/**All of the display modes supported by this device**/
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
		
		var obj = lime_display_get_current_display_mode(id);
		mode = new DisplayMode(obj.width, obj.height, obj.refresh_rate, obj.format);
		
		resolution = new Resolution(mode.width, mode.height);
		
		modes = [];
		var numModes = lime_display_get_num_display_modes(id);
		
		for (i in 0...numModes) {
			
			obj = lime_display_get_display_mode(id, i);
			modes.push(new DisplayMode(obj.width, obj.height, obj.refresh_rate, obj.format));
			
		}
	}
	
	/**GET / SET**/
	
	private function get_aspectRatio():Float {
		
		if (resolution.height != 0) {
		
			return resolution.width / resolution.height;
		
		}
		
		return 0;
	}
	
	// Native Methods
	
	#if (cpp || neko || nodejs)
	
	private static var lime_display_get_num_devices = System.load("lime", "lime_display_get_num_devices", 0);
	private static var lime_display_get_name = System.load ("lime", "lime_display_get_name", 1);
	private static var lime_display_get_num_display_modes = System.load ("lime", "lime_display_get_num_display_modes", 1);
	private static var lime_display_get_display_mode = System.load ("lime", "lime_display_get_display_mode", 2);
	private static var lime_display_get_current_display_mode = System.load ("lime", "lime_display_get_current_display_mode", 1);
	
	#end
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

abstract Resolution (Vector2) from Vector2 {
	
	public inline function new (width:Float = 0, height:Float = 0) this = new Vector2(width, height);
	
	public var width(get, never):Float;
	public var height(get, never):Float;
	
	inline function get_width ():Float return this.x;
	inline function get_height ():Float return this.y;
	
}