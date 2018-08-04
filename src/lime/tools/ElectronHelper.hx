package lime.tools;


import hxp.PathHelper;
import hxp.ProcessHelper;
import lime.tools.Project;


class ElectronHelper {


	public static function launch (project:Project, path:String):Void {

		var electronPath = project.defines.get ("ELECTRON_PATH");

		if (electronPath == null || electronPath == "") {

			electronPath = "electron";

		} else {

			electronPath = PathHelper.combine (electronPath, "electron");

		}

		ProcessHelper.runCommand ("", electronPath, [ path ]);

	}


}