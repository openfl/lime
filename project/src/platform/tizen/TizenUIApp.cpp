#include <Display.h>
#include "platform/tizen/TizenUIApp.h"
#include "platform/tizen/TizenUIFrame.h"


//using namespace Tizen::App;
//using namespace Tizen::Base;
//using namespace Tizen::System;
//using namespace Tizen::Ui;
//using namespace Tizen::Ui::Controls;


namespace nme {
	
	
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
		
		Tizen::Base::Collection::ArrayList args (Tizen::Base::Collection::SingleObjectDeleter);
		args.Construct ();
		result r = Tizen::App::UiApp::Execute(TizenUIApp::CreateInstance, &args);
		
	}
	
	
	TizenUIApp::TizenUIApp (void) {}
	TizenUIApp::~TizenUIApp (void) {}
	
	
	Tizen::App::UiApp* TizenUIApp::CreateInstance (void) {
		
		return new TizenUIApp ();
		
	}
	
	
	bool TizenUIApp::OnAppInitialized (void) {
		
		//AppLog ("Initialized");
		
		// TODO:
		// Add code to do after initialization here. 
		
		// Create a Frame
		TizenUIFrame* pTizenGLSampleFrame = new TizenUIFrame();
		pTizenGLSampleFrame->Construct();
		pTizenGLSampleFrame->SetBackgroundColor(Tizen::Graphics::Color(0xFF0000, false));
		pTizenGLSampleFrame->SetName(Tizen::Base::String(sgTitle));
		AddFrame(*pTizenGLSampleFrame);
		
		pTizenGLSampleFrame->AddKeyEventListener(*this);
		/*{
			__player = new Tizen::Graphics::Opengl::GlPlayer;
			__player->Construct(Tizen::Graphics::Opengl::EGL_CONTEXT_CLIENT_VERSION_1_X, pTizenGLSampleFrame);
			
			__player->SetFps(60);
			__player->SetEglAttributePreset(Tizen::Graphics::Opengl::EGL_ATTRIBUTES_PRESET_RGB565);
			
			__player->Start();
		}
		
		__renderer = new GlRendererTemplate();
		__player->SetIGlRenderer(__renderer);*/
		
		sgTizenFrame = new TizenFrame (sgWidth, sgHeight);
		//sgTizenFrame = createWindowFrame (inTitle, inWidth, inHeight, inFlags);
		sgCallback (sgTizenFrame);
		
		return true;
		
	}
	
	
	bool TizenUIApp::OnAppInitializing (Tizen::App::AppRegistry& appRegistry) {
		
		// TODO:
		// Initialize Frame and App specific data.
		// The App's permanent data and context can be obtained from the appRegistry.
		//
		// If this method is successful, return true; otherwise, return false.
		// If this method returns false, the App will be terminated.
		
		// Uncomment the following statement to listen to the screen on/off events.
		//PowerManager::SetScreenEventListener(*this);
		
		// TODO:
		// Add your initialization code here
		
		return true;
		
	}
	
	
	bool TizenUIApp::OnAppTerminating (Tizen::App::AppRegistry& appRegistry, bool forcedTermination) {
		
		// TODO:
		// Deallocate resources allocated by this App for termination.
		// The App's permanent data and context can be saved via appRegistry.
		
		/*__player->Stop ();
		
		if(__renderer != null)
		{
			delete __renderer;
		}
		delete __player;*/
		
		return true;
		
	}
	
	
	bool TizenUIApp::OnAppWillTerminate (void) {
		
		// TODO:
		// Add code to do something before application termination. 
		
		return true;
		
	}
	
	
	void TizenUIApp::OnBackground (void) {
		
		// TODO:
		// Stop drawing when the application is moved to the background.
		
	}
	
	
	void TizenUIApp::OnBatteryLevelChanged (Tizen::System::BatteryLevel batteryLevel) {
		
		// TODO:
		// Handle any changes in battery level here.
		// Stop using multimedia features(camera, mp3 etc.) if the battery level is CRITICAL.
		
	}
	
	
	void TizenUIApp::OnForeground (void) {
		
		// TODO:
		// Start or resume drawing when the application is moved to the foreground.
		
	}
	
	
	void TizenUIApp::OnKeyLongPressed (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode) {}
	void TizenUIApp::OnKeyPressed (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode) {}
	
	
	void TizenUIApp::OnKeyReleased (const Tizen::Ui::Control& source, Tizen::Ui::KeyCode keyCode) {
		
		if (keyCode == Tizen::Ui::KEY_BACK || keyCode == Tizen::Ui::KEY_ESC) {
			
			Terminate ();
			
		}
		
	}
	
	
	void TizenUIApp::OnLowMemory (void) {
		
		// TODO:
		// Free unnecessary resources or close the application.
		
	}
	
	
	void TizenUIApp::OnScreenOff (void) {
		
		// TODO:
		// Unless there is a strong reason to do otherwise, release resources (such as 3D, media, and sensors) to allow the device
		// to enter the sleep mode to save the battery.
		// Invoking a lengthy asynchronous method within this listener method can be risky, because it is not guaranteed to invoke a
		// callback before the device enters the sleep mode.
		// Similarly, do not perform lengthy operations in this listener method. Any operation must be a quick one.
		
	}
	
	
	void TizenUIApp::OnScreenOn (void) {
		
		// TODO:
		// Get the released resources or resume the operations that were paused or stopped in OnScreenOff().
		
	}
	
	
}
