package lime._internal.format;

#if js
import haxe.io.Bytes;

/**
	Inflates with pako, failing where zlib does. pako's own inflate() gives back what it has read of a stream
	that stops before its end (so before its Adler-32 or CRC-32), reads zlib and gzip streams alike, and stops
	after a gzip file's first member.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class PakoInflate
{
	/** zlib's windowBits for each format: negative for raw deflate, plus 16 for gzip **/
	public static inline var DEFLATE = -15;
	public static inline var GZIP = 31;
	public static inline var ZLIB = 15;

	/**
		The inflated data, or null when `bytes` is not a whole stream of the format `windowBits` names. As with
		the native decoder, a gzip file is a series of members (RFC 1952), and data after its last member that
		is not another one is left alone.
	**/
	public static function inflate(bytes:Bytes, windowBits:Int):Bytes
	{
		#if commonjs
		var library:Dynamic = untyped #if haxe4 js.Syntax.code #else __js__ #end ("require (\"pako\")");
		#else
		var library:Dynamic = untyped #if haxe4 js.Syntax.code #else __js__ #end ("pako");
		#end

		var input:Dynamic = @:privateAccess bytes.b;
		var results:Array<Dynamic> = [];
		var length = 0;

		do
		{
			var inflator:Dynamic = untyped #if haxe4 js.Syntax.code #else __js__ #end ("new {0}.Inflate({1})", library, {windowBits: windowBits});

			// Without Z_FINISH, the inflator ends only at the end of the stream, or on an error
			inflator.push(input, false);

			if (!inflator.ended || inflator.err != 0)
			{
				// Bytes after the last member that never start another, such as the zeros some tools pad with
				if (windowBits == GZIP && results.length > 0 && inflator.ended && inflator.strm.total_out == 0) break;
				return null;
			}

			results.push(inflator.result);
			length += inflator.result.length;

			var remaining:Int = inflator.strm.avail_in;
			input = input.subarray(input.length - remaining);
		}
		while (windowBits == GZIP && input.length > 0);

		// Each result can be a view of a larger buffer, so they are copied out
		var output = Bytes.alloc(length);
		var position = 0;

		for (result in results)
		{
			(@:privateAccess output.b).set(result, position);
			position += result.length;
		}

		return output;
	}
}
#end
