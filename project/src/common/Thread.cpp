#include <NMEThread.h>

namespace nme
{

ThreadId GetThreadId()
{
   #ifdef HX_WINDOWS
   return GetCurrentThreadId();
   #else
   return pthread_self();
   #endif
}



static ThreadId sMainThread = 0;

void SetMainThread()
{
   sMainThread = GetThreadId();
}

bool IsMainThread()
{
   return sMainThread==GetThreadId();
}


} // end namespace nmE
