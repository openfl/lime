package lime.ui;


import lime.system.System;
import lime.utils.Resource;

#if sys
import sys.io.File;
#end


class FileDialog {
	
	
	/**
	 * Open an "Open File" dialog window, and browse for an individual file
	 * @param	filter	(Optional) A file filter to use, such as "png,jpg;txt", "txt" or null (Default: null)
	 * @param	defaultPath	(Optional) The default path to use when browsing
	 * @return	The selected file path or null if the dialog was canceled
	 */
	public static function openFile (filter = null, defaultPath:String = null):String {
		
		#if (cpp || neko || nodejs)
		return lime_file_dialog_open_file (filter, defaultPath);
		#else
		return null;
		#end
		
	}
	
	
	/**
	 * Open an "Open File" dialog window, and browse for one or multiple files
	 * @param	filter	(Optional) A file filter to use, such as "png,jpg;txt", "txt" or null (Default: null)
	 * @param	defaultPath	(Optional) The default path to use when browsing
	 * @return	An list of the file paths that were selected
	 */
	public static function openFiles (filter = null, defaultPath:String = null):Array<String> {
		
		#if (cpp || neko || nodejs)
		return lime_file_dialog_open_files (filter, defaultPath);
		#else
		return [];
		#end
		
	}
	
	
	/**
	 * Open a "Save File" dialog and save the specified String or Bytes data
	 * @param	data	String or Bytes data to save
	 * @param	filter	(Optional) A file filter to use, such as "png,jpg;txt", "txt" or null (Default: null)
	 * @param	defaultPath	(Optional) The default path to use when browsing
	 * @return	The path of the saved file, or null if the data was not saved
	 */
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