package lime.graphics.vulkan;

import haxe.Int64;

/**
	A reserved range in a `VKUploadRing`.
**/
class VKUploadSlice
{
	public var buffer(default, null):VKBuffer;
	public var frameIndex(default, null):Int;
	public var offset(default, null):Int64;
	public var size(default, null):Int;

	@:allow(lime.graphics.vulkan.VKUploadRing)
	private function new(buffer:VKBuffer, offset:Int64, size:Int, frameIndex:Int)
	{
		this.buffer = buffer;
		this.offset = offset;
		this.size = size;
		this.frameIndex = frameIndex;
	}
}
