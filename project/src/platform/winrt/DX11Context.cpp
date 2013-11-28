#include <Display.h>
#include <Graphics.h>
#include "renderer/common/HardwareSurface.h"
#include "renderer/common/HardwareContext.h"
#include "renderer/common/Texture.h"


#include <wrl/client.h>
#include <d3d11_1.h>
#include <DirectXMath.h>
#include <memory>
#include <agile.h>
#include "BasicTimer.h"
#include "Direct3DBase.h"
#include "Shaders.h"


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


class DX11Context : public HardwareContext
{
public:
   ComPtr<ID3D11Device1> device;
   ComPtr<ID3D11DeviceContext1> context;
   int mWidth;
   int mHeight;


   DX11Context(void *inDevice,void *inContext)
   {
      device = (ID3D11Device1 *)inDevice;
      context = (ID3D11DeviceContext1 *)inContext;
      mWidth = mHeight = 0;
   }

   void SetWindowSize(int inWidth,int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
   }

   void SetQuality(StageQuality inQuality)
   {
   }

   void BeginRender(const Rect &inRect,bool inForHitTest)
   {
   }

   void EndRender()
   {
   }


   void SetViewport(const Rect &inRect)
   {
   }

   void Clear(uint32 inColour,const Rect *inRect=0)
   {
   }

   void Flip()
   {
   }

   void DestroyNativeTexture(void *)
   {
      // TODO
   }

   int Width() const { return mWidth; }

   int Height() const { return mHeight; } 

   class Texture *CreateTexture(class Surface *inSurface, unsigned int inFlags);

   void Render(const RenderState &inState, const HardwareCalls &inCalls )
   {
   }

   void BeginBitmapRender(Surface *inSurface,uint32 inTint,bool inRepeat,bool inSmooth)
   {
   }

   void RenderBitmap(const Rect &inSrc, int inX, int inY)
   {
   }

   void EndBitmapRender()
   {
   }
};




class DX11Texture : public Texture
{
public:
   ComPtr<ID3D11Texture2D> surface;
   ComPtr<ID3D11SamplerState> sampler;
   ComPtr<ID3D11ShaderResourceView> resourceView;
   ComPtr<ID3D11DeviceContext1> context;

   DX11Context *dx;
   unsigned int flags;
   int          width;
   int          height;

   DX11Texture(DX11Context *inContext,Surface *inSurface, unsigned int inFlags)
   {
      dx = inContext;
      width = inSurface->Width();
      height = inSurface->Height();
      flags = inFlags;

      // --- Texture ----
      D3D11_TEXTURE2D_DESC desc;
      desc.Width = width;
      desc.Height = height;
      desc.MipLevels = 1;
      desc.ArraySize = 1;
      desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
      desc.SampleDesc.Count = 1;
      desc.SampleDesc.Quality = 0;
      desc.Usage = D3D11_USAGE_DYNAMIC;
      desc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
      desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
      desc.MiscFlags = 0;

      DX::ThrowIfFailed(
         dx->device->CreateTexture2D( &desc, nullptr, &surface) );

      // --- Sampler ----
      D3D11_SAMPLER_DESC sampDesc;
      ZeroMemory( &sampDesc, sizeof(sampDesc) );
      sampDesc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
      sampDesc.AddressU = D3D11_TEXTURE_ADDRESS_WRAP;
      sampDesc.AddressV = D3D11_TEXTURE_ADDRESS_WRAP;
      sampDesc.AddressW = D3D11_TEXTURE_ADDRESS_WRAP;
      sampDesc.ComparisonFunc = D3D11_COMPARISON_NEVER;
      sampDesc.MinLOD = 0;
      sampDesc.MaxLOD = 1;
      DX::ThrowIfFailed(
         dx->device->CreateSamplerState( &sampDesc, &sampler ) );

      // --- Resource View ----
      D3D11_SHADER_RESOURCE_VIEW_DESC shaderResourceViewDesc;
      shaderResourceViewDesc.Format = desc.Format;
      shaderResourceViewDesc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
      shaderResourceViewDesc.Texture2D.MostDetailedMip = 0;
      shaderResourceViewDesc.Texture2D.MipLevels = 1;

      DX::ThrowIfFailed(
         dx->device->CreateShaderResourceView(surface.Get(), &shaderResourceViewDesc, &resourceView) );

      mDirtyRect = Rect(0,0,width,height);
   }

   ~DX11Texture()
   {
   }

   void Bind(class Surface *inSurface,int inSlot)
   {
      if (inSurface->GetBase() && mDirtyRect.HasPixels())
      {
         /*
         enum { CHECK_VIEWS = 4 };
         ID3D11ShaderResourceView *bound[CHECK_VIEWS];

         dx->context->PSGetShaderResources(0, CHECK_VIEWS, bound);
         for(int i=0;i<CHECK_VIEWS;i++)
         {
            if (bound[i])
            {
               if (bound[i]==resourceView.Get())
                  dx->context->PSSetShaderResources( i, 0, 0 );
               bound[i]->Release();
            }
         }
         */
         const uint8 *src = 
            inSurface->Row(mDirtyRect.y) + mDirtyRect.x*inSurface->BytesPP();

         D3D11_MAPPED_SUBRESOURCE mapData;
         HRESULT hr=dx->context->Map(surface.Get(), 0, D3D11_MAP_WRITE_DISCARD, 0, &mapData);
         int  destStride = mapData.RowPitch;
         uint8 *dest = ((uint8*)mapData.pData) + mDirtyRect.y*destStride + mDirtyRect.x*4;

         for(int y=0;y<mDirtyRect.h;y++)
         {
            memcpy(dest, src, mDirtyRect.w*4 );
            src += inSurface->GetStride();
            dest += destStride;
         }
         dx->context->Unmap(surface.Get(),0);
         mDirtyRect = Rect();


      }

      ID3D11ShaderResourceView *resources[] = { resourceView.Get() };
      dx->context->PSSetShaderResources( inSlot, 1, resources );
      dx->context->PSSetSamplers( inSlot, 1, &sampler );
   }

   void BindFlags(bool inRepeat,bool inSmooth)
   {
      // TODO:
   }
   UserPoint PixelToTex(const UserPoint &inPixels)
   {
      return UserPoint(inPixels.x/width, inPixels.y/height);
   }
   UserPoint TexToPaddedTex(const UserPoint &inPixels)
   {
      return inPixels;
   }

};



class Texture *DX11Context::CreateTexture(class Surface *inSurface, unsigned int inFlags)
{
   return new DX11Texture(this, inSurface, inFlags);
}






HardwareContext *HardwareContext::current = 0;

HardwareContext *HardwareContext::CreateDX11(void *inDevice, void *inContext)
{
   return new DX11Context(inDevice,inContext);
}

} // end namespace lime
