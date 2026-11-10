#include <net/LocalSocket.h>
#include <net/LocalSocketEvent.h>
#include <string.h>

#ifdef LIME_NATIVE_IPC
#include <native_ipc/Channel.h>
#include <native_ipc/Pipe.h>
#endif


namespace lime {


	static void (*wakeHandler) () = 0;


	#ifdef LIME_NATIVE_IPC


	// One for the process, made with the first server or connection
	static native_ipc_context* context = 0;

	// The event being dispatched, whose message and accepted connection Haxe
	// takes while it is
	static native_ipc_event current;
	static bool dispatching = false;


	// Lets Update dispatch again when a handler it called throws
	struct DispatchScope {

		DispatchScope () { dispatching = true; }
		~DispatchScope () { dispatching = false; memset (&current, 0, sizeof (current)); }

	};


	static void Wake (void* userData) {

		if (wakeHandler) wakeHandler ();

	}


	static native_ipc_context* GetContext () {

		if (!context) {

			memset (&current, 0, sizeof (current));
			context = native_ipc_context_create (Wake, 0);

		}

		return context;

	}


	static LocalSocketError GetError (int error) {

		switch (error) {

			case NATIVE_IPC_ERROR_NONE: return LOCAL_SOCKET_ERROR_NONE;
			case NATIVE_IPC_ERROR_NOT_OWNED: return LOCAL_SOCKET_ERROR_NOT_OWNED;
			case NATIVE_IPC_ERROR_PROTOCOL: return LOCAL_SOCKET_ERROR_PROTOCOL_MISMATCH;
			case NATIVE_IPC_ERROR_IN_USE: return LOCAL_SOCKET_ERROR_NAME_IN_USE;
			case NATIVE_IPC_ERROR_TIMEOUT: return LOCAL_SOCKET_ERROR_TIMEOUT;
			default: return LOCAL_SOCKET_ERROR_FAILED;

		}

	}


	#endif


	LocalSocket::LocalSocket (void* endpoint) {

		this->endpoint = endpoint;

	}


	LocalSocket::~LocalSocket () {

		Close ();

	}


	void LocalSocket::Close () {

		#ifdef LIME_NATIVE_IPC
		if (endpoint) {

			native_ipc_endpoint* native = (native_ipc_endpoint*)endpoint;

			// A client this server took that is being dispatched, and not taken
			// yet, goes with it, as those still queued do
			if (current.accepted && current.endpoint == native) {

				native_ipc_endpoint_close (current.accepted);
				current.accepted = 0;

			}

			native_ipc_endpoint_close (native);
			endpoint = 0;

		}
		#endif

	}


	LocalSocket* LocalSocket::Connect (const char* name, int timeoutMs) {

		#ifdef LIME_NATIVE_IPC
		native_ipc_endpoint* endpoint = native_ipc_client_open (GetContext (), name, timeoutMs);
		return endpoint ? new LocalSocket (endpoint) : 0;
		#else
		return 0;
		#endif

	}


	int LocalSocket::GetBytesPending () {

		#ifdef LIME_NATIVE_IPC
		return endpoint ? native_ipc_endpoint_bytes_pending ((native_ipc_endpoint*)endpoint) : 0;
		#else
		return 0;
		#endif

	}


	int LocalSocket::GetID () {

		#ifdef LIME_NATIVE_IPC
		return endpoint ? (int)native_ipc_endpoint_id ((native_ipc_endpoint*)endpoint) : 0;
		#else
		return 0;
		#endif

	}


	bool LocalSocket::IsSupported () {

		#ifdef LIME_NATIVE_IPC
		return true;
		#else
		return false;
		#endif

	}


	LocalSocket* LocalSocket::Listen (const char* name, LocalSocketError* error) {

		#ifdef LIME_NATIVE_IPC
		int nativeError = NATIVE_IPC_ERROR_NONE;
		native_ipc_endpoint* endpoint = native_ipc_server_open (GetContext (), name, &nativeError);

		if (error) *error = endpoint ? LOCAL_SOCKET_ERROR_NONE : GetError (nativeError == NATIVE_IPC_ERROR_NONE ? NATIVE_IPC_ERROR_FAILED : nativeError);
		return endpoint ? new LocalSocket (endpoint) : 0;
		#else
		if (error) *error = LOCAL_SOCKET_ERROR_FAILED;
		return 0;
		#endif

	}


	void LocalSocket::ReadData (unsigned char* buffer, int length) {

		#ifdef LIME_NATIVE_IPC
		if (buffer && current.data && current.length > 0) {

			memcpy (buffer, current.data, current.length < length ? current.length : length);

		}
		#endif

	}


	bool LocalSocket::Send (const unsigned char* data, int length) {

		#ifdef LIME_NATIVE_IPC
		return endpoint && native_ipc_endpoint_send ((native_ipc_endpoint*)endpoint, data, length);
		#else
		return false;
		#endif

	}


	void LocalSocket::SetMaxQueued (int bytes) {

		#ifdef LIME_NATIVE_IPC
		if (endpoint) native_ipc_endpoint_set_max_queued ((native_ipc_endpoint*)endpoint, bytes);
		#endif

	}


	void LocalSocket::SetWakeHandler (void (*handler) ()) {

		wakeHandler = handler;

	}


	LocalSocket* LocalSocket::TakeAccepted () {

		#ifdef LIME_NATIVE_IPC
		native_ipc_endpoint* accepted = current.accepted;
		current.accepted = 0;
		return accepted ? new LocalSocket (accepted) : 0;
		#else
		return 0;
		#endif

	}


	void LocalSocket::Update () {

		#ifdef LIME_NATIVE_IPC
		if (!context || dispatching || !LocalSocketEvent::callback) return;

		DispatchScope scope;
		LocalSocketEvent event;

		while (native_ipc_context_poll (context, &current)) {

			event.error = LOCAL_SOCKET_ERROR_NONE;
			event.id = current.id;
			event.length = current.length;

			switch (current.type) {

				case NATIVE_IPC_EVENT_ACCEPT: event.type = LOCAL_SOCKET_ACCEPT; break;
				case NATIVE_IPC_EVENT_CLOSE: event.type = LOCAL_SOCKET_CLOSE; break;
				case NATIVE_IPC_EVENT_CONNECT: event.type = LOCAL_SOCKET_CONNECT; break;
				case NATIVE_IPC_EVENT_DATA: event.type = LOCAL_SOCKET_DATA; break;

				case NATIVE_IPC_EVENT_ERROR:

					event.type = LOCAL_SOCKET_ERROR;

					switch (current.reason) {

						case NATIVE_IPC_REASON_OVERFLOW: event.error = LOCAL_SOCKET_ERROR_OVERFLOW; break;
						case NATIVE_IPC_REASON_INVALID_FRAME: event.error = LOCAL_SOCKET_ERROR_INVALID_MESSAGE; break;
						default: event.error = GetError (current.error); break;

					}

					break;

				default: continue;

			}

			LocalSocketEvent::Dispatch (&event);

			// A client Haxe did not take is closed, so its peer learns it is gone
			if (current.accepted) {

				native_ipc_endpoint_close (current.accepted);
				current.accepted = 0;

			}

		}
		#endif

	}


}
