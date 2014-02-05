#ifndef LIME_PIXEL_H
#define LIME_PIXEL_H

// The order or RGB or BGR is determined to the primary surface's
//  native order - this allows most transfers to be donw without swapping R & B
// When rendering from a source to a dest, the source is swapped to match in
//  the blending code.

namespace lime
{

extern bool gC0IsRed;


enum PixelFormat
{
   pfXRGB         = 0x00,
   pfARGB         = 0x01,
   pfXRGBSwap     = 0x02,
   pfARGBSwap     = 0x03,
   pfAlpha        = 0x04,
   pfHardware     = 0x10,
   pfARGB4444     = 0x11,
   pfRGB565       = 0x12,
   
   pfHasAlpha     = 0x01,
   pfSwapRB       = 0x02,
};


typedef unsigned char Uint8;



struct ARGB
{
   inline ARGB() { }
   inline ARGB(int inRGBA)
   {
      c1 = (inRGBA>>8) & 0xff;
      if (gC0IsRed)
      {
         c0 = (inRGBA>>16) & 0xff;
         c2 = (inRGBA) & 0xff;
      }
      else
      {
         c2 = (inRGBA>>16) & 0xff;
         c0 = (inRGBA) & 0xff;
      }
      a = (inRGBA>>24);
   }
   inline ARGB(int inRGB,int inA)
   {
      c1 = (inRGB>>8) & 0xff;
      if (gC0IsRed)
      {
         c0 = (inRGB>>16) & 0xff;
         c2 = (inRGB) & 0xff;
      }
      else
      {
         c2 = (inRGB>>16) & 0xff;
         c0 = (inRGB) & 0xff;
      }
      a = inA;
   }
   inline ARGB(int inRGB,float inA)
   {
      c1 = (inRGB>>8) & 0xff;
      if (gC0IsRed)
      {
         c0 = (inRGB>>16) & 0xff;
         c2 = (inRGB) & 0xff;
      }
      else
      {
         c2 = (inRGB>>16) & 0xff;
         c0 = (inRGB) & 0xff;
      }
      int alpha = 255.9 * inA;
      a = alpha<0 ? 0 : alpha >255 ? 255 : alpha;
   }

   inline int ToInt() const
   {
      if (gC0IsRed)
         return (ival & 0xff00ff00) | (c0<<16) | c2;

      return ival;
   }

   inline ARGB Swapped() const
   {
      ARGB result(*this);
      result.ival = SwappedIVal();
      return result;
   }

   inline int SwappedIVal() const
         { return (ival & 0xff00ff00) |  ((ival&0xff)<<16) | ( (ival&0xff0000)>>16) ; }

   static inline int Swap(int inVal)
         { return (inVal & 0xff00ff00) |  ((inVal&0xff)<<16) | ( (inVal&0xff0000)>>16) ; }


   inline void Set(int inVal) { ival = inVal; }

   inline void SetRGB(int inVal)
   {
      c1 = (inVal>>8) & 0xff;
      if (gC0IsRed)
      {
         c0 = (inVal>>16) & 0xff;
         c2 = (inVal) & 0xff;
      }
      else
      {
         c0 = (inVal) & 0xff;
         c2 = (inVal>>16) & 0xff;
      }
      a = 255;
   }
   inline void SetRGBA(int inVal)
   {
      c1 = (inVal>>8) & 0xff;
      if (gC0IsRed)
      {
         c0 = (inVal>>16) & 0xff;
         c2 = (inVal) & 0xff;
      }
      else
      {
         c0 = (inVal>>16) & 0xff;
         c2 = (inVal) & 0xff;
      }
      a = (inVal>>24);
   }

   inline void SetSwapRGB(const ARGB &inRGB)
   {
      c0 = inRGB.c2;
      c1 = inRGB.c1;
      c2 = inRGB.c0;
   }
   inline void SetSwapRGBA(const ARGB &inRGB)
   {
      c0 = inRGB.c2;
      c1 = inRGB.c1;
      c2 = inRGB.c0;
      a = inRGB.a;
   }

   void SwapRB() { Uint8 tmp = c2; c2 = c0; c0 = tmp; }


   template<bool SWAP_RB,bool DEST_ALPHA>
   inline void Blend(const ARGB &inVal)
   {
      int A = inVal.a + (inVal.a>>7);
      if (A>5)
      {
         // Replace if input is full, or we are empty
         if (A>250 || (DEST_ALPHA && a<5) )
         {
            if (SWAP_RB)
            {
               if (DEST_ALPHA)
                  SetSwapRGBA(inVal);
               else
                  SetSwapRGB(inVal);
            }
            else
               ival = inVal.ival;
         }
         // Our alpha is implicitly 256 ...
         else if (!DEST_ALPHA)
         {
            int f = 256-A;
            if (SWAP_RB)
            {
               c0 = (A*inVal.c2 + f*c0)>>8;
               c1 = (A*inVal.c1 + f*c1)>>8;
               c2 = (A*inVal.c0 + f*c2)>>8;
            }
            else
            {
               c0 = (A*inVal.c0 + f*c0)>>8;
               c1 = (A*inVal.c1 + f*c1)>>8;
               c2 = (A*inVal.c2 + f*c2)>>8;
            }
         }
         else
         {
            int alpha16 = ((a + A)<<8) - a*A;
            int f = (256-A) * a;
            A<<=8;
            if (SWAP_RB)
            {
               c0 = (A*inVal.c2 + f*c0)/alpha16;
               c1 = (A*inVal.c1 + f*c1)/alpha16;
               c2 = (A*inVal.c0 + f*c2)/alpha16;
            }
            else
            {
               c0 = (A*inVal.c0 + f*c0)/alpha16;
               c1 = (A*inVal.c1 + f*c1)/alpha16;
               c2 = (A*inVal.c2 + f*c2)/alpha16;
            }
            a = alpha16>>8;
         }
      }
   }


   inline void QBlend(ARGB inVal)
   {
      int A = inVal.a + (inVal.a>>7);
      int f = (256-A);
      c0 = (A*inVal.c0 + f*c0)>>8;
      c1 = (A*inVal.c1 + f*c1)>>8;
      c2 = (A*inVal.c2 + f*c2)>>8;
   }

   inline void QBlendA(ARGB inVal)
   {
      int A = inVal.a + (inVal.a>>7);
      int alpha16 = ((a + A)<<8) - a*A;
      int f = (256-A) * a;
      A<<=8;
      c0 = (A*inVal.c0 + f*c0)/alpha16;
      c1 = (A*inVal.c1 + f*c1)/alpha16;
      c2 = (A*inVal.c2 + f*c2)/alpha16;
      a = alpha16>>8;
   }



   inline void TBlend_00(const ARGB &inVal) { Blend<false,false>(inVal); }
   inline void TBlend_01(const ARGB &inVal) { Blend<false,true >(inVal); }
   inline void TBlend_10(const ARGB &inVal) { Blend<true ,false>(inVal); }
   inline void TBlend_11(const ARGB &inVal) { Blend<true ,true >(inVal); }


   union
   {
      struct { Uint8 c0,c1,c2,a; };
      unsigned int  ival;
   };
};


inline void BlendAlpha(Uint8 &ioDest, Uint8 inSrc)
{
   if (inSrc)
   {
      if (inSrc==255)
         ioDest = 255;
      else
         ioDest = 255 - ((255 - inSrc) * (255-ioDest) >> 8);
   }
}

inline void BlendAlpha(Uint8 &ioDest, const ARGB &inSrc)
{
   if (inSrc.a)
   {
      if (inSrc.a==255)
         ioDest = 255;
      else
         ioDest = 255 - ((255 - inSrc.a) * (255-ioDest) >> 8);
   }
}


inline void QBlendAlpha(Uint8 &ioDest, Uint8 inSrc)
{
   ioDest = 255 - ((255 - inSrc) * (255-ioDest) >> 8);
}




} // end namespace lime

#endif
