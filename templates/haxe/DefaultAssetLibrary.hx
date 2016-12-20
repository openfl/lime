package;


import haxe.Timer;
import haxe.Unserializer;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.AssetType;
import lime.utils.Bytes;
import lime.utils.Log;

#if sys
import haxe.io.Path;
import sys.FileSystem;
#end


@:keep class DefaultAssetLibrary extends AssetLibrary {
	
	
	private var lastModified:Float;
	private var timer:Timer;
	
	#if (windows && !cs)
	private var rootPath = FileSystem.absolutePath (Path.directory (#if (haxe_ver >= 3.3) Sys.programPath () #else Sys.executablePath () #end)) + "/";
	#else
	private var rootPath = "";
	#end
	
	
	public function new () {
		
		super ();
		
		#if (openfl && !flash)
		::if (assets != null)::
		::foreach assets::::if (type == "font")::openfl.text.Font.registerFont (__ASSET__OPENFL__::flatName::);::end::
		::end::::end::
		#end
		
		#if flash
		
		::if (assets != null)::::foreach assets::::if (embed)::classTypes.set ("::id::", __ASSET__::flatName::);::else::paths.set ("::id::", "::resourceName::");::end::
		types.set ("::id::", AssetType.$$upper(::type::));
		::end::::end::
		
		#elseif html5
		
		::if (assets != null)::var id;
		::foreach assets::id = "::id::";
		::if (embed)::::if (type == "font")::classTypes.set (id, __ASSET__::flatName::); preload.set (id, true);::else::paths.set (id, ::if (resourceName == id)::id::else::"::resourceName::"::end::);::end::
		::else::paths.set (id, ::if (resourceName == id)::id::else::"::resourceName::"::end::);::end::
		types.set (id, AssetType.$$upper(::type::));
		::end::::end::
		
		var assetsPrefix = null;
		if (ApplicationMain.config != null && Reflect.hasField (ApplicationMain.config, "assetsPrefix")) {
			assetsPrefix = ApplicationMain.config.assetsPrefix;
		}
		if (assetsPrefix != null) {
			for (k in paths.keys()) {
				paths.set(k, assetsPrefix + paths[k]);
			}
		}
		
		for (id in paths.keys()) {
			preload.set (id, true);
		}
		
		#else
		
		#if (windows || mac || linux)
		
		var useManifest = false;
		::if (assets != null)::::foreach assets::::if (type == "font")::
		classTypes.set ("::id::", __ASSET__::flatName::);
		types.set ("::id::", AssetType.$$upper(::type::));
		::else::::if (embed)::
		classTypes.set ("::id::", __ASSET__::flatName::);
		types.set ("::id::", AssetType.$$upper(::type::));
		::else::useManifest = true;
		::end::::end::::end::::end::
		
		if (useManifest) {
			
			loadManifest ();
			
			if (false && Sys.args ().indexOf ("-livereload") > -1) {
				
				var path = FileSystem.fullPath ("manifest");
				
				if (FileSystem.exists (path)) {
					
					lastModified = FileSystem.stat (path).mtime.getTime ();
					
					timer = new Timer (2000);
					timer.run = function () {
						
						var modified = FileSystem.stat (path).mtime.getTime ();
						
						if (modified > lastModified) {
							
							lastModified = modified;
							loadManifest ();
							
							onChange.dispatch ();
							
						}
						
					}
					
				}
				
			}
			
		}
		
		#else
		
		loadManifest ();
		
		#end
		#end
		
	}
	
	
	#if (!flash && !html5)
	private function loadManifest ():Void {
		
		try {
			
			#if blackberry
			var manifest = AssetManifest.fromFile ("app/native/manifest");
			#elseif tizen
			var manifest = AssetManifest.fromFile ("../res/manifest");
			#elseif emscripten
			var manifest = AssetManifest.fromFile ("assets/manifest");
			#elseif (mac && java)
			var manifest = AssetManifest.fromFile ("../Resources/manifest");
			#elseif (ios || tvos)
			var manifest = AssetManifest.fromFile ("assets/manifest");
			#else
			var manifest = AssetManifest.fromFile ("manifest");
			#end
			
			if (manifest != null) {
				
				for (asset in manifest.assets) {
					
					if (!classTypes.exists (asset.id)) {
						
						#if (ios || tvos)
						paths.set (asset.id, rootPath + "assets/" + asset.path);
						#else
						paths.set (asset.id, rootPath + asset.path);
						#end
						types.set (asset.id, cast (asset.type, AssetType));
						
					}
					
				}
				
			} else {
				
				Log.warn ("Could not load asset manifest (bytes was null)");
				
			}
		
		} catch (e:Dynamic) {
			
			Log.warn ('Could not load asset manifest (${e})');
			
		}
		
	}
	#end
	
	
}


#if !display
#if flash

::foreach assets::::if (embed)::::if (type == "image")::@:keep @:bind #if display private #end class __ASSET__::flatName:: extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }::else::@:keep @:bind #if display private #end class __ASSET__::flatName:: extends ::flashClass:: { }::end::::end::
::end::

#elseif html5

::foreach assets::::if (type == "font")::@:keep #if display private #end class __ASSET__::flatName:: extends lime.text.Font { public function new () { super (); name = "::fontName::"; } } ::end::
::end::

#else

::if (assets != null)::::foreach assets::::if (!embed)::::if (type == "font")::@:keep #if display private #end class __ASSET__::flatName:: extends lime.text.Font { public function new () { __fontPath = #if (ios || tvos) "assets/" + #end "::targetPath::"; name = "::fontName::"; super (); }}
::end::::end::::end::::end::

#if (windows || mac || linux || cpp)

::if (assets != null)::
::foreach assets::::if (embed)::::if (type == "image")::@:image("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends lime.graphics.Image {}
::elseif (type == "sound")::@:file("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends haxe.io.Bytes {}
::elseif (type == "music")::@:file("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends haxe.io.Bytes {}
::elseif (type == "font")::@:font("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends lime.text.Font {}
::else::@:file("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends haxe.io.Bytes {}
::end::::end::::end::
::end::

#end
#end

#if (openfl && !flash)
::if (assets != null)::::foreach assets::::if (type == "font")::@:keep #if display private #end class __ASSET__OPENFL__::flatName:: extends openfl.text.Font { public function new () { ::if (embed)::var font = new __ASSET__::flatName:: (); src = font.src; name = font.name;::else::__fontPath = #if (ios || tvos) "assets/" + #end "::targetPath::"; name = "::fontName::";::end:: super (); }}
::end::::end::::end::
#end

#end
