package lime.utils;
#if flash
typedef ByteArray = flash.utils.ByteArray;
#elseif js


import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesData;
import haxe.io.Input;
//import openfl.errors.IOError;
import lime.utils.ArrayBuffer;

#if js
import js.html.DataView;
import js.html.Uint8Array;
#end

#if format
import format.tools.Inflate;
#end


@:autoBuild(openfl.Assets.embedFile())
class ByteArray implements ArrayAccess<Int> {
   
   
   public var bytesAvailable (get, null):Int;
   public var endian (get, set):String;
   public var length (default, set):Int = 0;
   public var objectEncoding:Int;
   public var position:Int = 0;
   
   private var allocated:Int = 0;
   public var byteView:Uint8Array;
   private var data:DataView;
   private var littleEndian:Bool = false; // NOTE: default ByteArray endian is BIG_ENDIAN
   
   
   public function new ():Void {
      
      ___resizeBuffer (allocated);
      //this.byteView = untyped __new__("Uint8Array", allocated);
      //this.data = untyped __new__("DataView", this.byteView.buffer);
      
   }
   
   
   public function clear () {
      
      length = 0;
      position = 0;
      
   }
   
   
   @:extern private inline function ensureWrite (lengthToEnsure:Int):Void {
      
      if (this.length < lengthToEnsure) this.length = lengthToEnsure;
   }
   
   
   static public function fromBytes (inBytes:Bytes) {
      
      var result = new ByteArray ();
      result.__fromBytes (inBytes);
      return result;
      
   }
   
   
   public inline function readBoolean ():Bool {
      
      return (this.readByte () != 0);
      
   }
   
   
   public inline function readByte ():Int {
      
      var data:Dynamic = data;
      return data.getInt8 (this.position++);
      
   }
   
   
   public function readBytes (bytes:ByteArray, ?offset:Int = 0, ?length:Int = 0):Void {
      
      if (offset < 0 || length < 0) {
         
         //throw new IOError ("Read error - Out of bounds");
         throw ("Read error - Out of bounds");
         
      }
      
      if (length == 0) length = this.bytesAvailable;
      
      bytes.ensureWrite (offset + length);
      
      bytes.byteView.set (byteView.subarray(this.position, this.position + length), offset);
      bytes.position = offset;
      
      this.position += length;
      if (bytes.position + length > bytes.length) bytes.length = bytes.position + length;
      
   }
   
   
   public function readDouble ():Float {
      
      var double = data.getFloat64 (this.position, littleEndian);
      this.position += 8;
      return double;
      
   }
   
   
   public function readFloat ():Float {
      
      var float = data.getFloat32 (this.position, littleEndian);
      this.position += 4;
      return float;
      
   }
   
   
   private function readFullBytes (bytes:Bytes, pos:Int, len:Int):Void {
      
      // NOTE: It is used somewhere?
      
      ensureWrite (len);
      
      for (i in pos...(pos + len)) {
         
         var data:Dynamic = data;
         data.setInt8 (this.position++, bytes.get(i));
         
      }
      
   }
   
   
   public function readInt ():Int {
      
      var int = data.getInt32 (this.position, littleEndian);
      this.position += 4;
      return int;
      
   }
   
   
   public inline function readMultiByte (length:Int, charSet:String):String {
      
      return readUTFBytes (length);
      
   }
   
   
   public function readShort ():Int {
      
      var short = data.getInt16 (this.position, littleEndian);
      this.position += 2;
      return short;
      
   }
   
   
   public inline function readUnsignedByte ():Int {
      
      var data:Dynamic = data;
      return data.getUint8 (this.position++);
      
   }
   
   
   public function readUnsignedInt ():Int {
      
      var uInt = data.getUint32 (this.position, littleEndian);
      this.position += 4;
      return uInt;
      
   }
   
   
   public function readUnsignedShort ():Int {
      
      var uShort = data.getUint16 (this.position, littleEndian);
      this.position += 2;
      return uShort;
      
   }
   
   
   public function readUTF ():String {
      
      var bytesCount = readUnsignedShort ();
      return readUTFBytes (bytesCount);
      
   }
   
   
   public function readUTFBytes (len:Int):String {
      
      var value = "";
      var max = this.position + len;
      
      // utf8-encode
      while (this.position < max) {
         
         var data:Dynamic = data;
         var c = data.getUint8 (this.position++);
         
         if (c < 0x80) {
            
            if (c == 0) break;
            value += String.fromCharCode (c);
            
         } else if (c < 0xE0) {
            
            value += String.fromCharCode (((c & 0x3F) << 6) | (data.getUint8 (this.position++) & 0x7F));
            
         } else if (c < 0xF0) {
            
            var c2 = data.getUint8 (this.position++);
            value += String.fromCharCode (((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | (data.getUint8 (this.position++) & 0x7F));
            
         } else {
            
            var c2 = data.getUint8 (this.position++);
            var c3 = data.getUint8 (this.position++);
            value += String.fromCharCode (((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 << 6) & 0x7F) | (data.getUint8 (this.position++) & 0x7F));
            
         }
         
      }
      
      return value;
      
   }
   
   
   public function toString ():String {
      
      var cachePosition = position;
      position = 0;
      var value = readUTFBytes (length);
      position = cachePosition;
      return value;
      
   }
   
   
   #if format
   public function uncompress ():Void {
      
      var bytes = Bytes.ofData (cast byteView);
      var buf = Inflate.run (bytes).getData();
      this.byteView = untyped __new__("Uint8Array", buf);
      this.data = untyped __new__("DataView", byteView.buffer);
      this.length = this.allocated = byteView.buffer.byteLength;
      
   }
   #end
   
   
   public inline function writeBoolean (value:Bool):Void {
      
      this.writeByte (value ? 1 : 0);
      
   }
   
   
   public function writeByte (value:Int):Void {
      
      ensureWrite (this.position + 1);
      var data:Dynamic = data;
      data.setInt8 (this.position, value);
      this.position += 1;
      
   }
   
   
   public function writeBytes (bytes:ByteArray, ?offset:UInt = 0, ?length:UInt = 0):Void {
      
      if (offset < 0 || length < 0) throw ("Write error - Out of bounds");
      //if (offset < 0 || length < 0) throw new IOError ("Write error - Out of bounds");

      if( length == 0 ) length = bytes.length;
      
      ensureWrite (this.position + length);
      byteView.set (bytes.byteView.subarray (offset, offset + length), this.position);
      this.position += length;
      
   }
   
   
   public function writeDouble (x:Float):Void {
      
      ensureWrite (this.position + 8);
      data.setFloat64 (this.position, x, littleEndian);
      this.position += 8;
      
   }
   
   
   public function writeFloat (x:Float):Void {
      
      ensureWrite (this.position + 4);
      data.setFloat32 (this.position, x, littleEndian);
      this.position += 4;
      
   }
   
   
   public function writeInt (value:Int):Void {
      
      ensureWrite (this.position + 4);
      data.setInt32 (this.position, value, littleEndian);
      this.position += 4;
      
   }
   
   
   public function writeShort (value:Int):Void {
      
      ensureWrite (this.position + 2);
      data.setInt16 (this.position, value, littleEndian);
      this.position += 2;
      
   }
   
   
   public function writeUnsignedInt (value:Int):Void {
      
      ensureWrite (this.position + 4);
      data.setUint32 (this.position, value, littleEndian);
      this.position += 4;
      
   }
   
   
   public function writeUnsignedShort (value:Int):Void {
      
      ensureWrite (this.position + 2);
      data.setUint16 (this.position, value, littleEndian);
      this.position += 2;
      
   }
   
   
   public function writeUTF (value:String):Void {
      
      writeUnsignedShort (_getUTFBytesCount(value));
      writeUTFBytes (value);
      
   }
   
   
   public function writeUTFBytes (value:String):Void {
      
      // utf8-decode
      for (i in 0...value.length) {
         
         var c = StringTools.fastCodeAt (value, i);
         
         if (c <= 0x7F) {
            
            writeByte (c);
            
         } else if (c <= 0x7FF) {
            
            writeByte (0xC0 | (c >> 6));
            writeByte (0x80 | (c & 63));
            
         } else if (c <= 0xFFFF) {
            
            writeByte(0xE0 | (c >> 12));
            writeByte(0x80 | ((c >> 6) & 63));
            writeByte(0x80 | (c & 63));
            
         } else {
            
            writeByte(0xF0 | (c >> 18));
            writeByte(0x80 | ((c >> 12) & 63));
            writeByte(0x80 | ((c >> 6) & 63));
            writeByte(0x80 | (c & 63));
            
         }
         
      }
      
   }
   
   
   private inline function __fromBytes (inBytes:Bytes):Void {
      
      byteView = untyped __new__("Uint8Array", inBytes.getData ());
      length = byteView.length;
      allocated = length;
      
   }
   
   
      public function __get (pos:Int):Int {
         
         return data.getInt8 (pos);
         
      }
   
   
   private function _getUTFBytesCount (value:String):Int {
      
      var count:Int = 0;
      // utf8-decode
      
      for (i in 0...value.length) {
         
         var c = StringTools.fastCodeAt (value, i);
         
         if (c <= 0x7F) {
            
            count += 1;
            
         } else if (c <= 0x7FF) {
            
            count += 2;
            
         } else if (c <= 0xFFFF) {
            
            count += 3;
            
         } else {
            
            count += 4;
            
         }
         
      }
      
      return count;
      
   }
   
   
   private function ___resizeBuffer (len:Int):Void {
      
      var oldByteView:Uint8Array = this.byteView;
      var newByteView:Uint8Array = untyped __new__("Uint8Array", len);
      
      if (oldByteView != null)
      {
         if (oldByteView.length <= len) newByteView.set (oldByteView);
         else newByteView.set (oldByteView.subarray (0, len));
      }

      this.byteView = newByteView;
      this.data = untyped __new__("DataView", newByteView.buffer);
      
   }
   
   
   public inline function __getBuffer () {
      
      return data.buffer;
      
   }
   
   
   public function __set (pos:Int, v:Int):Void {
      
      data.setUint8 (pos, v);
      
   }
   
   
   public static function __ofBuffer (buffer:ArrayBuffer):ByteArray {
      
      var bytes = new ByteArray ();
      bytes.length = bytes.allocated = buffer.byteLength;
      bytes.data = untyped __new__("DataView", buffer);
      bytes.byteView = untyped __new__("Uint8Array", buffer);
      return bytes;
      
   }
   
   
   
   
   // Getters & Setters
   
   
   
   
   inline private function get_bytesAvailable ():Int { return length - position; }
   
   
   inline function get_endian ():String {
      
     // return littleEndian ? Endian.LITTLE_ENDIAN : Endian.BIG_ENDIAN;
      return littleEndian ? "littleEndian" : "bigEndian";
      
   }
   
   
   inline function set_endian (endian:String):String {
      
     // littleEndian = (endian == Endian.LITTLE_ENDIAN);
      littleEndian = (endian == "littleEndian");
      return endian;
      
   }
   
   
   private inline function set_length (value:Int):Int {

      if (allocated < value)
         ___resizeBuffer (allocated = Std.int (Math.max (value, allocated * 2)));
      else if (allocated > value)
         ___resizeBuffer (allocated = value);
      length = value;
      return value;
      
   }
   
   
}


#else


import lime.utils.IMemoryRange;
import haxe.io.Bytes;
import haxe.io.BytesData;
// import lime.errors.EOFError; // Ensure that the neko->haxe callbacks are initialized
//import lime.utils.compat.CompressionAlgorithm;
import lime.utils.IDataInput;
import lime.system.System;

#if !js

   #if neko
   import neko.Lib;
   import neko.zip.Compress;
   import neko.zip.Uncompress;
   import neko.zip.Flush;
   #else
   import cpp.Lib;
   import cpp.zip.Compress;
   import cpp.zip.Uncompress;
   import cpp.zip.Flush;
   #end

#end

class ByteArray extends Bytes implements ArrayAccess<Int> implements IDataInput implements IMemoryRange {

   public var bigEndian:Bool;
   public var bytesAvailable(get_bytesAvailable, null):Int;
   public var endian(get_endian, set_endian):String;
   public var position:Int;
   public var byteLength(get_byteLength,null):Int;

   #if neko
   /** @private */ private var alloced:Int;
   #end

   public function new(inSize = 0) 
   {
      bigEndian = true;
      position = 0;

      if (inSize >= 0) 
      {
         #if neko
         alloced = inSize < 16 ? 16 : inSize;
         var bytes = untyped __dollar__smake(alloced);
         super(inSize, bytes);
         #else
         var data = new BytesData();
         if (inSize > 0)
            untyped data[inSize - 1] = 0;
         super(inSize, data);
         #end
      }
   }

   @:keep
   inline public function __get(pos:Int):Int 
   {
      // Neko/cpp pseudo array accessors...
      // No bounds checking is done in the cpp case
      #if cpp
      return untyped b[pos];
      #else
      return get(pos);
      #end
   }

   #if !no_lime_io
   /** @private */ static function __init__() {
      var factory = function(inLen:Int) { return new ByteArray(inLen); };
      var resize = function(inArray:ByteArray, inLen:Int) 
      {
         if (inLen > 0)
            inArray.ensureElem(inLen - 1, true);
         inArray.length = inLen;

      };

      var bytes = function(inArray:ByteArray) { return inArray==null ? null :  inArray.b; }
      var slen = function(inArray:ByteArray) { return inArray == null ? 0 : inArray.length; }

      #if !js
         var init = System.load("lime", "lime_byte_array_init", 4);
         init(factory, slen, resize, bytes);
      #end
   }
   #end

   @:keep
   inline public function __set(pos:Int, v:Int):Void 
   {
      // No bounds checking is done in the cpp case
      #if cpp
      untyped b[pos] = v;
      #else
      set(pos, v);
      #end
   }

   public function asString():String 
   {
      return readUTFBytes(length);
   }

   public function checkData(inLength:Int) 
   {
      if (inLength + position > length)
         ThrowEOFi();
   }

   public function clear() 
   {
      position = 0;
      length = 0;
   }

#if !js
   //todo- sven

   /*public function compress(algorithm:CompressionAlgorithm = null) 
   {
      #if neko
      var src = alloced == length ? this : sub(0, length);
      #else
      var src = this;
      #end

      var result:Bytes;

      if (algorithm == CompressionAlgorithm.LZMA) 
      {
         result = Bytes.ofData(lime_lzma_encode( cast src.getData()) );

      } else 
      {
         var windowBits = switch(algorithm) 
         {
            case DEFLATE: -15;
            case GZIP: 31;
            default: 15;
         }

         #if enable_deflate
         result = Compress.run(src, 8, windowBits);
         #else
         result = Compress.run(src, 8);
         #end
      }

      b = result.b;
      length = result.length;
      position = length;
      #if neko
      alloced = length;
      #end
   }

   public function deflate() 
   {
      compress(CompressionAlgorithm.DEFLATE);
   }*/

#end //!js

   /** @private */ private function ensureElem(inSize:Int, inUpdateLenght:Bool) {
      var len = inSize + 1;

      #if neko
      if (alloced < len) 
      {
         alloced =((len+1) * 3) >> 1;
         var new_b = untyped __dollar__smake(alloced);
         untyped __dollar__sblit(new_b, 0, b, 0, length);
         b = new_b;
      }
      #else
      if (b.length < len)
         untyped b.__SetSize(len);
      #end

      if (inUpdateLenght && length < len)
         length = len;
   }

   static public function fromBytes(inBytes:Bytes) 
   {
      var result = new ByteArray( -1);
     result.limeFromBytes(inBytes);
      return result;
   }

   public function getLength():Int { return length; }

   // IMemoryRange
   public function getByteBuffer():ByteArray { return this; }
   public function getStart():Int { return 0; }

#if !js
   
   public function inflate() {

      //uncompress(CompressionAlgorithm.DEFLATE);

   }

#end //!js
   
   private inline function limeFromBytes(inBytes:Bytes):Void
   {
      b = inBytes.b;
      length = inBytes.length;
      
      #if neko
      alloced = length;
      #end
   }

   public inline function readBoolean():Bool 
   {
      return(position < length) ? __get(position++) != 0 : ThrowEOFi() != 0;
   }

   public inline function readByte():Int 
   {
      var val:Int = readUnsignedByte();
      return((val & 0x80) != 0) ?(val - 0x100) : val;
   }

   public function readBytes(outData:ByteArray, inOffset:Int = 0, inLen:Int = 0):Void 
   {
      if (inLen == 0)
         inLen = length - position;

      if (position + inLen > length)
         ThrowEOFi();

      if (outData.length < inOffset + inLen)
         outData.ensureElem(inOffset + inLen - 1, true);

      #if neko
      outData.blit(inOffset, this, position, inLen);
      #else
      var b1 = b;
      var b2 = outData.b;
      var p = position;
      for(i in 0...inLen)
         b2[inOffset + i] = b1[p + i];
      #end

      position += inLen;
   }

   public function readDouble():Float 
   {
      #if !js

         if (position + 8 > length)
            ThrowEOFi();

         #if neko
         var bytes = new Bytes(8, untyped __dollar__ssub(b, position, 8));
         #elseif cpp
         var bytes = new Bytes(8, b.slice(position, position + 8));
         #end

         position += 8;
         return _double_of_bytes(bytes.b, bigEndian);

      #end //!js

      return 0.0;
   }

   #if !no_lime_io
   static public function readFile(inString:String):ByteArray {
      return lime_byte_array_read_file(inString);
   }
   #end

   public function readFloat():Float
   {
      #if !js

         if (position + 4 > length)
            ThrowEOFi();

         #if neko
         var bytes = new Bytes(4, untyped __dollar__ssub(b, position, 4));
         #elseif cpp
         var bytes = new Bytes(4, b.slice(position, position + 4));
         #end

         position += 4;
         return _float_of_bytes(bytes.b, bigEndian);

      #end //!js

      return 0.0;
   }

   public function readInt():Int 
   {
      var ch1 = readUnsignedByte();
      var ch2 = readUnsignedByte();
      var ch3 = readUnsignedByte();
      var ch4 = readUnsignedByte();

      return bigEndian ?(ch1 << 24) |(ch2 << 16) |(ch3 << 8) | ch4 :(ch4 << 24) |(ch3 << 16) |(ch2 << 8) | ch1;
   }

   public inline function readMultiByte(inLen:Int, charSet:String):String 
   {
      // TODO - use code page
      return readUTFBytes(inLen);
   }

   public function readShort():Int 
   {
      var ch1 = readUnsignedByte();
      var ch2 = readUnsignedByte();

      var val = bigEndian ?((ch1 << 8) | ch2) :((ch2 << 8) | ch1);

      return((val & 0x8000) != 0) ?(val - 0x10000) : val;
   }

   inline public function readUnsignedByte():Int 
   {
      return(position < length) ? __get(position++) : ThrowEOFi();
   }

   public function readUnsignedInt():Int 
   {
      var ch1 = readUnsignedByte();
      var ch2 = readUnsignedByte();
      var ch3 = readUnsignedByte();
      var ch4 = readUnsignedByte();

      return bigEndian ?(ch1 << 24) |(ch2 << 16) |(ch3 << 8) | ch4 :(ch4 << 24) |(ch3 << 16) |(ch2 << 8) | ch1;
   }

   public function readUnsignedShort():Int 
   {
      var ch1 = readUnsignedByte();
      var ch2 = readUnsignedByte();

      return bigEndian ?(ch1 << 8) | ch2 :(ch2 << 8) + ch1;
   }

   public function readUTF():String 
   {
      var len = readUnsignedShort();
      return readUTFBytes(len);
   }

   public function readUTFBytes(inLen:Int):String 
   {
      if (position + inLen > length)
         ThrowEOFi();

      var p = position;
      position += inLen;

      #if lime_native

         #if neko
         return new String(untyped __dollar__ssub(b, p, inLen));
         #elseif cpp
         var result:String="";
         untyped __global__.__hxcpp_string_of_bytes(b, result, p, inLen);
         return result;
         #end

      #else 
         return "-";
      #end

   }

   public function setLength(inLength:Int):Void 
   {
      if (inLength > 0)
         ensureElem(inLength - 1, false);
      length = inLength;
   }

   // ArrayBuffer interface
   public function slice(inBegin:Int, ?inEnd:Int):ByteArray 
   {
      var begin = inBegin;

      if (begin < 0) 
      {
         begin += length;
         if (begin < 0)
            begin = 0;
      }

      var end:Int = inEnd == null ? length : inEnd;

      if (end < 0) 
      {
         end += length;

         if (end < 0)
            end = 0;
      }

      if (begin >= end)
         return new ByteArray();

      var result = new ByteArray(end - begin);

      var opos = position;
      result.blit(0, this, begin, end - begin);

      return result;
   }

   /** @private */ private function ThrowEOFi():Int {
      throw "new EOFError();"; //todo sven
      return 0;
   }

#if !js
//todo sven

   /*public function uncompress(algorithm:CompressionAlgorithm = null):Void 
   {
      if (algorithm == null) algorithm = CompressionAlgorithm.GZIP;

      #if neko
      var src = alloced == length ? this : sub(0, length);
      #else
      var src = this;
      #end

      var result:Bytes;

      if (algorithm == CompressionAlgorithm.LZMA) 
      {
         result = Bytes.ofData(lime_lzma_decode(src.getData()));

      } else 
      {
         var windowBits = switch(algorithm) 
         {
            case DEFLATE: -15;
            case GZIP: 31;
            default: 15;
         }

         #if enable_deflate
         result = Uncompress.run(src, null, windowBits);
         #else
         result = Uncompress.run(src, null);
         #end
      }

      b = result.b;
      length = result.length;
      position = 0;
      #if neko
      alloced = length;
      #end
   }*/

#end //!js

   /** @private */ inline function write_uncheck(inByte:Int) {
      #if cpp
      untyped b.__unsafe_set(position++, inByte);
      #else
      untyped __dollar__sset(b, position++, inByte & 0xff);
      #end
   }

   public function writeBoolean(value:Bool) 
   {
      writeByte(value ? 1 : 0);
   }

   inline public function writeByte(value:Int) 
   {
      ensureElem(position, true);

      #if cpp
      b[position++] = untyped value;
      #else
      untyped __dollar__sset(b, position++, value & 0xff);
      #end
   }

   public function writeBytes(bytes:Bytes, inOffset:Int = 0, inLength:Int = 0) 
   {
      if (inLength == 0) inLength = bytes.length - inOffset;
      ensureElem(position + inLength - 1, true);
      var opos = position;
      position += inLength;
      blit(opos, bytes, inOffset, inLength);
   }

   public function writeDouble(x:Float) 
   {  
      #if !js

         #if neko
         var bytes = new Bytes(8, _double_bytes(x, bigEndian));
         #elseif cpp
         var bytes = Bytes.ofData(_double_bytes(x, bigEndian));
         #end

         writeBytes(bytes);

      #end //!js
   }

   #if !no_lime_io
   public function writeFile(inString:String):Void 
   {
      lime_byte_array_overwrite_file(inString, this);
   }
   #end

   public function writeFloat(x:Float) 
   {
      #if !js

         #if neko
         var bytes = new Bytes(4, _float_bytes(x, bigEndian));
         #elseif cpp
         var bytes = Bytes.ofData(_float_bytes(x, bigEndian));
         #end

         writeBytes(bytes);

      #end //!js
   }

   public function writeInt(value:Int) 
   {
      ensureElem(position + 3, true);

      if (bigEndian) 
      {
         write_uncheck(value >> 24);
         write_uncheck(value >> 16);
         write_uncheck(value >> 8);
         write_uncheck(value);

      } else 
      {
         write_uncheck(value);
         write_uncheck(value >> 8);
         write_uncheck(value >> 16);
         write_uncheck(value >> 24);
      }
   }

   // public function writeMultiByte(value:String, charSet:String)
   // public function writeObject(object:*)
   public function writeShort(value:Int) 
   {
      ensureElem(position + 1, true);

      if (bigEndian) 
      {
         write_uncheck(value >> 8);
         write_uncheck(value);

      } else 
      {
         write_uncheck(value);
         write_uncheck(value >> 8);
      }
   }

   public function writeUnsignedInt(value:Int) 
   {
      writeInt(value);
   }

   public function writeUTF(s:String) 
   {
      #if neko
      var bytes = new Bytes(s.length, untyped s.__s);
      #else
      var bytes = Bytes.ofString(s);
      #end

      writeShort(bytes.length);
      writeBytes(bytes);
   }

   public function writeUTFBytes(s:String) 
   {
      #if neko
      var bytes = new Bytes(s.length, untyped s.__s);
      #else
      var bytes = Bytes.ofString(s);
      #end

      writeBytes(bytes);
   }

   // Getters & Setters
   private function get_bytesAvailable():Int { return length - position; }
   private function get_byteLength():Int { return length; }
   private function get_endian():String { return ""; /*return bigEndian ? lime.utils.compat.Endian.BIG_ENDIAN : lime.utils.compat.Endian.LITTLE_ENDIAN;*/ }
   private function set_endian(s:String):String { return ""; /*bigEndian =(s == lime.utils.compat.Endian.BIG_ENDIAN); return s;*/ }

   // Native Methods
   /** @private */ private static var _double_bytes =    System.load("std", "double_bytes", 2);
   /** @private */ private static var _double_of_bytes = System.load("std", "double_of_bytes", 2);
   /** @private */ private static var _float_bytes =     System.load("std", "float_bytes", 2);
   /** @private */ private static var _float_of_bytes =  System.load("std", "float_of_bytes", 2);
   #if !no_lime_io
   private static var lime_byte_array_overwrite_file =    System.load("lime","lime_byte_array_overwrite_file", 2);
   private static var lime_byte_array_read_file =         System.load("lime", "lime_byte_array_read_file", 1);
   #end
   private static var lime_lzma_encode = System.load("lime", "lime_lzma_encode", 1);
   private static var lime_lzma_decode = System.load("lime", "lime_lzma_decode", 1);
}


#end