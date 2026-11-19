package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;

/**
	A buffer's direction, script and language together, as
	`HBBuffer.segmentProperties` reads and sets them. A new one has HarfBuzz's
	defaults: no direction, script or language.
**/
@:access(lime._internal.backend.native.NativeCFFI)
class HBSegmentProperties
{
	@:noCompletion private var __handle:CFFIPointer;

	public function new()
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		__handle = NativeCFFI.lime_hb_segment_properties_create();
		#end
	}
	// @:cffi private static function lime_hb_segment_properties_equal (a:CFFIPointer, b:CFFIPointer):Bool;
	// @:cffi private static function lime_hb_segment_properties_hash (p:CFFIPointer):Int;
}
#end
