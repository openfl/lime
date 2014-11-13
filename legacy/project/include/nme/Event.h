#ifndef NME_EVENT_H
#define NME_EVENT_H

namespace nme
{

enum EventType
{
   etUnknown,   // 0
   etKeyDown,   // 1
   etChar,      // 2
   etKeyUp,     // 3
   etMouseMove, // 4
   etMouseDown, // 5
   etMouseClick,// 6
   etMouseUp,   // 7
   etResize,    // 8
   etPoll,      // 9
   etQuit,      // 10
   etFocus,     // 11
   etShouldRotate, // 12

   // Internal for now...
   etDestroyHandler, // 13
   etRedraw,   // 14

   etTouchBegin, // 15
   etTouchMove,  // 16
   etTouchEnd,   // 17
   etTouchTap,   // 18

   etChange,   // 19
   etActivate,   // 20
   etDeactivate, // 21
   etGotInputFocus,   // 22
   etLostInputFocus, // 23
   
   etJoyAxisMove, // 24
   etJoyBallMove, // 25
   etJoyHatMove, // 26
   etJoyButtonDown, // 27
   etJoyButtonUp, // 28
   etJoyDeviceAdded, //29
   etJoyDeviceRemoved, //30
   
   etSysWM, // 31
   
   etRenderContextLost, // 32
   etRenderContextRestored, // 33
};

enum EventFlags
{
   efLeftDown  =  0x0001,
   efShiftDown =  0x0002,
   efCtrlDown  =  0x0004,
   efAltDown   =  0x0008,
   efCommandDown = 0x0010,
   efMiddleDown  = 0x0020,
   efRightDown  = 0x0040,

   efLocationRight  = 0x4000,
   efPrimaryTouch   = 0x8000,
   efNoNativeClick  = 0x10000,
};


enum EventResult
{
   erOk,
   erCancel,
   erSpecial,
};

struct Event
{
   Event(EventType inType=etUnknown,int inX=0,int inY=0,int inValue=0,int inID=0,int inFlags=0,float inScaleX=1,float inScaleY=1,int inDeltaX=0,int inDeltaY=0):
        type(inType), x(inX), y(inY), value(inValue), id(inID), flags(inFlags), result(erOk), scaleX(inScaleX), scaleY(inScaleY), deltaX(inDeltaX), deltaY(inDeltaY), pollTime(0)
   {
   }

   #ifdef NME_BUILDING_LIB
   EventType       type;
   #else
   int       type;
   #endif
   int       x,y;
   int       value;
   int       code;
   int       id;
   int       flags;
   #ifdef NME_BUILDING_LIB
   EventResult  result;
   #else
   int         result;
   #endif
   float       scaleX, scaleY;
   int         deltaX, deltaY;
   double      pollTime;
};

} // end namespace nme

#endif
