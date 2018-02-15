package;


import lime.app.Config;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets;

#if sys
import sys.FileSystem;
#end

@:access(lime.utils.Assets)


@:keep @:dox(hide) class ManifestResources {
	
	
	public static var preloadLibraries:Array<AssetLibrary>;
	public static var preloadLibraryNames:Array<String>;
	
	
	public static function init (config:Config):Void {
		
		preloadLibraries = new Array ();
		preloadLibraryNames = new Array ();
		
		var rootPath = null;
		
		if (config != null && Reflect.hasField (config, "rootPath")) {
			
			rootPath = Reflect.field (config, "rootPath");
			
		}
		
		if (rootPath == null) {
			
			#if (ios || tvos || emscripten)
			rootPath = "assets/";
			#elseif (sys && windows && !cs)
			rootPath = FileSystem.absolutePath (haxe.io.Path.directory (#if (haxe_ver >= 3.3) Sys.programPath () #else Sys.executablePath () #end)) + "/";
			#else
			rootPath = "";
			#end
			
		}
		
		Assets.defaultRootPath = rootPath;
		
		#if (openfl && !flash && !display)
		::if (assets != null)::::foreach assets::::if (type == "font")::openfl.text.Font.registerFont (__ASSET__OPENFL__::flatName::);
		::end::::end::::end::
		#end
		
		var data, manifest, library;
		
		::if (assets != null)::::foreach assets::::if (type == "manifest")::::if (embed)::data = '::data::';
		manifest = AssetManifest.parse (data, rootPath);
		library = AssetLibrary.fromManifest (manifest);
		Assets.registerLibrary ("::library::", library);
		::else::Assets.libraryPaths["::library::"] = rootPath + "::resourceName::";
		::end::::end::::end::::end::
		
		::foreach libraries::::if (preload)::library = Assets.getLibrary ("::name::");
		if (library != null) preloadLibraries.push (library);
		else preloadLibraryNames.push ("::name::");
		::end::::end::
		
	}
	
	
}


#if !display
#if flash

::foreach assets::::if (embed != false)::::if (type == "image")::@:keep @:bind #if display private #end class __ASSET__::flatName:: extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }::else::@:keep @:bind #if display private #end class __ASSET__::flatName:: extends ::flashClass:: { }::end::
::end::::end::

#elseif (desktop || cpp)

::if (assets != null)::::foreach assets::::if (embed)::::if (type == "image")::@:image("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends lime.graphics.Image {}
::elseif (type == "sound")::@:file("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends haxe.io.Bytes {}
::elseif (type == "music")::@:file("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends haxe.io.Bytes {}
::elseif (type == "font")::@:font("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends lime.text.Font {}
::else::@:file("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends haxe.io.Bytes {}
::end::::end::::end::::end::
::if (assets != null)::::foreach assets::::if (!embed)::::if (type == "font")::@:keep #if display private #end class __ASSET__::flatName:: extends lime.text.Font { public function new () { ::if (targetPath != null)::__fontPath = #if (ios || tvos) "assets/" + #end "::targetPath::";::else::::if (library != null)::__fontID = "::library:::::id::";::else::__fontID = "::id::";::end::::end:: name = "::fontName::"; super (); }}
::end::::end::::end::::end::

#else

::if (assets != null)::::foreach assets::::if (type == "font")::@:keep @:expose('__ASSET__::flatName::') #if display private #end class __ASSET__::flatName:: extends lime.text.Font { public function new () { #if !html5 __fontPath = "::targetPath::"; #else ascender = ::ascender::; descender = ::descender::; height = ::height::; numGlyphs = ::numGlyphs::; underlinePosition = ::underlinePosition::; underlineThickness = ::underlineThickness::; unitsPerEM = ::unitsPerEM::; #end name = "::fontName::"; super (); }}
::end::::end::::end::

#end

#if (openfl && !flash)

::if (assets != null)::::foreach assets::::if (type == "font")::@:keep @:expose('__ASSET__OPENFL__::flatName::') #if display private #end class __ASSET__OPENFL__::flatName:: extends openfl.text.Font { public function new () { ::if (embed)::__fromLimeFont (new __ASSET__::flatName:: ());::else::#if !html5 ::if (targetPath != null)::__fontPath = #if (ios || tvos) "assets/" + #end "::targetPath::";::else::::if (library != null)::__fontID = "::library:::::id::";::else::__fontID = "::id::";::end::::end:: #end name = "::fontName::";::end:: super (); }}
::end::::end::::end::

#end
#end