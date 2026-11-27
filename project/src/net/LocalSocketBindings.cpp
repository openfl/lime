#include <net/LocalSocket.h>
#include <net/LocalSocketEvent.h>
#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <system/System.h>
#include <utils/Bytes.h>
#include <string>


namespace lime {


	// Why the last lime_local_socket_listen failed
	static LocalSocketError lastError = LOCAL_SOCKET_ERROR_NONE;


	void gc_local_socket (value handle) {

		LocalSocket* socket = (LocalSocket*)val_data (handle);
		delete socket;

	}


	void hl_gc_local_socket (HL_CFFIPointer* handle) {

		LocalSocket* socket = (LocalSocket*)handle->ptr;
		delete socket;

	}


	void lime_local_socket_close (value handle) {

		LocalSocket* socket = (LocalSocket*)val_data (handle);

		// Its threads are let go, which takes a moment at most
		System::GCEnterBlocking ();
		socket->Close ();
		System::GCExitBlocking ();

	}


	HL_PRIM void HL_NAME(hl_local_socket_close) (HL_CFFIPointer* handle) {

		LocalSocket* socket = (LocalSocket*)handle->ptr;

		hl_blocking (true);
		socket->Close ();
		hl_blocking (false);

	}


	value lime_local_socket_connect (HxString name, int timeout) {

		// hxcpp keeps strings with non-ASCII characters as UTF-16
		const char* utf8 = hxs_utf8 (name, nullptr);
		std::string source = utf8 ? utf8 : "";

		LocalSocket* socket = LocalSocket::Connect (source.c_str (), timeout);
		return socket ? CFFIPointer (socket, gc_local_socket) : alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_local_socket_connect) (hl_vstring* name, int timeout) {

		std::string source = name ? hl_to_utf8 (name->bytes) : "";

		LocalSocket* socket = LocalSocket::Connect (source.c_str (), timeout);
		return socket ? HLCFFIPointer (socket, (hl_finalizer)hl_gc_local_socket) : NULL;

	}


	void lime_local_socket_event_manager_register (value callback, value eventObject) {

		LocalSocketEvent::callback = new ValuePointer (callback);
		LocalSocketEvent::eventObject = new ValuePointer (eventObject);

	}


	HL_PRIM void HL_NAME(hl_local_socket_event_manager_register) (vclosure* callback, LocalSocketEvent* eventObject) {

		LocalSocketEvent::callback = new ValuePointer (callback);
		LocalSocketEvent::eventObject = new ValuePointer ((vobj*)eventObject);

	}


	value lime_local_socket_get_accepted () {

		LocalSocket* socket = LocalSocket::TakeAccepted ();
		return socket ? CFFIPointer (socket, gc_local_socket) : alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_local_socket_get_accepted) () {

		LocalSocket* socket = LocalSocket::TakeAccepted ();
		return socket ? HLCFFIPointer (socket, (hl_finalizer)hl_gc_local_socket) : NULL;

	}


	int lime_local_socket_get_bytes_pending (value handle) {

		LocalSocket* socket = (LocalSocket*)val_data (handle);
		return socket->GetBytesPending ();

	}


	HL_PRIM int HL_NAME(hl_local_socket_get_bytes_pending) (HL_CFFIPointer* handle) {

		LocalSocket* socket = (LocalSocket*)handle->ptr;
		return socket->GetBytesPending ();

	}


	int lime_local_socket_get_id (value handle) {

		LocalSocket* socket = (LocalSocket*)val_data (handle);
		return socket->GetID ();

	}


	HL_PRIM int HL_NAME(hl_local_socket_get_id) (HL_CFFIPointer* handle) {

		LocalSocket* socket = (LocalSocket*)handle->ptr;
		return socket->GetID ();

	}


	int lime_local_socket_get_last_error () {

		return lastError;

	}


	HL_PRIM int HL_NAME(hl_local_socket_get_last_error) () {

		return lastError;

	}


	bool lime_local_socket_is_supported () {

		return LocalSocket::IsSupported ();

	}


	HL_PRIM bool HL_NAME(hl_local_socket_is_supported) () {

		return LocalSocket::IsSupported ();

	}


	value lime_local_socket_listen (HxString name) {

		const char* utf8 = hxs_utf8 (name, nullptr);
		std::string source = utf8 ? utf8 : "";

		LocalSocket* socket = LocalSocket::Listen (source.c_str (), &lastError);
		return socket ? CFFIPointer (socket, gc_local_socket) : alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_local_socket_listen) (hl_vstring* name) {

		std::string source = name ? hl_to_utf8 (name->bytes) : "";

		LocalSocket* socket = LocalSocket::Listen (source.c_str (), &lastError);
		return socket ? HLCFFIPointer (socket, (hl_finalizer)hl_gc_local_socket) : NULL;

	}


	void lime_local_socket_read (value buffer) {

		Bytes bytes (buffer);
		LocalSocket::ReadData (bytes.b, bytes.length);

	}


	HL_PRIM void HL_NAME(hl_local_socket_read) (Bytes* buffer) {

		if (buffer) LocalSocket::ReadData (buffer->b, buffer->length);

	}


	bool lime_local_socket_send (value handle, value buffer, int offset, int length) {

		LocalSocket* socket = (LocalSocket*)val_data (handle);
		Bytes bytes (buffer);

		if (offset < 0 || length < 0 || (length > 0 && (!bytes.b || offset > bytes.length || length > bytes.length - offset))) return false;

		return socket->Send (length > 0 ? bytes.b + offset : NULL, length);

	}


	HL_PRIM bool HL_NAME(hl_local_socket_send) (HL_CFFIPointer* handle, Bytes* buffer, int offset, int length) {

		LocalSocket* socket = (LocalSocket*)handle->ptr;

		if (offset < 0 || length < 0 || (length > 0 && (!buffer || !buffer->b || offset > buffer->length || length > buffer->length - offset))) return false;

		return socket->Send (length > 0 ? buffer->b + offset : NULL, length);

	}


	void lime_local_socket_set_max_queued (value handle, int bytes) {

		LocalSocket* socket = (LocalSocket*)val_data (handle);
		socket->SetMaxQueued (bytes);

	}


	HL_PRIM void HL_NAME(hl_local_socket_set_max_queued) (HL_CFFIPointer* handle, int bytes) {

		LocalSocket* socket = (LocalSocket*)handle->ptr;
		socket->SetMaxQueued (bytes);

	}


	void lime_local_socket_update () {

		LocalSocket::Update ();

	}


	HL_PRIM void HL_NAME(hl_local_socket_update) () {

		LocalSocket::Update ();

	}


	DEFINE_PRIME1v (lime_local_socket_close);
	DEFINE_PRIME2 (lime_local_socket_connect);
	DEFINE_PRIME2v (lime_local_socket_event_manager_register);
	DEFINE_PRIME0 (lime_local_socket_get_accepted);
	DEFINE_PRIME1 (lime_local_socket_get_bytes_pending);
	DEFINE_PRIME1 (lime_local_socket_get_id);
	DEFINE_PRIME0 (lime_local_socket_get_last_error);
	DEFINE_PRIME0 (lime_local_socket_is_supported);
	DEFINE_PRIME1 (lime_local_socket_listen);
	DEFINE_PRIME1v (lime_local_socket_read);
	DEFINE_PRIME4 (lime_local_socket_send);
	DEFINE_PRIME2v (lime_local_socket_set_max_queued);
	DEFINE_PRIME0v (lime_local_socket_update);


	#define _TBYTES _OBJ (_I32 _BYTES)
	#define _TCFFIPOINTER _DYN
	#define _TLOCAL_SOCKET_EVENT _OBJ (_I32 _I32 _I32 _I32)

	DEFINE_HL_PRIM (_VOID, hl_local_socket_close, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_local_socket_connect, _STRING _I32);
	DEFINE_HL_PRIM (_VOID, hl_local_socket_event_manager_register, _FUN (_VOID, _NO_ARG) _TLOCAL_SOCKET_EVENT);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_local_socket_get_accepted, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_local_socket_get_bytes_pending, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_local_socket_get_id, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_local_socket_get_last_error, _NO_ARG);
	DEFINE_HL_PRIM (_BOOL, hl_local_socket_is_supported, _NO_ARG);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_local_socket_listen, _STRING);
	DEFINE_HL_PRIM (_VOID, hl_local_socket_read, _TBYTES);
	DEFINE_HL_PRIM (_BOOL, hl_local_socket_send, _TCFFIPOINTER _TBYTES _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_local_socket_set_max_queued, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_local_socket_update, _NO_ARG);


}


extern "C" int lime_local_socket_register_prims () {

	return 0;

}
