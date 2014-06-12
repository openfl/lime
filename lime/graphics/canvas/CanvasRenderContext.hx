package lime.graphics.canvas;
#if js
typedef CanvasRenderContext = js.html.CanvasRenderingContext2D;
#else


typedef CanvasElement = Dynamic;
typedef CanvasGradient = Dynamic;
typedef CanvasPattern = Dynamic;
typedef ImageData = Dynamic;
typedef ImageElement = Dynamic;
typedef TextMetrics = Dynamic;
typedef VideoElement = Dynamic;


class CanvasRenderContext {
	
	
	public var backingStorePixelRatio (default, null):Float;
	public var canvas:CanvasElement;
	public var fillStyle:Dynamic;
	public var font:String;
	public var globalAlpha:Float;
	public var globalCompositeOperation:String;
	public var imageSmoothingEnabled:Bool;
	public var lineCap:String;
	public var lineDash:Array<Dynamic>;
	public var lineDashOffset:Float;
	public var lineJoin:String;
	public var lineWidth:Float;
	public var miterLimit:Float;
	public var shadowBlur:Float;
	public var shadowColor:String;
	public var shadowOffsetX:Float;
	public var shadowOffsetY:Float;
	public var strokeStyle:Dynamic;
	public var textAlign:String;
	public var textBaseline:String;
	
	
	public function new () {
		
		
		
	}
	
	
	public function arc(x:Float, y:Float, radius:Float, startAngle:Float, endAngle:Float, anticlockwise:Bool):Void {};
	public function arcTo(x1:Float, y1:Float, x2:Float, y2:Float, radius:Float):Void {};
	public function beginPath():Void {};
	public function bezierCurveTo(cp1x:Float, cp1y:Float, cp2x:Float, cp2y:Float, x:Float, y:Float):Void {};
	public function clearRect(x:Float, y:Float, width:Float, height:Float):Void {};
	public function clearShadow():Void {};
	public function clip():Void {};
	public function closePath():Void {};
	@:overload(function(imagedata:ImageData):ImageData {})
	public function createImageData(sw:Float, sh:Float):ImageData { return null; };
	public function createLinearGradient(x0:Float, y0:Float, x1:Float, y1:Float):CanvasGradient { return null; };
	@:overload(function(canvas:CanvasElement, repetitionType:String):CanvasPattern {})
	public function createPattern(image:ImageElement, repetitionType:String):CanvasPattern { return null; };
	public function createRadialGradient(x0:Float, y0:Float, r0:Float, x1:Float, y1:Float, r1:Float):CanvasGradient { return null; };
	@:overload(function(image:ImageElement, x:Float, y:Float):Void {})
	@:overload(function(image:ImageElement, x:Float, y:Float, width:Float, height:Float):Void {})
	@:overload(function(image:ImageElement, sx:Float, sy:Float, sw:Float, sh:Float, dx:Float, dy:Float, dw:Float, dh:Float):Void {})
	@:overload(function(canvas:CanvasElement, x:Float, y:Float):Void {})
	@:overload(function(canvas:CanvasElement, x:Float, y:Float, width:Float, height:Float):Void {})
	@:overload(function(canvas:CanvasElement, sx:Float, sy:Float, sw:Float, sh:Float, dx:Float, dy:Float, dw:Float, dh:Float):Void {})
	@:overload(function(video:VideoElement, x:Float, y:Float):Void {})
	@:overload(function(video:VideoElement, x:Float, y:Float, width:Float, height:Float):Void {})
	public function drawImage(video:VideoElement, sx:Float, sy:Float, sw:Float, sh:Float, dx:Float, dy:Float, dw:Float, dh:Float):Void {};
	public function drawImageFromRect(image:ImageElement, ?sx:Float, ?sy:Float, ?sw:Float, ?sh:Float, ?dx:Float, ?dy:Float, ?dw:Float, ?dh:Float, ?compositeOperation:String):Void {};
	public function fill():Void {};
	public function fillRect(x:Float, y:Float, width:Float, height:Float):Void {};
	public function fillText(text:String, x:Float, y:Float, ?maxWidth:Float):Void {};
	public function getImageData(sx:Float, sy:Float, sw:Float, sh:Float):ImageData { return null; };
	public function getImageDataHD(sx:Float, sy:Float, sw:Float, sh:Float):ImageData { return null; };
	public function getLineDash():Array<Float> { return null; };
	public function isPointInPath(x:Float, y:Float):Bool { return false; };
	public function lineTo(x:Float, y:Float):Void {};
	public function measureText(text:String):TextMetrics { return null; };
	public function moveTo(x:Float, y:Float):Void {};
	@:overload(function(imagedata:ImageData, dx:Float, dy:Float):Void {})
	public function putImageData(imagedata:ImageData, dx:Float, dy:Float, dirtyX:Float, dirtyY:Float, dirtyWidth:Float, dirtyHeight:Float):Void {};
	@:overload(function(imagedata:ImageData, dx:Float, dy:Float):Void {})
	public function putImageDataHD(imagedata:ImageData, dx:Float, dy:Float, dirtyX:Float, dirtyY:Float, dirtyWidth:Float, dirtyHeight:Float):Void {};
	public function quadraticCurveTo(cpx:Float, cpy:Float, x:Float, y:Float):Void {};
	public function rect(x:Float, y:Float, width:Float, height:Float):Void {};
	public function restore():Void {};
	public function rotate(angle:Float):Void {};
	public function save():Void {};
	public function scale(sx:Float, sy:Float):Void {};
	public function setAlpha(alpha:Float):Void {};
	public function setCompositeOperation(compositeOperation:String):Void {};
	@:overload(function(color:String, ?alpha:Float):Void {})
	@:overload(function(grayLevel:Float, ?alpha:Float):Void {})
	@:overload(function(r:Float, g:Float, b:Float, a:Float):Void {})
	public function setFillColor(c:Float, m:Float, y:Float, k:Float, a:Float):Void {};
	public function setLineCap(cap:String):Void {};
	public function setLineDash(dash:Array<Float>):Void {};
	public function setLineJoin(join:String):Void {};
	public function setLineWidth(width:Float):Void {};
	public function setMiterLimit(limit:Float):Void {};
	@:overload(function(width:Float, height:Float, blur:Float, ?color:String, ?alpha:Float):Void {})
	@:overload(function(width:Float, height:Float, blur:Float, grayLevel:Float, ?alpha:Float):Void {})
	@:overload(function(width:Float, height:Float, blur:Float, r:Float, g:Float, b:Float, a:Float):Void {})
	public function setShadow(width:Float, height:Float, blur:Float, c:Float, m:Float, y:Float, k:Float, a:Float):Void {};
	@:overload(function(color:String, ?alpha:Float):Void {})
	@:overload(function(grayLevel:Float, ?alpha:Float):Void {})
	@:overload(function(r:Float, g:Float, b:Float, a:Float):Void {})
	public function setStrokeColor (c:Float, m:Float, y:Float, k:Float, a:Float):Void {};
	public function setTransform (m11:Float, m12:Float, m21:Float, m22:Float, dx:Float, dy:Float):Void {};
	public function stroke ():Void {};
	public function strokeRect (x:Float, y:Float, width:Float, height:Float, ?lineWidth:Float):Void {};
	public function strokeText (text:String, x:Float, y:Float, ?maxWidth:Float):Void {};
	public function transform (m11:Float, m12:Float, m21:Float, m22:Float, dx:Float, dy:Float):Void {};
	public function translate (tx:Float, ty:Float):Void {};
	
	
}


#end