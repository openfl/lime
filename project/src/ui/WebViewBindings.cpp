#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <system/ValuePointer.h>
#include <ui/WebView.h>
#include <string>


namespace lime {


	static ValuePointer* navigationCallback = 0;


	static void CallNavigationCallback () {

		navigationCallback->Call ();

	}


	static value alloc_web_view_string (const std::string& text) {

		return text.empty () ? alloc_null () : alloc_string (text.c_str ());

	}


	static vbyte* hl_web_view_string (const std::string& text) {

		return text.empty () ? NULL : hl_copy_bytes ((const vbyte*)text.c_str (), (int)text.size () + 1);

	}


	void gc_web_view (value handle) {

		WebView* view = (WebView*)val_data (handle);
		view->Release ();

	}


	void hl_gc_web_view (HL_CFFIPointer* handle) {

		WebView* view = (WebView*)handle->ptr;
		view->Release ();

	}


	void lime_web_view_add_init_script (value handle, HxString script) {

		((WebView*)val_data (handle))->AddInitScript (hxs_utf8 (script, nullptr));

	}


	HL_PRIM void HL_NAME(hl_web_view_add_init_script) (HL_CFFIPointer* handle, hl_vstring* script) {

		((WebView*)handle->ptr)->AddInitScript (hl_to_utf8 (script->bytes));

	}


	void lime_web_view_cancel_navigation () {

		WebView::CancelNavigation ();

	}


	HL_PRIM void HL_NAME(hl_web_view_cancel_navigation) () {

		WebView::CancelNavigation ();

	}


	value lime_web_view_capture (value handle) {

		return alloc_web_view_string (((WebView*)val_data (handle))->Capture ());

	}


	HL_PRIM vbyte* HL_NAME(hl_web_view_capture) (HL_CFFIPointer* handle) {

		return hl_web_view_string (((WebView*)handle->ptr)->Capture ());

	}


	void lime_web_view_close (value handle) {

		((WebView*)val_data (handle))->Close ();

	}


	HL_PRIM void HL_NAME(hl_web_view_close) (HL_CFFIPointer* handle) {

		((WebView*)handle->ptr)->Close ();

	}


	value lime_web_view_create (value window, int x, int y, int width, int height, int flags, HxString userAgent) {

		Window* targetWindow = val_is_null (window) ? 0 : (Window*)val_data (window);
		WebView* view = WebView::Create (targetWindow, x, y, width, height, flags, hxs_utf8 (userAgent, nullptr));
		return view ? CFFIPointer (view, gc_web_view) : alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_web_view_create) (HL_CFFIPointer* window, int x, int y, int width, int height, int flags, hl_vstring* userAgent) {

		Window* targetWindow = window ? (Window*)window->ptr : 0;
		WebView* view = WebView::Create (targetWindow, x, y, width, height, flags, userAgent ? hl_to_utf8 (userAgent->bytes) : nullptr);
		return view ? HLCFFIPointer (view, (hl_finalizer)hl_gc_web_view) : NULL;

	}


	void lime_web_view_evaluate_java_script (value handle, HxString script, int token) {

		((WebView*)val_data (handle))->EvaluateJavaScript (hxs_utf8 (script, nullptr), token);

	}


	HL_PRIM void HL_NAME(hl_web_view_evaluate_java_script) (HL_CFFIPointer* handle, hl_vstring* script, int token) {

		((WebView*)handle->ptr)->EvaluateJavaScript (hl_to_utf8 (script->bytes), token);

	}


	void lime_web_view_focus (value handle) {

		((WebView*)val_data (handle))->Focus ();

	}


	HL_PRIM void HL_NAME(hl_web_view_focus) (HL_CFFIPointer* handle) {

		((WebView*)handle->ptr)->Focus ();

	}


	bool lime_web_view_get_can_go_back (value handle) {

		return ((WebView*)val_data (handle))->GetCanGoBack ();

	}


	HL_PRIM bool HL_NAME(hl_web_view_get_can_go_back) (HL_CFFIPointer* handle) {

		return ((WebView*)handle->ptr)->GetCanGoBack ();

	}


	bool lime_web_view_get_can_go_forward (value handle) {

		return ((WebView*)val_data (handle))->GetCanGoForward ();

	}


	HL_PRIM bool HL_NAME(hl_web_view_get_can_go_forward) (HL_CFFIPointer* handle) {

		return ((WebView*)handle->ptr)->GetCanGoForward ();

	}


	int lime_web_view_get_id (value handle) {

		return ((WebView*)val_data (handle))->GetID ();

	}


	HL_PRIM int HL_NAME(hl_web_view_get_id) (HL_CFFIPointer* handle) {

		return ((WebView*)handle->ptr)->GetID ();

	}


	value lime_web_view_get_navigation () {

		return alloc_web_view_string (WebView::GetNavigation ());

	}


	HL_PRIM vbyte* HL_NAME(hl_web_view_get_navigation) () {

		return hl_web_view_string (WebView::GetNavigation ());

	}


	value lime_web_view_get_title (value handle) {

		return alloc_web_view_string (((WebView*)val_data (handle))->GetTitle ());

	}


	HL_PRIM vbyte* HL_NAME(hl_web_view_get_title) (HL_CFFIPointer* handle) {

		return hl_web_view_string (((WebView*)handle->ptr)->GetTitle ());

	}


	value lime_web_view_get_url (value handle) {

		return alloc_web_view_string (((WebView*)val_data (handle))->GetURL ());

	}


	HL_PRIM vbyte* HL_NAME(hl_web_view_get_url) (HL_CFFIPointer* handle) {

		return hl_web_view_string (((WebView*)handle->ptr)->GetURL ());

	}


	void lime_web_view_go_back (value handle) {

		((WebView*)val_data (handle))->GoBack ();

	}


	HL_PRIM void HL_NAME(hl_web_view_go_back) (HL_CFFIPointer* handle) {

		((WebView*)handle->ptr)->GoBack ();

	}


	void lime_web_view_go_forward (value handle) {

		((WebView*)val_data (handle))->GoForward ();

	}


	HL_PRIM void HL_NAME(hl_web_view_go_forward) (HL_CFFIPointer* handle) {

		((WebView*)handle->ptr)->GoForward ();

	}


	bool lime_web_view_is_supported () {

		return WebView::IsSupported ();

	}


	HL_PRIM bool HL_NAME(hl_web_view_is_supported) () {

		return WebView::IsSupported ();

	}


	void lime_web_view_load (value handle, HxString url) {

		((WebView*)val_data (handle))->Load (hxs_utf8 (url, nullptr));

	}


	HL_PRIM void HL_NAME(hl_web_view_load) (HL_CFFIPointer* handle, hl_vstring* url) {

		((WebView*)handle->ptr)->Load (hl_to_utf8 (url->bytes));

	}


	void lime_web_view_load_html (value handle, HxString html) {

		((WebView*)val_data (handle))->LoadHTML (hxs_utf8 (html, nullptr));

	}


	HL_PRIM void HL_NAME(hl_web_view_load_html) (HL_CFFIPointer* handle, hl_vstring* html) {

		((WebView*)handle->ptr)->LoadHTML (hl_to_utf8 (html->bytes));

	}


	value lime_web_view_poll_event () {

		return alloc_web_view_string (WebView::PollEvent ());

	}


	HL_PRIM vbyte* HL_NAME(hl_web_view_poll_event) () {

		return hl_web_view_string (WebView::PollEvent ());

	}


	void lime_web_view_post_message (value handle, HxString message) {

		((WebView*)val_data (handle))->PostToPage (hxs_utf8 (message, nullptr));

	}


	HL_PRIM void HL_NAME(hl_web_view_post_message) (HL_CFFIPointer* handle, hl_vstring* message) {

		((WebView*)handle->ptr)->PostToPage (hl_to_utf8 (message->bytes));

	}


	void lime_web_view_print_to_pdf (value handle, HxString path, value options, int token) {

		WebViewPDFOptions pdf;
		pdf.pageWidth = val_number (val_field (options, val_id ("pageWidth")));
		pdf.pageHeight = val_number (val_field (options, val_id ("pageHeight")));
		pdf.marginTop = val_number (val_field (options, val_id ("marginTop")));
		pdf.marginRight = val_number (val_field (options, val_id ("marginRight")));
		pdf.marginBottom = val_number (val_field (options, val_id ("marginBottom")));
		pdf.marginLeft = val_number (val_field (options, val_id ("marginLeft")));
		pdf.scale = val_number (val_field (options, val_id ("scale")));
		pdf.landscape = val_bool (val_field (options, val_id ("landscape")));
		pdf.printBackground = val_bool (val_field (options, val_id ("printBackground")));
		pdf.repeatTableHeaders = val_bool (val_field (options, val_id ("repeatTableHeaders")));

		((WebView*)val_data (handle))->PrintToPDF (hxs_utf8 (path, nullptr), &pdf, token);

	}


	HL_PRIM void HL_NAME(hl_web_view_print_to_pdf) (HL_CFFIPointer* handle, hl_vstring* path, vdynamic* options, int token) {

		WebViewPDFOptions pdf;
		pdf.pageWidth = hl_dyn_getd (options, hl_hash_utf8 ("pageWidth"));
		pdf.pageHeight = hl_dyn_getd (options, hl_hash_utf8 ("pageHeight"));
		pdf.marginTop = hl_dyn_getd (options, hl_hash_utf8 ("marginTop"));
		pdf.marginRight = hl_dyn_getd (options, hl_hash_utf8 ("marginRight"));
		pdf.marginBottom = hl_dyn_getd (options, hl_hash_utf8 ("marginBottom"));
		pdf.marginLeft = hl_dyn_getd (options, hl_hash_utf8 ("marginLeft"));
		pdf.scale = hl_dyn_getd (options, hl_hash_utf8 ("scale"));
		pdf.landscape = hl_dyn_geti (options, hl_hash_utf8 ("landscape"), &hlt_bool) != 0;
		pdf.printBackground = hl_dyn_geti (options, hl_hash_utf8 ("printBackground"), &hlt_bool) != 0;
		pdf.repeatTableHeaders = hl_dyn_geti (options, hl_hash_utf8 ("repeatTableHeaders"), &hlt_bool) != 0;

		((WebView*)handle->ptr)->PrintToPDF (hl_to_utf8 (path->bytes), &pdf, token);

	}


	void lime_web_view_process_events () {

		WebView::ProcessEvents ();

	}


	HL_PRIM void HL_NAME(hl_web_view_process_events) () {

		WebView::ProcessEvents ();

	}


	void lime_web_view_release_focus (value handle) {

		((WebView*)val_data (handle))->ReleaseFocus ();

	}


	HL_PRIM void HL_NAME(hl_web_view_release_focus) (HL_CFFIPointer* handle) {

		((WebView*)handle->ptr)->ReleaseFocus ();

	}


	void lime_web_view_reload (value handle) {

		((WebView*)val_data (handle))->Reload ();

	}


	HL_PRIM void HL_NAME(hl_web_view_reload) (HL_CFFIPointer* handle) {

		((WebView*)handle->ptr)->Reload ();

	}


	void lime_web_view_set_bounds (value handle, int x, int y, int width, int height) {

		((WebView*)val_data (handle))->SetBounds (x, y, width, height);

	}


	HL_PRIM void HL_NAME(hl_web_view_set_bounds) (HL_CFFIPointer* handle, int x, int y, int width, int height) {

		((WebView*)handle->ptr)->SetBounds (x, y, width, height);

	}


	void lime_web_view_set_navigation_callback (value callback) {

		navigationCallback = new ValuePointer (callback);
		WebView::SetNavigationHandler (CallNavigationCallback);

	}


	HL_PRIM void HL_NAME(hl_web_view_set_navigation_callback) (vclosure* callback) {

		navigationCallback = new ValuePointer (callback);
		WebView::SetNavigationHandler (CallNavigationCallback);

	}


	void lime_web_view_set_visible (value handle, bool visible) {

		((WebView*)val_data (handle))->SetVisible (visible);

	}


	HL_PRIM void HL_NAME(hl_web_view_set_visible) (HL_CFFIPointer* handle, bool visible) {

		((WebView*)handle->ptr)->SetVisible (visible);

	}


	void lime_web_view_stop (value handle) {

		((WebView*)val_data (handle))->Stop ();

	}


	HL_PRIM void HL_NAME(hl_web_view_stop) (HL_CFFIPointer* handle) {

		((WebView*)handle->ptr)->Stop ();

	}


	DEFINE_PRIME2v (lime_web_view_add_init_script);
	DEFINE_PRIME0v (lime_web_view_cancel_navigation);
	DEFINE_PRIME1 (lime_web_view_capture);
	DEFINE_PRIME1v (lime_web_view_close);
	DEFINE_PRIME7 (lime_web_view_create);
	DEFINE_PRIME3v (lime_web_view_evaluate_java_script);
	DEFINE_PRIME1v (lime_web_view_focus);
	DEFINE_PRIME1 (lime_web_view_get_can_go_back);
	DEFINE_PRIME1 (lime_web_view_get_can_go_forward);
	DEFINE_PRIME1 (lime_web_view_get_id);
	DEFINE_PRIME0 (lime_web_view_get_navigation);
	DEFINE_PRIME1 (lime_web_view_get_title);
	DEFINE_PRIME1 (lime_web_view_get_url);
	DEFINE_PRIME1v (lime_web_view_go_back);
	DEFINE_PRIME1v (lime_web_view_go_forward);
	DEFINE_PRIME0 (lime_web_view_is_supported);
	DEFINE_PRIME2v (lime_web_view_load);
	DEFINE_PRIME2v (lime_web_view_load_html);
	DEFINE_PRIME0 (lime_web_view_poll_event);
	DEFINE_PRIME2v (lime_web_view_post_message);
	DEFINE_PRIME4v (lime_web_view_print_to_pdf);
	DEFINE_PRIME0v (lime_web_view_process_events);
	DEFINE_PRIME1v (lime_web_view_release_focus);
	DEFINE_PRIME1v (lime_web_view_reload);
	DEFINE_PRIME5v (lime_web_view_set_bounds);
	DEFINE_PRIME1v (lime_web_view_set_navigation_callback);
	DEFINE_PRIME2v (lime_web_view_set_visible);
	DEFINE_PRIME1v (lime_web_view_stop);


	#define _TCFFIPOINTER _DYN

	DEFINE_HL_PRIM (_VOID, hl_web_view_add_init_script, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_VOID, hl_web_view_cancel_navigation, _NO_ARG);
	DEFINE_HL_PRIM (_BYTES, hl_web_view_capture, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_web_view_close, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_web_view_create, _TCFFIPOINTER _I32 _I32 _I32 _I32 _I32 _STRING);
	DEFINE_HL_PRIM (_VOID, hl_web_view_evaluate_java_script, _TCFFIPOINTER _STRING _I32);
	DEFINE_HL_PRIM (_VOID, hl_web_view_focus, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_web_view_get_can_go_back, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_web_view_get_can_go_forward, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_web_view_get_id, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BYTES, hl_web_view_get_navigation, _NO_ARG);
	DEFINE_HL_PRIM (_BYTES, hl_web_view_get_title, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BYTES, hl_web_view_get_url, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_web_view_go_back, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_web_view_go_forward, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_web_view_is_supported, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_web_view_load, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_VOID, hl_web_view_load_html, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_BYTES, hl_web_view_poll_event, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_web_view_post_message, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_VOID, hl_web_view_print_to_pdf, _TCFFIPOINTER _STRING _DYN _I32);
	DEFINE_HL_PRIM (_VOID, hl_web_view_process_events, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_web_view_release_focus, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_web_view_reload, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_web_view_set_bounds, _TCFFIPOINTER _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_web_view_set_navigation_callback, _FUN (_VOID, _NO_ARG));
	DEFINE_HL_PRIM (_VOID, hl_web_view_set_visible, _TCFFIPOINTER _BOOL);
	DEFINE_HL_PRIM (_VOID, hl_web_view_stop, _TCFFIPOINTER);


}


extern "C" int lime_web_view_register_prims () {

	return 0;

}
