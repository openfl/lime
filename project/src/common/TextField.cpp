#include <TextField.h>
#include <Tilesheet.h>
#include <Utils.h>
#include "renderer/common/Surface.h"
#include "renderer/common/BitmapCache.h"
#include <KeyCodes.h>
#include "XML/tinyxml.h"
#include <ctype.h>
#include <time.h>
#include <sstream>

#ifndef iswalpha
#define iswalpha isalpha
#endif


namespace lime
{

int gPasswordChar = 42; // *

TextField::TextField(bool inInitRef) : DisplayObject(inInitRef),
   alwaysShowSelection(false),
   antiAliasType(aaNormal),
   autoSize(asNone),
   background(false),
   backgroundColor(0xffffffff),
   border(false),
   borderColor(0x00000000),
   condenseWhite(false),
   defaultTextFormat( TextFormat::Default() ),
   displayAsPassword(false),
   embedFonts(false),
   gridFitType(gftPixel),
   maxChars(0),
   mouseWheelEnabled(true),
   multiline(false),
   restrict(WString()),
   scrollH(0),
   scrollV(1),
   selectable(true),
   sharpness(0),
   styleSheet(0),
   textColor(0x000000),
   thickness(0),
   useRichTextClipboard(false),
   wordWrap(false),
   isInput(false)
{
   mStringState = ssText;
   mLinesDirty = true;
   mGfxDirty = true;
   boundsWidth = 100.0;
   boundsHeight = 100.0;
   mActiveRect = Rect(100,100);
   mFontsDirty = false;
   mSelectMin = mSelectMax = 0;
   mSelectDownChar = 0;
   caretIndex = 0;
   mCaretGfx = 0;
   mHighlightGfx = 0;
   mLastCaretHeight = -1;
   mSelectKeyDown = -1;
   maxScrollH  = 0;
   maxScrollV  = 1;
   setText(L"");
   textWidth = 0;
   textHeight = 0;
   mLastUpDownX = -1;
   mLayoutScaleH = mLayoutScaleV = -1.0;
   mLayoutRotation = gr0;
   needsSoftKeyboard = true;
   mHasCaret = false;
}

TextField::~TextField()
{
   if (mCaretGfx)
      mCaretGfx->DecRef();
   if (mHighlightGfx)
      mHighlightGfx->DecRef();
   defaultTextFormat->DecRef();
   mCharGroups.DeleteAll();
}

void TextField::setWidth(double inWidth)
{
   boundsWidth = inWidth;
   mLinesDirty = true;
   mGfxDirty = true;
}

double TextField::getWidth()
{
   /*if (autoSize != asNone)
   {
      if (mLinesDirty)
         Layout();
      return textWidth;
   }
   return boundsWidth;*/
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

double TextField::getHeight()
{
   /*if (autoSize != asNone)
   {
      if (mLinesDirty)
         Layout();
      return textHeight;
   }
   return boundsHeight;*/
   Transform trans;
   trans.mMatrix = &GetLocalMatrix();
   Extent2DF ext;
   GetExtent(trans,ext,false,true);
   if (!ext.Valid())
      return 0;

   return ext.Height();
}
 


void TextField::setHeight(double inHeight)
{
   boundsHeight = inHeight;
   mLinesDirty = true;
   mGfxDirty = true;
}


const TextFormat *TextField::getDefaultTextFormat()
{
   return defaultTextFormat;
}

void TextField::setDefaultTextFormat(TextFormat *inFmt)
{
   if (inFmt)
      inFmt->IncRef();
   if (defaultTextFormat)
      defaultTextFormat->DecRef();
   defaultTextFormat = inFmt;
   textColor = defaultTextFormat->color;
   mLinesDirty = true;
   mGfxDirty = true;
   if (mCharGroups.empty() || (mCharGroups.size() == 1 && mCharGroups[0]->Chars() == 0))
      setText(L"");
}

void TextField::SplitGroup(int inGroup,int inPos)
{
   mCharGroups.InsertAt(inGroup+1,new CharGroup);
   CharGroup &group = *mCharGroups[inGroup];
   CharGroup &extra = *mCharGroups[inGroup+1];
   extra.mFormat = group.mFormat;
   extra.mFormat->IncRef();
   extra.mFontHeight = group.mFontHeight;
   extra.mFont = group.mFont;
   extra.mFont->IncRef();
   extra.mChar0 = group.mChar0 + inPos;
   extra.mString.Set(&group.mString[inPos], group.mString.size()-inPos);
   group.mString.resize(inPos); // TODO: free some memory?
   mLinesDirty = true;
}

TextFormat *TextField::getTextFormat(int inStart,int inEnd)
{
   TextFormat *commonFormat = NULL;
   
   for(int i=0;i<mCharGroups.size();i++)
   {
      CharGroup *charGroup = mCharGroups[i];
      TextFormat *format = charGroup->mFormat;
      
      if (commonFormat == NULL)
      {
         commonFormat = new TextFormat (*format);
         commonFormat->align.Set();
         commonFormat->blockIndent.Set();
         commonFormat->bold.Set();
         commonFormat->bullet.Set();
         commonFormat->color.Set();
         commonFormat->font.Set();
         commonFormat->indent.Set();
         commonFormat->italic.Set();
         commonFormat->kerning.Set();
         commonFormat->leading.Set();
         commonFormat->leftMargin.Set();
         commonFormat->letterSpacing.Set();
         commonFormat->rightMargin.Set();
         commonFormat->size.Set();
         commonFormat->tabStops.Set();
         commonFormat->target.Set();
         commonFormat->underline.Set();
         commonFormat->url.Set();
      }
      else
      {
         commonFormat->align.IfEquals(format->align);
         commonFormat->blockIndent.IfEquals(format->blockIndent);
         commonFormat->bullet.IfEquals(format->bullet);
         commonFormat->color.IfEquals(format->color);
         commonFormat->font.IfEquals(format->font);
         commonFormat->indent.IfEquals(format->indent);
         commonFormat->italic.IfEquals(format->italic);
         commonFormat->kerning.IfEquals(format->kerning);
         commonFormat->leading.IfEquals(format->leading);
         commonFormat->leftMargin.IfEquals(format->leftMargin);
         commonFormat->letterSpacing.IfEquals(format->letterSpacing);
         commonFormat->rightMargin.IfEquals(format->rightMargin);
         commonFormat->size.IfEquals(format->size);
         commonFormat->tabStops.IfEquals(format->tabStops);
         commonFormat->target.IfEquals(format->target);
         commonFormat->underline.IfEquals(format->underline);
         commonFormat->url.IfEquals(format->url);
      }
   }
   return commonFormat;
}

void TextField::setTextFormat(TextFormat *inFmt,int inStart,int inEnd)
{
   if (!inFmt)
      return;
   
   Layout();
   
   int max = mCharPos.size();
   
   if (inStart<0)
   {
      inStart = 0;
	  inEnd = max;
   }
   else if (inEnd<0)
   {
      inEnd = inStart + 1;
   }
   
   if (inEnd>max) inEnd = max;

   if (inEnd<=inStart)
      return;

   inFmt->IncRef();
   int g0 = GroupFromChar(inStart);
   int g1 = GroupFromChar(inEnd);
   int g0_ex = inStart-mCharGroups[g0]->mChar0;
   if (g0_ex>0)
   {
      SplitGroup(g0,g0_ex);
      g0++;
      g1++;
   }
   if (inEnd<max)
   {
      int g1_ex = inEnd-mCharGroups[g1]->mChar0;
      if (g1_ex<mCharGroups[g1]->mString.size())
      {
         SplitGroup(g1,g1_ex);
         g1++;
      }
   }

   for(int g=g0;g<g1;g++)
   {
      mCharGroups[g]->ApplyFormat(inFmt);
   }

   inFmt->DecRef();

   mLinesDirty = true;
   mFontsDirty = true;
   mGfxDirty = true;
}





void TextField::setTextColor(int inCol)
{
   textColor = inCol;
   if (!defaultTextFormat->color.IsSet() || defaultTextFormat->color.Get()!=inCol)
   {
      defaultTextFormat = defaultTextFormat->COW();
      defaultTextFormat->color = inCol;
      mGfxDirty = true;
      DirtyCache();
   }
}

void TextField::setIsInput(bool inIsInput)
{
   isInput = inIsInput;
}

void TextField::setBackground(bool inBackground)
{
   background = inBackground;
   mGfxDirty = true;
   DirtyCache();
}

void TextField::setBackgroundColor(int inBackgroundColor)
{
   backgroundColor = inBackgroundColor;
   mGfxDirty = true;
   DirtyCache();
}

void TextField::setBorder(bool inBorder)
{
   border = inBorder;
   mGfxDirty = true;
   DirtyCache();
}

void TextField::setBorderColor(int inBorderColor)
{
   borderColor = inBorderColor;
   mGfxDirty = true;
   DirtyCache();
}

void TextField::setMultiline(bool inMultiline)
{
   multiline = inMultiline;
   mLinesDirty = true;
   mGfxDirty = true;
   DirtyCache();
}

void TextField::setWordWrap(bool inWordWrap)
{
   wordWrap = inWordWrap;
   mLinesDirty = true;
   mGfxDirty = true;
   DirtyCache();
}

void TextField::setAutoSize(int inAutoSize)
{
   autoSize = (AutoSizeMode)inAutoSize;
   mLinesDirty = true;
   mGfxDirty = true;
   DirtyCache();
}

double TextField::getTextHeight()
{
   Layout();
   double h =  textHeight/mLayoutScaleV;
   return std::max(h-4,0.0);
}

double TextField::getTextWidth()
{
   Layout();
   double w =  textWidth/mLayoutScaleH;
   return std::max(w-4,0.0);
}



bool TextField::FinishEditOnEnter()
{
   // For iPhone really
   return !multiline;
}

int TextField::getBottomScrollV()
{
   Layout();
   int l = std::max(scrollV -1,0);
   int height = boundsHeight;
   while(height>0 && l<mLines.size())
   {
      Line &line = mLines[l++];
      height -= line.mMetrics.height;
   }
   return l;
}

void TextField::setScrollH(int inScrollH)
{
   scrollH = inScrollH;
   if (scrollH<0)
      scrollH = 0;
   if (scrollH>maxScrollH)
      scrollH = maxScrollH;
   // TODO: do we need to re-layout on scroll?
   mLinesDirty = true;
   mGfxDirty = true;
   DirtyCache();
}

void TextField::setScrollV(int inScrollV)
{
   if (inScrollV<1)
      inScrollV = 1;
   if (inScrollV>maxScrollV)
      inScrollV =maxScrollV;

   if (inScrollV!=scrollV && mSelectMin!=mSelectMax)
   {
      mSelectMin = mSelectMax = 0;
      mSelectKeyDown = -1;
   }

   scrollV = inScrollV;
   // TODO: do we need to re-layout on scroll?
   mLinesDirty = true;
   mGfxDirty = true;
   DirtyCache();

}



int TextField::getLength()
{
   if (mLines.empty()) return 0;
   Line & l =  mLines[ mLines.size()-1 ];
   return l.mChar0 + l.mChars;
}

int TextField::PointToChar(int inX,int inY)
{
   if (mCharPos.empty())
      return 0;

   ImagePoint scroll = GetScrollPos();
   inX +=scroll.x;
   inY +=scroll.y;

   // Find the line ...
   for(int l=0;l<mLines.size();l++)
   {
      Line &line = mLines[l];
      if ( (line.mY0+line.mMetrics.height) > inY && line.mChars)
      {
         // Find the char
         for(int c=0; c<line.mChars;c++)
            if (mCharPos[line.mChar0 + c].x>inX)
               return c==0 ? line.mChar0 : line.mChar0+c-1;
         return line.mChar0 + line.mChars;
      }
   }

   return getLength();
}



int TextField::getSelectionBeginIndex()
{
   if (mSelectMax <= mSelectMin)
      return caretIndex;
   return mSelectMin;
}

int TextField::getSelectionEndIndex()
{
   if (mSelectMax <= mSelectMin)
      return caretIndex;
   return mSelectMax;
}


bool TextField::CaptureDown(Event &inEvent)
{
   if (selectable || isInput)
   {
      if (selectable)
         getStage()->EnablePopupKeyboard(true);

      UserPoint point = TargetToRect(GetFullMatrix(true), UserPoint( inEvent.x, inEvent.y) );
      int pos = PointToChar(point.x,point.y);
      caretIndex = pos;
      if (selectable)
      {
         mSelectDownChar = pos;
         mSelectMin = mSelectMax = pos;
         mGfxDirty = true;
         DirtyCache();
      }
   }
   return true;
}

UserPoint TextField::TargetToRect(const Matrix &inMatrix,const UserPoint &inPoint)
{
   UserPoint p = (inPoint - UserPoint(inMatrix.mtx, inMatrix.mty));
   switch(mLayoutRotation)
   {
      case gr0: break;
      case gr90: return UserPoint(p.y,-p.x);
      case gr180: return UserPoint(-p.x,-p.y);
      case gr270: return UserPoint(-p.y,p.x);
   }
   return p;
}

UserPoint TextField::RectToTarget(const Matrix &inMatrix,const UserPoint &inPoint)
{
   UserPoint trans(inMatrix.mtx, inMatrix.mty);
   switch(mLayoutRotation)
   {
      case gr0: break;
      case gr90: return UserPoint(-inPoint.y,inPoint.x) + trans;
      case gr180: return UserPoint(-inPoint.x,-inPoint.y) + trans;
      case gr270: return UserPoint(inPoint.y,-inPoint.x) + trans;
   }
   return inPoint + trans;

}



void TextField::Drag(Event &inEvent)
{
   if (selectable)
   {
      mSelectKeyDown = -1;
      UserPoint point = TargetToRect(GetFullMatrix(true),UserPoint( inEvent.x, inEvent.y) );
      int pos = PointToChar(point.x,point.y);
      if (pos>mSelectDownChar)
      {
         mSelectMin = mSelectDownChar;
         mSelectMax = pos;
      }
      else
      {
         mSelectMin = pos;
         mSelectMax = mSelectDownChar;
      }
		if (point.x>mActiveRect.x1())
      {
			scrollH+=(point.x-mActiveRect.x1());
         if (scrollH>maxScrollH)
            scrollH = maxScrollH;
      }
		else if (point.x<mActiveRect.x)
      {
			scrollH-=(mActiveRect.x-point.x);
         if (scrollH<0)
           scrollH = 0;
      }
      caretIndex = pos;
      ShowCaret(true);
      //printf("%d(%d) -> %d,%d\n", pos, mSelectDownChar, mSelectMin , mSelectMax);
      mGfxDirty = true;
      DirtyCache();
   }
}

void TextField::EndDrag(Event &inEvent)
{
}

void TextField::OnChange()
{
   Stage *stage = getStage();
   if (stage)
   {
      Event change(etChange);
      change.id = getID();
      stage->HandleEvent(change);
   }
}


void TextField::OnKey(Event &inEvent)
{
   if (isInput && inEvent.type==etKeyDown && inEvent.code<0xffff )
   {
      int code = inEvent.code;
      bool shift = inEvent.flags & efShiftDown;

      switch(inEvent.value)
      {
         case keyBACKSPACE:
            if (mSelectMin<mSelectMax)
            {
               DeleteSelection();
            }
            else if (caretIndex>0)
            {
               DeleteChars(caretIndex-1,caretIndex);
               caretIndex--;
            }
            else if (mCharGroups.size())
               DeleteChars(0,1);
            ShowCaret();
            OnChange();
            return;
         
         case keyDELETE:
            if (mSelectMin<mSelectMax)
            {
               DeleteSelection();
            }
            else if (caretIndex<getLength())
            {
               DeleteChars(caretIndex,caretIndex+1);
            }
            ShowCaret();
            OnChange();
            return;

         case keySHIFT:
            mSelectKeyDown = -1;
            mGfxDirty = true;
            return;

         case keyRIGHT:
         case keyLEFT:
         case keyHOME:
         case keyEND:
            mLastUpDownX = -1;
         case keyUP:
         case keyDOWN:
            if (mSelectKeyDown<0 && shift) mSelectKeyDown = caretIndex;
            switch(inEvent.value)
            {
               case keyLEFT: if (caretIndex>0) caretIndex--; break;
               case keyRIGHT: if (caretIndex<mCharPos.size()) caretIndex++; break;
               case keyHOME: caretIndex = 0; break;
               case keyEND: caretIndex = getLength(); break;
               case keyUP:
               case keyDOWN:
               {
                  int l= LineFromChar(caretIndex);
                  //printf("caret line : %d\n",l);
                  if (l==0 && inEvent.value==keyUP) return;
                  if (l==mLines.size()-1 && inEvent.value==keyDOWN) return;
                  l += (inEvent.value==keyUP) ? -1 : 1;
                  Line &line = mLines[l];
                  if (mLastUpDownX<0)
                     mLastUpDownX  = GetCursorPos().x + 1;
                  int c;
                  for(c=0; c<line.mChars;c++)
                     if (mCharPos[line.mChar0 + c].x>mLastUpDownX)
                        break;
                  caretIndex =  c==0 ? line.mChar0 : line.mChar0+c-1;
                  OnChange();
                  break;
               }
            }

            if (mSelectKeyDown>=0)
            {
               mSelectMin = std::min(mSelectKeyDown,caretIndex);
               mSelectMax = std::max(mSelectKeyDown,caretIndex);
               mGfxDirty = true;
            }
            ShowCaret();
            return;

         // TODO: top/bottom

         case keyENTER:
            code = '\n';
            break;
      }

      if ( (multiline && code=='\n') || (code>27 && code<63000))
      {
         if (shift && code > 96 && code < 123)
         {
            code -= 32;
         }
         DeleteSelection();
         wchar_t str[2] = {code,0};
         WString ws(str);
         InsertString(ws);
         OnChange();
         ShowCaret();
      }
   }
   else
   {
      if (inEvent.type==etKeyUp && inEvent.value==keySHIFT)
         mSelectKeyDown = -1;
   }
}


void TextField::ShowCaret(bool inFromDrag)
{
	if (!CaretOn())
		return;
   ImagePoint pos(0,0);
   bool changed = false;

   if (caretIndex < mCharPos.size())
      pos = mCharPos[caretIndex];
   else if (mLines.size())
   {
      pos.x = EndOfLineX( mLines.size()-1 );
      pos.y = mLines[ mLines.size() -1].mY0;
   }

	//printf("Pos %dx%d\n", pos.x, pos.y);

   if (pos.x-scrollH >= mActiveRect.w)
   {
      changed = true;
      scrollH = pos.x - mActiveRect.w + 1;
   }
	// When dragging, allow caret to be hidden off to the left
   else if (pos.x-scrollH < 0 && !inFromDrag)
   {
      changed = true;
      scrollH = pos.x;
   }
	if (scrollH>maxScrollH)
	{
		scrollH = maxScrollH;
		changed = true;
	}
	else if (scrollH<0)
	{
		scrollH = 0;
		changed = true;
	}

   if (scrollV<1)
   {
      changed = true;
      scrollV = 1;
   }


	if (scrollV <= mLines.size())
	{
		if (pos.y-mLines[scrollV-1].mY0 >= mActiveRect.h)
		{
			changed = true;
			scrollV++;
		}
		else if (scrollV>1 && pos.y<mLines[scrollV-1].mY0)
		{
			scrollV--;
			changed = true;
		}
	}


   if (scrollH<0)
   {
      changed = true;
      scrollH = 0;
   }
   if (scrollH>maxScrollH)
   {
      scrollH = maxScrollH;
      changed = true;
      if (scrollV<1) scrollV = 1;
   }
   // TODO: -ve scroll for right/aligned/centred?
   if (scrollV>maxScrollV)
   {
      scrollV = maxScrollV;
      changed = true;
   }

   if (changed)
   {
      DirtyCache();
      if (mSelectMax > mSelectMin)
      {
         mGfxDirty = true;
      }
   }
}


void TextField::Clear()
{
   mCharGroups.DeleteAll();
   mLines.resize(0);
   maxScrollH = 0;
   maxScrollV = 1;
   scrollV = 1;
   scrollH = 0;
}

Cursor TextField::GetCursor()
{
	return selectable ? (Cursor)(curTextSelect0 + mLayoutRotation) : curPointer;
}


void TextField::setText(const WString &inString)
{
   Clear();
   CharGroup *chars = new CharGroup;
   chars->mString.Set(inString.c_str(),inString.length());
   chars->mFormat = defaultTextFormat->IncRef();
   chars->mFont = 0;
   chars->mFontHeight = 0;
   mCharGroups.push_back(chars);
   mLinesDirty = true;
   mFontsDirty = true;
   mGfxDirty = true;
}

WString TextField::getText()
{
   WString result;
   for(int i=0;i<mCharGroups.size();i++)
      result += WString(mCharGroups[i]->mString.mPtr,mCharGroups[i]->Chars());
   return result;
}

WString TextField::getHTMLText()
{
   WString result;
   TextFormat *cacheFormat = NULL;
   
   bool inAlign = false;
   bool inFontTag = false;
   bool inBoldTag = false;
   bool inItalicTag = false;
   bool inUnderlineTag = false;
   
   for(int i=0;i<mCharGroups.size();i++)
   {
	  CharGroup *charGroup = mCharGroups[i];
	  TextFormat *format = charGroup->mFormat;
	  
	  if (format != cacheFormat)
	  {
		  if (inUnderlineTag && !format->underline)
		  {
		  	 result += L"</u>";
		  	 inAlign = false;
		  }
		  
		  if (inItalicTag && !format->italic)
		  {
			  result += L"</i>";
			  inItalicTag = false;
		  }
		  
		  if (inBoldTag && !format->bold)
		  {
			  result += L"</b>";
			  inBoldTag = false;
		  }
		  
		  if (inFontTag && (WString (format->font).compare (cacheFormat->font) != 0 || format->color != cacheFormat->color || format->size != cacheFormat->size))
		  {
			  result += L"</font>";
			  inFontTag = false;
		  }
		  
		  if (inAlign && format->align != cacheFormat->align)
		  {
			  result += L"</p>";
			  inAlign = false;
		  }
	  }
	  
	  if (!inAlign && format->align != tfaLeft)
	  {
		  result += L"<p align=\"";
		  
		  switch(format->align)
		  {
           case tfaLeft: break;
           case tfaCenter: result += L"center"; break;
			  case tfaRight: result += L"right"; break;
			  case tfaJustify: result += L"justify"; break;
		  }
		  
		  result += L"\">";
		  inAlign = true;
	  }
	  
	  if (!inFontTag)
	  {
		  result += L"<font color=\"#";
		  result += ColorToWide(format->color);
		  result += L"\" face=\"";
		  result += format->font;
		  result += L"\" size=\"";
		  result += IntToWide(format->size);
		  result += L"\">";
		  inFontTag = true;
	  }
	  
	  if (!inBoldTag && format->bold)
	  {
		  result += L"<b>";
		  inBoldTag = true;
	  }
	  
	  if (!inItalicTag && format->italic)
	  {
		  result += L"<i>";
		  inItalicTag = true;
	  }
	  
	  if (!inUnderlineTag && format->underline)
	  {
		  result += L"<u>";
		  inUnderlineTag = true;
	  }
	  
	   result += WString(charGroup->mString.mPtr, charGroup->Chars());
	   cacheFormat = format;
   }
   
   if (inUnderlineTag) result += L"</u>";
   if (inItalicTag) result += L"</i>";
   if (inBoldTag) result += L"</b>";
   if (inFontTag) result += L"</font>";
   if (inAlign) result += L"</p>";
   
   return result;
}


void TextField::AddNode(const TiXmlNode *inNode, TextFormat *inFormat,int &ioCharCount)
{
   for(const TiXmlNode *child = inNode->FirstChild(); child; child = child->NextSibling() )
   {
      const TiXmlText *text = child->ToText();
      if (text)
      {
         CharGroup *chars = new CharGroup;;
         chars->mFormat = inFormat->IncRef();
         chars->mFont = 0;
         chars->mFontHeight = 0;
         chars->mString.Set(text->Value(), wcslen( text->Value() ));
         ioCharCount += chars->Chars();

         mCharGroups.push_back(chars);
         //printf("text: %s\n", text->Value());
      }
      else
      {
         const TiXmlElement *el = child->ToElement();
         if (el)
         {
            TextFormat *fmt = inFormat->IncRef();

            if (el->ValueTStr()==L"font")
            {
               for (const TiXmlAttribute *att = el->FirstAttribute(); att;
                          att = att->Next())
               {
                  const wchar_t *val = att->Value();
                  if (att->NameTStr()==L"color" && val[0]=='#')
                  {
                     int col;
                     if (TIXML_SSCANF(val+1,L"%x",&col))
                     {
                        fmt = fmt->COW();
                        fmt->color = col;
                     }
                  }
                  else if (att->NameTStr()==L"face")
                  {
                     fmt = fmt->COW();
                     fmt->font = val;
                  }
                  else if (att->NameTStr()==L"size")
                  {
                     int size;
                     if (TIXML_SSCANF(att->Value(),L"%d",&size))
                     {
                        fmt = fmt->COW();
                        if (val[0]=='-' || val[0]=='+')
                           fmt->size = std::max( (int)fmt->size + size, 0 );
                        else
                           fmt->size = size;
                     }
                  }
               }
            }
            else if (el->ValueTStr()==L"b")
            {
               if (!fmt->bold)
               {
                  fmt = fmt->COW();
                  fmt->bold = true;
               }
            }
            else if (el->ValueTStr()==L"i")
            {
               if (!fmt->italic)
               {
                  fmt = fmt->COW();
                  fmt->italic = true;
               }
            }
            else if (el->ValueTStr()==L"u")
            {
               if (!fmt->underline)
               {
                  fmt = fmt->COW();
                  fmt->underline = true;
               }
            }
            else if (el->ValueTStr()==L"br")
            {
               if (mCharGroups.size())
               {
                  CharGroup &last = *mCharGroups[ mCharGroups.size()-1 ];
                  last.mString.push_back('\n');
                  ioCharCount++;
               }
               else
               {
                  CharGroup *chars = new CharGroup;
                  chars->mFormat = inFormat->IncRef();
                  chars->mFont = 0;
                  chars->mFontHeight = 0;
                  chars->mString.push_back('\n');
                  ioCharCount++;
                  mCharGroups.push_back(chars);
               }
            }
            else if (el->ValueTStr()==L"p")
            {
               if (ioCharCount > 0)
               {
                  if (mCharGroups.size())
                  {
                     CharGroup &last = *mCharGroups[ mCharGroups.size()-1 ];
                     last.mString.push_back('\n');
                     ioCharCount++;
                  }
                  else
                  {
                     CharGroup *chars = new CharGroup;
                     chars->mFormat = inFormat->IncRef();
                     chars->mFont = 0;
                     chars->mFontHeight = 0;
                     chars->mString.push_back('\n');
                     ioCharCount++;
                     mCharGroups.push_back(chars);
                  }
               }
            }

            for (const TiXmlAttribute *att = el->FirstAttribute(); att; att = att->Next())
            {
               if (att->NameTStr()==L"align")
               {
                  fmt = fmt->COW();
                  if (att->ValueStr()==L"left")
                     fmt->align = tfaLeft;
                  else if (att->ValueStr()==L"right")
                     fmt->align = tfaRight;
                  else if (att->ValueStr()==L"center")
                     fmt->align = tfaCenter;
                  else if (att->ValueStr()==L"justify")
                     fmt->align = tfaJustify;
               }
            }


            AddNode(child,fmt,ioCharCount);

            fmt->DecRef();
         }
      }
   }
}


void TextField::setHTMLText(const WString &inString)
{
   Clear();
   mLinesDirty = true;
   mFontsDirty = true;

   WString str;
   str += L"<top>";
   str += inString;
   str += L"</top>";

   TiXmlNode::SetCondenseWhiteSpace(condenseWhite);
   TiXmlDocument doc;
   const wchar_t *err = doc.Parse(str.c_str(),0,TIXML_ENCODING_LEGACY);
   if (err != NULL)
      ELOG("Error parsing HTML input");
   const TiXmlNode *top =  doc.FirstChild();
   if (top)
   {
      int chars = 0;
         AddNode(top,defaultTextFormat,chars);
   }
   if (mCharGroups.empty())
      setText(L"");
}


int TextField::LineFromChar(int inChar)
{
   int min = 0;
   int max = mLines.size();

   while(min+1<max)
   {
      int mid = (min+max)/2;
      if (mLines[mid].mChar0>inChar)
         max = mid;
      else
         min = mid;
   }
   return min;
}

int TextField::GroupFromChar(int inChar)
{
   if (mCharGroups.empty()) return 0;

   int min = 0;
   int max = mCharGroups.size();
   CharGroup &last = *mCharGroups[max-1];
   if (inChar>=last.mChar0)
   {
      if (inChar>=last.mChar0 + last.Chars())
         return max;
      return max-1;
   }

   while(min+1<max)
   {
      int mid = (min+max)/2;
      if (mCharGroups[mid]->mChar0>inChar)
         max = mid;
      else
         min = mid;
   }
   while(min<max && mCharGroups[min]->Chars()==0)
      min++;
   return min;
}



int TextField::EndOfLineX(int inLine)
{
   Line &line = mLines[inLine];
   return mCharPos[ line.mChar0 ].x + line.mMetrics.width;
}

int TextField::EndOfCharX(int inChar,int inLine)
{
   if (inLine<0 || inLine>=mLines.size() || inChar<0 || inChar>=mCharPos.size())
      return 0;
   Line &line = mLines[inLine];
   // Not last character on line?
   if (inChar < line.mChar0 + line.mChars -1 )
      return mCharPos[inChar+1].x;
   // Return end-of-line
   return mCharPos[ line.mChar0 ].x + line.mMetrics.width;
}


int TextField::getLineOffset(int inLine)
{
   Layout();
   if (inLine<0 || mLines.size()<1)
      return 0;

   if (inLine>=mLines.size())
      return mLines[mLines.size()-1].mChar0;

   return mLines[inLine].mChar0;
}

WString TextField::getLineText(int inLine)
{
   Layout();
   if (inLine<0 || inLine>=mLines.size())
      return L"";
   Line &line = mLines[inLine];

   int g0 = GroupFromChar(line.mChar0);
   int g1 = GroupFromChar(line.mChar0 + line.mChars-1);

   int g0_pos =  line.mChar0 - mCharGroups[g0]->mChar0;
   wchar_t *g0_first = mCharGroups[g0]->mString.mPtr + g0_pos;
   if (g0==g1)
   {
      return WString(g0_first, line.mChars );
   }

   WString result(g0_first,mCharGroups[g0]->mString.size() - g0_pos );
   for(int g=g0+1;g<g1;g++)
   {
      CharGroup &group = *mCharGroups[g];
      result += WString( group.mString.mPtr, group.mString.size() );
   }
   CharGroup &group = *mCharGroups[g1];
   result += WString( group.mString.mPtr, line.mChar0 + line.mChars - group.mChar0 );

   return result;
}

TextLineMetrics *TextField::getLineMetrics(int inLine)
{
   Layout();
   if (inLine<0 || inLine>=mLines.size())
   {
      //val_throw(alloc_string("The supplied index is out of bounds."));
      return NULL;
   }
   Line &line = mLines[inLine];
   return &line.mMetrics;
}

ImagePoint TextField::GetScrollPos()
{
   return ImagePoint(scrollH,mLines[std::max(0,scrollV-1)].mY0-2);
}

ImagePoint TextField::GetCursorPos()
{
   ImagePoint pos(0,0);
   if (caretIndex < mCharPos.size())
      pos = mCharPos[caretIndex];
   else if (mLines.size())
   {
      pos.x = EndOfLineX( mLines.size()-1 );
      pos.y = mLines[ mLines.size() -1].mY0;
   }
   return pos;
}

void TextField::BuildBackground()
{
   Graphics &gfx = GetGraphics();
   if (mGfxDirty)
   {
      gfx.clear();
      if (mHighlightGfx)
         mHighlightGfx->clear();
      if (background || border)
      {
         if (background)
            gfx.beginFill( backgroundColor, 1 );
         if (border)
            gfx.lineStyle(0, borderColor );
         gfx.moveTo((mActiveRect.x)/mLayoutScaleH,   (mActiveRect.y)/mLayoutScaleV);
         gfx.lineTo((mActiveRect.x1())/mLayoutScaleH,(mActiveRect.y)/mLayoutScaleV);
         gfx.lineTo((mActiveRect.x1())/mLayoutScaleH,(mActiveRect.y1())/mLayoutScaleV);
         gfx.lineTo((mActiveRect.x)/mLayoutScaleH,   (mActiveRect.y1())/mLayoutScaleV);
         gfx.lineTo((mActiveRect.x)/mLayoutScaleH,   (mActiveRect.y)/mLayoutScaleV);
      }

      //printf("%d,%d\n", mSelectMin , mSelectMax);
      if (mSelectMin < mSelectMax)
      {
         ImagePoint scroll = GetScrollPos();
         if (!mHighlightGfx)
            mHighlightGfx = new Graphics(this,true);

         int l0 = LineFromChar(mSelectMin);
         int l1 = LineFromChar(mSelectMax-1);
         ImagePoint pos = mCharPos[mSelectMin] - scroll;
         int height = mLines[l1].mMetrics.height;
         int x1 = EndOfCharX(mSelectMax-1,l1) - scroll.x;
         mHighlightGfx->lineStyle(-1);
         mHighlightGfx->beginFill( 0x101060, 1);
         // Special case of begin/end on same line ...
         if (l0==l1)
         {
            //printf("HI %dx%d sv=%d (%d,%d) %d\n", pos.x,pos.y, scrollV, scroll.x, scroll.y, mSelectMin);
            mHighlightGfx->drawRect(pos.x,pos.y,x1-pos.x,height);
         }
         else
         {
            mHighlightGfx->drawRect(pos.x,pos.y,EndOfLineX(l0)- scroll.x-pos.x,height);
            for(int y=l0+1;y<l1;y++)
            {
               Line &line = mLines[y];
               pos = mCharPos[line.mChar0]-scroll;
               mHighlightGfx->drawRect(pos.x,pos.y,EndOfLineX(y)-scroll.x-pos.x,line.mMetrics.height);
            }
            Line &line = mLines[l1];
            pos = mCharPos[line.mChar0]-scroll;
            mHighlightGfx->drawRect(pos.x,pos.y,x1-pos.x,line.mMetrics.height);
         }
      }
      mGfxDirty = false;
   }
}

bool TextField::CaretOn()
{
   Stage *s = getStage();
   return  s && isInput && (( (int)(GetTimeStamp()*3)) & 1) && s->GetFocusObject()==this;
}

bool TextField::IsCacheDirty()
{
   return DisplayObject::IsCacheDirty() || mGfxDirty || mLinesDirty || (CaretOn()!=mHasCaret);
}



void TextField::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   if (inTarget.mPixelFormat==pfAlpha || inState.mPhase==rpBitmap)
      return;

   if (inState.mPhase==rpHitTest && !mouseEnabled )
      return;

   const Matrix &matrix = *inState.mTransform.mMatrix;
   Layout(matrix);


   RenderState state(inState);

   Rect r = mActiveRect.Rotated(mLayoutRotation).Translated(matrix.mtx,matrix.mty).RemoveBorder(2*mLayoutScaleH);
   state.mClipRect = r.Intersect(inState.mClipRect);

   if (inState.mMask)
      state.mClipRect = inState.mClipRect.Intersect(
               inState.mMask->GetRect().Translated(-inState.mTargetOffset) );

   if (!state.mClipRect.HasPixels())
      return;


   if (inState.mPhase==rpHitTest)
   {
      // Convert destination pixels to local pixels...
      UserPoint pos =  TargetToRect(matrix,UserPoint(inState.mClipRect.x, inState.mClipRect.y) );
      if ( mActiveRect.Contains(pos) )
         inState.mHitResult = this;
      return;
   }

   ImagePoint scroll = GetScrollPos();

   BuildBackground();

   Graphics &gfx = GetGraphics();

   if (!gfx.empty())
      gfx.Render(inTarget,inState);

   UserPoint origin = RectToTarget( matrix, UserPoint(mActiveRect.x, mActiveRect.y) );
   UserPoint dPdX(1,0);
   UserPoint dPdY(0,1);
   switch(mLayoutRotation)
   {
      case gr0: break;
      case gr90: dPdX = UserPoint(0,1); dPdY = UserPoint(-1,0); break;
      case gr180: dPdX = UserPoint(-1,0); dPdY = UserPoint(0,-1); break;
      case gr270: dPdX = UserPoint(0,-1); dPdY = UserPoint(1,0); break;
   }

   bool highlight = mHighlightGfx && !mHighlightGfx->empty();
   bool caret = CaretOn();

   // Setup matrix for going from Rect to Target
   Matrix rect_to_target;
   if (highlight || caret)
   {
      rect_to_target.m00 = dPdX.x;
      rect_to_target.m01 = dPdY.x;
      rect_to_target.mtx = origin.x;
      rect_to_target.m10 = dPdX.y;
      rect_to_target.m11 = dPdY.y;
      rect_to_target.mty = origin.y;
      state.mTransform.mMatrix = &rect_to_target;

      if (highlight)
         mHighlightGfx->Render(inTarget,state);

      if (caret)
      {
         if (!mCaretGfx)
            mCaretGfx = new Graphics(this,true);
         int line = LineFromChar(caretIndex);
         if (line>=0)
         {
            int height = mLines[line].mMetrics.height;
            if (height!=mLastCaretHeight)
            {
               mLastCaretHeight = height;
               mCaretGfx->clear();
               mCaretGfx->lineStyle(1,0x000000);
               mCaretGfx->moveTo(0,0);
               mCaretGfx->lineTo(0,mLastCaretHeight);
            }

            ImagePoint pos = GetCursorPos() - scroll;
           
            rect_to_target.TranslateData(pos.x,pos.y);
            mCaretGfx->Render(inTarget,state);
         }
      }
   }

   mHasCaret = caret;


   HardwareContext *hardware = inTarget.IsHardware() ? inTarget.mHardware : 0;

   RenderTarget clipped;
   if (hardware)
      hardware->SetViewport(state.mClipRect);
   else
      clipped = inTarget.ClipRect( state.mClipRect );


   int line = 0;
   int last_line = mLines.size()-1;
   Surface *hardwareSurface = 0;
   uint32  hardwareTint = 0;
   for(int g=0;g<mCharGroups.size();g++)
   {
      CharGroup &group = *mCharGroups[g];
      if (group.Chars() && group.mFont)
      {
         uint32 group_tint =
              inState.mColourTransform->Transform(group.mFormat->color(textColor) | 0xff000000);
         for(int c=0;c<group.Chars();c++)
         {
            int ch = group.mString[c];
            if (displayAsPassword)
               ch = gPasswordChar;
            if (ch!='\n' && ch!='\r')
            {
               int cid = group.mChar0 + c;
               ImagePoint pos = mCharPos[cid]-scroll;
               if (pos.y>mActiveRect.h) break;
               while(line<last_line && mLines[line+1].mChar0 >= cid)
                  line++;
               pos.y += mLines[line].mMetrics.ascent;

               int a;
               Tile tile = group.mFont->GetGlyph( ch, a);
               UserPoint p = origin + dPdX*pos.x + dPdY*pos.y+ UserPoint(tile.mOx,tile.mOy);
               uint32 tint = cid>=mSelectMin && cid<mSelectMax ? 0xffffffff : group_tint;
               if (hardware)
               {
                  if (hardwareSurface!=tile.mSurface || hardwareTint!=tint)
                  {
                     if (hardwareSurface)
                        hardware->EndBitmapRender();

                     hardwareSurface = tile.mSurface;
                     hardwareTint = tint;
                     hardware->BeginBitmapRender(tile.mSurface,tint);
                  }
                  hardware->RenderBitmap(tile.mRect, (int)p.x, (int)p.y);
               }
               else
               {
                  tile.mSurface->BlitTo(clipped,
                     tile.mRect, (int)p.x, (int)p.y,
                     bmTinted, 0,
                    (uint32)tint);
               }
            }
         }
      }
   }


   if (hardwareSurface)
      hardware->EndBitmapRender();
}

void TextField::GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForBitmap,bool inIncludeStroke)
{
   Layout(*inTrans.mMatrix);


   if (inForBitmap && !border && !background)
   {
      Rect r = mActiveRect.Rotated(mLayoutRotation).
            Translated(inTrans.mMatrix->mtx, inTrans.mMatrix->mty);
      for(int corner=0;corner<4;corner++)
          outExt.Add( UserPoint(((corner & 1) ? r.x : r.x1()),((corner & 1) ? r.y : r.y1())));
   }
   else if (inForBitmap && border)
   {
      BuildBackground();
      return DisplayObject::GetExtent(inTrans,outExt,inForBitmap,inIncludeStroke);
   }
   else
   {
      for(int corner=0;corner<4;corner++)
      {
         //UserPoint pos((corner & 1) ? boundsWidth*mLayoutScaleH : 0,
         //              (corner & 2) ? boundsHeight*mLayoutScaleV : 0);
         UserPoint pos((corner & 1) ? mActiveRect.x1() : mActiveRect.x,
                       (corner & 2) ? mActiveRect.y1() : mActiveRect.y);
         outExt.Add( RectToTarget(*inTrans.mMatrix,pos) );
      }
   }
}


void TextField::DeleteChars(int inFirst,int inEnd)
{
   inEnd = std::min(inEnd,getLength());
   if (inFirst>=inEnd)
      return;

   // Find CharGroup/Pos from char-id
   int g0 = GroupFromChar(inFirst);
   if (g0>=0 && g0<mCharGroups.size())
   {
      int g1 = GroupFromChar(inEnd-1);
      CharGroup &group0 = *mCharGroups[g0];
      int del_g0 = inFirst==group0.mChar0 ? g0 : g0+1;
      group0.mString.erase( inFirst - group0.mChar0, inEnd-inFirst );
      CharGroup &group1 = *mCharGroups[g1];
      int del_g1 = (inEnd ==group1.mChar0+group1.Chars())? g1+1 : g1;
      if (g0!=g1)
         group1.mString.erase( 0,inEnd - group1.mChar0);

      // Leave at least 1 group...
      if (del_g0==0 && del_g1==mCharGroups.size())
         del_g0=1;
      if (del_g0 < del_g1)
      {
         for(int g=del_g0; g<del_g1;g++)
            delete mCharGroups[g];
         mCharGroups.erase(del_g0, del_g1 - del_g0);
      }

      mLinesDirty = true;
      mGfxDirty = true;
      Layout(GetFullMatrix(true));
   }
}

void TextField::DeleteSelection()
{
   if (mSelectMin>=mSelectMax)
      return;
   DeleteChars(mSelectMin,mSelectMax);
   caretIndex = mSelectMin;
   mSelectMin = mSelectMax = 0;
   mSelectKeyDown = -1;
   mGfxDirty = true;
}

void TextField::InsertString(WString &inString)
{
   if (caretIndex<0) caretIndex = 0;
   caretIndex = std::min(caretIndex,getLength());

   if (maxChars>0)
   {
      int n = mCharPos.size();
      if (inString.size()+n>maxChars)
         inString = inString.substr(0, maxChars-n);
      if (inString.size()<1)
         return;
   }

   if (caretIndex==0)
   {
      if (mCharGroups.empty())
      {
         setText(inString);
      }
      else
      {
         mCharGroups[0]->mString.InsertAt(0,inString.c_str(),inString.length());
      }
   }
   else
   {
      int g = GroupFromChar(caretIndex-1);
      CharGroup &group = *mCharGroups[g];
      group.mString.InsertAt( caretIndex-group.mChar0,inString.c_str(),inString.length());
   }
   caretIndex += inString.length();
   mLinesDirty = true;
   mGfxDirty = true;
   Layout(GetFullMatrix(true));
}

static bool IsWord(int inCh)
{
  #ifdef EPPC
  return (!isspace(inCh));
  #else
  return (!iswspace(inCh));
  #endif
  //return inCh<255 && (iswalpha(inCh) || isdigit(inCh) || inCh=='_');
}

static inline int Round6(int inX6)
{
   return (inX6 + (1<<6) -1) >> 6;
}

// Combine x,y scaling with rotation to calculate pixel coordinates for
//  each character.
void TextField::Layout(const Matrix &inMatrix)
{
   GlyphRotation rot;
   double scale_h;
   double scale_v;

   if (fabs(inMatrix.m00)> fabs(inMatrix.m01))
   {
      scale_h = fabs(inMatrix.m00);
      scale_v = fabs(inMatrix.m11);
      rot = inMatrix.m00 < 0 ? gr180 : gr0;
   }
   else
   {
      scale_h = fabs(inMatrix.m10);
      scale_v = fabs(inMatrix.m01);
      rot = inMatrix.m01 < 0 ? gr90 : gr270;
   }


   if (mFontsDirty || scale_h!=mLayoutScaleH || scale_v!=mLayoutScaleV ||
           rot!=mLayoutRotation)
   {
      for(int i=0;i<mCharGroups.size();i++)
         mCharGroups[i]->UpdateFont(scale_v,rot,!embedFonts);
      mLinesDirty = true;
      mFontsDirty = false;
      mLayoutScaleV = scale_v;
      mLayoutScaleH = scale_h;
      mLayoutRotation = rot;
   }

   if (!mLinesDirty)
      return;

   //printf("Re-layout\n");
   // Now, layout into local co-ordinates...
   mLines.resize(0);
   mCharPos.resize(0);

   int gap = (int)(2.0*mLayoutScaleH+0.5);
   Line line;
   int char_count = 0;
   textHeight = 0;
   textWidth = 0;
   int x6 = gap << 6;
   int y = gap;
   line.mY0 = y;
   mLastUpDownX = -1;
   int max_x = boundsWidth * mLayoutScaleH - gap;
   if (max_x<1) max_x = 1;

   for(int i=0;i<mCharGroups.size();i++)
   {
      CharGroup &g = *mCharGroups[i];
      g.mChar0 = char_count;
      int cid = 0;
      int last_word_cid = 0;
      int last_word_x6 = x6;
      int last_word_line_chars = line.mChars;

      g.UpdateMetrics(line.mMetrics);
      while(cid<g.Chars())
      {
         if (line.mChars==0)
         {
            x6 = gap<<6;
            line.mY0 = y;
            line.mChar0 = char_count;
            line.mCharGroup0 = i;
            line.mCharInGroup0 = cid;
            last_word_line_chars = 0;
            last_word_cid = cid;
            last_word_x6 = gap<<6;
         }

         int advance = 0;
         int ch = g.mString[cid];
         mCharPos.push_back( ImagePoint(x6>>6,y) );
         line.mChars++;
         char_count++;
         cid++;
         if (!displayAsPassword && !iswalpha(ch) && !isdigit(ch) && ch!='_' && ch!=';' && ch!='.' && ch!=',' && ch!='"' && ch!=':' && ch!='\'' && ch!='!' && ch!='?')
         {
            if (!IsWord(ch) || (line.mChars>2 && !IsWord(g.mString[cid-2]))  )
            {
			   #ifdef EPPC
               if ( (ch<255 && isspace(ch)) || line.mChars==1)
			   #else
               if ( (ch<255 && iswspace(ch)) || line.mChars==1)
			   #endif
               {
                  last_word_cid = cid;
                  last_word_line_chars = line.mChars;
               }
               else
               {
                  last_word_cid = cid-1;
                  last_word_line_chars = line.mChars-1;
               }
               last_word_x6 = x6;
            }
   
            if (ch=='\n' || ch=='\r')
            {
               // New line ...
               mLines.push_back(line);
               line.Clear();
               g.UpdateMetrics(line.mMetrics);
               y += g.Height() + g.mFormat->leading;
               continue;
            }
         }
   
         int ox6 = x6;
         if (displayAsPassword)
            ch = gPasswordChar;
         if (g.mFont)
            g.mFont->GetGlyph( ch, advance );
         else
            advance = 0;
         x6 += advance;
         //printf(" Char %c (%d..%d/%d,%d) %p\n", ch, ox, x, max_x, y, g.mFont);
         if ( !displayAsPassword && (wordWrap) && Round6(x6) > max_x && line.mChars>1)
         {
            // No break on line so far - just back up 1 character....
            if (last_word_line_chars==0 || !wordWrap)
            {
               cid--;
               line.mChars--;
               char_count--;
               mCharPos.qpop();
               line.mMetrics.width = Round6(ox6);
            }
            else
            {
               // backtrack to last break ...
               cid = last_word_cid;
               char_count-= line.mChars - last_word_line_chars;
               mCharPos.resize(char_count);
               line.mChars = last_word_line_chars;
               line.mMetrics.width = Round6(last_word_x6);
            }
            mLines.push_back(line);
            y += g.Height() + g.mFormat->leading;
            x6 = gap<<6;
            line.Clear();
            g.UpdateMetrics(line.mMetrics);
            continue;
         }

         int x = Round6(x6);
         line.mMetrics.width = x;
         if (x>textWidth)
            textWidth = x;
      }
   }
   textWidth += gap;
   if (line.mChars || mLines.empty())
   {
      mCharGroups[mCharGroups.size()-1]->UpdateMetrics(line.mMetrics);
      y += line.mMetrics.height;
      mLines.push_back(line);
   }

   textHeight = y + gap;

   int max_y = boundsHeight * mLayoutScaleV;
   if (autoSize != asNone)
   {
      //if (!wordWrap) - still use this, even if wordWrap
      {
         switch(autoSize)
         {
            case asNone: break;
            case asLeft: mActiveRect.w = textWidth;
                         break;
            case asRight: mActiveRect.x = mActiveRect.x1()-textWidth - gap;
                         mActiveRect.w = textWidth;
                         break;
            case asCenter: mActiveRect.x = (mActiveRect.x+mActiveRect.x1()-textWidth)/2;
                         mActiveRect.w = textWidth;
                         break;
         }
         if (autoSize!=asNone)
         {
             boundsHeight = textHeight/mLayoutScaleV;
         }
      }
      max_y = mActiveRect.h = textHeight;
   }
   else
      mActiveRect = Rect(0,0,boundsWidth*mLayoutScaleH+0.99,boundsHeight*mLayoutScaleV+0.99);

   maxScrollH = std::max(0,textWidth-max_x);
   maxScrollV = 1;

   // Work out how many lines from the end fit in the rect, and
   //  therefore how many lines we can scroll...
   if (textHeight>max_y && mLines.size()>1)
   {
      int window_height = max_y-3*gap;
      int line = mLines.size()-1;
      int lines_height = mLines[line].mMetrics.height;
      while( line < window_height && line>0 )
      {
         // Try next row up....
         if (lines_height + mLines[line-1].mMetrics.height > window_height)
            break;
         lines_height += mLines[--line].mMetrics.height;
      }

      maxScrollV = line+1;
   }

   // Align rows ...
   for(int l=0;l<mLines.size();l++)
   {
      Line &line = mLines[l];
      int chars = line.mChars;
      if (chars>0)
      {
         CharGroup &group = *mCharGroups[line.mCharGroup0];

         // Get alignment...
         int extra = (mActiveRect.w - line.mMetrics.width - 1);
         switch(group.mFormat->align(tfaLeft))
         {
            case tfaJustify: break;
            case tfaRight: break;
            case tfaLeft: extra = 0; break;
            case tfaCenter: extra/=2; break;
         }
         if (extra>0)
         {
            for(int c=0; c<line.mChars; c++)
               mCharPos[line.mChar0+c].x += extra;
         }
      }
   }

   mLinesDirty = false;
   int n = mCharPos.size();
   mSelectMin = std::min(mSelectMin,n);
   mSelectMax = std::min(mSelectMax,n);
   ShowCaret();
}




// --- TextFormat -----------------------------------

TextFormat::TextFormat() :
   align(tfaLeft),
   blockIndent(0),
   bold(false),
   bullet(false),
   color(0x00000000),
   font( WString(L"_serif",6) ),
   indent(0),
   italic(false),
   kerning(false),
   leading(0),
   leftMargin(0),
   letterSpacing(0),
   rightMargin(0),
   size(12),
   tabStops( QuickVec<int>() ),
   target(L""),
   underline(false),
   url(L"")
{
  //sFmtObjs++;
}

TextFormat::TextFormat(const TextFormat &inRHS,bool inInitRef) : Object(inInitRef),
   align(inRHS.align),
   blockIndent(inRHS.blockIndent),
   bold(inRHS.bold),
   bullet(inRHS.bullet),
   color(inRHS.color),
   font( inRHS.font ),
   indent(inRHS.indent),
   italic(inRHS.italic),
   kerning(inRHS.kerning),
   leading(inRHS.leading),
   leftMargin(inRHS.leftMargin),
   letterSpacing(inRHS.letterSpacing),
   rightMargin(inRHS.rightMargin),
   size(inRHS.size),
   tabStops( inRHS.tabStops),
   target(inRHS.target),
   underline(inRHS.underline),
   url(inRHS.url)
{
  //sFmtObjs++;
}

TextFormat::~TextFormat()
{
  //sFmtObjs--;
}

TextFormat *TextFormat::COW()
{
   if (mRefCount<2)
      return this;
   TextFormat *result = new TextFormat(*this);
   mRefCount --;
   return result;
}

TextFormat *TextFormat::Create(bool inInitRef)
{
   TextFormat *result = new TextFormat();
   if (inInitRef)
      result->IncRef();
   return result;
}

static TextFormat *sDefaultTextFormat = 0;

TextFormat *TextFormat::Default()
{
   if (!sDefaultTextFormat)
      sDefaultTextFormat = TextFormat::Create(true);
   sDefaultTextFormat->IncRef();
   return sDefaultTextFormat;
}



// --- TextFormat -----------------------------------

CharGroup::~CharGroup()
{
   mFormat->DecRef();
   if (mFont)
      mFont->DecRef();
}

bool CharGroup::UpdateFont(double inScale,GlyphRotation inRotation,bool inNative)
{
   int h = 0.5 + inScale*mFormat->size;
   if (!mFont || h!=mFontHeight || mFont->IsNative()!=inNative || mFont->Rotation()!=inRotation)
   {
      if (mFont)
         mFont->DecRef();
      mFont = Font::Create(*mFormat,inScale,inRotation,inNative,true);
      mFontHeight = h;
      return true;
   }
   return false;
}

void CharGroup::ApplyFormat(TextFormat *inFormat)
{
   mFormat = mFormat->COW();

   inFormat->align.Apply(mFormat->align);
   inFormat->blockIndent.Apply(mFormat->blockIndent);
   inFormat->bold.Apply(mFormat->bold);
   inFormat->bullet.Apply(mFormat->bullet);
   inFormat->color.Apply(mFormat->color);
   inFormat->font.Apply(mFormat->font);
   inFormat->indent.Apply(mFormat->indent);
   inFormat->italic.Apply(mFormat->italic);
   inFormat->kerning.Apply(mFormat->kerning);
   inFormat->leading.Apply(mFormat->leading);
   inFormat->leftMargin.Apply(mFormat->leftMargin);
   inFormat->letterSpacing.Apply(mFormat->letterSpacing);
   inFormat->rightMargin.Apply(mFormat->rightMargin);
   inFormat->size.Apply(mFormat->size);
   inFormat->tabStops.Apply(mFormat->tabStops);
   inFormat->target.Apply(mFormat->target);
   inFormat->underline.Apply(mFormat->underline);
   inFormat->url.Apply(mFormat->url);
}

} // end namespace lime

