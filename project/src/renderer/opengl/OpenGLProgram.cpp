#include "renderer/opengl/OGL.h"


#include "renderer/opengl/OpenGLProgram.h"


namespace lime {
	
	
	const float one_on_255 = 1.0 / 255.0;
	
	
	OpenGLProgram::OpenGLProgram (const std::string &inVertProg, const std::string &inFragProg) {
		
		mVertProg = inVertProg;
		mFragProg = inFragProg;
		mVertId = 0;
		mFragId = 0;
		
		mImageSlot = -1;
		mColourTransform = 0;
		
		vertexSlot = -1;
		textureSlot = -1;
		normalSlot = -1;
		colourSlot = -1;
		
		//printf("%s", inVertProg.c_str());
		//printf("%s", inFragProg.c_str());
		
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
	
	
	void OpenGLProgram::disableSlots () {
		
		if (vertexSlot >= 0) {
			
			glDisableVertexAttribArray (vertexSlot);
			
		}
		
		if (normalSlot >= 0) {
			
			glDisableVertexAttribArray (normalSlot);
			
		}
		
		if (colourSlot >= 0) {
			
			glDisableVertexAttribArray (colourSlot);
				
		}
		
		if (textureSlot >= 0) {
			
			glDisableVertexAttribArray (textureSlot);
			
		}
		
	}
	
	
	int OpenGLProgram::getTextureSlot () {
		
		return mImageSlot;
		
	}
	
	
	void OpenGLProgram::recreate () {
		
		mContextVersion = gTextureContextVersion;
		mProgramId = 0;
		
		mVertId = createShader (GL_VERTEX_SHADER, mVertProg.c_str ());
		if (!mVertId)
			return;
		mFragId = createShader (GL_FRAGMENT_SHADER, mFragProg.c_str ());
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
				ELOG ("VERT: %s", mVertProg.c_str ());
				ELOG ("FRAG: %s", mFragProg.c_str ());
				ELOG ("ERROR:\n%s\n", log);
				delete [] log;
				
			}
			
			glDeleteShader (mVertId);
			glDeleteShader (mFragId);
			glDeleteProgram (mProgramId);
			mVertId = mFragId = mProgramId = 0;
			
		}
		
		vertexSlot = glGetAttribLocation(mProgramId, "aVertex");
		textureSlot = glGetAttribLocation(mProgramId, "aTexCoord");
		colourSlot = glGetAttribLocation(mProgramId, "aColourArray");
		normalSlot = glGetAttribLocation(mProgramId, "aNormal");
		
		mTransformSlot = glGetUniformLocation (mProgramId, "uTransform");
		mImageSlot = glGetUniformLocation(mProgramId, "uImage0");
		mColourOffsetSlot = glGetUniformLocation (mProgramId, "uColourOffset");
		mColourScaleSlot = glGetUniformLocation (mProgramId, "uColourScale");
		mFXSlot = glGetUniformLocation (mProgramId, "mFX");
		mASlot = glGetUniformLocation (mProgramId, "mA");
		mOn2ASlot = glGetUniformLocation (mProgramId, "mOn2A");
		
		glUseProgram (mProgramId);
	    
	    if (mImageSlot >= 0) {
	    	
	    	glUniform1i (mImageSlot, 0);
	    	
	    }
	    
	}
	
	
	void OpenGLProgram::setColourTransform (const ColorTransform *inTransform, uint32 inColor) {
		
		float rf, gf, bf, af;
		
		if (inColor == 0xFFFFFFFF) {
			
			rf = gf = bf = af = 1.0;
			
		} else {
			
			rf = ((inColor >> 16) & 0xFF) * one_on_255;
			gf = ((inColor >> 8) & 0xFF) * one_on_255;
			bf = (inColor & 0xFF) * one_on_255;
			af = ((inColor >> 24) & 0xFF) * one_on_255;
			
		}
		
		if (inTransform && !inTransform->IsIdentity ()) {
			
			if (mColourOffsetSlot >= 0) {
				
				glUniform4f (mColourOffsetSlot, inTransform->redOffset * one_on_255, inTransform->greenOffset * one_on_255, inTransform->blueOffset * one_on_255, inTransform->alphaOffset * one_on_255);
				
			}
			
			if (mColourScaleSlot >= 0) {
				
				#ifdef LIME_PREMULTIPLIED_ALPHA
				glUniform4f (mColourScaleSlot, inTransform->redMultiplier * inTransform->alphaMultiplier * rf, inTransform->greenMultiplier * inTransform->alphaMultiplier * gf, inTransform->blueMultiplier * inTransform->alphaMultiplier * bf, inTransform->alphaMultiplier * af);
				#else
				glUniform4f (mColourScaleSlot, inTransform->redMultiplier * rf, inTransform->greenMultiplier * gf, inTransform->blueMultiplier * bf, inTransform->alphaMultiplier * af);
				#endif
				
			}
			
		} else {
			
			if (mColourOffsetSlot >= 0)
				glUniform4f (mColourOffsetSlot, 0, 0, 0, 0);
			if (mColourScaleSlot >= 0)
				glUniform4f (mColourScaleSlot, rf, gf, bf, af);
			
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
	
	
	void OpenGLProgram::setTransform (const Trans4x4 &inTrans) {
		
		glUniformMatrix4fv (mTransformSlot, 1, 0, inTrans[0]);
		
	}
	
	
}
