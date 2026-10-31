package lime.graphics.vulkan;

import haxe.Int64;
#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	A Vulkan queue retrieved from a `VKDevice`.
**/
class VKQueue
{
	public var device(default, null):VKDevice;
	public var familyIndex(default, null):Int;
	public var handle(default, null):Int64;
	public var index(default, null):Int;

	@:allow(lime.graphics.vulkan.VKDevice)
	private function new(device:VKDevice, handle:Int64, familyIndex:Int, index:Int)
	{
		this.device = device;
		this.handle = handle;
		this.familyIndex = familyIndex;
		this.index = index;
	}

	public inline function get():Int64
	{
		return handle;
	}

	public inline function isValid():Bool
	{
		return !VK.__isZero(handle);
	}

	/**
		Presents an acquired swapchain image on this queue.
	**/
	public function present(swapchain:VKSwapchain, imageIndex:Int, waitSemaphore:VKSemaphore = null):Int
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && swapchain != null && swapchain.isValid())
		{
			var waitSemaphoreHandle = (waitSemaphore != null && waitSemaphore.isValid()) ? waitSemaphore.handle : Int64.ofInt(0);
			return NativeCFFI.lime_vk_queue_present(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, swapchain.handle.high, swapchain.handle.low, imageIndex,
				waitSemaphoreHandle.high, waitSemaphoreHandle.low);
		}
		#end

		return VK.ERROR_INITIALIZATION_FAILED;
	}

	/**
		Submits one command buffer to this queue. A fence may be provided to track
		completion from the CPU.
	**/
	public function submit(commandBuffer:VKCommandBuffer, fence:VKFence = null):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && commandBuffer != null && commandBuffer.isValid())
		{
			var fenceHigh = (fence != null && fence.isValid()) ? fence.handle.high : 0;
			var fenceLow = (fence != null && fence.isValid()) ? fence.handle.low : 0;

			return NativeCFFI.lime_vk_queue_submit(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, commandBuffer.handle.high, commandBuffer.handle.low, fenceHigh, fenceLow);
		}
		#end

		return false;
	}

	/**
		Submits one command buffer with optional acquire/render/present sync.
		This preserves the simple `submit(commandBuffer, fence)` path while
		exposing the explicit wait/signal pieces renderers need per frame.
	**/
	public function submitSynced(commandBuffer:VKCommandBuffer, waitSemaphore:VKSemaphore = null, signalSemaphore:VKSemaphore = null, fence:VKFence = null,
			waitStageMask:Int = VK.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && commandBuffer != null && commandBuffer.isValid())
		{
			var waitHandle = waitSemaphore != null && waitSemaphore.isValid() ? waitSemaphore.handle : Int64.ofInt(0);
			var signalHandle = signalSemaphore != null && signalSemaphore.isValid() ? signalSemaphore.handle : Int64.ofInt(0);
			var fenceHandle = fence != null && fence.isValid() ? fence.handle : Int64.ofInt(0);
			var state = [
				waitHandle.high,
				waitHandle.low,
				waitStageMask,
				signalHandle.high,
				signalHandle.low,
				fenceHandle.high,
				fenceHandle.low
			];

			return NativeCFFI.lime_vk_queue_submit_synced(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, commandBuffer.handle.high, commandBuffer.handle.low, state);
		}
		#end

		return false;
	}

	/**
		Blocks until this queue has completed all submitted work.
	**/
	public function waitIdle():Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_queue_wait_idle(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low);
		}
		#end

		return false;
	}
}
