package lime.graphics;


import lime.utils.UInt8Array;


abstract ImageData(UInt8Array) from UInt8Array to UInt8Array {
	
	
	public var length (get, never):Int;
	
	
	public function new (data:Dynamic = null) {
		
		this = new UInt8Array (data);
		
	}
	
	
	public function getComponent (pos:Int):Int {
		
		return this[pos];
		
	}
	
	
	public function getPixel (pos:Int):Int {
		
		var index = pos * 4;
		
		return ((this[index + 3] << 24) | (this[index] << 16 ) | (this[index + 1] << 8) | this[index + 2]);
		
	}
	
	
	public function premultiply ():Void {
		
		var index, a;
		var length = Std.int (this.length / 4);
		
		for (i in 0...length) {
			
			index = i * 4;
			
			a = this[index + 3];
			this[index] = (this[index] * a) >> 8;
			this[index + 1] = (this[index + 1] * a) >> 8;
			this[index + 2] = (this[index + 2] * a) >> 8;
			
		}
		
	}
	
	
	public function setComponent (pos:Int, value:Int):Void {
		
		this[pos] = value;
		
	}
	
	
	public function setPixel (pos:Int, value:Int):Void {
		
		var index = pos * 4;
		
		this[index + 3] = (value >> 24) & 0xFF;
		this[index] = (value >> 16) & 0xFF;
		this[index + 1] = (value >> 8) & 0xFF;
		this[index + 2] = value & 0xFF;
		
	}
	
	
	private function get_length ():Int {
		
		return this.length;
		
	}
	
	
	
}