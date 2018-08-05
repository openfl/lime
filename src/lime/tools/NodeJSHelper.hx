package lime.tools;


import hxp.Path;
import lime.tools.Architecture;
import hxp.Haxelib;
import lime.tools.Project;
import lime.tools.Platform;
import hxp.*;


class NodeJSHelper {


	public static function run (project:Project, modulePath:String, args:Array<String> = null):Void {

		/*var suffix = switch (System.hostPlatform) {

			case Platform.WINDOWS: "-windows.exe";
			case Platform.MAC: "-mac";
			case Platform.LINUX: "-linux";
			default: return;

		}

		if (suffix == "-linux") {

			if (System.hostArchitecture == X86) {

				suffix += "32";

			} else {

				suffix += "64";

			}

		}

		var templatePaths = [ Path.combine (Haxelib.getPath (new Haxelib (#if lime "lime" #else "hxp" #end)), "templates") ].concat (project.templatePaths);
		var node = System.findTemplate (templatePaths, "bin/node/node" + suffix);

		if (System.hostPlatform != WINDOWS) {

			Sys.command ("chmod", [ "+x", node ]);

		}

		if (args == null) {

			args = [];

		}*/

		args.unshift (Path.withoutDirectory (modulePath));

		System.runCommand (Path.directory (modulePath), "node", args);

	}


}