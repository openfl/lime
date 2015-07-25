package lime.graphics.format;


import lime.graphics.Image;
import lime.math.Rectangle;
import lime.utils.ByteArray;


class BMP {
	
	
	public static function encode (image:Image, type:BMPType = null):ByteArray {
		
		if (image.premultiplied || image.format != RGBA32) {
			
			// TODO: Handle encode from different formats
			
			image = image.clone ();
			image.premultiplied = false;
			image.format = RGBA32;
			
		}
		
		if (type == null) {
			
			type = RGB;
			
		}
		
		var fileHeaderLength = 14;
		var infoHeaderLength = 40;
		var pixelValuesLength = (image.width * image.height * 4);
		
		switch (type) {
			
			case BITFIELD:
				
				infoHeaderLength = 108;
			
			case ICO:
				
				fileHeaderLength = 0;
				pixelValuesLength += image.width * image.height;
			
			case RGB:
				
				pixelValuesLength = (image.width * 3) + ((image.width * 3) % 4) + (image.height * 3) + (image.height * 3);
			
			default:
			
		}
		
		#if !flash
		var data = new ByteArray (fileHeaderLength + infoHeaderLength + pixelValuesLength);
		#else
		var data = new ByteArray ();
		data.length = fileHeaderLength + infoHeaderLength + pixelValuesLength;
		#end
		
		#if (cpp || neko)
		data.bigEndian = false;
		#end
		
		if (fileHeaderLength > 0) {
			
			data.writeByte (0x42);
			data.writeByte (0x4D);
			data.writeInt (data.length);
			data.writeShort (0);
			data.writeShort (0);
			data.writeInt (fileHeaderLength + infoHeaderLength);
			
		}
		
		data.writeInt (infoHeaderLength);
		data.writeInt (image.width);
		data.writeInt (type == ICO ? image.height * 2 : image.height);
		data.writeShort (1);
		data.writeShort (type == RGB ? 24 : 32);
		data.writeInt (type == BITFIELD ? 3 : 0);
		data.writeInt (pixelValuesLength);
		data.writeInt (0x2e30);
		data.writeInt (0x2e30);
		data.writeInt (0);
		data.writeInt (0);
		
		if (type == BITFIELD) {
			
			data.writeInt (0x00FF0000);
			data.writeInt (0x0000FF00);
			data.writeInt (0x000000FF);
			data.writeInt (0xFF000000);
			
			data.writeByte (0x20);
			data.writeByte (0x6E);
			data.writeByte (0x69);
			data.writeByte (0x57);
			
			for (i in 0...48) {
				
				data.writeByte (0);
				
			}
			
		}
		
		var pixels = image.getPixels (new Rectangle (0, 0, image.width, image.height), ARGB32);
		var a, r, g, b;
		
		switch (type) {
			
			case BITFIELD:
				
				for (y in 0...image.height) {
					
					pixels.position = (image.height - 1 - y) * 4 * image.width;
					
					for (x in 0...image.width) {
						
						a = pixels.readByte ();
						r = pixels.readByte ();
						g = pixels.readByte ();
						b = pixels.readByte ();
						
						data.writeByte (b);
						data.writeByte (g);
						data.writeByte (r);
						data.writeByte (a);
						
					}
					
				}
			
			case ICO:
				
				#if !flash
				var andMask = new ByteArray (image.width * image.height);
				#else
				var andMask = new ByteArray ();
				andMask.length = image.width * image.height;
				#end
				
				for (y in 0...image.height) {
					
					pixels.position = (image.height - 1 - y) * 4 * image.width;
					
					for (x in 0...image.width) {
						
						a = pixels.readByte ();
						r = pixels.readByte ();
						g = pixels.readByte ();
						b = pixels.readByte ();
						
						data.writeByte (b);
						data.writeByte (g);
						data.writeByte (r);
						data.writeByte (a);
						
						//if (a < 128) {
							
							//andMask.writeByte (1);
							
						//} else {
							
							andMask.writeByte (0);
							
						//}
						
					}
					
				}
				
				data.writeBytes (andMask);
			
			case RGB:
				
				for (y in 0...image.height) {
					
					pixels.position = (image.height - 1 - y) * 4 * image.width;
					
					for (x in 0...image.width) {
						
						a = pixels.readByte ();
						r = pixels.readByte ();
						g = pixels.readByte ();
						b = pixels.readByte ();
						
						data.writeByte (b);
						data.writeByte (g);
						data.writeByte (r);
						
					}
					
					for (i in 0...((image.width * 3) % 4)) {
						
						data.writeByte (0);
						
					}
					
				}
			
			default:
				
		}
		
		return data;
		
	}
	
	
}


enum BMPType {
	
	RGB;
	BITFIELD;
	ICO;
	
}