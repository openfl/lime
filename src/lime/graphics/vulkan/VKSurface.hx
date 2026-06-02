package lime.graphics.vulkan;

import haxe.Int64;
import lime.graphics.VulkanRenderContext;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	A lightweight managed `VkSurfaceKHR` wrapper for the current Lime window.
**/
class VKSurface
{
	public var context(default, null):VulkanRenderContext;
	public var instance(default, null):VKInstance;
	public var high(default, null):Int;
	public var low(default, null):Int;

	@:allow(lime.graphics.vulkan.VKInstance)
	private function new(context:VulkanRenderContext, instance:VKInstance, high:Int, low:Int)
	{
		this.context = context;
		this.instance = instance;
		this.high = high;
		this.low = low;
	}

	public function dispose():Void
	{
		#if (!macro && lime_cffi)
		if (context != null && instance != null && instance.isValid() && (high != 0 || low != 0))
		{
			NativeCFFI.lime_vk_destroy_surface(context.__windowHandle, instance.handle.high, instance.handle.low, high, low);
			high = 0;
			low = 0;
		}
		#end
	}

	public inline function isValid():Bool
	{
		return high != 0 || low != 0;
	}

	public inline function toInt64():Int64
	{
		return Int64.make(high, low);
	}
}
