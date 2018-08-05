package lime.tools;


import hxp.Path;
import hxp.System;
import lime.tools.Project;


class ElectronHelper {


	public static function launch (project:Project, path:String):Void {

		var electronPath = project.defines.get ("ELECTRON_PATH");

		if (electronPath == null || electronPath == "") {

			electronPath = "electron";

		} else {

			electronPath = Path.combine (electronPath, "electron");

		}

		System.runCommand ("", electronPath, [ path ]);

	}


}