#include <Display.h>
#include <Graphics.h>
#include "renderer/common/Surface.h"
#include "renderer/common/SimpleSurface.h"
#include "renderer/common/HardwareContext.h"

#include <wrl/client.h>
#include <d3d11_1.h>
#include <DirectXMath.h>
#include <memory>
#include <agile.h>
#include "BasicTimer.h"
#include "Direct3DBase.h"
#include "Shaders.h"

//using namespace lime;

using namespace Windows::ApplicationModel;
using namespace Windows::ApplicationModel::Core;
using namespace Windows::ApplicationModel::Activation;
using namespace Windows::UI::Core;
using namespace Windows::System;
using namespace Windows::Foundation;
using namespace Windows::Graphics::Display;
using namespace Microsoft::WRL;
using namespace concurrency;
using namespace DirectX;


namespace lime
{


static int sgDesktopWidth = 0;
static int sgDesktopHeight = 0;
static bool sgInitCalled = false;
static class WinRTFrame *sgWinRTFrame = 0;
static FrameCreationCallback sgOnFrame = 0;

enum { NO_TOUCH = -1 };

struct ModelViewProjectionConstantBuffer
{
   XMFLOAT4X4 model;
   XMFLOAT4X4 view;
   XMFLOAT4X4 projection;
};

struct VertexPositionTex
{
   XMFLOAT3 pos;
   XMFLOAT2 tex;
};

#if 0
class WinRTSurface : public Surface
{
public:
   int width,height;
   ComPtr<ID3D11Device1> device;


   WinRTSurface( ComPtr<ID3D11Device1> inDevice,ComPtr<ID3D11DeviceContext1> inContext,
                int inWidth, int inHeight)
      : device(inDevice), context(inContext)
   {
      width = inWidth;
      height = inHeight;


   }


   virtual int Width() const { return width; }
   virtual int Height() const { return height; }
   virtual PixelFormat Format()  const { return pfXRGB; }

   virtual const uint8 *GetBase() const { return 0; }
   virtual int GetStride() const { return 0; }

   virtual void Clear(uint32 inColour,const Rect *inRect=0) { }

   virtual RenderTarget BeginRender(const Rect &inRect,bool inForHitTest=false)
   {
      if (inForHitTest)
         return RenderTarget( Rect(0,0,width,height), pfXRGB, 0, 0);

      HRESULT hr=context->Map(surface.Get(), 0, D3D11_MAP_READ_WRITE, 0, &mapData);

      // ???
      if (hr!=S_OK)
         return RenderTarget();

      mapped = true;
      return RenderTarget( Rect(0,0,width,height), pfXRGB, (uint8*)mapData.pData, mapData.RowPitch);
   }

   virtual void EndRender()
   {
      if (mapped)
      {
         context->Unmap(surface.Get(),0);
         mapped = false;
      }
   }

   virtual void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
                       BlendMode inBlend, const BitmapCache *inMask,
                       uint32 inTint=0xffffff ) const
   {
   }

   virtual void StretchTo(const RenderTarget &outTarget,
                          const Rect &inSrcRect, const DRect &inDestRect) const
   {
   }

   virtual void BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect,
                            int inPosX, int inPosY,
                            int inSrcChannel, int inDestChannel ) const
   {
   }
};
#endif

class Quad
{
public:
   Quad( ComPtr<ID3D11Device1> inDevice, ComPtr<ID3D11DeviceContext1> inContext)
      : device(inDevice), context(inContext)
   {
      m_vertexShader = limeCreateVertexShader(inDevice,m_inputLayout,vsSimple);
      m_pixelShader = limeCreatePixelShader(inDevice,psSimple);

      CD3D11_BUFFER_DESC constantBufferDesc(sizeof(ModelViewProjectionConstantBuffer),
                                            D3D11_BIND_CONSTANT_BUFFER);
      DX::ThrowIfFailed(
         device->CreateBuffer(
            &constantBufferDesc,
            nullptr,
            &m_constantBuffer
            )
         );

      VertexPositionTex cubeVertices[] = 
      {
         {XMFLOAT3(-0.5f, -0.5f, -0.5f), XMFLOAT2(0.0f, 0.0f)},
         {XMFLOAT3(-0.5f, -0.5f,  0.5f), XMFLOAT2(0.0f, 0.0f)},
         {XMFLOAT3(-0.5f,  0.5f, -0.5f), XMFLOAT2(0.0f, 1.0f)},
         {XMFLOAT3(-0.5f,  0.5f,  0.5f), XMFLOAT2(0.0f, 1.0f)},
         {XMFLOAT3( 0.5f, -0.5f, -0.5f), XMFLOAT2(1.0f, 0.0f)},
         {XMFLOAT3( 0.5f, -0.5f,  0.5f), XMFLOAT2(1.0f, 0.0f)},
         {XMFLOAT3( 0.5f,  0.5f, -0.5f), XMFLOAT2(1.0f, 1.0f)},
         {XMFLOAT3( 0.5f,  0.5f,  0.5f), XMFLOAT2(1.0f, 1.0f)},
      };

      D3D11_SUBRESOURCE_DATA vertexBufferData = {0};
      vertexBufferData.pSysMem = cubeVertices;
      vertexBufferData.SysMemPitch = 0;
      vertexBufferData.SysMemSlicePitch = 0;
      CD3D11_BUFFER_DESC vertexBufferDesc(sizeof(cubeVertices), D3D11_BIND_VERTEX_BUFFER);
      DX::ThrowIfFailed(
         device->CreateBuffer(
            &vertexBufferDesc,
            &vertexBufferData,
            &m_vertexBuffer
            )
         );

      unsigned short cubeIndices[] = 
      {
         0,2,1, // -x
         1,2,3,

         4,5,6, // +x
         5,7,6,

         0,1,5, // -y
         0,5,4,

         2,6,7, // +y
         2,7,3,

         0,4,6, // -z
         0,6,2,

         1,3,7, // +z
         1,7,5,
      };

      m_indexCount = ARRAYSIZE(cubeIndices);

      D3D11_SUBRESOURCE_DATA indexBufferData = {0};
      indexBufferData.pSysMem = cubeIndices;
      indexBufferData.SysMemPitch = 0;
      indexBufferData.SysMemSlicePitch = 0;
      CD3D11_BUFFER_DESC indexBufferDesc(sizeof(cubeIndices), D3D11_BIND_INDEX_BUFFER);
      DX::ThrowIfFailed(
         device->CreateBuffer(
            &indexBufferDesc,
            &indexBufferData,
            &m_indexBuffer
            )
         );

      valid = true;
   }

   void SetRect(XMFLOAT4X4 &inOrientation,int inWidth, int inHeight)
   {
      float aspectRatio = (float)inWidth/inHeight;
      float fovAngleY = 70.0f * XM_PI / 180.0f;

      // Note that the m_orientationTransform3D matrix is post-multiplied here
      // in order to correctly orient the scene to match the display orientation.
      // This post-multiplication step is required for any draw calls that are
      // made to the swap chain render target. For draw calls to other targets,
      // this transform should not be applied.
      XMStoreFloat4x4(
         &m_constantBufferData.projection,
         XMMatrixTranspose(
            XMMatrixMultiply(
               XMMatrixPerspectiveFovRH(
                  fovAngleY,
                  aspectRatio,
                  0.01f,
                  100.0f
                  ),
               XMLoadFloat4x4(&inOrientation)
               )
            )
         );
   }

   void Update(float timeTotal, float timeDelta)
   {
      XMVECTOR eye = XMVectorSet(0.0f, 0.7f, 1.5f, 0.0f);
      XMVECTOR at = XMVectorSet(0.0f, -0.1f, 0.0f, 0.0f);
      XMVECTOR up = XMVectorSet(0.0f, 1.0f, 0.0f, 0.0f);

      XMStoreFloat4x4(&m_constantBufferData.view, XMMatrixTranspose(XMMatrixLookAtRH(eye, at, up)));
      XMStoreFloat4x4(&m_constantBufferData.model, XMMatrixTranspose(XMMatrixRotationY(timeTotal * XM_PIDIV4)));
   }

   void Render(HardwareContext *dx, Surface *inSurface)
   {
      context->UpdateSubresource( m_constantBuffer.Get(), 0, NULL, &m_constantBufferData, 0, 0);

      UINT stride = sizeof(VertexPositionTex);
      UINT offset = 0;
      context->IASetVertexBuffers( 0, 1, m_vertexBuffer.GetAddressOf(), &stride, &offset);
      context->IASetIndexBuffer( m_indexBuffer.Get(), DXGI_FORMAT_R16_UINT, 0);
      context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
      context->IASetInputLayout(m_inputLayout.Get());
      context->VSSetShader( m_vertexShader.Get(), nullptr, 0);
      context->VSSetConstantBuffers( 0, 1, m_constantBuffer.GetAddressOf());
      context->PSSetShader( m_pixelShader.Get(), nullptr, 0);
      inSurface->Bind(*dx,0);

      context->DrawIndexed( m_indexCount, 0, 0);
   }

   ComPtr<ID3D11Device1> device;
   ComPtr<ID3D11DeviceContext1> context;

   ComPtr<ID3D11InputLayout> m_inputLayout;
   ComPtr<ID3D11Buffer> m_vertexBuffer;
   ComPtr<ID3D11Buffer> m_indexBuffer;
   ComPtr<ID3D11VertexShader> m_vertexShader;
   ComPtr<ID3D11PixelShader> m_pixelShader;
   ComPtr<ID3D11Buffer> m_constantBuffer;

   uint32 m_indexCount;
   bool   valid;
   ModelViewProjectionConstantBuffer m_constantBufferData;
};




class WinRTStage : public Stage, public Direct3DBase
{
public:
   WinRTStage(uint32 inFlags, int inWidth, int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
      mFlags = inFlags;

      mIsFullscreen = true;
   }

   void Initialize(Windows::UI::Core::CoreWindow^ window)
   {
      Direct3DBase::Initialize(window);

      mDXContext = HardwareContext::CreateDX11(m_d3dDevice.Get(), m_d3dContext.Get());

      mQuad = new Quad(m_d3dDevice, m_d3dContext);
      mQuad->SetRect(m_orientationTransform3D, mWidth, mHeight);

      //mPrimarySurface = new HardwareSurface(mDXContext);
      //mPrimarySurface = new SimpleSurface(mWidth,mHeight,pfARGB);
      mPrimarySurface = new SimpleSurface(mWidth,mHeight,pfARGB);

      mDXContext->SetWindowSize(mWidth, mHeight);

      mMultiTouch = true;
      mSingleTouchID = NO_TOUCH;
      mDX = 0;
      mDY = 0;

      // Click detection
      mDownX = 0;
      mDownY = 0;
   }

   ~WinRTStage()
   {
      delete mQuad;
      mPrimarySurface->DecRef();
   }

   void Resize(int inWidth,int inHeight)
   {
      // Little hack to help windows
      //mSDLSurface->w = inWidth;
      //mSDLSurface->h = inHeight;
      //mDXContext->SetWindowSize(inWidth,inHeight);
      gTextureContextVersion++;

      //lime_resize_id ++;
      mDXContext->DecRef();
      mDXContext = HardwareContext::CreateDX11(m_d3dDevice.Get(), m_d3dContext.Get());
      mDXContext->SetWindowSize(inWidth, inHeight);
      mDXContext->IncRef();
      mPrimarySurface->DecRef();
      //mPrimarySurface = new HardwareSurface(mDXContext);
      mPrimarySurface = new SimpleSurface(mWidth,mHeight,pfXRGB);
   }

    void Update(float timeTotal, float timeDelta)
    {
       if (mQuad && mQuad->valid)
          mQuad->Update(timeTotal, timeDelta);
    }


   void Render()
   {
      const float midnightBlue[] = { 0.098f, 0.098f, 0.439f, 1.000f };
      m_d3dContext->ClearRenderTargetView(
         m_renderTargetView.Get(),
         midnightBlue
         );

       m_d3dContext->ClearDepthStencilView(
          m_depthStencilView.Get(),
          D3D11_CLEAR_DEPTH,
          1.0f,
          0
          );

     m_d3dContext->OMSetRenderTargets(
      1,
      m_renderTargetView.GetAddressOf(),
      m_depthStencilView.Get()
      );

     RenderStage();

     if (mQuad && mQuad->valid)
        mQuad->Render(mDXContext, mPrimarySurface);
   }

   void SetFullscreen(bool inFullscreen)
   {
      // Hmmm
      //Event resize(etResize,w,h);
      //ProcessEvent(resize);
   }

   bool isOpenGL() const { return false; }

   void ProcessEvent(Event &inEvent)
   {
      HandleEvent(inEvent);
   }


   void Flip()
   {
   }
   void GetMouse()
   {
   }

   void SetCursor(Cursor inCursor)
   {
   }

   void ShowCursor(bool inShow)
   {
      if (inShow!=mShowCursor)
      {
         mShowCursor = inShow;
         this->SetCursor(mCurrentCursor);
      }
   }
   
   
   void EnablePopupKeyboard(bool enabled)
   {
   }
   
   
   bool getMultitouchSupported()
   { 
       return true;
   }
   void setMultitouchActive(bool inActive) { mMultiTouch = inActive; }
   bool getMultitouchActive()
   {
      return mMultiTouch;
   }
   
   bool mMultiTouch;
   int  mSingleTouchID;
  
   double mDX;
   double mDY;

   double mDownX;
   double mDownY;

   Surface *GetPrimarySurface()
   {
      return mPrimarySurface;
   }

   HardwareContext *mDXContext;
   Quad            *mQuad;
   SimpleSurface  *mPrimarySurface;
   double       mFrameRate;
   Cursor       mCurrentCursor;
   bool         mShowCursor;
   bool         mIsFullscreen;
   unsigned int mFlags;
   int          mWidth;
   int          mHeight;
};


class WinRTFrame : public Frame
{
public:
   WinRTFrame(uint32 inFlags, int inW,int inH)
   {
      mFlags = inFlags;
      mStage = new WinRTStage(mFlags,inW,inH);
      mStage->IncRef();
      // SetTimer(mHandle,timerFrame, 10,0);
   }
   ~WinRTFrame()
   {
      mStage->DecRef();
   }

   void ProcessEvent(Event &inEvent)
   {
      mStage->ProcessEvent(inEvent);
   }
   void Resize(int inWidth,int inHeight)
   {
      mStage->Resize(inWidth,inHeight);
   }

  // --- Frame Interface ----------------------------------------------------

   void SetTitle()
   {
   }
   void SetIcon()
   {
   }
   Stage *GetStage()
   {
      return mStage;
   }

   WinRTStage *mStage;
   uint32 mFlags;
   double mAccX;
   double mAccY;
   double mAccZ;
};



} // end namespace lime





// --- App interface ----------------------------------------------

ref class D3DApp sealed : public Windows::ApplicationModel::Core::IFrameworkView
{
   int width;
   int height;
   unsigned int flags;

public:
   D3DApp(int inWidth, int inHeight, unsigned int inFlags)
   {
      m_windowClosed = false;
      m_windowVisible = true;
      width = inWidth;
      height = inHeight;
      flags = inFlags;
   }

   D3DApp::D3DApp() : m_windowClosed(false), m_windowVisible(true)
   {
      mFrame = 0;
   }
   virtual ~D3DApp()
   {
      delete mFrame;
   }

   void bootlime()
   {
      mFrame = new lime::WinRTFrame(flags,width,height);
      mStage = mFrame->mStage;
      if (lime::sgOnFrame)
      {
         lime::sgOnFrame(mFrame);
         lime::sgOnFrame = 0;
      }
   }
   
   // IFrameworkView Methods.
   virtual void Initialize(Windows::ApplicationModel::Core::CoreApplicationView^ applicationView)
   {
      applicationView->Activated +=
        ref new TypedEventHandler<CoreApplicationView^, IActivatedEventArgs^>(this, &D3DApp::OnActivated);

      CoreApplication::Suspending +=
        ref new ::EventHandler<SuspendingEventArgs^>(this, &D3DApp::OnSuspending);

      CoreApplication::Resuming +=
        ref new ::EventHandler<Platform::Object^>(this, &D3DApp::OnResuming);

      bootlime();
   }

   virtual void SetWindow(Windows::UI::Core::CoreWindow^ window)
   {
      window->SizeChanged += 
           ref new TypedEventHandler<CoreWindow^, WindowSizeChangedEventArgs^>(this, &D3DApp::OnWindowSizeChanged);

      window->VisibilityChanged +=
         ref new TypedEventHandler<CoreWindow^, VisibilityChangedEventArgs^>(this, &D3DApp::OnVisibilityChanged);

      window->Closed += 
           ref new TypedEventHandler<CoreWindow^, CoreWindowEventArgs^>(this, &D3DApp::OnWindowClosed);

      window->PointerCursor = ref new CoreCursor(CoreCursorType::Arrow, 0);

      window->PointerPressed +=
         ref new TypedEventHandler<CoreWindow^, PointerEventArgs^>(this, &D3DApp::OnPointerPressed);

      window->PointerMoved +=
         ref new TypedEventHandler<CoreWindow^, PointerEventArgs^>(this, &D3DApp::OnPointerMoved);

      mStage->Initialize(CoreWindow::GetForCurrentThread());
   }

   virtual void Load(Platform::String^ entryPoint) { }
      
   virtual void Run()
   {
      BasicTimer^ timer = ref new BasicTimer();

      while (!m_windowClosed)
      {
         if (m_windowVisible)
         {
            timer->Update();
            CoreWindow::GetForCurrentThread()->Dispatcher->ProcessEvents(CoreProcessEventsOption::ProcessAllIfPresent);

            mStage->Update(timer->Total, timer->Delta);

            mStage->Render();

            mStage->Present();
         }
         else
         {
            CoreWindow::GetForCurrentThread()->Dispatcher->ProcessEvents(CoreProcessEventsOption::ProcessOneAndAllPending);
         }
      }
   }

   virtual void Uninitialize()
   {
   }

protected:
   // Event Handlers.
   void OnWindowSizeChanged(Windows::UI::Core::CoreWindow^ sender, Windows::UI::Core::WindowSizeChangedEventArgs^ args)
   {
      mStage->UpdateForWindowSizeChange();
   }

   void OnLogicalDpiChanged(Platform::Object^ sender);
   void OnActivated(Windows::ApplicationModel::Core::CoreApplicationView^ applicationView, Windows::ApplicationModel::Activation::IActivatedEventArgs^ args)
   {
      CoreWindow::GetForCurrentThread()->Activate();
   }

   void OnSuspending(Platform::Object^ sender, Windows::ApplicationModel::SuspendingEventArgs^ args)
   {
      // Save app state asynchronously after requesting a deferral. Holding a deferral
      // indicates that the application is busy performing suspending operations. Be
      // aware that a deferral may not be held indefinitely. After about five seconds,
      // the app will be forced to exit.
      SuspendingDeferral^ deferral = args->SuspendingOperation->GetDeferral();

      create_task([this, deferral]()
      {
         // Insert your code here.

         deferral->Complete();
      });
   }

   void OnResuming(Platform::Object^ sender, Platform::Object^ args)
   {
      // Restore any data or state that was unloaded on suspend. By default, data
      // and state are persisted when resuming from suspend. Note that this event
      // does not occur if the app was previously terminated.
   }

   void OnWindowClosed(Windows::UI::Core::CoreWindow^ sender, Windows::UI::Core::CoreWindowEventArgs^ args)
   {
      m_windowClosed = true;
   }
   void OnVisibilityChanged(Windows::UI::Core::CoreWindow^ sender, Windows::UI::Core::VisibilityChangedEventArgs^ args)
   {
      m_windowVisible = args->Visible;
   }

   void OnPointerPressed(Windows::UI::Core::CoreWindow^ sender, Windows::UI::Core::PointerEventArgs^ args)
   {
   }

   void OnPointerMoved(Windows::UI::Core::CoreWindow^ sender, Windows::UI::Core::PointerEventArgs^ args)
   {
   }

private:
   lime::WinRTFrame *mFrame;
   lime::WinRTStage *mStage;
   bool m_windowClosed;
   bool m_windowVisible;
};


// --- AppSource ------------------------------------------

ref class D3DAppSource sealed : Windows::ApplicationModel::Core::IFrameworkViewSource
{
   int width;
   int height;
   unsigned int flags;

public:
   D3DAppSource(int inWidth, int inHeight, unsigned int inFlags)
   {
      width = inWidth;
      height = inHeight;
      flags = inFlags;
   }

   virtual IFrameworkView^ CreateView()
   {
      auto result = ref new D3DApp(width,height,flags);
      return result;
   }

};


// --- External lime code ---------------------------------


namespace lime
{


void CreateMainFrame(lime::FrameCreationCallback inOnFrame,int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle, lime::Surface *inIcon )
{
   sgOnFrame = inOnFrame;
   auto appSource = ref new D3DAppSource(inWidth,inHeight,inFlags);
   CoreApplication::Run(appSource);
}


bool sgDead = false;

void SetIcon( const char *path ) { }

QuickVec<int> *CapabilitiesGetScreenResolutions()
{
   // TODO
   QuickVec<int> *out = new QuickVec<int>();
   out->push_back(1024);
   out->push_back(768);
   return out;
}

double CapabilitiesGetScreenResolutionX() { return sgDesktopWidth; }
double CapabilitiesGetScreenResolutionY() { return sgDesktopHeight; }
void PauseAnimation() {}
void ResumeAnimation() {}

void StopAnimation()
{
   sgDead = true;
}

void StartAnimation()
{
}


}
