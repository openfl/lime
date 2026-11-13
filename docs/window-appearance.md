# Window appearance

`Window.appearance` requests a native window appearance without recoloring rendered content:

```haxe
import lime.ui.WindowAppearance;

window.appearance = WindowAppearance.Dark;
window.appearance = WindowAppearance.Light;
window.appearance = WindowAppearance.System;
```

The optional `WindowAttributes.appearance` applies the preference during creation. Omitting
the attribute retains existing platform defaults. Assigning `System` explicitly restores
system following on platforms that support it. Invalid or null assignments leave the
previous preference intact.

`window.appearance` reports the requested preference. `window.effectiveAppearance` reports
the applied decoration appearance, or `System` when it cannot be determined. On X11 the
effective value reports the hint, not a guarantee that the window manager honored it.

| Backend | Behavior |
| --- | --- |
| Windows desktop | DWM dark title-bar attribute; unsupported Windows versions retain native styling. System preferences and high-contrast changes are reapplied on theme notifications. High contrast takes precedence. |
| macOS 10.14+ | Per-window Aqua or Dark Aqua appearance. System removes the override, following the application's effective appearance. |
| Linux X11 | Per-window `_GTK_THEME_VARIANT` decoration hint. System removes the hint. Window managers may ignore it. |
| HTML5 | Container `color-scheme`; System permits light and dark, following the browser preference. |
| Wayland, mobile, AIR, Flash, other backends | Preserve the requested preference; effective appearance is `System`. |

The preference does not change OS settings, an application's drawing colors, or global
toolkit settings. Native menus, dialogs, and tray menus retain platform-specific styling;
a window appearance request does not guarantee dark menus. Window methods must be called
on the owning UI thread, as with other native window operations.

The CFFI and HashLink bindings ship with the matching native library. Unit tests in
`ui.WindowTest` cover creation attributes, invalid assignments, transitions, and isolation
between two windows through the normal unit-test CI jobs.
