package lime.graphics.vulkan;

import haxe.Int64;
import lime.graphics.VulkanRenderContext;
#if (!lime_doc_gen || lime_cffi)
import lime.system.CFFI;
#end

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	Entry point for Lime's Vulkan API surface.

	Like `lime.graphics.opengl.GL`, this class is the public place for low-level
	graphics API access. Vulkan is explicit by design, so the API is organized
	around handles and lifecycle objects instead of GL-style global state.
**/
class VK
{
	public static inline var SUCCESS = 0;
	public static inline var NOT_READY = 1;
	public static inline var TIMEOUT = 2;
	public static inline var EVENT_SET = 3;
	public static inline var EVENT_RESET = 4;
	public static inline var INCOMPLETE = 5;
	public static inline var SUBOPTIMAL_KHR = 1000001003;
	public static inline var ERROR_INITIALIZATION_FAILED = -3;
	public static inline var ERROR_OUT_OF_DATE_KHR = -1000001004;

	public static inline var KHR_SWAPCHAIN_EXTENSION_NAME = "VK_KHR_swapchain";

	public static inline var PHYSICAL_DEVICE_TYPE_OTHER = 0;
	public static inline var PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU = 1;
	public static inline var PHYSICAL_DEVICE_TYPE_DISCRETE_GPU = 2;
	public static inline var PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU = 3;
	public static inline var PHYSICAL_DEVICE_TYPE_CPU = 4;

	public static inline var QUEUE_GRAPHICS_BIT = 0x00000001;
	public static inline var QUEUE_COMPUTE_BIT = 0x00000002;
	public static inline var QUEUE_TRANSFER_BIT = 0x00000004;
	public static inline var QUEUE_SPARSE_BINDING_BIT = 0x00000008;

	public static inline var COMMAND_POOL_CREATE_TRANSIENT_BIT = 0x00000001;
	public static inline var COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT = 0x00000002;
	public static inline var COMMAND_POOL_CREATE_PROTECTED_BIT = 0x00000004;

	public static inline var COMMAND_BUFFER_LEVEL_PRIMARY = 0;
	public static inline var COMMAND_BUFFER_LEVEL_SECONDARY = 1;

	public static inline var COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT = 0x00000001;
	public static inline var COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT = 0x00000002;
	public static inline var COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT = 0x00000004;

	public static inline var COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT = 0x00000001;

	public static inline var FENCE_CREATE_SIGNALED_BIT = 0x00000001;

	public static inline var DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT = 0x00000001;

	public static inline var FORMAT_UNDEFINED = 0;
	public static inline var FORMAT_R8_UNORM = 9;
	public static inline var FORMAT_R8G8_UNORM = 16;
	public static inline var FORMAT_R8G8B8A8_UNORM = 37;
	public static inline var FORMAT_R8G8B8A8_SRGB = 43;
	public static inline var FORMAT_B8G8R8A8_UNORM = 44;
	public static inline var FORMAT_B8G8R8A8_SRGB = 50;
	public static inline var FORMAT_R16G16B16A16_SFLOAT = 97;
	public static inline var FORMAT_R32_SFLOAT = 100;
	public static inline var FORMAT_R32G32_SFLOAT = 103;
	public static inline var FORMAT_R32G32B32_SFLOAT = 106;
	public static inline var FORMAT_R32G32B32A32_SFLOAT = 109;
	public static inline var FORMAT_D16_UNORM = 124;
	public static inline var FORMAT_X8_D24_UNORM_PACK32 = 125;
	public static inline var FORMAT_D32_SFLOAT = 126;
	public static inline var FORMAT_S8_UINT = 127;
	public static inline var FORMAT_D24_UNORM_S8_UINT = 129;
	public static inline var FORMAT_D32_SFLOAT_S8_UINT = 130;

	public static inline var COLOR_SPACE_SRGB_NONLINEAR_KHR = 0;

	public static inline var PRESENT_MODE_IMMEDIATE_KHR = 0;
	public static inline var PRESENT_MODE_MAILBOX_KHR = 1;
	public static inline var PRESENT_MODE_FIFO_KHR = 2;
	public static inline var PRESENT_MODE_FIFO_RELAXED_KHR = 3;

	public static inline var BUFFER_USAGE_TRANSFER_SRC_BIT = 0x00000001;
	public static inline var BUFFER_USAGE_TRANSFER_DST_BIT = 0x00000002;
	public static inline var BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT = 0x00000004;
	public static inline var BUFFER_USAGE_STORAGE_TEXEL_BUFFER_BIT = 0x00000008;
	public static inline var BUFFER_USAGE_UNIFORM_BUFFER_BIT = 0x00000010;
	public static inline var BUFFER_USAGE_STORAGE_BUFFER_BIT = 0x00000020;
	public static inline var BUFFER_USAGE_INDEX_BUFFER_BIT = 0x00000040;
	public static inline var BUFFER_USAGE_VERTEX_BUFFER_BIT = 0x00000080;
	public static inline var BUFFER_USAGE_INDIRECT_BUFFER_BIT = 0x00000100;

	public static inline var MEMORY_PROPERTY_DEVICE_LOCAL_BIT = 0x00000001;
	public static inline var MEMORY_PROPERTY_HOST_VISIBLE_BIT = 0x00000002;
	public static inline var MEMORY_PROPERTY_HOST_COHERENT_BIT = 0x00000004;
	public static inline var MEMORY_PROPERTY_HOST_CACHED_BIT = 0x00000008;
	public static inline var MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT = 0x00000010;

	public static inline var IMAGE_TYPE_1D = 0;
	public static inline var IMAGE_TYPE_2D = 1;
	public static inline var IMAGE_TYPE_3D = 2;

	public static inline var IMAGE_TILING_OPTIMAL = 0;
	public static inline var IMAGE_TILING_LINEAR = 1;

	public static inline var IMAGE_USAGE_TRANSFER_SRC_BIT = 0x00000001;
	public static inline var IMAGE_USAGE_TRANSFER_DST_BIT = 0x00000002;
	public static inline var IMAGE_USAGE_SAMPLED_BIT = 0x00000004;
	public static inline var IMAGE_USAGE_STORAGE_BIT = 0x00000008;
	public static inline var IMAGE_USAGE_COLOR_ATTACHMENT_BIT = 0x00000010;
	public static inline var IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT = 0x00000020;
	public static inline var IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT = 0x00000040;
	public static inline var IMAGE_USAGE_INPUT_ATTACHMENT_BIT = 0x00000080;

	public static inline var IMAGE_ASPECT_COLOR_BIT = 0x00000001;
	public static inline var IMAGE_ASPECT_DEPTH_BIT = 0x00000002;
	public static inline var IMAGE_ASPECT_STENCIL_BIT = 0x00000004;
	public static inline var IMAGE_ASPECT_METADATA_BIT = 0x00000008;

	public static inline var COLOR_COMPONENT_R_BIT = 0x00000001;
	public static inline var COLOR_COMPONENT_G_BIT = 0x00000002;
	public static inline var COLOR_COMPONENT_B_BIT = 0x00000004;
	public static inline var COLOR_COMPONENT_A_BIT = 0x00000008;
	public static inline var COLOR_COMPONENT_RGBA_BITS = COLOR_COMPONENT_R_BIT | COLOR_COMPONENT_G_BIT | COLOR_COMPONENT_B_BIT | COLOR_COMPONENT_A_BIT;

	public static inline var IMAGE_LAYOUT_UNDEFINED = 0;
	public static inline var IMAGE_LAYOUT_GENERAL = 1;
	public static inline var IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL = 2;
	public static inline var IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL = 3;
	public static inline var IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL = 4;
	public static inline var IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL = 5;
	public static inline var IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL = 6;
	public static inline var IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL = 7;
	public static inline var IMAGE_LAYOUT_PREINITIALIZED = 8;
	public static inline var IMAGE_LAYOUT_PRESENT_SRC_KHR = 1000001002;

	public static inline var IMAGE_VIEW_TYPE_1D = 0;
	public static inline var IMAGE_VIEW_TYPE_2D = 1;
	public static inline var IMAGE_VIEW_TYPE_3D = 2;
	public static inline var IMAGE_VIEW_TYPE_CUBE = 3;
	public static inline var IMAGE_VIEW_TYPE_1D_ARRAY = 4;
	public static inline var IMAGE_VIEW_TYPE_2D_ARRAY = 5;
	public static inline var IMAGE_VIEW_TYPE_CUBE_ARRAY = 6;

	public static inline var PIPELINE_STAGE_TOP_OF_PIPE_BIT = 0x00000001;
	public static inline var PIPELINE_STAGE_DRAW_INDIRECT_BIT = 0x00000002;
	public static inline var PIPELINE_STAGE_VERTEX_INPUT_BIT = 0x00000004;
	public static inline var PIPELINE_STAGE_VERTEX_SHADER_BIT = 0x00000008;
	public static inline var PIPELINE_STAGE_FRAGMENT_SHADER_BIT = 0x00000080;
	public static inline var PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT = 0x00000100;
	public static inline var PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT = 0x00000200;
	public static inline var PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT = 0x00000400;
	public static inline var PIPELINE_STAGE_TRANSFER_BIT = 0x00001000;
	public static inline var PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT = 0x00002000;
	public static inline var PIPELINE_STAGE_HOST_BIT = 0x00004000;
	public static inline var PIPELINE_STAGE_ALL_GRAPHICS_BIT = 0x00008000;
	public static inline var PIPELINE_STAGE_ALL_COMMANDS_BIT = 0x00010000;

	public static inline var ACCESS_INDIRECT_COMMAND_READ_BIT = 0x00000001;
	public static inline var ACCESS_INDEX_READ_BIT = 0x00000002;
	public static inline var ACCESS_VERTEX_ATTRIBUTE_READ_BIT = 0x00000004;
	public static inline var ACCESS_UNIFORM_READ_BIT = 0x00000008;
	public static inline var ACCESS_INPUT_ATTACHMENT_READ_BIT = 0x00000010;
	public static inline var ACCESS_SHADER_READ_BIT = 0x00000020;
	public static inline var ACCESS_SHADER_WRITE_BIT = 0x00000040;
	public static inline var ACCESS_COLOR_ATTACHMENT_READ_BIT = 0x00000080;
	public static inline var ACCESS_COLOR_ATTACHMENT_WRITE_BIT = 0x00000100;
	public static inline var ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT = 0x00000200;
	public static inline var ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT = 0x00000400;
	public static inline var ACCESS_TRANSFER_READ_BIT = 0x00000800;
	public static inline var ACCESS_TRANSFER_WRITE_BIT = 0x00001000;
	public static inline var ACCESS_HOST_READ_BIT = 0x00002000;
	public static inline var ACCESS_HOST_WRITE_BIT = 0x00004000;
	public static inline var ACCESS_MEMORY_READ_BIT = 0x00008000;
	public static inline var ACCESS_MEMORY_WRITE_BIT = 0x00010000;

	public static inline var SHADER_STAGE_VERTEX_BIT = 0x00000001;
	public static inline var SHADER_STAGE_TESSELLATION_CONTROL_BIT = 0x00000002;
	public static inline var SHADER_STAGE_TESSELLATION_EVALUATION_BIT = 0x00000004;
	public static inline var SHADER_STAGE_GEOMETRY_BIT = 0x00000008;
	public static inline var SHADER_STAGE_FRAGMENT_BIT = 0x00000010;
	public static inline var SHADER_STAGE_COMPUTE_BIT = 0x00000020;
	public static inline var SHADER_STAGE_ALL_GRAPHICS = 0x0000001F;
	public static inline var SHADER_STAGE_ALL = 0x7FFFFFFF;

	public static inline var DESCRIPTOR_TYPE_SAMPLER = 0;
	public static inline var DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER = 1;
	public static inline var DESCRIPTOR_TYPE_SAMPLED_IMAGE = 2;
	public static inline var DESCRIPTOR_TYPE_STORAGE_IMAGE = 3;
	public static inline var DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER = 4;
	public static inline var DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER = 5;
	public static inline var DESCRIPTOR_TYPE_UNIFORM_BUFFER = 6;
	public static inline var DESCRIPTOR_TYPE_STORAGE_BUFFER = 7;
	public static inline var DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC = 8;
	public static inline var DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC = 9;
	public static inline var DESCRIPTOR_TYPE_INPUT_ATTACHMENT = 10;

	public static inline var PRIMITIVE_TOPOLOGY_POINT_LIST = 0;
	public static inline var PRIMITIVE_TOPOLOGY_LINE_LIST = 1;
	public static inline var PRIMITIVE_TOPOLOGY_LINE_STRIP = 2;
	public static inline var PRIMITIVE_TOPOLOGY_TRIANGLE_LIST = 3;
	public static inline var PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP = 4;
	public static inline var PRIMITIVE_TOPOLOGY_TRIANGLE_FAN = 5;

	public static inline var POLYGON_MODE_FILL = 0;
	public static inline var POLYGON_MODE_LINE = 1;
	public static inline var POLYGON_MODE_POINT = 2;

	public static inline var CULL_MODE_NONE = 0;
	public static inline var CULL_MODE_FRONT_BIT = 0x00000001;
	public static inline var CULL_MODE_BACK_BIT = 0x00000002;
	public static inline var CULL_MODE_FRONT_AND_BACK = 0x00000003;

	public static inline var FRONT_FACE_COUNTER_CLOCKWISE = 0;
	public static inline var FRONT_FACE_CLOCKWISE = 1;

	public static inline var COMPARE_OP_NEVER = 0;
	public static inline var COMPARE_OP_LESS = 1;
	public static inline var COMPARE_OP_EQUAL = 2;
	public static inline var COMPARE_OP_LESS_OR_EQUAL = 3;
	public static inline var COMPARE_OP_GREATER = 4;
	public static inline var COMPARE_OP_NOT_EQUAL = 5;
	public static inline var COMPARE_OP_GREATER_OR_EQUAL = 6;
	public static inline var COMPARE_OP_ALWAYS = 7;

	public static inline var STENCIL_OP_KEEP = 0;
	public static inline var STENCIL_OP_ZERO = 1;
	public static inline var STENCIL_OP_REPLACE = 2;
	public static inline var STENCIL_OP_INCREMENT_AND_CLAMP = 3;
	public static inline var STENCIL_OP_DECREMENT_AND_CLAMP = 4;
	public static inline var STENCIL_OP_INVERT = 5;
	public static inline var STENCIL_OP_INCREMENT_AND_WRAP = 6;
	public static inline var STENCIL_OP_DECREMENT_AND_WRAP = 7;

	public static inline var BLEND_FACTOR_ZERO = 0;
	public static inline var BLEND_FACTOR_ONE = 1;
	public static inline var BLEND_FACTOR_SRC_COLOR = 2;
	public static inline var BLEND_FACTOR_ONE_MINUS_SRC_COLOR = 3;
	public static inline var BLEND_FACTOR_DST_COLOR = 4;
	public static inline var BLEND_FACTOR_ONE_MINUS_DST_COLOR = 5;
	public static inline var BLEND_FACTOR_SRC_ALPHA = 6;
	public static inline var BLEND_FACTOR_ONE_MINUS_SRC_ALPHA = 7;
	public static inline var BLEND_FACTOR_DST_ALPHA = 8;
	public static inline var BLEND_FACTOR_ONE_MINUS_DST_ALPHA = 9;
	public static inline var BLEND_FACTOR_CONSTANT_COLOR = 10;
	public static inline var BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR = 11;
	public static inline var BLEND_FACTOR_CONSTANT_ALPHA = 12;
	public static inline var BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA = 13;
	public static inline var BLEND_FACTOR_SRC_ALPHA_SATURATE = 14;

	public static inline var BLEND_OP_ADD = 0;
	public static inline var BLEND_OP_SUBTRACT = 1;
	public static inline var BLEND_OP_REVERSE_SUBTRACT = 2;
	public static inline var BLEND_OP_MIN = 3;
	public static inline var BLEND_OP_MAX = 4;

	public static inline var DYNAMIC_STATE_VIEWPORT = 0;
	public static inline var DYNAMIC_STATE_SCISSOR = 1;
	public static inline var DYNAMIC_STATE_LINE_WIDTH = 2;
	public static inline var DYNAMIC_STATE_DEPTH_BIAS = 3;
	public static inline var DYNAMIC_STATE_BLEND_CONSTANTS = 4;
	public static inline var DYNAMIC_STATE_DEPTH_BOUNDS = 5;
	public static inline var DYNAMIC_STATE_STENCIL_COMPARE_MASK = 6;
	public static inline var DYNAMIC_STATE_STENCIL_WRITE_MASK = 7;
	public static inline var DYNAMIC_STATE_STENCIL_REFERENCE = 8;
	public static inline var DYNAMIC_STATE_VIEWPORT_BIT = 0x00000001;
	public static inline var DYNAMIC_STATE_SCISSOR_BIT = 0x00000002;

	public static inline var SAMPLE_COUNT_1_BIT = 0x00000001;
	public static inline var SAMPLE_COUNT_2_BIT = 0x00000002;
	public static inline var SAMPLE_COUNT_4_BIT = 0x00000004;
	public static inline var SAMPLE_COUNT_8_BIT = 0x00000008;
	public static inline var SAMPLE_COUNT_16_BIT = 0x00000010;
	public static inline var SAMPLE_COUNT_32_BIT = 0x00000020;
	public static inline var SAMPLE_COUNT_64_BIT = 0x00000040;

	public static inline var INDEX_TYPE_UINT16 = 0;
	public static inline var INDEX_TYPE_UINT32 = 1;
	public static inline var INDEX_TYPE_UINT8_KHR = 1000265000;

	public static inline var ATTACHMENT_LOAD_OP_LOAD = 0;
	public static inline var ATTACHMENT_LOAD_OP_CLEAR = 1;
	public static inline var ATTACHMENT_LOAD_OP_DONT_CARE = 2;
	public static inline var ATTACHMENT_STORE_OP_STORE = 0;
	public static inline var ATTACHMENT_STORE_OP_DONT_CARE = 1;

	public static inline var FILTER_NEAREST = 0;
	public static inline var FILTER_LINEAR = 1;
	public static inline var SAMPLER_MIPMAP_MODE_NEAREST = 0;
	public static inline var SAMPLER_MIPMAP_MODE_LINEAR = 1;
	public static inline var SAMPLER_ADDRESS_MODE_REPEAT = 0;
	public static inline var SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT = 1;
	public static inline var SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE = 2;
	public static inline var SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER = 3;

	public static inline var PIPELINE_BIND_POINT_GRAPHICS = 0;
	public static inline var SUBPASS_CONTENTS_INLINE = 0;
	public static inline var SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS = 1;
	public static inline var VERTEX_INPUT_RATE_VERTEX = 0;
	public static inline var VERTEX_INPUT_RATE_INSTANCE = 1;

	/**
		Creates a managed `VkInstance` for the current Lime Vulkan window.
	**/
	public static function createInstance(context:VulkanRenderContext, applicationName:String = "Lime"):VKInstance
	{
		if (context == null)
		{
			return null;
		}

		#if (!macro && lime_cffi)
		var handleData:Dynamic = NativeCFFI.lime_vk_create_instance(context.__windowHandle, applicationName);
		if (handleData != null)
		{
			var handle = __makeHandle(handleData);
			if (!__isZero(handle))
			{
				return new VKInstance(context, handle);
			}
		}
		#end

		return null;
	}

	/**
		Returns the last bootstrap-layer Vulkan error surfaced by Lime.
	**/
	public static function getLastError():String
	{
		#if (!macro && lime_cffi)
		var value:Dynamic = NativeCFFI.lime_vk_get_last_error();
		if (value != null)
		{
			return CFFI.stringValue(value);
		}
		#end

		return "";
	}

	/**
		Picks a preferred physical device from an enumerated device list.
		This currently prefers graphics-capable devices, optionally requiring
		present support, and favors discrete GPUs by default.
	**/
	public static function pickPhysicalDevice(devices:Array<VKPhysicalDevice>, requirePresent:Bool = false,
		preferDiscrete:Bool = true):VKPhysicalDevice
	{
		if (devices == null || devices.length == 0)
		{
			return null;
		}

		var bestDevice:VKPhysicalDevice = null;
		var bestScore = -1;

		for (device in devices)
		{
			var score = __scorePhysicalDevice(device, requirePresent, preferDiscrete);
			if (score > bestScore)
			{
				bestScore = score;
				bestDevice = device;
			}
		}

		return bestDevice;
	}

	public static inline function versionString(version:Int):String
	{
		var major = version >>> 22;
		var minor = (version >>> 12) & 0x3FF;
		var patch = version & 0xFFF;
		return major + "." + minor + "." + patch;
	}

	@:allow(lime.graphics.VulkanRenderContext)
	@:allow(lime.graphics.vulkan.VKBuffer)
	@:allow(lime.graphics.vulkan.VKCommandBuffer)
	@:allow(lime.graphics.vulkan.VKCommandPool)
	@:allow(lime.graphics.vulkan.VKDescriptorPool)
	@:allow(lime.graphics.vulkan.VKDescriptorSet)
	@:allow(lime.graphics.vulkan.VKDescriptorSetLayout)
	@:allow(lime.graphics.vulkan.VKDevice)
	@:allow(lime.graphics.vulkan.VKDeviceMemory)
	@:allow(lime.graphics.vulkan.VKFence)
	@:allow(lime.graphics.vulkan.VKFramebuffer)
	@:allow(lime.graphics.vulkan.VKImage)
	@:allow(lime.graphics.vulkan.VKImageView)
	@:allow(lime.graphics.vulkan.VKInstance)
	@:allow(lime.graphics.vulkan.VKMemoryRequirements)
	@:allow(lime.graphics.vulkan.VKPhysicalDevice)
	@:allow(lime.graphics.vulkan.VKPipeline)
	@:allow(lime.graphics.vulkan.VKPipelineCache)
	@:allow(lime.graphics.vulkan.VKPipelineLayout)
	@:allow(lime.graphics.vulkan.VKQueue)
	@:allow(lime.graphics.vulkan.VKRenderPass)
	@:allow(lime.graphics.vulkan.VKSampler)
	@:allow(lime.graphics.vulkan.VKSemaphore)
	@:allow(lime.graphics.vulkan.VKShaderModule)
	@:allow(lime.graphics.vulkan.VKSwapchain)
	private static function __makeHandle(value:Dynamic):Int64
	{
		if (value == null)
		{
			return Int64.ofInt(0);
		}

		return Int64.make(value.high, value.low);
	}

	@:allow(lime.graphics.VulkanRenderContext)
	@:allow(lime.graphics.vulkan.VKBuffer)
	@:allow(lime.graphics.vulkan.VKCommandBuffer)
	@:allow(lime.graphics.vulkan.VKCommandPool)
	@:allow(lime.graphics.vulkan.VKDescriptorPool)
	@:allow(lime.graphics.vulkan.VKDescriptorSet)
	@:allow(lime.graphics.vulkan.VKDescriptorSetLayout)
	@:allow(lime.graphics.vulkan.VKDevice)
	@:allow(lime.graphics.vulkan.VKDeviceMemory)
	@:allow(lime.graphics.vulkan.VKFence)
	@:allow(lime.graphics.vulkan.VKFramebuffer)
	@:allow(lime.graphics.vulkan.VKImage)
	@:allow(lime.graphics.vulkan.VKImageView)
	@:allow(lime.graphics.vulkan.VKInstance)
	@:allow(lime.graphics.vulkan.VKMemoryRequirements)
	@:allow(lime.graphics.vulkan.VKQueue)
	@:allow(lime.graphics.vulkan.VKPipeline)
	@:allow(lime.graphics.vulkan.VKPipelineCache)
	@:allow(lime.graphics.vulkan.VKPipelineLayout)
	@:allow(lime.graphics.vulkan.VKRenderPass)
	@:allow(lime.graphics.vulkan.VKSampler)
	@:allow(lime.graphics.vulkan.VKSemaphore)
	@:allow(lime.graphics.vulkan.VKShaderModule)
	@:allow(lime.graphics.vulkan.VKSwapchain)
	private static inline function __isZero(handle:Int64):Bool
	{
		return handle.high == 0 && handle.low == 0;
	}

	private static function __scorePhysicalDevice(device:VKPhysicalDevice, requirePresent:Bool, preferDiscrete:Bool):Int
	{
		if (device == null || !device.hasQueueFamily(true, requirePresent))
		{
			return -1;
		}

		var score = 0;

		switch (device.deviceType)
		{
			case PHYSICAL_DEVICE_TYPE_DISCRETE_GPU:
				score += preferDiscrete ? 400 : 250;
			case PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU:
				score += preferDiscrete ? 300 : 400;
			case PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU:
				score += 150;
			case PHYSICAL_DEVICE_TYPE_CPU:
				score += 100;
			default:
				score += 50;
		}

		var primaryQueue = device.getQueueFamily(true, requirePresent);
		if (primaryQueue != null)
		{
			score += primaryQueue.queueCount * 2;
			if (primaryQueue.supportsTransfer) score += 4;
			if (primaryQueue.supportsCompute) score += 2;
		}

		score += device.queueFamilies.length;
		return score;
	}
}
