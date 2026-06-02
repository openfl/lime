package lime.graphics.vulkan;

import haxe.Int64;

/**
	Memory requirements returned by Vulkan for buffers and images.
**/
class VKMemoryRequirements
{
	public var alignment(default, null):Int64;
	public var memoryTypeBits(default, null):Int;
	public var size(default, null):Int64;

	public function new(size:Int64, alignment:Int64, memoryTypeBits:Int)
	{
		this.size = size;
		this.alignment = alignment;
		this.memoryTypeBits = memoryTypeBits;
	}

	@:allow(lime.graphics.vulkan.VKBuffer)
	@:allow(lime.graphics.vulkan.VKImage)
	private static function fromDynamic(data:Dynamic):VKMemoryRequirements
	{
		if (data == null)
		{
			return null;
		}

		return new VKMemoryRequirements(VK.__makeHandle(data.size), VK.__makeHandle(data.alignment), data.memoryTypeBits);
	}
}
