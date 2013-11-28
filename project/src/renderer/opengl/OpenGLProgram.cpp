#include "renderer/opengl/OGL.h"
#ifdef ALLOW_OGL2


#include "renderer/opengl/OpenGLProgram.h"


namespace lime {
	
	
	const float one_on_255 = 1.0 / 255.0;
	
	
	OpenGLProgram::OpenGLProgram (const char *inVertProg, const char *inFragProg, AlphaMode inAlphaMode) {
		
		mVertProg = inVertProg;
		mFragProg = inFragProg;
		mAlphaMode = inAlphaMode;
		mVertId = 0;
		mFragId = 0;
		mTexCoordSlot = -1;
		mTextureSlot = -1;
		mColourTransform = 0;
		recreate ();
		
	}
	
	
	OpenGLProgram::~OpenGLProgram () {}
	
	
	bool OpenGLProgram::bind () {
		
		if (gTextureContextVersion != mContextVersion)
			recreate ();
		
		if (mProgramId == 0)
			return false;
		
		glUseProgram (mProgramId);
		return true;
		
	}
	
	
	GLuint OpenGLProgram::createShader (GLuint inType, const char *inShader) {
		
		const char *source = inShader;
		GLuint shader = glCreateShader (inType);
		
		#ifdef LIME_GLES
		std::string sourceBuf;
		if (inType == GL_FRAGMENT_SHADER) {
			
			sourceBuf = std::string ("precision mediump float;\n") + inShader;
			source = sourceBuf.c_str ();
			
		}
		#endif
		
		glShaderSource (shader, 1, &source, 0);
		glCompileShader (shader);
		
		GLint compiled = 0;
		glGetShaderiv (shader, GL_COMPILE_STATUS, &compiled);
		if (compiled)
			return shader;
		
		GLint blen = 0;	
		GLsizei slen = 0;
		
		glGetShaderiv (shader, GL_INFO_LOG_LENGTH, &blen);		 
		if (blen > 0) {
			
			char* compiler_log = (char*)malloc (blen);
			glGetShaderInfoLog (shader, blen, &slen, compiler_log);
			ELOG ("Error compiling shader : %s\n", compiler_log);
			ELOG ("%s\n", source);
			free (compiler_log);
			
		} else {
			
			ELOG ("Unknown error compiling shader : \n");
			ELOG ("%s\n", source);
			
		}
		
		glDeleteShader (shader);
		return 0;
		
	}
	
	
	void OpenGLProgram::finishDrawing () {
		
		if (mColourArraySlot >= 0)
			glDisableVertexAttribArray (mColourArraySlot);
		
		if (mTexCoordSlot >= 0)
			glDisableVertexAttribArray (mTexCoordSlot);
		
		if (mVertexSlot >= 0)
			glDisableVertexAttribArray (mVertexSlot);
		
	}
	
	
	int OpenGLProgram::getTextureSlot () {
		
		return mTextureSlot;
		
	}
	
	
	void OpenGLProgram::recreate () {
		
		mContextVersion = gTextureContextVersion;
		mProgramId = 0;
		
		mVertId = createShader (GL_VERTEX_SHADER, mVertProg);
		if (!mVertId)
			return;
		mFragId = createShader (GL_FRAGMENT_SHADER, mFragProg);
		if (!mFragId)
			return;
		
		mProgramId = glCreateProgram ();
		
		glAttachShader (mProgramId, mVertId);
		glAttachShader (mProgramId, mFragId);
		
		glLinkProgram (mProgramId); 
		
		// Validate program
		glValidateProgram (mProgramId);
		
		GLint linked;
		glGetProgramiv (mProgramId, GL_LINK_STATUS, &linked);
		if (linked) {
			
			// All good !
			//printf("Linked!\n");
			
		} else {
			
			ELOG ("Bad Link.");
			
			// Check the status of the compile/link
			int logLen = 0;
			glGetProgramiv (mProgramId, GL_INFO_LOG_LENGTH, &logLen);
			if (logLen > 0) {
				
				// Show any errors as appropriate
				char *log = new char[logLen];
				glGetProgramInfoLog (mProgramId, logLen, &logLen, log);
				ELOG ("----");
				ELOG ("VERT: %s", mVertProg);
				ELOG ("FRAG: %s", mFragProg);
				ELOG ("ERROR:\n%s\n", log);
				delete [] log;
				
			}
			
			glDeleteShader (mVertId);
			glDeleteShader (mFragId);
			glDeleteProgram (mProgramId);
			mVertId = mFragId = mProgramId = 0;
			
		}
		
		mVertexSlot = glGetAttribLocation (mProgramId, "aVertex");
		mTexCoordSlot = glGetAttribLocation (mProgramId, "aTexCoord");
		mTransformSlot = glGetUniformLocation (mProgramId, "uTransform");
		mTintSlot = glGetUniformLocation (mProgramId, "uTint");
		mColourArraySlot = glGetAttribLocation (mProgramId, "aColourArray");
		mTextureSlot = glGetUniformLocation (mProgramId, "uImage0");
		mColourOffsetSlot = glGetUniformLocation (mProgramId, "uColourOffset");
		mColourScaleSlot = glGetUniformLocation (mProgramId, "uColourScale");
		mFXSlot = glGetUniformLocation (mProgramId, "mFX");
		mASlot = glGetUniformLocation (mProgramId, "mA");
		mOn2ASlot = glGetUniformLocation (mProgramId, "mOn2A");
		
	}
	
	
	void OpenGLProgram::setColourData (const int *inData) {
		
		if (inData && mColourArraySlot >= 0) {
			
			glVertexAttribPointer (mColourArraySlot, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, inData);
			glEnableVertexAttribArray (mColourArraySlot);
			
		} else if (mColourArraySlot >= 0) {
			
			glDisableVertexAttribArray (mColourArraySlot);
			
		}
		
	}
	
	
	void OpenGLProgram::setColourTransform (const ColorTransform *inTransform) {
		
		mColourTransform = inTransform;
		if (inTransform && !inTransform->IsIdentity ()) {
			
			if (mColourOffsetSlot >= 0) {
				
				if (mAlphaMode == amPremultiplied)
					glUniform4f (mColourOffsetSlot, inTransform->redOffset * one_on_255 * inTransform->alphaMultiplier, inTransform->greenOffset * one_on_255 * inTransform->alphaMultiplier, inTransform->blueOffset * one_on_255 * inTransform->alphaMultiplier, inTransform->alphaOffset * one_on_255);
				else
					glUniform4f (mColourOffsetSlot, inTransform->redOffset * one_on_255, inTransform->greenOffset * one_on_255, inTransform->blueOffset * one_on_255, inTransform->alphaOffset * one_on_255);
				
			}
			
			if (mColourScaleSlot >= 0) {
				
				if (mAlphaMode == amPremultiplied)
					glUniform4f (mColourScaleSlot, inTransform->redMultiplier * inTransform->alphaMultiplier, inTransform->greenMultiplier * inTransform->alphaMultiplier, inTransform->blueMultiplier * inTransform->alphaMultiplier, inTransform->alphaMultiplier);
				else
					glUniform4f (mColourScaleSlot, inTransform->redMultiplier, inTransform->greenMultiplier, inTransform->blueMultiplier, inTransform->alphaMultiplier);
				
			}
			
		} else {
			
			if (mColourOffsetSlot >= 0)
				glUniform4f (mColourOffsetSlot, 0, 0, 0, 0);
			if (mColourScaleSlot >= 0)
				glUniform4f (mColourScaleSlot, 1, 1, 1, 1);
			
		}
		
	}
	
	
	void OpenGLProgram::setGradientFocus (float inFocus) {
		
		if (mASlot >= 0) {
			
			double fx = inFocus;
			if (fx < -0.99) fx = -0.99;
			else if (fx > 0.99) fx = 0.99;
			
			// mFY = 0;	mFY can be set to zero, since rotating the matrix
			//  can also compensate for this.
			
			double a = (fx * fx - 1.0);
			double on2a = 1.0 / (2.0 * a);
			a *= 4.0;
			glUniform1f (mASlot, a);
			glUniform1f (mFXSlot, fx);
			glUniform1f (mOn2ASlot, on2a);
			
		}
		
	}
	
	
	void OpenGLProgram::setPositionData (const float *inData, bool inIsPerspective) {
		
		glVertexAttribPointer (mVertexSlot, inIsPerspective ? 4 : 2, GL_FLOAT, GL_FALSE, 0, inData);
		glEnableVertexAttribArray (mVertexSlot);
		
	}
	
	
	void OpenGLProgram::setTexCoordData (const float *inData) {
		
		if (inData) {
			
			glVertexAttribPointer (mTexCoordSlot, 2, GL_FLOAT, GL_FALSE, 0, inData);
			glEnableVertexAttribArray (mTexCoordSlot);
			glUniform1i (mTextureSlot, 0);
			
		}
		
	}
	
	
	void OpenGLProgram::setTint (unsigned int inColour) {
		
		if (mTintSlot >= 0) {
			
			float a = ((inColour >> 24) & 0xff) * one_on_255;
			float c0 = ((inColour >> 16) & 0xff) * one_on_255;
			float c1 = ((inColour >> 8) & 0xff) * one_on_255;
			float c2 = (inColour & 0xff) * one_on_255;
			if (mAlphaMode == amPremultiplied)
				glUniform4f (mTintSlot, c0 * a, c1 * a, c2 * a, a);
			else
				glUniform4f (mTintSlot, c0, c1, c2, a);
			
		}
		
	}
	
	
	void OpenGLProgram::setTransform (const Trans4x4 &inTrans) {
		
		glUniformMatrix4fv (mTransformSlot, 1, 0, inTrans[0]);
		
	}
	
	
}


#endif
