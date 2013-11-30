#include "platform/tizen/TizenApplication.h"


using namespace Tizen::Graphics::Opengl;


namespace lime {
	
	
	FrameCreationCallback sgCallback;
	unsigned int sgFlags;
	int sgHeight;
	const char *sgTitle;
	TizenFrame *sgTizenFrame;
	int sgWidth;
	
	
	void CreateMainFrame (FrameCreationCallback inOnFrame, int inWidth, int inHeight, unsigned int inFlags, const char *inTitle, Surface *inIcon) {
		
		sgCallback = inOnFrame;
		sgWidth = inWidth;
		sgHeight = inHeight;
		sgFlags = inFlags;
		sgTitle = inTitle;
		
		if (sgWidth == 0 && sgHeight == 0) {
			
			// Hard-code screen size for now
			
			sgWidth = 720;
			sgHeight = 1280;
			
		}
		
		Tizen::Base::Collection::ArrayList args (Tizen::Base::Collection::SingleObjectDeleter);
		args.Construct ();
		result r = Tizen::App::Application::Execute (TizenApplication::CreateInstance, &args);
		
	}
	
	
	void StartAnimation () {}
	void PauseAnimation () {}
	void ResumeAnimation () {}
	void StopAnimation () {}
	
	
	TizenApplication::TizenApplication (void) {
		
		mEGLDisplay = EGL_NO_DISPLAY;
		mEGLSurface = EGL_NO_SURFACE;
		mEGLConfig = null;
		mEGLContext = EGL_NO_CONTEXT;
		mForm = null;
		mTimer = null;
		
	}
	
	
	TizenApplication::~TizenApplication (void) {}
	
	
	void TizenApplication::Cleanup (void) {
		
		if (mTimer != null) {
			
			mTimer->Cancel ();
			delete mTimer;
			mTimer = null;
			
		}
		
		Event close (etQuit);
		sgTizenFrame->HandleEvent (close);
		
		Event lostFocus (etLostInputFocus);
		sgTizenFrame->HandleEvent (lostFocus);
		
		Event deactivate (etDeactivate);
		sgTizenFrame->HandleEvent (deactivate);
		
		Event kill (etDestroyHandler);
		sgTizenFrame->HandleEvent (kill);
		
	}


	Tizen::App::Application* TizenApplication::CreateInstance (void) {
		
		return new (std::nothrow) TizenApplication ();
		
	}
	
	
	bool TizenApplication::OnAppInitializing (Tizen::App::AppRegistry& appRegistry) {
		
		Tizen::Ui::Controls::Frame* appFrame = new (std::nothrow) Tizen::Ui::Controls::Frame ();
		appFrame->Construct ();
		this->AddFrame (*appFrame);
		
		mForm = new (std::nothrow) TizenForm (this);
		mForm->Construct (Tizen::Ui::Controls::FORM_STYLE_NORMAL);
		GetAppFrame ()->GetFrame ()->AddControl (mForm);
		
		mForm->AddKeyEventListener (*this);
		mForm->AddTouchEventListener (*this);
		
		bool ok = limeEGLCreate (mForm, sgWidth, sgHeight, 2, (sgFlags & wfDepthBuffer) ? 16 : 0, (sgFlags & wfStencilBuffer) ? 8 : 0, 0);
		
		mTimer = new (std::nothrow) Tizen::Base::Runtime::Timer;
		mTimer->Construct (*this);
		
		Tizen::System::PowerManager::AddScreenEventListener (*this);
		
		sgTizenFrame = new TizenFrame (sgWidth, sgHeight);
		sgCallback (sgTizenFrame);
		
		return true;
		
	}
	
	
	bool TizenApplication::OnAppTerminating (Tizen::App::AppRegistry& appRegistry, bool forcedTermination) {
		
		Cleanup ();

		return true;
		
	}
	
	
	void TizenApplication::OnBackground (void) {
		
		if (mTimer != null) {
			
			mTimer->Cancel ();
			
		}
		
		Event lostFocus (etLostInputFocus);
		sgTizenFrame->HandleEvent (lostFocus);
		
		Event deactivate (etDeactivate);
		sgTizenFrame->HandleEvent (deactivate);
		
	}
	
	
	void TizenApplication::OnBatteryLevelChanged (Tizen::System::BatteryLevel batteryLevel) {}
	
	
	void TizenApplication::OnForeground (void) {
		
		if (mTimer != null) {
			
			mTimer->Start (10);
			
		}
		
		Event activate (etActivate);
		sgTizenFrame->HandleEvent (activate);
		
		Event gotFocus (etGotInputFocus);
		sgTizenFrame->HandleEvent (gotFocus);
		
	}
	
	
	void TizenApplication::OnKeyLongPressed (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode) {}
	
	
	void TizenApplication::OnKeyPressed (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode) {
		
		
		
	}
	
	
	void TizenApplication::OnKeyReleased (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode) {
		
		if (keyCode == Tizen::Ui::KEY_BACK || keyCode == Tizen::Ui::KEY_ESC) {
			
			Terminate ();
			
		}
		
	}
	
	
	void TizenApplication::OnLowMemory (void) {}
	void TizenApplication::OnScreenOn (void) {}
	void TizenApplication::OnScreenOff (void) {}
	
	
	void TizenApplication::OnTimerExpired (Tizen::Base::Runtime::Timer& timer) {
		
		if (mTimer == null) {
			
			return;
			
		}
		
		mTimer->Start (10);
		
		Event poll (etPoll);
		sgTizenFrame->HandleEvent (poll);
		
	}
	
	
	void TizenApplication::OnTouchCanceled (const Tizen::Ui::Control &source, const Tizen::Graphics::Point &currentPosition, const Tizen::Ui::TouchEventInfo &touchInfo) {}
	void TizenApplication::OnTouchFocusIn (const Tizen::Ui::Control &source, const Tizen::Graphics::Point &currentPosition, const Tizen::Ui::TouchEventInfo &touchInfo) {}
	void TizenApplication::OnTouchFocusOut (const Tizen::Ui::Control &source, const Tizen::Graphics::Point &currentPosition, const Tizen::Ui::TouchEventInfo &touchInfo) {}
	
	
	void TizenApplication::OnTouchMoved (const Tizen::Ui::Control &source, const Tizen::Graphics::Point &currentPosition, const Tizen::Ui::TouchEventInfo &touchInfo) {
		
		AppLog ("OnTouchMoved: (%d x %d)", currentPosition.x, currentPosition.y);
		
	}
	
	
	void TizenApplication::OnTouchPressed (const Tizen::Ui::Control &source, const Tizen::Graphics::Point &currentPosition, const Tizen::Ui::TouchEventInfo &touchInfo) {
		
		AppLog ("OnTouchPressed: (%d x %d)", currentPosition.x, currentPosition.y);
		
		
	}
	
	
	void TizenApplication::OnTouchReleased (const Tizen::Ui::Control &source, const Tizen::Graphics::Point &currentPosition, const Tizen::Ui::TouchEventInfo &touchInfo) {
		
		AppLog ("OnTouchReleased: (%d x %d)", currentPosition.x, currentPosition.y);
		
	}
	
	
}
