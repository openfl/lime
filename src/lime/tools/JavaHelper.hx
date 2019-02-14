package lime.tools;

import hxp.*;
import sys.io.File;

class JavaHelper
{
	public static function copyLibraries(templatePaths:Array<String>, platformName:String, targetPath:String)
	{
		System.recursiveCopyTemplate(templatePaths, "java/ndll/" + platformName, targetPath);
	}
}
