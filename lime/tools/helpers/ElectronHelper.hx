package lime.tools.helpers;


import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.ProcessHelper;
import lime.project.HXProject;
import utils.PlatformSetup;

class ElectronHelper {
	
	
	public static function launch (project:HXProject, path:String):Void {
		
		var electronPath = project.defines.get ("ELECTRON");
		if (electronPath == null || electronPath == "") electronPath = "electron";
		else electronPath = electronPath + "\\electron";
		var exitCode = ProcessHelper.runCommand ("", electronPath, [path]);
	}
}
