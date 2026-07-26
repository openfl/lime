package lime.graphics.vulkan;

import haxe.Int64;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	A Vulkan swapchain created for a Lime window surface.
**/
class VKSwapchain
{
	public var colorSpace(default, null):Int;
	public var device(default, null):VKDevice;
	public var format(default, null):Int;
	public var handle(default, null):Int64;
	public var height(default, null):Int;
	public var imageCount(default, null):Int;
	public var images(default, null):Array<VKImage>;
	public var presentMode(default, null):Int;
	public var surface(default, null):VKSurface;
	public var width(default, null):Int;

	@:allow(lime.graphics.vulkan.VKDevice)
	private function new(device:VKDevice, surface:VKSurface, data:Dynamic)
	{
		this.device = device;
		this.surface = surface;
		handle = VK.__makeHandle(data.handle);
		format = data.format;
		colorSpace = data.colorSpace;
		width = data.width;
		height = data.height;
		imageCount = data.imageCount;
		presentMode = data.presentMode;
		images = [];
		refreshImages();
	}

	/**
		Acquires the next presentable image from the swapchain.
	**/
	public function acquireNextImage(semaphore:VKSemaphore = null, fence:VKFence = null, timeout:Int64 = null):VKAcquireResult
	{
		if (timeout == null)
		{
			timeout = Int64.make(-1, -1);
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			var semaphoreHandle = (semaphore != null && semaphore.isValid()) ? semaphore.handle : Int64.ofInt(0);
			var fenceHandle = (fence != null && fence.isValid()) ? fence.handle : Int64.ofInt(0);
			var data:Dynamic = NativeCFFI.lime_vk_acquire_next_image(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, timeout.high, timeout.low,
				semaphoreHandle.high, semaphoreHandle.low, fenceHandle.high, fenceHandle.low);

			if (data != null)
			{
				return new VKAcquireResult(data.result, data.imageIndex);
			}
		}
		#end

		return new VKAcquireResult(VK.ERROR_INITIALIZATION_FAILED, -1);
	}

	public function dispose():Void
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			NativeCFFI.lime_vk_destroy_swapchain(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low);
			handle = Int64.ofInt(0);
			images = [];
			imageCount = 0;
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

	public function refreshImages():Array<VKImage>
	{
		images = [];
		imageCount = 0;

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_get_swapchain_images(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low);

			if (data != null)
			{
				var length:Int = untyped data.length;
				for (i in 0...length)
				{
					images.push(new VKImage(this, VK.__makeHandle(untyped data[i]), i));
				}
				imageCount = images.length;
			}
		}
		#end

		return images;
	}

	/**
		Creates a replacement swapchain using this swapchain as the old handle.
		Dispose the old swapchain after any in-flight work has finished.
	**/
	public function recreate(width:Int = 0, height:Int = 0, presentMode:Int = -1):VKSwapchain
	{
		if (presentMode < 0)
		{
			presentMode = this.presentMode;
		}

		if (device == null)
		{
			return null;
		}

		return device.createSwapchain(surface, width, height, presentMode, this);
	}
}
