package lime.tools;

import hxp.*;
import lime.tools.Architecture;
import lime.tools.Asset;
import lime.tools.HXProject;
import lime.tools.Platform;
import sys.FileSystem;
import sys.io.File;
#if neko
import neko.vm.Thread;
#elseif cpp
import cpp.vm.Thread;
#end

class HTML5Helper
{
	public static function encodeSourceMappingURL(sourceFile:String)
	{
		// This is only required for projects with url-unsafe characters built with a Haxe version prior to 4.0.0

		var filename = Path.withoutDirectory(sourceFile);

		if (filename != StringTools.urlEncode(filename))
		{
			var output = System.runProcess("", "haxe", ["-version"], true, true, true, false, true);
			var haxeVer:Version = StringTools.trim(output);

			if (haxeVer < ("4.0.0":Version))
			{
				var replaceString = "//# sourceMappingURL=" + filename + ".map";
				var replacement = "//# sourceMappingURL=" + StringTools.urlEncode(filename) + ".map";

				System.replaceText(sourceFile, replaceString, replacement);
			}
		}
	}

	// public static function generateFontData (project:HXProject, font:Asset):String {
	// 	var sourcePath = font.sourcePath;
	// 	if (!FileSystem.exists (FileSystem.fullPath (sourcePath) + ".hash")) {
	// 		var templatePaths = [ Path.combine (Haxelib.getPath (new Haxelib (#if lime "lime" #else "hxp" #end)), "templates") ].concat (project.templatePaths);
	// 		System.runCommand (Path.directory (sourcePath), "neko", [ System.findTemplate (templatePaths, "bin/hxswfml.n"), "ttf2hash2", Path.withoutDirectory (sourcePath), FileSystem.fullPath (sourcePath) + ".hash", "-glyphs", font.glyphs ]);
	// 	}
	// 	return "-resource " + FileSystem.fullPath (sourcePath) + ".hash@__ASSET__" + font.flatName;
	// }
	public static function generateWebfonts(project:HXProject, font:Asset):Void
	{
		var suffix = switch (System.hostPlatform)
		{
			case WINDOWS: "-windows.exe";
			case MAC: "-mac";
			case LINUX: "-linux";
			default: return;
		}

		if (suffix == "-linux")
		{
			if (System.hostArchitecture == X86)
			{
				suffix += "32";
			}
			else
			{
				suffix += "64";
			}
		}

		var templatePaths = [
			Path.combine(Haxelib.getPath(new Haxelib(#if lime "lime" #else "hxp" #end)), #if lime "templates" #else "" #end)
		].concat(project.templatePaths);
		var webify = System.findTemplate(templatePaths, "bin/webify" + suffix);
		if (System.hostPlatform != WINDOWS)
		{
			Sys.command("chmod", ["+x", webify]);
		}

		if (Log.verbose)
		{
			System.runCommand("", webify, [FileSystem.fullPath(font.sourcePath)]);
		}
		else
		{
			System.runProcess("", webify, [FileSystem.fullPath(font.sourcePath)], true, true, true);
		}
	}

	public static function launch(project:HXProject, path:String, port:Int = 0):Void
	{
		if (project.app.url != null && project.app.url != "")
		{
			System.openURL(project.app.url);
		}
		else
		{
			if (project.targetFlags.exists("port"))
			{
				port = Std.parseInt(project.targetFlags.get("port"));
			}

			// Other machines, such as a phone, reach it only when asked to
			var host = project.targetFlags.exists("host") ? project.targetFlags.get("host") : "127.0.0.1";

			#if crossbyte
			WebServer.serve(path, host, port, !project.targetFlags.exists("nolaunch"));
			#else
			// As with -eval, without the crossbyte haxelib or on Haxe before 4.3
			Log.error("These tools were built without CrossByte, which serves the output. Install the crossbyte haxelib and Haxe 4.3 or later, or serve \"" + path + "\" with a web server of your own.");
			#end
		}
	}

	public static function minify(project:HXProject, sourceFile:String):Bool
	{
		if (FileSystem.exists(sourceFile))
		{
			var tempFile = System.getTemporaryFile(".js");

			if (project.targetFlags.exists("terser"))
			{
				// Lime no longer bundles Node.js, so terser comes from the system's
				var args = ["terser", sourceFile, "-c", "-m", "-o", tempFile];

				if (FileSystem.exists(sourceFile + ".map"))
				{
					args.push("--source-map");
					args.push('content=\'${sourceFile}.map\'');
				}

				// System.runCommand answers 0 for a failure it is told to ignore
				Log.info("", " - \x1b[1mRunning command:\x1b[0m npx " + args.join(" "));

				if (Sys.command("npx", args) != 0)
				{
					// Tell a missing Node.js apart from terser failing
					if (Sys.command("npx", ["--version"]) != 0)
					{
						Log.error("-terser needs Node.js, whose npx runs terser. Install Node.js, or use -minify without -terser.");
					}
					else
					{
						Log.error("terser could not minify \"" + sourceFile + "\"");
					}
				}
			}
			else if (project.targetFlags.exists("yui"))
			{
				var templatePaths = [
					Path.combine(Haxelib.getPath(new Haxelib(#if lime "lime" #else "hxp" #end)), #if lime "templates" #else "" #end)
				].concat(project.templatePaths);
				System.runCommand("", "java", [
					"-Dapple.awt.UIElement=true",
					"-jar",
					System.findTemplate(templatePaths, "bin/yuicompressor-2.4.7.jar"),
					"-o",
					tempFile,
					sourceFile
				]);
			}
			else
			{
				var executable:String;
				var args:Array<String>;
				if (project.targetFlags.exists("npx"))
				{
					executable = "npx";
					args = ["google-closure-compiler"];
				}
				else
				{
					executable = "java";
					var templatePaths = [
						Path.combine(Haxelib.getPath(new Haxelib(#if lime "lime" #else "hxp" #end)), #if lime "templates" #else "" #end)
					].concat(project.templatePaths);
					args = [
						"-Dapple.awt.UIElement=true",
						"-jar",
						System.findTemplate(templatePaths, "bin/compiler.jar"),
					];
				}
				args.push("--strict_mode_input");
				args.push("false");
				args.push("--js");
				args.push(sourceFile);
				args.push("--js_output_file");
				args.push(tempFile);

				if (project.targetFlags.exists("advanced"))
				{
					args.push("--compilation_level");
					args.push("ADVANCED_OPTIMIZATIONS");
				}

				if (FileSystem.exists(sourceFile + ".map") || project.targetFlags.exists("source-map"))
				{
					// if an input .js.map exists closure automatically detects it (from sourceMappingURL)
					// --source_map_location_mapping adds file:// to paths (similarly to haxe's .js.map)

					args.push("--create_source_map");
					args.push(tempFile + ".map");
					args.push("--source_map_location_mapping");
					args.push("/|file:///");
				}

				if (!Log.verbose)
				{
					args.push("--jscomp_off=uselessCode");
					args.push("--jscomp_off=suspiciousCode"); // avoid warnings caused by the embedded minified libraries
				}

				System.runCommand("", executable, args);

				if (FileSystem.exists(tempFile + ".map"))
				{
					// closure does not include a sourceMappingURL in the created .js, we do it here
					#if !nodejs
					var f = File.append(tempFile);
					f.writeString("//# sourceMappingURL=" + StringTools.urlEncode(Path.withoutDirectory(sourceFile)) + ".map");
					f.close();
					#end

					File.copy(tempFile + ".map", sourceFile + ".map");
					FileSystem.deleteFile(tempFile + ".map");
				}
			}

			FileSystem.deleteFile(sourceFile);
			File.copy(tempFile, sourceFile);
			FileSystem.deleteFile(tempFile);

			return true;
		}

		return false;
	}
}
