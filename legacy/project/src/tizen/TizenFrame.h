#ifndef TIZEN_FRAME_H
#define TIZEN_FRAME_H


#include <Display.h>
#include "./TizenStage.h"


namespace nme {
	
	
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
