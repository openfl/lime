package lime.graphics.vulkan;

import haxe.Int64;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
class VKDescriptorSet
{
	public var device(get, never):VKDevice;
	public var handle(default, null):Int64;
	public var layout(default, null):VKDescriptorSetLayout;
	public var pool(default, null):VKDescriptorPool;

	@:allow(lime.graphics.vulkan.VKDescriptorPool)
	private function new(pool:VKDescriptorPool, layout:VKDescriptorSetLayout, handle:Int64)
	{
		this.pool = pool;
		this.layout = layout;
		this.handle = handle;
	}

	public inline function get():Int64
	{
		return handle;
	}

	public inline function isValid():Bool
	{
		return !VK.__isZero(handle);
	}

	public function updateBuffer(binding:Int, buffer:VKBuffer, range:Int, offset:Int = 0,
			descriptorType:Int = VK.DESCRIPTOR_TYPE_UNIFORM_BUFFER):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		var device = get_device();
		if (isValid() && device != null && device.isValid() && buffer != null && buffer.isValid())
		{
			return NativeCFFI.lime_vk_update_descriptor_set_buffer(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, binding, descriptorType,
				buffer.handle.high, buffer.handle.low, offset, range);
		}
		#end

		return false;
	}

	public function updateImage(binding:Int, imageView:VKImageView, sampler:VKSampler = null,
			layout:Int = VK.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, descriptorType:Int = VK.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		var device = get_device();
		if (isValid() && device != null && device.isValid() && imageView != null && imageView.isValid())
		{
			var samplerHandle = (sampler != null && sampler.isValid()) ? sampler.handle : Int64.ofInt(0);
			return NativeCFFI.lime_vk_update_descriptor_set_image(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, binding, descriptorType,
				imageView.handle.high, imageView.handle.low, samplerHandle.high, samplerHandle.low, layout);
		}
		#end

		return false;
	}

	private inline function get_device():VKDevice
	{
		return pool != null ? pool.device : null;
	}
}
