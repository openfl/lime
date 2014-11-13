#ifndef TIZEN_STAGE_H
#define TIZEN_STAGE_H


#include <Display.h>
#include <Surface.h>


namespace nme {
	
	
	class HardwareRenderer;
	
	
	class TizenStage : public Stage {
		
		public:
			
			TizenStage (int inWidth, int inHeight);
			~TizenStage ();
			
			void Flip ();
			void GetMouse ();
			bool getMultitouchSupported ();
			bool getMultitouchActive ();
			void Resize (const int inWidth, const int inHeight);
			void SetCursor (Cursor inCursor);
			void setMultitouchActive (bool inActive);
			
			Surface *GetPrimarySurface () { return mPrimarySurface; }
			bool isOpenGL () const { return true; }
		
		private:
			
			HardwareRenderer *mOpenGLContext;
			Surface *mPrimarySurface;
		
	};
	
	
}


#endif
