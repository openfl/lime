#include <LimeThread.h>


namespace lime {

    static ThreadId sMainThread = 0;

    ThreadId GetThreadId() {

        #ifdef HX_WINDOWS
            return GetCurrentThreadId();
        #else
            return pthread_self();
        #endif

    }

    bool IsMainThread() {

       return sMainThread == GetThreadId();

    }
    
    void SetMainThread() {

       sMainThread = GetThreadId();

    }


} // end namespace lime
