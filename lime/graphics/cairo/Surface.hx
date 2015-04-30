package lime.graphics.cairo;


import lime.IncludePaths;
import lime.graphics.cairo.Format;


@:include("graphics/cairo/CairoSurface.h")
@:native("cpp::Struct<lime::CairoSurface>")
extern class Surface {

	@:native("lime::CairoSurface::createForData")
	public static function createForData (
		data:cpp.Pointer<cpp.UInt8>,
		format:Format,
		width:Int,
		height:Int,
		stride:Int
	):Surface;

	public function destroy ():Void;
	
}
