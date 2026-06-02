package lime.graphics.vulkan;

import haxe.Int64;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	A Vulkan image handle. Swapchain images are owned by their `VKSwapchain`.
**/
class VKImage
{
	public var device(default, null):VKDevice;
	public var format(default, null):Int;
	public var handle(default, null):Int64;
	public var height(default, null):Int;
	public var index(default, null):Int;
	public var memory(default, null):VKDeviceMemory;
	public var ownsHandle(default, null):Bool;
	public var swapchain(default, null):VKSwapchain;
	public var width(default, null):Int;

	@:allow(lime.graphics.vulkan.VKSwapchain)
	private function new(swapchain:VKSwapchain, handle:Int64, index:Int)
	{
		this.swapchain = swapchain;
		this.device = swapchain != null ? swapchain.device : null;
		this.handle = handle;
		this.index = index;
		this.format = swapchain != null ? swapchain.format : VK.FORMAT_UNDEFINED;
		this.width = swapchain != null ? swapchain.width : 0;
		this.height = swapchain != null ? swapchain.height : 0;
		this.ownsHandle = false;
	}

	@:allow(lime.graphics.vulkan.VKDevice)
	private static function createOwned(device:VKDevice, handle:Int64, width:Int, height:Int, format:Int):VKImage
	{
		var image = new VKImage(null, handle, -1);
		image.swapchain = null;
		image.device = device;
		image.handle = handle;
		image.index = -1;
		image.format = format;
		image.width = width;
		image.height = height;
		image.ownsHandle = true;
		return image;
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
			var result = NativeCFFI.lime_vk_bind_image_memory(device.instance.context.__windowHandle, device.instance.handle.high,
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

	public function createView(format:Int = 0, aspectMask:Int = VK.IMAGE_ASPECT_COLOR_BIT, viewType:Int = VK.IMAGE_VIEW_TYPE_2D,
			baseMipLevel:Int = 0, levelCount:Int = 1, baseArrayLayer:Int = 0, layerCount:Int = 1):VKImageView
	{
		if (format == 0)
		{
			format = this.format;
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_image_view_ex(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, format, aspectMask, viewType,
				baseMipLevel, levelCount, baseArrayLayer, layerCount);
			var imageViewHandle = VK.__makeHandle(data);
			if (!VK.__isZero(imageViewHandle))
			{
				return new VKImageView(this, imageViewHandle, format, aspectMask, viewType);
			}
		}
		#end

		return null;
	}

	public function dispose(destroyMemory:Bool = false):Void
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (ownsHandle && isValid() && device != null && device.isValid())
		{
			NativeCFFI.lime_vk_destroy_image(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
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
			var data:Dynamic = NativeCFFI.lime_vk_get_image_memory_requirements(device.instance.context.__windowHandle, device.instance.handle.high,
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
}
