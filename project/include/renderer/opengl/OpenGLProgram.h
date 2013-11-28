#ifndef RENDERER_OPENGL_PROGRAM_H
#define RENDERER_OPENGL_PROGRAM_H


#include "renderer/opengl/OGL.h"


namespace lime {
	
	
	class OpenGLProgram : public GPUProg {
		
		public:
			
			OpenGLProgram (const char *inVertProg, const char *inFragProg, AlphaMode inAlphaMode);
			virtual ~OpenGLProgram ();
			
			virtual bool bind ();
			virtual void setGradientFocus (float inFocus);
			
			GLuint createShader (GLuint inType, const char *inShader);
			void finishDrawing ();
			int getTextureSlot ();
			void recreate ();
			void setColourData (const int *inData);
			void setColourTransform (const ColorTransform *inTransform);
			void setPositionData (const float *inData, bool inIsPerspective);
			void setTexCoordData (const float *inData);
			void setTint (unsigned int inColour);
			void setTransform (const Trans4x4 &inTrans);
			
			AlphaMode mAlphaMode;
			GLint mASlot;
			GLint mColourArraySlot;
			GLint mColourOffsetSlot;
			GLint mColourScaleSlot;
			const ColorTransform *mColourTransform;
			int mContextVersion;
			GLuint mFragId;
			const char *mFragProg;
			GLint mFXSlot;
			GLint mOn2ASlot;
			GLuint mProgramId;
			GLint mTexCoordSlot;
			GLint mTextureSlot;
			GLint mTintSlot;
			GLint mTransformSlot;
			GLuint mVertId;
			const char *mVertProg;
			GLint mVertexSlot;
		
	};
	
	
}


#endif
