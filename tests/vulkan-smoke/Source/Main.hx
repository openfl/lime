package;

import haxe.Int64;
import haxe.Timer;
import haxe.io.Bytes;
import lime.app.Application;
import lime.graphics.RenderContext;
import lime.graphics.RenderContextType;
import lime.graphics.VulkanRenderContext;
import lime.graphics.vulkan.VK;
import lime.graphics.vulkan.VKBuffer;
import lime.graphics.vulkan.VKCommandBuffer;
import lime.graphics.vulkan.VKCommandPool;
import lime.graphics.vulkan.VKDescriptorPool;
import lime.graphics.vulkan.VKDescriptorPoolSize;
import lime.graphics.vulkan.VKDescriptorSet;
import lime.graphics.vulkan.VKDescriptorSetLayout;
import lime.graphics.vulkan.VKDescriptorSetLayoutBinding;
import lime.graphics.vulkan.VKDevice;
import lime.graphics.vulkan.VKFence;
import lime.graphics.vulkan.VKFramebuffer;
import lime.graphics.vulkan.VKGraphicsPipelineInfo;
import lime.graphics.vulkan.VKImage;
import lime.graphics.vulkan.VKImageView;
import lime.graphics.vulkan.VKInstance;
import lime.graphics.vulkan.VKPhysicalDevice;
import lime.graphics.vulkan.VKPipeline;
import lime.graphics.vulkan.VKPipelineLayout;
import lime.graphics.vulkan.VKQueueFamilyInfo;
import lime.graphics.vulkan.VKRenderPass;
import lime.graphics.vulkan.VKSampler;
import lime.graphics.vulkan.VKSemaphore;
import lime.graphics.vulkan.VKShaderModule;
import lime.graphics.vulkan.VKSurface;
import lime.graphics.vulkan.VKSwapchain;
import lime.graphics.vulkan.VKVertexAttribute;
import lime.graphics.vulkan.VKVertexBinding;
import lime.system.System;
import lime.utils.Assets;

class Main extends Application
{
	private static inline var DEPTH_FORMAT = VK.FORMAT_D32_SFLOAT;
	private static inline var OFFSCREEN_FORMAT = VK.FORMAT_R8G8B8A8_UNORM;
	private static inline var OFFSCREEN_SIZE = 256;
	private static inline var REQUESTED_MSAA_SAMPLES = VK.SAMPLE_COUNT_4_BIT;

	private var colorImage:VKImage;
	private var colorView:VKImageView;
	private var commandBuffer:VKCommandBuffer;
	private var commandPool:VKCommandPool;
	private var cubeDescriptorSet:VKDescriptorSet;
	private var cubeDescriptorSetLayout:VKDescriptorSetLayout;
	private var cubeFragmentShader:VKShaderModule;
	private var cubeIndexBuffer:VKBuffer;
	private var cubePipeline:VKPipeline;
	private var cubePipelineLayout:VKPipelineLayout;
	private var cubeVertexBuffer:VKBuffer;
	private var cubeVertexShader:VKShaderModule;
	private var depthImage:VKImage;
	private var depthView:VKImageView;
	private var descriptorPool:VKDescriptorPool;
	private var device:VKDevice;
	private var fence:VKFence;
	private var finished:Bool;
	private var framebuffers:Array<VKFramebuffer> = [];
	private var imageAvailable:VKSemaphore;
	private var imageViews:Array<VKImageView> = [];
	private var instance:VKInstance;
	private var offscreenDescriptorSet:VKDescriptorSet;
	private var offscreenDescriptorSetLayout:VKDescriptorSetLayout;
	private var offscreenFramebuffer:VKFramebuffer;
	private var offscreenImage:VKImage;
	private var offscreenPipeline:VKPipeline;
	private var offscreenPipelineLayout:VKPipelineLayout;
	private var offscreenRenderPass:VKRenderPass;
	private var offscreenSampler:VKSampler;
	private var offscreenView:VKImageView;
	private var physicalDevice:VKPhysicalDevice;
	private var preloadComplete:Bool;
	private var quadFragmentShader:VKShaderModule;
	private var quadIndexBuffer:VKBuffer;
	private var quadVertexBuffer:VKBuffer;
	private var quadVertexShader:VKShaderModule;
	private var queueFamily:VKQueueFamilyInfo;
	private var renderFinished:VKSemaphore;
	private var renderPass:VKRenderPass;
	private var msaaSamples:Int = VK.SAMPLE_COUNT_1_BIT;
	private var sourceTextureImage:VKImage;
	private var sourceTextureSampler:VKSampler;
	private var sourceTextureView:VKImageView;
	private var surface:VKSurface;
	private var swapchain:VKSwapchain;
	private var uniformBuffer:VKBuffer;
	private var windowCreated:Bool;

	public function new()
	{
		super();
	}

	override public function onWindowCreate():Void
	{
		super.onWindowCreate();

		if (window == null)
		{
			fail("Missing primary window");
			return;
		}

		if (window.context == null || window.context.type != RenderContextType.VULKAN || window.context.vulkan == null)
		{
			fail("Primary window was not created with a Vulkan context");
			return;
		}

		windowCreated = true;
		tryCreateRenderer();
	}

	override public function onPreloadComplete():Void
	{
		super.onPreloadComplete();

		preloadComplete = true;
		tryCreateRenderer();
	}

	override public function onWindowResize(width:Int, height:Int):Void
	{
		super.onWindowResize(width, height);

		if (!finished && device != null && device.isValid() && width > 0 && height > 0)
		{
			recreateSwapchain(width, height);
		}
	}

	override public function render(context:RenderContext):Void
	{
		super.render(context);

		if (finished || device == null)
		{
			return;
		}

		if (!drawFrame())
		{
			return;
		}

		finished = true;
		Timer.delay(complete, 50);
	}

	private function createRenderer(context:VulkanRenderContext):Void
	{
		var extensions = context.getInstanceExtensions();
		if (extensions == null || extensions.length == 0)
		{
			fail("No Vulkan instance extensions were reported");
			return;
		}

		var procAddr = context.getInstanceProcAddr();
		if (!isNonZero(procAddr))
		{
			fail("vkGetInstanceProcAddr was not available");
			return;
		}

		instance = VK.createInstance(context, "LimeVulkanSmoke");
		if (instance == null || !instance.isValid())
		{
			fail("Failed to create Vulkan instance: " + VK.getLastError());
			return;
		}

		surface = instance.createSurface();
		if (surface == null || !surface.isValid())
		{
			fail("Failed to create Vulkan surface");
			return;
		}

		physicalDevice = instance.pickPhysicalDevice(surface);
		if (physicalDevice == null || !physicalDevice.hasQueueFamily(true, true))
		{
			fail("No present-capable graphics queue family was found");
			return;
		}
		msaaSamples = physicalDevice.supportsSampleCount(REQUESTED_MSAA_SAMPLES, true) ? REQUESTED_MSAA_SAMPLES : VK.SAMPLE_COUNT_1_BIT;

		queueFamily = physicalDevice.getQueueFamily(true, true);
		device = physicalDevice.createDevice(queueFamily);
		if (device == null || !device.isValid() || device.graphicsQueue == null || !device.graphicsQueue.isValid())
		{
			fail("Failed to create Vulkan logical device: " + VK.getLastError());
			return;
		}

		commandPool = device.createCommandPool(queueFamily);
		commandBuffer = commandPool != null ? commandPool.allocateCommandBuffer() : null;
		imageAvailable = device.createSemaphore();
		renderFinished = device.createSemaphore();
		fence = device.createFence(true);

		if (commandPool == null || commandBuffer == null || imageAvailable == null || renderFinished == null || fence == null)
		{
			fail("Failed to create Vulkan frame synchronization resources: " + VK.getLastError());
			return;
		}

		swapchain = device.createSwapchain(surface, window.width, window.height);
		if (swapchain == null || !swapchain.isValid() || swapchain.images.length == 0)
		{
			fail("Failed to create Vulkan swapchain: " + VK.getLastError());
			return;
		}

		if (!createSourceTexture()
			|| !createGeometry()
			|| !createDescriptorLayouts()
			|| !createOffscreenPass()
			|| !createOnscreenPass())
		{
			return;
		}
	}

	private function tryCreateRenderer():Void
	{
		if (device != null || !windowCreated || !preloadComplete || window == null || window.context == null || window.context.vulkan == null)
		{
			return;
		}

		createRenderer(window.context.vulkan);
	}

	private function createSourceTexture():Bool
	{
		sourceTextureImage = device.createImage(2, 2, OFFSCREEN_FORMAT, VK.IMAGE_USAGE_TRANSFER_DST_BIT | VK.IMAGE_USAGE_SAMPLED_BIT);
		if (sourceTextureImage == null || sourceTextureImage.allocateMemory(VK.MEMORY_PROPERTY_DEVICE_LOCAL_BIT) == null)
		{
			fail("Failed to create Vulkan texture image: " + VK.getLastError());
			return false;
		}

		var pixels = Bytes.alloc(16);
		var values = [
			0xFF, 0x90, 0x20, 0xFF,
			0x10, 0xD8, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF,
			0x20, 0x40, 0xFF, 0xFF
		];
		for (i in 0...values.length)
		{
			pixels.set(i, values[i]);
		}

		var staging = device.createStagingBuffer(Int64.ofInt(pixels.length), pixels);
		if (staging == null)
		{
			fail("Failed to create Vulkan texture staging buffer: " + VK.getLastError());
			return false;
		}

		if (!commandBuffer.reset()
			|| !commandBuffer.begin(VK.COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT)
			|| !commandBuffer.pipelineBarrierImage(sourceTextureImage, VK.IMAGE_LAYOUT_UNDEFINED, VK.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
				VK.PIPELINE_STAGE_TOP_OF_PIPE_BIT, VK.PIPELINE_STAGE_TRANSFER_BIT, 0, VK.ACCESS_TRANSFER_WRITE_BIT, VK.IMAGE_ASPECT_COLOR_BIT)
			|| !commandBuffer.copyBufferToImage(staging, sourceTextureImage, 2, 2)
			|| !commandBuffer.pipelineBarrierImage(sourceTextureImage, VK.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, VK.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
				VK.PIPELINE_STAGE_TRANSFER_BIT, VK.PIPELINE_STAGE_FRAGMENT_SHADER_BIT, VK.ACCESS_TRANSFER_WRITE_BIT, VK.ACCESS_SHADER_READ_BIT,
				VK.IMAGE_ASPECT_COLOR_BIT)
			|| !commandBuffer.end())
		{
			staging.dispose(true);
			fail("Failed to record Vulkan texture upload commands: " + VK.getLastError());
			return false;
		}

		if (!fence.waitForever() || !fence.reset() || !device.graphicsQueue.submit(commandBuffer, fence) || !fence.waitForever())
		{
			staging.dispose(true);
			fail("Failed to submit Vulkan texture upload: " + VK.getLastError());
			return false;
		}

		staging.dispose(true);

		sourceTextureView = sourceTextureImage.createView(OFFSCREEN_FORMAT);
		sourceTextureSampler = device.createSampler(VK.FILTER_NEAREST, VK.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE, VK.SAMPLER_MIPMAP_MODE_NEAREST);

		if (sourceTextureView == null || sourceTextureSampler == null)
		{
			fail("Failed to create Vulkan texture view/sampler: " + VK.getLastError());
			return false;
		}

		return true;
	}

	private function createGeometry():Bool
	{
		if (!createQuadGeometry() || !createCubeGeometry())
		{
			return false;
		}

		uniformBuffer = device.createUniformBuffer(Int64.ofInt(64), VK.MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK.MEMORY_PROPERTY_HOST_COHERENT_BIT);
		if (uniformBuffer == null)
		{
			fail("Failed to create Vulkan uniform buffer: " + VK.getLastError());
			return false;
		}

		return true;
	}

	private function createQuadGeometry():Bool
	{
		var vertices = Bytes.alloc(4 * 32);
		var data = [
			-0.72, -0.72, 0.0, 1.0, 1.0, 1.0, 1.0, 0.86,
			 0.72, -0.72, 1.0, 1.0, 1.0, 1.0, 1.0, 0.86,
			 0.72,  0.72, 1.0, 0.0, 1.0, 1.0, 1.0, 0.86,
			-0.72,  0.72, 0.0, 0.0, 1.0, 1.0, 1.0, 0.86
		];
		for (i in 0...data.length)
		{
			vertices.setFloat(i * 4, data[i]);
		}

		var indices = Bytes.alloc(6 * 2);
		var indexData = [0, 1, 2, 2, 3, 0];
		for (i in 0...indexData.length)
		{
			indices.setUInt16(i * 2, indexData[i]);
		}

		quadVertexBuffer = device.createVertexBuffer(Int64.ofInt(vertices.length), VK.MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK.MEMORY_PROPERTY_HOST_COHERENT_BIT,
			vertices);
		quadIndexBuffer = device.createIndexBuffer(Int64.ofInt(indices.length), VK.MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK.MEMORY_PROPERTY_HOST_COHERENT_BIT,
			indices);

		if (quadVertexBuffer == null || quadIndexBuffer == null)
		{
			fail("Failed to create Vulkan quad buffers: " + VK.getLastError());
			return false;
		}

		return true;
	}

	private function createCubeGeometry():Bool
	{
		var vertexData = [
			-1.0, -1.0,  1.0, 0.0, 1.0,  1.0, 0.85, 0.55, 1.0,
			 1.0, -1.0,  1.0, 1.0, 1.0,  1.0, 0.85, 0.55, 1.0,
			 1.0,  1.0,  1.0, 1.0, 0.0,  1.0, 0.85, 0.55, 1.0,
			-1.0,  1.0,  1.0, 0.0, 0.0,  1.0, 0.85, 0.55, 1.0,
			 1.0, -1.0, -1.0, 0.0, 1.0, 0.55,  0.8,  1.0, 1.0,
			-1.0, -1.0, -1.0, 1.0, 1.0, 0.55,  0.8,  1.0, 1.0,
			-1.0,  1.0, -1.0, 1.0, 0.0, 0.55,  0.8,  1.0, 1.0,
			 1.0,  1.0, -1.0, 0.0, 0.0, 0.55,  0.8,  1.0, 1.0,
			-1.0, -1.0, -1.0, 0.0, 1.0, 0.75,  1.0, 0.65, 1.0,
			-1.0, -1.0,  1.0, 1.0, 1.0, 0.75,  1.0, 0.65, 1.0,
			-1.0,  1.0,  1.0, 1.0, 0.0, 0.75,  1.0, 0.65, 1.0,
			-1.0,  1.0, -1.0, 0.0, 0.0, 0.75,  1.0, 0.65, 1.0,
			 1.0, -1.0,  1.0, 0.0, 1.0,  1.0, 0.75,  0.6, 1.0,
			 1.0, -1.0, -1.0, 1.0, 1.0,  1.0, 0.75,  0.6, 1.0,
			 1.0,  1.0, -1.0, 1.0, 0.0,  1.0, 0.75,  0.6, 1.0,
			 1.0,  1.0,  1.0, 0.0, 0.0,  1.0, 0.75,  0.6, 1.0,
			-1.0,  1.0,  1.0, 0.0, 1.0, 0.65, 0.95,  1.0, 1.0,
			 1.0,  1.0,  1.0, 1.0, 1.0, 0.65, 0.95,  1.0, 1.0,
			 1.0,  1.0, -1.0, 1.0, 0.0, 0.65, 0.95,  1.0, 1.0,
			-1.0,  1.0, -1.0, 0.0, 0.0, 0.65, 0.95,  1.0, 1.0,
			-1.0, -1.0, -1.0, 0.0, 1.0,  1.0, 0.65, 0.75, 1.0,
			 1.0, -1.0, -1.0, 1.0, 1.0,  1.0, 0.65, 0.75, 1.0,
			 1.0, -1.0,  1.0, 1.0, 0.0,  1.0, 0.65, 0.75, 1.0,
			-1.0, -1.0,  1.0, 0.0, 0.0,  1.0, 0.65, 0.75, 1.0
		];

		var indexData = [
			 0,  1,  2,  2,  3,  0,
			 4,  5,  6,  6,  7,  4,
			 8,  9, 10, 10, 11,  8,
			12, 13, 14, 14, 15, 12,
			16, 17, 18, 18, 19, 16,
			20, 21, 22, 22, 23, 20
		];

		var vertices = Bytes.alloc(vertexData.length * 4);
		for (i in 0...vertexData.length)
		{
			vertices.setFloat(i * 4, vertexData[i]);
		}

		var indices = Bytes.alloc(indexData.length * 2);
		for (i in 0...indexData.length)
		{
			indices.setUInt16(i * 2, indexData[i]);
		}

		cubeVertexBuffer = device.createVertexBuffer(Int64.ofInt(vertices.length), VK.MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK.MEMORY_PROPERTY_HOST_COHERENT_BIT,
			vertices);
		cubeIndexBuffer = device.createIndexBuffer(Int64.ofInt(indices.length), VK.MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK.MEMORY_PROPERTY_HOST_COHERENT_BIT,
			indices);

		if (cubeVertexBuffer == null || cubeIndexBuffer == null)
		{
			fail("Failed to create Vulkan cube buffers: " + VK.getLastError());
			return false;
		}

		return true;
	}

	private function createDescriptorLayouts():Bool
	{
		offscreenDescriptorSetLayout = device.createDescriptorSetLayout([
			new VKDescriptorSetLayoutBinding(0, VK.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, VK.SHADER_STAGE_FRAGMENT_BIT)
		]);
		cubeDescriptorSetLayout = device.createDescriptorSetLayout([
			new VKDescriptorSetLayoutBinding(0, VK.DESCRIPTOR_TYPE_UNIFORM_BUFFER, VK.SHADER_STAGE_VERTEX_BIT),
			new VKDescriptorSetLayoutBinding(1, VK.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, VK.SHADER_STAGE_FRAGMENT_BIT)
		]);
		descriptorPool = device.createDescriptorPool(2, [
			new VKDescriptorPoolSize(VK.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 2),
			new VKDescriptorPoolSize(VK.DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1)
		]);

		if (offscreenDescriptorSetLayout == null || cubeDescriptorSetLayout == null || descriptorPool == null)
		{
			fail("Failed to create Vulkan descriptor layouts: " + VK.getLastError());
			return false;
		}

		return true;
	}

	private function createOffscreenPass():Bool
	{
		offscreenRenderPass = device.createRenderPass(OFFSCREEN_FORMAT, VK.FORMAT_UNDEFINED, VK.SAMPLE_COUNT_1_BIT, VK.ATTACHMENT_LOAD_OP_CLEAR,
			VK.ATTACHMENT_STORE_OP_STORE, VK.IMAGE_LAYOUT_UNDEFINED, VK.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
		offscreenImage = device.createImage(OFFSCREEN_SIZE, OFFSCREEN_SIZE, OFFSCREEN_FORMAT,
			VK.IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK.IMAGE_USAGE_SAMPLED_BIT | VK.IMAGE_USAGE_TRANSFER_SRC_BIT);

		if (offscreenRenderPass == null
			|| offscreenImage == null
			|| offscreenImage.allocateMemory(VK.MEMORY_PROPERTY_DEVICE_LOCAL_BIT) == null)
		{
			fail("Failed to create Vulkan offscreen render target: " + VK.getLastError());
			return false;
		}

		offscreenView = offscreenImage.createView(OFFSCREEN_FORMAT);
		offscreenSampler = device.createSampler(VK.FILTER_LINEAR, VK.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE, VK.SAMPLER_MIPMAP_MODE_LINEAR);
		offscreenFramebuffer = offscreenView != null ? device.createFramebuffer(offscreenRenderPass, [offscreenView], OFFSCREEN_SIZE, OFFSCREEN_SIZE) : null;

		offscreenDescriptorSet = descriptorPool.allocate(offscreenDescriptorSetLayout);
		offscreenPipelineLayout = device.createPipelineLayout([offscreenDescriptorSetLayout]);
		quadVertexShader = device.createShaderModule(Assets.getBytes("Assets/shaders/quad.vert.spv"));
		quadFragmentShader = device.createShaderModule(Assets.getBytes("Assets/shaders/quad.frag.spv"));

		if (offscreenView == null
			|| offscreenSampler == null
			|| offscreenFramebuffer == null
			|| offscreenDescriptorSet == null
			|| offscreenPipelineLayout == null
			|| quadVertexShader == null
			|| quadFragmentShader == null
			|| !offscreenDescriptorSet.updateImage(0, sourceTextureView, sourceTextureSampler))
		{
			fail("Failed to create Vulkan offscreen pipeline resources: " + VK.getLastError());
			return false;
		}

		var info = new VKGraphicsPipelineInfo();
		info.blend = true;
		info.cullMode = VK.CULL_MODE_NONE;
		info.vertexBindings.push(new VKVertexBinding(0, 32, VK.VERTEX_INPUT_RATE_VERTEX));
		info.vertexAttributes.push(new VKVertexAttribute(0, 0, VK.FORMAT_R32G32_SFLOAT, 0));
		info.vertexAttributes.push(new VKVertexAttribute(1, 0, VK.FORMAT_R32G32_SFLOAT, 8));
		info.vertexAttributes.push(new VKVertexAttribute(2, 0, VK.FORMAT_R32G32B32A32_SFLOAT, 16));

		offscreenPipeline = device.createGraphicsPipeline(offscreenRenderPass, offscreenPipelineLayout, quadVertexShader, quadFragmentShader, info);
		if (offscreenPipeline == null)
		{
			fail("Failed to create Vulkan offscreen graphics pipeline: " + VK.getLastError());
			return false;
		}

		return true;
	}

	private function createOnscreenPass():Bool
	{
		if (msaaSamples != VK.SAMPLE_COUNT_1_BIT)
		{
			renderPass = device.createRenderPass(swapchain.format, DEPTH_FORMAT, msaaSamples, VK.ATTACHMENT_LOAD_OP_CLEAR, VK.ATTACHMENT_STORE_OP_DONT_CARE,
				VK.IMAGE_LAYOUT_UNDEFINED, VK.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, VK.IMAGE_LAYOUT_UNDEFINED,
				VK.IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL, VK.ATTACHMENT_LOAD_OP_CLEAR, VK.ATTACHMENT_STORE_OP_DONT_CARE, swapchain.format,
				VK.ATTACHMENT_LOAD_OP_DONT_CARE, VK.ATTACHMENT_STORE_OP_STORE, VK.IMAGE_LAYOUT_UNDEFINED, VK.IMAGE_LAYOUT_PRESENT_SRC_KHR);
		}
		else
		{
			renderPass = device.createRenderPass(swapchain.format, DEPTH_FORMAT, VK.SAMPLE_COUNT_1_BIT, VK.ATTACHMENT_LOAD_OP_CLEAR,
				VK.ATTACHMENT_STORE_OP_STORE, VK.IMAGE_LAYOUT_UNDEFINED, VK.IMAGE_LAYOUT_PRESENT_SRC_KHR);
		}

		if (renderPass == null || !createColorResources() || !createDepthResources() || !createFramebuffers())
		{
			fail("Failed to create Vulkan onscreen render pass resources: " + VK.getLastError());
			return false;
		}

		cubeDescriptorSet = descriptorPool.allocate(cubeDescriptorSetLayout);
		cubePipelineLayout = device.createPipelineLayout([cubeDescriptorSetLayout]);
		cubeVertexShader = device.createShaderModule(Assets.getBytes("Assets/shaders/cube.vert.spv"));
		cubeFragmentShader = device.createShaderModule(Assets.getBytes("Assets/shaders/cube.frag.spv"));

		if (cubeDescriptorSet == null
			|| cubePipelineLayout == null
			|| cubeVertexShader == null
			|| cubeFragmentShader == null
			|| !cubeDescriptorSet.updateBuffer(0, uniformBuffer, 64)
			|| !cubeDescriptorSet.updateImage(1, offscreenView, offscreenSampler))
		{
			fail("Failed to create Vulkan cube descriptor resources: " + VK.getLastError());
			return false;
		}

		var info = new VKGraphicsPipelineInfo();
		info.depthTest = true;
		info.depthWrite = true;
		info.depthCompareOp = VK.COMPARE_OP_LESS;
		info.cullMode = VK.CULL_MODE_BACK_BIT;
		info.frontFace = VK.FRONT_FACE_CLOCKWISE;
		info.rasterizationSamples = msaaSamples;
		info.vertexBindings.push(new VKVertexBinding(0, 36, VK.VERTEX_INPUT_RATE_VERTEX));
		info.vertexAttributes.push(new VKVertexAttribute(0, 0, VK.FORMAT_R32G32B32_SFLOAT, 0));
		info.vertexAttributes.push(new VKVertexAttribute(1, 0, VK.FORMAT_R32G32_SFLOAT, 12));
		info.vertexAttributes.push(new VKVertexAttribute(2, 0, VK.FORMAT_R32G32B32A32_SFLOAT, 20));

		cubePipeline = device.createGraphicsPipeline(renderPass, cubePipelineLayout, cubeVertexShader, cubeFragmentShader, info);
		if (cubePipeline == null)
		{
			fail("Failed to create Vulkan cube graphics pipeline: " + VK.getLastError());
			return false;
		}

		return true;
	}

	private function createColorResources():Bool
	{
		disposeColorResources();

		if (msaaSamples == VK.SAMPLE_COUNT_1_BIT)
		{
			return true;
		}

		colorImage = device.createImage(swapchain.width, swapchain.height, swapchain.format,
			VK.IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK.IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT, 1, 1, 1, VK.IMAGE_TYPE_2D, VK.IMAGE_TILING_OPTIMAL, msaaSamples);
		if (colorImage == null || colorImage.allocateMemory(VK.MEMORY_PROPERTY_DEVICE_LOCAL_BIT) == null)
		{
			return false;
		}

		colorView = colorImage.createView(swapchain.format);
		return colorView != null;
	}

	private function createDepthResources():Bool
	{
		disposeDepthResources();

		depthImage = device.createImage(swapchain.width, swapchain.height, DEPTH_FORMAT, VK.IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT, 1, 1, 1,
			VK.IMAGE_TYPE_2D, VK.IMAGE_TILING_OPTIMAL, msaaSamples);
		if (depthImage == null || depthImage.allocateMemory(VK.MEMORY_PROPERTY_DEVICE_LOCAL_BIT) == null)
		{
			return false;
		}

		depthView = depthImage.createView(DEPTH_FORMAT, VK.IMAGE_ASPECT_DEPTH_BIT);
		return depthView != null;
	}

	private function createFramebuffers():Bool
	{
		disposeSwapchainFramebuffers();

		for (image in swapchain.images)
		{
			var imageView = image.createView(swapchain.format);
			if (imageView == null)
			{
				fail("Failed to create Vulkan swapchain image view: " + VK.getLastError());
				return false;
			}

			var attachments = msaaSamples != VK.SAMPLE_COUNT_1_BIT ? [colorView, depthView, imageView] : [imageView, depthView];
			var framebuffer = device.createFramebuffer(renderPass, attachments, swapchain.width, swapchain.height);
			if (framebuffer == null)
			{
				imageView.dispose();
				fail("Failed to create Vulkan framebuffer: " + VK.getLastError());
				return false;
			}

			imageViews.push(imageView);
			framebuffers.push(framebuffer);
		}

		return true;
	}

	private function drawFrame():Bool
	{
		if (!fence.waitForever())
		{
			fail("Failed to wait for Vulkan frame fence: " + VK.getLastError());
			return false;
		}

		var acquired = swapchain.acquireNextImage(imageAvailable);
		if (acquired.result == VK.ERROR_OUT_OF_DATE_KHR)
		{
			return recreateSwapchain(window.width, window.height);
		}
		if (!acquired.isSuccess())
		{
			fail("Failed to acquire Vulkan swapchain image: " + VK.getLastError());
			return false;
		}

		var framebuffer = framebuffers[acquired.imageIndex];
		if (framebuffer == null)
		{
			fail("Swapchain image did not have a framebuffer");
			return false;
		}

		if (!updateCubeUniform())
		{
			fail("Failed to update Vulkan uniform buffer: " + VK.getLastError());
			return false;
		}

		if (!commandBuffer.reset()
			|| !commandBuffer.begin(VK.COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT)
			|| !commandBuffer.beginRenderPass(offscreenRenderPass, offscreenFramebuffer, OFFSCREEN_SIZE, OFFSCREEN_SIZE, 0.02, 0.04, 0.07, 1.0)
			|| !commandBuffer.setViewport(0, 0, OFFSCREEN_SIZE, OFFSCREEN_SIZE)
			|| !commandBuffer.setScissor(0, 0, OFFSCREEN_SIZE, OFFSCREEN_SIZE)
			|| !commandBuffer.bindPipeline(offscreenPipeline)
			|| !commandBuffer.bindDescriptorSet(offscreenPipelineLayout, offscreenDescriptorSet)
			|| !commandBuffer.bindVertexBuffer(quadVertexBuffer)
			|| !commandBuffer.bindIndexBuffer(quadIndexBuffer)
			|| !commandBuffer.drawIndexed(6)
			|| !commandBuffer.endRenderPass()
			|| !commandBuffer.pipelineBarrierImage(offscreenImage, VK.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
				VK.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, VK.PIPELINE_STAGE_FRAGMENT_SHADER_BIT, VK.ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
				VK.ACCESS_SHADER_READ_BIT, VK.IMAGE_ASPECT_COLOR_BIT)
			|| !commandBuffer.beginRenderPass(renderPass, framebuffer, swapchain.width, swapchain.height, 0.07, 0.08, 0.09, 1.0, 1.0)
			|| !commandBuffer.setViewport(0, 0, swapchain.width, swapchain.height)
			|| !commandBuffer.setScissor(0, 0, swapchain.width, swapchain.height)
			|| !commandBuffer.bindPipeline(cubePipeline)
			|| !commandBuffer.bindDescriptorSet(cubePipelineLayout, cubeDescriptorSet)
			|| !commandBuffer.bindVertexBuffer(cubeVertexBuffer)
			|| !commandBuffer.bindIndexBuffer(cubeIndexBuffer)
			|| !commandBuffer.drawIndexed(36)
			|| !commandBuffer.endRenderPass()
			|| !commandBuffer.end())
		{
			fail("Failed to record Vulkan draw commands: " + VK.getLastError());
			return false;
		}

		if (!fence.reset()
			|| !device.graphicsQueue.submitSynced(commandBuffer, imageAvailable, renderFinished, fence)
			|| !fence.waitForever())
		{
			fail("Failed to submit Vulkan draw commands: " + VK.getLastError());
			return false;
		}

		var presentResult = device.graphicsQueue.present(swapchain, acquired.imageIndex, renderFinished);
		if (presentResult == VK.ERROR_OUT_OF_DATE_KHR)
		{
			return recreateSwapchain(window.width, window.height);
		}
		if (presentResult != VK.SUCCESS && presentResult != VK.SUBOPTIMAL_KHR)
		{
			fail("Failed to present Vulkan swapchain image: " + VK.getLastError());
			return false;
		}

		return true;
	}

	private function updateCubeUniform():Bool
	{
		var aspect = swapchain.height > 0 ? swapchain.width / swapchain.height : 1.0;
		var angle = Timer.stamp();
		var model = multiply(rotationY(angle), rotationX(angle * 0.61));
		var view = translation(0, 0, -4.25);
		var projection = perspective(Math.PI / 3, aspect, 0.1, 100);
		var mvp = multiply(projection, multiply(view, model));
		var bytes = Bytes.alloc(64);

		for (i in 0...16)
		{
			bytes.setFloat(i * 4, mvp[i]);
		}

		return uniformBuffer.upload(bytes);
	}

	private function recreateSwapchain(width:Int, height:Int):Bool
	{
		if (width <= 0 || height <= 0 || swapchain == null)
		{
			return false;
		}

		if (!device.waitIdle())
		{
			fail("Failed to idle Vulkan device before swapchain recreation: " + VK.getLastError());
			return false;
		}

		disposeSwapchainResources();
		var oldSwapchain = swapchain;
		swapchain = oldSwapchain.recreate(width, height);
		oldSwapchain.dispose();

		if (swapchain == null || !swapchain.isValid() || swapchain.images.length == 0)
		{
			fail("Failed to recreate Vulkan swapchain: " + VK.getLastError());
			return false;
		}

		return createColorResources() && createDepthResources() && createFramebuffers();
	}

	private function disposeSwapchainResources():Void
	{
		disposeSwapchainFramebuffers();
		disposeColorResources();
		disposeDepthResources();
	}

	private function disposeSwapchainFramebuffers():Void
	{
		for (framebuffer in framebuffers)
		{
			if (framebuffer != null)
			{
				framebuffer.dispose();
			}
		}
		framebuffers = [];

		for (imageView in imageViews)
		{
			if (imageView != null)
			{
				imageView.dispose();
			}
		}
		imageViews = [];
	}

	private function disposeColorResources():Void
	{
		if (colorView != null)
		{
			colorView.dispose();
			colorView = null;
		}
		if (colorImage != null)
		{
			colorImage.dispose(true);
			colorImage = null;
		}
	}

	private function disposeDepthResources():Void
	{
		if (depthView != null)
		{
			depthView.dispose();
			depthView = null;
		}
		if (depthImage != null)
		{
			depthImage.dispose(true);
			depthImage = null;
		}
	}

	private function complete():Void
	{
		disposeRenderer();

		if (window != null)
		{
			window.close();
		}
		System.exit(0);
	}

	private function disposeRenderer():Void
	{
		if (device != null && device.isValid())
		{
			device.waitIdle();
		}

		disposeSwapchainResources();
		if (offscreenFramebuffer != null) offscreenFramebuffer.dispose();
		if (offscreenView != null) offscreenView.dispose();
		if (offscreenImage != null) offscreenImage.dispose(true);
		if (offscreenSampler != null) offscreenSampler.dispose();
		if (cubeIndexBuffer != null) cubeIndexBuffer.dispose(true);
		if (cubeVertexBuffer != null) cubeVertexBuffer.dispose(true);
		if (quadIndexBuffer != null) quadIndexBuffer.dispose(true);
		if (quadVertexBuffer != null) quadVertexBuffer.dispose(true);
		if (uniformBuffer != null) uniformBuffer.dispose(true);
		if (cubePipeline != null) cubePipeline.dispose();
		if (cubePipelineLayout != null) cubePipelineLayout.dispose();
		if (offscreenPipeline != null) offscreenPipeline.dispose();
		if (offscreenPipelineLayout != null) offscreenPipelineLayout.dispose();
		if (descriptorPool != null) descriptorPool.dispose();
		if (cubeDescriptorSetLayout != null) cubeDescriptorSetLayout.dispose();
		if (offscreenDescriptorSetLayout != null) offscreenDescriptorSetLayout.dispose();
		if (sourceTextureSampler != null) sourceTextureSampler.dispose();
		if (sourceTextureView != null) sourceTextureView.dispose();
		if (sourceTextureImage != null) sourceTextureImage.dispose(true);
		if (cubeFragmentShader != null) cubeFragmentShader.dispose();
		if (cubeVertexShader != null) cubeVertexShader.dispose();
		if (quadFragmentShader != null) quadFragmentShader.dispose();
		if (quadVertexShader != null) quadVertexShader.dispose();
		if (renderPass != null) renderPass.dispose();
		if (offscreenRenderPass != null) offscreenRenderPass.dispose();
		if (fence != null) fence.dispose();
		if (renderFinished != null) renderFinished.dispose();
		if (imageAvailable != null) imageAvailable.dispose();
		if (commandBuffer != null) commandBuffer.dispose();
		if (commandPool != null) commandPool.dispose();
		if (swapchain != null) swapchain.dispose();
		if (device != null) device.dispose();
		if (surface != null) surface.dispose();
		if (instance != null) instance.dispose();

		commandBuffer = null;
		commandPool = null;
		colorImage = null;
		colorView = null;
		cubeDescriptorSet = null;
		cubeDescriptorSetLayout = null;
		cubeFragmentShader = null;
		cubeIndexBuffer = null;
		cubePipeline = null;
		cubePipelineLayout = null;
		cubeVertexBuffer = null;
		cubeVertexShader = null;
		descriptorPool = null;
		device = null;
		fence = null;
		imageAvailable = null;
		instance = null;
		offscreenDescriptorSet = null;
		offscreenDescriptorSetLayout = null;
		offscreenFramebuffer = null;
		offscreenImage = null;
		offscreenPipeline = null;
		offscreenPipelineLayout = null;
		offscreenRenderPass = null;
		offscreenSampler = null;
		offscreenView = null;
		quadFragmentShader = null;
		quadIndexBuffer = null;
		quadVertexBuffer = null;
		quadVertexShader = null;
		renderFinished = null;
		renderPass = null;
		sourceTextureImage = null;
		sourceTextureSampler = null;
		sourceTextureView = null;
		surface = null;
		swapchain = null;
		uniformBuffer = null;
	}

	private function fail(message:String):Void
	{
		trace("Vulkan smoke failed: " + message);
		disposeRenderer();
		System.exit(1);
	}

	private static function identity():Array<Float>
	{
		return [
			1.0, 0.0, 0.0, 0.0,
			0.0, 1.0, 0.0, 0.0,
			0.0, 0.0, 1.0, 0.0,
			0.0, 0.0, 0.0, 1.0
		];
	}

	private static inline function isNonZero(value:Int64):Bool
	{
		return value.high != 0 || value.low != 0;
	}

	private static function multiply(a:Array<Float>, b:Array<Float>):Array<Float>
	{
		var result = [];

		for (column in 0...4)
		{
			for (row in 0...4)
			{
				var value = 0.0;
				for (i in 0...4)
				{
					value += a[i * 4 + row] * b[column * 4 + i];
				}
				result[column * 4 + row] = value;
			}
		}

		return result;
	}

	private static function perspective(fovY:Float, aspect:Float, near:Float, far:Float):Array<Float>
	{
		var f = 1.0 / Math.tan(fovY * 0.5);
		var result = [
			f / aspect, 0.0,                         0.0,  0.0,
			       0.0,  -f,                         0.0,  0.0,
			       0.0, 0.0,          far / (near - far), -1.0,
			       0.0, 0.0, (far * near) / (near - far),  0.0
		];
		return result;
	}

	private static function rotationX(angle:Float):Array<Float>
	{
		var c = Math.cos(angle);
		var s = Math.sin(angle);
		var result = identity();
		result[5] = c;
		result[6] = s;
		result[9] = -s;
		result[10] = c;
		return result;
	}

	private static function rotationY(angle:Float):Array<Float>
	{
		var c = Math.cos(angle);
		var s = Math.sin(angle);
		var result = identity();
		result[0] = c;
		result[2] = -s;
		result[8] = s;
		result[10] = c;
		return result;
	}

	private static function translation(x:Float, y:Float, z:Float):Array<Float>
	{
		var result = identity();
		result[12] = x;
		result[13] = y;
		result[14] = z;
		return result;
	}
}
