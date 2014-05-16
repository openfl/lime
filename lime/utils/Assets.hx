package lime.utils;

#if !macro

import haxe.Unserializer;
import lime.utils.ByteArray;

#if (tools && !display)
	import lime.AssetData;
#end

#if swf
	#if js
		import format.swf.lite.SWFLite;
	#else
		import format.SWF;
		import lime.utils.UInt8Array;
	#end //js
#end //swf


	/**
	 * <p>The Assets class provides a cross-platform interface to access 
	 * embedded images, fonts, sounds and other resource files.</p>
	 * 
	 * <p>The contents are populated automatically when an application
	 * is compiled using the lime command-line tools, based on the
	 * contents of the *.nmml project file.</p>
	 * 
	 * <p>For most platforms, the assets are included in the same directory
	 * or package as the application, and the paths are handled
	 * automatically. For web content, the assets are preloaded before
	 * the start of the rest of the application. You can customize the 
	 * preloader by extending the <code>NMEPreloader</code> class,
	 * and specifying a custom preloader using <window preloader="" />
	 * in the project file.</p>
	 */
	class Assets {
		
		private static var initialized = false;

		public static var id (get, null)		: Array<String>;
		public static var library (get, null)	: Map<String, LibraryType>;
		public static var path (get, null)		: Map<String, String>;
		public static var type (get, null)		: Map<String, AssetType>;
		
		#if swf private static var cachedSWFLibraries = new Map<String, #if js SWFLite #else SWF #end>(); #end
		
		private static function initialize():Void {
			
			if(!initialized) {
				
				#if (tools && !display)
					AssetData.initialize();
				#end //(tools && !display)
				
				initialized = true;
				
			} //if(!initialized)
			
		} //initialize
		
		/**
		 * Gets an instance of an embedded binary asset
		 * @usage		var bytes = Assets.getBytes("file.zip");
		 * @param	id		The ID or asset path for the file
		 * @return		A new ByteArray object
		 */
		public static function getBytes(id:String):ByteArray {
			
			initialize();
			
			if (AssetData.type.exists(id)) {
				
				#if lime_html5
				
					var req = new haxe.Http(id);
		        	var results : Dynamic = null;

		        	req.async = false;
		        	req.onData = function(e) { 
		        		results = e; 
		        	}
		        	req.request();
		        	req = null;

		        	var len : Int = results.length;
		        	var bytearray : ByteArray = new ByteArray();
					for( i in 0 ... len ) {
					  	bytearray.writeByte(results.charCodeAt(i));
					}

					bytearray.position = 0;
		        	return bytearray;

				#else //lime_html5
				
					return ByteArray.readFile(AssetData.path.get(id));
				
				#end
				
			} else {
				trace("[lime.utils.Assets] There is no String or ByteArray asset with an ID of \"" + id + "\"");
			}
			
			return null;
			
		} //getBytes
		
		
		/**
		 * Gets an instance of an embedded text asset
		 * @usage		var text = Assets.getText("text.txt");
		 * @param	id		The ID or asset path for the file
		 * @return		A new String object
		 */
		public static function getText(id:String):String {
				
			#if lime_native
				var bytes = getBytes(id);
				if (bytes == null) {
					return null;
				} else {
					return bytes.readUTFBytes(bytes.length);
				}
			#end //lime_native

			#if lime_html5

	 			var req = new haxe.Http(id);
	        	var results : Dynamic;

	        	req.async = false;
	        	req.onData = function(e) { results = e; }
	        	req.request();
	        	req = null;

	        	return results;

			#end //lime_html5
			
		}
		
		
		#if js
		
			private static function resolveClass(name:String):Class <Dynamic> {
				name = StringTools.replace(name, "native.", "browser.");
				return Type.resolveClass(name);
			}
			
			
			private static function resolveEnum(name:String):Enum <Dynamic> {
				name = StringTools.replace(name, "native.", "browser.");
				return Type.resolveEnum(name);
			}
		
		#end //js
		

			// Getters & Setters
		private static function get_id():Array<String> {
			
			initialize ();
			
			var ids = [];
			
			#if (tools && !display)
				for (key in AssetData.type.keys ()) {
					ids.push (key);
				}
			#end
			
			return ids;
			
		} //get_id
		
		private static function get_library():Map<String, LibraryType> {
			
			initialize ();
			
			#if (tools && !display)
				return AssetData.library;
			#else
				return new Map<String, LibraryType>();
			#end
			
		} //get_library
		
		
		private static function get_path():Map<String, String> {
			
			initialize ();
			
			#if ((tools && !display) && !flash)
				return AssetData.path;
			#else
				return new Map<String, String> ();
			#end
			
		} //get_path
		
		
		private static function get_type():Map<String, AssetType> {
			
			initialize ();
			
			#if (tools && !display)
				return AssetData.type;
			#else
				return new Map<String, AssetType> ();
			#end
			
		} //get_type
		
		
	} //Assets


	enum AssetType {
		BINARY;
		TEXT;
	}


	enum LibraryType {
		SWF;
	}

#end //!macro