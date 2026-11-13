package system;

import lime.system.System;
import utest.Assert;
import utest.Test;

class WindowsFileAttributesTest extends Test
{
	public function new()
	{
		super();
	}

	public function testHiddenFlag():Void
	{
		#if (sys && windows && lime_cffi)
		// a name outside ASCII, as the path goes to Windows in UTF-16. Neko's files take
		// their names in the ANSI code page, so there the file would have another name
		var path = haxe.io.Path.join([Sys.getCwd(), #if neko "attributes.txt" #else "attributes-é.txt" #end]);
		sys.io.File.saveContent(path, "test");

		var attributes = @:privateAccess System.__getWindowsFileAttributes(path);
		Assert.notEquals(-1, attributes);
		Assert.equals(0, attributes & 0x2);

		Assert.equals(0, Sys.command("attrib", ["+h", path]));
		Assert.equals(0x2, @:privateAccess System.__getWindowsFileAttributes(path) & 0x2);

		Sys.command("attrib", ["-h", path]);
		sys.FileSystem.deleteFile(path);
		Assert.equals(-1, @:privateAccess System.__getWindowsFileAttributes(path));
		#else
		Assert.equals(-1, @:privateAccess System.__getWindowsFileAttributes("."));
		#end
	}
}
