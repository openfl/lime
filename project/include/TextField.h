#ifndef LIME_TEXT_FIELD_H
#define LIME_TEXT_FIELD_H

#include "Utils.h"
#include "Graphics.h"
#include "QuickVec.h"
#include "Font.h"
#include "Display.h"

class TiXmlNode;

namespace lime
{



class TextField : public DisplayObject
{
public:
   TextField(bool inInitRef=false);

   void appendText(WString inString);
   Rect getCharBoundaries(int inCharIndex);
   int getCharIndexAtPoint(double x, double y);
   int getFirstCharInParagraph(int inCharIndex);
   int getLineIndexAtPoint(double x,double y);
   int getLineIndexOfChar(int inCharIndex);
   int getLineLength(int inLineIndex);
   WString getLineText();
   int getParagraphLength(int inCharIndex);
   TextFormat *getTextFormat(int inFirstChar=-1, int inEndChar=-1);
   bool isFontCompatible(const WString &inFont, const WString &inStyle);
   void replaceSelectedText(const WString &inText);
   void replaceText(int inBeginIndex, int inEndIndex, const WString &inText);
   int  setSelection(int inFirst, int inLast);
   void setTextFormat(TextFormat *inFormat,int inFirstChar=-1, int inLastChar = -1);
   bool getSelectable() { return selectable; }
   void setSelectable(bool inSelectable) { selectable = inSelectable; }
   void setTextColor(int inColor);
   int  getTextColor() { return textColor; }
   bool getIsInput() { return isInput; }
   void setIsInput(bool inIsInput);
   AutoSizeMode getAutoSize() { return autoSize; }
   void  setAutoSize(int inAutoSize);

   int   getCaretIndex() { return caretIndex; }
   int   getMaxScrollH() { Layout(); return maxScrollH; }
   int   getMaxScrollV() { Layout(); return maxScrollV; }
   int   getBottomScrollV();
   int   getScrollH() { return scrollH; }
   void  setScrollH(int inScrollH);
   int   getScrollV() { return scrollV; }
   void  setScrollV(int inScrollV);
   int   getNumLines() { Layout(); return mLines.size(); }
   int   getSelectionBeginIndex();
   int   getSelectionEndIndex();

   const TextFormat *getDefaultTextFormat();
   void setDefaultTextFormat(TextFormat *inFormat);

   bool  getBackground() const { return background; }
   void  setBackground(bool inBackground);
   int   getBackgroundColor() const { return backgroundColor; }
   void  setBackgroundColor(int inBackgroundColor);
   bool  getBorder() const { return border; }
   void  setBorder(bool inBorder);
   int   getBorderColor() const { return borderColor; }
   void  setBorderColor(int inBorderColor);
   bool  getMultiline() const { return multiline; }
   void  setMultiline(bool inMultiline);
   bool  getWordWrap() const { return wordWrap; }
   void  setWordWrap(bool inWordWrap);
   int   getMaxChars() const { return maxChars; }
   void  setMaxChars(int inMaxChars) { maxChars = inMaxChars; }
   bool  getDisplayAsPassword() const { return displayAsPassword; }
   void  setDisplayAsPassword(bool inValue) { displayAsPassword = inValue; }
   bool  getEmbedFonts() const { return embedFonts; }
   void  setEmbedFonts(bool inValue) { embedFonts = inValue; }


   int   getLineOffset(int inLine);
   WString getLineText(int inLine);
   TextLineMetrics *getLineMetrics(int inLine);

   double getWidth();
   void setWidth(double inWidth);
   double getHeight();
   void setHeight(double inHeight);

   WString getHTMLText();
   void setHTMLText(const WString &inString);
   WString getText();
   void setText(const WString &inString);

   int   getLength();
   double   getTextHeight();
   double   getTextWidth();

   bool  alwaysShowSelection;
   AntiAliasType antiAliasType;
   AutoSizeMode autoSize;
   bool  background;
   int   backgroundColor;
   bool  border;
   int   borderColor;
   bool  condenseWhite;

   TextFormat *defaultTextFormat;
   bool  displayAsPassword;
   bool  embedFonts;
   GridFitType gridFitType;
   int  maxChars;
   bool mouseWheelEnabled;
   bool multiline;
   WString restrict;
   bool selectable;
   float sharpness;
   struct StyleSheet *styleSheet;
   int textColor;
   float  thickness;
   bool useRichTextClipboard;
   bool  wordWrap;
   bool  isInput;

   int  scrollH;
   int  scrollV;
   int  maxScrollH;
   int  maxScrollV;
   int  caretIndex;

   void Render( const RenderTarget &inTarget, const RenderState &inState );

   // Display-object like properties
	// Glyphs are laid out in a local pixel coordinate space, which is related to the
	//  render-target window co-ordinates by the folling members
	double mLayoutScaleH;
	double mLayoutScaleV;
   GlyphRotation mLayoutRotation;
	// Unscaled size, as specified by application
	double boundsWidth;
	double boundsHeight;
   // Local pixel space
	int  textWidth;
	int  textHeight;
   Rect mActiveRect;

   void GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForBitmap,bool inIncludeStroke);
   Cursor GetCursor();
   bool WantsFocus() { return isInput && mouseEnabled; }
   bool CaptureDown(Event &inEvent);
   void Drag(Event &inEvent);
   void EndDrag(Event &inEvent);
   void OnKey(Event &inEvent);
   void DeleteSelection();
   void DeleteChars(int inFirst,int inEnd);
   void InsertString(WString &ioString);
   void ShowCaret(bool inFromDrag=false);
   bool FinishEditOnEnter();

   bool CaretOn();
   bool IsCacheDirty();






protected:
   ~TextField();

private:
   TextField(const TextField &);
   void operator=(const TextField &);
   void Layout(const Matrix &inMatrix);
   void Layout() { Layout(GetFullMatrix(true)); }

   void Clear();
   void AddNode(const TiXmlNode *inNode, TextFormat *inFormat, int &ioCharCount);

   enum StringState { ssNone, ssText, ssHTML };
   StringState mStringState;
   WString mUserString;

	void SplitGroup(int inGroup,int inPos);

	void BuildBackground();
	UserPoint TargetToRect(const Matrix &inMat,const UserPoint &inPoint);
	UserPoint RectToTarget(const Matrix &inMat,const UserPoint &inPoint);

   int  PointToChar(int inX,int inY);
   int  LineFromChar(int inChar);
   int  GroupFromChar(int inChar);
   int  EndOfCharX(int inChar,int inLine);
   int  EndOfLineX(int inLine);
	ImagePoint GetScrollPos();
	ImagePoint GetCursorPos();

   void OnChange();

   bool mLinesDirty;
   bool mGfxDirty;
   bool mFontsDirty;
   bool mHasCaret;


   CharGroups mCharGroups;
   Lines mLines;
   QuickVec<ImagePoint> mCharPos;
   Graphics *mCaretGfx;
   Graphics *mHighlightGfx;
   int      mLastCaretHeight;
   int      mLastUpDownX;

   int mSelectMin;
   int mSelectMax;
   int mSelectDownChar;
   int mSelectKeyDown;
};

} // end namespace lime


#endif
