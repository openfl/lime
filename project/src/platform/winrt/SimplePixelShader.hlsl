Texture2D tex0  :register( t0 );
SamplerState sampleType : register( s0 );


struct PixelShaderInput
{
	float2 Texcoord  : TEXCOORD0;
};

float4 main(PixelShaderInput input) : SV_TARGET
{
   return tex0.Sample(sampleType, input.Texcoord);
   //return input.Texcoord.xyxy;
}
