package lime.graphics.vulkan;

class VKDescriptorPoolSize
{
	public var descriptorCount:Int;
	public var descriptorType:Int;

	public function new(descriptorType:Int, descriptorCount:Int)
	{
		this.descriptorType = descriptorType;
		this.descriptorCount = descriptorCount;
	}
}
