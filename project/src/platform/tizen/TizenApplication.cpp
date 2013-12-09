#include "platform/tizen/TizenApplication.h"


using namespace Tizen::Graphics::Opengl;


namespace lime {
	
	
	int gFixedOrientation = -1;
	//double mAccelX;
	//double mAccelY;
	//double mAccelZ;
	int mSingleTouchID;
	FrameCreationCallback sgCallback;
	unsigned int sgFlags;
	int sgHeight;
	const char *sgTitle;
	TizenFrame *sgTizenFrame;
	int sgWidth;
	
	enum { NO_TOUCH = -1 };
	
	
	void CreateMainFrame (FrameCreationCallback inOnFrame, int inWidth, int inHeight, unsigned int inFlags, const char *inTitle, Surface *inIcon) {
		
		sgCallback = inOnFrame;
		sgWidth = inWidth;
		sgHeight = inHeight;
		sgFlags = inFlags;
		sgTitle = inTitle;
		
		mSingleTouchID = NO_TOUCH;
		
		//if (sgWidth == 0 && sgHeight == 0) {
			
			// Hard-code screen size for now
			
			sgWidth = 720;
			sgHeight = 1280;
			
		//}
		
		// For now, swap the width/height for proper EGL initialization, when landscape
		
		if (gFixedOrientation == 3 || gFixedOrientation == 4) {
			
			int temp = sgWidth;
			sgWidth = sgHeight;
			sgHeight = temp;
			
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
		
		//mAccelX = 0;
		//mAccelY = 0;
		//mAccelZ = 0;
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
		
		/*if (mSensorManager) {
			
			mSensorManager->RemoveSensorListener (*this);
			delete mSensorManager;
			mSensorManager = null;
			
		}*/
		
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
		
		if (gFixedOrientation == 3 || gFixedOrientation == 4) {
			
			mForm->SetOrientation (Tizen::Ui::ORIENTATION_LANDSCAPE);
			
		}
		
		GetAppFrame ()->GetFrame ()->AddControl (mForm);
		
		mForm->AddKeyEventListener (*this);
		mForm->AddTouchEventListener (*this);
		mForm->SetMultipointTouchEnabled (true);
		
		/*long interval = 0L;
		mSensorManager = new Tizen::Uix::Sensor::SensorManager ();
		mSensorManager->Construct ();
		mSensorManager->GetMinInterval (Tizen::Uix::Sensor::SENSOR_TYPE_ACCELERATION, interval);
		
		if (interval < 50) {
			
			interval = 50;
			
		}
		
		mSensorManager->AddSensorListener (*this, Tizen::Uix::Sensor::SENSOR_TYPE_ACCELERATION, interval, true);*/
		
		bool ok = limeEGLCreate (mForm, sgWidth, sgHeight, 1, (sgFlags & wfDepthBuffer) ? 16 : 0, (sgFlags & wfStencilBuffer) ? 8 : 0, 0);
		
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
	
	
	//void OnDataReceived (Tizen::Uix::Sensor::SensorType sensorType, Tizen::Uix::Sensor::SensorData& sensorData, result r) {
		
		//Tizen::Uix::Sensor::AccelerationSensorData& data = static_cast<Tizen::Uix::Sensor::AccelerationSensorData&>(sensorData);
		
		//mAccelX = -data.x;
		//mAccelY = -data.y;
		//mAccelZ = -data.z;
		
	//}
	
	
	void TizenApplication::OnForeground (void) {
		
		Event activate (etActivate);
		sgTizenFrame->HandleEvent (activate);
		
		Event gotFocus (etGotInputFocus);
		sgTizenFrame->HandleEvent (gotFocus);
		
		Event poll (etPoll);
		sgTizenFrame->HandleEvent (poll);
		
		double next = sgTizenFrame->GetStage ()->GetNextWake () - GetTimeStamp ();
		
		if (mTimer != null) {
			
			if (next > 0.001) {
				
				mTimer->Start (next * 1000.0);
				
			} else {
				
				mTimer->Start (1);
				
			}
			
		}
		
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
		
		double next = sgTizenFrame->GetStage ()->GetNextWake () - GetTimeStamp ();
		
		if (next > 0.001) {
			
			mTimer->Start (next * 1000.0);
			
		} else {
			
			mTimer->Start (1);
			
		}
		
		Event poll (etPoll);
		sgTizenFrame->HandleEvent (poll);
		
	}
	
	
	void TizenApplication::OnTouchCanceled (const Tizen::Ui::Control &source, const Tizen::Graphics::Point &currentPosition, const Tizen::Ui::TouchEventInfo &touchInfo) {}
	void TizenApplication::OnTouchFocusIn (const Tizen::Ui::Control &source, const Tizen::Graphics::Point &currentPosition, const Tizen::Ui::TouchEventInfo &touchInfo) {}
	void TizenApplication::OnTouchFocusOut (const Tizen::Ui::Control &source, const Tizen::Graphics::Point &currentPosition, const Tizen::Ui::TouchEventInfo &touchInfo) {}
	
	
	void TizenApplication::OnTouchMoved (const Tizen::Ui::Control &source, const Tizen::Graphics::Point &currentPosition, const Tizen::Ui::TouchEventInfo &touchInfo) {
		
		Event mouse (etTouchMove, currentPosition.x, currentPosition.y);
		mouse.value = touchInfo.GetPointId ();
		
		if (mSingleTouchID == NO_TOUCH || mouse.value == mSingleTouchID) {
			
			mouse.flags |= efPrimaryTouch;
			
		}
		
		sgTizenFrame->HandleEvent (mouse);
		
	}
	
	
	void TizenApplication::OnTouchPressed (const Tizen::Ui::Control &source, const Tizen::Graphics::Point &currentPosition, const Tizen::Ui::TouchEventInfo &touchInfo) {
		
		Event mouse (etTouchBegin, currentPosition.x, currentPosition.y);
		mouse.value = touchInfo.GetPointId ();
		
		if (mSingleTouchID == NO_TOUCH || mouse.value == mSingleTouchID) {
			
			mouse.flags |= efPrimaryTouch;
			
		}
		
		sgTizenFrame->HandleEvent (mouse);
		
	}
	
	
	void TizenApplication::OnTouchReleased (const Tizen::Ui::Control &source, const Tizen::Graphics::Point &currentPosition, const Tizen::Ui::TouchEventInfo &touchInfo) {
		
		Event mouse (etTouchEnd, currentPosition.x, currentPosition.y);
		mouse.value = touchInfo.GetPointId ();
		
		if (mSingleTouchID == NO_TOUCH || mouse.value == mSingleTouchID) {
			
			mouse.flags |= efPrimaryTouch;
			
		}
		
		if (mSingleTouchID == mouse.value) {
			
			mSingleTouchID = NO_TOUCH;
			
		}
		
		sgTizenFrame->HandleEvent (mouse);
		
	}
	
	
	bool ClearUserPreference (const char *inId) {
		
		result r = E_SUCCESS;
		
		Tizen::App::AppRegistry* appRegistry = Tizen::App::AppRegistry::GetInstance ();
		r = appRegistry->Remove (inId);
		
		return (r == E_SUCCESS);
		
	}
	
	
	bool GetAcceleration (double &outX, double &outY, double &outZ) {
		
		//if (gFixedOrientation == 3 || gFixedOrientation == 4) {
		
		//outX = mAccelX;
		//outY = mAccelY;
		//outZ = mAccelZ;
		outX = 0;
		outY = 0;
		outZ = -1;
		return true;
		
		//}
		
		/*int result = accelerometer_read_forces (&outX, &outY, &outZ);
		
		if (getenv ("FORCE_PORTRAIT") != NULL) {
			
			int cache = outX;
			outX = outY;
			outY = -cache;
			
		}
		
		outZ = -outZ;*/
		
	}
	
	
	std::string GetUserPreference (const char *inId) {
		
		Tizen::Base::String value; 
		result r = E_SUCCESS;
		
		Tizen::App::AppRegistry* appRegistry = Tizen::App::AppRegistry::GetInstance ();
		r = appRegistry->Get (inId, value);
		
		if (r == E_SUCCESS) {
			
			std::wstring dir = std::wstring (value.GetPointer ());
			return std::string (dir.begin (), dir.end ());
			
		}
		
		return "";
		
	}
	
	
	bool LaunchBrowser (const char *inUtf8URL) {
		
		Tizen::Base::String uri = Tizen::Base::String(inUtf8URL);
		Tizen::App::AppControl* pAc = Tizen::App::AppManager::FindAppControlN (L"tizen.internet", L"http://tizen.org/appcontrol/operation/view");
		
		if (pAc) {
			
			pAc->Start (&uri, null, null, null);
			delete pAc;
			
		}
		
		return true;	
		
	}
	
	
	bool SetUserPreference (const char *inId, const char *inPreference) {
		
		result r = E_SUCCESS;
		
		Tizen::App::AppRegistry* appRegistry = Tizen::App::AppRegistry::GetInstance ();
		r = appRegistry->Set (inId, inPreference);
		
		if (r != E_SUCCESS) {
			
			r = appRegistry->Add (inId, inPreference);
			
		}
		
		return (r == E_SUCCESS);
		
	}
	
	
}
