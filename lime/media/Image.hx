package lime.media;


import lime.app.Application;
import lime.graphics.Renderer;
import lime.utils.ByteArray;
import lime.utils.UInt8Array;
import lime.system.System;

#if js
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.Browser;
#elseif flash
import flash.display.BitmapData;
#end

@:access(lime.app.Application)


class Image {
	
	
	#if js
	private static var __canvas:CanvasElement;
	private static var __context:CanvasRenderingContext2D;
	#end
	
	public var buffer:ImageBuffer;
	public var height:Int;
	public var offsetX:Int;
	public var offsetY:Int;
	public var powerOfTwo (get, set):Bool;
	public var premultiplied (get, set):Bool;
	public var width:Int;
	
	private var __renderer:Renderer;
	
	
	public function new (buffer:ImageBuffer, renderer:Renderer = null) {
		
		this.buffer = buffer;
		
		if (renderer == null) {
			
			__renderer = Application.__instance.window.currentRenderer;
			
		} else {
			
			__renderer = renderer;
			
		}
		
		width = buffer.width;
		height = buffer.height;
		offsetX = 0;
		offsetY = 0;
		
		switch (__renderer.context) {
			
			case OPENGL (_):
				
				#if js
				if (buffer.data == null && buffer.src != null && buffer.width > 0 && buffer.height > 0) {
						
					if (__canvas == null) {
						
						__canvas = cast Browser.document.createElement ("canvas");
						__context = cast __canvas.getContext ("2d");
						
					}
					
					__canvas.width = buffer.width;
					__canvas.height = buffer.height;
					__context.drawImage (buffer.src, 0, 0);
					
					var pixels = __context.getImageData (0, 0, buffer.width, buffer.height);
					buffer.data = pixels.data;
					
				}
				#end
			
			default:
			
		}
		
	}
	
	
	public function getPixel (x:Int, y:Int):Int {
		
		// TODO: cache context type?
		
		x += offsetX;
		y += offsetY;
		
		switch (__renderer.context) {
			
			case OPENGL (_):
				
				// TODO: handle premultiplied
				
				var data = buffer.data;
				var index = (y * buffer.width + x) * 4;
				
				return ((data[index + 3] << 24) | (data[index] << 16 ) | (data[index + 1] << 8) | data[index + 2]);
			
			case FLASH (_):
				
				#if flash
				return buffer.src.getPixel (x, y);
				#else
				return 0;
				#end
			
			case DOM (_):
				
				// TODO
				
				return 0;
			
			case CANVAS (_):
				
				// TODO
				
				return 0;
				
			default:
				
				return 0;
			
		}
		
		
	}
	
	
	public function setPixel (x:Int, y:Int, value:Int):Void {
		
		x += offsetX;
		y += offsetY;
		
		switch (__renderer.context) {
			
			case OPENGL (_):
				
				// TODO: handle premultiplied
				
				var data = buffer.data;
				var index = (y * buffer.width + x) * 4;
				
				data[index + 3] = (value >> 24) & 0xFF;
				data[index] = (value >> 16) & 0xFF;
				data[index + 1] = (value >> 8) & 0xFF;
				data[index + 2] = value & 0xFF;
			
			case FLASH (_):
				
				#if flash
				buffer.src.setPixel (x, y, value);
				#end
			
			case DOM (_):
				
				// TODO
			
			case CANVAS (_):
				
				// TODO
				
			default:
			
		}
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_powerOfTwo ():Bool {
		
		return ((buffer.width != 0) && ((buffer.width & (~buffer.width + 1)) == buffer.width)) && ((buffer.height != 0) && ((buffer.height & (~buffer.height + 1)) == buffer.height));
		
	}
	
	
	private function set_powerOfTwo (value:Bool):Bool {
		
		if (value != powerOfTwo) {
			
			var newWidth = 1;
			var newHeight = 1;
			
			while (newWidth < buffer.width) {
				
				newWidth <<= 1;
				
			}
			
			while (newHeight < buffer.height) {
				
				newHeight <<= 1;
				
			}
			
			switch (__renderer.context) {
				
				case OPENGL (_):
					
					var data = buffer.data;
					var newData = new UInt8Array (newWidth * newHeight * 4);
					var sourceIndex:Int, index:Int;
					
					for (y in 0...buffer.height) {
						
						for (x in 0...buffer.width) {
							
							sourceIndex = y * buffer.width + x;
							index = y * newWidth + x * 4;
							
							newData[index] = data[sourceIndex];
							newData[index + 1] = data[sourceIndex + 1];
							newData[index + 2] = data[sourceIndex + 2];
							newData[index + 3] = data[sourceIndex + 3];
							
						}
						
					}
					
					buffer.data = newData;
					buffer.width = newWidth;
					buffer.height = newHeight;
				
				case FLASH (_):
					
					#if flash
					var bitmapData = new BitmapData (newWidth, newHeight, true, 0x000000);
					bitmapData.draw (buffer.src, null, null, null, true);
					
					buffer.src = bitmapData;
					buffer.width = newWidth;
					buffer.height = newHeight;
					#end
				
				default:
					
					// TODO
				
			}
			
		}
		
		return value;
		
	}
	
	
	private function get_premultiplied ():Bool {
		
		return buffer.premultiplied;
		
	}
	
	
	private function set_premultiplied (value:Bool):Bool {
		
		if (value && !buffer.premultiplied) {
			
			switch (__renderer.context) {
				
				case OPENGL (_):
					
					var data = buffer.data;
					var index, a;
					var length = Std.int (data.length / 4);
					
					for (i in 0...length) {
						
						index = i * 4;
						
						a = data[index + 3];
						data[index] = (data[index] * a) >> 8;
						data[index + 1] = (data[index + 1] * a) >> 8;
						data[index + 2] = (data[index + 2] * a) >> 8;
						
					}
					
					buffer.premultiplied = true;
				
				default:
					
					// TODO
				
			}
			
		} else {
			
			// TODO, unmultiply
			
		}
		
		return value;
		
	}
	
	
}