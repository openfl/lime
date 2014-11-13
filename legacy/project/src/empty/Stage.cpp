#include <Display.h>
#include <Graphics.h>
#include <Surface.h>

//using namespace nme;


namespace nme
{


void CreateMainFrame(nme::FrameCreationCallback inOnFrame,int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle, nme::Surface *inIcon )
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
