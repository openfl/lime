#include <jni.h>
#include <android/log.h>
#include <stdio.h>
#include <string>
#include <vector>
#include "AndroidCommon.h"

#undef LOGV
#undef LOGE

#define LOGV(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::System", msg, ## args)

#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::System", msg, ## args)

namespace nme {


	
	double CapabilitiesGetPixelAspectRatio () {
		
		JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetPixelAspectRatio", "()D");
		if (mid == 0)
			return 1;
		
		return env->CallStaticDoubleMethod (cls, mid);
		
	}
	
	
	double CapabilitiesGetScreenDPI () {
		
		JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetScreenDPI", "()D");
		if (mid == 0)
			return 1;
		
		return env->CallStaticDoubleMethod (cls, mid);
		
	}
	
	
	double CapabilitiesGetScreenResolutionX () {
		
		JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetScreenResolutionX", "()D");
		if (mid == 0)
			return 1;
		
		return env->CallStaticDoubleMethod (cls, mid);
		
	}
	
	
	double CapabilitiesGetScreenResolutionY () {
		
		JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetScreenResolutionY", "()D");
		if (mid == 0)
			return 1;
		
		return env->CallStaticDoubleMethod (cls, mid);
		
	}
	
	std::string CapabilitiesGetLanguage() {
		JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "CapabilitiesGetLanguage", "()Ljava/lang/String;");
		if(mid == 0)
			return std::string("");
		jstring jLang = (jstring) env->CallStaticObjectMethod(cls, mid);
		const char *nativeLang = env->GetStringUTFChars(jLang, 0);
		std::string result(nativeLang);
		env->ReleaseStringUTFChars(jLang, nativeLang);
		return result;
	}
	
	void HapticVibrate (int period, int duration)
	{
		JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "vibrate", "(II)V");
		if (mid > 0)
			env->CallStaticVoidMethod(cls, mid, period, duration);	
	}
	

	bool LaunchBrowser(const char *inUtf8URL)
	{
	   JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "launchBrowser", "(Ljava/lang/String;)V");
		if (mid == 0)
			return false;

		jstring str = env->NewStringUTF( inUtf8URL );

		env->CallStaticVoidMethod(cls, mid, str );
		return true;

	}
	
	
	std::string GetUserPreference(const char *inId)
	{
	   JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "getUserPreference", "(Ljava/lang/String;)Ljava/lang/String;");
		if (mid == 0)
		{
			return std::string("");
		}
		
		jstring jInId = env->NewStringUTF(inId);
		jstring jPref = (jstring) env->CallStaticObjectMethod(cls, mid, jInId);
		env->DeleteLocalRef(jInId);
		const char *nativePref = env->GetStringUTFChars(jPref, 0);
		std::string result(nativePref);
		env->ReleaseStringUTFChars(jPref, nativePref);
		return result;	
	}
	
	bool SetUserPreference(const char *inId, const char *inPreference)
	{
	   JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "setUserPreference", "(Ljava/lang/String;Ljava/lang/String;)V");
		if (mid == 0)
			return false;
	
		jstring jInId = env->NewStringUTF( inId );
		jstring jPref = env->NewStringUTF ( inPreference );
		env->CallStaticVoidMethod(cls, mid, jInId, jPref );
		env->DeleteLocalRef(jInId);
		env->DeleteLocalRef(jPref);
		return true;
	}
	
	
	bool ClearUserPreference(const char *inId)
	{
	   JNIEnv *env = GetEnv();
		jclass cls = FindClass("org/haxe/nme/GameActivity");
		jmethodID mid = env->GetStaticMethodID(cls, "clearUserPreference", "(Ljava/lang/String;)V");
		if (mid == 0)
			return false;
		
		jstring jInId = env->NewStringUTF( inId );
		env->CallStaticVoidMethod(cls, mid, jInId );
		return true;
	}


	std::string FileDialogFolder( const std::string &title, const std::string &text ) { return ""; }
	std::string FileDialogOpen( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { return ""; }
	std::string FileDialogSave( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { return ""; }

}
