#ifndef PLATFORM_TIZEN_TIZEN_FRAME_H
#define PLATFORM_TIZEN_TIZEN_FRAME_H


#include <Display.h>
#include "platform/tizen/TizenStage.h"


namespace lime {
	
	
	class TizenFrame : public Frame {
		
		public:
			
			TizenFrame (int inW, int inH);
			~TizenFrame ();
			
			void Resize (const int inWidth, const int inHeight);
			void SetIcon ();
			void SetTitle ();
			
			Stage *GetStage () { return mStage; }
			inline void HandleEvent (Event &event) { mStage->HandleEvent (event); }
			
		private:
			
			TizenStage *mStage;
		
	};
	
	
}


#endif
