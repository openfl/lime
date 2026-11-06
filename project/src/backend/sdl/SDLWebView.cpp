#include "SDLApplication.h"
#include <ui/WebView.h>
#include <stagewebview/WebViewBackend.h>
#include <stagewebview/WindowBackend.h>
#include <deque>
#include <vector>


namespace lime {


	// Records of id, type and payload, which NativeWebView reads
	static const char WEB_VIEW_FIELD = '\x1F';
	static const char WEB_VIEW_PART = '\x1D';

	static void (*navigationHandler) () = 0;
	static bool navigationCanceled = false;
	static int navigationID = 0;
	static std::string navigationURL;
	static int nextID = 0;
	static std::deque<std::string> pendingEvents;


	static void PushEvent (int id, const char* type, const std::string& payload) {

		std::string record = std::to_string (id);
		record += WEB_VIEW_FIELD;
		record += type;
		record += WEB_VIEW_FIELD;
		record += payload;
		pendingEvents.push_back (record);

	}


	static void CallNavigationHandler (void*) {

		navigationHandler ();

	}


	// What is asked of an engine that answers later, when the view may be gone
	struct ResultRequest {

		int id;
		int token;
		const char* type;

	};


	class SDLWebView : public WebView {

		public:

			SDLWebView (stagewebview::WebViewBackend* backend, void* host, void* parent, bool visible):
				backend (backend), closing (false), dispatching (false), height (0), host (host), id (++nextID), parent (parent), released (false), visible (visible), width (0), x (0), y (0) {

				stagewebview::WebViewCallbackSet callbacks;
				callbacks.userData = this;
				callbacks.onLocationChanging = OnLocationChanging;
				callbacks.onLocationChange = OnLocationChange;
				callbacks.onComplete = OnComplete;
				callbacks.onError = OnError;
				callbacks.onFocusIn = OnFocusIn;
				callbacks.onFocusOut = OnFocusOut;
				callbacks.onMessage = OnMessage;
				backend->setCallbacks (callbacks);

			}


			~SDLWebView () {

				Destroy ();

			}


			virtual void AddInitScript (const char* script) {

				if (backend) backend->addInitScript (script);

			}


			virtual std::string Capture () {

				return backend ? backend->capturePreviewBase64 (0) : std::string ();

			}


			virtual void Close () {

				// An engine cannot be taken down from inside its own handler
				if (dispatching) {

					if (!closing) closed.push_back (this);
					closing = true;

				} else {

					Destroy ();

				}

			}


			virtual void EvaluateJavaScript (const char* script, int token) {

				ResultRequest* request = new ResultRequest ();
				request->id = id;
				request->token = token;
				request->type = "script";

				if (!backend || backend->evaluateJavaScript (script, OnResult, request) != 0) {

					OnResult (request, false, "The webview could not run the script");

				}

			}


			virtual void Focus () {

				if (backend) backend->assignFocus (0);

			}


			virtual bool GetCanGoBack () {

				return backend && backend->canGoBack ();

			}


			virtual bool GetCanGoForward () {

				return backend && backend->canGoForward ();

			}


			virtual int GetID () {

				return id;

			}


			virtual std::string GetTitle () {

				return backend ? backend->getTitle () : std::string ();

			}


			virtual std::string GetURL () {

				return backend ? backend->getLocation () : std::string ();

			}


			virtual void GoBack () {

				if (backend) backend->historyBack ();

			}


			virtual void GoForward () {

				if (backend) backend->historyForward ();

			}


			virtual void Load (const char* url) {

				if (backend) backend->navigate (url);

			}


			virtual void LoadHTML (const char* html) {

				if (backend) backend->setHtml (html);

			}


			virtual void PostToPage (const char* message) {

				if (backend) backend->postMessage (message);

			}


			virtual void PrintToPDF (const char* path, const WebViewPDFOptions* options, int token) {

				ResultRequest* request = new ResultRequest ();
				request->id = id;
				request->token = token;
				request->type = "pdf";

				stagewebview::WebViewPdfOptions pdf;
				pdf.pageWidth = options->pageWidth;
				pdf.pageHeight = options->pageHeight;
				pdf.marginTop = options->marginTop;
				pdf.marginRight = options->marginRight;
				pdf.marginBottom = options->marginBottom;
				pdf.marginLeft = options->marginLeft;
				pdf.scale = options->scale;
				pdf.landscape = options->landscape ? 1 : 0;
				pdf.printBackground = options->printBackground ? 1 : 0;
				pdf.repeatTableHeaders = options->repeatTableHeaders ? 1 : 0;

				if (!backend || backend->printToPdf (path, pdf, OnResult, request) != 0) {

					OnResult (request, false, "The webview could not print");

				}

			}


			virtual void Reload () {

				if (backend) backend->reload ();

			}


			virtual void Release () {

				// A view closed from inside its own handler waits in closed, and goes with it
				if (closing) {

					released = true;

				} else {

					delete this;

				}

			}


			virtual void ReleaseFocus () {

				if (parent) stagewebview::windowSetFocus (parent);

			}


			virtual void SetBounds (int x, int y, int width, int height) {

				this->x = x;
				this->y = y;
				this->width = width;
				this->height = height;
				UpdateHost ();

			}


			virtual void SetVisible (bool visible) {

				this->visible = visible;
				UpdateHost ();

			}


			virtual void Stop () {

				if (backend) backend->stop ();

			}


			static void CloseWaiting () {

				for (size_t i = 0; i < closed.size (); i++) {

					SDLWebView* view = closed[i];
					view->Destroy ();
					view->closing = false;

					if (view->released) delete view;

				}

				closed.clear ();

			}


		private:

			void Destroy () {

				if (backend) {

					delete backend;
					backend = 0;

				}

				if (host) {

					stagewebview::windowDestroy (host);
					host = 0;

				}

			}


			void UpdateHost () {

				if (!host) return;

				stagewebview::windowMove (host, x, y, width, height);

				if (!visible || width <= 0 || height <= 0) {

					stagewebview::windowHide (host);
					return;

				}

				#ifdef HX_WINDOWS
				// WebView2 renders into a widget inside the host, which does not follow it
				void* widget = backend->getNativeHandle (WEBVIEW_NATIVE_HANDLE_KIND_UI_WIDGET);
				if (widget) stagewebview::windowMove (widget, 0, 0, width, height);

				void* controller = backend->getNativeHandle (WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER);
				if (controller) stagewebview::WebViewBackend::webView2ControllerSetBounds (controller, width, height);
				#endif

				stagewebview::windowShow (host);

			}


			static bool OnLocationChanging (void* userData, const std::string& location) {

				SDLWebView* view = (SDLWebView*)userData;

				if (!navigationHandler || view->closing) return false;

				navigationCanceled = false;
				navigationID = view->id;
				navigationURL = location;

				view->dispatching = true;
				SDLApplication::CallFromEventPump (CallNavigationHandler, 0);
				view->dispatching = false;

				return navigationCanceled;

			}


			static void OnLocationChange (void* userData, const std::string& location) {

				PushEvent (((SDLWebView*)userData)->id, "location", location);

			}


			static void OnComplete (void* userData) {

				PushEvent (((SDLWebView*)userData)->id, "complete", "");

			}


			static void OnError (void* userData, const std::string& message) {

				PushEvent (((SDLWebView*)userData)->id, "error", message);

			}


			static void OnFocusIn (void* userData) {

				PushEvent (((SDLWebView*)userData)->id, "focusIn", "");

			}


			static void OnFocusOut (void* userData) {

				PushEvent (((SDLWebView*)userData)->id, "focusOut", "");

			}


			static void OnMessage (void* userData, const std::string& message) {

				PushEvent (((SDLWebView*)userData)->id, "message", message);

			}


			static void OnResult (void* userData, bool success, const std::string& message) {

				ResultRequest* request = (ResultRequest*)userData;

				std::string payload = std::to_string (request->token);
				payload += WEB_VIEW_PART;
				payload += success ? "1" : "0";
				payload += WEB_VIEW_PART;
				payload += message;
				PushEvent (request->id, request->type, payload);

				delete request;

			}


			stagewebview::WebViewBackend* backend;
			bool closing;
			bool dispatching;
			int height;
			void* host;
			int id;
			void* parent;
			bool released;
			bool visible;
			int width;
			int x;
			int y;

			static std::vector<SDLWebView*> closed;

	};


	std::vector<SDLWebView*> SDLWebView::closed;


	WebView* WebView::Create (Window* window, int x, int y, int width, int height, int flags, const char* userAgent) {

		stagewebview::WebViewCreateOptions options;
		options.enableContextMenu = (flags & WEB_VIEW_FLAG_CONTEXT_MENU) ? 1 : 0;
		options.enableKeyboardShortcuts = (flags & WEB_VIEW_FLAG_KEYBOARD_SHORTCUTS) ? 1 : 0;
		options.enableDevTools = (flags & WEB_VIEW_FLAG_DEV_TOOLS) ? 1 : 0;
		options.enableStatusBar = (flags & WEB_VIEW_FLAG_STATUS_BAR) ? 1 : 0;
		options.enableZoom = (flags & WEB_VIEW_FLAG_ZOOM) ? 1 : 0;
		options.mediaPlaybackRequiresUserAction = (flags & WEB_VIEW_FLAG_MEDIA_NEEDS_USER_ACTION) ? 1 : 0;
		if (userAgent) options.userAgent = userAgent;

		void* parent = 0;
		void* host = 0;

		if (window) {

			void* display;
			if (window->GetNativeHandle (&parent, &display) == WINDOW_HANDLE_NONE) return 0;

			host = stagewebview::windowCreateChildWindow (parent, x, y, width, height);
			if (!host) return 0;

		} else {

			options.startHidden = 1;

		}

		stagewebview::WebViewBackend* backend = stagewebview::WebViewBackend::create ((flags & WEB_VIEW_FLAG_DEV_TOOLS) ? 1 : 0, host, options);

		if (!backend) {

			if (host) stagewebview::windowDestroy (host);
			return 0;

		}

		SDLWebView* view = new SDLWebView (backend, host, parent, !(flags & WEB_VIEW_FLAG_HIDDEN));
		view->SetBounds (x, y, width, height);
		return view;

	}


	bool WebView::IsSupported () {

		return stagewebview::WebViewBackend::isSupported ();

	}


	std::string WebView::PollEvent () {

		SDLWebView::CloseWaiting ();

		if (pendingEvents.empty ()) return std::string ();

		std::string record = pendingEvents.front ();
		pendingEvents.pop_front ();
		return record;

	}


	void WebView::ProcessEvents () {

		stagewebview::WebViewBackend::processEvents ();

	}


	void WebView::CancelNavigation () {

		navigationCanceled = true;

	}


	std::string WebView::GetNavigation () {

		return std::to_string (navigationID) + WEB_VIEW_FIELD + navigationURL;

	}


	void WebView::SetNavigationHandler (void (*handler) ()) {

		navigationHandler = handler;

	}


}
