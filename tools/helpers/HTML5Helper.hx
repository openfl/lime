package helpers;


import haxe.io.Path;
import haxe.Timer;
import helpers.LogHelper;
import helpers.PathHelper;
import helpers.PlatformHelper;
import helpers.ProcessHelper;
import neko.vm.Thread;
import project.Architecture;
import project.Asset;
import project.Haxelib;
import project.HXProject;
import project.Platform;
import sys.FileSystem;


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
			var server = PathHelper.findTemplate (templatePaths, "bin/node/http-server/http-server");
			
			if (PlatformHelper.hostPlatform != Platform.WINDOWS) {
				
				Sys.command ("chmod", [ "+x", node ]);
				
			}
			
			LogHelper.info ("", " - \x1b[1mStarting local web server:\x1b[0m http://localhost:" + port);
			
			/*Thread.create (function () { 
				
				Sys.sleep (0.5);
				ProcessHelper.openURL ("http://localhost:" + port);
				
			});*/
			
			var args = [ server, path, "-p", Std.string (port), "-c-1", "-o", "-a", "localhost", "--cors" ];
			
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
				var args = [ "-Dapple.awt.UIElement=true", "-jar", PathHelper.findTemplate (templatePaths, "bin/compiler.jar"), "--js", sourceFile, "--js_output_file", tempFile ];
				
				if (!LogHelper.verbose) {
					
					args.push ("--jscomp_off=uselessCode");
					
				}
				
				ProcessHelper.runCommand ("", "java", args);
				
			}
			
			FileSystem.deleteFile (sourceFile);
			FileSystem.rename (tempFile, sourceFile);
			
			return true;
			
		}
		
		return false;
		
	}
	
	
}