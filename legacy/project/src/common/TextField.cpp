#include <TextField.h>
#include <Tilesheet.h>
#include <Utils.h>
#include <Surface.h>
#include <KeyCodes.h>
#include "XML/tinyxml.h"
#include <ctype.h>
#include <time.h>
#include <sstream>
#include <algorithm>

#ifndef iswalpha
#define iswalpha isalpha
#endif

// For some reason normal "iswalpha" or "isdigit" makes Blackberry crash, workarround:
#if defined(BLACKBERRY)

   int iswalphaBB(int c)
   {
      return((c >='a' && c <='z') || (c >='A' && c <='Z'));
   }
   #undef iswalpha
   #define iswalpha iswalphaBB
   
   int isdigitBB(int c)
   {
      return(c >='0' && c <='9');
   }
   #undef isdigit
   #define isdigit isdigitBB

#endif


namespace nme
{

int gPasswordChar = 42; // *

static const double GAP = 2.0;

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
   mTilesDirty = false;
   mCaretDirty = true;
   fieldWidth = 100.0;
   explicitWidth = fieldWidth;
   fieldHeight = 100.0;
   //mActiveRect = Rect(100,100);
   mFontsDirty = false;
   mSelectMin = mSelectMax = 0;
   mSelectDownChar = 0;
   caretIndex = 0;
   mCaretGfx = 0;
   mHighlightGfx = 0;
   mTiles = 0;
   mSelectKeyDown = -1;
   maxScrollH  = 0;
   maxScrollV  = 1;
   setText(L"");
   textWidth = 0;
   textHeight = 0;
   fontScale = 1.0;
   fontToLocal = 1.0;
   mLastUpDownX = -1;
   needsSoftKeyboard = true;
   mHasCaret = false;
   screenGrid = false;
   mBlink0 = GetTimeStamp();
}

TextField::~TextField()
{
   if (mCaretGfx)
      mCaretGfx->DecRef();
   if (mHighlightGfx)
      mHighlightGfx->DecRef();
   if (mTiles)
      mTiles->DecRef();
   defaultTextFormat->DecRef();
   mCharGroups.DeleteAll();
}

double TextField::getWidth()
{
   if (mLinesDirty)
      Layout();

   return fieldWidth*scaleX;
}

double TextField::getHeight()
{
   if (mLinesDirty)
      Layout();

   return fieldHeight*scaleY;
}

void TextField::setWidth(double inWidth)
{
   explicitWidth = inWidth;
   if (autoSize==asNone || wordWrap)
   {
      fieldWidth = inWidth;
      mLinesDirty = true;
      mGfxDirty = true;
   }
   mDirtyFlags |= dirtLocalMatrix;
}

void TextField::setHeight(double inHeight)
{
   if (autoSize==asNone)
   {
      fieldHeight = inHeight;
      mLinesDirty = true;
      mGfxDirty = true;
   }
}


void TextField::modifyLocalMatrix(Matrix &ioMatrix)
{
   if ( (autoSize==asCenter || autoSize==asRight) && !multiline )
   {
      if (autoSize==asCenter)
         ioMatrix.mtx += (fieldWidth-GAP*2) * scaleX* 0.5;
      else
         ioMatrix.mtx += (fieldWidth-GAP*2) * scaleX;
   }
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
   extra.mFlags = group.mFlags;
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
      mTilesDirty = true;
      mCaretDirty = true;
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
   setWidth(explicitWidth);
   mLinesDirty = true;
   mGfxDirty = true;
   DirtyCache();
}

void TextField::setAutoSize(int inAutoSize)
{
   if (inAutoSize!=autoSize)
   {
      autoSize = (AutoSizeMode)inAutoSize;
      mLinesDirty = true;
      mGfxDirty = true;
      mDirtyFlags |= dirtLocalMatrix;
      DirtyCache();
   }
}

double TextField::getTextHeight()
{
   Layout();
   return textHeight;
}

double TextField::getTextWidth()
{
   Layout();
   return textWidth;
}



bool TextField::FinishEditOnEnter()
{
   // For iPhone really
   return !multiline;
}

int TextField::getBottomScrollV()
{
   Layout();
   double l = std::max(scrollV -1,0);
   double height = fieldHeight-2*GAP;
   while(height>0 && l<mLines.size())
   {
      Line &line = mLines[l++];
      height -= line.mMetrics.height;
   }
   return l;
}

void TextField::setScrollH(int inScrollH)
{
   int oldPos = scrollH;
   scrollH = inScrollH;
   if (scrollH<0)
      scrollH = 0;
   if (scrollH>maxScrollH)
      scrollH = maxScrollH;

   if (oldPos!=scrollH)
   {
      mTilesDirty = true;
      mCaretDirty = true;
      mGfxDirty = true;
      DirtyCache();
   }
}

void TextField::setScrollV(int inScrollV)
{
   setScrollVClearSel(inScrollV,true);
}

void TextField::setScrollVClearSel(int inScrollV,bool inClearSel)
{
   int oldPos = scrollV;
   if (inScrollV<1)
      inScrollV = 1;
   if (inScrollV>maxScrollV)
      inScrollV =maxScrollV;

   if (inScrollV!=oldPos)
   {
      if (inClearSel && mSelectMin!=mSelectMax)
      {
         mSelectMin = mSelectMax = 0;
         mSelectKeyDown = -1;
      }

      scrollV = inScrollV;

      mTilesDirty = true;
      mCaretDirty = true;
      mGfxDirty = true;
      DirtyCache();
   }
}



int TextField::getLength() const
{
   if (mLines.empty()) return 0;
   const Line & l =  mLines[ mLines.size()-1 ];
   return l.mChar0 + l.mChars;
}

int TextField::PointToChar(UserPoint inPoint) const
{
   if (mCharPos.empty() || inPoint.y<mLines[0].mY0)
      return 0;

   inPoint += GetScrollPos();

   // Find the line ...
   for(int l=0;l<mLines.size();l++)
   {
      const Line &line = mLines[l];
      //printf("%d] %f/%f/%f\n",l, line.mY0, inPoint.y,  line.mY0+line.mMetrics.height );
      if ( (line.mY0+line.mMetrics.height) > inPoint.y && line.mChars)
      {
         if (line.mChars==1)
            return line.mChar0;

         // Find the char
         for(int c=0; c<line.mChars;c++)
         {
            double nextX = c<line.mChars-1 ? mCharPos[line.mChar0 + c + 1].x : mCharPos[line.mChar0].x+line.mMetrics.width;
            double middle = (mCharPos[line.mChar0 + c].x +  nextX)*0.5;
            if (inPoint.x<middle)
               return line.mChar0+c;
         }

         if (line.mChars>0 )
         {
            int cidx = line.mChar0 + line.mChars - 1;
            int g = GroupFromChar(cidx);
            int g_pos =  cidx - mCharGroups[g]->mChar0;
            wchar_t ch = mCharGroups[g]->mString.mPtr[g_pos];
            if (ch=='\n')
               return line.mChar0 + line.mChars -1;
         }
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
      if (selectable && isInput)
         getStage()->EnablePopupKeyboard(true);

      UserPoint point = GlobalToLocal(UserPoint( inEvent.x, inEvent.y));
      int pos = PointToChar(point);
      caretIndex = pos;
      if (selectable)
      {
         mSelectDownChar = pos;
         mSelectMin = mSelectMax = pos;
         mTilesDirty = true;
         mCaretDirty = true;
         mGfxDirty = true;
         DirtyCache();
      }
   }
   return true;
}

void TextField::Drag(Event &inEvent)
{
   if (selectable)
   {
      mSelectKeyDown = -1;
      UserPoint point = GlobalToLocal(UserPoint( inEvent.x, inEvent.y));

      int pos = PointToChar(point);
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


      if (point.x>fieldWidth-GAP)
         setScrollH(scrollH+(point.x-(fieldWidth-GAP)));
      else if (point.x<GAP)
         setScrollH(scrollH-(GAP-point.x));

      if (point.y>fieldHeight-GAP)
         setScrollVClearSel(scrollV+1,false);
      else if (point.y<GAP)
         setScrollVClearSel(scrollV-1,false);

      caretIndex = pos;
      ShowCaret(true);
      //printf("%d(%d) -> %d,%d\n", pos, mSelectDownChar, mSelectMin , mSelectMax);
      mGfxDirty = true;
      mTilesDirty = true;
      mCaretDirty = true;
      DirtyCache();
   }
}

void TextField::EndDrag(Event &inEvent)
{

}

void TextField::OnScrollWheel(int inDirection)
{
   setScrollV(scrollV + inDirection);
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
            mCaretDirty = true;
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
            if (mSelectKeyDown<0 && shift)
               mSelectKeyDown = caretIndex;
            if (!shift)
               ClearSelection();

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
               mTilesDirty = true;
               mCaretDirty = true;
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
   mCaretDirty = true;
   mBlink0 = GetTimeStamp();
   mHasCaret = false;

   UserPoint pos = GetCursorPos() - GetScrollPos();
   // When dragging, allow caret to be hidden off to the left
   if (pos.x<GAP && !inFromDrag)
      setScrollH( scrollH + pos.x-GAP - 1 );
   else if (pos.x>fieldWidth-GAP)
      setScrollH( scrollH + pos.x - (fieldWidth-GAP) + 1 );

   int line = LineFromChar(caretIndex);
   if (pos.y<GAP)
   {
      setScrollV(line+1);
   }
   else if (pos.y+mLines[line].mMetrics.height > fieldHeight-GAP)
   {
      int scroll = scrollV-1;
      double extra = pos.y+mLines[line].mMetrics.height - (fieldHeight-GAP);
      while(extra>0 && scroll<mLines.size())
      {
         extra -= mLines[scroll].mMetrics.height;
         scroll++;
      }
      setScrollV(scroll+1);
   }
   /*

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
      mTilesDirty = true;
      mCaretDirty = true;
      if (mSelectMax > mSelectMin)
      {
         mGfxDirty = true;
      }
   }
   */
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
   // TODO - angle cursor
   return selectable ? (Cursor)(curTextSelect0) : curPointer;
}


void TextField::setText(const WString &inString)
{
   Clear();
   CharGroup *chars = new CharGroup;
   chars->mString.Set(inString.c_str(),inString.length());
   chars->mFormat = defaultTextFormat->IncRef();
   chars->mFont = 0;
   chars->mFontHeight = 0;
   chars->mFlags = 0;
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


// Not sure why I need these now?
int MySSCAND(const wchar_t *inStr, int *outValue)
{
   #ifdef ANDROID
   int sign = 1;
   int result = 0;
   const wchar_t *oStr = inStr;
   if (*inStr=='-' || *inStr=='+')
   {
      sign = *inStr=='-' ? -1 : 1;
      inStr++;
   }
   while(*inStr>='0' && *inStr<='9')
   {
      result = result * 10 + *inStr-'0';
      inStr++;
   }
   *outValue = result * sign;
   return inStr>oStr;
   #else
   return TIXML_SSCANF(inStr, L"%d", outValue);
   #endif
}


int MySSCANHex(const wchar_t *inStr, int *outValue)
{
   #ifdef ANDROID
   int result = 0;
   const wchar_t *oStr = inStr;
   while( (*inStr>='0' && *inStr<='9') ||
           (*inStr>='a' && *inStr<='f') ||
            (*inStr>='A' && *inStr<='F')  )
   {
      result = result * 16;
      if (*inStr>='0' && *inStr<='9') result += *inStr-'0';
      if (*inStr>='a' && *inStr<='f') result += *inStr-'a' + 10;
      if (*inStr>='A' && *inStr<='F') result += *inStr-'A' + 10;
      inStr++;
   }
   *outValue = result;
   return inStr>oStr;
   #else
   return TIXML_SSCANF(inStr, L"%x", outValue);
   #endif
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
         chars->mFlags = 0;
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
                     if (MySSCANHex(val+1,&col))
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
                     int size=0;
                     if (MySSCAND(val,&size))
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
                  chars->mFlags = 0;
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
                     chars->mFlags = 0;
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


int TextField::LineFromChar(int inChar) const
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

int TextField::GroupFromChar(int inChar) const
{
   if (mCharGroups.empty()) return 0;

   int min = 0;
   int max = mCharGroups.size();
   const CharGroup &last = *mCharGroups[max-1];
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



double TextField::EndOfLineX(int inLine) const
{
   const Line &line = mLines[inLine];
   if (line.mChars==0)
      return GAP;
   return mCharPos[ line.mChar0 ].x + line.mMetrics.width;
}

double TextField::EndOfCharX(int inChar,int inLine) const
{
   if (inLine<0 || inLine>=mLines.size() || inChar<0 || inChar>=mCharPos.size())
      return 0;
   const Line &line = mLines[inLine];
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

   if (line.mChars==0)
      return L"";
      
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

UserPoint TextField::GetScrollPos() const
{
   return UserPoint(scrollH,mLines[std::max(0,scrollV-1)].mY0-GAP);
}

UserPoint TextField::GetCursorPos() const
{
   UserPoint pos(0,0);
   if (caretIndex < mCharPos.size())
      pos = mCharPos[caretIndex];
   else if (mLines.size())
   {
      pos.x = EndOfLineX( mLines.size()-1 );
      pos.y = mLines[ mLines.size() -1].mY0;
   }
   return pos;
}

bool TextField::isLineVisible(int inLine) const
{
   if (inLine<scrollV-1)
      return false;
   double bottom = GAP+mLines[inLine].mY0 + mLines[inLine].mMetrics.height - mLines[scrollV-1].mY0;
   return bottom<=fieldHeight-GAP;
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
            gfx.lineStyle(0, borderColor,1.0, false, ssmOpenGL  );

         gfx.moveTo(0.001,0.001);
         gfx.lineTo(fieldWidth+0.001,0.001);
         gfx.lineTo(fieldWidth+0.001,fieldHeight+0.001);
         gfx.lineTo(0.001,fieldHeight+0.001);
         gfx.lineTo(0.001,0.001);
      }

      //printf("%d,%d\n", mSelectMin , mSelectMax);
      if (mSelectMin < mSelectMax)
      {
         UserPoint scroll = GetScrollPos();
         if (!mHighlightGfx)
            mHighlightGfx = new Graphics(this,true);

         int l0 = LineFromChar(mSelectMin);
         int l1 = LineFromChar(mSelectMax-1);
         UserPoint pos = mCharPos[mSelectMin] - scroll;
         double height = mLines[l1].mMetrics.height;
         double x1 = EndOfCharX(mSelectMax-1,l1) - scroll.x;
         mHighlightGfx->lineStyle(-1);
         mHighlightGfx->beginFill( 0x101060, 1);
         // Special case of begin/end on same line ...
         if (l0==l1)
         {
            if (isLineVisible(l0))
               highlightRect(pos.x,pos.y,x1-pos.x,height);
         }
         else
         {
            if (isLineVisible(l0))
               highlightRect(pos.x,pos.y,EndOfLineX(l0)- scroll.x-pos.x,height);

            for(int y=l0+1;y<l1;y++)
            {
               if (isLineVisible(y))
               {
                  Line &line = mLines[y];
                  pos = mCharPos[line.mChar0]-scroll;
                  highlightRect(pos.x,pos.y,EndOfLineX(y)-scroll.x-pos.x,line.mMetrics.height);
               }
            }
            if (isLineVisible(l1))
            {
               Line &line = mLines[l1];
               pos = mCharPos[line.mChar0]-scroll;
               highlightRect(pos.x,pos.y,x1-pos.x,line.mMetrics.height);
            }
         }
      }
      mGfxDirty = false;
   }
}

void TextField::highlightRect(double x0, double y0, double w, double h)
{
   if (x0<GAP)
   {
      w += x0-GAP;
      x0 = GAP;
   }
   if (x0+w>fieldWidth-GAP)
      w = fieldWidth-GAP - x0;

   if (w>0)
      mHighlightGfx->drawRect(x0,y0,w,h);
}

bool TextField::CaretOn()
{
   Stage *s = getStage();
   return (s && isInput && s->GetFocusObject()==this && !(( (int)((GetTimeStamp()-mBlink0)*3)) & 1));
}

bool TextField::IsCacheDirty()
{
   //if (mGfxDirty) BuildBackground();
   return DisplayObject::IsCacheDirty() || mGfxDirty || mLinesDirty || (CaretOn()!=mHasCaret);
}


void  TextField::toScreenGrid(UserPoint &ioPoint, const Matrix &inMatrix)
{
   ioPoint.x = floor((ioPoint.x-inMatrix.mtx)*fontScale+0.5)*fontToLocal+inMatrix.mtx;
   ioPoint.y = floor((ioPoint.y-inMatrix.mty)*fontScale+0.5)*fontToLocal+inMatrix.mty;
}




void TextField::Render( const RenderTarget &inTarget, const RenderState &inState )
{
   if (inState.mPhase==rpBitmap && inState.mWasDirtyPtr && !*inState.mWasDirtyPtr && IsCacheDirty())
   {
      const Matrix &matrix = *inState.mTransform.mMatrix;
      Layout(matrix);

      RenderState state(inState);

      //Rect r = mActiveRect.Rotated(mLayoutRotation).Translated(matrix.mtx,matrix.mty).RemoveBorder(2*mLayoutScaleH);
      //state.mClipRect = r.Intersect(inState.mClipRect);

      if (inState.mMask)
         state.mClipRect = inState.mClipRect.Intersect(
               inState.mMask->GetRect().Translated(-inState.mTargetOffset) );

      *inState.mWasDirtyPtr =  state.mClipRect.HasPixels();
      return;
   }

   if (inTarget.mPixelFormat==pfAlpha || inState.mPhase==rpBitmap)
      return;

   if (inState.mPhase==rpHitTest && !mouseEnabled )
      return;

   const Matrix &matrix = *inState.mTransform.mMatrix;
   Layout(matrix);


   RenderState state(inState);

   // TODO - full transform
   //Rect r = mActiveRect.Translated(matrix.mtx,matrix.mty).RemoveBorder(2*mLayoutScaleH);
   //state.mClipRect = r.Intersect(inState.mClipRect);

   if (inState.mMask)
      state.mClipRect = inState.mClipRect.Intersect(
               inState.mMask->GetRect().Translated(-inState.mTargetOffset) );

   if (!state.mClipRect.HasPixels())
      return;


   if (inState.mPhase==rpHitTest)
   {
      // Convert destination pixels to local pixels...
      UserPoint pos = GlobalToLocal(UserPoint(inState.mClipRect.x, inState.mClipRect.y));
      if (pos.x>=0 && pos.y>=0 && pos.x<=fieldWidth && pos.y<=fieldHeight)
         inState.mHitResult = this;
      return;
   }

   UserPoint scroll = GetScrollPos();

   BuildBackground();

   Graphics &gfx = GetGraphics();

   if (!gfx.empty())
      gfx.Render(inTarget,inState);

   bool highlight = mHighlightGfx && !mHighlightGfx->empty();
   bool caret = CaretOn();

   if (highlight)
      mHighlightGfx->Render(inTarget,state);

   if (caret && mCaretDirty)
   {
      mCaretDirty = false;
      if (!mCaretGfx)
         mCaretGfx = new Graphics(this,true);
      else
         mCaretGfx->clear();

      int line = LineFromChar(caretIndex);
      if (line>=0)
      {
         UserPoint pos = GetCursorPos() - scroll;
         if (pos.x>=GAP-1 && pos.x<=fieldWidth-GAP+1 && pos.y>=GAP-1)
         {
            double height = mLines[line].mMetrics.height;
            if (pos.y+height <= fieldHeight-GAP+1)
            {
               mCaretGfx->lineStyle(1, 0x000000 ,1.0, false, ssmOpenGL  );
               mCaretGfx->moveTo(pos.x,pos.y);
               mCaretGfx->lineTo(pos.x,pos.y+height);
            }
         }
      }
   }

   mHasCaret = caret;

   if (mTilesDirty)
   {
      mTilesDirty = false;
      if (mCharGroups.size()==0)
      {
         if (mTiles)
         {
            mTiles->DecRef();
            mTiles = 0;
         }
      }
      else
      {
         if (!mTiles)
            mTiles = new Graphics(this,true);
         else
            mTiles->clear();

         int line = 0;
         int last_line = mLines.size()-1;
         Surface *fontSurface = 0;
         uint32  hardwareTint = 0;
         double clipRight = fieldWidth-GAP;

         float white[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
         float groupColour[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
         float trans_2x2[4] = { fontToLocal, 0.0f, 0.0f, fontToLocal };
         for(int g=0;g<mCharGroups.size();g++)
         {
            CharGroup &group = *mCharGroups[g];
            if (group.Chars() && group.mFont)
            {
               ARGB tint = group.mFormat->color(textColor);
               groupColour[0] = tint.getRedFloat();
               groupColour[1] = tint.getGreenFloat();
               groupColour[2] = tint.getBlueFloat();
               groupColour[3] = 1.0;
               for(int c=0;c<group.Chars();c++)
               {
                  int ch = group.mString[c];
                  if (displayAsPassword)
                     ch = gPasswordChar;
                  if (ch!='\n' && ch!='\r')
                  {
                     int cid = group.mChar0 + c;
                     UserPoint pos = mCharPos[cid]-scroll;
                     if (pos.x < clipRight)
                     {
                        while(line<last_line && mLines[line+1].mChar0 >= cid)
                           line++;
                        double lineY = pos.y + mLines[line].mMetrics.ascent;
                        if (lineY>fieldHeight)
                           break;
                        if (pos.y>=GAP)
                        {
                           pos.y = lineY;

                           int a;
                           Tile tile = group.mFont->GetGlyph( ch, a);

                           if (fontSurface!=tile.mSurface)
                           {
                              //if (fontSurface) mTiles->endTiles();
                              fontSurface = tile.mSurface;
                              mTiles->beginTiles(fontSurface,!screenGrid,bmNormal);
                           }

                           UserPoint p(pos.x+tile.mOx*fontToLocal,pos.y+tile.mOy*fontToLocal);
                           if (screenGrid)
                           {
                              toScreenGrid(p,matrix);
                           }

                           double right = p.x+tile.mRect.w*fontToLocal;
                           if (right>GAP)
                           {
                              float *tint = cid>=mSelectMin && cid<mSelectMax ? white : groupColour;
                              if (pos.x < GAP)
                              {
                                 Rect r = tile.mRect;
                                 int dx = (GAP-pos.x)*fontScale + 0.001;
                                 r.x += dx;
                                 r.w -= dx;

                                 if (right>clipRight)
                                 {
                                    r.w = (clipRight-GAP)*fontScale + 0.001;
                                    if (r.w>0)
                                       mTiles->tile(GAP,p.y,r,trans_2x2,tint);
                                 }
                                 else
                                 {
                                    mTiles->tile(GAP,p.y,r,trans_2x2,tint);
                                 }

                              }
                              else if (right>clipRight)
                              {
                                 Rect r = tile.mRect;
                                 r.w = (clipRight-p.x)*fontScale + 0.001;
                                 if (r.w>0)
                                    mTiles->tile(p.x,p.y,r,trans_2x2,tint);
                              }
                              else
                              {
                                 mTiles->tile(p.x,p.y,tile.mRect,trans_2x2,tint);
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }

   }

   if (mTiles && !mTiles->empty())
      mTiles->Render(inTarget,inState);

   if (caret && mCaretGfx && !mCaretGfx->empty())
      mCaretGfx->Render(inTarget,state);
}


void TextField::GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForBitmap,bool inIncludeStroke)
{
   Layout(*inTrans.mMatrix);


   /*
   if (inForBitmap && !border && !background)
   {
      Rect r = mActiveRect.Translated(inTrans.mMatrix->mtx, inTrans.mMatrix->mty);
      for(int corner=0;corner<4;corner++)
          outExt.Add( UserPoint(((corner & 1) ? r.x : r.x1()),((corner & 1) ? r.y : r.y1())));
   }
   else
   */
   if (inForBitmap && border)
   {
      BuildBackground();
      return DisplayObject::GetExtent(inTrans,outExt,inForBitmap,inIncludeStroke);
   }
   else
   {
      for(int corner=0;corner<4;corner++)
      {
         UserPoint pos((corner & 1) ? fieldWidth : 0, (corner & 2) ? fieldHeight: 0);
         //UserPoint pos((corner & 1) ? mActiveRect.x1() : mActiveRect.x,
         //              (corner & 2) ? mActiveRect.y1() : mActiveRect.y);
         outExt.Add( inTrans.mMatrix->Apply(pos.x,pos.y) );
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

void TextField::ClearSelection()
{
   if (mSelectMin!=mSelectMax)
   {
      mSelectMin = mSelectMax = 0;
      mTilesDirty = true;
      mCaretDirty = true;
      mGfxDirty = true;
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
   mTilesDirty = true;
   mCaretDirty = true;
   mGfxDirty = true;
}

void TextField::InsertString(WString &inString)
{
   if (caretIndex<0)
      caretIndex = 0;
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

#ifdef EPPC
   #define iswspace(x) isspace(x)
#endif


static bool IsWord(int inCh)
{
  //return inCh<255 && (iswalpha(inCh) || isdigit(inCh) || inCh=='_');
  // TODO - other breaks?
  return !iswspace(inCh) && inCh!='-';
}

// Combine x,y scaling with rotation to calculate pixel coordinates for
//  each character.
void TextField::Layout(const Matrix &inMatrix)
{
   //double scale = scaleY<=0 ? 0.0 : sqrt( inMatrix.m10*inMatrix.m10 + inMatrix.m11*inMatrix.m11 )/scaleY;
   double scale = sqrt( inMatrix.m10*inMatrix.m10 + inMatrix.m11*inMatrix.m11 );
   bool grid =  ( fabs(fabs(inMatrix.m10)-fabs(inMatrix.m10)))<0.0001 &&
                  fabs(fabs(inMatrix.m00)-fabs(inMatrix.m11))<0.0001 &&
                ( fabs(inMatrix.m10)<0.0001 || fabs(inMatrix.m11)<0.0001);

   if (mFontsDirty || fabs(scale-fontScale)>0.0001 || grid!=screenGrid)
   {
      // fontScale is local-to-pixel scale
      fontScale = scale;
      screenGrid = grid;
      for(int i=0;i<mCharGroups.size();i++)
         mCharGroups[i]->UpdateFont(fontScale,!embedFonts);

      mLinesDirty = true;
      mFontsDirty = false;
      fontToLocal = scale>0 ? 1.0/scale : 0.0;
   }

   if (!mLinesDirty)
      return;

   double font6ToLocalX = fontToLocal/64.0;

   mLines.resize(0);
   mCharPos.resize(0);

   textHeight = 0;
   textWidth = 0;
   if (scaleX==0 || scaleY==0)
      return;

   double oldW = fieldWidth;
   double oldH = fieldHeight;

   Line line;
   int char_count = 0;
   double charX = 0;
   double charY = 0;
   line.mY0 = charY;
   mLastUpDownX = -1;
   double max_x = autoSize!=asNone && !wordWrap ? 1e30 : fieldWidth - GAP*2.0;
   if (max_x<1)
      max_x = 1;
   bool endsWidthNewLine = false;

   for(int i=0;i<mCharGroups.size();i++)
   {
      CharGroup &g = *mCharGroups[i];
      g.mChar0 = char_count;
      int cid = 0;
      int last_word_cid = 0;
      double last_word_x = charX;
      int last_word_line_chars = line.mChars;

      g.UpdateMetrics(line.mMetrics);
      while(cid<g.Chars())
      {
         endsWidthNewLine = false;
         if (line.mChars==0)
         {
            charX = 0;
            line.mY0 = charY;
            line.mChar0 = char_count;
            line.mCharGroup0 = i;
            line.mCharInGroup0 = cid;
            last_word_line_chars = 0;
            last_word_cid = cid;
            last_word_x = 0;
            g.UpdateMetrics(line.mMetrics);
         }

         int advance6 = 0;
         int ch = g.mString[cid];
         mCharPos.push_back( UserPoint(charX,charY) );
         line.mChars++;
         char_count++;
         cid++;

         if (!displayAsPassword && !iswalpha(ch) && !isdigit(ch) && ch!='_' && ch!=';' && ch!='.' && ch!=',' && ch!='"' && ch!=':' && ch!='\'' && ch!='!' && ch!='?')
         {
            if (!IsWord(ch) || (cid>=2 && !IsWord(g.mString[cid-2]))  )
            {
               if ( (ch<255 && !IsWord(ch)) || line.mChars==1)
               {
                  last_word_cid = cid;
                  last_word_line_chars = line.mChars;
               }
               else
               {
                  last_word_cid = cid-1;
                  last_word_line_chars = line.mChars-1;
               }
               last_word_x = charX;
            }

            if (ch=='\n' || ch=='\r')
            {
               // New line ...
               line.mMetrics.fontToLocal(fontToLocal);
               if (i+1<mCharGroups.size() || cid+1<g.Chars())
                  line.mMetrics.height += g.mFormat->leading;
               charY += line.mMetrics.height;
               mLines.push_back(line);
               line.Clear();
               endsWidthNewLine = true;
               continue;
            }
         }

         double ox = charX;
         if (displayAsPassword)
            ch = gPasswordChar;
         if (g.mFont)
            g.mFont->GetGlyph( ch, advance6 );
         else
            advance6 = 0;
         charX += advance6*font6ToLocalX;

         //printf(" Char %c (%d..%d/%d,%d) %p\n", ch, ox, x, max_x, charY, g.mFont);
         if ( !displayAsPassword && (wordWrap) && charX > max_x && line.mChars>1)
         {
            // No break on line so far - just back up 1 character....
            if (last_word_line_chars==0 || !wordWrap)
            {
               cid--;
               line.mChars--;
               char_count--;
               mCharPos.qpop();
               line.mMetrics.width = ox;
            }
            else
            {
               // backtrack to last break ...
               cid = last_word_cid;
               char_count-= line.mChars - last_word_line_chars;
               mCharPos.resize(char_count);
               line.mChars = last_word_line_chars;
               line.mMetrics.width = last_word_x;
            }
            line.mMetrics.fontToLocal(fontToLocal);
            if (i+1<mCharGroups.size() || cid+1<g.Chars())
               line.mMetrics.height += g.mFormat->leading;
            charY += line.mMetrics.height;
            charX = 0;
            mLines.push_back(line);
            line.Clear();
            g.UpdateMetrics(line.mMetrics);
            continue;
         }

         double right = charX;
         if (screenGrid)
            right = ((int)((right*fontScale+0.999)))*fontToLocal;
         line.mMetrics.width = right;
      }
   }

   if ((endsWidthNewLine && multiline) || line.mChars || mLines.empty())
   {
      CharGroup *last=mCharGroups[mCharGroups.size()-1];
      last->UpdateMetrics(line.mMetrics);
      line.mMetrics.fontToLocal(fontToLocal);
      if (endsWidthNewLine)
      {
         line.mY0 = charY;
         line.mChar0 = char_count;
         line.mChars = 0;
         line.mCharGroup0 = mCharGroups.size()-1;
         line.mCharInGroup0 = last->mString.size();
      }
      charY += line.mMetrics.height;
      mLines.push_back(line);
   }

   for(int i=0;i<mLines.size();i++)
   {
      double right = mLines[i].mMetrics.width;
      if (right>textWidth)
         textWidth = right;
   }

   textHeight = charY;
   //printf("textHeight = %f\n", textHeight);
   if (autoSize!=asNone)
   {
      if (!wordWrap)
      {
         fieldWidth = textWidth + 2.0*GAP;
         if (screenGrid)
            fieldWidth += 1;
      }
      fieldHeight = textHeight + 2.0*GAP;
      if (screenGrid)
         fieldHeight += 1;
   }

   maxScrollH = std::max(0.0,textWidth-(fieldWidth-GAP*2));
   maxScrollV = 1;

   // Work out how many lines from the end fit in the rect, and
   //  therefore how many lines we can scroll...
   double clippedHeight = fieldHeight - 2.0*GAP;
   int last = mLines.size()-1;
   if (textHeight>fieldHeight && mLines.size()>1)
   {
      int    lines_visible = 0;
      double lines_height = mLines[last-lines_visible].mMetrics.height;
      lines_visible++;

      while( lines_visible<mLines.size() && lines_height+mLines[last-lines_visible].mMetrics.height<= clippedHeight)
      {
         lines_height += mLines[last-lines_visible].mMetrics.height;
         lines_visible++;
      }

      maxScrollV = mLines.size() - lines_visible + 1;
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
         double extra = (fieldWidth - line.mMetrics.width);
         switch(group.mFormat->align(tfaLeft))
         {
            case tfaJustify:
            case tfaRight:
               extra -= GAP;
               break;
            case tfaLeft:
               extra = GAP;
               break;
            case tfaCenter:
               extra*=0.5;
               break;
         }
         if (extra)
            for(int c=0; c<line.mChars; c++)
            {
               mCharPos[line.mChar0+c].x += extra;
               //mCharPos[line.mChar0+c].y += GAP;
            }
      }
   }

   if ( (fieldWidth!=oldW || fieldHeight!=oldH) && (autoSize==asRight || autoSize==asCenter))
      mDirtyFlags |= dirtLocalMatrix;

   mLinesDirty = false;
   mTilesDirty = true;
   mCaretDirty = true;
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

bool CharGroup::UpdateFont(double inScale,bool inNative)
{
   int h = 0.5 + inScale*mFormat->size;
   int flags = (mFormat->bold.Get() ? 1 : 0 ) |
               (mFormat->italic.Get() ? 2 : 0 ) |
               (mFormat->underline.Get() ? 4 : 0 );
   if (!mFont || h!=mFontHeight || mFlags!=flags )
   {
      Font *oldFont = mFont;
      mFont = Font::Create(*mFormat,inScale,inNative,true);
      if (oldFont)
         oldFont->DecRef();
      mFontHeight = h;
      mFlags=flags;
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
   
   Font* cacheFont = mFont;
   WString cacheFontName = mFormat->font.Get();
   
   inFormat->font.Apply(mFormat->font);
   
   if (cacheFontName != mFormat->font.Get())
   {
      mFont = 0;
      mFontHeight = 0;
      mFlags = 0;
      if (cacheFont) cacheFont->DecRef();
   }
   
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

} // end namespace nme

