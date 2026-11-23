#include <media/CameraCapture.h>

#ifdef LIME_VIDEO_GSTREAMER

#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>


namespace lime {


	// GStreamer is loaded at runtime, as for video, so Lime has no build or link
	// dependency on it. The types used are declared by hand, in their own
	// namespace so they cannot clash with the video backend's.
	namespace camera_gst {


		typedef int gboolean;
		struct GstBus;
		struct GstCaps;
		struct GstDevice;
		struct GstDeviceMonitor;
		struct GstElement;
		struct GstSample;
		struct GstStructure;

		struct GList {

			void* data;
			GList* next;
			GList* prev;

		};

		// GStreamer 1.x keeps these public structures ABI stable
		struct GstMiniObject {

			size_t type;
			int refcount;
			int lockstate;
			unsigned int flags;
			void* copy;
			void* dispose;
			void* free;
			unsigned int n_qdata;
			void* qdata;

		};

		struct GstBuffer {

			GstMiniObject mini_object;
			void* pool;
			uint64_t pts;
			uint64_t dts;
			uint64_t duration;

		};

		struct GstMapInfo {

			void* memory;
			int flags;
			unsigned char* data;
			size_t size;
			size_t maxsize;
			void* user_data[4];
			void* _gst_reserved[4];

		};

		struct GstMeta {

			int flags;
			const void* info;

		};

		struct GstVideoMeta {

			GstMeta meta;
			GstBuffer* buffer;
			int flags;
			int format;
			int id;
			unsigned int width;
			unsigned int height;
			unsigned int n_planes;
			size_t offset[4];
			int stride[4];

		};

		static const uint64_t GST_CLOCK_TIME_NONE = (uint64_t)-1;
		static const int GST_MAP_READ = 1;
		static const int GST_MESSAGE_ERROR = 1 << 1;
		static const int GST_MESSAGE_EOS = 1 << 0;
		static const int GST_STATE_CHANGE_FAILURE = 0;
		static const int GST_STATE_NULL = 1;
		static const int GST_STATE_READY = 2;
		static const int GST_STATE_PAUSED = 3;
		static const int GST_STATE_PLAYING = 4;


		struct Library {

			void (*g_free) (void*);
			void (*g_list_free) (GList*);
			void (*g_object_set) (void*, const char*, ...);
			GstSample* (*gst_app_sink_try_pull_sample) (GstElement*, uint64_t);
			gboolean (*gst_bin_add) (GstElement*, GstElement*);
			GstMeta* (*gst_buffer_get_meta) (GstBuffer*, size_t);
			gboolean (*gst_buffer_map) (GstBuffer*, GstMapInfo*, int);
			void (*gst_buffer_unmap) (GstBuffer*, GstMapInfo*);
			void* (*gst_bus_pop_filtered) (GstBus*, int);
			GstCaps* (*gst_caps_from_string) (const char*);
			GstStructure* (*gst_caps_get_structure) (const GstCaps*, unsigned int);
			GstElement* (*gst_device_create_element) (GstDevice*, const char*);
			char* (*gst_device_get_display_name) (GstDevice*);
			GstStructure* (*gst_device_get_properties) (GstDevice*);
			unsigned int (*gst_device_monitor_add_filter) (GstDeviceMonitor*, const char*, GstCaps*);
			GList* (*gst_device_monitor_get_devices) (GstDeviceMonitor*);
			GstDeviceMonitor* (*gst_device_monitor_new) ();
			GstElement* (*gst_element_factory_make) (const char*, const char*);
			GstBus* (*gst_element_get_bus) (GstElement*);
			gboolean (*gst_element_link) (GstElement*, GstElement*);
			int (*gst_element_set_state) (GstElement*, int);
			gboolean (*gst_init_check) (int*, char***, void**);
			void (*gst_mini_object_unref) (void*);
			void (*gst_object_unref) (void*);
			GstElement* (*gst_pipeline_new) (const char*);
			GstBuffer* (*gst_sample_get_buffer) (GstSample*);
			GstCaps* (*gst_sample_get_caps) (GstSample*);
			void (*gst_structure_free) (GstStructure*);
			gboolean (*gst_structure_get_fraction) (const GstStructure*, const char*, int*, int*);
			gboolean (*gst_structure_get_int) (const GstStructure*, const char*, int*);
			const char* (*gst_structure_get_string) (const GstStructure*, const char*);
			size_t (*gst_video_meta_api_get_type) ();

		};


		static Library gst;
		static std::once_flag loadFlag;
		static bool loaded = false;
		static size_t videoMetaAPI = 0;


		static bool Load () {

			std::call_once (loadFlag, [] {

				void* glib = dlopen ("libglib-2.0.so.0", RTLD_NOW | RTLD_LOCAL);
				void* gobject = dlopen ("libgobject-2.0.so.0", RTLD_NOW | RTLD_LOCAL);
				void* gstreamer = dlopen ("libgstreamer-1.0.so.0", RTLD_NOW | RTLD_LOCAL);
				void* app = dlopen ("libgstapp-1.0.so.0", RTLD_NOW | RTLD_LOCAL);
				if (!glib || !gobject || !gstreamer || !app) return;

				#define LIME_CAMERA_GST_REQUIRE(library, name) gst.name = (decltype (gst.name))dlsym (library, #name); if (!gst.name) return;

				LIME_CAMERA_GST_REQUIRE (glib, g_free);
				LIME_CAMERA_GST_REQUIRE (glib, g_list_free);
				LIME_CAMERA_GST_REQUIRE (gobject, g_object_set);
				LIME_CAMERA_GST_REQUIRE (app, gst_app_sink_try_pull_sample);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_bin_add);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_buffer_get_meta);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_buffer_map);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_buffer_unmap);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_bus_pop_filtered);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_caps_from_string);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_caps_get_structure);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_device_create_element);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_device_get_display_name);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_device_get_properties);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_device_monitor_add_filter);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_device_monitor_get_devices);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_device_monitor_new);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_element_factory_make);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_element_get_bus);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_element_link);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_element_set_state);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_init_check);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_mini_object_unref);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_object_unref);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_pipeline_new);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_sample_get_buffer);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_sample_get_caps);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_structure_free);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_structure_get_fraction);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_structure_get_int);
				LIME_CAMERA_GST_REQUIRE (gstreamer, gst_structure_get_string);

				#undef LIME_CAMERA_GST_REQUIRE

				// Video metas describe padded frames, and are read when available
				void* video = dlopen ("libgstvideo-1.0.so.0", RTLD_NOW | RTLD_LOCAL);
				if (video) gst.gst_video_meta_api_get_type = (decltype (gst.gst_video_meta_api_get_type))dlsym (video, "gst_video_meta_api_get_type");

				if (!gst.gst_init_check (NULL, NULL, NULL)) return;
				if (gst.gst_video_meta_api_get_type) videoMetaAPI = gst.gst_video_meta_api_get_type ();

				loaded = true;

			});

			return loaded;

		}


		// The id a camera is opened by: its device node for Video4Linux, its serial
		// for PipeWire, or else its name
		static std::string GetDeviceId (GstDevice* device, const std::string& name) {

			GstStructure* properties = gst.gst_device_get_properties (device);
			std::string id;

			if (properties) {

				const char* keys[] = { "device.path", "api.v4l2.path", "object.serial", "node.name" };

				for (size_t i = 0; i < sizeof (keys) / sizeof (keys[0]) && id.empty (); i++) {

					const char* value = gst.gst_structure_get_string (properties, keys[i]);
					if (value) id = value;

				}

				gst.gst_structure_free (properties);

			}

			return id.empty () ? name : id;

		}


		// Lists the cameras. With create, it makes the source element for the one
		// with id, or the first, instead.
		static GstElement* ListDevices (std::vector<CameraDeviceInfo>* devices, const char* create) {

			GstDeviceMonitor* monitor = gst.gst_device_monitor_new ();
			if (!monitor) return NULL;

			gst.gst_device_monitor_add_filter (monitor, "Video/Source", NULL);
			GList* list = gst.gst_device_monitor_get_devices (monitor);
			GstElement* element = NULL;

			for (GList* item = list; item; item = item->next) {

				GstDevice* device = (GstDevice*)item->data;
				char* displayName = gst.gst_device_get_display_name (device);
				std::string name = displayName ? displayName : "Camera";
				if (displayName) gst.g_free (displayName);

				std::string id = GetDeviceId (device, name);

				if (devices) {

					CameraDeviceInfo info;
					info.id = id;
					info.name = name;
					info.position = CAMERA_POSITION_UNKNOWN;
					devices->push_back (info);

				}

				if (create && !element && (!create[0] || id == create)) {

					element = gst.gst_device_create_element (device, NULL);

				}

				gst.gst_object_unref (device);

			}

			if (list) gst.g_list_free (list);
			gst.gst_object_unref (monitor);
			return element;

		}


	}


	using namespace camera_gst;


	class GStreamerCameraCapture : public CameraCapture {


		public:

			GStreamerCameraCapture () {

				bus = NULL;
				pipeline = NULL;
				sink = NULL;

			}


			~GStreamerCameraCapture () {

				Close ();

			}


			void Close () {

				if (pipeline) {

					gst.gst_element_set_state (pipeline, GST_STATE_NULL);
					gst.gst_object_unref (pipeline);
					pipeline = NULL;

				}

				if (bus) {

					gst.gst_object_unref (bus);
					bus = NULL;

				}

				// The appsink belongs to the pipeline
				sink = NULL;
				SetDisconnected ();

			}


			bool Open (const char* id, int requestedWidth, int requestedHeight, double requestedFrameRate) {

				// Only a camera the device monitor lists is opened. autovideosrc is not
				// a fallback: with no camera it gives GStreamer's test pattern, and the
				// plugins that would give it a real camera list that camera here.
				GstElement* source = ListDevices (NULL, id ? id : "");
				if (!source) return false;

				GstElement* convert = gst.gst_element_factory_make ("videoconvert", NULL);
				GstElement* scale = gst.gst_element_factory_make ("videoscale", NULL);
				GstElement* rate = gst.gst_element_factory_make ("videorate", NULL);
				GstElement* filter = gst.gst_element_factory_make ("capsfilter", NULL);
				sink = gst.gst_element_factory_make ("appsink", NULL);
				pipeline = gst.gst_pipeline_new (NULL);

				if (!convert || !scale || !rate || !filter || !sink || !pipeline) {

					GstElement* elements[] = { source, convert, scale, rate, filter, sink };
					for (size_t i = 0; i < 6; i++) if (elements[i]) gst.gst_object_unref (elements[i]);
					if (pipeline) gst.gst_object_unref (pipeline);
					pipeline = NULL;
					sink = NULL;
					return false;

				}

				// The camera's own format is scaled and converted to the size, rate
				// and NV12 asked for
				int frames = (int)(requestedFrameRate + 0.5);
				if (frames < 1) frames = 1;

				char capsText[160];
				snprintf (capsText, sizeof (capsText), "video/x-raw,format=NV12,width=%d,height=%d,framerate=%d/1", requestedWidth, requestedHeight, frames);
				GstCaps* caps = gst.gst_caps_from_string (capsText);
				gst.g_object_set (filter, "caps", caps, NULL);
				gst.gst_mini_object_unref (caps);

				// Only the newest frame is kept
				gst.g_object_set (sink, "max-buffers", 1u, "drop", 1, "sync", 0, NULL);

				GstElement* elements[] = { source, convert, scale, rate, filter, sink };
				for (size_t i = 0; i < 6; i++) gst.gst_bin_add (pipeline, elements[i]);

				for (size_t i = 0; i + 1 < 6; i++) {

					if (!gst.gst_element_link (elements[i], elements[i + 1])) return false;

				}

				bus = gst.gst_element_get_bus (pipeline);

				// The device opens as the pipeline readies
				if (gst.gst_element_set_state (pipeline, GST_STATE_READY) == GST_STATE_CHANGE_FAILURE) return false;

				width = requestedWidth;
				height = requestedHeight;
				frameRate = frames;
				return true;

			}


			bool Start () {

				return pipeline && gst.gst_element_set_state (pipeline, GST_STATE_PLAYING) != GST_STATE_CHANGE_FAILURE;

			}


			void Stop () {

				if (pipeline) gst.gst_element_set_state (pipeline, GST_STATE_PAUSED);

			}


		protected:

			void Update () {

				if (!pipeline) return;

				void* message = gst.gst_bus_pop_filtered (bus, GST_MESSAGE_ERROR | GST_MESSAGE_EOS);

				if (message) {

					gst.gst_mini_object_unref (message);
					SetDisconnected ();
					return;

				}

				GstSample* newest = NULL;

				while (GstSample* sample = gst.gst_app_sink_try_pull_sample (sink, 0)) {

					if (newest) gst.gst_mini_object_unref (newest);
					newest = sample;

				}

				if (!newest) return;

				WriteSample (newest);
				gst.gst_mini_object_unref (newest);

			}


		private:

			void WriteSample (GstSample* sample) {

				GstBuffer* buffer = gst.gst_sample_get_buffer (sample);
				GstCaps* caps = gst.gst_sample_get_caps (sample);
				if (!buffer || !caps) return;

				int frameWidth = 0, frameHeight = 0;
				GstStructure* structure = gst.gst_caps_get_structure (caps, 0);
				gst.gst_structure_get_int (structure, "width", &frameWidth);
				gst.gst_structure_get_int (structure, "height", &frameHeight);
				if (frameWidth <= 0 || frameHeight <= 0) return;

				const char* matrix = gst.gst_structure_get_string (structure, "colorimetry");

				GstMapInfo map;
				if (!gst.gst_buffer_map (buffer, &map, GST_MAP_READ)) return;

				// GStreamer pads NV12 rows to 4 bytes, unless a video meta says otherwise
				int yStride = (frameWidth + 3) & ~3;
				int uvStride = yStride;
				size_t uvOffset = (size_t)yStride * ((frameHeight + 1) & ~1);

				GstVideoMeta* meta = videoMetaAPI ? (GstVideoMeta*)gst.gst_buffer_get_meta (buffer, videoMetaAPI) : NULL;

				if (meta && meta->n_planes >= 2) {

					yStride = meta->stride[0];
					uvStride = meta->stride[1];
					uvOffset = meta->offset[1];

				}

				if (uvOffset + (size_t)uvStride * ((frameHeight + 1) / 2) <= map.size) {

					VideoPlanes planes;
					planes.colorMatrix = (matrix && strstr (matrix, "709")) ? VIDEO_COLOR_MATRIX_BT709 : VIDEO_COLOR_MATRIX_BT601;
					planes.fullRange = matrix && strncmp (matrix, "1:", 2) == 0;
					planes.height = frameHeight;
					planes.transfer = VIDEO_COLOR_TRANSFER_SDR;
					planes.width = frameWidth;
					planes.y = map.data + (meta ? meta->offset[0] : 0);
					planes.yStride = yStride;
					planes.u = map.data + uvOffset;
					planes.v = planes.u + 1;
					planes.uvPixelStride = 2;
					planes.uvStride = uvStride;

					double time = buffer->pts != GST_CLOCK_TIME_NONE ? buffer->pts / 1000000000.0 : 0;
					PushFrame (&planes, time);

				}

				gst.gst_buffer_unmap (buffer, &map);

			}


			GstBus* bus;
			GstElement* pipeline;
			GstElement* sink;


	};


	bool CameraCapture::GetDevices (std::vector<CameraDeviceInfo>* devices) {

		if (!Load ()) return false;
		ListDevices (devices, NULL);
		return true;

	}


	int CameraCapture::GetPermissionStatus () {

		return 1;

	}


	bool CameraCapture::IsSupported () {

		return Load ();

	}


	CameraCapture* CameraCapture::Open (const char* id, int width, int height, double frameRate) {

		if (!Load ()) return NULL;

		GStreamerCameraCapture* capture = new GStreamerCameraCapture ();

		if (!capture->Open (id, width > 0 ? width : 640, height > 0 ? height : 480, frameRate > 0 ? frameRate : 30)) {

			delete capture;
			return NULL;

		}

		return capture;

	}


	void CameraCapture::RequestPermission () {}


}


#endif
