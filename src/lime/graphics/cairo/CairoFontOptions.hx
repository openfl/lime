package lime.graphics.cairo;

#if (!lime_doc_gen || native)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;
import lime.text.Font;

@:access(lime._internal.backend.native.NativeCFFI)
abstract CairoFontOptions(CFFIPointer) from CFFIPointer to CFFIPointer
{
	public var antialias(get, set):CairoAntialias;
	public var hintMetrics(get, set):CairoHintMetrics;
	public var hintStyle(get, set):CairoHintStyle;
	public var subpixelOrder(get, set):CairoSubpixelOrder;

	public function new()
	{
		#if (lime_cffi && lime_cairo && !macro)
		this = NativeCFFI.lime_cairo_font_options_create();
		#else
		this = null;
		#end
	}

	// Get & Set Methods
	@:noCompletion private function get_antialias():CairoAntialias
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_font_options_get_antialias(this);
		#end

		return cast 0;
	}

	@:noCompletion private function set_antialias(value:CairoAntialias):CairoAntialias
	{
		#if (lime_cffi && lime_cairo && !macro)
		NativeCFFI.lime_cairo_font_options_set_antialias(this, value);
		#end

		return value;
	}

	@:noCompletion private function get_hintMetrics():CairoHintMetrics
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_font_options_get_hint_metrics(this);
		#end

		return cast 0;
	}

	@:noCompletion private function set_hintMetrics(value:CairoHintMetrics):CairoHintMetrics
	{
		#if (lime_cffi && lime_cairo && !macro)
		NativeCFFI.lime_cairo_font_options_set_hint_metrics(this, value);
		#end

		return value;
	}

	@:noCompletion private function get_hintStyle():CairoHintStyle
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_font_options_get_hint_style(this);
		#end

		return cast 0;
	}

	@:noCompletion private function set_hintStyle(value:CairoHintStyle):CairoHintStyle
	{
		#if (lime_cffi && lime_cairo && !macro)
		NativeCFFI.lime_cairo_font_options_set_hint_style(this, value);
		#end

		return value;
	}

	@:noCompletion private function get_subpixelOrder():CairoSubpixelOrder
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_font_options_get_subpixel_order(this);
		#end

		return cast 0;
	}

	@:noCompletion private function set_subpixelOrder(value:CairoSubpixelOrder):CairoSubpixelOrder
	{
		#if (lime_cffi && lime_cairo && !macro)
		NativeCFFI.lime_cairo_font_options_set_subpixel_order(this, value);
		#end

		return value;
	}
}
#end
