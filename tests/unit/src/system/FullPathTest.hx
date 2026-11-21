package system;

import utest.Assert;
import utest.Test;

/**
	Lime builds the HashLink runtime it ships, so its file system functions
	have to work as they do in HashLink's own builds.
**/
class FullPathTest extends Test
{
	public function new()
	{
		super();
	}

	#if (sys && !macro)
	public function testFullPathGivesAFoldersPathWithItsCaseOnDisk():Void
	{
		var base = Sys.getEnv("TEMP");
		if (base == null || base == "") base = Sys.getEnv("TMPDIR");
		if (base == null || base == "") base = "/tmp";

		var name = "LimeFullPath" + Std.random(0x10000);
		var folder = haxe.io.Path.join([sys.FileSystem.fullPath(base), name]);
		sys.FileSystem.createDirectory(folder);

		try
		{
			#if windows
			// Windows names are case insensitive, and the full path has the case on disk
			var asked = haxe.io.Path.join([sys.FileSystem.fullPath(base), name.toLowerCase()]);
			#else
			var asked = folder;
			#end

			var full = sys.FileSystem.fullPath(asked);
			Assert.notNull(full);

			if (full != null)
			{
				var last = haxe.io.Path.withoutDirectory(haxe.io.Path.removeTrailingSlashes(full));
				#if hl
				// HashLink looks up each part of the path for its case on disk
				Assert.equals(name, last);
				#else
				Assert.equals(name.toLowerCase(), last.toLowerCase());
				#end
			}
		}
		catch (e:Dynamic)
		{
			Assert.fail("fullPath() threw " + e);
		}

		sys.FileSystem.deleteDirectory(folder);
	}
	#end
}
