package lime.graphics.vulkan;

import haxe.Int64;
import haxe.io.Bytes;
#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	A Vulkan buffer usable for vertex, index, uniform, staging, or storage data.
**/
class VKBuffer
{
	public var device(default, null):VKDevice;
	public var handle(default, null):Int64;
	public var memory(default, null):VKDeviceMemory;
	public var size(default, null):Int64;
	public var usage(default, null):Int;

	@:allow(lime.graphics.vulkan.VKDevice)
	private function new(device:VKDevice, handle:Int64, size:Int64, usage:Int)
	{
		this.device = device;
		this.handle = handle;
		this.size = size;
		this.usage = usage;
	}

	public function allocateMemory(properties:Int):VKDeviceMemory
	{
		if (device == null)
		{
			return null;
		}

		var allocated = device.allocateMemory(getMemoryRequirements(), properties);
		if (allocated != null && bindMemory(allocated))
		{
			memory = allocated;
			return allocated;
		}

		if (allocated != null)
		{
			allocated.dispose();
		}
		return null;
	}

	public function bindMemory(memory:VKDeviceMemory, offset:Int64 = null):Bool
	{
		if (offset == null)
		{
			offset = Int64.ofInt(0);
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && memory != null && memory.isValid())
		{
			var result = NativeCFFI.lime_vk_bind_buffer_memory(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, memory.handle.high, memory.handle.low,
				offset.high, offset.low);
			if (result)
			{
				this.memory = memory;
			}
			return result;
		}
		#end

		return false;
	}

	public function dispose(destroyMemory:Bool = false):Void
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			NativeCFFI.lime_vk_destroy_buffer(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low);
			handle = Int64.ofInt(0);
		}
		#end

		if (destroyMemory && memory != null)
		{
			memory.dispose();
			memory = null;
		}
	}

	public inline function get():Int64
	{
		return handle;
	}

	public function getMemoryRequirements():VKMemoryRequirements
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_get_buffer_memory_requirements(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low);
			return VKMemoryRequirements.fromDynamic(data);
		}
		#end

		return null;
	}

	public inline function isValid():Bool
	{
		return !VK.__isZero(handle);
	}

	public function map(offset:Int64 = null, size:Int64 = null, flags:Int = 0):Bool
	{
		return memory != null && memory.map(offset, size, flags);
	}

	public function unmap():Void
	{
		if (memory != null)
		{
			memory.unmap();
		}
	}

	public function writeBytes(bytes:Bytes, srcOffset:Int = 0, length:Int = -1, dstOffset:Int64 = null):Bool
	{
		return memory != null && memory.writeBytes(bytes, srcOffset, length, dstOffset);
	}

	public function flush(offset:Int64 = null, size:Int64 = null):Bool
	{
		return memory != null && memory.flush(offset, size);
	}

	public function invalidate(offset:Int64 = null, size:Int64 = null):Bool
	{
		return memory != null && memory.invalidate(offset, size);
	}

	public function upload(bytes:Bytes, memoryOffset:Int64 = null, byteOffset:Int = 0, byteLength:Int = -1):Bool
	{
		return memory != null && memory.upload(bytes, memoryOffset, byteOffset, byteLength);
	}

	public function download(bytes:Bytes, memoryOffset:Int64 = null, byteOffset:Int = 0, byteLength:Int = -1):Bool
	{
		return memory != null && memory.download(bytes, memoryOffset, byteOffset, byteLength);
	}
}
