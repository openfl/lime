package lime.tools;

import haxe.io.Eof;
import hxp.*;

class CLIHelper
{
	public static function ask(question:String, options:Array<String> = null):Answer
	{
		if (options == null)
		{
			options = ["y", "n", "a"];
		}

		while (true)
		{
			Log.print(Log.accentColor + question + "\x1b[0m \x1b[3;37m[" + options.join("/") + "]\x1b[0m ? ");

			try
			{
				switch (readLine())
				{
					case "n":
						return NO;
					case "y":
						return YES;
					case "a":
						return ALWAYS;
					case _ => x if (options.indexOf(x) > -1):
						return CUSTOM(x);
				}
			}
			catch (e:Dynamic)
			{
				Sys.exit(0);
			}
		}

		return null;
	}

	public static inline function getChar():Int
	{
		return Sys.getChar(false);
	}

	public static function param(name:String, passwd:Bool = false):String
	{
		Log.print(name + ": ");

		if (passwd)
		{
			var s = new StringBuf();
			var c;
			while ((c = getChar()) != 13)
				s.addChar(c);

			Log.print("");
			Log.println("");

			return s.toString();
		}

		try
		{
			return readLine();
		}
		catch (e:Eof)
		{
			return "";
		}
	}

	public static function progress(prefix:String, now:Int, total:Int):Void
	{
		var percent = Math.floor((now / total) * 100);

		Log.print('\r$prefix $now/$total ($percent%)');
	}

	public static inline function readLine():String
	{
		return Sys.stdin().readLine();
	}
}

enum Answer
{
	YES;
	NO;
	ALWAYS;
	CUSTOM(answer:String);
}
