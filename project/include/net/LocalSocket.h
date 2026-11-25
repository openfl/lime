#ifndef LIME_NET_LOCAL_SOCKET_H
#define LIME_NET_LOCAL_SOCKET_H


namespace lime {


	// As lime.net.LocalSocketError numbers them
	enum LocalSocketError {

		LOCAL_SOCKET_ERROR_NONE,
		LOCAL_SOCKET_ERROR_FAILED,
		LOCAL_SOCKET_ERROR_NOT_OWNED,
		LOCAL_SOCKET_ERROR_PROTOCOL_MISMATCH,
		LOCAL_SOCKET_ERROR_NAME_IN_USE,
		LOCAL_SOCKET_ERROR_TIMEOUT,
		LOCAL_SOCKET_ERROR_OVERFLOW,
		LOCAL_SOCKET_ERROR_INVALID_MESSAGE

	};


	// A local server, or a connection to or from one, made with native-ipc.
	// Its events are dispatched by Update, on the main thread.
	class LocalSocket {

		public:

			~LocalSocket ();

			static LocalSocket* Connect (const char* name, int timeoutMs);
			static bool IsSupported ();
			static LocalSocket* Listen (const char* name, LocalSocketError* error);
			// The message of the LOCAL_SOCKET_DATA event being dispatched
			static void ReadData (unsigned char* buffer, int length);
			// What wakes the application's loop from native-ipc's threads when
			// events wait, so that it calls Update
			static void SetWakeHandler (void (*handler) ());
			// The connection of the LOCAL_SOCKET_ACCEPT event being dispatched
			static LocalSocket* TakeAccepted ();
			static void Update ();

			void Close ();
			int GetBytesPending ();
			int GetID ();
			bool Send (const unsigned char* data, int length);
			void SetMaxQueued (int bytes);

		private:

			LocalSocket (void* endpoint);

			void* endpoint;

	};


}


#endif
