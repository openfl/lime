#include <graphics/vulkan/VKRenderer.h>

#include <SDL.h>
#include <SDL_vulkan.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <sstream>


namespace lime {


	static const char* VulkanResultToString (VkResult result) {

		switch (result) {

			case VK_SUCCESS: return "VK_SUCCESS";
			case VK_NOT_READY: return "VK_NOT_READY";
			case VK_TIMEOUT: return "VK_TIMEOUT";
			case VK_EVENT_SET: return "VK_EVENT_SET";
			case VK_EVENT_RESET: return "VK_EVENT_RESET";
			case VK_INCOMPLETE: return "VK_INCOMPLETE";
			case VK_ERROR_OUT_OF_HOST_MEMORY: return "VK_ERROR_OUT_OF_HOST_MEMORY";
			case VK_ERROR_OUT_OF_DEVICE_MEMORY: return "VK_ERROR_OUT_OF_DEVICE_MEMORY";
			case VK_ERROR_INITIALIZATION_FAILED: return "VK_ERROR_INITIALIZATION_FAILED";
			case VK_ERROR_DEVICE_LOST: return "VK_ERROR_DEVICE_LOST";
			case VK_ERROR_MEMORY_MAP_FAILED: return "VK_ERROR_MEMORY_MAP_FAILED";
			case VK_ERROR_LAYER_NOT_PRESENT: return "VK_ERROR_LAYER_NOT_PRESENT";
			case VK_ERROR_EXTENSION_NOT_PRESENT: return "VK_ERROR_EXTENSION_NOT_PRESENT";
			case VK_ERROR_FEATURE_NOT_PRESENT: return "VK_ERROR_FEATURE_NOT_PRESENT";
			case VK_ERROR_INCOMPATIBLE_DRIVER: return "VK_ERROR_INCOMPATIBLE_DRIVER";
			case VK_ERROR_TOO_MANY_OBJECTS: return "VK_ERROR_TOO_MANY_OBJECTS";
			case VK_ERROR_FORMAT_NOT_SUPPORTED: return "VK_ERROR_FORMAT_NOT_SUPPORTED";
			case VK_ERROR_SURFACE_LOST_KHR: return "VK_ERROR_SURFACE_LOST_KHR";
			case VK_ERROR_NATIVE_WINDOW_IN_USE_KHR: return "VK_ERROR_NATIVE_WINDOW_IN_USE_KHR";
			case VK_SUBOPTIMAL_KHR: return "VK_SUBOPTIMAL_KHR";
			case VK_ERROR_OUT_OF_DATE_KHR: return "VK_ERROR_OUT_OF_DATE_KHR";
			default: return "VK_RESULT_UNKNOWN";

		}

	}


	static std::string FormatVulkanVersion (uint32_t version) {

		std::ostringstream result;
		result << VK_API_VERSION_MAJOR (version) << "." << VK_API_VERSION_MINOR (version) << "." << VK_API_VERSION_PATCH (version);
		return result.str ();

	}


	static const char* VulkanPresentModeToString (VkPresentModeKHR mode) {

		switch (mode) {

			case VK_PRESENT_MODE_IMMEDIATE_KHR: return "immediate";
			case VK_PRESENT_MODE_MAILBOX_KHR: return "mailbox";
			case VK_PRESENT_MODE_FIFO_KHR: return "fifo";
			#ifdef VK_PRESENT_MODE_FIFO_RELAXED_KHR
			case VK_PRESENT_MODE_FIFO_RELAXED_KHR: return "fifo-relaxed";
			#endif
			default: return "unknown";

		}

	}


	static VkPresentModeKHR ChoosePresentMode (const std::vector<VkPresentModeKHR>& presentModes, int requestedVSyncMode) {

		bool hasImmediate = false;
		bool hasMailbox = false;
		bool hasFifo = false;
		bool hasFifoRelaxed = false;

		for (size_t i = 0; i < presentModes.size (); ++i) {

			switch (presentModes[i]) {

				case VK_PRESENT_MODE_IMMEDIATE_KHR:
					hasImmediate = true;
					break;

				case VK_PRESENT_MODE_MAILBOX_KHR:
					hasMailbox = true;
					break;

				case VK_PRESENT_MODE_FIFO_KHR:
					hasFifo = true;
					break;

				#ifdef VK_PRESENT_MODE_FIFO_RELAXED_KHR
				case VK_PRESENT_MODE_FIFO_RELAXED_KHR:
					hasFifoRelaxed = true;
					break;
				#endif

				default:
					break;

			}

		}

		switch (requestedVSyncMode) {

			case 0:
				if (hasImmediate) return VK_PRESENT_MODE_IMMEDIATE_KHR;
				if (hasMailbox) return VK_PRESENT_MODE_MAILBOX_KHR;
				break;

			case 2:
				if (hasMailbox) return VK_PRESENT_MODE_MAILBOX_KHR;
				#ifdef VK_PRESENT_MODE_FIFO_RELAXED_KHR
				if (hasFifoRelaxed) return VK_PRESENT_MODE_FIFO_RELAXED_KHR;
				#endif
				break;

			case 3:
				if (hasMailbox) return VK_PRESENT_MODE_MAILBOX_KHR;
				if (hasFifo) return VK_PRESENT_MODE_FIFO_KHR;
				if (hasImmediate) return VK_PRESENT_MODE_IMMEDIATE_KHR;
				break;

			default:
				if (hasFifo) return VK_PRESENT_MODE_FIFO_KHR;
				break;

		}

		if (hasFifo) return VK_PRESENT_MODE_FIFO_KHR;
		if (hasMailbox) return VK_PRESENT_MODE_MAILBOX_KHR;
		if (hasImmediate) return VK_PRESENT_MODE_IMMEDIATE_KHR;
		return VK_PRESENT_MODE_FIFO_KHR;

	}


	VulkanRenderer::VulkanRenderer (Window* window)
		: window (window),
		vkGetInstanceProcAddr (0),
		vkGetDeviceProcAddr (0),
		vkAllocateMemory (0),
		vkBindBufferMemory (0),
		vkCmdCopyBufferToImage (0),
		vkCmdPipelineBarrier (0),
		vkCreateBuffer (0),
		vkCreateDevice (0),
		vkCreateFence (0),
		vkCreateFramebuffer (0),
		vkCreateImageView (0),
		vkCreateInstance (0),
		vkCreateRenderPass (0),
		vkCreateSemaphore (0),
		vkCreateSwapchainKHR (0),
		vkCreateCommandPool (0),
		vkAllocateCommandBuffers (0),
		vkAcquireNextImageKHR (0),
		vkBeginCommandBuffer (0),
		vkCmdBeginRenderPass (0),
		vkCmdEndRenderPass (0),
		vkDestroyCommandPool (0),
		vkDestroyBuffer (0),
		vkDestroyDevice (0),
		vkDestroyFence (0),
		vkDestroyFramebuffer (0),
		vkDestroyImageView (0),
		vkDestroyInstance (0),
		vkDestroyRenderPass (0),
		vkDestroySemaphore (0),
		vkDestroySurfaceKHR (0),
		vkDestroySwapchainKHR (0),
		vkDeviceWaitIdle (0),
		vkEndCommandBuffer (0),
		vkEnumerateDeviceExtensionProperties (0),
		vkFreeMemory (0),
		vkGetBufferMemoryRequirements (0),
		vkEnumerateInstanceExtensionProperties (0),
		vkEnumerateInstanceVersion (0),
		vkEnumeratePhysicalDevices (0),
		vkGetDeviceQueue (0),
		vkGetPhysicalDeviceMemoryProperties (0),
		vkGetPhysicalDeviceProperties (0),
		vkGetPhysicalDeviceQueueFamilyProperties (0),
		vkGetPhysicalDeviceSurfaceCapabilitiesKHR (0),
		vkGetPhysicalDeviceSurfaceFormatsKHR (0),
		vkGetPhysicalDeviceSurfacePresentModesKHR (0),
		vkGetPhysicalDeviceSurfaceSupportKHR (0),
		vkGetSwapchainImagesKHR (0),
		vkMapMemory (0),
		vkQueuePresentKHR (0),
		vkQueueSubmit (0),
		vkResetCommandPool (0),
		vkResetFences (0),
		vkUnmapMemory (0),
		vkWaitForFences (0),
		instance (VK_NULL_HANDLE),
		surface (VK_NULL_HANDLE),
		physicalDevice (VK_NULL_HANDLE),
		device (VK_NULL_HANDLE),
		queue (VK_NULL_HANDLE),
		queueFamilyIndex (0),
		swapchain (VK_NULL_HANDLE),
		swapchainFormat (VK_FORMAT_UNDEFINED),
		swapchainPresentMode (VK_PRESENT_MODE_FIFO_KHR),
		requestedVSyncMode (0),
		renderPass (VK_NULL_HANDLE),
		commandPool (VK_NULL_HANDLE),
		imageAvailableSemaphore (VK_NULL_HANDLE),
		renderFinishedSemaphore (VK_NULL_HANDLE),
		inFlightFence (VK_NULL_HANDLE),
		overlayBuffer (VK_NULL_HANDLE),
		overlayBufferMemory (VK_NULL_HANDLE),
		portabilityEnumerationSupported (false),
		portabilitySubsetSupported (false),
		swapchainDirty (false),
		overlayBufferCapacity (0),
		overlayMappedData (0),
		overlayWidth (0),
		overlayHeight (0),
		overlayX (0),
		overlayY (0),
		overlayEnabled (false) {

		memset (&physicalDeviceProperties, 0, sizeof (physicalDeviceProperties));
		memset (&swapchainExtent, 0, sizeof (swapchainExtent));

	}


	VulkanRenderer::~VulkanRenderer () {

		Destroy ();

	}


	bool VulkanRenderer::Create (const char* applicationName) {

		Destroy ();
		lastError.clear ();
		info.clear ();

		if (!window) {

			SetError ("Vulkan renderer creation failed: missing window");
			return false;

		}

		if (SDL_Vulkan_LoadLibrary (NULL) != 0) {

			SetError (std::string ("SDL_Vulkan_LoadLibrary failed: ") + SDL_GetError ());
			return false;

		}

		if (!LoadGlobalProcs ()) {

			return false;

		}

		if (!CreateInstance (applicationName)) return false;
		if (!LoadInstanceProcs ()) return false;
		if (!CreateSurface ()) return false;
		if (!PickPhysicalDevice ()) return false;
		if (!CreateDevice ()) return false;
		if (!LoadDeviceProcs ()) return false;
		vkGetDeviceQueue (device, queueFamilyIndex, 0, &queue);
		if (!CreateSwapchainResources ()) return false;
		if (!CreateSyncObjects ()) return false;

		std::ostringstream result;
		result << physicalDeviceProperties.deviceName << " | Vulkan " << FormatVulkanVersion (physicalDeviceProperties.apiVersion)
			<< " | present " << VulkanPresentModeToString (swapchainPresentMode);
		info = result.str ();
		return true;

	}


	bool VulkanRenderer::ClearOverlay () {

		overlayEnabled = false;
		overlayWidth = 0;
		overlayHeight = 0;
		overlayX = 0;
		overlayY = 0;
		lastError.clear ();
		return true;

	}


	void VulkanRenderer::Destroy () {

		if (device && vkDeviceWaitIdle) {

			vkDeviceWaitIdle (device);

		}

		if (device && vkDestroyFence && inFlightFence) {

			vkDestroyFence (device, inFlightFence, 0);
			inFlightFence = VK_NULL_HANDLE;

		}

		if (device && vkDestroySemaphore && renderFinishedSemaphore) {

			vkDestroySemaphore (device, renderFinishedSemaphore, 0);
			renderFinishedSemaphore = VK_NULL_HANDLE;

		}

		if (device && vkDestroySemaphore && imageAvailableSemaphore) {

			vkDestroySemaphore (device, imageAvailableSemaphore, 0);
			imageAvailableSemaphore = VK_NULL_HANDLE;

		}

		DestroyOverlayResources ();
		DestroySwapchainResources ();

		if (device && vkDestroyDevice) {

			vkDestroyDevice (device, 0);
			device = VK_NULL_HANDLE;

		}

		queue = VK_NULL_HANDLE;
		physicalDevice = VK_NULL_HANDLE;
		memset (&physicalDeviceProperties, 0, sizeof (physicalDeviceProperties));

		if (surface && vkDestroySurfaceKHR && instance) {

			vkDestroySurfaceKHR (instance, surface, 0);
			surface = VK_NULL_HANDLE;

		}

		if (instance && vkDestroyInstance) {

			vkDestroyInstance (instance, 0);
			instance = VK_NULL_HANDLE;

		}

		instanceExtensions.clear ();
		deviceExtensions.clear ();
		portabilityEnumerationSupported = false;
		portabilitySubsetSupported = false;
		swapchainDirty = false;
		swapchainFormat = VK_FORMAT_UNDEFINED;
		swapchainPresentMode = VK_PRESENT_MODE_FIFO_KHR;
		requestedVSyncMode = 0;
		memset (&swapchainExtent, 0, sizeof (swapchainExtent));

	}


	bool VulkanRenderer::Render (float red, float green, float blue, float alpha) {

		if (!device) {

			SetError ("Vulkan renderer is not initialized");
			return false;

		}

		int currentRequestedVSyncMode = window ? window->GetRequestedVSyncMode () : 0;
		if (swapchainDirty || !swapchain || swapchainExtent.width == 0 || swapchainExtent.height == 0 || currentRequestedVSyncMode != requestedVSyncMode) {

			if (!RecreateSwapchain ()) {

				return false;

			}

		}

		if (!swapchain || swapchainExtent.width == 0 || swapchainExtent.height == 0) {

			return true;

		}

		VkResult result = vkWaitForFences (device, 1, &inFlightFence, VK_TRUE, UINT64_MAX);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkWaitForFences failed: ") + VulkanResultToString (result));
			return false;

		}

		uint32_t imageIndex = 0;
		result = vkAcquireNextImageKHR (device, swapchain, UINT64_MAX, imageAvailableSemaphore, VK_NULL_HANDLE, &imageIndex);

		if (result == VK_ERROR_OUT_OF_DATE_KHR) {

			return RecreateSwapchain ();

		}

		if (result != VK_SUCCESS && result != VK_SUBOPTIMAL_KHR) {

			SetError (std::string ("vkAcquireNextImageKHR failed: ") + VulkanResultToString (result));
			return false;

		}

		result = vkResetFences (device, 1, &inFlightFence);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkResetFences failed: ") + VulkanResultToString (result));
			return false;

		}

		result = vkResetCommandPool (device, commandPool, 0);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkResetCommandPool failed: ") + VulkanResultToString (result));
			return false;

		}

		if (!RecordCommandBuffer (imageIndex, red, green, blue, alpha)) {

			return false;

		}

		VkPipelineStageFlags waitStages[] = { VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT };
		VkSubmitInfo submitInfo;
		memset (&submitInfo, 0, sizeof (submitInfo));
		submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
		submitInfo.waitSemaphoreCount = 1;
		submitInfo.pWaitSemaphores = &imageAvailableSemaphore;
		submitInfo.pWaitDstStageMask = waitStages;
		submitInfo.commandBufferCount = 1;
		submitInfo.pCommandBuffers = &commandBuffers[imageIndex];
		submitInfo.signalSemaphoreCount = 1;
		submitInfo.pSignalSemaphores = &renderFinishedSemaphore;

		result = vkQueueSubmit (queue, 1, &submitInfo, inFlightFence);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkQueueSubmit failed: ") + VulkanResultToString (result));
			return false;

		}

		VkPresentInfoKHR presentInfo;
		memset (&presentInfo, 0, sizeof (presentInfo));
		presentInfo.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
		presentInfo.waitSemaphoreCount = 1;
		presentInfo.pWaitSemaphores = &renderFinishedSemaphore;
		presentInfo.swapchainCount = 1;
		presentInfo.pSwapchains = &swapchain;
		presentInfo.pImageIndices = &imageIndex;

		result = vkQueuePresentKHR (queue, &presentInfo);
		if (result == VK_ERROR_OUT_OF_DATE_KHR || result == VK_SUBOPTIMAL_KHR) {

			return RecreateSwapchain ();

		}

		if (result != VK_SUCCESS) {

			SetError (std::string ("vkQueuePresentKHR failed: ") + VulkanResultToString (result));
			return false;

		}

		return true;

	}


	bool VulkanRenderer::Resize () {

		return RecreateSwapchain ();

	}


	bool VulkanRenderer::SetOverlay (const unsigned char* data, int width, int height, int x, int y) {

		if (!data || width <= 0 || height <= 0) {

			return ClearOverlay ();

		}

		size_t requiredSize = (size_t)width * (size_t)height * 4;
		if (!CreateOverlayBuffer (requiredSize)) {

			return false;

		}

		memcpy (overlayMappedData, data, requiredSize);

		overlayWidth = (uint32_t)width;
		overlayHeight = (uint32_t)height;
		overlayX = x;
		overlayY = y;
		overlayEnabled = true;
		lastError.clear ();
		return true;

	}


	bool VulkanRenderer::CreateCommandBuffers () {

		commandBuffers.clear ();

		if (swapchainImages.empty ()) {

			SetError ("Cannot allocate Vulkan command buffers without swapchain images");
			return false;

		}

		commandBuffers.resize (swapchainImages.size (), VK_NULL_HANDLE);

		VkCommandBufferAllocateInfo allocateInfo;
		memset (&allocateInfo, 0, sizeof (allocateInfo));
		allocateInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
		allocateInfo.commandPool = commandPool;
		allocateInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
		allocateInfo.commandBufferCount = (uint32_t)commandBuffers.size ();

		VkResult result = vkAllocateCommandBuffers (device, &allocateInfo, commandBuffers.data ());
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkAllocateCommandBuffers failed: ") + VulkanResultToString (result));
			return false;

		}

		return true;

	}


	bool VulkanRenderer::CreateCommandPool () {

		VkCommandPoolCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
		createInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
		createInfo.queueFamilyIndex = queueFamilyIndex;

		VkResult result = vkCreateCommandPool (device, &createInfo, 0, &commandPool);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkCreateCommandPool failed: ") + VulkanResultToString (result));
			return false;

		}

		return true;

	}


	bool VulkanRenderer::CreateDevice () {

		const float queuePriority = 1.0f;

		VkDeviceQueueCreateInfo queueCreateInfo;
		memset (&queueCreateInfo, 0, sizeof (queueCreateInfo));
		queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
		queueCreateInfo.queueFamilyIndex = queueFamilyIndex;
		queueCreateInfo.queueCount = 1;
		queueCreateInfo.pQueuePriorities = &queuePriority;

		deviceExtensions.clear ();
		deviceExtensions.push_back (VK_KHR_SWAPCHAIN_EXTENSION_NAME);
		if (portabilitySubsetSupported) {

			#ifdef VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME
			deviceExtensions.push_back (VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME);
			#endif

		}

		VkDeviceCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
		createInfo.queueCreateInfoCount = 1;
		createInfo.pQueueCreateInfos = &queueCreateInfo;
		createInfo.enabledExtensionCount = (uint32_t)deviceExtensions.size ();
		createInfo.ppEnabledExtensionNames = deviceExtensions.data ();

		VkResult result = vkCreateDevice (physicalDevice, &createInfo, 0, &device);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkCreateDevice failed: ") + VulkanResultToString (result));
			return false;

		}

		return true;

	}


	bool VulkanRenderer::CreateFramebuffers () {

		framebuffers.clear ();
		framebuffers.resize (swapchainImageViews.size (), VK_NULL_HANDLE);

		for (size_t i = 0; i < swapchainImageViews.size (); ++i) {

			VkImageView attachments[] = { swapchainImageViews[i] };
			VkFramebufferCreateInfo createInfo;
			memset (&createInfo, 0, sizeof (createInfo));
			createInfo.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
			createInfo.renderPass = renderPass;
			createInfo.attachmentCount = 1;
			createInfo.pAttachments = attachments;
			createInfo.width = swapchainExtent.width;
			createInfo.height = swapchainExtent.height;
			createInfo.layers = 1;

			VkResult result = vkCreateFramebuffer (device, &createInfo, 0, &framebuffers[i]);
			if (result != VK_SUCCESS) {

				SetError (std::string ("vkCreateFramebuffer failed: ") + VulkanResultToString (result));
				return false;

			}

		}

		return true;

	}


	bool VulkanRenderer::CreateImageViews () {

		swapchainImageViews.clear ();
		swapchainImageViews.resize (swapchainImages.size (), VK_NULL_HANDLE);

		for (size_t i = 0; i < swapchainImages.size (); ++i) {

			VkImageViewCreateInfo createInfo;
			memset (&createInfo, 0, sizeof (createInfo));
			createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
			createInfo.image = swapchainImages[i];
			createInfo.viewType = VK_IMAGE_VIEW_TYPE_2D;
			createInfo.format = swapchainFormat;
			createInfo.components.r = VK_COMPONENT_SWIZZLE_IDENTITY;
			createInfo.components.g = VK_COMPONENT_SWIZZLE_IDENTITY;
			createInfo.components.b = VK_COMPONENT_SWIZZLE_IDENTITY;
			createInfo.components.a = VK_COMPONENT_SWIZZLE_IDENTITY;
			createInfo.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
			createInfo.subresourceRange.baseMipLevel = 0;
			createInfo.subresourceRange.levelCount = 1;
			createInfo.subresourceRange.baseArrayLayer = 0;
			createInfo.subresourceRange.layerCount = 1;

			VkResult result = vkCreateImageView (device, &createInfo, 0, &swapchainImageViews[i]);
			if (result != VK_SUCCESS) {

				SetError (std::string ("vkCreateImageView failed: ") + VulkanResultToString (result));
				return false;

			}

		}

		return true;

	}


	bool VulkanRenderer::CreateInstance (const char* applicationName) {

		instanceExtensions.clear ();

		unsigned int requiredExtensionCount = 0;
		if (!window->GetVulkanInstanceExtensions (&requiredExtensionCount, 0)) {

			SetError ("Failed to query required Vulkan window extensions");
			return false;

		}

		std::vector<const char*> requiredExtensions (requiredExtensionCount);
		if (requiredExtensionCount > 0 && !window->GetVulkanInstanceExtensions (&requiredExtensionCount, requiredExtensions.data ())) {

			SetError ("Failed to fetch required Vulkan window extensions");
			return false;

		}

		for (size_t i = 0; i < requiredExtensions.size (); ++i) {

			instanceExtensions.push_back (requiredExtensions[i]);

		}

		uint32_t availableCount = 0;
		if (vkEnumerateInstanceExtensionProperties &&
			vkEnumerateInstanceExtensionProperties (0, &availableCount, 0) == VK_SUCCESS && availableCount > 0) {

			std::vector<VkExtensionProperties> availableExtensions (availableCount);
			if (vkEnumerateInstanceExtensionProperties (0, &availableCount, availableExtensions.data ()) == VK_SUCCESS) {

				for (size_t i = 0; i < availableExtensions.size (); ++i) {

					#ifdef VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME
					if (strcmp (availableExtensions[i].extensionName, VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME) == 0) {

						portabilityEnumerationSupported = true;

					}
					#endif

				}

			}

		}

		if (portabilityEnumerationSupported) {

			#ifdef VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME
			instanceExtensions.push_back (VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME);
			#endif

		}

		uint32_t instanceVersion = VK_API_VERSION_1_0;
		if (vkEnumerateInstanceVersion) {

			vkEnumerateInstanceVersion (&instanceVersion);

		}

		VkApplicationInfo applicationInfo;
		memset (&applicationInfo, 0, sizeof (applicationInfo));
		applicationInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
		applicationInfo.pApplicationName = applicationName ? applicationName : "Lime Vulkan Sample";
		applicationInfo.pEngineName = "Lime";
		applicationInfo.applicationVersion = VK_MAKE_VERSION (1, 0, 0);
		applicationInfo.engineVersion = VK_MAKE_VERSION (1, 0, 0);
		applicationInfo.apiVersion = instanceVersion >= VK_API_VERSION_1_0 ? VK_API_VERSION_1_0 : instanceVersion;

		VkInstanceCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
		createInfo.pApplicationInfo = &applicationInfo;
		createInfo.enabledExtensionCount = (uint32_t)instanceExtensions.size ();
		createInfo.ppEnabledExtensionNames = instanceExtensions.empty () ? 0 : instanceExtensions.data ();

		#ifdef VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR
		if (portabilityEnumerationSupported) {

			createInfo.flags |= VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR;

		}
		#endif

		VkResult result = vkCreateInstance (&createInfo, 0, &instance);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkCreateInstance failed: ") + VulkanResultToString (result));
			return false;

		}

		return true;

	}


	bool VulkanRenderer::CreateOverlayBuffer (size_t requiredSize) {

		if (!device) {

			SetError ("Cannot create Vulkan overlay buffer before device initialization");
			return false;

		}

		if (requiredSize == 0) {

			DestroyOverlayResources ();
			return true;

		}

		if (overlayBuffer != VK_NULL_HANDLE && overlayMappedData && overlayBufferCapacity >= requiredSize) {

			return true;

		}

		DestroyOverlayResources ();

		VkBufferCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
		createInfo.size = requiredSize;
		createInfo.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
		createInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

		VkResult result = vkCreateBuffer (device, &createInfo, 0, &overlayBuffer);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkCreateBuffer failed for overlay upload: ") + VulkanResultToString (result));
			return false;

		}

		VkMemoryRequirements memoryRequirements;
		memset (&memoryRequirements, 0, sizeof (memoryRequirements));
		vkGetBufferMemoryRequirements (device, overlayBuffer, &memoryRequirements);

		VkMemoryAllocateInfo allocateInfo;
		memset (&allocateInfo, 0, sizeof (allocateInfo));
		allocateInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
		allocateInfo.allocationSize = memoryRequirements.size;
		allocateInfo.memoryTypeIndex = FindMemoryType (
			memoryRequirements.memoryTypeBits,
			VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
		);
		if (allocateInfo.memoryTypeIndex == UINT32_MAX) {

			return false;

		}

		result = vkAllocateMemory (device, &allocateInfo, 0, &overlayBufferMemory);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkAllocateMemory failed for overlay upload: ") + VulkanResultToString (result));
			return false;

		}

		result = vkBindBufferMemory (device, overlayBuffer, overlayBufferMemory, 0);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkBindBufferMemory failed for overlay upload: ") + VulkanResultToString (result));
			return false;

		}

		void* mappedData = 0;
		result = vkMapMemory (device, overlayBufferMemory, 0, allocateInfo.allocationSize, 0, &mappedData);
		if (result != VK_SUCCESS || !mappedData) {

			SetError (std::string ("vkMapMemory failed for overlay upload: ") + VulkanResultToString (result));
			return false;

		}

		overlayMappedData = (unsigned char*)mappedData;
		overlayBufferCapacity = requiredSize;
		return true;

	}


	bool VulkanRenderer::CreateRenderPass () {

		VkAttachmentDescription colorAttachment;
		memset (&colorAttachment, 0, sizeof (colorAttachment));
		colorAttachment.format = swapchainFormat;
		colorAttachment.samples = VK_SAMPLE_COUNT_1_BIT;
		colorAttachment.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
		colorAttachment.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
		colorAttachment.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
		colorAttachment.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
		colorAttachment.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
		colorAttachment.finalLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

		VkAttachmentReference colorAttachmentRef;
		memset (&colorAttachmentRef, 0, sizeof (colorAttachmentRef));
		colorAttachmentRef.attachment = 0;
		colorAttachmentRef.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

		VkSubpassDescription subpass;
		memset (&subpass, 0, sizeof (subpass));
		subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
		subpass.colorAttachmentCount = 1;
		subpass.pColorAttachments = &colorAttachmentRef;

		VkSubpassDependency dependency;
		memset (&dependency, 0, sizeof (dependency));
		dependency.srcSubpass = VK_SUBPASS_EXTERNAL;
		dependency.dstSubpass = 0;
		dependency.srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
		dependency.dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
		dependency.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;

		VkRenderPassCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
		createInfo.attachmentCount = 1;
		createInfo.pAttachments = &colorAttachment;
		createInfo.subpassCount = 1;
		createInfo.pSubpasses = &subpass;
		createInfo.dependencyCount = 1;
		createInfo.pDependencies = &dependency;

		VkResult result = vkCreateRenderPass (device, &createInfo, 0, &renderPass);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkCreateRenderPass failed: ") + VulkanResultToString (result));
			return false;

		}

		return true;

	}


	bool VulkanRenderer::CreateSurface () {

		uint64_t nativeSurface = window->CreateVulkanSurface ((uintptr_t)instance);
		if (!nativeSurface) {

			SetError ("Failed to create Vulkan surface from Lime window");
			return false;

		}

		surface = (VkSurfaceKHR)(uintptr_t)nativeSurface;
		return true;

	}


	bool VulkanRenderer::CreateSwapchain () {

		VkSurfaceCapabilitiesKHR capabilities;
		memset (&capabilities, 0, sizeof (capabilities));
		VkResult result = vkGetPhysicalDeviceSurfaceCapabilitiesKHR (physicalDevice, surface, &capabilities);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkGetPhysicalDeviceSurfaceCapabilitiesKHR failed: ") + VulkanResultToString (result));
			return false;

		}

		uint32_t formatCount = 0;
		result = vkGetPhysicalDeviceSurfaceFormatsKHR (physicalDevice, surface, &formatCount, 0);
		if (result != VK_SUCCESS || formatCount == 0) {

			SetError ("Failed to query Vulkan surface formats");
			return false;

		}

		std::vector<VkSurfaceFormatKHR> formats (formatCount);
		vkGetPhysicalDeviceSurfaceFormatsKHR (physicalDevice, surface, &formatCount, formats.data ());

		VkSurfaceFormatKHR surfaceFormat = formats[0];
		for (size_t i = 0; i < formats.size (); ++i) {

			if (formats[i].format == VK_FORMAT_B8G8R8A8_UNORM && formats[i].colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {

				surfaceFormat = formats[i];
				break;

			}

		}

		uint32_t presentModeCount = 0;
		vkGetPhysicalDeviceSurfacePresentModesKHR (physicalDevice, surface, &presentModeCount, 0);
		std::vector<VkPresentModeKHR> presentModes (presentModeCount > 0 ? presentModeCount : 1, VK_PRESENT_MODE_FIFO_KHR);
		if (presentModeCount > 0) {

			vkGetPhysicalDeviceSurfacePresentModesKHR (physicalDevice, surface, &presentModeCount, presentModes.data ());

		}

		int currentRequestedVSyncMode = window ? window->GetRequestedVSyncMode () : 0;
		VkPresentModeKHR presentMode = ChoosePresentMode (presentModes, currentRequestedVSyncMode);

		int drawableWidth = 0;
		int drawableHeight = 0;
		window->GetVulkanDrawableSize (&drawableWidth, &drawableHeight);
		if (drawableWidth <= 0 || drawableHeight <= 0) {

			swapchainExtent.width = 0;
			swapchainExtent.height = 0;
			swapchainDirty = true;
			return true;

		}

		if (capabilities.currentExtent.width != UINT32_MAX) {

			swapchainExtent = capabilities.currentExtent;

		} else {

			swapchainExtent.width = (uint32_t)(std::max) ((int)capabilities.minImageExtent.width,
				(std::min) (drawableWidth, (int)capabilities.maxImageExtent.width));
			swapchainExtent.height = (uint32_t)(std::max) ((int)capabilities.minImageExtent.height,
				(std::min) (drawableHeight, (int)capabilities.maxImageExtent.height));

		}

		uint32_t imageCount = capabilities.minImageCount + 1;
		if (capabilities.maxImageCount > 0 && imageCount > capabilities.maxImageCount) {

			imageCount = capabilities.maxImageCount;

		}

		VkCompositeAlphaFlagBitsKHR compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
		const bool transparentWindow = window && ((window->flags & WINDOW_FLAG_TRANSPARENT) != 0);
		const VkCompositeAlphaFlagBitsKHR opaqueCompositeAlphaFlags[] = {
			VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
			VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR,
			VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR,
			VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR
		};
		const VkCompositeAlphaFlagBitsKHR transparentCompositeAlphaFlags[] = {
			VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR,
			VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR,
			VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR,
			VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR
		};
		const VkCompositeAlphaFlagBitsKHR* compositeAlphaFlags = transparentWindow ? transparentCompositeAlphaFlags : opaqueCompositeAlphaFlags;
		const size_t compositeAlphaFlagCount = transparentWindow
			? sizeof (transparentCompositeAlphaFlags) / sizeof (transparentCompositeAlphaFlags[0])
			: sizeof (opaqueCompositeAlphaFlags) / sizeof (opaqueCompositeAlphaFlags[0]);

		for (size_t i = 0; i < compositeAlphaFlagCount; ++i) {

			if (capabilities.supportedCompositeAlpha & compositeAlphaFlags[i]) {

				compositeAlpha = compositeAlphaFlags[i];
				break;

			}

		}

		VkSwapchainCreateInfoKHR createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
		createInfo.surface = surface;
		createInfo.minImageCount = imageCount;
		createInfo.imageFormat = surfaceFormat.format;
		createInfo.imageColorSpace = surfaceFormat.colorSpace;
		createInfo.imageExtent = swapchainExtent;
		createInfo.imageArrayLayers = 1;
		createInfo.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT;
		createInfo.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
		createInfo.preTransform = capabilities.currentTransform;
		createInfo.compositeAlpha = compositeAlpha;
		createInfo.presentMode = presentMode;
		createInfo.clipped = VK_TRUE;
		createInfo.oldSwapchain = VK_NULL_HANDLE;

		result = vkCreateSwapchainKHR (device, &createInfo, 0, &swapchain);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkCreateSwapchainKHR failed: ") + VulkanResultToString (result));
			return false;

		}

		swapchainFormat = surfaceFormat.format;
		swapchainPresentMode = presentMode;
		requestedVSyncMode = currentRequestedVSyncMode;
		swapchainDirty = false;

		uint32_t swapchainImageCount = 0;
		result = vkGetSwapchainImagesKHR (device, swapchain, &swapchainImageCount, 0);
		if (result != VK_SUCCESS || swapchainImageCount == 0) {

			SetError ("Failed to query Vulkan swapchain images");
			return false;

		}

		swapchainImages.resize (swapchainImageCount);
		result = vkGetSwapchainImagesKHR (device, swapchain, &swapchainImageCount, swapchainImages.data ());
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkGetSwapchainImagesKHR failed: ") + VulkanResultToString (result));
			return false;

		}

		return true;

	}


	bool VulkanRenderer::CreateSwapchainResources () {

		if (!CreateSwapchain ()) return false;
		if (swapchainExtent.width == 0 || swapchainExtent.height == 0) return true;
		if (!CreateImageViews ()) return false;
		if (!CreateRenderPass ()) return false;
		if (!CreateCommandPool ()) return false;
		if (!CreateFramebuffers ()) return false;
		if (!CreateCommandBuffers ()) return false;
		return true;

	}


	bool VulkanRenderer::CreateSyncObjects () {

		VkSemaphoreCreateInfo semaphoreInfo;
		memset (&semaphoreInfo, 0, sizeof (semaphoreInfo));
		semaphoreInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;

		VkFenceCreateInfo fenceInfo;
		memset (&fenceInfo, 0, sizeof (fenceInfo));
		fenceInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
		fenceInfo.flags = VK_FENCE_CREATE_SIGNALED_BIT;

		VkResult result = vkCreateSemaphore (device, &semaphoreInfo, 0, &imageAvailableSemaphore);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkCreateSemaphore failed: ") + VulkanResultToString (result));
			return false;

		}

		result = vkCreateSemaphore (device, &semaphoreInfo, 0, &renderFinishedSemaphore);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkCreateSemaphore failed: ") + VulkanResultToString (result));
			return false;

		}

		result = vkCreateFence (device, &fenceInfo, 0, &inFlightFence);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkCreateFence failed: ") + VulkanResultToString (result));
			return false;

		}

		return true;

	}


	void VulkanRenderer::DestroyOverlayResources () {

		overlayEnabled = false;
		overlayWidth = 0;
		overlayHeight = 0;
		overlayX = 0;
		overlayY = 0;

		if (device && overlayBufferMemory && overlayMappedData && vkUnmapMemory) {

			vkUnmapMemory (device, overlayBufferMemory);
			overlayMappedData = 0;

		}

		if (device && vkDestroyBuffer && overlayBuffer) {

			vkDestroyBuffer (device, overlayBuffer, 0);
			overlayBuffer = VK_NULL_HANDLE;

		}

		if (device && vkFreeMemory && overlayBufferMemory) {

			vkFreeMemory (device, overlayBufferMemory, 0);
			overlayBufferMemory = VK_NULL_HANDLE;

		}

		overlayMappedData = 0;
		overlayBufferCapacity = 0;

	}


	void VulkanRenderer::DestroySwapchainResources () {

		commandBuffers.clear ();

		if (device && vkDestroyCommandPool && commandPool) {

			vkDestroyCommandPool (device, commandPool, 0);
			commandPool = VK_NULL_HANDLE;

		}

		for (size_t i = 0; i < framebuffers.size (); ++i) {

			if (framebuffers[i] && device && vkDestroyFramebuffer) {

				vkDestroyFramebuffer (device, framebuffers[i], 0);

			}

		}

		framebuffers.clear ();

		if (device && vkDestroyRenderPass && renderPass) {

			vkDestroyRenderPass (device, renderPass, 0);
			renderPass = VK_NULL_HANDLE;

		}

		for (size_t i = 0; i < swapchainImageViews.size (); ++i) {

			if (swapchainImageViews[i] && device && vkDestroyImageView) {

				vkDestroyImageView (device, swapchainImageViews[i], 0);

			}

		}

		swapchainImageViews.clear ();
		swapchainImages.clear ();

		if (device && vkDestroySwapchainKHR && swapchain) {

			vkDestroySwapchainKHR (device, swapchain, 0);
			swapchain = VK_NULL_HANDLE;

		}

	}


	uint32_t VulkanRenderer::FindMemoryType (uint32_t typeFilter, VkMemoryPropertyFlags properties) {

		VkPhysicalDeviceMemoryProperties memoryProperties;
		memset (&memoryProperties, 0, sizeof (memoryProperties));
		vkGetPhysicalDeviceMemoryProperties (physicalDevice, &memoryProperties);

		for (uint32_t i = 0; i < memoryProperties.memoryTypeCount; ++i) {

			if ((typeFilter & (1u << i)) &&
				(memoryProperties.memoryTypes[i].propertyFlags & properties) == properties) {

				return i;

			}

		}

		SetError ("Failed to find a compatible Vulkan memory type");
		return UINT32_MAX;

	}


	bool VulkanRenderer::LoadDeviceProcs () {

		if (!vkGetDeviceProcAddr) {

			SetError ("Missing vkGetDeviceProcAddr");
			return false;

		}

		#define LIME_LOAD_DEVICE_PROC(name) \
			name = (PFN_##name)vkGetDeviceProcAddr (device, #name); \
			if (!name) { SetError (std::string ("Missing Vulkan device proc: ") + #name); return false; }

		LIME_LOAD_DEVICE_PROC (vkAllocateMemory);
		LIME_LOAD_DEVICE_PROC (vkAcquireNextImageKHR);
		LIME_LOAD_DEVICE_PROC (vkAllocateCommandBuffers);
		LIME_LOAD_DEVICE_PROC (vkBeginCommandBuffer);
		LIME_LOAD_DEVICE_PROC (vkBindBufferMemory);
		LIME_LOAD_DEVICE_PROC (vkCmdCopyBufferToImage);
		LIME_LOAD_DEVICE_PROC (vkCmdBeginRenderPass);
		LIME_LOAD_DEVICE_PROC (vkCmdEndRenderPass);
		LIME_LOAD_DEVICE_PROC (vkCmdPipelineBarrier);
		LIME_LOAD_DEVICE_PROC (vkCreateBuffer);
		LIME_LOAD_DEVICE_PROC (vkCreateCommandPool);
		LIME_LOAD_DEVICE_PROC (vkCreateFence);
		LIME_LOAD_DEVICE_PROC (vkCreateFramebuffer);
		LIME_LOAD_DEVICE_PROC (vkCreateImageView);
		LIME_LOAD_DEVICE_PROC (vkCreateRenderPass);
		LIME_LOAD_DEVICE_PROC (vkCreateSemaphore);
		LIME_LOAD_DEVICE_PROC (vkCreateSwapchainKHR);
		LIME_LOAD_DEVICE_PROC (vkDestroyCommandPool);
		LIME_LOAD_DEVICE_PROC (vkDestroyBuffer);
		LIME_LOAD_DEVICE_PROC (vkDestroyDevice);
		LIME_LOAD_DEVICE_PROC (vkDestroyFence);
		LIME_LOAD_DEVICE_PROC (vkDestroyFramebuffer);
		LIME_LOAD_DEVICE_PROC (vkDestroyImageView);
		LIME_LOAD_DEVICE_PROC (vkDestroyRenderPass);
		LIME_LOAD_DEVICE_PROC (vkDestroySemaphore);
		LIME_LOAD_DEVICE_PROC (vkDestroySwapchainKHR);
		LIME_LOAD_DEVICE_PROC (vkDeviceWaitIdle);
		LIME_LOAD_DEVICE_PROC (vkEndCommandBuffer);
		LIME_LOAD_DEVICE_PROC (vkFreeMemory);
		LIME_LOAD_DEVICE_PROC (vkGetBufferMemoryRequirements);
		LIME_LOAD_DEVICE_PROC (vkGetSwapchainImagesKHR);
		LIME_LOAD_DEVICE_PROC (vkMapMemory);
		LIME_LOAD_DEVICE_PROC (vkQueuePresentKHR);
		LIME_LOAD_DEVICE_PROC (vkQueueSubmit);
		LIME_LOAD_DEVICE_PROC (vkResetCommandPool);
		LIME_LOAD_DEVICE_PROC (vkResetFences);
		LIME_LOAD_DEVICE_PROC (vkUnmapMemory);
		LIME_LOAD_DEVICE_PROC (vkWaitForFences);

		#undef LIME_LOAD_DEVICE_PROC

		return true;

	}


	bool VulkanRenderer::LoadGlobalProcs () {

		vkGetInstanceProcAddr = (PFN_vkGetInstanceProcAddr)window->GetVulkanInstanceProcAddr ();

		if (!vkGetInstanceProcAddr) {

			SetError ("SDL did not expose vkGetInstanceProcAddr");
			return false;

		}

		#define LIME_LOAD_GLOBAL_PROC(name) \
			name = (PFN_##name)vkGetInstanceProcAddr (VK_NULL_HANDLE, #name); \
			if (!name) { SetError (std::string ("Missing Vulkan global proc: ") + #name); return false; }

		LIME_LOAD_GLOBAL_PROC (vkCreateInstance);
		LIME_LOAD_GLOBAL_PROC (vkEnumerateInstanceExtensionProperties);
		vkEnumerateInstanceVersion = (PFN_vkEnumerateInstanceVersion)vkGetInstanceProcAddr (VK_NULL_HANDLE, "vkEnumerateInstanceVersion");

		#undef LIME_LOAD_GLOBAL_PROC

		return true;

	}


	bool VulkanRenderer::LoadInstanceProcs () {

		#define LIME_LOAD_INSTANCE_PROC(name) \
			name = (PFN_##name)vkGetInstanceProcAddr (instance, #name); \
			if (!name) { SetError (std::string ("Missing Vulkan instance proc: ") + #name); return false; }

		LIME_LOAD_INSTANCE_PROC (vkCreateDevice);
		LIME_LOAD_INSTANCE_PROC (vkDestroyInstance);
		LIME_LOAD_INSTANCE_PROC (vkDestroySurfaceKHR);
		LIME_LOAD_INSTANCE_PROC (vkEnumerateDeviceExtensionProperties);
		LIME_LOAD_INSTANCE_PROC (vkEnumeratePhysicalDevices);
		LIME_LOAD_INSTANCE_PROC (vkGetDeviceProcAddr);
		LIME_LOAD_INSTANCE_PROC (vkGetPhysicalDeviceMemoryProperties);
		LIME_LOAD_INSTANCE_PROC (vkGetPhysicalDeviceProperties);
		LIME_LOAD_INSTANCE_PROC (vkGetPhysicalDeviceQueueFamilyProperties);
		LIME_LOAD_INSTANCE_PROC (vkGetPhysicalDeviceSurfaceCapabilitiesKHR);
		LIME_LOAD_INSTANCE_PROC (vkGetPhysicalDeviceSurfaceFormatsKHR);
		LIME_LOAD_INSTANCE_PROC (vkGetPhysicalDeviceSurfacePresentModesKHR);
		LIME_LOAD_INSTANCE_PROC (vkGetPhysicalDeviceSurfaceSupportKHR);
		LIME_LOAD_INSTANCE_PROC (vkGetDeviceQueue);

		#undef LIME_LOAD_INSTANCE_PROC

		return true;

	}


	bool VulkanRenderer::PickPhysicalDevice () {

		uint32_t deviceCount = 0;
		VkResult result = vkEnumeratePhysicalDevices (instance, &deviceCount, 0);
		if (result != VK_SUCCESS || deviceCount == 0) {

			SetError ("No Vulkan physical devices were found");
			return false;

		}

		std::vector<VkPhysicalDevice> physicalDevices (deviceCount);
		vkEnumeratePhysicalDevices (instance, &deviceCount, physicalDevices.data ());

		for (size_t deviceIndex = 0; deviceIndex < physicalDevices.size (); ++deviceIndex) {

			VkPhysicalDevice candidate = physicalDevices[deviceIndex];

			uint32_t extensionCount = 0;
			vkEnumerateDeviceExtensionProperties (candidate, 0, &extensionCount, 0);
			std::vector<VkExtensionProperties> extensions (extensionCount);
			if (extensionCount > 0) {

				vkEnumerateDeviceExtensionProperties (candidate, 0, &extensionCount, extensions.data ());

			}

			bool hasSwapchain = false;
			bool hasPortabilitySubset = false;

			for (size_t i = 0; i < extensions.size (); ++i) {

				if (strcmp (extensions[i].extensionName, VK_KHR_SWAPCHAIN_EXTENSION_NAME) == 0) {

					hasSwapchain = true;

				}

				#ifdef VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME
				if (strcmp (extensions[i].extensionName, VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME) == 0) {

					hasPortabilitySubset = true;

				}
				#endif

			}

			if (!hasSwapchain) {

				continue;

			}

			uint32_t queueFamilyCount = 0;
			vkGetPhysicalDeviceQueueFamilyProperties (candidate, &queueFamilyCount, 0);
			if (queueFamilyCount == 0) {

				continue;

			}

			std::vector<VkQueueFamilyProperties> queueFamilies (queueFamilyCount);
			vkGetPhysicalDeviceQueueFamilyProperties (candidate, &queueFamilyCount, queueFamilies.data ());

			for (uint32_t queueIndex = 0; queueIndex < queueFamilyCount; ++queueIndex) {

				VkBool32 supportsPresent = VK_FALSE;
				vkGetPhysicalDeviceSurfaceSupportKHR (candidate, queueIndex, surface, &supportsPresent);

				if ((queueFamilies[queueIndex].queueFlags & VK_QUEUE_GRAPHICS_BIT) && supportsPresent) {

					physicalDevice = candidate;
					queueFamilyIndex = queueIndex;
					portabilitySubsetSupported = hasPortabilitySubset;
					vkGetPhysicalDeviceProperties (physicalDevice, &physicalDeviceProperties);
					return true;

				}

			}

		}

		SetError ("Failed to find a Vulkan physical device with graphics and present support");
		return false;

	}


	bool VulkanRenderer::RecordCommandBuffer (uint32_t imageIndex, float red, float green, float blue, float alpha) {

		if (imageIndex >= commandBuffers.size () || imageIndex >= framebuffers.size ()) {

			SetError ("Invalid Vulkan swapchain image index");
			return false;

		}

		VkCommandBuffer commandBuffer = commandBuffers[imageIndex];

		VkCommandBufferBeginInfo beginInfo;
		memset (&beginInfo, 0, sizeof (beginInfo));
		beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;

		VkResult result = vkBeginCommandBuffer (commandBuffer, &beginInfo);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkBeginCommandBuffer failed: ") + VulkanResultToString (result));
			return false;

		}

		VkClearValue clearValue;
		clearValue.color.float32[0] = red;
		clearValue.color.float32[1] = green;
		clearValue.color.float32[2] = blue;
		clearValue.color.float32[3] = alpha;

		VkRenderPassBeginInfo renderPassInfo;
		memset (&renderPassInfo, 0, sizeof (renderPassInfo));
		renderPassInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
		renderPassInfo.renderPass = renderPass;
		renderPassInfo.framebuffer = framebuffers[imageIndex];
		renderPassInfo.renderArea.offset.x = 0;
		renderPassInfo.renderArea.offset.y = 0;
		renderPassInfo.renderArea.extent = swapchainExtent;
		renderPassInfo.clearValueCount = 1;
		renderPassInfo.pClearValues = &clearValue;

		vkCmdBeginRenderPass (commandBuffer, &renderPassInfo, VK_SUBPASS_CONTENTS_INLINE);
		vkCmdEndRenderPass (commandBuffer);

		uint32_t copyWidth = overlayWidth;
		uint32_t copyHeight = overlayHeight;
		int copyX = overlayX;
		int copyY = overlayY;
		VkDeviceSize bufferOffset = 0;
		bool hasOverlayCopy = overlayEnabled && overlayBuffer && overlayMappedData && overlayWidth > 0 && overlayHeight > 0;

		if (hasOverlayCopy) {

			if (copyX < 0) {

				uint32_t clipped = (uint32_t)(-copyX);
				if (clipped >= copyWidth) {

					hasOverlayCopy = false;

				} else {

					bufferOffset += (VkDeviceSize)clipped * 4;
					copyWidth -= clipped;
					copyX = 0;

				}

			}

			if (hasOverlayCopy && copyY < 0) {

				uint32_t clipped = (uint32_t)(-copyY);
				if (clipped >= copyHeight) {

					hasOverlayCopy = false;

				} else {

					bufferOffset += (VkDeviceSize)clipped * (VkDeviceSize)overlayWidth * 4;
					copyHeight -= clipped;
					copyY = 0;

				}

			}

			if (hasOverlayCopy &&
				(copyX >= (int)swapchainExtent.width || copyY >= (int)swapchainExtent.height)) {

				hasOverlayCopy = false;

			}

			if (hasOverlayCopy && (uint32_t)copyX + copyWidth > swapchainExtent.width) {

				copyWidth = swapchainExtent.width - (uint32_t)copyX;

			}

			if (hasOverlayCopy && (uint32_t)copyY + copyHeight > swapchainExtent.height) {

				copyHeight = swapchainExtent.height - (uint32_t)copyY;

			}

			hasOverlayCopy = hasOverlayCopy && copyWidth > 0 && copyHeight > 0;

		}

		VkImageMemoryBarrier imageBarrier;
		memset (&imageBarrier, 0, sizeof (imageBarrier));
		imageBarrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
		imageBarrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
		imageBarrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
		imageBarrier.image = swapchainImages[imageIndex];
		imageBarrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		imageBarrier.subresourceRange.baseMipLevel = 0;
		imageBarrier.subresourceRange.levelCount = 1;
		imageBarrier.subresourceRange.baseArrayLayer = 0;
		imageBarrier.subresourceRange.layerCount = 1;

		if (hasOverlayCopy) {

			imageBarrier.srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
			imageBarrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
			imageBarrier.oldLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
			imageBarrier.newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;

			vkCmdPipelineBarrier (
				commandBuffer,
				VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
				VK_PIPELINE_STAGE_TRANSFER_BIT,
				0,
				0, 0,
				0, 0,
				1, &imageBarrier
			);

			VkBufferImageCopy copyRegion;
			memset (&copyRegion, 0, sizeof (copyRegion));
			copyRegion.bufferOffset = bufferOffset;
			copyRegion.bufferRowLength = overlayWidth;
			copyRegion.bufferImageHeight = overlayHeight;
			copyRegion.imageSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
			copyRegion.imageSubresource.mipLevel = 0;
			copyRegion.imageSubresource.baseArrayLayer = 0;
			copyRegion.imageSubresource.layerCount = 1;
			copyRegion.imageOffset.x = copyX;
			copyRegion.imageOffset.y = copyY;
			copyRegion.imageOffset.z = 0;
			copyRegion.imageExtent.width = copyWidth;
			copyRegion.imageExtent.height = copyHeight;
			copyRegion.imageExtent.depth = 1;

			vkCmdCopyBufferToImage (commandBuffer, overlayBuffer, swapchainImages[imageIndex], VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &copyRegion);

			imageBarrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
			imageBarrier.dstAccessMask = 0;
			imageBarrier.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
			imageBarrier.newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

			vkCmdPipelineBarrier (
				commandBuffer,
				VK_PIPELINE_STAGE_TRANSFER_BIT,
				VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
				0,
				0, 0,
				0, 0,
				1, &imageBarrier
			);

		} else {

			imageBarrier.srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
			imageBarrier.dstAccessMask = 0;
			imageBarrier.oldLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
			imageBarrier.newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

			vkCmdPipelineBarrier (
				commandBuffer,
				VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
				VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
				0,
				0, 0,
				0, 0,
				1, &imageBarrier
			);

		}

		result = vkEndCommandBuffer (commandBuffer);
		if (result != VK_SUCCESS) {

			SetError (std::string ("vkEndCommandBuffer failed: ") + VulkanResultToString (result));
			return false;

		}

		return true;

	}


	bool VulkanRenderer::RecreateSwapchain () {

		if (!device) {

			return false;

		}

		int drawableWidth = 0;
		int drawableHeight = 0;
		window->GetVulkanDrawableSize (&drawableWidth, &drawableHeight);
		if (drawableWidth <= 0 || drawableHeight <= 0) {

			if (swapchain || !swapchainImages.empty () || !swapchainImageViews.empty () || !framebuffers.empty () || !commandBuffers.empty () || commandPool || renderPass) {

				if (vkDeviceWaitIdle (device) != VK_SUCCESS) {

					SetError ("vkDeviceWaitIdle failed while suspending the swapchain");
					return false;

				}

				DestroySwapchainResources ();

			}

			swapchainExtent.width = 0;
			swapchainExtent.height = 0;
			swapchainDirty = true;
			lastError.clear ();
			return true;

		}

		if (vkDeviceWaitIdle (device) != VK_SUCCESS) {

			SetError ("vkDeviceWaitIdle failed during swapchain recreation");
			return false;

		}

		DestroySwapchainResources ();
		if (!CreateSwapchainResources ()) {

			swapchainDirty = true;
			return false;

		}

		swapchainDirty = (swapchain == VK_NULL_HANDLE || swapchainExtent.width == 0 || swapchainExtent.height == 0);
		lastError.clear ();
		return true;

	}


	void VulkanRenderer::SetError (const std::string& value) {

		lastError = value;

	}


}
