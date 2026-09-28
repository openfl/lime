package lime.graphics.vulkan;

import lime.graphics.Image;
#if (!lime_doc_gen || lime_cffi)
import lime.system.CFFI;
#end
#if (!lime_doc_gen || lime_cffi)
import lime.system.CFFIPointer;
#end
#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	Lime's managed Vulkan validation renderer.

	This is useful for smoke tests and samples, but application renderers should
	build on `VK` handles such as `VKInstance`, `VKDevice`, and `VKQueue`.
**/
class VKRenderer
{
	public var info(get, never):String;
	public var isValid(get, never):Bool;
	public var lastError(get, never):String;

	private var __handle:#if (!lime_doc_gen || lime_cffi) CFFIPointer #else Dynamic #end;
	private var __info:String;

	@:allow(lime.graphics.VulkanRenderContext)
	private function new(handle:#if (!lime_doc_gen || lime_cffi) CFFIPointer #else Dynamic #end)
	{
		__handle = handle;
		__info = "";

		#if (!macro && lime_cffi)
		if (__handle != null)
		{
			refreshInfo();
		}
		#end
	}

	public function dispose():Void
	{
		#if (!macro && lime_cffi)
		if (__handle != null)
		{
			NativeCFFI.lime_vulkan_renderer_destroy(__handle);
			__handle = null;
		}
		#end
	}

	public function render(red:Float, green:Float, blue:Float, alpha:Float = 1.0):Bool
	{
		#if (!macro && lime_cffi)
		if (__handle != null)
		{
			return NativeCFFI.lime_vulkan_renderer_render(__handle, red, green, blue, alpha);
		}
		#end

		return false;
	}

	public function refreshInfo():String
	{
		#if (!macro && lime_cffi)
		if (__handle != null)
		{
			var value:Dynamic = NativeCFFI.lime_vulkan_renderer_get_info(__handle);
			__info = (value != null) ? CFFI.stringValue(value) : "";
		}
		#end

		return __info;
	}

	public function setOverlayImage(image:Image, x:Int, y:Int):Bool
	{
		#if (!macro && lime_cffi)
		if (__handle != null)
		{
			if (image == null)
			{
				return NativeCFFI.lime_vulkan_renderer_clear_overlay(__handle);
			}

			if (image.buffer != null && image.width > 0 && image.height > 0)
			{
				return NativeCFFI.lime_vulkan_renderer_set_overlay(__handle, image.data.toBytes(), image.width, image.height, x, y);
			}
		}
		#end

		return false;
	}

	public function clearOverlay():Bool
	{
		#if (!macro && lime_cffi)
		if (__handle != null)
		{
			return NativeCFFI.lime_vulkan_renderer_clear_overlay(__handle);
		}
		#end

		return false;
	}

	public function resize():Bool
	{
		#if (!macro && lime_cffi)
		if (__handle != null)
		{
			return NativeCFFI.lime_vulkan_renderer_resize(__handle);
		}
		#end

		return false;
	}

	public static function getLastError():String
	{
		#if (!macro && lime_cffi)
		var value:Dynamic = NativeCFFI.lime_vulkan_renderer_get_last_error();
		if (value != null)
		{
			return CFFI.stringValue(value);
		}
		#end

		return "";
	}

	private inline function get_info():String
	{
		return __info;
	}

	private inline function get_isValid():Bool
	{
		return __handle != null;
	}

	private inline function get_lastError():String
	{
		return getLastError();
	}
}
