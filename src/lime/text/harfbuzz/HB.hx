package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
import lime._internal.backend.native.NativeCFFI;

@:access(lime._internal.backend.native.NativeCFFI)
class HB
{
	public static function shape(font:HBFont, buffer:HBBuffer, features:Array<HBFeature> = null):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_shape(font, buffer, #if hl null #else features #end);
		#end
	}
}
#end
