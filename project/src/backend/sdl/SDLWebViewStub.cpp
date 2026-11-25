#include <ui/WebView.h>


namespace lime {


	WebView* WebView::Create (Window* window, int x, int y, int width, int height, int flags, const char* userAgent) {

		return 0;

	}


	bool WebView::IsSupported () {

		return false;

	}


	std::string WebView::PollEvent () {

		return std::string ();

	}


	void WebView::ProcessEvents () {}


	void WebView::CancelNavigation () {}


	std::string WebView::GetNavigation () {

		return std::string ();

	}


	void WebView::SetNavigationHandler (void (*handler) ()) {}


}
