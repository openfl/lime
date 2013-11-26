#ifndef PLATFORM_TIZEN_TIZEN_UI_FRAME_H
#define PLATFORM_TIZEN_TIZEN_UI_FRAME_H


#include <FApp.h>
#include <FBase.h>
#include <FSystem.h>
#include <FUi.h>
#include <FUiIme.h>
#include <FGraphics.h>
#include <gl.h>


namespace nme {
	
	
	class TizenUIFrame : public Tizen::Ui::Controls::Frame {
		
		public:
			
			TizenUIFrame (void);
			virtual ~TizenUIFrame (void);
			
			virtual result OnInitializing (void);
			virtual result OnTerminating (void);
		
	};
	
	
}


#endif
