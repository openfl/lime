package lime.tools;

#if crossbyte
import crossbyte.core.HostApplication;
import crossbyte.http.HTTPServer;
import crossbyte.http.HTTPServerConfig;
import crossbyte.io.File;
import crossbyte.url.URLRequestHeader;
import crossbyte.utils.LogLevel;
import crossbyte.utils.Logger;
import haxe.Timer;
import hxp.*;
import sys.FileSystem;

/**
	Serves a build's output folder to the browser for `lime test html5`, until
	the process ends. Pages are never cached, any origin may read them, and
	media seeks with range requests.

	It is CrossByte's `HTTPServer`, driven from here. snake-server was the other
	choice, but like Python's `http.server`, which it ports, it does not answer
	range requests, and audio and video cannot seek without them.
**/
class WebServer extends HostApplication
{
	private static inline var FIRST_PORT:Int = 3000;
	private static inline var LAST_PORT:Int = 3100;

	/**
		Serves `path` on `host` until the process ends. A `port` of 0 takes the
		first free one from 3000.
	**/
	public static function serve(path:String, host:String, port:Int, open:Bool):Void
	{
		// A port that is taken is not news; what comes of the search is
		Logger.level = Log.verbose ? LogLevel.INFO : LogLevel.OFF;

		var application = new WebServer();
		var server = application.listen(path, host, port);

		if (server == null)
		{
			Log.error(port != 0 ? "Could not serve on port " + port : "Could not find a free port from " + FIRST_PORT + " to " + LAST_PORT);
			return;
		}

		var url = "http://" + (host == "0.0.0.0" || host == "::" ? "localhost" : host) + ":" + server.localPort;
		Log.info("\x1b[1mStarting local web server:\x1b[0m " + url);
		Log.info("Press Ctrl+C to stop");

		if (open)
		{
			System.openURL(url);
		}

		var last = Timer.stamp();

		while (true)
		{
			var now = Timer.stamp();
			application.advance(now - last, 0.05);
			last = now;
		}
	}

	private function new()
	{
		super();
	}

	private function listen(path:String, host:String, port:Int):HTTPServer
	{
		var first = port != 0 ? port : FIRST_PORT;
		var last = port != 0 ? port : LAST_PORT;

		for (candidate in first...last + 1)
		{
			var config = new HTTPServerConfig(host, candidate, new File(FileSystem.fullPath(path)));
			config.directoryIndex = ["index.html"];
			config.corsEnabled = true;
			config.customHeaders = [new URLRequestHeader("Cache-Control", "no-store")];

			if (Log.verbose)
			{
				config.middleware = [
					function(handler, next)
					{
						Log.info("", handler.method + " " + handler.requestPath);
						next();
					}
				];
			}

			try
			{
				return new HTTPServer(config);
			}
			catch (e:Dynamic) {}
		}

		return null;
	}
}
#end
