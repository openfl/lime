package lime.graphics.vulkan;

import haxe.Int64;
#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
class VKFramebuffer
{
	public var device(default, null):VKDevice;
	public var handle(default, null):Int64;
	public var height(default, null):Int;
	public var renderPass(default, null):VKRenderPass;
	public var width(default, null):Int;

	@:allow(lime.graphics.vulkan.VKDevice)
	private function new(device:VKDevice, renderPass:VKRenderPass, handle:Int64, width:Int, height:Int)
	{
		this.device = device;
		this.renderPass = renderPass;
		this.handle = handle;
		this.width = width;
		this.height = height;
	}

	public function dispose():Void
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			NativeCFFI.lime_vk_destroy_framebuffer(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
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
