package lime.graphics.vulkan;

import haxe.Int64;
import haxe.io.Bytes;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	Device memory allocated from a `VKDevice`.
**/
class VKDeviceMemory
{
	public var device(default, null):VKDevice;
	public var handle(default, null):Int64;
	public var memoryTypeIndex(default, null):Int;
	public var mapped(default, null):Bool = false;
	public var mappedOffset(default, null):Int64 = Int64.ofInt(0);
	public var mappedSize(default, null):Int64 = Int64.ofInt(0);
	public var properties(default, null):Int;
	public var size(default, null):Int64;

	@:allow(lime.graphics.vulkan.VKDevice)
	private function new(device:VKDevice, handle:Int64, size:Int64, memoryTypeIndex:Int, properties:Int)
	{
		this.device = device;
		this.handle = handle;
		this.size = size;
		this.memoryTypeIndex = memoryTypeIndex;
		this.properties = properties;
	}

	public function dispose():Void
	{
		if (mapped)
		{
			unmap();
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			NativeCFFI.lime_vk_free_memory(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low);
			handle = Int64.ofInt(0);
		}
		#end
	}

	public inline function get():Int64
	{
		return handle;
	}

	public inline function isValid():Bool
	{
		return !VK.__isZero(handle);
	}

	/**
		Maps host-visible memory and keeps it mapped for repeated writes or
		readback. Passing `size` as `null` maps the rest of the allocation.
	**/
	public function map(offset:Int64 = null, size:Int64 = null, flags:Int = 0):Bool
	{
		if (offset == null)
		{
			offset = Int64.ofInt(0);
		}
		if (size == null)
		{
			size = Int64.ofInt(0);
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			var result = NativeCFFI.lime_vk_map_memory(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, offset.high, offset.low, size.high,
				size.low, flags);
			if (result)
			{
				mapped = true;
				mappedOffset = offset;
				mappedSize = size;
			}
			return result;
		}
		#end

		return false;
	}

	public function unmap():Void
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (mapped && isValid() && device != null && device.isValid())
		{
			NativeCFFI.lime_vk_unmap_memory(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low);
		}
		#end

		mapped = false;
		mappedOffset = Int64.ofInt(0);
		mappedSize = Int64.ofInt(0);
	}

	/**
		Copies bytes into a currently mapped range without unmapping. This is the
		hot-path companion to `upload()` for dynamic vertex/uniform streaming.
	**/
	public function writeBytes(bytes:Bytes, srcOffset:Int = 0, length:Int = -1, dstOffset:Int64 = null):Bool
	{
		if (bytes == null || !mapped)
		{
			return false;
		}
		if (dstOffset == null)
		{
			dstOffset = mappedOffset;
		}
		if (length < 0)
		{
			length = bytes.length - srcOffset;
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_write_mapped_memory(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, dstOffset.high, dstOffset.low, bytes,
				srcOffset, length);
		}
		#end

		return false;
	}

	public function flush(offset:Int64 = null, size:Int64 = null):Bool
	{
		if (!mapped)
		{
			return false;
		}
		if (offset == null)
		{
			offset = mappedOffset;
		}
		if (size == null)
		{
			size = mappedSize;
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_flush_mapped_memory(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, offset.high, offset.low, size.high,
				size.low);
		}
		#end

		return false;
	}

	public function invalidate(offset:Int64 = null, size:Int64 = null):Bool
	{
		if (!mapped)
		{
			return false;
		}
		if (offset == null)
		{
			offset = mappedOffset;
		}
		if (size == null)
		{
			size = mappedSize;
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_invalidate_mapped_memory(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, offset.high, offset.low, size.high,
				size.low);
		}
		#end

		return false;
	}

	/**
		Copies bytes into host-visible memory. This maps and unmaps internally,
		which is convenient for staging/uniform data and avoids exposing unsafe
		raw pointers at the Lime boundary.
	**/
	public function upload(bytes:Bytes, memoryOffset:Int64 = null, byteOffset:Int = 0, byteLength:Int = -1):Bool
	{
		if (memoryOffset == null)
		{
			memoryOffset = Int64.ofInt(0);
		}
		if (bytes == null)
		{
			return false;
		}
		if (byteLength < 0)
		{
			byteLength = bytes.length - byteOffset;
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_upload_memory(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, memoryOffset.high, memoryOffset.low, bytes, byteOffset, byteLength);
		}
		#end

		return false;
	}

	/**
		Copies host-visible memory into a Haxe `Bytes` buffer. Use this after an
		image-to-buffer transfer for render target and texture capture paths.
	**/
	public function download(bytes:Bytes, memoryOffset:Int64 = null, byteOffset:Int = 0, byteLength:Int = -1):Bool
	{
		if (memoryOffset == null)
		{
			memoryOffset = Int64.ofInt(0);
		}
		if (bytes == null)
		{
			return false;
		}
		if (byteLength < 0)
		{
			byteLength = bytes.length - byteOffset;
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_download_memory(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, memoryOffset.high, memoryOffset.low, bytes, byteOffset, byteLength);
		}
		#end

		return false;
	}
}
