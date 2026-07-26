package lime.graphics.vulkan;

/**
	Result metadata from `vkAcquireNextImageKHR`.
**/
class VKAcquireResult
{
	public var imageIndex(default, null):Int;
	public var result(default, null):Int;

	@:allow(lime.graphics.vulkan.VKSwapchain)
	private function new(result:Int, imageIndex:Int)
	{
		this.result = result;
		this.imageIndex = imageIndex;
	}

	public inline function isSuccess():Bool
	{
		return result == VK.SUCCESS || result == VK.SUBOPTIMAL_KHR;
	}
}
