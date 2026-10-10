#include <media/VideoDecoder.h>


#ifdef LIME_VIDEO_GSTREAMER


#include <atomic>
#include <chrono>
#include <dlfcn.h>
#include <stdint.h>
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
	struct GstPad;
	struct GstSample;
	struct GstSegment;
	struct GstStructure;


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

	// A stalled stream fails after longer than souphttpsrc waits before it
	// reconnects, which is 15 seconds
	static const int DECODE_TIMEOUT_SECONDS = 20;
	static const unsigned int MAX_AUDIO_BUFFERS = 4;
	static const unsigned int MAX_VIDEO_BUFFERS = 2;
	static const int OPEN_TIMEOUT_SECONDS = 20;
	static const uint64_t PULL_INTERVAL = 100 * GST_MSECOND;


	struct GStreamerLibrary {

		void (*g_free) (void*);
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
		gboolean (*gst_element_query_duration) (GstElement*, int, int64_t*);
		gboolean (*gst_element_seek_simple) (GstElement*, int, int, int64_t);
		int (*gst_element_set_state) (GstElement*, int);
		gboolean (*gst_element_sync_state_with_parent) (GstElement*);
		char* (*gst_filename_to_uri) (const char*, void**);
		GstPad* (*gst_ghost_pad_new) (const char*, GstPad*);
		gboolean (*gst_init_check) (int*, char***, void**);
		void* (*gst_mini_object_ref) (void*);
		void (*gst_mini_object_unref) (void*);
		void* (*gst_object_ref_sink) (void*);
		void (*gst_object_unref) (void*);
		GstCaps* (*gst_pad_get_current_caps) (GstPad*);
		int (*gst_pad_link) (GstPad*, GstPad*);
		gboolean (*gst_pad_query) (GstPad*, GstQuery*);
		GstCaps* (*gst_pad_query_caps) (GstPad*, GstCaps*);
		GstElement* (*gst_pipeline_new) (const char*);
		void (*gst_plugin_feature_list_free) (GList*);
		GstBuffer* (*gst_sample_get_buffer) (GstSample*);
		GstCaps* (*gst_sample_get_caps) (GstSample*);
		GstSegment* (*gst_sample_get_segment) (GstSample*);
		int (*gst_segment_to_stream_time_full) (const GstSegment*, int, uint64_t, uint64_t*);
		gboolean (*gst_structure_get_fraction) (const GstStructure*, const char*, int*, int*);
		gboolean (*gst_structure_get_int) (const GstStructure*, const char*, int*);
		const char* (*gst_structure_get_name) (const GstStructure*);
		const char* (*gst_structure_get_string) (const GstStructure*, const char*);
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
	static void GetColorimetry (const char* colorimetry, int* range, int* matrix) {

		static const struct { const char* name; int range; int matrix; } names[] = {

			{ "bt2020", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_BT2020 },
			{ "bt2020-10", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_BT2020 },
			{ "bt2100-hlg", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_BT2020 },
			{ "bt2100-pq", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_BT2020 },
			{ "bt601", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_BT601 },
			{ "bt709", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_BT709 },
			{ "smpte240m", GST_VIDEO_COLOR_RANGE_16_235, GST_VIDEO_COLOR_MATRIX_SMPTE240M },
			{ "sRGB", GST_VIDEO_COLOR_RANGE_0_255, GST_VIDEO_COLOR_MATRIX_RGB }

		};

		*range = GST_VIDEO_COLOR_RANGE_UNKNOWN;
		*matrix = GST_VIDEO_COLOR_MATRIX_UNKNOWN;

		if (!colorimetry) return;

		for (size_t i = 0; i < sizeof (names) / sizeof (names[0]); i++) {

			if (strcmp (colorimetry, names[i].name) == 0) {

				*range = names[i].range;
				*matrix = names[i].matrix;
				return;

			}

		}

		// Parsed by hand, since glibc 2.38 builds link sscanf to a symbol that
		// older systems lack
		const char* matrixText = strchr (colorimetry, ':');
		if (!matrixText) return;

		for (const char* c = colorimetry; *c >= '0' && *c <= '9'; c++) *range = *range * 10 + (*c - '0');
		for (const char* c = matrixText + 1; *c >= '0' && *c <= '9'; c++) *matrix = *matrix * 10 + (*c - '0');

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


	static bool IsVideo (const char* mediaType) {

		return strncmp (mediaType, "video/", 6) == 0 || strncmp (mediaType, "image/", 6) == 0;

	}


	// One pipeline decoding one stream type. The converter and appsink wait in
	// a bin until uridecodebin exposes a raw stream of that type.
	class GStreamerStream {


		public:

			GStreamerStream ();
			~GStreamerStream ();

			void Close ();
			GstCaps* GetCaps ();
			double GetDuration ();
			void Interrupt ();
			bool Open (const char* uri, bool video, bool hardware, std::chrono::steady_clock::time_point deadline);
			void Play ();
			VideoDecodeResult Pull (GstSample** sample);
			bool Seek (double time);

			std::atomic<bool> foundAudio;
			GstElement* pipeline;
			std::atomic<bool> triedHardware;

		private:

			static gboolean AutoplugContinue (GstElement* decodeBin, GstPad* pad, GstCaps* caps, void* data);
			static gboolean AutoplugQuery (GstElement* decodeBin, GstPad* pad, GstElement* element, GstQuery* query, void* data);
			static int AutoplugSelect (GstElement* decodeBin, GstPad* pad, GstCaps* caps, GstElementFactory* factory, void* data);
			static int BusSync (GstBus* bus, GstMessage* message, void* data);
			static void PadAdded (GstElement* decodeBin, GstPad* pad, void* data);

			void FlushBus ();
			bool Preroll (std::chrono::steady_clock::time_point deadline);

			GstElement* appSink;
			GstElement* bin;
			GstBus* bus;
			bool hardware;
			std::atomic<bool> interrupted;
			std::atomic<bool> linked;
			bool video;


	};


	GStreamerStream::GStreamerStream () {

		appSink = NULL;
		bin = NULL;
		bus = NULL;
		foundAudio = false;
		hardware = false;
		interrupted = false;
		linked = false;
		pipeline = NULL;
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


	bool GStreamerStream::Open (const char* uri, bool video, bool hardware, std::chrono::steady_clock::time_point deadline) {

		Close ();

		foundAudio = false;
		this->hardware = hardware;
		interrupted = false;
		linked = false;
		triedHardware = false;
		this->video = video;

		pipeline = (GstElement*)gst.gst_object_ref_sink (gst.gst_pipeline_new (NULL));
		bin = (GstElement*)gst.gst_object_ref_sink (gst.gst_bin_new (NULL));
		bus = gst.gst_element_get_bus (pipeline);
		gst.gst_bus_set_sync_handler (bus, BusSync, NULL, NULL);

		GstElement* decodeBin = AddElement (pipeline, "uridecodebin");
		GstElement* convert = AddElement (bin, video ? "videoconvert" : "audioconvert");
		appSink = AddElement (bin, "appsink");

		if (!decodeBin || !convert || !appSink || !gst.gst_element_link (convert, appSink)) {

			Close ();
			return false;

		}

		GstPad* convertPad = gst.gst_element_get_static_pad (convert, "sink");
		gst.gst_element_add_pad (bin, gst.gst_ghost_pad_new ("sink", convertPad));
		gst.gst_object_unref (convertPad);

		// audioconvert downmixes to stereo at the source rate
		GstCaps* caps = gst.gst_caps_from_string (video ? "video/x-raw,format=NV12" : "audio/x-raw,format=S16LE,layout=interleaved,channels=[1,2]");
		gst.g_object_set (appSink, "caps", caps, "drop", false, "enable-last-sample", false, "max-buffers", video ? MAX_VIDEO_BUFFERS : MAX_AUDIO_BUFFERS, "sync", false, NULL);
		gst.gst_mini_object_unref (caps);

		gst.g_object_set (decodeBin, "uri", uri, NULL);
		gst.g_signal_connect_data (decodeBin, "autoplug-continue", (GCallback)AutoplugContinue, this, NULL, 0);
		gst.g_signal_connect_data (decodeBin, "autoplug-query", (GCallback)AutoplugQuery, this, NULL, 0);
		gst.g_signal_connect_data (decodeBin, "autoplug-select", (GCallback)AutoplugSelect, this, NULL, 0);
		gst.g_signal_connect_data (decodeBin, "pad-added", (GCallback)PadAdded, this, NULL, 0);

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


	void GStreamerStream::Play () {

		gst.gst_element_set_state (pipeline, GST_STATE_PLAYING);

	}


	bool GStreamerStream::Preroll (std::chrono::steady_clock::time_point deadline) {

		int result = gst.gst_element_set_state (pipeline, GST_STATE_PAUSED);

		if (result == GST_STATE_CHANGE_FAILURE) return false;
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
		FlushBus ();

		int flags = GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_KEY_UNIT | GST_SEEK_FLAG_SNAP_BEFORE;
		return gst.gst_element_seek_simple (pipeline, GST_FORMAT_TIME, flags, (int64_t)(time * GST_SECOND));

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
			virtual bool Seek (double time);

		private:

			void ReadVideoFormat (GstCaps* caps);
			void UnmapVideo ();

			GStreamerStream audio;
			int audioChannels;
			double audioPosition;
			int audioSampleRate;
			VideoColorMatrix colorMatrix;
			double frameRate;
			bool fullRange;
			int height;
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
		frameRate = 0;
		fullRange = false;
		height = 0;
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
		VideoDecodeResult result = video.Pull (&sample);
		if (result != VIDEO_DECODE_OK) return result;

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

		// Without a video meta the frame has GStreamer's default NV12 layout
		GstVideoMeta* meta = videoMetaAPI ? (GstVideoMeta*)gst.gst_buffer_get_meta (buffer, videoMetaAPI) : NULL;
		size_t yOffset = 0;
		size_t uvOffset;
		int yStride;
		int uvStride;

		if (meta && meta->n_planes == 2) {

			yOffset = meta->offset[0];
			uvOffset = meta->offset[1];
			yStride = meta->stride[0];
			uvStride = meta->stride[1];

		} else {

			yStride = (width + 3) & ~3;
			uvStride = yStride;
			uvOffset = (size_t)yStride * ((height + 1) & ~1);

		}

		int chromaHeight = (height + 1) / 2;
		int chromaRow = ((width + 1) / 2) * 2;

		if (width <= 0 || height <= 0 || yStride < width || uvStride < chromaRow || yOffset + (size_t)yStride * (height - 1) + width > videoMap.size || uvOffset + (size_t)uvStride * (chromaHeight - 1) + chromaRow > videoMap.size) {

			UnmapVideo ();
			return VIDEO_DECODE_ERROR;

		}

		planes->colorMatrix = colorMatrix;
		planes->fullRange = fullRange;
		planes->width = width;
		planes->height = height;
		planes->y = videoMap.data + yOffset;
		planes->yStride = yStride;
		planes->u = videoMap.data + uvOffset;
		planes->v = planes->u + 1;
		planes->uvStride = uvStride;
		planes->uvPixelStride = 2;

		*time = GetTime (sample, videoPosition);
		*duration = buffer->duration != GST_CLOCK_TIME_NONE ? (double)buffer->duration / GST_SECOND : (frameRate > 0 ? 1.0 / frameRate : 0);
		videoPosition = *time + *duration;

		return VIDEO_DECODE_OK;

	}


	void GStreamerVideoBackend::Interrupt () {

		audio.Interrupt ();
		video.Interrupt ();

	}


	bool GStreamerVideoBackend::Open (const char* path, bool hardwareDecoding, VideoStreamInfo* info) {

		Close ();

		if (!path || !path[0]) return false;

		std::string uri = GetURI (path);
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

			}

		}

		if (!video.pipeline && !audio.pipeline) return false;

		info->audioChannels = audioChannels;
		info->audioSampleRate = audioSampleRate;
		info->duration = video.pipeline ? video.GetDuration () : audio.GetDuration ();
		info->frameRate = video.pipeline ? frameRate : 0;
		info->hasAudio = (audio.pipeline != NULL);
		info->hasVideo = (video.pipeline != NULL);
		info->height = info->hasVideo ? height : 0;
		info->width = info->hasVideo ? width : 0;

		if (video.pipeline) video.Play ();
		if (audio.pipeline) audio.Play ();

		return true;

	}


	void GStreamerVideoBackend::ReadVideoFormat (GstCaps* caps) {

		GstStructure* structure = GetStructure (caps);
		if (!structure) return;

		gst.gst_structure_get_int (structure, "width", &width);
		gst.gst_structure_get_int (structure, "height", &height);

		int numerator = 0;
		int denominator = 0;

		if (gst.gst_structure_get_fraction (structure, "framerate", &numerator, &denominator) && numerator > 0 && denominator > 0) {

			frameRate = (double)numerator / denominator;

		}

		int range;
		int matrix;
		GetColorimetry (gst.gst_structure_get_string (structure, "colorimetry"), &range, &matrix);

		switch (matrix) {

			case GST_VIDEO_COLOR_MATRIX_BT601: case GST_VIDEO_COLOR_MATRIX_FCC: colorMatrix = VIDEO_COLOR_MATRIX_BT601; break;
			case GST_VIDEO_COLOR_MATRIX_BT709: case GST_VIDEO_COLOR_MATRIX_SMPTE240M: colorMatrix = VIDEO_COLOR_MATRIX_BT709; break;
			case GST_VIDEO_COLOR_MATRIX_BT2020: colorMatrix = VIDEO_COLOR_MATRIX_BT2020; break;
			default: colorMatrix = GetDefaultColorMatrix (width, height); break;

		}

		fullRange = (range == GST_VIDEO_COLOR_RANGE_0_255);

	}


	bool GStreamerVideoBackend::Seek (double time) {

		UnmapVideo ();

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
