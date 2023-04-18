package lime.tools;

import hxp.*;
import lime.tools.HXProject;

class ElectronHelper
{
	public static function launch(project:HXProject, path:String):Void
	{
		var electronPath = project.defines.get("ELECTRON_PATH");

		if (electronPath == null || electronPath == "")
		{
			electronPath = "electron";
		}
		else
		{
			electronPath = Path.combine(electronPath, "electron");
		}

		System.runCommand("", electronPath, [path]);
	}
}
