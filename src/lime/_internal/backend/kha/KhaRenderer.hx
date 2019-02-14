package lime._internal.backend.kha;

import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.Renderer;
import lime.math.Rectangle;
import lime.utils.UInt8Array;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.ui.Window)
class KhaRenderer
{
	public var handle:Dynamic;

	private var parent:Renderer;
	private var useHardware:Bool = true;

	public function new(parent:Renderer)
	{
		this.parent = parent;
	}

	public function create():Void
	{
		parent.context = KHA;
		parent.type = KHA;
	}

	private function dispatch():Void {}

	public function flip():Void {}

	public function readPixels(rect:Rectangle):Image
	{
		return null;
	}

	public function render():Void {}
}
