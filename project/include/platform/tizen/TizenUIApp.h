#ifndef PLATFORM_TIZEN_TIZEN_UI_APP_H
#define PLATFORM_TIZEN_TIZEN_UI_APP_H


#include "platform/tizen/TizenFrame.h"
#include <FApp.h>
#include <FBase.h>
#include <FSystem.h>
#include <FUi.h>
#include <FUiIme.h>
#include <FGraphics.h>
//#include <gl.h>
#include <FGrpGlPlayer.h>

//#include "GlRendererTemplate.h"


namespace nme {
	
	
	class TizenUIApp : public Tizen::App::UiApp, public Tizen::System::IScreenEventListener, public Tizen::Ui::IKeyEventListener {
		
		public:
			
			static Tizen::App::UiApp* CreateInstance (void);
			
			TizenUIApp (void);
			virtual ~TizenUIApp (void);
			
			virtual bool OnAppInitialized (void); 
			virtual bool OnAppInitializing (Tizen::App::AppRegistry& appRegistry);
			virtual bool OnAppTerminating (Tizen::App::AppRegistry& appRegistry, bool forcedTermination = false);
			virtual bool OnAppWillTerminate (void); 
			virtual void OnBackground (void);
			virtual void OnBatteryLevelChanged (Tizen::System::BatteryLevel batteryLevel);
			virtual void OnForeground (void);
			virtual void OnLowMemory (void);
			virtual void OnKeyLongPressed (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode);
			virtual void OnKeyPressed (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode);
			virtual void OnKeyReleased (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode);
			virtual void OnScreenOff (void);
			virtual void OnScreenOn (void);
		
		private:
			
			//Tizen::Graphics::Opengl::GlPlayer* __player;
			//Tizen::Graphics::Opengl::IGlRenderer* __renderer;
		
	};
	
	
}


#endif
