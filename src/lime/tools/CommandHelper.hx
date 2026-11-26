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
		Opens `url` in the default browser without waiting for the browser.

		hxp 1.3.1's `System.openURL()` gets two hosts wrong. On Windows it hands
		the URL to `start` as it is, which opens a console window titled with the
		URL instead, as Haxe quotes it for the slashes in it, so `start` is given
		an empty title first. On Linux it passes a literal "&" to xdg-open, which
		exits with an error and stops the tools, so xdg-open is run through the
		shell instead, in the background, with its output discarded.
	**/
	public static function openURL(url:String):Void
	{
		if (System.hostPlatform == WINDOWS)
		{
			Log.info("", " - \x1b[1mOpening:\x1b[0m " + url);
			Sys.command("start", ["", url]);
		}
		else if (System.hostPlatform == MAC)
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
