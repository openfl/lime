#include <Display.h>
#include "renderer/common/Surface.h"
#include "renderer/common/SimpleSurface.h"
#include "renderer/common/AutoSurfaceRender.h"
#include "renderer/common/BitmapCache.h"
#include <math.h>

#ifndef M_PI
#define M_PI 3.1415926535897932385
#endif

#ifdef ANDROID
#include <android/log.h>
#endif

namespace lime
{

unsigned int gDisplayRefCounting = drDisplayChildRefs;
static int sgDisplayObjID = 0;

bool gMouseShowCursor = true;

// --- DisplayObject ------------------------------------------------

DisplayObject::DisplayObject(bool inInitRef) : Object(inInitRef)
{
   mParent = 0;
   mGfx = 0;
   mDirtyFlags = 0;
   x = y = 0;
   scaleX = scaleY = 1.0;
   rotation = 0;
   visible = true;
   mBitmapCache = 0;
   cacheAsBitmap = false;
   pedanticBitmapCaching = false;
   blendMode = bmNormal;
   pixelSnapping = psNone;
   opaqueBackground = 0;
   mouseEnabled = true;
   needsSoftKeyboard = false;
   mMask = 0;
   mIsMaskCount = 0;
   mBitmapGfx = 0;
   id = sgDisplayObjID++ & 0x7fffffff;
   if (id==0)
      id = sgDisplayObjID++;
}

DisplayObject::~DisplayObject()
{
   if (mGfx)
   {
      mGfx->removeOwner(this);
      mGfx->DecRef();
   }
   delete mBitmapCache;
   if (mMask)
      setMask(0);
   ClearFilters();
}

Graphics &DisplayObject::GetGraphics()
{
   if (!mGfx)
      mGfx = new Graphics(this,true);
   return *mGfx;
}

bool DisplayObject::IsCacheDirty()
{
   if (mDirtyFlags & dirtCache)
      return true;
   return mGfx && mGfx->Version() != mBitmapGfx;
}

void DisplayObject::ClearCacheDirty()
{
   mDirtyFlags &= ~dirtCache;
   mBitmapGfx = mGfx ? mGfx->Version() : 0;
}


void DisplayObject::SetParent(DisplayObjectContainer *inParent)
{
   IncRef();

   if (gDisplayRefCounting &drDisplayChildRefs)
   {
      if (mParent && !inParent)
         DecRef();
      else if (!mParent && inParent)
         IncRef();
   }

   if (mParent)
   {
      Stage *stage = getStage();
      if (stage)
         stage->RemovingFromStage(this);
      mParent->RemoveChildFromList(this);
      mParent->DirtyCache();
   }
   mParent = inParent;
   DirtyCache();

   DecRef();
}

DisplayObject *DisplayObject::getParent()
{
   return mParent;
}

Stage  *DisplayObject::getStage()
{
   if (!mParent)
      return 0;
   return mParent->getStage();
}



UserPoint DisplayObject::GlobalToLocal(const UserPoint &inPoint)
{
   Matrix m = GetFullMatrix(false);
   return m.ApplyInverse(inPoint);
}

UserPoint DisplayObject::LocalToGlobal(const UserPoint &inPoint)
{
   Matrix m = GetFullMatrix(false);
   return m.Apply(inPoint.x,inPoint.y);
}



void DisplayObject::setCacheAsBitmap(bool inVal)
{
   cacheAsBitmap = inVal;
}


void DisplayObject::setPixelSnapping(int inVal)
{
   if (pixelSnapping!=inVal)
   {
      pixelSnapping = inVal;
      DirtyCache();
   }
}


void DisplayObject::setVisible(bool inVal)
{
   if (visible!=inVal)
   {
      visible = inVal;
      DirtyCache(!visible);
   }
}




void DisplayObject::CheckCacheDirty(bool inForHardware)
{
   if (mBitmapCache && IsCacheDirty())
   {
      delete mBitmapCache;
      mBitmapCache = 0;
   }

   if (!IsBitmapRender(inForHardware) && !IsMask() && mBitmapCache)
   {
      delete mBitmapCache;
      mBitmapCache = 0;
   }
}

bool DisplayObject::IsBitmapRender(bool inHardware)
{
   return cacheAsBitmap || blendMode!=bmNormal || NonNormalBlendChild() || filters.size() ||
                                      (inHardware && mMask);
}

void DisplayObject::SetBitmapCache(BitmapCache *inCache)
{
   delete mBitmapCache;
   mBitmapCache = inCache;
}




void DisplayObject::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   if (inState.mPhase==rpHitTest && !mouseEnabled )
      return;

   if (mGfx && inState.mPhase!=rpBitmap)
   {
      bool hit = false;
      if (scale9Grid.HasPixels())
      {
         RenderState state(inState);

         const Extent2DF &ext0 = mGfx->GetExtent0(0);
         Scale9 s9;
         s9.Activate(scale9Grid,ext0,scaleX,scaleY);
         state.mTransform.mScale9 = &s9;

         Matrix unscaled = state.mTransform.mMatrix->Mult( Matrix(1.0/scaleX,1.0/scaleY) );
         state.mTransform.mMatrix = &unscaled;

         hit = mGfx->Render(inTarget,state);
         
         if (IsInteractive())
            inState.mHitResult = state.mHitResult;
         else
            inState.mHitResult = state.mHitResult != NULL ? mParent : NULL;
      }
      else if (mGfx)
      {
         hit = mGfx->Render(inTarget,inState);
      }

      if (hit)
      {
         if (IsInteractive())
            inState.mHitResult = this;
         else
            inState.mHitResult = mParent;
      }
   }
}


bool DisplayObject::HitBitmap( const RenderTarget &inTarget, const RenderState &inState )
{
   if (!mBitmapCache)
      return false;
   return mBitmapCache->HitTest(inState.mClipRect.x, inState.mClipRect.y);
}

void DisplayObject::RenderBitmap( const RenderTarget &inTarget, const RenderState &inState )
{
   if (!mBitmapCache)
      return;

   ImagePoint offset;
   if (inState.mMask)
   {
      BitmapCache *mask = inState.mMask;
      ImagePoint buffer;
      mask->PushTargetOffset(inState.mTargetOffset,buffer);
      mBitmapCache->Render(inTarget,inState.mClipRect,mask,blendMode);
      mask->PopTargetOffset(buffer);
   }
   else
   {
      mBitmapCache->Render(inTarget,inState.mClipRect,0,blendMode);
   }
}

void DisplayObject::DebugRenderMask( const RenderTarget &inTarget, const RenderState &inState )
{
   if (mMask)
      mMask->RenderBitmap(inTarget,inState);
}




void DisplayObject::DirtyCache(bool inParentOnly)
{
   if (!(mDirtyFlags & dirtCache))
   {
      if (!inParentOnly)
         mDirtyFlags |= dirtCache;
      if (mParent)
         mParent->DirtyCache(false);
   }
}

Matrix DisplayObject::GetFullMatrix(bool inStageScaling)
{
   if (mParent)
     return mParent->GetFullMatrix(inStageScaling).Mult(GetLocalMatrix().Translated(-scrollRect.x,-scrollRect.y));
   return GetLocalMatrix().Translated(-scrollRect.x,-scrollRect.y);
}

void DisplayObject::setMatrix(const Matrix &inMatrix)
{
   mLocalMatrix = inMatrix;
   DirtyCache();
   mDirtyFlags |= dirtDecomp;
   mDirtyFlags &= ~dirtLocalMatrix;
}


ColorTransform DisplayObject::GetFullColorTransform()
{
  if (mParent)
  {
     ColorTransform result;
     result.Combine(mParent->GetFullColorTransform(),colorTransform);
     return result;
  }
  return colorTransform;
}


void DisplayObject::setColorTransform(const ColorTransform &inTrans)
{
   colorTransform = inTrans;
   DirtyCache();
}



Matrix &DisplayObject::GetLocalMatrix()
{
   if (mDirtyFlags & dirtLocalMatrix)
   {
      mDirtyFlags ^= dirtLocalMatrix;
      double r = rotation*M_PI/-180.0;
      double c = cos(r);
      double s = sin(r);
      mLocalMatrix.m00 = c*scaleX;
      mLocalMatrix.m01 = s*scaleY;
      mLocalMatrix.m10 = -s*scaleX;
      mLocalMatrix.m11 = c*scaleY;
      mLocalMatrix.mtx = x;
      mLocalMatrix.mty = y;
   }
   return mLocalMatrix;
}

void DisplayObject::GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForScreen,bool inIncludeStroke)
{
   if (mGfx)
      outExt.Add(mGfx->GetSoftwareExtent(inTrans,inIncludeStroke));
}




void DisplayObject::UpdateDecomp()
{
   if (mDirtyFlags & dirtDecomp)
   {
      mDirtyFlags ^= dirtDecomp;
      x = mLocalMatrix.mtx;
      y = mLocalMatrix.mty;
      scaleX = sqrt( mLocalMatrix.m00*mLocalMatrix.m00 +
                     mLocalMatrix.m10*mLocalMatrix.m10 );
      scaleY = sqrt( mLocalMatrix.m01*mLocalMatrix.m01 +
                     mLocalMatrix.m11*mLocalMatrix.m11 );
      rotation = scaleX>0 ? atan2( mLocalMatrix.m01, mLocalMatrix.m00 ) :
                 scaleY>0 ? atan2( mLocalMatrix.m11, mLocalMatrix.m10 ) : 0.0;
      //printf("Rotation = %f\n",rotation);
      /*
      scaleX = cos(rotation) * mLocalMatrix.m00 +
               -sin(rotation) * mLocalMatrix.m10;
      scaleY = sin(rotation) * mLocalMatrix.m01 + 
               cos(rotation) * mLocalMatrix.m11;
               */
      //printf("scale = %f,%f\n", scaleX, scaleY );
      rotation *= 180.0/-M_PI;
   }
}

double DisplayObject::getMouseX()
{
   Stage *s = getStage();
   if (!s)
      s = Stage::GetCurrent();
   UserPoint p = s->getMousePos();
   UserPoint result = GetFullMatrix(true).ApplyInverse(p);
   return result.x;
   
}

double DisplayObject::getMouseY()
{
   Stage *s = getStage();
   if (!s)
      s = Stage::GetCurrent();
   UserPoint p = s->getMousePos();
   UserPoint result = GetFullMatrix(true).ApplyInverse(p);
   return result.y;
}




double DisplayObject::getX()
{
   UpdateDecomp();
   return x;
}

void DisplayObject::setX(double inValue)
{
   UpdateDecomp();
   if (x!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      x = inValue;
      DirtyCache(true);
   }
}


void DisplayObject::setScaleX(double inValue)
{
   UpdateDecomp();
   if (scaleX!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      scaleX = inValue;
      DirtyCache();
   }
}

double DisplayObject::getScaleX()
{
   UpdateDecomp();
   return scaleX;
}


void DisplayObject::setWidth(double inValue)
{
   Transform trans0;
   Matrix rot;
   if (rotation)
      rot.Rotate(rotation);
   trans0.mMatrix = &rot;
   Extent2DF ext0;
   GetExtent(trans0,ext0,false,true);

   if (!ext0.Valid())
      return;
   if (ext0.Width()==0)
      return;

   scaleX = inValue/ext0.Width();
   scaleY = ext0.Height()==0.0 ? 1.0 : getHeight() / ext0.Height();
   mDirtyFlags |= dirtLocalMatrix;
}

double DisplayObject::getWidth()
{
   Transform trans;
   trans.mMatrix = &GetLocalMatrix();
   Extent2DF ext;
   GetExtent(trans,ext,false,true);

   if (!ext.Valid())
   {
      return 0;
   }

   return ext.Width();
}


void DisplayObject::setHeight(double inValue)
{
   Transform trans0;
   Matrix rot;
   if (rotation)
      rot.Rotate(rotation);
   trans0.mMatrix = &rot;
   Extent2DF ext0;
   GetExtent(trans0,ext0,false,true);

   if (!ext0.Valid())
      return;
   if (ext0.Height()==0)
      return;

   scaleX = ext0.Width()==0.0 ? 1.0 : getWidth() / ext0.Width();
   scaleY = inValue/ext0.Height();
   mDirtyFlags |= dirtLocalMatrix;
}

double DisplayObject::getHeight()
{
   Transform trans;
   trans.mMatrix = &GetLocalMatrix();
   Extent2DF ext;
   GetExtent(trans,ext,false,true);
   if (!ext.Valid())
      return 0;

   return ext.Height();
}


double DisplayObject::getScaleY()
{
   UpdateDecomp();
   return scaleY;
}



double DisplayObject::getY()
{
   UpdateDecomp();
   return y;
}

void DisplayObject::setY(double inValue)
{
   UpdateDecomp();
   if (y!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      y = inValue;
      DirtyCache(true);
   }
}

void DisplayObject::setScaleY(double inValue)
{
   UpdateDecomp();
   if (scaleY!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      scaleY = inValue;
      DirtyCache();
   }
}

void DisplayObject::setScale9Grid(const DRect &inRect)
{
   scale9Grid = inRect;
   DirtyCache();
}

void DisplayObject::setScrollRect(const DRect &inRect)
{
   scrollRect = inRect;
   UpdateDecomp();
   mDirtyFlags |= dirtLocalMatrix;
   DirtyCache();
}



double DisplayObject::getRotation()
{
   UpdateDecomp();
   return rotation;
}

void DisplayObject::setRotation(double inValue)
{
   UpdateDecomp();
   if (rotation!=inValue)
   {
      mDirtyFlags |= dirtLocalMatrix;
      rotation = inValue;
      DirtyCache();
   }
}


void DisplayObject::ChangeIsMaskCount(int inDelta)
{
   if (inDelta>0)
   {
      IncRef();
      mIsMaskCount++;
   }
   else
   {
      mIsMaskCount--;
      if (!mIsMaskCount)
         SetBitmapCache(0);
      DecRef();
   }
}


void DisplayObject::setMask(DisplayObject *inMask)
{
   if (inMask)
      inMask->ChangeIsMaskCount(1);
   if (mMask)
      mMask->ChangeIsMaskCount(-1);

   mMask = inMask;
   DirtyCache();
}

void DisplayObject::setAlpha(double inAlpha)
{
   colorTransform.alphaMultiplier = inAlpha;
   colorTransform.alphaOffset = 0;
   DirtyCache();
}

void DisplayObject::setBlendMode(int inMode)
{
   if (inMode!=blendMode)
   {
      blendMode = (BlendMode)inMode;
      DirtyCache();
   }
}



void DisplayObject::setFilters(FilterList &inFilters)
{
   ClearFilters();
   filters = inFilters;
   DirtyCache();
}

void DisplayObject::setOpaqueBackground(uint32 inBG)
{
   opaqueBackground = inBG;
   DirtyCache();
}


void DisplayObject::ClearFilters()
{
   for(int i=0;i<filters.size();i++)
      delete filters[i];
   filters.resize(0);
}



void DisplayObject::Focus()
{
#if defined(IPHONE) || defined (ANDROID) || defined(WEBOS) || defined(BLACKBERRY) || defined(TIZEN)
  if (needsSoftKeyboard)
  {
     Stage *stage = getStage();
     if (stage)
        stage->EnablePopupKeyboard(true);
  }
#endif
}

void DisplayObject::Unfocus()
{
#if defined(IPHONE) || defined (ANDROID) || defined(WEBOS) || defined(BLACKBERRY) || defined(TIZEN)
  if (needsSoftKeyboard)
  {
     Stage *stage = getStage();
     if (stage)
        stage->EnablePopupKeyboard(false);
  }
#endif
}

// --- DirectRenderer ------------------------------------------------

HardwareContext *gDirectRenderContext = 0;

void DirectRenderer::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   if (inState.mPhase==rpRender && inTarget.IsHardware())
   {
      gDirectRenderContext = inTarget.mHardware;
      Rect clip = inState.mClipRect;
      clip.y = inTarget.mHardware->Height() - clip.y - clip.h;
      onRender(renderHandle,clip,inState.mTransform);
      gDirectRenderContext = 0;
   }
}


// --- SimpleButton ------------------------------------------------
SimpleButton::SimpleButton(bool inInitRef) : DisplayObjectContainer(inInitRef),
        enabled(true), useHandCursor(true), mMouseState(stateUp)
{
   for(int i=0;i<stateSIZE; i++)
      mState[i] = 0;
}

SimpleButton::~SimpleButton()
{
   for(int i=0;i<stateSIZE; i++)
      if (mState[i])
         mState[i]->DecRef();
}

void SimpleButton::RemoveChildFromList(DisplayObject *inChild)
{
   // This is called by 'setParent'
}


void SimpleButton::setState(int inState, DisplayObject *inObject)
{
   if (inState>=0 && inState<stateSIZE)
   {
       if (inObject)
          inObject->IncRef();
       if (mState[inState])
       {
          bool inMultipleTimes = false;
          for(int i=0;i<stateSIZE;i++)
             if (i!=inState && mState[i]==inObject)
                inMultipleTimes = true;
          if (!inMultipleTimes)
             mState[inState]->SetParent(0);
          mState[inState]->DecRef();
       }
       mState[inState] = inObject;
       if (inObject)
          inObject->SetParent(this);
   }
}


void SimpleButton::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   if (inState.mPhase==rpHitTest)
   {
      if (!mouseEnabled)
         return;
      if (mState[stateHitTest])
      {
          mState[stateHitTest]->Render(inTarget,inState);
          if (inState.mHitResult)
             inState.mHitResult = this;
      }
   }
   else
   {
      DisplayObject *obj = mState[mMouseState];
      if (obj)
         obj->Render(inTarget,inState);
   }
}

void SimpleButton::setMouseState(int inState)
{
   if (mState[inState]!=mState[mMouseState])
       DirtyCache();

   mMouseState = inState;
}

void SimpleButton::GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForScreen, bool inIncludeStroke)
{
   DisplayObject::GetExtent(inTrans,outExt,inForScreen,inIncludeStroke);

   Matrix full;
   Transform trans(inTrans);
   trans.mMatrix = &full;

   for(int i=0;i<stateSIZE;i++)
   {
      if (i == stateHitTest) continue;
      DisplayObject *obj = mState[i];
      if (!obj)
         continue;

      full = inTrans.mMatrix->Mult( obj->GetLocalMatrix() );
      if (inForScreen && obj->scrollRect.HasPixels())
      {
         for(int corner=0;corner<4;corner++)
         {
            double x = (corner & 1) ? obj->scrollRect.w : 0;
            double y = (corner & 2) ? obj->scrollRect.h : 0;
            outExt.Add( full.Apply(x,y) );
         }
      }
      else
         // Seems scroll rects are ignored when calculating extent...
         obj->GetExtent(trans,outExt,inForScreen,inIncludeStroke);
   }
}


bool SimpleButton::IsCacheDirty()
{
   for(int i=0;i<stateSIZE;i++)
      if (mState[i] && mState[i]->IsCacheDirty())
         return true;
   return DisplayObject::IsCacheDirty();
}


void SimpleButton::ClearCacheDirty()
{
   DisplayObject::ClearCacheDirty();
   for(int i=0;i<stateSIZE;i++)
      if (mState[i])
         mState[i]->ClearCacheDirty();
}

bool SimpleButton::NonNormalBlendChild()
{
   for(int i=0;i<stateSIZE;i++)
      if (mState[i] && mState[i]->NonNormalBlendChild())
         return true;
   return false;
}

void SimpleButton::DirtyCache(bool inParentOnly)
{
   DisplayObject::DirtyCache(inParentOnly);
}




// --- DisplayObjectContainer ------------------------------------------------

DisplayObjectContainer::~DisplayObjectContainer()
{
   while(mChildren.size())
      mChildren[0]->SetParent(0);
}

void DisplayObjectContainer::RemoveChildFromList(DisplayObject *inChild)
{
   for(int i=0;i<mChildren.size();i++)
      if (inChild==mChildren[i])
      {
         if (gDisplayRefCounting & drDisplayParentRefs)
            DecRef();
         mChildren.EraseAt(i);
         DirtyCache();
         return;
      }
   // This is an error, I think.
   return;
}

void DisplayObjectContainer::setChildIndex(DisplayObject *inChild,int inNewIndex)
{
   for(int i=0;i<mChildren.size();i++)
      if (inChild==mChildren[i])
      {
         if (inNewIndex<i)
         {
            while(i > inNewIndex)
            {
               mChildren[i] = mChildren[i-1];
               i--;
            }
         }
         // move up ...
         else if (i<inNewIndex)
         {
            while(i < inNewIndex)
            {
               mChildren[i] = mChildren[i+1];
               i++;
            }
         }
         mChildren[inNewIndex] = inChild;
         DirtyCache();
         return;
      }
   // This is an error, I think.
   return;

}

void DisplayObjectContainer::swapChildrenAt(int inChild1, int inChild2)
{
   if (inChild1>=0 && inChild2>=0 &&
        inChild1<mChildren.size() &&  inChild2<mChildren.size() )
   {
      std::swap(mChildren[inChild1],mChildren[inChild2]);
      DirtyCache();
   }
}
 


void DisplayObjectContainer::removeChild(DisplayObject *inChild)
{
   IncRef();
   inChild->SetParent(0);
   DecRef();
   DirtyCache();
}

void DisplayObjectContainer::removeChildAt(int inIndex)
{
   if (inIndex>=0 && inIndex<mChildren.size())
      removeChild( mChildren[inIndex] );
}


void DisplayObjectContainer::addChild(DisplayObject *inChild)
{
   //printf("DisplayObjectContainer::addChild\n");
   IncRef();
   inChild->SetParent(this);

   mChildren.push_back(inChild);
   if (gDisplayRefCounting & drDisplayParentRefs)
      IncRef();

   DirtyCache();
   DecRef();
}

void DisplayObjectContainer::DirtyCache(bool inParentOnly)
{
   if (!(mDirtyFlags & dirtCache))
      DisplayObject::DirtyCache(inParentOnly);
   if (!(mDirtyFlags & dirtExtent))
      DirtyExtent();
}

void DisplayObjectContainer::DirtyExtent()
{
   if (!(mDirtyFlags & dirtExtent))
   {
      mDirtyFlags |= dirtExtent;
      mExtentCache[0].mIsSet = 
       mExtentCache[1].mIsSet = 
        mExtentCache[2].mIsSet = false;
      if (mParent)
         mParent->DirtyExtent();
   }
}

void DisplayObject::DirtyExtent()
{
   mDirtyFlags |= dirtExtent;
   if (mParent)
      mParent->DirtyExtent();
}

void DisplayObject::ClearExtentDirty()
{
   mDirtyFlags &= ~dirtExtent;
}

void DisplayObjectContainer::ClearExtentDirty()
{
   if (mDirtyFlags & dirtExtent)
   {
      mDirtyFlags &= ~dirtExtent;
      for(int c=0;c<mChildren.size();c++)
         mChildren[c]->ClearExtentDirty();
   }
}



bool DisplayObject::CreateMask(const Rect &inClipRect,int inAA)
{
   Transform trans;
   trans.mAAFactor = inAA;
   Matrix m = GetFullMatrix(true);
   trans.mMatrix = &m;
   Scale9 s9;
   if ( scale9Grid.HasPixels() )
   {
      const Extent2DF &ext0 = mGfx->GetExtent0(0);
      s9.Activate(scale9Grid,ext0,scaleX,scaleY);
      trans.mScale9 = &s9;

      m = m.Mult( Matrix(1.0/scaleX,1.0/scaleY) );
   }

   Extent2DF ext;
   GetExtent(trans,ext,false,true);

   Rect rect;
   if (!ext.GetRect(rect,0.999,0.999))
   {
      SetBitmapCache(0);
      return false;
   }

   rect = rect.Intersect(inClipRect);
   if (!rect.HasPixels())
   {
      SetBitmapCache(0);
      return false;
   }


   if (GetBitmapCache())
   {
      // Clear mask if invalid
      if (!GetBitmapCache()->StillGood(trans, rect,0))
      {
         SetBitmapCache(0);
      }
      else
         return true;
   }

   int w = rect.w;
   int h = rect.h;
   //w = UpToPower2(w); h = UpToPower2(h);

   Surface *bitmap = new SimpleSurface(w, h, pfAlpha);
   RenderState state(bitmap,inAA);

   bitmap->IncRef();
   if (opaqueBackground)
      bitmap->Clear(0xffffffff);
   else
   {
      bitmap->Zero();

      AutoSurfaceRender render(bitmap,Rect(rect.w,rect.h));

      state.mTransform = trans;
   
      state.mPhase = rpCreateMask;
      Matrix obj_matrix = m;

      m.Translate(-rect.x, -rect.y );
      Render(render.Target(), state);

      m = obj_matrix;

      ClearCacheDirty();
   }
   
   SetBitmapCache( new BitmapCache(bitmap, trans, rect, false, 0));
   bitmap->DecRef();
   return true;
}



/*
static int level = 0;
struct Leveller
{
   Leveller() { level++; print(); printf(">>>\n"); }
   ~Leveller() { level--; print(); printf(">>>\n"); }
   void print()
   {
      for(int i=0;i<level;i++)
         printf(" ");
   }
};
*/

void DisplayObjectContainer::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   //Leveller level;

   Rect visible_bitmap;

   bool parent_first = inState.mPhase==rpRender || inState.mPhase==rpCreateMask;

   // Render parent first (or at the end) ?
   if (parent_first)
      DisplayObject::Render(inTarget,inState);

   // Render children/build child bitmaps ...
   Matrix full;
   ColorTransform col_trans;
   RenderState state(inState);
   state.mTransform.mMatrix = &full;
   RenderState clip_state(state);

   int first = 0;
   int last = mChildren.size();
   int dir = 1;
   // Build top first when making bitmaps, or doing hit test...
   if (!parent_first)
   {
      first = last - 1;
      last = -1;
      dir = -1;
   }

   BitmapCache *orig_mask = inState.mMask;
   if (!inState.mRecurse)
      last = first;
   for(int i=first; i!=last; i+=dir)
   {
      DisplayObject *obj = mChildren[i];
      //printf("Render phase = %d, parent = %d, child = %d\n", inState.mPhase, id, obj->id);
      if (!obj->visible || (inState.mPhase!=rpCreateMask && obj->IsMask()) )
         continue;

      RenderState *obj_state = &state;
      full = inState.mTransform.mMatrix->Mult( obj->GetLocalMatrix() );

      if (obj->scrollRect.HasPixels())
      {
         Extent2DF extent;
 
         DRect rect = obj->scrollRect;
         for(int c=0;c<4;c++)
            extent.Add( full.Apply( (((c&1)>0) ? rect.w :0), (((c&2)>0) ? rect.h :0) ) );


         Rect screen_rect(extent.mMinX,extent.mMinY, extent.mMaxX, extent.mMaxY, true );

         full.TranslateData(-obj->scrollRect.x, -obj->scrollRect.y );

         ImagePoint scroll(obj->scrollRect.x, obj->scrollRect.y);

         clip_state.mClipRect = inState.mClipRect.Intersect(screen_rect);

         if (!clip_state.mClipRect.HasPixels())
         {
            continue;
         }

         obj_state = &clip_state;
      }

      if (obj->pixelSnapping)
      {
         if (obj->pixelSnapping!=psAuto || (
             full.m00>0.99 && full.m00<1.01 && full.m01==0 &&
             full.m11>0.99 && full.m11<1.01 && full.m10==0 ) )
         {
            full.mtx = (int)full.mtx;
            full.mty = (int)full.mty;
         }
      }

      obj_state->mMask = orig_mask;

      DisplayObject *mask = obj->getMask();
      if (mask)
      {
         if (!mask->CreateMask(inTarget.mRect.Translated(obj_state->mTargetOffset),
                               obj_state->mTransform.mAAFactor))
            continue;

         // todo: combine masks ?
         //obj->DebugRenderMask(inTarget,obj->getMask());
         obj_state->mMask = mask->GetBitmapCache();
      }

      if (inState.mPhase==rpBitmap)
      {
         //printf("Bitmap phase %d\n", obj->id);
         if (obj->IsBitmapRender(inTarget.IsHardware()) )
         {
            obj->CheckCacheDirty(inTarget.IsHardware());

            Extent2DF screen_extent;
            obj->GetExtent(obj_state->mTransform,screen_extent,true,true);
            BitmapCache *mask = obj_state->mMask;

            // Get bounding pixel rect
            Rect rect = obj_state->mTransform.GetTargetRect(screen_extent);

            if (mask)
            {
               rect = rect.Intersect(mask->GetRect().Translated(-inState.mTargetOffset));
            }

            const FilterList &filters = obj->getFilters();


            // Move rect to include filtered pixels...
            Rect filtered = GetFilteredObjectRect(filters,rect);


            // Expand clip rect to account for pixels that must be rendered so the
            //  filtered image remains valid in the original clip region.
            Rect expanded = ExpandVisibleFilterDomain( filters, obj_state->mClipRect );


            // Must render to this ...
            Rect render_to  = rect.Intersect(expanded);
            // In order to get this ...
            visible_bitmap  = filtered.Intersect(obj_state->mClipRect );

            if (obj->GetBitmapCache())
            {
               // Done - our bitmap is good!
               if (obj->GetBitmapCache()->StillGood(obj_state->mTransform,
                      visible_bitmap, mask))
                  continue;
               else
               {
                  obj->SetBitmapCache(0);
               }
            }

            // Ok, build bitmap cache...
            if (visible_bitmap.HasPixels())
            {
               /*
               printf("object rect %d,%d %dx%d\n", rect.x, rect.y, rect.w, rect.h);
               printf("filtered rect %d,%d %dx%d\n", filtered.x, filtered.y, filtered.w, filtered.h);
               printf("expanded rect %d,%d %dx%d\n", expanded.x, expanded.y, expanded.w, expanded.h);
               printf("render to %d,%d %dx%d\n", render_to.x, render_to.y, render_to.w, render_to.h);
               printf("Build bitmap cache (%d,%d %dx%d)\n", visible_bitmap.x, visible_bitmap.y,
                  visible_bitmap.w, visible_bitmap.h );
               */

               int w = render_to.w;
               int h = render_to.h;
               if (inState.mRoundSizeToPOW2 && filters.size()==0)
               {
                  w = UpToPower2(w);
                  h = UpToPower2(h);
               }

               uint32 bg = obj->opaqueBackground;
               if (bg && filters.size())
                   bg = 0;
               Surface *bitmap = new SimpleSurface(w, h, obj->IsBitmapRender(inTarget.IsHardware()) ?
                         (bg ? pfXRGB : pfARGB) : pfAlpha );
               bitmap->IncRef();

               if (bg && obj->IsBitmapRender(inTarget.IsHardware()))
                  bitmap->Clear(obj->opaqueBackground | 0xff000000,0);
               else
                  bitmap->Zero();
               // debug ...
               //bitmap->Clear(0xff333333);

               //printf("Render %dx%d\n", w,h);
               bool old_pow2 = obj_state->mRoundSizeToPOW2;
               Matrix orig = full;
               {
               AutoSurfaceRender render(bitmap,Rect(render_to.w,render_to.h));
               full.Translate(-render_to.x, -render_to.y );
               ImagePoint offset = obj_state->mTargetOffset;
               Rect clip = obj_state->mClipRect;
               RenderPhase phase = obj_state->mPhase;

               obj_state->mClipRect = Rect(render_to.w,render_to.h);

               obj_state->mTargetOffset += ImagePoint(render_to.x,render_to.y);

               obj_state->CombineColourTransform(inState,&obj->colorTransform,&col_trans);

               obj_state->mPhase = rpBitmap;
               obj->Render(render.Target(), *obj_state);

               obj_state->mPhase = rpRender;
               obj_state->mRoundSizeToPOW2 = false;

               int old_aa = obj_state->mTransform.mAAFactor;
               obj_state->mTransform.mAAFactor = 4;

               obj->Render(render.Target(), *obj_state);
               obj_state->mTransform.mAAFactor = old_aa;

               obj->ClearCacheDirty();
               obj_state->mTargetOffset = offset;
               obj_state->mClipRect = clip;
               obj_state->mPhase = phase;
               }

               bitmap = FilterBitmap(filters,bitmap,render_to,visible_bitmap,old_pow2);

               full = orig;
               obj->SetBitmapCache(
                      new BitmapCache(bitmap, obj_state->mTransform, visible_bitmap, false, mask));
               obj_state->mRoundSizeToPOW2 = old_pow2;
               bitmap->DecRef();
            }
            else
            {
               obj->ClearCacheDirty();
            }
         }
         else
         {
            if (!obj->IsMask())
               obj->SetBitmapCache(0);
            obj_state->CombineColourTransform(inState,&obj->colorTransform,&col_trans);
            obj->Render(inTarget,*obj_state);
         }
      }
      else
      {
         if ( (obj->IsBitmapRender(inTarget.IsHardware()) && inState.mPhase!=rpHitTest) )
         {
            if (inState.mPhase==rpRender)
            {
               obj->RenderBitmap(inTarget,*obj_state);
            }
            /* HitTest is done on vector, not bitmap
            else if (inState.mPhase==rpHitTest && obj->IsBitmapRender() )
            {
                if (obj->HitBitmap(inTarget,*obj_state))
                {
                   inState.mHitResult = obj;
                   return;
                }
            }
            */
         }
         else
         {
            if (inState.mHitResult==this && !obj->IsInteractive())
               continue;
            
            if (obj->opaqueBackground)
            {
               Rect rect = clip_state.mClipRect;
               if ( !obj->scrollRect.HasPixels() )
               {
                  // TODO: this should actually be a rectangle rotated like the object?
                  Extent2DF screen_extent;
                  obj->GetExtent(obj_state->mTransform,screen_extent,true,true);
                  // Get bounding pixel rect
                  rect = obj_state->mTransform.GetTargetRect(screen_extent);

                  // Intersect with clip rect ...
                  rect = rect.Intersect(obj_state->mClipRect);
               }

               if (rect.HasPixels())
               {
                  if (inState.mPhase == rpHitTest && obj->mouseEnabled)
                  {
                     if (obj->IsInteractive())
                     {
                        inState.mHitResult = obj;
                        return;
                     }
                     else
                     {
                        inState.mHitResult = this;
                        continue;
					 }
                  }
                  else if (inState.mPhase == rpRender )
                     inTarget.Clear(obj->opaqueBackground,rect);
               }
               else if (inState.mPhase == rpHitTest)
               {
                  continue;
               }
            }

            if (inState.mPhase==rpRender)
               obj_state->CombineColourTransform(inState,&obj->colorTransform,&col_trans);
            obj->Render(inTarget,*obj_state);
         }

         if (obj_state->mHitResult)
         {
            if(mouseChildren && obj_state->mHitResult->mouseEnabled && obj_state->mHitResult != NULL)
	            inState.mHitResult = obj_state->mHitResult;
			else if(mouseEnabled)
	            inState.mHitResult = this;
            
			if (inState.mHitResult!=this)
               return;
         }
      }
   }
   
   if (inState.mPhase==rpHitTest && inState.mHitResult==this)
      return;

   // Render parent at beginning or end...
   if (!parent_first)
      DisplayObject::Render(inTarget,inState);
}

void DisplayObjectContainer::GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForScreen,bool inIncludeStroke)
{
   int smallest = mExtentCache[0].mID;
   int slot = 0;
   ClearExtentDirty();
   for(int i=0;i<3;i++)
   {
      CachedExtent &cache = mExtentCache[i];
      if (cache.mIsSet && *inTrans.mMatrix==cache.mMatrix &&
            *inTrans.mScale9==cache.mScale9 && cache.mIncludeStroke==inIncludeStroke &&
               cache.mForScreen==inForScreen)
         {
            // Maybe set but not valid - ie, 0 size
            if (cache.mExtent.Valid())
               outExt.Add(cache.mExtent);
            return;
         }
      if (cache.mID<gCachedExtentID)
         cache.mID = gCachedExtentID;

      if (cache.mID<smallest)
      {
         smallest = cache.mID;
         slot = i;
      }
   }

   // Need to recalculate the extent...
   CachedExtent &cache = mExtentCache[slot];
   cache.mExtent = Extent2DF();
   cache.mIsSet = true;
   cache.mMatrix = *inTrans.mMatrix;
   cache.mScale9 = *inTrans.mScale9;
   // todo:Matrix3d?
   cache.mForScreen = inForScreen;
   cache.mIncludeStroke = inIncludeStroke;

   DisplayObject::GetExtent(inTrans,cache.mExtent,inForScreen,inIncludeStroke);

   // TODO - allow translations without clearing cache
   Matrix full;
   Transform trans(inTrans);
   trans.mMatrix = &full;

   for(int i=0;i<mChildren.size();i++)
   {
      DisplayObject *obj = mChildren[i];

      full = inTrans.mMatrix->Mult( obj->GetLocalMatrix() );
      if (inForScreen && obj->scrollRect.HasPixels())
      {
         for(int corner=0;corner<4;corner++)
         {
            double x = (corner & 1) ? obj->scrollRect.w : 0;
            double y = (corner & 2) ? obj->scrollRect.h : 0;
            cache.mExtent.Add( full.Apply(x,y) );
         }
      }
      else
         // Seems scroll rects are ignored when calculating extent...
         obj->GetExtent(trans,cache.mExtent,inForScreen,inIncludeStroke);
   }

   if (cache.mExtent.Valid())
     outExt.Add(cache.mExtent);
}


DisplayObject *DisplayObjectContainer::getChildAt(int index)
{
   if (index<0 || index>=mChildren.size())
      return 0;
   return mChildren[index];
}

bool DisplayObjectContainer::NonNormalBlendChild()
{
   for(int i=0;i<mChildren.size();i++)
      if (mChildren[i]->visible && mChildren[i]->blendMode!=bmNormal)
         return true;
   return false;
}

bool DisplayObjectContainer::IsCacheDirty()
{
   for(int i=0;i<mChildren.size();i++)
      if (mChildren[i]->visible && mChildren[i]->IsCacheDirty())
         return true;
   return DisplayObject::IsCacheDirty();
}

void DisplayObjectContainer::ClearCacheDirty()
{
   for(int i=0;i<mChildren.size();i++)
      mChildren[i]->ClearCacheDirty();

   DisplayObject::ClearCacheDirty();
}


// --- BitmapCache ---------------------------------------------------------





// --- Stage ---------------------------------------------------------------


// Helper class....
class AutoStageRender
{
   Surface *mSurface;
   Stage   *mToFlip;
   RenderTarget mTarget;
public:
   AutoStageRender(Stage *inStage,int inRGB)
   {
      mSurface = inStage->GetPrimarySurface();
      mToFlip = inStage;
      mTarget = mSurface->BeginRender( Rect(mSurface->Width(),mSurface->Height()),false );
      mSurface->Clear(inRGB | 0xff000000 );
   }
   int Width() const { return mSurface->Width(); }
   int Height() const { return mSurface->Height(); }
   ~AutoStageRender()
   {
      mSurface->EndRender();
      mToFlip->Flip();
   }
   const RenderTarget &Target() { return mTarget; }
};

Stage *Stage::gCurrentStage = 0;

Stage::Stage(bool inInitRef) : DisplayObjectContainer(inInitRef)
{
   gCurrentStage = this;
   mHandler = 0;
   mHandlerData = 0;
   opaqueBackground = 0xffffffff;
   mFocusObject = 0;
   mMouseDownObject = 0;
   mSimpleButton = 0;
   focusRect = true;
   mLastMousePos = UserPoint(0,0);
   scaleMode = ssmShowAll;
   mNominalWidth = 100;
   mNominalHeight = 100;
   mNextWake = 0.0;
   displayState = sdsNormal;
   align = saTopLeft;

   #if defined(IPHONE) || defined(ANDROID) || defined(WEBOS) || defined(TIZEN)
   quality = sqLow;
   #else
   quality = sqBest;
   #endif
}

Stage::~Stage()
{
   if (gCurrentStage==this)
      gCurrentStage = 0;
   if (mFocusObject)
      mFocusObject->DecRef();
   if (mMouseDownObject)
      mMouseDownObject->DecRef();
}

void Stage::SetNextWakeDelay(double inNextWake)
{
	mNextWake = inNextWake + GetTimeStamp();
}

void Stage::SetFocusObject(DisplayObject *inObj,FocusSource inSource,int inKey)
{
   if (inObj==mFocusObject)
      return;

   if (mHandler)
   {
      Event focus(etFocus);
      focus.id = inObj ? inObj->id : 0;
      focus.value = inSource;
      focus.code = inKey;
   
      mHandler(focus,mHandlerData);

      if (inSource!=fsProgram && focus.result==erCancel)
         return;
   }


   if (!inObj || inObj->getStage()!=this)
   {
      if (mFocusObject)
      {
         mFocusObject->Unfocus();
         mFocusObject->DecRef();
      }
      mFocusObject = 0;
   }
   else
   {
      inObj->IncRef();
      if (mFocusObject)
      {
         mFocusObject->Unfocus();
         mFocusObject->DecRef();
      }
      mFocusObject = inObj;
      inObj->Focus();
   }

}

void Stage::SetNominalSize(int inWidth, int inHeight)
{
   mNominalWidth = inWidth;
   mNominalHeight = inHeight;
   CalcStageScaling( getStageWidth(), getStageHeight() );
}


void Stage::SetEventHandler(EventHandler inHander,void *inUserData)
{
   mHandler = inHander;
   mHandlerData = inUserData;
}

void Stage::HandleEvent(Event &inEvent)
{
   gCurrentStage = this;
   DisplayObject *hit_obj = 0;

   bool primary = inEvent.flags & efPrimaryTouch;

   if ( (inEvent.type==etMouseMove || inEvent.type==etMouseDown ||
         inEvent.type==etTouchBegin || inEvent.type==etTouchMove  )
            && primary )
      mLastMousePos = UserPoint(inEvent.x, inEvent.y);

   if (mMouseDownObject && primary)
   {
      switch(inEvent.type)
      {
         case etTouchMove:
         case etMouseMove:
            if (inEvent.flags & efLeftDown)
            {
               mMouseDownObject->Drag(inEvent);
               break;
            }
            // fallthrough
         case etMouseClick:
         case etMouseDown:
         case etMouseUp:
         case etTouchBegin:
         case etTouchTap:
         case etTouchEnd:
            mMouseDownObject->EndDrag(inEvent);
            mMouseDownObject->DecRef();
            mMouseDownObject = 0;
            break;
         default: break;
      }
   }

   if (inEvent.type==etKeyDown || inEvent.type==etKeyUp)
   {
      inEvent.id = mFocusObject ? mFocusObject->id : id;
      if (mHandler)
         mHandler(inEvent,mHandlerData);
      if (inEvent.result==0 && mFocusObject)
         mFocusObject->OnKey(inEvent);
      #ifdef ANDROID
      // Non-cancelled back key ...
      if (inEvent.result==0 && inEvent.code==27 && inEvent.type == etKeyUp)
      {
          StopAnimation();
      }
      #endif
      return;
   }

   if (inEvent.type==etResize)
   {
      CalcStageScaling( inEvent.x, inEvent.y);
   }

   if (inEvent.type==etMouseMove || inEvent.type==etMouseDown ||
         inEvent.type==etMouseUp || inEvent.type==etMouseClick ||
         inEvent.type==etTouchBegin || inEvent.type==etTouchEnd ||
         inEvent.type==etTouchMove || inEvent.type==etTouchTap
       )
   {
      UserPoint pixels(inEvent.x,inEvent.y);
      hit_obj = HitTest(pixels);
      //if (inEvent.type!=etTouchMove)
        //ELOG("  type=%d %d,%d obj=%p (%S)", inEvent.type, inEvent.x, inEvent.y, hit_obj, hit_obj?hit_obj->name.c_str():L"(none)");

      SimpleButton *but = hit_obj ? dynamic_cast<SimpleButton *>(hit_obj) : 0;
      inEvent.id = hit_obj ? hit_obj->id : id;
      Cursor cur = hit_obj ? hit_obj->GetCursor() : curPointer;

      if (mSimpleButton && (inEvent.flags & efLeftDown) )
      {
         // Don't change simple button if dragging ...
      }
      else if (but!=mSimpleButton)
      {
         if (but)
            but->IncRef();
         if (mSimpleButton)
         {
            SimpleButton *s = mSimpleButton;
            mSimpleButton = 0;
            s->setMouseState(SimpleButton::stateUp);
            s->DecRef();
         }
         mSimpleButton = but;
      }

      if (mSimpleButton)
      {
         bool over = but==mSimpleButton;
         bool down =  (inEvent.flags & efLeftDown);
         mSimpleButton->setMouseState( over ? ( down ?
             SimpleButton::stateDown : SimpleButton::stateOver) : SimpleButton::stateUp );
         if (!down && !over)
         {
            SimpleButton *s = mSimpleButton;
            mSimpleButton = 0;
            s->DecRef();
         }
         else if (mSimpleButton->getUseHandCursor())
            cur = curHand;
      }

      SetCursor( (gMouseShowCursor || cur>=curTextSelect0) ? cur : curNone );

      UserPoint stage = mStageScale.ApplyInverse(pixels);
      inEvent.x = stage.x;
      inEvent.y = stage.y;
   }


   if (hit_obj)
      hit_obj->IncRef();

   if (mHandler)
      mHandler(inEvent,mHandlerData);

   if (hit_obj)
   {
      if ( (inEvent.type==etMouseDown ||
            (inEvent.type==etTouchBegin && (inEvent.flags & efPrimaryTouch) ))
           && inEvent.result!=erCancel )
      {
         if (hit_obj->WantsFocus())
            SetFocusObject(hit_obj,fsMouse);
         #if defined(IPHONE) || defined(ANDROID) || defined(WEBOS) || defined(TIZEN)
         else
         {
            EnablePopupKeyboard(false);
            SetFocusObject(0,fsMouse);
         }
         #endif
      }
   
      if (inEvent.type==etMouseDown || (inEvent.type==etTouchBegin && primary) )
      {
         if (hit_obj->CaptureDown(inEvent))
         {
            hit_obj->IncRef();
            mMouseDownObject = hit_obj;
         }
      }
   }
   #if defined(IPHONE) || defined(ANDROID) || defined(WEBOS) || defined(TIZEN)
   else if (inEvent.type==etMouseClick ||  inEvent.type==etMouseDown ||
         (inEvent.type==etTouchBegin && (inEvent.flags & efPrimaryTouch) ))
   {
      EnablePopupKeyboard(false);
      SetFocusObject(0);
   }
   #endif
 
   
   if (hit_obj)
      hit_obj->DecRef();
}

void Stage::setOpaqueBackground(uint32 inBG)
{
   opaqueBackground = inBG | 0xff000000;
   DirtyCache();
}


void Stage::RemovingFromStage(DisplayObject *inObject)
{
   DisplayObject *b = mSimpleButton;
   while(b)
   {
      if (b==inObject)
      {
         mSimpleButton->DecRef();
         mSimpleButton = 0;
         break;
      }
      b = b->getParent();
   }


   DisplayObject *f = mFocusObject;
   while(f)
   {
      if (f==inObject)
      {
         mFocusObject->DecRef();
         mFocusObject = 0;
         break;
      }
      f = f->getParent();
   }

   DisplayObject *m = mMouseDownObject;
   while(m)
   {
      if (m==inObject)
      {
         mMouseDownObject->DecRef();
         mMouseDownObject = 0;
         break;
      }
      m = m->getParent();
   }

}


void Stage::CalcStageScaling(double inNewWidth,double inNewHeight)
{
   double StageScaleX=1;
   double StageScaleY=1;
   double StageOX=0;
   double StageOY=0;

   if (inNewWidth<=0 || inNewHeight<=0)
      return;

   if (scaleMode!=ssmNoScale)
   {
      StageScaleX = inNewWidth/(double)mNominalWidth;
      StageScaleY = inNewHeight/(double)mNominalHeight;

      if (scaleMode==ssmNoBorder)
      {
         if (StageScaleX>StageScaleY)
            StageScaleY = StageScaleX;
         else
            StageScaleX = StageScaleY;
      }
      else if (scaleMode==ssmShowAll)
      {
         if (StageScaleX<StageScaleY)
            StageScaleY = StageScaleX;
         else
            StageScaleX = StageScaleY;
      }

   }

   double extra_x = inNewWidth-StageScaleX*mNominalWidth;
   double extra_y = inNewHeight-StageScaleY*mNominalHeight;

   switch(align)
   {
      case saTopLeft: break;
      case saLeft: break;
      case saBottomLeft: break;
      case saTopRight:
      case saRight:
      case saBottomRight:
         StageOX = -extra_y;
         break;
      case saTop:
      case saBottom:
         StageOX = -extra_x/2;
         break;
   }

   switch(align)
   {
      case saTopLeft: break;
      case saTopRight: break;
      case saTop: break;
      case saBottomRight:
      case saBottomLeft:
      case saBottom:
         StageOY = -extra_y;
         break;
      case saLeft:
      case saRight:
         StageOY = -extra_y/2;
         break;
   }

   DirtyCache();

   mStageScale.m00 = StageScaleX;
   mStageScale.m11 = StageScaleY;
   mStageScale.mtx = StageOX;
   mStageScale.mty = StageOY;
}


bool Stage::FinishEditOnEnter()
{
   if (mFocusObject && mFocusObject!=this)
      return mFocusObject->FinishEditOnEnter();
   return false;
}

int Stage::GetAA()
{
   switch(quality)
   {
      case sqLow: return 1;
      case sqMedium: return 2;
      case sqHigh:
      case sqBest:
         return 4;
   }
   return 1;
}


void Stage::RenderStage()
{
   ColorTransform::TidyCache();
   AutoStageRender render(this,opaqueBackground);
   if (render.Target().IsHardware())
      render.Target().mHardware->SetQuality(quality);

   RenderState state(0, GetAA() );

   state.mTransform.mMatrix = &mStageScale;

   state.mClipRect = Rect( render.Width(), render.Height() );

   state.mPhase = rpBitmap;
   state.mRoundSizeToPOW2 = render.Target().IsHardware();
   Render(render.Target(),state);

   state.mPhase = rpRender;
   Render(render.Target(),state);

   // Clear alpha masks
}

double Stage::getStageWidth()
{
   Surface *s = GetPrimarySurface();
   if (!s) return 0;
   return s->Width();
}

double Stage::getStageHeight()
{
   Surface *s = GetPrimarySurface();
   if (!s) return 0;
   return s->Height();
}


void Stage::setScaleMode(int inMode)
{
   scaleMode = (StageScaleMode)inMode;
   CalcStageScaling( getStageWidth(), getStageHeight() );
}

void Stage::setAlign(int inAlign)
{
   align = (StageAlign)inAlign;
   CalcStageScaling( getStageWidth(), getStageHeight() );
}

void Stage::setQuality(int inQuality)
{
   quality = (StageQuality)inQuality;
   DirtyCache();
}

void Stage::setDisplayState(int inDisplayState)
{
   displayState = (StageDisplayState)inDisplayState;
   SetFullscreen(inDisplayState>0);
}


Matrix Stage::GetFullMatrix(bool inStageScaling)
{
   if (!inStageScaling)
      return DisplayObject::GetFullMatrix(false);

   return mStageScale.Mult(GetLocalMatrix());
}
  


DisplayObject *Stage::HitTest(UserPoint inStage,DisplayObject *inRoot,bool inRecurse)
{
   Surface *surface = GetPrimarySurface();

   RenderTarget target = surface->BeginRender( Rect(surface->Width(),surface->Height()),true );

   RenderState state(0, GetAA() );
   state.mClipRect = Rect( inStage.x, inStage.y, 1, 1 );
   Matrix m = mStageScale;
   if (inRoot)
      m = inRoot->GetFullMatrix(true);
   state.mTransform.mMatrix = &m;


   state.mRoundSizeToPOW2 = target.IsHardware();
   state.mPhase = rpHitTest;
   state.mRecurse = inRecurse;

   (inRoot ? inRoot : this) -> Render(target,state);

   surface->EndRender();

   // ELOG("Stage hit %f,%f -> %p\n", inStage.x, inStage.y, state.mHitResult );

   return state.mHitResult;
}

} // end namespace lime

