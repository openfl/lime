package flash.display;

extern class Stage extends DisplayObjectContainer
{
	#if (haxe_ver < 4.3)
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
	static var supportsOrientationChange(default, never):Bool;
	#else
	@:flash.property var align(get, set):StageAlign;
	@:flash.property var allowsFullScreen(get, never):Bool;
	@:flash.property @:require(flash11_3) var allowsFullScreenInteractive(get, never):Bool;
	#if air
	@:flash.property var autoOrients(get, set):Bool;
	#end
	@:flash.property var browserZoomFactor(get, never):Float;
	@:flash.property @:require(flash10_2) var color(get, set):UInt;
	@:flash.property @:require(flash10) var colorCorrection(get, set):ColorCorrection;
	@:flash.property @:require(flash10) var colorCorrectionSupport(get, never):ColorCorrectionSupport;
	@:flash.property @:require(flash11_4) var contentsScaleFactor(get, never):Float;
	#if air
	@:flash.property var deviceOrientation(get, never):StageOrientation;
	#end
	@:flash.property @:require(flash11) var displayContextInfo(get, never):String;
	@:flash.property var displayState(get, set):StageDisplayState;
	@:flash.property var focus(get, set):InteractiveObject;
	@:flash.property var frameRate(get, set):Float;
	@:flash.property var fullScreenHeight(get, never):UInt;
	@:flash.property var fullScreenSourceRect(get, set):flash.geom.Rectangle;
	@:flash.property var fullScreenWidth(get, never):UInt;
	@:flash.property @:require(flash11_2) var mouseLock(get, set):Bool;
	#if air
	@:flash.property var nativeWindow(get, never):NativeWindow;
	@:flash.property var orientation(get, never):StageOrientation;
	#end
	@:flash.property var quality(get, set):StageQuality;
	@:flash.property var scaleMode(get, set):StageScaleMode;
	@:flash.property var showDefaultContextMenu(get, set):Bool;
	@:flash.property @:require(flash11) var softKeyboardRect(get, never):flash.geom.Rectangle;
	@:flash.property @:require(flash11) var stage3Ds(get, never):flash.Vector<Stage3D>;
	@:flash.property var stageFocusRect(get, set):Bool;
	@:flash.property var stageHeight(get, set):Int;
	@:flash.property @:require(flash10_2) var stageVideos(get, never):flash.Vector<flash.media.StageVideo>;
	@:flash.property var stageWidth(get, set):Int;
	#if air
	@:flash.property var supportedOrientations(get, never):flash.Vector<StageOrientation>;
	#end
	@:flash.property @:require(flash10_1) var wmodeGPU(get, never):Bool;
	@:flash.property static var supportsOrientationChange(get, never):Bool;
	#end
	#if air
	function assignFocus(objectToFocus:InteractiveObject, direction:FocusDirection):Void;
	#end
	function invalidate():Void;
	function isFocusInaccessible():Bool;
	#if air
	function setAspectRatio(newAspectRatio:StageAspectRatio):Void;
	function setOrientation(newOrientation:StageOrientation):Void;
	#end

	#if (haxe_ver >= 4.3)
	private function get_align():StageAlign;
	private function get_allowsFullScreen():Bool;
	private function get_allowsFullScreenInteractive():Bool;
	private function get_browserZoomFactor():Float;
	private function get_color():UInt;
	private function get_colorCorrection():ColorCorrection;
	private function get_colorCorrectionSupport():ColorCorrectionSupport;
	private function get_constructor():Dynamic;
	private function get_contentsScaleFactor():Float;
	private function get_displayContextInfo():String;
	private function get_displayState():StageDisplayState;
	private function get_focus():InteractiveObject;
	private function get_frameRate():Float;
	private function get_fullScreenHeight():UInt;
	private function get_fullScreenSourceRect():flash.geom.Rectangle;
	private function get_fullScreenWidth():UInt;
	private function get_mouseLock():Bool;
	private function get_quality():StageQuality;
	private function get_scaleMode():StageScaleMode;
	private function get_showDefaultContextMenu():Bool;
	private function get_softKeyboardRect():flash.geom.Rectangle;
	private function get_stage3Ds():Vector<Stage3D>;
	private function get_stageFocusRect():Bool;
	private function get_stageHeight():Int;
	private function get_stageVideos():Vector<flash.media.StageVideo>;
	private function get_stageWidth():Int;
	private function get_wmodeGPU():Bool;
	private function set_align(value:StageAlign):StageAlign;
	private function set_color(value:UInt):UInt;
	private function set_colorCorrection(value:ColorCorrection):ColorCorrection;
	private function set_constructor(value:Dynamic):Dynamic;
	private function set_displayState(value:StageDisplayState):StageDisplayState;
	private function set_focus(value:InteractiveObject):InteractiveObject;
	private function set_frameRate(value:Float):Float;
	private function set_fullScreenSourceRect(value:flash.geom.Rectangle):flash.geom.Rectangle;
	private function set_mouseLock(value:Bool):Bool;
	private function set_quality(value:StageQuality):StageQuality;
	private function set_scaleMode(value:StageScaleMode):StageScaleMode;
	private function set_showDefaultContextMenu(value:Bool):Bool;
	private function set_stageFocusRect(value:Bool):Bool;
	private function set_stageHeight(value:Int):Int;
	private function set_stageWidth(value:Int):Int;
	#if air
	private static function get_supportsOrientationChange():Bool;
	private function get_autoOrients():Bool;
	private function get_deviceOrientation():StageOrientation;
	private function get_nativeWindow():NativeWindow;
	private function get_orientation():StageOrientation;
	private function get_supportedOrientations():Vector<StageOrientation>;
	private function get_vsyncEnabled():Bool;
	private function set_autoOrients(value:Bool):Bool;
	private function set_vsyncEnabled(value:Bool):Bool;
	#end
	#end
}
