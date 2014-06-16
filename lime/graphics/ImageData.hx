package lime.graphics;


class ImageData {
	
	
	public var data:ImageDataType;
	public var height:Int;
	public var offsetX:Int;
	public var offsetY:Int;
	public var width:Int;
	
	
	public function new (data:ImageDataType = null, width = 0, height = 0) {
		
		this.data = data;
		this.width = width;
		this.height = height;
		
		offsetX = 0;
		offsetY = 0;
		
	}
	
	
	
}


#if js
typedef ImageDataType = js.html.Image;
#elseif flash
typedef ImageDataType = flash.display.BitmapData;
#else
typedef ImageDataType = lime.utils.UInt8Array;
#end