#ifndef NME_THREAD_H
#define NME_THREAD_H

#ifndef HX_WINDOWS
#include <pthread.h>
#else
#include <windows.h>
#undef min
#undef max
#endif

namespace nme
{
#ifndef HX_WINDOWS
typedef pthread_t ThreadId;
#else
typedef DWORD ThreadId;
#endif

ThreadId GetThreadId();
bool IsMainThread();
void SetMainThread();
}

#endif

