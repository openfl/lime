#include <jni.h>

#ifndef _AndroidCommon_h
#define _AndroidCommon_h

JNIEnv *GetEnv();
jclass FindClass(const char *className);
#endif
