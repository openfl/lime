#ifndef LIME_THREAD_H
#define LIME_THREAD_H


    #ifndef HX_WINDOWS
        #ifndef EPPC
            #include <pthread.h>
        #endif
    #else
        #include <windows.h>
        #undef min
        #undef max
    #endif

namespace lime {


    #ifndef HX_WINDOWS
        #ifdef EPPC
            typedef int ThreadId;
        #else
            typedef pthread_t ThreadId;
        #endif
    #else
        typedef DWORD ThreadId;
    #endif

    ThreadId    GetThreadId();
    bool        IsMainThread();
    void        SetMainThread();


} //namespace lime


#endif //LIME_THREAD_H
