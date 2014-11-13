#ifndef STAGE_VIDEO_H
#define STAGE_VIDEO_H

#include <nme/NmeCffi.h>

namespace nme
{

   
enum { PAUSE_LEN = -3 };
enum
{
   PLAY_STATUS_COMPLETE = 0,
   PLAY_STATUS_SWITCH = 1,
   PLAY_STATUS_TRANSITION = 2,
   PLAY_STATUS_ERROR = 3,
   PLAY_STATUS_NOT_STARTED = 4,
   PLAY_STATUS_STARTED = 5,
   PLAY_STATUS_STOPPED = 6,
};

enum
{
   SEEK_FINISHED_OK = 0,
   SEEK_FINISHED_EARLY = 1,
   SEEK_FINISHED_ERROR = 2,
};


class StageVideo : public Object
{
protected:
   AutoGCRoot mOwner;

public:
   StageVideo();
   void setOwner(value inOwner);

   virtual void play(const char *inUrl, double inStart, double inLength) = 0;
   virtual void seek(double inTime) = 0;
   virtual void setPan(double x, double y) = 0;
   virtual void setZoom(double x, double y) = 0;
   virtual void setSoundTransform(double x, double y) = 0;
   virtual void setViewport(double x, double y, double width, double height) = 0;
   virtual double getTime() = 0;
   virtual double getBufferedPercent() = 0;
   virtual void pause() = 0;
   virtual void resume() = 0;
   virtual void togglePause() = 0;
   virtual void destroy() = 0;
};


}

#endif
