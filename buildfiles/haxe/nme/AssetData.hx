package nme;


import lime.utils.Assets;


class AssetData {

	
	public static var library = new #if haxe3 Map <String, #else Hash <#end LibraryType> ();
	public static var path = new #if haxe3 Map <String, #else Hash <#end String> ();
	public static var type = new #if haxe3 Map <String, #else Hash <#end AssetType> ();
	
	private static var initialized:Bool = false;
	
	
	public static function initialize ():Void {
		
		if (!initialized) {
			
			::if (assets != null)::::foreach assets::path.set ("::id::", "::resourceName::");
			type.set ("::id::", Reflect.field (AssetType, "::type::".toUpperCase ()));
			::end::::end::
			::if (libraries != null)::::foreach libraries::library.set ("::name::", Reflect.field (LibraryType, "::type::".toUpperCase ()));
			::end::::end::
			initialized = true;
			
		}
		
	}
	
	
}
