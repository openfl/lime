#include "Shaders.h"
#include <DirectXMath.h>
#include "DirectXHelper.h"
#include <string>

typedef unsigned char BYTE;

#include "shaders/SimplePixelShader.h"
#include "shaders/SimpleVertexShader.h"


using namespace Microsoft::WRL;

static const D3D11_INPUT_ELEMENT_DESC posTex[] = 
{
  { "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0,  D3D11_INPUT_PER_VERTEX_DATA, 0 },
  { "TEXCOORD",0, DXGI_FORMAT_R32G32_FLOAT,     0, 12, D3D11_INPUT_PER_VERTEX_DATA, 0 },
};


ComPtr<ID3D11VertexShader> limeCreateVertexShader(
    ComPtr<ID3D11Device1> inDevice,
    ComPtr<ID3D11InputLayout> &outLayout,
    ShaderId inShader)
{
   const BYTE *data = 0;
   int len = 0;
   const D3D11_INPUT_ELEMENT_DESC *desc = 0;
   int descLen = 0;

   switch(inShader)
   {
      case vsSimple:
         data = gVertexShader;
         len = sizeof(gVertexShader);
         desc = posTex;
         descLen = 2;
         break;
   }

   ComPtr<ID3D11VertexShader> result;

   std::string s((const char *)data,len);

   DX::ThrowIfFailed( inDevice->CreateVertexShader( data, len, 0, &result) );

   HRESULT hr = inDevice->CreateInputLayout( desc, descLen, data, len, &outLayout);
   DX::ThrowIfFailed(hr);

   return result;
}



ComPtr<ID3D11PixelShader> limeCreatePixelShader(ComPtr<ID3D11Device1> inDevice, ShaderId inShader)
{
   const BYTE *data = 0;
   int len = 0;

   switch(inShader)
   {
      case psSimple:
         data = gPixelShader;
         len = sizeof(gPixelShader);
         break;
   }

   ComPtr<ID3D11PixelShader> result;

   DX::ThrowIfFailed( inDevice->CreatePixelShader( data, len, nullptr, &result) );

   return result;
}


