#ifndef LIME_UI_WEB_VIEW_H
#define LIME_UI_WEB_VIEW_H


#include <ui/Window.h>
#include <string>


namespace lime {


	enum WebViewFlags {

		WEB_VIEW_FLAG_CONTEXT_MENU = 0x01,
		WEB_VIEW_FLAG_KEYBOARD_SHORTCUTS = 0x02,
		WEB_VIEW_FLAG_DEV_TOOLS = 0x04,
		WEB_VIEW_FLAG_STATUS_BAR = 0x08,
		WEB_VIEW_FLAG_ZOOM = 0x10,
		WEB_VIEW_FLAG_MEDIA_NEEDS_USER_ACTION = 0x20,
		WEB_VIEW_FLAG_HIDDEN = 0x40

	};


	struct WebViewPDFOptions {

		double pageWidth;
		double pageHeight;
		double marginTop;
		double marginRight;
		double marginBottom;
		double marginLeft;
		double scale;
		bool landscape;
		bool printBackground;
		bool repeatTableHeaders;

	};


	class WebView {

		public:

			// A view over window, or with no window at all, one that is never shown
			static WebView* Create (Window* window, int x, int y, int width, int height, int flags, const char* userAgent);
			static bool IsSupported ();

			// The next thing that happened, as a record for NativeWebView to read, or nothing.
			// A record ends with what a page sent, so records cannot be joined by any separator.
			static std::string PollEvent ();

			// Runs the engines' own work, for hosts whose event loop does not
			static void ProcessEvents ();

			// A navigation waits for an answer, so it cannot wait for the next PollEvents.
			// handler runs on the main thread, and calls CancelNavigation to stop it.
			static void CancelNavigation ();
			static std::string GetNavigation ();
			static void SetNavigationHandler (void (*handler) ());

			virtual ~WebView () {}

			virtual void AddInitScript (const char* script) = 0;
			virtual std::string Capture () = 0;
			virtual void Close () = 0;
			virtual void EvaluateJavaScript (const char* script, int token) = 0;
			virtual void Focus () = 0;
			virtual bool GetCanGoBack () = 0;
			virtual bool GetCanGoForward () = 0;
			virtual int GetID () = 0;
			virtual std::string GetTitle () = 0;
			virtual std::string GetURL () = 0;
			virtual void GoBack () = 0;
			virtual void GoForward () = 0;
			virtual void Load (const char* url) = 0;
			virtual void LoadHTML (const char* html) = 0;
			virtual void PostToPage (const char* message) = 0;
			virtual void PrintToPDF (const char* path, const WebViewPDFOptions* options, int token) = 0;
			virtual void Reload () = 0;
			virtual void ReleaseFocus () = 0;

			// The handle was collected
			virtual void Release () { delete this; }

			virtual void SetBounds (int x, int y, int width, int height) = 0;
			virtual void SetVisible (bool visible) = 0;
			virtual void Stop () = 0;

	};


}


#endif
