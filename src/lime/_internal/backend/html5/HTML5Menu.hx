package lime._internal.backend.html5;

import haxe.Timer;
import js.html.DivElement;
import js.html.Element;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.Node;
import js.html.StyleElement;
import js.Browser;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Menu;
import lime.ui.MenuItem;
import lime.ui.Window;
import lime.ui.WindowAppearance;

/**
	Menus drawn in the page, since browsers have none for pages to use: the menu
	bar of a window, across the top of its element, and the dropdowns, submenus
	and context menus opened from it, which are placed over the page.

	The styles use the `lime-menu` classes and `--lime-menu-*` properties, which
	a page's own stylesheet can override.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.ui.Menu)
@:access(lime.ui.MenuItem)
@:access(lime.ui.Window)
class HTML5Menu
{
	// Ahead of the page's own stylesheets, so that they can override it
	private static inline var STYLE:String = ".lime-menu-bar, .lime-menu {
	--lime-menu-background: #f9f9f9;
	--lime-menu-border: #d0d0d0;
	--lime-menu-color: #1b1b1b;
	--lime-menu-disabled-color: #a0a0a0;
	--lime-menu-font: 13px system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
	--lime-menu-highlight: #e3e3e3;
	--lime-menu-separator: #dcdcdc;
	--lime-menu-shadow: 0 4px 12px rgba(0, 0, 0, 0.18);
	box-sizing: border-box;
	margin: 0;
	background: var(--lime-menu-background);
	color: var(--lime-menu-color);
	font: var(--lime-menu-font);
	white-space: nowrap;
	cursor: default;
	-webkit-user-select: none;
	-moz-user-select: none;
	-ms-user-select: none;
	user-select: none;
}
.lime-menu-dark {
	--lime-menu-background: #2b2b2b;
	--lime-menu-border: #454545;
	--lime-menu-color: #f2f2f2;
	--lime-menu-disabled-color: #7c7c7c;
	--lime-menu-highlight: #3e3e3e;
	--lime-menu-separator: #454545;
	--lime-menu-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
}
@media (prefers-color-scheme: dark) {
	.lime-menu-system {
		--lime-menu-background: #2b2b2b;
		--lime-menu-border: #454545;
		--lime-menu-color: #f2f2f2;
		--lime-menu-disabled-color: #7c7c7c;
		--lime-menu-highlight: #3e3e3e;
		--lime-menu-separator: #454545;
		--lime-menu-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
	}
}
.lime-menu-bar { display: flex; overflow: hidden; padding: 2px; }
.lime-menu-bar > .lime-menu-item { padding: 3px 8px; border-radius: 4px; }
.lime-menu { position: fixed; z-index: 2147483647; min-width: 160px; max-height: 100vh; overflow-y: auto; padding: 4px; border: 1px solid var(--lime-menu-border); border-radius: 6px; box-shadow: var(--lime-menu-shadow); }
.lime-menu > .lime-menu-item { display: flex; align-items: center; padding: 4px 8px 4px 0; border-radius: 4px; }
.lime-menu-bar > .lime-menu-item:hover, .lime-menu-item.lime-menu-selected { background: var(--lime-menu-highlight); }
.lime-menu-disabled { color: var(--lime-menu-disabled-color); }
.lime-menu-check { flex: none; width: 24px; text-align: center; }
.lime-menu-label { flex: 1 1 auto; }
.lime-menu-shortcut { margin-left: 32px; opacity: 0.7; }
.lime-menu-arrow { flex: none; width: 16px; margin-left: 16px; text-align: right; }
.lime-menu-separator { height: 1px; margin: 4px 8px; background: var(--lime-menu-separator); }
.lime-menu-keyboard .lime-menu-mnemonic { text-decoration: underline; }";

	private static inline var SUBMENU_DELAY:Int = 200;

	private static var isApple:Bool;
	private static var style:StyleElement;

	/**
		The height of the menu bar, or `0` when there is none.
	**/
	public var height(get, never):Int;

	public var isOpen(get, never):Bool;

	private var bar:DivElement;
	private var barIndex:Int;
	private var barRows:Array<Element>;
	private var keyboard:Bool;
	private var listening:Bool;
	private var menu:Menu;
	private var panels:Array<MenuPanel>;
	private var parent:Window;
	private var submenuTimer:Timer;
	private var swallowedKeys:Array<Int>;

	public function new(parent:Window)
	{
		this.parent = parent;

		barIndex = -1;
		barRows = [];
		keyboard = false;
		listening = false;
		panels = [];
		swallowedKeys = [];

		if (style == null)
		{
			isApple = ~/Mac|iPhone|iPad|iPod/.match(Browser.navigator.platform);

			style = cast Browser.document.createElement("style");
			style.textContent = STYLE;

			var head = Browser.document.head;
			head.insertBefore(style, head.firstChild);
		}
	}

	public function close():Void
	{
		closeAll();
		Browser.window.removeEventListener("keyup", handleKeyUp, true);

		if (bar != null && bar.parentNode != null)
		{
			bar.parentNode.removeChild(bar);
		}

		bar = null;
		barRows = [];
		menu = null;
	}

	public function handleKeyEquivalent(keyCode:KeyCode, modifier:KeyModifier):Bool
	{
		if (menu == null || keyCode == UNKNOWN) return false;

		var modifiers = getModifierMask(modifier);

		if (!isApple && modifiers == KeyModifier.ALT)
		{
			// Alt and a mnemonic opens a menu of the bar, as on Windows
			var items = menu.__items;

			for (i in 0...items.length)
			{
				if (getMnemonic(items[i]) == keyCode)
				{
					keyboard = true;
					openBarItem(i, true);
					return true;
				}
			}
		}

		var item = findKeyEquivalent(menu, keyCode, modifiers);
		if (item == null) return false;

		item.__select();
		return true;
	}

	public function isMenuBarTarget(node:Node):Bool
	{
		return bar != null && node != null && bar.contains(node);
	}

	/**
		Opens `menu` as a context menu with its corner at page coordinates `x` and `y`.
	**/
	public function popup(menu:Menu, x:Float, y:Float):Void
	{
		closeAll();

		if (menu == null || menu.__items.length == 0) return;

		var panel = openPanel(menu, null);
		place(panel, x, y, x, y);
		startListening();
	}

	public function setAppearance():Void
	{
		var theme = getThemeClass();

		if (bar != null) setTheme(bar, theme);

		for (panel in panels)
		{
			setTheme(panel.element, theme);
		}
	}

	public function setMenu(menu:Menu):Void
	{
		// Changes to an open menu bar are shown in place, so remember what is open
		var openIndex = barIndex;
		var selections = [];

		if (openIndex > -1)
		{
			for (panel in panels)
			{
				selections.push(panel.selectedIndex);
			}
		}

		var wasKeyboard = keyboard;

		closeAll();
		this.menu = menu;

		if (menu == null)
		{
			if (bar != null && bar.parentNode != null)
			{
				bar.parentNode.removeChild(bar);
			}

			barRows = [];
			return;
		}

		if (bar == null)
		{
			bar = cast Browser.document.createElement("div");
			bar.className = "lime-menu-bar";
			bar.setAttribute("role", "menubar");
			bar.addEventListener("contextmenu", handleContextMenu);
		}

		setTheme(bar, getThemeClass());

		while (bar.firstChild != null)
		{
			bar.removeChild(bar.firstChild);
		}

		barRows = [];

		for (i in 0...menu.__items.length)
		{
			var row = createBarRow(menu.__items[i], i);
			bar.appendChild(row);
			barRows.push(row);
		}

		if (bar.parentNode == null)
		{
			var element = parent.element;

			if (element == null) return;

			if (element == cast parent.__backend.canvas)
			{
				if (element.parentNode != null) element.parentNode.insertBefore(bar, element);
			}
			else
			{
				element.insertBefore(bar, element.firstChild);
			}
		}

		if (openIndex > -1 && openIndex < menu.__items.length)
		{
			keyboard = wasKeyboard;
			openBarItem(openIndex, false);

			for (i in 0...selections.length)
			{
				if (i >= panels.length) break;

				var panel = panels[i];
				panel.select(selections[i]);

				if (i < selections.length - 1)
				{
					openSubmenu(panel, false);
				}
			}
		}
	}

	private function activate(panel:MenuPanel, index:Int):Void
	{
		var item = panel.items[index];
		if (item == null || item.isSeparator || !item.enabled) return;

		if (item.submenu != null)
		{
			panel.select(index);
			openSubmenu(panel, keyboard);
		}
		else
		{
			select(item);
		}
	}

	private function cancelSubmenuTimer():Void
	{
		if (submenuTimer != null)
		{
			submenuTimer.stop();
			submenuTimer = null;
		}
	}

	private function closeAll():Void
	{
		cancelSubmenuTimer();
		closePanels(0);

		if (barIndex > -1 && barIndex < barRows.length)
		{
			var row = barRows[barIndex];
			row.classList.remove("lime-menu-selected");
			row.setAttribute("aria-expanded", "false");
		}

		barIndex = -1;
		keyboard = false;
		if (bar != null) bar.classList.remove("lime-menu-keyboard");

		stopListening();
	}

	private function closePanels(depth:Int):Void
	{
		while (panels.length > depth)
		{
			var panel = panels.pop();

			if (panel.element.parentNode != null)
			{
				panel.element.parentNode.removeChild(panel.element);
			}
		}
	}

	private function createBarRow(item:MenuItem, index:Int):Element
	{
		var row = Browser.document.createElement("div");
		row.className = "lime-menu-item";
		row.setAttribute("role", "menuitem");
		appendLabel(row, item);

		if (!item.enabled)
		{
			row.classList.add("lime-menu-disabled");
			row.setAttribute("aria-disabled", "true");
		}

		if (item.submenu != null)
		{
			row.setAttribute("aria-haspopup", "true");
			row.setAttribute("aria-expanded", "false");
		}

		var self = this;

		row.addEventListener("mousedown", function(event:MouseEvent)
		{
			event.preventDefault();
			if (event.button != 0 || item.isSeparator) return;

			if (self.barIndex == index && self.panels.length > 0)
			{
				self.closeAll();
			}
			else
			{
				self.keyboard = false;
				self.openBarItem(index, false);
			}
		});

		row.addEventListener("mouseenter", function(event:MouseEvent)
		{
			// Moving across the bar while a menu of it is open opens the others
			if (self.barIndex > -1 && self.barIndex != index)
			{
				self.openBarItem(index, false);
			}
		});

		row.addEventListener("mouseup", function(event:MouseEvent)
		{
			// An item of the bar itself, without a submenu, is a command
			if (self.barIndex == index && item.submenu == null && item.enabled && event.button == 0)
			{
				self.select(item);
			}
		});

		return row;
	}

	private function createPanelRow(panel:MenuPanel, item:MenuItem, index:Int):Element
	{
		var row = Browser.document.createElement("div");

		if (item.isSeparator)
		{
			row.className = "lime-menu-separator";
			row.setAttribute("role", "separator");
			return row;
		}

		row.className = "lime-menu-item";
		row.setAttribute("role", item.checked ? "menuitemcheckbox" : "menuitem");
		if (item.checked) row.setAttribute("aria-checked", "true");

		var check = Browser.document.createElement("span");
		check.className = "lime-menu-check";
		check.textContent = item.checked ? "✓" : "";
		row.appendChild(check);

		var label = Browser.document.createElement("span");
		label.className = "lime-menu-label";
		appendLabel(label, item);
		row.appendChild(label);

		var shortcut = getShortcutText(item);

		if (shortcut != null)
		{
			var span = Browser.document.createElement("span");
			span.className = "lime-menu-shortcut";
			span.textContent = shortcut;
			row.appendChild(span);
		}

		if (item.submenu != null)
		{
			var arrow = Browser.document.createElement("span");
			arrow.className = "lime-menu-arrow";
			arrow.textContent = "›";
			row.appendChild(arrow);

			row.setAttribute("aria-haspopup", "true");
		}

		if (!item.enabled)
		{
			row.classList.add("lime-menu-disabled");
			row.setAttribute("aria-disabled", "true");
		}

		var self = this;

		row.addEventListener("mouseenter", function(event:MouseEvent)
		{
			if (panel.selectedIndex == index) return;

			panel.select(index);

			// After a moment, so that moving to an open submenu across other items keeps it
			self.cancelSubmenuTimer();
			self.submenuTimer = Timer.delay(function()
			{
				self.submenuTimer = null;
				self.openSubmenu(panel, false);
			}, SUBMENU_DELAY);
		});

		row.addEventListener("mouseup", function(event:MouseEvent)
		{
			self.cancelSubmenuTimer();
			self.activate(panel, index);
		});

		return row;
	}

	private function findKeyEquivalent(menu:Menu, keyCode:KeyCode, modifiers:Int):MenuItem
	{
		for (item in menu.__items)
		{
			if (item.isSeparator || !item.enabled) continue;

			if (item.submenu != null)
			{
				var result = findKeyEquivalent(item.submenu, keyCode, modifiers);
				if (result != null) return result;
			}
			else if (item.keyCode == keyCode && getItemModifierMask(item) == modifiers)
			{
				return item;
			}
		}

		return null;
	}

	private function getNextIndex(panel:MenuPanel, start:Int, direction:Int):Int
	{
		var length = panel.items.length;
		var index = start;

		for (i in 0...length)
		{
			index = (index + direction + length) % length;
			if (!panel.items[index].isSeparator) return index;
		}

		return -1;
	}

	private function getThemeClass():String
	{
		return switch (parent.appearance)
		{
			case DARK: "lime-menu-dark";
			case LIGHT: "lime-menu-light";
			default: "lime-menu-system";
		}
	}

	private function handleContextMenu(event:MouseEvent):Void
	{
		event.preventDefault();
	}

	private function handleDocumentEvent(event:js.html.Event):Void
	{
		var node:Node = cast event.target;

		// Clicks and scrolling outside of the menus close them
		if ((event.type == "mousedown" || event.type == "scroll") && (isMenuBarTarget(node) || isPanelTarget(node)))
		{
			return;
		}

		closeAll();
	}

	private function handleKeyDown(event:KeyboardEvent):Void
	{
		var handled = true;
		var panel = panels.length > 0 ? panels[panels.length - 1] : null;
		var barItem = (barIndex > -1 && menu != null) ? menu.__items[barIndex] : null;

		switch (event.keyCode)
		{
			case 27: // Escape
				if (panels.length > 1)
				{
					closePanels(panels.length - 1);
				}
				else
				{
					closeAll();
				}

			case 9: // Tab
				closeAll();

			case 13, 32: // Enter, Space
				if (panel != null)
				{
					activate(panel, panel.selectedIndex);
				}
				else if (barItem != null && barItem.submenu == null && barItem.enabled)
				{
					select(barItem);
				}

			case 38, 40: // Up, Down
				if (panel != null)
				{
					var direction = event.keyCode == 38 ? -1 : 1;
					var start = panel.selectedIndex;
					if (start < 0) start = direction > 0 ? -1 : 0;
					panel.select(getNextIndex(panel, start, direction));
				}

			case 36, 35: // Home, End
				if (panel != null)
				{
					panel.select(event.keyCode == 36 ? getNextIndex(panel, -1, 1) : getNextIndex(panel, 0, -1));
				}

			case 39: // Right
				var item = panel != null ? panel.items[panel.selectedIndex] : null;

				if (item != null && item.submenu != null && item.enabled)
				{
					openSubmenu(panel, true);
				}
				else if (barIndex > -1)
				{
					openBarItem((barIndex + 1) % barRows.length, true);
				}

			case 37: // Left
				if (panels.length > 1)
				{
					closePanels(panels.length - 1);
				}
				else if (barIndex > -1)
				{
					openBarItem((barIndex + barRows.length - 1) % barRows.length, true);
				}

			case 16, 17, 18, 91, 92, 93, 224: // Modifier keys
				handled = false;

			default:
				handled = handleMnemonic(panel, event.key);
		}

		if (handled)
		{
			if (isOpen) setKeyboard(true);

			swallowedKeys.push(event.keyCode);
			event.preventDefault();
		}

		// Keys go to the menus, and not to the application, while they are open
		event.stopPropagation();
	}

	private function handleKeyUp(event:KeyboardEvent):Void
	{
		var index = swallowedKeys.indexOf(event.keyCode);

		if (index > -1)
		{
			swallowedKeys.splice(index, 1);
			event.stopPropagation();
		}
	}

	private function handleMnemonic(panel:MenuPanel, key:String):Bool
	{
		if (panel == null || key == null || key.length != 1) return false;

		var code = key.toLowerCase().charCodeAt(0);

		for (i in 0...panel.items.length)
		{
			var item = panel.items[i];
			if (item.isSeparator) continue;

			if (isApple)
			{
				// Typing selects by the first letter, as on macOS
				if (item.label.length > 0 && item.label.toLowerCase().charCodeAt(0) == code)
				{
					panel.select(i);
					return true;
				}
			}
			else if (getMnemonic(item) == code)
			{
				activate(panel, i);
				return true;
			}
		}

		return false;
	}

	private function handlePanelEnter(panel:MenuPanel):Void
	{
		cancelSubmenuTimer();

		// Reaching a submenu keeps it open, with its item in the parent selected
		var depth = panels.indexOf(panel);

		if (depth > 0)
		{
			var owner = panels[depth - 1];
			owner.select(owner.items.indexOf(panel.menu.parent));
		}
	}

	private function isPanelTarget(node:Node):Bool
	{
		for (panel in panels)
		{
			if (panel.element.contains(node)) return true;
		}

		return false;
	}

	private function openBarItem(index:Int, keyboard:Bool):Void
	{
		var wasKeyboard = this.keyboard || keyboard;
		closeAll();

		if (menu == null || index < 0 || index >= barRows.length) return;

		barIndex = index;
		var row = barRows[index];
		row.classList.add("lime-menu-selected");
		setKeyboard(wasKeyboard);

		var item = menu.__items[index];

		if (item.submenu != null && item.enabled && item.submenu.__items.length > 0)
		{
			row.setAttribute("aria-expanded", "true");

			var panel = openPanel(item.submenu, null);
			var rect = row.getBoundingClientRect();
			place(panel, rect.left, rect.bottom, rect.left, rect.top);

			if (keyboard) panel.select(getNextIndex(panel, -1, 1));
		}

		startListening();
	}

	private function openPanel(menu:Menu, owner:MenuPanel):MenuPanel
	{
		var panel = new MenuPanel(menu);

		var element = panel.element;
		element.className = "lime-menu";
		element.setAttribute("role", "menu");
		setTheme(element, getThemeClass());
		if (keyboard) element.classList.add("lime-menu-keyboard");

		for (i in 0...panel.items.length)
		{
			var row = createPanelRow(panel, panel.items[i], i);
			element.appendChild(row);
			panel.rows.push(row);
		}

		var self = this;

		element.addEventListener("mousedown", function(event:MouseEvent)
		{
			// Keeps the focus where it is
			event.preventDefault();
		});
		element.addEventListener("mouseenter", function(event:MouseEvent)
		{
			self.handlePanelEnter(panel);
		});
		element.addEventListener("mouseleave", function(event:MouseEvent)
		{
			if (self.panels[self.panels.length - 1] == panel)
			{
				self.cancelSubmenuTimer();
				panel.select(-1);
			}
		});
		element.addEventListener("contextmenu", handleContextMenu);

		Browser.document.body.appendChild(element);
		panels.push(panel);

		return panel;
	}

	private function openSubmenu(panel:MenuPanel, keyboard:Bool):Void
	{
		var depth = panels.indexOf(panel);
		if (depth < 0) return;

		closePanels(depth + 1);

		var item = panel.items[panel.selectedIndex];
		if (item == null || item.submenu == null || !item.enabled || item.submenu.__items.length == 0) return;

		var submenu = openPanel(item.submenu, panel);
		var rect = panel.rows[panel.selectedIndex].getBoundingClientRect();
		var panelRect = panel.element.getBoundingClientRect();
		place(submenu, panelRect.right - 2, rect.top - 5, panelRect.left + 2, rect.bottom + 5);

		if (keyboard) submenu.select(getNextIndex(submenu, -1, 1));
	}

	// Places a panel at x, y, or where it fits, to the left of altX or above altY
	private function place(panel:MenuPanel, x:Float, y:Float, altX:Float, altY:Float):Void
	{
		var element = panel.element;
		var width = element.offsetWidth;
		var height = element.offsetHeight;
		var viewWidth = Browser.document.documentElement.clientWidth;
		var viewHeight = Browser.document.documentElement.clientHeight;

		if (x + width > viewWidth) x = Math.max(0, (altX - width >= 0) ? altX - width : viewWidth - width);
		if (y + height > viewHeight) y = Math.max(0, (altY - height >= 0) ? altY - height : viewHeight - height);

		element.style.left = Math.round(x) + "px";
		element.style.top = Math.round(y) + "px";
	}

	private function select(item:MenuItem):Void
	{
		// Closed first, like a native menu, so that the item can change the menus
		closeAll();
		item.__select();
	}

	private function setKeyboard(value:Bool):Void
	{
		keyboard = value;

		if (bar != null)
		{
			if (value) bar.classList.add("lime-menu-keyboard") else bar.classList.remove("lime-menu-keyboard");
		}

		for (panel in panels)
		{
			if (value) panel.element.classList.add("lime-menu-keyboard") else panel.element.classList.remove("lime-menu-keyboard");
		}
	}

	private function startListening():Void
	{
		if (listening) return;
		listening = true;

		Browser.window.addEventListener("keydown", handleKeyDown, true);
		Browser.window.addEventListener("keyup", handleKeyUp, true);
		Browser.window.addEventListener("blur", handleDocumentEvent);
		Browser.window.addEventListener("resize", handleDocumentEvent);
		Browser.document.addEventListener("mousedown", handleDocumentEvent, true);
		Browser.document.addEventListener("scroll", handleDocumentEvent, true);
	}

	private function stopListening():Void
	{
		if (!listening) return;
		listening = false;

		// keyup stays until the keys the menus took are released
		Browser.window.removeEventListener("keydown", handleKeyDown, true);
		Browser.window.removeEventListener("blur", handleDocumentEvent);
		Browser.window.removeEventListener("resize", handleDocumentEvent);
		Browser.document.removeEventListener("mousedown", handleDocumentEvent, true);
		Browser.document.removeEventListener("scroll", handleDocumentEvent, true);
	}

	private static function appendLabel(element:Element, item:MenuItem):Void
	{
		var label = item.label;
		var index = isApple ? -1 : item.mnemonicIndex;

		if (index < 0 || index >= label.length)
		{
			element.appendChild(Browser.document.createTextNode(label));
			return;
		}

		var mnemonic = Browser.document.createElement("span");
		mnemonic.className = "lime-menu-mnemonic";
		mnemonic.textContent = label.charAt(index);

		element.appendChild(Browser.document.createTextNode(label.substr(0, index)));
		element.appendChild(mnemonic);
		element.appendChild(Browser.document.createTextNode(label.substr(index + 1)));
	}

	// macOS browsers take `CTRL`, the default, as the Command key, as macOS applications do
	private static function getItemModifierMask(item:MenuItem):Int
	{
		var mask = getModifierMask(item.keyModifier);

		if (isApple && mask & KeyModifier.CTRL != 0 && mask & KeyModifier.META == 0)
		{
			mask = (mask & ~KeyModifier.CTRL) | KeyModifier.META;
		}

		return mask;
	}

	private static function getKeyName(keyCode:KeyCode):String
	{
		var code:Int = keyCode;

		if (code >= KeyCode.F1 && code <= KeyCode.F12) return "F" + (code - KeyCode.F1 + 1);
		if (code >= KeyCode.F13 && code <= KeyCode.F24) return "F" + (code - KeyCode.F13 + 13);

		return switch (keyCode)
		{
			case BACKSPACE: isApple ? "⌫" : "Backspace";
			case TAB: isApple ? "⇥" : "Tab";
			case RETURN: isApple ? "↩" : "Enter";
			case ESCAPE: isApple ? "⎋" : "Esc";
			case SPACE: "Space";
			case DELETE: isApple ? "⌦" : "Del";
			case INSERT: "Ins";
			case HOME: isApple ? "↖" : "Home";
			case END: isApple ? "↘" : "End";
			case PAGE_UP: isApple ? "⇞" : "PgUp";
			case PAGE_DOWN: isApple ? "⇟" : "PgDn";
			case LEFT: isApple ? "←" : "Left";
			case RIGHT: isApple ? "→" : "Right";
			case UP: isApple ? "↑" : "Up";
			case DOWN: isApple ? "↓" : "Down";
			default:
				(code > 32 && code < 127) ? String.fromCharCode(code).toUpperCase() : null;
		}
	}

	private static function getMnemonic(item:MenuItem):Int
	{
		var index = item.mnemonicIndex;
		if (index < 0 || index >= item.label.length || !item.enabled) return -1;

		return item.label.charAt(index).toLowerCase().charCodeAt(0);
	}

	private static function getModifierMask(modifier:KeyModifier):Int
	{
		var mask = 0;

		if (modifier.ctrlKey) mask |= KeyModifier.CTRL;
		if (modifier.shiftKey) mask |= KeyModifier.SHIFT;
		if (modifier.altKey) mask |= KeyModifier.ALT;
		if (modifier.metaKey) mask |= KeyModifier.META;

		return mask;
	}

	private static function getShortcutText(item:MenuItem):String
	{
		if (item.keyCode == UNKNOWN) return null;

		var key = getKeyName(item.keyCode);
		if (key == null) return null;

		var mask = getItemModifierMask(item);

		if (isApple)
		{
			var text = "";
			if (mask & KeyModifier.CTRL != 0) text += "⌃";
			if (mask & KeyModifier.ALT != 0) text += "⌥";
			if (mask & KeyModifier.SHIFT != 0) text += "⇧";
			if (mask & KeyModifier.META != 0) text += "⌘";
			return text + key;
		}
		else
		{
			var text = "";
			if (mask & KeyModifier.CTRL != 0) text += "Ctrl+";
			if (mask & KeyModifier.ALT != 0) text += "Alt+";
			if (mask & KeyModifier.SHIFT != 0) text += "Shift+";
			if (mask & KeyModifier.META != 0) text += "Meta+";
			return text + key;
		}
	}

	private static function setTheme(element:Element, theme:String):Void
	{
		element.classList.remove("lime-menu-dark");
		element.classList.remove("lime-menu-light");
		element.classList.remove("lime-menu-system");
		element.classList.add(theme);
	}

	// Get & Set Methods
	private function get_height():Int
	{
		return (bar != null && bar.parentNode != null) ? bar.offsetHeight : 0;
	}

	private function get_isOpen():Bool
	{
		return barIndex > -1 || panels.length > 0;
	}
}

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
private class MenuPanel
{
	public var element:DivElement;
	public var items:Array<MenuItem>;
	public var menu:Menu;
	public var rows:Array<Element>;
	public var selectedIndex:Int;

	public function new(menu:Menu)
	{
		this.menu = menu;

		element = cast Browser.document.createElement("div");
		items = menu.items;
		rows = [];
		selectedIndex = -1;
	}

	public function select(index:Int):Void
	{
		if (index >= items.length || (index > -1 && items[index].isSeparator)) index = -1;

		if (selectedIndex > -1) rows[selectedIndex].classList.remove("lime-menu-selected");
		selectedIndex = index;
		if (index > -1) rows[index].classList.add("lime-menu-selected");
	}
}
