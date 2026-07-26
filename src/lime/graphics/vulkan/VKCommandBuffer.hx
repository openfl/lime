package lime.graphics.vulkan;

import haxe.Int64;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	A Vulkan command buffer allocated from a `VKCommandPool`.
**/
class VKCommandBuffer
{
	public var device(get, never):VKDevice;
	public var handle(default, null):Int64;
	public var level(default, null):Int;
	public var pool(default, null):VKCommandPool;

	@:allow(lime.graphics.vulkan.VKCommandPool)
	private function new(pool:VKCommandPool, handle:Int64, level:Int)
	{
		this.pool = pool;
		this.handle = handle;
		this.level = level;
	}

	public function begin(flags:Int = 0):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && pool != null && pool.device != null && pool.device.isValid())
		{
			return NativeCFFI.lime_vk_begin_command_buffer(pool.device.instance.context.__windowHandle, pool.device.instance.handle.high,
				pool.device.instance.handle.low, pool.device.handle.high, pool.device.handle.low, handle.high, handle.low, flags);
		}
		#end

		return false;
	}

	public function dispose():Void
	{
		if (pool != null)
		{
			pool.free(this);
		}
	}

	public function beginRenderPass(renderPass:VKRenderPass, framebuffer:VKFramebuffer, width:Int, height:Int,
			clearRed:Float = 0, clearGreen:Float = 0, clearBlue:Float = 0, clearAlpha:Float = 1,
			clearDepth:Float = 1, clearStencil:Int = 0, x:Int = 0, y:Int = 0):Bool
	{
		var clearValueCount = renderPass != null && renderPass.depthStencilFormat != VK.FORMAT_UNDEFINED ? 2 : 1;
		var state = [x, y, width, height, clearStencil, clearValueCount];
		var clear = [clearRed, clearGreen, clearBlue, clearAlpha, clearDepth];

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && renderPass != null && renderPass.isValid() && framebuffer != null
			&& framebuffer.isValid())
		{
			return NativeCFFI.lime_vk_cmd_begin_render_pass(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, renderPass.handle.high,
				renderPass.handle.low, framebuffer.handle.high, framebuffer.handle.low, state, clear);
		}
		#end

		return false;
	}

	public function bindDescriptorSet(layout:VKPipelineLayout, descriptorSet:VKDescriptorSet, firstSet:Int = 0,
			bindPoint:Int = VK.PIPELINE_BIND_POINT_GRAPHICS, dynamicOffsets:Array<Int> = null):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && layout != null && layout.isValid() && descriptorSet != null && descriptorSet.isValid())
		{
			if (dynamicOffsets != null && dynamicOffsets.length > 0)
			{
				var state = [bindPoint, firstSet, dynamicOffsets.length];
				for (offset in dynamicOffsets)
				{
					state.push(offset);
				}
				return NativeCFFI.lime_vk_cmd_bind_descriptor_set_ex(device.instance.context.__windowHandle, device.instance.handle.high,
					device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, layout.handle.high, layout.handle.low,
					descriptorSet.handle.high, descriptorSet.handle.low, state);
			}

			return NativeCFFI.lime_vk_cmd_bind_descriptor_set(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, layout.handle.high, layout.handle.low,
				descriptorSet.handle.high, descriptorSet.handle.low, bindPoint, firstSet);
		}
		#end

		return false;
	}

	public function bindDescriptorSetDynamicOffset(layout:VKPipelineLayout, descriptorSet:VKDescriptorSet, dynamicOffset:Int, firstSet:Int = 0,
			bindPoint:Int = VK.PIPELINE_BIND_POINT_GRAPHICS):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && layout != null && layout.isValid() && descriptorSet != null && descriptorSet.isValid())
		{
			return NativeCFFI.lime_vk_cmd_bind_descriptor_set_dynamic_offset(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, layout.handle.high, layout.handle.low,
				descriptorSet.handle.high, descriptorSet.handle.low, dynamicOffset, firstSet, bindPoint);
		}
		#end

		return false;
	}

	public function bindIndexBuffer(buffer:VKBuffer, offset:Int64 = null, indexType:Int = VK.INDEX_TYPE_UINT16):Bool
	{
		if (offset == null)
		{
			offset = Int64.ofInt(0);
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && buffer != null && buffer.isValid())
		{
			return NativeCFFI.lime_vk_cmd_bind_index_buffer(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, buffer.handle.high, buffer.handle.low,
				offset.high, offset.low, indexType);
		}
		#end

		return false;
	}

	public function bindPipeline(pipeline:VKPipeline, bindPoint:Int = VK.PIPELINE_BIND_POINT_GRAPHICS):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && pipeline != null && pipeline.isValid())
		{
			return NativeCFFI.lime_vk_cmd_bind_pipeline(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, pipeline.handle.high, pipeline.handle.low,
				bindPoint);
		}
		#end

		return false;
	}

	public function bindVertexBuffer(buffer:VKBuffer, binding:Int = 0, offset:Int64 = null):Bool
	{
		if (offset == null)
		{
			offset = Int64.ofInt(0);
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && buffer != null && buffer.isValid())
		{
			return NativeCFFI.lime_vk_cmd_bind_vertex_buffer(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, buffer.handle.high, buffer.handle.low,
				binding, offset.high, offset.low);
		}
		#end

		return false;
	}

	public function blitImage(source:VKImage, destination:VKImage, width:Int, height:Int, sourceLayout:Int = VK.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
			destinationLayout:Int = VK.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, filter:Int = VK.FILTER_LINEAR):Bool
	{
		return blitImageRegion(source, destination, width, height, sourceLayout, destinationLayout, filter);
	}

	public function blitImageRegion(source:VKImage, destination:VKImage, sourceWidth:Int, sourceHeight:Int,
			sourceLayout:Int = VK.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, destinationLayout:Int = VK.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			filter:Int = VK.FILTER_LINEAR, destinationWidth:Int = -1, destinationHeight:Int = -1, sourceX:Int = 0, sourceY:Int = 0,
			sourceZ:Int = 0, destinationX:Int = 0, destinationY:Int = 0, destinationZ:Int = 0, sourceDepth:Int = 1, destinationDepth:Int = 1,
			sourceMipLevel:Int = 0, destinationMipLevel:Int = 0, sourceBaseArrayLayer:Int = 0, destinationBaseArrayLayer:Int = 0, layerCount:Int = 1,
			aspectMask:Int = VK.IMAGE_ASPECT_COLOR_BIT):Bool
	{
		if (destinationWidth < 0) destinationWidth = sourceWidth;
		if (destinationHeight < 0) destinationHeight = sourceHeight;
		var state = [
			sourceX,
			sourceY,
			sourceZ,
			sourceX + sourceWidth,
			sourceY + sourceHeight,
			sourceZ + sourceDepth,
			destinationX,
			destinationY,
			destinationZ,
			destinationX + destinationWidth,
			destinationY + destinationHeight,
			destinationZ + destinationDepth,
			sourceLayout,
			destinationLayout,
			filter,
			sourceMipLevel,
			destinationMipLevel,
			sourceBaseArrayLayer,
			destinationBaseArrayLayer,
			layerCount,
			aspectMask
		];

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && source != null && source.isValid() && destination != null && destination.isValid())
		{
			return NativeCFFI.lime_vk_cmd_blit_image(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, source.handle.high, source.handle.low, destination.handle.high,
				destination.handle.low, state);
		}
		#end

		return false;
	}

	public function clearColorImage(image:VKImage, layout:Int, red:Float, green:Float, blue:Float, alpha:Float,
			aspectMask:Int = VK.IMAGE_ASPECT_COLOR_BIT):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && image != null && image.isValid())
		{
			return NativeCFFI.lime_vk_cmd_clear_color_image(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, image.handle.high, image.handle.low,
				layout, aspectMask, [red, green, blue, alpha]);
		}
		#end

		return false;
	}

	public function clearDepthStencilImage(image:VKImage, layout:Int, depth:Float = 1, stencil:Int = 0,
			aspectMask:Int = VK.IMAGE_ASPECT_DEPTH_BIT | VK.IMAGE_ASPECT_STENCIL_BIT, baseMipLevel:Int = 0, levelCount:Int = 1,
			baseArrayLayer:Int = 0, layerCount:Int = 1):Bool
	{
		var state = [layout, stencil, aspectMask, baseMipLevel, levelCount, baseArrayLayer, layerCount];

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && image != null && image.isValid())
		{
			return NativeCFFI.lime_vk_cmd_clear_depth_stencil_image(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, image.handle.high, image.handle.low,
				state, [depth]);
		}
		#end

		return false;
	}

	public function clearAttachments(color:Bool, depth:Bool, stencil:Bool, x:Int, y:Int, width:Int, height:Int, red:Float = 0,
			green:Float = 0, blue:Float = 0, alpha:Float = 0, depthValue:Float = 1, stencilValue:Int = 0):Bool
	{
		var state = [color ? 1 : 0, depth ? 1 : 0, stencil ? 1 : 0, x, y, width, height, stencilValue];
		var clear = [red, green, blue, alpha, depthValue];

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_cmd_clear_attachments(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, state, clear);
		}
		#end

		return false;
	}

	public function copyBuffer(source:VKBuffer, destination:VKBuffer, size:Int64, sourceOffset:Int64 = null, destinationOffset:Int64 = null):Bool
	{
		if (sourceOffset == null) sourceOffset = Int64.ofInt(0);
		if (destinationOffset == null) destinationOffset = Int64.ofInt(0);
		var state = [size.high, size.low, sourceOffset.high, sourceOffset.low, destinationOffset.high, destinationOffset.low];

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && source != null && source.isValid() && destination != null && destination.isValid())
		{
			return NativeCFFI.lime_vk_cmd_copy_buffer(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, source.handle.high, source.handle.low, destination.handle.high,
				destination.handle.low, state);
		}
		#end

		return false;
	}

	public function copyBufferToImage(buffer:VKBuffer, image:VKImage, width:Int, height:Int,
			layout:Int = VK.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL):Bool
	{
		return copyBufferToImageRegion(buffer, image, width, height, layout);
	}

	public function copyBufferToImageRegion(buffer:VKBuffer, image:VKImage, width:Int, height:Int,
			layout:Int = VK.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, depth:Int = 1, bufferOffset:Int64 = null, bufferRowLength:Int = 0,
			bufferImageHeight:Int = 0, imageX:Int = 0, imageY:Int = 0, imageZ:Int = 0, mipLevel:Int = 0, baseArrayLayer:Int = 0,
			layerCount:Int = 1, aspectMask:Int = VK.IMAGE_ASPECT_COLOR_BIT):Bool
	{
		if (bufferOffset == null) bufferOffset = Int64.ofInt(0);
		var state = [
			width,
			height,
			depth,
			layout,
			bufferOffset.high,
			bufferOffset.low,
			bufferRowLength,
			bufferImageHeight,
			imageX,
			imageY,
			imageZ,
			mipLevel,
			baseArrayLayer,
			layerCount,
			aspectMask
		];

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && buffer != null && buffer.isValid() && image != null && image.isValid())
		{
			return NativeCFFI.lime_vk_cmd_copy_buffer_to_image_region(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, buffer.handle.high, buffer.handle.low,
				image.handle.high, image.handle.low, state);
		}
		#end

		return false;
	}

	public function copyImageToBufferRegion(image:VKImage, buffer:VKBuffer, width:Int, height:Int,
			layout:Int = VK.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, depth:Int = 1, bufferOffset:Int64 = null, bufferRowLength:Int = 0,
			bufferImageHeight:Int = 0, imageX:Int = 0, imageY:Int = 0, imageZ:Int = 0, mipLevel:Int = 0, baseArrayLayer:Int = 0,
			layerCount:Int = 1, aspectMask:Int = VK.IMAGE_ASPECT_COLOR_BIT):Bool
	{
		if (bufferOffset == null) bufferOffset = Int64.ofInt(0);
		var state = [
			width,
			height,
			depth,
			layout,
			bufferOffset.high,
			bufferOffset.low,
			bufferRowLength,
			bufferImageHeight,
			imageX,
			imageY,
			imageZ,
			mipLevel,
			baseArrayLayer,
			layerCount,
			aspectMask
		];

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && image != null && image.isValid() && buffer != null && buffer.isValid())
		{
			return NativeCFFI.lime_vk_cmd_copy_image_to_buffer_region(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, image.handle.high, image.handle.low,
				buffer.handle.high, buffer.handle.low, state);
		}
		#end

		return false;
	}

	public function draw(vertexCount:Int, instanceCount:Int = 1, firstVertex:Int = 0, firstInstance:Int = 0):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_cmd_draw(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, vertexCount, instanceCount, firstVertex, firstInstance);
		}
		#end

		return false;
	}

	public function drawIndexed(indexCount:Int, instanceCount:Int = 1, firstIndex:Int = 0, vertexOffset:Int = 0, firstInstance:Int = 0):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_cmd_draw_indexed(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, indexCount, instanceCount, firstIndex, vertexOffset, firstInstance);
		}
		#end

		return false;
	}

	public function drawIndirect(buffer:VKBuffer, offset:Int64, drawCount:Int, stride:Int):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && buffer != null && buffer.isValid())
		{
			return NativeCFFI.lime_vk_cmd_draw_indirect(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, buffer.handle.high, buffer.handle.low,
				offset.high, offset.low, drawCount, stride);
		}
		#end

		return false;
	}

	public function drawIndexedIndirect(buffer:VKBuffer, offset:Int64, drawCount:Int, stride:Int):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && buffer != null && buffer.isValid())
		{
			return NativeCFFI.lime_vk_cmd_draw_indexed_indirect(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, buffer.handle.high, buffer.handle.low,
				offset.high, offset.low, drawCount, stride);
		}
		#end

		return false;
	}

	public function end():Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && pool != null && pool.device != null && pool.device.isValid())
		{
			return NativeCFFI.lime_vk_end_command_buffer(pool.device.instance.context.__windowHandle, pool.device.instance.handle.high,
				pool.device.instance.handle.low, pool.device.handle.high, pool.device.handle.low, handle.high, handle.low);
		}
		#end

		return false;
	}

	public function endRenderPass():Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_cmd_end_render_pass(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low);
		}
		#end

		return false;
	}

	public inline function get():Int64
	{
		return handle;
	}

	public inline function isValid():Bool
	{
		return !VK.__isZero(handle);
	}

	public function reset(flags:Int = 0):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && pool != null && pool.device != null && pool.device.isValid())
		{
			return NativeCFFI.lime_vk_reset_command_buffer(pool.device.instance.context.__windowHandle, pool.device.instance.handle.high,
				pool.device.instance.handle.low, pool.device.handle.high, pool.device.handle.low, handle.high, handle.low, flags);
		}
		#end

		return false;
	}

	public function pipelineBarrierImage(image:VKImage, oldLayout:Int, newLayout:Int, srcStageMask:Int, dstStageMask:Int, srcAccessMask:Int,
			dstAccessMask:Int, aspectMask:Int, baseMipLevel:Int = 0, levelCount:Int = 1, baseArrayLayer:Int = 0, layerCount:Int = 1):Bool
	{
		var state = [oldLayout, newLayout, srcStageMask, dstStageMask, srcAccessMask, dstAccessMask, aspectMask, baseMipLevel, levelCount,
			baseArrayLayer, layerCount];

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && image != null && image.isValid())
		{
			return NativeCFFI.lime_vk_cmd_pipeline_barrier_image(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, image.handle.high, image.handle.low, state);
		}
		#end

		return false;
	}

	public function pushConstants(layout:VKPipelineLayout, stageFlags:Int, bytes:haxe.io.Bytes, offset:Int = 0, byteOffset:Int = 0,
			byteLength:Int = -1):Bool
	{
		if (bytes == null || layout == null)
		{
			return false;
		}
		if (byteLength < 0)
		{
			byteLength = bytes.length - byteOffset;
		}
		var state = [stageFlags, offset, byteOffset, byteLength];

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid() && layout.isValid())
		{
			return NativeCFFI.lime_vk_cmd_push_constants(device.instance.context.__windowHandle, device.instance.handle.high,
				device.instance.handle.low, device.handle.high, device.handle.low, handle.high, handle.low, layout.handle.high, layout.handle.low, state,
				bytes);
		}
		#end

		return false;
	}

	public function setScissor(x:Int, y:Int, width:Int, height:Int):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_cmd_set_scissor(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, x, y, width, height);
		}
		#end

		return false;
	}

	public function setViewport(x:Float, y:Float, width:Float, height:Float, minDepth:Float = 0, maxDepth:Float = 1):Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && device != null && device.isValid())
		{
			return NativeCFFI.lime_vk_cmd_set_viewport(device.instance.context.__windowHandle, device.instance.handle.high, device.instance.handle.low,
				device.handle.high, device.handle.low, handle.high, handle.low, x, y, width, height, minDepth, maxDepth);
		}
		#end

		return false;
	}

	@:allow(lime.graphics.vulkan.VKCommandPool)
	private function __invalidate():Void
	{
		handle = Int64.ofInt(0);
	}

	private inline function get_device():VKDevice
	{
		return (pool != null) ? pool.device : null;
	}
}
