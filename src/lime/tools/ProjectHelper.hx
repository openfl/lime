package lime.tools;

import hxp.*;
import sys.io.File;
import sys.FileSystem;
#if neko
import neko.Lib;
#elseif cpp
import cpp.Lib;
#end

class ProjectHelper
{
	// private static var doubleVarMatch = new EReg ("\\$\\${(.*?)}", "");
	private static var varMatch = new EReg("{{(.*?)}}", "");

	public static function copyLibrary(project:HXProject, ndll:NDLL, directoryName:String, namePrefix:String, nameSuffix:String, targetDirectory:String,
			allowDebug:Bool = false, targetSuffix:String = null)
	{
		var path = NDLL.getLibraryPath(ndll, directoryName, namePrefix, nameSuffix, allowDebug);

		if (FileSystem.exists(path))
		{
			var targetPath = Path.combine(targetDirectory, namePrefix + ndll.name);

			if (targetSuffix != null)
			{
				targetPath += targetSuffix;
			}
			else
			{
				targetPath += nameSuffix;
			}

			if (project.config.getBool("tools.copy-ndlls"))
			{
				Log.info("", " - \x1b[1mCopying library file:\x1b[0m " + path + " \x1b[3;37m->\x1b[0m " + targetPath);

				System.mkdir(targetDirectory);

				try
				{
					File.copy(path, targetPath);
				}
				catch (e:Dynamic)
				{
					Log.error("Cannot copy to \"" + targetPath + "\", is the file in use?");
				}
			}
			else
			{
				Log.info("", " - \x1b[1mSkipping library file:\x1b[0m " + path + " \x1b[3;37m->\x1b[0m " + targetPath);
			}
		}
		else
		{
			Log.error("Source path \"" + path + "\" does not exist");
		}
	}

	public static function getCurrentCommand():String
	{
		var args = Sys.args();
		args.remove("-watch");

		if (Haxelib.pathOverrides.exists("lime-tools"))
		{
			var tools = Haxelib.pathOverrides.get("lime-tools");

			return "neko " + tools + "/tools.n " + args.join(" ");
		}
		else
		{
			args.pop();

			return "lime " + args.join(" ");
		}
	}

	public static function recursiveSmartCopyTemplate(project:HXProject, source:String, destination:String, context:Dynamic = null, process:Bool = true,
			warnIfNotFound:Bool = true)
	{
		var destinations:Array<String> = [];
		var paths = System.findTemplateRecursive(project.templatePaths, source, warnIfNotFound, destinations);

		if (paths != null)
		{
			System.mkdir(destination);
			var itemDestination:String;

			for (i in 0...paths.length)
			{
				itemDestination = Path.combine(destination, ProjectHelper.substitutePath(project, destinations[i]));
				System.copyFile(paths[i], itemDestination, context, process);
			}
		}
	}

	public static function replaceVariable(project:HXProject, string:String):String
	{
		if (string.substr(0, 8) == "haxelib:")
		{
			var path = Haxelib.getPath(new Haxelib(string.substr(8)), true);
			return Path.standardize(path);
		}
		else if (project.defines.exists(string))
		{
			return project.defines.get(string);
		}
		else if (project.environment != null && project.environment.exists(string))
		{
			return project.environment.get(string);
		}
		// TODO: Should we start phasing this out?
		else if (string == "projectDirectory")
		{
			Log.info("", "Consider using ${project.workingDirectory} instead of ${projectDirectory}.");
			return project.workingDirectory;
		}
		else
		{
			var substring = StringTools.replace(string, " ", "");
			var index:Int;
			var value:String;

			if (substring.indexOf("==") > -1)
			{
				index = substring.indexOf("==");
				value = ProjectHelper.replaceVariable(project, substring.substr(0, index));

				return Std.string(value == substring.substr(index + 2));
			}
			else if (substring.indexOf("!=") > -1)
			{
				index = substring.indexOf("!=");
				value = ProjectHelper.replaceVariable(project, substring.substr(0, index));

				return Std.string(value != substring.substr(index + 2));
			}
			else if (substring.indexOf("<=") > -1)
			{
				index = substring.indexOf("<=");
				value = ProjectHelper.replaceVariable(project, substring.substr(0, index));

				return Std.string(value <= substring.substr(index + 2));
			}
			else if (substring.indexOf("<") > -1)
			{
				index = substring.indexOf("<");
				value = ProjectHelper.replaceVariable(project, substring.substr(0, index));

				return Std.string(value < substring.substr(index + 1));
			}
			else if (substring.indexOf(">=") > -1)
			{
				index = substring.indexOf(">=");
				value = ProjectHelper.replaceVariable(project, substring.substr(0, index));

				return Std.string(value >= substring.substr(index + 2));
			}
			else if (substring.indexOf(">") > -1)
			{
				index = substring.indexOf(">");
				value = ProjectHelper.replaceVariable(project, substring.substr(0, index));

				return Std.string(value > substring.substr(index + 1));
			}
			else if (substring.indexOf(".") > -1)
			{
				var fields = substring.split(".");
				if (fields[0] == "project") fields.shift();

				var object:Dynamic = project;
				while (object != null && fields.length > 0)
				{
					object = Reflect.getProperty(object, fields.shift());
				}

				if (object != null && object != project)
				{
					return Std.string(object);
				}
			}
		}

		return string;
	}

	public static function substitutePath(project:HXProject, path:String):String
	{
		var newString = path;

		// while (doubleVarMatch.match (newString)) {

		// 	newString = doubleVarMatch.matchedLeft () + "${" + ProjectHelper.replaceVariable (this, doubleVarMatch.matched (1)) + "}" + doubleVarMatch.matchedRight ();

		// }

		while (varMatch.match(newString))
		{
			newString = varMatch.matchedLeft() + ProjectHelper.replaceVariable(project, varMatch.matched(1)) + varMatch.matchedRight();
		}

		return newString;
	}
}
