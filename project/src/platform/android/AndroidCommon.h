#ifndef _AndroidCommon_h
#define _AndroidCommon_h

#include <jni.h>
#include <pthread.h>
#include <android/log.h>
#include <hx/CFFI.h>


#ifdef __GNUC__
  #define JAVA_EXPORT __attribute__ ((visibility("default"))) JNIEXPORT
#else
  #define JAVA_EXPORT JNIEXPORT
#endif



struct AutoHaxe
{
   int base;
   const char *message;
   AutoHaxe(const char *inMessage)
   {  
      base = 0;
      message = inMessage;
      gc_set_top_of_stack(&base,true);
      //__android_log_print(ANDROID_LOG_VERBOSE, "NME", "Enter %s %p", message, pthread_self());
   }
   ~AutoHaxe()
   {
      //__android_log_print(ANDROID_LOG_VERBOSE, "NME", "Leave %s %p", message, pthread_self());
      gc_set_top_of_stack(0,true);
   }
};

JNIEnv *GetEnv();
jclass FindClass(const char *className);

#endif