#ifndef LIME_GRAPHICS_VULKAN_VKRENDERER_H
#define LIME_GRAPHICS_VULKAN_VKRENDERER_H

#include <string>
#include <vector>
#include <ui/Cursor.h>
#include <ui/Window.h>
#include <vulkan/vulkan.h>


namespace lime {


	class VulkanRenderer {

		public:

			explicit VulkanRenderer (Window* window);
			~VulkanRenderer ();

			bool ClearOverlay ();
			bool Create (const char* applicationName);
			void Destroy ();
			bool Render (float red, float green, float blue, float alpha);
			bool Resize ();
			bool SetOverlay (const unsigned char* data, int width, int height, int x, int y);

			inline const std::string& GetInfo () const { return info; }
			inline const std::string& GetLastError () const { return lastError; }

		private:

			bool CreateCommandBuffers ();
			bool CreateCommandPool ();
			bool CreateDevice ();
			bool CreateFramebuffers ();
			bool CreateImageViews ();
			bool CreateInstance (const char* applicationName);
			bool CreateOverlayBuffer (size_t requiredSize);
			bool CreateRenderPass ();
			bool CreateSurface ();
			bool CreateSwapchain ();
			bool CreateSwapchainResources ();
			bool CreateSyncObjects ();
			void DestroyOverlayResources ();
			void DestroySwapchainResources ();
			uint32_t FindMemoryType (uint32_t typeFilter, VkMemoryPropertyFlags properties);
			bool LoadDeviceProcs ();
			bool LoadGlobalProcs ();
			bool LoadInstanceProcs ();
			bool PickPhysicalDevice ();
			bool RecordCommandBuffer (uint32_t imageIndex, float red, float green, float blue, float alpha);
			bool RecreateSwapchain ();
			void SetError (const std::string& value);

			Window* window;
			std::string info;
			std::string lastError;

			PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr;
			PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr;
			PFN_vkAllocateMemory vkAllocateMemory;
			PFN_vkBindBufferMemory vkBindBufferMemory;
			PFN_vkCmdCopyBufferToImage vkCmdCopyBufferToImage;
			PFN_vkCmdPipelineBarrier vkCmdPipelineBarrier;
			PFN_vkCreateBuffer vkCreateBuffer;
			PFN_vkCreateDevice vkCreateDevice;
			PFN_vkCreateFence vkCreateFence;
			PFN_vkCreateFramebuffer vkCreateFramebuffer;
			PFN_vkCreateImageView vkCreateImageView;
			PFN_vkCreateInstance vkCreateInstance;
			PFN_vkCreateRenderPass vkCreateRenderPass;
			PFN_vkCreateSemaphore vkCreateSemaphore;
			PFN_vkCreateSwapchainKHR vkCreateSwapchainKHR;
			PFN_vkCreateCommandPool vkCreateCommandPool;
			PFN_vkAllocateCommandBuffers vkAllocateCommandBuffers;
			PFN_vkAcquireNextImageKHR vkAcquireNextImageKHR;
			PFN_vkBeginCommandBuffer vkBeginCommandBuffer;
			PFN_vkCmdBeginRenderPass vkCmdBeginRenderPass;
			PFN_vkCmdEndRenderPass vkCmdEndRenderPass;
			PFN_vkDestroyCommandPool vkDestroyCommandPool;
			PFN_vkDestroyBuffer vkDestroyBuffer;
			PFN_vkDestroyDevice vkDestroyDevice;
			PFN_vkDestroyFence vkDestroyFence;
			PFN_vkDestroyFramebuffer vkDestroyFramebuffer;
			PFN_vkDestroyImageView vkDestroyImageView;
			PFN_vkDestroyInstance vkDestroyInstance;
			PFN_vkDestroyRenderPass vkDestroyRenderPass;
			PFN_vkDestroySemaphore vkDestroySemaphore;
			PFN_vkDestroySurfaceKHR vkDestroySurfaceKHR;
			PFN_vkDestroySwapchainKHR vkDestroySwapchainKHR;
			PFN_vkDeviceWaitIdle vkDeviceWaitIdle;
			PFN_vkEndCommandBuffer vkEndCommandBuffer;
			PFN_vkEnumerateDeviceExtensionProperties vkEnumerateDeviceExtensionProperties;
			PFN_vkFreeMemory vkFreeMemory;
			PFN_vkGetBufferMemoryRequirements vkGetBufferMemoryRequirements;
			PFN_vkEnumerateInstanceExtensionProperties vkEnumerateInstanceExtensionProperties;
			PFN_vkEnumerateInstanceVersion vkEnumerateInstanceVersion;
			PFN_vkEnumeratePhysicalDevices vkEnumeratePhysicalDevices;
			PFN_vkGetDeviceQueue vkGetDeviceQueue;
			PFN_vkGetPhysicalDeviceMemoryProperties vkGetPhysicalDeviceMemoryProperties;
			PFN_vkGetPhysicalDeviceProperties vkGetPhysicalDeviceProperties;
			PFN_vkGetPhysicalDeviceQueueFamilyProperties vkGetPhysicalDeviceQueueFamilyProperties;
			PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR vkGetPhysicalDeviceSurfaceCapabilitiesKHR;
			PFN_vkGetPhysicalDeviceSurfaceFormatsKHR vkGetPhysicalDeviceSurfaceFormatsKHR;
			PFN_vkGetPhysicalDeviceSurfacePresentModesKHR vkGetPhysicalDeviceSurfacePresentModesKHR;
			PFN_vkGetPhysicalDeviceSurfaceSupportKHR vkGetPhysicalDeviceSurfaceSupportKHR;
			PFN_vkGetSwapchainImagesKHR vkGetSwapchainImagesKHR;
			PFN_vkMapMemory vkMapMemory;
			PFN_vkQueuePresentKHR vkQueuePresentKHR;
			PFN_vkQueueSubmit vkQueueSubmit;
			PFN_vkResetCommandPool vkResetCommandPool;
			PFN_vkResetFences vkResetFences;
			PFN_vkUnmapMemory vkUnmapMemory;
			PFN_vkWaitForFences vkWaitForFences;

			VkInstance instance;
			VkSurfaceKHR surface;
			VkPhysicalDevice physicalDevice;
			VkPhysicalDeviceProperties physicalDeviceProperties;
			VkDevice device;
			VkQueue queue;
			uint32_t queueFamilyIndex;
			VkSwapchainKHR swapchain;
			VkFormat swapchainFormat;
			VkPresentModeKHR swapchainPresentMode;
			int requestedVSyncMode;
			VkExtent2D swapchainExtent;
			VkRenderPass renderPass;
			VkCommandPool commandPool;
			VkSemaphore imageAvailableSemaphore;
			VkSemaphore renderFinishedSemaphore;
			VkFence inFlightFence;
			VkBuffer overlayBuffer;
			VkDeviceMemory overlayBufferMemory;
			bool portabilityEnumerationSupported;
			bool portabilitySubsetSupported;
			bool swapchainDirty;
			size_t overlayBufferCapacity;
			unsigned char* overlayMappedData;
			uint32_t overlayWidth;
			uint32_t overlayHeight;
			int overlayX;
			int overlayY;
			bool overlayEnabled;

			std::vector<const char*> instanceExtensions;
			std::vector<const char*> deviceExtensions;
			std::vector<VkImage> swapchainImages;
			std::vector<VkImageView> swapchainImageViews;
			std::vector<VkFramebuffer> framebuffers;
			std::vector<VkCommandBuffer> commandBuffers;

	};


}


#endif
