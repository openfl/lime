package lime.graphics.vulkan;

import haxe.Int64;
import lime.graphics.VulkanRenderContext;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	A lightweight managed `VkInstance` wrapper created through `VK.createInstance`.
**/
class VKInstance
{
	public var context(default, null):VulkanRenderContext;
	public var handle(default, null):Int64;

	@:allow(lime.graphics.vulkan.VK)
	private function new(context:VulkanRenderContext, handle:Int64)
	{
		this.context = context;
		this.handle = handle;
	}

	/**
		Creates a `VKSurface` for the current window using this instance.
	**/
	public function createSurface(contextOverride:VulkanRenderContext = null):VKSurface
	{
		var activeContext = (contextOverride != null) ? contextOverride : context;

		if (activeContext == null || VK.__isZero(handle))
		{
			return null;
		}

		#if (!macro && lime_cffi)
		var surfaceData:Dynamic = NativeCFFI.lime_window_create_vulkan_surface(activeContext.__windowHandle, handle.high, handle.low);
		if (surfaceData != null)
		{
			return new VKSurface(activeContext, this, surfaceData.high, surfaceData.low);
		}
		#end

		return null;
	}

	/**
		Destroys the managed `VkInstance`.
	**/
	public function dispose():Void
	{
		#if (!macro && lime_cffi)
		if (context != null && !VK.__isZero(handle))
		{
			NativeCFFI.lime_vk_destroy_instance(context.__windowHandle, handle.high, handle.low);
			handle = Int64.ofInt(0);
		}
		#end
	}

	/**
		Enumerates physical devices visible to this instance. If a surface is
		provided, queue family presentation support is populated for that surface.
	**/
	public function enumeratePhysicalDevices(surface:VKSurface = null):Array<VKPhysicalDevice>
	{
		var devices = new Array<VKPhysicalDevice>();

		if (context == null || VK.__isZero(handle))
		{
			return devices;
		}

		#if (!macro && lime_cffi)
		var result:Dynamic = NativeCFFI.lime_vk_get_physical_devices(context.__windowHandle, handle.high, handle.low, surface != null ? surface.high : 0,
			surface != null ? surface.low : 0);

		if (result != null)
		{
			var length:Int = untyped result.length;
			for (i in 0...length)
			{
				devices.push(new VKPhysicalDevice(this, untyped result[i]));
			}
		}
		#end

		return devices;
	}

	/**
		Selects a preferred physical device using Lime's lightweight heuristics.
	**/
	public function pickPhysicalDevice(surface:VKSurface = null, preferDiscrete:Bool = true):VKPhysicalDevice
	{
		return VK.pickPhysicalDevice(enumeratePhysicalDevices(surface), surface != null && surface.isValid(), preferDiscrete);
	}

	public inline function get():Int64
	{
		return handle;
	}

	public inline function isValid():Bool
	{
		return !VK.__isZero(handle);
	}
}
