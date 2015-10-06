2.6.8 (10/05/2015)
------------------

* Updated to a new SDL development version
* Added window.scale, window size and mouse events are in points
* Added Lime Joystick events (alongside Gamepad events)
* Added JPEG and PNG encode support for HTML5
* Improved tooling support for tvOS builds


2.6.7 (10/02/2015)
------------------

* Added initial changes to support Apple tvOS
* Added System.allowScreenTimeout to allow screensaver/sleep
* Updated CFFI to fix "hx_register_prim" issue on Android
* Improved "lime setup linux"
* Fixed preload when the same asset is listed twice
* Fixed an issue with importing lime.Assets in legacy builds


2.6.6 (09/24/2015)
------------------

* Patch support for static C++ builds without use of HXCPP dev
* Fixed a crash that could occur in Flixel 3.x


2.6.5 (09/23/2015)
------------------

* Improved automatic garbage collection for native references
* Removed Cairo reference/destroy (handled internally now)
* Added lime.system.CFFIPointer
* Added *.fla to default exclude asset filter
* Disabled ENABLE_BITCODE on iOS by default
* Fixed an issue with Image.fromBitmapData when using OpenFL
* Fixed a minor issue with copyPixels on Firefox


2.6.4 (09/21/2015)
------------------

* Changed cURL bindings to use Bytes instead of String for callbacks
* Fixed iOS support for CFFI prime (requires HXCPP update)
* Reverted SDL2 version to fix regression in iOS window size
* Disabled Cairo finalizer (for now) to resolve some crash problems
* Reduced "unreachable code" warnings in Firefox
* Fixed iOS multitouch behavior (legacy)


2.6.3 (09/19/2015)
------------------

* Added initial support for CFFI-based finalizer callbacks
* Added initial accelerometer support
* Fixed an issue with erratic mouse values on Mac
* Fixed a minor issue with touch events
* Updated to a newer SDL development version
* Improved the handling of alpha when using image.setPixel
* Updated System.exit to go to background on Android if not an error
* Improved dirty logic with Image pixel operations
* Added an optimization for repeated Font path lookups
* Improved support for non-US keyboard layouts (legacy)


2.6.2 (09/08/2015)
------------------

* Added support for Raspberry Pi 2
* Added lime.app.Future/lime.app.Promise
* Migrated asynchronous lime.Assets calls to use futures
* Added lime.system.CFFI and a new @:cffi macro to use prime
* Migrated Lime CFFI bindings to use new (faster) prime bindings
* Added window.alert (taskbar flash, optional message popup)
* Set the "lime" shortcut on Mac and Linux to use "/usr/local/bin"
* Set the Lime tools to use optional CFFI (can run without NDLL)
* Added -Ddisplay when running "lime display" to help code completion
* Added some minor Windows XP fixes
* Improved lime.app.Event to be more resilient to other macros
* Fixed lime.ui.FileDialog on Mac
* Fixed dispatch of mouse events from touch on HTML5
* Added "onBackPressed" to Android extensions


2.6.1 (08/26/2015)
------------------

* Added window.focus for raising and focusing windows
* Added lime.ui.FileDialog for save/open dialogs
* Made application renderer and window return the first of each array
* Added renderer.type for simpler comparisons
* Implemented AudioBuffer.fromURL for OpenFL Sound support
* Switched to current Lime architecture when processing SVG files
* Fixed color order in image.getColorBoundsRect
* Fixed font embedding for HTML5
* Fixed Cairo inFill, inStroke, inClip
* Fixed some issues in image.copyPixels
* Fixed missing callback in Assets.loadLibrary
* Fixed multi-touch on iOS (legacy)


2.6.0 (08/20/2015)
------------------

* Added support for multiple windows
* Improved Lime application config for multiple windows
* Renamed application.init to application.onWindowCreate
* Changed many application events to include a window reference
* Expanded touch input support, added lime.ui.Touch
* Moved game input events from Window to Gamepad
* Added application onPreloadProgress/onPreloadComplete events
* Added onModuleExit events (for a clean shutdown)
* Added additional key mappings for Flash and HTML5
* Fixed HTML5 text input with spaces
* Fixed event.remove
* Fixed an issue with software-based windows
* Fixed an unused reference in the Android template
* Fixed "std@module_read" errors on Neko


2.5.3 (08/13/2015)
------------------

* Ported the JNI class for Android extension support without legacy
* Added a new Display API for information on connected screens
* Added lime.system.Clipboard and support for System.endianness
* Added window.display and window.setTitle
* Merged updates to the game console render context
* Standardized touch events to use normalized x/y coordinates
* Standardized touch events to dispatch mouse events as well
* Added support for unicode text input on HTML5
* Added support for specifying the iOS simulator device type
* Added conversion to/from UInt for Int abstracts
* Fixed the output color order when image encoding
* Reduced allocations when using gl.vertexAttribPointer
* Improved font hinting when using Cairo
* Fixed decoding support for some JPEG images
* Fixed support for embedded assets on iOS and Android
* Fixed a possible issue in the Flash preloader
* Fixed passing of Haxe defines in the iOS build template
* Fixed support for lime.utils.Log
* Fixed support for event.has


2.5.2 (07/23/2015)
------------------

* Added support for automatic software fallback on native platforms
* Improved the behavior of image getPixel/setPixel
* Fixed native fillRect/floodFill when using certain color values
* Improved color conversion support for Flash
* Fixed issue preventing Neko from reading 32-bit integers correctly 


2.5.1 (07/21/2015)
------------------

* Made Image properly support all PixelFormat/premultiplied types
* Updated PixelFormat names to be more descriptive
* Added prefix support for generated library class names
* Fixed an issue with Assets.loadImage on HTML5
* Fixed support for OpenAL playback using a starting offset


2.5.0 (07/17/2015)
------------------

* Added guards against duplicate gamepad connect events
* Added guards against gamepad events after a disconnect
* Added dead zone and repeat value filtering for gamepad axis
* Added CairoImageSurface, properly separate from CairoSurface
* Improved HTML5 to use the project FPS setting
* Improved asset libraries to have an "unload" method
* Fixed repeated calls to Assets.load* with the same ID
* Fixed "lime build" to not progress without sources
* Fixed a regression in ByteArray.fromFile on Android
* Fixed a bug in arrayBufferView.set
* Quieted libpng "known incorrect profile" messages
* Added a patch to allow Wii Remote detection (legacy)


2.4.9 (07/13/2015)
------------------

* Added lime.system.ThreadPool
* Added lime.utils.Log
* Added image.scroll
* Added event.has
* Improved performance of Flash target logging
* Improved "lime upgrade" when Git is not in the PATH
* Improved image.clone when using canvas
* Updated for compatibility with newer lime-samples
* Updated to use a default icon when none is available
* Updated Assets to use a ThreadPool for asynchronous loads
* Updated to pass -verbose during "run" when in verbose mode
* Fixed an issue when tracing null typed arrays
* Fixed image.copyChannel when clipping is necessary
* Fixed use of cURL basic types as Int
* Improved support for asynchronous SSL requests (legacy)


2.4.8 (07/09/2015)
------------------

* Improved lime.system.BackgroundWorker onComplete
* Improved native bytes to guard against premature GC
* Fixed ENABLE_BITCODE when targeting older iOS versions
* Fixed possible double mouse events on iOS
* Fixed embedded font support on iOS
* Fixed "lime rebuild ios" with some versions of HXCPP
* Fixed mouse middle/right/wheel events on desktop (legacy)


2.4.7 (07/06/2015)
------------------

* Fixed regression in HTML5 typed array support


2.4.6 (07/06/2015)
------------------

* Added lime.system.BackgroundWorker for easy threads
* Made Assets loadImage/loadBytes asynchronous on native
* Removed the ByteArray \__init__ and matching CFFI functions
* Improved the help documentation when using "lime create"
* Fixed a crash that could occur when using Bytes
* Fixed audioSource.play on native when there is no data
* Fixed event.remove when using during an event dispatch
* Fixed the cleanup of OpenAL when closing applications
* Fixed a crash that could occur using cURL on Mac
* Fixed static builds for the Mac target


2.4.5 (07/02/2015)
------------------

* Changed to a new, better Haxe typed array implementation
* Added an improved Bytes (internal) for native targets
* Added lime.utils.LZMA for LZMA compression/decompression
* Expanded support for gamepad devices
* Improved desktop multitouch support
* Exposed decodeBytes/decodeFile for PNG and JPG formats
* Added support for header-only decoding of PNG or JPG
* Improved support for Flash log output
* Improved the "update" command to support GIT submodules
* Restored previous rendering behavior on high-DPI Apple devices
* Fixed support for non-embedded assets on HTML5
* Fixed other cases in the Assets loading code on HTML5
* Fixed imageBuffer.bitsPerPixel to default 32, not 4 (bytes)
* Updated webgl-debug.js for use with HTML5 -Dwebgl -debug
* Fixed a regression in middle and right click events (legacy)
* Fixed possible file handle leaks in the audio code (legacy)
* Added DPI-aware keyboard height for iOS (legacy)
* Added a hack to identify the type of connected gamepads (legacy)
* Fixed the sourceRect coordinates for blitChannel (legacy)
* Added screen resolution width/height for BlackBerry (legacy)
* Fixed a possible overflow in the LZMA buffer (legacy)


2.4.4 (06/08/2015)
------------------

* Handle Flash traces, similar to native logging
* Improved performance of TextLayout
* Improved the behavior of the Android Activity class
* Added window activate/deactivate events on mobile
* Added retina support on Mac desktop
* Allow --meta overrides when using `lime create project`
* Added sleep after Android touch events for better performance
* Improved build support for Raspberry Pi 2
* Fixed -force_load flag on iOS builds
* Fixed GL.clearDepth and GL.depthRange bindings
* Fixed negative System.getTimer value on HTML5
* Added multi-touch desktop support (legacy)
* Improved WAV format loading (legacy)
* Fixed iswalpha crash on BlackBerry (legacy)


2.4.3 (06/01/2015)
------------------

* Improved support for embedded fonts
* Fixed regression when embedding certain OTF fonts


2.4.2 (05/30/2015)
------------------

* Improved iOS and Android build support
* Add support for application.frameRate
* Reduce cURL connection timeout to 30 seconds
* Improved handling of non-transparent image buffers
* Add cubic support to font decomposition
* Added Cairo window resize handling
* Added Cairo Freetype support
* Added check to remove duplicated <dependency /> references
* Minor fix to image premultiply alpha
* Minor fix to "lime create" command
* Minor fix to rectangle.transform
* Fixed Windows Neko builds when not running on Windows 


2.4.1 (05/13/2015)
------------------

* Improve handling of custom error types in HTML5 target
* Guard icon helpers if PNG encoding fails
* Fixed Emscripten rebuild
* Fixed issue on the build server


2.4.0 (05/12/2015)
------------------

* Added Cairo render context and bindings
* Added support for software windows, using Cairo not OpenGL
* Added text input/edit events
* Added onEnter/onLeave events for Window mouse focus
* Added Image getColorBoundsRect
* Added build support for ANGLE
* Removed prevent default for HTML5 arrow and space keys
* Improved Image copyPixels with merge alpha
* Fixed static build support
* Fixed a case where fonts might not be embedded
* Fixed occasional crash with OpenAL on Neko


2.3.3 (04/21/2015)
------------------

* Added audioSource.loops, audioSource.offset, audioSource.length
* Renamed audioSource.timeOffset to audioSource.currentTime
* Fixed onComplete for AudioSource instances
* Fixed support for embedded bytes on HTML5
* Fixed support for hardware anti-aliasing on SDL2 targets
* Fixed some loose file handles in the format decoders
* Fixed a possible crash in copyPixels
* Improved accuracy of URLLoader progress


2.3.2 (04/15/2015)
------------------

* Improved performance of pixel-based operations in Image
* Added support for RGBA (default) and ARGB color order
* Added --port=123 to change the webserver port on HTML5 builds 
* Added support for Unicode Windows system paths
* Added larger icon sizes requested by Windows 10
* Improved functionality of BMP.encode
* Fixed compilation on Android without Sound.java
* Fixed support for -Doptional-cffi
* Fixed haxe.Timer (legacy)


2.3.1 (04/08/2015)
------------------

* Renamed Lime legacy to "lime-legacy" to support hybrid builds
* Added -Dhybrid for using Lime 2 and Lime legacy in the same project
* Improved support for standalone Neko builds on Linux
* Fixed loading of OGG sounds on Android
* Fixed Emscripten support for newer HXCPP
* Fixed a crash using gl.texSubImage2D on Neko
* Fixed missing System.fontsDirectory on Linux
* Fixed crash on NULL system directories
* Fixed crash when font or JPEG file paths are not found
* Added softKeyboardRect support for iOS (legacy)


2.3.0 (03/26/2015)
------------------

* Added initial Lime 2 support for iOS
* Added Mouse.lock and Mouse.warp on native platforms
* Added window.onMouseMoveRelative for use with mouse locking
* Added System.exit
* Added Lime 2 support for haxe.Timer
* Changed window.onMouseMove to dispatch only (x, y)
* Improved window width/height reporting after creation
* Updated ios-deploy, fixed the run command for iOS
* Fixed the ByteArray size returned from Image.getPixels
* Fixed Flash builds for Mac and Haxe 3.2
* Fixed js.Boot for new changes in Haxe 3.2
* Fixed an issue in the Gamepad API
* Fixed the ZipHelper for Haxe 3.2
* Fixed the -Dstats define for HTML5 builds


2.2.2 (03/25/2015)
------------------

* Restored support for OpenFL 2.2
* Added System.fontsDirectory
* Improved Font.fromFile when the file is not available
* Improved HTTP server to allow access from other devices
* Improved System.getTimer to work without haxe.Timer
* Fixed a crash when using GL.bufferData with zero-length data


2.2.1 (03/21/2015)
------------------

* Fixed -rebuild for 32-bit Mac/Linux with newer HXCPP
* Fixed ImageBuffer with newer HXCPP
* Compile fix


2.2.0 (03/20/2015)
------------------

* Added formal support for fonts
* Added formal support for complex text layout
* Added Gamepad input support
* Added Haxe 3.2 support
* Added support for Window fullscreen
* Added support for Window minimized
* Added System directories (user, documents, etc)
* Added the foundation for iOS support
* Improved support for node.js
* Improved support for Lime modules
* Added support for embedded images and sounds
* Changed Module init() to occur sooner
* Implemented Assets.getBytes for Flash BitmapData
* Fixed Assets.isLocal for Flash sound assets
* Fixed Image and ImageBuffer clone()
* Fixed support for HXCPP 3.2.x
* Fixed -rebuild when using the Lime 2 desktop NDLL
* Fixed "lime rebuild" when in the Lime directory


2.1.3 (03/02/2015)
------------------

* Added lime.ui.KeyModifier
* Added key modifier support to Flash and HTML5 keyboard events
* Added support for iOS builds using HXCPP 3.2
* Now "create project" creates unique package IDs instead of a common one
* Now "-clean" is ignored where it does not make sense (such as "run -clean")
* Changed default fullscreen for native targets to SDL_WINDOW_FULLSCREEN_DESKTOP
* Fixed escaping for quotes and spaces in macro calls on Flash target
* Removed Lime native dependency defines from Flash and HTML5 builds
* Improved the behavior of shader isValid/isInvalid
* Added a request for focus after resuming on Android
* Fixed an IME issue that affected some Android keyboards
* Fixed Linux setup on Arch 32-bit systems
* Fixed an issue when building iOS projects to an absolute build path
* Fixed issue where iOS builds may lack some defines (such as HXCPP_API_LEVEL)
* Patched support for Assets.loadSound on Flash target
* Fixed a null check in lime_alc_open_device


2.1.2 (02/20/2015)
------------------

* Minor fixes for upcoming Haxe 3.2 release
* Added "lime deploy" to zip and support upload targets
* Added initial support for Google Drive using "lime deploy"
* Added "Options.txt" reading for iOS builds to include -Dhxcpp_api_level
* Changed "lime update ios" to only update, and not open Xcode
* Added "-xcode" flag to open Xcode on iOS "build" or "run" command
* Fixed the use of "lime" from Windows batch/command files
* Improved "haxelib path" error message when a dependency haxelib is missing
* Improved PathHelper.relocatePath to resolve issues with absolute paths
* Fixed issue preventing projects from changing Flash scaleMode/align
* Improved web font loading on HTML5 target
* Fixed JavaScript minification that was failing on some systems
* Fix issue with disappearing keyboards on certain Android devices
* Fix "isValid" check in GLShader to check for zero
* Set `<config:android install-location="auto" />` by default
* Request focus in resume on Android, in case an extension has focus (legacy)
* Added TILE_BLEND_SUBTRACT (legacy)


2.1.1 (02/13/2015)
------------------

* Added initial Emscripten target support
* Fixed regression in HTML5 font asset embedding
* Minor improvement to SWF embedding for Flash target


2.1.0 (02/11/2015)
------------------

* Refactored, made many events instance-based, not static
* Removed event managers, moved input events to Window class instances
* Moved many Lime tool classes into the public lime.* API
* Added initial Lime 2 support for Android
* Added official Android X86 emulator support
* Added support for munit unit testing suite
* Added System.getTimer for faster delta time calculations
* Added application.removeWindow and window.close
* Added support for a custom asset root URL on HTML5
* Added forced OpenAL cleanup, in case of an unclean exit
* Fixed support for Haxe 3.2 haxelib behavior
* Fixed createImageData issue on HTML5 for WebGL
* Improvements to in-progress Lime text layout API
* Improved handling of Android Debug Bridge on Linux
* Improved handling of ANT_HOME for use with ADB
* Fixed the output of textField.htmlText on Android (legacy)
* Updated TextField implementation (legacy)
* Fixed behavior of ColorMatrixFilter (legacy)
* Fixed textField.setTextFormat with different font (legacy)
* Fixed crash in Capabilities.language on iOS (legacy)


2.0.6 (01/22/2015)
------------------

* Resolved asset embedding for Lime resources
* Added "js-flatten" and "dce full" to HTML5 -final builds
* Made "-minify" occur by default on HTML5 -final builds
* Improved the copy behavior for assets on Android and BlackBerry
* Improved the getDeviceSDKVersion call for Android
* Fixed support for making typed arrays from OpenFL Vector data
* Removed unneeded iOS CFBundleIcon references
* Updated the default iOS deployment to version 5.1.1 for arm64
* Updated to the latest Google Closure compiler version
* Added a ConsoleRenderContext, to continue to grow with console efforts
* Refactored Application, Window, Renderer and other "backend" classes
* Fixed crash in BitmapData rendering (legacy)
* Fixed rotation of TextField instances (legacy)


2.0.5 (01/13/2015)
------------------

* Improved the Windows ICO generation support
* Added support for embedded ICO resources in Windows applications
* Added caching to improve performance when icons exist
* Added lime.graphics.format.JPEG/PNG/BMP classes for encoding 
* Improved KeyCode so it automatically casts to/from Int
* Improved the behavior of Android ADB management
* Migrated to an "Asset Catalog" for iOS icons and launch images
* Added missing iOS icon and launch image sizes
* Added image.merge support for software image blending
* Fixed the color order for Windows icon generation
* Fixed a possible crash issue in empty Image instances
* Fixed support for forwarding HXCPP defines on iOS builds
* Fixed support for dead-code elimination full
* Guarded Android API calls that require newer device versions
* Improved lime.embed to support either a DOM object or ID string
* Improved the behavior of BitmapData getPixels (legacy)
* Exposed support for shifting pitch on OpenAL (legacy)
* Fixed a crash in iOS Capabilities.language (legacy)
* Added bitmapData.merge support (legacy)


2.0.4 (12/31/2014)
------------------

* Added system mouse cursor support in lime.ui.Mouse
* Added hide/show cursor support in lime.ui.Mouse
* Improved the behavior of the embedded web server
* Fixed the behavior of Image.getPixels
* Fixed embedded font support for OpenFL HTML5
* Fixed the Windows application icon
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

