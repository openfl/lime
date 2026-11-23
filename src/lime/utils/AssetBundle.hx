package lime.utils;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.zip.Reader;
import lime.app.Future;
import lime.utils.Bytes as LimeBytes;
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

	/**
		The bundle in the zip `bytes` hold, or `null` when they aren't a zip.
	**/
	public static function fromBytes(bytes:Bytes):AssetBundle
	{
		try
		{
			return __extractBundle(new BytesInput(bytes));
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	/**
		The bundle in the zip file at `path`, or `null` when it can't be read as one.
	**/
	public static function fromFile(path:String):AssetBundle
	{
		#if sys
		var input = null;

		try
		{
			input = File.read(path);
			var bundle = __extractBundle(input);
			input.close();
			return bundle;
		}
		catch (e:Dynamic)
		{
			if (input != null) input.close();
			return null;
		}
		#else
		return null;
		#end
	}

	/**
		Reads the bundle in the zip `bytes` hold. The future fails, saying why, when they aren't a zip.
	**/
	public static function loadFromBytes(bytes:Bytes):Future<AssetBundle>
	{
		try
		{
			return Future.withValue(__extractBundle(new BytesInput(bytes)));
		}
		catch (e:Dynamic)
		{
			return cast Future.withError("Not a zip file: " + Std.string(e));
		}
	}

	public static function loadFromFile(path:String):Future<AssetBundle>
	{
		return LimeBytes.loadFromFile(path).then(loadFromBytes);
	}

	@:noCompletion private static function __extractBundle(input:Input):AssetBundle
	{
		var entries = Reader.readZip(input);

		var bundle = new AssetBundle();

		for (entry in entries)
		{
			if (entry.compressed)
			{
				var bytes:LimeBytes = entry.data;
				bundle.data.set(entry.fileName, bytes.decompress(DEFLATE));

				// Let go of the compressed data once inflated, rather than keeping
				// the whole zip until every entry is
				entry.data = null;
			}
			else
			{
				bundle.data.set(entry.fileName, entry.data);
			}
			bundle.paths.push(entry.fileName);
		}

		return bundle;
	}
}
