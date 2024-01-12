package lime.tools;

import hxp.*;
import lime.tools.HXProject;

class ElectronHelper
{
	public static function launch(project:HXProject, path:String, ?npx:Bool):Void
	{
		if (npx)
		{
			System.runCommand("", "npx", ["electron", path]);
			return;
		}

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
