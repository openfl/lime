package helpers;


import haxe.io.BytesOutput;
import haxe.io.Eof;
import haxe.io.Path;
import project.Platform;
import sys.io.Process;
import sys.FileSystem;


class ProcessHelper {
	
	
	public static var processorCores (get_processorCores, null):Int;
	
	private static var _processorCores:Int = 0;
	
	
	public static function openFile (workingDirectory:String, targetPath:String, executable:String = ""):Void {
		
		if (executable == null) { 
			
			executable = "";
			
		}
		
		if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
			
			if (executable == "") {
				
				if (targetPath.indexOf (":\\") == -1) {
					
					runCommand (workingDirectory, targetPath, []);
					
				} else {
					
					runCommand (workingDirectory, ".\\" + targetPath, []);
					
				}
				
			} else {
				
				if (targetPath.indexOf (":\\") == -1) {
					
					runCommand (workingDirectory, executable, [ targetPath ]);
					
				} else {
					
					runCommand (workingDirectory, executable, [ ".\\" + targetPath ]);
					
				}
				
			}
			
		} else if (PlatformHelper.hostPlatform == Platform.MAC) {
			
			if (executable == "") {
				
				executable = "/usr/bin/open";
				
			}
			
			if (targetPath.substr (0) == "/") {
				
				runCommand (workingDirectory, executable, [ targetPath ]);
				
			} else {
				
				runCommand (workingDirectory, executable, [ "./" + targetPath ]);
				
			}
			
		} else {
			
			if (executable == "") {
				
				executable = "/usr/bin/xdg-open";
				
			}
			
			if (targetPath.substr (0) == "/") {
				
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
	
	
	public static function runCommand (path:String, command:String, args:Array <String>, safeExecute:Bool = true, ignoreErrors:Bool = false, print:Bool = false):Int {
		
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
		
		command = PathHelper.escape (command);
		
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
			
			oldPath = Sys.getCwd ();
			Sys.setCwd (path);
			
		}
		
		var argString = "";
		
		for (arg in args) {
			
			if (arg.indexOf (" ") > -1) {
				
				argString += " \"" + arg + "\"";
				
			} else {
				
				argString += " " + arg;
				
			}
			
		}
		
		LogHelper.info ("", " - \x1b[1mRunning command:\x1b[0m " + command + argString);
		
		var result = 0;
		
		if (args != null && args.length > 0) {
			
			result = Sys.command (command, args);
			
		} else {
			
			result = Sys.command (command);
			
		}
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
		if (result != 0) {
			
			throw ("Error running: " + command + " " + args.join (" ") + " [" + path + "]");
			
		}
		
		return result;
		
	}
	
	
	public static function runProcess (path:String, command:String, args:Array <String>, waitForOutput:Bool = true, safeExecute:Bool = true, ignoreErrors:Bool = false, print:Bool = false):String {
		
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
		
		command = PathHelper.escape (command);
		
		if (safeExecute) {
			
			try {
				
				if (path != null && path != "" && !FileSystem.exists (FileSystem.fullPath (path)) && !FileSystem.exists (FileSystem.fullPath (new Path (path).dir))) {
					
					LogHelper.error ("The specified target path \"" + path + "\" does not exist");
					
				}
				
				return _runProcess (path, command, args, waitForOutput, ignoreErrors);
				
			} catch (e:Dynamic) {
				
				if (!ignoreErrors) {
					
					LogHelper.error ("", e);
					
				}
				
				return null;
				
			}
			
		} else {
			
			return _runProcess (path, command, args, waitForOutput, ignoreErrors);
			
		}
		
	}
	
	
	private static function _runProcess (path:String, command:String, args:Array<String>, waitForOutput:Bool, ignoreErrors:Bool):String {
		
		var oldPath:String = "";
		
		if (path != null && path != "") {
			
			LogHelper.info ("", " - \x1b[1mChanging directory:\x1b[0m " + path + "");
			
			oldPath = Sys.getCwd ();
			Sys.setCwd (path);
			
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
			process.close();
			
			//if (result == 0) {
				
				output = buffer.getBytes ().toString ();
				
				if (output == "") {
					
					var error = process.stderr.readAll ().toString ();
					
					if (ignoreErrors) {
						
						output = error;
						
					} else {
						
						LogHelper.error (error);
						
					}
					
					return null;
					
					/*if (error != "") {
						
						LogHelper.error (error);
						
					}*/
					
				}
				
			//}
			
		}
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
		return output;
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	public static function get_processorCores ():Int {
		
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
		
		return _processorCores;
		
	}
	
	
}