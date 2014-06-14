package lime.graphics;
#if flash
typedef FlashRenderContext = flash.display.Sprite;
#else


class FlashRenderContext {
	
	
	public var accessibilityImplementation:Dynamic /*flash.accessibility.AccessibilityImplementation*/;
	public var accessibilityProperties:Dynamic /*flash.accessibility.AccessibilityProperties*/;
	public var alpha:Float;
	public var blendMode:Dynamic /*BlendMode*/;
	public var blendShader (null, default):Dynamic /*Shader*/;
	public var buttonMode:Bool;
	public var cacheAsBitmap:Bool;
	public var contextMenu:Dynamic /*flash.ui.ContextMenu*/;
	public var doubleClickEnabled:Bool;
	public var dropTarget (default, null):Dynamic /*DisplayObject*/;
	public var filters:Array<Dynamic /*flash.filters.BitmapFilter*/>;
	public var focusRect:Dynamic;
	public var graphics (default, null):Dynamic /*Graphics*/;
	public var height:Float;
	public var hitArea:Dynamic /*Sprite*/;
	public var loaderInfo (default, null):Dynamic /*LoaderInfo*/;
	public var mask:Dynamic /*DisplayObject*/;
	public var mouseChildren:Bool;
	public var mouseEnabled:Bool;
	public var mouseX (default, null):Float;
	public var mouseY (default, null):Float;
	public var name:String;
	public var needsSoftKeyboard:Bool;
	public var numChildren (default, null):Int;
	public var opaqueBackground:Null<UInt>;
	public var parent (default, null):Dynamic /*DisplayObjectContainer*/;
	public var root (default, null):Dynamic /*DisplayObject*/;
	public var rotation:Float;
	public var rotationX:Float;
	public var rotationY:Float;
	public var rotationZ:Float;
	public var scale9Grid:Dynamic /*flash.geom.Rectangle*/;
	public var scaleX:Float;
	public var scaleY:Float;
	public var scaleZ:Float;
	public var scrollRect:Dynamic /*flash.geom.Rectangle*/;
	public var softKeyboardInputAreaOfInterest:Dynamic /*flash.geom.Rectangle*/;
	public var soundTransform:Dynamic /*flash.media.SoundTransform*/;
	public var stage (default, null):Dynamic /*Stage*/;
	public var tabChildren:Bool;
	public var tabEnabled:Bool;
	public var tabIndex:Int;
	public var textSnapshot (default, null):Dynamic /*flash.text.TextSnapshot*/;
	public var transform:Dynamic /*flash.geom.Transform*/;
	public var useHandCursor:Bool;
	public var visible:Bool;
	public var width:Float;
	public var x:Float;
	public var y:Float;
	public var z:Float;
	
	
	public function new () {
		
		
		
	}
	
	
	public function addChild (child:Dynamic /*DisplayObject*/):Dynamic /*DisplayObject*/ { return null; };
	public function addChildAt (child:Dynamic /*DisplayObject*/, index:Int):Dynamic /*DisplayObject*/ { return null; };
	public function addEventListener (type:String, listener:Dynamic->Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {};
	public function areInaccessibleObjectsUnderPoint (point:Dynamic /*flash.geom.Point*/):Bool { return false; };
	public function contains (child:Dynamic /*DisplayObject*/):Bool { return false; };
	public function dispatchEvent (event:Dynamic /*Event*/):Bool { return false; };
	public function getBounds (targetCoordinateSpace:Dynamic /*DisplayObject*/):Dynamic /*flash.geom.Rectangle*/ { return null; };
	public function getChildAt (index:Int):Dynamic /*DisplayObject*/ { return null; };
	public function getChildByName (name:String):Dynamic /*DisplayObject*/ { return null; };
	public function getChildIndex (child:Dynamic /*DisplayObject*/):Int { return 0; };
	public function getObjectsUnderPoint (point:Dynamic /*flash.geom.Point*/):Array<Dynamic /*DisplayObject*/> { return null; };
	public function getRect (targetCoordinateSpace:Dynamic /*DisplayObject*/):Dynamic /*flash.geom.Rectangle*/ { return null; };
	public function globalToLocal (point:Dynamic /*flash.geom.Point*/):Dynamic /*flash.geom.Point*/ { return null; };
	public function globalToLocal3D (point:Dynamic /*flash.geom.Point*/):Dynamic /*flash.geom.Vector3D*/ { return null; };
	public function hasEventListener (type:String):Bool { return false; };
	public function hitTestObject (obj:Dynamic /*DisplayObject*/):Bool { return false; };
	public function hitTestPoint (x:Float, y:Float, shapeFlag:Bool = false):Bool { return false; };
	public function local3DToGlobal (point3d:Dynamic /*flash.geom.Vector3D*/):Dynamic /*flash.geom.Point*/ { return null; };
	public function localToGlobal (point:Dynamic /*flash.geom.Point*/):Dynamic /*flash.geom.Point*/ { return null; };
	public function removeChild (child:Dynamic /*DisplayObject*/):Dynamic /*DisplayObject*/ { return null; };
	public function removeChildAt (index:Int):Dynamic /*DisplayObject*/ { return null; };
	public function removeChildren (beginIndex:Int = 0, endIndex:Int = 2147483647):Void {};
	public function removeEventListener (type:String, listener:Dynamic->Void, useCapture:Bool = false):Void {};
	public function requestSoftKeyboard ():Bool { return false; };
	public function setChildIndex (child:Dynamic /*DisplayObject*/, index:Int):Void {};
	public function startDrag (lockCenter:Bool = false, ?bounds:Dynamic /*flash.geom.Rectangle*/):Void {};
	public function startTouchDrag (touchPointID:Int, lockCenter:Bool = false, ?bounds:Dynamic /*flash.geom.Rectangle*/):Void {};
	public function stopAllMovieClips ():Void {};
	public function stopDrag ():Void {};
	public function stopTouchDrag (touchPointID:Int):Void {};
	public function swapChildren (child1:Dynamic /*DisplayObject*/, child2:Dynamic /*DisplayObject*/):Void {};
	public function swapChildrenAt (index1:Int, index2:Int):Void {};
	public function toString ():String { return null; };
	public function willTrigger (type:String):Bool { return false; };
	
	
}


#end