#ifndef PLATFORM_TIZEN_TIZEN_STAGE_H
#define PLATFORM_TIZEN_TIZEN_STAGE_H


#include <Display.h>
#include "renderer/common/Surface.h"
#include "renderer/common/HardwareContext.h"


namespace nme {
	
	
	class TizenStage : public Stage {
		
		public:
			
			TizenStage (int inWidth, int inHeight);
			~TizenStage ();
			
			void Flip ();
			void GetMouse ();
			void Resize (const int inWidth, const int inHeight);
			void SetCursor (Cursor inCursor);
			
			Surface *GetPrimarySurface () { return mPrimarySurface; }
			bool isOpenGL () const { return true; }
		
		private:
			
			HardwareContext *mOpenGLContext;
			Surface *mPrimarySurface;
		
	};
	
	
}


#endif
