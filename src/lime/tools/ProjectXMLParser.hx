package lime.tools;

import hxp.*;
import lime.tools.CommandHelper;
import lime.tools.ModuleHelper;
import lime.tools.Asset;
import lime.tools.AssetType;
import lime.tools.Dependency;
import lime.tools.HXProject;
#if lime
import lime.utils.AssetManifest;
#end
import sys.io.File;
import sys.FileSystem;
#if (haxe_ver >= 4)
import haxe.xml.Access;
#else
import haxe.xml.Fast as Access;
#end

class ProjectXMLParser extends HXProject
{
	public var includePaths:Array<String>;

	private static var doubleVarMatch = new EReg("\\$\\${(.*?)}", "");
	private static var varMatch = new EReg("\\${(.*?)}", "");

	public function new(path:String = "", defines:Map<String, Dynamic> = null, includePaths:Array<String> = null, useExtensionPath:Bool = false)
	{
		super();

		if (defines != null)
		{
			this.defines = MapTools.copy(defines);
		}

		if (includePaths != null)
		{
			this.includePaths = includePaths;
		}
		else
		{
			this.includePaths = new Array<String>();
		}

		initialize();

		if (path != "")
		{
			process(path, useExtensionPath);
		}
	}

	private function initialize():Void
	{
		switch (platformType)
		{
			case MOBILE:
				defines.set("platformType", "mobile");
				defines.set("mobile", "1");

			case DESKTOP:
				defines.set("platformType", "desktop");
				defines.set("desktop", "1");

			case WEB:
				defines.set("platformType", "web");
				defines.set("web", "1");

			case CONSOLE:
				defines.set("platformType", "console");
				defines.set("console", "1");
		}

		if (targetFlags.exists("neko"))
		{
			defines.set("targetType", "neko");
			defines.set("native", "1");
			defines.set("neko", "1");
		}
		else if (targetFlags.exists("hl"))
		{
			defines.set("targetType", "hl");
			defines.set("native", "1");
			defines.set("hl", "1");
		}
		else if (targetFlags.exists("java"))
		{
			defines.set("targetType", "java");
			defines.set("native", "1");
			defines.set("java", "1");
		}
		else if (targetFlags.exists("nodejs"))
		{
			defines.set("targetType", "nodejs");
			defines.set("native", "1");
			defines.set("nodejs", "1");
		}
		else if (targetFlags.exists("cs"))
		{
			defines.set("targetType", "cs");
			defines.set("native", "1");
			defines.set("cs", "1");
		}
		else if (target == Platform.FIREFOX)
		{
			defines.set("targetType", "js");
			defines.set("html5", "1");
		}
		else if (target == Platform.AIR)
		{
			defines.set("targetType", "swf");
			defines.set("flash", "1");
			if (targetFlags.exists("ios")) defines.set("ios", "1");
			if (targetFlags.exists("android")) defines.set("android", "1");
		}
		else if (target == Platform.WINDOWS && (targetFlags.exists("uwp") || targetFlags.exists("winjs")))
		{
			targetFlags.set("uwp", "");
			targetFlags.set("winjs", "");

			defines.set("targetType", "js");
			defines.set("html5", "1");
			defines.set("uwp", "1");
			defines.set("winjs", "1");
		}
		else if (platformType == DESKTOP && target != cast System.hostPlatform)
		{
			defines.set("native", "1");

			if (target == Platform.WINDOWS)
			{
				defines.set("targetType", "cpp");
				defines.set("cpp", "1");
				defines.set("mingw", "1");
			}
			else
			{
				defines.set("targetType", "neko");
				defines.set("neko", "1");
			}
		}
		else if (targetFlags.exists("cpp")
			|| ((platformType != PlatformType.WEB) && !targetFlags.exists("html5"))
			|| target == Platform.EMSCRIPTEN)
		{
			defines.set("targetType", "cpp");
			defines.set("native", "1");
			defines.set("cpp", "1");
		}
		else if (target == Platform.FLASH)
		{
			defines.set("targetType", "swf");
		}

		if (debug)
		{
			defines.set("buildType", "debug");
			defines.set("debug", "1");
		}
		else if (targetFlags.exists("final"))
		{
			defines.set("buildType", "final");
			defines.set("final", "1");
		}
		else
		{
			defines.set("buildType", "release");
			defines.set("release", "1");
		}

		if (targetFlags.exists("static"))
		{
			defines.set("static_link", "1");
		}

		if (defines.exists("SWF_PLAYER"))
		{
			environment.set("SWF_PLAYER", defines.get("SWF_PLAYER"));
		}

		defines.set(Std.string(target).toLowerCase(), "1");
		defines.set("target", Std.string(target).toLowerCase());
		defines.set("platform", defines.get("target"));

		switch (System.hostPlatform)
		{
			case WINDOWS:
				defines.set("host", "windows");
			case MAC:
				defines.set("host", "mac");
			case LINUX:
				defines.set("host", "linux");
			default:
				defines.set("host", "unknown");
		}

		#if lime
		defines.set("lime-tools", "1");
		#end

		defines.set("hxp", "1"); // TODO: Version?
	}

	private function isValidElement(element:Access, section:String):Bool
	{
		if (element.x.get("if") != null)
		{
			var value = element.x.get("if");
			var optionalDefines = value.split("||");
			var matchOptional = false;

			for (optional in optionalDefines)
			{
				optional = substitute(optional);
				var requiredDefines = optional.split(" ");
				var matchRequired = true;

				for (required in requiredDefines)
				{
					required = substitute(required);
					var check = StringTools.trim(required);

					if (check == "false")
					{
						matchRequired = false;
					}
					else if (check != ""
						&& check != "true"
						&& !defines.exists(check)
						&& (environment == null || !environment.exists(check))
						&& check != command)
					{
						matchRequired = false;
					}
				}

				if (matchRequired)
				{
					matchOptional = true;
				}
			}

			if (optionalDefines.length > 0 && !matchOptional)
			{
				return false;
			}
		}

		if (element.has.unless)
		{
			var value = substitute(element.att.unless);
			var optionalDefines = value.split("||");
			var matchOptional = false;

			for (optional in optionalDefines)
			{
				optional = substitute(optional);
				var requiredDefines = optional.split(" ");
				var matchRequired = true;

				for (required in requiredDefines)
				{
					required = substitute(required);
					var check = StringTools.trim(required);

					if (check == "false")
					{
						matchRequired = false;
					}
					else if (check != ""
						&& check != "true"
						&& !defines.exists(check)
						&& (environment == null || !environment.exists(check))
						&& check != command)
					{
						matchRequired = false;
					}
				}

				if (matchRequired)
				{
					matchOptional = true;
				}
			}

			if (optionalDefines.length > 0 && matchOptional)
			{
				return false;
			}
		}

		if (section != "")
		{
			if (element.name != "section")
			{
				return false;
			}

			if (!element.has.id)
			{
				return false;
			}

			if (substitute(element.att.id) != section)
			{
				return false;
			}
		}

		return true;
	}

	private function findIncludeFile(base:String):String
	{
		if (base == "")
		{
			return "";
		}

		if (base.substr(0, 1) != "/" && base.substr(0, 1) != "\\" && base.substr(1, 1) != ":" && base.substr(0, 1) != "." && !FileSystem.exists(base))
		{
			for (path in includePaths)
			{
				var includePath = path + "/" + base;

				if (FileSystem.exists(includePath))
				{
					if (FileSystem.exists(includePath + "/include.lime"))
					{
						return includePath + "/include.lime";
					}
					else if (FileSystem.exists(includePath + "/include.nmml"))
					{
						return includePath + "/include.nmml";
					}
					else if (FileSystem.exists(includePath + "/include.xml"))
					{
						return includePath + "/include.xml";
					}
					else
					{
						return includePath;
					}
				}
			}
		}
		else
		{
			if (base.substr(-1, 1) == "/")
			{
				base = base.substr(0, base.length - 1);
			}
			else if (base.substr(-1, 1) == "\\")
			{
				base = base.substring(0, base.length - 1);
			}

			if (FileSystem.exists(base))
			{
				if (FileSystem.exists(base + "/include.lime"))
				{
					return base + "/include.lime";
				}
				else if (FileSystem.exists(base + "/include.nmml"))
				{
					return base + "/include.nmml";
				}
				else if (FileSystem.exists(base + "/include.xml"))
				{
					return base + "/include.xml";
				}
				else
				{
					return base;
				}
			}
		}

		return "";
	}

	private function formatAttributeName(name:String):String
	{
		var segments = name.toLowerCase().split("-");

		for (i in 1...segments.length)
		{
			segments[i] = segments[i].substr(0, 1).toUpperCase() + segments[i].substr(1);
		}

		return segments.join("");
	}

	public static function fromFile(path:String, defines:Map<String, Dynamic> = null, includePaths:Array<String> = null,
			useExtensionPath:Bool = false):ProjectXMLParser
	{
		if (path == null) return null;

		if (FileSystem.exists(path))
		{
			return new ProjectXMLParser(path, defines, includePaths, useExtensionPath);
		}

		return null;
	}

	private function parseAppElement(element:Access, extensionPath:String):Void
	{
		for (attribute in element.x.attributes())
		{
			switch (attribute)
			{
				case "path":
					app.path = Path.combine(extensionPath, substitute(element.att.path));

				case "min-swf-version":
					var version = Std.parseFloat(substitute(element.att.resolve("min-swf-version")));

					if (version > app.swfVersion)
					{
						app.swfVersion = version;
					}

				case "swf-version":
					app.swfVersion = Std.parseFloat(substitute(element.att.resolve("swf-version")));

				case "preloader":
					app.preloader = substitute(element.att.preloader);

				default:
					// if we are happy with this spec, we can tighten up this parsing a bit, later

					var name = formatAttributeName(attribute);
					var value = substitute(element.att.resolve(attribute));

					if (attribute == "package")
					{
						name = "packageName";
					}

					if (Reflect.hasField(ApplicationData.expectedFields, name))
					{
						Reflect.setField(app, name, value);
					}
					else if (Reflect.hasField(MetaData.expectedFields, name))
					{
						Reflect.setField(meta, name, value);
					}
			}
		}
	}

	private function parseAssetsElement(element:Access, basePath:String = "", isTemplate:Bool = false):Void
	{
		var path = "";
		var embed:Null<Bool> = null;
		var library = null;
		var targetPath = "";
		var glyphs = null;
		var type = null;

		if (element.has.path)
		{
			path = Path.combine(basePath, substitute(element.att.path));
		}

		if (element.has.embed)
		{
			embed = parseBool(element.att.embed);
		}

		if (element.has.rename)
		{
			targetPath = substitute(element.att.rename);
		}
		else if (element.has.path)
		{
			targetPath = substitute(element.att.path);
		}

		if (element.has.library)
		{
			library = substitute(element.att.library);
		}

		if (element.has.glyphs)
		{
			glyphs = substitute(element.att.glyphs);
		}

		if (isTemplate)
		{
			type = AssetType.TEMPLATE;
		}
		else if (element.has.type)
		{
			var typeName = substitute(element.att.type);

			if (Reflect.hasField(AssetType, typeName.toUpperCase()))
			{
				type = Reflect.field(AssetType, typeName.toUpperCase());
			}
			else if (typeName == "bytes")
			{
				type = AssetType.BINARY;
			}
			else
			{
				Log.warn("Ignoring unknown asset type \"" + typeName + "\"");
			}
		}

		if (path == "" && (element.has.include || element.has.exclude || type != null))
		{
			Log.error("In order to use 'include' or 'exclude' on <asset /> nodes, you must specify also specify a 'path' attribute");
			return;
		}
		else if (!element.elements.hasNext())
		{
			// Empty element

			if (path == "")
			{
				return;
			}

			if (!FileSystem.exists(path))
			{
				Log.error("Could not find asset path \"" + path + "\"");
				return;
			}

			if (!FileSystem.isDirectory(path))
			{
				var asset = new Asset(path, targetPath, type, embed);
				asset.library = library;

				if (element.has.id)
				{
					asset.id = substitute(element.att.id);
				}

				if (glyphs != null)
				{
					asset.glyphs = glyphs;
				}

				assets.push(asset);
			}
			else if (Path.extension(path) == "bundle")
			{
				parseAssetsElementLibrary(path, targetPath, "*", "", type, embed, library, glyphs, true);
			}
			else
			{
				var exclude = ".*|cvs|thumbs.db|desktop.ini|*.fla|*.hash";
				var include = "";

				if (element.has.exclude)
				{
					exclude += "|" + substitute(element.att.exclude);
				}

				if (element.has.include)
				{
					include = substitute(element.att.include);
				}
				else
				{
					// if (type == null) {

					include = "*";

					/*} else {

						switch (type) {

							case IMAGE:

								include = "*.jpg|*.jpeg|*.png|*.gif";

							case SOUND:

								include = "*.wav|*.ogg";

							case MUSIC:

								include = "*.mp2|*.mp3|*.ogg";

							case FONT:

								include = "*.otf|*.ttf";

							case TEMPLATE:

								include = "*";

							default:

								include = "*";

						}

					}*/
				}

				parseAssetsElementDirectory(path, targetPath, include, exclude, type, embed, library, glyphs, true);
			}
		}
		else
		{
			if (path != "")
			{
				path += "/";
			}

			if (targetPath != "")
			{
				targetPath += "/";
			}

			for (childElement in element.elements)
			{
				var isValid = isValidElement(childElement, "");

				if (isValid)
				{
					var childPath = substitute(childElement.has.name ? childElement.att.name : childElement.att.path);
					var childTargetPath = childPath;
					var childEmbed:Null<Bool> = embed;
					var childLibrary = library;
					var childType = type;
					var childGlyphs = glyphs;

					if (childElement.has.rename)
					{
						childTargetPath = substitute(childElement.att.rename);
					}

					if (childElement.has.embed)
					{
						childEmbed = parseBool(childElement.att.embed);
					}

					if (childElement.has.library)
					{
						childLibrary = substitute(childElement.att.library);
					}

					if (childElement.has.glyphs)
					{
						childGlyphs = substitute(childElement.att.glyphs);
					}

					switch (childElement.name)
					{
						case "image", "sound", "music", "font", "template":
							childType = Reflect.field(AssetType, childElement.name.toUpperCase());

						case "library", "manifest":
							childType = AssetType.MANIFEST;

						default:
							if (childElement.has.type)
							{
								childType = Reflect.field(AssetType, substitute(childElement.att.type).toUpperCase());
							}
					}

					var id = "";

					if (childElement.has.id)
					{
						id = substitute(childElement.att.id);
					}
					else if (childElement.has.name)
					{
						id = substitute(childElement.att.name);
					}

					var asset = new Asset(path + childPath, targetPath + childTargetPath, childType, childEmbed);
					asset.library = childLibrary;
					asset.id = id;

					if (childGlyphs != null)
					{
						asset.glyphs = childGlyphs;
					}

					assets.push(asset);
				}
			}
		}
	}

	private function parseAssetsElementDirectory(path:String, targetPath:String, include:String, exclude:String, type:AssetType, embed:Null<Bool>,
			library:String, glyphs:String, recursive:Bool):Void
	{
		var files = FileSystem.readDirectory(path);

		if (targetPath != "")
		{
			targetPath += "/";
		}

		for (file in files)
		{
			if (FileSystem.isDirectory(path + "/" + file))
			{
				if (Path.extension(file) == "bundle")
				{
					parseAssetsElementLibrary(path + "/" + file, targetPath + file, include, exclude, type, embed, library, glyphs, true);
				}
				else if (recursive)
				{
					if (filter(file, ["*"], exclude.split("|")))
					{
						parseAssetsElementDirectory(path + "/" + file, targetPath + file, include, exclude, type, embed, library, glyphs, true);
					}
				}
			}
			else
			{
				if (filter(file, include.split("|"), exclude.split("|")))
				{
					var asset = new Asset(path + "/" + file, targetPath + file, type, embed);
					asset.library = library;

					if (glyphs != null)
					{
						asset.glyphs = glyphs;
					}

					assets.push(asset);
				}
			}
		}
	}

	private function parseAssetsElementLibrary(path:String, targetPath:String, include:String, exclude:String, type:AssetType, embed:Null<Bool>,
			library:String, glyphs:String, recursive:Bool):Void
	{
		var includePath = findIncludeFile(path);

		if (includePath != null && includePath != "" && FileSystem.exists(includePath) && !FileSystem.isDirectory(includePath))
		{
			var includeProject = new ProjectXMLParser(includePath, defines);
			merge(includeProject);
		}

		var processedLibrary = false;
		var jsonPath = Path.combine(path, "library.json");

		if (FileSystem.exists(jsonPath))
		{
			#if lime
			try
			{
				var manifest = AssetManifest.fromFile(jsonPath);

				if (manifest != null)
				{
					library = targetPath;

					var asset = new Asset(jsonPath, Path.combine(targetPath, "library.json"), AssetType.MANIFEST);
					asset.id = "libraries/" + library + ".json";
					asset.library = library;
					asset.data = manifest.serialize();
					asset.embed = embed;
					assets.push(asset);

					for (manifestAsset in manifest.assets)
					{
						if (Reflect.hasField(manifestAsset, "path"))
						{
							var asset = new Asset(Path.combine(path, manifestAsset.path), Path.combine(targetPath, manifestAsset.path), type, embed);
							asset.id = manifestAsset.id;
							asset.library = library;
							asset.embed = embed;
							assets.push(asset);
						}
					}

					processedLibrary = true;
				}
			}
			catch (e:Dynamic) {}
			#end
		}

		if (!processedLibrary)
		{
			parseAssetsElementDirectory(path, targetPath, include, exclude, type, embed, library, glyphs, true);
		}
	}

	private function parseBool(attribute:String):Bool
	{
		return substitute(attribute) == "true";
	}

	private function parseCommandElement(element:Access, commandList:Array<CLICommand>):Void
	{
		var command:CLICommand = null;

		if (element.has.haxe)
		{
			command = CommandHelper.interpretHaxe(substitute(element.att.haxe));
		}

		if (element.has.open)
		{
			command = CommandHelper.openFile(substitute(element.att.open));
		}

		if (element.has.command)
		{
			command = CommandHelper.fromSingleString(substitute(element.att.command));
		}

		if (element.has.cmd)
		{
			command = CommandHelper.fromSingleString(substitute(element.att.cmd));
		}

		if (command != null)
		{
			for (arg in element.elements)
			{
				if (arg.name == "arg")
				{
					command.args.push(arg.innerData);
				}
			}

			commandList.push(command);
		}
	}

	private function parseMetaElement(element:Access):Void
	{
		for (attribute in element.x.attributes())
		{
			switch (attribute)
			{
				case "title", "description", "package", "version", "company", "company-id", "build-number", "company-url":
					var value = substitute(element.att.resolve(attribute));

					defines.set("APP_" + StringTools.replace(attribute, "-", "_").toUpperCase(), value);

					var name = formatAttributeName(attribute);

					if (attribute == "package")
					{
						name = "packageName";
					}

					if (Reflect.hasField(MetaData.expectedFields, name))
					{
						Reflect.setField(meta, name, value);
					}
			}
		}
	}

	private function parseModuleElement(element:Access, basePath:String = "", moduleData:ModuleData = null):Void
	{
		var topLevel = (moduleData == null);

		var exclude = "";
		var include = "*";

		if (element.has.include)
		{
			include = substitute(element.att.include);
		}

		if (element.has.exclude)
		{
			exclude = substitute(element.att.exclude);
		}

		if (moduleData == null)
		{
			var name = substitute(element.att.name);

			if (modules.exists(name))
			{
				moduleData = modules.get(name);
			}
			else
			{
				moduleData = new ModuleData(name);
				modules.set(name, moduleData);
			}
		}

		switch (element.name)
		{
			case "module" | "source":
				var sourceAttribute = (element.name == "module" ? "source" : "path");

				if (element.has.resolve(sourceAttribute))
				{
					var source = Path.combine(basePath, substitute(element.att.resolve(sourceAttribute)));
					var packageName = "";

					if (element.has.resolve("package"))
					{
						packageName = element.att.resolve("package");
					}

					ModuleHelper.addModuleSource(source, moduleData, include.split("|"), exclude.split("|"), packageName);
				}

			case "class":
				if (element.has.remove)
				{
					moduleData.classNames.remove(substitute(element.att.remove));
				}
				else
				{
					moduleData.classNames.push(substitute(element.att.name));
				}

			case "haxedef":
				var value = substitute(element.att.name);

				if (element.has.value)
				{
					value += "=" + substitute(element.att.value);
				}

				moduleData.haxeflags.push("-D " + value);

			case "haxeflag":
				var flag = substitute(element.att.name);

				if (element.has.value)
				{
					flag += " " + substitute(element.att.value);
				}

				moduleData.haxeflags.push(substitute(flag));

			case "include":
				moduleData.includeTypes.push(substitute(element.att.type));

			case "exclude":
				moduleData.excludeTypes.push(substitute(element.att.type));
		}

		if (topLevel)
		{
			for (childElement in element.elements)
			{
				if (isValidElement(childElement, ""))
				{
					parseModuleElement(childElement, basePath, moduleData);
				}
			}
		}
	}

	private function parseOutputElement(element:Access, extensionPath:String):Void
	{
		if (element.has.name)
		{
			app.file = substitute(element.att.name);
		}

		if (element.has.path)
		{
			app.path = Path.combine(extensionPath, substitute(element.att.path));
		}

		if (element.has.resolve("swf-version"))
		{
			app.swfVersion = Std.parseFloat(substitute(element.att.resolve("swf-version")));
		}
	}

	private function parseXML(xml:Access, section:String, extensionPath:String = ""):Void
	{
		for (element in xml.elements)
		{
			var isValid = isValidElement(element, section);
			if (isValid)
			{
				switch (element.name)
				{
					case "set":
						var name = element.att.name;
						var value = "";

						if (element.has.value)
						{
							value = substitute(element.att.value);
						}

						switch (name)
						{
							case "BUILD_DIR": app.path = value;
							case "SWF_VERSION": app.swfVersion = Std.parseFloat(value);
							case "PRERENDERED_ICON": config.set("ios.prerenderedIcon", value);
							case "ANDROID_INSTALL_LOCATION": config.set("android.install-location", value);
						}

						defines.set(name, value);
						environment.set(name, value);

					case "unset":
						defines.remove(element.att.name);
						environment.remove(element.att.name);

					case "define":
						var name = element.att.name;
						var value = "";

						if (element.has.value)
						{
							value = substitute(element.att.value);
						}

						defines.set(name, value);
						haxedefs.set(name, value);
						environment.set(name, value);

					case "undefine":
						defines.remove(element.att.name);
						haxedefs.remove(element.att.name);
						environment.remove(element.att.name);

					case "setenv":
						var value = "";

						if (element.has.value)
						{
							value = substitute(element.att.value);
						}
						else
						{
							value = "1";
						}

						var name = substitute(element.att.name);

						defines.set(name, value);
						environment.set(name, value);
						setenv(name, value);

						if (needRerun) return;

					case "error":
						Log.error(substitute(element.att.value));

					case "echo":
						Log.println(substitute(element.att.value));

					case "log":
						var verbose = "";

						if (element.has.verbose)
						{
							verbose = substitute(element.att.verbose);
						}

						if (element.has.error)
						{
							Log.error(substitute(element.att.error), verbose);
						}
						else if (element.has.warn)
						{
							Log.warn(substitute(element.att.warn), verbose);
						}
						else if (element.has.info)
						{
							Log.info(substitute(element.att.info), verbose);
						}
						else if (element.has.value)
						{
							Log.info(substitute(element.att.value), verbose);
						}
						else if (verbose != "")
						{
							Log.info("", verbose);
						}

					case "path":
						var value = "";

						if (element.has.value)
						{
							value = substitute(element.att.value);
						}
						else
						{
							value = substitute(element.att.name);
						}

						path(value);

					case "include":
						var path = "";
						var addSourcePath = true;
						var haxelib = null;

						if (element.has.haxelib)
						{
							haxelib = new Haxelib(substitute(element.att.haxelib));
							path = findIncludeFile(Haxelib.getPath(haxelib, true));
							addSourcePath = false;
						}
						else if (element.has.path)
						{
							var subPath = substitute(element.att.path);
							if (subPath == "") subPath = element.att.path;

							path = findIncludeFile(Path.combine(extensionPath, subPath));
						}
						else
						{
							path = findIncludeFile(Path.combine(extensionPath, substitute(element.att.name)));
						}

						if (path != null && path != "" && FileSystem.exists(path) && !FileSystem.isDirectory(path))
						{
							var includeProject = new ProjectXMLParser(path, defines);

							if (includeProject != null && haxelib != null)
							{
								for (ndll in includeProject.ndlls)
								{
									if (ndll.haxelib == null)
									{
										ndll.haxelib = haxelib;
									}
								}
							}

							if (addSourcePath)
							{
								var dir = Path.directory(path);

								if (dir != "")
								{
									includeProject.sources.unshift(dir);
								}
							}

							merge(includeProject);
						}
						else if (!element.has.noerror)
						{
							if (path == "" || FileSystem.isDirectory(path))
							{
								var errorPath = "";

								if (element.has.path)
								{
									errorPath = element.att.path;
								}
								else if (element.has.name)
								{
									errorPath = element.att.name;
								}
								else
								{
									errorPath = Std.string(element);
								}

								Log.error("\"" + errorPath + "\" does not appear to be a valid <include /> path");
							}
							else
							{
								Log.error("Could not find include file \"" + path + "\"");
							}
						}

					case "meta":
						parseMetaElement(element);

					case "app":
						parseAppElement(element, extensionPath);

					case "java":
						javaPaths.push(Path.combine(extensionPath, substitute(element.att.path)));

					case "language":
						languages.push(element.att.name);

					case "haxelib":
						if (element.has.repository)
						{
							setenv("HAXELIB_PATH", Path.combine(Sys.getCwd(), element.att.repository));
							if (needRerun) return;
							continue;
						}

						var name = substitute(element.att.name);
						var version = "";
						var optional = false;
						var path = null;

						if (element.has.version)
						{
							version = substitute(element.att.version);
						}

						if (element.has.optional)
						{
							optional = parseBool(element.att.optional);
						}

						if (element.has.path)
						{
							path = Path.combine(extensionPath, substitute(element.att.path));
						}

						var haxelib = new Haxelib(name, version);

						if (version != "" && defines.exists(name) && !haxelib.versionMatches(defines.get(name)))
						{
							Log.warn("Ignoring requested haxelib \"" + name + "\" version \"" + version + "\" (version \"" + defines.get(name)
								+ "\" was already included)");
							continue;
						}

						if (path == null)
						{
							if (defines.exists("setup"))
							{
								path = Haxelib.getPath(haxelib);
							}
							else
							{
								path = Haxelib.getPath(haxelib, !optional);

								if (optional && path == "")
								{
									continue;
								}
							}
						}
						else
						{
							path = Path.tryFullPath(Path.combine(extensionPath, path));

							if (version != "")
							{
								Haxelib.pathOverrides.set(name + ":" + version, path);
							}
							else
							{
								Haxelib.pathOverrides.set(name, path);
							}
						}

						if (!defines.exists(haxelib.name))
						{
							defines.set(haxelib.name, Std.string(Haxelib.getVersion(haxelib)));
						}

						haxelibs.push(haxelib);

						var includeProject = HXProject.fromHaxelib(haxelib, defines);

						if (includeProject != null)
						{
							for (ndll in includeProject.ndlls)
							{
								if (ndll.haxelib == null)
								{
									ndll.haxelib = haxelib;
								}
							}

							merge(includeProject);
						}

					case "ndll":
						var name = substitute(element.att.name);
						var haxelib = null;
						var staticLink:Null<Bool> = null;
						var registerStatics = true;
						var subdirectory = null;

						if (element.has.haxelib)
						{
							haxelib = new Haxelib(substitute(element.att.haxelib));
						}

						if (element.has.dir)
						{
							subdirectory = substitute(element.att.dir);
						}

						if (haxelib == null && (name == "std" || name == "regexp" || name == "zlib"))
						{
							haxelib = new Haxelib(config.getString("cpp.buildLibrary", "hxcpp"));
						}

						if (element.has.type)
						{
							var typeString = substitute(element.att.type).toLowerCase();
							if (typeString == "static") staticLink = true;
							if (typeString == "dynamic") staticLink = false;
						}

						if (element.has.register)
						{
							registerStatics = parseBool(element.att.register);
						}

						var ndll = new NDLL(name, haxelib, staticLink, registerStatics);
						ndll.extensionPath = extensionPath;
						ndll.subdirectory = subdirectory;

						ndlls.push(ndll);

					case "architecture":
						if (element.has.name)
						{
							var name = substitute(element.att.name);

							if (Reflect.hasField(Architecture, name.toUpperCase()))
							{
								ArrayTools.addUnique(architectures, Reflect.field(Architecture, name.toUpperCase()));
							}
						}

						if (element.has.exclude)
						{
							var exclude = substitute(element.att.exclude);

							if (Reflect.hasField(Architecture, exclude.toUpperCase()))
							{
								ArrayTools.addUnique(excludeArchitectures, Reflect.field(Architecture, exclude.toUpperCase()));
							}
						}

					case "launchImage", "splashscreen", "splashScreen":
						var path = "";

						if (element.has.path)
						{
							path = Path.combine(extensionPath, substitute(element.att.path));
						}
						else
						{
							path = Path.combine(extensionPath, substitute(element.att.name));
						}

						var splashScreen = new SplashScreen(path);

						if (element.has.width)
						{
							splashScreen.width = Std.parseInt(substitute(element.att.width));
						}

						if (element.has.height)
						{
							splashScreen.height = Std.parseInt(substitute(element.att.height));
						}

						splashScreens.push(splashScreen);

					case "launchStoryboard":
						if (launchStoryboard == null)
						{
							launchStoryboard = new LaunchStoryboard();
						}

						if (element.has.path)
						{
							launchStoryboard.path = Path.combine(extensionPath, substitute(element.att.path));
						}
						else if (element.has.name)
						{
							launchStoryboard.path = Path.combine(extensionPath, substitute(element.att.name));
						}
						else if (element.has.template)
						{
							launchStoryboard.template = substitute(element.att.template);
							launchStoryboard.templateContext = {};

							for (attr in element.x.attributes())
							{
								if (attr == "assetsPath") continue;

								var valueType = "String";
								var valueName = attr;

								if (valueName.indexOf("-") != -1)
								{
									valueType = valueName.substring(valueName.lastIndexOf("-") + 1);
									valueName = valueName.substring(0, valueName.lastIndexOf("-"));
								}
								else if (valueName.indexOf(":") != -1)
								{
									valueType = valueName.substring(valueName.lastIndexOf(":") + 1);
									valueName = valueName.substring(0, valueName.lastIndexOf(":"));
								}

								var stringValue = element.x.get(attr);
								var value:Dynamic;

								switch (valueType)
								{
									case "Int":
										value = Std.parseInt(stringValue);
									case "RGB":
										var rgb:lime.math.ARGB = Std.parseInt(stringValue);
										value = {r: rgb.r / 255, g: rgb.g / 255, b: rgb.b / 255};
									case "String":
										value = stringValue;
									default:
										Log.warn("Ignoring unknown value type \"" + valueType + "\" in storyboard configuration.");
										value = "";
								}

								Reflect.setField(launchStoryboard.templateContext, valueName, value);
							}
						}

						if (element.has.assetsPath)
						{
							launchStoryboard.assetsPath = Path.combine(extensionPath, substitute(element.att.assetsPath));
						}

						for (childElement in element.elements)
						{
							var isValid = isValidElement(childElement, "");

							if (isValid)
							{
								switch (childElement.name)
								{
									case "imageset":
										var name = substitute(childElement.att.name);
										var imageset = new LaunchStoryboard.ImageSet(name);

										if (childElement.has.width) imageset.width = Std.parseInt(substitute(childElement.att.width));
										if (childElement.has.height) imageset.height = Std.parseInt(substitute(childElement.att.height));

										launchStoryboard.assets.push(imageset);
								}
							}
						}

					case "icon":
						var path = "";

						if (element.has.path)
						{
							path = Path.combine(extensionPath, substitute(element.att.path));
						}
						else
						{
							path = Path.combine(extensionPath, substitute(element.att.name));
						}

						var icon = new Icon(path);

						if (element.has.size)
						{
							icon.size = icon.width = icon.height = Std.parseInt(substitute(element.att.size));
						}

						if (element.has.width)
						{
							icon.width = Std.parseInt(substitute(element.att.width));
						}

						if (element.has.height)
						{
							icon.height = Std.parseInt(substitute(element.att.height));
						}

						icons.push(icon);

					case "source", "classpath":
						var path = "";

						if (element.has.path)
						{
							path = Path.combine(extensionPath, substitute(element.att.path));
						}
						else
						{
							path = Path.combine(extensionPath, substitute(element.att.name));
						}

						sources.push(path);

					case "extension":

					// deprecated

					case "haxedef":
						if (element.has.remove)
						{
							haxedefs.remove(substitute(element.att.remove));
						}
						else
						{
							var name = substitute(element.att.name);
							var value = "";

							if (element.has.value)
							{
								value = substitute(element.att.value);
							}

							haxedefs.set(name, value);
						}

					case "haxeflag", "compilerflag":
						var flag = substitute(element.att.name);

						if (element.has.value)
						{
							flag += " " + substitute(element.att.value);
						}

						haxeflags.push(substitute(flag));

					case "window":
						parseWindowElement(element);

					case "assets":
						parseAssetsElement(element, extensionPath);

					case "library", "swf":
						if (element.has.handler)
						{
							if (element.has.type)
							{
								libraryHandlers.set(substitute(element.att.type), substitute(element.att.handler));
							}
						}
						else
						{
							var path = null;
							var name = "";
							var type = null;
							var embed:Null<Bool> = null;
							var preload = false;
							var generate = false;
							var prefix = "";

							if (element.has.path)
							{
								path = Path.combine(extensionPath, substitute(element.att.path));
							}

							if (element.has.name)
							{
								name = substitute(element.att.name);
							}

							if (element.has.id)
							{
								name = substitute(element.att.id);
							}

							if (element.has.type)
							{
								type = substitute(element.att.type);
							}

							if (element.has.embed)
							{
								embed = parseBool(element.att.embed);
							}

							if (element.has.preload)
							{
								preload = parseBool(element.att.preload);
							}

							if (element.has.generate)
							{
								generate = parseBool(element.att.generate);
							}

							if (element.has.prefix)
							{
								prefix = substitute(element.att.prefix);
							}

							libraries.push(new Library(path, name, type, embed, preload, generate, prefix));
						}

					case "module":
						parseModuleElement(element, extensionPath);

					case "ssl":

					// if (wantSslCertificate())
					// parseSsl (element);

					case "sample":
						samplePaths.push(Path.combine(extensionPath, substitute(element.att.path)));

					case "target":
						if (element.has.handler)
						{
							if (element.has.name)
							{
								targetHandlers.set(substitute(element.att.name), substitute(element.att.handler));
							}
						}
						else if (element.has.path)
						{
							if (element.has.name)
							{
								targetHandlers.set(substitute(element.att.name), Path.combine(extensionPath, substitute(element.att.path)));
							}
						}

					case "template":
						if (element.has.path)
						{
							if (element.has.haxelib)
							{
								var haxelibPath = Haxelib.getPath(new Haxelib(substitute(element.att.haxelib)), true);
								var path = Path.combine(haxelibPath, substitute(element.att.path));
								templatePaths.push(path);
							}
							else
							{
								var path = Path.combine(extensionPath, substitute(element.att.path));

								if (FileSystem.exists(path) && !FileSystem.isDirectory(path))
								{
									parseAssetsElement(element, extensionPath, true);
								}
								else
								{
									templatePaths.push(path);
								}
							}
						}
						else
						{
							parseAssetsElement(element, extensionPath, true);
						}

					case "templatePath":
						templatePaths.push(Path.combine(extensionPath, substitute(element.att.name)));

					case "preloader":
						// deprecated

						app.preloader = substitute(element.att.name);

					case "output":
						// deprecated

						parseOutputElement(element, extensionPath);

					case "section":
						parseXML(element, "", extensionPath);

					case "certificate":
						var path = null;

						if (element.has.path)
						{
							path = element.att.path;
						}
						else if (element.has.keystore)
						{
							path = element.att.keystore;
						}

						if (path != null)
						{
							keystore = new Keystore(Path.combine(extensionPath, substitute(element.att.path)));

							if (element.has.type)
							{
								keystore.type = substitute(element.att.type);
							}

							if (element.has.password)
							{
								keystore.password = substitute(element.att.password);
							}

							if (element.has.alias)
							{
								keystore.alias = substitute(element.att.alias);
							}

							if (element.has.resolve("alias-password"))
							{
								keystore.aliasPassword = substitute(element.att.resolve("alias-password"));
							}
							else if (element.has.alias_password)
							{
								keystore.aliasPassword = substitute(element.att.alias_password);
							}
						}

						if (element.has.identity)
						{
							config.set("ios.identity", element.att.identity);
							config.set("tvos.identity", element.att.identity);
						}

						if (element.has.resolve("team-id"))
						{
							config.set("ios.team-id", element.att.resolve("team-id"));
							config.set("tvos.team-id", element.att.resolve("team-id"));
						}

					case "dependency":
						var name = "";
						var path = "";

						if (element.has.path)
						{
							path = Path.combine(extensionPath, substitute(element.att.path));
						}

						if (element.has.name)
						{
							var foundName = substitute(element.att.name);

							if (StringTools.endsWith(foundName, ".a") || StringTools.endsWith(foundName, ".dll"))
							{
								path = Path.combine(extensionPath, foundName);
							}
							else
							{
								name = foundName;
							}
						}

						var dependency = new Dependency(name, path);

						if (element.has.embed)
						{
							dependency.embed = parseBool(element.att.embed);
						}

						if (element.has.resolve("force-load"))
						{
							dependency.forceLoad = parseBool(element.att.resolve("force-load"));
						}

						var i = dependencies.length;

						while (i-- > 0)
						{
							if ((name != "" && dependencies[i].name == name) || (path != "" && dependencies[i].path == path))
							{
								dependencies.splice(i, 1);
							}
						}

						dependencies.push(dependency);

					case "android":
						// deprecated

						for (attribute in element.x.attributes())
						{
							var name = attribute;
							var value = substitute(element.att.resolve(attribute));

							switch (name)
							{
								case "minimum-sdk-version":
									config.set("android.minimum-sdk-version", Std.parseInt(value));

								case "target-sdk-version":
									config.set("android.target-sdk-version", Std.parseInt(value));

								case "install-location":
									config.set("android.install-location", value);

								case "extension":
									var extensions = config.getArrayString("android.extension");

									if (extensions == null || extensions.indexOf(value) == -1)
									{
										config.push("android.extension", value);
									}

								case "permission":
									var permissions = config.getArrayString("android.permission");

									if (permissions == null || permissions.indexOf(value) == -1)
									{
										config.push("android.permission", value);
									}

								case "gradle-version":
									config.set("android.gradle-version", value);

								default:
									name = formatAttributeName(attribute);
							}
						}

					case "cpp":
						// deprecated

						for (attribute in element.x.attributes())
						{
							var name = attribute;
							var value = substitute(element.att.resolve(attribute));

							switch (name)
							{
								case "build-library":
									config.set("cpp.buildLibrary", value);

								default:
									name = formatAttributeName(attribute);
							}
						}

					case "ios":
						// deprecated

						if (target == Platform.IOS)
						{
							if (element.has.deployment)
							{
								var deployment = Std.parseFloat(substitute(element.att.deployment));

								// If it is specified, assume the dev knows what he is doing!
								config.set("ios.deployment", deployment);
							}

							if (element.has.binaries)
							{
								var binaries = substitute(element.att.binaries);

								switch (binaries)
								{
									case "fat":
										ArrayTools.addUnique(architectures, Architecture.ARMV6);
										ArrayTools.addUnique(architectures, Architecture.ARMV7);

									case "armv6":
										ArrayTools.addUnique(architectures, Architecture.ARMV6);
										architectures.remove(Architecture.ARMV7);

									case "armv7":
										ArrayTools.addUnique(architectures, Architecture.ARMV7);
										architectures.remove(Architecture.ARMV6);
								}
							}

							if (element.has.devices)
							{
								config.set("ios.device", substitute(element.att.devices).toLowerCase());
							}

							if (element.has.compiler)
							{
								config.set("ios.compiler", substitute(element.att.compiler));
							}

							if (element.has.resolve("prerendered-icon"))
							{
								config.set("ios.prerenderedIcon", substitute(element.att.resolve("prerendered-icon")));
							}

							if (element.has.resolve("linker-flags"))
							{
								config.push("ios.linker-flags", substitute(element.att.resolve("linker-flags")));
							}
						}

					case "tvos":
						// deprecated

						if (target == Platform.TVOS)
						{
							if (element.has.deployment)
							{
								var deployment = Std.parseFloat(substitute(element.att.deployment));

								// If it is specified, assume the dev knows what he is doing!
								config.set("tvos.deployment", deployment);
							}

							if (element.has.binaries)
							{
								var binaries = substitute(element.att.binaries);

								switch (binaries)
								{
									case "arm64":
										ArrayTools.addUnique(architectures, Architecture.ARM64);
								}
							}

							if (element.has.devices)
							{
								config.set("tvos.device", substitute(element.att.devices).toLowerCase());
							}

							if (element.has.compiler)
							{
								config.set("tvos.compiler", substitute(element.att.compiler));
							}

							if (element.has.resolve("prerendered-icon"))
							{
								config.set("tvos.prerenderedIcon", substitute(element.att.resolve("prerendered-icon")));
							}

							if (element.has.resolve("linker-flags"))
							{
								config.push("tvos.linker-flags", substitute(element.att.resolve("linker-flags")));
							}
						}

					case "config":
						config.parse(element, substitute);

					case "prebuild":
						parseCommandElement(element, preBuildCallbacks);

					case "postbuild":
						parseCommandElement(element, postBuildCallbacks);

					default:
						if (StringTools.startsWith(element.name, "config:"))
						{
							config.parse(element, substitute);
						}
				}
			}
		}
	}

	private function parseWindowElement(element:Access):Void
	{
		var id = 0;

		if (element.has.id)
		{
			id = Std.parseInt(substitute(element.att.id));
		}

		while (id >= windows.length)
		{
			windows.push({});
		}

		for (attribute in element.x.attributes())
		{
			var name = attribute;
			var value = substitute(element.att.resolve(attribute));

			switch (name)
			{
				case "background":
					value = StringTools.replace(value, "#", "");

					if (value == "null" || value == "transparent" || value == "")
					{
						windows[id].background = null;
					}
					else
					{
						if (value.indexOf("0x") == -1) value = "0x" + value;

						if (value.length == 10 && StringTools.startsWith(value, "0x00"))
						{
							windows[id].background = null;
						}
						else
						{
							windows[id].background = Std.parseInt(value);
						}
					}

				case "orientation":
					var orientation = Reflect.field(Orientation, Std.string(value).toUpperCase());

					if (orientation != null)
					{
						windows[id].orientation = orientation;
					}

				case "height", "width", "fps", "antialiasing":
					Reflect.setField(windows[id], name, Std.parseInt(value));

				case "parameters", "title":
					Reflect.setField(windows[id], name, Std.string(value));

				case "allow-high-dpi":
					Reflect.setField(windows[id], "allowHighDPI", value == "true");

				case "color-depth":
					Reflect.setField(windows[id], "colorDepth", Std.parseInt(value));

				default:
					if (Reflect.hasField(WindowData.expectedFields, name))
					{
						Reflect.setField(windows[id], name, value == "true");
					}
					else if (Reflect.hasField(WindowData.expectedFields, formatAttributeName(name)))
					{
						Reflect.setField(windows[id], formatAttributeName(name), value == "true");
					}
			}
		}
	}

	public function process(projectFile:String, useExtensionPath:Bool):Void
	{
		var xml = null;
		var extensionPath = "";

		try
		{
			xml = new Access(Xml.parse(File.getContent(projectFile)).firstElement());
			extensionPath = Path.directory(projectFile);
		}
		catch (e:Dynamic)
		{
			Log.error("\"" + projectFile + "\" contains invalid XML data", e);
		}

		parseXML(xml, "", extensionPath);
	}

	private function substitute(string:String):String
	{
		var newString = string;

		while (doubleVarMatch.match(newString))
		{
			newString = doubleVarMatch.matchedLeft()
				+ "${"
				+ ProjectHelper.replaceVariable(this, doubleVarMatch.matched(1))
				+ "}"
				+ doubleVarMatch.matchedRight();
		}

		while (varMatch.match(newString))
		{
			newString = varMatch.matchedLeft() + ProjectHelper.replaceVariable(this, varMatch.matched(1)) + varMatch.matchedRight();
		}

		return newString;
	}
}
