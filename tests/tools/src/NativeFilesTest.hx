import hxp.Path;
import sys.FileSystem;
import sys.io.File;
import utest.Assert;
import utest.Test;

/**
	The source files a native library's build file names, which only a build for the platform that
	compiles them would find missing. Lime's own copies of a library's files are in project/lib/custom,
	as SDL's UIKit files for the iOS scene life cycle are (#1990), and are checked every time. A
	library's own files are checked where its submodule is checked out.
**/
class NativeFilesTest extends Test
{
	private static inline var TOOLKIT = "${NATIVE_TOOLKIT_PATH}/";

	public function new()
	{
		super();
	}

	public function testEveryFileTheSDLBuildNamesIsThere():Void
	{
		var lib = Path.combine(LimeRepo.path(), "project/lib");
		var xml = Xml.parse(File.getContent(Path.combine(lib, "sdl-files.xml")));
		var missing = [];
		var checked = 0;
		var skipped = 0;

		for (name in fileNames(xml))
		{
			if (!StringTools.startsWith(name, TOOLKIT)) continue;

			var relative = name.substr(TOOLKIT.length);
			if (relative.indexOf("${") > -1) continue;

			if (!StringTools.startsWith(relative, "custom/") && !checkedOut(Path.combine(lib, relative.split("/")[0])))
			{
				skipped++;
				continue;
			}

			checked++;
			if (!FileSystem.exists(Path.combine(lib, relative))) missing.push(relative);
		}

		Assert.isTrue(checked > 0, "no file of sdl-files.xml was checked");
		Assert.equals("", missing.join(", "), "files sdl-files.xml names that aren't there");

		if (skipped > 0)
		{
			trace(skipped + " files of SDL's own were not checked, as its submodule isn't checked out here");
		}
	}

	/** The name of every <file> in a build file, in sections and targets too **/
	private static function fileNames(xml:Xml):Array<String>
	{
		var names = [];

		for (element in xml.elements())
		{
			if (element.nodeName == "file" && element.exists("name")) names.push(element.get("name"));
			names = names.concat(fileNames(element));
		}

		return names;
	}

	private static function checkedOut(directory:String):Bool
	{
		return FileSystem.exists(directory) && FileSystem.isDirectory(directory) && FileSystem.readDirectory(directory).length > 0;
	}
}
