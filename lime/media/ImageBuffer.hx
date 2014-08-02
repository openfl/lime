package lime.media;


import lime.utils.UInt8Array;


class ImageBuffer {
	
	
	public var bitsPerPixel:Int;
	public var data:UInt8Array;
	public var height:Int;
	public var premultiplied:Bool;
	public var src:Dynamic;
	public var width:Int;
	
	
	public function new (data:UInt8Array = null, width:Int = 0, height:Int = 0, bitsPerPixel:Int = 4) {
		
		this.data = data;
		this.width = width;
		this.height = height;
		this.bitsPerPixel = bitsPerPixel;
		
	}
	
	
}