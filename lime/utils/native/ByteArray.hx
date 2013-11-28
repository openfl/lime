package lime.utils.native;
// #if (cpp || neko)
#if (lime_native || lime_html5)

import lime.utils.Libs;

import haxe.io.Bytes;
import haxe.io.BytesData;
// import lime.errors.EOFError; // Ensure that the neko->haxe callbacks are initialized
import lime.utils.CompressionAlgorithm;
import lime.utils.IDataInput;

#if !lime_html5

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

class ByteArray extends Bytes #if !haxe3 , #end implements ArrayAccess<Int> #if !haxe3 , #end implements IDataInput #if !haxe3 , #end implements IMemoryRange 
{

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

      #if !lime_html5
         var init = Libs.load("lime", "lime_byte_array_init", 4);
         init(factory, slen, resize, bytes);
      #end //lime_html5
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

#if !lime_html5
   //todo- sven

   public function compress(algorithm:CompressionAlgorithm = null) 
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
   }

#end //!lime_html5

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

#if !lime_html5
   
   public function inflate() {

      uncompress(CompressionAlgorithm.DEFLATE);

   }

#end //!lime_html5
   
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
      #if !lime_html5

         if (position + 8 > length)
            ThrowEOFi();

         #if neko
         var bytes = new Bytes(8, untyped __dollar__ssub(b, position, 8));
         #elseif cpp
         var bytes = new Bytes(8, b.slice(position, position + 8));
         #end

         position += 8;
         return _double_of_bytes(bytes.b, bigEndian);

      #end //!lime_html5

      return 0.0;
   }

   #if !no_lime_io
   static public function readFile(inString:String):ByteArray 
   {
      return lime_byte_array_read_file(inString);
   }
   #end

   public function readFloat():Float 
   {  
      #if !lime_html5

         if (position + 4 > length)
            ThrowEOFi();

         #if neko
         var bytes = new Bytes(4, untyped __dollar__ssub(b, position, 4));
         #elseif cpp
         var bytes = new Bytes(4, b.slice(position, position + 4));
         #end

         position += 4;
         return _float_of_bytes(bytes.b, bigEndian);

      #end //!lime_html5

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

#if !lime_html5
//todo sven

   public function uncompress(algorithm:CompressionAlgorithm = null):Void 
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
   }

#end //!lime_html5

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
      #if !lime_html5

         #if neko
         var bytes = new Bytes(8, _double_bytes(x, bigEndian));
         #elseif cpp
         var bytes = Bytes.ofData(_double_bytes(x, bigEndian));
         #end

         writeBytes(bytes);

      #end //!lime_html5
   }

   #if !no_lime_io
   public function writeFile(inString:String):Void 
   {
      lime_byte_array_overwrite_file(inString, this);
   }
   #end

   public function writeFloat(x:Float) 
   {
      #if !lime_html5

         #if neko
         var bytes = new Bytes(4, _float_bytes(x, bigEndian));
         #elseif cpp
         var bytes = Bytes.ofData(_float_bytes(x, bigEndian));
         #end

         writeBytes(bytes);

      #end //!lime_html5
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
   private function get_endian():String { return bigEndian ? Endian.BIG_ENDIAN : Endian.LITTLE_ENDIAN; }
   private function set_endian(s:String):String { bigEndian =(s == Endian.BIG_ENDIAN); return s; }

   // Native Methods
   /** @private */ private static var _double_bytes =    Libs.load("std", "double_bytes", 2);
   /** @private */ private static var _double_of_bytes = Libs.load("std", "double_of_bytes", 2);
   /** @private */ private static var _float_bytes =     Libs.load("std", "float_bytes", 2);
   /** @private */ private static var _float_of_bytes =  Libs.load("std", "float_of_bytes", 2);
   #if !no_lime_io
   private static var lime_byte_array_overwrite_file =    Libs.load("lime","lime_byte_array_overwrite_file", 2);
   private static var lime_byte_array_read_file =         Libs.load("lime", "lime_byte_array_read_file", 1);
   #end
   private static var lime_lzma_encode = Libs.load("lime", "lime_lzma_encode", 1);
   private static var lime_lzma_decode = Libs.load("lime", "lime_lzma_decode", 1);
}

#else
typedef ByteArray = Dynamic;//todo ; flash.utils.ByteArray;
#end
