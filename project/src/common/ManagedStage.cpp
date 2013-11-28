#include <Graphics.h>
#include <Display.h>
#include "renderer/common/HardwareSurface.h"
#include <KeyCodes.h>
#include <map>


namespace lime
{


// --- Stage ------------------------------------------------------------------------


//typedef std::vector<Stage *> StageList;
static Stage *sgStage = 0;

ManagedStage::ManagedStage(int inWidth,int inHeight,int inFlags)
{
   mHardwareContext = 0;
   mHardwareSurface = 0;
   mCursor = curPointer;
   mIsHardware = true;
   HintColourOrder(mIsHardware);
   mActiveWidth = inWidth;
   mActiveHeight = inHeight;
   SetNominalSize(inWidth,inHeight);

   sgStage = this;

   mHardwareContext = HardwareContext::CreateOpenGL(0, 0, inFlags & wfAllowShaders);
   mHardwareContext->IncRef();
   mHardwareSurface = new HardwareSurface(mHardwareContext);
   mHardwareSurface->IncRef();
}

ManagedStage::~ManagedStage()
{
   if (mHardwareContext)
      mHardwareContext->DecRef();
   if (mHardwareSurface)
      mHardwareSurface->DecRef();
}


void ManagedStage::SetCursor(Cursor inCursor)
{
  mCursor = inCursor;
}


void ManagedStage::SetActiveSize(int inW,int inH)
{
   mActiveWidth = inW;
   mActiveHeight = inH;
   mHardwareContext->SetWindowSize(inW,inH);

   Event event(etResize,inW,inH);
   Stage::HandleEvent(event);
}

void ManagedStage::PumpEvent(Event &inEvent)
{
   if (inEvent.type==etResize)
   {
      SetActiveSize(inEvent.x, inEvent.y);
   }
   else
      Stage::HandleEvent(inEvent);
}

Surface *ManagedStage::GetPrimarySurface()
{
  return mHardwareSurface;
}


} // end namespace lime

