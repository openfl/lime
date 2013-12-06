#include <hx/CFFI.h>
#include <Display.h>
#include "renderer/common/Surface.h"
#include "renderer/common/HardwareSurface.h"
#include "renderer/common/HardwareContext.h"
#include <KeyCodes.h>
#include <Utils.h>
#include <jni.h>
#include <ByteArray.h>
#include <Sound.h>

#include <android/log.h>
#include "AndroidCommon.h"

#include <assert.h>
#include <sys/types.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>

JavaVM *gJVM=0;

namespace lime
{

static class AndroidStage *sStage = 0;
static class AndroidFrame *sFrame = 0;
static FrameCreationCallback sOnFrame = 0;
static bool sCloseActivity = false;

static int sgLimeResult = 0;

enum { NO_TOUCH = -1 };

int GetResult()
{
   if (sCloseActivity)
   {
      sCloseActivity = false;
      return -1;
   }
   int r = sgLimeResult;
   sgLimeResult = 0;
   return r;
}

class AndroidStage : public Stage
{
    
public:
   AndroidStage(int inWidth,int inHeight,int inFlags) : Stage(true)
   {
      mHardwareContext = HardwareContext::CreateOpenGL(0, 0, inFlags & (wfAllowShaders|wfRequireShaders));
      mHardwareContext->IncRef();
      mHardwareContext->SetWindowSize(inWidth,inHeight);
      mHardwareSurface = new HardwareSurface(mHardwareContext);
      mHardwareSurface->IncRef();
      mMultiTouch = true;
      mSingleTouchID = NO_TOUCH;
      mDX = 0;
      mDY = 0;

      // Click detection
      mDownX = 0;
      mDownY = 0;

      normalOrientation = 0;
       
   }
   ~AndroidStage()
   {
      mHardwareSurface->DecRef();
      mHardwareContext->DecRef();
   }

   void Flip() { }
   void GetMouse()
   {
   }
   Surface *GetPrimarySurface() { return mHardwareSurface; }
   bool isOpenGL() const { return true; }
   virtual void SetCursor(Cursor inCursor) { }

	void OnPoll()
   {
      Event evt(etPoll);
      HandleEvent(evt);
   }

   void onActivityEvent(int inVal)
   {
      __android_log_print(ANDROID_LOG_INFO, "lime", "Activity action %d", inVal);
      if (inVal==1 || inVal==2)
      {
         if (inVal == 1)
         {
            Sound::Resume();
         }
         Event evt( inVal==1 ? etActivate : etDeactivate );
         HandleEvent(evt);
         if (inVal != 1)
         {
            Sound::Suspend();
         }
      }
   }
 

   void OnRender()
   {
      Event evt(etRedraw);
      HandleEvent(evt);
   }
   void Resize(int inWidth,int inHeight)
   {
      ResetHardwareContext();
      Event contextLost(etRenderContextLost);
      HandleEvent(contextLost);
      mHardwareContext->SetWindowSize(inWidth,inHeight);
      Event contextRestored(etRenderContextRestored);
      HandleEvent(contextRestored);
      Event evt(etResize, inWidth, inHeight);
      HandleEvent(evt);
   }

   void OnKey(int inCode, bool inDown)
   {
      //__android_log_print(ANDROID_LOG_INFO, "lime", "OnKey %d %d", inCode, inDown);
      Event key( inDown ? etKeyDown : etKeyUp );
      key.code = inCode;
      key.value = inCode;
      HandleEvent(key);
   }

   void OnJoy(int inDeviceId, int inCode, bool inDown)
   {
      //__android_log_print(ANDROID_LOG_INFO, "lime", "OnJoy %d %d %d", inDeviceId, inCode, inDown);
      Event joystick( inDown ? etJoyButtonDown : etJoyButtonUp );
      joystick.id = inDeviceId;
      joystick.code = inCode;
      HandleEvent(joystick);
   }
   
   void OnJoyMotion(int inDeviceId, int inAxis, float inValue)
   {
      Event joystick(etJoyAxisMove);
      joystick.id = inDeviceId;
      joystick.code = inAxis;
      joystick.value = inValue;
      HandleEvent(joystick);
   }
   
   void OnTrackball(double inX, double inY)
   {
      // __android_log_print(ANDROID_LOG_INFO, "lime", "Trackball %f %f", inX, inY);
   }

   void OnTouch(int inType,double inX, double inY, int inID, float sizeX, float sizeY)
   {
         if (mSingleTouchID==NO_TOUCH || inID==mSingleTouchID || mMultiTouch)
         {
            EventType type = (EventType)inType;
            if (!mMultiTouch)
            {
               switch(inType)
               {
                  case  etTouchBegin: type = etMouseDown; break;
                  case  etTouchEnd:   type = etMouseUp; break;
                  case  etTouchMove : type = etMouseMove; break;
                  case  etTouchTap:   return; break;
               }
            }

               Event mouse(type, inX, inY);
               if (mSingleTouchID==NO_TOUCH || inID==mSingleTouchID || !mMultiTouch)
                  mouse.flags |= efPrimaryTouch;

               if (inType==etTouchBegin)
               {
                  if (mSingleTouchID==NO_TOUCH)
                     mSingleTouchID = inID;
                  mouse.flags |= efLeftDown;
                  mDownX = inX;
                  mDownY = inY;
               }
               else if (inType==etTouchEnd)
               {
                  if (mSingleTouchID==inID)
                     mSingleTouchID = NO_TOUCH;
               }
               else if (inType==etTouchMove)
               {
                  mouse.flags |= efLeftDown;
               }
               mouse.value = inID;
               
               mouse.sx = sizeX;
               mouse.sy = sizeY;

               //if (inType==etTouchBegin)
                  //ELOG("DOWN %d %f,%f (%s) %f,%f", inID, inX, inY, (mouse.flags & efPrimaryTouch) ? "P":"S", sizeX, sizeY );

               //if (inType==etTouchEnd)
                  //ELOG("UP %d %f,%f (%s) %f,%f", inID, inX, inY, (mouse.flags & efPrimaryTouch) ? "P":"S", sizeX, sizeY );

               HandleEvent(mouse);
         }
   }

   void OnDeviceOrientationUpdate(int orientation)
   {
      currentDeviceOrientation = orientation;
      //__android_log_print(ANDROID_LOG_INFO, "lime", "Device Orientation %d", currentDeviceOrientation);
   }

   void OnNormalOrientationFound(int orientation)
   {
      normalOrientation = orientation;
      //__android_log_print(ANDROID_LOG_INFO, "lime", "Normal Orientation %d", normalOrientation);
   }

   void OnOrientationUpdate(double inX, double inY, double inZ)
   {
      mOrientationX = inX;
      mOrientationY = inY;
      mOrientationZ = inZ;
      //__android_log_print(ANDROID_LOG_INFO, "lime", "Orientation %f %f %f", inX, inY, inZ);
   }
   
   void OnAccelerate(double inX, double inY, double inZ)
   {
      if (normalOrientation == 0 || normalOrientation == 1) { // UNKNOWN || PORTRAIT
         mAccX = -inX / 9.80665;
         mAccY = -inY / 9.80665;
         mAccZ = -inZ / 9.80665;
      } else { // 4 || LANDSCAPE_LEFT
         mAccX = inY / 9.80665;
         mAccY = -inX / 9.80665;
         mAccZ = -inZ / 9.80665;
      }
      //__android_log_print(ANDROID_LOG_INFO, "lime", "Accelerometer %f %f %f", inX, inY, inZ);
   }

   void EnablePopupKeyboard(bool inEnable)
   {
      JNIEnv *env = GetEnv();
      jclass cls = FindClass("org/haxe/lime/GameActivity");
      jmethodID mid = env->GetStaticMethodID(cls, "showKeyboard", "(Z)V");
      if (mid == 0)
        return;

      env->CallStaticVoidMethod(cls, mid, (jboolean) inEnable);
   }

   bool getMultitouchSupported() { return true; }
   void setMultitouchActive(bool inActive) { mMultiTouch = inActive; }
   bool getMultitouchActive() {  return mMultiTouch; }


   bool mMultiTouch;
   int  mSingleTouchID;
  
   double mDX;
   double mDY;
   
   int currentDeviceOrientation;
   int normalOrientation;
   double mOrientationX;
   double mOrientationY;
   double mOrientationZ;
      
   double mAccX;
   double mAccY;
   double mAccZ;
      
   double mDownX;
   double mDownY;

   HardwareContext *mHardwareContext;
   HardwareSurface *mHardwareSurface;
};



class AndroidFrame : public Frame
{
public:
   AndroidFrame(FrameCreationCallback inOnFrame, int inWidth,int inHeight,
       unsigned int inFlags, const char *inTitle, Surface *inIcon )
   {
      sOnFrame = inOnFrame;
      mFlags = inFlags;
      sFrame = this;
      //__android_log_print(ANDROID_LOG_INFO, "AndroidFrame", "Construct %p, sOnFrame=%p", sFrame,sOnFrame);
   }
   ~AndroidFrame()
   {
     if (sStage)
        sStage->DecRef();
     sStage = 0;
   }

   virtual void SetTitle() { }
   virtual void SetIcon() { }
   virtual Stage *GetStage() 
   {
      return sStage;
   }

   void onResize(int inWidth, int inHeight)
   {
      if (!sStage)
      {
         sStage = new AndroidStage(inWidth,inHeight,mFlags);
         //__android_log_print(ANDROID_LOG_INFO, "AndroidFrame::onResize",
            //"Create stage %p, sOnFrame=%p", sStage,sOnFrame);
         if (sOnFrame)
            sOnFrame(this);
      }
      else
      {
         //ResetHardwareContext();
         sStage->Resize(inWidth,inHeight);
      }
   }

   unsigned int mFlags;
};


void CreateMainFrame( FrameCreationCallback inOnFrame, int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle,  Surface *inIcon )
{
   __android_log_print(ANDROID_LOG_INFO, "CreateMainFrame!", "creating...");
   sOnFrame = inOnFrame;
   sFrame = new AndroidFrame(inOnFrame, inWidth, inHeight, inFlags,
                 inTitle, inIcon);
	//__android_log_print(ANDROID_LOG_INFO, "CreateMainFrame", "%dx%d  %p", inWidth,inHeight,sOnFrame);
}

void StartAnimation()
{
   sCloseActivity = false;
}

void PauseAnimation()
{
   sCloseActivity = true;
}

void ResumeAnimation()
{
   sCloseActivity = false;
}

void StopAnimation()
{
   sCloseActivity = true;
}

AAsset *AndroidGetAsset(const char *inResource)
{
   JNIEnv *env = GetEnv();
   jclass cls = FindClass("org/haxe/lime/GameActivity");
   jmethodID mid = env->GetStaticMethodID(cls, "getAssetManager", "()Landroid/content/res/AssetManager;");
   if (mid == 0)
      return 0;
   
   jobject assetManager = (jobject)env->CallStaticObjectMethod(cls, mid);
   assert(0 != assetManager);
   AAssetManager* mgr = AAssetManager_fromJava(env, assetManager);
   assert(0 != mgr);
   return AAssetManager_open(mgr, inResource, AASSET_MODE_UNKNOWN);
}

ByteArray AndroidGetAssetBytes(const char *inResource)
{
   AAsset *asset = AndroidGetAsset(inResource);
   
   if (asset)
   {
      long size = AAsset_getLength(asset);
      ByteArray result(size);
      AAsset_read(asset, result.Bytes(), size);
      AAsset_close(asset);
      return result;
   }
   
   return 0;
   
   /*JNIEnv *env = GetEnv();
   
   jclass cls = FindClass("org/haxe/lime/GameActivity");
   jmethodID mid = env->GetStaticMethodID(cls, "getResource", "(Ljava/lang/String;)[B");
   if (mid == 0)
      return 0;
   
   jstring str = env->NewStringUTF( inResource );
   jbyteArray bytes = (jbyteArray)env->CallStaticObjectMethod(cls, mid, str);
   env->DeleteLocalRef(str);
   if (bytes==0)
   {
      return 0;
   }
   
   jint len = env->GetArrayLength(bytes);
   ByteArray result(len);
   env->GetByteArrayRegion(bytes, (jint)0, (jint)len, (jbyte*)result.Bytes());
   return result;*/
}

FileInfo AndroidGetAssetFD(const char *inResource)
{
   FileInfo info;
   info.fd = 0;
   info.offset = 0;
   info.length = 0;
   
   AAsset *asset = AndroidGetAsset(inResource);
   
   if (asset)
   {
      info.fd = AAsset_openFileDescriptor(asset, &info.offset, &info.length);
      assert(0 <= fd);
      AAsset_close(asset);
   }
   
   return info;
}

void AndroidRequestRender()
{
    JNIEnv *env = GetEnv();
    jclass cls = FindClass("org/haxe/lime/MainView");
    jmethodID mid = env->GetStaticMethodID(cls, "renderNow", "()V");
    if (mid == 0)
        return;
    env->CallStaticVoidMethod(cls, mid);
}

int GetDeviceOrientation() {
	if (sStage) {
		return sStage->currentDeviceOrientation;
	}
	return 0;
}

int GetNormalOrientation() {
	if (sStage) {
		return sStage->normalOrientation;
	}
	return 0;
}

int GetOrientation(double& outX, double& outY, double& outZ) {
	if (sStage) {
		outX = sStage->mOrientationX;
		outY = sStage->mOrientationY;
		outZ = sStage->mOrientationZ;
		return true;
	}
	return false;
}

bool GetAcceleration(double& outX, double& outY, double& outZ) {
	if (sStage) {
		outX = sStage->mAccX;
		outY = sStage->mAccY;
		outZ = sStage->mAccZ;
		return true;
	}
	return false;
}

} // end namespace lime



extern "C"
{

#ifdef __GNUC__
  #define JAVA_EXPORT __attribute__ ((visibility("default"))) JNIEXPORT
#else
  #define JAVA_EXPORT JNIEXPORT
#endif

JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onResize(JNIEnv * env, jobject obj,  jint width, jint height)
{
   env->GetJavaVM(&gJVM);
   int top = 0;
   gc_set_top_of_stack(&top,true);
   __android_log_print(ANDROID_LOG_INFO, "Resize", "%p  %d,%d", lime::sFrame, width, height);
   if (lime::sFrame)
      lime::sFrame->onResize(width,height);
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}


JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onRender(JNIEnv * env, jobject obj)
{
   env->GetJavaVM(&gJVM);
   int top = 0;
   gc_set_top_of_stack(&top,true);
   //double t0 = lime::GetTimeStamp();
   //__android_log_print(ANDROID_LOG_INFO, "lime", "lime onRender: %p", lime::sStage );
   if (lime::sStage)
      lime::sStage->OnRender();
   //__android_log_print(ANDROID_LOG_INFO, "lime", "Haxe Time: %f", lime::GetTimeStamp()-t0);
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onNormalOrientationFound(JNIEnv * env, jobject obj, jint orientation)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (lime::sStage)
      lime::sStage->OnNormalOrientationFound(orientation);
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onDeviceOrientationUpdate(JNIEnv * env, jobject obj, jint orientation)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (lime::sStage)
      lime::sStage->OnDeviceOrientationUpdate(orientation);
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onOrientationUpdate(JNIEnv * env, jobject obj, jfloat x, jfloat y, jfloat z)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (lime::sStage)
      lime::sStage->OnOrientationUpdate(x,y,z);
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onAccelerate(JNIEnv * env, jobject obj, jfloat x, jfloat y, jfloat z)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (lime::sStage)
      lime::sStage->OnAccelerate(x,y,z);
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onTouch(JNIEnv * env, jobject obj, jint type, jfloat x, jfloat y, jint id, jfloat sizeX, jfloat sizeY)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (lime::sStage)
      lime::sStage->OnTouch(type,x,y,id,sizeX,sizeY);
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onTrackball(JNIEnv * env, jobject obj, jfloat dx, jfloat dy)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (lime::sStage)
      lime::sStage->OnTrackball(dx,dy);
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onKeyChange(JNIEnv * env, jobject obj, int code, bool down)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (lime::sStage)
      lime::sStage->OnKey(code,down);
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onJoyChange(JNIEnv * env, jobject obj, int deviceId, int code, bool down)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (lime::sStage)
      lime::sStage->OnJoy(deviceId,code,down);
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onJoyMotion(JNIEnv * env, jobject obj, int deviceId, int axis, float value)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (lime::sStage)
      lime::sStage->OnJoyMotion(deviceId,axis,value);
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}

JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onPoll(JNIEnv * env, jobject obj)
{
   env->GetJavaVM(&gJVM);
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (lime::sStage)
      lime::sStage->OnPoll();
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}

JAVA_EXPORT double JNICALL Java_org_haxe_lime_Lime_getNextWake(JNIEnv * env, jobject obj)
{
   env->GetJavaVM(&gJVM);
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (lime::sStage)
	{
      double delta = lime::sStage->GetNextWake()-lime::GetTimeStamp();
      gc_set_top_of_stack(0,true);
      return delta;
	}
   gc_set_top_of_stack(0,true);
   return 3600*100000;
}


JAVA_EXPORT int JNICALL Java_org_haxe_lime_Lime_onActivity(JNIEnv * env, jobject obj, int inVal)
{
   int top = 0;
   gc_set_top_of_stack(&top,true);
   if (lime::sStage)
      lime::sStage->onActivityEvent(inVal);
   gc_set_top_of_stack(0,true);
   return lime::GetResult();
}


} // end extern C





