package lime.text.harfbuzz;


import lime._backend.native.NativeCFFI;
import lime.system.CFFIPointer;
import lime.text.Font;

@:forward
@:access(lime._backend.native.NativeCFFI)


abstract HBFTFont(HBFont) to HBFont from CFFIPointer to CFFIPointer {
	
	
	public var loadFlags (get, set):Int;
	
	
	public function new (font:Font) {
		
		#if (lime_cffi && lime_harfbuzz && !macro)
		this = NativeCFFI.lime_hb_ft_font_create_referenced (font.src);
		#else
		this = null;
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private inline function get_loadFlags ():Int {
		
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_ft_font_get_load_flags (this);
		#else
		return 0;
		#end
		
	}
	
	
	private inline function set_loadFlags (value:Int):Int {
		
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_ft_font_set_load_flags (this, value);
		#end
		return value;
		
	}
	
	
}