#ifndef RENDERER_OPENGL_TEXTURE_H
#define RENDERER_OPENGL_TEXTURE_H


#include "renderer/opengl/OGL.h"
#include "renderer/common/Texture.h"


namespace lime {
	
	
	class OpenGLTexture : public Texture {
		
		public:
			
			OpenGLTexture (Surface *inSurface, unsigned int inFlags);
			~OpenGLTexture ();
			
			void Bind (class Surface *inSurface, int inSlot);
			void BindFlags (bool inRepeat, bool inSmooth);
			UserPoint PixelToTex (const UserPoint &inPixels);
			UserPoint TexToPaddedTex (const UserPoint &inTex);
			
			bool mCanRepeat;
			int mPixelHeight;
			int mPixelWidth;
			bool mRepeat;
			bool mSmooth;
			int mTextureHeight;
			GLuint mTextureID;
			int mTextureWidth;
		
	};
	
	
}


#endif
