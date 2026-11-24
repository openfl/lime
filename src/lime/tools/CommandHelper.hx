package lime.tools;

import hxp.*;
import lime.tools.CLICommand;
import lime.tools.Platform;

class CommandHelper
{
	public static function executeCommands(commands:Array<CLICommand>):Void
	{
		for (c in commands)
		{
			Sys.command(c.command, c.args);
		}
	}

	public static function openFile(file:String):CLICommand
	{
		if (System.hostPlatform == WINDOWS)
		{
			// Haxe quotes an argument with a slash or space in it, and start takes
			// its first quoted argument as the title of a new console window
			return new CLICommand("start", ["", file]);
		}
		else if (System.hostPlatform == MAC)
		{
			return new CLICommand("/usr/bin/open", [file]);
		}
		else
		{
			return new CLICommand("/usr/bin/xdg-open", [file]);
		}
	}

	/**
		Opens `url` in the default browser. hxp's `System.openURL()` hands it to
		`start` on Windows as it is, which opens a console window titled with the
		URL instead, as Haxe quotes it for the slashes in it.
	**/
	public static function openURL(url:String):Void
	{
		if (System.hostPlatform == WINDOWS)
		{
			Log.info("", " - \x1b[1mOpening:\x1b[0m " + url);
			Sys.command("start", ["", url]);
		}
		else
		{
			System.openURL(url);
		}
	}

	public static function interpretHaxe(mainFile:String):CLICommand
	{
		return new CLICommand("haxe", ["-main", mainFile, "--interp"]);
	}

	public static function fromSingleString(command:String):CLICommand
	{
		var args:Array<String> = command.split(" ");
		command = args.shift();
		return new CLICommand(command, args);
	}
}
