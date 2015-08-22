package lime.ui;


import lime.system.System;
import lime.utils.Resource;

#if sys
import sys.io.File;
#end


class FileDialog {
	
	
	public static function openFile (filter = null, defaultPath:String = null):String {
		
		#if (cpp || neko || nodejs)
		return lime_file_dialog_open_file (filter, defaultPath);
		#else
		return null;
		#end
		
	}
	
	
	public static function openFiles (filter = null, defaultPath:String = null):Array<String> {
		
		#if (cpp || neko || nodejs)
		return lime_file_dialog_open_files (filter, defaultPath);
		#else
		return [];
		#end
		
	}
	
	
	public static function saveFile (data:Resource, filter = null, defaultPath:String = null):String {
		
		var path = null;
		
		#if (cpp || neko || nodejs)
		
		path = lime_file_dialog_save_file (filter, defaultPath);
		
		if (path != null) {
			
			try {
				
				File.saveBytes (path, data);
				
			} catch (e:Dynamic) {
				
				path = null;
				
			}
			
		}
		
		#end
		
		return path;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_file_dialog_open_file = System.load ("lime", "lime_file_dialog_open_file", 2);
	private static var lime_file_dialog_open_files = System.load ("lime", "lime_file_dialog_open_files", 2);
	private static var lime_file_dialog_save_file = System.load ("lime", "lime_file_dialog_save_file", 2);
	#end
	
	
}