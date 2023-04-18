package lime.utils;

import haxe.io.Bytes as HaxeBytes;
import haxe.io.BytesData;
import lime._internal.backend.native.NativeCFFI;
import lime._internal.format.Deflate;
import lime._internal.format.GZip;
import lime._internal.format.LZMA;
import lime._internal.format.Zlib;
import lime.app.Future;
import lime.net.HTTPRequest;

@:access(haxe.io.Bytes)
@:access(lime._internal.backend.native.NativeCFFI)
@:forward()
@:transitive
abstract Bytes(HaxeBytes) from HaxeBytes to HaxeBytes
{
	public function new(length:Int, bytesData:BytesData)
	{
		#if js
		this = new HaxeBytes(bytesData);
		#elseif hl
		this = new HaxeBytes(bytesData, length);
		#else
		this = new HaxeBytes(length, bytesData);
		#end
	}

	public static function alloc(length:Int):Bytes
	{
		#if hl
		if (length == 0) return new Bytes(0, null);
		#end
		return HaxeBytes.alloc(length);
	}

	public function compress(algorithm:CompressionAlgorithm):Bytes
	{
		switch (algorithm)
		{
			case DEFLATE:
				return Deflate.compress(this);

			case GZIP:
				return GZip.compress(this);

			case LZMA:
				return LZMA.compress(this);

			case ZLIB:
				return Zlib.compress(this);

			default:
				return null;
		}
	}

	public function decompress(algorithm:CompressionAlgorithm):Bytes
	{
		switch (algorithm)
		{
			case DEFLATE:
				return Deflate.decompress(this);

			case GZIP:
				return GZip.decompress(this);

			case LZMA:
				return LZMA.decompress(this);

			case ZLIB:
				return Zlib.decompress(this);

			default:
				return null;
		}
	}

	public static inline function fastGet(b:BytesData, pos:Int):Int
	{
		return HaxeBytes.fastGet(b, pos);
	}

	public static function fromBytes(bytes:haxe.io.Bytes):Bytes
	{
		if (bytes == null) return null;

		return new Bytes(bytes.length, bytes.getData());
	}

	public static function fromFile(path:String):Bytes
	{
		#if (sys && lime_cffi && !macro)
		#if !cs
		var bytes = Bytes.alloc(0);
		NativeCFFI.lime_bytes_read_file(path, bytes);
		if (bytes.length > 0) return bytes;
		#else
		var data:Dynamic = NativeCFFI.lime_bytes_read_file(path, null);
		if (data != null) return new Bytes(data.length, data.b);
		#end
		#end
		return null;
	}

	public static function loadFromBytes(bytes:haxe.io.Bytes):Future<Bytes>
	{
		return Future.withValue(fromBytes(bytes));
	}

	public static function loadFromFile(path:String):Future<Bytes>
	{
		var request = new HTTPRequest<Bytes>();
		return request.load(path);
	}

	public static function ofData(b:BytesData):Bytes
	{
		var bytes = HaxeBytes.ofData(b);
		return new Bytes(bytes.length, bytes.getData());
	}

	public static function ofString(s:String):Bytes
	{
		var bytes = HaxeBytes.ofString(s);
		return new Bytes(bytes.length, bytes.getData());
	}

	#if (lime_cffi && !macro)
	public static function __fromNativePointer(data:Dynamic, length:Int):Bytes
	{
		var bytes = Bytes.alloc(0);
		return NativeCFFI.lime_bytes_from_data_pointer(data, length, bytes);
	}
	#end
}
