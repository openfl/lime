package lime.graphics.vulkan;

class VKVertexBinding
{
	public var binding:Int;
	public var inputRate:Int;
	public var stride:Int;

	public function new(binding:Int, stride:Int, inputRate:Int = VK.VERTEX_INPUT_RATE_VERTEX)
	{
		this.binding = binding;
		this.stride = stride;
		this.inputRate = inputRate;
	}
}
