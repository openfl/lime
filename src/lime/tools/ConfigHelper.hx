package lime.tools;

import hxp.*;
import lime.tools.HXProject;
import lime.tools.Platform;
import lime.tools.ProjectXMLParser;
import sys.io.File;
import sys.FileSystem;

class ConfigHelper
{
	private static var backedUpConfig:Bool = false;
	private static var configPath:String = null;

	public static function getConfig():HXProject
	{
		var config = getConfigPath();

		if (FileSystem.exists(config))
		{
			Log.info("", Log.accentColor + "Reading Lime config: " + config + Log.resetColor);

			return new ProjectXMLParser(config);
		}
		else
		{
			Log.warn("", "Could not read Lime config: " + config);
		}

		return null;
	}

	public static function getConfigPath():String
	{
		if (configPath == null)
		{
			var environment = Sys.environment();

			if (environment.exists("LIME_CONFIG"))
			{
				configPath = environment.get("LIME_CONFIG");
			}
			else
			{
				var home = "";

				if (environment.exists("HOME"))
				{
					home = environment.get("HOME");
				}
				else if (environment.exists("USERPROFILE"))
				{
					home = environment.get("USERPROFILE");
				}
				else
				{
					Log.warn("Lime config might be missing (Environment has no \"HOME\" variable)");

					return null;
				}

				configPath = home + "/.lime/config.xml";

				if (System.hostPlatform == WINDOWS)
				{
					configPath = configPath.split("/").join("\\");
				}

				if (!FileSystem.exists(configPath))
				{
					System.mkdir(Path.directory(configPath));

					var hxcppConfig = null;

					if (environment.exists("HXCPP_CONFIG"))
					{
						hxcppConfig = environment.get("HXCPP_CONFIG");
					}
					else
					{
						hxcppConfig = home + "/.hxcpp_config.xml";
					}

					if (FileSystem.exists(hxcppConfig))
					{
						var vars = new ProjectXMLParser(hxcppConfig);

						for (key in vars.defines.keys())
						{
							if (key != key.toUpperCase())
							{
								vars.defines.remove(key);
							}
						}

						writeConfig(configPath, vars.defines);
					}
					else
					{
						writeConfig(configPath, new Map());
					}
				}

				Sys.putEnv("LIME_CONFIG", configPath);
			}
		}

		return configPath;
	}

	public static function getConfigValue(name:String):String
	{
		var config = getConfig();

		if (config.defines.exists(name))
		{
			return config.defines.get(name);
		}

		return null;
	}

	public static function removeConfigValue(name:String):Void
	{
		var path = getConfigPath();

		if (FileSystem.exists(path))
		{
			var configText = File.getContent(path);
			var lines = configText.split("\n");

			var findSet = "<set name=\"" + name + "\"";
			var findSetenv = "<setenv name=\"" + name + "\"";
			var findDefine = "<define name=\"" + name + "\"";
			var line, i = 0, index = 0, found = false;

			while (i < lines.length)
			{
				line = lines[i];

				if ((index = line.indexOf(findSet)) > -1)
				{
					found = true;
					lines.splice(i, 1);
					continue;
				}

				if ((index = line.indexOf(findSetenv)) > -1)
				{
					found = true;
					lines.splice(i, 1);
					continue;
				}

				if ((index = line.indexOf(findDefine)) > -1)
				{
					found = true;
					lines.splice(i, 1);
					continue;
				}

				i++;
			}

			var content = lines.join("\n");
			File.saveContent(path, content);

			if (found)
			{
				Log.info("Removed define \"" + name + "\"");
			}
			else
			{
				Log.info("There is no define \"" + name + "\"");
			}
		}
		else
		{
			Log.error("Cannot find \"" + path + "\"");
		}
	}

	private static function stripQuotes(path:String):String
	{
		if (path != null)
		{
			return path.split("\"").join("");
		}

		return path;
	}

	public static function writeConfig(path:String, defines:Map<String, Dynamic>):Void
	{
		var newContent = "";
		var definesText = "";
		var env = Sys.environment();

		for (key in defines.keys())
		{
			if (key != "LIME_CONFIG" && key != "LIME_CONFIG" && (!env.exists(key) || env.get(key) != defines.get(key)))
			{
				definesText += "\t\t<set name=\"" + key + "\" value=\"" + stripQuotes(Std.string(defines.get(key))) + "\" />\n";
			}
		}

		if (FileSystem.exists(path))
		{
			var input = File.read(path, false);
			var bytes = input.readAll();
			input.close();

			if (!backedUpConfig)
			{
				try
				{
					var backup = File.write(path + ".bak", false);
					backup.writeBytes(bytes, 0, bytes.length);
					backup.close();
				}
				catch (e:Dynamic) {}

				backedUpConfig = true;
			}

			var content = bytes.getString(0, bytes.length);

			var startIndex = content.indexOf("<section id=\"defines\">");
			var endIndex = content.indexOf("</section>", startIndex);

			newContent += content.substr(0, startIndex) + "<section id=\"defines\">\n\t\t\n";
			newContent += definesText;
			newContent += "\t\t\n\t" + content.substr(endIndex);
		}
		else
		{
			newContent += "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
			newContent += "<config>\n\t\n";
			newContent += "\t<section id=\"defines\">\n\t\t\n";
			newContent += definesText;
			newContent += "\t\t\n\t</section>\n\t\n</config>";
		}

		var output = File.write(path, false);
		output.writeString(newContent);
		output.close();

		if (backedUpConfig)
		{
			try
			{
				FileSystem.deleteFile(path + ".bak");
			}
			catch (e:Dynamic) {}
		}
	}

	public static function writeConfigValue(name:String, value:String):Void
	{
		var path = getConfigPath();

		try
		{
			if (!FileSystem.exists(value) && FileSystem.exists(Path.expand(value)))
			{
				value = Path.expand(value);
			}
		}
		catch (e:Dynamic) {}

		if (FileSystem.exists(path))
		{
			var configText = File.getContent(path);
			var lines = configText.split("\n");

			var findSet = "<set name=\"" + name + "\"";
			var findSetenv = "<setenv name=\"" + name + "\"";
			var findDefine = "<define name=\"" + name + "\"";
			var line, i = 0, index = 0, found = false;

			while (i < lines.length)
			{
				line = lines[i];

				if ((index = line.indexOf(findSet)) > -1)
				{
					found = true;
					lines[i] = line.substr(0, index) + "<set name=\"" + name + "\" value=\"" + value + "\" />";
				}

				if ((index = line.indexOf(findSetenv)) > -1)
				{
					found = true;
					lines[i] = line.substr(0, index) + "<setenv name=\"" + name + "\" value=\"" + value + "\" />";
				}

				if ((index = line.indexOf(findDefine)) > -1)
				{
					found = true;
					lines[i] = line.substr(0, index) + "<define name=\"" + name + "\" value=\"" + value + "\" />";
				}

				i++;
			}

			if (!found && lines.length > 2)
			{
				var insertPoint = lines.length - 3;

				if (StringTools.trim(lines[lines.length - 1]) == "")
				{
					insertPoint--;
				}

				if (StringTools.trim(lines[insertPoint + 1]) != "")
				{
					lines.insert(insertPoint + 1, "\t");
				}

				lines.insert(insertPoint + 1, "\t<define name=\"" + name + "\" value=\"" + value + "\" />");
			}

			var content = lines.join("\n");
			File.saveContent(path, content);

			Log.info("Set \x1b[1m" + name + "\x1b[0m to \x1b[1m" + value + "\x1b[0m");
		}
		else
		{
			Log.error("Cannot find \"" + path + "\"");
		}
	}
}
