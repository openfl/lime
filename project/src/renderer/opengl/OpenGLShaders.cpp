#include "renderer/opengl/OGL.h"
#include "renderer/opengl/OpenGLProgram.h"


namespace lime {
	
	
	const char *gSolidVert = 
		"uniform mat4 uTransform;\n"
		"attribute vec4 aVertex;\n"
		"void main(void)\n"
		"{\n"
		"	gl_Position = aVertex * uTransform;\n"
		"}";
	
	
	const char *gColourVert =
		"uniform mat4 uTransform;\n"
		"attribute vec4 aVertex;\n"
		"attribute vec4 aColourArray;\n"
		"varying vec4 vColourArray;\n"
		"void main(void)\n"
		"{\n"
		"	vColourArray = aColourArray;\n"
		"	gl_Position = aVertex * uTransform;\n"
		"}";
	
	
	const char *gTextureVert =
		"uniform mat4 uTransform;\n"
		"attribute vec4 aVertex;\n"
		"attribute vec2 aTexCoord;\n"
		"varying vec2 vTexCoord;\n"
		"void main(void)\n"
		"{\n"
		"	vTexCoord = aTexCoord;\n"
		"	gl_Position = aVertex * uTransform;\n"
		"}";
	
	
	const char *gTextureColourVert =
		"uniform mat4 uTransform;\n"
		"attribute vec4 aColourArray;\n"
		"attribute vec4 aVertex;\n"
		"attribute vec2 aTexCoord;\n"
		"varying vec2	vTexCoord;\n"
		"varying vec4  vColourArray;\n"
		"void main(void)\n"
		"{\n"
		"	vColourArray = aColourArray;\n"
		"	vTexCoord = aTexCoord;\n"
		"	gl_Position = aVertex * uTransform;\n"
		"}";
	
	
	const char *gSolidFrag = 
		"uniform vec4 uTint;\n"
		"void main(void)\n"
		"{\n"
		"	gl_FragColor = uTint;\n"
		"}\n";
	
	
	const char *gColourFrag =
		"varying vec4 vColourArray;\n"
		"void main(void)\n"
		"{\n"
		"	gl_FragColor = vColourArray;\n"
		"}\n";
	
	
	const char *gColourTransFrag =
		"varying vec4 vColourArray;\n"
		"uniform vec4 uColourScale;\n"
		"uniform vec4 uColourOffset;\n"
		"void main(void)\n"
		"{\n"
		"	gl_FragColor = vColourArray*uColourScale+uColourOffset;\n"
		"}\n";
	
	
	const char *gBitmapAlphaFrag =
		"varying vec2 vTexCoord;\n"
		"uniform sampler2D uImage0;\n"
		"uniform vec4 uTint;\n"
		"void main(void)\n"
		"{\n"
		"	gl_FragColor.rgb = uTint.rgb;\n"
		"	gl_FragColor.a = texture2D(uImage0,vTexCoord).a*uTint.a;\n"
		"}\n";
	
	
	const char *gBitmapAlphaPremultFrag =
		"varying vec2 vTexCoord;\n"
		"uniform sampler2D uImage0;\n"
		"uniform vec4 uTint;\n"
		"void main(void)\n"
		"{\n"
		"	gl_FragColor.rgb = uTint.rgb*texture2D(uImage0,vTexCoord).a;\n"
		"	gl_FragColor.a = texture2D(uImage0,vTexCoord).a*uTint.a;\n"
		"}\n";
	
	
	const char *gBitmapFrag =
		"varying vec2 vTexCoord;\n"
		"uniform sampler2D uImage0;\n"
		"uniform vec4 uTint;\n"
		"void main(void)\n"
		"{\n"
		"	gl_FragColor = texture2D(uImage0,vTexCoord)*uTint;\n"
		"}\n";
	
	
	const char *gTextureFrag =
		"varying vec2 vTexCoord;\n"
		"uniform sampler2D uImage0;\n"
		"void main(void)\n"
		"{\n"
		"	gl_FragColor = texture2D(uImage0,vTexCoord);\n"
		"}\n";
	
	
	const char *gRadialTextureFrag =
		"varying vec2 vTexCoord;\n"
		"uniform sampler2D uImage0;\n"
		"void main(void)\n"
		"{\n"
		"	float rad = sqrt(vTexCoord.x*vTexCoord.x + vTexCoord.y*vTexCoord.y);\n"
		"	gl_FragColor = texture2D(uImage0,vec2(rad,0));\n"
		"}\n";
	
	
	const char *gRadialFocusTextureFrag =
		"varying vec2 vTexCoord;\n"
		"uniform sampler2D uImage0;\n"
		"uniform float mA;\n"
		"uniform float mFX;\n"
		"uniform float mOn2A;\n"
		"void main(void)\n"
		"{\n"
		"	float GX = vTexCoord.x - mFX;\n"
		"	float C = GX*GX + vTexCoord.y*vTexCoord.y;\n"
		"	float B = 2.0*GX * mFX;\n"
		"	float det =B*B - mA*C;\n"
		"	float rad;\n"
		"	if (det<0.0)\n"
		"		rad = -B * mOn2A;\n"
		"	else\n"
		"		rad = (-B - sqrt(det)) * mOn2A;"
		"	gl_FragColor = texture2D(uImage0,vec2(rad,0));\n"
		"}\n";
	
	
	const char *gTextureColourFrag =
		"uniform sampler2D uImage0;\n"
		"varying vec2 vTexCoord;\n"
		"varying vec4 vColourArray;\n"
		"void main(void)\n"
		"{\n"
		"	gl_FragColor = texture2D(uImage0,vTexCoord) * vColourArray;\n"
		"}\n";
	
	
	const char *gTextureColourPremultFrag =
		"uniform sampler2D uImage0;\n"
		"varying vec2 vTexCoord;\n"
		"varying vec4 vColourArray;\n"
		"void main(void)\n"
		"{\n"
		"	gl_FragColor.rgb = texture2D(uImage0,vTexCoord).rgb * vColourArray.rgb * vColourArray.a;\n"
		"	gl_FragColor.a = texture2D(uImage0,vTexCoord).a * vColourArray.a;\n"
		"}\n";
	
	
	const char *gTextureTransFrag =
		"varying vec2 vTexCoord;\n"
		"uniform sampler2D uImage0;\n"
		"uniform vec4 uColourScale;\n"
		"uniform vec4 uColourOffset;\n"
		"void main(void)\n"
		"{\n"
		"	gl_FragColor = texture2D(uImage0,vTexCoord) * uColourScale + uColourOffset;\n"
		"}\n";
	
	
	GPUProg *GPUProg::create (GPUProgID inID, AlphaMode inAlphaMode) {
		
		#ifdef ALLOW_OGL2
		switch (inID) {
			
			case gpuSolid:
				return new OpenGLProgram (gSolidVert, gSolidFrag, inAlphaMode);
				
			case gpuColourTransform:
				return new OpenGLProgram (gColourVert, gColourTransFrag, inAlphaMode);
				
			case gpuColour:
				return new OpenGLProgram (gColourVert, gColourFrag, inAlphaMode);
				
			case gpuRadialGradient:
				return new OpenGLProgram (gTextureVert, gRadialTextureFrag, inAlphaMode);
				
			case gpuRadialFocusGradient:
				return new OpenGLProgram (gTextureVert, gRadialFocusTextureFrag, inAlphaMode);
				
			case gpuTexture:
				return new OpenGLProgram (gTextureVert, gTextureFrag, inAlphaMode);
				
			case gpuTextureColourArray:
				if (inAlphaMode == amPremultiplied)
					return new OpenGLProgram (gTextureColourVert, gTextureColourPremultFrag, inAlphaMode);
				else
					return new OpenGLProgram (gTextureColourVert, gTextureColourFrag, inAlphaMode);
				
			case gpuTextureTransform:
				return new OpenGLProgram (gTextureVert, gTextureTransFrag, inAlphaMode);
				
			case gpuBitmap:
				return new OpenGLProgram (gTextureVert, gBitmapFrag, inAlphaMode);
				
			case gpuBitmapAlpha:
				if (inAlphaMode == amPremultiplied)
					return new OpenGLProgram (gTextureVert, gBitmapAlphaPremultFrag, inAlphaMode);
				else
					return new OpenGLProgram (gTextureVert, gBitmapAlphaFrag, inAlphaMode);
				
			default:
				break;
			
		}
		#endif
		
		return 0;
		
	}
	
	
}
