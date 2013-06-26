package nme;


import lime.utils.Assets;


class AssetData {

	
	public static var className = new Map <String, Dynamic> ();
	public static var library = new Map <String, LibraryType> ();
	public static var path = new Map <String, String> ();
	public static var type = new Map <String, AssetType> ();
	
	private static var initialized:Bool = false;
	
	
	public static function initialize ():Void {
		
		if (!initialized) {
			
			::if (assets != null)::::foreach assets::::if (type == "font")::className.set ("::id::", nme.NME_::flatName::);::else::path.set ("::id::", "::resourceName::");::end::
			type.set ("::id::", Reflect.field (AssetType, "::type::".toUpperCase ()));
			::end::::end::
			::if (libraries != null)::::foreach libraries::library.set ("::name::", Reflect.field (LibraryType, "::type::".toUpperCase ()));
			::end::::end::
			initialized = true;
			
		}
		
	}
	
	
}


::foreach assets::::if (type == "font")::class NME_::flatName:: extends flash.text.Font { }::end::
::end::