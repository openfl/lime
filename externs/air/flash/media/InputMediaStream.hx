package flash.media;

extern class InputMediaStream extends flash.events.EventDispatcher implements flash.utils.IDataInput
{
	var bytesAvailable(default, never):UInt;
	var endian:flash.utils.Endian;
	var objectEncoding:#if openfl openfl.net.ObjectEncoding #else UInt #end;
	// function new() : Void;
	function close():Dynamic;
	function open():Dynamic;
	function readBoolean():Bool;
	function readByte():Int;
	function readBytes(bytes:flash.utils.ByteArray, ?offset:UInt, ?length:UInt):Void;
	function readDouble():Float;
	function readFloat():Float;
	function readInt():Int;
	function readMultiByte(length:UInt, charSet:String):String;
	function readObject():Dynamic;
	function readShort():Int;
	function readUTF():String;
	function readUTFBytes(length:UInt):String;
	function readUnsignedByte():UInt;
	function readUnsignedInt():UInt;
	function readUnsignedShort():UInt;
}
