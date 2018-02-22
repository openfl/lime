package lime.tools.helpers;


import haxe.io.Path;
import haxe.Timer;
import lime.tools.helpers.LogHelper;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.ProcessHelper;
import lime.project.Architecture;
import lime.project.Asset;
import lime.project.Haxelib;
import lime.project.HXProject;
import lime.project.Platform;
import sys.FileSystem;
import sys.io.File;

#if neko
import neko.vm.Thread;
#elseif cpp
import cpp.vm.Thread;
#end


class HTML5Helper {
	
	
	public static function generateFontData (project:HXProject, font:Asset):String {
		
		var sourcePath = font.sourcePath;
		
		if (!FileSystem.exists (FileSystem.fullPath (sourcePath) + ".hash")) {
			
			var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
			ProcessHelper.runCommand (Path.directory (sourcePath), "neko", [ PathHelper.findTemplate (templatePaths, "bin/hxswfml.n"), "ttf2hash2", Path.withoutDirectory (sourcePath), FileSystem.fullPath (sourcePath) + ".hash", "-glyphs", font.glyphs ]);
			
		}
		
		return "-resource " + FileSystem.fullPath (sourcePath) + ".hash@__ASSET__" + font.flatName;
		
	}
	
	
	public static function generateWebfonts (project:HXProject, font:Asset):Void {
		
		var suffix = switch (PlatformHelper.hostPlatform) {
			
			case Platform.WINDOWS: "-windows.exe";
			case Platform.MAC: "-mac";
			case Platform.LINUX: "-linux";
			default: return;
			
		}
		
		if (suffix == "-linux") {
			
			if (PlatformHelper.hostArchitecture == Architecture.X86) {
				
				suffix += "32";
				
			} else {
				
				suffix += "64";
				
			}
			
		}
		
		var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
		var webify = PathHelper.findTemplate (templatePaths, "bin/webify" + suffix);
		if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
			
			Sys.command ("chmod", [ "+x", webify ]);
			
		}
		
		if (LogHelper.verbose) {
			
			ProcessHelper.runCommand ("", webify, [ FileSystem.fullPath (font.sourcePath) ]);
			
		} else {
			
			ProcessHelper.runProcess ("", webify, [ FileSystem.fullPath (font.sourcePath) ], true, true, true);
			
		}
		
	}
	
	
	public static function launch (project:HXProject, path:String, port:Int = 3000):Void {
		
		if (project.app.url != null && project.app.url != "") {
			
			ProcessHelper.openURL (project.app.url);
			
		} else {
			
			var suffix = switch (PlatformHelper.hostPlatform) {
				
				case Platform.WINDOWS: "-windows.exe";
				case Platform.MAC: "-mac";
				case Platform.LINUX: "-linux";
				default: return;
				
			}
			
			if (suffix == "-linux") {
				
				if (PlatformHelper.hostArchitecture == Architecture.X86) {
					
					suffix += "32";
					
				} else {
					
					suffix += "64";
					
				}
				
			}
			
			var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
			var node = PathHelper.findTemplate (templatePaths, "bin/node/node" + suffix);
			var server = PathHelper.findTemplate (templatePaths, "bin/node/http-server/bin/http-server");
			
			if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
				
				Sys.command ("chmod", [ "+x", node ]);
				
			}
			
			if (project.targetFlags.exists ("port")) {
				
				port = Std.parseInt (project.targetFlags.get ("port"));
				
			}
			
			LogHelper.info ("", " - \x1b[1mStarting local web server:\x1b[0m http://localhost:" + port);
			
			/*Thread.create (function () { 
				
				Sys.sleep (0.5);
				ProcessHelper.openURL ("http://localhost:" + port);
				
			});*/
			
			var args = [ server, path, "-p", Std.string (port), "-c-1", "--cors" ];
			
			if (project.targetFlags.exists ("nolaunch")) {
				
				LogHelper.info ("\x1b[1mStarting local web server:\x1b[0m http://localhost:" + port);
				
			} else {
				
				args.push ("-o");
				
			}
			
			if (!LogHelper.verbose) {
				
				args.push ("--silent");
				
			}
			
			ProcessHelper.runCommand ("", node, args);
			
		}
		
	}
	
	
	public static function minify (project:HXProject, sourceFile:String):Bool {
		
		if (FileSystem.exists (sourceFile)) {
			
			var tempFile = PathHelper.getTemporaryFile (".js");
			
			if (project.targetFlags.exists ("yui")) {
				
				var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
				ProcessHelper.runCommand ("", "java", [ "-Dapple.awt.UIElement=true", "-jar", PathHelper.findTemplate (templatePaths, "bin/yuicompressor-2.4.7.jar"), "-o", tempFile, sourceFile ]);
				
			} else {
				
				var templatePaths = [ PathHelper.combine (PathHelper.getHaxelib (new Haxelib ("lime")), "templates") ].concat (project.templatePaths);
				var args = [ "-Dapple.awt.UIElement=true", "-jar", PathHelper.findTemplate (templatePaths, "bin/compiler.jar"), "--strict_mode_input", "false", "--js", sourceFile, "--js_output_file", tempFile ];
				
				if (project.targetFlags.exists ("advanced")) {
					
					args.push ("--compilation_level");
					args.push ("ADVANCED_OPTIMIZATIONS");
					
				}
				
				if (FileSystem.exists (sourceFile + ".map") || project.targetFlags.exists ("source-map")) {
					
					// if an input .js.map exists closure automatically detects it (from sourceMappingURL)
					// --source_map_location_mapping adds file:// to paths (similarly to haxe's .js.map)
					
					args.push ("--create_source_map");
					args.push (tempFile + ".map");
					args.push ("--source_map_location_mapping");
					args.push ("/|file:///");
					
				}
				
				if (!LogHelper.verbose) {
					
					args.push ("--jscomp_off=uselessCode");
					
				}
				
				ProcessHelper.runCommand ("", "java", args);
				
				if (FileSystem.exists (tempFile + ".map")) {
					
					// closure does not include a sourceMappingURL in the created .js, we do it here
					var f = File.append (tempFile);
					f.writeString ("//# sourceMappingURL=" + Path.withoutDirectory (sourceFile) + ".map");
					f.close ();
					
					File.copy (tempFile + ".map", sourceFile + ".map");
					FileSystem.deleteFile (tempFile + ".map");
					
				}
				
			}
			
			FileSystem.deleteFile (sourceFile);
			File.copy (tempFile, sourceFile);
			FileSystem.deleteFile (tempFile);
			
			return true;
			
		}
		
		return false;
		
	}
	
	
}
