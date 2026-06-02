package lime.graphics;

import haxe.Int64;
import lime.graphics.vulkan.VKRenderer;
import lime.math.Vector2;
#if (!lime_doc_gen || lime_cffi)
import lime.system.CFFI;
#end
#if (!lime_doc_gen || lime_cffi)
import lime.system.CFFIPointer;
#end

#if hl
import hl.Bytes as HLBytes;
import hl.NativeArray;
#end
#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

/**
	The `VulkanRenderContext` exposes native Vulkan window bootstrap helpers when
	Vulkan is the render context type of the current `Window`.

	This context owns the window-specific pieces of Lime's Vulkan API:

	- required instance extensions for the current window
	- the current drawable size in pixels
	- Vulkan surface creation for an existing `VkInstance`
	- access to `vkGetInstanceProcAddr`

	Use `lime.graphics.vulkan.VK` and related classes for the broader Vulkan API
	surface as it grows.
**/
@:access(lime._internal.backend.native.NativeCFFI)
class VulkanRenderContext
{
	public var type(default, null):RenderContextType;
	public var version(default, null):String;

	private var __windowHandle:#if (!lime_doc_gen || lime_cffi) CFFIPointer #else Dynamic #end;

	@:allow(lime._internal.backend.native.NativeWindow)
	private function new(windowHandle:#if (!lime_doc_gen || lime_cffi) CFFIPointer #else Dynamic #end)
	{
		__windowHandle = windowHandle;
		type = VULKAN;
		version = "";
	}

	/**
		Creates a Vulkan surface for the current window using an existing
		`VkInstance` handle, or an object that exposes a `get()` method returning
		that handle.
	**/
	public function createSurface(instance:Dynamic):Int64
	{
		var surfaceData:Dynamic = null;

		#if (!macro && lime_cffi)
		var instanceHandle = __resolveHandle(instance);
		if (instanceHandle.high != 0 || instanceHandle.low != 0)
		{
			surfaceData = NativeCFFI.lime_window_create_vulkan_surface(__windowHandle, instanceHandle.high, instanceHandle.low);
		}
		#end

		if (surfaceData != null)
		{
			return Int64.make(surfaceData.high, surfaceData.low);
		}

		return Int64.ofInt(0);
	}

	/**
		Gets the current drawable size in pixels for the Vulkan surface.
	**/
	public function getDrawableSize(result:Vector2 = null):Vector2
	{
		if (result == null) result = new Vector2();

		#if (!macro && lime_cffi)
		var size:Dynamic = NativeCFFI.lime_window_get_vulkan_drawable_size(__windowHandle);
		if (size != null)
		{
			result.x = size.width;
			result.y = size.height;
			return result;
		}
		#end

		result.x = 0;
		result.y = 0;
		return result;
	}

	/**
		Returns the list of Vulkan instance extensions required to create a
		surface for this window.
	**/
	public function getInstanceExtensions():Array<String>
	{
		#if (!macro && lime_cffi)
		#if hl
		var bytes:NativeArray<HLBytes> = cast NativeCFFI.lime_window_get_vulkan_instance_extensions(__windowHandle);
		if (bytes != null)
		{
			var extensions = new Array<String>();
			for (i in 0...bytes.length)
			{
				extensions[i] = CFFI.stringValue(bytes[i]);
			}
			return extensions;
		}
		#else
		var extensions:Array<String> = cast NativeCFFI.lime_window_get_vulkan_instance_extensions(__windowHandle);
		if (extensions != null)
		{
			return extensions;
		}
		#end
		#end

		return [];
	}

	/**
		Returns the native address of SDL's `vkGetInstanceProcAddr` function.
	**/
	public function getInstanceProcAddr():Int64
	{
		#if (!macro && lime_cffi)
		var handleData:Dynamic = NativeCFFI.lime_window_get_vulkan_instance_proc_addr(__windowHandle);
		if (handleData != null)
		{
			return Int64.make(handleData.high, handleData.low);
		}
		#end

		return Int64.ofInt(0);
	}

	/**
		Creates Lime's validation Vulkan swapchain renderer for the current window.

		This renderer exists for smoke tests and samples while the public `VK`
		surface grows into the full rendering API.
		The renderer respects the current Lime `vsyncMode` preference when it
		chooses a swapchain present mode.
	**/
	public function createRenderer(applicationName:String = "Lime"):VKRenderer
	{
		#if (!macro && lime_cffi)
		var handle = NativeCFFI.lime_vulkan_renderer_create(__windowHandle, applicationName);
		if (handle != null)
		{
			return new VKRenderer(handle);
		}
		#end

		return null;
	}

	private static function __resolveHandle(value:Dynamic):Int64
	{
		if (value == null) return Int64.ofInt(0);

		var high:Dynamic = Reflect.field(value, "high");
		var low:Dynamic = Reflect.field(value, "low");
		if (high != null && low != null)
		{
			return Int64.make(high, low);
		}

		switch (Type.typeof(value))
		{
			case TInt:
				return Int64.ofInt(cast value);
			default:
		}

		var getField = Reflect.field(value, "get");
		if (getField != null)
		{
			try
			{
				return __resolveHandle(Reflect.callMethod(value, getField, []));
			}
			catch (e:Dynamic) {}
		}

		return Int64.ofInt(0);
	}
}
