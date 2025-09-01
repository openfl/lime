package flash.display;

extern class DisplayObject extends flash.events.EventDispatcher implements IBitmapDrawable
{
	#if (haxe_ver < 4.3)
	var accessibilityProperties:flash.accessibility.AccessibilityProperties;
	var alpha:Float;
	var blendMode:BlendMode;
	@:require(flash10) var blendShader(never, default):Shader;
	var cacheAsBitmap:Bool;
	#if air
	var cacheAsBitmapMatrix:flash.geom.Matrix;
	#end
	var filters:Array<flash.filters.BitmapFilter>;
	var height:Float;
	var loaderInfo(default, never):LoaderInfo;
	var mask:DisplayObject;
	var mouseX(default, never):Float;
	var mouseY(default, never):Float;
	var name:String;
	var opaqueBackground:Null<UInt>;
	var parent(default, never):DisplayObjectContainer;
	var root(default, never):DisplayObject;
	var rotation:Float;
	@:require(flash10) var rotationX:Float;
	@:require(flash10) var rotationY:Float;
	@:require(flash10) var rotationZ:Float;
	var scale9Grid:flash.geom.Rectangle;
	var scaleX:Float;
	var scaleY:Float;
	@:require(flash10) var scaleZ:Float;
	var scrollRect:flash.geom.Rectangle;
	var stage(default, never):Stage;
	var transform:flash.geom.Transform;
	var visible:Bool;
	var width:Float;
	var x:Float;
	var y:Float;
	@:require(flash10) var z:Float;
	#else
	@:flash.property var accessibilityProperties:flash.accessibility.AccessibilityProperties;
	@:flash.property var alpha:Float;
	@:flash.property var blendMode:BlendMode;
	@:flash.property @:require(flash10) var blendShader(never, default):Shader;
	@:flash.property var cacheAsBitmap:Bool;
	#if air
	@:flash.property var cacheAsBitmapMatrix:flash.geom.Matrix;
	#end
	@:flash.property var filters(get, set):Array<flash.filters.BitmapFilter>;
	@:flash.property var height(get, set):Float;
	@:flash.property var loaderInfo(get, never):LoaderInfo;
	@:flash.property var mask(get, set):DisplayObject;
	@:flash.property var mouseX(get, never):Float;
	@:flash.property var mouseY(get, never):Float;
	@:flash.property var name(get, set):String;
	@:flash.property var opaqueBackground(get, set):Null<UInt>;
	@:flash.property var parent(get, never):DisplayObjectContainer;
	@:flash.property var root(get, never):DisplayObject;
	@:flash.property var rotation(get, set):Float;
	@:flash.property @:require(flash10) var rotationX(get, set):Float;
	@:flash.property @:require(flash10) var rotationY(get, set):Float;
	@:flash.property @:require(flash10) var rotationZ(get, set):Float;
	@:flash.property var scale9Grid(get, set):flash.geom.Rectangle;
	@:flash.property var scaleX(get, set):Float;
	@:flash.property var scaleY(get, set):Float;
	@:flash.property @:require(flash10) var scaleZ(get, set):Float;
	@:flash.property var scrollRect(get, set):flash.geom.Rectangle;
	@:flash.property var stage(get, never):Stage;
	@:flash.property var transform(get, set):flash.geom.Transform;
	@:flash.property var visible(get, set):Bool;
	@:flash.property var width(get, set):Float;
	@:flash.property var x(get, set):Float;
	@:flash.property var y(get, set):Float;
	@:flash.property @:require(flash10) var z(get, set):Float;
	#end
	function getBounds(targetCoordinateSpace:DisplayObject):flash.geom.Rectangle;
	function getRect(targetCoordinateSpace:DisplayObject):flash.geom.Rectangle;
	function globalToLocal(point:flash.geom.Point):flash.geom.Point;
	@:require(flash10) function globalToLocal3D(point:flash.geom.Point):flash.geom.Vector3D;
	function hitTestObject(obj:DisplayObject):Bool;
	function hitTestPoint(x:Float, y:Float, shapeFlag:Bool = false):Bool;
	@:require(flash10) function local3DToGlobal(point3d:flash.geom.Vector3D):flash.geom.Point;
	function localToGlobal(point:flash.geom.Point):flash.geom.Point;

	#if (haxe_ver >= 4.3)
	private function get_accessibilityProperties():flash.accessibility.AccessibilityProperties;
	private function get_alpha():Float;
	private function get_blendMode():BlendMode;
	private function get_cacheAsBitmap():Bool;
	private function get_filters():Array<flash.filters.BitmapFilter>;
	private function get_height():Float;
	private function get_loaderInfo():LoaderInfo;
	private function get_mask():DisplayObject;
	private function get_metaData():Dynamic;
	private function get_mouseX():Float;
	private function get_mouseY():Float;
	private function get_name():String;
	private function get_opaqueBackground():Null<UInt>;
	private function get_parent():DisplayObjectContainer;
	private function get_root():DisplayObject;
	private function get_rotation():Float;
	private function get_rotationX():Float;
	private function get_rotationY():Float;
	private function get_rotationZ():Float;
	private function get_scale9Grid():flash.geom.Rectangle;
	private function get_scaleX():Float;
	private function get_scaleY():Float;
	private function get_scaleZ():Float;
	private function get_scrollRect():flash.geom.Rectangle;
	private function get_stage():Stage;
	private function get_transform():flash.geom.Transform;
	private function get_visible():Bool;
	private function get_width():Float;
	private function get_x():Float;
	private function get_y():Float;
	private function get_z():Float;
	#if air
	private function get_cacheAsBitmapMatrix():flash.geom.Matrix;
	#end
	private function set_accessibilityProperties(value:flash.accessibility.AccessibilityProperties):flash.accessibility.AccessibilityProperties;
	private function set_alpha(value:Float):Float;
	private function set_blendMode(value:BlendMode):BlendMode;
	private function set_blendShader(value:Shader):Shader;
	private function set_cacheAsBitmap(value:Bool):Bool;
	private function set_filters(value:Array<flash.filters.BitmapFilter>):Array<flash.filters.BitmapFilter>;
	private function set_height(value:Float):Float;
	private function set_mask(value:DisplayObject):DisplayObject;
	private function set_metaData(value:Dynamic):Dynamic;
	private function set_name(value:String):String;
	private function set_opaqueBackground(value:Null<UInt>):Null<UInt>;
	private function set_rotation(value:Float):Float;
	private function set_rotationX(value:Float):Float;
	private function set_rotationY(value:Float):Float;
	private function set_rotationZ(value:Float):Float;
	private function set_scale9Grid(value:flash.geom.Rectangle):flash.geom.Rectangle;
	private function set_scaleX(value:Float):Float;
	private function set_scaleY(value:Float):Float;
	private function set_scaleZ(value:Float):Float;
	private function set_scrollRect(value:flash.geom.Rectangle):flash.geom.Rectangle;
	private function set_transform(value:flash.geom.Transform):flash.geom.Transform;
	private function set_visible(value:Bool):Bool;
	private function set_width(value:Float):Float;
	private function set_x(value:Float):Float;
	private function set_y(value:Float):Float;
	private function set_z(value:Float):Float;
	#if air
	private function set_cacheAsBitmapMatrix(value:flash.geom.Matrix):flash.geom.Matrix;
	#end
	#end
}
