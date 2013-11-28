#include "platform/tizen/TizenFrame.h"


namespace lime {
	
	
	TizenFrame::TizenFrame (int inW, int inH) {
		
		mStage = new TizenStage (inW, inH);
		mStage->IncRef ();
		
	}
	
	
	TizenFrame::~TizenFrame () {
		
		mStage->DecRef ();
		
	}
	
	
	void TizenFrame::Resize (const int inWidth, const int inHeight) {
		
		mStage->Resize (inWidth, inHeight);
		
	}
	
	
	void TizenFrame::SetIcon () {}
	void TizenFrame::SetTitle () {}
	
	
}
