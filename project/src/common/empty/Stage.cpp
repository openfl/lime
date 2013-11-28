#include <Display.h>
#include <Graphics.h>
#include "renderer/common/Surface.h"

//using namespace lime;


namespace lime
{


void CreateMainFrame(lime::FrameCreationCallback inOnFrame,int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle, lime::Surface *inIcon )
{
}


bool sgDead = false;

void SetIcon( const char *path ) { }

QuickVec<int> *CapabilitiesGetScreenResolutions()
{
   // TODO
   QuickVec<int> *out = new QuickVec<int>();
   out->push_back(1024);
   out->push_back(768);
   return out;
}

double CapabilitiesGetScreenResolutionX() { return 1024; }
double CapabilitiesGetScreenResolutionY() { return 768; }
void PauseAnimation() {}
void ResumeAnimation() {}

void StopAnimation()
{
   sgDead = true;
}

void StartAnimation()
{
}


}
