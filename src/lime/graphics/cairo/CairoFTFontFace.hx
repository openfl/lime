package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;
import lime.text.Font;

@:access(lime._internal.backend.native.NativeCFFI)
abstract CairoFTFontFace(CairoFontFace) from CairoFontFace to CairoFontFace from CFFIPointer to CFFIPointer
{
	public static inline var FT_LOAD_FORCE_AUTOHINT = (1 << 5);

	@:noCompletion private function new()
	{
		this = cast 0;
	}

	public static function create(face:Font, loadFlags:Int):CairoFTFontFace
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_ft_font_face_create(face.src, loadFlags);
		#else
		return cast 0;
		#end
	}
}
#end
