package lime.tools.helpers;


import haxe.io.BytesOutput;
import haxe.io.Eof;
import haxe.io.Path;
import lime.project.Platform;
import sys.io.Process;
import sys.FileSystem;


class ProcessHelper {
	
	
	public static var dryRun:Bool = false;
	public static var processorCores (get_processorCores, null):Int;
	
	private static var _processorCores:Int = 0;
	
	
	public static function openFile (workingDirectory:String, targetPath:String, executable:String = ""):Void {
		
		if (executable == null) { 
			
			executable = "";
			
		}
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			var args = [];
			
			if (executable == "") {
				
				executable = "cmd";
				args = [ "/c" ];
				
			}
			
			if (targetPath.indexOf (":\\") == -1) {
				
				runCommand (workingDirectory, executable, args.concat ([ targetPath ]));
				
			} else {
				
				runCommand (workingDirectory, executable, args.concat ([ ".\\" + targetPath ]));
				
			}
			
		} else if (PlatformHelper.hostPlatform == Platform.MAC) {
			
			if (executable == "") {
				
				executable = "/usr/bin/open";
				
			}
			
			if (targetPath.substr (0, 1) == "/") {
				
				runCommand (workingDirectory, executable, [ "-W", targetPath ]);
				
			} else {
				
				runCommand (workingDirectory, executable, [ "-W", "./" + targetPath ]);
				
			}
			
		} else {
			
			if (executable == "") {
				
				executable = "/usr/bin/xdg-open";
				
			}
			
			if (targetPath.substr (0, 1) == "/") {
				
				runCommand (workingDirectory, executable, [ targetPath ]);
				
			} else {
				
				runCommand (workingDirectory, executable, [ "./" + targetPath ]);
				
			}
			
		}
		
	}
	
	
	public static function openURL (url:String):Void {
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			runCommand ("", "start", [ url ]);
			
		} else if (PlatformHelper.hostPlatform == Platform.MAC) {
			
			runCommand ("", "/usr/bin/open", [ url ]);
			
		} else {
			
			runCommand ("", "/usr/bin/xdg-open", [ url, "&" ]);
			
		}
		
	}
	
	
	public static function runCommand (path:String, command:String, args:Array<String>, safeExecute:Bool = true, ignoreErrors:Bool = false, print:Bool = false):Int {
		
		if (print) {
			
			var message = command;
			
			if (args != null) {
				
				for (arg in args) {
					
					if (arg.indexOf (" ") > -1) {
						
						message += " \"" + arg + "\"";
						
					} else {
						
						message += " " + arg;
						
					}
					
				}
				
			}
			
			Sys.println (message);
			
		}
		
		#if (haxe_ver < "3.3.0")
		if (args != null && PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			command = PathHelper.escape (command);
			
		}
		#end
		
		if (safeExecute) {
			
			try {
				
				if (path != null && path != "" && !FileSystem.exists (FileSystem.fullPath (path)) && !FileSystem.exists (FileSystem.fullPath (new Path (path).dir))) {
					
					LogHelper.error ("The specified target path \"" + path + "\" does not exist");
					return 1;
					
				}
				
				return _runCommand (path, command, args);
				
			} catch (e:Dynamic) {
				
				if (!ignoreErrors) {
					
					LogHelper.error ("", e);
					return 1;
					
				}
				
				return 0;
				
			}
			
		} else {
			
			return _runCommand (path, command, args);
			
		}
		
	}
	
	
	private static function _runCommand (path:String, command:String, args:Array<String>):Int {
		
		var oldPath:String = "";
		
		if (path != null && path != "") {
			
			LogHelper.info ("", " - \x1b[1mChanging directory:\x1b[0m " + path + "");
			
			if (!dryRun) {
				
				oldPath = Sys.getCwd ();
				Sys.setCwd (path);
				
			}
			
		}
		
		var argString = "";
		
		if (args != null) {
			
			for (arg in args) {
				
				if (arg.indexOf (" ") > -1) {
					
					argString += " \"" + arg + "\"";
					
				} else {
					
					argString += " " + arg;
					
				}
				
			}
			
		}
		
		LogHelper.info ("", " - \x1b[1mRunning command:\x1b[0m " + command + argString);
		
		var result = 0;
		
		if (!dryRun) {
			
			if (args != null && args.length > 0) {
				
				result = Sys.command (command, args);
				
			} else {
				
				result = Sys.command (command);
				
			}
			
			if (oldPath != "") {
				
				Sys.setCwd (oldPath);
				
			}
			
		}
		
		if (result != 0) {
			
			throw ("Error running: " + command + " " + args.join (" ") + " [" + path + "]");
			
		}
		
		return result;
		
	}
	
	
	public static function runProcess (path:String, command:String, args:Array<String>, waitForOutput:Bool = true, safeExecute:Bool = true, ignoreErrors:Bool = false, print:Bool = false, returnErrorValue:Bool = false):String {
		
		if (print) {
			
			var message = command;
			
			for (arg in args) {
				
				if (arg.indexOf (" ") > -1) {
					
					message += " \"" + arg + "\"";
					
				} else {
					
					message += " " + arg;
					
				}
				
			}
			
			Sys.println (message);
			
		}
		
		#if (haxe_ver < "3.3.0")
		command = PathHelper.escape (command);
		#end
		
		if (safeExecute) {
			
			try {
				
				if (path != null && path != "" && !FileSystem.exists (FileSystem.fullPath (path)) && !FileSystem.exists (FileSystem.fullPath (new Path (path).dir))) {
					
					LogHelper.error ("The specified target path \"" + path + "\" does not exist");
					
				}
				
				return _runProcess (path, command, args, waitForOutput, safeExecute, ignoreErrors, returnErrorValue);
				
			} catch (e:Dynamic) {
				
				if (!ignoreErrors) {
					
					LogHelper.error ("", e);
					
				}
				
				return null;
				
			}
			
		} else {
			
			return _runProcess (path, command, args, waitForOutput, safeExecute, ignoreErrors, returnErrorValue);
			
		}
		
	}
	
	
	private static function _runProcess (path:String, command:String, args:Array<String>, waitForOutput:Bool, safeExecute:Bool, ignoreErrors:Bool, returnErrorValue:Bool):String {
		
		var oldPath:String = "";
		
		if (path != null && path != "") {
			
			LogHelper.info ("", " - \x1b[1mChanging directory:\x1b[0m " + path + "");
			
			if (!dryRun) {
				
				oldPath = Sys.getCwd ();
				Sys.setCwd (path);
				
			}
			
		}
		
		var argString = "";
		
		for (arg in args) {
			
			if (arg.indexOf (" ") > -1) {
				
				argString += " \"" + arg + "\"";
				
			} else {
				
				argString += " " + arg;
				
			}
			
		}
		
		LogHelper.info ("", " - \x1b[1mRunning process:\x1b[0m " + command + argString);
		
		var output = "";
		var result = 0;
		
		if (!dryRun) {
			
			var process = new Process (command, args);
			var buffer = new BytesOutput ();
			
			if (waitForOutput) {
				
				var waiting = true;
				
				while (waiting) {
					
					try  {
						
						var current = process.stdout.readAll (1024);
						buffer.write (current);
						
						if (current.length == 0) {
							
							waiting = false;
							
						}
						
					} catch (e:Eof) {
						
						waiting = false;
						
					}
					
				}
				
				result = process.exitCode ();
				
				output = buffer.getBytes ().toString ();
				
				if (output == "") {
					
					var error = process.stderr.readAll ().toString ();
					process.close ();
					
					if (result != 0 || error != "") {
						
						if (ignoreErrors) {
							
							output = error;
							
						} else if (!safeExecute) {
							
							throw error;
							
						} else {
							
							LogHelper.error (error);
							
						}
						
						if (returnErrorValue) {
							
							return output;
							
						} else {
							
							return null;
							
						}
						
					}
					
					/*if (error != "") {
						
						LogHelper.error (error);
						
					}*/
					
				} else {
				
					process.close ();
				
				}
				
			}
			
			if (oldPath != "") {
				
				Sys.setCwd (oldPath);
				
			}
			
		}
		
		return output;
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	public static function get_processorCores ():Int {
		
		var cacheDryRun = dryRun;
		dryRun = false;
		
		if (_processorCores < 1) {
			
			var result = null;
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				var env = Sys.getEnv ("NUMBER_OF_PROCESSORS");
				
				if (env != null) {
					
					result = env;
					
				}
				
			} else if (PlatformHelper.hostPlatform == Platform.LINUX) {
				
				result = runProcess ("", "nproc", [], true, true, true);
				
				if (result == null) {
					
					var cpuinfo = runProcess ("", "cat", [ "/proc/cpuinfo" ], true, true, true);
					
					if (cpuinfo != null) {
						
						var split = cpuinfo.split ("processor");
						result = Std.string (split.length - 1);
						
					}
					
				}
				
			} else if (PlatformHelper.hostPlatform == Platform.MAC) {
				
				var cores = ~/Total Number of Cores: (\d+)/;
				var output = runProcess ("", "/usr/sbin/system_profiler", [ "-detailLevel", "full", "SPHardwareDataType" ]);
				
				if (cores.match (output)) {
					
					result = cores.matched (1);
					
				}
				
			}
			
			if (result == null || Std.parseInt (result) < 1) {
				
				_processorCores = 1;
				
			} else {
				
				_processorCores = Std.parseInt (result);
				
			}
			
		}
		
		dryRun = cacheDryRun;
		
		return _processorCores;
		
	}
	
	
}
