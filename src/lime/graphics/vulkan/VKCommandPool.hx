package lime.graphics.vulkan;

import haxe.Int64;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	A Vulkan command pool created from a `VKDevice`.
**/
class VKCommandPool
{
	public var device(default, null):VKDevice;
	public var handle(default, null):Int64;
	public var queueFamilyIndex(default, null):Int;

	@:allow(lime.graphics.vulkan.VKDevice)
	private function new(device:VKDevice, queueFamilyIndex:Int, handle:Int64)
	{
		this.device = device;
		this.queueFamilyIndex = queueFamilyIndex;
		this.handle = handle;
	}

	public function allocateCommandBuffer(level:Int = VK.COMMAND_BUFFER_LEVEL_PRIMARY):VKCommandBuffer
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_allocate_command_buffer(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, level);
			var commandBufferHandle = VK.__makeHandle(data);
			if (!VK.__isZero(commandBufferHandle))
			{
				return new VKCommandBuffer(this, commandBufferHandle, level);
			}
		}
		#end

		return null;
	}

	public function dispose():Void
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			NativeCFFI.lime_vk_destroy_command_pool(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
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

	public function reset(flags:Int = 0):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_reset_command_pool(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, flags);
		}
		#end

		return false;
	}

	@:allow(lime.graphics.vulkan.VKCommandBuffer)
	private function free(commandBuffer:VKCommandBuffer):Void
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (commandBuffer != null && commandBuffer.isValid() && isValid() && device != null && device.isValid())
		{
			NativeCFFI.lime_vk_free_command_buffer(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, commandBuffer.handle.high, commandBuffer.handle.low);
			commandBuffer.__invalidate();
		}
		#end
	}
}
