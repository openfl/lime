#include <media/VideoDecoder.h>


#ifdef LIME_VIDEO_GSTREAMER


#include <atomic>
#include <chrono>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>


namespace lime {


	// GStreamer is loaded at runtime, so Lime has no build or link dependency
	// on it. The few types and constants used here are declared by hand.

	typedef int gboolean;
	typedef void (*GCallback) ();

	struct GList;
	struct GstBus;
	struct GstCaps;
	struct GstElement;
	struct GstElementFactory;
	struct GstEvent;
	struct GstPad;
	struct GstSample;
	struct GstSegment;
	struct GstStructure;
	struct GstTagList;


	// Every GObject instance starts with a pointer to its class
	struct GTypeInstance {

		void* g_class;

	};


	// GStreamer 1.x keeps these public structures ABI stable. They follow
	// gstminiobject.h, gstbuffer.h, gstmemory.h, gstmessage.h, gstquery.h,
	// gstmeta.h and gstvideometa.h. Only GstMapInfo is allocated here, so the
	// others declare just their leading fields.

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


	struct GstMessage {

		GstMiniObject mini_object;
		int type;

	};


	struct GstMeta {

		int flags;
		const void* info;

	};


	struct GstQuery {

		GstMiniObject mini_object;
		int type;

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


	typedef int (*GstBusSyncHandler) (GstBus*, GstMessage*, void*);


	static const int GST_AUTOPLUG_SELECT_SKIP = 2;
	static const int GST_AUTOPLUG_SELECT_TRY = 0;
	static const int GST_BUS_DROP = 0;
	static const int GST_BUS_PASS = 1;
	static const uint64_t GST_CLOCK_TIME_NONE = (uint64_t)-1;
	static const uint64_t GST_ELEMENT_FACTORY_TYPE_DEMUXER = 1 << 5;
	static const int GST_EVENT_TAG = (80 << 8) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4);
	static const int GST_FORMAT_TIME = 3;
	static const int GST_MAP_READ = 1;
	static const int GST_MESSAGE_ASYNC_DONE = 1 << 21;
	static const int GST_MESSAGE_ERROR = 1 << 1;
	static const uint64_t GST_MSECOND = 1000000;
	static const int GST_PAD_LINK_OK = 0;
	static const int GST_PAD_SINK = 2;
	static const int GST_QUERY_CAPS = (170 << 8) | 3;
	static const int GST_RANK_MARGINAL = 64;
	static const uint64_t GST_SECOND = 1000000000;
	static const int GST_SEEK_FLAG_FLUSH = 1 << 0;
	static const int GST_SEEK_FLAG_KEY_UNIT = 1 << 2;
	static const int GST_SEEK_FLAG_SNAP_BEFORE = 1 << 5;
	static const int GST_STATE_CHANGE_ASYNC = 2;
	static const int GST_STATE_CHANGE_FAILURE = 0;
	static const int GST_STATE_CHANGE_NO_PREROLL = 3;
	static const int GST_STATE_NULL = 1;
	static const int GST_STATE_PAUSED = 3;
	static const int GST_STATE_PLAYING = 4;
	static const int GST_VIDEO_COLOR_MATRIX_BT2020 = 6;
	static const int GST_VIDEO_COLOR_MATRIX_BT601 = 4;
	static const int GST_VIDEO_COLOR_MATRIX_BT709 = 3;
	static const int GST_VIDEO_COLOR_MATRIX_FCC = 2;
	static const int GST_VIDEO_COLOR_MATRIX_RGB = 1;
	static const int GST_VIDEO_COLOR_MATRIX_SMPTE240M = 5;
	static const int GST_VIDEO_COLOR_MATRIX_UNKNOWN = 0;
	static const int GST_VIDEO_COLOR_RANGE_0_255 = 1;
	static const int GST_VIDEO_COLOR_RANGE_16_235 = 2;
	static const int GST_VIDEO_COLOR_RANGE_UNKNOWN = 0;
	static const int GST_VIDEO_TRANSFER_ARIB_STD_B67 = 15;
	static const int GST_VIDEO_TRANSFER_SMPTE2084 = 14;

	// A stalled stream fails after longer than souphttpsrc waits before it
	// reconnects, which is 15 seconds
	static const int DECODE_TIMEOUT_SECONDS = 20;
	static const unsigned int MAX_AUDIO_BUFFERS = 4;
	static const unsigned int MAX_VIDEO_BUFFERS = 2;
	static const int OPEN_TIMEOUT_SECONDS = 20;
	static const uint64_t PULL_INTERVAL = 100 * GST_MSECOND;

	// A hardware decoder that fails partway is replaced in software within this
	static const int SOFTWARE_REOPEN_SECONDS = 5;


	struct GStreamerLibrary {

		void (*g_free) (void*);
		void* (*g_object_class_find_property) (void*, const char*);
		void (*g_object_set) (void*, const char*, ...);
		unsigned long (*g_signal_connect_data) (void*, const char*, GCallback, void*, void*, int);
		gboolean (*gst_app_sink_is_eos) (GstElement*);
		GstSample* (*gst_app_sink_try_pull_sample) (GstElement*, uint64_t);
		gboolean (*gst_bin_add) (GstElement*, GstElement*);
		GstElement* (*gst_bin_new) (const char*);
		gboolean (*gst_bin_remove) (GstElement*, GstElement*);
		GstMeta* (*gst_buffer_get_meta) (GstBuffer*, size_t);
		gboolean (*gst_buffer_map) (GstBuffer*, GstMapInfo*, int);
		void (*gst_buffer_unmap) (GstBuffer*, GstMapInfo*);
		GstMessage* (*gst_bus_pop) (GstBus*);
		GstMessage* (*gst_bus_pop_filtered) (GstBus*, int);
		void (*gst_bus_set_sync_handler) (GstBus*, GstBusSyncHandler, void*, void*);
		GstMessage* (*gst_bus_timed_pop_filtered) (GstBus*, uint64_t, int);
		GstCaps* (*gst_caps_from_string) (const char*);
		unsigned int (*gst_caps_get_size) (const GstCaps*);
		GstStructure* (*gst_caps_get_structure) (const GstCaps*, unsigned int);
		gboolean (*gst_element_add_pad) (GstElement*, GstPad*);
		GstElementFactory* (*gst_element_factory_find) (const char*);
		const char* (*gst_element_factory_get_metadata) (GstElementFactory*, const char*);
		GList* (*gst_element_factory_list_filter) (GList*, const GstCaps*, int, gboolean);
		GList* (*gst_element_factory_list_get_elements) (uint64_t, int);
		GstElement* (*gst_element_factory_make) (const char*, const char*);
		GstBus* (*gst_element_get_bus) (GstElement*);
		GstElementFactory* (*gst_element_get_factory) (GstElement*);
		GstPad* (*gst_element_get_static_pad) (GstElement*, const char*);
		gboolean (*gst_element_link) (GstElement*, GstElement*);
		gboolean (*gst_element_query) (GstElement*, GstQuery*);
		gboolean (*gst_element_query_duration) (GstElement*, int, int64_t*);
		gboolean (*gst_element_seek_simple) (GstElement*, int, int, int64_t);
		int (*gst_element_set_state) (GstElement*, int);
		gboolean (*gst_element_sync_state_with_parent) (GstElement*);
		void (*gst_event_parse_tag) (GstEvent*, GstTagList**);
		char* (*gst_filename_to_uri) (const char*, void**);
		GstPad* (*gst_ghost_pad_new) (const char*, GstPad*);
		gboolean (*gst_init_check) (int*, char***, void**);
		void* (*gst_mini_object_ref) (void*);
		void (*gst_mini_object_unref) (void*);
		void* (*gst_object_ref_sink) (void*);
		void (*gst_object_unref) (void*);
		GstCaps* (*gst_pad_get_current_caps) (GstPad*);
		GstEvent* (*gst_pad_get_sticky_event) (GstPad*, int, unsigned int);
		int (*gst_pad_link) (GstPad*, GstPad*);
		gboolean (*gst_pad_query) (GstPad*, GstQuery*);
		GstCaps* (*gst_pad_query_caps) (GstPad*, GstCaps*);
		GstElement* (*gst_pipeline_new) (const char*);
		void (*gst_plugin_feature_list_free) (GList*);
		GstQuery* (*gst_query_new_seeking) (int);
		void (*gst_query_parse_seeking) (GstQuery*, int*, gboolean*, int64_t*, int64_t*);
		GstBuffer* (*gst_sample_get_buffer) (GstSample*);
		GstCaps* (*gst_sample_get_caps) (GstSample*);
		GstSegment* (*gst_sample_get_segment) (GstSample*);
		int (*gst_segment_to_stream_time_full) (const GstSegment*, int, uint64_t, uint64_t*);
		gboolean (*gst_structure_get_fraction) (const GstStructure*, const char*, int*, int*);
		gboolean (*gst_structure_get_int) (const GstStructure*, const char*, int*);
		const char* (*gst_structure_get_name) (const GstStructure*);
		const char* (*gst_structure_get_string) (const GstStructure*, const char*);
		gboolean (*gst_tag_list_get_string) (const GstTagList*, const char*, char**);
		size_t (*gst_video_meta_api_get_type) ();

	};


	static GStreamerLibrary gst;
	static std::once_flag loadFlag;
	static bool loaded = false;
	static size_t videoMetaAPI = 0;


	static bool LoadGStreamer () {

		std::call_once (loadFlag, [] {

			void* glib = dlopen ("libglib-2.0.so.0", RTLD_NOW | RTLD_LOCAL);
			void* gobject = dlopen ("libgobject-2.0.so.0", RTLD_NOW | RTLD_LOCAL);
			void* gstreamer = dlopen ("libgstreamer-1.0.so.0", RTLD_NOW | RTLD_LOCAL);
			void* app = dlopen ("libgstapp-1.0.so.0", RTLD_NOW | RTLD_LOCAL);

			if (!glib || !gobject || !gstreamer || !app) return;

			#define LIME_GST_REQUIRE(library, name) gst.name = (decltype (gst.name))dlsym (library, #name); if (!gst.name) return;

			LIME_GST_REQUIRE (glib, g_free);
			LIME_GST_REQUIRE (gobject, g_object_class_find_property);
			LIME_GST_REQUIRE (gobject, g_object_set);
			LIME_GST_REQUIRE (gobject, g_signal_connect_data);
			LIME_GST_REQUIRE (app, gst_app_sink_is_eos);
			LIME_GST_REQUIRE (app, gst_app_sink_try_pull_sample);
			LIME_GST_REQUIRE (gstreamer, gst_bin_add);
			LIME_GST_REQUIRE (gstreamer, gst_bin_new);
			LIME_GST_REQUIRE (gstreamer, gst_bin_remove);
			LIME_GST_REQUIRE (gstreamer, gst_buffer_get_meta);
			LIME_GST_REQUIRE (gstreamer, gst_buffer_map);
			LIME_GST_REQUIRE (gstreamer, gst_buffer_unmap);
			LIME_GST_REQUIRE (gstreamer, gst_bus_pop);
			LIME_GST_REQUIRE (gstreamer, gst_bus_pop_filtered);
			LIME_GST_REQUIRE (gstreamer, gst_bus_set_sync_handler);
			LIME_GST_REQUIRE (gstreamer, gst_bus_timed_pop_filtered);
			LIME_GST_REQUIRE (gstreamer, gst_caps_from_string);
			LIME_GST_REQUIRE (gstreamer, gst_caps_get_size);
			LIME_GST_REQUIRE (gstreamer, gst_caps_get_structure);
			LIME_GST_REQUIRE (gstreamer, gst_element_add_pad);
			LIME_GST_REQUIRE (gstreamer, gst_element_factory_find);
			LIME_GST_REQUIRE (gstreamer, gst_element_factory_get_metadata);
			LIME_GST_REQUIRE (gstreamer, gst_element_factory_list_filter);
			LIME_GST_REQUIRE (gstreamer, gst_element_factory_list_get_elements);
			LIME_GST_REQUIRE (gstreamer, gst_element_factory_make);
			LIME_GST_REQUIRE (gstreamer, gst_element_get_bus);
			LIME_GST_REQUIRE (gstreamer, gst_element_get_factory);
			LIME_GST_REQUIRE (gstreamer, gst_element_get_static_pad);
			LIME_GST_REQUIRE (gstreamer, gst_element_link);
			LIME_GST_REQUIRE (gstreamer, gst_element_query_duration);
			LIME_GST_REQUIRE (gstreamer, gst_element_seek_simple);
			LIME_GST_REQUIRE (gstreamer, gst_element_set_state);
			LIME_GST_REQUIRE (gstreamer, gst_element_sync_state_with_parent);
			LIME_GST_REQUIRE (gstreamer, gst_filename_to_uri);
			LIME_GST_REQUIRE (gstreamer, gst_ghost_pad_new);
			LIME_GST_REQUIRE (gstreamer, gst_init_check);
			LIME_GST_REQUIRE (gstreamer, gst_mini_object_ref);
			LIME_GST_REQUIRE (gstreamer, gst_mini_object_unref);
			LIME_GST_REQUIRE (gstreamer, gst_object_ref_sink);
			LIME_GST_REQUIRE (gstreamer, gst_object_unref);
			LIME_GST_REQUIRE (gstreamer, gst_pad_get_current_caps);
			LIME_GST_REQUIRE (gstreamer, gst_pad_link);
			LIME_GST_REQUIRE (gstreamer, gst_pad_query);
			LIME_GST_REQUIRE (gstreamer, gst_pad_query_caps);
			LIME_GST_REQUIRE (gstreamer, gst_pipeline_new);
			LIME_GST_REQUIRE (gstreamer, gst_plugin_feature_list_free);
			LIME_GST_REQUIRE (gstreamer, gst_sample_get_buffer);
			LIME_GST_REQUIRE (gstreamer, gst_sample_get_caps);
			LIME_GST_REQUIRE (gstreamer, gst_sample_get_segment);
			LIME_GST_REQUIRE (gstreamer, gst_segment_to_stream_time_full);
			LIME_GST_REQUIRE (gstreamer, gst_structure_get_fraction);
			LIME_GST_REQUIRE (gstreamer, gst_structure_get_int);
			LIME_GST_REQUIRE (gstreamer, gst_structure_get_name);
			LIME_GST_REQUIRE (gstreamer, gst_structure_get_string);

			#undef LIME_GST_REQUIRE

			// Tags give the rotation, and queries whether a stream can seek, where
			// the library has them
			#define LIME_GST_OPTIONAL(library, name) gst.name = (decltype (gst.name))dlsym (library, #name);

			LIME_GST_OPTIONAL (gstreamer, gst_element_query);
			LIME_GST_OPTIONAL (gstreamer, gst_event_parse_tag);
			LIME_GST_OPTIONAL (gstreamer, gst_pad_get_sticky_event);
			LIME_GST_OPTIONAL (gstreamer, gst_query_new_seeking);
			LIME_GST_OPTIONAL (gstreamer, gst_query_parse_seeking);
			LIME_GST_OPTIONAL (gstreamer, gst_tag_list_get_string);

			#undef LIME_GST_OPTIONAL

			// Video metas describe padded frames, and are read when available
			void* video = dlopen ("libgstvideo-1.0.so.0", RTLD_NOW | RTLD_LOCAL);
			if (video) gst.gst_video_meta_api_get_type = (decltype (gst.gst_video_meta_api_get_type))dlsym (video, "gst_video_meta_api_get_type");

			if (!gst.gst_init_check (NULL, NULL, NULL)) return;

			// The elements come from the core, base and app plugins
			static const char* factories[] = { "appsink", "audioconvert", "fakesink", "uridecodebin", "videoconvert" };

			for (size_t i = 0; i < sizeof (factories) / sizeof (factories[0]); i++) {

				GstElementFactory* factory = gst.gst_element_factory_find (factories[i]);
				if (!factory) return;
				gst.gst_object_unref (factory);

			}

			if (gst.gst_video_meta_api_get_type) videoMetaAPI = gst.gst_video_meta_api_get_type ();

			loaded = true;

		});

		return loaded;

	}


	static GstElement* AddElement (GstElement* bin, const char* factory) {

		GstElement* element = gst.gst_element_factory_make (factory, NULL);
		if (element) gst.gst_bin_add (bin, element);
		return element;

	}


	// GStreamer writes the predefined colorimetries by name, and the others as
	// range:matrix:transfer:primaries
	static void GetColorimetry (const char* colorimetry, int* range, int* matrix, int* transfer) {

		static const struct { const char* name; int range; int matrix; int transfer; } names[] = {

			{ "bt2020", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_BT2020, 0 },
			{ "bt2020-10", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_BT2020, 0 },
			{ "bt2100-hlg", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_BT2020, GST_VIDEO_TRANSFER_ARIB_STD_B67 },
			{ "bt2100-pq", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_BT2020, GST_VIDEO_TRANSFER_SMPTE2084 },
			{ "bt601", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_BT601, 0 },
			{ "bt709", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_BT709, 0 },
			{ "smpte240m", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_SMPTE240M, 0 },
			{ "sRGB", GST_VIDEO_COLOR_RANGE_0_255, GST_VIDEO_COLOR_MATRIX_RGB, 0 }

		};

		*range = GST_VIDEO_COLOR_RANGE_UNKNOWN;
		*matrix = GST_VIDEO_COLOR_MATRIX_UNKNOWN;
		*transfer = 0;

		if (!colorimetry) return;

		for (size_t i = 0; i < sizeof (names) / sizeof (names[0]); i++) {

			if (strcmp (colorimetry, names[i].name) == 0) {

				*range = names[i].range;
				*matrix = names[i].matrix;
				*transfer = names[i].transfer;
				return;

			}

		}

		// Parsed by hand, since glibc 2.38 builds link sscanf to a symbol that
		// older systems lack
		const char* matrixText = strchr (colorimetry, ':');
		if (!matrixText) return;

		for (const char* c = colorimetry; *c >= '0' && *c <= '9'; c++) *range = *range * 10 + (*c - '0');
		for (const char* c = matrixText + 1; *c >= '0' && *c <= '9'; c++) *matrix = *matrix * 10 + (*c - '0');

		const char* transferText = strchr (matrixText + 1, ':');
		if (transferText) for (const char* c = transferText + 1; *c >= '0' && *c <= '9'; c++) *transfer = *transfer * 10 + (*c - '0');

	}


	static GstStructure* GetStructure (GstCaps* caps) {

		return (caps && gst.gst_caps_get_size (caps) > 0) ? gst.gst_caps_get_structure (caps, 0) : NULL;

	}


	static double GetTime (GstSample* sample, double position) {

		GstBuffer* buffer = gst.gst_sample_get_buffer (sample);
		if (!buffer || buffer->pts == GST_CLOCK_TIME_NONE) return position;

		// Stream time applies edit lists, and is the time that seeks use
		GstSegment* segment = gst.gst_sample_get_segment (sample);
		uint64_t time = 0;
		int sign = segment ? gst.gst_segment_to_stream_time_full (segment, GST_FORMAT_TIME, buffer->pts, &time) : 0;

		if (sign == 0) return (double)buffer->pts / GST_SECOND;
		return sign > 0 ? (double)time / GST_SECOND : -(double)time / GST_SECOND;

	}


	static std::string GetURI (const char* path) {

		if (strstr (path, "://")) return path;

		char* uri = gst.gst_filename_to_uri (path, NULL);
		if (!uri) return std::string ();

		std::string result (uri);
		gst.g_free (uri);
		return result;

	}


	static bool HasClass (GstElementFactory* factory, const char* name) {

		const char* klass = factory ? gst.gst_element_factory_get_metadata (factory, "klass") : NULL;
		return klass && strstr (klass, name);

	}


	static bool IsAudio (const char* mediaType) {

		return strncmp (mediaType, "audio/", 6) == 0;

	}


	static bool IsSubtitle (const char* mediaType) {

		static const char* prefixes[] = { "text/", "subpicture/", "closedcaption/", "application/x-ass", "application/x-ssa", "application/x-sub", "application/x-teletext", "application/x-kate", "application/x-usf", "application/ttml" };

		for (size_t i = 0; i < sizeof (prefixes) / sizeof (prefixes[0]); i++) {

			if (strncmp (mediaType, prefixes[i], strlen (prefixes[i])) == 0) return true;

		}

		return false;

	}


	static bool IsVideo (const char* mediaType) {

		return strncmp (mediaType, "video/", 6) == 0 || strncmp (mediaType, "image/", 6) == 0;

	}


	// One pipeline decoding one stream type. The converter and appsink wait in
	// a bin until uridecodebin exposes a raw stream of that type.
	class GStreamerStream {


		public:

			GStreamerStream ();
			~GStreamerStream ();

			void CancelSeek ();
			void Close ();
			GstCaps* GetCaps ();
			double GetDuration ();
			int GetRotation ();
			void Interrupt ();
			bool IsInterrupted ();
			bool IsSeekable ();
			bool Open (const char* uri, bool video, bool hardware, std::chrono::steady_clock::time_point deadline);
			void Play ();
			void PrepareSeek ();
			VideoDecodeResult Pull (GstSample** sample);
			bool Seek (double time);
			void SetCaps (const char* caps);

			std::atomic<bool> foundAudio;
			std::atomic<bool> foundUnsupported;
			GstElement* pipeline;
			std::atomic<bool> triedHardware;

		private:

			static gboolean AutoplugContinue (GstElement* decodeBin, GstPad* pad, GstCaps* caps, void* data);
			static gboolean AutoplugQuery (GstElement* decodeBin, GstPad* pad, GstElement* element, GstQuery* query, void* data);
			static int AutoplugSelect (GstElement* decodeBin, GstPad* pad, GstCaps* caps, GstElementFactory* factory, void* data);
			static int BusSync (GstBus* bus, GstMessage* message, void* data);
			static void ElementAdded (GstElement* pipeline, GstElement* bin, GstElement* element, void* data);
			static void PadAdded (GstElement* decodeBin, GstPad* pad, void* data);
			static void UnknownType (GstElement* decodeBin, GstPad* pad, GstCaps* caps, void* data);

			void FlushBus ();
			bool Preroll (std::chrono::steady_clock::time_point deadline);

			GstElement* appSink;
			GstElement* bin;
			GstBus* bus;
			bool hardware;
			std::atomic<bool> interrupted;
			std::atomic<bool> linked;
			std::atomic<bool> seeking;
			bool video;


	};


	GStreamerStream::GStreamerStream () {

		appSink = NULL;
		bin = NULL;
		bus = NULL;
		foundAudio = false;
		foundUnsupported = false;
		hardware = false;
		interrupted = false;
		linked = false;
		pipeline = NULL;
		seeking = false;
		triedHardware = false;
		video = false;

	}


	GStreamerStream::~GStreamerStream () {

		Close ();

	}


	gboolean GStreamerStream::AutoplugContinue (GstElement* decodeBin, GstPad* pad, GstCaps* caps, void* data) {

		GStreamerStream* stream = (GStreamerStream*)data;

		GstStructure* structure = GetStructure (caps);
		const char* name = structure ? gst.gst_structure_get_name (structure) : "";
		bool audio = IsAudio (name);
		bool video = IsVideo (name);

		// Subtitles and captions are exposed undecoded, so a missing or failing
		// decoder for them does not stop the video
		if (IsSubtitle (name)) return false;
		if (!audio && !video) return true;

		// Containers such as video/quicktime are demuxed further. Elementary
		// streams of the other type are exposed undecoded, so each pipeline
		// only decodes its own stream.
		GList* demuxers = gst.gst_element_factory_list_get_elements (GST_ELEMENT_FACTORY_TYPE_DEMUXER, GST_RANK_MARGINAL);
		GList* matches = gst.gst_element_factory_list_filter (demuxers, caps, GST_PAD_SINK, false);
		bool container = (matches != NULL);
		gst.gst_plugin_feature_list_free (matches);
		gst.gst_plugin_feature_list_free (demuxers);

		if (container) return true;

		if (audio) stream->foundAudio = true;

		return stream->video ? !audio : !video;

	}


	gboolean GStreamerStream::AutoplugQuery (GstElement* decodeBin, GstPad* pad, GstElement* element, GstQuery* query, void* data) {

		GStreamerStream* stream = (GStreamerStream*)data;

		// Decoders choose their output before decodebin exposes them, so answer
		// with what the converter reads. Hardware decoders would otherwise
		// choose video memory that it cannot map.
		if (query->type != GST_QUERY_CAPS) return false;

		GstElementFactory* factory = gst.gst_element_get_factory (element);
		if (!HasClass (factory, "Decoder") || !HasClass (factory, stream->video ? "Video" : "Audio")) return false;

		GstPad* sinkPad = gst.gst_element_get_static_pad (stream->bin, "sink");
		gboolean result = gst.gst_pad_query (sinkPad, query);
		gst.gst_object_unref (sinkPad);
		return result;

	}


	int GStreamerStream::AutoplugSelect (GstElement* decodeBin, GstPad* pad, GstCaps* caps, GstElementFactory* factory, void* data) {

		GStreamerStream* stream = (GStreamerStream*)data;

		// Decoders are chosen by rank, so hardware decoding can only be turned off
		if (!HasClass (factory, "Hardware")) return GST_AUTOPLUG_SELECT_TRY;
		if (!stream->hardware) return GST_AUTOPLUG_SELECT_SKIP;

		stream->triedHardware = true;
		return GST_AUTOPLUG_SELECT_TRY;

	}


	int GStreamerStream::BusSync (GstBus* bus, GstMessage* message, void* data) {

		// Only errors and prerolling are read, so nothing else is queued. A
		// sync handler owns the messages that it drops.
		if (message->type == GST_MESSAGE_ERROR || message->type == GST_MESSAGE_ASYNC_DONE) return GST_BUS_PASS;

		gst.gst_mini_object_unref (message);
		return GST_BUS_DROP;

	}


	void GStreamerStream::Close () {

		if (pipeline) gst.gst_element_set_state (pipeline, GST_STATE_NULL);

		if (bus) {

			// Queued messages hold references to the pipeline
			FlushBus ();
			gst.gst_object_unref (bus);
			bus = NULL;

		}

		if (pipeline) {

			gst.gst_object_unref (pipeline);
			pipeline = NULL;

		}

		if (bin) {

			gst.gst_object_unref (bin);
			bin = NULL;

		}

		appSink = NULL;
		seeking = false;

	}


	void GStreamerStream::ElementAdded (GstElement* pipeline, GstElement* bin, GstElement* element, void* data) {

		// libav decoders write into buffers that GStreamer allocates. When a
		// seek changes the output size while their frame threads still hold
		// buffers, GStreamer 1.24 fails an assertion and aborts the process.
		// Copying each decoded frame instead avoids that path.
		if (gst.g_object_class_find_property (((GTypeInstance*)element)->g_class, "direct-rendering")) {

			gst.g_object_set (element, "direct-rendering", false, NULL);

		}

	}


	void GStreamerStream::FlushBus () {

		GstMessage* message;
		while ((message = gst.gst_bus_pop (bus))) gst.gst_mini_object_unref (message);

	}


	GstCaps* GStreamerStream::GetCaps () {

		GstPad* pad = gst.gst_element_get_static_pad (appSink, "sink");
		GstCaps* caps = gst.gst_pad_get_current_caps (pad);
		gst.gst_object_unref (pad);
		return caps;

	}


	double GStreamerStream::GetDuration () {

		int64_t duration = 0;
		return (gst.gst_element_query_duration (pipeline, GST_FORMAT_TIME, &duration) && duration > 0) ? (double)duration / GST_SECOND : 0;

	}


	int GStreamerStream::GetRotation () {

		if (!appSink || !gst.gst_pad_get_sticky_event || !gst.gst_event_parse_tag || !gst.gst_tag_list_get_string) return 0;

		// Demuxers tag a stream with the turn that shows it upright, such as
		// rotate-90 for a quarter clockwise, and the tags follow it to the sink.
		// Flipped orientations are taken as their rotation.
		GstPad* pad = gst.gst_element_get_static_pad (appSink, "sink");
		int rotation = 0;

		for (unsigned int i = 0; i < 4; i++) {

			GstEvent* event = gst.gst_pad_get_sticky_event (pad, GST_EVENT_TAG, i);
			if (!event) break;

			GstTagList* tags = NULL;
			char* orientation = NULL;
			gst.gst_event_parse_tag (event, &tags);

			if (tags && gst.gst_tag_list_get_string (tags, "image-orientation", &orientation)) {

				const char* turn = orientation ? strstr (orientation, "rotate-") : NULL;
				if (turn) rotation = atoi (turn + 7);
				gst.g_free (orientation);

			}

			gst.gst_mini_object_unref (event);

		}

		gst.gst_object_unref (pad);
		return rotation;

	}


	bool GStreamerStream::IsInterrupted () {

		return interrupted;

	}


	bool GStreamerStream::IsSeekable () {

		// A stream that says it cannot seek, such as a live one, is not asked to.
		// One that does not say is tried.
		if (!pipeline || !gst.gst_query_new_seeking || !gst.gst_element_query || !gst.gst_query_parse_seeking) return true;

		GstQuery* query = gst.gst_query_new_seeking (GST_FORMAT_TIME);
		if (!query) return true;

		gboolean seekable = true;
		if (gst.gst_element_query (pipeline, query)) gst.gst_query_parse_seeking (query, NULL, &seekable, NULL, NULL);
		gst.gst_mini_object_unref (query);

		return seekable != 0;

	}


	bool GStreamerStream::Open (const char* uri, bool video, bool hardware, std::chrono::steady_clock::time_point deadline) {

		Close ();

		foundAudio = false;
		foundUnsupported = false;
		this->hardware = hardware;
		interrupted = false;
		linked = false;
		seeking = false;
		triedHardware = false;
		this->video = video;

		pipeline = (GstElement*)gst.gst_object_ref_sink (gst.gst_pipeline_new (NULL));
		bin = (GstElement*)gst.gst_object_ref_sink (gst.gst_bin_new (NULL));
		bus = gst.gst_element_get_bus (pipeline);
		gst.gst_bus_set_sync_handler (bus, BusSync, NULL, NULL);
		gst.g_signal_connect_data (pipeline, "deep-element-added", (GCallback)ElementAdded, this, NULL, 0);

		GstElement* decodeBin = AddElement (pipeline, "uridecodebin");
		GstElement* convert = AddElement (bin, video ? "videoconvert" : "audioconvert");

		// Interlaced video is deinterlaced, after conversion so the deinterlacer
		// does not limit the formats decoders can give, and sound is resampled
		// once its format is fixed. Progressive video and sound at that format
		// pass through, and either is left out where its plugin is missing.
		GstElement* adjust = AddElement (bin, video ? "deinterlace" : "audioresample");
		appSink = AddElement (bin, "appsink");

		if (!decodeBin || !convert || !appSink) {

			Close ();
			return false;

		}

		if (adjust && !(gst.gst_element_link (convert, adjust) && gst.gst_element_link (adjust, appSink))) {

			gst.gst_bin_remove (bin, adjust);
			adjust = NULL;

		}

		if (!adjust && !gst.gst_element_link (convert, appSink)) {

			Close ();
			return false;

		}

		if (video && gst.g_object_class_find_property (((GTypeInstance*)convert)->g_class, "n-threads")) {

			// Converting 10-bit video to 8-bit uses every core
			gst.g_object_set (convert, "n-threads", 0, NULL);

		}

		GstPad* convertPad = gst.gst_element_get_static_pad (convert, "sink");
		gst.gst_element_add_pad (bin, gst.gst_ghost_pad_new ("sink", convertPad));
		gst.gst_object_unref (convertPad);

		// audioconvert downmixes to stereo at the source rate. Frames are taken
		// as NV12, or as the I420 that software decoders give, without repacking.
		GstCaps* caps = gst.gst_caps_from_string (video ? "video/x-raw,format=(string){ NV12, I420 }" : "audio/x-raw,format=S16LE,layout=interleaved,channels=[1,2]");
		gst.g_object_set (appSink, "caps", caps, "drop", false, "enable-last-sample", false, "max-buffers", video ? MAX_VIDEO_BUFFERS : MAX_AUDIO_BUFFERS, "sync", false, NULL);
		gst.gst_mini_object_unref (caps);

		gst.g_object_set (decodeBin, "uri", uri, NULL);
		gst.g_signal_connect_data (decodeBin, "autoplug-continue", (GCallback)AutoplugContinue, this, NULL, 0);
		gst.g_signal_connect_data (decodeBin, "autoplug-query", (GCallback)AutoplugQuery, this, NULL, 0);
		gst.g_signal_connect_data (decodeBin, "autoplug-select", (GCallback)AutoplugSelect, this, NULL, 0);
		gst.g_signal_connect_data (decodeBin, "pad-added", (GCallback)PadAdded, this, NULL, 0);
		gst.g_signal_connect_data (decodeBin, "unknown-type", (GCallback)UnknownType, this, NULL, 0);

		if (!Preroll (deadline) || !linked) {

			Close ();
			return false;

		}

		return true;

	}


	void GStreamerStream::PadAdded (GstElement* decodeBin, GstPad* pad, void* data) {

		GStreamerStream* stream = (GStreamerStream*)data;

		GstCaps* caps = gst.gst_pad_get_current_caps (pad);
		if (!caps) caps = gst.gst_pad_query_caps (pad, NULL);

		GstStructure* structure = GetStructure (caps);
		const char* name = structure ? gst.gst_structure_get_name (structure) : "";
		bool raw = strcmp (name, stream->video ? "video/x-raw" : "audio/x-raw") == 0;

		if (IsAudio (name)) stream->foundAudio = true;

		if (caps) gst.gst_mini_object_unref (caps);

		if (raw && !stream->linked && gst.gst_bin_add (stream->pipeline, stream->bin)) {

			GstPad* sinkPad = gst.gst_element_get_static_pad (stream->bin, "sink");
			bool linked = (gst.gst_pad_link (pad, sinkPad) == GST_PAD_LINK_OK);
			gst.gst_object_unref (sinkPad);

			if (linked) {

				gst.gst_element_sync_state_with_parent (stream->bin);
				stream->linked = true;
				return;

			}

			gst.gst_bin_remove (stream->pipeline, stream->bin);

		}

		// Discard the other streams
		GstElement* sink = gst.gst_element_factory_make ("fakesink", NULL);
		if (!sink) return;

		gst.g_object_set (sink, "async", false, "enable-last-sample", false, "sync", false, NULL);
		gst.gst_bin_add (stream->pipeline, sink);

		GstPad* sinkPad = gst.gst_element_get_static_pad (sink, "sink");
		gst.gst_pad_link (pad, sinkPad);
		gst.gst_object_unref (sinkPad);

		gst.gst_element_sync_state_with_parent (sink);

	}


	void GStreamerStream::CancelSeek () {

		seeking = false;

	}


	void GStreamerStream::Play () {

		gst.gst_element_set_state (pipeline, GST_STATE_PLAYING);

	}


	void GStreamerStream::PrepareSeek () {

		seeking = true;

	}


	bool GStreamerStream::Preroll (std::chrono::steady_clock::time_point deadline) {

		int result = gst.gst_element_set_state (pipeline, GST_STATE_PAUSED);

		if (result == GST_STATE_CHANGE_FAILURE) return false;

		if (result == GST_STATE_CHANGE_NO_PREROLL) {

			// A live source, such as RTSP, only produces data while playing, so it
			// plays until its stream is linked and has a format
			if (gst.gst_element_set_state (pipeline, GST_STATE_PLAYING) == GST_STATE_CHANGE_FAILURE) return false;

			while (std::chrono::steady_clock::now () < deadline) {

				GstMessage* message = gst.gst_bus_pop_filtered (bus, GST_MESSAGE_ERROR);

				if (message) {

					gst.gst_mini_object_unref (message);
					return false;

				}

				if (linked) {

					GstCaps* caps = GetCaps ();

					if (caps) {

						gst.gst_mini_object_unref (caps);
						return true;

					}

				}

				std::this_thread::sleep_for (std::chrono::milliseconds (10));

			}

			return false;

		}

		if (result != GST_STATE_CHANGE_ASYNC) return true;

		// An error does not end the pending state change, so wait for either
		int64_t timeout = std::chrono::duration_cast<std::chrono::nanoseconds> (deadline - std::chrono::steady_clock::now ()).count ();
		GstMessage* message = gst.gst_bus_timed_pop_filtered (bus, timeout > 0 ? (uint64_t)timeout : 0, GST_MESSAGE_ASYNC_DONE | GST_MESSAGE_ERROR);
		if (!message) return false;

		bool prerolled = (message->type == GST_MESSAGE_ASYNC_DONE);
		gst.gst_mini_object_unref (message);
		return prerolled;

	}


	VideoDecodeResult GStreamerStream::Pull (GstSample** sample) {

		std::chrono::steady_clock::time_point deadline = std::chrono::steady_clock::now () + std::chrono::seconds (DECODE_TIMEOUT_SECONDS);

		while (true) {

			*sample = gst.gst_app_sink_try_pull_sample (appSink, PULL_INTERVAL);
			if (*sample) return VIDEO_DECODE_OK;

			if (interrupted) return VIDEO_DECODE_ERROR;

			// A seek is waiting for this stream, which can be stalled on a network
			if (seeking) return VIDEO_DECODE_AGAIN;

			if (gst.gst_app_sink_is_eos (appSink)) return VIDEO_DECODE_END;

			// An error stops the stream without an end of stream
			GstMessage* message = gst.gst_bus_pop_filtered (bus, GST_MESSAGE_ERROR);

			if (message) {

				gst.gst_mini_object_unref (message);
				return VIDEO_DECODE_ERROR;

			}

			if (std::chrono::steady_clock::now () >= deadline) return VIDEO_DECODE_ERROR;

		}

	}


	void GStreamerStream::Interrupt () {

		interrupted = true;

	}


	bool GStreamerStream::Seek (double time) {

		// A flushing seek restarts a stream that stopped with an error
		seeking = false;
		FlushBus ();

		int flags = GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_KEY_UNIT | GST_SEEK_FLAG_SNAP_BEFORE;
		return gst.gst_element_seek_simple (pipeline, GST_FORMAT_TIME, flags, (int64_t)(time * GST_SECOND));

	}


	void GStreamerStream::SetCaps (const char* caps) {

		GstCaps* value = gst.gst_caps_from_string (caps);
		if (!value) return;

		gst.g_object_set (appSink, "caps", value, NULL);
		gst.gst_mini_object_unref (value);

	}


	void GStreamerStream::UnknownType (GstElement* decodeBin, GstPad* pad, GstCaps* caps, void* data) {

		GStreamerStream* stream = (GStreamerStream*)data;

		// A stream that nothing installed can decode, such as one in a codec
		// whose plugin is missing
		GstStructure* structure = GetStructure (caps);
		const char* name = structure ? gst.gst_structure_get_name (structure) : "";

		if (IsAudio (name)) stream->foundAudio = true;
		if (stream->video ? IsVideo (name) : IsAudio (name)) stream->foundUnsupported = true;

	}


	class GStreamerVideoBackend : public VideoBackend {


		public:

			GStreamerVideoBackend ();
			~GStreamerVideoBackend ();

			virtual void Close ();
			virtual VideoDecodeResult DecodeAudio (std::vector<unsigned char>* pcm, double* time);
			virtual VideoDecodeResult DecodeVideo (VideoPlanes* planes, double* time, double* duration);
			virtual void Interrupt ();
			virtual bool Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info);
			virtual void PrepareSeek ();
			virtual bool Seek (double time);

		private:

			void ReadVideoFormat (GstCaps* caps);
			bool ReopenVideoInSoftware ();
			void UnmapVideo ();

			GStreamerStream audio;
			int audioChannels;
			double audioPosition;
			int audioSampleRate;
			VideoColorMatrix colorMatrix;
			VideoColorTransfer colorTransfer;
			double frameRate;
			bool fullRange;
			int height;
			std::atomic<bool> interrupted;
			double lastFrameTime;
			double pixelAspectRatio;
			bool planar;
			double skipUntil;
			std::string uri;
			GStreamerStream video;
			GstCaps* videoCaps;
			GstMapInfo videoMap;
			double videoPosition;
			GstSample* videoSample;
			int width;


	};


	GStreamerVideoBackend::GStreamerVideoBackend () {

		audioChannels = 0;
		audioPosition = 0;
		audioSampleRate = 0;
		colorMatrix = VIDEO_COLOR_MATRIX_BT709;
		colorTransfer = VIDEO_COLOR_TRANSFER_SDR;
		frameRate = 0;
		fullRange = false;
		height = 0;
		interrupted = false;
		lastFrameTime = -1;
		pixelAspectRatio = 0;
		planar = false;
		skipUntil = -1;
		videoCaps = NULL;
		memset (&videoMap, 0, sizeof (videoMap));
		videoPosition = 0;
		videoSample = NULL;
		width = 0;

	}


	GStreamerVideoBackend::~GStreamerVideoBackend () {

		Close ();

	}


	void GStreamerVideoBackend::Close () {

		UnmapVideo ();

		video.Close ();
		audio.Close ();

		if (videoCaps) {

			gst.gst_mini_object_unref (videoCaps);
			videoCaps = NULL;

		}

		audioChannels = 0;
		audioPosition = 0;
		audioSampleRate = 0;
		frameRate = 0;
		height = 0;
		lastFrameTime = -1;
		pixelAspectRatio = 0;
		planar = false;
		skipUntil = -1;
		videoPosition = 0;
		width = 0;

	}


	VideoDecodeResult GStreamerVideoBackend::DecodeAudio (std::vector<unsigned char>* pcm, double* time) {

		if (!audio.pipeline) return VIDEO_DECODE_END;

		GstSample* sample = NULL;
		VideoDecodeResult result = audio.Pull (&sample);
		if (result != VIDEO_DECODE_OK) return result;

		GstBuffer* buffer = gst.gst_sample_get_buffer (sample);
		GstMapInfo map;

		if (!buffer || !gst.gst_buffer_map (buffer, &map, GST_MAP_READ)) {

			gst.gst_mini_object_unref (sample);
			return VIDEO_DECODE_ERROR;

		}

		*time = GetTime (sample, audioPosition);
		pcm->insert (pcm->end (), map.data, map.data + map.size);
		audioPosition = *time + (double)map.size / (audioSampleRate * audioChannels * 2);

		gst.gst_buffer_unmap (buffer, &map);
		gst.gst_mini_object_unref (sample);

		return VIDEO_DECODE_OK;

	}


	VideoDecodeResult GStreamerVideoBackend::DecodeVideo (VideoPlanes* planes, double* time, double* duration) {

		UnmapVideo ();

		if (!video.pipeline) return VIDEO_DECODE_END;

		GstSample* sample = NULL;
		VideoDecodeResult result;

		while (true) {

			result = video.Pull (&sample);

			// A hardware decoder can fail on a stream it accepted, such as after a
			// seek or a change of size, so decoding carries on in software
			if (result == VIDEO_DECODE_ERROR && video.triedHardware && !video.IsInterrupted () && ReopenVideoInSoftware ()) continue;

			if (result != VIDEO_DECODE_OK) return result;

			// After reopening, the frames up to the last one returned are skipped
			if (skipUntil >= 0) {

				double time = GetTime (sample, videoPosition);

				if (time <= skipUntil + 0.0001) {

					gst.gst_mini_object_unref (sample);
					continue;

				}

				skipUntil = -1;

			}

			break;

		}

		GstCaps* caps = gst.gst_sample_get_caps (sample);

		if (caps && caps != videoCaps) {

			if (videoCaps) gst.gst_mini_object_unref (videoCaps);
			videoCaps = (GstCaps*)gst.gst_mini_object_ref (caps);
			ReadVideoFormat (videoCaps);

		}

		GstBuffer* buffer = gst.gst_sample_get_buffer (sample);

		if (!buffer || !gst.gst_buffer_map (buffer, &videoMap, GST_MAP_READ)) {

			gst.gst_mini_object_unref (sample);
			return VIDEO_DECODE_ERROR;

		}

		videoSample = sample;

		// Without a video meta the frame has GStreamer's default layout: NV12
		// with interleaved chroma, or I420 with a plane for each
		GstVideoMeta* meta = videoMetaAPI ? (GstVideoMeta*)gst.gst_buffer_get_meta (buffer, videoMetaAPI) : NULL;
		size_t offsets[3] = { 0, 0, 0 };
		int strides[3] = { 0, 0, 0 };
		unsigned int planeCount = planar ? 3 : 2;

		if (meta && meta->n_planes == planeCount) {

			for (unsigned int i = 0; i < planeCount; i++) {

				offsets[i] = meta->offset[i];
				strides[i] = meta->stride[i];

			}

		} else if (planar) {

			strides[0] = (width + 3) & ~3;
			strides[1] = ((((width + 1) & ~1) / 2) + 3) & ~3;
			strides[2] = strides[1];
			offsets[1] = (size_t)strides[0] * ((height + 1) & ~1);
			offsets[2] = offsets[1] + (size_t)strides[1] * (((height + 1) & ~1) / 2);

		} else {

			strides[0] = (width + 3) & ~3;
			strides[1] = strides[0];
			offsets[1] = (size_t)strides[0] * ((height + 1) & ~1);

		}

		int chromaHeight = (height + 1) / 2;
		int chromaRow = planar ? (width + 1) / 2 : ((width + 1) / 2) * 2;
		bool valid = width > 0 && height > 0 && strides[0] >= width && strides[1] >= chromaRow
			&& offsets[0] + (size_t)strides[0] * (height - 1) + width <= videoMap.size
			&& offsets[1] + (size_t)strides[1] * (chromaHeight - 1) + chromaRow <= videoMap.size;

		// Both chroma planes share a stride
		if (planar) valid = valid && strides[2] == strides[1] && offsets[2] + (size_t)strides[2] * (chromaHeight - 1) + chromaRow <= videoMap.size;

		if (!valid) {

			UnmapVideo ();
			return VIDEO_DECODE_ERROR;

		}

		planes->colorMatrix = colorMatrix;
		planes->fullRange = fullRange;
		planes->transfer = colorTransfer;
		planes->width = width;
		planes->height = height;
		planes->y = videoMap.data + offsets[0];
		planes->yStride = strides[0];
		planes->u = videoMap.data + offsets[1];
		planes->v = planar ? videoMap.data + offsets[2] : planes->u + 1;
		planes->uvStride = strides[1];
		planes->uvPixelStride = planar ? 1 : 2;

		// A frame without a timestamp follows the one before it. Without a
		// duration or frame rate either, frames are spaced as at 30 fps, as frames
		// that all had the same time would play as fast as they are decoded.
		*time = GetTime (sample, videoPosition);
		*duration = buffer->duration != GST_CLOCK_TIME_NONE ? (double)buffer->duration / GST_SECOND : (frameRate > 0 ? 1.0 / frameRate : 1.0 / 30);
		lastFrameTime = *time;
		videoPosition = *time + *duration;

		return VIDEO_DECODE_OK;

	}


	void GStreamerVideoBackend::Interrupt () {

		// Kept for the backend too, as reopening the video in software starts a
		// new stream, which would not know it was interrupted
		interrupted = true;
		audio.Interrupt ();
		video.Interrupt ();

	}


	bool GStreamerVideoBackend::Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info) {

		Close ();
		interrupted = false;

		if (!path || !path[0]) return false;

		uri = GetURI (path);
		if (uri.empty ()) return false;

		// The pipelines share one timeout, so a stalled source fails once. The
		// video pipeline also finds the audio stream, so a file without one is
		// only opened once. A hardware decoder can fail on a stream it
		// accepted, so that is retried in software.
		std::chrono::steady_clock::time_point deadline = std::chrono::steady_clock::now () + std::chrono::seconds (OPEN_TIMEOUT_SECONDS);

		if (!video.Open (uri.c_str (), true, hardwareDecoding, deadline) && video.triedHardware) video.Open (uri.c_str (), true, false, deadline);
		if (video.foundAudio) audio.Open (uri.c_str (), false, hardwareDecoding, deadline);

		if (video.pipeline) {

			videoCaps = video.GetCaps ();
			ReadVideoFormat (videoCaps);
			if (width <= 0 || height <= 0) video.Close ();

		}

		// A stream that was found but cannot be decoded, such as one in a codec
		// whose plugin is not installed
		info->videoUnsupported = !video.pipeline && video.foundUnsupported;
		info->audioUnsupported = video.foundAudio && !audio.pipeline && audio.foundUnsupported;

		if (audio.pipeline) {

			GstCaps* caps = audio.GetCaps ();
			GstStructure* structure = GetStructure (caps);

			if (structure) {

				gst.gst_structure_get_int (structure, "channels", &audioChannels);
				gst.gst_structure_get_int (structure, "rate", &audioSampleRate);

			}

			if (caps) gst.gst_mini_object_unref (caps);

			if (audioChannels < 1 || audioChannels > 2 || audioSampleRate <= 0) {

				audio.Close ();
				audioChannels = 0;
				audioSampleRate = 0;

			} else {

				// The format is kept from here on, so a stream that changes rate or
				// channels, such as a broadcast between programmes, is converted
				char caps[128];
				snprintf (caps, sizeof (caps), "audio/x-raw,format=S16LE,layout=interleaved,channels=%d,rate=%d", audioChannels, audioSampleRate);
				audio.SetCaps (caps);

			}

		}

		if (!video.pipeline && !audio.pipeline) return false;

		double duration = video.pipeline ? video.GetDuration () : 0;
		if (duration <= 0 && audio.pipeline) duration = audio.GetDuration ();

		info->audioChannels = audioChannels;
		info->audioSampleRate = audioSampleRate;
		info->duration = duration;
		info->frameRate = video.pipeline ? frameRate : 0;
		info->hasAudio = (audio.pipeline != NULL);
		info->hasVideo = (video.pipeline != NULL);
		info->height = info->hasVideo ? height : 0;
		info->pixelAspectRatio = info->hasVideo ? pixelAspectRatio : 0;
		info->rotation = info->hasVideo ? video.GetRotation () : 0;
		info->width = info->hasVideo ? width : 0;

		if (video.pipeline) video.Play ();
		if (audio.pipeline) audio.Play ();

		return true;

	}


	void GStreamerVideoBackend::PrepareSeek () {

		audio.PrepareSeek ();
		video.PrepareSeek ();

	}


	void GStreamerVideoBackend::ReadVideoFormat (GstCaps* caps) {

		GstStructure* structure = GetStructure (caps);
		if (!structure) return;

		gst.gst_structure_get_int (structure, "width", &width);
		gst.gst_structure_get_int (structure, "height", &height);

		const char* format = gst.gst_structure_get_string (structure, "format");
		planar = format && strcmp (format, "I420") == 0;

		int pixelWidth = 0;
		int pixelHeight = 0;
		pixelAspectRatio = gst.gst_structure_get_fraction (structure, "pixel-aspect-ratio", &pixelWidth, &pixelHeight) && pixelWidth > 0 && pixelHeight > 0 ? (double)pixelWidth / pixelHeight : 0;

		int numerator = 0;
		int denominator = 0;

		if (gst.gst_structure_get_fraction (structure, "framerate", &numerator, &denominator) && numerator > 0 && denominator > 0) {

			frameRate = (double)numerator / denominator;

		}

		int range;
		int matrix;
		int transfer;
		GetColorimetry (gst.gst_structure_get_string (structure, "colorimetry"), &range, &matrix, &transfer);

		// HDR is tone mapped by VideoDecoder, as no element here can
		colorTransfer = transfer == GST_VIDEO_TRANSFER_SMPTE2084 ? VIDEO_COLOR_TRANSFER_PQ : (transfer == GST_VIDEO_TRANSFER_ARIB_STD_B67 ? VIDEO_COLOR_TRANSFER_HLG : VIDEO_COLOR_TRANSFER_SDR);

		switch (matrix) {

			case GST_VIDEO_COLOR_MATRIX_BT601: case GST_VIDEO_COLOR_MATRIX_FCC: colorMatrix = VIDEO_COLOR_MATRIX_BT601; break;
			case GST_VIDEO_COLOR_MATRIX_BT709: case GST_VIDEO_COLOR_MATRIX_SMPTE240M: colorMatrix = VIDEO_COLOR_MATRIX_BT709; break;
			case GST_VIDEO_COLOR_MATRIX_BT2020: colorMatrix = VIDEO_COLOR_MATRIX_BT2020; break;
			default: colorMatrix = GetDefaultColorMatrix (width, height); break;

		}

		fullRange = (range == GST_VIDEO_COLOR_RANGE_0_255);

	}


	bool GStreamerVideoBackend::ReopenVideoInSoftware () {

		std::chrono::steady_clock::time_point deadline = std::chrono::steady_clock::now () + std::chrono::seconds (SOFTWARE_REOPEN_SECONDS);

		UnmapVideo ();

		if (interrupted || !video.Open (uri.c_str (), true, false, deadline)) return false;

		// Closing can have begun while the new stream opened
		if (interrupted) {

			video.Interrupt ();
			return false;

		}

		// Decoding resumes from the keyframe before the last frame returned
		if (lastFrameTime >= 0) {

			video.Seek (lastFrameTime);
			skipUntil = lastFrameTime;

		}

		video.Play ();
		return true;

	}


	bool GStreamerVideoBackend::Seek (double time) {

		UnmapVideo ();

		// A stream that cannot seek, such as a live one, is left playing, rather
		// than one stream moving without the other
		if ((video.pipeline && !video.IsSeekable ()) || (audio.pipeline && !audio.IsSeekable ())) {

			audio.CancelSeek ();
			video.CancelSeek ();
			return false;

		}

		lastFrameTime = -1;
		skipUntil = -1;

		bool success = true;

		if (video.pipeline) {

			success = video.Seek (time) && success;
			videoPosition = time;

		}

		if (audio.pipeline) {

			success = audio.Seek (time) && success;
			audioPosition = time;

		}

		return success;

	}


	void GStreamerVideoBackend::UnmapVideo () {

		if (videoSample) {

			gst.gst_buffer_unmap (gst.gst_sample_get_buffer (videoSample), &videoMap);
			gst.gst_mini_object_unref (videoSample);
			videoSample = NULL;

		}

	}


	VideoBackend* VideoBackend::Create () {

		return LoadGStreamer () ? new GStreamerVideoBackend () : NULL;

	}


	bool VideoBackend::IsSupported () {

		return LoadGStreamer ();

	}


}


#endif
