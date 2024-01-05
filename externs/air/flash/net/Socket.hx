package flash.net;

extern class Socket extends flash.events.EventDispatcher implements flash.utils.IDataOutput implements flash.utils.IDataInput
{
	#if (haxe_ver < 4.3)
	var bytesAvailable(default, never):UInt;
	@:require(flash11) var bytesPending(default, never):UInt;
	var connected(default, never):Bool;
	var endian:flash.utils.Endian;
	var objectEncoding:UInt;
	@:require(flash10) var timeout:UInt;
	#if air
	var localAddress(default, never):String;
	var localPort(default, never):Int;
	var remoteAddress(default, never):String;
	var remotePort(default, never):Int;
	#end
	#else
	@:flash.property var bytesAvailable(get, never):UInt;
	@:flash.property @:require(flash11) var bytesPending(get, never):UInt;
	@:flash.property var connected(get, never):Bool;
	@:flash.property var endian(get, set):flash.utils.Endian;
	@:flash.property var objectEncoding(get, set):UInt;
	@:flash.property @:require(flash10) var timeout(get, set):UInt;
	#if air
	@:flash.property var localAddress(get, never):String;
	@:flash.property var localPort(get, never):Int;
	@:flash.property var remoteAddress(get, never):String;
	@:flash.property var remotePort(get, never):Int;
	#end
	#end
	function new(?host:String, port:Int = 0):Void;
	function close():Void;
	function connect(host:String, port:Int):Void;
	function flush():Void;
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
	private function get_bytesPending():UInt;
	private function get_connected():Bool;
	private function get_endian():flash.utils.Endian;
	private function get_objectEncoding():UInt;
	private function get_timeout():UInt;
	#if air
	private function get_localAddress():String;
	private function get_localPort():Int;
	private function get_remoteAddress():String;
	private function get_remotePort():Int;
	#end
	private function set_endian(value:flash.utils.Endian):flash.utils.Endian;
	private function set_objectEncoding(value:UInt):UInt;
	private function set_timeout(value:UInt):UInt;
	#end
}
