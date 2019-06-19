package lime.utils;

import haxe.zip.Reader;
import lime.utils.Bytes;

#if sys
import sys.io.File;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class AssetBundle
{
	public var data:Map<String, Bytes>;
	public var paths:Array<String>;

	public function new()
	{
		// compressed = new Map();
		data = new Map();
		paths = new Array();
	}

	public static function fromFile(path:String):AssetBundle
	{
		#if sys
		var input = File.read(path);
		var entries = Reader.readZip(input);

		var bundle = new AssetBundle();

		for (entry in entries)
		{
			if (entry.compressed)
			{
				var bytes:Bytes = entry.data;
				bundle.data.set(entry.fileName, bytes.decompress(DEFLATE));
			}
			else
			{
				bundle.data.set(entry.fileName, entry.data);
			}
			bundle.paths.push(entry.fileName);
		}

		return bundle;
		#else
		return null;
		#end
	}
}