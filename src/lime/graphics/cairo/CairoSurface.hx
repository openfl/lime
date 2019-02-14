package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;

@:access(lime._internal.backend.native.NativeCFFI)
abstract CairoSurface(CFFIPointer) from CFFIPointer to CFFIPointer
{
	public function flush():Void
	{
		#if (lime_cffi && lime_cairo && !macro)
		NativeCFFI.lime_cairo_surface_flush(this);
		#end
	}
}
#end
