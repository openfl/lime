package flash.display;

extern class Stage extends DisplayObjectContainer
{
	var align:StageAlign;
	var allowsFullScreen(default, never):Bool;
	@:require(flash11_3) var allowsFullScreenInteractive(default, never):Bool;
	#if air
	var autoOrients:Bool;
	#end
	var browserZoomFactor(default, never):Float;
	@:require(flash10_2) var color:UInt;
	@:require(flash10) var colorCorrection:ColorCorrection;
	@:require(flash10) var colorCorrectionSupport(default, never):ColorCorrectionSupport;
	@:require(flash11_4) var contentsScaleFactor(default, never):Float;
	#if air
	var deviceOrientation(default, never):StageOrientation;
	#end
	@:require(flash11) var displayContextInfo(default, never):String;
	// var constructor : Dynamic;
	var displayState:StageDisplayState;
	var focus:InteractiveObject;
	var frameRate:Float;
	var fullScreenHeight(default, never):UInt;
	var fullScreenSourceRect:flash.geom.Rectangle;
	var fullScreenWidth(default, never):UInt;
	@:require(flash11_2) var mouseLock:Bool;
	#if air
	var nativeWindow(default, never):NativeWindow;
	var orientation(default, never):StageOrientation;
	#end
	var quality:StageQuality;
	var scaleMode:StageScaleMode;
	var showDefaultContextMenu:Bool;
	@:require(flash11) var softKeyboardRect(default, never):flash.geom.Rectangle;
	@:require(flash11) var stage3Ds(default, never):flash.Vector<Stage3D>;
	var stageFocusRect:Bool;
	var stageHeight:Int;
	@:require(flash10_2) var stageVideos(default, never):flash.Vector<flash.media.StageVideo>;
	var stageWidth:Int;
	#if air
	var supportedOrientations(default, never):flash.Vector<StageOrientation>;
	#end
	@:require(flash10_1) var wmodeGPU(default, never):Bool;
	#if air
	function assignFocus(objectToFocus:InteractiveObject, direction:FocusDirection):Void;
	#end
	function invalidate():Void;
	function isFocusInaccessible():Bool;
	#if air
	function setAspectRatio(newAspectRatio:StageAspectRatio):Void;
	function setOrientation(newOrientation:StageOrientation):Void;
	static var supportsOrientationChange(default, never):Bool;
	#end
}
