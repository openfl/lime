package lime.tools.helpers;


import haxe.io.Bytes;
import lime.tools.helpers.PlatformHelper;
import lime.project.Platform;
import lime.system.CFFI;
import sys.io.Process;

#if neko
import neko.Lib;
#elseif cpp
import cpp.Lib;
#elseif cs
import cs.Lib;
#end


class LogHelper {
	
	
	public static var accentColor = "\x1b[32;1m";
	public static var enableColor = true;
	public static var mute = false;
	public static var resetColor = "\x1b[0m";
	public static var verbose = false;
	
	private static var colorCodes:EReg = ~/\x1b\[[^m]+m/g;
	private static var colorSupported:Null<Bool>;
	private static var sentWarnings:Map<String, Bool> = new Map<String, Bool> ();
	
	
	public static function error (message:String, verboseMessage:String = "", e:Dynamic = null):Void {
		
		if (message != "" && !mute) {
			
			var output;
			
			if (verbose && verboseMessage != "") {
				
				output = "\x1b[31;1mError:\x1b[0m\x1b[1m " + verboseMessage + "\x1b[0m\n";
				
			} else {
				
				output = "\x1b[31;1mError:\x1b[0m \x1b[1m" + message + "\x1b[0m\n";
				
			}
			
			Sys.stderr ().write (Bytes.ofString (stripColor (output)));
			
		}
		
		if (verbose && e != null) {
			
			#if js
			throw e;
			#elseif !cs
			Lib.rethrow (e);
			#end
			
		}
		
		Sys.exit (1);
		
	}
	
	
	public static function info (message:String, verboseMessage:String = ""):Void {
		
		if (!mute) {
			
			if (verbose && verboseMessage != "") {
				
				println (verboseMessage);
				
			} else if (message != "") {
				
				println (message);
				
			}
			
		}
		
	}
	
	
	public static function print (message:String):Void {
		
		Sys.print (stripColor (message));
		
	}
	
	
	public static function println (message:String):Void {
		
		Sys.println (stripColor (message));
		
	}
	
	
	private static function stripColor (output:String):String {
		
		if (colorSupported == null) {
			
			if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
				
				var result = -1;
				
				try {
					
					var process = new Process ("tput", [ "colors" ]);
					result = process.exitCode ();
					process.close ();
					
				} catch (e:Dynamic) {};
				
				colorSupported = (result == 0);
				
			} else {
				
				colorSupported = false;
				
				if (Sys.getEnv ("TERM") == "xterm" || Sys.getEnv ("ANSICON") != null) {
					
					colorSupported = true;
					
				} else if (CFFI.enabled) {
					
					var getConsoleMode = CFFI.load ("lime", "lime_system_get_windows_console_mode", 1);
					var setConsoleMode = CFFI.load ("lime", "lime_system_set_windows_console_mode", 2);
					
					var STD_INPUT_HANDLE = -10;
					var STD_OUTPUT_HANDLE = -11;
					var STD_ERROR_HANDLE = -12;
					
					var ENABLE_VIRTUAL_TERMINAL_INPUT = 0x0200;
					var ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;
					var DISABLE_NEWLINE_AUTO_RETURN = 0x0008;
					
					var outputMode = getConsoleMode (STD_OUTPUT_HANDLE);
					var errorMode = getConsoleMode (STD_ERROR_HANDLE);
					
					if (outputMode & ENABLE_VIRTUAL_TERMINAL_PROCESSING != 0) {
						
						colorSupported = true; 
						
					} else {
						
						outputMode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING | DISABLE_NEWLINE_AUTO_RETURN;
						colorSupported = setConsoleMode (STD_OUTPUT_HANDLE, outputMode);
						
					}
					
					if (colorSupported) {
						
						if (errorMode & ENABLE_VIRTUAL_TERMINAL_PROCESSING == 0) {
							
							errorMode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING | DISABLE_NEWLINE_AUTO_RETURN;
							colorSupported = setConsoleMode (STD_ERROR_HANDLE, errorMode);
							
						}
						
						if (colorSupported) {
							
							// Fake presence of ANSICON, so subsequent tools know they can use ANSI codes
							Sys.putEnv ("ANSICON", "1");
							
						}
						
					}
					
				}
				
			}
			
		}
		
		if (enableColor && colorSupported) {
			
			return output;
			
		} else {
			
			return colorCodes.replace (output, "");
			
		}
		
	}
	
	
	public static function warn (message:String, verboseMessage:String = "", allowRepeat:Bool = false):Void {
		
		if (!mute) {
			
			var output = "";
			
			if (verbose && verboseMessage != "") {
				
				output = "\x1b[33;1mWarning:\x1b[0m \x1b[1m" + verboseMessage + "\x1b[0m";
				
			} else if (message != "") {
				
				output = "\x1b[33;1mWarning:\x1b[0m \x1b[1m" + message + "\x1b[0m";
				
			}
			
			if (!allowRepeat && sentWarnings.exists (output)) {
				
				return;
				
			}
			
			sentWarnings.set (output, true);
			println (output);
			
		}
		
	}
	
	
}