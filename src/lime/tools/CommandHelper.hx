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
			return new CLICommand("start", [file]);
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
		Opens `url` in the default browser without waiting for the browser.

		On Linux, hxp 1.3.1's `System.openURL()` passes a literal "&" to
		xdg-open, which exits with an error and stops the tools. Until Lime
		depends on an hxp with that fixed, xdg-open is run through the shell
		here instead, in the background, with its output discarded.
	**/
	public static function openURL(url:String):Void
	{
		if (System.hostPlatform == WINDOWS || System.hostPlatform == MAC)
		{
			System.openURL(url);
		}
		else
		{
			var quotedURL = "'" + StringTools.replace(url, "'", "'\\''") + "'";
			System.runCommand("", "xdg-open " + quotedURL + " > /dev/null 2>&1 &", null, true, true);
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
