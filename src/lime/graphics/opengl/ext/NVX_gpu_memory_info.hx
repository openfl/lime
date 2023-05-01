package lime.graphics.opengl.ext;

@:keep
@:noCompletion class NVX_gpu_memory_info
{
	public var GPU_MEMORY_INFO_DEDICATED_VIDMEM_NVX = 0x9047;
	public var GPU_MEMORY_INFO_TOTAL_AVAILABLE_MEMORY_NVX = 0x9048;
	public var GPU_MEMORY_INFO_CURRENT_AVAILABLE_VIDMEM_NVX = 0x9049;
	public var GPU_MEMORY_INFO_EVICTION_COUNT_NVX = 0x904A;
	public var GPU_MEMORY_INFO_EVICTED_MEMORY_NVX = 0x904B;

	@:noCompletion private function new() {}
}
