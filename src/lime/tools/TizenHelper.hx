package lime.tools;

import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.Eof;
import hxp.*;
import lime.tools.HXProject;
import lime.tools.Platform;
import sys.FileSystem;

class TizenHelper
{
	private static var cacheID:String = null;
	private static var cacheUUID:String = null;

	public static function createPackage(project:HXProject, workingDirectory:String, targetPath:String):Void
	{
		var keystore:String = null;
		var password:String = null;

		if (project.keystore != null)
		{
			keystore = Path.tryFullPath(project.keystore.path);
			password = project.keystore.password;

			if (password == null)
			{
				password = prompt("Keystore password", true);
				Sys.println("");
			}
		}

		if (keystore == null)
		{
			var templatePaths = [
				Path.combine(Haxelib.getPath(new Haxelib(#if lime "lime" #else "hxp" #end)), #if lime "templates" #else "" #end)
			].concat(project.templatePaths);
			keystore = System.findTemplate(templatePaths, "bin/debug.p12");
			password = "1234";
		}

		var packageName = getUUID(project) + "-" + project.meta.version + "-";

		if (project.targetFlags.exists("simulator"))
		{
			packageName += "i386";
		}
		else
		{
			packageName += "arm";
		}

		packageName += ".tpk";

		if (FileSystem.exists(Path.combine(workingDirectory, packageName)))
		{
			try
			{
				FileSystem.deleteFile((Path.combine(workingDirectory, packageName)));
			}
			catch (e:Dynamic) {}
		}

		runCommand(project, workingDirectory, "native-packaging", ["--sign-author-key", keystore, "--sign-author-pwd", password]);
	}

	public static function getUUID(project:HXProject):String
	{
		if (cacheID != project.meta.packageName)
		{
			if (project.meta.packageName != null || project.meta.packageName.length == 10 || project.meta.packageName.indexOf(".") == -1)
			{
				var bytes = Bytes.ofString(project.meta.packageName);
				var crc = Crc32.make(bytes);
				cacheUUID = StringTools.generateUUID(10, null, crc);
			}
			else
			{
				cacheUUID = project.meta.packageName;
			}

			cacheID = project.meta.packageName;
		}

		return cacheUUID;
	}

	public static function install(project:HXProject, workingDirectory:String):Void
	{
		var packageName = getUUID(project) + "-" + project.meta.version + "-";

		if (project.targetFlags.exists("simulator"))
		{
			packageName += "i386";
		}
		else
		{
			packageName += "arm";
		}

		packageName += ".tpk";

		runCommand(project, "", "native-install", ["--package", FileSystem.fullPath(workingDirectory + "/" + packageName)]);
	}

	public static function launch(project:HXProject):Void
	{
		runCommand(project, "", "native-run", ["--package", getUUID(project)]);
	}

	private static function prompt(name:String, ?passwd:Bool):String
	{
		Sys.print(name + ": ");

		if (passwd)
		{
			var s = new StringBuf();
			var c:Int;
			while ((c = Sys.getChar(false)) != 13)
				s.addChar(c);
			return s.toString();
		}

		try
		{
			return Sys.stdin().readLine();
		}
		catch (e:Eof)
		{
			return "";
		}
	}

	private static function runCommand(project:HXProject, workingDirectory:String, command:String, args:Array<String>):Void
	{
		var sdkDirectory = "";

		if (project.environment.exists("TIZEN_SDK"))
		{
			sdkDirectory = project.environment.get("TIZEN_SDK");
		}
		else
		{
			if (System.hostPlatform == WINDOWS)
			{
				sdkDirectory = "C:\\Development\\Tizen\\tizen-sdk";
			}
			else
			{
				sdkDirectory = "~/Development/Tizen/tizen-sdk";
			}
		}

		System.runCommand(workingDirectory, Path.combine(sdkDirectory, "tools/ide/bin/" + command), args);
	}

	public static function trace(project:HXProject, follow:Bool = true):Void
	{
		/*var args:Array<String> = [];

			if (follow) {

				args.push ("-f");

			}

			args.push (project.meta.packageName);

			runPalmCommand (project, "", "log", args); */

		var sdkDirectory = "";

		if (project.environment.exists("TIZEN_SDK"))
		{
			sdkDirectory = project.environment.get("TIZEN_SDK");
		}
		else
		{
			if (System.hostPlatform == WINDOWS)
			{
				sdkDirectory = "C:\\Development\\Tizen\\tizen-sdk";
			}
			else
			{
				sdkDirectory = "~/Development/Tizen/tizen-sdk";
			}
		}

		// var args = [ "--package", project.meta.packageName ];
		// var args = [ "dlog", project.meta.packageName + ":V", "*:E" ];
		var args = ["dlog", project.app.file + ":V", "*:F"];

		System.runCommand("", Path.combine(sdkDirectory, "tools/sdb"), ["dlog", "-c"]);
		System.runCommand("", Path.combine(sdkDirectory, "tools/sdb"), args);
		// runCommand (project, "", "native-debug", [ "-p", project.meta.packageName ]);
	}
}
