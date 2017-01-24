package;


import haxe.Resource;
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


@:keep @:dox(hide) class DefaultAssetLibrary extends AssetLibrary {
	
	
	private var lastModified:Float;
	private var rootPath:String;
	private var timer:Timer;
	
	
	public function new () {
		
		super ();
		
		if (ApplicationMain.config != null && Reflect.hasField (ApplicationMain.config, "assetsPrefix")) {
			
			rootPath = Reflect.field (ApplicationMain.config, "assetsPrefix");
			
		}
		
		if (rootPath == null) {
			
			#if (ios || tvos)
			rootPath = "assets/";
			#elseif (windows && !cs)
			rootPath = FileSystem.absolutePath (Path.directory (#if (haxe_ver >= 3.3) Sys.programPath () #else Sys.executablePath () #end)) + "/";
			#else
			rootPath = "";
			#end
			
		}
		
		#if (openfl && !flash && !display)
		::if (assets != null)::::foreach assets::::if (type == "font")::openfl.text.Font.registerFont (__ASSET__OPENFL__::flatName::);
		::end::::end::::end::
		#end
		
		var useManifest = #if html5 true #else false #end;
		var id;
		::if (assets != null)::::foreach assets::id = "::id::";::if (type == "font")::
		classTypes.set (id, __ASSET__::flatName::);
		types.set (id, AssetType.$$upper(::type::));
		#if html5
		preload.set (id, true);
		#end ::else::::if (embed)::
		#if html5
		preload.set (id, true);
		#elseif (desktop || cpp || flash)
		classTypes.set (id, __ASSET__::flatName::);
		types.set (id, AssetType.$$upper(::type::));
		#end
		::else::useManifest = true;
		::end::::end::::end::::end::
		
		if (useManifest) {
			
			loadManifest ();
			
			#if sys
			if (false && Sys.args ().indexOf ("-livereload") > -1) {
				
				var path = FileSystem.fullPath (rootPath + "manifest");
				
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
			#end
			
		}
		
	}
	
	
	private function loadManifest ():Void {
		
		var bytes = Resource.getBytes ("__ASSET_MANIFEST__");
		var manifest;
		
		if (bytes != null) {
			
			var manifest = AssetManifest.fromBytes (bytes);
			manifest.basePath = rootPath;
			__fromManifest (manifest);
			
		} else {
			
			// TODO: Make asynchronous
			
			var manifest = AssetManifest.fromFile (rootPath + "manifest");
			
			if (manifest != null) {
				
				manifest.basePath = rootPath;
				__fromManifest (manifest);
				
			} else {
				
				Log.warn ("Could not load asset manifest (bytes was null)");
				
			}
			
			//AssetManifest.loadFromFile (rootPath + "manifest").onComplete (function (manifest:AssetManifest) {
				//
				//if (manifest != null) {
					//
					//__fromManifest (manifest);
					//
				//} else {
					//
					//Log.warn ("Could not load asset manifest (bytes was null)");
					//
				//}
				//
				//__fromManifest (manifest);
				//
			//}).onError (function (e:Dynamic) {
				//
				//Log.warn ('Could not load asset manifest (${e})');
				//
			//});
			
		}
		
	}
	
	
}


#if !display
#if flash

::foreach assets::::if (embed)::::if (type == "image")::@:keep @:bind #if display private #end class __ASSET__::flatName:: extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }::else::@:keep @:bind #if display private #end class __ASSET__::flatName:: extends ::flashClass:: { }::end::::end::
::end::

#elseif (desktop || cpp)

::if (assets != null)::::foreach assets::::if (embed)::::if (type == "image")::@:image("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends lime.graphics.Image {}
::elseif (type == "sound")::@:file("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends haxe.io.Bytes {}
::elseif (type == "music")::@:file("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends haxe.io.Bytes {}
::elseif (type == "font")::@:font("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends lime.text.Font {}
::else::@:file("::sourcePath::") #if display private #end class __ASSET__::flatName:: extends haxe.io.Bytes {}::end::::end::::end::::end::

::if (assets != null)::::foreach assets::::if (!embed)::::if (type == "font")::@:keep #if display private #end class __ASSET__::flatName:: extends lime.text.Font { public function new () { __fontPath = #if (ios || tvos) "assets/" + #end "::targetPath::"; name = "::fontName::"; super (); }}
::end::::end::::end::::end::

#else

::if (assets != null)::::foreach assets::::if (type == "font")::@:keep #if display private #end class __ASSET__::flatName:: extends lime.text.Font { public function new () { #if !html5 __fontPath = "::targetPath::"; #end name = "::fontName::"; super (); }}
::end::::end::::end::

#end

#if (openfl && !flash)

::if (assets != null)::::foreach assets::::if (type == "font")::@:keep #if display private #end class __ASSET__OPENFL__::flatName:: extends openfl.text.Font { public function new () { ::if (embed)::var font = new __ASSET__::flatName:: (); src = font.src; name = font.name;::else::#if !html5 __fontPath = #if (ios || tvos) "assets/" + #end "::targetPath::"; #end name = "::fontName::";::end:: super (); }}
::end::::end::::end::

#end
#end