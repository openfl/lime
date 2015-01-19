#ifndef __MINGW32__

#include <windows.h>
#include <process.h>
#include <comdef.h>
#include <comip.h>
#include <comdefsp.h>
#include <dshow.h>
#include <string>
#include <vector>

#include <Camera.h>

#pragma comment(lib,"Strmiids.lib")


EXTERN_C const IID IID_ISampleGrabberCB;

MIDL_INTERFACE("0579154A-2B53-4994-B0D0-E773148EFF85")
ISampleGrabberCB : public IUnknown
{
public:
    virtual HRESULT STDMETHODCALLTYPE SampleCB( 
         double SampleTime,
         IMediaSample *pSample) = 0;
     virtual HRESULT STDMETHODCALLTYPE BufferCB( 
         double SampleTime,
         BYTE *pBuffer,
         long BufferLen) = 0;
};


EXTERN_C const CLSID CLSID_SampleGrabber;
EXTERN_C const IID IID_ISampleGrabber;

MIDL_INTERFACE("6B652FFF-11FE-4fce-92AD-0266B5D7C78F")
ISampleGrabber : public IUnknown
{
    public:
     virtual HRESULT STDMETHODCALLTYPE SetOneShot( 
         BOOL OneShot) = 0;
     virtual HRESULT STDMETHODCALLTYPE SetMediaType( 
         const AM_MEDIA_TYPE *pType) = 0;
     virtual HRESULT STDMETHODCALLTYPE GetConnectedMediaType( 
         AM_MEDIA_TYPE *pType) = 0;
     virtual HRESULT STDMETHODCALLTYPE SetBufferSamples( 
         BOOL BufferThem) = 0;
     virtual HRESULT STDMETHODCALLTYPE GetCurrentBuffer( 
         /* [out][in] */ long *pBufferSize,
         /* [out] */ long *pBuffer) = 0;
     virtual HRESULT STDMETHODCALLTYPE GetCurrentSample( 
         /* [retval][out] */ IMediaSample **ppSample) = 0;
     virtual HRESULT STDMETHODCALLTYPE SetCallback( 
         ISampleGrabberCB *pCallback,
         long WhichMethodToCallback) = 0;
};


_COM_SMARTPTR_TYPEDEF(IBaseFilter, __uuidof(IBaseFilter));
_COM_SMARTPTR_TYPEDEF(ICreateDevEnum, __uuidof(ICreateDevEnum));
_COM_SMARTPTR_TYPEDEF(IEnumMoniker, __uuidof(IEnumMoniker));
_COM_SMARTPTR_TYPEDEF(ISampleGrabber, __uuidof(ISampleGrabber));
_COM_SMARTPTR_TYPEDEF(ISampleGrabberCB, __uuidof(ISampleGrabberCB));
_COM_SMARTPTR_TYPEDEF(IFilterGraph2, __uuidof(IFilterGraph2));
_COM_SMARTPTR_TYPEDEF(ICaptureGraphBuilder2, __uuidof(ICaptureGraphBuilder2));
_COM_SMARTPTR_TYPEDEF(IMediaControl, __uuidof(IMediaControl));
_COM_SMARTPTR_TYPEDEF(IMediaEventEx, __uuidof(IMediaEventEx));


namespace nme
{


class CaptureDevice : public Camera
{
public:
   CaptureDevice(const char *inName)
   {
      mKeepGoing = true;
      InitializeCriticalSection(&mCritSec);
      //printf("Create CaptureDevice %s...\n", inName);
      _beginthread( startThread, 0, this);
   }


   static void __cdecl startThread(void *inThis)
   {
      //printf("Run....\n");
      ((CaptureDevice *)inThis)->runThread();
   }

   ~CaptureDevice()
   {
      mKeepGoing = false;
      for(int i=0;i<20;i++)
      {
         if (status==camError || status==camStopped)
            break;
         Sleep(10);
      }
      DeleteCriticalSection(&mCritSec);
   }
   void lock() { EnterCriticalSection(&mCritSec); }
   void unlock() { LeaveCriticalSection(&mCritSec); }

   void kill()
   {
      mKeepGoing = false;
   }





   bool FindCaptureDeviceMoniker(IMonikerPtr &outMoniker, IBaseFilterPtr &outSrcFilter)
   {
       HRESULT hr;
       ULONG cFetched;

       nAnalogCount = 0;
       nVSourceCount = 0;
       bDevCheck = false;

       // Create the system device enumerator
       ICreateDevEnumPtr pDevEnum = NULL;
       hr = CoCreateInstance (CLSID_SystemDeviceEnum, NULL, CLSCTX_INPROC,
                              IID_ICreateDevEnum, (void ** ) &pDevEnum);
       if (FAILED(hr))
          return setError("Couldn't create system enumerator");

       // Create an enumerator for the video capture devices
       IEnumMonikerPtr pClassEnum = NULL;
       hr = pDevEnum->CreateClassEnumerator (CLSID_VideoInputDeviceCategory, &pClassEnum, 0);
       if (FAILED(hr))
          return setError("Couldn't create class enumerator");

       // If there are no enumerators for the requested type, then 
       // CreateClassEnumerator will succeed, but pClassEnum will be NULL.
       if (pClassEnum == NULL)
          return setError("No devices detected");

       // Use the first video capture device on the device list.
       // Note that if the Next() call succeeds but there are no monikers,
       // it will return S_FALSE (which is not a failure).  Therefore, we
       // check that the return code is S_OK instead of using SUCCEEDED() macro.

      /// For finding Digital Capture Devices ...

      BOOL         Found = false;
      IPin        *pP = 0;
      IEnumPins   *pins=0;
      ULONG        n;
      PIN_INFO     pinInfo;
      Found = FALSE;
      IKsPropertySet *pKs=0;
      GUID guid;
      GUID logitech = {0x1B6C4281,0x0353,0x11D1,{0x90,0x5F,0x00,0x00,0xC0,0xCC,0x16,0xB0}};
      DWORD dw;
      BOOL fMatch = FALSE;
      IMoniker *pMoniker = NULL;
      IBaseFilter *pSrc;

      //if(S_OK == (pClassEnum->Next (1, &pMoniker, &cFetched)))
      while (S_OK == (pClassEnum->Next (1, &outMoniker, &cFetched)))
      {
         pMoniker = outMoniker;

         hr = pMoniker->BindToObject(0,0,IID_IBaseFilter, (void**)&pSrc);
         if (FAILED(hr))
            return setError("Couldn't bind moniker to filter object");
         else
            outSrcFilter = pSrc;

               if(SUCCEEDED(pSrc->EnumPins(&pins)))
               {
                while(!Found && (S_OK == pins->Next(1, &pP, &n)))
                  {
                     //printf("Found pin\n");
                     if(S_OK == pP->QueryPinInfo(&pinInfo))
                     {
                        if(pinInfo.dir == PINDIR_INPUT)
                        {
                           // is this pin an ANALOGVIDEOIN input pin?
                           if(pP->QueryInterface(IID_IKsPropertySet,
                              (void **)&pKs) == S_OK)
                           {
                              if(pKs->Get(AMPROPSETID_Pin, AMPROPERTY_PIN_CATEGORY, NULL, 0,
                                 &guid, sizeof(GUID), &dw) == S_OK)
                              {
                                 #define CAT(x) \
                                 if(guid == x) \
                                 { \
                                    fMatch = true; \
                                 }
                                 CAT(PIN_CATEGORY_ANALOGVIDEOIN);
                                 CAT(logitech);

                                 if (!fMatch)
                                 {
                                   //printf("unknown Pin category\n");
                                   //printf("using anyhow!\n");
                                   fMatch = true;
                                 }
                              }
                              //else printf("Pin has unknown category\n");
                              pKs->Release();
                           }

                           if(fMatch)
                           {
                              Found = TRUE;
                              bDevCheck = Found;
                              nAnalogCount++;
                              //printf("Matched!\n");
                              break;
                           }

                        }
                        pinInfo.pFilter->Release();
                     }
                     pP->Release();
                  }
                  pins->Release();
               }

         if (Found)
            break;
         nVSourceCount++;
      } // End of While Loop

      if (!Found)
         return setError("Cound not find capture device");
      return Found;
   }


   bool AddCaptureMonikerToGraph(IFilterGraph2 *inGraph,
                                 ICaptureGraphBuilder2 *inCapture,
                                 IMoniker *pMoniker,
                                 IBaseFilter *inTarget)
   {
       HRESULT hr;
       IBaseFilter *pBaseFilter=0;

       // Get the display name of the moniker
       LPOLESTR strMonikerName=0;
       hr = pMoniker->GetDisplayName(NULL, NULL, &strMonikerName);
       if (FAILED(hr))
          return setError("Could not get device name");
       //printf("Capture from %S\n", strMonikerName);

       // Create a bind context needed for working with the moniker
       IBindCtx *pContext=0;
       hr = CreateBindCtx(0, &pContext);
       if (FAILED(hr))
          return setError("Could not create bind context");

       hr = inGraph->AddSourceFilterForMoniker(pMoniker, pContext, 
                                                strMonikerName, &pBaseFilter);
       if (FAILED(hr))
          return setError("AddSourceFilterForMoniker failed.");


       // Attach the filter graph to the capture graph
       hr = inCapture->SetFiltergraph(inGraph);
       if (FAILED(hr))
          return setError("Failed to set capture filter graph");

       // Render the preview pin on the video capture filter
       // Use this instead of m_pGraph->RenderFile
       hr = inCapture->RenderStream (&PIN_CATEGORY_PREVIEW, &MEDIATYPE_Video,
                                      pBaseFilter, NULL, inTarget );
        if (FAILED(hr))
           return setError("Couldn't render capture stream. Thw WebCam may already be in use");

       if (pContext) pContext->Release();
       if (pBaseFilter) pBaseFilter->Release();

       return true;
   }

   bool SetSampleGrabberMediaType(ISampleGrabber *inGrabber)
   {
        AM_MEDIA_TYPE mt;
        ZeroMemory(&mt, sizeof(AM_MEDIA_TYPE));
        mt.majortype = MEDIATYPE_Video;
        mt.subtype = MEDIASUBTYPE_RGB24;
        if (inGrabber->SetMediaType(&mt)!=S_OK)
           return setError("Could not set media type");

        inGrabber->SetOneShot(FALSE);
        inGrabber->SetBufferSamples(TRUE);
        return true;
   }

   bool GetSampleInfo(ISampleGrabber *inGrabber)
   {
        AM_MEDIA_TYPE mt;
        HRESULT hr = inGrabber->GetConnectedMediaType(&mt);
        if (FAILED(hr))
           return false;

        VIDEOINFOHEADER *pVih = (VIDEOINFOHEADER *)mt.pbFormat;
        int channels = pVih->bmiHeader.biBitCount / 8;
        width = pVih->bmiHeader.biWidth;
        height = pVih->bmiHeader.biHeight;
        mBytesPerRow = (width * 3 + 3) & ~7;

        CoTaskMemFree((PVOID)mt.pbFormat);

        if (channels!=3)
           return setError("Wrong channel count");

        //printf("Got sample info %dx%d\n", width, height );
        return true;
   }

   virtual bool updateBuffer( ) { return false; }

   void GrabImage(ISampleGrabber *inGrabber)
   {
      long size = 0;
      if (inGrabber->GetCurrentBuffer(&size, NULL)==S_OK)
      {
         FrameBuffer *frameBuffer = getWriteBuffer();

         frameBuffer->data.resize(size);
         frameBuffer->width = width;
         frameBuffer->height = height;
         frameBuffer->stride = mBytesPerRow;

         if (inGrabber->GetCurrentBuffer(&size, (long*)&frameBuffer->data[0])==S_OK)
         {
            frameBuffer->age = frameId++;
         }
      }
   }

   void runThread()
   {
      if(FAILED(CoInitialize(NULL)))
      {
         setError("CoInitialize Failed");
         return;
      }
      { // Block to hold references

      IFilterGraph2Ptr graph;
      if (CoCreateInstance(CLSID_FilterGraph, NULL, CLSCTX_INPROC,
                        IID_IFilterGraph2, (void **) &graph))
         setError("Could not build Graph");


      ICaptureGraphBuilder2Ptr capture;
      if (ok() && CoCreateInstance (CLSID_CaptureGraphBuilder2 , NULL, CLSCTX_INPROC,
                        IID_ICaptureGraphBuilder2, (void **) &capture)!=S_OK)
         setError("Could not create capture builder");

      IMediaControlPtr media_control;
      if (ok() && graph->QueryInterface(IID_IMediaControl,(LPVOID *) &media_control)!=S_OK)
         setError("No Media Control");

      IMediaEventExPtr media_event;
      if (ok() && graph->QueryInterface(IID_IMediaEvent,(LPVOID *) &media_event)!=S_OK)
         setError("No Media Event");

      IBaseFilterPtr sample_grabber;
      if (ok() && CoCreateInstance(CLSID_SampleGrabber, NULL, CLSCTX_INPROC_SERVER,
                                      IID_IBaseFilter, (void**) &sample_grabber)!=S_OK)
         setError("Could not create sample grabber");

      if (ok() && graph->AddFilter(sample_grabber, L"Sample Grabber")!=S_OK)
         setError("Could not add sample grabber");

      ISampleGrabberPtr grabber;
      if (ok() && sample_grabber->QueryInterface(IID_ISampleGrabber, (void **)&grabber)!=S_OK)
         setError("Could not find sample grabber interface");

      if (ok())
         SetSampleGrabberMediaType(grabber);


      IMonikerPtr moniker;
      IBaseFilterPtr src_filter;
      // Use the system device enumerator and class enumerator to find
      // a moniker that represents a video capture/preview device, 
      // such as a desktop USB video camera.
      if (ok())
         FindCaptureDeviceMoniker(moniker,src_filter);

      if( ok() && nAnalogCount == nVSourceCount )
         setError("Capture device is not a Webcam");

      if (ok())
         AddCaptureMonikerToGraph(graph,capture,moniker,sample_grabber);

      moniker = 0;


      if (FAILED(media_control->Run()))
         setError("Could not run graph.");


      if (ok())
      {
         bool info_init = false;
         while(mKeepGoing)
         {
            LONG evCode;
            LONG_PTR evParam1, evParam2;
            HRESULT hr = S_OK;


            while (SUCCEEDED(media_event->GetEvent(&evCode, &evParam1, &evParam2, 0)))
            {
               //printf("Got event %d\n",evCode);
               media_event->FreeEventParams(evCode, evParam1, evParam2);
            }

            if (!info_init)
            {
               info_init =  GetSampleInfo(grabber);
               if (info_init)
                  status = camRunning;
            }

            if (info_init)
               GrabImage(grabber);

            Sleep(10);
         }
      }

      if (media_control)
         media_control->Stop();

      } // Release references
      CoUninitialize();

      if (status!=camError)
         status = camStopped;
   }

   void copyFrame(ImageBuffer *outBuffer, FrameBuffer *inFrame)
   {
         //printf("Got framebuffer %d\n", frameBuffer->age);
         unsigned char *dest = outBuffer->Edit(0);
         //printf("Dest %p (%dx%d, %d)\n", dest, outBuffer->Width(), outBuffer->Height(), outBuffer->GetStride() );
         unsigned char *src = &inFrame->data[0];
         //printf("Src %p (%dx%d, %d)\n", src, inFrame->width, inFrame->height, inFrame->stride );
         for(int y=0;y<height;y++)
         {
            int destY = height-1-y;
            unsigned char *rgb =  src+inFrame->stride*y;
            unsigned char *out =  dest+destY*outBuffer->GetStride();
            for(int x=0;x<width;x++)
            {
               *out++ = rgb[0];
               *out++ = rgb[1];
               *out++ = rgb[2];
               *out++ = 0xff;
               rgb+=3;
            }
         }
         outBuffer->Commit();

   }

   bool mKeepGoing;

   const std::string &GetError() { return mError; }
   const std::string &GetName() { return mDeviceName; }

   std::string mError;
   std::string mDeviceName;

   bool bDevCheck;
   int  nAnalogCount;
   int nVSourceCount;
   int mBytesPerRow;

    CRITICAL_SECTION mCritSec;
};




Camera *CreateCamera(const char *inName)
{
   return new CaptureDevice(inName);
}

} // end namespace name


#else // __MINGW__


#include <Camera.h>
namespace nme
{

Camera *CreateCamera(const char *inName)
{
   return 0;
}

} // end namespace name

#endif
