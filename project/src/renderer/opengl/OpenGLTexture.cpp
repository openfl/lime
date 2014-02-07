#include "renderer/opengl/OpenGLTexture.h"


namespace lime {
	
	
	static int *sAlpha16Table = 0;
	
	bool gFullNPO2Support = false;
	bool gPartialNPO2Support = false;
	
	
	bool NonPO2Supported (bool inNotRepeating) {
		
		static bool tried = false;
		
		//OpenGL 2.0 introduced non PO2 as standard, in 2004 - safe to assume it exists on PC
		#ifdef FORCE_NON_PO2
		return true;
		#endif
		
		if (!tried) {
			
			tried = true;
			const char* extensions = (char*)glGetString (GL_EXTENSIONS);
			
			gFullNPO2Support = strstr (extensions, "ARB_texture_non_power_of_two") != 0;
			
			if (!gFullNPO2Support) {
				
				gPartialNPO2Support = strstr (extensions, "GL_APPLE_texture_2D_limited_npot") != 0;
				
			}
			
			//printf("Full non-PO2 support : %d\n", gFullNPO2Support);
			//printf("Partial non-PO2 support : %d\n", gPartialNPO2Support);
			
		}
		
		return (gFullNPO2Support || (gPartialNPO2Support && inNotRepeating));
		
	}
	
	
	void RGBX_to_RGB565 (uint8 *outDest, const uint8 *inSrc, int inPixels) {
		
		unsigned short *dest = (unsigned short *)outDest;
		const uint8 *src = inSrc;
		for (int x = 0; x < inPixels; x++) {
			
			*dest++ = ((src[0] << 8) & 0xf800) | ((src[1] << 3) & 0x07e0) | ((src[2] >> 3));
			src += 4;
			
		}
		
	}
	
	
	void RGBA_to_RGBA4444 (uint8 *outDest, const uint8 *inSrc, int inPixels) {
		
		unsigned short *dest = (unsigned short *)outDest;
		const uint8 *src = inSrc;
		for (int x = 0; x < inPixels; x++) {
			
			*dest++ = ((src[0] << 8) & 0xf000) | ((src[1] << 4) & 0x0f00) | ((src[2]) & 0x00f0) | ((src[3] >> 4));
			src += 4;
			
		}
		
	}
	
	
	int *getAlpha16Table () {
		
		if (sAlpha16Table == 0) {
			
			sAlpha16Table = new int[256];
			
			for (int a = 0; a < 256; a++) {
				
				sAlpha16Table[a] = a * (1 << 16) / 255;
				
			}
			
		}
		
		return sAlpha16Table;
		
	}
	
	
	OpenGLTexture::OpenGLTexture (Surface *inSurface, unsigned int inFlags) {
		
		mPixelWidth = inSurface->Width ();
		mPixelHeight = inSurface->Height ();
		mDirtyRect = Rect (0, 0);
		mContextVersion = gTextureContextVersion;
		
		bool non_po2 = NonPO2Supported (inFlags & SURF_FLAGS_NOT_REPEAT_IF_NON_PO2);
		//printf("Using non-power-of-2 texture %d\n",non_po2);
		
		int w = non_po2 ? mPixelWidth : UpToPower2 (mPixelWidth);
		int h = non_po2 ? mPixelHeight : UpToPower2 (mPixelHeight);
		mCanRepeat = IsPower2 (w) && IsPower2 (h);
		
		//__android_log_print(ANDROID_LOG_ERROR, "lime",	"NewTexure %d %d", w, h);
		
		mTextureWidth = w;
		mTextureHeight = h;
		bool usePreAlpha = inFlags & SURF_FLAGS_USE_PREMULTIPLIED_ALPHA;
		bool hasPreAlpha = inFlags & SURF_FLAGS_HAS_PREMULTIPLIED_ALPHA;
		int *multiplyAlpha = usePreAlpha && !hasPreAlpha ? getAlpha16Table () : 0;
		
		bool copy_required = inSurface->GetBase () && (w != mPixelWidth || h != mPixelHeight || multiplyAlpha);
		
		Surface *load = inSurface;
		
		uint8 *buffer = 0;
		PixelFormat fmt = inSurface->Format ();
		GLuint store_format = (fmt == pfAlpha ? GL_ALPHA : GL_RGBA);
		int pixels = GL_UNSIGNED_BYTE;
		int gpuFormat = inSurface->GPUFormat ();
		
		if (!inSurface->GetBase ()) {
			
			if (gpuFormat != fmt)
				switch (gpuFormat) {
					
					case pfARGB4444: pixels = GL_UNSIGNED_SHORT_4_4_4_4; break;
					case pfRGB565: pixels = GL_UNSIGNED_SHORT_5_6_5; break;
					default: pixels = gpuFormat;
					
				}
			
		} else if (gpuFormat == pfARGB4444) {
			
			pixels = GL_UNSIGNED_SHORT_4_4_4_4;
			buffer = (uint8 *)malloc (mTextureWidth * mTextureHeight * 2);
			for (int y = 0; y < mPixelHeight; y++)
				RGBA_to_RGBA4444 (buffer + y * mTextureWidth * 2, inSurface->Row (y), mPixelWidth);
			
		} else if ( gpuFormat == pfRGB565) {
			
			pixels = GL_UNSIGNED_SHORT_5_6_5;
			buffer = (uint8 *)malloc (mTextureWidth * mTextureHeight * 2);
			for (int y = 0; y < mPixelHeight; y++)
				RGBX_to_RGB565 (buffer + y * mTextureWidth * 2, inSurface->Row (y), mPixelWidth);
			
		} else if (copy_required) {
			
			int pw = (inSurface->Format () == pfAlpha ? 1 : 4);
			buffer = (uint8 *)malloc (pw * mTextureWidth * mTextureHeight);
			
			for (int y = 0; y < mPixelHeight; y++) {
				
				const uint8 *src = inSurface->Row (y);
				uint8 *b = buffer + (mTextureWidth * pw * y);
				
				if (multiplyAlpha) {
					
					for (int x = 0; x < mPixelWidth; x++) {
						
						int a16 = multiplyAlpha[src[3]];
						b[0] = (src[0] * a16) >> 16;
						b[1] = (src[1] * a16) >> 16;
						b[2] = (src[2] * a16) >> 16;
						b[3] = src[3];
						b += 4;
						src += 4;
						
					}
					
				} else {
					
					memcpy (b, src, mPixelWidth * pw);
					b += mPixelWidth * pw;
					
				}
				
				// Duplicate last pixel to help with bilinear interpolation
				if (w > mPixelWidth)
					memcpy (b, buffer + ((mPixelWidth - 1) * pw), pw);
				
			}
			
			// Duplicate last Row to help with bilinear interpolation
			if (h != mPixelHeight) {
				
				uint8 *b = buffer + (mTextureWidth * pw * mPixelHeight);
				uint8 *b0 = b - (mTextureWidth * pw);
				memcpy (b, b0, (mPixelWidth + (w != mPixelWidth)) * pw);
				
			}
			
		} else {
			
			buffer = (uint8 *)inSurface->Row (0);
			
		}
		
		
		glGenTextures (1, &mTextureID);
		// __android_log_print(ANDROID_LOG_ERROR, "lime", "CreateTexture %d (%dx%d)",
		//	mTextureID, mPixelWidth, mPixelHeight);
		glBindTexture (GL_TEXTURE_2D, mTextureID);
		mRepeat = mCanRepeat;
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, mRepeat ? GL_REPEAT : GL_CLAMP_TO_EDGE);
		
		glTexImage2D (GL_TEXTURE_2D, 0, store_format, w, h, 0, store_format, pixels, buffer);
		
		if (buffer && buffer != inSurface->Row (0))
			free (buffer);
		
		mSmooth = true;
		
		#ifndef LIME_GLES
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);
		#endif
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		
		// TODO: Need replacement call for GLES2?
		#ifdef GPH
		glTexEnvx (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
		#endif
		
		#ifndef LIME_FORCE_GLES2
		//glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
		#endif
		
		//int err = glGetError();
		//printf ("GL texture error: %i", err);
		
	}
	
	
	OpenGLTexture::~OpenGLTexture () {
		
		if (mTextureID && mContextVersion == gTextureContextVersion && HardwareContext::current) {
			
			//__android_log_print(ANDROID_LOG_ERROR, "lime", "DeleteTexture %d (%dx%d)",
			//mTextureID, mPixelWidth, mPixelHeight);
			HardwareContext::current->DestroyNativeTexture ((void *)(size_t)mTextureID);
			
		}
		
	}
	
	
	void OpenGLTexture::Bind (class Surface *inSurface, int inSlot) {
		
		if (inSlot >= 0 && &glActiveTexture) {
			
			glActiveTexture (GL_TEXTURE0 + inSlot);
			
		}
		
		glBindTexture (GL_TEXTURE_2D, mTextureID);
		if (gTextureContextVersion != mContextVersion) {
			
			mContextVersion = gTextureContextVersion;
			mDirtyRect = Rect (inSurface->Width (), inSurface->Height ());
			
		}
		
		if (inSurface->GetBase () && mDirtyRect.HasPixels ()) {
			
			//__android_log_print(ANDROID_LOG_INFO, "lime", "UpdateDirtyRect! %d %d",
			//mPixelWidth, mPixelHeight);
			
			PixelFormat fmt = inSurface->Format ();
			int pw = inSurface->BytesPP ();
			GLuint store_format = (fmt == pfAlpha ? GL_ALPHA : GL_RGBA);
			glGetError ();
			
			int x0 = mDirtyRect.x;
			int y0 = mDirtyRect.y;
			int dw = mDirtyRect.w;
			int dh = mDirtyRect.h;
			
			#if defined(LIME_GLES)
			
			uint8 *buffer = 0;
			if (pw == 1) {
				
				// Make unpack align a multiple of 4 ...
				if (inSurface->Width () > 3) {
					
					dw = (dw + 3) & ~3;
					if (x0 + dw > inSurface->Width ()) {
						
						x0 = inSurface->Width () - dw;
						
					}
					
				}
				
				const uint8 *p0 = inSurface->Row (y0) + (x0 * pw);
				buffer = (uint8 *)malloc (pw * dw * dh);
				
				for (int y = 0; y < dh; y++) {
					
					memcpy (buffer + (y * dw), p0, dw);
					p0 += inSurface->GetStride ();
					
				}
				
			} else {
				
				// TODO: pre-alpha ?
				buffer = (uint8 *)malloc (pw * dw * dh);
				const uint8 *p0 = inSurface->Row (y0) + (x0 * pw);
				
				for (int y = 0; y < mDirtyRect.h; y++) {
					
					memcpy (buffer + (y * dw * pw), p0, dw * pw);
					p0 += inSurface->GetStride ();
					
				}
				
			}
			
			glTexSubImage2D (GL_TEXTURE_2D, 0, x0, y0, dw, dh, store_format, GL_UNSIGNED_BYTE, buffer);
			free (buffer);
			
			#else
			
			const uint8 *p0 = inSurface->Row (y0) + (x0 * pw);
			glPixelStorei (GL_UNPACK_ROW_LENGTH, inSurface->Width ());
			glTexSubImage2D (GL_TEXTURE_2D, 0, x0, y0, dw, dh, store_format, GL_UNSIGNED_BYTE, p0);
			glPixelStorei (GL_UNPACK_ROW_LENGTH, 0);
			
			#endif
			
			int err = glGetError ();
			if (err != GL_NO_ERROR)
				ELOG ("GL Error: %d", err);
			mDirtyRect = Rect ();
			
		}
		
	}
	
	
	void OpenGLTexture::BindFlags (bool inRepeat, bool inSmooth) {
		
		if (!mCanRepeat) inRepeat = false;
		if (mRepeat != inRepeat) {
			
			mRepeat = inRepeat;
			if (mRepeat) {
				
				glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
				glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
				
			} else {
				
				glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
				glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
				
			}
			
		}
		
		if (mSmooth != inSmooth) {
			
			mSmooth = inSmooth;
			if (mSmooth) {
				
				glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
				glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
				
			} else {
				
				glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
				glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
				
			}
			
		}
		
	}
	
	
	UserPoint OpenGLTexture::PixelToTex (const UserPoint &inPixels) {
		
		return UserPoint (inPixels.x / mTextureWidth, inPixels.y / mTextureHeight);
		
	}
	
	
	UserPoint OpenGLTexture::TexToPaddedTex (const UserPoint &inTex) {
		
		return UserPoint (inTex.x * mPixelWidth / mTextureWidth, inTex.y * mPixelHeight / mTextureHeight);
		
	}
	
	
}
