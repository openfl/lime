package helpers;


import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;
import format.SVG;


class ImageHelper {
	
	
	public static function rasterizeSVG (svg:SVG, width:Int, height:Int, backgroundColor:Int = null):BitmapData {
		
		if (backgroundColor == null) {
			
			backgroundColor = 0x00FFFFFF;
			
		}
		
		var shape = new Shape ();
		svg.render (shape.graphics, 0, 0, width, height);
		
		var bitmapData = new BitmapData (width, height, true, backgroundColor);
		bitmapData.draw (shape);
		
		return bitmapData;
		
	}
	
	
	public static function resizeBitmapData (bitmapData:BitmapData, width:Int, height:Int):BitmapData {
		
		if (bitmapData.width == width && bitmapData.height == height) {
			
			return bitmapData;
			
		}
		
		var matrix = new Matrix ();
		matrix.scale (width / bitmapData.width, height / bitmapData.height);
		
		var data = new BitmapData (width, height, true, 0x00FFFFFF);
		data.draw (bitmapData, matrix, null, null, null, true);
		
		return data;
		
	}
	
	
}