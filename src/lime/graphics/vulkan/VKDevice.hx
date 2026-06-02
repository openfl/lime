package lime.graphics.vulkan;

import haxe.Int64;
import haxe.io.Bytes;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
#end

@:access(lime.graphics.VulkanRenderContext)
@:access(lime._internal.backend.native.NativeCFFI)
/**
	A logical Vulkan device created from a `VKPhysicalDevice`.
**/
class VKDevice
{
	public var extensions(default, null):Array<String>;
	public var graphicsQueue(default, null):VKQueue;
	public var handle(default, null):Int64;
	public var instance(default, null):VKInstance;
	public var physicalDevice(default, null):VKPhysicalDevice;
	public var queueFamily(default, null):VKQueueFamilyInfo;

	@:allow(lime.graphics.vulkan.VKPhysicalDevice)
	private function new(physicalDevice:VKPhysicalDevice, queueFamily:VKQueueFamilyInfo, extensions:Array<String>, data:Dynamic)
	{
		this.physicalDevice = physicalDevice;
		this.instance = physicalDevice.instance;
		this.queueFamily = queueFamily;
		this.extensions = extensions.copy();
		handle = VK.__makeHandle(data.handle);
		graphicsQueue = new VKQueue(this, VK.__makeHandle(data.queue), data.queueFamilyIndex, 0);
	}

	public function createCommandPool(queueFamily:VKQueueFamilyInfo = null, flags:Int = VK.COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT):VKCommandPool
	{
		if (queueFamily == null)
		{
			queueFamily = this.queueFamily;
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && queueFamily != null)
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_command_pool(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				handle.high, handle.low, queueFamily.index, flags);
			var commandPoolHandle = VK.__makeHandle(data);
			if (!VK.__isZero(commandPoolHandle))
			{
				return new VKCommandPool(this, queueFamily.index, commandPoolHandle);
			}
		}
		#end

		return null;
	}

	public function createFence(signaled:Bool = false):VKFence
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var flags = signaled ? VK.FENCE_CREATE_SIGNALED_BIT : 0;
			var data:Dynamic = NativeCFFI.lime_vk_create_fence(instance.context.__windowHandle, instance.handle.high, instance.handle.low, handle.high,
				handle.low, flags);
			var fenceHandle = VK.__makeHandle(data);
			if (!VK.__isZero(fenceHandle))
			{
				return new VKFence(this, fenceHandle);
			}
		}
		#end

		return null;
	}

	public function allocateMemory(requirements:VKMemoryRequirements, properties:Int):VKDeviceMemory
	{
		if (requirements == null)
		{
			return null;
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_allocate_memory(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				physicalDevice.handle.high, physicalDevice.handle.low, handle.high, handle.low, requirements.size.high, requirements.size.low,
				requirements.memoryTypeBits, properties);
			var memoryHandle = VK.__makeHandle(data != null ? data.handle : null);
			if (!VK.__isZero(memoryHandle))
			{
				return new VKDeviceMemory(this, memoryHandle, requirements.size, data.memoryTypeIndex, properties);
			}
		}
		#end

		return null;
	}

	public function createBuffer(size:Int64, usage:Int):VKBuffer
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_buffer(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				handle.high, handle.low, size.high, size.low, usage);
			var bufferHandle = VK.__makeHandle(data);
			if (!VK.__isZero(bufferHandle))
			{
				return new VKBuffer(this, bufferHandle, size, usage);
			}
		}
		#end

		return null;
	}

	public function createBufferWithMemory(size:Int64, usage:Int, properties:Int, bytes:Bytes = null):VKBuffer
	{
		var buffer = createBuffer(size, usage);
		if (buffer == null)
		{
			return null;
		}

		var memory = buffer.allocateMemory(properties);
		if (memory == null)
		{
			buffer.dispose();
			return null;
		}

		if (bytes != null && !buffer.upload(bytes))
		{
			buffer.dispose(true);
			return null;
		}

		return buffer;
	}

	public inline function createIndexBuffer(size:Int64, properties:Int, bytes:Bytes = null):VKBuffer
	{
		return createBufferWithMemory(size, VK.BUFFER_USAGE_INDEX_BUFFER_BIT, properties, bytes);
	}

	public inline function createStagingBuffer(size:Int64, bytes:Bytes = null):VKBuffer
	{
		return createBufferWithMemory(size, VK.BUFFER_USAGE_TRANSFER_SRC_BIT,
			VK.MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK.MEMORY_PROPERTY_HOST_COHERENT_BIT, bytes);
	}

	public inline function createUploadRing(byteCapacity:Int, usage:Int = VK.BUFFER_USAGE_TRANSFER_SRC_BIT,
			properties:Int = VK.MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK.MEMORY_PROPERTY_HOST_COHERENT_BIT):VKUploadRing
	{
		return new VKUploadRing(this, byteCapacity, usage, properties);
	}

	public inline function createStorageBuffer(size:Int64, properties:Int, bytes:Bytes = null):VKBuffer
	{
		return createBufferWithMemory(size, VK.BUFFER_USAGE_STORAGE_BUFFER_BIT, properties, bytes);
	}

	public inline function createUniformBuffer(size:Int64, properties:Int, bytes:Bytes = null):VKBuffer
	{
		return createBufferWithMemory(size, VK.BUFFER_USAGE_UNIFORM_BUFFER_BIT, properties, bytes);
	}

	public inline function createVertexBuffer(size:Int64, properties:Int, bytes:Bytes = null):VKBuffer
	{
		return createBufferWithMemory(size, VK.BUFFER_USAGE_VERTEX_BUFFER_BIT, properties, bytes);
	}

	public function createDescriptorPool(maxSets:Int, poolSizes:Array<VKDescriptorPoolSize>, flags:Int = 0):VKDescriptorPool
	{
		var packed = [flags, maxSets, poolSizes != null ? poolSizes.length : 0];
		if (poolSizes != null)
		{
			for (poolSize in poolSizes)
			{
				packed.push(poolSize.descriptorType);
				packed.push(poolSize.descriptorCount);
			}
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_descriptor_pool(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				handle.high, handle.low, packed);
			var descriptorPoolHandle = VK.__makeHandle(data);
			if (!VK.__isZero(descriptorPoolHandle))
			{
				return new VKDescriptorPool(this, descriptorPoolHandle);
			}
		}
		#end

		return null;
	}

	public function createDescriptorSetLayout(bindings:Array<VKDescriptorSetLayoutBinding>, flags:Int = 0):VKDescriptorSetLayout
	{
		var packed = [flags, bindings != null ? bindings.length : 0];
		if (bindings != null)
		{
			for (binding in bindings)
			{
				packed.push(binding.binding);
				packed.push(binding.descriptorType);
				packed.push(binding.descriptorCount);
				packed.push(binding.stageFlags);
			}
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_descriptor_set_layout(instance.context.__windowHandle, instance.handle.high,
				instance.handle.low, handle.high, handle.low, packed);
			var descriptorSetLayoutHandle = VK.__makeHandle(data);
			if (!VK.__isZero(descriptorSetLayoutHandle))
			{
				return new VKDescriptorSetLayout(this, descriptorSetLayoutHandle);
			}
		}
		#end

		return null;
	}

	public function updateDescriptorSets(writes:Array<VKDescriptorWrite>):Bool
	{
		if (writes == null || writes.length == 0)
		{
			return true;
		}

		var packed = [writes.length];
		for (write in writes)
		{
			if (write == null || !write.pack(packed))
			{
				return false;
			}
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			return NativeCFFI.lime_vk_update_descriptor_sets(instance.context.__windowHandle, instance.handle.high, instance.handle.low, handle.high,
				handle.low, packed);
		}
		#end

		return false;
	}

	public function createFramebuffer(renderPass:VKRenderPass, attachments:Array<VKImageView>, width:Int, height:Int, layers:Int = 1):VKFramebuffer
	{
		if (renderPass == null || !renderPass.isValid() || attachments == null || attachments.length == 0)
		{
			return null;
		}

		var packed = [attachments.length];
		for (attachment in attachments)
		{
			if (attachment == null || !attachment.isValid())
			{
				return null;
			}
			packed.push(attachment.handle.high);
			packed.push(attachment.handle.low);
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_framebuffer(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				handle.high, handle.low, renderPass.handle.high, renderPass.handle.low, packed, width, height, layers);
			var framebufferHandle = VK.__makeHandle(data);
			if (!VK.__isZero(framebufferHandle))
			{
				return new VKFramebuffer(this, renderPass, framebufferHandle, width, height);
			}
		}
		#end

		return null;
	}

	public function createGraphicsPipeline(renderPass:VKRenderPass, layout:VKPipelineLayout, vertexShader:VKShaderModule,
			fragmentShader:VKShaderModule, info:VKGraphicsPipelineInfo, cache:VKPipelineCache = null):VKPipeline
	{
		if (renderPass == null || layout == null || vertexShader == null || fragmentShader == null)
		{
			return null;
		}
		if (info == null)
		{
			info = new VKGraphicsPipelineInfo();
		}

		var cacheHandle = cache != null && cache.isValid() ? cache.handle : Int64.ofInt(0);

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && renderPass.isValid() && layout.isValid() && vertexShader.isValid() && fragmentShader.isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_graphics_pipeline(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				handle.high, handle.low, renderPass.handle.high, renderPass.handle.low, layout.handle.high, layout.handle.low,
				vertexShader.handle.high, vertexShader.handle.low, fragmentShader.handle.high, fragmentShader.handle.low, info.pack(cacheHandle));
			var pipelineHandle = VK.__makeHandle(data);
			if (!VK.__isZero(pipelineHandle))
			{
				return new VKPipeline(this, layout, pipelineHandle);
			}
		}
		#end

		return null;
	}

	public function createImage(width:Int, height:Int, format:Int, usage:Int, depth:Int = 1, mipLevels:Int = 1, arrayLayers:Int = 1,
			imageType:Int = VK.IMAGE_TYPE_2D, tiling:Int = VK.IMAGE_TILING_OPTIMAL, samples:Int = VK.SAMPLE_COUNT_1_BIT):VKImage
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_image(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				handle.high, handle.low, width, height, depth, mipLevels, arrayLayers, format, imageType, tiling, usage, samples);
			var imageHandle = VK.__makeHandle(data);
			if (!VK.__isZero(imageHandle))
			{
				return VKImage.createOwned(this, imageHandle, width, height, format);
			}
		}
		#end

		return null;
	}

	public function createPipelineCache(bytes:Bytes = null, byteOffset:Int = 0, byteLength:Int = -1):VKPipelineCache
	{
		if (byteLength < 0 && bytes != null)
		{
			byteLength = bytes.length - byteOffset;
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_pipeline_cache(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				handle.high, handle.low, bytes, byteOffset, byteLength);
			var pipelineCacheHandle = VK.__makeHandle(data);
			if (!VK.__isZero(pipelineCacheHandle))
			{
				return new VKPipelineCache(this, pipelineCacheHandle);
			}
		}
		#end

		return null;
	}

	public function createPipelineLayout(descriptorSetLayouts:Array<VKDescriptorSetLayout> = null, pushConstantStages:Int = 0,
			pushConstantSize:Int = 0):VKPipelineLayout
	{
		var packed = [descriptorSetLayouts != null ? descriptorSetLayouts.length : 0];
		if (descriptorSetLayouts != null)
		{
			for (layout in descriptorSetLayouts)
			{
				if (layout == null || !layout.isValid())
				{
					return null;
				}
				packed.push(layout.handle.high);
				packed.push(layout.handle.low);
			}
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_pipeline_layout(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				handle.high, handle.low, packed, pushConstantStages, pushConstantSize);
			var pipelineLayoutHandle = VK.__makeHandle(data);
			if (!VK.__isZero(pipelineLayoutHandle))
			{
				return new VKPipelineLayout(this, pipelineLayoutHandle);
			}
		}
		#end

		return null;
	}

	public function createRenderPass(colorFormat:Int, depthStencilFormat:Int = VK.FORMAT_UNDEFINED,
			samples:Int = VK.SAMPLE_COUNT_1_BIT, colorLoadOp:Int = VK.ATTACHMENT_LOAD_OP_CLEAR,
			colorStoreOp:Int = VK.ATTACHMENT_STORE_OP_STORE, colorInitialLayout:Int = VK.IMAGE_LAYOUT_UNDEFINED,
			colorFinalLayout:Int = VK.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
			depthInitialLayout:Int = VK.IMAGE_LAYOUT_UNDEFINED,
			depthFinalLayout:Int = VK.IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
			depthLoadOp:Int = VK.ATTACHMENT_LOAD_OP_CLEAR, depthStoreOp:Int = VK.ATTACHMENT_STORE_OP_DONT_CARE,
			resolveFormat:Int = VK.FORMAT_UNDEFINED, resolveLoadOp:Int = VK.ATTACHMENT_LOAD_OP_DONT_CARE,
			resolveStoreOp:Int = VK.ATTACHMENT_STORE_OP_STORE, resolveInitialLayout:Int = VK.IMAGE_LAYOUT_UNDEFINED,
			resolveFinalLayout:Int = VK.IMAGE_LAYOUT_PRESENT_SRC_KHR):VKRenderPass
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var state = [
				colorFormat,
				depthStencilFormat,
				samples,
				colorLoadOp,
				colorStoreOp,
				colorInitialLayout,
				colorFinalLayout,
				depthInitialLayout,
				depthFinalLayout,
				depthLoadOp,
				depthStoreOp,
				resolveFormat,
				resolveLoadOp,
				resolveStoreOp,
				resolveInitialLayout,
				resolveFinalLayout
			];
			var data:Dynamic = NativeCFFI.lime_vk_create_render_pass(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				handle.high, handle.low, state);
			var renderPassHandle = VK.__makeHandle(data);
			if (!VK.__isZero(renderPassHandle))
			{
				return new VKRenderPass(this, renderPassHandle, colorFormat, depthStencilFormat, samples, resolveFormat);
			}
		}
		#end

		return null;
	}

	public function createSampler(filter:Int = VK.FILTER_LINEAR, addressMode:Int = VK.SAMPLER_ADDRESS_MODE_REPEAT,
			mipmapMode:Int = VK.SAMPLER_MIPMAP_MODE_LINEAR, anisotropyEnable:Bool = false, maxAnisotropy:Float = 1,
			compareOp:Int = -1, minLod:Float = 0, maxLod:Float = 0):VKSampler
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_sampler(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				handle.high, handle.low, filter, addressMode, mipmapMode, anisotropyEnable, maxAnisotropy, compareOp, minLod, maxLod);
			var samplerHandle = VK.__makeHandle(data);
			if (!VK.__isZero(samplerHandle))
			{
				return new VKSampler(this, samplerHandle);
			}
		}
		#end

		return null;
	}

	public function createSemaphore():VKSemaphore
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_semaphore(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				handle.high, handle.low);
			var semaphoreHandle = VK.__makeHandle(data);
			if (!VK.__isZero(semaphoreHandle))
			{
				return new VKSemaphore(this, semaphoreHandle);
			}
		}
		#end

		return null;
	}

	public function createShaderModule(bytes:Bytes, byteOffset:Int = 0, byteLength:Int = -1):VKShaderModule
	{
		if (bytes == null)
		{
			return null;
		}
		if (byteLength < 0)
		{
			byteLength = bytes.length - byteOffset;
		}

		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			var data:Dynamic = NativeCFFI.lime_vk_create_shader_module(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				handle.high, handle.low, bytes, byteOffset, byteLength);
			var shaderModuleHandle = VK.__makeHandle(data);
			if (!VK.__isZero(shaderModuleHandle))
			{
				return new VKShaderModule(this, shaderModuleHandle);
			}
		}
		#end

		return null;
	}

	/**
		Creates a swapchain for a window surface. Pass an existing swapchain as
		`oldSwapchain` when recreating resources after a resize.
	**/
	public function createSwapchain(surface:VKSurface, width:Int = 0, height:Int = 0, presentMode:Int = VK.PRESENT_MODE_FIFO_KHR,
			oldSwapchain:VKSwapchain = null):VKSwapchain
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid() && surface != null && surface.isValid() && queueFamily != null)
		{
			var oldSwapchainHandle = (oldSwapchain != null && oldSwapchain.isValid()) ? oldSwapchain.handle : Int64.ofInt(0);
			var data:Dynamic = NativeCFFI.lime_vk_create_swapchain(instance.context.__windowHandle, instance.handle.high, instance.handle.low,
				physicalDevice.handle.high, physicalDevice.handle.low, handle.high, handle.low, surface.high, surface.low, queueFamily.index, width,
				height, presentMode, oldSwapchainHandle.high, oldSwapchainHandle.low);
			var swapchainHandle = VK.__makeHandle(data != null ? data.handle : null);
			if (!VK.__isZero(swapchainHandle))
			{
				return new VKSwapchain(this, surface, data);
			}
		}
		#end

		return null;
	}

	/**
		Destroys the logical device. All resources created from the device should
		be destroyed before calling this method.
	**/
	public function dispose():Void
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			NativeCFFI.lime_vk_destroy_device(instance.context.__windowHandle, instance.handle.high, instance.handle.low, handle.high, handle.low);
			handle = Int64.ofInt(0);
			graphicsQueue = null;
		}
		#end
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
		Blocks until the logical device has completed all submitted work.
	**/
	public function waitIdle():Bool
	{
		#if (!macro && lime_cffi && lime_vulkan)
		if (isValid())
		{
			return NativeCFFI.lime_vk_device_wait_idle(instance.context.__windowHandle, instance.handle.high, instance.handle.low, handle.high, handle.low);
		}
		#end

		return false;
	}
}
