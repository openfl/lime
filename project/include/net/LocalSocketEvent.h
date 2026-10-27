#ifndef LIME_NET_LOCAL_SOCKET_EVENT_H
#define LIME_NET_LOCAL_SOCKET_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {


	enum LocalSocketEventType {

		LOCAL_SOCKET_ACCEPT,
		LOCAL_SOCKET_CLOSE,
		LOCAL_SOCKET_CONNECT,
		LOCAL_SOCKET_DATA,
		LOCAL_SOCKET_ERROR

	};


	struct LocalSocketEvent {

		hl_type* t;
		int error;
		int id;
		int length;
		LocalSocketEventType type;

		static ValuePointer* callback;
		static ValuePointer* eventObject;

		LocalSocketEvent ();

		static void Dispatch (LocalSocketEvent* event);

	};


}


#endif
