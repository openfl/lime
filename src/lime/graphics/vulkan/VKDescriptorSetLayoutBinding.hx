package lime.graphics.vulkan;

class VKDescriptorSetLayoutBinding
{
	public var binding:Int;
	public var descriptorCount:Int;
	public var descriptorType:Int;
	public var stageFlags:Int;

	public function new(binding:Int, descriptorType:Int, stageFlags:Int, descriptorCount:Int = 1)
	{
		this.binding = binding;
		this.descriptorType = descriptorType;
		this.stageFlags = stageFlags;
		this.descriptorCount = descriptorCount;
	}
}
