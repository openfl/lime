2.0.4 (12/31/2014)
------------------

* Added system mouse cursor support in lime.ui.Mouse
* Added hide/show cursor support in lime.ui.Mouse
* Improved the behavior of the embedded web server
* Fixed the behavior of Image.getPixels
* Fixed embedded font support for OpenFL HTML5
* Fixed handling of dummy ANT_HOME or JAVA_HOME HXCPP values
* Improved default context menu behavior on Flash/OpenFL
* Improved fixed orientation support on iOS (legacy)


2.0.3 (12/27/2014)
------------------

* Improved linking of OpenAL for Android
* Added support for cached `<library />` processing
* Fixed exit code behavior when calling HXCPP
* Fixed minor issues with "lime rebuild tools"


2.0.2 (12/21/2014)
------------------

* Added ARMV7S, ARM64 and X86_64 support for iOS
* Added unofficial Java support
* Added xxhdpi and xxxhdpi icons for Android
* Added initial support for Android (without legacy)
* Upgraded to a newer SDL2 release for desktop
* Improved the behavior of Image.setPixels
* Improved Image.fromBytes for HTML5
* Improved Image.fillRect for HTML5
* Fixed issue causing "bin" directories to appear on rebuild
* Fixed issues with Android ADB
* Fixed an issue with HTML5 copyPixels
* Fixed an infinite loop when loading WAV audio
* Fixed an infinite loop when loading WAV audio (legacy)
* Fixed GL.getShaderPrecisionFormat (legacy)
* Removed unnecessary iOS libraries (legacy)
* Fixed Android x86 builds (legacy)
* Fixed TextField leading (legacy)


2.0.1 (12/04/2014)
------------------

* Added GL.isContextLost
* Added Renderer onRenderContextLost/onRenderContextRestored
* Improved Android device version check
* Changed Firefox to type WEB instead of MOBILE
* Fixed HTML5 touch event coordinates


2.0.0 (11/20/2014)
------------------

* Improved the "lime rebuild" command
* Added a "-dryrun" flag to help test the tools 
* Fixed zero width/height in lime.graphics.Image
* Populate environment with HXCPP config defines
* Fixed double dispatch of HTML5 mouse events
* Improved the "lime.embed" JS command
* Fixed "lime create openfl"
* Made fixes to support the newer Blackberry SDK
* Fixed GraphicsPath on Neko (legacy)


2.0.0-beta (11/13/2014)
-----------------------

* Merged the Lime "legacy" codebase
* Initial steps towards Lime node.js support
* Sped up rasterization of SVG icon images
* Sped up splash image generation
* Improved lime.graphics.Image for some browsers
* Added native PNG/JPG encoding
* Improved $variable handling in project parsing
* Other minor fixes


2.0.0-alpha.8 (11/08/2014)
--------------------------

* Guarded certain CFFI calls
* Fixed discovery of Java install on OS X
* Omitting Android force downgrade on old devices


2.0.0-alpha.7 (11/01/2014)
--------------------------

* Improved handling of haxelib library versions
* Add patched haxe.CallStack to fix C++ stack order
* Fix fonts to use the true font name
* Automatically register fonts embedded in the project
* Fixed and documented the "-args" tool flag
* Added the force downgrade argument when installing on Android


2.0.0-alpha.6 (10/28/2014)
--------------------------

* Added initial support for cubic bezier font outlines
* Added better OpenFL ASCII color on Mac
* Maybe Java optional during build process for SVG rasterizer
* Improved "isText" file detection
* Fixed loading of type BINARY files as TEXT


2.0.0-alpha.5 (10/23/2014)
--------------------------

* Added patched Haxe Boot class, to fix Std.is on Safari
* Added support for the "openfl" command
* Using the proper font name when embedding in Flash
* Improved the handling of font family name detection
* Minor fixes


2.0.0-alpha.4 (10/21/2014)
--------------------------

* Improved parsing of HXML when compiling for the Flash target
* Improved the `<config />` data system
* Enabled splash screen generation for iOS again


2.0.0-alpha.3 (10/20/2014)
--------------------------

* Fixed handling of HXML with comments when targeting Flash
* Added initial support for ".bundle" asset folders
* Added initial support for `<library path="" preload="true" />`
* Passing "-verbose" when appropriate to library handlers
* Improved code completion for FlashDevelop
* Improved population of defines in project file handling
* Fixed "lime create extension"
* Improvements to `<config />` tag merging
* Added Tilesheet TILE_RECT support (legacy)


2.0.0-alpha.2 (10/16/2014)
--------------------------

* Added Lime "legacy" binaries for OpenFL v2 native support
* Merged the Aether tools into Lime
* Improved the "lime rebuild" command
* Added onSaveInstanceState/onRestoreInstanceState on Android
* Added TouchEvent handling on HTML5
* Fixed handling of GL depth and stencil buffers
* Fixed ImageDataUtil fillRect, copyPixels, colorTransform
* Fixed iOS framework paths which include spaces
* Fixed ByteArray.writeBytes when the length is zero
* Fixed the iOS linker flags project option
* Moved to JSON asset libraries instead of serialized ones
* Improved handling of SWF asset embedding
* Improved handling of HTML5 key events
* Disabled HTML5 page scrolling using the arrow keys
* Improved ByteArray support on HTML5
* Fixed HTML5 mouse coordinates when letterboxing
* Fixed "bin" tool paths when Lime is not included in the project
* Many other small fixes
* Fixed sound.length when using streaming OGG audio (legacy)
* Added a proper shutdown for OpenAL audio (legacy)
* Fixed null data in URLLoader on Neko (legacy)
* Added a dead zone filter for joystick events (legacy)


2.0.0-alpha (10/14/2014)
------------------------

* Created an all-new Lime API
* The core architecture is built around Application, Window and Renderer
* Events are similar to C# or signals/slots, and strongly-typed
* Add support for Flash, DOM, Canvas or GL render contexts
* Added bindings to OpenAL, as well a simple unified audio API
* Added networking support, with bindings to cURL on native platforms
* Added cross-target pixel image manipulation features
* Fixed support for Xcode 6 publishing for iOS 8
* Fixed support for BlackBerry 10.3
* Restored support for old Android devices
* Added support for static linking on Windows, Mac and Linux
* Added support for externally defined platform targets
* Improved Flash asset embedding, to handle larger projects
* Added Firefox OS publishing using "lime publish firefox"
* Made the asset library system more flexible
* Many other tool improvements


1.0.1 (06/24/2014)
------------------

* Fixed BlackBerry support
* Fixed a memory leak when using LZMA decoding


1.0.0 (05/29/2014)
-----------------


0.9.9 (05/28/2014)
-----------------

* Fixed ACTIVATE/DEACTIVATE for Windows on minimize/restore
* Fixed Mac fullscreen handling
* Silenced "missing NDLL" warning when not in -verbose mode
* Added "-nocolor" option


0.9.8 (05/27/2014)
------------------

* Fixed issues with Android JNI
* Fixed a GPU texture issue on iOS
* Fixed keyboard to only show if a TextField is type INPUT
* Fixed support for OpenGL on Nvidia drivers for Linux
* Fixed a bug where OpenGL textures were freed improperly
* Improved support for reading audio file length
* Added support for custom user agents in URL requests
* Other minor fixes


0.9.7 (04/22/2014)
------------------

* Merged Lime with NME for code collaboration
* Fixed software rendering path
* Fixed compile for older Android devices
* Added OpenAL support for BlackBerry
* Moved to C++11 by default for iOS builds
* Added additional Android extension callbacks
* Improved handling of Android keyboard/gamepad input
* Confirmed support for the Amazon FireTV
* Improved cursor visibility when switching to/from fullscreen
* Improved support for iOS virtual text input
* Fixed support for BWF wave files
* Fixed color order for PNG encoding


0.9.6 (03/18/2014)
------------------

* Fixed Android library instantiation order
* Fixed Android onKeyUp event
* Fixed volume and back keys on Android
* Added stereoscopic 3D support on Android
* Fixed TextField.textColor rendering
* Improved support for key codes
* Improved support for looping audio
* Minor fixes


0.9.5 (03/04/2014)
------------------

* Improvements to Lime wrapper
* Fixed cURL to support larger header sizes
* Updated the SDL2 backend to support initialization without AA if not supported
* Added support for Android "immersive mode"
* Improved default _sans, _serif and _typewriter font matching for Mac and iOS
* Multiple improvements to Android JNI support
* Added "count" support for drawTiles rendering
* Optimized renderer to perform more with a single draw array
* Improvements for anti-aliased hardware lines
* Optimizations to tessellation algorithm
* Added better support for pre-multiplied alpha, currently per surface
* Memory fixes for Freetype fonts
* Fix listing of Lime samples when running "lime create openfl"
* Added proper charCode and keyCode support for Android keyboard input
* Minor improvement to OpenAL sound
* Multi-threading fix for Android
* Fixed OpenGL ES 2 context support for Tizen
* Keyboard event support on Tizen
* Resolved rare issue when loading BitmapData from bytes
* Minor fixes for Emscripten
* Updated for automated builds: http://openfl.org/builds/lime


0.9.4 (01/27/2014)
------------------

* Fixed support for 8-bit PNG images with alpha
* Fixed software fallback for certain older cards


0.9.3 (01/22/2014)
------------------

* Improved the Android extension API
* Improved OpenAL audio panning behavior
* Fixed crash in ColorMatrixFilter
* Fixed GL drawArrays issue on desktop


0.9.2 (12/31/2013)
------------------

* Fixed Tizen storage directory
* Fixed support for Emscripten


0.9.1 (12/18/2013)
------------------

* Lime wrapper improvements
* Improved performance when loading OGG samples in memory
* Added support for the Tizen emulator


0.9.0 (12/10/2013)
------------------

* Added Tizen support
* Initial wrapper implementation
* Android JNI improvements
* Add OpenGL context lost/restored events
* Fixed support for Android OpenAL audio

