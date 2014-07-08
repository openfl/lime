package lime.graphics;


import lime.utils.UInt8Array;


abstract ImageData(UInt8Array) from UInt8Array to UInt8Array {
	
	
	public var length (get, never):Int;
	
	
	public function new (data:Dynamic = null) {
		
		this = new UInt8Array (data);
		
	}
	
	
	public function getComponent (pos:Int):Int {
		
		return this.getUInt8 (pos);
		
	}
	
	
	public function getPixel (pos:Int):Int {
		
		return this.getUInt32 (pos);
		
	}
	
	
	public function premultiply ():Void {
		
		var index, a;
		var length = Std.int (this.length / 4);
		
		for (i in 0...length) {
			
			index = i * 4;
			
			a = this.getUInt8 (index + 3);
			this.setUInt8 (index, (this.getUInt8 (index) * a) >> 8);
			this.setUInt8 (index + 1, (this.getUInt8 (index + 1) * a) >> 8);
			this.setUInt8 (index + 2, (this.getUInt8 (index + 2) * a) >> 8);
			
		}
		
	}
	
	
	public function setComponent (pos:Int, value:Int):Void {
		
		this.setUInt8 (pos, value);
		
	}
	
	
	public function setPixel (pos:Int, value:Int):Void {
		
		this.setUInt32 (pos, value);
		
	}
	
	
	private function get_length ():Int {
		
		return this.length;
		
	}
	
	
	
}