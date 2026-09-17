#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif

#include <system/CFFI.h>

#include <app/Application.h>
#include <app/ApplicationEvent.h>
#include <graphics/format/JPEG.h>
#include <graphics/format/PNG.h>
#include <graphics/utils/ImageDataUtil.h>
#include <graphics/Image.h>
#include <graphics/ImageBuffer.h>
#include <graphics/RenderEvent.h>
#ifdef LIME_VULKAN
#include <graphics/vulkan/VKRenderer.h>
#endif
#include <media/containers/OGG.h>
#include <media/containers/WAV.h>
#include <media/AudioBuffer.h>
#include <system/CFFIPointer.h>
#include <system/Clipboard.h>
#include <system/ClipboardEvent.h>
#include <system/Endian.h>
#include <system/FileWatcher.h>
#include <system/JNI.h>
#include <system/Locale.h>
#include <system/OrientationEvent.h>
#include <system/SensorEvent.h>
#include <system/System.h>
#include <text/Font.h>
#include <ui/Cursor.h>
#include <ui/DropEvent.h>
#include <ui/FileDialog.h>
#include <ui/Gamepad.h>
#include <ui/GamepadEvent.h>
#include <ui/Haptic.h>
#include <ui/Joystick.h>
#include <ui/JoystickEvent.h>
#include <ui/KeyCode.h>
#include <ui/KeyEvent.h>
#include <ui/MouseEvent.h>
#include <ui/TextEvent.h>
#include <ui/TouchEvent.h>
#include <ui/Window.h>
#include <ui/WindowEvent.h>
#include <utils/compress/LZMA.h>
#include <utils/compress/Zlib.h>
#include <vm/NekoVM.h>

#ifdef HX_WINDOWS
#include <locale>
#include <codecvt>
#endif
#include <memory>

#include <algorithm>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <unordered_map>
#include <vector>

#ifdef LIME_SDL_SOUND
#include <media/SDLSound.h>
#endif

DEFINE_KIND (k_finalizer);


namespace lime {

	static std::string lastVulkanRendererError;
	static std::string lastVKError;


	static void LogVulkanNativeBootstrap (const char* message) {

#ifdef LIME_VULKAN
		::FILE* file = ::fopen ("lime-vulkan-native.log", "a");
		if (file) {

			::fprintf (file, "%s\n", message ? message : "<null>");
			::fclose (file);

		}
#endif

	}


	static void LogVulkanNativeBootstrap (const std::string& message) {

		LogVulkanNativeBootstrap (message.c_str ());

	}


	static uint64_t CombineVulkanHandle (int high, int low) {

		return ((uint64_t)(uint32_t)high << 32) | (uint32_t)low;

	}


	static value CreateVulkanHandleValue (uint64_t handleValue) {

		value result = alloc_empty_object ();
		alloc_field (result, val_id ("low"), alloc_int ((int32_t)(handleValue & 0xFFFFFFFFULL)));
		alloc_field (result, val_id ("high"), alloc_int ((int32_t)(handleValue >> 32)));
		return result;

	}


	static vdynamic* HLCreateVulkanHandleValue (uint64_t handleValue) {

		const int id_low = hl_hash_utf8 ("low");
		const int id_high = hl_hash_utf8 ("high");
		vdynamic* result = (vdynamic*)hl_alloc_dynobj ();
		hl_dyn_seti (result, id_low, &hlt_i32, (int32_t)(handleValue & 0xFFFFFFFFULL));
		hl_dyn_seti (result, id_high, &hlt_i32, (int32_t)(handleValue >> 32));
		return result;

	}


#ifdef LIME_VULKAN
	static VkSurfaceKHR UInt64ToVulkanSurface (uint64_t value) {

		return (VkSurfaceKHR)value;

	}


	struct ManagedVulkanMappedMemory {

		VkDevice device;
		VkDeviceMemory memory;
		VkDeviceSize offset;
		VkDeviceSize size;
		void* data;

	};


	static std::unordered_map<uint64_t, ManagedVulkanMappedMemory> mappedVulkanMemory;
	static std::unordered_map<uint64_t, std::unordered_map<std::string, PFN_vkVoidFunction> > managedVulkanDeviceProcCache;


	static uint64_t GetManagedVulkanMappedMemoryKey (VkDeviceMemory memory) {

		return (uint64_t)(uintptr_t)memory;

	}


	static VkDeviceSize NormalizeVulkanRangeSize (uint64_t size) {

		return size == 0 ? VK_WHOLE_SIZE : (VkDeviceSize)size;

	}


	static void ClearManagedVulkanDeviceProcCache (VkDevice device) {

		if (device) managedVulkanDeviceProcCache.erase ((uint64_t)(uintptr_t)device);

	}


	static bool CreateManagedVulkanInstance (Window* targetWindow, const char* applicationName, VkInstance* outInstance) {

		if (!targetWindow || !outInstance) {

			lastVKError = "Missing Vulkan window or output instance";
			return false;

		}

		*outInstance = VK_NULL_HANDLE;

		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr ();
		if (!vkGetInstanceProcAddr) {

			lastVKError = "SDL did not expose vkGetInstanceProcAddr";
			return false;

		}

		PFN_vkCreateInstance vkCreateInstance = (PFN_vkCreateInstance)vkGetInstanceProcAddr (VK_NULL_HANDLE, "vkCreateInstance");
		PFN_vkEnumerateInstanceExtensionProperties vkEnumerateInstanceExtensionProperties =
			(PFN_vkEnumerateInstanceExtensionProperties)vkGetInstanceProcAddr (VK_NULL_HANDLE, "vkEnumerateInstanceExtensionProperties");
		PFN_vkEnumerateInstanceVersion vkEnumerateInstanceVersion =
			(PFN_vkEnumerateInstanceVersion)vkGetInstanceProcAddr (VK_NULL_HANDLE, "vkEnumerateInstanceVersion");

		if (!vkCreateInstance || !vkEnumerateInstanceExtensionProperties) {

			lastVKError = "Missing required Vulkan global functions";
			return false;

		}

		unsigned int requiredExtensionCount = 0;
		if (!targetWindow->GetVulkanInstanceExtensions (&requiredExtensionCount, 0)) {

			lastVKError = "Failed to query required Vulkan window extensions";
			return false;

		}

		std::vector<const char*> requiredExtensions (requiredExtensionCount);
		if (requiredExtensionCount > 0 && !targetWindow->GetVulkanInstanceExtensions (&requiredExtensionCount, requiredExtensions.data ())) {

			lastVKError = "Failed to fetch required Vulkan window extensions";
			return false;

		}

		std::vector<const char*> instanceExtensions;
		for (size_t i = 0; i < requiredExtensions.size (); ++i) {

			instanceExtensions.push_back (requiredExtensions[i]);

		}

		bool portabilityEnumerationSupported = false;
		uint32_t availableExtensionCount = 0;
		if (vkEnumerateInstanceExtensionProperties (0, &availableExtensionCount, 0) == VK_SUCCESS && availableExtensionCount > 0) {

			std::vector<VkExtensionProperties> availableExtensions (availableExtensionCount);
			if (vkEnumerateInstanceExtensionProperties (0, &availableExtensionCount, availableExtensions.data ()) == VK_SUCCESS) {

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
		applicationInfo.pApplicationName = applicationName ? applicationName : "Lime";
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

		VkResult result = vkCreateInstance (&createInfo, 0, outInstance);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateInstance failed";
			return false;

		}

		lastVKError.clear ();
		return true;

	}


	static std::vector<std::string> GetVulkanDeviceExtensions (value extensions) {

		std::vector<std::string> deviceExtensions;

		if (val_is_null (extensions)) {

			deviceExtensions.push_back (VK_KHR_SWAPCHAIN_EXTENSION_NAME);
			return deviceExtensions;

		}

		int length = val_array_size (extensions);
		for (int i = 0; i < length; ++i) {

			value extension = val_array_i (extensions, i);
			if (!val_is_null (extension)) {

				deviceExtensions.push_back (val_string (extension));

			}

		}

		return deviceExtensions;

	}


	static std::vector<std::string> GetHLVulkanDeviceExtensions (hl_varray* extensions) {

		std::vector<std::string> deviceExtensions;

		if (!extensions) {

			deviceExtensions.push_back (VK_KHR_SWAPCHAIN_EXTENSION_NAME);
			return deviceExtensions;

		}

		int length = extensions->size;
		hl_vstring** extensionData = hl_aptr (extensions, hl_vstring*);

		for (int i = 0; i < length; ++i) {

			hl_vstring* extension = *extensionData++;
			if (extension) {

				deviceExtensions.push_back (hl_to_utf8 ((const uchar*)extension->bytes));

			}

		}

		return deviceExtensions;

	}


	static PFN_vkVoidFunction GetManagedVulkanDeviceProc (Window* targetWindow, VkInstance instance, VkDevice device, const char* name) {

		if (!targetWindow || !instance || !device || !name) {

			lastVKError = "Missing Vulkan window, instance, or device";
			return 0;

		}

		uint64_t deviceKey = (uint64_t)(uintptr_t)device;
		std::string procName (name);
		std::unordered_map<uint64_t, std::unordered_map<std::string, PFN_vkVoidFunction> >::iterator deviceCache =
			managedVulkanDeviceProcCache.find (deviceKey);
		if (deviceCache != managedVulkanDeviceProcCache.end ()) {

			std::unordered_map<std::string, PFN_vkVoidFunction>::iterator procCache = deviceCache->second.find (procName);
			if (procCache != deviceCache->second.end ()) return procCache->second;

		}

		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr ();
		if (!vkGetInstanceProcAddr) {

			lastVKError = "SDL did not expose vkGetInstanceProcAddr";
			return 0;

		}

		PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr = (PFN_vkGetDeviceProcAddr)vkGetInstanceProcAddr (instance, "vkGetDeviceProcAddr");
		if (!vkGetDeviceProcAddr) {

			lastVKError = "Missing Vulkan device proc address function";
			return 0;

		}

		PFN_vkVoidFunction proc = vkGetDeviceProcAddr (device, procName.c_str ());
		if (!proc) {

			lastVKError = std::string ("Missing Vulkan device function: ") + procName;
			return 0;

		}

		managedVulkanDeviceProcCache[deviceKey][procName] = proc;
		return proc;

	}


	static bool UpdateManagedVulkanDescriptorSets (Window* targetWindow, VkInstance instance, VkDevice device, const std::vector<int>& packed) {

		if (packed.empty ()) return true;

		PFN_vkUpdateDescriptorSets vkUpdateDescriptorSets =
			(PFN_vkUpdateDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUpdateDescriptorSets");
		if (!vkUpdateDescriptorSets) return false;

		int writeCount = packed[0];
		if (writeCount < 0) return false;

		std::vector<VkDescriptorBufferInfo> bufferInfos;
		std::vector<VkDescriptorImageInfo> imageInfos;
		std::vector<VkWriteDescriptorSet> descriptorWrites;
		bufferInfos.reserve ((size_t)writeCount);
		imageInfos.reserve ((size_t)writeCount);
		descriptorWrites.reserve ((size_t)writeCount);

		size_t index = 1;
		for (int i = 0; i < writeCount; ++i) {

			if (index >= packed.size ()) return false;
			int kind = packed[index++];

			VkWriteDescriptorSet write;
			memset (&write, 0, sizeof (write));
			write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
			write.descriptorCount = 1;

			if (kind == 0) {

				if (index + 11 > packed.size ()) return false;
				write.dstSet = (VkDescriptorSet)(uintptr_t)CombineVulkanHandle (packed[index], packed[index + 1]);
				write.dstBinding = (uint32_t)packed[index + 2];
				write.dstArrayElement = (uint32_t)packed[index + 3];
				write.descriptorType = (VkDescriptorType)packed[index + 4];

				VkDescriptorBufferInfo bufferInfo;
				memset (&bufferInfo, 0, sizeof (bufferInfo));
				bufferInfo.buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (packed[index + 5], packed[index + 6]);
				bufferInfo.offset = (VkDeviceSize)CombineVulkanHandle (packed[index + 7], packed[index + 8]);
				bufferInfo.range = NormalizeVulkanRangeSize (CombineVulkanHandle (packed[index + 9], packed[index + 10]));
				bufferInfos.push_back (bufferInfo);
				write.pBufferInfo = &bufferInfos[bufferInfos.size () - 1];
				index += 11;

			} else if (kind == 1) {

				if (index + 10 > packed.size ()) return false;
				write.dstSet = (VkDescriptorSet)(uintptr_t)CombineVulkanHandle (packed[index], packed[index + 1]);
				write.dstBinding = (uint32_t)packed[index + 2];
				write.dstArrayElement = (uint32_t)packed[index + 3];
				write.descriptorType = (VkDescriptorType)packed[index + 4];

				VkDescriptorImageInfo imageInfo;
				memset (&imageInfo, 0, sizeof (imageInfo));
				imageInfo.imageView = (VkImageView)(uintptr_t)CombineVulkanHandle (packed[index + 5], packed[index + 6]);
				imageInfo.sampler = (VkSampler)(uintptr_t)CombineVulkanHandle (packed[index + 7], packed[index + 8]);
				imageInfo.imageLayout = (VkImageLayout)packed[index + 9];
				imageInfos.push_back (imageInfo);
				write.pImageInfo = &imageInfos[imageInfos.size () - 1];
				index += 10;

			} else {

				lastVKError = "Invalid Vulkan descriptor write kind";
				return false;

			}

			if (!write.dstSet) return false;
			descriptorWrites.push_back (write);

		}

		vkUpdateDescriptorSets (device, (uint32_t)descriptorWrites.size (), descriptorWrites.empty () ? 0 : descriptorWrites.data (), 0, 0);
		lastVKError.clear ();
		return true;

	}


	static bool CreateManagedVulkanDevice (Window* targetWindow, VkInstance instance, VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex,
		const std::vector<std::string>& requestedExtensions, VkDevice* outDevice, VkQueue* outQueue) {

		LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: begin");
		if (!targetWindow || !instance || !physicalDevice || !outDevice || !outQueue) {

			lastVKError = "Missing Vulkan instance, physical device, or output device";
			LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: missing input");
			return false;

		}

		*outDevice = VK_NULL_HANDLE;
		*outQueue = VK_NULL_HANDLE;

		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr ();
		LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: acquired vkGetInstanceProcAddr");
		if (!vkGetInstanceProcAddr) {

			lastVKError = "SDL did not expose vkGetInstanceProcAddr";
			LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: missing vkGetInstanceProcAddr");
			return false;

		}

		PFN_vkCreateDevice vkCreateDevice = (PFN_vkCreateDevice)vkGetInstanceProcAddr (instance, "vkCreateDevice");
		PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr = (PFN_vkGetDeviceProcAddr)vkGetInstanceProcAddr (instance, "vkGetDeviceProcAddr");
		PFN_vkEnumerateDeviceExtensionProperties vkEnumerateDeviceExtensionProperties =
			(PFN_vkEnumerateDeviceExtensionProperties)vkGetInstanceProcAddr (instance, "vkEnumerateDeviceExtensionProperties");
		PFN_vkGetPhysicalDeviceQueueFamilyProperties vkGetPhysicalDeviceQueueFamilyProperties =
			(PFN_vkGetPhysicalDeviceQueueFamilyProperties)vkGetInstanceProcAddr (instance, "vkGetPhysicalDeviceQueueFamilyProperties");
		LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: loaded device creation procs");

		if (!vkCreateDevice || !vkGetDeviceProcAddr || !vkEnumerateDeviceExtensionProperties || !vkGetPhysicalDeviceQueueFamilyProperties) {

			lastVKError = "Missing required Vulkan device creation functions";
			LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: missing required procs");
			return false;

		}

		uint32_t queueFamilyCount = 0;
		LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: query queue family count");
		vkGetPhysicalDeviceQueueFamilyProperties (physicalDevice, &queueFamilyCount, 0);
		if (queueFamilyIndex >= queueFamilyCount) {

			lastVKError = "Invalid Vulkan queue family index";
			LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: invalid queue family index");
			return false;

		}

		float queuePriority = 1.0f;
		VkDeviceQueueCreateInfo queueCreateInfo;
		memset (&queueCreateInfo, 0, sizeof (queueCreateInfo));
		queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
		queueCreateInfo.queueFamilyIndex = queueFamilyIndex;
		queueCreateInfo.queueCount = 1;
		queueCreateInfo.pQueuePriorities = &queuePriority;

		std::vector<const char*> deviceExtensions;
		for (size_t i = 0; i < requestedExtensions.size (); ++i) {

			deviceExtensions.push_back (requestedExtensions[i].c_str ());

		}

		uint32_t extensionCount = 0;
		LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: enumerate device extension count");
		VkResult extensionResult = vkEnumerateDeviceExtensionProperties (physicalDevice, 0, &extensionCount, 0);
		if (extensionResult != VK_SUCCESS) {

			lastVKError = "Could not enumerate Vulkan device extensions";
			LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: extension count enumeration failed");
			return false;

		}

		std::vector<VkExtensionProperties> availableExtensions (extensionCount);
		if (extensionCount > 0) {

			LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: enumerate device extensions");
			extensionResult = vkEnumerateDeviceExtensionProperties (physicalDevice, 0, &extensionCount, availableExtensions.data ());
			if (extensionResult != VK_SUCCESS) {

				lastVKError = "Could not enumerate Vulkan device extensions";
				LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: extension enumeration failed");
				return false;

			}

		}

		#ifdef VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME
		bool portabilitySubsetSupported = false;
		bool portabilitySubsetRequested = false;
		#endif

		for (size_t i = 0; i < requestedExtensions.size (); ++i) {

			bool extensionSupported = false;

			for (size_t e = 0; e < availableExtensions.size (); ++e) {

				if (strcmp (availableExtensions[e].extensionName, requestedExtensions[i].c_str ()) == 0) {

					extensionSupported = true;
					break;

				}

			}

			if (!extensionSupported) {

				lastVKError = std::string ("Vulkan physical device does not support ") + requestedExtensions[i];
				LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: requested extension missing");
				return false;

			}

			#ifdef VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME
			if (strcmp (requestedExtensions[i].c_str (), VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME) == 0) {

				portabilitySubsetRequested = true;

			}
			#endif

		}

		#ifdef VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME
		for (size_t i = 0; i < availableExtensions.size (); ++i) {

			if (strcmp (availableExtensions[i].extensionName, VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME) == 0) {

				portabilitySubsetSupported = true;
				break;

			}

		}

		if (portabilitySubsetSupported && !portabilitySubsetRequested) {

			deviceExtensions.push_back (VK_KHR_PORTABILITY_SUBSET_EXTENSION_NAME);

		}
		#endif

		VkPhysicalDeviceFeatures deviceFeatures;
		memset (&deviceFeatures, 0, sizeof (deviceFeatures));

		VkDeviceCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
		createInfo.queueCreateInfoCount = 1;
		createInfo.pQueueCreateInfos = &queueCreateInfo;
		createInfo.pEnabledFeatures = &deviceFeatures;
		createInfo.enabledExtensionCount = (uint32_t)deviceExtensions.size ();
		createInfo.ppEnabledExtensionNames = deviceExtensions.empty () ? 0 : deviceExtensions.data ();

		VkResult result = vkCreateDevice (physicalDevice, &createInfo, 0, outDevice);
		LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: returned from vkCreateDevice");
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateDevice failed";
			LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: vkCreateDevice failed");
			return false;

		}

		PFN_vkGetDeviceQueue vkGetDeviceQueue = (PFN_vkGetDeviceQueue)vkGetDeviceProcAddr (*outDevice, "vkGetDeviceQueue");
		LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: loaded vkGetDeviceQueue");
		if (!vkGetDeviceQueue) {

			PFN_vkDestroyDevice vkDestroyDevice = (PFN_vkDestroyDevice)vkGetDeviceProcAddr (*outDevice, "vkDestroyDevice");
			if (vkDestroyDevice) vkDestroyDevice (*outDevice, 0);
			*outDevice = VK_NULL_HANDLE;
			lastVKError = "Missing Vulkan device queue function";
			LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: missing vkGetDeviceQueue");
			return false;

		}

		LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: get device queue");
		vkGetDeviceQueue (*outDevice, queueFamilyIndex, 0, outQueue);
		if (!*outQueue) {

			PFN_vkDestroyDevice vkDestroyDevice = (PFN_vkDestroyDevice)vkGetDeviceProcAddr (*outDevice, "vkDestroyDevice");
			if (vkDestroyDevice) vkDestroyDevice (*outDevice, 0);
			*outDevice = VK_NULL_HANDLE;
			lastVKError = "Failed to get Vulkan device queue";
			LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: device queue was null");
			return false;

		}

		lastVKError.clear ();
		LogVulkanNativeBootstrap ("CreateManagedVulkanDevice: success");
		return true;

	}


	struct ManagedVulkanSwapchain {

		VkSwapchainKHR handle;
		VkFormat format;
		VkColorSpaceKHR colorSpace;
		VkExtent2D extent;
		VkPresentModeKHR presentMode;
		uint32_t imageCount;

	};


	static VkPresentModeKHR ChooseManagedVulkanPresentMode (const std::vector<VkPresentModeKHR>& presentModes, VkPresentModeKHR requestedPresentMode) {

		bool hasRequested = false;
		bool hasFifo = false;
		bool hasMailbox = false;
		bool hasImmediate = false;

		for (size_t i = 0; i < presentModes.size (); ++i) {

			if (presentModes[i] == requestedPresentMode) hasRequested = true;
			if (presentModes[i] == VK_PRESENT_MODE_FIFO_KHR) hasFifo = true;
			if (presentModes[i] == VK_PRESENT_MODE_MAILBOX_KHR) hasMailbox = true;
			if (presentModes[i] == VK_PRESENT_MODE_IMMEDIATE_KHR) hasImmediate = true;

		}

		if (hasRequested) return requestedPresentMode;
		if (hasFifo) return VK_PRESENT_MODE_FIFO_KHR;
		if (hasMailbox) return VK_PRESENT_MODE_MAILBOX_KHR;
		if (hasImmediate) return VK_PRESENT_MODE_IMMEDIATE_KHR;
		return VK_PRESENT_MODE_FIFO_KHR;

	}


	static value CreateVulkanSwapchainValue (const ManagedVulkanSwapchain& swapchain) {

		value result = alloc_empty_object ();
		alloc_field (result, val_id ("handle"), CreateVulkanHandleValue ((uint64_t)(uintptr_t)swapchain.handle));
		alloc_field (result, val_id ("format"), alloc_int ((int)swapchain.format));
		alloc_field (result, val_id ("colorSpace"), alloc_int ((int)swapchain.colorSpace));
		alloc_field (result, val_id ("width"), alloc_int ((int)swapchain.extent.width));
		alloc_field (result, val_id ("height"), alloc_int ((int)swapchain.extent.height));
		alloc_field (result, val_id ("imageCount"), alloc_int ((int)swapchain.imageCount));
		alloc_field (result, val_id ("presentMode"), alloc_int ((int)swapchain.presentMode));
		return result;

	}


	static vdynamic* HLCreateVulkanSwapchainValue (const ManagedVulkanSwapchain& swapchain) {

		const int id_handle = hl_hash_utf8 ("handle");
		const int id_format = hl_hash_utf8 ("format");
		const int id_colorSpace = hl_hash_utf8 ("colorSpace");
		const int id_width = hl_hash_utf8 ("width");
		const int id_height = hl_hash_utf8 ("height");
		const int id_imageCount = hl_hash_utf8 ("imageCount");
		const int id_presentMode = hl_hash_utf8 ("presentMode");

		vdynamic* result = (vdynamic*)hl_alloc_dynobj ();
		hl_dyn_setp (result, id_handle, &hlt_dynobj, HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)swapchain.handle));
		hl_dyn_seti (result, id_format, &hlt_i32, (int)swapchain.format);
		hl_dyn_seti (result, id_colorSpace, &hlt_i32, (int)swapchain.colorSpace);
		hl_dyn_seti (result, id_width, &hlt_i32, (int)swapchain.extent.width);
		hl_dyn_seti (result, id_height, &hlt_i32, (int)swapchain.extent.height);
		hl_dyn_seti (result, id_imageCount, &hlt_i32, (int)swapchain.imageCount);
		hl_dyn_seti (result, id_presentMode, &hlt_i32, (int)swapchain.presentMode);
		return result;

	}


	static value CreateVulkanAcquireValue (VkResult acquireResult, int imageIndex) {

		value result = alloc_empty_object ();
		alloc_field (result, val_id ("result"), alloc_int ((int)acquireResult));
		alloc_field (result, val_id ("imageIndex"), alloc_int (imageIndex));
		return result;

	}


	static vdynamic* HLCreateVulkanAcquireValue (VkResult acquireResult, int imageIndex) {

		const int id_result = hl_hash_utf8 ("result");
		const int id_imageIndex = hl_hash_utf8 ("imageIndex");

		vdynamic* result = (vdynamic*)hl_alloc_dynobj ();
		hl_dyn_seti (result, id_result, &hlt_i32, (int)acquireResult);
		hl_dyn_seti (result, id_imageIndex, &hlt_i32, imageIndex);
		return result;

	}


	static value CreateVulkanMemoryRequirementsValue (const VkMemoryRequirements& requirements) {

		value result = alloc_empty_object ();
		alloc_field (result, val_id ("size"), CreateVulkanHandleValue ((uint64_t)requirements.size));
		alloc_field (result, val_id ("alignment"), CreateVulkanHandleValue ((uint64_t)requirements.alignment));
		alloc_field (result, val_id ("memoryTypeBits"), alloc_int ((int)requirements.memoryTypeBits));
		return result;

	}


	static vdynamic* HLCreateVulkanMemoryRequirementsValue (const VkMemoryRequirements& requirements) {

		const int id_size = hl_hash_utf8 ("size");
		const int id_alignment = hl_hash_utf8 ("alignment");
		const int id_memoryTypeBits = hl_hash_utf8 ("memoryTypeBits");

		vdynamic* result = (vdynamic*)hl_alloc_dynobj ();
		hl_dyn_setp (result, id_size, &hlt_dynobj, HLCreateVulkanHandleValue ((uint64_t)requirements.size));
		hl_dyn_setp (result, id_alignment, &hlt_dynobj, HLCreateVulkanHandleValue ((uint64_t)requirements.alignment));
		hl_dyn_seti (result, id_memoryTypeBits, &hlt_i32, (int)requirements.memoryTypeBits);
		return result;

	}


	static value CreateVulkanMemoryValue (VkDeviceMemory memory, uint32_t memoryTypeIndex) {

		value result = alloc_empty_object ();
		alloc_field (result, val_id ("handle"), CreateVulkanHandleValue ((uint64_t)(uintptr_t)memory));
		alloc_field (result, val_id ("memoryTypeIndex"), alloc_int ((int)memoryTypeIndex));
		return result;

	}


	static vdynamic* HLCreateVulkanMemoryValue (VkDeviceMemory memory, uint32_t memoryTypeIndex) {

		const int id_handle = hl_hash_utf8 ("handle");
		const int id_memoryTypeIndex = hl_hash_utf8 ("memoryTypeIndex");

		vdynamic* result = (vdynamic*)hl_alloc_dynobj ();
		hl_dyn_setp (result, id_handle, &hlt_dynobj, HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)memory));
		hl_dyn_seti (result, id_memoryTypeIndex, &hlt_i32, (int)memoryTypeIndex);
		return result;

	}


	static std::vector<int> GetVulkanIntVector (value data) {

		std::vector<int> result;
		if (val_is_null (data)) return result;

		int length = val_array_size (data);
		result.reserve (length);
		for (int i = 0; i < length; ++i) {

			result.push_back (val_int (val_array_i (data, i)));

		}

		return result;

	}


	static std::vector<int> GetHLVulkanIntVector (hl_varray* data) {

		std::vector<int> result;
		if (!data) return result;

		result.reserve (data->size);
		int* values = hl_aptr (data, int);
		for (int i = 0; i < data->size; ++i) {

			result.push_back (values[i]);

		}

		return result;

	}


	static std::vector<double> GetVulkanDoubleVector (value data) {

		std::vector<double> result;
		if (val_is_null (data)) return result;

		int length = val_array_size (data);
		result.reserve (length);
		for (int i = 0; i < length; ++i) {

			result.push_back (val_number (val_array_i (data, i)));

		}

		return result;

	}


	static std::vector<double> GetHLVulkanDoubleVector (hl_varray* data) {

		std::vector<double> result;
		if (!data) return result;

		result.reserve (data->size);
		double* values = hl_aptr (data, double);
		for (int i = 0; i < data->size; ++i) {

			result.push_back (values[i]);

		}

		return result;

	}


	static bool FindManagedVulkanMemoryType (Window* targetWindow, VkInstance instance, VkPhysicalDevice physicalDevice, uint32_t typeFilter,
		VkMemoryPropertyFlags properties, uint32_t* outMemoryTypeIndex) {

		if (!targetWindow || !instance || !physicalDevice || !outMemoryTypeIndex) {

			lastVKError = "Missing Vulkan window, instance, physical device, or memory type output";
			return false;

		}

		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr ();
		if (!vkGetInstanceProcAddr) {

			lastVKError = "SDL did not expose vkGetInstanceProcAddr";
			return false;

		}

		PFN_vkGetPhysicalDeviceMemoryProperties vkGetPhysicalDeviceMemoryProperties =
			(PFN_vkGetPhysicalDeviceMemoryProperties)vkGetInstanceProcAddr (instance, "vkGetPhysicalDeviceMemoryProperties");
		if (!vkGetPhysicalDeviceMemoryProperties) {

			lastVKError = "Missing Vulkan physical device memory properties function";
			return false;

		}

		VkPhysicalDeviceMemoryProperties memoryProperties;
		memset (&memoryProperties, 0, sizeof (memoryProperties));
		vkGetPhysicalDeviceMemoryProperties (physicalDevice, &memoryProperties);

		for (uint32_t i = 0; i < memoryProperties.memoryTypeCount; ++i) {

			if ((typeFilter & (1u << i)) && (memoryProperties.memoryTypes[i].propertyFlags & properties) == properties) {

				*outMemoryTypeIndex = i;
				lastVKError.clear ();
				return true;

			}

		}

		lastVKError = "Failed to find a compatible Vulkan memory type";
		return false;

	}


	static bool CreateManagedVulkanSwapchain (Window* targetWindow, VkInstance instance, VkPhysicalDevice physicalDevice, VkDevice device,
		VkSurfaceKHR surface, uint32_t queueFamilyIndex, int requestedWidth, int requestedHeight, VkPresentModeKHR requestedPresentMode,
		VkSwapchainKHR oldSwapchain, ManagedVulkanSwapchain* outSwapchain) {

		if (!targetWindow || !instance || !physicalDevice || !device || !surface || !outSwapchain) {

			lastVKError = "Missing Vulkan window, instance, device, surface, or output swapchain";
			return false;

		}

		outSwapchain->handle = VK_NULL_HANDLE;
		outSwapchain->format = VK_FORMAT_UNDEFINED;
		outSwapchain->colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
		outSwapchain->extent.width = 0;
		outSwapchain->extent.height = 0;
		outSwapchain->presentMode = VK_PRESENT_MODE_FIFO_KHR;
		outSwapchain->imageCount = 0;

		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr ();
		if (!vkGetInstanceProcAddr) {

			lastVKError = "SDL did not expose vkGetInstanceProcAddr";
			return false;

		}

		PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR vkGetPhysicalDeviceSurfaceCapabilitiesKHR =
			(PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR)vkGetInstanceProcAddr (instance, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR");
		PFN_vkGetPhysicalDeviceSurfaceFormatsKHR vkGetPhysicalDeviceSurfaceFormatsKHR =
			(PFN_vkGetPhysicalDeviceSurfaceFormatsKHR)vkGetInstanceProcAddr (instance, "vkGetPhysicalDeviceSurfaceFormatsKHR");
		PFN_vkGetPhysicalDeviceSurfacePresentModesKHR vkGetPhysicalDeviceSurfacePresentModesKHR =
			(PFN_vkGetPhysicalDeviceSurfacePresentModesKHR)vkGetInstanceProcAddr (instance, "vkGetPhysicalDeviceSurfacePresentModesKHR");
		PFN_vkGetPhysicalDeviceSurfaceSupportKHR vkGetPhysicalDeviceSurfaceSupportKHR =
			(PFN_vkGetPhysicalDeviceSurfaceSupportKHR)vkGetInstanceProcAddr (instance, "vkGetPhysicalDeviceSurfaceSupportKHR");

		if (!vkGetPhysicalDeviceSurfaceCapabilitiesKHR || !vkGetPhysicalDeviceSurfaceFormatsKHR || !vkGetPhysicalDeviceSurfacePresentModesKHR) {

			lastVKError = "Missing required Vulkan surface functions";
			return false;

		}

		if (vkGetPhysicalDeviceSurfaceSupportKHR) {

			VkBool32 supportsPresent = VK_FALSE;
			VkResult supportResult = vkGetPhysicalDeviceSurfaceSupportKHR (physicalDevice, queueFamilyIndex, surface, &supportsPresent);
			if (supportResult != VK_SUCCESS || supportsPresent == VK_FALSE) {

				lastVKError = "Vulkan queue family does not support presenting to this surface";
				return false;

			}

		}

		VkSurfaceCapabilitiesKHR capabilities;
		memset (&capabilities, 0, sizeof (capabilities));
		VkResult result = vkGetPhysicalDeviceSurfaceCapabilitiesKHR (physicalDevice, surface, &capabilities);
		if (result != VK_SUCCESS) {

			lastVKError = "vkGetPhysicalDeviceSurfaceCapabilitiesKHR failed";
			return false;

		}

		uint32_t formatCount = 0;
		result = vkGetPhysicalDeviceSurfaceFormatsKHR (physicalDevice, surface, &formatCount, 0);
		if (result != VK_SUCCESS || formatCount == 0) {

			lastVKError = "Failed to query Vulkan surface formats";
			return false;

		}

		std::vector<VkSurfaceFormatKHR> formats (formatCount);
		result = vkGetPhysicalDeviceSurfaceFormatsKHR (physicalDevice, surface, &formatCount, formats.data ());
		if (result != VK_SUCCESS) {

			lastVKError = "vkGetPhysicalDeviceSurfaceFormatsKHR failed";
			return false;

		}

		VkSurfaceFormatKHR surfaceFormat = formats[0];
		if (formats.size () == 1 && formats[0].format == VK_FORMAT_UNDEFINED) {

			surfaceFormat.format = VK_FORMAT_B8G8R8A8_UNORM;
			surfaceFormat.colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;

		} else {

			for (size_t i = 0; i < formats.size (); ++i) {

				if (formats[i].format == VK_FORMAT_B8G8R8A8_UNORM && formats[i].colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {

					surfaceFormat = formats[i];
					break;

				}

			}

		}

		uint32_t presentModeCount = 0;
		result = vkGetPhysicalDeviceSurfacePresentModesKHR (physicalDevice, surface, &presentModeCount, 0);
		if (result != VK_SUCCESS) {

			lastVKError = "Failed to query Vulkan present modes";
			return false;

		}

		std::vector<VkPresentModeKHR> presentModes (presentModeCount > 0 ? presentModeCount : 1, VK_PRESENT_MODE_FIFO_KHR);
		if (presentModeCount > 0) {

			result = vkGetPhysicalDeviceSurfacePresentModesKHR (physicalDevice, surface, &presentModeCount, presentModes.data ());
			if (result != VK_SUCCESS) {

				lastVKError = "vkGetPhysicalDeviceSurfacePresentModesKHR failed";
				return false;

			}

		}

		int drawableWidth = requestedWidth;
		int drawableHeight = requestedHeight;
		if (drawableWidth <= 0 || drawableHeight <= 0) {

			drawableWidth = 0;
			drawableHeight = 0;
			targetWindow->GetVulkanDrawableSize (&drawableWidth, &drawableHeight);

		}

		if (drawableWidth <= 0 || drawableHeight <= 0) {

			lastVKError = "Vulkan drawable size is zero";
			return false;

		}

		VkExtent2D extent;
		if (capabilities.currentExtent.width != UINT32_MAX) {

			extent = capabilities.currentExtent;

		} else {

			extent.width = (uint32_t)(std::max) ((int)capabilities.minImageExtent.width,
				(std::min) (drawableWidth, (int)capabilities.maxImageExtent.width));
			extent.height = (uint32_t)(std::max) ((int)capabilities.minImageExtent.height,
				(std::min) (drawableHeight, (int)capabilities.maxImageExtent.height));

		}

		if ((capabilities.supportedUsageFlags & VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) == 0) {

			lastVKError = "Vulkan surface images do not support color attachments";
			return false;

		}

		VkImageUsageFlags imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
		if (capabilities.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_DST_BIT) {

			imageUsage |= VK_IMAGE_USAGE_TRANSFER_DST_BIT;

		}
		if (capabilities.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_SRC_BIT) {

			imageUsage |= VK_IMAGE_USAGE_TRANSFER_SRC_BIT;

		}

		uint32_t imageCount = capabilities.minImageCount + 1;
		if (capabilities.maxImageCount > 0 && imageCount > capabilities.maxImageCount) {

			imageCount = capabilities.maxImageCount;

		}

		VkCompositeAlphaFlagBitsKHR compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
		const bool transparentWindow = targetWindow && ((targetWindow->flags & WINDOW_FLAG_TRANSPARENT) != 0);
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

		PFN_vkCreateSwapchainKHR vkCreateSwapchainKHR = (PFN_vkCreateSwapchainKHR)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCreateSwapchainKHR");
		PFN_vkGetSwapchainImagesKHR vkGetSwapchainImagesKHR = (PFN_vkGetSwapchainImagesKHR)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkGetSwapchainImagesKHR");
		if (!vkCreateSwapchainKHR || !vkGetSwapchainImagesKHR) return false;

		VkSwapchainCreateInfoKHR createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
		createInfo.surface = surface;
		createInfo.minImageCount = imageCount;
		createInfo.imageFormat = surfaceFormat.format;
		createInfo.imageColorSpace = surfaceFormat.colorSpace;
		createInfo.imageExtent = extent;
		createInfo.imageArrayLayers = 1;
		createInfo.imageUsage = imageUsage;
		createInfo.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
		createInfo.preTransform = capabilities.currentTransform;
		createInfo.compositeAlpha = compositeAlpha;
		createInfo.presentMode = ChooseManagedVulkanPresentMode (presentModes, requestedPresentMode);
		createInfo.clipped = VK_TRUE;
		createInfo.oldSwapchain = oldSwapchain;

		VkSwapchainKHR swapchain = VK_NULL_HANDLE;
		result = vkCreateSwapchainKHR (device, &createInfo, 0, &swapchain);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateSwapchainKHR failed";
			return false;

		}

		uint32_t swapchainImageCount = 0;
		result = vkGetSwapchainImagesKHR (device, swapchain, &swapchainImageCount, 0);
		if (result != VK_SUCCESS || swapchainImageCount == 0) {

			PFN_vkDestroySwapchainKHR vkDestroySwapchainKHR = (PFN_vkDestroySwapchainKHR)GetManagedVulkanDeviceProc (targetWindow, instance, device,
				"vkDestroySwapchainKHR");
			if (vkDestroySwapchainKHR) vkDestroySwapchainKHR (device, swapchain, 0);
			lastVKError = "Failed to query Vulkan swapchain images";
			return false;

		}

		outSwapchain->handle = swapchain;
		outSwapchain->format = surfaceFormat.format;
		outSwapchain->colorSpace = surfaceFormat.colorSpace;
		outSwapchain->extent = extent;
		outSwapchain->presentMode = createInfo.presentMode;
		outSwapchain->imageCount = swapchainImageCount;
		lastVKError.clear ();
		return true;

	}
#endif


	void gc_application (value handle) {

		Application* application = (Application*)val_data (handle);
		delete application;

	}


	void hl_gc_application (HL_CFFIPointer* handle) {

		Application* application = (Application*)handle->ptr;
		delete application;

	}


	void gc_file_watcher (value handle) {

		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)val_data (handle);
		delete watcher;
		#endif

	}


	void hl_gc_file_watcher (HL_CFFIPointer* handle) {

		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)handle->ptr;
		delete watcher;
		#endif

	}


	void gc_font (value handle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (handle);
		delete font;
		#endif

	}


	void hl_gc_font (HL_CFFIPointer* handle) {

		#ifdef LIME_FREETYPE
		Font* font = (Font*)handle->ptr;
		delete font;
		#endif

	}


	void gc_window (value handle) {

		Window* window = (Window*)val_data (handle);
		delete window;

	}


	void hl_gc_window (HL_CFFIPointer* handle) {

		Window* window = (Window*)handle->ptr;
		delete window;

	}


	std::string wstring_utf8 (const std::wstring& val) {

		std::string out;
		unsigned int codepoint = 0;

		for (const wchar_t chr : val) {

			if (chr >= 0xd800 && chr <= 0xdbff) {

				codepoint = ((chr - 0xd800) << 10) + 0x10000;

			} else {

				if (chr >= 0xdc00 && chr <= 0xdfff) {

					codepoint |= chr - 0xdc00;

				} else {

					codepoint = chr;

				}

				if (codepoint <= 0x7f) {

					out.append (1, static_cast<char> (codepoint));

				} else if (codepoint <= 0x7ff) {

					out.append (1, static_cast<char> (0xc0 | ((codepoint >> 6) & 0x1f)));
					out.append (1, static_cast<char> (0x80 | (codepoint & 0x3f)));

				} else if (codepoint <= 0xffff) {

					out.append (1, static_cast<char> (0xe0 | ((codepoint >> 12) & 0x0f)));
					out.append (1, static_cast<char> (0x80 | ((codepoint >> 6) & 0x3f)));
					out.append (1, static_cast<char> (0x80 | (codepoint & 0x3f)));

				} else {

					out.append (1, static_cast<char> (0xf0 | ((codepoint >> 18) & 0x07)));
					out.append (1, static_cast<char> (0x80 | ((codepoint >> 12) & 0x3f)));
					out.append (1, static_cast<char> (0x80 | ((codepoint >> 6) & 0x3f)));
					out.append (1, static_cast<char> (0x80 | (codepoint & 0x3f)));

				}

				codepoint = 0;

			}

		}

		return out;

	}


	vbyte* hl_wstring_to_utf8_bytes (const std::wstring& val) {

		const std::string utf8 (wstring_utf8 (val));
		vbyte* const bytes = hl_alloc_bytes (utf8.size () + 1);
		std::memcpy(bytes, utf8.c_str (), utf8.size () + 1);
		return bytes;

	}


	#ifdef HX_WINDOWS
	#define hxs_to_fd_str(str) hxs_wchar(str, nullptr)
	#define alloc_from_fd_str(str) alloc_wstring(str)
	#define alloc_from_fd_str_len(str, len) alloc_wstring_len(str, len)

	static const FileDialog::char_t* hl_vstring_to_fd_str (hl_vstring* val) {
		if (val) {
			return val->bytes;
		}
		return nullptr;
	}

	static vbyte* hl_fd_str_to_utf8_bytes(const FileDialog::char_t* src, size_t length) {
		// copy first, since hl_to_utf8 has no length parameter, and hl_utf16_to_utf8 is not exposed
		FileDialog::char_t* utf16 = (FileDialog::char_t*)hl_copy_bytes((vbyte*)src, (length + 1) * sizeof(FileDialog::char_t));
		utf16[length] = L'\0';
		return (vbyte*)hl_to_utf8(utf16);
	}

	static vbyte* hl_fd_str_to_utf8_bytes(const FileDialog::char_t* src) {
		return (vbyte*)hl_to_utf8((uchar*)src);
	}

	#else
	#define hxs_to_fd_str(str) hxs_utf8(str, nullptr)
	#define alloc_from_fd_str(str) alloc_string(str)
	#define alloc_from_fd_str_len(str, len) alloc_string_len(str, len)

	static const FileDialog::char_t* hl_vstring_to_fd_str (hl_vstring* val) {
		if (val) {
			return hl_to_utf8 (val->bytes);
		}
		return nullptr;
	}

	static vbyte* hl_fd_str_to_utf8_bytes(const FileDialog::char_t* src, size_t length) {
		vbyte* result = hl_copy_bytes((vbyte*)src, length + 1);
		result[length] = '\0';
		return result;
	}

	static vbyte* hl_fd_str_to_utf8_bytes(const FileDialog::char_t* src) {
		return hl_fd_str_to_utf8_bytes(src, std::strlen(src));
	}
	#endif

	value lime_application_create () {

		Application* application = CreateApplication ();
		return CFFIPointer (application, gc_application);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_application_create) () {

		Application* application = CreateApplication ();
		return HLCFFIPointer (application, (hl_finalizer)hl_gc_application);

	}


	void lime_application_event_manager_register (value callback, value eventObject) {

		ApplicationEvent::callback = new ValuePointer (callback);
		ApplicationEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_application_event_manager_register) (vclosure* callback, ApplicationEvent* eventObject) {

		ApplicationEvent::callback = new ValuePointer (callback);
		ApplicationEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	int lime_application_exec (value application) {

		Application* app = (Application*)val_data (application);
		return app->Exec ();

	}


	HL_PRIM int HL_NAME(hl_application_exec) (HL_CFFIPointer* application) {

		Application* app = (Application*)application->ptr;
		return app->Exec ();

	}


	void lime_application_init (value application) {

		Application* app = (Application*)val_data (application);
		app->Init ();

	}


	HL_PRIM void HL_NAME(hl_application_init) (HL_CFFIPointer* application) {

		Application* app = (Application*)application->ptr;
		app->Init ();

	}


	int lime_application_quit (value application) {

		Application* app = (Application*)val_data (application);
		return app->Quit ();

	}


	HL_PRIM int HL_NAME(hl_application_quit) (HL_CFFIPointer* application) {

		Application* app = (Application*)application->ptr;
		return app->Quit ();

	}


	void lime_application_set_frame_rate (value application, double frameRate) {

		Application* app = (Application*)val_data (application);
		app->SetFrameRate (frameRate);

	}


	HL_PRIM void HL_NAME(hl_application_set_frame_rate) (HL_CFFIPointer* application, double frameRate) {

		Application* app = (Application*)application->ptr;
		app->SetFrameRate (frameRate);

	}


	void lime_application_set_main_loop (value application, int profile, double frameRate, int timePrecision, int busyWait, int uncapMode) {

		Application* app = (Application*)val_data (application);
		app->SetMainLoop (profile, frameRate, timePrecision, busyWait, uncapMode);

	}


	HL_PRIM void HL_NAME(hl_application_set_main_loop) (HL_CFFIPointer* application, int profile, double frameRate, int timePrecision, int busyWait, int uncapMode) {

		Application* app = (Application*)application->ptr;
		app->SetMainLoop (profile, frameRate, timePrecision, busyWait, uncapMode);

	}


	void lime_application_set_vsync_mode (value application, int vsyncMode) {

		Application* app = (Application*)val_data (application);
		app->SetVSyncMode (vsyncMode);

	}


	HL_PRIM void HL_NAME(hl_application_set_vsync_mode) (HL_CFFIPointer* application, int vsyncMode) {

		Application* app = (Application*)application->ptr;
		app->SetVSyncMode (vsyncMode);

	}


	bool lime_application_update (value application) {

		Application* app = (Application*)val_data (application);
		return app->Update ();

	}


	HL_PRIM bool HL_NAME(hl_application_update) (HL_CFFIPointer* application) {

		Application* app = (Application*)application->ptr;
		return app->Update ();

	}


	value lime_audio_load_bytes (value data, value buffer) {

		Resource resource;
		Bytes bytes;

		AudioBuffer audioBuffer = AudioBuffer (buffer);

		bytes.Set (data);
		resource = Resource (&bytes);

		#ifdef LIME_SDL_SOUND
		if (SDLSound::Decode (&resource, &audioBuffer)) {

			return audioBuffer.Value (buffer);

		}
		#endif


		if (WAV::Decode (&resource, &audioBuffer)) {

			return audioBuffer.Value (buffer);

		}

		#ifdef LIME_OGG
		if (OGG::Decode (&resource, &audioBuffer)) {

			return audioBuffer.Value (buffer);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM AudioBuffer* HL_NAME(hl_audio_load_bytes) (Bytes* data, AudioBuffer* buffer) {

		Resource resource = Resource (data);

		#ifdef LIME_SDL_SOUND
		if (SDLSound::Decode (&resource, buffer)) {

			return buffer;

		}
		#endif

		if (WAV::Decode (&resource, buffer)) {

			return buffer;

		}

		#ifdef LIME_OGG
		if (OGG::Decode (&resource, buffer)) {

			return buffer;

		}
		#endif

		return 0;

	}


	value lime_audio_load_file (value data, value buffer) {

		Resource resource;

		AudioBuffer audioBuffer = AudioBuffer (buffer);

		resource = Resource (val_string (data));

		#ifdef LIME_SDL_SOUND
		if (SDLSound::Decode (&resource, &audioBuffer)) {

			return audioBuffer.Value (buffer);

		}
		#endif

		if (WAV::Decode (&resource, &audioBuffer)) {

			return audioBuffer.Value (buffer);

		}

		#ifdef LIME_OGG
		if (OGG::Decode (&resource, &audioBuffer)) {

			return audioBuffer.Value (buffer);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM AudioBuffer* HL_NAME(hl_audio_load_file) (hl_vstring* data, AudioBuffer* buffer) {

		Resource resource = Resource (data ? hl_to_utf8 ((const uchar*)data->bytes) : NULL);

		#ifdef LIME_SDL_SOUND
		if (SDLSound::Decode (&resource, buffer)) {

			return buffer;

		}
		#endif

		if (WAV::Decode (&resource, buffer)) {

			return buffer;

		}

		#ifdef LIME_OGG
		if (OGG::Decode (&resource, buffer)) {

			return buffer;

		}
		#endif

		return 0;

	}


	value lime_audio_load (value data, value buffer) {

		if (val_is_string (data)) {

			return lime_audio_load_file (data, buffer);

		} else {

			return lime_audio_load_bytes (data, buffer);

		}

	}


	value lime_bytes_from_data_pointer (double data, int length, value _bytes) {

		uintptr_t ptr = (uintptr_t)data;
		Bytes bytes (_bytes);
		bytes.Resize (length);

		if (ptr) {

			memcpy (bytes.b, (const void*)ptr, length);

		}

		return bytes.Value (_bytes);

	}


	HL_PRIM Bytes* HL_NAME(hl_bytes_from_data_pointer) (double data, int length, Bytes* bytes) {

		uintptr_t ptr = (uintptr_t)data;
		bytes->Resize (length);

		if (ptr) {

			memcpy (bytes->b, (const void*)ptr, length);

		}

		return bytes;

	}


	double lime_bytes_get_data_pointer (value bytes) {

		Bytes data = Bytes (bytes);
		return (uintptr_t)data.b;

	}


	HL_PRIM double HL_NAME(hl_bytes_get_data_pointer) (Bytes* bytes) {

		return bytes ? (uintptr_t)bytes->b : 0;

	}


	double lime_bytes_get_data_pointer_offset (value bytes, int offset) {

		if (val_is_null (bytes)) return 0;

		Bytes data = Bytes (bytes);
		return (uintptr_t)data.b + offset;

	}


	HL_PRIM double HL_NAME(hl_bytes_get_data_pointer_offset) (Bytes* bytes, int offset) {

		if (!bytes) return 0;
		return (uintptr_t)bytes->b + offset;

	}


	value lime_bytes_read_file (HxString path, value bytes) {

		Bytes data (bytes);
		data.ReadFile (hxs_utf8 (path, nullptr));
		return data.Value (bytes);

	}


	HL_PRIM Bytes* HL_NAME(hl_bytes_read_file) (hl_vstring* path, Bytes* bytes) {

		if (!path) return 0;
		bytes->ReadFile (hl_to_utf8 ((const uchar*)path->bytes));
		return bytes;

	}


	double lime_cffi_get_native_pointer (value handle) {

		return (uintptr_t)val_data (handle);

	}


	HL_PRIM double HL_NAME(hl_cffi_get_native_pointer) (HL_CFFIPointer* handle) {

		return (uintptr_t)handle->ptr;

	}


	void lime_cffi_finalizer (value abstract) {

		val_call0 ((value)val_data (abstract));

	}


	value lime_cffi_set_finalizer (value callback) {

		value abstract = alloc_abstract (k_finalizer, callback);
		val_gc (abstract, lime_cffi_finalizer);
		return abstract;

	}


	void lime_clipboard_event_manager_register (value callback, value eventObject) {

		ClipboardEvent::callback = new ValuePointer (callback);
		ClipboardEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_clipboard_event_manager_register) (vclosure* callback, ClipboardEvent* eventObject) {

		ClipboardEvent::callback = new ValuePointer (callback);
		ClipboardEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	value lime_clipboard_get_text () {

		if (Clipboard::HasText ()) {

			const char* text = Clipboard::GetText ();
			value _text = alloc_string (text);

			// TODO: Should we free for all backends? (SDL requires it)

			free ((char*)text);
			return _text;

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM vbyte* HL_NAME(hl_clipboard_get_text) () {

		if (Clipboard::HasText ()) {

			const char* text = Clipboard::GetText ();
			return (vbyte*)text;

		} else {

			return 0;

		}

	}


	void lime_clipboard_set_text (HxString text) {

		Clipboard::SetText (hxs_utf8 (text, nullptr));

	}


	HL_PRIM void HL_NAME(hl_clipboard_set_text) (hl_vstring* text) {

		Clipboard::SetText (text ? (const char*)hl_to_utf8 ((const uchar*)text->bytes) : NULL);

	}


	double lime_data_pointer_offset (double pointer, int offset) {

		return (uintptr_t)pointer + offset;

	}


	HL_PRIM double HL_NAME(hl_data_pointer_offset) (double pointer, int offset) {

		return (uintptr_t)pointer + offset;

	}


	value lime_deflate_compress (value buffer, value bytes) {

		#ifdef LIME_ZLIB
		Bytes data (buffer);
		Bytes result (bytes);

		Zlib::Compress (DEFLATE, &data, &result);

		return result.Value (bytes);
		#else
		return alloc_null();
		#endif

	}


	HL_PRIM Bytes* HL_NAME(hl_deflate_compress) (Bytes* buffer, Bytes* bytes) {

		#ifdef LIME_ZLIB
		Zlib::Compress (DEFLATE, buffer, bytes);
		return bytes;
		#else
		return 0;
		#endif

	}


	value lime_deflate_decompress (value buffer, value bytes) {

		#ifdef LIME_ZLIB
		Bytes data (buffer);
		Bytes result (bytes);

		Zlib::Decompress (DEFLATE, &data, &result);

		return result.Value (bytes);
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM Bytes* HL_NAME(hl_deflate_decompress) (Bytes* buffer, Bytes* bytes) {

		#ifdef LIME_ZLIB
		Zlib::Decompress (DEFLATE, buffer, bytes);
		return bytes;
		#else
		return 0;
		#endif

	}


	void lime_drop_event_manager_register (value callback, value eventObject) {

		DropEvent::callback = new ValuePointer (callback);
		DropEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_drop_event_manager_register) (vclosure* callback, DropEvent* eventObject) {

		DropEvent::callback = new ValuePointer (callback);
		DropEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	value lime_file_dialog_open_directory (HxString title, HxString filter, HxString defaultPath) {

		#ifdef LIME_TINYFILEDIALOGS

		const FileDialog::char_t* path = FileDialog::OpenDirectory (hxs_to_fd_str (title), hxs_to_fd_str (filter), hxs_to_fd_str (defaultPath));

		if (path) {

			return alloc_from_fd_str (path);

		}

		#endif

		return alloc_null ();

	}


	HL_PRIM vbyte* HL_NAME(hl_file_dialog_open_directory) (hl_vstring* title, hl_vstring* filter, hl_vstring* defaultPath) {

		#ifdef LIME_TINYFILEDIALOGS

		const FileDialog::char_t* path = FileDialog::OpenDirectory (hl_vstring_to_fd_str (title), hl_vstring_to_fd_str (filter), hl_vstring_to_fd_str (defaultPath));

		if (path) {

			return hl_fd_str_to_utf8_bytes(path);

		}

		#endif

		return NULL;

	}


	value lime_file_dialog_open_file (HxString title, HxString filter, HxString defaultPath) {

		#ifdef LIME_TINYFILEDIALOGS

		const FileDialog::char_t* path = FileDialog::OpenFile (hxs_to_fd_str (title), hxs_to_fd_str (filter), hxs_to_fd_str (defaultPath));

		if (path) {

			return alloc_from_fd_str (path);

		}

		#endif

		return alloc_null ();

	}


	HL_PRIM vbyte* HL_NAME(hl_file_dialog_open_file) (hl_vstring* title, hl_vstring* filter, hl_vstring* defaultPath) {

		#ifdef LIME_TINYFILEDIALOGS

		const FileDialog::char_t* path = FileDialog::OpenFile (hl_vstring_to_fd_str (title), hl_vstring_to_fd_str (filter), hl_vstring_to_fd_str (defaultPath));

		if (path) {

			return hl_fd_str_to_utf8_bytes (path);

		}

		#endif

		return NULL;

	}


	value lime_file_dialog_open_files (HxString title, HxString filter, HxString defaultPath) {

		#ifdef LIME_TINYFILEDIALOGS

		auto files = FileDialog::OpenFiles (hxs_to_fd_str (title), hxs_to_fd_str (filter), hxs_to_fd_str (defaultPath));
		value result = alloc_array (files.size ());

		for (int i = 0; i < files.size (); i++) {

			auto file_str = files[i];

			value file = alloc_from_fd_str_len (file_str.data(), file_str.size());
			val_array_set_i (result, i, file);

		}

		#else
		value result = alloc_array (0);
		#endif

		return result;

	}


	HL_PRIM hl_varray* HL_NAME(hl_file_dialog_open_files) (hl_vstring* title, hl_vstring* filter, hl_vstring* defaultPath) {

		#ifdef LIME_TINYFILEDIALOGS

		auto files = FileDialog::OpenFiles (hl_vstring_to_fd_str (title), hl_vstring_to_fd_str (filter), hl_vstring_to_fd_str (defaultPath));
		hl_varray* result = (hl_varray*)hl_alloc_array (&hlt_bytes, files.size ());
		vbyte** resultData = hl_aptr (result, vbyte*);

		for (int i = 0; i < files.size (); i++) {

			auto file_str = files[i];
			*resultData++ = hl_fd_str_to_utf8_bytes (file_str.data(), file_str.size());

		}

		#else
		hl_varray* result = hl_alloc_array (&hlt_bytes, 0);
		#endif

		return result;

	}


	value lime_file_dialog_save_file (HxString title, HxString filter, HxString defaultPath) {

		#ifdef LIME_TINYFILEDIALOGS

		const FileDialog::char_t* path = FileDialog::SaveFile (hxs_to_fd_str (title), hxs_to_fd_str (filter), hxs_to_fd_str (defaultPath));

		if (path) {

			return alloc_from_fd_str (path);

		}

		#endif

		return alloc_null ();

	}


	HL_PRIM vbyte* HL_NAME(hl_file_dialog_save_file) (hl_vstring* title, hl_vstring* filter, hl_vstring* defaultPath) {

		#ifdef LIME_TINYFILEDIALOGS

		const FileDialog::char_t* path = FileDialog::SaveFile (hl_vstring_to_fd_str (title), hl_vstring_to_fd_str (filter), hl_vstring_to_fd_str (defaultPath));

		if (path) {

			return hl_fd_str_to_utf8_bytes (path);

		}

		#endif

		return NULL;

	}


	value lime_file_watcher_create (value callback) {

		#ifdef LIME_EFSW
		FileWatcher* watcher = new FileWatcher (callback);
		return CFFIPointer (watcher, gc_file_watcher);
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_file_watcher_create) (vclosure* callback) {

		// #ifdef LIME_EFSW
		// FileWatcher* watcher = new FileWatcher (callback);
		// return HLCFFIPointer (watcher, (hl_finalizer)hl_gc_file_watcher);
		// #else
		return 0;
		// #endif

	}


	value lime_file_watcher_add_directory (value handle, value path, bool recursive) {

		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)val_data (handle);
		return alloc_int (watcher->AddDirectory (val_string (path), recursive));
		#else
		return alloc_int (0);
		#endif

	}


	HL_PRIM int HL_NAME(hl_file_watcher_add_directory) (HL_CFFIPointer* handle, hl_vstring* path, bool recursive) {

		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)handle->ptr;
		return watcher->AddDirectory ((const char*)path, recursive);
		#else
		return 0;
		#endif

	}


	void lime_file_watcher_remove_directory (value handle, value watchID) {

		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)val_data (handle);
		watcher->RemoveDirectory (val_int (watchID));
		#endif

	}


	HL_PRIM void HL_NAME(hl_file_watcher_remove_directory) (HL_CFFIPointer* handle, int watchID) {

		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)handle->ptr;
		watcher->RemoveDirectory (watchID);
		#endif

	}


	void lime_file_watcher_update (value handle) {

		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)val_data (handle);
		watcher->Update ();
		#endif

	}


	HL_PRIM void HL_NAME(hl_file_watcher_update) (HL_CFFIPointer* handle) {

		#ifdef LIME_EFSW
		FileWatcher* watcher = (FileWatcher*)handle->ptr;
		watcher->Update ();
		#endif

	}


	int lime_font_get_ascender (value fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetAscender ();
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_font_get_ascender) (HL_CFFIPointer* fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetAscender ();
		#else
		return 0;
		#endif

	}


	int lime_font_get_descender (value fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetDescender ();
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_font_get_descender) (HL_CFFIPointer* fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetDescender ();
		#else
		return 0;
		#endif

	}


	value lime_font_get_family_name (value fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		wchar_t *name = font->GetFamilyName ();
		value result = alloc_wstring (name);
		delete name;
		return result;
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM vbyte* HL_NAME(hl_font_get_family_name) (HL_CFFIPointer* fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		wchar_t *name = font->GetFamilyName ();
		if (!name)
			return nullptr;
		vbyte* const result = hl_wstring_to_utf8_bytes (name);
		delete name;
		return result;
		#else
		return 0;
		#endif

	}


	int lime_font_get_glyph_index (value fontHandle, HxString character) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetGlyphIndex (hxs_utf8 (character, nullptr));
		#else
		return -1;
		#endif

	}


	HL_PRIM int HL_NAME(hl_font_get_glyph_index) (HL_CFFIPointer* fontHandle, hl_vstring* character) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetGlyphIndex (character ? (char*)hl_to_utf8 ((const uchar*)character->bytes) : NULL);
		#else
		return -1;
		#endif

	}


	value lime_font_get_glyph_indices (value fontHandle, HxString characters) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return (value)font->GetGlyphIndices (true, hxs_utf8 (characters, nullptr));
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM hl_varray* HL_NAME(hl_font_get_glyph_indices) (HL_CFFIPointer* fontHandle, hl_vstring* characters) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return (hl_varray*)font->GetGlyphIndices (false, characters ? (char*)hl_to_utf8 ((const uchar*)characters->bytes) : NULL);
		#else
		return 0;
		#endif

	}


	value lime_font_get_glyph_metrics (value fontHandle, int index) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return (value)font->GetGlyphMetrics (true, index);
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_font_get_glyph_metrics) (HL_CFFIPointer* fontHandle, int index) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return (vdynamic*)font->GetGlyphMetrics (false, index);
		#else
		return 0;
		#endif

	}


	int lime_font_get_height (value fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetHeight ();
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_font_get_height) (HL_CFFIPointer* fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetHeight ();
		#else
		return 0;
		#endif

	}


	int lime_font_get_num_glyphs (value fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetNumGlyphs ();
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_font_get_num_glyphs) (HL_CFFIPointer* fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetNumGlyphs ();
		#else
		return 0;
		#endif

	}


	int lime_font_get_underline_position (value fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetUnderlinePosition ();
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_font_get_underline_position) (HL_CFFIPointer* fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetUnderlinePosition ();
		#else
		return 0;
		#endif

	}


	int lime_font_get_underline_thickness (value fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetUnderlineThickness ();
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_font_get_underline_thickness) (HL_CFFIPointer* fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetUnderlineThickness ();
		#else
		return 0;
		#endif

	}


	int lime_font_get_strikethrough_position (value fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetStrikethroughPosition ();
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_font_get_strikethrough_position) (HL_CFFIPointer* fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetStrikethroughPosition ();
		#else
		return 0;
		#endif

	}


	int lime_font_get_strikethrough_thickness (value fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetStrikethroughThickness ();
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_font_get_strikethrough_thickness) (HL_CFFIPointer* fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetStrikethroughThickness ();
		#else
		return 0;
		#endif

	}


	int lime_font_get_units_per_em (value fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->GetUnitsPerEM ();
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_font_get_units_per_em) (HL_CFFIPointer* fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->GetUnitsPerEM ();
		#else
		return 0;
		#endif

	}


	bool lime_font_is_bold (value fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->IsBold ();
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_font_is_bold) (HL_CFFIPointer* fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->IsBold ();
		#else
		return false;
		#endif

	}


	bool lime_font_is_italic (value fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return font->IsItalic ();
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_font_is_italic) (HL_CFFIPointer* fontHandle) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return font->IsItalic ();
		#else
		return false;
		#endif

	}


	value lime_font_load_bytes (value data) {

		#ifdef LIME_FREETYPE
		Resource resource;
		Bytes bytes;

		bytes.Set (data);
		resource = Resource (&bytes);

		Font *font = new Font (&resource, 0);

		if (font) {

			if (font->face) {

				return CFFIPointer (font, gc_font);

			} else {

				delete font;

			}

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_font_load_bytes) (Bytes* data) {

		#ifdef LIME_FREETYPE
		Resource resource = Resource (data);

		Font *font = new Font (&resource, 0);

		if (font) {

			if (font->face) {

				return HLCFFIPointer (font, (hl_finalizer)hl_gc_font);

			} else {

				delete font;

			}

		}
		#endif

		return 0;

	}


	value lime_font_load_file (value data) {

		#ifdef LIME_FREETYPE
		Resource resource = Resource (val_string (data));

		Font *font = new Font (&resource, 0);

		if (font) {

			if (font->face) {

				return CFFIPointer (font, gc_font);

			} else {

				delete font;

			}

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_font_load_file) (hl_vstring* data) {

		#ifdef LIME_FREETYPE
		Resource resource = Resource (data ? hl_to_utf8 ((const uchar*)data->bytes) : NULL);

		Font *font = new Font (&resource, 0);

		if (font) {

			if (font->face) {

				return HLCFFIPointer (font, (hl_finalizer)hl_gc_font);

			} else {

				delete font;

			}

		}
		#endif

		return 0;

	}


	value lime_font_load (value data) {

		if (val_is_string (data)) {

			return lime_font_load_file (data);

		} else {

			return lime_font_load_bytes (data);

		}

	}


	value lime_font_outline_decompose (value fontHandle, int size) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return (value)font->Decompose (true, size);
		#else
		return alloc_null ();
		#endif

	}


	value lime_font_outline_decompose_no_hint (value fontHandle, int size) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		return (value)font->Decompose (true, size, false);
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_font_outline_decompose) (HL_CFFIPointer* fontHandle, int size) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return (vdynamic*)font->Decompose (false, size);
		#else
		return 0;
		#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_font_outline_decompose_no_hint) (HL_CFFIPointer* fontHandle, int size) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		return (vdynamic*)font->Decompose (false, size, false);
		#else
		return 0;
		#endif

	}


	value lime_font_render_glyph (value fontHandle, int index, value data) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		Bytes bytes (data);

		if (font->RenderGlyph (index, &bytes)) {

			return bytes.Value (data);

		}
		#endif

		return alloc_null ();

	}


	value lime_font_render_glyph_with_flags (value fontHandle, int index, int loadFlags, value data) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		Bytes bytes (data);

		if (font->RenderGlyphWithFlags (index, loadFlags, &bytes)) {

			return bytes.Value (data);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM Bytes* HL_NAME(hl_font_render_glyph) (HL_CFFIPointer* fontHandle, int index, Bytes* data) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;

		if (font->RenderGlyph (index, data)) {

			return data;

		}
		#endif

		return NULL;

	}


	HL_PRIM Bytes* HL_NAME(hl_font_render_glyph_with_flags) (HL_CFFIPointer* fontHandle, int index, int loadFlags, Bytes* data) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;

		if (font->RenderGlyphWithFlags (index, loadFlags, data)) {

			return data;

		}
		#endif

		return NULL;

	}


	value lime_font_render_glyphs (value fontHandle, value indices, value data) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		Bytes bytes (data);

		if (font->RenderGlyphs (indices, &bytes)) {

			return bytes.Value (data);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM Bytes* HL_NAME(hl_font_render_glyphs) (HL_CFFIPointer* fontHandle, hl_varray* indices, Bytes* data) {

		// #ifdef LIME_FREETYPE
		// Font *font = (Font*)fontHandle->ptr;
		// return font->RenderGlyphs (indices, &bytes);
		// #else
		return NULL;
		// #endif

	}


	void lime_font_set_size (value fontHandle, int fontSize, int dpi) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)val_data (fontHandle);
		font->SetSize (fontSize, dpi);
		#endif

	}


	HL_PRIM void HL_NAME(hl_font_set_size) (HL_CFFIPointer* fontHandle, int fontSize, int dpi) {

		#ifdef LIME_FREETYPE
		Font *font = (Font*)fontHandle->ptr;
		font->SetSize (fontSize, dpi);
		#endif

	}


	void lime_gamepad_add_mappings (value mappings) {

		int length = val_array_size (mappings);

		for (int i = 0; i < length; i++) {

			Gamepad::AddMapping (val_string (val_array_i (mappings, i)));

		}

	}


	HL_PRIM void HL_NAME(hl_gamepad_add_mappings) (hl_varray* mappings) {

		int length = mappings->size;
		hl_vstring** mappingsData = hl_aptr (mappings, hl_vstring*);

		for (int i = 0; i < length; i++) {

			Gamepad::AddMapping (hl_to_utf8 ((const uchar*)((*mappingsData++)->bytes)));

		}

	}


	void lime_gamepad_event_manager_register (value callback, value eventObject) {

		GamepadEvent::callback = new ValuePointer (callback);
		GamepadEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_gamepad_event_manager_register) (vclosure* callback, GamepadEvent* eventObject) {

		GamepadEvent::callback = new ValuePointer (callback);
		GamepadEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	value lime_gamepad_get_device_guid (int id) {

		const char* guid = Gamepad::GetDeviceGUID (id);

		if (guid) {

			value result = alloc_string (guid);
			delete guid;
			return result;

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM vbyte* HL_NAME(hl_gamepad_get_device_guid) (int id) {

		const char* guid = Gamepad::GetDeviceGUID (id);

		if (guid) {

			return (vbyte*)guid;

		} else {

			return 0;

		}

	}


	value lime_gamepad_get_device_name (int id) {

		const char* name = Gamepad::GetDeviceName (id);
		return name ? alloc_string (name) : alloc_null ();

	}


	HL_PRIM vbyte* HL_NAME(hl_gamepad_get_device_name) (int id) {

		return (vbyte*)Gamepad::GetDeviceName (id);

	}


	void lime_gamepad_rumble (int id, double lowFrequencyRumble, double highFrequencyRumble, int duration) {

		Gamepad::Rumble (id, lowFrequencyRumble, highFrequencyRumble, duration);

	}


	HL_PRIM void HL_NAME(hl_gamepad_rumble) (int id, double lowFrequencyRumble, double highFrequencyRumble, int duration) {

		Gamepad::Rumble (id, lowFrequencyRumble, highFrequencyRumble, duration);

	}


	value lime_gzip_compress (value buffer, value bytes) {

		#ifdef LIME_ZLIB
		Bytes data (buffer);
		Bytes result (bytes);

		Zlib::Compress (GZIP, &data, &result);

		return result.Value (bytes);
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM Bytes* HL_NAME(hl_gzip_compress) (Bytes* buffer, Bytes* bytes) {

		#ifdef LIME_ZLIB
		Zlib::Compress (GZIP, buffer, bytes);
		return bytes;
		#else
		return 0;
		#endif

	}


	value lime_gzip_decompress (value buffer, value bytes) {

		#ifdef LIME_ZLIB
		Bytes data (buffer);
		Bytes result (bytes);

		Zlib::Decompress (GZIP, &data, &result);

		return result.Value (bytes);
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM Bytes* HL_NAME(hl_gzip_decompress) (Bytes* buffer, Bytes* bytes) {

		#ifdef LIME_ZLIB
		Zlib::Decompress (GZIP, buffer, bytes);
		return bytes;
		#else
		return 0;
		#endif

	}


	void lime_haptic_vibrate (int period, int duration) {

		#ifdef IPHONE
		Haptic::Vibrate (period, duration);
		#endif

	}


	HL_PRIM void HL_NAME(hl_haptic_vibrate) (int period, int duration) {

		#ifdef IPHONE
		Haptic::Vibrate (period, duration);
		#endif

	}


	value lime_image_encode (value buffer, int type, int quality, value bytes) {

		ImageBuffer imageBuffer = ImageBuffer (buffer);
		Bytes data = Bytes (bytes);

		switch (type) {

			case 0:

				#ifdef LIME_PNG
				if (PNG::Encode (&imageBuffer, &data)) {

					return data.Value (bytes);

				}
				#endif
				break;

			case 1:

				#ifdef LIME_JPEG
				if (JPEG::Encode (&imageBuffer, &data, quality)) {

					return data.Value (bytes);

				}
				#endif
				break;

			default: break;

		}

		return alloc_null ();

	}


	HL_PRIM Bytes* HL_NAME(hl_image_encode) (ImageBuffer* buffer, int type, int quality, Bytes* bytes) {

		switch (type) {

			case 0:

				#ifdef LIME_PNG
				if (PNG::Encode (buffer, bytes)) {

					return bytes;

				}
				#endif
				break;

			case 1:

				#ifdef LIME_JPEG
				if (JPEG::Encode (buffer, bytes, quality)) {

					return bytes;

				}
				#endif
				break;

			default: break;

		}

		return 0;

	}


	value lime_image_load_bytes (value data, value buffer) {

		Resource resource;
		Bytes bytes;

		ImageBuffer imageBuffer = ImageBuffer (buffer);

		bytes.Set (data);
		resource = Resource (&bytes);

		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &imageBuffer)) {

			return imageBuffer.Value (buffer);

		}
		#endif

		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &imageBuffer)) {

			return imageBuffer.Value (buffer);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM ImageBuffer* HL_NAME(hl_image_load_bytes) (Bytes* data, ImageBuffer* buffer) {

		Resource resource = Resource (data);

		#ifdef LIME_PNG
		if (PNG::Decode (&resource, buffer)) {

			return buffer;

		}
		#endif

		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, buffer)) {

			return buffer;

		}
		#endif

		return 0;

	}


	value lime_image_load_file (value data, value buffer) {

		Resource resource = Resource (val_string (data));
		ImageBuffer imageBuffer = ImageBuffer (buffer);

		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &imageBuffer)) {

			return imageBuffer.Value (buffer);

		}
		#endif

		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &imageBuffer)) {

			return imageBuffer.Value (buffer);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM ImageBuffer* HL_NAME(hl_image_load_file) (hl_vstring* data, ImageBuffer* buffer) {

		Resource resource = Resource (data);

		#ifdef LIME_PNG
		if (PNG::Decode (&resource, buffer)) {

			return buffer;

		}
		#endif

		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, buffer)) {

			return buffer;

		}
		#endif

		return 0;

	}


	value lime_image_load (value data, value buffer) {

		if (val_is_string (data)) {

			return lime_image_load_file (data, buffer);

		} else {

			return lime_image_load_bytes (data, buffer);

		}

	}


	void lime_image_data_util_color_transform (value image, value rect, value colorMatrix) {

		Image _image = Image (image);
		Rectangle _rect = Rectangle (rect);
		ColorMatrix _colorMatrix = ColorMatrix (colorMatrix);
		ImageDataUtil::ColorTransform (&_image, &_rect, &_colorMatrix);

	}


	HL_PRIM void HL_NAME(hl_image_data_util_color_transform) (Image* image, Rectangle* rect, ArrayBufferView* colorMatrix) {

		ColorMatrix _colorMatrix = ColorMatrix (colorMatrix);
		ImageDataUtil::ColorTransform (image, rect, &_colorMatrix);

	}


	void lime_image_data_util_copy_channel (value image, value sourceImage, value sourceRect, value destPoint, int srcChannel, int destChannel) {

		Image _image = Image (image);
		Image _sourceImage = Image (sourceImage);
		Rectangle _sourceRect = Rectangle (sourceRect);
		Vector2 _destPoint = Vector2 (destPoint);
		ImageDataUtil::CopyChannel (&_image, &_sourceImage, &_sourceRect, &_destPoint, srcChannel, destChannel);

	}


	HL_PRIM void HL_NAME(hl_image_data_util_copy_channel) (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, int srcChannel, int destChannel) {

		ImageDataUtil::CopyChannel (image, sourceImage, sourceRect, destPoint, srcChannel, destChannel);

	}


	void lime_image_data_util_copy_pixels (value image, value sourceImage, value sourceRect, value destPoint, value alphaImage, value alphaPoint, bool mergeAlpha) {

		Image _image = Image (image);
		Image _sourceImage = Image (sourceImage);
		Rectangle _sourceRect = Rectangle (sourceRect);
		Vector2 _destPoint = Vector2 (destPoint);

		if (val_is_null (alphaImage)) {

			ImageDataUtil::CopyPixels (&_image, &_sourceImage, &_sourceRect, &_destPoint, 0, 0, mergeAlpha);

		} else {

			Image _alphaImage = Image (alphaImage);
			Vector2 _alphaPoint = Vector2 (alphaPoint);

			ImageDataUtil::CopyPixels (&_image, &_sourceImage, &_sourceRect, &_destPoint, &_alphaImage, &_alphaPoint, mergeAlpha);

		}

	}


	HL_PRIM void HL_NAME(hl_image_data_util_copy_pixels) (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, Image* alphaImage, Vector2* alphaPoint, bool mergeAlpha) {

		if (!alphaImage) {

			ImageDataUtil::CopyPixels (image, sourceImage, sourceRect, destPoint, NULL, NULL, mergeAlpha);

		} else {

			if (!alphaPoint) {

				Vector2 _alphaPoint = Vector2 (0, 0);

				ImageDataUtil::CopyPixels (image, sourceImage, sourceRect, destPoint, alphaImage, &_alphaPoint, mergeAlpha);

			} else {

				ImageDataUtil::CopyPixels (image, sourceImage, sourceRect, destPoint, alphaImage, alphaPoint, mergeAlpha);

			}

		}

	}


	void lime_image_data_util_fill_rect (value image, value rect, int rg, int ba) {

		Image _image = Image (image);
		Rectangle _rect = Rectangle (rect);
		int32_t color = (rg << 16) | ba;
		ImageDataUtil::FillRect (&_image, &_rect, color);

	}


	HL_PRIM void HL_NAME(hl_image_data_util_fill_rect) (Image* image, Rectangle* rect, int rg, int ba) {

		int32_t color = (rg << 16) | ba;
		ImageDataUtil::FillRect (image, rect, color);

	}


	void lime_image_data_util_flood_fill (value image, int x, int y, int rg, int ba) {

		Image _image = Image (image);
		int32_t color = (rg << 16) | ba;
		ImageDataUtil::FloodFill (&_image, x, y, color);

	}


	HL_PRIM void HL_NAME(hl_image_data_util_flood_fill) (Image* image, int x, int y, int rg, int ba) {

		int32_t color = (rg << 16) | ba;
		ImageDataUtil::FloodFill (image, x, y, color);

	}


	void lime_image_data_util_get_pixels (value image, value rect, int format, value bytes) {

		Image _image = Image (image);
		Rectangle _rect = Rectangle (rect);
		PixelFormat _format = (PixelFormat)format;
		Bytes pixels = Bytes (bytes);
		ImageDataUtil::GetPixels (&_image, &_rect, _format, &pixels);

	}


	HL_PRIM void HL_NAME(hl_image_data_util_get_pixels) (Image* image, Rectangle* rect, PixelFormat format, Bytes* bytes) {

		ImageDataUtil::GetPixels (image, rect, format, bytes);

	}


	void lime_image_data_util_merge (value image, value sourceImage, value sourceRect, value destPoint, int redMultiplier, int greenMultiplier, int blueMultiplier, int alphaMultiplier) {

		Image _image = Image (image);
		Image _sourceImage = Image (sourceImage);
		Rectangle _sourceRect = Rectangle (sourceRect);
		Vector2 _destPoint = Vector2 (destPoint);
		ImageDataUtil::Merge (&_image, &_sourceImage, &_sourceRect, &_destPoint, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);

	}


	HL_PRIM void HL_NAME(hl_image_data_util_merge) (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, int redMultiplier, int greenMultiplier, int blueMultiplier, int alphaMultiplier) {

		ImageDataUtil::Merge (image, sourceImage, sourceRect, destPoint, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);

	}


	void lime_image_data_util_multiply_alpha (value image) {

		Image _image = Image (image);
		ImageDataUtil::MultiplyAlpha (&_image);

	}


	HL_PRIM void HL_NAME(hl_image_data_util_multiply_alpha) (Image* image) {

		ImageDataUtil::MultiplyAlpha (image);

	}


	void lime_image_data_util_resize (value image, value buffer, int width, int height) {

		Image _image = Image (image);
		ImageBuffer _buffer = ImageBuffer (buffer);
		ImageDataUtil::Resize (&_image, &_buffer, width, height);

	}


	HL_PRIM void HL_NAME(hl_image_data_util_resize) (Image* image, ImageBuffer* buffer, int width, int height) {

		ImageDataUtil::Resize (image, buffer, width, height);

	}


	void lime_image_data_util_set_format (value image, int format) {

		Image _image = Image (image);
		PixelFormat _format = (PixelFormat)format;
		ImageDataUtil::SetFormat (&_image, _format);

	}


	HL_PRIM void HL_NAME(hl_image_data_util_set_format) (Image* image, PixelFormat format) {

		ImageDataUtil::SetFormat (image, format);

	}


	void lime_image_data_util_set_pixels (value image, value rect, value bytes, int offset, int format, int endian) {

		Image _image = Image (image);
		Rectangle _rect = Rectangle (rect);
		Bytes _bytes (bytes);
		PixelFormat _format = (PixelFormat)format;
		Endian _endian = (Endian)endian;
		ImageDataUtil::SetPixels (&_image, &_rect, &_bytes, offset, _format, _endian);

	}


	HL_PRIM void HL_NAME(hl_image_data_util_set_pixels) (Image* image, Rectangle* rect, Bytes* bytes, int offset, PixelFormat format, Endian endian) {

		ImageDataUtil::SetPixels (image, rect, bytes, offset, format, endian);

	}


	int lime_image_data_util_threshold (value image, value sourceImage, value sourceRect, value destPoint, int operation, int thresholdRG, int thresholdBA, int colorRG, int colorBA, int maskRG, int maskBA, bool copySource) {

		Image _image = Image (image);
		Image _sourceImage = Image (sourceImage);
		Rectangle _sourceRect = Rectangle (sourceRect);
		Vector2 _destPoint = Vector2 (destPoint);
		int32_t threshold = (thresholdRG << 16) | thresholdBA;
		int32_t color = (colorRG << 16) | colorBA;
		int32_t mask = (maskRG << 16) | maskBA;
		return ImageDataUtil::Threshold (&_image, &_sourceImage, &_sourceRect, &_destPoint, operation, threshold, color, mask, copySource);

	}


	HL_PRIM int HL_NAME(hl_image_data_util_threshold) (Image* image, Image* sourceImage, Rectangle* sourceRect, Vector2* destPoint, int operation, int thresholdRG, int thresholdBA, int colorRG, int colorBA, int maskRG, int maskBA, bool copySource) {

		int32_t threshold = (thresholdRG << 16) | thresholdBA;
		int32_t color = (colorRG << 16) | colorBA;
		int32_t mask = (maskRG << 16) | maskBA;
		return ImageDataUtil::Threshold (image, sourceImage, sourceRect, destPoint, operation, threshold, color, mask, copySource);

	}


	void lime_image_data_util_unmultiply_alpha (value image) {

		Image _image = Image (image);
		ImageDataUtil::UnmultiplyAlpha (&_image);

	}


	HL_PRIM void HL_NAME(hl_image_data_util_unmultiply_alpha) (Image* image) {

		ImageDataUtil::UnmultiplyAlpha (image);

	}


	double lime_jni_getenv () {

		#ifdef ANDROID
		return (uintptr_t)JNI::GetEnv ();
		#else
		return 0;
		#endif

	}


	HL_PRIM double HL_NAME(hl_jni_getenv) () {

		#ifdef ANDROID
		return (uintptr_t)JNI::GetEnv ();
		#else
		return 0;
		#endif

	}


	void lime_joystick_event_manager_register (value callback, value eventObject) {

		JoystickEvent::callback = new ValuePointer (callback);
		JoystickEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_joystick_event_manager_register) (vclosure* callback, JoystickEvent* eventObject) {

		JoystickEvent::callback = new ValuePointer (callback);
		JoystickEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	value lime_joystick_get_device_guid (int id) {

		const char* guid = Joystick::GetDeviceGUID (id);
		return guid ? alloc_string (guid) : alloc_null ();

	}


	HL_PRIM vbyte* HL_NAME(hl_joystick_get_device_guid) (int id) {

		return (vbyte*)Joystick::GetDeviceGUID (id);

	}


	value lime_joystick_get_device_name (int id) {

		const char* name = Joystick::GetDeviceName (id);
		return name ? alloc_string (name) : alloc_null ();

	}


	HL_PRIM vbyte* HL_NAME(hl_joystick_get_device_name) (int id) {

		return (vbyte*)Joystick::GetDeviceName (id);

	}


	int lime_joystick_get_num_axes (int id) {

		return Joystick::GetNumAxes (id);

	}


	HL_PRIM int HL_NAME(hl_joystick_get_num_axes) (int id) {

		return Joystick::GetNumAxes (id);

	}


	int lime_joystick_get_num_buttons (int id) {

		return Joystick::GetNumButtons (id);

	}


	HL_PRIM int HL_NAME(hl_joystick_get_num_buttons) (int id) {

		return Joystick::GetNumButtons (id);

	}


	int lime_joystick_get_num_hats (int id) {

		return Joystick::GetNumHats (id);

	}


	HL_PRIM int HL_NAME(hl_joystick_get_num_hats) (int id) {

		return Joystick::GetNumHats (id);

	}


	value lime_jpeg_decode_bytes (value data, bool decodeData, value buffer) {

		ImageBuffer imageBuffer (buffer);

		Bytes bytes (data);
		Resource resource = Resource (&bytes);

		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &imageBuffer, decodeData)) {

			return imageBuffer.Value (buffer);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM ImageBuffer* HL_NAME(hl_jpeg_decode_bytes) (Bytes* data, bool decodeData, ImageBuffer* buffer) {

		Resource resource = Resource (data);

		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, buffer, decodeData)) {

			return buffer;

		}
		#endif

		return 0;

	}


	value lime_jpeg_decode_file (HxString path, bool decodeData, value buffer) {

		ImageBuffer imageBuffer (buffer);
		Resource resource = Resource (hxs_utf8 (path, nullptr));

		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, &imageBuffer, decodeData)) {

			return imageBuffer.Value (buffer);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM ImageBuffer* HL_NAME(hl_jpeg_decode_file) (hl_vstring* path, bool decodeData, ImageBuffer* buffer) {

		Resource resource = Resource (path);

		#ifdef LIME_JPEG
		if (JPEG::Decode (&resource, buffer, decodeData)) {

			return buffer;

		}
		#endif

		return 0;

	}


	int lime_key_code_from_scan_code (int scanCode) {

		return KeyCode::FromScanCode (scanCode);

	}


	HL_PRIM int HL_NAME(hl_key_code_from_scan_code) (int scanCode) {

		return KeyCode::FromScanCode (scanCode);

	}


	int lime_key_code_to_scan_code (int keyCode) {

		return KeyCode::ToScanCode (keyCode);

	}


	HL_PRIM int HL_NAME(hl_key_code_to_scan_code) (int keyCode) {

		return KeyCode::ToScanCode (keyCode);

	}


	void lime_key_event_manager_register (value callback, value eventObject) {

		KeyEvent::callback = new ValuePointer (callback);
		KeyEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_key_event_manager_register) (vclosure* callback, KeyEvent* eventObject) {

		KeyEvent::callback = new ValuePointer (callback);
		KeyEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	value lime_locale_get_system_locale () {

		std::string* locale = Locale::GetSystemLocale ();

		if (!locale) {

			return alloc_null ();

		} else {

			value result = alloc_string (locale->c_str ());
			delete locale;
			return result;

		}

	}


	HL_PRIM vbyte* HL_NAME(hl_locale_get_system_locale) () {

		std::string* locale = Locale::GetSystemLocale ();

		if (!locale) {

			return 0;

		} else {

			int size = locale->size ();
			char* _locale = (char*)malloc (size + 1);
			strncpy (_locale, locale->c_str (), size);
			_locale[size] = '\0';
			delete locale;

			return (vbyte*)_locale;

		}

	}


	value lime_lzma_compress (value buffer, value bytes) {

		#ifdef LIME_LZMA
		Bytes data (buffer);
		Bytes result (bytes);

		LZMA::Compress (&data, &result);

		return result.Value (bytes);
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM Bytes* HL_NAME(hl_lzma_compress) (Bytes* buffer, Bytes* bytes) {

		#ifdef LIME_LZMA
		LZMA::Compress (buffer, bytes);
		return bytes;
		#else
		return 0;
		#endif

	}


	value lime_lzma_decompress (value buffer, value bytes) {

		#ifdef LIME_LZMA
		Bytes data (buffer);
		Bytes result (bytes);

		LZMA::Decompress (&data, &result);

		return result.Value (bytes);
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM Bytes* HL_NAME(hl_lzma_decompress) (Bytes* buffer, Bytes* bytes) {

		#ifdef LIME_LZMA
		LZMA::Decompress (buffer, bytes);
		return bytes;
		#else
		return 0;
		#endif

	}


	void lime_mouse_event_manager_register (value callback, value eventObject) {

		MouseEvent::callback = new ValuePointer (callback);
		MouseEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_mouse_event_manager_register) (vclosure* callback, MouseEvent* eventObject) {

		MouseEvent::callback = new ValuePointer (callback);
		MouseEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	void lime_neko_execute (HxString module) {

		#ifdef LIME_NEKO
		NekoVM::Execute (module.c_str ());
		#endif

	}


	void lime_orientation_event_manager_register (value callback, value eventObject) {

		OrientationEvent::callback = new ValuePointer (callback);
		OrientationEvent::eventObject = new ValuePointer (eventObject);
		System::EnableDeviceOrientationChange(true);

	}


	HL_PRIM void HL_NAME(hl_orientation_event_manager_register) (vclosure* callback, OrientationEvent* eventObject) {

		OrientationEvent::callback = new ValuePointer (callback);
		OrientationEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	value lime_png_decode_bytes (value data, bool decodeData, value buffer) {

		ImageBuffer imageBuffer (buffer);
		Bytes bytes (data);
		Resource resource = Resource (&bytes);

		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &imageBuffer, decodeData)) {

			return imageBuffer.Value (buffer);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM ImageBuffer* HL_NAME(hl_png_decode_bytes) (Bytes* data, bool decodeData, ImageBuffer* buffer) {

		Resource resource = Resource (data);

		#ifdef LIME_PNG
		if (PNG::Decode (&resource, buffer, decodeData)) {

			return buffer;

		}
		#endif

		return 0;

	}


	value lime_png_decode_file (HxString path, bool decodeData, value buffer) {

		ImageBuffer imageBuffer (buffer);
		Resource resource = Resource (hxs_utf8 (path, nullptr));

		#ifdef LIME_PNG
		if (PNG::Decode (&resource, &imageBuffer, decodeData)) {

			return imageBuffer.Value (buffer);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM ImageBuffer* HL_NAME(hl_png_decode_file) (hl_vstring* path, bool decodeData, ImageBuffer* buffer) {

		Resource resource = Resource (path);

		#ifdef LIME_PNG
		if (PNG::Decode (&resource, buffer, decodeData)) {

			return buffer;

		}
		#endif

		return 0;

	}


	void lime_render_event_manager_register (value callback, value eventObject) {

		RenderEvent::callback = new ValuePointer (callback);
		RenderEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_render_event_manager_register) (vclosure* callback, RenderEvent* eventObject) {

		RenderEvent::callback = new ValuePointer (callback);
		RenderEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	void lime_sensor_event_manager_register (value callback, value eventObject) {

		SensorEvent::callback = new ValuePointer (callback);
		SensorEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_sensor_event_manager_register) (vclosure* callback, SensorEvent* eventObject) {

		SensorEvent::callback = new ValuePointer (callback);
		SensorEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	bool lime_system_get_allow_screen_timeout () {

		return System::GetAllowScreenTimeout ();

	}


	HL_PRIM bool HL_NAME(hl_system_get_allow_screen_timeout) () {

		return System::GetAllowScreenTimeout ();

	}


	value lime_system_get_device_model () {

		std::wstring* model = System::GetDeviceModel ();

		if (model) {

			value result = alloc_wstring (model->c_str ());
			delete model;
			return result;

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM vbyte* HL_NAME(hl_system_get_device_model) () {

		#ifndef EMSCRIPTEN

		std::wstring* model = System::GetDeviceModel ();

		if (model) {

			vbyte* const result = hl_wstring_to_utf8_bytes (*model);
			delete model;
			return result;

		}

		#endif

		return 0;

	}


	value lime_system_get_device_vendor () {

		std::wstring* vendor = System::GetDeviceVendor ();

		if (vendor) {

			value result = alloc_wstring (vendor->c_str ());
			delete vendor;
			return result;

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM vbyte* HL_NAME(hl_system_get_device_vendor) () {

		#ifndef EMSCRIPTEN

		std::wstring* vendor = System::GetDeviceVendor ();

		if (vendor) {

			vbyte* const result = hl_wstring_to_utf8_bytes (*vendor);
			delete vendor;
			return result;

		}

		#endif

		return 0;

	}


	value lime_system_get_directory (int type, HxString company, HxString title) {

		std::wstring* path = System::GetDirectory ((SystemDirectory)type, hxs_utf8 (company, nullptr), hxs_utf8 (title, nullptr));

		if (path) {

			value result = alloc_wstring (path->c_str ());
			delete path;
			return result;

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM vbyte* HL_NAME(hl_system_get_directory) (int type, hl_vstring* company, hl_vstring* title) {

		#ifndef EMSCRIPTEN

		std::wstring* path = System::GetDirectory ((SystemDirectory)type, company ? (char*)hl_to_utf8 ((const uchar*)company->bytes) : NULL, title ? (char*)hl_to_utf8 ((const uchar*)title->bytes) : NULL);

		if (path) {

			vbyte* const result = hl_wstring_to_utf8_bytes (*path);
			delete path;
			return result;

		}

		#endif

		return 0;

	}


	value lime_system_get_display (int id) {

		return (value)System::GetDisplay (true, id);

	}


	HL_PRIM vdynamic* HL_NAME(hl_system_get_display) (int id) {

		return (vdynamic*)System::GetDisplay (false, id);

	}


	bool lime_system_get_ios_tablet () {

		#ifdef IPHONE
		return System::GetIOSTablet ();
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_system_get_ios_tablet) () {

		#ifdef IPHONE
		return System::GetIOSTablet ();
		#else
		return false;
		#endif

	}


	int lime_system_get_num_displays () {

		return System::GetNumDisplays ();

	}


	HL_PRIM int HL_NAME(hl_system_get_num_displays) () {

		return System::GetNumDisplays ();

	}


	int lime_system_get_device_orientation () {

		return System::GetDeviceOrientation();

	}


	HL_PRIM int HL_NAME(hl_system_get_device_orientation) () {

		return System::GetDeviceOrientation();

	}


	value lime_system_get_platform_label () {

		std::wstring* label = System::GetPlatformLabel ();

		if (label) {

			value result = alloc_wstring (label->c_str ());
			delete label;
			return result;

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM vbyte* HL_NAME(hl_system_get_platform_label) () {

		#ifndef EMSCRIPTEN

		std::wstring* label = System::GetPlatformLabel ();

		if (label) {

			vbyte* const result = hl_wstring_to_utf8_bytes (*label);
			delete label;
			return result;

		}

		#endif

		return 0;

	}


	value lime_system_get_platform_name () {

		std::wstring* name = System::GetPlatformName ();

		if (name) {

			value result = alloc_wstring (name->c_str ());
			delete name;
			return result;

		} else {

			return 0;

		}

	}


	HL_PRIM vbyte* HL_NAME(hl_system_get_platform_name) () {

		#ifndef EMSCRIPTEN

		std::wstring* name = System::GetPlatformName ();

		if (name) {

			vbyte* const result = hl_wstring_to_utf8_bytes (*name);
			delete name;
			return result;

		}

		#endif

		return 0;

	}


	value lime_system_get_platform_version () {

		std::wstring* version = System::GetPlatformVersion ();

		if (version) {

			value result = alloc_wstring (version->c_str ());
			delete version;
			return result;

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM vbyte* HL_NAME(hl_system_get_platform_version) () {

		#ifndef EMSCRIPTEN

		std::wstring* version = System::GetPlatformVersion ();

		if (version) {

			vbyte* const result = hl_wstring_to_utf8_bytes (*version);
			delete version;
			return result;
		}

		#endif

		return 0;

	}


	double lime_system_get_timer () {

		return System::GetTimer ();

	}


	HL_PRIM double HL_NAME(hl_system_get_timer) () {

		return System::GetTimer ();

	}


	int lime_system_get_windows_console_mode (int handleType) {

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)
		return System::GetWindowsConsoleMode (handleType);
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_system_get_windows_console_mode) (int handleType) {

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)
		return System::GetWindowsConsoleMode (handleType);
		#else
		return 0;
		#endif

	}


	void lime_system_open_file (HxString path) {

		#ifdef IPHONE
		System::OpenFile (path.c_str ());
		#endif

	}


	HL_PRIM void HL_NAME(hl_system_open_file) (vbyte* path) {

		#ifdef IPHONE
		System::OpenFile ((char*)path);
		#endif

	}


	void lime_system_open_url (HxString url, HxString target) {

		#ifdef IPHONE
		System::OpenURL (url.c_str (), target.c_str ());
		#endif

	}


	HL_PRIM void HL_NAME(hl_system_open_url) (vbyte* url, vbyte* target) {

		#ifdef IPHONE
		System::OpenURL ((char*)url, (char*)target);
		#endif

	}


	bool lime_system_set_allow_screen_timeout (bool allow) {

		return System::SetAllowScreenTimeout (allow);

	}


	HL_PRIM bool HL_NAME(hl_system_set_allow_screen_timeout) (bool allow) {

		return System::SetAllowScreenTimeout (allow);

	}


	bool lime_system_set_windows_console_mode (int handleType, int mode) {

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)
		return System::SetWindowsConsoleMode (handleType, mode);
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_system_set_windows_console_mode) (int handleType, int mode) {

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)
		return System::SetWindowsConsoleMode (handleType, mode);
		#else
		return false;
		#endif

	}


	void lime_text_event_manager_register (value callback, value eventObject) {

		TextEvent::callback = new ValuePointer (callback);
		TextEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_text_event_manager_register) (vclosure* callback, TextEvent* eventObject) {

		TextEvent::callback = new ValuePointer (callback);
		TextEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	void lime_touch_event_manager_register (value callback, value eventObject) {

		TouchEvent::callback = new ValuePointer (callback);
		TouchEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_touch_event_manager_register) (vclosure* callback, TouchEvent* eventObject) {

		TouchEvent::callback = new ValuePointer (callback);
		TouchEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	void lime_window_alert (value window, HxString message, HxString title) {

		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Alert (hxs_utf8 (message, nullptr), hxs_utf8 (title, nullptr));

	}


	HL_PRIM void HL_NAME(hl_window_alert) (HL_CFFIPointer* window, hl_vstring* message, hl_vstring* title) {

		Window* targetWindow = (Window*)window->ptr;
		const char *cmessage = message ? hl_to_utf8(message->bytes) : nullptr;
		const char *ctitle = title ? hl_to_utf8(title->bytes) : nullptr;
		targetWindow->Alert (cmessage, ctitle);

	}


	void lime_window_close (value window) {

		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Close ();

	}


	HL_PRIM void HL_NAME(hl_window_close) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->Close ();

	}


	void lime_window_context_flip (value window) {

		((Window*)val_data (window))->ContextFlip ();

	}


	HL_PRIM void HL_NAME(hl_window_context_flip) (HL_CFFIPointer* window) {

		((Window*)window->ptr)->ContextFlip ();

	}


	value lime_window_context_lock (value window) {

		return (value)((Window*)val_data (window))->ContextLock (true);

	}


	HL_PRIM vdynamic* HL_NAME(hl_window_context_lock) (HL_CFFIPointer* window) {

		return (vdynamic*)((Window*)window->ptr)->ContextLock (false);

	}


	void lime_window_context_make_current (value window) {

		((Window*)val_data (window))->ContextMakeCurrent ();

	}


	HL_PRIM void HL_NAME(hl_window_context_make_current) (HL_CFFIPointer* window) {

		((Window*)window->ptr)->ContextMakeCurrent ();

	}


	void lime_window_context_unlock (value window) {

		((Window*)val_data (window))->ContextUnlock ();

	}


	HL_PRIM void HL_NAME(hl_window_context_unlock) (HL_CFFIPointer* window) {

		((Window*)window->ptr)->ContextUnlock ();

	}


	value lime_window_create (value application, int width, int height, int flags, HxString title) {

		Window* window = CreateWindow ((Application*)val_data (application), width, height, flags, hxs_utf8 (title, nullptr));
		return CFFIPointer (window, gc_window);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_window_create) (HL_CFFIPointer* application, int width, int height, int flags, hl_vstring* title) {

		Window* window = CreateWindow ((Application*)application->ptr, width, height, flags, (const char*)hl_to_utf8 ((const uchar*)title->bytes));
		return HLCFFIPointer (window, (hl_finalizer)hl_gc_window);

	}


	void lime_window_event_manager_register (value callback, value eventObject) {

		WindowEvent::callback = new ValuePointer (callback);
		WindowEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_window_event_manager_register) (vclosure* callback, WindowEvent* eventObject) {

		WindowEvent::callback = new ValuePointer (callback);
		WindowEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	void lime_window_focus (value window) {

		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Focus ();

	}


	HL_PRIM void HL_NAME(hl_window_focus) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->Focus ();

	}


	double lime_window_get_context (value window) {

		Window* targetWindow = (Window*)val_data (window);
		return (uintptr_t)targetWindow->GetContext ();

	}


	HL_PRIM double HL_NAME(hl_window_get_context) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return (uintptr_t)targetWindow->GetContext ();

	}


	value lime_window_get_context_type (value window) {

		Window* targetWindow = (Window*)val_data (window);
		const char* type = targetWindow->GetContextType ();
		return type ? alloc_string (type) : alloc_null ();

	}


	HL_PRIM vbyte* HL_NAME(hl_window_get_context_type) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return (vbyte*)targetWindow->GetContextType ();

	}


	value lime_window_get_vulkan_instance_extensions (value window) {

		Window* targetWindow = (Window*)val_data (window);
		unsigned int count = 0;

		if (!targetWindow->GetVulkanInstanceExtensions (&count, 0) || count == 0) {

			return alloc_array (0);

		}

		std::vector<const char*> names (count);
		if (!targetWindow->GetVulkanInstanceExtensions (&count, names.data ())) {

			return alloc_array (0);

		}

		value result = alloc_array (count);

		for (unsigned int i = 0; i < count; ++i) {

			val_array_set_i (result, i, alloc_string (names[i]));

		}

		return result;

	}


	HL_PRIM hl_varray* HL_NAME(hl_window_get_vulkan_instance_extensions) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		unsigned int count = 0;

		if (!targetWindow->GetVulkanInstanceExtensions (&count, 0) || count == 0) {

			return hl_alloc_array (&hlt_bytes, 0);

		}

		std::vector<const char*> names (count);
		if (!targetWindow->GetVulkanInstanceExtensions (&count, names.data ())) {

			return hl_alloc_array (&hlt_bytes, 0);

		}

		hl_varray* result = (hl_varray*)hl_alloc_array (&hlt_bytes, count);
		vbyte** resultData = hl_aptr (result, vbyte*);

		for (unsigned int i = 0; i < count; ++i) {

			*resultData++ = hl_copy_bytes ((const vbyte*)names[i], (int)std::strlen (names[i]) + 1);

		}

		return result;

	}


	value lime_window_get_vulkan_drawable_size (value window) {

		Window* targetWindow = (Window*)val_data (window);
		int width = 0;
		int height = 0;
		targetWindow->GetVulkanDrawableSize (&width, &height);

		value result = alloc_empty_object ();
		alloc_field (result, val_id ("width"), alloc_int (width));
		alloc_field (result, val_id ("height"), alloc_int (height));
		return result;

	}


	HL_PRIM vdynamic* HL_NAME(hl_window_get_vulkan_drawable_size) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		int width = 0;
		int height = 0;
		targetWindow->GetVulkanDrawableSize (&width, &height);

		const int id_width = hl_hash_utf8 ("width");
		const int id_height = hl_hash_utf8 ("height");
		vdynamic* result = (vdynamic*)hl_alloc_dynobj();
		hl_dyn_seti (result, id_width, &hlt_i32, width);
		hl_dyn_seti (result, id_height, &hlt_i32, height);
		return result;

	}


	value lime_window_get_vulkan_instance_proc_addr (value window) {

		Window* targetWindow = (Window*)val_data (window);
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)targetWindow->GetVulkanInstanceProcAddr ());

	}


	HL_PRIM vdynamic* HL_NAME(hl_window_get_vulkan_instance_proc_addr) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)targetWindow->GetVulkanInstanceProcAddr ());

	}


	value lime_window_create_vulkan_surface (value window, int instanceHigh, int instanceLow) {

		Window* targetWindow = (Window*)val_data (window);
		uint64_t surface = targetWindow->CreateVulkanSurface ((uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow));

		if (!surface) {

			return alloc_null ();

		}

		return CreateVulkanHandleValue (surface);

	}


	HL_PRIM vdynamic* HL_NAME(hl_window_create_vulkan_surface) (HL_CFFIPointer* window, int instanceHigh, int instanceLow) {

		Window* targetWindow = (Window*)window->ptr;
		uint64_t surface = targetWindow->CreateVulkanSurface ((uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow));

		if (!surface) {

			return 0;

		}

		return HLCreateVulkanHandleValue (surface);

	}


	value lime_vk_create_instance (value window, HxString applicationName) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = VK_NULL_HANDLE;

		if (!CreateManagedVulkanInstance (targetWindow, applicationName.c_str () ? hxs_utf8 (applicationName, nullptr) : 0, &instance)) {

			return alloc_null ();

		}

		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)instance);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_instance) (HL_CFFIPointer* window, hl_vstring* applicationName) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = VK_NULL_HANDLE;
		const char* applicationNameUTF8 = applicationName ? (const char*)hl_to_utf8 ((const uchar*)applicationName->bytes) : 0;

		if (!CreateManagedVulkanInstance (targetWindow, applicationNameUTF8, &instance)) {

			return 0;

		}

		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)instance);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_instance (value window, int instanceHigh, int instanceLow) {

#ifdef LIME_VULKAN
		if (instanceHigh == 0 && instanceLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = targetWindow ? (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr () : 0;
		if (!vkGetInstanceProcAddr) return;

		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		PFN_vkDestroyInstance vkDestroyInstance = (PFN_vkDestroyInstance)vkGetInstanceProcAddr (instance, "vkDestroyInstance");
		if (vkDestroyInstance) {

			vkDestroyInstance (instance, 0);

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_instance) (HL_CFFIPointer* window, int instanceHigh, int instanceLow) {

#ifdef LIME_VULKAN
		if (instanceHigh == 0 && instanceLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = targetWindow ? (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr () : 0;
		if (!vkGetInstanceProcAddr) return;

		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		PFN_vkDestroyInstance vkDestroyInstance = (PFN_vkDestroyInstance)vkGetInstanceProcAddr (instance, "vkDestroyInstance");
		if (vkDestroyInstance) {

			vkDestroyInstance (instance, 0);

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	void lime_vk_destroy_surface (value window, int instanceHigh, int instanceLow, int surfaceHigh, int surfaceLow) {

#ifdef LIME_VULKAN
		if (instanceHigh == 0 && instanceLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = targetWindow ? (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr () : 0;
		if (!vkGetInstanceProcAddr) return;

		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkSurfaceKHR surface = UInt64ToVulkanSurface (CombineVulkanHandle (surfaceHigh, surfaceLow));
		if (!surface) return;

		PFN_vkDestroySurfaceKHR vkDestroySurfaceKHR = (PFN_vkDestroySurfaceKHR)vkGetInstanceProcAddr (instance, "vkDestroySurfaceKHR");
		if (vkDestroySurfaceKHR) {

			vkDestroySurfaceKHR (instance, surface, 0);

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_surface) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int surfaceHigh, int surfaceLow) {

#ifdef LIME_VULKAN
		if (instanceHigh == 0 && instanceLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = targetWindow ? (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr () : 0;
		if (!vkGetInstanceProcAddr) return;

		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkSurfaceKHR surface = UInt64ToVulkanSurface (CombineVulkanHandle (surfaceHigh, surfaceLow));
		if (!surface) return;

		PFN_vkDestroySurfaceKHR vkDestroySurfaceKHR = (PFN_vkDestroySurfaceKHR)vkGetInstanceProcAddr (instance, "vkDestroySurfaceKHR");
		if (vkDestroySurfaceKHR) {

			vkDestroySurfaceKHR (instance, surface, 0);

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	value lime_vk_get_physical_devices (value window, int instanceHigh, int instanceLow, int surfaceHigh, int surfaceLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);

		if (!targetWindow || !instance) {

			lastVKError = "Missing Vulkan window or instance";
			return alloc_null ();

		}

		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr ();
		if (!vkGetInstanceProcAddr) {

			lastVKError = "SDL did not expose vkGetInstanceProcAddr";
			return alloc_null ();

		}

		PFN_vkEnumeratePhysicalDevices vkEnumeratePhysicalDevices = (PFN_vkEnumeratePhysicalDevices)vkGetInstanceProcAddr (instance,
			"vkEnumeratePhysicalDevices");
		PFN_vkGetPhysicalDeviceProperties vkGetPhysicalDeviceProperties = (PFN_vkGetPhysicalDeviceProperties)vkGetInstanceProcAddr (instance,
			"vkGetPhysicalDeviceProperties");
		PFN_vkGetPhysicalDeviceQueueFamilyProperties vkGetPhysicalDeviceQueueFamilyProperties =
			(PFN_vkGetPhysicalDeviceQueueFamilyProperties)vkGetInstanceProcAddr (instance, "vkGetPhysicalDeviceQueueFamilyProperties");
		PFN_vkGetPhysicalDeviceSurfaceSupportKHR vkGetPhysicalDeviceSurfaceSupportKHR =
			(PFN_vkGetPhysicalDeviceSurfaceSupportKHR)vkGetInstanceProcAddr (instance, "vkGetPhysicalDeviceSurfaceSupportKHR");

		if (!vkEnumeratePhysicalDevices || !vkGetPhysicalDeviceProperties || !vkGetPhysicalDeviceQueueFamilyProperties) {

			lastVKError = "Missing required Vulkan instance functions";
			return alloc_null ();

		}

		VkSurfaceKHR surface = UInt64ToVulkanSurface (CombineVulkanHandle (surfaceHigh, surfaceLow));
		uint32_t deviceCount = 0;
		VkResult result = vkEnumeratePhysicalDevices (instance, &deviceCount, 0);

		if (result != VK_SUCCESS) {

			lastVKError = "vkEnumeratePhysicalDevices failed";
			return alloc_null ();

		}

		value devices = alloc_array (deviceCount);
		if (deviceCount == 0) {

			lastVKError.clear ();
			return devices;

		}

		std::vector<VkPhysicalDevice> physicalDevices (deviceCount);
		result = vkEnumeratePhysicalDevices (instance, &deviceCount, physicalDevices.data ());

		if (result != VK_SUCCESS) {

			lastVKError = "vkEnumeratePhysicalDevices returned incomplete data";
			return alloc_null ();

		}

		const int id_handle = val_id ("handle");
		const int id_name = val_id ("name");
		const int id_apiVersion = val_id ("apiVersion");
		const int id_driverVersion = val_id ("driverVersion");
		const int id_vendorID = val_id ("vendorID");
		const int id_deviceID = val_id ("deviceID");
		const int id_deviceType = val_id ("deviceType");
		const int id_framebufferColorSampleCounts = val_id ("framebufferColorSampleCounts");
		const int id_framebufferDepthSampleCounts = val_id ("framebufferDepthSampleCounts");
		const int id_framebufferNoAttachmentsSampleCounts = val_id ("framebufferNoAttachmentsSampleCounts");
		const int id_framebufferStencilSampleCounts = val_id ("framebufferStencilSampleCounts");
		const int id_maxPushConstantsSize = val_id ("maxPushConstantsSize");
		const int id_minStorageBufferOffsetAlignment = val_id ("minStorageBufferOffsetAlignment");
		const int id_minUniformBufferOffsetAlignment = val_id ("minUniformBufferOffsetAlignment");
		const int id_nonCoherentAtomSize = val_id ("nonCoherentAtomSize");
		const int id_queueFamilies = val_id ("queueFamilies");

		const int id_index = val_id ("index");
		const int id_flags = val_id ("flags");
		const int id_queueCount = val_id ("queueCount");
		const int id_timestampValidBits = val_id ("timestampValidBits");
		const int id_supportsGraphics = val_id ("supportsGraphics");
		const int id_supportsCompute = val_id ("supportsCompute");
		const int id_supportsTransfer = val_id ("supportsTransfer");
		const int id_supportsPresent = val_id ("supportsPresent");

		for (uint32_t i = 0; i < deviceCount; ++i) {

			VkPhysicalDeviceProperties properties;
			memset (&properties, 0, sizeof (properties));
			vkGetPhysicalDeviceProperties (physicalDevices[i], &properties);

			uint32_t queueFamilyCount = 0;
			vkGetPhysicalDeviceQueueFamilyProperties (physicalDevices[i], &queueFamilyCount, 0);
			std::vector<VkQueueFamilyProperties> queueFamilies (queueFamilyCount);
			if (queueFamilyCount > 0) {

				vkGetPhysicalDeviceQueueFamilyProperties (physicalDevices[i], &queueFamilyCount, queueFamilies.data ());

			}

			value queueFamilyArray = alloc_array (queueFamilyCount);

			for (uint32_t q = 0; q < queueFamilyCount; ++q) {

				VkBool32 supportsPresent = VK_FALSE;
				if (surface && vkGetPhysicalDeviceSurfaceSupportKHR) {

					vkGetPhysicalDeviceSurfaceSupportKHR (physicalDevices[i], q, surface, &supportsPresent);

				}

				value queueFamilyObject = alloc_empty_object ();
				alloc_field (queueFamilyObject, id_index, alloc_int (q));
				alloc_field (queueFamilyObject, id_flags, alloc_int (queueFamilies[q].queueFlags));
				alloc_field (queueFamilyObject, id_queueCount, alloc_int (queueFamilies[q].queueCount));
				alloc_field (queueFamilyObject, id_timestampValidBits, alloc_int (queueFamilies[q].timestampValidBits));
				alloc_field (queueFamilyObject, id_supportsGraphics, alloc_bool ((queueFamilies[q].queueFlags & VK_QUEUE_GRAPHICS_BIT) != 0));
				alloc_field (queueFamilyObject, id_supportsCompute, alloc_bool ((queueFamilies[q].queueFlags & VK_QUEUE_COMPUTE_BIT) != 0));
				alloc_field (queueFamilyObject, id_supportsTransfer, alloc_bool ((queueFamilies[q].queueFlags & VK_QUEUE_TRANSFER_BIT) != 0));
				alloc_field (queueFamilyObject, id_supportsPresent, alloc_bool (supportsPresent != VK_FALSE));
				val_array_set_i (queueFamilyArray, q, queueFamilyObject);

			}

			value deviceObject = alloc_empty_object ();
			alloc_field (deviceObject, id_handle, CreateVulkanHandleValue ((uint64_t)(uintptr_t)physicalDevices[i]));
			alloc_field (deviceObject, id_name, alloc_string (properties.deviceName));
			alloc_field (deviceObject, id_apiVersion, alloc_int (properties.apiVersion));
			alloc_field (deviceObject, id_driverVersion, alloc_int (properties.driverVersion));
			alloc_field (deviceObject, id_vendorID, alloc_int (properties.vendorID));
			alloc_field (deviceObject, id_deviceID, alloc_int (properties.deviceID));
			alloc_field (deviceObject, id_deviceType, alloc_int (properties.deviceType));
			alloc_field (deviceObject, id_framebufferColorSampleCounts, alloc_int ((int)properties.limits.framebufferColorSampleCounts));
			alloc_field (deviceObject, id_framebufferDepthSampleCounts, alloc_int ((int)properties.limits.framebufferDepthSampleCounts));
			alloc_field (deviceObject, id_framebufferNoAttachmentsSampleCounts, alloc_int ((int)properties.limits.framebufferNoAttachmentsSampleCounts));
			alloc_field (deviceObject, id_framebufferStencilSampleCounts, alloc_int ((int)properties.limits.framebufferStencilSampleCounts));
			alloc_field (deviceObject, id_maxPushConstantsSize, alloc_int ((int)properties.limits.maxPushConstantsSize));
			alloc_field (deviceObject, id_minStorageBufferOffsetAlignment,
				CreateVulkanHandleValue ((uint64_t)properties.limits.minStorageBufferOffsetAlignment));
			alloc_field (deviceObject, id_minUniformBufferOffsetAlignment,
				CreateVulkanHandleValue ((uint64_t)properties.limits.minUniformBufferOffsetAlignment));
			alloc_field (deviceObject, id_nonCoherentAtomSize, CreateVulkanHandleValue ((uint64_t)properties.limits.nonCoherentAtomSize));
			alloc_field (deviceObject, id_queueFamilies, queueFamilyArray);
			val_array_set_i (devices, i, deviceObject);

		}

		lastVKError.clear ();
		return devices;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_array (0);
#endif

	}


	HL_PRIM hl_varray* HL_NAME(hl_vk_get_physical_devices) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int surfaceHigh, int surfaceLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);

		if (!targetWindow || !instance) {

			lastVKError = "Missing Vulkan window or instance";
			return 0;

		}

		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr ();
		if (!vkGetInstanceProcAddr) {

			lastVKError = "SDL did not expose vkGetInstanceProcAddr";
			return 0;

		}

		PFN_vkEnumeratePhysicalDevices vkEnumeratePhysicalDevices = (PFN_vkEnumeratePhysicalDevices)vkGetInstanceProcAddr (instance,
			"vkEnumeratePhysicalDevices");
		PFN_vkGetPhysicalDeviceProperties vkGetPhysicalDeviceProperties = (PFN_vkGetPhysicalDeviceProperties)vkGetInstanceProcAddr (instance,
			"vkGetPhysicalDeviceProperties");
		PFN_vkGetPhysicalDeviceQueueFamilyProperties vkGetPhysicalDeviceQueueFamilyProperties =
			(PFN_vkGetPhysicalDeviceQueueFamilyProperties)vkGetInstanceProcAddr (instance, "vkGetPhysicalDeviceQueueFamilyProperties");
		PFN_vkGetPhysicalDeviceSurfaceSupportKHR vkGetPhysicalDeviceSurfaceSupportKHR =
			(PFN_vkGetPhysicalDeviceSurfaceSupportKHR)vkGetInstanceProcAddr (instance, "vkGetPhysicalDeviceSurfaceSupportKHR");

		if (!vkEnumeratePhysicalDevices || !vkGetPhysicalDeviceProperties || !vkGetPhysicalDeviceQueueFamilyProperties) {

			lastVKError = "Missing required Vulkan instance functions";
			return 0;

		}

		VkSurfaceKHR surface = UInt64ToVulkanSurface (CombineVulkanHandle (surfaceHigh, surfaceLow));
		uint32_t deviceCount = 0;
		VkResult result = vkEnumeratePhysicalDevices (instance, &deviceCount, 0);

		if (result != VK_SUCCESS) {

			lastVKError = "vkEnumeratePhysicalDevices failed";
			return 0;

		}

		hl_varray* devices = (hl_varray*)hl_alloc_array (&hlt_dynobj, deviceCount);
		if (deviceCount == 0) {

			lastVKError.clear ();
			return devices;

		}

		std::vector<VkPhysicalDevice> physicalDevices (deviceCount);
		result = vkEnumeratePhysicalDevices (instance, &deviceCount, physicalDevices.data ());

		if (result != VK_SUCCESS) {

			lastVKError = "vkEnumeratePhysicalDevices returned incomplete data";
			return 0;

		}

		vdynamic** deviceData = hl_aptr (devices, vdynamic*);

		const int id_handle = hl_hash_utf8 ("handle");
		const int id_name = hl_hash_utf8 ("name");
		const int id_apiVersion = hl_hash_utf8 ("apiVersion");
		const int id_driverVersion = hl_hash_utf8 ("driverVersion");
		const int id_vendorID = hl_hash_utf8 ("vendorID");
		const int id_deviceID = hl_hash_utf8 ("deviceID");
		const int id_deviceType = hl_hash_utf8 ("deviceType");
		const int id_framebufferColorSampleCounts = hl_hash_utf8 ("framebufferColorSampleCounts");
		const int id_framebufferDepthSampleCounts = hl_hash_utf8 ("framebufferDepthSampleCounts");
		const int id_framebufferNoAttachmentsSampleCounts = hl_hash_utf8 ("framebufferNoAttachmentsSampleCounts");
		const int id_framebufferStencilSampleCounts = hl_hash_utf8 ("framebufferStencilSampleCounts");
		const int id_maxPushConstantsSize = hl_hash_utf8 ("maxPushConstantsSize");
		const int id_minStorageBufferOffsetAlignment = hl_hash_utf8 ("minStorageBufferOffsetAlignment");
		const int id_minUniformBufferOffsetAlignment = hl_hash_utf8 ("minUniformBufferOffsetAlignment");
		const int id_nonCoherentAtomSize = hl_hash_utf8 ("nonCoherentAtomSize");
		const int id_queueFamilies = hl_hash_utf8 ("queueFamilies");

		const int id_index = hl_hash_utf8 ("index");
		const int id_flags = hl_hash_utf8 ("flags");
		const int id_queueCount = hl_hash_utf8 ("queueCount");
		const int id_timestampValidBits = hl_hash_utf8 ("timestampValidBits");
		const int id_supportsGraphics = hl_hash_utf8 ("supportsGraphics");
		const int id_supportsCompute = hl_hash_utf8 ("supportsCompute");
		const int id_supportsTransfer = hl_hash_utf8 ("supportsTransfer");
		const int id_supportsPresent = hl_hash_utf8 ("supportsPresent");

		for (uint32_t i = 0; i < deviceCount; ++i) {

			VkPhysicalDeviceProperties properties;
			memset (&properties, 0, sizeof (properties));
			vkGetPhysicalDeviceProperties (physicalDevices[i], &properties);

			uint32_t queueFamilyCount = 0;
			vkGetPhysicalDeviceQueueFamilyProperties (physicalDevices[i], &queueFamilyCount, 0);
			std::vector<VkQueueFamilyProperties> queueFamilies (queueFamilyCount);
			if (queueFamilyCount > 0) {

				vkGetPhysicalDeviceQueueFamilyProperties (physicalDevices[i], &queueFamilyCount, queueFamilies.data ());

			}

			hl_varray* queueFamilyArray = (hl_varray*)hl_alloc_array (&hlt_dynobj, queueFamilyCount);
			vdynamic** queueFamilyData = hl_aptr (queueFamilyArray, vdynamic*);

			for (uint32_t q = 0; q < queueFamilyCount; ++q) {

				VkBool32 supportsPresent = VK_FALSE;
				if (surface && vkGetPhysicalDeviceSurfaceSupportKHR) {

					vkGetPhysicalDeviceSurfaceSupportKHR (physicalDevices[i], q, surface, &supportsPresent);

				}

				vdynamic* queueFamilyObject = (vdynamic*)hl_alloc_dynobj ();
				*queueFamilyData++ = queueFamilyObject;
				hl_dyn_seti (queueFamilyObject, id_index, &hlt_i32, q);
				hl_dyn_seti (queueFamilyObject, id_flags, &hlt_i32, queueFamilies[q].queueFlags);
				hl_dyn_seti (queueFamilyObject, id_queueCount, &hlt_i32, queueFamilies[q].queueCount);
				hl_dyn_seti (queueFamilyObject, id_timestampValidBits, &hlt_i32, queueFamilies[q].timestampValidBits);
				hl_dyn_seti (queueFamilyObject, id_supportsGraphics, &hlt_bool, (queueFamilies[q].queueFlags & VK_QUEUE_GRAPHICS_BIT) != 0);
				hl_dyn_seti (queueFamilyObject, id_supportsCompute, &hlt_bool, (queueFamilies[q].queueFlags & VK_QUEUE_COMPUTE_BIT) != 0);
				hl_dyn_seti (queueFamilyObject, id_supportsTransfer, &hlt_bool, (queueFamilies[q].queueFlags & VK_QUEUE_TRANSFER_BIT) != 0);
				hl_dyn_seti (queueFamilyObject, id_supportsPresent, &hlt_bool, supportsPresent != VK_FALSE);

			}

			vdynamic* deviceObject = (vdynamic*)hl_alloc_dynobj ();
			*deviceData++ = deviceObject;
			hl_dyn_setp (deviceObject, id_handle, &hlt_dynobj, HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)physicalDevices[i]));
			hl_dyn_setp (deviceObject, id_name, &hlt_bytes, hl_copy_bytes ((const vbyte*)properties.deviceName, (int)std::strlen (properties.deviceName) + 1));
			hl_dyn_seti (deviceObject, id_apiVersion, &hlt_i32, properties.apiVersion);
			hl_dyn_seti (deviceObject, id_driverVersion, &hlt_i32, properties.driverVersion);
			hl_dyn_seti (deviceObject, id_vendorID, &hlt_i32, properties.vendorID);
			hl_dyn_seti (deviceObject, id_deviceID, &hlt_i32, properties.deviceID);
			hl_dyn_seti (deviceObject, id_deviceType, &hlt_i32, properties.deviceType);
			hl_dyn_seti (deviceObject, id_framebufferColorSampleCounts, &hlt_i32, properties.limits.framebufferColorSampleCounts);
			hl_dyn_seti (deviceObject, id_framebufferDepthSampleCounts, &hlt_i32, properties.limits.framebufferDepthSampleCounts);
			hl_dyn_seti (deviceObject, id_framebufferNoAttachmentsSampleCounts, &hlt_i32, properties.limits.framebufferNoAttachmentsSampleCounts);
			hl_dyn_seti (deviceObject, id_framebufferStencilSampleCounts, &hlt_i32, properties.limits.framebufferStencilSampleCounts);
			hl_dyn_seti (deviceObject, id_maxPushConstantsSize, &hlt_i32, properties.limits.maxPushConstantsSize);
			hl_dyn_setp (deviceObject, id_minStorageBufferOffsetAlignment, &hlt_dynobj,
				HLCreateVulkanHandleValue ((uint64_t)properties.limits.minStorageBufferOffsetAlignment));
			hl_dyn_setp (deviceObject, id_minUniformBufferOffsetAlignment, &hlt_dynobj,
				HLCreateVulkanHandleValue ((uint64_t)properties.limits.minUniformBufferOffsetAlignment));
			hl_dyn_setp (deviceObject, id_nonCoherentAtomSize, &hlt_dynobj,
				HLCreateVulkanHandleValue ((uint64_t)properties.limits.nonCoherentAtomSize));
			hl_dyn_setp (deviceObject, id_queueFamilies, &hlt_array, queueFamilyArray);

		}

		lastVKError.clear ();
		return devices;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return (hl_varray*)hl_alloc_array (&hlt_dynobj, 0);
#endif

	}


	value lime_vk_create_device (value window, int instanceHigh, int instanceLow, int physicalDeviceHigh, int physicalDeviceLow, int queueFamilyIndex,
		value extensions) {

#ifdef LIME_VULKAN
		LogVulkanNativeBootstrap ("lime_vk_create_device: begin");
		if (val_is_null (window)) {

			lastVKError = "Missing Lime window for Vulkan device creation";
			LogVulkanNativeBootstrap ("lime_vk_create_device: null window");
			return alloc_null ();

		}
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkPhysicalDevice physicalDevice = (VkPhysicalDevice)(uintptr_t)CombineVulkanHandle (physicalDeviceHigh, physicalDeviceLow);
		LogVulkanNativeBootstrap ("lime_vk_create_device: decoded handles");
		std::vector<std::string> deviceExtensions = GetVulkanDeviceExtensions (extensions);
		LogVulkanNativeBootstrap ("lime_vk_create_device: decoded extensions");
		VkDevice device = VK_NULL_HANDLE;
		VkQueue queue = VK_NULL_HANDLE;

		if (!CreateManagedVulkanDevice (targetWindow, instance, physicalDevice, queueFamilyIndex, deviceExtensions, &device, &queue)) {

			LogVulkanNativeBootstrap ("lime_vk_create_device: CreateManagedVulkanDevice failed");
			return alloc_null ();

		}

		LogVulkanNativeBootstrap ("lime_vk_create_device: create result object");
		value result = alloc_empty_object ();
		alloc_field (result, val_id ("handle"), CreateVulkanHandleValue ((uint64_t)(uintptr_t)device));
		alloc_field (result, val_id ("queue"), CreateVulkanHandleValue ((uint64_t)(uintptr_t)queue));
		alloc_field (result, val_id ("queueFamilyIndex"), alloc_int (queueFamilyIndex));
		LogVulkanNativeBootstrap ("lime_vk_create_device: success");
		return result;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_device) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int physicalDeviceHigh,
		int physicalDeviceLow, int queueFamilyIndex, hl_varray* extensions) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkPhysicalDevice physicalDevice = (VkPhysicalDevice)(uintptr_t)CombineVulkanHandle (physicalDeviceHigh, physicalDeviceLow);
		std::vector<std::string> deviceExtensions = GetHLVulkanDeviceExtensions (extensions);
		VkDevice device = VK_NULL_HANDLE;
		VkQueue queue = VK_NULL_HANDLE;

		if (!CreateManagedVulkanDevice (targetWindow, instance, physicalDevice, queueFamilyIndex, deviceExtensions, &device, &queue)) {

			return 0;

		}

		const int id_handle = hl_hash_utf8 ("handle");
		const int id_queue = hl_hash_utf8 ("queue");
		const int id_queueFamilyIndex = hl_hash_utf8 ("queueFamilyIndex");
		vdynamic* result = (vdynamic*)hl_alloc_dynobj ();
		hl_dyn_setp (result, id_handle, &hlt_dynobj, HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)device));
		hl_dyn_setp (result, id_queue, &hlt_dynobj, HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)queue));
		hl_dyn_seti (result, id_queueFamilyIndex, &hlt_i32, queueFamilyIndex);
		return result;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_device (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow) {

#ifdef LIME_VULKAN
		if (deviceHigh == 0 && deviceLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = targetWindow ? (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr () : 0;
		if (!vkGetInstanceProcAddr) return;

		PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr = (PFN_vkGetDeviceProcAddr)vkGetInstanceProcAddr (instance, "vkGetDeviceProcAddr");
		if (!vkGetDeviceProcAddr) return;

		PFN_vkDestroyDevice vkDestroyDevice = (PFN_vkDestroyDevice)vkGetDeviceProcAddr (device, "vkDestroyDevice");
		if (vkDestroyDevice) {

			ClearManagedVulkanDeviceProcCache (device);
			vkDestroyDevice (device, 0);

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_device) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow) {

#ifdef LIME_VULKAN
		if (deviceHigh == 0 && deviceLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = targetWindow ? (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr () : 0;
		if (!vkGetInstanceProcAddr) return;

		PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr = (PFN_vkGetDeviceProcAddr)vkGetInstanceProcAddr (instance, "vkGetDeviceProcAddr");
		if (!vkGetDeviceProcAddr) return;

		PFN_vkDestroyDevice vkDestroyDevice = (PFN_vkDestroyDevice)vkGetDeviceProcAddr (device, "vkDestroyDevice");
		if (vkDestroyDevice) {

			ClearManagedVulkanDeviceProcCache (device);
			vkDestroyDevice (device, 0);

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	bool lime_vk_device_wait_idle (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = targetWindow ? (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr () : 0;
		if (!vkGetInstanceProcAddr || !instance || !device) {

			lastVKError = "Missing Vulkan window, instance, or device";
			return false;

		}

		PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr = (PFN_vkGetDeviceProcAddr)vkGetInstanceProcAddr (instance, "vkGetDeviceProcAddr");
		if (!vkGetDeviceProcAddr) {

			lastVKError = "Missing Vulkan device proc address function";
			return false;

		}

		PFN_vkDeviceWaitIdle vkDeviceWaitIdle = (PFN_vkDeviceWaitIdle)vkGetDeviceProcAddr (device, "vkDeviceWaitIdle");
		if (!vkDeviceWaitIdle) {

			lastVKError = "Missing Vulkan device wait idle function";
			return false;

		}

		VkResult result = vkDeviceWaitIdle (device);
		if (result != VK_SUCCESS) {

			lastVKError = "vkDeviceWaitIdle failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_device_wait_idle) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = targetWindow ? (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr () : 0;
		if (!vkGetInstanceProcAddr || !instance || !device) {

			lastVKError = "Missing Vulkan window, instance, or device";
			return false;

		}

		PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr = (PFN_vkGetDeviceProcAddr)vkGetInstanceProcAddr (instance, "vkGetDeviceProcAddr");
		if (!vkGetDeviceProcAddr) {

			lastVKError = "Missing Vulkan device proc address function";
			return false;

		}

		PFN_vkDeviceWaitIdle vkDeviceWaitIdle = (PFN_vkDeviceWaitIdle)vkGetDeviceProcAddr (device, "vkDeviceWaitIdle");
		if (!vkDeviceWaitIdle) {

			lastVKError = "Missing Vulkan device wait idle function";
			return false;

		}

		VkResult result = vkDeviceWaitIdle (device);
		if (result != VK_SUCCESS) {

			lastVKError = "vkDeviceWaitIdle failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_queue_wait_idle (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int queueHigh, int queueLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkQueue queue = (VkQueue)(uintptr_t)CombineVulkanHandle (queueHigh, queueLow);
		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = targetWindow ? (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr () : 0;
		if (!vkGetInstanceProcAddr || !instance || !device || !queue) {

			lastVKError = "Missing Vulkan window, instance, device, or queue";
			return false;

		}

		PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr = (PFN_vkGetDeviceProcAddr)vkGetInstanceProcAddr (instance, "vkGetDeviceProcAddr");
		if (!vkGetDeviceProcAddr) {

			lastVKError = "Missing Vulkan device proc address function";
			return false;

		}

		PFN_vkQueueWaitIdle vkQueueWaitIdle = (PFN_vkQueueWaitIdle)vkGetDeviceProcAddr (device, "vkQueueWaitIdle");
		if (!vkQueueWaitIdle) {

			lastVKError = "Missing Vulkan queue wait idle function";
			return false;

		}

		VkResult result = vkQueueWaitIdle (queue);
		if (result != VK_SUCCESS) {

			lastVKError = "vkQueueWaitIdle failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_queue_wait_idle) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int queueHigh,
		int queueLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkQueue queue = (VkQueue)(uintptr_t)CombineVulkanHandle (queueHigh, queueLow);
		PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr = targetWindow ? (PFN_vkGetInstanceProcAddr)targetWindow->GetVulkanInstanceProcAddr () : 0;
		if (!vkGetInstanceProcAddr || !instance || !device || !queue) {

			lastVKError = "Missing Vulkan window, instance, device, or queue";
			return false;

		}

		PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr = (PFN_vkGetDeviceProcAddr)vkGetInstanceProcAddr (instance, "vkGetDeviceProcAddr");
		if (!vkGetDeviceProcAddr) {

			lastVKError = "Missing Vulkan device proc address function";
			return false;

		}

		PFN_vkQueueWaitIdle vkQueueWaitIdle = (PFN_vkQueueWaitIdle)vkGetDeviceProcAddr (device, "vkQueueWaitIdle");
		if (!vkQueueWaitIdle) {

			lastVKError = "Missing Vulkan queue wait idle function";
			return false;

		}

		VkResult result = vkQueueWaitIdle (queue);
		if (result != VK_SUCCESS) {

			lastVKError = "vkQueueWaitIdle failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	value lime_vk_create_command_pool (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int queueFamilyIndex, int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateCommandPool vkCreateCommandPool = (PFN_vkCreateCommandPool)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCreateCommandPool");
		if (!vkCreateCommandPool) return alloc_null ();

		VkCommandPoolCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
		createInfo.flags = flags;
		createInfo.queueFamilyIndex = queueFamilyIndex;

		VkCommandPool commandPool = VK_NULL_HANDLE;
		VkResult result = vkCreateCommandPool (device, &createInfo, 0, &commandPool);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateCommandPool failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)commandPool);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_command_pool) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int queueFamilyIndex, int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateCommandPool vkCreateCommandPool = (PFN_vkCreateCommandPool)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCreateCommandPool");
		if (!vkCreateCommandPool) return 0;

		VkCommandPoolCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
		createInfo.flags = flags;
		createInfo.queueFamilyIndex = queueFamilyIndex;

		VkCommandPool commandPool = VK_NULL_HANDLE;
		VkResult result = vkCreateCommandPool (device, &createInfo, 0, &commandPool);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateCommandPool failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)commandPool);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_command_pool (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandPoolHigh,
		int commandPoolLow) {

#ifdef LIME_VULKAN
		if (commandPoolHigh == 0 && commandPoolLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandPool commandPool = (VkCommandPool)(uintptr_t)CombineVulkanHandle (commandPoolHigh, commandPoolLow);
		PFN_vkDestroyCommandPool vkDestroyCommandPool = (PFN_vkDestroyCommandPool)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroyCommandPool");
		if (vkDestroyCommandPool) vkDestroyCommandPool (device, commandPool, 0);
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_command_pool) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandPoolHigh, int commandPoolLow) {

#ifdef LIME_VULKAN
		if (commandPoolHigh == 0 && commandPoolLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandPool commandPool = (VkCommandPool)(uintptr_t)CombineVulkanHandle (commandPoolHigh, commandPoolLow);
		PFN_vkDestroyCommandPool vkDestroyCommandPool = (PFN_vkDestroyCommandPool)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroyCommandPool");
		if (vkDestroyCommandPool) vkDestroyCommandPool (device, commandPool, 0);
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	bool lime_vk_reset_command_pool (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandPoolHigh,
		int commandPoolLow, int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandPool commandPool = (VkCommandPool)(uintptr_t)CombineVulkanHandle (commandPoolHigh, commandPoolLow);
		PFN_vkResetCommandPool vkResetCommandPool = (PFN_vkResetCommandPool)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkResetCommandPool");
		if (!vkResetCommandPool) return false;

		VkResult result = vkResetCommandPool (device, commandPool, flags);
		if (result != VK_SUCCESS) {

			lastVKError = "vkResetCommandPool failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_reset_command_pool) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandPoolHigh, int commandPoolLow, int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandPool commandPool = (VkCommandPool)(uintptr_t)CombineVulkanHandle (commandPoolHigh, commandPoolLow);
		PFN_vkResetCommandPool vkResetCommandPool = (PFN_vkResetCommandPool)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkResetCommandPool");
		if (!vkResetCommandPool) return false;

		VkResult result = vkResetCommandPool (device, commandPool, flags);
		if (result != VK_SUCCESS) {

			lastVKError = "vkResetCommandPool failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	value lime_vk_allocate_command_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandPoolHigh,
		int commandPoolLow, int level) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandPool commandPool = (VkCommandPool)(uintptr_t)CombineVulkanHandle (commandPoolHigh, commandPoolLow);
		PFN_vkAllocateCommandBuffers vkAllocateCommandBuffers = (PFN_vkAllocateCommandBuffers)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkAllocateCommandBuffers");
		if (!vkAllocateCommandBuffers) return alloc_null ();

		VkCommandBufferAllocateInfo allocateInfo;
		memset (&allocateInfo, 0, sizeof (allocateInfo));
		allocateInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
		allocateInfo.commandPool = commandPool;
		allocateInfo.level = (VkCommandBufferLevel)level;
		allocateInfo.commandBufferCount = 1;

		VkCommandBuffer commandBuffer = VK_NULL_HANDLE;
		VkResult result = vkAllocateCommandBuffers (device, &allocateInfo, &commandBuffer);
		if (result != VK_SUCCESS) {

			lastVKError = "vkAllocateCommandBuffers failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)commandBuffer);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_allocate_command_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandPoolHigh, int commandPoolLow, int level) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandPool commandPool = (VkCommandPool)(uintptr_t)CombineVulkanHandle (commandPoolHigh, commandPoolLow);
		PFN_vkAllocateCommandBuffers vkAllocateCommandBuffers = (PFN_vkAllocateCommandBuffers)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkAllocateCommandBuffers");
		if (!vkAllocateCommandBuffers) return 0;

		VkCommandBufferAllocateInfo allocateInfo;
		memset (&allocateInfo, 0, sizeof (allocateInfo));
		allocateInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
		allocateInfo.commandPool = commandPool;
		allocateInfo.level = (VkCommandBufferLevel)level;
		allocateInfo.commandBufferCount = 1;

		VkCommandBuffer commandBuffer = VK_NULL_HANDLE;
		VkResult result = vkAllocateCommandBuffers (device, &allocateInfo, &commandBuffer);
		if (result != VK_SUCCESS) {

			lastVKError = "vkAllocateCommandBuffers failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)commandBuffer);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_free_command_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandPoolHigh,
		int commandPoolLow, int commandBufferHigh, int commandBufferLow) {

#ifdef LIME_VULKAN
		if (commandBufferHigh == 0 && commandBufferLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandPool commandPool = (VkCommandPool)(uintptr_t)CombineVulkanHandle (commandPoolHigh, commandPoolLow);
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		PFN_vkFreeCommandBuffers vkFreeCommandBuffers = (PFN_vkFreeCommandBuffers)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkFreeCommandBuffers");
		if (vkFreeCommandBuffers) vkFreeCommandBuffers (device, commandPool, 1, &commandBuffer);
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_free_command_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandPoolHigh, int commandPoolLow, int commandBufferHigh, int commandBufferLow) {

#ifdef LIME_VULKAN
		if (commandBufferHigh == 0 && commandBufferLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandPool commandPool = (VkCommandPool)(uintptr_t)CombineVulkanHandle (commandPoolHigh, commandPoolLow);
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		PFN_vkFreeCommandBuffers vkFreeCommandBuffers = (PFN_vkFreeCommandBuffers)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkFreeCommandBuffers");
		if (vkFreeCommandBuffers) vkFreeCommandBuffers (device, commandPool, 1, &commandBuffer);
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	bool lime_vk_begin_command_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		PFN_vkBeginCommandBuffer vkBeginCommandBuffer = (PFN_vkBeginCommandBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkBeginCommandBuffer");
		if (!vkBeginCommandBuffer) return false;

		VkCommandBufferBeginInfo beginInfo;
		memset (&beginInfo, 0, sizeof (beginInfo));
		beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
		beginInfo.flags = flags;

		VkResult result = vkBeginCommandBuffer (commandBuffer, &beginInfo);
		if (result != VK_SUCCESS) {

			lastVKError = "vkBeginCommandBuffer failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_begin_command_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		PFN_vkBeginCommandBuffer vkBeginCommandBuffer = (PFN_vkBeginCommandBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkBeginCommandBuffer");
		if (!vkBeginCommandBuffer) return false;

		VkCommandBufferBeginInfo beginInfo;
		memset (&beginInfo, 0, sizeof (beginInfo));
		beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
		beginInfo.flags = flags;

		VkResult result = vkBeginCommandBuffer (commandBuffer, &beginInfo);
		if (result != VK_SUCCESS) {

			lastVKError = "vkBeginCommandBuffer failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_end_command_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		PFN_vkEndCommandBuffer vkEndCommandBuffer = (PFN_vkEndCommandBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkEndCommandBuffer");
		if (!vkEndCommandBuffer) return false;

		VkResult result = vkEndCommandBuffer (commandBuffer);
		if (result != VK_SUCCESS) {

			lastVKError = "vkEndCommandBuffer failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_end_command_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		PFN_vkEndCommandBuffer vkEndCommandBuffer = (PFN_vkEndCommandBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkEndCommandBuffer");
		if (!vkEndCommandBuffer) return false;

		VkResult result = vkEndCommandBuffer (commandBuffer);
		if (result != VK_SUCCESS) {

			lastVKError = "vkEndCommandBuffer failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_reset_command_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		PFN_vkResetCommandBuffer vkResetCommandBuffer = (PFN_vkResetCommandBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkResetCommandBuffer");
		if (!vkResetCommandBuffer) return false;

		VkResult result = vkResetCommandBuffer (commandBuffer, flags);
		if (result != VK_SUCCESS) {

			lastVKError = "vkResetCommandBuffer failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_reset_command_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		PFN_vkResetCommandBuffer vkResetCommandBuffer = (PFN_vkResetCommandBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkResetCommandBuffer");
		if (!vkResetCommandBuffer) return false;

		VkResult result = vkResetCommandBuffer (commandBuffer, flags);
		if (result != VK_SUCCESS) {

			lastVKError = "vkResetCommandBuffer failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	value lime_vk_create_semaphore (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateSemaphore vkCreateSemaphore = (PFN_vkCreateSemaphore)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCreateSemaphore");
		if (!vkCreateSemaphore) return alloc_null ();

		VkSemaphoreCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;

		VkSemaphore semaphore = VK_NULL_HANDLE;
		VkResult result = vkCreateSemaphore (device, &createInfo, 0, &semaphore);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateSemaphore failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)semaphore);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_semaphore) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateSemaphore vkCreateSemaphore = (PFN_vkCreateSemaphore)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCreateSemaphore");
		if (!vkCreateSemaphore) return 0;

		VkSemaphoreCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;

		VkSemaphore semaphore = VK_NULL_HANDLE;
		VkResult result = vkCreateSemaphore (device, &createInfo, 0, &semaphore);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateSemaphore failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)semaphore);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_semaphore (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int semaphoreHigh,
		int semaphoreLow) {

#ifdef LIME_VULKAN
		if (semaphoreHigh == 0 && semaphoreLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkSemaphore semaphore = (VkSemaphore)(uintptr_t)CombineVulkanHandle (semaphoreHigh, semaphoreLow);
		PFN_vkDestroySemaphore vkDestroySemaphore = (PFN_vkDestroySemaphore)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroySemaphore");
		if (vkDestroySemaphore) vkDestroySemaphore (device, semaphore, 0);
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_semaphore) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int semaphoreHigh, int semaphoreLow) {

#ifdef LIME_VULKAN
		if (semaphoreHigh == 0 && semaphoreLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkSemaphore semaphore = (VkSemaphore)(uintptr_t)CombineVulkanHandle (semaphoreHigh, semaphoreLow);
		PFN_vkDestroySemaphore vkDestroySemaphore = (PFN_vkDestroySemaphore)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroySemaphore");
		if (vkDestroySemaphore) vkDestroySemaphore (device, semaphore, 0);
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	value lime_vk_create_fence (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateFence vkCreateFence = (PFN_vkCreateFence)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateFence");
		if (!vkCreateFence) return alloc_null ();

		VkFenceCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
		createInfo.flags = flags;

		VkFence fence = VK_NULL_HANDLE;
		VkResult result = vkCreateFence (device, &createInfo, 0, &fence);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateFence failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)fence);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_fence) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateFence vkCreateFence = (PFN_vkCreateFence)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateFence");
		if (!vkCreateFence) return 0;

		VkFenceCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
		createInfo.flags = flags;

		VkFence fence = VK_NULL_HANDLE;
		VkResult result = vkCreateFence (device, &createInfo, 0, &fence);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateFence failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)fence);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_fence (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int fenceHigh, int fenceLow) {

#ifdef LIME_VULKAN
		if (fenceHigh == 0 && fenceLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkFence fence = (VkFence)(uintptr_t)CombineVulkanHandle (fenceHigh, fenceLow);
		PFN_vkDestroyFence vkDestroyFence = (PFN_vkDestroyFence)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyFence");
		if (vkDestroyFence) vkDestroyFence (device, fence, 0);
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_fence) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int fenceHigh,
		int fenceLow) {

#ifdef LIME_VULKAN
		if (fenceHigh == 0 && fenceLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkFence fence = (VkFence)(uintptr_t)CombineVulkanHandle (fenceHigh, fenceLow);
		PFN_vkDestroyFence vkDestroyFence = (PFN_vkDestroyFence)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyFence");
		if (vkDestroyFence) vkDestroyFence (device, fence, 0);
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	bool lime_vk_wait_for_fence (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int fenceHigh, int fenceLow,
		int timeoutHigh, int timeoutLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkFence fence = (VkFence)(uintptr_t)CombineVulkanHandle (fenceHigh, fenceLow);
		uint64_t timeout = CombineVulkanHandle (timeoutHigh, timeoutLow);
		PFN_vkWaitForFences vkWaitForFences = (PFN_vkWaitForFences)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkWaitForFences");
		if (!vkWaitForFences) return false;

		VkResult result = vkWaitForFences (device, 1, &fence, VK_TRUE, timeout);
		if (result != VK_SUCCESS) {

			lastVKError = "vkWaitForFences failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_wait_for_fence) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int fenceHigh,
		int fenceLow, int timeoutHigh, int timeoutLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkFence fence = (VkFence)(uintptr_t)CombineVulkanHandle (fenceHigh, fenceLow);
		uint64_t timeout = CombineVulkanHandle (timeoutHigh, timeoutLow);
		PFN_vkWaitForFences vkWaitForFences = (PFN_vkWaitForFences)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkWaitForFences");
		if (!vkWaitForFences) return false;

		VkResult result = vkWaitForFences (device, 1, &fence, VK_TRUE, timeout);
		if (result != VK_SUCCESS) {

			lastVKError = "vkWaitForFences failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_reset_fence (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int fenceHigh, int fenceLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkFence fence = (VkFence)(uintptr_t)CombineVulkanHandle (fenceHigh, fenceLow);
		PFN_vkResetFences vkResetFences = (PFN_vkResetFences)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkResetFences");
		if (!vkResetFences) return false;

		VkResult result = vkResetFences (device, 1, &fence);
		if (result != VK_SUCCESS) {

			lastVKError = "vkResetFences failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_reset_fence) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int fenceHigh,
		int fenceLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkFence fence = (VkFence)(uintptr_t)CombineVulkanHandle (fenceHigh, fenceLow);
		PFN_vkResetFences vkResetFences = (PFN_vkResetFences)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkResetFences");
		if (!vkResetFences) return false;

		VkResult result = vkResetFences (device, 1, &fence);
		if (result != VK_SUCCESS) {

			lastVKError = "vkResetFences failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_queue_submit (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int queueHigh, int queueLow,
		int commandBufferHigh, int commandBufferLow, int fenceHigh, int fenceLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkQueue queue = (VkQueue)(uintptr_t)CombineVulkanHandle (queueHigh, queueLow);
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkFence fence = (VkFence)(uintptr_t)CombineVulkanHandle (fenceHigh, fenceLow);
		PFN_vkQueueSubmit vkQueueSubmit = (PFN_vkQueueSubmit)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkQueueSubmit");
		if (!vkQueueSubmit) return false;

		VkSubmitInfo submitInfo;
		memset (&submitInfo, 0, sizeof (submitInfo));
		submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
		submitInfo.commandBufferCount = 1;
		submitInfo.pCommandBuffers = &commandBuffer;

		VkResult result = vkQueueSubmit (queue, 1, &submitInfo, fence);
		if (result != VK_SUCCESS) {

			char error[64];
			::snprintf (error, sizeof (error), "vkQueueSubmit failed: %d", (int)result);
			lastVKError = error;
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_queue_submit) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int queueHigh,
		int queueLow, int commandBufferHigh, int commandBufferLow, int fenceHigh, int fenceLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkQueue queue = (VkQueue)(uintptr_t)CombineVulkanHandle (queueHigh, queueLow);
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkFence fence = (VkFence)(uintptr_t)CombineVulkanHandle (fenceHigh, fenceLow);
		PFN_vkQueueSubmit vkQueueSubmit = (PFN_vkQueueSubmit)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkQueueSubmit");
		if (!vkQueueSubmit) return false;

		VkSubmitInfo submitInfo;
		memset (&submitInfo, 0, sizeof (submitInfo));
		submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
		submitInfo.commandBufferCount = 1;
		submitInfo.pCommandBuffers = &commandBuffer;

		VkResult result = vkQueueSubmit (queue, 1, &submitInfo, fence);
		if (result != VK_SUCCESS) {

			char error[64];
			::snprintf (error, sizeof (error), "vkQueueSubmit failed: %d", (int)result);
			lastVKError = error;
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	value lime_vk_allocate_memory (value window, int instanceHigh, int instanceLow, int physicalDeviceHigh, int physicalDeviceLow, int deviceHigh,
		int deviceLow, int sizeHigh, int sizeLow, int memoryTypeBits, int properties) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkPhysicalDevice physicalDevice = (VkPhysicalDevice)(uintptr_t)CombineVulkanHandle (physicalDeviceHigh, physicalDeviceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		uint64_t size = CombineVulkanHandle (sizeHigh, sizeLow);
		uint32_t memoryTypeIndex = 0;
		if (!FindManagedVulkanMemoryType (targetWindow, instance, physicalDevice, (uint32_t)memoryTypeBits, (VkMemoryPropertyFlags)properties,
			&memoryTypeIndex)) {

			return alloc_null ();

		}

		PFN_vkAllocateMemory vkAllocateMemory = (PFN_vkAllocateMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkAllocateMemory");
		if (!vkAllocateMemory) return alloc_null ();

		VkMemoryAllocateInfo allocateInfo;
		memset (&allocateInfo, 0, sizeof (allocateInfo));
		allocateInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
		allocateInfo.allocationSize = (VkDeviceSize)size;
		allocateInfo.memoryTypeIndex = memoryTypeIndex;

		VkDeviceMemory memory = VK_NULL_HANDLE;
		VkResult result = vkAllocateMemory (device, &allocateInfo, 0, &memory);
		if (result != VK_SUCCESS) {

			lastVKError = "vkAllocateMemory failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanMemoryValue (memory, memoryTypeIndex);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_allocate_memory) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int physicalDeviceHigh,
		int physicalDeviceLow, int deviceHigh, int deviceLow, int sizeHigh, int sizeLow, int memoryTypeBits, int properties) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkPhysicalDevice physicalDevice = (VkPhysicalDevice)(uintptr_t)CombineVulkanHandle (physicalDeviceHigh, physicalDeviceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		uint64_t size = CombineVulkanHandle (sizeHigh, sizeLow);
		uint32_t memoryTypeIndex = 0;
		if (!FindManagedVulkanMemoryType (targetWindow, instance, physicalDevice, (uint32_t)memoryTypeBits, (VkMemoryPropertyFlags)properties,
			&memoryTypeIndex)) {

			return 0;

		}

		PFN_vkAllocateMemory vkAllocateMemory = (PFN_vkAllocateMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkAllocateMemory");
		if (!vkAllocateMemory) return 0;

		VkMemoryAllocateInfo allocateInfo;
		memset (&allocateInfo, 0, sizeof (allocateInfo));
		allocateInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
		allocateInfo.allocationSize = (VkDeviceSize)size;
		allocateInfo.memoryTypeIndex = memoryTypeIndex;

		VkDeviceMemory memory = VK_NULL_HANDLE;
		VkResult result = vkAllocateMemory (device, &allocateInfo, 0, &memory);
		if (result != VK_SUCCESS) {

			lastVKError = "vkAllocateMemory failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanMemoryValue (memory, memoryTypeIndex);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_free_memory (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int memoryHigh, int memoryLow) {

#ifdef LIME_VULKAN
		if (memoryHigh == 0 && memoryLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		PFN_vkFreeMemory vkFreeMemory = (PFN_vkFreeMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkFreeMemory");
		if (vkFreeMemory) {

			uint64_t mapKey = GetManagedVulkanMappedMemoryKey (memory);
			std::unordered_map<uint64_t, ManagedVulkanMappedMemory>::iterator mapped = mappedVulkanMemory.find (mapKey);
			if (mapped != mappedVulkanMemory.end ()) {

				PFN_vkUnmapMemory vkUnmapMemory = (PFN_vkUnmapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUnmapMemory");
				if (vkUnmapMemory) vkUnmapMemory (device, memory);
				mappedVulkanMemory.erase (mapped);

			}

			vkFreeMemory (device, memory, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_free_memory) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int memoryHigh, int memoryLow) {

#ifdef LIME_VULKAN
		if (memoryHigh == 0 && memoryLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		PFN_vkFreeMemory vkFreeMemory = (PFN_vkFreeMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkFreeMemory");
		if (vkFreeMemory) {

			uint64_t mapKey = GetManagedVulkanMappedMemoryKey (memory);
			std::unordered_map<uint64_t, ManagedVulkanMappedMemory>::iterator mapped = mappedVulkanMemory.find (mapKey);
			if (mapped != mappedVulkanMemory.end ()) {

				PFN_vkUnmapMemory vkUnmapMemory = (PFN_vkUnmapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUnmapMemory");
				if (vkUnmapMemory) vkUnmapMemory (device, memory);
				mappedVulkanMemory.erase (mapped);

			}

			vkFreeMemory (device, memory, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	bool lime_vk_upload_memory (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int memoryHigh, int memoryLow,
		int offsetHigh, int offsetLow, value bytes, int byteOffset, int byteLength) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		uint64_t offset = CombineVulkanHandle (offsetHigh, offsetLow);
		Bytes data (bytes);
		if (!memory || !data.b || byteOffset < 0 || byteLength < 0 || byteOffset + byteLength > data.length) {

			lastVKError = "Invalid Vulkan memory upload range";
			return false;

		}

		PFN_vkMapMemory vkMapMemory = (PFN_vkMapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkMapMemory");
		PFN_vkUnmapMemory vkUnmapMemory = (PFN_vkUnmapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUnmapMemory");
		if (!vkMapMemory || !vkUnmapMemory) return false;

		void* mappedData = 0;
		VkResult result = vkMapMemory (device, memory, (VkDeviceSize)offset, (VkDeviceSize)byteLength, 0, &mappedData);
		if (result != VK_SUCCESS || !mappedData) {

			lastVKError = "vkMapMemory failed";
			return false;

		}

		memcpy (mappedData, data.b + byteOffset, byteLength);
		vkUnmapMemory (device, memory);
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_upload_memory) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int memoryHigh, int memoryLow, int offsetHigh, int offsetLow, Bytes* bytes, int byteOffset, int byteLength) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		uint64_t offset = CombineVulkanHandle (offsetHigh, offsetLow);
		if (!memory || !bytes || !bytes->b || byteOffset < 0 || byteLength < 0 || byteOffset + byteLength > bytes->length) {

			lastVKError = "Invalid Vulkan memory upload range";
			return false;

		}

		PFN_vkMapMemory vkMapMemory = (PFN_vkMapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkMapMemory");
		PFN_vkUnmapMemory vkUnmapMemory = (PFN_vkUnmapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUnmapMemory");
		if (!vkMapMemory || !vkUnmapMemory) return false;

		void* mappedData = 0;
		VkResult result = vkMapMemory (device, memory, (VkDeviceSize)offset, (VkDeviceSize)byteLength, 0, &mappedData);
		if (result != VK_SUCCESS || !mappedData) {

			lastVKError = "vkMapMemory failed";
			return false;

		}

		memcpy (mappedData, bytes->b + byteOffset, byteLength);
		vkUnmapMemory (device, memory);
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_download_memory (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int memoryHigh, int memoryLow,
		int offsetHigh, int offsetLow, value bytes, int byteOffset, int byteLength) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		uint64_t offset = CombineVulkanHandle (offsetHigh, offsetLow);
		Bytes data (bytes);
		if (!memory || !data.b || byteOffset < 0 || byteLength < 0 || byteOffset + byteLength > data.length) {

			lastVKError = "Invalid Vulkan memory download range";
			return false;

		}

		PFN_vkMapMemory vkMapMemory = (PFN_vkMapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkMapMemory");
		PFN_vkUnmapMemory vkUnmapMemory = (PFN_vkUnmapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUnmapMemory");
		if (!vkMapMemory || !vkUnmapMemory) return false;

		void* mappedData = 0;
		VkResult result = vkMapMemory (device, memory, (VkDeviceSize)offset, (VkDeviceSize)byteLength, 0, &mappedData);
		if (result != VK_SUCCESS || !mappedData) {

			lastVKError = "vkMapMemory failed";
			return false;

		}

		memcpy (data.b + byteOffset, mappedData, byteLength);
		vkUnmapMemory (device, memory);
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_download_memory) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int memoryHigh, int memoryLow, int offsetHigh, int offsetLow, Bytes* bytes, int byteOffset, int byteLength) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		uint64_t offset = CombineVulkanHandle (offsetHigh, offsetLow);
		if (!memory || !bytes || !bytes->b || byteOffset < 0 || byteLength < 0 || byteOffset + byteLength > bytes->length) {

			lastVKError = "Invalid Vulkan memory download range";
			return false;

		}

		PFN_vkMapMemory vkMapMemory = (PFN_vkMapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkMapMemory");
		PFN_vkUnmapMemory vkUnmapMemory = (PFN_vkUnmapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUnmapMemory");
		if (!vkMapMemory || !vkUnmapMemory) return false;

		void* mappedData = 0;
		VkResult result = vkMapMemory (device, memory, (VkDeviceSize)offset, (VkDeviceSize)byteLength, 0, &mappedData);
		if (result != VK_SUCCESS || !mappedData) {

			lastVKError = "vkMapMemory failed";
			return false;

		}

		memcpy (bytes->b + byteOffset, mappedData, byteLength);
		vkUnmapMemory (device, memory);
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_map_memory (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int memoryHigh, int memoryLow,
		int offsetHigh, int offsetLow, int sizeHigh, int sizeLow, int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		VkDeviceSize offset = (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow);
		VkDeviceSize size = NormalizeVulkanRangeSize (CombineVulkanHandle (sizeHigh, sizeLow));
		if (!memory) return false;

		uint64_t mapKey = GetManagedVulkanMappedMemoryKey (memory);
		if (mappedVulkanMemory.find (mapKey) != mappedVulkanMemory.end ()) {

			lastVKError.clear ();
			return true;

		}

		PFN_vkMapMemory vkMapMemory = (PFN_vkMapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkMapMemory");
		if (!vkMapMemory) return false;

		void* mappedData = 0;
		VkResult result = vkMapMemory (device, memory, offset, size, (VkMemoryMapFlags)flags, &mappedData);
		if (result != VK_SUCCESS || !mappedData) {

			lastVKError = "vkMapMemory failed";
			return false;

		}

		ManagedVulkanMappedMemory mapped;
		mapped.device = device;
		mapped.memory = memory;
		mapped.offset = offset;
		mapped.size = size;
		mapped.data = mappedData;
		mappedVulkanMemory[mapKey] = mapped;
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_map_memory) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int memoryHigh, int memoryLow, int offsetHigh, int offsetLow, int sizeHigh, int sizeLow, int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		VkDeviceSize offset = (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow);
		VkDeviceSize size = NormalizeVulkanRangeSize (CombineVulkanHandle (sizeHigh, sizeLow));
		if (!memory) return false;

		uint64_t mapKey = GetManagedVulkanMappedMemoryKey (memory);
		if (mappedVulkanMemory.find (mapKey) != mappedVulkanMemory.end ()) {

			lastVKError.clear ();
			return true;

		}

		PFN_vkMapMemory vkMapMemory = (PFN_vkMapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkMapMemory");
		if (!vkMapMemory) return false;

		void* mappedData = 0;
		VkResult result = vkMapMemory (device, memory, offset, size, (VkMemoryMapFlags)flags, &mappedData);
		if (result != VK_SUCCESS || !mappedData) {

			lastVKError = "vkMapMemory failed";
			return false;

		}

		ManagedVulkanMappedMemory mapped;
		mapped.device = device;
		mapped.memory = memory;
		mapped.offset = offset;
		mapped.size = size;
		mapped.data = mappedData;
		mappedVulkanMemory[mapKey] = mapped;
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	void lime_vk_unmap_memory (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int memoryHigh, int memoryLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		uint64_t mapKey = GetManagedVulkanMappedMemoryKey (memory);
		std::unordered_map<uint64_t, ManagedVulkanMappedMemory>::iterator mapped = mappedVulkanMemory.find (mapKey);
		if (mapped == mappedVulkanMemory.end ()) return;

		PFN_vkUnmapMemory vkUnmapMemory = (PFN_vkUnmapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUnmapMemory");
		if (!vkUnmapMemory) return;

		vkUnmapMemory (device, memory);
		mappedVulkanMemory.erase (mapped);
		lastVKError.clear ();
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_unmap_memory) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int memoryHigh, int memoryLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		uint64_t mapKey = GetManagedVulkanMappedMemoryKey (memory);
		std::unordered_map<uint64_t, ManagedVulkanMappedMemory>::iterator mapped = mappedVulkanMemory.find (mapKey);
		if (mapped == mappedVulkanMemory.end ()) return;

		PFN_vkUnmapMemory vkUnmapMemory = (PFN_vkUnmapMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUnmapMemory");
		if (!vkUnmapMemory) return;

		vkUnmapMemory (device, memory);
		mappedVulkanMemory.erase (mapped);
		lastVKError.clear ();
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	bool lime_vk_write_mapped_memory (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int memoryHigh, int memoryLow,
		int offsetHigh, int offsetLow, value bytes, int byteOffset, int byteLength) {

#ifdef LIME_VULKAN
		Bytes data (bytes);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		uint64_t offset = CombineVulkanHandle (offsetHigh, offsetLow);
		if (!memory || !data.b || byteOffset < 0 || byteLength < 0 || byteOffset + byteLength > data.length) {

			lastVKError = "Invalid mapped Vulkan memory write range";
			return false;

		}

		std::unordered_map<uint64_t, ManagedVulkanMappedMemory>::iterator mapped = mappedVulkanMemory.find (GetManagedVulkanMappedMemoryKey (memory));
		if (mapped == mappedVulkanMemory.end ()) {

			lastVKError = "Vulkan memory is not mapped";
			return false;

		}

		if (offset < mapped->second.offset) {

			lastVKError = "Mapped Vulkan memory write offset is outside the mapped range";
			return false;

		}

		uint64_t relativeOffset = offset - mapped->second.offset;
		if (mapped->second.size != VK_WHOLE_SIZE && relativeOffset + (uint64_t)byteLength > (uint64_t)mapped->second.size) {

			lastVKError = "Mapped Vulkan memory write exceeds the mapped range";
			return false;

		}

		memcpy ((unsigned char*)mapped->second.data + relativeOffset, data.b + byteOffset, byteLength);
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_write_mapped_memory) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int memoryHigh, int memoryLow, int offsetHigh, int offsetLow, Bytes* bytes, int byteOffset, int byteLength) {

#ifdef LIME_VULKAN
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		uint64_t offset = CombineVulkanHandle (offsetHigh, offsetLow);
		if (!memory || !bytes || !bytes->b || byteOffset < 0 || byteLength < 0 || byteOffset + byteLength > bytes->length) {

			lastVKError = "Invalid mapped Vulkan memory write range";
			return false;

		}

		std::unordered_map<uint64_t, ManagedVulkanMappedMemory>::iterator mapped = mappedVulkanMemory.find (GetManagedVulkanMappedMemoryKey (memory));
		if (mapped == mappedVulkanMemory.end ()) {

			lastVKError = "Vulkan memory is not mapped";
			return false;

		}

		if (offset < mapped->second.offset) {

			lastVKError = "Mapped Vulkan memory write offset is outside the mapped range";
			return false;

		}

		uint64_t relativeOffset = offset - mapped->second.offset;
		if (mapped->second.size != VK_WHOLE_SIZE && relativeOffset + (uint64_t)byteLength > (uint64_t)mapped->second.size) {

			lastVKError = "Mapped Vulkan memory write exceeds the mapped range";
			return false;

		}

		memcpy ((unsigned char*)mapped->second.data + relativeOffset, bytes->b + byteOffset, byteLength);
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_flush_mapped_memory (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int memoryHigh,
		int memoryLow, int offsetHigh, int offsetLow, int sizeHigh, int sizeLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		PFN_vkFlushMappedMemoryRanges vkFlushMappedMemoryRanges =
			(PFN_vkFlushMappedMemoryRanges)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkFlushMappedMemoryRanges");
		if (!vkFlushMappedMemoryRanges || !memory) return false;

		VkMappedMemoryRange range;
		memset (&range, 0, sizeof (range));
		range.sType = VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
		range.memory = memory;
		range.offset = (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow);
		range.size = NormalizeVulkanRangeSize (CombineVulkanHandle (sizeHigh, sizeLow));
		VkResult result = vkFlushMappedMemoryRanges (device, 1, &range);
		if (result != VK_SUCCESS) {

			lastVKError = "vkFlushMappedMemoryRanges failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_flush_mapped_memory) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int memoryHigh, int memoryLow, int offsetHigh, int offsetLow, int sizeHigh, int sizeLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		PFN_vkFlushMappedMemoryRanges vkFlushMappedMemoryRanges =
			(PFN_vkFlushMappedMemoryRanges)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkFlushMappedMemoryRanges");
		if (!vkFlushMappedMemoryRanges || !memory) return false;

		VkMappedMemoryRange range;
		memset (&range, 0, sizeof (range));
		range.sType = VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
		range.memory = memory;
		range.offset = (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow);
		range.size = NormalizeVulkanRangeSize (CombineVulkanHandle (sizeHigh, sizeLow));
		VkResult result = vkFlushMappedMemoryRanges (device, 1, &range);
		if (result != VK_SUCCESS) {

			lastVKError = "vkFlushMappedMemoryRanges failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_invalidate_mapped_memory (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int memoryHigh,
		int memoryLow, int offsetHigh, int offsetLow, int sizeHigh, int sizeLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		PFN_vkInvalidateMappedMemoryRanges vkInvalidateMappedMemoryRanges =
			(PFN_vkInvalidateMappedMemoryRanges)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkInvalidateMappedMemoryRanges");
		if (!vkInvalidateMappedMemoryRanges || !memory) return false;

		VkMappedMemoryRange range;
		memset (&range, 0, sizeof (range));
		range.sType = VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
		range.memory = memory;
		range.offset = (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow);
		range.size = NormalizeVulkanRangeSize (CombineVulkanHandle (sizeHigh, sizeLow));
		VkResult result = vkInvalidateMappedMemoryRanges (device, 1, &range);
		if (result != VK_SUCCESS) {

			lastVKError = "vkInvalidateMappedMemoryRanges failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_invalidate_mapped_memory) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int memoryHigh, int memoryLow, int offsetHigh, int offsetLow, int sizeHigh, int sizeLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		PFN_vkInvalidateMappedMemoryRanges vkInvalidateMappedMemoryRanges =
			(PFN_vkInvalidateMappedMemoryRanges)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkInvalidateMappedMemoryRanges");
		if (!vkInvalidateMappedMemoryRanges || !memory) return false;

		VkMappedMemoryRange range;
		memset (&range, 0, sizeof (range));
		range.sType = VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
		range.memory = memory;
		range.offset = (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow);
		range.size = NormalizeVulkanRangeSize (CombineVulkanHandle (sizeHigh, sizeLow));
		VkResult result = vkInvalidateMappedMemoryRanges (device, 1, &range);
		if (result != VK_SUCCESS) {

			lastVKError = "vkInvalidateMappedMemoryRanges failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	value lime_vk_create_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int sizeHigh, int sizeLow, int usage) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateBuffer vkCreateBuffer = (PFN_vkCreateBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateBuffer");
		if (!vkCreateBuffer) return alloc_null ();

		VkBufferCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
		createInfo.size = (VkDeviceSize)CombineVulkanHandle (sizeHigh, sizeLow);
		createInfo.usage = (VkBufferUsageFlags)usage;
		createInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

		VkBuffer buffer = VK_NULL_HANDLE;
		VkResult result = vkCreateBuffer (device, &createInfo, 0, &buffer);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateBuffer failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)buffer);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int sizeHigh, int sizeLow, int usage) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateBuffer vkCreateBuffer = (PFN_vkCreateBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateBuffer");
		if (!vkCreateBuffer) return 0;

		VkBufferCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
		createInfo.size = (VkDeviceSize)CombineVulkanHandle (sizeHigh, sizeLow);
		createInfo.usage = (VkBufferUsageFlags)usage;
		createInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

		VkBuffer buffer = VK_NULL_HANDLE;
		VkResult result = vkCreateBuffer (device, &createInfo, 0, &buffer);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateBuffer failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)buffer);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int bufferHigh, int bufferLow) {

#ifdef LIME_VULKAN
		if (bufferHigh == 0 && bufferLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		PFN_vkDestroyBuffer vkDestroyBuffer = (PFN_vkDestroyBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyBuffer");
		if (vkDestroyBuffer) {

			vkDestroyBuffer (device, buffer, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int bufferHigh, int bufferLow) {

#ifdef LIME_VULKAN
		if (bufferHigh == 0 && bufferLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		PFN_vkDestroyBuffer vkDestroyBuffer = (PFN_vkDestroyBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyBuffer");
		if (vkDestroyBuffer) {

			vkDestroyBuffer (device, buffer, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	value lime_vk_get_buffer_memory_requirements (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int bufferHigh,
		int bufferLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		PFN_vkGetBufferMemoryRequirements vkGetBufferMemoryRequirements =
			(PFN_vkGetBufferMemoryRequirements)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkGetBufferMemoryRequirements");
		if (!vkGetBufferMemoryRequirements || !buffer) return alloc_null ();

		VkMemoryRequirements requirements;
		memset (&requirements, 0, sizeof (requirements));
		vkGetBufferMemoryRequirements (device, buffer, &requirements);
		lastVKError.clear ();
		return CreateVulkanMemoryRequirementsValue (requirements);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_get_buffer_memory_requirements) (HL_CFFIPointer* window, int instanceHigh, int instanceLow,
		int deviceHigh, int deviceLow, int bufferHigh, int bufferLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		PFN_vkGetBufferMemoryRequirements vkGetBufferMemoryRequirements =
			(PFN_vkGetBufferMemoryRequirements)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkGetBufferMemoryRequirements");
		if (!vkGetBufferMemoryRequirements || !buffer) return 0;

		VkMemoryRequirements requirements;
		memset (&requirements, 0, sizeof (requirements));
		vkGetBufferMemoryRequirements (device, buffer, &requirements);
		lastVKError.clear ();
		return HLCreateVulkanMemoryRequirementsValue (requirements);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	bool lime_vk_bind_buffer_memory (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int bufferHigh, int bufferLow,
		int memoryHigh, int memoryLow, int offsetHigh, int offsetLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		PFN_vkBindBufferMemory vkBindBufferMemory = (PFN_vkBindBufferMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkBindBufferMemory");
		if (!vkBindBufferMemory || !buffer || !memory) return false;

		VkResult result = vkBindBufferMemory (device, buffer, memory, (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow));
		if (result != VK_SUCCESS) {

			lastVKError = "vkBindBufferMemory failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_bind_buffer_memory) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int bufferHigh, int bufferLow, int memoryHigh, int memoryLow, int offsetHigh, int offsetLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		PFN_vkBindBufferMemory vkBindBufferMemory = (PFN_vkBindBufferMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkBindBufferMemory");
		if (!vkBindBufferMemory || !buffer || !memory) return false;

		VkResult result = vkBindBufferMemory (device, buffer, memory, (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow));
		if (result != VK_SUCCESS) {

			lastVKError = "vkBindBufferMemory failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	value lime_vk_create_image (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int width, int height, int depth,
		int mipLevels, int arrayLayers, int format, int imageType, int tiling, int usage, int samples) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateImage vkCreateImage = (PFN_vkCreateImage)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateImage");
		if (!vkCreateImage) return alloc_null ();

		VkImageCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
		createInfo.imageType = (VkImageType)imageType;
		createInfo.format = (VkFormat)format;
		createInfo.extent.width = (uint32_t)width;
		createInfo.extent.height = (uint32_t)height;
		createInfo.extent.depth = (uint32_t)depth;
		createInfo.mipLevels = (uint32_t)mipLevels;
		createInfo.arrayLayers = (uint32_t)arrayLayers;
		createInfo.samples = (VkSampleCountFlagBits)samples;
		createInfo.tiling = (VkImageTiling)tiling;
		createInfo.usage = (VkImageUsageFlags)usage;
		createInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
		createInfo.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
		if ((VkImageViewType)imageType == VK_IMAGE_VIEW_TYPE_CUBE || arrayLayers == 6) {

			createInfo.flags |= VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT;

		}

		VkImage image = VK_NULL_HANDLE;
		VkResult result = vkCreateImage (device, &createInfo, 0, &image);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateImage failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)image);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_image) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int width, int height, int depth, int mipLevels, int arrayLayers, int format, int imageType, int tiling, int usage, int samples) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateImage vkCreateImage = (PFN_vkCreateImage)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateImage");
		if (!vkCreateImage) return 0;

		VkImageCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
		createInfo.imageType = (VkImageType)imageType;
		createInfo.format = (VkFormat)format;
		createInfo.extent.width = (uint32_t)width;
		createInfo.extent.height = (uint32_t)height;
		createInfo.extent.depth = (uint32_t)depth;
		createInfo.mipLevels = (uint32_t)mipLevels;
		createInfo.arrayLayers = (uint32_t)arrayLayers;
		createInfo.samples = (VkSampleCountFlagBits)samples;
		createInfo.tiling = (VkImageTiling)tiling;
		createInfo.usage = (VkImageUsageFlags)usage;
		createInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
		createInfo.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
		if ((VkImageViewType)imageType == VK_IMAGE_VIEW_TYPE_CUBE || arrayLayers == 6) {

			createInfo.flags |= VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT;

		}

		VkImage image = VK_NULL_HANDLE;
		VkResult result = vkCreateImage (device, &createInfo, 0, &image);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateImage failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)image);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_image (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int imageHigh, int imageLow) {

#ifdef LIME_VULKAN
		if (imageHigh == 0 && imageLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkImage image = (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow);
		PFN_vkDestroyImage vkDestroyImage = (PFN_vkDestroyImage)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyImage");
		if (vkDestroyImage) {

			vkDestroyImage (device, image, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_image) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int imageHigh, int imageLow) {

#ifdef LIME_VULKAN
		if (imageHigh == 0 && imageLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkImage image = (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow);
		PFN_vkDestroyImage vkDestroyImage = (PFN_vkDestroyImage)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyImage");
		if (vkDestroyImage) {

			vkDestroyImage (device, image, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	value lime_vk_get_image_memory_requirements (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int imageHigh,
		int imageLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkImage image = (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow);
		PFN_vkGetImageMemoryRequirements vkGetImageMemoryRequirements =
			(PFN_vkGetImageMemoryRequirements)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkGetImageMemoryRequirements");
		if (!vkGetImageMemoryRequirements || !image) return alloc_null ();

		VkMemoryRequirements requirements;
		memset (&requirements, 0, sizeof (requirements));
		vkGetImageMemoryRequirements (device, image, &requirements);
		lastVKError.clear ();
		return CreateVulkanMemoryRequirementsValue (requirements);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_get_image_memory_requirements) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int imageHigh, int imageLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkImage image = (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow);
		PFN_vkGetImageMemoryRequirements vkGetImageMemoryRequirements =
			(PFN_vkGetImageMemoryRequirements)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkGetImageMemoryRequirements");
		if (!vkGetImageMemoryRequirements || !image) return 0;

		VkMemoryRequirements requirements;
		memset (&requirements, 0, sizeof (requirements));
		vkGetImageMemoryRequirements (device, image, &requirements);
		lastVKError.clear ();
		return HLCreateVulkanMemoryRequirementsValue (requirements);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	bool lime_vk_bind_image_memory (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int imageHigh, int imageLow,
		int memoryHigh, int memoryLow, int offsetHigh, int offsetLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkImage image = (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		PFN_vkBindImageMemory vkBindImageMemory = (PFN_vkBindImageMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkBindImageMemory");
		if (!vkBindImageMemory || !image || !memory) return false;

		VkResult result = vkBindImageMemory (device, image, memory, (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow));
		if (result != VK_SUCCESS) {

			lastVKError = "vkBindImageMemory failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_bind_image_memory) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int imageHigh, int imageLow, int memoryHigh, int memoryLow, int offsetHigh, int offsetLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkImage image = (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow);
		VkDeviceMemory memory = (VkDeviceMemory)(uintptr_t)CombineVulkanHandle (memoryHigh, memoryLow);
		PFN_vkBindImageMemory vkBindImageMemory = (PFN_vkBindImageMemory)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkBindImageMemory");
		if (!vkBindImageMemory || !image || !memory) return false;

		VkResult result = vkBindImageMemory (device, image, memory, (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow));
		if (result != VK_SUCCESS) {

			lastVKError = "vkBindImageMemory failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	value lime_vk_create_swapchain (value window, int instanceHigh, int instanceLow, int physicalDeviceHigh, int physicalDeviceLow, int deviceHigh,
		int deviceLow, int surfaceHigh, int surfaceLow, int queueFamilyIndex, int width, int height, int presentMode, int oldSwapchainHigh,
		int oldSwapchainLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkPhysicalDevice physicalDevice = (VkPhysicalDevice)(uintptr_t)CombineVulkanHandle (physicalDeviceHigh, physicalDeviceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkSurfaceKHR surface = UInt64ToVulkanSurface (CombineVulkanHandle (surfaceHigh, surfaceLow));
		VkSwapchainKHR oldSwapchain = (VkSwapchainKHR)(uintptr_t)CombineVulkanHandle (oldSwapchainHigh, oldSwapchainLow);
		ManagedVulkanSwapchain swapchain;

		if (!CreateManagedVulkanSwapchain (targetWindow, instance, physicalDevice, device, surface, (uint32_t)queueFamilyIndex, width, height,
			(VkPresentModeKHR)presentMode, oldSwapchain, &swapchain)) {

			return alloc_null ();

		}

		return CreateVulkanSwapchainValue (swapchain);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_swapchain) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int physicalDeviceHigh,
		int physicalDeviceLow, int deviceHigh, int deviceLow, int surfaceHigh, int surfaceLow, int queueFamilyIndex, int width, int height,
		int presentMode, int oldSwapchainHigh, int oldSwapchainLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkPhysicalDevice physicalDevice = (VkPhysicalDevice)(uintptr_t)CombineVulkanHandle (physicalDeviceHigh, physicalDeviceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkSurfaceKHR surface = UInt64ToVulkanSurface (CombineVulkanHandle (surfaceHigh, surfaceLow));
		VkSwapchainKHR oldSwapchain = (VkSwapchainKHR)(uintptr_t)CombineVulkanHandle (oldSwapchainHigh, oldSwapchainLow);
		ManagedVulkanSwapchain swapchain;

		if (!CreateManagedVulkanSwapchain (targetWindow, instance, physicalDevice, device, surface, (uint32_t)queueFamilyIndex, width, height,
			(VkPresentModeKHR)presentMode, oldSwapchain, &swapchain)) {

			return 0;

		}

		return HLCreateVulkanSwapchainValue (swapchain);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_swapchain (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int swapchainHigh, int swapchainLow) {

#ifdef LIME_VULKAN
		if (swapchainHigh == 0 && swapchainLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkSwapchainKHR swapchain = (VkSwapchainKHR)(uintptr_t)CombineVulkanHandle (swapchainHigh, swapchainLow);
		PFN_vkDestroySwapchainKHR vkDestroySwapchainKHR = (PFN_vkDestroySwapchainKHR)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroySwapchainKHR");
		if (vkDestroySwapchainKHR) {

			vkDestroySwapchainKHR (device, swapchain, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_swapchain) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int swapchainHigh, int swapchainLow) {

#ifdef LIME_VULKAN
		if (swapchainHigh == 0 && swapchainLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkSwapchainKHR swapchain = (VkSwapchainKHR)(uintptr_t)CombineVulkanHandle (swapchainHigh, swapchainLow);
		PFN_vkDestroySwapchainKHR vkDestroySwapchainKHR = (PFN_vkDestroySwapchainKHR)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroySwapchainKHR");
		if (vkDestroySwapchainKHR) {

			vkDestroySwapchainKHR (device, swapchain, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	value lime_vk_get_swapchain_images (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int swapchainHigh,
		int swapchainLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkSwapchainKHR swapchain = (VkSwapchainKHR)(uintptr_t)CombineVulkanHandle (swapchainHigh, swapchainLow);
		PFN_vkGetSwapchainImagesKHR vkGetSwapchainImagesKHR = (PFN_vkGetSwapchainImagesKHR)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkGetSwapchainImagesKHR");
		if (!vkGetSwapchainImagesKHR || !swapchain) return alloc_null ();

		uint32_t imageCount = 0;
		VkResult result = vkGetSwapchainImagesKHR (device, swapchain, &imageCount, 0);
		if (result != VK_SUCCESS) {

			lastVKError = "Failed to query Vulkan swapchain image count";
			return alloc_null ();

		}

		value images = alloc_array (imageCount);
		if (imageCount == 0) {

			lastVKError.clear ();
			return images;

		}

		std::vector<VkImage> swapchainImages (imageCount);
		result = vkGetSwapchainImagesKHR (device, swapchain, &imageCount, swapchainImages.data ());
		if (result != VK_SUCCESS) {

			lastVKError = "vkGetSwapchainImagesKHR failed";
			return alloc_null ();

		}

		for (uint32_t i = 0; i < imageCount; ++i) {

			val_array_set_i (images, i, CreateVulkanHandleValue ((uint64_t)(uintptr_t)swapchainImages[i]));

		}

		lastVKError.clear ();
		return images;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_array (0);
#endif

	}


	HL_PRIM hl_varray* HL_NAME(hl_vk_get_swapchain_images) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int swapchainHigh, int swapchainLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkSwapchainKHR swapchain = (VkSwapchainKHR)(uintptr_t)CombineVulkanHandle (swapchainHigh, swapchainLow);
		PFN_vkGetSwapchainImagesKHR vkGetSwapchainImagesKHR = (PFN_vkGetSwapchainImagesKHR)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkGetSwapchainImagesKHR");
		if (!vkGetSwapchainImagesKHR || !swapchain) return 0;

		uint32_t imageCount = 0;
		VkResult result = vkGetSwapchainImagesKHR (device, swapchain, &imageCount, 0);
		if (result != VK_SUCCESS) {

			lastVKError = "Failed to query Vulkan swapchain image count";
			return 0;

		}

		hl_varray* images = (hl_varray*)hl_alloc_array (&hlt_dynobj, imageCount);
		if (imageCount == 0) {

			lastVKError.clear ();
			return images;

		}

		std::vector<VkImage> swapchainImages (imageCount);
		result = vkGetSwapchainImagesKHR (device, swapchain, &imageCount, swapchainImages.data ());
		if (result != VK_SUCCESS) {

			lastVKError = "vkGetSwapchainImagesKHR failed";
			return 0;

		}

		vdynamic** imageData = hl_aptr (images, vdynamic*);
		for (uint32_t i = 0; i < imageCount; ++i) {

			*imageData++ = HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)swapchainImages[i]);

		}

		lastVKError.clear ();
		return images;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return (hl_varray*)hl_alloc_array (&hlt_dynobj, 0);
#endif

	}


	value lime_vk_acquire_next_image (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int swapchainHigh,
		int swapchainLow, int timeoutHigh, int timeoutLow, int semaphoreHigh, int semaphoreLow, int fenceHigh, int fenceLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkSwapchainKHR swapchain = (VkSwapchainKHR)(uintptr_t)CombineVulkanHandle (swapchainHigh, swapchainLow);
		uint64_t timeout = CombineVulkanHandle (timeoutHigh, timeoutLow);
		VkSemaphore semaphore = (VkSemaphore)(uintptr_t)CombineVulkanHandle (semaphoreHigh, semaphoreLow);
		VkFence fence = (VkFence)(uintptr_t)CombineVulkanHandle (fenceHigh, fenceLow);
		if (!semaphore && !fence) {

			lastVKError = "Vulkan image acquisition requires a semaphore or fence";
			return CreateVulkanAcquireValue (VK_ERROR_INITIALIZATION_FAILED, -1);

		}

		PFN_vkAcquireNextImageKHR vkAcquireNextImageKHR = (PFN_vkAcquireNextImageKHR)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkAcquireNextImageKHR");
		if (!vkAcquireNextImageKHR || !swapchain) return CreateVulkanAcquireValue (VK_ERROR_INITIALIZATION_FAILED, -1);

		uint32_t imageIndex = 0;
		VkResult result = vkAcquireNextImageKHR (device, swapchain, timeout, semaphore, fence, &imageIndex);
		if (result == VK_SUCCESS || result == VK_SUBOPTIMAL_KHR) {

			lastVKError.clear ();
			return CreateVulkanAcquireValue (result, (int)imageIndex);

		}

		lastVKError = "vkAcquireNextImageKHR failed";
		return CreateVulkanAcquireValue (result, -1);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_acquire_next_image) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int swapchainHigh, int swapchainLow, int timeoutHigh, int timeoutLow, int semaphoreHigh, int semaphoreLow, int fenceHigh, int fenceLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkSwapchainKHR swapchain = (VkSwapchainKHR)(uintptr_t)CombineVulkanHandle (swapchainHigh, swapchainLow);
		uint64_t timeout = CombineVulkanHandle (timeoutHigh, timeoutLow);
		VkSemaphore semaphore = (VkSemaphore)(uintptr_t)CombineVulkanHandle (semaphoreHigh, semaphoreLow);
		VkFence fence = (VkFence)(uintptr_t)CombineVulkanHandle (fenceHigh, fenceLow);
		if (!semaphore && !fence) {

			lastVKError = "Vulkan image acquisition requires a semaphore or fence";
			return HLCreateVulkanAcquireValue (VK_ERROR_INITIALIZATION_FAILED, -1);

		}

		PFN_vkAcquireNextImageKHR vkAcquireNextImageKHR = (PFN_vkAcquireNextImageKHR)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkAcquireNextImageKHR");
		if (!vkAcquireNextImageKHR || !swapchain) return HLCreateVulkanAcquireValue (VK_ERROR_INITIALIZATION_FAILED, -1);

		uint32_t imageIndex = 0;
		VkResult result = vkAcquireNextImageKHR (device, swapchain, timeout, semaphore, fence, &imageIndex);
		if (result == VK_SUCCESS || result == VK_SUBOPTIMAL_KHR) {

			lastVKError.clear ();
			return HLCreateVulkanAcquireValue (result, (int)imageIndex);

		}

		lastVKError = "vkAcquireNextImageKHR failed";
		return HLCreateVulkanAcquireValue (result, -1);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	int lime_vk_queue_present (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int queueHigh, int queueLow,
		int swapchainHigh, int swapchainLow, int imageIndex, int waitSemaphoreHigh, int waitSemaphoreLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkQueue queue = (VkQueue)(uintptr_t)CombineVulkanHandle (queueHigh, queueLow);
		VkSwapchainKHR swapchain = (VkSwapchainKHR)(uintptr_t)CombineVulkanHandle (swapchainHigh, swapchainLow);
		VkSemaphore waitSemaphore = (VkSemaphore)(uintptr_t)CombineVulkanHandle (waitSemaphoreHigh, waitSemaphoreLow);
		PFN_vkQueuePresentKHR vkQueuePresentKHR = (PFN_vkQueuePresentKHR)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkQueuePresentKHR");
		if (!vkQueuePresentKHR || !queue || !swapchain) return VK_ERROR_INITIALIZATION_FAILED;

		VkPresentInfoKHR presentInfo;
		memset (&presentInfo, 0, sizeof (presentInfo));
		presentInfo.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
		presentInfo.waitSemaphoreCount = waitSemaphore ? 1 : 0;
		presentInfo.pWaitSemaphores = waitSemaphore ? &waitSemaphore : 0;
		presentInfo.swapchainCount = 1;
		presentInfo.pSwapchains = &swapchain;
		uint32_t swapchainImageIndex = (uint32_t)imageIndex;
		presentInfo.pImageIndices = &swapchainImageIndex;

		VkResult result = vkQueuePresentKHR (queue, &presentInfo);
		if (result == VK_SUCCESS || result == VK_SUBOPTIMAL_KHR) {

			lastVKError.clear ();

		} else {

			lastVKError = "vkQueuePresentKHR failed";

		}

		return (int)result;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return -3;
#endif

	}


	HL_PRIM int HL_NAME(hl_vk_queue_present) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int queueHigh,
		int queueLow, int swapchainHigh, int swapchainLow, int imageIndex, int waitSemaphoreHigh, int waitSemaphoreLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkQueue queue = (VkQueue)(uintptr_t)CombineVulkanHandle (queueHigh, queueLow);
		VkSwapchainKHR swapchain = (VkSwapchainKHR)(uintptr_t)CombineVulkanHandle (swapchainHigh, swapchainLow);
		VkSemaphore waitSemaphore = (VkSemaphore)(uintptr_t)CombineVulkanHandle (waitSemaphoreHigh, waitSemaphoreLow);
		PFN_vkQueuePresentKHR vkQueuePresentKHR = (PFN_vkQueuePresentKHR)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkQueuePresentKHR");
		if (!vkQueuePresentKHR || !queue || !swapchain) return VK_ERROR_INITIALIZATION_FAILED;

		VkPresentInfoKHR presentInfo;
		memset (&presentInfo, 0, sizeof (presentInfo));
		presentInfo.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
		presentInfo.waitSemaphoreCount = waitSemaphore ? 1 : 0;
		presentInfo.pWaitSemaphores = waitSemaphore ? &waitSemaphore : 0;
		presentInfo.swapchainCount = 1;
		presentInfo.pSwapchains = &swapchain;
		uint32_t swapchainImageIndex = (uint32_t)imageIndex;
		presentInfo.pImageIndices = &swapchainImageIndex;

		VkResult result = vkQueuePresentKHR (queue, &presentInfo);
		if (result == VK_SUCCESS || result == VK_SUBOPTIMAL_KHR) {

			lastVKError.clear ();

		} else {

			lastVKError = "vkQueuePresentKHR failed";

		}

		return (int)result;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return -3;
#endif

	}


	value lime_vk_create_image_view (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int imageHigh, int imageLow,
		int format, int aspectMask, int viewType) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkImage image = (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow);
		if (!image || format == VK_FORMAT_UNDEFINED) {

			lastVKError = "Missing Vulkan image or image view format";
			return alloc_null ();

		}

		PFN_vkCreateImageView vkCreateImageView = (PFN_vkCreateImageView)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateImageView");
		if (!vkCreateImageView) return alloc_null ();

		VkImageViewCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		createInfo.image = image;
		createInfo.viewType = (VkImageViewType)viewType;
		createInfo.format = (VkFormat)format;
		createInfo.subresourceRange.aspectMask = (VkImageAspectFlags)aspectMask;
		createInfo.subresourceRange.baseMipLevel = 0;
		createInfo.subresourceRange.levelCount = 1;
		createInfo.subresourceRange.baseArrayLayer = 0;
		createInfo.subresourceRange.layerCount = 1;

		VkImageView imageView = VK_NULL_HANDLE;
		VkResult result = vkCreateImageView (device, &createInfo, 0, &imageView);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateImageView failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)imageView);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_image_view) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int imageHigh, int imageLow, int format, int aspectMask, int viewType) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkImage image = (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow);
		if (!image || format == VK_FORMAT_UNDEFINED) {

			lastVKError = "Missing Vulkan image or image view format";
			return 0;

		}

		PFN_vkCreateImageView vkCreateImageView = (PFN_vkCreateImageView)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateImageView");
		if (!vkCreateImageView) return 0;

		VkImageViewCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		createInfo.image = image;
		createInfo.viewType = (VkImageViewType)viewType;
		createInfo.format = (VkFormat)format;
		createInfo.subresourceRange.aspectMask = (VkImageAspectFlags)aspectMask;
		createInfo.subresourceRange.baseMipLevel = 0;
		createInfo.subresourceRange.levelCount = 1;
		createInfo.subresourceRange.baseArrayLayer = 0;
		createInfo.subresourceRange.layerCount = 1;

		VkImageView imageView = VK_NULL_HANDLE;
		VkResult result = vkCreateImageView (device, &createInfo, 0, &imageView);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateImageView failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)imageView);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_image_view (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int imageViewHigh,
		int imageViewLow) {

#ifdef LIME_VULKAN
		if (imageViewHigh == 0 && imageViewLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkImageView imageView = (VkImageView)(uintptr_t)CombineVulkanHandle (imageViewHigh, imageViewLow);
		PFN_vkDestroyImageView vkDestroyImageView = (PFN_vkDestroyImageView)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroyImageView");
		if (vkDestroyImageView) {

			vkDestroyImageView (device, imageView, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_image_view) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int imageViewHigh, int imageViewLow) {

#ifdef LIME_VULKAN
		if (imageViewHigh == 0 && imageViewLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkImageView imageView = (VkImageView)(uintptr_t)CombineVulkanHandle (imageViewHigh, imageViewLow);
		PFN_vkDestroyImageView vkDestroyImageView = (PFN_vkDestroyImageView)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroyImageView");
		if (vkDestroyImageView) {

			vkDestroyImageView (device, imageView, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	value lime_vk_create_image_view_ex (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int imageHigh, int imageLow,
		int format, int aspectMask, int viewType, int baseMipLevel, int levelCount, int baseArrayLayer, int layerCount) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkImage image = (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow);
		if (!image || format == VK_FORMAT_UNDEFINED) {

			lastVKError = "Missing Vulkan image or image view format";
			return alloc_null ();

		}

		PFN_vkCreateImageView vkCreateImageView = (PFN_vkCreateImageView)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateImageView");
		if (!vkCreateImageView) return alloc_null ();

		VkImageViewCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		createInfo.image = image;
		createInfo.viewType = (VkImageViewType)viewType;
		createInfo.format = (VkFormat)format;
		createInfo.subresourceRange.aspectMask = (VkImageAspectFlags)aspectMask;
		createInfo.subresourceRange.baseMipLevel = (uint32_t)baseMipLevel;
		createInfo.subresourceRange.levelCount = (uint32_t)levelCount;
		createInfo.subresourceRange.baseArrayLayer = (uint32_t)baseArrayLayer;
		createInfo.subresourceRange.layerCount = (uint32_t)layerCount;

		VkImageView imageView = VK_NULL_HANDLE;
		VkResult result = vkCreateImageView (device, &createInfo, 0, &imageView);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateImageView failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)imageView);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_image_view_ex) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int imageHigh, int imageLow, int format, int aspectMask, int viewType, int baseMipLevel, int levelCount,
		int baseArrayLayer, int layerCount) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkImage image = (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow);
		if (!image || format == VK_FORMAT_UNDEFINED) {

			lastVKError = "Missing Vulkan image or image view format";
			return 0;

		}

		PFN_vkCreateImageView vkCreateImageView = (PFN_vkCreateImageView)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateImageView");
		if (!vkCreateImageView) return 0;

		VkImageViewCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		createInfo.image = image;
		createInfo.viewType = (VkImageViewType)viewType;
		createInfo.format = (VkFormat)format;
		createInfo.subresourceRange.aspectMask = (VkImageAspectFlags)aspectMask;
		createInfo.subresourceRange.baseMipLevel = (uint32_t)baseMipLevel;
		createInfo.subresourceRange.levelCount = (uint32_t)levelCount;
		createInfo.subresourceRange.baseArrayLayer = (uint32_t)baseArrayLayer;
		createInfo.subresourceRange.layerCount = (uint32_t)layerCount;

		VkImageView imageView = VK_NULL_HANDLE;
		VkResult result = vkCreateImageView (device, &createInfo, 0, &imageView);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateImageView failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)imageView);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	value lime_vk_create_render_pass (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, value state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateRenderPass vkCreateRenderPass = (PFN_vkCreateRenderPass)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCreateRenderPass");
		if (!vkCreateRenderPass) return alloc_null ();
		std::vector<int> packed = GetVulkanIntVector (state);
		if (packed.size () < 16) return alloc_null ();

		int colorFormat = packed[0];
		int depthStencilFormat = packed[1];
		int samples = packed[2];
		int colorLoadOp = packed[3];
		int colorStoreOp = packed[4];
		int colorInitialLayout = packed[5];
		int colorFinalLayout = packed[6];
		int depthInitialLayout = packed[7];
		int depthFinalLayout = packed[8];
		int depthLoadOp = packed[9];
		int depthStoreOp = packed[10];
		int resolveFormat = packed[11];
		int resolveLoadOp = packed[12];
		int resolveStoreOp = packed[13];
		int resolveInitialLayout = packed[14];
		int resolveFinalLayout = packed[15];

		std::vector<VkAttachmentDescription> attachments;
		VkAttachmentDescription colorAttachment;
		memset (&colorAttachment, 0, sizeof (colorAttachment));
		colorAttachment.format = (VkFormat)colorFormat;
		colorAttachment.samples = (VkSampleCountFlagBits)samples;
		colorAttachment.loadOp = (VkAttachmentLoadOp)colorLoadOp;
		colorAttachment.storeOp = (VkAttachmentStoreOp)colorStoreOp;
		colorAttachment.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
		colorAttachment.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
		colorAttachment.initialLayout = (VkImageLayout)colorInitialLayout;
		colorAttachment.finalLayout = (VkImageLayout)colorFinalLayout;
		attachments.push_back (colorAttachment);

		VkAttachmentReference colorReference;
		memset (&colorReference, 0, sizeof (colorReference));
		colorReference.attachment = 0;
		colorReference.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

		VkAttachmentReference depthReference;
		memset (&depthReference, 0, sizeof (depthReference));
		bool hasDepth = depthStencilFormat != VK_FORMAT_UNDEFINED;
		bool hasResolve = resolveFormat != VK_FORMAT_UNDEFINED;
		if (hasDepth) {

			VkAttachmentDescription depthAttachment;
			memset (&depthAttachment, 0, sizeof (depthAttachment));
			depthAttachment.format = (VkFormat)depthStencilFormat;
			depthAttachment.samples = (VkSampleCountFlagBits)samples;
			depthAttachment.loadOp = (VkAttachmentLoadOp)depthLoadOp;
			depthAttachment.storeOp = (VkAttachmentStoreOp)depthStoreOp;
			depthAttachment.stencilLoadOp = (VkAttachmentLoadOp)depthLoadOp;
			depthAttachment.stencilStoreOp = (VkAttachmentStoreOp)depthStoreOp;
			depthAttachment.initialLayout = (VkImageLayout)depthInitialLayout;
			depthAttachment.finalLayout = (VkImageLayout)depthFinalLayout;
			attachments.push_back (depthAttachment);
			depthReference.attachment = 1;
			depthReference.layout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

		}

		VkAttachmentReference resolveReference;
		memset (&resolveReference, 0, sizeof (resolveReference));
		if (hasResolve) {

			VkAttachmentDescription resolveAttachment;
			memset (&resolveAttachment, 0, sizeof (resolveAttachment));
			resolveAttachment.format = (VkFormat)resolveFormat;
			resolveAttachment.samples = VK_SAMPLE_COUNT_1_BIT;
			resolveAttachment.loadOp = (VkAttachmentLoadOp)resolveLoadOp;
			resolveAttachment.storeOp = (VkAttachmentStoreOp)resolveStoreOp;
			resolveAttachment.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
			resolveAttachment.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
			resolveAttachment.initialLayout = (VkImageLayout)resolveInitialLayout;
			resolveAttachment.finalLayout = (VkImageLayout)resolveFinalLayout;
			attachments.push_back (resolveAttachment);
			resolveReference.attachment = (uint32_t)(attachments.size () - 1);
			resolveReference.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

		}

		VkSubpassDescription subpass;
		memset (&subpass, 0, sizeof (subpass));
		subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
		subpass.colorAttachmentCount = 1;
		subpass.pColorAttachments = &colorReference;
		subpass.pResolveAttachments = hasResolve ? &resolveReference : 0;
		subpass.pDepthStencilAttachment = hasDepth ? &depthReference : 0;

		VkSubpassDependency dependency;
		memset (&dependency, 0, sizeof (dependency));
		dependency.srcSubpass = VK_SUBPASS_EXTERNAL;
		dependency.dstSubpass = 0;
		dependency.srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT;
		dependency.dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT;
		dependency.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;

		VkRenderPassCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
		createInfo.attachmentCount = (uint32_t)attachments.size ();
		createInfo.pAttachments = attachments.data ();
		createInfo.subpassCount = 1;
		createInfo.pSubpasses = &subpass;
		createInfo.dependencyCount = 1;
		createInfo.pDependencies = &dependency;

		VkRenderPass renderPass = VK_NULL_HANDLE;
		VkResult result = vkCreateRenderPass (device, &createInfo, 0, &renderPass);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateRenderPass failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)renderPass);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_render_pass) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, hl_varray* state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateRenderPass vkCreateRenderPass = (PFN_vkCreateRenderPass)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCreateRenderPass");
		if (!vkCreateRenderPass) return 0;
		std::vector<int> packed = GetHLVulkanIntVector (state);
		if (packed.size () < 16) return 0;

		int colorFormat = packed[0];
		int depthStencilFormat = packed[1];
		int samples = packed[2];
		int colorLoadOp = packed[3];
		int colorStoreOp = packed[4];
		int colorInitialLayout = packed[5];
		int colorFinalLayout = packed[6];
		int depthInitialLayout = packed[7];
		int depthFinalLayout = packed[8];
		int depthLoadOp = packed[9];
		int depthStoreOp = packed[10];
		int resolveFormat = packed[11];
		int resolveLoadOp = packed[12];
		int resolveStoreOp = packed[13];
		int resolveInitialLayout = packed[14];
		int resolveFinalLayout = packed[15];

		std::vector<VkAttachmentDescription> attachments;
		VkAttachmentDescription colorAttachment;
		memset (&colorAttachment, 0, sizeof (colorAttachment));
		colorAttachment.format = (VkFormat)colorFormat;
		colorAttachment.samples = (VkSampleCountFlagBits)samples;
		colorAttachment.loadOp = (VkAttachmentLoadOp)colorLoadOp;
		colorAttachment.storeOp = (VkAttachmentStoreOp)colorStoreOp;
		colorAttachment.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
		colorAttachment.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
		colorAttachment.initialLayout = (VkImageLayout)colorInitialLayout;
		colorAttachment.finalLayout = (VkImageLayout)colorFinalLayout;
		attachments.push_back (colorAttachment);

		VkAttachmentReference colorReference;
		memset (&colorReference, 0, sizeof (colorReference));
		colorReference.attachment = 0;
		colorReference.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

		VkAttachmentReference depthReference;
		memset (&depthReference, 0, sizeof (depthReference));
		bool hasDepth = depthStencilFormat != VK_FORMAT_UNDEFINED;
		bool hasResolve = resolveFormat != VK_FORMAT_UNDEFINED;
		if (hasDepth) {

			VkAttachmentDescription depthAttachment;
			memset (&depthAttachment, 0, sizeof (depthAttachment));
			depthAttachment.format = (VkFormat)depthStencilFormat;
			depthAttachment.samples = (VkSampleCountFlagBits)samples;
			depthAttachment.loadOp = (VkAttachmentLoadOp)depthLoadOp;
			depthAttachment.storeOp = (VkAttachmentStoreOp)depthStoreOp;
			depthAttachment.stencilLoadOp = (VkAttachmentLoadOp)depthLoadOp;
			depthAttachment.stencilStoreOp = (VkAttachmentStoreOp)depthStoreOp;
			depthAttachment.initialLayout = (VkImageLayout)depthInitialLayout;
			depthAttachment.finalLayout = (VkImageLayout)depthFinalLayout;
			attachments.push_back (depthAttachment);
			depthReference.attachment = 1;
			depthReference.layout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

		}

		VkAttachmentReference resolveReference;
		memset (&resolveReference, 0, sizeof (resolveReference));
		if (hasResolve) {

			VkAttachmentDescription resolveAttachment;
			memset (&resolveAttachment, 0, sizeof (resolveAttachment));
			resolveAttachment.format = (VkFormat)resolveFormat;
			resolveAttachment.samples = VK_SAMPLE_COUNT_1_BIT;
			resolveAttachment.loadOp = (VkAttachmentLoadOp)resolveLoadOp;
			resolveAttachment.storeOp = (VkAttachmentStoreOp)resolveStoreOp;
			resolveAttachment.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
			resolveAttachment.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
			resolveAttachment.initialLayout = (VkImageLayout)resolveInitialLayout;
			resolveAttachment.finalLayout = (VkImageLayout)resolveFinalLayout;
			attachments.push_back (resolveAttachment);
			resolveReference.attachment = (uint32_t)(attachments.size () - 1);
			resolveReference.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

		}

		VkSubpassDescription subpass;
		memset (&subpass, 0, sizeof (subpass));
		subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
		subpass.colorAttachmentCount = 1;
		subpass.pColorAttachments = &colorReference;
		subpass.pResolveAttachments = hasResolve ? &resolveReference : 0;
		subpass.pDepthStencilAttachment = hasDepth ? &depthReference : 0;

		VkSubpassDependency dependency;
		memset (&dependency, 0, sizeof (dependency));
		dependency.srcSubpass = VK_SUBPASS_EXTERNAL;
		dependency.dstSubpass = 0;
		dependency.srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT;
		dependency.dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT;
		dependency.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;

		VkRenderPassCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
		createInfo.attachmentCount = (uint32_t)attachments.size ();
		createInfo.pAttachments = attachments.data ();
		createInfo.subpassCount = 1;
		createInfo.pSubpasses = &subpass;
		createInfo.dependencyCount = 1;
		createInfo.pDependencies = &dependency;

		VkRenderPass renderPass = VK_NULL_HANDLE;
		VkResult result = vkCreateRenderPass (device, &createInfo, 0, &renderPass);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateRenderPass failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)renderPass);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}

	value lime_vk_get_last_error () {

		return alloc_string (lastVKError.c_str ());

	}


	void lime_vk_destroy_render_pass (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int renderPassHigh,
		int renderPassLow) {

#ifdef LIME_VULKAN
		if (renderPassHigh == 0 && renderPassLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkRenderPass renderPass = (VkRenderPass)(uintptr_t)CombineVulkanHandle (renderPassHigh, renderPassLow);
		PFN_vkDestroyRenderPass vkDestroyRenderPass = (PFN_vkDestroyRenderPass)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroyRenderPass");
		if (vkDestroyRenderPass) {

			vkDestroyRenderPass (device, renderPass, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_render_pass) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int renderPassHigh, int renderPassLow) {

#ifdef LIME_VULKAN
		if (renderPassHigh == 0 && renderPassLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkRenderPass renderPass = (VkRenderPass)(uintptr_t)CombineVulkanHandle (renderPassHigh, renderPassLow);
		PFN_vkDestroyRenderPass vkDestroyRenderPass = (PFN_vkDestroyRenderPass)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroyRenderPass");
		if (vkDestroyRenderPass) {

			vkDestroyRenderPass (device, renderPass, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	value lime_vk_create_framebuffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int renderPassHigh,
		int renderPassLow, value attachments, int width, int height, int layers) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkRenderPass renderPass = (VkRenderPass)(uintptr_t)CombineVulkanHandle (renderPassHigh, renderPassLow);
		std::vector<int> packed = GetVulkanIntVector (attachments);
		if (packed.empty () || packed.size () < (size_t)(1 + packed[0] * 2)) {

			lastVKError = "Invalid Vulkan framebuffer attachment list";
			return alloc_null ();

		}

		std::vector<VkImageView> imageViews;
		imageViews.reserve ((size_t)packed[0]);
		for (int i = 0; i < packed[0]; ++i) {

			imageViews.push_back ((VkImageView)(uintptr_t)CombineVulkanHandle (packed[1 + i * 2], packed[2 + i * 2]));

		}

		PFN_vkCreateFramebuffer vkCreateFramebuffer = (PFN_vkCreateFramebuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCreateFramebuffer");
		if (!vkCreateFramebuffer || !renderPass) return alloc_null ();

		VkFramebufferCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
		createInfo.renderPass = renderPass;
		createInfo.attachmentCount = (uint32_t)imageViews.size ();
		createInfo.pAttachments = imageViews.data ();
		createInfo.width = (uint32_t)width;
		createInfo.height = (uint32_t)height;
		createInfo.layers = (uint32_t)layers;

		VkFramebuffer framebuffer = VK_NULL_HANDLE;
		VkResult result = vkCreateFramebuffer (device, &createInfo, 0, &framebuffer);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateFramebuffer failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)framebuffer);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_framebuffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int renderPassHigh, int renderPassLow, hl_varray* attachments, int width, int height, int layers) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkRenderPass renderPass = (VkRenderPass)(uintptr_t)CombineVulkanHandle (renderPassHigh, renderPassLow);
		std::vector<int> packed = GetHLVulkanIntVector (attachments);
		if (packed.empty () || packed.size () < (size_t)(1 + packed[0] * 2)) {

			lastVKError = "Invalid Vulkan framebuffer attachment list";
			return 0;

		}

		std::vector<VkImageView> imageViews;
		imageViews.reserve ((size_t)packed[0]);
		for (int i = 0; i < packed[0]; ++i) {

			imageViews.push_back ((VkImageView)(uintptr_t)CombineVulkanHandle (packed[1 + i * 2], packed[2 + i * 2]));

		}

		PFN_vkCreateFramebuffer vkCreateFramebuffer = (PFN_vkCreateFramebuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCreateFramebuffer");
		if (!vkCreateFramebuffer || !renderPass) return 0;

		VkFramebufferCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
		createInfo.renderPass = renderPass;
		createInfo.attachmentCount = (uint32_t)imageViews.size ();
		createInfo.pAttachments = imageViews.data ();
		createInfo.width = (uint32_t)width;
		createInfo.height = (uint32_t)height;
		createInfo.layers = (uint32_t)layers;

		VkFramebuffer framebuffer = VK_NULL_HANDLE;
		VkResult result = vkCreateFramebuffer (device, &createInfo, 0, &framebuffer);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateFramebuffer failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)framebuffer);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_framebuffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int framebufferHigh,
		int framebufferLow) {

#ifdef LIME_VULKAN
		if (framebufferHigh == 0 && framebufferLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkFramebuffer framebuffer = (VkFramebuffer)(uintptr_t)CombineVulkanHandle (framebufferHigh, framebufferLow);
		PFN_vkDestroyFramebuffer vkDestroyFramebuffer = (PFN_vkDestroyFramebuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroyFramebuffer");
		if (vkDestroyFramebuffer) {

			vkDestroyFramebuffer (device, framebuffer, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_framebuffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int framebufferHigh, int framebufferLow) {

#ifdef LIME_VULKAN
		if (framebufferHigh == 0 && framebufferLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkFramebuffer framebuffer = (VkFramebuffer)(uintptr_t)CombineVulkanHandle (framebufferHigh, framebufferLow);
		PFN_vkDestroyFramebuffer vkDestroyFramebuffer = (PFN_vkDestroyFramebuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroyFramebuffer");
		if (vkDestroyFramebuffer) {

			vkDestroyFramebuffer (device, framebuffer, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	value lime_vk_create_shader_module (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, value bytes, int byteOffset,
		int byteLength) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		Bytes data (bytes);
		if (!data.b || byteOffset < 0 || byteLength <= 0 || byteOffset + byteLength > data.length || (byteLength % 4) != 0) {

			lastVKError = "Invalid Vulkan shader module bytes";
			return alloc_null ();

		}

		PFN_vkCreateShaderModule vkCreateShaderModule = (PFN_vkCreateShaderModule)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCreateShaderModule");
		if (!vkCreateShaderModule) return alloc_null ();

		VkShaderModuleCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
		createInfo.codeSize = (size_t)byteLength;
		createInfo.pCode = (const uint32_t*)(data.b + byteOffset);

		VkShaderModule shaderModule = VK_NULL_HANDLE;
		VkResult result = vkCreateShaderModule (device, &createInfo, 0, &shaderModule);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateShaderModule failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)shaderModule);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_shader_module) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, Bytes* bytes, int byteOffset, int byteLength) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		if (!bytes || !bytes->b || byteOffset < 0 || byteLength <= 0 || byteOffset + byteLength > bytes->length || (byteLength % 4) != 0) {

			lastVKError = "Invalid Vulkan shader module bytes";
			return 0;

		}

		PFN_vkCreateShaderModule vkCreateShaderModule = (PFN_vkCreateShaderModule)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCreateShaderModule");
		if (!vkCreateShaderModule) return 0;

		VkShaderModuleCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
		createInfo.codeSize = (size_t)byteLength;
		createInfo.pCode = (const uint32_t*)(bytes->b + byteOffset);

		VkShaderModule shaderModule = VK_NULL_HANDLE;
		VkResult result = vkCreateShaderModule (device, &createInfo, 0, &shaderModule);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateShaderModule failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)shaderModule);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_shader_module (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int shaderModuleHigh,
		int shaderModuleLow) {

#ifdef LIME_VULKAN
		if (shaderModuleHigh == 0 && shaderModuleLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkShaderModule shaderModule = (VkShaderModule)(uintptr_t)CombineVulkanHandle (shaderModuleHigh, shaderModuleLow);
		PFN_vkDestroyShaderModule vkDestroyShaderModule = (PFN_vkDestroyShaderModule)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroyShaderModule");
		if (vkDestroyShaderModule) {

			vkDestroyShaderModule (device, shaderModule, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_shader_module) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int shaderModuleHigh, int shaderModuleLow) {

#ifdef LIME_VULKAN
		if (shaderModuleHigh == 0 && shaderModuleLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkShaderModule shaderModule = (VkShaderModule)(uintptr_t)CombineVulkanHandle (shaderModuleHigh, shaderModuleLow);
		PFN_vkDestroyShaderModule vkDestroyShaderModule = (PFN_vkDestroyShaderModule)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroyShaderModule");
		if (vkDestroyShaderModule) {

			vkDestroyShaderModule (device, shaderModule, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	value lime_vk_create_sampler (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int filter, int addressMode,
		int mipmapMode, bool anisotropyEnable, double maxAnisotropy, int compareOp, double minLod, double maxLod) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateSampler vkCreateSampler = (PFN_vkCreateSampler)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateSampler");
		if (!vkCreateSampler) return alloc_null ();

		VkSamplerCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
		createInfo.magFilter = (VkFilter)filter;
		createInfo.minFilter = (VkFilter)filter;
		createInfo.mipmapMode = (VkSamplerMipmapMode)mipmapMode;
		createInfo.addressModeU = (VkSamplerAddressMode)addressMode;
		createInfo.addressModeV = (VkSamplerAddressMode)addressMode;
		createInfo.addressModeW = (VkSamplerAddressMode)addressMode;
		createInfo.anisotropyEnable = anisotropyEnable ? VK_TRUE : VK_FALSE;
		createInfo.maxAnisotropy = (float)maxAnisotropy;
		createInfo.compareEnable = compareOp >= 0 ? VK_TRUE : VK_FALSE;
		createInfo.compareOp = compareOp >= 0 ? (VkCompareOp)compareOp : VK_COMPARE_OP_ALWAYS;
		createInfo.minLod = (float)minLod;
		createInfo.maxLod = (float)maxLod;
		createInfo.borderColor = VK_BORDER_COLOR_INT_OPAQUE_BLACK;

		VkSampler sampler = VK_NULL_HANDLE;
		VkResult result = vkCreateSampler (device, &createInfo, 0, &sampler);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateSampler failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)sampler);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_sampler) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int filter, int addressMode, int mipmapMode, bool anisotropyEnable, double maxAnisotropy, int compareOp, double minLod, double maxLod) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreateSampler vkCreateSampler = (PFN_vkCreateSampler)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateSampler");
		if (!vkCreateSampler) return 0;

		VkSamplerCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
		createInfo.magFilter = (VkFilter)filter;
		createInfo.minFilter = (VkFilter)filter;
		createInfo.mipmapMode = (VkSamplerMipmapMode)mipmapMode;
		createInfo.addressModeU = (VkSamplerAddressMode)addressMode;
		createInfo.addressModeV = (VkSamplerAddressMode)addressMode;
		createInfo.addressModeW = (VkSamplerAddressMode)addressMode;
		createInfo.anisotropyEnable = anisotropyEnable ? VK_TRUE : VK_FALSE;
		createInfo.maxAnisotropy = (float)maxAnisotropy;
		createInfo.compareEnable = compareOp >= 0 ? VK_TRUE : VK_FALSE;
		createInfo.compareOp = compareOp >= 0 ? (VkCompareOp)compareOp : VK_COMPARE_OP_ALWAYS;
		createInfo.minLod = (float)minLod;
		createInfo.maxLod = (float)maxLod;
		createInfo.borderColor = VK_BORDER_COLOR_INT_OPAQUE_BLACK;

		VkSampler sampler = VK_NULL_HANDLE;
		VkResult result = vkCreateSampler (device, &createInfo, 0, &sampler);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateSampler failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)sampler);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_sampler (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int samplerHigh, int samplerLow) {

#ifdef LIME_VULKAN
		if (samplerHigh == 0 && samplerLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkSampler sampler = (VkSampler)(uintptr_t)CombineVulkanHandle (samplerHigh, samplerLow);
		PFN_vkDestroySampler vkDestroySampler = (PFN_vkDestroySampler)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroySampler");
		if (vkDestroySampler) {

			vkDestroySampler (device, sampler, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_sampler) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int samplerHigh, int samplerLow) {

#ifdef LIME_VULKAN
		if (samplerHigh == 0 && samplerLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkSampler sampler = (VkSampler)(uintptr_t)CombineVulkanHandle (samplerHigh, samplerLow);
		PFN_vkDestroySampler vkDestroySampler = (PFN_vkDestroySampler)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroySampler");
		if (vkDestroySampler) {

			vkDestroySampler (device, sampler, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	value lime_vk_create_descriptor_set_layout (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, value bindings) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		std::vector<int> packed = GetVulkanIntVector (bindings);
		if (packed.size () < 2 || packed.size () < (size_t)(2 + packed[1] * 4)) return alloc_null ();

		std::vector<VkDescriptorSetLayoutBinding> nativeBindings;
		nativeBindings.reserve ((size_t)packed[1]);
		for (int i = 0; i < packed[1]; ++i) {

			int base = 2 + i * 4;
			VkDescriptorSetLayoutBinding binding;
			memset (&binding, 0, sizeof (binding));
			binding.binding = (uint32_t)packed[base];
			binding.descriptorType = (VkDescriptorType)packed[base + 1];
			binding.descriptorCount = (uint32_t)packed[base + 2];
			binding.stageFlags = (VkShaderStageFlags)packed[base + 3];
			nativeBindings.push_back (binding);

		}

		PFN_vkCreateDescriptorSetLayout vkCreateDescriptorSetLayout =
			(PFN_vkCreateDescriptorSetLayout)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateDescriptorSetLayout");
		if (!vkCreateDescriptorSetLayout) return alloc_null ();

		VkDescriptorSetLayoutCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
		createInfo.flags = (VkDescriptorSetLayoutCreateFlags)packed[0];
		createInfo.bindingCount = (uint32_t)nativeBindings.size ();
		createInfo.pBindings = nativeBindings.empty () ? 0 : nativeBindings.data ();

		VkDescriptorSetLayout layout = VK_NULL_HANDLE;
		VkResult result = vkCreateDescriptorSetLayout (device, &createInfo, 0, &layout);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateDescriptorSetLayout failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)layout);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_descriptor_set_layout) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, hl_varray* bindings) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		std::vector<int> packed = GetHLVulkanIntVector (bindings);
		if (packed.size () < 2 || packed.size () < (size_t)(2 + packed[1] * 4)) return 0;

		std::vector<VkDescriptorSetLayoutBinding> nativeBindings;
		nativeBindings.reserve ((size_t)packed[1]);
		for (int i = 0; i < packed[1]; ++i) {

			int base = 2 + i * 4;
			VkDescriptorSetLayoutBinding binding;
			memset (&binding, 0, sizeof (binding));
			binding.binding = (uint32_t)packed[base];
			binding.descriptorType = (VkDescriptorType)packed[base + 1];
			binding.descriptorCount = (uint32_t)packed[base + 2];
			binding.stageFlags = (VkShaderStageFlags)packed[base + 3];
			nativeBindings.push_back (binding);

		}

		PFN_vkCreateDescriptorSetLayout vkCreateDescriptorSetLayout =
			(PFN_vkCreateDescriptorSetLayout)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateDescriptorSetLayout");
		if (!vkCreateDescriptorSetLayout) return 0;

		VkDescriptorSetLayoutCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
		createInfo.flags = (VkDescriptorSetLayoutCreateFlags)packed[0];
		createInfo.bindingCount = (uint32_t)nativeBindings.size ();
		createInfo.pBindings = nativeBindings.empty () ? 0 : nativeBindings.data ();

		VkDescriptorSetLayout layout = VK_NULL_HANDLE;
		VkResult result = vkCreateDescriptorSetLayout (device, &createInfo, 0, &layout);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateDescriptorSetLayout failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)layout);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_descriptor_set_layout (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int layoutHigh,
		int layoutLow) {

#ifdef LIME_VULKAN
		if (layoutHigh == 0 && layoutLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDescriptorSetLayout layout = (VkDescriptorSetLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		PFN_vkDestroyDescriptorSetLayout vkDestroyDescriptorSetLayout =
			(PFN_vkDestroyDescriptorSetLayout)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyDescriptorSetLayout");
		if (vkDestroyDescriptorSetLayout) {

			vkDestroyDescriptorSetLayout (device, layout, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_descriptor_set_layout) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int layoutHigh, int layoutLow) {

#ifdef LIME_VULKAN
		if (layoutHigh == 0 && layoutLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDescriptorSetLayout layout = (VkDescriptorSetLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		PFN_vkDestroyDescriptorSetLayout vkDestroyDescriptorSetLayout =
			(PFN_vkDestroyDescriptorSetLayout)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyDescriptorSetLayout");
		if (vkDestroyDescriptorSetLayout) {

			vkDestroyDescriptorSetLayout (device, layout, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	value lime_vk_create_descriptor_pool (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, value poolSizes) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		std::vector<int> packed = GetVulkanIntVector (poolSizes);
		if (packed.size () < 3 || packed.size () < (size_t)(3 + packed[2] * 2)) return alloc_null ();

		std::vector<VkDescriptorPoolSize> nativeSizes;
		nativeSizes.reserve ((size_t)packed[2]);
		for (int i = 0; i < packed[2]; ++i) {

			int base = 3 + i * 2;
			VkDescriptorPoolSize size;
			size.type = (VkDescriptorType)packed[base];
			size.descriptorCount = (uint32_t)packed[base + 1];
			nativeSizes.push_back (size);

		}

		PFN_vkCreateDescriptorPool vkCreateDescriptorPool =
			(PFN_vkCreateDescriptorPool)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateDescriptorPool");
		if (!vkCreateDescriptorPool) return alloc_null ();

		VkDescriptorPoolCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
		createInfo.flags = (VkDescriptorPoolCreateFlags)packed[0];
		createInfo.maxSets = (uint32_t)packed[1];
		createInfo.poolSizeCount = (uint32_t)nativeSizes.size ();
		createInfo.pPoolSizes = nativeSizes.empty () ? 0 : nativeSizes.data ();

		VkDescriptorPool pool = VK_NULL_HANDLE;
		VkResult result = vkCreateDescriptorPool (device, &createInfo, 0, &pool);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateDescriptorPool failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)pool);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_descriptor_pool) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, hl_varray* poolSizes) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		std::vector<int> packed = GetHLVulkanIntVector (poolSizes);
		if (packed.size () < 3 || packed.size () < (size_t)(3 + packed[2] * 2)) return 0;

		std::vector<VkDescriptorPoolSize> nativeSizes;
		nativeSizes.reserve ((size_t)packed[2]);
		for (int i = 0; i < packed[2]; ++i) {

			int base = 3 + i * 2;
			VkDescriptorPoolSize size;
			size.type = (VkDescriptorType)packed[base];
			size.descriptorCount = (uint32_t)packed[base + 1];
			nativeSizes.push_back (size);

		}

		PFN_vkCreateDescriptorPool vkCreateDescriptorPool =
			(PFN_vkCreateDescriptorPool)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateDescriptorPool");
		if (!vkCreateDescriptorPool) return 0;

		VkDescriptorPoolCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
		createInfo.flags = (VkDescriptorPoolCreateFlags)packed[0];
		createInfo.maxSets = (uint32_t)packed[1];
		createInfo.poolSizeCount = (uint32_t)nativeSizes.size ();
		createInfo.pPoolSizes = nativeSizes.empty () ? 0 : nativeSizes.data ();

		VkDescriptorPool pool = VK_NULL_HANDLE;
		VkResult result = vkCreateDescriptorPool (device, &createInfo, 0, &pool);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateDescriptorPool failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)pool);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}

	HL_PRIM vbyte* HL_NAME(hl_vk_get_last_error) () {

		return hl_copy_bytes ((const vbyte*)lastVKError.c_str (), (int)lastVKError.size () + 1);

	}


	void lime_vk_destroy_descriptor_pool (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int poolHigh, int poolLow) {

#ifdef LIME_VULKAN
		if (poolHigh == 0 && poolLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDescriptorPool pool = (VkDescriptorPool)(uintptr_t)CombineVulkanHandle (poolHigh, poolLow);
		PFN_vkDestroyDescriptorPool vkDestroyDescriptorPool =
			(PFN_vkDestroyDescriptorPool)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyDescriptorPool");
		if (vkDestroyDescriptorPool) {

			vkDestroyDescriptorPool (device, pool, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_descriptor_pool) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int poolHigh, int poolLow) {

#ifdef LIME_VULKAN
		if (poolHigh == 0 && poolLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDescriptorPool pool = (VkDescriptorPool)(uintptr_t)CombineVulkanHandle (poolHigh, poolLow);
		PFN_vkDestroyDescriptorPool vkDestroyDescriptorPool =
			(PFN_vkDestroyDescriptorPool)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyDescriptorPool");
		if (vkDestroyDescriptorPool) {

			vkDestroyDescriptorPool (device, pool, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	bool lime_vk_reset_descriptor_pool (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int poolHigh, int poolLow,
		int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDescriptorPool pool = (VkDescriptorPool)(uintptr_t)CombineVulkanHandle (poolHigh, poolLow);
		PFN_vkResetDescriptorPool vkResetDescriptorPool =
			(PFN_vkResetDescriptorPool)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkResetDescriptorPool");
		if (!vkResetDescriptorPool || !pool) return false;

		VkResult result = vkResetDescriptorPool (device, pool, (VkDescriptorPoolResetFlags)flags);
		if (result != VK_SUCCESS) {

			lastVKError = "vkResetDescriptorPool failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_reset_descriptor_pool) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int poolHigh, int poolLow, int flags) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDescriptorPool pool = (VkDescriptorPool)(uintptr_t)CombineVulkanHandle (poolHigh, poolLow);
		PFN_vkResetDescriptorPool vkResetDescriptorPool =
			(PFN_vkResetDescriptorPool)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkResetDescriptorPool");
		if (!vkResetDescriptorPool || !pool) return false;

		VkResult result = vkResetDescriptorPool (device, pool, (VkDescriptorPoolResetFlags)flags);
		if (result != VK_SUCCESS) {

			lastVKError = "vkResetDescriptorPool failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	value lime_vk_allocate_descriptor_set (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int poolHigh,
		int poolLow, int layoutHigh, int layoutLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDescriptorPool pool = (VkDescriptorPool)(uintptr_t)CombineVulkanHandle (poolHigh, poolLow);
		VkDescriptorSetLayout layout = (VkDescriptorSetLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		PFN_vkAllocateDescriptorSets vkAllocateDescriptorSets =
			(PFN_vkAllocateDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkAllocateDescriptorSets");
		if (!vkAllocateDescriptorSets || !pool || !layout) return alloc_null ();

		VkDescriptorSetAllocateInfo allocateInfo;
		memset (&allocateInfo, 0, sizeof (allocateInfo));
		allocateInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
		allocateInfo.descriptorPool = pool;
		allocateInfo.descriptorSetCount = 1;
		allocateInfo.pSetLayouts = &layout;

		VkDescriptorSet descriptorSet = VK_NULL_HANDLE;
		VkResult result = vkAllocateDescriptorSets (device, &allocateInfo, &descriptorSet);
		if (result != VK_SUCCESS) {

			lastVKError = "vkAllocateDescriptorSets failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)descriptorSet);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_allocate_descriptor_set) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int poolHigh, int poolLow, int layoutHigh, int layoutLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDescriptorPool pool = (VkDescriptorPool)(uintptr_t)CombineVulkanHandle (poolHigh, poolLow);
		VkDescriptorSetLayout layout = (VkDescriptorSetLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		PFN_vkAllocateDescriptorSets vkAllocateDescriptorSets =
			(PFN_vkAllocateDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkAllocateDescriptorSets");
		if (!vkAllocateDescriptorSets || !pool || !layout) return 0;

		VkDescriptorSetAllocateInfo allocateInfo;
		memset (&allocateInfo, 0, sizeof (allocateInfo));
		allocateInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
		allocateInfo.descriptorPool = pool;
		allocateInfo.descriptorSetCount = 1;
		allocateInfo.pSetLayouts = &layout;

		VkDescriptorSet descriptorSet = VK_NULL_HANDLE;
		VkResult result = vkAllocateDescriptorSets (device, &allocateInfo, &descriptorSet);
		if (result != VK_SUCCESS) {

			lastVKError = "vkAllocateDescriptorSets failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)descriptorSet);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	bool lime_vk_update_descriptor_set_image (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int setHigh,
		int setLow, int binding, int descriptorType, int imageViewHigh, int imageViewLow, int samplerHigh, int samplerLow, int imageLayout) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDescriptorSet descriptorSet = (VkDescriptorSet)(uintptr_t)CombineVulkanHandle (setHigh, setLow);
		PFN_vkUpdateDescriptorSets vkUpdateDescriptorSets =
			(PFN_vkUpdateDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUpdateDescriptorSets");
		if (!vkUpdateDescriptorSets || !descriptorSet) return false;

		VkDescriptorImageInfo imageInfo;
		memset (&imageInfo, 0, sizeof (imageInfo));
		imageInfo.sampler = (VkSampler)(uintptr_t)CombineVulkanHandle (samplerHigh, samplerLow);
		imageInfo.imageView = (VkImageView)(uintptr_t)CombineVulkanHandle (imageViewHigh, imageViewLow);
		imageInfo.imageLayout = (VkImageLayout)imageLayout;

		VkWriteDescriptorSet write;
		memset (&write, 0, sizeof (write));
		write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
		write.dstSet = descriptorSet;
		write.dstBinding = (uint32_t)binding;
		write.descriptorCount = 1;
		write.descriptorType = (VkDescriptorType)descriptorType;
		write.pImageInfo = &imageInfo;
		vkUpdateDescriptorSets (device, 1, &write, 0, 0);
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_update_descriptor_set_image) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int setHigh, int setLow, int binding, int descriptorType, int imageViewHigh, int imageViewLow, int samplerHigh,
		int samplerLow, int imageLayout) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDescriptorSet descriptorSet = (VkDescriptorSet)(uintptr_t)CombineVulkanHandle (setHigh, setLow);
		PFN_vkUpdateDescriptorSets vkUpdateDescriptorSets =
			(PFN_vkUpdateDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUpdateDescriptorSets");
		if (!vkUpdateDescriptorSets || !descriptorSet) return false;

		VkDescriptorImageInfo imageInfo;
		memset (&imageInfo, 0, sizeof (imageInfo));
		imageInfo.sampler = (VkSampler)(uintptr_t)CombineVulkanHandle (samplerHigh, samplerLow);
		imageInfo.imageView = (VkImageView)(uintptr_t)CombineVulkanHandle (imageViewHigh, imageViewLow);
		imageInfo.imageLayout = (VkImageLayout)imageLayout;

		VkWriteDescriptorSet write;
		memset (&write, 0, sizeof (write));
		write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
		write.dstSet = descriptorSet;
		write.dstBinding = (uint32_t)binding;
		write.descriptorCount = 1;
		write.descriptorType = (VkDescriptorType)descriptorType;
		write.pImageInfo = &imageInfo;
		vkUpdateDescriptorSets (device, 1, &write, 0, 0);
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}

#ifdef LIME_VULKAN
	value lime_vulkan_renderer_create (value window, HxString applicationName) {

		Window* targetWindow = (Window*)val_data (window);
		VulkanRenderer* renderer = new VulkanRenderer (targetWindow);

		if (!renderer->Create (applicationName.c_str () ? hxs_utf8 (applicationName, nullptr) : 0)) {

			lastVulkanRendererError = renderer->GetLastError ();
			delete renderer;
			return alloc_null ();

		}

		lastVulkanRendererError.clear ();
		return CFFIPointer (renderer);

	}


	bool lime_vk_update_descriptor_set_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int setHigh,
		int setLow, int binding, int descriptorType, int bufferHigh, int bufferLow, int offset, int range) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDescriptorSet descriptorSet = (VkDescriptorSet)(uintptr_t)CombineVulkanHandle (setHigh, setLow);
		PFN_vkUpdateDescriptorSets vkUpdateDescriptorSets =
			(PFN_vkUpdateDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUpdateDescriptorSets");
		if (!vkUpdateDescriptorSets || !descriptorSet) return false;

		VkDescriptorBufferInfo bufferInfo;
		memset (&bufferInfo, 0, sizeof (bufferInfo));
		bufferInfo.buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		bufferInfo.offset = (VkDeviceSize)(uint32_t)offset;
		bufferInfo.range = range > 0 ? (VkDeviceSize)(uint32_t)range : VK_WHOLE_SIZE;

		VkWriteDescriptorSet write;
		memset (&write, 0, sizeof (write));
		write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
		write.dstSet = descriptorSet;
		write.dstBinding = (uint32_t)binding;
		write.descriptorCount = 1;
		write.descriptorType = (VkDescriptorType)descriptorType;
		write.pBufferInfo = &bufferInfo;
		vkUpdateDescriptorSets (device, 1, &write, 0, 0);
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_update_descriptor_set_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int setHigh, int setLow, int binding, int descriptorType, int bufferHigh, int bufferLow, int offset, int range) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkDescriptorSet descriptorSet = (VkDescriptorSet)(uintptr_t)CombineVulkanHandle (setHigh, setLow);
		PFN_vkUpdateDescriptorSets vkUpdateDescriptorSets =
			(PFN_vkUpdateDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkUpdateDescriptorSets");
		if (!vkUpdateDescriptorSets || !descriptorSet) return false;

		VkDescriptorBufferInfo bufferInfo;
		memset (&bufferInfo, 0, sizeof (bufferInfo));
		bufferInfo.buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		bufferInfo.offset = (VkDeviceSize)(uint32_t)offset;
		bufferInfo.range = range > 0 ? (VkDeviceSize)(uint32_t)range : VK_WHOLE_SIZE;

		VkWriteDescriptorSet write;
		memset (&write, 0, sizeof (write));
		write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
		write.dstSet = descriptorSet;
		write.dstBinding = (uint32_t)binding;
		write.descriptorCount = 1;
		write.descriptorType = (VkDescriptorType)descriptorType;
		write.pBufferInfo = &bufferInfo;
		vkUpdateDescriptorSets (device, 1, &write, 0, 0);
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_update_descriptor_sets (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, value writes) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		return UpdateManagedVulkanDescriptorSets (targetWindow, instance, device, GetVulkanIntVector (writes));
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_update_descriptor_sets) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, hl_varray* writes) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		return UpdateManagedVulkanDescriptorSets (targetWindow, instance, device, GetHLVulkanIntVector (writes));
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	value lime_vk_create_pipeline_layout (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, value setLayouts,
		int pushConstantStages, int pushConstantSize) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		std::vector<int> packed = GetVulkanIntVector (setLayouts);
		if (packed.empty () || packed.size () < (size_t)(1 + packed[0] * 2)) return alloc_null ();

		std::vector<VkDescriptorSetLayout> layouts;
		layouts.reserve ((size_t)packed[0]);
		for (int i = 0; i < packed[0]; ++i) {

			layouts.push_back ((VkDescriptorSetLayout)(uintptr_t)CombineVulkanHandle (packed[1 + i * 2], packed[2 + i * 2]));

		}

		VkPushConstantRange pushRange;
		memset (&pushRange, 0, sizeof (pushRange));
		pushRange.stageFlags = (VkShaderStageFlags)pushConstantStages;
		pushRange.offset = 0;
		pushRange.size = (uint32_t)pushConstantSize;

		PFN_vkCreatePipelineLayout vkCreatePipelineLayout =
			(PFN_vkCreatePipelineLayout)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreatePipelineLayout");
		if (!vkCreatePipelineLayout) return alloc_null ();

		VkPipelineLayoutCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
		createInfo.setLayoutCount = (uint32_t)layouts.size ();
		createInfo.pSetLayouts = layouts.empty () ? 0 : layouts.data ();
		createInfo.pushConstantRangeCount = pushConstantSize > 0 ? 1 : 0;
		createInfo.pPushConstantRanges = pushConstantSize > 0 ? &pushRange : 0;

		VkPipelineLayout layout = VK_NULL_HANDLE;
		VkResult result = vkCreatePipelineLayout (device, &createInfo, 0, &layout);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreatePipelineLayout failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)layout);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_pipeline_layout) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, hl_varray* setLayouts, int pushConstantStages, int pushConstantSize) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		std::vector<int> packed = GetHLVulkanIntVector (setLayouts);
		if (packed.empty () || packed.size () < (size_t)(1 + packed[0] * 2)) return 0;

		std::vector<VkDescriptorSetLayout> layouts;
		layouts.reserve ((size_t)packed[0]);
		for (int i = 0; i < packed[0]; ++i) {

			layouts.push_back ((VkDescriptorSetLayout)(uintptr_t)CombineVulkanHandle (packed[1 + i * 2], packed[2 + i * 2]));

		}

		VkPushConstantRange pushRange;
		memset (&pushRange, 0, sizeof (pushRange));
		pushRange.stageFlags = (VkShaderStageFlags)pushConstantStages;
		pushRange.offset = 0;
		pushRange.size = (uint32_t)pushConstantSize;

		PFN_vkCreatePipelineLayout vkCreatePipelineLayout =
			(PFN_vkCreatePipelineLayout)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreatePipelineLayout");
		if (!vkCreatePipelineLayout) return 0;

		VkPipelineLayoutCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
		createInfo.setLayoutCount = (uint32_t)layouts.size ();
		createInfo.pSetLayouts = layouts.empty () ? 0 : layouts.data ();
		createInfo.pushConstantRangeCount = pushConstantSize > 0 ? 1 : 0;
		createInfo.pPushConstantRanges = pushConstantSize > 0 ? &pushRange : 0;

		VkPipelineLayout layout = VK_NULL_HANDLE;
		VkResult result = vkCreatePipelineLayout (device, &createInfo, 0, &layout);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreatePipelineLayout failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)layout);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}

	HL_PRIM HL_CFFIPointer* HL_NAME(hl_vulkan_renderer_create) (HL_CFFIPointer* window, hl_vstring* applicationName) {

		Window* targetWindow = (Window*)window->ptr;
		VulkanRenderer* renderer = new VulkanRenderer (targetWindow);
		const char* applicationNameUTF8 = applicationName ? (const char*)hl_to_utf8 ((const uchar*)applicationName->bytes) : 0;

		if (!renderer->Create (applicationNameUTF8)) {

			lastVulkanRendererError = renderer->GetLastError ();
			delete renderer;
			return 0;

		}

		lastVulkanRendererError.clear ();
		return HLCFFIPointer (renderer);

	}


	void lime_vk_destroy_pipeline_layout (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int layoutHigh,
		int layoutLow) {

#ifdef LIME_VULKAN
		if (layoutHigh == 0 && layoutLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkPipelineLayout layout = (VkPipelineLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		PFN_vkDestroyPipelineLayout vkDestroyPipelineLayout =
			(PFN_vkDestroyPipelineLayout)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyPipelineLayout");
		if (vkDestroyPipelineLayout) {

			vkDestroyPipelineLayout (device, layout, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_pipeline_layout) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int layoutHigh, int layoutLow) {

#ifdef LIME_VULKAN
		if (layoutHigh == 0 && layoutLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkPipelineLayout layout = (VkPipelineLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		PFN_vkDestroyPipelineLayout vkDestroyPipelineLayout =
			(PFN_vkDestroyPipelineLayout)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyPipelineLayout");
		if (vkDestroyPipelineLayout) {

			vkDestroyPipelineLayout (device, layout, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	value lime_vk_create_pipeline_cache (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, value bytes, int byteOffset,
		int byteLength) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreatePipelineCache vkCreatePipelineCache =
			(PFN_vkCreatePipelineCache)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreatePipelineCache");
		if (!vkCreatePipelineCache) return alloc_null ();

		VkPipelineCacheCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
		Bytes initialData (bytes);
		if (initialData.b && byteLength > 0) {

			if (byteOffset < 0 || byteOffset + byteLength > initialData.length) {

				lastVKError = "Invalid Vulkan pipeline cache data range";
				return alloc_null ();

			}

			createInfo.initialDataSize = (size_t)byteLength;
			createInfo.pInitialData = initialData.b + byteOffset;

		}

		VkPipelineCache cache = VK_NULL_HANDLE;
		VkResult result = vkCreatePipelineCache (device, &createInfo, 0, &cache);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreatePipelineCache failed";
			return alloc_null ();

		}

		lastVKError.clear ();
		return CreateVulkanHandleValue ((uint64_t)(uintptr_t)cache);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_pipeline_cache) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, Bytes* bytes, int byteOffset, int byteLength) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCreatePipelineCache vkCreatePipelineCache =
			(PFN_vkCreatePipelineCache)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreatePipelineCache");
		if (!vkCreatePipelineCache) return 0;

		VkPipelineCacheCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
		if (bytes && bytes->b && byteLength > 0) {

			if (byteOffset < 0 || byteOffset + byteLength > bytes->length) {

				lastVKError = "Invalid Vulkan pipeline cache data range";
				return 0;

			}

			createInfo.initialDataSize = (size_t)byteLength;
			createInfo.pInitialData = bytes->b + byteOffset;

		}

		VkPipelineCache cache = VK_NULL_HANDLE;
		VkResult result = vkCreatePipelineCache (device, &createInfo, 0, &cache);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreatePipelineCache failed";
			return 0;

		}

		lastVKError.clear ();
		return HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)cache);
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	bool lime_vk_get_pipeline_cache_data (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int cacheHigh,
		int cacheLow, value bytes) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkPipelineCache cache = (VkPipelineCache)(uintptr_t)CombineVulkanHandle (cacheHigh, cacheLow);
		PFN_vkGetPipelineCacheData vkGetPipelineCacheData =
			(PFN_vkGetPipelineCacheData)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkGetPipelineCacheData");
		if (!vkGetPipelineCacheData || !cache) return false;

		size_t size = 0;
		VkResult result = vkGetPipelineCacheData (device, cache, &size, 0);
		if (result != VK_SUCCESS) {

			lastVKError = "vkGetPipelineCacheData failed";
			return false;

		}

		Bytes data (bytes);
		data.Resize ((int)size);
		if (size > 0 && !data.b) return false;

		result = vkGetPipelineCacheData (device, cache, &size, data.b);
		if (result != VK_SUCCESS) {

			lastVKError = "vkGetPipelineCacheData failed";
			return false;

		}

		data.Value (bytes);
		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_get_pipeline_cache_data) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int cacheHigh, int cacheLow, Bytes* bytes) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkPipelineCache cache = (VkPipelineCache)(uintptr_t)CombineVulkanHandle (cacheHigh, cacheLow);
		PFN_vkGetPipelineCacheData vkGetPipelineCacheData =
			(PFN_vkGetPipelineCacheData)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkGetPipelineCacheData");
		if (!vkGetPipelineCacheData || !cache || !bytes) return false;

		size_t size = 0;
		VkResult result = vkGetPipelineCacheData (device, cache, &size, 0);
		if (result != VK_SUCCESS) {

			lastVKError = "vkGetPipelineCacheData failed";
			return false;

		}

		bytes->Resize ((int)size);
		if (size > 0 && !bytes->b) return false;

		result = vkGetPipelineCacheData (device, cache, &size, bytes->b);
		if (result != VK_SUCCESS) {

			lastVKError = "vkGetPipelineCacheData failed";
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	void lime_vk_destroy_pipeline_cache (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int cacheHigh,
		int cacheLow) {

#ifdef LIME_VULKAN
		if (cacheHigh == 0 && cacheLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkPipelineCache cache = (VkPipelineCache)(uintptr_t)CombineVulkanHandle (cacheHigh, cacheLow);
		PFN_vkDestroyPipelineCache vkDestroyPipelineCache =
			(PFN_vkDestroyPipelineCache)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyPipelineCache");
		if (vkDestroyPipelineCache) {

			vkDestroyPipelineCache (device, cache, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_pipeline_cache) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int cacheHigh, int cacheLow) {

#ifdef LIME_VULKAN
		if (cacheHigh == 0 && cacheLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkPipelineCache cache = (VkPipelineCache)(uintptr_t)CombineVulkanHandle (cacheHigh, cacheLow);
		PFN_vkDestroyPipelineCache vkDestroyPipelineCache =
			(PFN_vkDestroyPipelineCache)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkDestroyPipelineCache");
		if (vkDestroyPipelineCache) {

			vkDestroyPipelineCache (device, cache, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}

	void lime_vulkan_renderer_destroy (value handle) {

		if (val_is_null (handle)) return;
		VulkanRenderer* renderer = (VulkanRenderer*)val_data (handle);
		delete renderer;

	}


#ifdef LIME_VULKAN
	static VkPipeline CreateManagedVulkanGraphicsPipeline (Window* targetWindow, VkInstance instance, VkDevice device, VkRenderPass renderPass,
		VkPipelineLayout layout, VkShaderModule vertexShader, VkShaderModule fragmentShader, const std::vector<int>& state) {

		if (state.size () < 41 || !renderPass || !layout || !vertexShader || !fragmentShader) {

			lastVKError = "Invalid Vulkan graphics pipeline state";
			return VK_NULL_HANDLE;

		}

		int cursor = 0;
		VkPipelineCache cache = (VkPipelineCache)(uintptr_t)CombineVulkanHandle (state[cursor], state[cursor + 1]);
		cursor += 2;
		int topology = state[cursor++];
		bool primitiveRestart = state[cursor++] != 0;
		int polygonMode = state[cursor++];
		int cullMode = state[cursor++];
		int frontFace = state[cursor++];
		bool depthTest = state[cursor++] != 0;
		bool depthWrite = state[cursor++] != 0;
		int depthCompareOp = state[cursor++];
		bool blend = state[cursor++] != 0;
		int srcColorBlendFactor = state[cursor++];
		int dstColorBlendFactor = state[cursor++];
		int colorBlendOp = state[cursor++];
		int srcAlphaBlendFactor = state[cursor++];
		int dstAlphaBlendFactor = state[cursor++];
		int alphaBlendOp = state[cursor++];
		int dynamicStateFlags = state[cursor++];
		int colorWriteMask = state[cursor++];
		bool stencilTest = state[cursor++] != 0;
		int frontFailOp = state[cursor++];
		int frontPassOp = state[cursor++];
		int frontDepthFailOp = state[cursor++];
		int frontCompareOp = state[cursor++];
		int frontCompareMask = state[cursor++];
		int frontWriteMask = state[cursor++];
		int frontReference = state[cursor++];
		int backFailOp = state[cursor++];
		int backPassOp = state[cursor++];
		int backDepthFailOp = state[cursor++];
		int backCompareOp = state[cursor++];
		int backCompareMask = state[cursor++];
		int backWriteMask = state[cursor++];
		int backReference = state[cursor++];
		int rasterizationSamples = state[cursor++];
		bool sampleShading = state[cursor++] != 0;
		int minSampleShading = state[cursor++];
		int sampleMask = state[cursor++];
		bool alphaToCoverage = state[cursor++] != 0;
		bool alphaToOne = state[cursor++] != 0;
		int bindingCount = state[cursor++];

		if ((int)state.size () < cursor + bindingCount * 3 + 1) {

			lastVKError = "Invalid Vulkan vertex binding state";
			return VK_NULL_HANDLE;

		}

		std::vector<VkVertexInputBindingDescription> bindings;
		bindings.reserve ((size_t)bindingCount);
		for (int i = 0; i < bindingCount; ++i) {

			VkVertexInputBindingDescription binding;
			binding.binding = (uint32_t)state[cursor++];
			binding.stride = (uint32_t)state[cursor++];
			binding.inputRate = (VkVertexInputRate)state[cursor++];
			bindings.push_back (binding);

		}

		int attributeCount = state[cursor++];
		if ((int)state.size () < cursor + attributeCount * 4) {

			lastVKError = "Invalid Vulkan vertex attribute state";
			return VK_NULL_HANDLE;

		}

		std::vector<VkVertexInputAttributeDescription> attributes;
		attributes.reserve ((size_t)attributeCount);
		for (int i = 0; i < attributeCount; ++i) {

			VkVertexInputAttributeDescription attribute;
			attribute.location = (uint32_t)state[cursor++];
			attribute.binding = (uint32_t)state[cursor++];
			attribute.format = (VkFormat)state[cursor++];
			attribute.offset = (uint32_t)state[cursor++];
			attributes.push_back (attribute);

		}

		PFN_vkCreateGraphicsPipelines vkCreateGraphicsPipelines =
			(PFN_vkCreateGraphicsPipelines)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCreateGraphicsPipelines");
		if (!vkCreateGraphicsPipelines) return VK_NULL_HANDLE;

		VkPipelineShaderStageCreateInfo stages[2];
		memset (stages, 0, sizeof (stages));
		stages[0].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
		stages[0].stage = VK_SHADER_STAGE_VERTEX_BIT;
		stages[0].module = vertexShader;
		stages[0].pName = "main";
		stages[1].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
		stages[1].stage = VK_SHADER_STAGE_FRAGMENT_BIT;
		stages[1].module = fragmentShader;
		stages[1].pName = "main";

		VkPipelineVertexInputStateCreateInfo vertexInput;
		memset (&vertexInput, 0, sizeof (vertexInput));
		vertexInput.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
		vertexInput.vertexBindingDescriptionCount = (uint32_t)bindings.size ();
		vertexInput.pVertexBindingDescriptions = bindings.empty () ? 0 : bindings.data ();
		vertexInput.vertexAttributeDescriptionCount = (uint32_t)attributes.size ();
		vertexInput.pVertexAttributeDescriptions = attributes.empty () ? 0 : attributes.data ();

		VkPipelineInputAssemblyStateCreateInfo inputAssembly;
		memset (&inputAssembly, 0, sizeof (inputAssembly));
		inputAssembly.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
		inputAssembly.topology = (VkPrimitiveTopology)topology;
		inputAssembly.primitiveRestartEnable = primitiveRestart ? VK_TRUE : VK_FALSE;

		VkViewport viewport;
		memset (&viewport, 0, sizeof (viewport));
		viewport.width = 1.0f;
		viewport.height = 1.0f;
		viewport.maxDepth = 1.0f;

		VkRect2D scissor;
		memset (&scissor, 0, sizeof (scissor));
		scissor.extent.width = 1;
		scissor.extent.height = 1;

		VkPipelineViewportStateCreateInfo viewportState;
		memset (&viewportState, 0, sizeof (viewportState));
		viewportState.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
		viewportState.viewportCount = 1;
		viewportState.pViewports = &viewport;
		viewportState.scissorCount = 1;
		viewportState.pScissors = &scissor;

		VkPipelineRasterizationStateCreateInfo rasterization;
		memset (&rasterization, 0, sizeof (rasterization));
		rasterization.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
		rasterization.polygonMode = (VkPolygonMode)polygonMode;
		rasterization.cullMode = (VkCullModeFlags)cullMode;
		rasterization.frontFace = (VkFrontFace)frontFace;
		rasterization.lineWidth = 1.0f;

		VkPipelineMultisampleStateCreateInfo multisample;
		memset (&multisample, 0, sizeof (multisample));
		multisample.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
		multisample.rasterizationSamples = (VkSampleCountFlagBits)rasterizationSamples;
		multisample.sampleShadingEnable = sampleShading ? VK_TRUE : VK_FALSE;
		multisample.minSampleShading = (float)minSampleShading / 1000000.0f;
		VkSampleMask sampleMaskValue = (VkSampleMask)sampleMask;
		multisample.pSampleMask = sampleMask != 0 ? &sampleMaskValue : 0;
		multisample.alphaToCoverageEnable = alphaToCoverage ? VK_TRUE : VK_FALSE;
		multisample.alphaToOneEnable = alphaToOne ? VK_TRUE : VK_FALSE;

		VkPipelineDepthStencilStateCreateInfo depthStencil;
		memset (&depthStencil, 0, sizeof (depthStencil));
		depthStencil.sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;
		depthStencil.depthTestEnable = depthTest ? VK_TRUE : VK_FALSE;
		depthStencil.depthWriteEnable = depthWrite ? VK_TRUE : VK_FALSE;
		depthStencil.depthCompareOp = (VkCompareOp)depthCompareOp;
		depthStencil.stencilTestEnable = stencilTest ? VK_TRUE : VK_FALSE;
		depthStencil.front.failOp = (VkStencilOp)frontFailOp;
		depthStencil.front.passOp = (VkStencilOp)frontPassOp;
		depthStencil.front.depthFailOp = (VkStencilOp)frontDepthFailOp;
		depthStencil.front.compareOp = (VkCompareOp)frontCompareOp;
		depthStencil.front.compareMask = (uint32_t)frontCompareMask;
		depthStencil.front.writeMask = (uint32_t)frontWriteMask;
		depthStencil.front.reference = (uint32_t)frontReference;
		depthStencil.back.failOp = (VkStencilOp)backFailOp;
		depthStencil.back.passOp = (VkStencilOp)backPassOp;
		depthStencil.back.depthFailOp = (VkStencilOp)backDepthFailOp;
		depthStencil.back.compareOp = (VkCompareOp)backCompareOp;
		depthStencil.back.compareMask = (uint32_t)backCompareMask;
		depthStencil.back.writeMask = (uint32_t)backWriteMask;
		depthStencil.back.reference = (uint32_t)backReference;

		VkPipelineColorBlendAttachmentState colorAttachment;
		memset (&colorAttachment, 0, sizeof (colorAttachment));
		colorAttachment.colorWriteMask = (VkColorComponentFlags)colorWriteMask;
		colorAttachment.blendEnable = blend ? VK_TRUE : VK_FALSE;
		colorAttachment.srcColorBlendFactor = (VkBlendFactor)srcColorBlendFactor;
		colorAttachment.dstColorBlendFactor = (VkBlendFactor)dstColorBlendFactor;
		colorAttachment.colorBlendOp = (VkBlendOp)colorBlendOp;
		colorAttachment.srcAlphaBlendFactor = (VkBlendFactor)srcAlphaBlendFactor;
		colorAttachment.dstAlphaBlendFactor = (VkBlendFactor)dstAlphaBlendFactor;
		colorAttachment.alphaBlendOp = (VkBlendOp)alphaBlendOp;

		VkPipelineColorBlendStateCreateInfo colorBlend;
		memset (&colorBlend, 0, sizeof (colorBlend));
		colorBlend.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
		colorBlend.attachmentCount = 1;
		colorBlend.pAttachments = &colorAttachment;

		std::vector<VkDynamicState> dynamicStates;
		if (dynamicStateFlags & 0x1) dynamicStates.push_back (VK_DYNAMIC_STATE_VIEWPORT);
		if (dynamicStateFlags & 0x2) dynamicStates.push_back (VK_DYNAMIC_STATE_SCISSOR);
		VkPipelineDynamicStateCreateInfo dynamicState;
		memset (&dynamicState, 0, sizeof (dynamicState));
		dynamicState.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
		dynamicState.dynamicStateCount = (uint32_t)dynamicStates.size ();
		dynamicState.pDynamicStates = dynamicStates.empty () ? 0 : dynamicStates.data ();

		VkGraphicsPipelineCreateInfo createInfo;
		memset (&createInfo, 0, sizeof (createInfo));
		createInfo.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
		createInfo.stageCount = 2;
		createInfo.pStages = stages;
		createInfo.pVertexInputState = &vertexInput;
		createInfo.pInputAssemblyState = &inputAssembly;
		createInfo.pViewportState = &viewportState;
		createInfo.pRasterizationState = &rasterization;
		createInfo.pMultisampleState = &multisample;
		createInfo.pDepthStencilState = &depthStencil;
		createInfo.pColorBlendState = &colorBlend;
		createInfo.pDynamicState = dynamicStates.empty () ? 0 : &dynamicState;
		createInfo.layout = layout;
		createInfo.renderPass = renderPass;
		createInfo.subpass = 0;

		VkPipeline pipeline = VK_NULL_HANDLE;
		VkResult result = vkCreateGraphicsPipelines (device, cache, 1, &createInfo, 0, &pipeline);
		if (result != VK_SUCCESS) {

			lastVKError = "vkCreateGraphicsPipelines failed";
			return VK_NULL_HANDLE;

		}

		lastVKError.clear ();
		return pipeline;

	}

#endif


	value lime_vk_create_graphics_pipeline (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int renderPassHigh,
		int renderPassLow, int layoutHigh, int layoutLow, int vertexShaderHigh, int vertexShaderLow, int fragmentShaderHigh, int fragmentShaderLow,
		value state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkPipeline pipeline = CreateManagedVulkanGraphicsPipeline (targetWindow, instance, device,
			(VkRenderPass)(uintptr_t)CombineVulkanHandle (renderPassHigh, renderPassLow),
			(VkPipelineLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow),
			(VkShaderModule)(uintptr_t)CombineVulkanHandle (vertexShaderHigh, vertexShaderLow),
			(VkShaderModule)(uintptr_t)CombineVulkanHandle (fragmentShaderHigh, fragmentShaderLow),
			GetVulkanIntVector (state));
		return pipeline ? CreateVulkanHandleValue ((uint64_t)(uintptr_t)pipeline) : alloc_null ();
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();
#endif

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_graphics_pipeline) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int renderPassHigh, int renderPassLow, int layoutHigh, int layoutLow, int vertexShaderHigh, int vertexShaderLow,
		int fragmentShaderHigh, int fragmentShaderLow, hl_varray* state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkPipeline pipeline = CreateManagedVulkanGraphicsPipeline (targetWindow, instance, device,
			(VkRenderPass)(uintptr_t)CombineVulkanHandle (renderPassHigh, renderPassLow),
			(VkPipelineLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow),
			(VkShaderModule)(uintptr_t)CombineVulkanHandle (vertexShaderHigh, vertexShaderLow),
			(VkShaderModule)(uintptr_t)CombineVulkanHandle (fragmentShaderHigh, fragmentShaderLow),
			GetHLVulkanIntVector (state));
		return pipeline ? HLCreateVulkanHandleValue ((uint64_t)(uintptr_t)pipeline) : 0;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return 0;
#endif

	}


	void lime_vk_destroy_pipeline (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int pipelineHigh, int pipelineLow) {

#ifdef LIME_VULKAN
		if (pipelineHigh == 0 && pipelineLow == 0) return;
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkPipeline pipeline = (VkPipeline)(uintptr_t)CombineVulkanHandle (pipelineHigh, pipelineLow);
		PFN_vkDestroyPipeline vkDestroyPipeline = (PFN_vkDestroyPipeline)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroyPipeline");
		if (vkDestroyPipeline) {

			vkDestroyPipeline (device, pipeline, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_pipeline) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int pipelineHigh, int pipelineLow) {

#ifdef LIME_VULKAN
		if (pipelineHigh == 0 && pipelineLow == 0) return;
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkPipeline pipeline = (VkPipeline)(uintptr_t)CombineVulkanHandle (pipelineHigh, pipelineLow);
		PFN_vkDestroyPipeline vkDestroyPipeline = (PFN_vkDestroyPipeline)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkDestroyPipeline");
		if (vkDestroyPipeline) {

			vkDestroyPipeline (device, pipeline, 0);
			lastVKError.clear ();

		}
#else
		lastVKError = "Lime was built without lime-vulkan support";
#endif

	}

	HL_PRIM void HL_NAME(hl_vulkan_renderer_destroy) (HL_CFFIPointer* handle) {

		if (!handle || !handle->ptr) return;
		VulkanRenderer* renderer = (VulkanRenderer*)handle->ptr;
		handle->ptr = 0;
		delete renderer;

	}


	bool lime_vk_queue_submit_synced (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int queueHigh,
		int queueLow, int commandBufferHigh, int commandBufferLow, value state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkQueue queue = (VkQueue)(uintptr_t)CombineVulkanHandle (queueHigh, queueLow);
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetVulkanIntVector (state);
		if (packed.size () < 7) return false;

		VkSemaphore waitSemaphore = (VkSemaphore)(uintptr_t)CombineVulkanHandle (packed[0], packed[1]);
		VkPipelineStageFlags waitStage = (VkPipelineStageFlags)packed[2];
		VkSemaphore signalSemaphore = (VkSemaphore)(uintptr_t)CombineVulkanHandle (packed[3], packed[4]);
		VkFence fence = (VkFence)(uintptr_t)CombineVulkanHandle (packed[5], packed[6]);
		PFN_vkQueueSubmit vkQueueSubmit = (PFN_vkQueueSubmit)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkQueueSubmit");
		if (!vkQueueSubmit || !queue || !commandBuffer) return false;

		VkSubmitInfo submitInfo;
		memset (&submitInfo, 0, sizeof (submitInfo));
		submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
		submitInfo.waitSemaphoreCount = waitSemaphore ? 1 : 0;
		submitInfo.pWaitSemaphores = waitSemaphore ? &waitSemaphore : 0;
		submitInfo.pWaitDstStageMask = waitSemaphore ? &waitStage : 0;
		submitInfo.commandBufferCount = 1;
		submitInfo.pCommandBuffers = &commandBuffer;
		submitInfo.signalSemaphoreCount = signalSemaphore ? 1 : 0;
		submitInfo.pSignalSemaphores = signalSemaphore ? &signalSemaphore : 0;

		VkResult result = vkQueueSubmit (queue, 1, &submitInfo, fence);
		if (result != VK_SUCCESS) {

			char error[64];
			::snprintf (error, sizeof (error), "vkQueueSubmit failed: %d", (int)result);
			lastVKError = error;
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_queue_submit_synced) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int queueHigh, int queueLow, int commandBufferHigh, int commandBufferLow, hl_varray* state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		VkQueue queue = (VkQueue)(uintptr_t)CombineVulkanHandle (queueHigh, queueLow);
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetHLVulkanIntVector (state);
		if (packed.size () < 7) return false;

		VkSemaphore waitSemaphore = (VkSemaphore)(uintptr_t)CombineVulkanHandle (packed[0], packed[1]);
		VkPipelineStageFlags waitStage = (VkPipelineStageFlags)packed[2];
		VkSemaphore signalSemaphore = (VkSemaphore)(uintptr_t)CombineVulkanHandle (packed[3], packed[4]);
		VkFence fence = (VkFence)(uintptr_t)CombineVulkanHandle (packed[5], packed[6]);
		PFN_vkQueueSubmit vkQueueSubmit = (PFN_vkQueueSubmit)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkQueueSubmit");
		if (!vkQueueSubmit || !queue || !commandBuffer) return false;

		VkSubmitInfo submitInfo;
		memset (&submitInfo, 0, sizeof (submitInfo));
		submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
		submitInfo.waitSemaphoreCount = waitSemaphore ? 1 : 0;
		submitInfo.pWaitSemaphores = waitSemaphore ? &waitSemaphore : 0;
		submitInfo.pWaitDstStageMask = waitSemaphore ? &waitStage : 0;
		submitInfo.commandBufferCount = 1;
		submitInfo.pCommandBuffers = &commandBuffer;
		submitInfo.signalSemaphoreCount = signalSemaphore ? 1 : 0;
		submitInfo.pSignalSemaphores = signalSemaphore ? &signalSemaphore : 0;

		VkResult result = vkQueueSubmit (queue, 1, &submitInfo, fence);
		if (result != VK_SUCCESS) {

			char error[64];
			::snprintf (error, sizeof (error), "vkQueueSubmit failed: %d", (int)result);
			lastVKError = error;
			return false;

		}

		lastVKError.clear ();
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_begin_render_pass (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int renderPassHigh, int renderPassLow, int framebufferHigh, int framebufferLow, value state, value clear) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBeginRenderPass vkCmdBeginRenderPass = (PFN_vkCmdBeginRenderPass)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCmdBeginRenderPass");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetVulkanIntVector (state);
		std::vector<double> clearValues = GetVulkanDoubleVector (clear);
		if (!vkCmdBeginRenderPass || !commandBuffer || packed.size () < 5 || clearValues.size () < 5) return false;
		uint32_t clearValueCount = packed.size () > 5 ? (uint32_t)packed[5] : 2;
		if (clearValueCount < 1) clearValueCount = 1;
		if (clearValueCount > 2) clearValueCount = 2;

		VkClearValue clears[2];
		memset (clears, 0, sizeof (clears));
		clears[0].color.float32[0] = (float)clearValues[0];
		clears[0].color.float32[1] = (float)clearValues[1];
		clears[0].color.float32[2] = (float)clearValues[2];
		clears[0].color.float32[3] = (float)clearValues[3];
		clears[1].depthStencil.depth = (float)clearValues[4];
		clears[1].depthStencil.stencil = (uint32_t)packed[4];

		VkRenderPassBeginInfo beginInfo;
		memset (&beginInfo, 0, sizeof (beginInfo));
		beginInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
		beginInfo.renderPass = (VkRenderPass)(uintptr_t)CombineVulkanHandle (renderPassHigh, renderPassLow);
		beginInfo.framebuffer = (VkFramebuffer)(uintptr_t)CombineVulkanHandle (framebufferHigh, framebufferLow);
		beginInfo.renderArea.offset.x = packed[0];
		beginInfo.renderArea.offset.y = packed[1];
		beginInfo.renderArea.extent.width = (uint32_t)packed[2];
		beginInfo.renderArea.extent.height = (uint32_t)packed[3];
		beginInfo.clearValueCount = clearValueCount;
		beginInfo.pClearValues = clears;

		vkCmdBeginRenderPass (commandBuffer, &beginInfo, VK_SUBPASS_CONTENTS_INLINE);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_begin_render_pass) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int renderPassHigh, int renderPassLow, int framebufferHigh, int framebufferLow,
		hl_varray* state, hl_varray* clear) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBeginRenderPass vkCmdBeginRenderPass = (PFN_vkCmdBeginRenderPass)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCmdBeginRenderPass");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetHLVulkanIntVector (state);
		std::vector<double> clearValues = GetHLVulkanDoubleVector (clear);
		if (!vkCmdBeginRenderPass || !commandBuffer || packed.size () < 5 || clearValues.size () < 5) return false;
		uint32_t clearValueCount = packed.size () > 5 ? (uint32_t)packed[5] : 2;
		if (clearValueCount < 1) clearValueCount = 1;
		if (clearValueCount > 2) clearValueCount = 2;

		VkClearValue clears[2];
		memset (clears, 0, sizeof (clears));
		clears[0].color.float32[0] = (float)clearValues[0];
		clears[0].color.float32[1] = (float)clearValues[1];
		clears[0].color.float32[2] = (float)clearValues[2];
		clears[0].color.float32[3] = (float)clearValues[3];
		clears[1].depthStencil.depth = (float)clearValues[4];
		clears[1].depthStencil.stencil = (uint32_t)packed[4];

		VkRenderPassBeginInfo beginInfo;
		memset (&beginInfo, 0, sizeof (beginInfo));
		beginInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
		beginInfo.renderPass = (VkRenderPass)(uintptr_t)CombineVulkanHandle (renderPassHigh, renderPassLow);
		beginInfo.framebuffer = (VkFramebuffer)(uintptr_t)CombineVulkanHandle (framebufferHigh, framebufferLow);
		beginInfo.renderArea.offset.x = packed[0];
		beginInfo.renderArea.offset.y = packed[1];
		beginInfo.renderArea.extent.width = (uint32_t)packed[2];
		beginInfo.renderArea.extent.height = (uint32_t)packed[3];
		beginInfo.clearValueCount = clearValueCount;
		beginInfo.pClearValues = clears;

		vkCmdBeginRenderPass (commandBuffer, &beginInfo, VK_SUBPASS_CONTENTS_INLINE);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_end_render_pass (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdEndRenderPass vkCmdEndRenderPass = (PFN_vkCmdEndRenderPass)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCmdEndRenderPass");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		if (!vkCmdEndRenderPass || !commandBuffer) return false;
		vkCmdEndRenderPass (commandBuffer);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_end_render_pass) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdEndRenderPass vkCmdEndRenderPass = (PFN_vkCmdEndRenderPass)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCmdEndRenderPass");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		if (!vkCmdEndRenderPass || !commandBuffer) return false;
		vkCmdEndRenderPass (commandBuffer);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_bind_pipeline (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int pipelineHigh, int pipelineLow, int bindPoint) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBindPipeline vkCmdBindPipeline = (PFN_vkCmdBindPipeline)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCmdBindPipeline");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkPipeline pipeline = (VkPipeline)(uintptr_t)CombineVulkanHandle (pipelineHigh, pipelineLow);
		if (!vkCmdBindPipeline || !commandBuffer || !pipeline) return false;
		vkCmdBindPipeline (commandBuffer, (VkPipelineBindPoint)bindPoint, pipeline);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_bind_pipeline) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int pipelineHigh, int pipelineLow, int bindPoint) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBindPipeline vkCmdBindPipeline = (PFN_vkCmdBindPipeline)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCmdBindPipeline");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkPipeline pipeline = (VkPipeline)(uintptr_t)CombineVulkanHandle (pipelineHigh, pipelineLow);
		if (!vkCmdBindPipeline || !commandBuffer || !pipeline) return false;
		vkCmdBindPipeline (commandBuffer, (VkPipelineBindPoint)bindPoint, pipeline);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_bind_descriptor_set (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int layoutHigh, int layoutLow, int setHigh, int setLow, int bindPoint, int firstSet) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBindDescriptorSets vkCmdBindDescriptorSets =
			(PFN_vkCmdBindDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdBindDescriptorSets");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkPipelineLayout layout = (VkPipelineLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		VkDescriptorSet descriptorSet = (VkDescriptorSet)(uintptr_t)CombineVulkanHandle (setHigh, setLow);
		if (!vkCmdBindDescriptorSets || !commandBuffer || !layout || !descriptorSet) return false;
		vkCmdBindDescriptorSets (commandBuffer, (VkPipelineBindPoint)bindPoint, layout, (uint32_t)firstSet, 1, &descriptorSet, 0, 0);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_bind_descriptor_set) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int layoutHigh, int layoutLow, int setHigh, int setLow, int bindPoint,
		int firstSet) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBindDescriptorSets vkCmdBindDescriptorSets =
			(PFN_vkCmdBindDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdBindDescriptorSets");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkPipelineLayout layout = (VkPipelineLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		VkDescriptorSet descriptorSet = (VkDescriptorSet)(uintptr_t)CombineVulkanHandle (setHigh, setLow);
		if (!vkCmdBindDescriptorSets || !commandBuffer || !layout || !descriptorSet) return false;
		vkCmdBindDescriptorSets (commandBuffer, (VkPipelineBindPoint)bindPoint, layout, (uint32_t)firstSet, 1, &descriptorSet, 0, 0);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}

	bool lime_vk_cmd_bind_descriptor_set_ex (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int layoutHigh, int layoutLow, int setHigh, int setLow, value state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBindDescriptorSets vkCmdBindDescriptorSets =
			(PFN_vkCmdBindDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdBindDescriptorSets");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkPipelineLayout layout = (VkPipelineLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		VkDescriptorSet descriptorSet = (VkDescriptorSet)(uintptr_t)CombineVulkanHandle (setHigh, setLow);
		std::vector<int> packed = GetVulkanIntVector (state);
		if (!vkCmdBindDescriptorSets || !commandBuffer || !layout || !descriptorSet || packed.size () < 3) return false;

		int dynamicOffsetCount = packed[2];
		if ((int)packed.size () < 3 + dynamicOffsetCount) return false;
		std::vector<uint32_t> dynamicOffsets;
		dynamicOffsets.reserve ((size_t)dynamicOffsetCount);
		for (int i = 0; i < dynamicOffsetCount; ++i) dynamicOffsets.push_back ((uint32_t)packed[3 + i]);

		vkCmdBindDescriptorSets (commandBuffer, (VkPipelineBindPoint)packed[0], layout, (uint32_t)packed[1], 1, &descriptorSet,
			(uint32_t)dynamicOffsets.size (), dynamicOffsets.empty () ? 0 : dynamicOffsets.data ());
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_bind_descriptor_set_ex) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int layoutHigh, int layoutLow, int setHigh, int setLow, hl_varray* state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBindDescriptorSets vkCmdBindDescriptorSets =
			(PFN_vkCmdBindDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdBindDescriptorSets");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkPipelineLayout layout = (VkPipelineLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		VkDescriptorSet descriptorSet = (VkDescriptorSet)(uintptr_t)CombineVulkanHandle (setHigh, setLow);
		std::vector<int> packed = GetHLVulkanIntVector (state);
		if (!vkCmdBindDescriptorSets || !commandBuffer || !layout || !descriptorSet || packed.size () < 3) return false;

		int dynamicOffsetCount = packed[2];
		if ((int)packed.size () < 3 + dynamicOffsetCount) return false;
		std::vector<uint32_t> dynamicOffsets;
		dynamicOffsets.reserve ((size_t)dynamicOffsetCount);
		for (int i = 0; i < dynamicOffsetCount; ++i) dynamicOffsets.push_back ((uint32_t)packed[3 + i]);

		vkCmdBindDescriptorSets (commandBuffer, (VkPipelineBindPoint)packed[0], layout, (uint32_t)packed[1], 1, &descriptorSet,
			(uint32_t)dynamicOffsets.size (), dynamicOffsets.empty () ? 0 : dynamicOffsets.data ());
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_bind_descriptor_set_dynamic_offset (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int layoutHigh, int layoutLow, int setHigh, int setLow, int dynamicOffset, int firstSet,
		int bindPoint) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBindDescriptorSets vkCmdBindDescriptorSets =
			(PFN_vkCmdBindDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdBindDescriptorSets");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkPipelineLayout layout = (VkPipelineLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		VkDescriptorSet descriptorSet = (VkDescriptorSet)(uintptr_t)CombineVulkanHandle (setHigh, setLow);
		uint32_t offset = (uint32_t)dynamicOffset;
		if (!vkCmdBindDescriptorSets || !commandBuffer || !layout || !descriptorSet) return false;
		vkCmdBindDescriptorSets (commandBuffer, (VkPipelineBindPoint)bindPoint, layout, (uint32_t)firstSet, 1, &descriptorSet, 1, &offset);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_bind_descriptor_set_dynamic_offset) (HL_CFFIPointer* window, int instanceHigh, int instanceLow,
		int deviceHigh, int deviceLow, int commandBufferHigh, int commandBufferLow, int layoutHigh, int layoutLow, int setHigh, int setLow,
		int dynamicOffset, int firstSet, int bindPoint) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBindDescriptorSets vkCmdBindDescriptorSets =
			(PFN_vkCmdBindDescriptorSets)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdBindDescriptorSets");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkPipelineLayout layout = (VkPipelineLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		VkDescriptorSet descriptorSet = (VkDescriptorSet)(uintptr_t)CombineVulkanHandle (setHigh, setLow);
		uint32_t offset = (uint32_t)dynamicOffset;
		if (!vkCmdBindDescriptorSets || !commandBuffer || !layout || !descriptorSet) return false;
		vkCmdBindDescriptorSets (commandBuffer, (VkPipelineBindPoint)bindPoint, layout, (uint32_t)firstSet, 1, &descriptorSet, 1, &offset);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	value lime_vulkan_renderer_get_info (value handle) {

		if (val_is_null (handle)) return alloc_string ("");
		VulkanRenderer* renderer = (VulkanRenderer*)val_data (handle);
		return alloc_string (renderer->GetInfo ().c_str ());

	}


	bool lime_vk_cmd_bind_vertex_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int bufferHigh, int bufferLow, int binding, int offsetHigh, int offsetLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBindVertexBuffers vkCmdBindVertexBuffers =
			(PFN_vkCmdBindVertexBuffers)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdBindVertexBuffers");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		VkDeviceSize offset = (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow);
		if (!vkCmdBindVertexBuffers || !commandBuffer || !buffer) return false;
		vkCmdBindVertexBuffers (commandBuffer, (uint32_t)binding, 1, &buffer, &offset);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_bind_vertex_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int binding, int offsetHigh, int offsetLow) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBindVertexBuffers vkCmdBindVertexBuffers =
			(PFN_vkCmdBindVertexBuffers)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdBindVertexBuffers");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		VkDeviceSize offset = (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow);
		if (!vkCmdBindVertexBuffers || !commandBuffer || !buffer) return false;
		vkCmdBindVertexBuffers (commandBuffer, (uint32_t)binding, 1, &buffer, &offset);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_bind_index_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int bufferHigh, int bufferLow, int offsetHigh, int offsetLow, int indexType) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBindIndexBuffer vkCmdBindIndexBuffer =
			(PFN_vkCmdBindIndexBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdBindIndexBuffer");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		if (!vkCmdBindIndexBuffer || !commandBuffer || !buffer) return false;
		vkCmdBindIndexBuffer (commandBuffer, buffer, (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow), (VkIndexType)indexType);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_bind_index_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int offsetHigh, int offsetLow, int indexType) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBindIndexBuffer vkCmdBindIndexBuffer =
			(PFN_vkCmdBindIndexBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdBindIndexBuffer");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		if (!vkCmdBindIndexBuffer || !commandBuffer || !buffer) return false;
		vkCmdBindIndexBuffer (commandBuffer, buffer, (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow), (VkIndexType)indexType);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_set_viewport (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, double x, double y, double width, double height, double minDepth, double maxDepth) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdSetViewport vkCmdSetViewport = (PFN_vkCmdSetViewport)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCmdSetViewport");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		if (!vkCmdSetViewport || !commandBuffer) return false;
		VkViewport viewport;
		viewport.x = (float)x;
		viewport.y = (float)y;
		viewport.width = (float)width;
		viewport.height = (float)height;
		viewport.minDepth = (float)minDepth;
		viewport.maxDepth = (float)maxDepth;
		vkCmdSetViewport (commandBuffer, 0, 1, &viewport);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_set_viewport) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, double x, double y, double width, double height, double minDepth, double maxDepth) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdSetViewport vkCmdSetViewport = (PFN_vkCmdSetViewport)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCmdSetViewport");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		if (!vkCmdSetViewport || !commandBuffer) return false;
		VkViewport viewport;
		viewport.x = (float)x;
		viewport.y = (float)y;
		viewport.width = (float)width;
		viewport.height = (float)height;
		viewport.minDepth = (float)minDepth;
		viewport.maxDepth = (float)maxDepth;
		vkCmdSetViewport (commandBuffer, 0, 1, &viewport);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}

	HL_PRIM vbyte* HL_NAME(hl_vulkan_renderer_get_info) (HL_CFFIPointer* handle) {

		if (!handle || !handle->ptr) return 0;
		VulkanRenderer* renderer = (VulkanRenderer*)handle->ptr;
		return hl_copy_bytes ((const vbyte*)renderer->GetInfo ().c_str (), (int)renderer->GetInfo ().size () + 1);

	}


	bool lime_vk_cmd_set_scissor (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int x, int y, int width, int height) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdSetScissor vkCmdSetScissor = (PFN_vkCmdSetScissor)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdSetScissor");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		if (!vkCmdSetScissor || !commandBuffer) return false;
		VkRect2D scissor;
		scissor.offset.x = x;
		scissor.offset.y = y;
		scissor.extent.width = (uint32_t)width;
		scissor.extent.height = (uint32_t)height;
		vkCmdSetScissor (commandBuffer, 0, 1, &scissor);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_set_scissor) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int x, int y, int width, int height) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdSetScissor vkCmdSetScissor = (PFN_vkCmdSetScissor)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdSetScissor");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		if (!vkCmdSetScissor || !commandBuffer) return false;
		VkRect2D scissor;
		scissor.offset.x = x;
		scissor.offset.y = y;
		scissor.extent.width = (uint32_t)width;
		scissor.extent.height = (uint32_t)height;
		vkCmdSetScissor (commandBuffer, 0, 1, &scissor);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_draw (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int vertexCount, int instanceCount, int firstVertex, int firstInstance) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdDraw vkCmdDraw = (PFN_vkCmdDraw)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdDraw");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		if (!vkCmdDraw || !commandBuffer) return false;
		vkCmdDraw (commandBuffer, (uint32_t)vertexCount, (uint32_t)instanceCount, (uint32_t)firstVertex, (uint32_t)firstInstance);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_draw) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int vertexCount, int instanceCount, int firstVertex, int firstInstance) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdDraw vkCmdDraw = (PFN_vkCmdDraw)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdDraw");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		if (!vkCmdDraw || !commandBuffer) return false;
		vkCmdDraw (commandBuffer, (uint32_t)vertexCount, (uint32_t)instanceCount, (uint32_t)firstVertex, (uint32_t)firstInstance);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_draw_indexed (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int indexCount, int instanceCount, int firstIndex, int vertexOffset, int firstInstance) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdDrawIndexed vkCmdDrawIndexed = (PFN_vkCmdDrawIndexed)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCmdDrawIndexed");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		if (!vkCmdDrawIndexed || !commandBuffer) return false;
		vkCmdDrawIndexed (commandBuffer, (uint32_t)indexCount, (uint32_t)instanceCount, (uint32_t)firstIndex, vertexOffset, (uint32_t)firstInstance);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_draw_indexed) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int indexCount, int instanceCount, int firstIndex, int vertexOffset, int firstInstance) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdDrawIndexed vkCmdDrawIndexed = (PFN_vkCmdDrawIndexed)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCmdDrawIndexed");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		if (!vkCmdDrawIndexed || !commandBuffer) return false;
		vkCmdDrawIndexed (commandBuffer, (uint32_t)indexCount, (uint32_t)instanceCount, (uint32_t)firstIndex, vertexOffset, (uint32_t)firstInstance);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_draw_indirect (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int bufferHigh, int bufferLow, int offsetHigh, int offsetLow, int drawCount, int stride) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdDrawIndirect vkCmdDrawIndirect = (PFN_vkCmdDrawIndirect)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCmdDrawIndirect");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		if (!vkCmdDrawIndirect || !commandBuffer || !buffer) return false;
		vkCmdDrawIndirect (commandBuffer, buffer, (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow), (uint32_t)drawCount,
			(uint32_t)stride);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_draw_indirect) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int offsetHigh, int offsetLow, int drawCount, int stride) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdDrawIndirect vkCmdDrawIndirect = (PFN_vkCmdDrawIndirect)GetManagedVulkanDeviceProc (targetWindow, instance, device,
			"vkCmdDrawIndirect");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		if (!vkCmdDrawIndirect || !commandBuffer || !buffer) return false;
		vkCmdDrawIndirect (commandBuffer, buffer, (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow), (uint32_t)drawCount,
			(uint32_t)stride);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_draw_indexed_indirect (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int offsetHigh, int offsetLow, int drawCount, int stride) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdDrawIndexedIndirect vkCmdDrawIndexedIndirect =
			(PFN_vkCmdDrawIndexedIndirect)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdDrawIndexedIndirect");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		if (!vkCmdDrawIndexedIndirect || !commandBuffer || !buffer) return false;
		vkCmdDrawIndexedIndirect (commandBuffer, buffer, (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow), (uint32_t)drawCount,
			(uint32_t)stride);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_draw_indexed_indirect) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int offsetHigh, int offsetLow, int drawCount,
		int stride) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdDrawIndexedIndirect vkCmdDrawIndexedIndirect =
			(PFN_vkCmdDrawIndexedIndirect)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdDrawIndexedIndirect");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkBuffer buffer = (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow);
		if (!vkCmdDrawIndexedIndirect || !commandBuffer || !buffer) return false;
		vkCmdDrawIndexedIndirect (commandBuffer, buffer, (VkDeviceSize)CombineVulkanHandle (offsetHigh, offsetLow), (uint32_t)drawCount,
			(uint32_t)stride);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}

	value lime_vulkan_renderer_get_last_error () {

		return alloc_string (lastVulkanRendererError.c_str ());

	}


	bool lime_vk_cmd_copy_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int sourceHigh, int sourceLow, int destinationHigh, int destinationLow, value state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdCopyBuffer vkCmdCopyBuffer = (PFN_vkCmdCopyBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdCopyBuffer");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetVulkanIntVector (state);
		if (!vkCmdCopyBuffer || !commandBuffer || packed.size () < 6) return false;

		VkBufferCopy region;
		region.size = (VkDeviceSize)CombineVulkanHandle (packed[0], packed[1]);
		region.srcOffset = (VkDeviceSize)CombineVulkanHandle (packed[2], packed[3]);
		region.dstOffset = (VkDeviceSize)CombineVulkanHandle (packed[4], packed[5]);
		vkCmdCopyBuffer (commandBuffer, (VkBuffer)(uintptr_t)CombineVulkanHandle (sourceHigh, sourceLow),
			(VkBuffer)(uintptr_t)CombineVulkanHandle (destinationHigh, destinationLow), 1, &region);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_copy_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int sourceHigh, int sourceLow, int destinationHigh, int destinationLow, hl_varray* state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdCopyBuffer vkCmdCopyBuffer = (PFN_vkCmdCopyBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdCopyBuffer");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetHLVulkanIntVector (state);
		if (!vkCmdCopyBuffer || !commandBuffer || packed.size () < 6) return false;

		VkBufferCopy region;
		region.size = (VkDeviceSize)CombineVulkanHandle (packed[0], packed[1]);
		region.srcOffset = (VkDeviceSize)CombineVulkanHandle (packed[2], packed[3]);
		region.dstOffset = (VkDeviceSize)CombineVulkanHandle (packed[4], packed[5]);
		vkCmdCopyBuffer (commandBuffer, (VkBuffer)(uintptr_t)CombineVulkanHandle (sourceHigh, sourceLow),
			(VkBuffer)(uintptr_t)CombineVulkanHandle (destinationHigh, destinationLow), 1, &region);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}

	bool lime_vk_cmd_copy_buffer_to_image_region (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int imageHigh, int imageLow, value state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdCopyBufferToImage vkCmdCopyBufferToImage =
			(PFN_vkCmdCopyBufferToImage)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdCopyBufferToImage");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetVulkanIntVector (state);
		if (!vkCmdCopyBufferToImage || !commandBuffer || packed.size () < 15) return false;

		VkBufferImageCopy region;
		memset (&region, 0, sizeof (region));
		region.bufferOffset = (VkDeviceSize)CombineVulkanHandle (packed[4], packed[5]);
		region.bufferRowLength = (uint32_t)packed[6];
		region.bufferImageHeight = (uint32_t)packed[7];
		region.imageSubresource.aspectMask = (VkImageAspectFlags)packed[14];
		region.imageSubresource.mipLevel = (uint32_t)packed[11];
		region.imageSubresource.baseArrayLayer = (uint32_t)packed[12];
		region.imageSubresource.layerCount = (uint32_t)packed[13];
		region.imageOffset.x = packed[8];
		region.imageOffset.y = packed[9];
		region.imageOffset.z = packed[10];
		region.imageExtent.width = (uint32_t)packed[0];
		region.imageExtent.height = (uint32_t)packed[1];
		region.imageExtent.depth = (uint32_t)packed[2];
		vkCmdCopyBufferToImage (commandBuffer, (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow),
			(VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow), (VkImageLayout)packed[3], 1, &region);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_copy_buffer_to_image_region) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int imageHigh, int imageLow, hl_varray* state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdCopyBufferToImage vkCmdCopyBufferToImage =
			(PFN_vkCmdCopyBufferToImage)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdCopyBufferToImage");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetHLVulkanIntVector (state);
		if (!vkCmdCopyBufferToImage || !commandBuffer || packed.size () < 15) return false;

		VkBufferImageCopy region;
		memset (&region, 0, sizeof (region));
		region.bufferOffset = (VkDeviceSize)CombineVulkanHandle (packed[4], packed[5]);
		region.bufferRowLength = (uint32_t)packed[6];
		region.bufferImageHeight = (uint32_t)packed[7];
		region.imageSubresource.aspectMask = (VkImageAspectFlags)packed[14];
		region.imageSubresource.mipLevel = (uint32_t)packed[11];
		region.imageSubresource.baseArrayLayer = (uint32_t)packed[12];
		region.imageSubresource.layerCount = (uint32_t)packed[13];
		region.imageOffset.x = packed[8];
		region.imageOffset.y = packed[9];
		region.imageOffset.z = packed[10];
		region.imageExtent.width = (uint32_t)packed[0];
		region.imageExtent.height = (uint32_t)packed[1];
		region.imageExtent.depth = (uint32_t)packed[2];
		vkCmdCopyBufferToImage (commandBuffer, (VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow),
			(VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow), (VkImageLayout)packed[3], 1, &region);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_copy_image_to_buffer_region (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, int bufferHigh, int bufferLow, value state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdCopyImageToBuffer vkCmdCopyImageToBuffer =
			(PFN_vkCmdCopyImageToBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdCopyImageToBuffer");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetVulkanIntVector (state);
		if (!vkCmdCopyImageToBuffer || !commandBuffer || packed.size () < 15) return false;

		VkBufferImageCopy region;
		memset (&region, 0, sizeof (region));
		region.bufferOffset = (VkDeviceSize)CombineVulkanHandle (packed[4], packed[5]);
		region.bufferRowLength = (uint32_t)packed[6];
		region.bufferImageHeight = (uint32_t)packed[7];
		region.imageSubresource.aspectMask = (VkImageAspectFlags)packed[14];
		region.imageSubresource.mipLevel = (uint32_t)packed[11];
		region.imageSubresource.baseArrayLayer = (uint32_t)packed[12];
		region.imageSubresource.layerCount = (uint32_t)packed[13];
		region.imageOffset.x = packed[8];
		region.imageOffset.y = packed[9];
		region.imageOffset.z = packed[10];
		region.imageExtent.width = (uint32_t)packed[0];
		region.imageExtent.height = (uint32_t)packed[1];
		region.imageExtent.depth = (uint32_t)packed[2];
		vkCmdCopyImageToBuffer (commandBuffer, (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow), (VkImageLayout)packed[3],
			(VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow), 1, &region);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_copy_image_to_buffer_region) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, int bufferHigh, int bufferLow, hl_varray* state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdCopyImageToBuffer vkCmdCopyImageToBuffer =
			(PFN_vkCmdCopyImageToBuffer)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdCopyImageToBuffer");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetHLVulkanIntVector (state);
		if (!vkCmdCopyImageToBuffer || !commandBuffer || packed.size () < 15) return false;

		VkBufferImageCopy region;
		memset (&region, 0, sizeof (region));
		region.bufferOffset = (VkDeviceSize)CombineVulkanHandle (packed[4], packed[5]);
		region.bufferRowLength = (uint32_t)packed[6];
		region.bufferImageHeight = (uint32_t)packed[7];
		region.imageSubresource.aspectMask = (VkImageAspectFlags)packed[14];
		region.imageSubresource.mipLevel = (uint32_t)packed[11];
		region.imageSubresource.baseArrayLayer = (uint32_t)packed[12];
		region.imageSubresource.layerCount = (uint32_t)packed[13];
		region.imageOffset.x = packed[8];
		region.imageOffset.y = packed[9];
		region.imageOffset.z = packed[10];
		region.imageExtent.width = (uint32_t)packed[0];
		region.imageExtent.height = (uint32_t)packed[1];
		region.imageExtent.depth = (uint32_t)packed[2];
		vkCmdCopyImageToBuffer (commandBuffer, (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow), (VkImageLayout)packed[3],
			(VkBuffer)(uintptr_t)CombineVulkanHandle (bufferHigh, bufferLow), 1, &region);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}

	HL_PRIM vbyte* HL_NAME(hl_vulkan_renderer_get_last_error) () {

		return hl_copy_bytes ((const vbyte*)lastVulkanRendererError.c_str (), (int)lastVulkanRendererError.size () + 1);

	}


	bool lime_vk_cmd_pipeline_barrier_image (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, value state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdPipelineBarrier vkCmdPipelineBarrier =
			(PFN_vkCmdPipelineBarrier)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdPipelineBarrier");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetVulkanIntVector (state);
		if (!vkCmdPipelineBarrier || !commandBuffer || packed.size () < 11) return false;

		VkImageMemoryBarrier barrier;
		memset (&barrier, 0, sizeof (barrier));
		barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
		barrier.oldLayout = (VkImageLayout)packed[0];
		barrier.newLayout = (VkImageLayout)packed[1];
		barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
		barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
		barrier.image = (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow);
		barrier.srcAccessMask = (VkAccessFlags)packed[4];
		barrier.dstAccessMask = (VkAccessFlags)packed[5];
		barrier.subresourceRange.aspectMask = (VkImageAspectFlags)packed[6];
		barrier.subresourceRange.baseMipLevel = (uint32_t)packed[7];
		barrier.subresourceRange.levelCount = (uint32_t)packed[8];
		barrier.subresourceRange.baseArrayLayer = (uint32_t)packed[9];
		barrier.subresourceRange.layerCount = (uint32_t)packed[10];

		vkCmdPipelineBarrier (commandBuffer, (VkPipelineStageFlags)packed[2], (VkPipelineStageFlags)packed[3], 0, 0, 0, 0, 0, 1, &barrier);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_pipeline_barrier_image) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, hl_varray* state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdPipelineBarrier vkCmdPipelineBarrier =
			(PFN_vkCmdPipelineBarrier)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdPipelineBarrier");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetHLVulkanIntVector (state);
		if (!vkCmdPipelineBarrier || !commandBuffer || packed.size () < 11) return false;

		VkImageMemoryBarrier barrier;
		memset (&barrier, 0, sizeof (barrier));
		barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
		barrier.oldLayout = (VkImageLayout)packed[0];
		barrier.newLayout = (VkImageLayout)packed[1];
		barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
		barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
		barrier.image = (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow);
		barrier.srcAccessMask = (VkAccessFlags)packed[4];
		barrier.dstAccessMask = (VkAccessFlags)packed[5];
		barrier.subresourceRange.aspectMask = (VkImageAspectFlags)packed[6];
		barrier.subresourceRange.baseMipLevel = (uint32_t)packed[7];
		barrier.subresourceRange.levelCount = (uint32_t)packed[8];
		barrier.subresourceRange.baseArrayLayer = (uint32_t)packed[9];
		barrier.subresourceRange.layerCount = (uint32_t)packed[10];

		vkCmdPipelineBarrier (commandBuffer, (VkPipelineStageFlags)packed[2], (VkPipelineStageFlags)packed[3], 0, 0, 0, 0, 0, 1, &barrier);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_clear_color_image (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int imageHigh, int imageLow, int layout, int aspectMask, value clear) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdClearColorImage vkCmdClearColorImage =
			(PFN_vkCmdClearColorImage)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdClearColorImage");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<double> clearValues = GetVulkanDoubleVector (clear);
		if (!vkCmdClearColorImage || !commandBuffer || clearValues.size () < 4) return false;

		VkClearColorValue color;
		color.float32[0] = (float)clearValues[0];
		color.float32[1] = (float)clearValues[1];
		color.float32[2] = (float)clearValues[2];
		color.float32[3] = (float)clearValues[3];
		VkImageSubresourceRange range;
		memset (&range, 0, sizeof (range));
		range.aspectMask = (VkImageAspectFlags)aspectMask;
		range.levelCount = 1;
		range.layerCount = 1;
		vkCmdClearColorImage (commandBuffer, (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow), (VkImageLayout)layout, &color, 1, &range);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_clear_color_image) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, int layout, int aspectMask, hl_varray* clear) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdClearColorImage vkCmdClearColorImage =
			(PFN_vkCmdClearColorImage)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdClearColorImage");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<double> clearValues = GetHLVulkanDoubleVector (clear);
		if (!vkCmdClearColorImage || !commandBuffer || clearValues.size () < 4) return false;

		VkClearColorValue color;
		color.float32[0] = (float)clearValues[0];
		color.float32[1] = (float)clearValues[1];
		color.float32[2] = (float)clearValues[2];
		color.float32[3] = (float)clearValues[3];
		VkImageSubresourceRange range;
		memset (&range, 0, sizeof (range));
		range.aspectMask = (VkImageAspectFlags)aspectMask;
		range.levelCount = 1;
		range.layerCount = 1;
		vkCmdClearColorImage (commandBuffer, (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow), (VkImageLayout)layout, &color, 1, &range);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_clear_depth_stencil_image (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, value state, value clear) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdClearDepthStencilImage vkCmdClearDepthStencilImage =
			(PFN_vkCmdClearDepthStencilImage)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdClearDepthStencilImage");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetVulkanIntVector (state);
		std::vector<double> clearValues = GetVulkanDoubleVector (clear);
		if (!vkCmdClearDepthStencilImage || !commandBuffer || packed.size () < 7 || clearValues.size () < 1) return false;

		VkClearDepthStencilValue depthStencil;
		depthStencil.depth = (float)clearValues[0];
		depthStencil.stencil = (uint32_t)packed[1];
		VkImageSubresourceRange range;
		memset (&range, 0, sizeof (range));
		range.aspectMask = (VkImageAspectFlags)packed[2];
		range.baseMipLevel = (uint32_t)packed[3];
		range.levelCount = (uint32_t)packed[4];
		range.baseArrayLayer = (uint32_t)packed[5];
		range.layerCount = (uint32_t)packed[6];
		vkCmdClearDepthStencilImage (commandBuffer, (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow), (VkImageLayout)packed[0],
			&depthStencil, 1, &range);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_clear_depth_stencil_image) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, hl_varray* state, hl_varray* clear) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdClearDepthStencilImage vkCmdClearDepthStencilImage =
			(PFN_vkCmdClearDepthStencilImage)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdClearDepthStencilImage");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetHLVulkanIntVector (state);
		std::vector<double> clearValues = GetHLVulkanDoubleVector (clear);
		if (!vkCmdClearDepthStencilImage || !commandBuffer || packed.size () < 7 || clearValues.size () < 1) return false;

		VkClearDepthStencilValue depthStencil;
		depthStencil.depth = (float)clearValues[0];
		depthStencil.stencil = (uint32_t)packed[1];
		VkImageSubresourceRange range;
		memset (&range, 0, sizeof (range));
		range.aspectMask = (VkImageAspectFlags)packed[2];
		range.baseMipLevel = (uint32_t)packed[3];
		range.levelCount = (uint32_t)packed[4];
		range.baseArrayLayer = (uint32_t)packed[5];
		range.layerCount = (uint32_t)packed[6];
		vkCmdClearDepthStencilImage (commandBuffer, (VkImage)(uintptr_t)CombineVulkanHandle (imageHigh, imageLow), (VkImageLayout)packed[0],
			&depthStencil, 1, &range);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_clear_attachments (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, value state, value clear) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdClearAttachments vkCmdClearAttachments =
			(PFN_vkCmdClearAttachments)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdClearAttachments");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetVulkanIntVector (state);
		std::vector<double> clearValues = GetVulkanDoubleVector (clear);
		if (!vkCmdClearAttachments || !commandBuffer || packed.size () < 8 || clearValues.size () < 5) return false;

		VkClearAttachment attachments[2];
		memset (attachments, 0, sizeof (attachments));
		uint32_t attachmentCount = 0;

		if (packed[0] != 0) {

			attachments[attachmentCount].aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
			attachments[attachmentCount].colorAttachment = 0;
			attachments[attachmentCount].clearValue.color.float32[0] = (float)clearValues[0];
			attachments[attachmentCount].clearValue.color.float32[1] = (float)clearValues[1];
			attachments[attachmentCount].clearValue.color.float32[2] = (float)clearValues[2];
			attachments[attachmentCount].clearValue.color.float32[3] = (float)clearValues[3];
			attachmentCount++;

		}

		if (packed[1] != 0 || packed[2] != 0) {

			attachments[attachmentCount].aspectMask = 0;
			if (packed[1] != 0) attachments[attachmentCount].aspectMask |= VK_IMAGE_ASPECT_DEPTH_BIT;
			if (packed[2] != 0) attachments[attachmentCount].aspectMask |= VK_IMAGE_ASPECT_STENCIL_BIT;
			attachments[attachmentCount].clearValue.depthStencil.depth = (float)clearValues[4];
			attachments[attachmentCount].clearValue.depthStencil.stencil = (uint32_t)packed[7];
			attachmentCount++;

		}

		if (attachmentCount == 0) return true;

		VkClearRect rect;
		memset (&rect, 0, sizeof (rect));
		rect.rect.offset.x = packed[3];
		rect.rect.offset.y = packed[4];
		rect.rect.extent.width = (uint32_t)packed[5];
		rect.rect.extent.height = (uint32_t)packed[6];
		rect.baseArrayLayer = 0;
		rect.layerCount = 1;
		vkCmdClearAttachments (commandBuffer, attachmentCount, attachments, 1, &rect);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_clear_attachments) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, hl_varray* state, hl_varray* clear) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdClearAttachments vkCmdClearAttachments =
			(PFN_vkCmdClearAttachments)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdClearAttachments");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetHLVulkanIntVector (state);
		std::vector<double> clearValues = GetHLVulkanDoubleVector (clear);
		if (!vkCmdClearAttachments || !commandBuffer || packed.size () < 8 || clearValues.size () < 5) return false;

		VkClearAttachment attachments[2];
		memset (attachments, 0, sizeof (attachments));
		uint32_t attachmentCount = 0;

		if (packed[0] != 0) {

			attachments[attachmentCount].aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
			attachments[attachmentCount].colorAttachment = 0;
			attachments[attachmentCount].clearValue.color.float32[0] = (float)clearValues[0];
			attachments[attachmentCount].clearValue.color.float32[1] = (float)clearValues[1];
			attachments[attachmentCount].clearValue.color.float32[2] = (float)clearValues[2];
			attachments[attachmentCount].clearValue.color.float32[3] = (float)clearValues[3];
			attachmentCount++;

		}

		if (packed[1] != 0 || packed[2] != 0) {

			attachments[attachmentCount].aspectMask = 0;
			if (packed[1] != 0) attachments[attachmentCount].aspectMask |= VK_IMAGE_ASPECT_DEPTH_BIT;
			if (packed[2] != 0) attachments[attachmentCount].aspectMask |= VK_IMAGE_ASPECT_STENCIL_BIT;
			attachments[attachmentCount].clearValue.depthStencil.depth = (float)clearValues[4];
			attachments[attachmentCount].clearValue.depthStencil.stencil = (uint32_t)packed[7];
			attachmentCount++;

		}

		if (attachmentCount == 0) return true;

		VkClearRect rect;
		memset (&rect, 0, sizeof (rect));
		rect.rect.offset.x = packed[3];
		rect.rect.offset.y = packed[4];
		rect.rect.extent.width = (uint32_t)packed[5];
		rect.rect.extent.height = (uint32_t)packed[6];
		rect.baseArrayLayer = 0;
		rect.layerCount = 1;
		vkCmdClearAttachments (commandBuffer, attachmentCount, attachments, 1, &rect);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_blit_image (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int sourceHigh, int sourceLow, int destinationHigh, int destinationLow, value state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBlitImage vkCmdBlitImage = (PFN_vkCmdBlitImage)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdBlitImage");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetVulkanIntVector (state);
		if (!vkCmdBlitImage || !commandBuffer || packed.size () < 21) return false;

		VkImageBlit blit;
		memset (&blit, 0, sizeof (blit));
		blit.srcOffsets[0].x = packed[0];
		blit.srcOffsets[0].y = packed[1];
		blit.srcOffsets[0].z = packed[2];
		blit.srcOffsets[1].x = packed[3];
		blit.srcOffsets[1].y = packed[4];
		blit.srcOffsets[1].z = packed[5];
		blit.dstOffsets[0].x = packed[6];
		blit.dstOffsets[0].y = packed[7];
		blit.dstOffsets[0].z = packed[8];
		blit.dstOffsets[1].x = packed[9];
		blit.dstOffsets[1].y = packed[10];
		blit.dstOffsets[1].z = packed[11];
		int sourceLayout = packed[12];
		int destinationLayout = packed[13];
		int filter = packed[14];
		blit.srcSubresource.mipLevel = (uint32_t)packed[15];
		blit.dstSubresource.mipLevel = (uint32_t)packed[16];
		blit.srcSubresource.baseArrayLayer = (uint32_t)packed[17];
		blit.dstSubresource.baseArrayLayer = (uint32_t)packed[18];
		blit.srcSubresource.layerCount = (uint32_t)packed[19];
		blit.dstSubresource.layerCount = (uint32_t)packed[19];
		blit.srcSubresource.aspectMask = (VkImageAspectFlags)packed[20];
		blit.dstSubresource.aspectMask = (VkImageAspectFlags)packed[20];
		vkCmdBlitImage (commandBuffer, (VkImage)(uintptr_t)CombineVulkanHandle (sourceHigh, sourceLow), (VkImageLayout)sourceLayout,
			(VkImage)(uintptr_t)CombineVulkanHandle (destinationHigh, destinationLow), (VkImageLayout)destinationLayout, 1, &blit,
			(VkFilter)filter);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_blit_image) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int sourceHigh, int sourceLow, int destinationHigh, int destinationLow, hl_varray* state) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdBlitImage vkCmdBlitImage = (PFN_vkCmdBlitImage)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdBlitImage");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		std::vector<int> packed = GetHLVulkanIntVector (state);
		if (!vkCmdBlitImage || !commandBuffer || packed.size () < 21) return false;

		VkImageBlit blit;
		memset (&blit, 0, sizeof (blit));
		blit.srcOffsets[0].x = packed[0];
		blit.srcOffsets[0].y = packed[1];
		blit.srcOffsets[0].z = packed[2];
		blit.srcOffsets[1].x = packed[3];
		blit.srcOffsets[1].y = packed[4];
		blit.srcOffsets[1].z = packed[5];
		blit.dstOffsets[0].x = packed[6];
		blit.dstOffsets[0].y = packed[7];
		blit.dstOffsets[0].z = packed[8];
		blit.dstOffsets[1].x = packed[9];
		blit.dstOffsets[1].y = packed[10];
		blit.dstOffsets[1].z = packed[11];
		int sourceLayout = packed[12];
		int destinationLayout = packed[13];
		int filter = packed[14];
		blit.srcSubresource.mipLevel = (uint32_t)packed[15];
		blit.dstSubresource.mipLevel = (uint32_t)packed[16];
		blit.srcSubresource.baseArrayLayer = (uint32_t)packed[17];
		blit.dstSubresource.baseArrayLayer = (uint32_t)packed[18];
		blit.srcSubresource.layerCount = (uint32_t)packed[19];
		blit.dstSubresource.layerCount = (uint32_t)packed[19];
		blit.srcSubresource.aspectMask = (VkImageAspectFlags)packed[20];
		blit.dstSubresource.aspectMask = (VkImageAspectFlags)packed[20];
		vkCmdBlitImage (commandBuffer, (VkImage)(uintptr_t)CombineVulkanHandle (sourceHigh, sourceLow), (VkImageLayout)sourceLayout,
			(VkImage)(uintptr_t)CombineVulkanHandle (destinationHigh, destinationLow), (VkImageLayout)destinationLayout, 1, &blit,
			(VkFilter)filter);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vk_cmd_push_constants (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int layoutHigh, int layoutLow, value state, value bytes) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)val_data (window);
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdPushConstants vkCmdPushConstants =
			(PFN_vkCmdPushConstants)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdPushConstants");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkPipelineLayout layout = (VkPipelineLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		std::vector<int> packed = GetVulkanIntVector (state);
		Bytes data (bytes);
		if (!vkCmdPushConstants || !commandBuffer || !layout || !data.b || packed.size () < 4) return false;
		if (packed[2] < 0 || packed[3] < 0 || packed[2] + packed[3] > data.length) return false;

		vkCmdPushConstants (commandBuffer, layout, (VkShaderStageFlags)packed[0], (uint32_t)packed[1], (uint32_t)packed[3], data.b + packed[2]);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_push_constants) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int layoutHigh, int layoutLow, hl_varray* state, Bytes* bytes) {

#ifdef LIME_VULKAN
		Window* targetWindow = (Window*)window->ptr;
		VkInstance instance = (VkInstance)(uintptr_t)CombineVulkanHandle (instanceHigh, instanceLow);
		VkDevice device = (VkDevice)(uintptr_t)CombineVulkanHandle (deviceHigh, deviceLow);
		PFN_vkCmdPushConstants vkCmdPushConstants =
			(PFN_vkCmdPushConstants)GetManagedVulkanDeviceProc (targetWindow, instance, device, "vkCmdPushConstants");
		VkCommandBuffer commandBuffer = (VkCommandBuffer)(uintptr_t)CombineVulkanHandle (commandBufferHigh, commandBufferLow);
		VkPipelineLayout layout = (VkPipelineLayout)(uintptr_t)CombineVulkanHandle (layoutHigh, layoutLow);
		std::vector<int> packed = GetHLVulkanIntVector (state);
		if (!vkCmdPushConstants || !commandBuffer || !layout || !bytes || !bytes->b || packed.size () < 4) return false;
		if (packed[2] < 0 || packed[3] < 0 || packed[2] + packed[3] > bytes->length) return false;

		vkCmdPushConstants (commandBuffer, layout, (VkShaderStageFlags)packed[0], (uint32_t)packed[1], (uint32_t)packed[3], bytes->b + packed[2]);
		return true;
#else
		lastVKError = "Lime was built without lime-vulkan support";
		return false;
#endif

	}


	bool lime_vulkan_renderer_set_overlay (value handle, value bytes, int width, int height, int x, int y) {

		if (val_is_null (handle)) return false;
		VulkanRenderer* renderer = (VulkanRenderer*)val_data (handle);
		Bytes data (bytes);
		bool result = renderer->SetOverlay (data.b, width, height, x, y);
		lastVulkanRendererError = renderer->GetLastError ();
		return result;

	}


	HL_PRIM bool HL_NAME(hl_vulkan_renderer_set_overlay) (HL_CFFIPointer* handle, Bytes* bytes, int width, int height, int x, int y) {

		if (!handle || !handle->ptr) return false;
		VulkanRenderer* renderer = (VulkanRenderer*)handle->ptr;
		bool result = renderer->SetOverlay (bytes ? bytes->b : 0, width, height, x, y);
		lastVulkanRendererError = renderer->GetLastError ();
		return result;

	}


	bool lime_vulkan_renderer_clear_overlay (value handle) {

		if (val_is_null (handle)) return false;
		VulkanRenderer* renderer = (VulkanRenderer*)val_data (handle);
		bool result = renderer->ClearOverlay ();
		lastVulkanRendererError = renderer->GetLastError ();
		return result;

	}


	HL_PRIM bool HL_NAME(hl_vulkan_renderer_clear_overlay) (HL_CFFIPointer* handle) {

		if (!handle || !handle->ptr) return false;
		VulkanRenderer* renderer = (VulkanRenderer*)handle->ptr;
		bool result = renderer->ClearOverlay ();
		lastVulkanRendererError = renderer->GetLastError ();
		return result;

	}


	bool lime_vulkan_renderer_render (value handle, double red, double green, double blue, double alpha) {

		if (val_is_null (handle)) return false;
		VulkanRenderer* renderer = (VulkanRenderer*)val_data (handle);
		bool result = renderer->Render (red, green, blue, alpha);
		lastVulkanRendererError = renderer->GetLastError ();
		return result;

	}


	HL_PRIM bool HL_NAME(hl_vulkan_renderer_render) (HL_CFFIPointer* handle, double red, double green, double blue, double alpha) {

		if (!handle || !handle->ptr) return false;
		VulkanRenderer* renderer = (VulkanRenderer*)handle->ptr;
		bool result = renderer->Render (red, green, blue, alpha);
		lastVulkanRendererError = renderer->GetLastError ();
		return result;

	}


	bool lime_vulkan_renderer_resize (value handle) {

		if (val_is_null (handle)) return false;
		VulkanRenderer* renderer = (VulkanRenderer*)val_data (handle);
		bool result = renderer->Resize ();
		lastVulkanRendererError = renderer->GetLastError ();
		return result;

	}


	HL_PRIM bool HL_NAME(hl_vulkan_renderer_resize) (HL_CFFIPointer* handle) {

		if (!handle || !handle->ptr) return false;
		VulkanRenderer* renderer = (VulkanRenderer*)handle->ptr;
		bool result = renderer->Resize ();
		lastVulkanRendererError = renderer->GetLastError ();
		return result;

	}
#else
	static inline bool LimeVulkanUnavailableBool () {

		lastVKError = "Lime was built without lime-vulkan support";
		return false;

	}


	static inline value LimeVulkanUnavailableValue () {

		lastVKError = "Lime was built without lime-vulkan support";
		return alloc_null ();

	}


	static inline vdynamic* HLLimeVulkanUnavailableValue () {

		lastVKError = "Lime was built without lime-vulkan support";
		return 0;

	}


	static inline void LimeVulkanUnavailableVoid () {

		lastVKError = "Lime was built without lime-vulkan support";

	}


	bool lime_vk_update_descriptor_set_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int setHigh,
		int setLow, int binding, int descriptorType, int bufferHigh, int bufferLow, int offset, int range) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_update_descriptor_set_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int setHigh, int setLow, int binding, int descriptorType, int bufferHigh, int bufferLow, int offset, int range) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_update_descriptor_sets (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, value writes) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_update_descriptor_sets) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, hl_varray* writes) {

		return LimeVulkanUnavailableBool ();

	}


	value lime_vk_create_pipeline_layout (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, value setLayouts,
		int pushConstantStages, int pushConstantSize) {

		return LimeVulkanUnavailableValue ();

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_pipeline_layout) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, hl_varray* setLayouts, int pushConstantStages, int pushConstantSize) {

		return HLLimeVulkanUnavailableValue ();

	}


	void lime_vk_destroy_pipeline_layout (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int layoutHigh,
		int layoutLow) {

		LimeVulkanUnavailableVoid ();

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_pipeline_layout) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int layoutHigh, int layoutLow) {

		LimeVulkanUnavailableVoid ();

	}


	value lime_vk_create_pipeline_cache (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, value bytes, int byteOffset,
		int byteLength) {

		return LimeVulkanUnavailableValue ();

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_pipeline_cache) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, Bytes* bytes, int byteOffset, int byteLength) {

		return HLLimeVulkanUnavailableValue ();

	}


	void lime_vk_destroy_pipeline_cache (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int cacheHigh,
		int cacheLow) {

		LimeVulkanUnavailableVoid ();

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_pipeline_cache) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int cacheHigh, int cacheLow) {

		LimeVulkanUnavailableVoid ();

	}


	bool lime_vk_get_pipeline_cache_data (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int cacheHigh,
		int cacheLow, value bytes) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_get_pipeline_cache_data) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int cacheHigh, int cacheLow, Bytes* bytes) {

		return LimeVulkanUnavailableBool ();

	}


	value lime_vk_create_graphics_pipeline (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int renderPassHigh,
		int renderPassLow, int layoutHigh, int layoutLow, int vertexShaderHigh, int vertexShaderLow, int fragmentShaderHigh, int fragmentShaderLow,
		value state) {

		return LimeVulkanUnavailableValue ();

	}


	HL_PRIM vdynamic* HL_NAME(hl_vk_create_graphics_pipeline) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int renderPassHigh, int renderPassLow, int layoutHigh, int layoutLow, int vertexShaderHigh, int vertexShaderLow,
		int fragmentShaderHigh, int fragmentShaderLow, hl_varray* state) {

		return HLLimeVulkanUnavailableValue ();

	}


	void lime_vk_destroy_pipeline (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int pipelineHigh,
		int pipelineLow) {

		LimeVulkanUnavailableVoid ();

	}


	HL_PRIM void HL_NAME(hl_vk_destroy_pipeline) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int pipelineHigh, int pipelineLow) {

		LimeVulkanUnavailableVoid ();

	}


	bool lime_vk_queue_submit_synced (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int queueHigh,
		int queueLow, int commandBufferHigh, int commandBufferLow, value state) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_queue_submit_synced) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int queueHigh, int queueLow, int commandBufferHigh, int commandBufferLow, hl_varray* state) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_begin_render_pass (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int renderPassHigh, int renderPassLow, int framebufferHigh, int framebufferLow, value state, value clear) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_begin_render_pass) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int renderPassHigh, int renderPassLow, int framebufferHigh, int framebufferLow,
		hl_varray* state, hl_varray* clear) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_end_render_pass (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_end_render_pass) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_bind_pipeline (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int pipelineHigh, int pipelineLow, int bindPoint) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_bind_pipeline) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int pipelineHigh, int pipelineLow, int bindPoint) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_bind_descriptor_set (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int layoutHigh, int layoutLow, int setHigh, int setLow, int bindPoint, int firstSet) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_bind_descriptor_set) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int layoutHigh, int layoutLow, int setHigh, int setLow, int bindPoint,
		int firstSet) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_bind_descriptor_set_ex (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int layoutHigh, int layoutLow, int setHigh, int setLow, value state) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_bind_descriptor_set_ex) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int layoutHigh, int layoutLow, int setHigh, int setLow, hl_varray* state) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_bind_descriptor_set_dynamic_offset (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int layoutHigh, int layoutLow, int setHigh, int setLow, int dynamicOffset, int firstSet,
		int bindPoint) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_bind_descriptor_set_dynamic_offset) (HL_CFFIPointer* window, int instanceHigh, int instanceLow,
		int deviceHigh, int deviceLow, int commandBufferHigh, int commandBufferLow, int layoutHigh, int layoutLow, int setHigh, int setLow,
		int dynamicOffset, int firstSet, int bindPoint) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_bind_vertex_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int bufferHigh, int bufferLow, int binding, int offsetHigh, int offsetLow) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_bind_vertex_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int binding, int offsetHigh, int offsetLow) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_bind_index_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int bufferHigh, int bufferLow, int offsetHigh, int offsetLow, int indexType) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_bind_index_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int offsetHigh, int offsetLow, int indexType) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_set_viewport (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, double x, double y, double width, double height, double minDepth, double maxDepth) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_set_viewport) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, double x, double y, double width, double height, double minDepth, double maxDepth) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_set_scissor (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int x, int y, int width, int height) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_set_scissor) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int x, int y, int width, int height) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_draw (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int vertexCount, int instanceCount, int firstVertex, int firstInstance) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_draw) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int vertexCount, int instanceCount, int firstVertex, int firstInstance) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_draw_indexed (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int indexCount, int instanceCount, int firstIndex, int vertexOffset, int firstInstance) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_draw_indexed) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int indexCount, int instanceCount, int firstIndex, int vertexOffset, int firstInstance) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_draw_indirect (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int bufferHigh, int bufferLow, int offsetHigh, int offsetLow, int drawCount, int stride) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_draw_indirect) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int offsetHigh, int offsetLow, int drawCount, int stride) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_draw_indexed_indirect (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int offsetHigh, int offsetLow, int drawCount, int stride) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_draw_indexed_indirect) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int offsetHigh, int offsetLow, int drawCount,
		int stride) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_copy_buffer (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int sourceHigh, int sourceLow, int destinationHigh, int destinationLow, value state) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_copy_buffer) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int sourceHigh, int sourceLow, int destinationHigh, int destinationLow, hl_varray* state) {

		return LimeVulkanUnavailableBool ();

	}

	bool lime_vk_cmd_copy_buffer_to_image_region (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int imageHigh, int imageLow, value state) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_copy_buffer_to_image_region) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int bufferHigh, int bufferLow, int imageHigh, int imageLow, hl_varray* state) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_copy_image_to_buffer_region (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, int bufferHigh, int bufferLow, value state) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_copy_image_to_buffer_region) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, int bufferHigh, int bufferLow, hl_varray* state) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_pipeline_barrier_image (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, value state) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_pipeline_barrier_image) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, hl_varray* state) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_clear_color_image (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int imageHigh, int imageLow, int layout, int aspectMask, value clear) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_clear_color_image) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, int layout, int aspectMask, hl_varray* clear) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_clear_depth_stencil_image (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, value state, value clear) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_clear_depth_stencil_image) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, int imageHigh, int imageLow, hl_varray* state, hl_varray* clear) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_clear_attachments (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, value state, value clear) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_clear_attachments) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh,
		int deviceLow, int commandBufferHigh, int commandBufferLow, hl_varray* state, hl_varray* clear) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_blit_image (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int sourceHigh, int sourceLow, int destinationHigh, int destinationLow, value state) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_blit_image) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int sourceHigh, int sourceLow, int destinationHigh, int destinationLow, hl_varray* state) {

		return LimeVulkanUnavailableBool ();

	}


	bool lime_vk_cmd_push_constants (value window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow, int commandBufferHigh,
		int commandBufferLow, int layoutHigh, int layoutLow, value state, value bytes) {

		return LimeVulkanUnavailableBool ();

	}


	HL_PRIM bool HL_NAME(hl_vk_cmd_push_constants) (HL_CFFIPointer* window, int instanceHigh, int instanceLow, int deviceHigh, int deviceLow,
		int commandBufferHigh, int commandBufferLow, int layoutHigh, int layoutLow, hl_varray* state, Bytes* bytes) {

		return LimeVulkanUnavailableBool ();

	}


	value lime_vulkan_renderer_create (value window, HxString applicationName) {

		lastVulkanRendererError = "Lime was built without lime-vulkan support";
		return alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_vulkan_renderer_create) (HL_CFFIPointer* window, hl_vstring* applicationName) {

		lastVulkanRendererError = "Lime was built without lime-vulkan support";
		return 0;

	}


	void lime_vulkan_renderer_destroy (value handle) {}


	HL_PRIM void HL_NAME(hl_vulkan_renderer_destroy) (HL_CFFIPointer* handle) {}


	value lime_vulkan_renderer_get_info (value handle) {

		return alloc_string ("");

	}


	HL_PRIM vbyte* HL_NAME(hl_vulkan_renderer_get_info) (HL_CFFIPointer* handle) {

		return hl_copy_bytes ((const vbyte*)"", 1);

	}


	value lime_vulkan_renderer_get_last_error () {

		return alloc_string (lastVulkanRendererError.c_str ());

	}


	HL_PRIM vbyte* HL_NAME(hl_vulkan_renderer_get_last_error) () {

		return hl_copy_bytes ((const vbyte*)lastVulkanRendererError.c_str (), (int)lastVulkanRendererError.size () + 1);

	}


	bool lime_vulkan_renderer_set_overlay (value handle, value bytes, int width, int height, int x, int y) {

		lastVulkanRendererError = "Lime was built without lime-vulkan support";
		return false;

	}


	HL_PRIM bool HL_NAME(hl_vulkan_renderer_set_overlay) (HL_CFFIPointer* handle, Bytes* bytes, int width, int height, int x, int y) {

		lastVulkanRendererError = "Lime was built without lime-vulkan support";
		return false;

	}


	bool lime_vulkan_renderer_clear_overlay (value handle) {

		lastVulkanRendererError = "Lime was built without lime-vulkan support";
		return false;

	}


	HL_PRIM bool HL_NAME(hl_vulkan_renderer_clear_overlay) (HL_CFFIPointer* handle) {

		lastVulkanRendererError = "Lime was built without lime-vulkan support";
		return false;

	}


	bool lime_vulkan_renderer_render (value handle, double red, double green, double blue, double alpha) {

		lastVulkanRendererError = "Lime was built without lime-vulkan support";
		return false;

	}


	HL_PRIM bool HL_NAME(hl_vulkan_renderer_render) (HL_CFFIPointer* handle, double red, double green, double blue, double alpha) {

		lastVulkanRendererError = "Lime was built without lime-vulkan support";
		return false;

	}


	bool lime_vulkan_renderer_resize (value handle) {

		lastVulkanRendererError = "Lime was built without lime-vulkan support";
		return false;

	}


	HL_PRIM bool HL_NAME(hl_vulkan_renderer_resize) (HL_CFFIPointer* handle) {

		lastVulkanRendererError = "Lime was built without lime-vulkan support";
		return false;

	}
#endif


	int lime_window_get_display (value window) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetDisplay ();

	}


	HL_PRIM int HL_NAME(hl_window_get_display) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetDisplay ();

	}


	value lime_window_get_display_mode (value window) {

		Window* targetWindow = (Window*)val_data (window);
		DisplayMode displayMode;
		targetWindow->GetDisplayMode (&displayMode);
		return (value)displayMode.Value ();

	}


	HL_PRIM void HL_NAME(hl_window_get_display_mode) (HL_CFFIPointer* window, DisplayMode* result) {

		Window* targetWindow = (Window*)window->ptr;
		DisplayMode displayMode;
		targetWindow->GetDisplayMode (&displayMode);
		result->CopyFrom(&displayMode);

	}


	int lime_window_get_height (value window) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetHeight ();

	}


	HL_PRIM int HL_NAME(hl_window_get_height) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetHeight ();

	}


	int32_t lime_window_get_id (value window) {

		Window* targetWindow = (Window*)val_data (window);
		return (int32_t)targetWindow->GetID ();

	}


	HL_PRIM int32_t HL_NAME(hl_window_get_id) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return (int32_t)targetWindow->GetID ();

	}


	bool lime_window_get_mouse_lock (value window) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetMouseLock ();

	}


	HL_PRIM bool HL_NAME(hl_window_get_mouse_lock) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetMouseLock ();

	}


	double lime_window_get_opacity (value window) {

		Window* targetWindow = (Window*)val_data (window);
		return (float)targetWindow->GetOpacity ();

	}


	HL_PRIM double HL_NAME(hl_window_get_opacity) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return (float)targetWindow->GetOpacity ();

	}


	double lime_window_get_scale (value window) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetScale ();

	}


	HL_PRIM double HL_NAME(hl_window_get_scale) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetScale ();

	}


	bool lime_window_get_text_input_enabled (value window) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetTextInputEnabled ();

	}


	HL_PRIM bool HL_NAME(hl_window_get_text_input_enabled) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetTextInputEnabled ();

	}


	int lime_window_get_width (value window) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetWidth ();

	}


	HL_PRIM int HL_NAME(hl_window_get_width) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetWidth ();

	}


	int lime_window_get_x (value window) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetX ();

	}


	HL_PRIM int HL_NAME(hl_window_get_x) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetX ();

	}


	int lime_window_get_y (value window) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->GetY ();

	}


	HL_PRIM int HL_NAME(hl_window_get_y) (HL_CFFIPointer* window) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->GetY ();

	}


	void lime_window_move (value window, int x, int y) {

		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Move (x, y);

	}


	HL_PRIM void HL_NAME(hl_window_move) (HL_CFFIPointer* window, int x, int y) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->Move (x, y);

	}


	value lime_window_read_pixels (value window, value rect, value imageBuffer) {

		Window* targetWindow = (Window*)val_data (window);
		ImageBuffer buffer (imageBuffer);

		if (!val_is_null (rect)) {

			Rectangle _rect = Rectangle (rect);
			targetWindow->ReadPixels (&buffer, &_rect);

		} else {

			targetWindow->ReadPixels (&buffer, NULL);

		}

		return buffer.Value (imageBuffer);

	}


	HL_PRIM ImageBuffer* HL_NAME(hl_window_read_pixels) (HL_CFFIPointer* window, Rectangle* rect, ImageBuffer* imageBuffer) {

		Window* targetWindow = (Window*)window->ptr;

		if (rect) {

			targetWindow->ReadPixels (imageBuffer, rect);

		} else {

			targetWindow->ReadPixels (imageBuffer, NULL);

		}

		return imageBuffer;

	}


	void lime_window_resize (value window, int width, int height) {

		Window* targetWindow = (Window*)val_data (window);
		targetWindow->Resize (width, height);

	}


	HL_PRIM void HL_NAME(hl_window_resize) (HL_CFFIPointer* window, int width, int height) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->Resize (width, height);

	}


	void lime_window_set_minimum_size (value window, int width, int height) {

		Window* targetWindow = (Window*)val_data (window);
		targetWindow->SetMinimumSize (width, height);

	}


	HL_PRIM void HL_NAME(hl_window_set_minimum_size) (HL_CFFIPointer* window, int width, int height) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->SetMinimumSize (width, height);

	}


	void lime_window_set_maximum_size (value window, int width, int height) {

		Window* targetWindow = (Window*)val_data (window);
		targetWindow->SetMaximumSize (width, height);

	}


	HL_PRIM void HL_NAME(hl_window_set_maximum_size) (HL_CFFIPointer* window, int width, int height) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->SetMaximumSize (width, height);

	}


	bool lime_window_set_borderless (value window, bool borderless) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetBorderless (borderless);

	}


	HL_PRIM bool HL_NAME(hl_window_set_borderless) (HL_CFFIPointer* window, bool borderless) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->SetBorderless (borderless);

	}


	void lime_window_set_cursor (value window, int cursor) {

		Window* targetWindow = (Window*)val_data (window);
		targetWindow->SetCursor ((Cursor)cursor);

	}


	HL_PRIM void HL_NAME(hl_window_set_cursor) (HL_CFFIPointer* window, int cursor) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->SetCursor ((Cursor)cursor);

	}


	value lime_window_set_display_mode (value window, value displayMode) {

		Window* targetWindow = (Window*)val_data (window);
		DisplayMode _displayMode (displayMode);
		targetWindow->SetDisplayMode (&_displayMode);
		targetWindow->GetDisplayMode (&_displayMode);
		return (value)_displayMode.Value ();

	}


	HL_PRIM void HL_NAME(hl_window_set_display_mode) (HL_CFFIPointer* window, DisplayMode* displayMode, DisplayMode* result) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->SetDisplayMode (displayMode);
		targetWindow->GetDisplayMode (displayMode);
		result->CopyFrom(displayMode);

	}


	bool lime_window_set_fullscreen (value window, bool fullscreen) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetFullscreen (fullscreen);

	}


	HL_PRIM bool HL_NAME(hl_window_set_fullscreen) (HL_CFFIPointer* window, bool fullscreen) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->SetFullscreen (fullscreen);

	}


	void lime_window_set_icon (value window, value buffer) {

		Window* targetWindow = (Window*)val_data (window);
		ImageBuffer imageBuffer = ImageBuffer (buffer);
		targetWindow->SetIcon (&imageBuffer);

	}


	HL_PRIM void HL_NAME(hl_window_set_icon) (HL_CFFIPointer* window, ImageBuffer* buffer) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->SetIcon (buffer);

	}


	bool lime_window_set_maximized (value window, bool maximized) {

		Window* targetWindow = (Window*)val_data(window);
		return targetWindow->SetMaximized (maximized);

	}


	HL_PRIM bool HL_NAME(hl_window_set_maximized) (HL_CFFIPointer* window, bool maximized) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->SetMaximized (maximized);

	}


	bool lime_window_set_minimized (value window, bool minimized) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetMinimized (minimized);

	}


	HL_PRIM bool HL_NAME(hl_window_set_minimized) (HL_CFFIPointer* window, bool minimized) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->SetMinimized (minimized);

	}


	void lime_window_set_mouse_lock (value window, bool mouseLock) {

		Window* targetWindow = (Window*)val_data (window);
		targetWindow->SetMouseLock (mouseLock);

	}


	HL_PRIM void HL_NAME(hl_window_set_mouse_lock) (HL_CFFIPointer* window, bool mouseLock) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->SetMouseLock (mouseLock);

	}


	void lime_window_set_opacity (value window, double opacity) {

		Window* targetWindow = (Window*)val_data (window);
		targetWindow->SetOpacity ((float)opacity);

	}


	HL_PRIM void HL_NAME(hl_window_set_opacity) (HL_CFFIPointer* window, double opacity) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->SetOpacity ((float)opacity);

	}


	bool lime_window_set_resizable (value window, bool resizable) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetResizable (resizable);

	}


	HL_PRIM bool HL_NAME(hl_window_set_resizable) (HL_CFFIPointer* window, bool resizable) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->SetResizable (resizable);

	}


	void lime_window_set_text_input_enabled (value window, bool enabled) {

		Window* targetWindow = (Window*)val_data (window);
		targetWindow->SetTextInputEnabled (enabled);

	}


	HL_PRIM void HL_NAME(hl_window_set_text_input_enabled) (HL_CFFIPointer* window, bool enabled) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->SetTextInputEnabled (enabled);

	}


	void lime_window_set_text_input_rect (value window, value rect) {

		Window* targetWindow = (Window*)val_data (window);
		Rectangle _rect = Rectangle (rect);
		targetWindow->SetTextInputRect (&_rect);

	}


	HL_PRIM void HL_NAME(hl_window_set_text_input_rect) (HL_CFFIPointer* window, Rectangle* rect) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->SetTextInputRect (rect);

	}


	value lime_window_set_title (value window, HxString title) {

		Window* targetWindow = (Window*)val_data (window);
		const char* titleUtf8 = hxs_utf8 (title, nullptr);
		const char* result = targetWindow->SetTitle (titleUtf8);

		if (result) {

			value _result = alloc_string (result);

			if (result != titleUtf8) {

				free ((char*) result);

			}

			return _result;

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM hl_vstring* HL_NAME(hl_window_set_title) (HL_CFFIPointer* window, hl_vstring* title) {

		Window* targetWindow = (Window*)window->ptr;
		const char* result = targetWindow->SetTitle ((char*)hl_to_utf8 ((const uchar*)title->bytes));

		if (result) {

			return title;

		} else {

			return 0;

		}

	}


	bool lime_window_set_visible (value window, bool visible) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetVisible (visible);

	}


	HL_PRIM bool HL_NAME(hl_window_set_visible) (HL_CFFIPointer* window, bool visible) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->SetVisible (visible);

	}


	bool lime_window_set_always_on_top (value window, bool alwaysOnTop) {

		Window* targetWindow = (Window*)val_data (window);
		return targetWindow->SetAlwaysOnTop(alwaysOnTop);

	}


	HL_PRIM bool HL_NAME(hl_window_set_always_on_top) (HL_CFFIPointer* window, bool alwaysOnTop) {

		Window* targetWindow = (Window*)window->ptr;
		return targetWindow->SetAlwaysOnTop (alwaysOnTop);

	}


	void lime_window_warp_mouse (value window, int x, int y) {

		Window* targetWindow = (Window*)val_data (window);
		targetWindow->WarpMouse (x, y);

	}


	HL_PRIM void HL_NAME(hl_window_warp_mouse) (HL_CFFIPointer* window, int x, int y) {

		Window* targetWindow = (Window*)window->ptr;
		targetWindow->WarpMouse (x, y);

	}


	value lime_zlib_compress (value buffer, value bytes) {

		#ifdef LIME_ZLIB
		Bytes data (buffer);
		Bytes result (bytes);

		Zlib::Compress (ZLIB, &data, &result);

		return result.Value (bytes);
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM Bytes* HL_NAME(hl_zlib_compress) (Bytes* buffer, Bytes* bytes) {

		#ifdef LIME_ZLIB
		Zlib::Compress (ZLIB, buffer, bytes);
		return bytes;
		#else
		return 0;
		#endif

	}


	value lime_zlib_decompress (value buffer, value bytes) {

		#ifdef LIME_ZLIB
		Bytes data (buffer);
		Bytes result (bytes);

		Zlib::Decompress (ZLIB, &data, &result);

		return result.Value (bytes);
		#else
		return alloc_null ();
		#endif

	}


	HL_PRIM Bytes* HL_NAME(hl_zlib_decompress) (Bytes* buffer, Bytes* bytes) {

		#ifdef LIME_ZLIB
		Zlib::Decompress (ZLIB, buffer, bytes);
		return bytes;
		#else
		return 0;
		#endif

	}


	DEFINE_PRIME0 (lime_application_create);
	DEFINE_PRIME2v (lime_application_event_manager_register);
	DEFINE_PRIME1 (lime_application_exec);
	DEFINE_PRIME1v (lime_application_init);
	DEFINE_PRIME1 (lime_application_quit);
	DEFINE_PRIME6v (lime_application_set_main_loop);
	DEFINE_PRIME2v (lime_application_set_frame_rate);
	DEFINE_PRIME2v (lime_application_set_vsync_mode);
	DEFINE_PRIME1 (lime_application_update);
	DEFINE_PRIME2 (lime_audio_load);
	DEFINE_PRIME2 (lime_audio_load_bytes);
	DEFINE_PRIME2 (lime_audio_load_file);
	DEFINE_PRIME3 (lime_bytes_from_data_pointer);
	DEFINE_PRIME1 (lime_bytes_get_data_pointer);
	DEFINE_PRIME2 (lime_bytes_get_data_pointer_offset);
	DEFINE_PRIME2 (lime_bytes_read_file);
	DEFINE_PRIME1 (lime_cffi_get_native_pointer);
	DEFINE_PRIME1 (lime_cffi_set_finalizer);
	DEFINE_PRIME2v (lime_clipboard_event_manager_register);
	DEFINE_PRIME0 (lime_clipboard_get_text);
	DEFINE_PRIME1v (lime_clipboard_set_text);
	DEFINE_PRIME2 (lime_data_pointer_offset);
	DEFINE_PRIME2 (lime_deflate_compress);
	DEFINE_PRIME2 (lime_deflate_decompress);
	DEFINE_PRIME2v (lime_drop_event_manager_register);
	DEFINE_PRIME3 (lime_file_dialog_open_directory);
	DEFINE_PRIME3 (lime_file_dialog_open_file);
	DEFINE_PRIME3 (lime_file_dialog_open_files);
	DEFINE_PRIME3 (lime_file_dialog_save_file);
	DEFINE_PRIME1 (lime_file_watcher_create);
	DEFINE_PRIME3 (lime_file_watcher_add_directory);
	DEFINE_PRIME2v (lime_file_watcher_remove_directory);
	DEFINE_PRIME1v (lime_file_watcher_update);
	DEFINE_PRIME1 (lime_font_get_ascender);
	DEFINE_PRIME1 (lime_font_get_descender);
	DEFINE_PRIME1 (lime_font_get_family_name);
	DEFINE_PRIME2 (lime_font_get_glyph_index);
	DEFINE_PRIME2 (lime_font_get_glyph_indices);
	DEFINE_PRIME2 (lime_font_get_glyph_metrics);
	DEFINE_PRIME1 (lime_font_get_height);
	DEFINE_PRIME1 (lime_font_get_num_glyphs);
	DEFINE_PRIME1 (lime_font_get_underline_position);
	DEFINE_PRIME1 (lime_font_get_underline_thickness);
	DEFINE_PRIME1 (lime_font_get_strikethrough_position);
	DEFINE_PRIME1 (lime_font_get_strikethrough_thickness);
	DEFINE_PRIME1 (lime_font_get_units_per_em);
	DEFINE_PRIME1 (lime_font_is_bold);
	DEFINE_PRIME1 (lime_font_is_italic);
	DEFINE_PRIME1 (lime_font_load);
	DEFINE_PRIME1 (lime_font_load_bytes);
	DEFINE_PRIME1 (lime_font_load_file);
	DEFINE_PRIME2 (lime_font_outline_decompose);
	DEFINE_PRIME2 (lime_font_outline_decompose_no_hint);
	DEFINE_PRIME3 (lime_font_render_glyph);
	DEFINE_PRIME4 (lime_font_render_glyph_with_flags);
	DEFINE_PRIME3 (lime_font_render_glyphs);
	DEFINE_PRIME3v (lime_font_set_size);
	DEFINE_PRIME1v (lime_gamepad_add_mappings);
	DEFINE_PRIME2v (lime_gamepad_event_manager_register);
	DEFINE_PRIME1 (lime_gamepad_get_device_guid);
	DEFINE_PRIME1 (lime_gamepad_get_device_name);
	DEFINE_PRIME4v (lime_gamepad_rumble);
	DEFINE_PRIME2 (lime_gzip_compress);
	DEFINE_PRIME2 (lime_gzip_decompress);
	DEFINE_PRIME2v (lime_haptic_vibrate);
	DEFINE_PRIME3v (lime_image_data_util_color_transform);
	DEFINE_PRIME6v (lime_image_data_util_copy_channel);
	DEFINE_PRIME7v (lime_image_data_util_copy_pixels);
	DEFINE_PRIME4v (lime_image_data_util_fill_rect);
	DEFINE_PRIME5v (lime_image_data_util_flood_fill);
	DEFINE_PRIME4v (lime_image_data_util_get_pixels);
	DEFINE_PRIME8v (lime_image_data_util_merge);
	DEFINE_PRIME1v (lime_image_data_util_multiply_alpha);
	DEFINE_PRIME4v (lime_image_data_util_resize);
	DEFINE_PRIME2v (lime_image_data_util_set_format);
	DEFINE_PRIME6v (lime_image_data_util_set_pixels);
	DEFINE_PRIME12 (lime_image_data_util_threshold);
	DEFINE_PRIME1v (lime_image_data_util_unmultiply_alpha);
	DEFINE_PRIME4 (lime_image_encode);
	DEFINE_PRIME2 (lime_image_load);
	DEFINE_PRIME2 (lime_image_load_bytes);
	DEFINE_PRIME2 (lime_image_load_file);
	DEFINE_PRIME0 (lime_jni_getenv);
	DEFINE_PRIME2v (lime_joystick_event_manager_register);
	DEFINE_PRIME1 (lime_joystick_get_device_guid);
	DEFINE_PRIME1 (lime_joystick_get_device_name);
	DEFINE_PRIME1 (lime_joystick_get_num_axes);
	DEFINE_PRIME1 (lime_joystick_get_num_buttons);
	DEFINE_PRIME1 (lime_joystick_get_num_hats);
	DEFINE_PRIME3 (lime_jpeg_decode_bytes);
	DEFINE_PRIME3 (lime_jpeg_decode_file);
	DEFINE_PRIME1 (lime_key_code_from_scan_code);
	DEFINE_PRIME1 (lime_key_code_to_scan_code);
	DEFINE_PRIME2v (lime_key_event_manager_register);
	DEFINE_PRIME0 (lime_locale_get_system_locale);
	DEFINE_PRIME2 (lime_lzma_compress);
	DEFINE_PRIME2 (lime_lzma_decompress);
	DEFINE_PRIME2v (lime_mouse_event_manager_register);
	DEFINE_PRIME1v (lime_neko_execute);
	DEFINE_PRIME2v (lime_orientation_event_manager_register);
	DEFINE_PRIME3 (lime_png_decode_bytes);
	DEFINE_PRIME3 (lime_png_decode_file);
	DEFINE_PRIME2v (lime_render_event_manager_register);
	DEFINE_PRIME2v (lime_sensor_event_manager_register);
	DEFINE_PRIME0 (lime_system_get_allow_screen_timeout);
	DEFINE_PRIME0 (lime_system_get_device_model);
	DEFINE_PRIME0 (lime_system_get_device_vendor);
	DEFINE_PRIME3 (lime_system_get_directory);
	DEFINE_PRIME1 (lime_system_get_display);
	DEFINE_PRIME0 (lime_system_get_ios_tablet);
	DEFINE_PRIME0 (lime_system_get_num_displays);
	DEFINE_PRIME0 (lime_system_get_device_orientation);
	DEFINE_PRIME0 (lime_system_get_platform_label);
	DEFINE_PRIME0 (lime_system_get_platform_name);
	DEFINE_PRIME0 (lime_system_get_platform_version);
	DEFINE_PRIME0 (lime_system_get_timer);
	DEFINE_PRIME1 (lime_system_get_windows_console_mode);
	DEFINE_PRIME1v (lime_system_open_file);
	DEFINE_PRIME2v (lime_system_open_url);
	DEFINE_PRIME1 (lime_system_set_allow_screen_timeout);
	DEFINE_PRIME2 (lime_system_set_windows_console_mode);
	DEFINE_PRIME2v (lime_text_event_manager_register);
	DEFINE_PRIME2v (lime_touch_event_manager_register);
	DEFINE_PRIME3v (lime_window_alert);
	DEFINE_PRIME1v (lime_window_close);
	DEFINE_PRIME1v (lime_window_context_flip);
	DEFINE_PRIME1 (lime_window_context_lock);
	DEFINE_PRIME1v (lime_window_context_make_current);
	DEFINE_PRIME1v (lime_window_context_unlock);
	DEFINE_PRIME5 (lime_window_create);
	DEFINE_PRIME2v (lime_window_event_manager_register);
	DEFINE_PRIME1v (lime_window_focus);
	DEFINE_PRIME1 (lime_window_get_context);
	DEFINE_PRIME1 (lime_window_get_context_type);
	DEFINE_PRIME3 (lime_window_create_vulkan_surface);
	DEFINE_PRIME1 (lime_window_get_display);
	DEFINE_PRIME1 (lime_window_get_display_mode);
	DEFINE_PRIME1 (lime_window_get_height);
	DEFINE_PRIME1 (lime_window_get_id);
	DEFINE_PRIME1 (lime_window_get_mouse_lock);
	DEFINE_PRIME1 (lime_window_get_scale);
	DEFINE_PRIME1 (lime_window_get_text_input_enabled);
	DEFINE_PRIME1 (lime_window_get_vulkan_drawable_size);
	DEFINE_PRIME1 (lime_window_get_vulkan_instance_extensions);
	DEFINE_PRIME1 (lime_window_get_vulkan_instance_proc_addr);
	DEFINE_PRIME2 (lime_vk_create_instance);
	DEFINE_PRIME3v (lime_vk_destroy_instance);
	DEFINE_PRIME5v (lime_vk_destroy_surface);
	DEFINE_PRIME5 (lime_vk_get_physical_devices);
	DEFINE_PRIME7 (lime_vk_create_device);
	DEFINE_PRIME5v (lime_vk_destroy_device);
	DEFINE_PRIME5 (lime_vk_device_wait_idle);
	DEFINE_PRIME7 (lime_vk_queue_wait_idle);
	DEFINE_PRIME7 (lime_vk_create_command_pool);
	DEFINE_PRIME7v (lime_vk_destroy_command_pool);
	DEFINE_PRIME8 (lime_vk_reset_command_pool);
	DEFINE_PRIME8 (lime_vk_allocate_command_buffer);
	DEFINE_PRIME9v (lime_vk_free_command_buffer);
	DEFINE_PRIME8 (lime_vk_begin_command_buffer);
	DEFINE_PRIME7 (lime_vk_end_command_buffer);
	DEFINE_PRIME8 (lime_vk_reset_command_buffer);
	DEFINE_PRIME5 (lime_vk_create_semaphore);
	DEFINE_PRIME7v (lime_vk_destroy_semaphore);
	DEFINE_PRIME6 (lime_vk_create_fence);
	DEFINE_PRIME7v (lime_vk_destroy_fence);
	DEFINE_PRIME9 (lime_vk_wait_for_fence);
	DEFINE_PRIME7 (lime_vk_reset_fence);
	DEFINE_PRIME11 (lime_vk_queue_submit);
	DEFINE_PRIME11 (lime_vk_allocate_memory);
	DEFINE_PRIME7v (lime_vk_free_memory);
	DEFINE_PRIME12 (lime_vk_upload_memory);
	DEFINE_PRIME12 (lime_vk_download_memory);
	DEFINE_PRIME12 (lime_vk_map_memory);
	DEFINE_PRIME7v (lime_vk_unmap_memory);
	DEFINE_PRIME12 (lime_vk_write_mapped_memory);
	DEFINE_PRIME11 (lime_vk_flush_mapped_memory);
	DEFINE_PRIME11 (lime_vk_invalidate_mapped_memory);
	DEFINE_PRIME8 (lime_vk_create_buffer);
	DEFINE_PRIME7v (lime_vk_destroy_buffer);
	DEFINE_PRIME7 (lime_vk_get_buffer_memory_requirements);
	DEFINE_PRIME11 (lime_vk_bind_buffer_memory);
	DEFINE_PRIME15 (lime_vk_create_image);
	DEFINE_PRIME7v (lime_vk_destroy_image);
	DEFINE_PRIME7 (lime_vk_get_image_memory_requirements);
	DEFINE_PRIME11 (lime_vk_bind_image_memory);
	DEFINE_PRIME15 (lime_vk_create_swapchain);
	DEFINE_PRIME7v (lime_vk_destroy_swapchain);
	DEFINE_PRIME7 (lime_vk_get_swapchain_images);
	DEFINE_PRIME13 (lime_vk_acquire_next_image);
	DEFINE_PRIME12 (lime_vk_queue_present);
	DEFINE_PRIME10 (lime_vk_create_image_view);
	DEFINE_PRIME7v (lime_vk_destroy_image_view);
	DEFINE_PRIME14 (lime_vk_create_image_view_ex);
	DEFINE_PRIME6 (lime_vk_create_render_pass);
	DEFINE_PRIME7v (lime_vk_destroy_render_pass);
	DEFINE_PRIME11 (lime_vk_create_framebuffer);
	DEFINE_PRIME7v (lime_vk_destroy_framebuffer);
	DEFINE_PRIME8 (lime_vk_create_shader_module);
	DEFINE_PRIME7v (lime_vk_destroy_shader_module);
	DEFINE_PRIME13 (lime_vk_create_sampler);
	DEFINE_PRIME7v (lime_vk_destroy_sampler);
	DEFINE_PRIME6 (lime_vk_create_descriptor_set_layout);
	DEFINE_PRIME7v (lime_vk_destroy_descriptor_set_layout);
	DEFINE_PRIME6 (lime_vk_create_descriptor_pool);
	DEFINE_PRIME7v (lime_vk_destroy_descriptor_pool);
	DEFINE_PRIME8 (lime_vk_reset_descriptor_pool);
	DEFINE_PRIME9 (lime_vk_allocate_descriptor_set);
	DEFINE_PRIME14 (lime_vk_update_descriptor_set_image);
	DEFINE_PRIME13 (lime_vk_update_descriptor_set_buffer);
	DEFINE_PRIME6 (lime_vk_update_descriptor_sets);
	DEFINE_PRIME8 (lime_vk_create_pipeline_layout);
	DEFINE_PRIME7v (lime_vk_destroy_pipeline_layout);
	DEFINE_PRIME8 (lime_vk_create_pipeline_cache);
	DEFINE_PRIME7v (lime_vk_destroy_pipeline_cache);
	DEFINE_PRIME8 (lime_vk_get_pipeline_cache_data);
	DEFINE_PRIME14 (lime_vk_create_graphics_pipeline);
	DEFINE_PRIME7v (lime_vk_destroy_pipeline);
	DEFINE_PRIME10 (lime_vk_queue_submit_synced);
	DEFINE_PRIME13 (lime_vk_cmd_begin_render_pass);
	DEFINE_PRIME7 (lime_vk_cmd_end_render_pass);
	DEFINE_PRIME10 (lime_vk_cmd_bind_pipeline);
	DEFINE_PRIME13 (lime_vk_cmd_bind_descriptor_set);
	DEFINE_PRIME12 (lime_vk_cmd_bind_descriptor_set_ex);
	DEFINE_PRIME14 (lime_vk_cmd_bind_descriptor_set_dynamic_offset);
	DEFINE_PRIME12 (lime_vk_cmd_bind_vertex_buffer);
	DEFINE_PRIME12 (lime_vk_cmd_bind_index_buffer);
	DEFINE_PRIME13 (lime_vk_cmd_set_viewport);
	DEFINE_PRIME11 (lime_vk_cmd_set_scissor);
	DEFINE_PRIME11 (lime_vk_cmd_draw);
	DEFINE_PRIME12 (lime_vk_cmd_draw_indexed);
	DEFINE_PRIME13 (lime_vk_cmd_draw_indirect);
	DEFINE_PRIME13 (lime_vk_cmd_draw_indexed_indirect);
	DEFINE_PRIME12 (lime_vk_cmd_copy_buffer);
	DEFINE_PRIME12 (lime_vk_cmd_copy_buffer_to_image_region);
	DEFINE_PRIME12 (lime_vk_cmd_copy_image_to_buffer_region);
	DEFINE_PRIME10 (lime_vk_cmd_pipeline_barrier_image);
	DEFINE_PRIME12 (lime_vk_cmd_clear_color_image);
	DEFINE_PRIME11 (lime_vk_cmd_clear_depth_stencil_image);
	DEFINE_PRIME9 (lime_vk_cmd_clear_attachments);
	DEFINE_PRIME12 (lime_vk_cmd_blit_image);
	DEFINE_PRIME11 (lime_vk_cmd_push_constants);
	DEFINE_PRIME0 (lime_vk_get_last_error);
	DEFINE_PRIME2 (lime_vulkan_renderer_create);
	DEFINE_PRIME1v (lime_vulkan_renderer_destroy);
	DEFINE_PRIME1 (lime_vulkan_renderer_get_info);
	DEFINE_PRIME0 (lime_vulkan_renderer_get_last_error);
	DEFINE_PRIME6 (lime_vulkan_renderer_set_overlay);
	DEFINE_PRIME1 (lime_vulkan_renderer_clear_overlay);
	DEFINE_PRIME5 (lime_vulkan_renderer_render);
	DEFINE_PRIME1 (lime_vulkan_renderer_resize);
	DEFINE_PRIME1 (lime_window_get_width);
	DEFINE_PRIME1 (lime_window_get_x);
	DEFINE_PRIME1 (lime_window_get_y);
	DEFINE_PRIME3v (lime_window_move);
	DEFINE_PRIME3 (lime_window_read_pixels);
	DEFINE_PRIME3v (lime_window_resize);
	DEFINE_PRIME3v (lime_window_set_minimum_size);
	DEFINE_PRIME3v (lime_window_set_maximum_size);
	DEFINE_PRIME2 (lime_window_set_borderless);
	DEFINE_PRIME2v (lime_window_set_cursor);
	DEFINE_PRIME2 (lime_window_set_display_mode);
	DEFINE_PRIME2 (lime_window_set_fullscreen);
	DEFINE_PRIME2v (lime_window_set_icon);
	DEFINE_PRIME2 (lime_window_set_maximized);
	DEFINE_PRIME2 (lime_window_set_minimized);
	DEFINE_PRIME2v (lime_window_set_mouse_lock);
	DEFINE_PRIME2 (lime_window_set_resizable);
	DEFINE_PRIME2v (lime_window_set_text_input_enabled);
	DEFINE_PRIME2v (lime_window_set_text_input_rect);
	DEFINE_PRIME2 (lime_window_set_title);
	DEFINE_PRIME2 (lime_window_set_visible);
	DEFINE_PRIME2 (lime_window_set_always_on_top);
	DEFINE_PRIME3v (lime_window_warp_mouse);
	DEFINE_PRIME1 (lime_window_get_opacity);
	DEFINE_PRIME2v (lime_window_set_opacity);
	DEFINE_PRIME2 (lime_zlib_compress);
	DEFINE_PRIME2 (lime_zlib_decompress);


	#define _ENUM "?"
	// #define _TCFFIPOINTER _ABSTRACT (HL_CFFIPointer)
	#define _TAPPLICATION_EVENT _OBJ (_I32 _I32)
	#define _TBYTES _OBJ (_I32 _BYTES)
	#define _TCFFIPOINTER _DYN
	#define _TCLIPBOARD_EVENT _OBJ (_I32)
	#define _TDISPLAYMODE _OBJ (_I32 _I32 _I32 _I32)
	#define _TDROP_EVENT _OBJ (_BYTES _I32)
	#define _TGAMEPAD_EVENT _OBJ (_I32 _I32 _I32 _I32 _F64 _I32)
	#define _TJOYSTICK_EVENT _OBJ (_I32 _I32 _I32 _I32 _F64 _F64)
	#define _TKEY_EVENT _OBJ (_F64 _I32 _I32 _I32 _I32)
	#define _TMOUSE_EVENT _OBJ (_I32 _F64 _F64 _I32 _I32 _F64 _F64 _I32)
	#define _TORIENTATION_EVENT _OBJ (_I32 _I32 _I32)
	#define _TRECTANGLE _OBJ (_F64 _F64 _F64 _F64)
	#define _TRENDER_EVENT _OBJ (_I32)
	#define _TSENSOR_EVENT _OBJ (_I32 _F64 _F64 _F64 _I32)
	#define _TTEXT_EVENT _OBJ (_I32 _I32 _I32 _BYTES _I32 _I32)
	#define _TTOUCH_EVENT _OBJ (_I32 _F64 _F64 _I32 _F64 _I32 _F64 _F64)
	#define _TVECTOR2 _OBJ (_F64 _F64)
	#define _TVORBISFILE _OBJ (_I32 _DYN)
	#define _TWINDOW_EVENT _OBJ (_I32 _I32 _I32 _I32 _I32 _I32)

	#define _TARRAYBUFFER _TBYTES
	#define _TARRAYBUFFERVIEW _OBJ (_I32 _TARRAYBUFFER _I32 _I32 _I32 _I32)
	#define _TAUDIOBUFFER _OBJ (_I32 _I32 _TARRAYBUFFERVIEW _I32 _DYN _DYN _I32 _DYN _DYN _BOOL _DYN _TBYTES _BOOL _I32 _STRING _TBYTES _STRING _TVORBISFILE)
	#define _TIMAGEBUFFER _OBJ (_I32 _TARRAYBUFFERVIEW _I32 _I32 _BOOL _BOOL _I32 _DYN _DYN _DYN _DYN _DYN _DYN)
	#define _TIMAGE _OBJ (_TIMAGEBUFFER _BOOL _I32 _I32 _I32 _TRECTANGLE _ENUM _I32 _I32 _F64 _F64)

	#define _TARRAY _OBJ (_BYTES _I32)
	#define _TARRAY2 _OBJ (_ARR)


	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_application_create, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_application_event_manager_register, _FUN(_VOID, _NO_ARG) _TAPPLICATION_EVENT);
	DEFINE_HL_PRIM (_I32, hl_application_exec, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_application_init, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_application_quit, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_application_set_main_loop, _TCFFIPOINTER _I32 _F64 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_application_set_frame_rate, _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_VOID, hl_application_set_vsync_mode, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_BOOL, hl_application_update, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TAUDIOBUFFER, hl_audio_load_bytes, _TBYTES _TAUDIOBUFFER);
	DEFINE_HL_PRIM (_TAUDIOBUFFER, hl_audio_load_file, _STRING _TAUDIOBUFFER);
	DEFINE_HL_PRIM (_TBYTES, hl_bytes_from_data_pointer, _F64 _I32 _TBYTES);
	DEFINE_HL_PRIM (_F64, hl_bytes_get_data_pointer, _TBYTES);
	DEFINE_HL_PRIM (_F64, hl_bytes_get_data_pointer_offset, _TBYTES _I32);
	DEFINE_HL_PRIM (_TBYTES, hl_bytes_read_file, _STRING _TBYTES);
	DEFINE_HL_PRIM (_F64, hl_cffi_get_native_pointer, _TCFFIPOINTER);
	// DEFINE_PRIME1 (lime_cffi_set_finalizer);
	DEFINE_HL_PRIM (_VOID, hl_clipboard_event_manager_register, _FUN(_VOID, _NO_ARG) _TCLIPBOARD_EVENT);
	DEFINE_HL_PRIM (_BYTES, hl_clipboard_get_text, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_clipboard_set_text, _STRING);
	DEFINE_HL_PRIM (_F64, hl_data_pointer_offset, _F64 _I32);
	DEFINE_HL_PRIM (_TBYTES, hl_deflate_compress, _TBYTES _TBYTES);
	DEFINE_HL_PRIM (_TBYTES, hl_deflate_decompress, _TBYTES _TBYTES);
	DEFINE_HL_PRIM (_VOID, hl_drop_event_manager_register, _FUN(_VOID, _NO_ARG) _TDROP_EVENT);
	DEFINE_HL_PRIM (_BYTES, hl_file_dialog_open_directory, _STRING _STRING _STRING);
	DEFINE_HL_PRIM (_BYTES, hl_file_dialog_open_file, _STRING _STRING _STRING);
	DEFINE_HL_PRIM (_ARR, hl_file_dialog_open_files, _STRING _STRING _STRING);
	DEFINE_HL_PRIM (_BYTES, hl_file_dialog_save_file, _STRING _STRING _STRING);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_file_watcher_create, _DYN);
	DEFINE_HL_PRIM (_I32, hl_file_watcher_add_directory, _TCFFIPOINTER _STRING _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_file_watcher_remove_directory, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_file_watcher_update, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_font_get_ascender, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_font_get_descender, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BYTES, hl_font_get_family_name, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_font_get_glyph_index, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_ARR, hl_font_get_glyph_indices, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_DYN, hl_font_get_glyph_metrics, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_I32, hl_font_get_height, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_font_get_num_glyphs, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_font_get_underline_position, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_font_get_underline_thickness, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_font_get_strikethrough_position, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_font_get_strikethrough_thickness, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_font_get_units_per_em, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_font_is_bold, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_font_is_italic, _TCFFIPOINTER);
	// DEFINE_PRIME1 (lime_font_load);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_font_load_bytes, _TBYTES);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_font_load_file, _STRING);
	DEFINE_HL_PRIM (_DYN, hl_font_outline_decompose, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_DYN, hl_font_outline_decompose_no_hint, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_TBYTES, hl_font_render_glyph, _TCFFIPOINTER _I32 _TBYTES);
	DEFINE_HL_PRIM (_TBYTES, hl_font_render_glyph_with_flags, _TCFFIPOINTER _I32 _I32 _TBYTES);
	DEFINE_HL_PRIM (_TBYTES, hl_font_render_glyphs, _TCFFIPOINTER _ARR _TBYTES);
	DEFINE_HL_PRIM (_VOID, hl_font_set_size, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_gamepad_add_mappings, _ARR);
	DEFINE_HL_PRIM (_VOID, hl_gamepad_event_manager_register, _FUN(_VOID, _NO_ARG) _TGAMEPAD_EVENT);
	DEFINE_HL_PRIM (_BYTES, hl_gamepad_get_device_guid, _I32);
	DEFINE_HL_PRIM (_BYTES, hl_gamepad_get_device_name, _I32);
	DEFINE_HL_PRIM (_VOID, hl_gamepad_rumble, _I32 _F64 _F64 _I32);
	DEFINE_HL_PRIM (_TBYTES, hl_gzip_compress, _TBYTES _TBYTES);
	DEFINE_HL_PRIM (_TBYTES, hl_gzip_decompress, _TBYTES _TBYTES);
	DEFINE_HL_PRIM (_VOID, hl_haptic_vibrate, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_image_data_util_color_transform, _TIMAGE _TRECTANGLE _TARRAYBUFFERVIEW);
	DEFINE_HL_PRIM (_VOID, hl_image_data_util_copy_channel, _TIMAGE _TIMAGE _TRECTANGLE _TVECTOR2 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_image_data_util_copy_pixels, _TIMAGE _TIMAGE _TRECTANGLE _TVECTOR2 _TIMAGE _TVECTOR2 _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_image_data_util_fill_rect, _TIMAGE _TRECTANGLE _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_image_data_util_flood_fill, _TIMAGE _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_image_data_util_get_pixels, _TIMAGE _TRECTANGLE _I32 _TBYTES);
	DEFINE_HL_PRIM (_VOID, hl_image_data_util_merge, _TIMAGE _TIMAGE _TRECTANGLE _TVECTOR2 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_image_data_util_multiply_alpha, _TIMAGE);
	DEFINE_HL_PRIM (_VOID, hl_image_data_util_resize, _TIMAGE _TIMAGEBUFFER _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_image_data_util_set_format, _TIMAGE _I32);
	DEFINE_HL_PRIM (_VOID, hl_image_data_util_set_pixels, _TIMAGE _TRECTANGLE _TBYTES _I32 _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_image_data_util_threshold, _TIMAGE _TIMAGE _TRECTANGLE _TVECTOR2 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_image_data_util_unmultiply_alpha, _TIMAGE);
	DEFINE_HL_PRIM (_TBYTES, hl_image_encode, _TIMAGEBUFFER _I32 _I32 _TBYTES);
	// DEFINE_PRIME2 (lime_image_load);
	DEFINE_HL_PRIM (_TIMAGEBUFFER, hl_image_load_bytes, _TBYTES _TIMAGEBUFFER);
	DEFINE_HL_PRIM (_TIMAGEBUFFER, hl_image_load_file, _STRING _TIMAGEBUFFER);
	DEFINE_HL_PRIM (_F64, hl_jni_getenv, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_joystick_event_manager_register, _FUN(_VOID, _NO_ARG) _TJOYSTICK_EVENT);
	DEFINE_HL_PRIM (_BYTES, hl_joystick_get_device_guid, _I32);
	DEFINE_HL_PRIM (_BYTES, hl_joystick_get_device_name, _I32);
	DEFINE_HL_PRIM (_I32, hl_joystick_get_num_axes, _I32);
	DEFINE_HL_PRIM (_I32, hl_joystick_get_num_buttons, _I32);
	DEFINE_HL_PRIM (_I32, hl_joystick_get_num_hats, _I32);
	DEFINE_HL_PRIM (_TIMAGEBUFFER, hl_jpeg_decode_bytes, _TBYTES _BOOL _TIMAGEBUFFER);
	DEFINE_HL_PRIM (_TIMAGEBUFFER, hl_jpeg_decode_file, _STRING _BOOL _TIMAGEBUFFER);
	DEFINE_HL_PRIM (_I32, hl_key_code_from_scan_code, _I32);
	DEFINE_HL_PRIM (_I32, hl_key_code_to_scan_code, _I32);
	DEFINE_HL_PRIM (_VOID, hl_key_event_manager_register, _FUN (_VOID, _NO_ARG) _TKEY_EVENT);
	DEFINE_HL_PRIM (_BYTES, hl_locale_get_system_locale, _NO_ARG);
	DEFINE_HL_PRIM (_TBYTES, hl_lzma_compress, _TBYTES _TBYTES);
	DEFINE_HL_PRIM (_TBYTES, hl_lzma_decompress, _TBYTES _TBYTES);
	DEFINE_HL_PRIM (_VOID, hl_mouse_event_manager_register, _FUN (_VOID, _NO_ARG) _TMOUSE_EVENT);
	// DEFINE_PRIME1v (lime_neko_execute);
	DEFINE_HL_PRIM (_VOID, hl_orientation_event_manager_register, _FUN (_VOID, _NO_ARG) _TORIENTATION_EVENT);
	DEFINE_HL_PRIM (_TIMAGEBUFFER, hl_png_decode_bytes, _TBYTES _BOOL _TIMAGEBUFFER);
	DEFINE_HL_PRIM (_TIMAGEBUFFER, hl_png_decode_file, _STRING _BOOL _TIMAGEBUFFER);
	DEFINE_HL_PRIM (_VOID, hl_render_event_manager_register, _FUN (_VOID, _NO_ARG) _TRENDER_EVENT);
	DEFINE_HL_PRIM (_VOID, hl_sensor_event_manager_register, _FUN (_VOID, _NO_ARG) _TSENSOR_EVENT);
	DEFINE_HL_PRIM (_BOOL, hl_system_get_allow_screen_timeout, _NO_ARG);
	DEFINE_HL_PRIM (_BYTES, hl_system_get_device_model, _NO_ARG);
	DEFINE_HL_PRIM (_BYTES, hl_system_get_device_vendor, _NO_ARG);
	DEFINE_HL_PRIM (_BYTES, hl_system_get_directory, _I32 _STRING _STRING);
	DEFINE_HL_PRIM (_DYN, hl_system_get_display, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_system_get_ios_tablet, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_system_get_num_displays, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_system_get_device_orientation, _NO_ARG);
	DEFINE_HL_PRIM (_BYTES, hl_system_get_platform_label, _NO_ARG);
	DEFINE_HL_PRIM (_BYTES, hl_system_get_platform_name, _NO_ARG);
	DEFINE_HL_PRIM (_BYTES, hl_system_get_platform_version, _NO_ARG);
	DEFINE_HL_PRIM (_F64, hl_system_get_timer, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_system_get_windows_console_mode, _I32);
	DEFINE_HL_PRIM (_VOID, hl_system_open_file, _STRING);
	DEFINE_HL_PRIM (_VOID, hl_system_open_url, _STRING _STRING);
	DEFINE_HL_PRIM (_BOOL, hl_system_set_allow_screen_timeout, _BOOL);
	DEFINE_HL_PRIM (_BOOL, hl_system_set_windows_console_mode, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_text_event_manager_register, _FUN (_VOID, _NO_ARG) _TTEXT_EVENT);
	DEFINE_HL_PRIM (_VOID, hl_touch_event_manager_register, _FUN (_VOID, _NO_ARG) _TTOUCH_EVENT);
	DEFINE_HL_PRIM (_VOID, hl_window_alert, _TCFFIPOINTER _STRING _STRING);
	DEFINE_HL_PRIM (_VOID, hl_window_close, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_window_context_flip, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN, hl_window_context_lock, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_window_context_make_current, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_window_context_unlock, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_window_create, _TCFFIPOINTER _I32 _I32 _I32 _STRING);
	DEFINE_HL_PRIM (_VOID, hl_window_event_manager_register, _FUN (_VOID, _NO_ARG) _TWINDOW_EVENT);
	DEFINE_HL_PRIM (_VOID, hl_window_focus, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_F64, hl_window_get_context, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BYTES, hl_window_get_context_type, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN, hl_window_create_vulkan_surface, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_window_get_display, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_window_get_display_mode, _TCFFIPOINTER _TDISPLAYMODE);
	DEFINE_HL_PRIM (_I32, hl_window_get_height, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_window_get_id, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_window_get_mouse_lock, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_F64, hl_window_get_scale, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_window_get_text_input_enabled, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN, hl_window_get_vulkan_drawable_size, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_ARR, hl_window_get_vulkan_instance_extensions, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN, hl_window_get_vulkan_instance_proc_addr, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_instance, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_instance, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_surface, _TCFFIPOINTER _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_ARR, hl_vk_get_physical_devices, _TCFFIPOINTER _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_device, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_device, _TCFFIPOINTER _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_device_wait_idle, _TCFFIPOINTER _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_queue_wait_idle, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_command_pool, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_command_pool, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_reset_command_pool, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_allocate_command_buffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_free_command_buffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_begin_command_buffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_end_command_buffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_reset_command_buffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_semaphore, _TCFFIPOINTER _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_semaphore, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_fence, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_fence, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_wait_for_fence, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_reset_fence, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_queue_submit, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_allocate_memory, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_free_memory, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_upload_memory, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _TBYTES _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_download_memory, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _TBYTES _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_map_memory, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_unmap_memory, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_write_mapped_memory, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _TBYTES _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_flush_mapped_memory, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_invalidate_mapped_memory, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_buffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_buffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_get_buffer_memory_requirements, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_bind_buffer_memory, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_image, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_image, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_get_image_memory_requirements, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_bind_image_memory, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_swapchain, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_swapchain, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_ARR, hl_vk_get_swapchain_images, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_acquire_next_image, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_vk_queue_present, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_image_view, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_image_view, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_image_view_ex, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_render_pass, _TCFFIPOINTER _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_render_pass, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_framebuffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _ARR _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_framebuffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_shader_module, _TCFFIPOINTER _I32 _I32 _I32 _I32 _TBYTES _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_shader_module, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_sampler, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _BOOL _F64 _I32 _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_sampler, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_descriptor_set_layout, _TCFFIPOINTER _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_descriptor_set_layout, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_descriptor_pool, _TCFFIPOINTER _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_descriptor_pool, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_reset_descriptor_pool, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_allocate_descriptor_set, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_update_descriptor_set_image, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_update_descriptor_set_buffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_update_descriptor_sets, _TCFFIPOINTER _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_pipeline_layout, _TCFFIPOINTER _I32 _I32 _I32 _I32 _ARR _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_pipeline_layout, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_pipeline_cache, _TCFFIPOINTER _I32 _I32 _I32 _I32 _TBYTES _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_pipeline_cache, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_get_pipeline_cache_data, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _TBYTES);
	DEFINE_HL_PRIM (_DYN, hl_vk_create_graphics_pipeline, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_vk_destroy_pipeline, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_queue_submit_synced, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_begin_render_pass, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _ARR _ARR);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_end_render_pass, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_bind_pipeline, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_bind_descriptor_set, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_bind_descriptor_set_ex, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_bind_descriptor_set_dynamic_offset, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_bind_vertex_buffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_bind_index_buffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_set_viewport, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _F64 _F64 _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_set_scissor, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_draw, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_draw_indexed, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_draw_indirect, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_draw_indexed_indirect, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_copy_buffer, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_copy_buffer_to_image_region, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_copy_image_to_buffer_region, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_pipeline_barrier_image, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_clear_color_image, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_clear_depth_stencil_image, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _ARR _ARR);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_clear_attachments, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _ARR _ARR);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_blit_image, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _ARR);
	DEFINE_HL_PRIM (_BOOL, hl_vk_cmd_push_constants, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _ARR _TBYTES);
	DEFINE_HL_PRIM (_BYTES, hl_vk_get_last_error, _NO_ARG);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_vulkan_renderer_create, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_VOID, hl_vulkan_renderer_destroy, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BYTES, hl_vulkan_renderer_get_info, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BYTES, hl_vulkan_renderer_get_last_error, _NO_ARG);
	DEFINE_HL_PRIM (_BOOL, hl_vulkan_renderer_set_overlay, _TCFFIPOINTER _TBYTES _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_vulkan_renderer_clear_overlay, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_vulkan_renderer_render, _TCFFIPOINTER _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_BOOL, hl_vulkan_renderer_resize, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_window_get_width, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_window_get_x, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_window_get_y, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_window_move, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_window_read_pixels, _TCFFIPOINTER _TRECTANGLE _TIMAGEBUFFER);
	DEFINE_HL_PRIM (_VOID, hl_window_resize, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_window_set_minimum_size, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_window_set_maximum_size, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_window_set_borderless, _TCFFIPOINTER _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_window_set_cursor, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_window_set_display_mode, _TCFFIPOINTER _TDISPLAYMODE _TDISPLAYMODE);
	DEFINE_HL_PRIM (_BOOL, hl_window_set_fullscreen, _TCFFIPOINTER _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_window_set_icon, _TCFFIPOINTER _TIMAGEBUFFER);
	DEFINE_HL_PRIM (_BOOL, hl_window_set_maximized, _TCFFIPOINTER _BOOL);
	DEFINE_HL_PRIM (_BOOL, hl_window_set_minimized, _TCFFIPOINTER _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_window_set_mouse_lock, _TCFFIPOINTER _BOOL);
	DEFINE_HL_PRIM (_BOOL, hl_window_set_resizable, _TCFFIPOINTER _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_window_set_text_input_enabled, _TCFFIPOINTER _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_window_set_text_input_rect, _TCFFIPOINTER _TRECTANGLE);
	DEFINE_HL_PRIM (_STRING, hl_window_set_title, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_BOOL, hl_window_set_visible, _TCFFIPOINTER _BOOL);
	DEFINE_HL_PRIM (_BOOL, hl_window_set_always_on_top, _TCFFIPOINTER _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_window_warp_mouse, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_F64, hl_window_get_opacity, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_window_set_opacity, _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_TBYTES, hl_zlib_compress, _TBYTES _TBYTES);
	DEFINE_HL_PRIM (_TBYTES, hl_zlib_decompress, _TBYTES _TBYTES);


}


#ifdef LIME_CAIRO
extern "C" int lime_cairo_register_prims ();
#else
extern "C" int lime_cairo_register_prims () { return 0; }
#endif

#ifdef LIME_CURL
extern "C" int lime_curl_register_prims ();
#else
extern "C" int lime_curl_register_prims () { return 0; }
#endif

#ifdef LIME_HARFBUZZ
extern "C" int lime_harfbuzz_register_prims ();
#else
extern "C" int lime_harfbuzz_register_prims () { return 0; }
#endif

#ifdef LIME_OPENAL
extern "C" int lime_openal_register_prims ();
#else
extern "C" int lime_openal_register_prims () { return 0; }
#endif

#ifdef LIME_OPENGL
extern "C" int lime_opengl_register_prims ();
#else
extern "C" int lime_opengl_register_prims () { return 0; }
#endif

#ifdef LIME_VORBIS
extern "C" int lime_vorbis_register_prims ();
#else
extern "C" int lime_vorbis_register_prims () { return 0; }
#endif


extern "C" int lime_register_prims () {

	lime_cairo_register_prims ();
	lime_curl_register_prims ();
	lime_harfbuzz_register_prims ();
	lime_openal_register_prims ();
	lime_opengl_register_prims ();
	lime_vorbis_register_prims ();

	return 0;

}
