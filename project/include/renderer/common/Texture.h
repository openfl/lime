#ifndef RENDERER_TEXTURE_H
#define RENDERER_TEXTURE_H


namespace nme {
	
	
	extern int gTextureContextVersion;
	
	
	class Texture {
		
		public:
			
			Texture () : mContextVersion (gTextureContextVersion) {}
			virtual ~Texture() {};
			
			virtual void Bind (class Surface *inSurface, int inSlot) = 0;
			virtual void BindFlags (bool inRepeat, bool inSmooth) = 0;
			virtual UserPoint PixelToTex (const UserPoint &inPixels) = 0;
			virtual UserPoint TexToPaddedTex (const UserPoint &inPixels) = 0;
			
			void Dirty (const Rect &inRect);
			bool IsCurrentVersion () { return mContextVersion == gTextureContextVersion; }
			bool IsDirty () { return mDirtyRect.HasPixels (); }
			
			int  mContextVersion;
			Rect mDirtyRect;
		
	};
	
	
};


#endif
