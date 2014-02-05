#include "renderer/opengl/OGL.h"
#include "renderer/opengl/OpenGLProgram.h"


namespace lime {
	
	
	GPUProg *GPUProg::create (unsigned int inID) {
		
		std::string vertexVars =
			"uniform mat4 uTransform;\n"
			"attribute vec4 aVertex;\n";
		
		std::string vertexProg =
			"   gl_Position = aVertex * uTransform;\n";
		
		std::string pixelVars = "";
		std::string pixelProlog = "";
		
		#ifdef LIME_GLES
		pixelVars = std::string ("precision mediump float;\n");
		#endif
		
		std::string fragColour = "";
		
		if (inID & PROG_TINT) {
			
			pixelVars += "uniform vec4 uColourScale;\n";
			fragColour = "uColourScale";
			
		}
		
		if (inID & PROG_COLOUR_OFFSET) {
			
			pixelVars += "uniform vec4 uColourOffset;\n";
			
		}
		
		if (inID & PROG_COLOUR_PER_VERTEX) {
			
			vertexVars +=
				"attribute vec4 aColourArray;\n"
				"varying vec4 vColourArray;\n";
			
			vertexProg =
				"   vColourArray = aColourArray;\n" + vertexProg;
			
			pixelVars +=
				"varying vec4 vColourArray;\n";
			
			if (fragColour != "") {
				
				fragColour += "*";
				
			}
			
			fragColour += "vColourArray";
			
		}
		
		if (inID & PROG_TEXTURE) {
			
			vertexVars +=
				"attribute vec2 aTexCoord;\n"
				"varying vec2 vTexCoord;\n";
			
			vertexProg =
				"   vTexCoord = aTexCoord;\n" + vertexProg;
			
			pixelVars +=
				"uniform sampler2D uImage0;\n"
				"varying vec2 vTexCoord;\n";
			
			if (!(inID & PROG_RADIAL)) {
				
				if (fragColour != "") {
					
					fragColour += "*";
					
				}
				
				if (inID & PROG_ALPHA_TEXTURE) {
					
					fragColour += "vec4(1,1,1,texture2D(uImage0,vTexCoord).a)";
					
				} else {
					
					fragColour += "texture2D(uImage0,vTexCoord)";
					
				}
				
			}
			
		}
		
		if (inID & PROG_RADIAL) {
			
			if (inID & PROG_RADIAL_FOCUS) {
				
				pixelVars +=
					"uniform float mA;\n"
					"uniform float mFX;\n"
					"uniform float mOn2A;\n";
				
				pixelProlog = 
					"   float GX = vTexCoord.x - mFX;\n"
					"   float C = GX*GX + vTexCoord.y*vTexCoord.y;\n"
					"   float B = 2.0*GX * mFX;\n"
					"   float det =B*B - mA*C;\n"
					"   float rad;\n"
					"   if (det<0.0)\n"
					"      rad = -B * mOn2A;\n"
					"   else\n"
					"      rad = (-B - sqrt(det)) * mOn2A;\n";
				
			} else {
				
				pixelProlog = 
					"   float rad = sqrt(vTexCoord.x*vTexCoord.x + vTexCoord.y*vTexCoord.y);\n";
				
			}
			
			if (fragColour != "") {
				
				fragColour += "*";
				
			}
			
			fragColour += "texture2D(uImage0,vec2(rad,0))";
			
		}
		
		if (inID & PROG_NORMAL_DATA) {
			
			vertexVars +=
				"attribute vec2 aNormal;\n"
				"varying vec2 vNormal;\n";
			
			vertexProg =
				"   vNormal = aNormal;\n" + vertexProg;
			
			pixelVars +=
				"varying vec2 vNormal;\n";
			
		}
		
		std::string vertexShader = 
			vertexVars + 
			"void main()\n"
			"{\n" +
				vertexProg +
			"}\n";
		
		if (fragColour == "") {
			
			fragColour = "vec4(1,1,1,1)";
			
		}
		
		if (inID & PROG_COLOUR_OFFSET) {
			
			fragColour = fragColour + "+ uColourOffset";
			
		}
		
		if (inID & PROG_NORMAL_DATA) {
			
			fragColour = "(" + fragColour + ") * vec4(1,1,1, min(vNormal.x-abs(vNormal.y),1.0) )";
			
		}
		
		std::string pixelShader =
			pixelVars +
			"void main()\n"
			"{\n" +
				pixelProlog +
				"   gl_FragColor = " + fragColour + ";\n" +
			"}\n";
		
		return new OpenGLProgram (vertexShader, pixelShader);
		
	}
	
	
}
