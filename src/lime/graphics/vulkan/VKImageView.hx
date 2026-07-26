package lime.graphics.vulkan;

import haxe.Int64;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	A Vulkan image view created for a `VKImage`.
**/
class VKImageView
{
	public var aspectMask(default, null):Int;
	public var device(default, null):VKDevice;
	public var format(default, null):Int;
	public var handle(default, null):Int64;
	public var image(default, null):VKImage;
	public var viewType(default, null):Int;

	@:allow(lime.graphics.vulkan.VKImage)
	private function new(image:VKImage, handle:Int64, format:Int, aspectMask:Int, viewType:Int)
	{
		this.image = image;
		this.device = image.device;
		this.handle = handle;
		this.format = format;
		this.aspectMask = aspectMask;
		this.viewType = viewType;
	}

	public function dispose():Void
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			NativeCFFI.lime_vk_destroy_image_view(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
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
}
