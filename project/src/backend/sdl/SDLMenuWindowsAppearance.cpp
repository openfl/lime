#include "SDLMenu.h"
#ifdef LIME_SDL_MENU_WIN32
#include "SDLMenuWindowsAppearance.h"
#include <oleacc.h>
#include <cwctype>
#include <map>
#include <vector>
#include <string>
#include <commctrl.h>
#include <algorithm>

namespace lime {
// Owner-drawn items retain their native strings, states and command identifiers.
struct MenuAppearanceItem {
	MSAAMENUINFO accessible;
	std::wstring text;
	std::wstring accessibleText;
	bool bar;
	bool separator;
	bool submenu;
	MenuAppearanceItem (const std::wstring& value, bool isBar, bool isSeparator, bool hasSubmenu)
		: text (value), bar (isBar), separator (isSeparator), submenu (hasSubmenu) {
		for (size_t i = 0; i < text.size () && text[i] != L'\t'; ++i) {
			if (text[i] == L'&') {
				if (i + 1 < text.size () && text[i + 1] == L'&') ++i;
				else continue;
			}
			accessibleText += text[i];
		}
		accessible.dwMSAASignature = MSAA_MENU_SIG;
		accessible.cchWText = (DWORD)accessibleText.size ();
		accessible.pszWText = const_cast<wchar_t*> (accessibleText.c_str ());
	}
};

static std::map<HMENU, std::vector<MenuAppearanceItem*> > appearanceItems;
static const UINT_PTR MENU_APPEARANCE_SUBCLASS = 0x4C4D454E;
static HBRUSH MenuBackground () {
	static HBRUSH brush = CreateSolidBrush (RGB (32, 32, 32));
	return brush;
}

static UINT MenuDPI (HWND window) {
	typedef UINT (WINAPI *GetDPI) (HWND);
	static GetDPI get = (GetDPI)GetProcAddress (GetModuleHandleW (L"user32.dll"), "GetDpiForWindow");
	return get ? get (window) : 96;
}

static int MenuScale (HWND window, int value) { return MulDiv (value, MenuDPI (window), 96); }

static HFONT MenuFont (HWND window) {
	NONCLIENTMETRICSW metrics = {};
	metrics.cbSize = sizeof (metrics);
	typedef BOOL (WINAPI *ParametersForDPI) (UINT, UINT, PVOID, UINT, UINT);
	static ParametersForDPI parameters = (ParametersForDPI)GetProcAddress (GetModuleHandleW (L"user32.dll"), "SystemParametersInfoForDpi");
	if (parameters) {
		if (!parameters (SPI_GETNONCLIENTMETRICS, sizeof (metrics), &metrics, 0, MenuDPI (window))) return NULL;
	} else if (!SystemParametersInfoW (SPI_GETNONCLIENTMETRICS, sizeof (metrics), &metrics, 0)) return NULL;
	return CreateFontIndirectW (&metrics.lfMenuFont);
}

static MenuAppearanceItem* FindAppearanceItem (ULONG_PTR data) {
	// Do not dereference itemData belonging to controls or other menu owners.
	for (auto& menu : appearanceItems) for (auto item : menu.second)
		if ((ULONG_PTR)item == data) return item;
	return NULL;
}

void ReleaseWindowsMenuAppearance (HMENU menu) {
	if (!menu) return;
	int count = GetMenuItemCount (menu);
	for (int i = 0; i < count; ++i) ReleaseWindowsMenuAppearance (GetSubMenu (menu, i));
	auto found = appearanceItems.find (menu);
	if (found == appearanceItems.end ()) return;
	for (int i = 0; i < count; ++i) {
		MENUITEMINFOW info = {};
		info.cbSize = sizeof (info);
		info.fMask = MIIM_FTYPE | MIIM_DATA;
		if (GetMenuItemInfoW (menu, i, TRUE, &info)
			&& std::find (found->second.begin (), found->second.end (), (MenuAppearanceItem*)info.dwItemData) != found->second.end ()) {
			info.fType &= ~MFT_OWNERDRAW;
			info.dwItemData = 0;
			SetMenuItemInfoW (menu, i, TRUE, &info);
		}
	}
	for (auto item : found->second) delete item;
	appearanceItems.erase (found);
}

static void StyleMenu (HMENU menu, bool dark, bool bar) {
	if (!menu) return;
	if (dark && appearanceItems.find (menu) != appearanceItems.end ()) return;
	ReleaseWindowsMenuAppearance (menu);
	MENUINFO background = {};
	background.cbSize = sizeof (background);
	background.fMask = MIM_BACKGROUND;
	background.hbrBack = dark ? MenuBackground () : NULL;
	SetMenuInfo (menu, &background);
	int count = GetMenuItemCount (menu);
	for (int i = 0; i < count; ++i) {
		HMENU child = GetSubMenu (menu, i);
		StyleMenu (child, dark, false);
		if (!dark) continue;
		MENUITEMINFOW info = {};
		info.cbSize = sizeof (info);
		info.fMask = MIIM_FTYPE | MIIM_STRING;
		if (!GetMenuItemInfoW (menu, i, TRUE, &info)) continue;
		std::vector<wchar_t> text (info.cch + 1);
		info.dwTypeData = &text[0];
		info.cch = (UINT)text.size ();
		if (!GetMenuItemInfoW (menu, i, TRUE, &info)) continue;
		auto item = new MenuAppearanceItem (&text[0], bar, (info.fType & MFT_SEPARATOR) != 0, child != NULL);
		info.fMask = MIIM_FTYPE | MIIM_DATA;
		info.fType |= MFT_OWNERDRAW;
		info.dwItemData = (ULONG_PTR)item;
		if (SetMenuItemInfoW (menu, i, TRUE, &info)) appearanceItems[menu].push_back (item);
		else delete item;
	}
}

static void PaintMenuBarBackground (HWND window) {
	HMENU menu = GetMenu (window);
	if (!menu || !GetPropW (window, L"Lime.DarkMenus")) return;
	MENUBARINFO bar = {};
	bar.cbSize = sizeof (bar);
	if (!GetMenuBarInfo (window, OBJID_MENU, 0, &bar)) return;
	RECT frame;
	GetWindowRect (window, &frame);
	HDC dc = GetWindowDC (window);
	if (!dc) return;
	int saved = SaveDC (dc);
	// Leave native item painting intact; fill only the unused menu bar surface.
	for (int i = 0; i < GetMenuItemCount (menu); ++i) {
		RECT item;
		if (GetMenuItemRect (window, menu, i, &item))
			ExcludeClipRect (dc, item.left - frame.left, item.top - frame.top, item.right - frame.left, item.bottom - frame.top);
	}
	OffsetRect (&bar.rcBar, -frame.left, -frame.top);
	FillRect (dc, &bar.rcBar, MenuBackground ());
	RestoreDC (dc, saved);
	ReleaseDC (window, dc);
}

static LRESULT CALLBACK MenuAppearanceProc (HWND window, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR id, DWORD_PTR data) {
	if (message == WM_MEASUREITEM && wParam == 0) {
		auto measure = (MEASUREITEMSTRUCT*)lParam;
		auto item = measure->CtlType == ODT_MENU ? FindAppearanceItem (measure->itemData) : NULL;
		if (item) {
			HDC dc = GetDC (window);
			HFONT font = MenuFont (window);
			HGDIOBJ previous = SelectObject (dc, font ? font : GetStockObject (DEFAULT_GUI_FONT));
			RECT bounds = {};
			DrawTextW (dc, item->text.c_str (), (int)item->text.size (), &bounds, DT_CALCRECT | DT_SINGLELINE | DT_EXPANDTABS);
			measure->itemWidth = bounds.right + MenuScale (window, item->bar ? 16 : 72);
			measure->itemHeight = item->separator ? MenuScale (window, 9) : (bounds.bottom + MenuScale (window, item->bar ? 6 : 10));
			SelectObject (dc, previous);
			if (font) DeleteObject (font);
			ReleaseDC (window, dc);
			return TRUE;
		}
	} else if (message == WM_DRAWITEM && wParam == 0) {
		auto draw = (DRAWITEMSTRUCT*)lParam;
		auto item = draw->CtlType == ODT_MENU ? FindAppearanceItem (draw->itemData) : NULL;
		if (item) {
			int saved = SaveDC (draw->hDC);
			IntersectClipRect (draw->hDC, draw->rcItem.left, draw->rcItem.top, draw->rcItem.right, draw->rcItem.bottom);
			bool disabled = (draw->itemState & (ODS_DISABLED | ODS_GRAYED)) != 0;
			bool selected = (draw->itemState & (ODS_SELECTED | ODS_HOTLIGHT)) != 0;
			HBRUSH brush = selected ? CreateSolidBrush (RGB (62, 62, 62)) : MenuBackground ();
			FillRect (draw->hDC, &draw->rcItem, brush);
			if (selected) DeleteObject (brush);
			COLORREF color = disabled ? RGB (150, 150, 150) : RGB (240, 240, 240);
			RECT text = draw->rcItem;
			int gutter = MenuScale (window, 28);
			if (item->separator) {
				HPEN pen = CreatePen (PS_SOLID, 1, RGB (75, 75, 75));
				HGDIOBJ old = SelectObject (draw->hDC, pen);
				int y = (text.top + text.bottom) / 2;
				MoveToEx (draw->hDC, text.left + gutter, y, NULL);
				LineTo (draw->hDC, text.right - MenuScale (window, 8), y);
				SelectObject (draw->hDC, old);
				DeleteObject (pen);
			} else {
				HFONT font = MenuFont (window);
				SelectObject (draw->hDC, font ? font : GetStockObject (DEFAULT_GUI_FONT));
				SetBkMode (draw->hDC, TRANSPARENT);
				SetTextColor (draw->hDC, color);
				text.left += item->bar ? MenuScale (window, 8) : gutter;
				text.right -= item->bar ? MenuScale (window, 8) : gutter;
				UINT flags = DT_SINGLELINE | DT_VCENTER | ((draw->itemState & ODS_NOACCEL) ? DT_HIDEPREFIX : 0);
				size_t tab = item->text.find (L'\t');
				DrawTextW (draw->hDC, item->text.c_str (), (int)(tab == std::wstring::npos ? item->text.size () : tab), &text, flags);
				if (tab != std::wstring::npos) DrawTextW (draw->hDC, item->text.c_str () + tab + 1, -1, &text, flags | DT_RIGHT | DT_NOPREFIX);
				// Use vector marks so glyph availability does not affect checkmarks or arrows.
				HPEN pen = CreatePen (PS_SOLID, MenuScale (window, 2), color);
				SelectObject (draw->hDC, pen);
				int cy = (text.top + text.bottom) / 2;
				if (draw->itemState & ODS_CHECKED) {
					int x = draw->rcItem.left + MenuScale (window, 9);
					MoveToEx (draw->hDC, x, cy, NULL);
					LineTo (draw->hDC, x + MenuScale (window, 3), cy + MenuScale (window, 3));
					LineTo (draw->hDC, x + MenuScale (window, 9), cy - MenuScale (window, 4));
				}
				if (item->submenu && !item->bar) {
					int x = draw->rcItem.right - MenuScale (window, 13);
					MoveToEx (draw->hDC, x - MenuScale (window, 3), cy - MenuScale (window, 4), NULL);
					LineTo (draw->hDC, x + MenuScale (window, 1), cy);
					LineTo (draw->hDC, x - MenuScale (window, 3), cy + MenuScale (window, 4));
				}
				RestoreDC (draw->hDC, saved);
				DeleteObject (pen);
				if (font) DeleteObject (font);
				return TRUE;
			}
			RestoreDC (draw->hDC, saved);
			return TRUE;
		}
	} else if (message == WM_MENUCHAR) {
		HMENU menu = (HMENU)lParam;
		if (appearanceItems.find (menu) != appearanceItems.end ()) {
			std::vector<int> matches;
			int highlighted = -1;
			for (int i = 0; i < GetMenuItemCount (menu); ++i) {
				MENUITEMINFOW info = {};
				info.cbSize = sizeof (info);
				info.fMask = MIIM_DATA | MIIM_STATE;
				if (!GetMenuItemInfoW (menu, i, TRUE, &info)) continue;
				if (info.fState & MFS_HILITE) highlighted = i;
				auto item = FindAppearanceItem (info.dwItemData);
				if (!item || (info.fState & (MFS_DISABLED | MFS_GRAYED))) continue;
				for (size_t j = 0; j + 1 < item->text.size (); ++j) if (item->text[j] == L'&') {
					if (item->text[j + 1] == L'&') { ++j; continue; }
					if (towupper (item->text[j + 1]) == towupper ((wchar_t)LOWORD (wParam))) matches.push_back (i);
					break;
				}
			}
			if (!matches.empty ()) {
				int match = matches[0];
				for (auto candidate : matches) if (candidate > highlighted) { match = candidate; break; }
				return MAKELRESULT (match, matches.size () == 1 ? MNC_EXECUTE : MNC_SELECT);
			}
			return MAKELRESULT (0, MNC_IGNORE);
		}
	} else if (message == WM_NCDESTROY) {
		ReleaseWindowsMenuAppearance (GetMenu (window));
		RemovePropW (window, L"Lime.DarkMenus");
		RemoveWindowSubclass (window, MenuAppearanceProc, id);
	}
	LRESULT result = DefSubclassProc (window, message, wParam, lParam);
	if (message == WM_NCPAINT || message == WM_NCACTIVATE) PaintMenuBarBackground (window);
	return result;
}

void RefreshWindowsMenuAppearance (HWND window, bool dark) {
	if (!SetWindowSubclass (window, MenuAppearanceProc, MENU_APPEARANCE_SUBCLASS, 0)) return;
	if (dark) {
		if (!SetPropW (window, L"Lime.DarkMenus", (HANDLE)1)) return;
	} else RemovePropW (window, L"Lime.DarkMenus");
	StyleMenu (GetMenu (window), dark, true);
	DrawMenuBar (window);
}

void PrepareWindowsPopupAppearance (HWND window, HMENU menu, bool dark) {
	if (SetWindowSubclass (window, MenuAppearanceProc, MENU_APPEARANCE_SUBCLASS, 0))
		StyleMenu (menu, dark, false);
}
}
#endif
