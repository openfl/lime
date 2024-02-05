package flash.filesystem;

extern class FileStream extends flash.events.EventDispatcher implements flash.utils.IDataInput implements flash.utils.IDataOutput
{
	#if (haxe_ver < 4.3)
	var bytesAvailable(default, never):UInt;
	var endian:flash.utils.Endian;
	var objectEncoding:#if openfl openfl.net.ObjectEncoding #else UInt #end;
	#else
	@:flash.property var bytesAvailable(get, never):UInt;
	@:flash.property var endian(get, set):flash.utils.Endian;
	@:flash.property var objectEncoding(get, set):#if openfl openfl.net.ObjectEncoding #else UInt #end;
	#end

	var position:Float;
	var readAhead:Float;
	function new():Void;
	function close():Void;
	function open(file:File, fileMode:FileMode):Void;
	function openAsync(file:File, fileMode:FileMode):Void;
	function readBoolean():Bool;
	function readByte():Int;
	function readBytes(bytes:flash.utils.ByteArray, offset:UInt = 0, length:UInt = 0):Void;
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
	function truncate():Void;
	function writeBoolean(value:Bool):Void;
	function writeByte(value:Int):Void;
	function writeBytes(bytes:flash.utils.ByteArray, offset:UInt = 0, length:UInt = 0):Void;
	function writeDouble(value:Float):Void;
	function writeFloat(value:Float):Void;
	function writeInt(value:Int):Void;
	function writeMultiByte(value:String, charSet:String):Void;
	function writeObject(object:Dynamic):Void;
	function writeShort(value:Int):Void;
	function writeUTF(value:String):Void;
	function writeUTFBytes(value:String):Void;
	function writeUnsignedInt(value:UInt):Void;

	#if (haxe_ver >= 4.3)
	private function get_bytesAvailable():UInt;
	private function get_endian():flash.utils.Endian;
	private function get_objectEncoding():#if openfl openfl.net.ObjectEncoding #else UInt #end;
	private function set_endian(value:flash.utils.Endian):flash.utils.Endian;
	private function set_objectEncoding(value:#if openfl openfl.net.ObjectEncoding #else UInt #end):#if openfl openfl.net.ObjectEncoding #else UInt #end;
	#end
}
