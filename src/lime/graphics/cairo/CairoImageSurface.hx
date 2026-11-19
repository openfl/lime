package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;
import lime.utils.DataPointer;

@:access(lime._internal.backend.native.NativeCFFI)
@:forward abstract CairoImageSurface(CairoSurface) from CairoSurface to CairoSurface from CFFIPointer to CFFIPointer
{
	public var data(get, never):DataPointer;
	public var format(get, never):CairoFormat;
	public var height(get, never):Int;
	public var stride(get, never):Int;
	public var width(get, never):Int;

	public function new(format:CairoFormat, width:Int, height:Int):CairoSurface
	{
		#if (lime_cffi && lime_cairo && !macro)
		this = NativeCFFI.lime_cairo_image_surface_create(format, width, height);
		#else
		this = cast 0;
		#end
	}

	public static function create(data:DataPointer, format:CairoFormat, width:Int, height:Int, stride:Int):CairoSurface
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_image_surface_create_for_data(data, format, width, height, stride);
		#else
		return cast 0;
		#end
	}

	public static function fromImage(image:Image):CairoSurface
	{
		#if (lime_cffi && lime_cairo && !macro)
		#if nodejs
		return create(image.data, CairoFormat.ARGB32, image.width, image.height, image.buffer.stride);
		#else
		// From the image's first pixel, which for part of a larger buffer isn't the buffer's first
		var data:DataPointer = DataPointer.fromArrayBufferView(image.data);
		data = data + (image.offsetY * image.buffer.stride + image.offsetX * 4);
		return create(data, CairoFormat.ARGB32, image.width, image.height, image.buffer.stride);
		#end
		#else
		return null;
		#end
	}

	// Get & Set Methods
	@:noCompletion private function get_data():DataPointer
	{
		#if (lime_cffi && lime_cairo && !macro)
		// A cast, as on HashLink the binding gives a Float, which would become a DataPointer
		// through fromCFFIPointer and be read as a handle
		var data:Float = NativeCFFI.lime_cairo_image_surface_get_data(this);
		return cast data;
		#else
		return 0;
		#end
	}

	@:noCompletion private function get_format():CairoFormat
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_image_surface_get_format(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private function get_height():Int
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_image_surface_get_height(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private function get_stride():Int
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_image_surface_get_stride(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private function get_width():Int
	{
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_image_surface_get_width(this);
		#else
		return 0;
		#end
	}
}
#end
