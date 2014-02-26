#include "platform/tizen/TizenApplication.h"
#include <KeyCodes.h>

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
	
	#define TIZEN_TRANS(x) case Tizen::Ui::KEY_##x: return key##x;
	#define TIZEN_TRANS_TO(x,y) case Tizen::Ui::KEY_##x: return key##y;
	#define TIZEN_KEY(x) Tizen::Ui::KEY_##x
	
	int TizenKeyToFlash(int inKey, bool &outRight) {
		
		outRight = (inKey == TIZEN_KEY(RIGHT_SHIFT) || inKey == TIZEN_KEY(RIGHT_CTRL) ||
					inKey == TIZEN_KEY(RIGHT_ALT) || inKey == TIZEN_KEY(RIGHT_WIN));
		
		
		if (inKey >= TIZEN_KEY(A) && inKey <= TIZEN_KEY(Z))
		  return inKey - TIZEN_KEY(A) + keyA;
		
		if (inKey >= TIZEN_KEY(0) && inKey <= TIZEN_KEY(9))
		  return inKey - TIZEN_KEY(0) + keyNUMBER_0;
		
		if (inKey >= TIZEN_KEY(NUMPAD_0) && inKey <= TIZEN_KEY(NUMPAD_9))
		  return inKey - TIZEN_KEY(NUMPAD_0) + keyNUMPAD_0;
		
		if (inKey >= TIZEN_KEY(FN_1) && inKey <= TIZEN_KEY(FN_5))
		  return inKey - TIZEN_KEY(FN_1) + keyF1;
		
		// Fun, There are some random key mappings between F5 and F6
		if (inKey >= TIZEN_KEY(FN_6) && inKey <= TIZEN_KEY(FN_12))
		  return inKey - TIZEN_KEY(FN_6) + keyF6;
		
		
		switch (inKey)
		{
		  case TIZEN_KEY(RIGHT_ALT):
		  case TIZEN_KEY(LEFT_ALT):
			return keyALTERNATE;
		  case TIZEN_KEY(RIGHT_SHIFT):
		  case TIZEN_KEY(LEFT_SHIFT):
			return keySHIFT;
		  case TIZEN_KEY(RIGHT_CTRL):
		  case TIZEN_KEY(LEFT_CTRL):
			return keyCONTROL;
		  case TIZEN_KEY(RIGHT_WIN):
		  case TIZEN_KEY(LEFT_WIN):
			return keyCOMMAND;

		  TIZEN_TRANS_TO(LEFT_BRACKET,  LEFTBRACKET)
		  TIZEN_TRANS_TO(RIGHT_BRACKET, RIGHTBRACKET)
		  TIZEN_TRANS_TO(APOSTROPHE,    QUOTE)
		  TIZEN_TRANS_TO(GRAVE,         BACKQUOTE)
		  TIZEN_TRANS_TO(CAPSLOCK,      CAPS_LOCK)
		  TIZEN_TRANS_TO(MOVE_END,      END)
		  TIZEN_TRANS_TO(ESC,           ESCAPE)
		  TIZEN_TRANS_TO(MOVE_HOME,     HOME)
		  TIZEN_TRANS_TO(DOT,           PERIOD)
		  TIZEN_TRANS_TO(NUMPAD_DOT,    NUMPAD_DECIMAL)
		  
		  TIZEN_TRANS(BACKSLASH)
		  TIZEN_TRANS(BACKSPACE)
		  TIZEN_TRANS(COMMA)
		  TIZEN_TRANS(DELETE)
		  TIZEN_TRANS(ENTER)
		  TIZEN_TRANS(INSERT)
		  TIZEN_TRANS(DOWN)
		  TIZEN_TRANS(LEFT)
		  TIZEN_TRANS(RIGHT)
		  TIZEN_TRANS(UP)
		  TIZEN_TRANS(MINUS)
		  TIZEN_TRANS(PAGE_UP)
		  TIZEN_TRANS(PAGE_DOWN)
		  TIZEN_TRANS(SEMICOLON)
		  TIZEN_TRANS(SLASH)
		  TIZEN_TRANS(SPACE)
		  TIZEN_TRANS(TAB)
		  
		  TIZEN_TRANS(NUMPAD_ADD)
		  TIZEN_TRANS(NUMPAD_DIVIDE)
		  TIZEN_TRANS(NUMPAD_ENTER)
		  TIZEN_TRANS(NUMPAD_MULTIPLY)
		  TIZEN_TRANS(NUMPAD_SUBTRACT)
		}
        
		return inKey;
	}
	
	void TizenApplication::OnKeyPressed (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode) {
		Event key(etKeyDown);
		key.code = keyCode;
		
		bool right;
		key.value = TizenKeyToFlash(keyCode, right);
		
		if (right)
			key.flags |= efLocationRight;
		
		sgTizenFrame->HandleEvent(key);
	}
	
	
	void TizenApplication::OnKeyReleased (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode) {
		Event key(etKeyUp);
		key.code = keyCode;
		
		bool right;
		key.value = TizenKeyToFlash(keyCode, right);
		
		if (right)
			key.flags |= efLocationRight;
		
		sgTizenFrame->HandleEvent(key);
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
