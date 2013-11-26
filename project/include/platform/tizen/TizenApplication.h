#ifndef PLATFORM_TIZEN_TIZEN_APPLICATION_H
#define PLATFORM_TIZEN_TIZEN_APPLICATION_H


#include "platform/tizen/TizenFrame.h"
#include "renderer/opengl/Egl.h"
#include <FApp.h>
#include <FBase.h>
#include <FSystem.h>
#include <FUi.h>
#include <FUiIme.h>
#include <FGraphics.h>
#include <FGraphicsOpengl2.h>


namespace nme {
	
	
	class TizenApplication : public Tizen::App::UiApp, public Tizen::System::IScreenEventListener, public Tizen::Ui::IKeyEventListener, public Tizen::Base::Runtime::ITimerEventListener {
		
		public:
			
			static Tizen::App::Application* CreateInstance (void);
			
			TizenApplication (void);
			virtual ~TizenApplication (void);
			
			//virtual bool OnAppInitialized (void); 
			virtual bool OnAppInitializing (Tizen::App::AppRegistry& appRegistry);
			virtual bool OnAppTerminating (Tizen::App::AppRegistry& appRegistry, bool forcedTermination = false);
			//virtual bool OnAppWillTerminate (void); 
			virtual void OnBackground (void);
			virtual void OnBatteryLevelChanged (Tizen::System::BatteryLevel batteryLevel);
			virtual void OnForeground (void);
			virtual void OnLowMemory (void);
			virtual void OnKeyLongPressed (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode);
			virtual void OnKeyPressed (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode);
			virtual void OnKeyReleased (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode);
			virtual void OnScreenOff (void);
			virtual void OnScreenOn (void);
			virtual void OnTimerExpired (Tizen::Base::Runtime::Timer& timer);
		
		private:
			
			void Cleanup (void);
			
			Tizen::Graphics::Opengl::EGLDisplay mEGLDisplay;
			Tizen::Graphics::Opengl::EGLSurface mEGLSurface;
			Tizen::Graphics::Opengl::EGLConfig mEGLConfig;
			Tizen::Graphics::Opengl::EGLContext mEGLContext;
			Tizen::Ui::Controls::Form* mForm;
			Tizen::Base::Runtime::Timer* mTimer;
		
	};
	
	
	class TizenForm : public Tizen::Ui::Controls::Form {
		
		public:
			
			TizenForm (TizenApplication* inApplication) : mApplication (inApplication) {}
			virtual ~TizenForm (void) {}
			
			virtual result OnDraw (void) {
				
				return E_SUCCESS;
				
			}
			
		private:
			
			TizenApplication* mApplication;
		
	};
	
	
}


#endif
