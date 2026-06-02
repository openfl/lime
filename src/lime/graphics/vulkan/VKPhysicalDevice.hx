package lime.graphics.vulkan;

import haxe.Int64;
#if (!lime_doc_gen || lime_cffi)
import lime.system.CFFI;
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	Describes a Vulkan physical device discovered through a `VKInstance`.
**/
class VKPhysicalDevice
{
	public var instance(default, null):VKInstance;
	public var handle(default, null):Int64;
	public var name(default, null):String;
	public var apiVersion(default, null):Int;
	public var apiVersionString(default, null):String;
	public var driverVersion(default, null):Int;
	public var vendorID(default, null):Int;
	public var deviceID(default, null):Int;
	public var deviceType(default, null):Int;
	public var deviceTypeName(default, null):String;
	public var framebufferColorSampleCounts(default, null):Int;
	public var framebufferDepthSampleCounts(default, null):Int;
	public var framebufferNoAttachmentsSampleCounts(default, null):Int;
	public var framebufferStencilSampleCounts(default, null):Int;
	public var isDiscrete(default, null):Bool;
	public var maxPushConstantsSize(default, null):Int;
	public var minStorageBufferOffsetAlignment(default, null):Int64;
	public var minUniformBufferOffsetAlignment(default, null):Int64;
	public var nonCoherentAtomSize(default, null):Int64;
	public var supportsPresent(default, null):Bool;
	public var queueFamilies(default, null):Array<VKQueueFamilyInfo>;

	@:allow(lime.graphics.vulkan.VKInstance)
	private function new(instance:VKInstance, data:Dynamic)
	{
		this.instance = instance;
		handle = VK.__makeHandle(data.handle);
		name = (data.name != null) ? #if (!lime_doc_gen || lime_cffi) CFFI.stringValue(data.name) #else cast data.name #end : "";
		apiVersion = data.apiVersion;
		apiVersionString = VK.versionString(apiVersion);
		driverVersion = data.driverVersion;
		vendorID = data.vendorID;
		deviceID = data.deviceID;
		deviceType = data.deviceType;
		framebufferColorSampleCounts = data.framebufferColorSampleCounts;
		framebufferDepthSampleCounts = data.framebufferDepthSampleCounts;
		framebufferNoAttachmentsSampleCounts = data.framebufferNoAttachmentsSampleCounts;
		framebufferStencilSampleCounts = data.framebufferStencilSampleCounts;
		maxPushConstantsSize = data.maxPushConstantsSize;
		minStorageBufferOffsetAlignment = VK.__makeHandle(data.minStorageBufferOffsetAlignment);
		minUniformBufferOffsetAlignment = VK.__makeHandle(data.minUniformBufferOffsetAlignment);
		nonCoherentAtomSize = VK.__makeHandle(data.nonCoherentAtomSize);
		deviceTypeName = switch (deviceType)
		{
			case 1: "integrated-gpu";
			case 2: "discrete-gpu";
			case 3: "virtual-gpu";
			case 4: "cpu";
			default: "other";
		}
		isDiscrete = (deviceType == 2);
		supportsPresent = false;

		queueFamilies = [];
		var rawQueueFamilies:Dynamic = data.queueFamilies;
		if (rawQueueFamilies != null)
		{
			var length:Int = untyped rawQueueFamilies.length;
			for (i in 0...length)
			{
				var queueFamily = new VKQueueFamilyInfo(untyped rawQueueFamilies[i]);
				queueFamilies.push(queueFamily);
				if (queueFamily.supportsPresent)
				{
					supportsPresent = true;
				}
			}
		}
	}

	/**
		Creates a logical device with one queue from the requested queue family.
		If no queue family is provided, Lime selects a graphics-capable family
		that can present to the current surface when that data is available.
	**/
	public function createDevice(queueFamily:VKQueueFamilyInfo = null, extensions:Array<String> = null):VKDevice
	{
		if (queueFamily == null)
		{
			queueFamily = getQueueFamily(true, supportsPresent);
		}

		if (extensions == null)
		{
			extensions = [VK.KHR_SWAPCHAIN_EXTENSION_NAME];
		}

		if (queueFamily == null || instance == null || instance.context == null || !instance.isValid())
		{
			return null;
		}

		#if (!macro && lime_cffi && lime_vulkan)
		var data:Dynamic = NativeCFFI.lime_vk_create_device(instance.context.__windowHandle, instance.handle.high, instance.handle.low, handle.high,
			handle.low, queueFamily.index, extensions);
		if (data != null)
		{
			return new VKDevice(this, queueFamily, extensions, data);
		}
		#end

		return null;
	}

	/**
		Returns the first queue family that matches the requested capabilities.
	**/
	public function getQueueFamily(requireGraphics:Bool = true, requirePresent:Bool = false, requireCompute:Bool = false,
		requireTransfer:Bool = false):VKQueueFamilyInfo
	{
		for (queueFamily in queueFamilies)
		{
			if (queueFamily.matches(requireGraphics, requirePresent, requireCompute, requireTransfer))
			{
				return queueFamily;
			}
		}

		return null;
	}

	public inline function hasQueueFamily(requireGraphics:Bool = true, requirePresent:Bool = false, requireCompute:Bool = false,
		requireTransfer:Bool = false):Bool
	{
		return getQueueFamily(requireGraphics, requirePresent, requireCompute, requireTransfer) != null;
	}

	public function getMaxUsableSampleCount(requireDepth:Bool = false, requireStencil:Bool = false):Int
	{
		var counts = framebufferColorSampleCounts;
		if (requireDepth)
		{
			counts &= framebufferDepthSampleCounts;
		}
		if (requireStencil)
		{
			counts &= framebufferStencilSampleCounts;
		}

		for (sampleCount in [VK.SAMPLE_COUNT_64_BIT, VK.SAMPLE_COUNT_32_BIT, VK.SAMPLE_COUNT_16_BIT, VK.SAMPLE_COUNT_8_BIT,
			VK.SAMPLE_COUNT_4_BIT, VK.SAMPLE_COUNT_2_BIT])
		{
			if ((counts & sampleCount) != 0)
			{
				return sampleCount;
			}
		}

		return VK.SAMPLE_COUNT_1_BIT;
	}

	public function supportsSampleCount(samples:Int, requireDepth:Bool = false, requireStencil:Bool = false):Bool
	{
		var counts = framebufferColorSampleCounts;
		if (requireDepth)
		{
			counts &= framebufferDepthSampleCounts;
		}
		if (requireStencil)
		{
			counts &= framebufferStencilSampleCounts;
		}
		return (counts & samples) != 0;
	}
}
