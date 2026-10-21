package lime.graphics.vulkan;

class VKVertexAttribute
{
	public var binding:Int;
	public var format:Int;
	public var location:Int;
	public var offset:Int;

	public function new(location:Int, binding:Int, format:Int, offset:Int)
	{
		this.location = location;
		this.binding = binding;
		this.format = format;
		this.offset = offset;
	}
}
