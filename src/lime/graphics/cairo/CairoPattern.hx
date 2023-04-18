package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
import lime._internal.backend.native.NativeCFFI;
import lime.math.Matrix3;
import lime.system.CFFIPointer;

@:access(lime._internal.backend.native.NativeCFFI)
abstract CairoPattern(CFFIPointer) from CFFIPointer to CFFIPointer
{
	public var colorStopCount(get, never):Int;
	public var extend(get, set):CairoExtend;
	public var filter(get, set):CairoFilter;
	public var matrix(get, set):Matrix3;

	public function new(handle)
	{
		this = handle;
	}

	public function addColorStopRGB(offset:Float, r:Float, g:Float, b:Float):Void
	{
		#if (lime_cffi && lime_cairo && !macro)
		NativeCFFI.lime_cairo_pattern_add_color_stop_rgb(this, offset, r, g, b);
		#end
	}

	public function addColorStopRGBA(offset:Float, r:Float, g:Float, b:Float, a:Float):Void
	{
		#if (lime_cffi && lime_cairo && !macro)
		NativeCFFI.lime_cairo_pattern_add_color_stop_rgba(this, offset, r, g, b, a);
		#end
	}

	public static function createForSurface(surface:CairoSurface):CairoPattern
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_pattern_create_for_surface(surface);
		#else
		return cast 0;
		#end
	}

	public static function createLinear(x0:Float, y0:Float, x1:Float, y1:Float):CairoPattern
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_pattern_create_linear(x0, y0, x1, y1);
		#else
		return cast 0;
		#end
	}

	public static function createRadial(cx0:Float, cy0:Float, radius0:Float, cx1:Float, cy1:Float, radius1:Float):CairoPattern
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_pattern_create_radial(cx0, cy0, radius0, cx1, cy1, radius1);
		#else
		return cast 0;
		#end
	}

	public static function createRGB(r:Float, g:Float, b:Float):CairoPattern
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_pattern_create_rgb(r, g, b);
		#else
		return cast 0;
		#end
	}

	public static function createRGBA(r:Float, g:Float, b:Float, a:Float):CairoPattern
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_pattern_create_rgba(r, g, b, a);
		#else
		return cast 0;
		#end
	}

	// Get & Set Methods
	@:noCompletion private function get_colorStopCount():Int
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_pattern_get_color_stop_count(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private function get_extend():CairoExtend
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_pattern_get_extend(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private function set_extend(value:CairoExtend):CairoExtend
	{
		#if (lime_cffi && lime_cairo && !macro)
		NativeCFFI.lime_cairo_pattern_set_extend(this, value);
		#end

		return value;
	}

	@:noCompletion private function get_filter():CairoFilter
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_pattern_get_filter(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private function set_filter(value:CairoFilter):CairoFilter
	{
		#if (lime_cffi && lime_cairo && !macro)
		NativeCFFI.lime_cairo_pattern_set_filter(this, value);
		#end

		return value;
	}

	@:noCompletion private function get_matrix():Matrix3
	{
		#if (lime_cffi && lime_cairo && !macro)
		#if hl
		return NativeCFFI.lime_cairo_pattern_get_matrix(this, new Matrix3());
		#else
		var m:Dynamic = NativeCFFI.lime_cairo_pattern_get_matrix(this);
		return new Matrix3(m.a, m.b, m.c, m.d, m.tx, m.ty);
		#end
		#else
		return null;
		#end
	}

	@:noCompletion private function set_matrix(value:Matrix3):Matrix3
	{
		#if (lime_cffi && lime_cairo && !macro)
		NativeCFFI.lime_cairo_pattern_set_matrix(this, value);
		#end

		return value;
	}
}
#end
