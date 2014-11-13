#include "AndroidCommon.h"
#include <android/log.h>
#include <string>
#include <map>
#include <stdint.h>
#include <pthread.h>

#undef LOGE
#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::System", msg, ## args)

JavaVM *_vm;
std::map<std::string, jclass> jClassCache;
static pthread_key_t s_thread_key;

static void ThreadDataDestroy (void *env)
{
  _vm->DetachCurrentThread();
}

JNIEnv *GetEnv()
{
    JNIEnv *env;
    int getEnvStat = _vm->GetEnv((void**)&env, JNI_VERSION_1_4);
    if (getEnvStat == JNI_EDETACHED) {
        //LOGE("GetEnv: not attached");
        if (_vm->AttachCurrentThread(&env, 0) != 0) {
            LOGE("Failed to attach");
        }
        pthread_setspecific (s_thread_key, &env);
    }
    return env;
}

jclass FindClass(const char *className,bool inQuiet)
{
    std::string cppClassName(className);
    jclass ret;
    if(jClassCache[cppClassName]!=NULL)
    {
        ret = jClassCache[cppClassName];
    }
    else
    {
        JNIEnv *env = GetEnv();
        jclass tmp = env->FindClass(className);
        if (!tmp)
        {
           if (inQuiet)
           {
              jthrowable exc = env->ExceptionOccurred();
              if (exc)
                 env->ExceptionClear();
           }
           else
              CheckException(env);
           return 0;
        }
        ret = (jclass)env->NewGlobalRef(tmp);
        jClassCache[cppClassName] = ret;
        env->DeleteLocalRef(tmp);
    }
    return ret;
}

std::string JStringToStdString(JNIEnv *env, jstring inString, bool inReleaseLocalRef)
{
   const char *c_ptr = env->GetStringUTFChars(inString, 0);
   std::string result(c_ptr);
   env->ReleaseStringUTFChars(inString, c_ptr);
   if (inReleaseLocalRef)
      env->DeleteLocalRef(inString);
   return result;
}


JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved)
{
    _vm = vm;
    jClassCache = std::map<std::string, jclass>();
    pthread_key_create(&s_thread_key, ThreadDataDestroy);
    return  JNI_VERSION_1_4;                    // the required JNI version
    
}



