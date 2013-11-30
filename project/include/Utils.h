#ifndef LIME_UTILS_H
#define LIME_UTILS_H

#include <hx/CFFI.h>
#include <string>
#include <vector>
#include <QuickVec.h>


#ifdef BLACKBERRY
#include <bps/event.h>
#endif

#ifdef ANDROID
#include <android/log.h>

#ifdef VERBOSE
#define VLOG(args...) __android_log_print(ANDROID_LOG_INFO, "lime",args)
#else
#define VLOG(args...)
#endif

#define ELOG(args...) __android_log_print(ANDROID_LOG_ERROR, "lime",args)

#elif defined(TIZEN)

extern "C" __attribute__ ((visibility("default"))) void AppLogInternal(const char* pFunction, int lineNumber, const char* pFormat, ...);
extern "C" __attribute__ ((visibility("default"))) void AppLogDebugInternal(const char* pFunction, int lineNumber, const char* pFormat, ...);

#ifdef VERBOSE
#define VLOG(...) AppLogInternal(__PRETTY_FUNCTION__, __LINE__, __VA_ARGS__)
#else
#define VLOG(...)
#endif

#define ELOG(...) AppLogDebugInternal(__PRETTY_FUNCTION__, __LINE__, __VA_ARGS__)

#else

#include <stdio.h>

#ifdef _MSC_VER
#include <stdio.h>
#include <stdarg.h>

inline void DoLog(const char *inFormat,...)
{
  va_list args;
  va_start(args, inFormat);
  vprintf (inFormat, args);
  printf("\n");
  va_end (args);
}
inline void DontLog(const char *inFormat,...) { }

#ifdef VERBOSE

#define VLOG DoLog
#else
#define VLOG DontLog
#endif
#define ELOG DoLog

#else

#ifndef VERBOSE
#define VLOG(args...) { printf(args); printf("\n"); }
#else
#define VLOG(args...)
#endif

#define ELOG(args...) { printf(args); printf("\n"); }

#endif

#endif



namespace lime
{

extern std::string gAssetBase;
extern std::string gCompany;
extern std::string gPackage;
extern std::string gVersion;
extern std::string gFile;

const std::string GetUniqueDeviceIdentifier();
const std::string &GetResourcePath();


enum SpecialDir
{
   DIR_APP,
   DIR_STORAGE,
   DIR_DESKTOP,
   DIR_DOCS,
   DIR_USER,

   DIR_SIZE
};
void GetSpecialDir(SpecialDir inDir,std::string &outDir);

#ifdef ANDROID
class WString
{
public:
   WString() : mLength(0), mString(0) { }
   WString(const WString &inRHS);
   WString(const wchar_t *inStr);
   WString(const wchar_t *inStr,int inLen);
   ~WString();

   inline int length() const { return mLength; }
   inline int size() const { return mLength; }
   
   int compare ( const WString& str ) const { return wcscmp (mString, str.mString); };

   WString &operator=(const WString &inRHS);
   inline wchar_t &operator[](int inIndex) { return mString[inIndex]; }
   inline const wchar_t &operator[](int inIndex) const { return mString[inIndex]; }
   const wchar_t *c_str() const { return mString ? mString : L""; }

   WString &operator +=(const WString &inRHS);
   WString operator +(const WString &inRHS) const;
   bool operator<(const WString &inRHS) const;
   bool operator>(const WString &inRHS) const;
   bool operator==(const WString &inRHS) const;
   bool operator!=(const WString &inRHS) const;

   WString substr(int inPos,int inLen) const;


private:
   wchar_t *mString;
   int     mLength;
};
#else
typedef std::wstring WString;
#endif

WString IntToWide(int value);
WString ColorToWide(int value);

void SetIcon( const char *path );

int GetDeviceOrientation();
int GetNormalOrientation();
double CapabilitiesGetPixelAspectRatio ();
double CapabilitiesGetScreenDPI ();
double CapabilitiesGetScreenResolutionX ();
double CapabilitiesGetScreenResolutionY ();
QuickVec<int>* CapabilitiesGetScreenResolutions ();

std::string CapabilitiesGetLanguage();

std::string FileDialogOpen( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes );
std::string FileDialogSave( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes );
std::string FileDialogFolder( const std::string &title, const std::string &text );

bool LaunchBrowser(const char *inUtf8URL);

void ExternalInterface_AddCallback (const char *functionName, AutoGCRoot *inCallback);
void ExternalInterface_Call (const char *functionName, const char **params, int numParams);
void ExternalInterface_RegisterCallbacks ();

void HapticVibrate(int period, int duration);

bool SetUserPreference(const char *inId, const char *inPreference);
std::string GetUserPreference(const char *inId);
bool ClearUserPreference(const char *inId);

#ifdef HX_WINDOWS
typedef wchar_t OSChar;
#define val_os_string val_wstring
#define OpenRead(x) _wfopen(x,L"rb")
#define OpenOverwrite(x) _wfopen(x,L"wb") // [ddc]

#else
typedef char OSChar;
#define val_os_string val_string

#if defined(IPHONE)
FILE *OpenRead(const char *inName);
FILE *OpenOverwrite(const char *inName); // [ddc]
extern int gFixedOrientation;

#elif defined(HX_MACOS)
} // close namespace lime
extern "C" FILE *OpenRead(const char *inName);
extern "C" bool GetBundleFilename(const char *inName, char *outBuffer,int inBufSize);
extern "C" FILE *OpenOverwrite(const char *inName);
namespace lime {
#else
#ifdef TIZEN
extern int gFixedOrientation;
#endif
#define OpenRead(x) fopen(x,"rb")
#define OpenOverwrite(x) fopen(x,"wb") // [ddc]
#endif

#endif

std::string WideToUTF8(const WString &inWideString);

double GetTimeStamp();

struct VolumeInfo
{
   std::string path;
   std::string name;
   bool        writable;
   bool        removable;
   std::string fileSystemType;
   std::string drive;
};

void GetVolumeInfo( std::vector<VolumeInfo> &outInfo );


}


#endif
