package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;
import lime.text.Font;

@:forward
@:access(lime._internal.backend.native.NativeCFFI)
abstract HBFTFont(HBFont) to HBFont from CFFIPointer to CFFIPointer
{
	public var loadFlags(get, set):Int;

	public function new(font:Font)
	{
		if (font.src != null)
		{
			#if (lime_cffi && lime_harfbuzz && !macro)
			// this = NativeCFFI.lime_hb_ft_font_create (font.src);
			this = NativeCFFI.lime_hb_ft_font_create_referenced(font.src);
			#else
			this = null;
			#end
		}
		else
		{
			this = null;
		}
	}

	// Get & Set Methods
	@:noCompletion private inline function get_loadFlags():Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_ft_font_get_load_flags(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function set_loadFlags(value:Int):Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_ft_font_set_load_flags(this, value);
		#end
		return value;
	}
}
#end
