package lime.graphics.vulkan;

import haxe.Int64;

/**
	A single descriptor write used by `VKDevice.updateDescriptorSets()`.
**/
class VKDescriptorWrite
{
	private static inline var KIND_BUFFER = 0;
	private static inline var KIND_IMAGE = 1;

	public var arrayElement:Int;
	public var binding:Int;
	public var buffer:VKBuffer;
	public var descriptorSet:VKDescriptorSet;
	public var descriptorType:Int;
	public var imageLayout:Int;
	public var imageView:VKImageView;
	public var offset:Int64;
	public var range:Int64;
	public var sampler:VKSampler;

	private var kind:Int;

	public function new()
	{
		arrayElement = 0;
		binding = 0;
		descriptorType = VK.DESCRIPTOR_TYPE_UNIFORM_BUFFER;
		imageLayout = VK.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		kind = KIND_BUFFER;
		offset = Int64.ofInt(0);
		range = Int64.ofInt(0);
	}

	public static function forBuffer(descriptorSet:VKDescriptorSet, binding:Int, buffer:VKBuffer, range:Int64 = null, offset:Int64 = null,
			descriptorType:Int = VK.DESCRIPTOR_TYPE_UNIFORM_BUFFER, arrayElement:Int = 0):VKDescriptorWrite
	{
		var write = new VKDescriptorWrite();
		write.kind = KIND_BUFFER;
		write.descriptorSet = descriptorSet;
		write.binding = binding;
		write.buffer = buffer;
		write.range = range != null ? range : Int64.ofInt(0);
		write.offset = offset != null ? offset : Int64.ofInt(0);
		write.descriptorType = descriptorType;
		write.arrayElement = arrayElement;
		return write;
	}

	public static function forImage(descriptorSet:VKDescriptorSet, binding:Int, imageView:VKImageView, sampler:VKSampler = null,
			imageLayout:Int = VK.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, descriptorType:Int = VK.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			arrayElement:Int = 0):VKDescriptorWrite
	{
		var write = new VKDescriptorWrite();
		write.kind = KIND_IMAGE;
		write.descriptorSet = descriptorSet;
		write.binding = binding;
		write.imageView = imageView;
		write.sampler = sampler;
		write.imageLayout = imageLayout;
		write.descriptorType = descriptorType;
		write.arrayElement = arrayElement;
		return write;
	}

	@:allow(lime.graphics.vulkan.VKDevice)
	private function pack(result:Array<Int>):Bool
	{
		if (descriptorSet == null || !descriptorSet.isValid())
		{
			return false;
		}

		if (kind == KIND_IMAGE)
		{
			if (imageView == null || !imageView.isValid())
			{
				return false;
			}
			var samplerHandle = (sampler != null && sampler.isValid()) ? sampler.handle : Int64.ofInt(0);
			result.push(KIND_IMAGE);
			result.push(descriptorSet.handle.high);
			result.push(descriptorSet.handle.low);
			result.push(binding);
			result.push(arrayElement);
			result.push(descriptorType);
			result.push(imageView.handle.high);
			result.push(imageView.handle.low);
			result.push(samplerHandle.high);
			result.push(samplerHandle.low);
			result.push(imageLayout);
			return true;
		}

		if (buffer == null || !buffer.isValid())
		{
			return false;
		}
		result.push(KIND_BUFFER);
		result.push(descriptorSet.handle.high);
		result.push(descriptorSet.handle.low);
		result.push(binding);
		result.push(arrayElement);
		result.push(descriptorType);
		result.push(buffer.handle.high);
		result.push(buffer.handle.low);
		result.push(offset.high);
		result.push(offset.low);
		result.push(range.high);
		result.push(range.low);
		return true;
	}
}
