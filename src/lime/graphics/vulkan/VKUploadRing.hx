package lime.graphics.vulkan;

import haxe.Int64;
import haxe.io.Bytes;

/**
	A persistently mapped host-visible ring buffer for staging dynamic uploads.
**/
class VKUploadRing
{
	public var buffer(default, null):VKBuffer;
	public var byteCapacity(default, null):Int;
	public var device(default, null):VKDevice;
	public var frameIndex(default, null):Int = 0;
	public var head(default, null):Int = 0;

	public function new(device:VKDevice, byteCapacity:Int, usage:Int = VK.BUFFER_USAGE_TRANSFER_SRC_BIT,
			properties:Int = VK.MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK.MEMORY_PROPERTY_HOST_COHERENT_BIT)
	{
		this.device = device;
		this.byteCapacity = byteCapacity;

		if (device != null && byteCapacity > 0)
		{
			buffer = device.createBufferWithMemory(Int64.ofInt(byteCapacity), usage | VK.BUFFER_USAGE_TRANSFER_SRC_BIT, properties);
			if (buffer != null && !buffer.map(Int64.ofInt(0), Int64.ofInt(byteCapacity)))
			{
				buffer.dispose(true);
				buffer = null;
			}
		}
	}

	public function beginFrame(frameIndex:Int):Void
	{
		this.frameIndex = frameIndex;
		head = 0;
	}

	public function reserve(byteCount:Int, alignment:Int):VKUploadSlice
	{
		if (!isValid() || byteCount <= 0)
		{
			return null;
		}
		if (alignment <= 0)
		{
			alignment = 1;
		}

		var aligned = __align(head, alignment);
		if (aligned + byteCount > byteCapacity)
		{
			return null;
		}

		head = aligned + byteCount;
		return new VKUploadSlice(buffer, Int64.ofInt(aligned), byteCount, frameIndex);
	}

	public function writeBytes(slice:VKUploadSlice, bytes:Bytes, srcOffset:Int = 0, length:Int = -1):Bool
	{
		if (slice == null || slice.buffer != buffer || bytes == null)
		{
			return false;
		}
		if (length < 0)
		{
			length = bytes.length - srcOffset;
		}
		if (length < 0 || length > slice.size)
		{
			return false;
		}
		return buffer.writeBytes(bytes, srcOffset, length, slice.offset);
	}

	public function flush():Bool
	{
		return isValid() ? buffer.flush(Int64.ofInt(0), Int64.ofInt(0)) : false;
	}

	public function invalidate():Bool
	{
		return isValid() ? buffer.invalidate(Int64.ofInt(0), Int64.ofInt(0)) : false;
	}

	public function dispose():Void
	{
		if (buffer != null)
		{
			buffer.dispose(true);
			buffer = null;
		}
	}

	public inline function isValid():Bool
	{
		return buffer != null && buffer.isValid();
	}

	private inline function __align(value:Int, alignment:Int):Int
	{
		return Std.int((value + alignment - 1) / alignment) * alignment;
	}
}
