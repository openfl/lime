Changelog
=========

8.0.1 (02/21/2023)
------------------

* Fixed error where low-priority SVG icons (such as the Flixel icon) would override normal- or high-priority PNGs
* Fixed `NativeHTTPRequest` buffer management for neko
* Fixed text field losing focus after copying in HTML5
* Fixed extra or missing slashes in certain cases when loading assets
* Fixed `Assets.isLocal(null)` not checking all asset types
* Fixed getting `Clipboard.text` on Linux
* Fixed building `-static -debug` Windows apps
* Fixed sounds playing twice on iOS
* Fixed command line arguments not being passed to HashLink on macOS
* Fixed a null pointer exception when setting sound position in HTML5
* Fixed cURL not resending data if there's a redirect
* Fixed `FileDialog` behavior when filtering by multiple file extensions, or 0 file extensions
* Fixed error when importing `JNI` during a macro while building for Android
* Fixed building `-static` Linux apps
* Fixed crash when compiling iOS apps with no background color
* Fixed `System.openFile()` on Linux
* Fixed requiring a keystore to sign AIR apps
* Fixed requiring a path to create a keystore
* Fixed HTML5 text fields not updating promptly on Android devices

8.0.0 (08/30/2022)
------------------

* Updated HashLink to version 1.12
* Updated Android minimum SDK version to 21
* Updated Electron template to version 18
* Updated HTML5 to high DPI by default
* Added `--template` command line option to Lime tools
* Added `--appstore` and `--adhoc` command line options for AIR on iOS to Lime tools (to match iOS native)
* Added `-air-simulator` command line option for AIR to Lime tools (avoids packaging full AIR app)
* Added `<config:air profile="value"/>` to optionally support custom AIR profiles in simulator
* Added `setTextInputRect` to `Window` to specify a rectangle that has focus for text input
* Added `JNISafety` to improve JNI communication on Android
* Added `manageCookies` to `HTTPRequest` to support cookies on native platforms (only session for now)
* Added `pitch` property to `AudioSource`
* Added `-Delectron` flag to Electron builds so that it's possible to use `#if electron`
* Added icon priorities to allow a library to provide a default icon that the user can override
* Improved HashLink _.app_ file generation on macOS
* Improved performance of `HTTPRequest` on native platforms with better buffer management
* Improved support for Android 12 (SDK 31) and newer
* Improved output file size if no assets are defined (sets `disable_preloader_assets` define)
* Improved stage sizing on Electron (defaults to `0` for fluid width/height, same as regular browsers)
* Fixed garbage collector crash issue on iOS 12
* Fixed iOS build that failed because of missing _Metal.framework_ dependency
* Fixed switching between light and dark modes on Android destroying the Lime activity
* Fixed `getCurrentTime` on `AudioSource` for streaming sounds on native platforms
* Fixed wrong types on `NativeMenuItem` Flash externs
* Fixed set clipboard when `null` is passed (now changes to an empty string automatically)
* Fixed warnings for deprecated "devicemotion" events on Firefox
* Fixed incompatibility with "genes" Haxelib to allow generating JS Modules

7.9.0 (03/10/2021)
------------------

_Notice: We are moving from our custom build server to Github Actions for releases._
_As a result, official releases support only current macOS versions. Earlier macOS_
_releases are still supported when building Lime from the source._

* Updated support for Haxe 4.2
* Updated the default iOS deployment to 9.0
* Updated `ios-deploy` tool to support newer iOS and Xcode versions
* Added `failIfMajorPerformanceCaveat` setting for window (default false)
* Added bindings for OGG Vorbis on the HashLink target
* Improved iOS target to exclude Core Bluetooth framework
* Improved the performance for AIR application boot times
* Improved error message when attempting to use HashLink target on Haxe 3
* Fixed support for Android screen orientation
* Fixed touch support on Android hardware that return unusual touch IDs
* Fixed an issue with excess bytes saved from `FileDialog` on HTML5
* Fixed null-termination issues on strings returned from `lime.system.System`
* Fixed support for IEM input text on HTML5
* Fixed audio stutter on HTML5 when `force-html-audio` is defined

7.8.0 (06/24/2020)
------------------

* Updated to SDL 2.0.12
* Updated Google Closure to v20200315
* Added support for *.xcframework dependencies on iOS
* Added support for merging "-Info.plist" files from native extensions on iOS
* Fixed warnings when compiling on HTML5 using Haxe 4.1
* Fixed HTML5 focus to return to previous element after using `lime.app.Clipboard`
* Fixed an unnecessary `setTextInputEnabled` workaround on Android
* Fixed return type for `gl.getParameter(GL.RENDERBUFFER_BINDING)`
* Fixed old default iOS simulator version
* Fixed the search string for HaxeObject/JNI to be more precise
* Fixed support for building using `-Djs-es=6`

7.7.0 (01/27/2020)
------------------

* Updated SDL with a patch for high DPI resolution on macOS
* Updated tinyfiledialogs with a Unicode patch on Windows
* Updated macOS to use OpenAL-Soft (rather than deprecated Apple OpenAL library)
* Added missing properties/methods to `lime.utils.ArrayBuffer`
* Added support for NVX_gpu_memory_info OpenGL extension
* Added support for using launch storyboards instead of launch images on iOS
* Updated Android template to use Gradle 5.6.3 and Android Gradle Plugin 3.5.1
* Improved `Assets.unloadLibrary` to allow unloading the default asset library
* Improved HTML5 WebGL to fallback to canvas if "major performance caveat"
* Improved the Electron output template to work without `-lib hxelectron`
* Improved support for x86-64 on Android target
* Improved handling of asset library root paths
* Improved garbage collection performance on `GLRenderbuffer`
* Fixed "auto" window orientation in the AIR template
* Fixed launch of iOS simulator on some systems
* Fixed support for `Clipboard` on HTML5
* Fixed minimize/maximize on some desktop windows that are not resizable
* Fixed `Image.fromBitmapData` to set `buffer.transparent`
* Fixed some issues when toggling fullscreen on Android
* Fixed a potential crash when getting the system locale on iOS or macOS
* Fixed cleanup of Howler.js sounds after they are stopped
* Fixed `FileDialog` to not return as completed if the path is an empty string
* Fixed the default launch screen sizes on the iOS target
* Fixed Gradle paths to jcenter/Google for HTTPS support

7.6.3 (09/11/2019)
------------------

* Fixed copying of 64-bit binaries when using Neko on Windows with Haxe 4
* Fixed support for both 32- and 64-bit Neko on Windows (for Haxe 3 and 4)
* Fixed support for loading `HTTPRequest` data using the HL target

7.6.2 (09/05/2019)
------------------

* Fixed support for 64-bit Neko on Windows (included in Haxe 4 RC 4)

7.6.1 (09/04/2019)
------------------

* Fixed support for array-based form parameters when making HTTP requests
* Fixed incorrect default root path for asset manifests on some platforms
* Fixed a crash on the HL target when pasting non-text data

7.6.0 (08/20/2019)
------------------

* Updated support for Haxe 4 dev versions
* Updated SDL to 2.10
* Updated the default Android target API to 28 (per Google guidelines)
* Updated HashLink support to 1.10 (requires Haxe 4 RC3 or greater)
* Added official support for Android ARM64 architecture
* Added ARM64 as a default architecture in Android builds
* Added `lime.utils.AssetBundle` for standard compressed libraries
* Added support for pure JSON-based asset manifest data
* Added AMD support to generated JavaScript output
* Added `remove` to `lime.utils.ObjectPool`
* Added initial support for `window.onMove` on the AIR target
* Improved the performance of `Image.loadFromBytes` on HTML5
* Improved `DataPointer` to be a more reliable implementation in JavaScript
* Improved support for pre-generated asset libraries
* Improved the same origin check for `HTTPRequest` data-based URIs
* Improved the native main loop behavior on the Android target
* Fixed a compile error when using `flash.system.SystemIdleMode`
* Fixed issues with WebGL on the HTML5 target caused by `DataPointer`
* Fixed an issue where antialiasing was always enabled on HTML5
* Fixed the behavior of `image.copyPixels` in a few cases
* Fixed minor issues when using the `-npm` HTML5 template

7.5.0 (05/14/2019)
------------------

* Update version

7.4.0 (05/14/2019)
------------------

* Renamed the "ndll" folder to "lib"
* Updated SDL to latest development version
* Updated the minimum target Android API from 14 to 16
* Added support for CMYK JPEG decoding on native platforms
* Added an `-npm` option for HTML5 to use Webpack
* Added "hashlink" as an alias for the HL target
* Improved the Zlib default compression level
* Improved support for WinRT applications
* Improved the internal blur implementation
* Improved support for native joystick connection/disconnection
* Improved the output HTML5 script wrapper with better Haxe 3.2 support
* Fixed the values in `lime.ui.MouseButton` to match Lime's historic values (zero based)
* Fixed issues effecting proper `Image` pixel-level APIs when targeting HL
* Fixed a missing button value when dispatching HL mouse events

7.3.0 (04/01/2019)
------------------

* Updated support for Haxe 4 dev versions
* Updated SDL to 2.0.9
* Updated howler.js to 2.1.1
* Added initial display options to improve debugging with VS Code
* Added initial HashLink 1.9 support (requires Haxe 4 dev)
* Added initial support for embedding HTML5 projects in unique isolated JS closures
* Added support for appending dependency JS scripts to the application file
* Added initial support for haptic feedback on HTML5
* Improved `lime display` when `lime build` has not been called
* Improved support for WinRT native builds
* Improved the behavior of `URLRequest` to re-use `Bytes` when writing
* Improved the performance of `URLRequest` on native platforms
* Improved `window.onDropFile` with an initial workaround for HTML5 support
* Moved internal code style to use the Haxe "formatter" library for consistency
* Fixed possible incorrect names in generated package.json for Electron output
* Fixed support for building for Android using ARMv5 or ARMv6 only
* Fixed the event types in `lime.system.ThreadPool`
* Fixed a possible rounding error when calculating application update times
* Fixed cases where HTML5 canvas was not properly enabling image smoothing
* Fixed the behavior of `threadPool.minThreads` to keep threads active
* Fixed incorrect extern in "lime/graphics/opengl/ext" classes on HTML5
* Fixed incorrect `imageBuffer.bitsPerPixel` handling in `Font.renderGlyph`
* Fixed incorrect offset when using `image.copyPixels` with an alpha image
* Fixed Java `HaxeObject.create` to return `null` if handle is `null`
* Fixed exposure of generated `__ASSET__` classes to display completion

7.2.1 (01/07/2019)
------------------

* Updated howler.js to 2.1.0
* Improved the internal HTTP request limit for better transfer speed on HTML5
* Improved the performance for native HTTP requests
* Improved the quality of embedded font meta-data on the HTML5 target
* Improved `lime.utils.Assets` to allow disabling or setting the cache break number
* Fixed `Window` to not dispatch `onClose` on HTML5 (due to some mobile browsers)
* Fixed ability to cancel context menus on HTML5 when they occur on mouse down
* Fixed font support for some video game console targets

7.2.0 (12/04/2018)
------------------

* Improved support for Haxe 4 preview 5
* Improved detection of HTML5 browser key codes to convert to Lime key values
* Improved support for Turkish lowercase values in `lime.text.UTF8String`
* Improved `HTTPRequest` with `-Dallow-status-0` to allow code 0 as success
* Improved project XML to allow `<window background="null" />` or `"transparent"`
* Improved `fileDialog.save` support optional MIME types on HTML5
* Improved munit support by enabling headless testing on the AIR target
* Improved the Electron target template with minor updates
* Improved the standard index.html template for cases when the window is transparent
* Improved performance when converting `lime.utils.DataPointer` on the C++ target
* Improved support for native `Clipboard` events
* Improved use of the `-rebuild` flag when targeting Neko on Windows
* Fixed a memory leak when certain kinds of bytes were loaded from disk
* Fixed a possible multi-thread crash in Lime native Bytes
* Fixed the failure case when loading corrupted PNG images
* Fixed an issue where `window.cursor = null` did not hide the cursor on HTML5
* Fixed cases where the HTML5 backend attempted to cancel non-cancelable events
* Fixed support for `Font.renderGlyph` and `Font.renderGlyphs`
* Fixed an error in `haxe.Timer` if `System.getTimer` returned 0
* Fixed native libraries to build with SSE3 support for better performance
* Fixed use of the `-Ddom` define to force HTML5 DOM render mode

7.1.1 (10/02/2018)
------------------

* Improved the timing on native `HTTPRequest` to process more quickly
* Improved handling of `haxe.Timer` to pause and resume when the application suspends
* Fixed `lime rebuild mac` using Xcode 10 (disabled 32-bit rebuilds by default)
* Fixed an issue in the newer howler.js library regarding IE support
* Fixed a regression in older desktop CPU support
* Fixed an issue when using larger than 64-bit background color values on Flash
* Fixed `context.antialiasing` setting on HTML5 `Window`

7.1.0 (09/26/2018)
------------------

* Updated Harfbuzz to 1.8.8
* Updated OpenAL to 1.19.0
* Updated howler.js to 2.0.15
* Updated build configuration of pixman to better support each platform
* Added `application.meta.version` to the default application template
* Added support for `<undefine name="" />` for undefining values
* Added support for `<window title="" />` in project.xml
* Renamed `cairo.operator` to `cairo.setOperator`/`getOperator` on Haxe 4 builds
* Updated `lime.text.Font` to allow for changes to the font metric meta values
* Removed `-Ddisplay` on `lime display` output for better cached compilation
* Removed prefixes on `imageSmoothingEnabled` internally to remove HTML5 warnings
* Improved use of howler.js to enable sound position
* Improved HTML5 support for certain MP3 audio files
* Improved `Image.loadFromBase64`/`Image.fromBase64` to work on non-HTML5 platforms
* Fixed a possible error when processing directories ending in ".bundle"
* Fixed an issue where multiple `HTTPRequest` instances on native could hang
* Fixed support for `<library type="zip" />` as an alias for type "deflate"
* Fixed minor issues in `TextField` when working with non-UTF8 `String` values
* Fixed use of specific iOS target devices in the AIR project template
* Fixed an exception caused in garbage collection for cURL requests
* Fixed an issue when using `window.readPixels` on HTML5
* Fixed possible exceptions when working with Harfbuzz languages
* Fixed a minor encoding issue in `image.encode (BMP)`
* Fixed setting of `window.parameters` using `WindowAttributes` on creation
* Fixed default use of Visual Studio Community when older versions are installed
* Fixed an exception when checking locale on certain iOS devices
* Fixed compiler errors when using `webgl2.texImage2D` with certain parameters
* Fixed use of WebGL 2, when available, as the default context on HTML5
* Fixed support for `-static` native builds for Windows
* Fixed an issue where `Assets` cache breaking was not working properly
* Fixed compilation issues in Haxe 4 development builds

7.0.0 (08/09/2018)
------------------

* Major API re-design to improve workflow outside of command-line tools
* Migrated the core of the command-line tools into a new project called HXP
* Updated Freetype to 2.9.1
* Updated Android minimum SDK to API 14 and the default target SDK to API 26
* Updated window defaults to always enable depth and stencil buffers
* Updated window defaults to use a 32-bit (instead of 16-bit) backbuffer
* Removed `lime.graphics.Renderer`, functionality moved to `Window`
* Removed `lime.app.Config`, moved `app.frameRate` to `Window`
* Removed `lime.graphics.format.*`, functionality moved to `image.encode`
* Removed `lime.utils.compress.*`, functionality moved to `lime.utils.Bytes`
* Removed `lime.ui.Mouse`, functionality moved to `Window`
* Renamed `lime.app.Preloader` to `lime.utils.Preloader`
* Removed `lime.text.TextLayout`, replaced with native Harfbuzz bindings
* Moved `lime.project` types into `lime.tools`
* Moved `lime.utils.GLUtils` functionality to `GLProgram` and `GLShader`
* Added new `lime.graphics.RenderContext` with more lightweight API bindings
* Divided OpenGL support into separate `OPENGL`, `OPENGLES` and `WEBGL` types
* Compatibility APIs are provided in one direction (GL -> GLES -> WebGL)
* Added `lime.ui.WindowAttributes` with broader context creation control
* Sub-classing `Application` now requires no `window` argument for most methods
* Multi-window applications should listen to `app.onWindowCreate` instead
* Added support for Haxe Eval target, and beta support for HashLink (on dev)
* Added Windows 64-bit support, Android ARM64 support, progress on WinRT support
* Added bindings for the Harfbuzz native text layout library
* Added `lime.ui.MouseButton` and `lime.ui.MouseWheelMode`
* Added MojoAL support (as an alternative to OpenAL-Soft) in dev builds
* Added cURL Multi support
* Added support for `<config:air languages="" />`
* Exposed `window.stage` and `window.element` on Flash/HTML5 targets
* Improved native build times by not relying on macros for CFFI
* Improved mouse event bindings, improved consistency of mouse wheel behavior
* Improved HTML5 fullscreen exit to dispatch a restore, not a resize event
* Improved `lime.math.*` classes to allow for less GC activity
* Improved support for Electron on Linux to allow for WebGL on more drivers
* Improved quality for HTML5 frame rate when set to lower than VSync
* Improved `HTTPRequest` to dispatch a progress event when loading locally
* Fixed some cases where allocation could occur during native GC
* Fixed use of future.then when the result is an error condition
* Fixed issues with some of the equations in `lime.math.*`
* Fixed warning in Chrome caused by default HTML5 template
* Fixed unnecessary AL cleanup message on exit
* Fixed replay of existing native AudioSource sounds
* Fixed Unicode paths on Windows when returning paths from the system
* Fixed pasting Clipboard data when application first launches
* Fixed webfont loading on mobile Safari
* Fixed issue with AL.source3i types
* Fixed support for iOS entitlements paths that include spaces

6.4.0 (06/01/2018)
------------------

* Updated NPM dependency to `file-saver` from `file-saverjs`
* Updated Android ARMv7 builds to use `armeabi-v7a` instead of `armeabi-v7`
* Added (Beta) support for `electron` (`html5 -electron`) target
* Added `window.onExpose` event (useful when not rendering every frame)
* Added `raspberrypi` or `rpi` as a target alias
* Improved `Locale` to better handle `en_US-en` style strings
* Improved handling of iOS locale values
* Improved support for current Xcode versions by using an `.entitlements` file
* Improved support for mouse "release outside" behavior on HTML5
* Improved support for current Raspberry Pi OpenGL/EGL libraries
* Improved Android Gradle template to include Maven for native extensions
* Improved error handling when a library handler does not execute properly
* Fixed crash in `ObjectPool` when setting initial size
* Fixed setting `powerOfTwo = true` for an `ImageBuffer` with a canvas source
* Fixed SWF font generation to limit kerning values to the SWF spec maximum
* Fixed some cases where `HOME` environment variable might return `null`

6.3.1 (05/11/2018)
------------------

* Improved support for \*.bundle libraries within an asset folder
* Improved the output of `lime help`
* Fixed the behavior of `<define />` to behave like `<haxedef />` + `<set />`

6.3.0 (05/04/2018)
------------------

* Updated SDL to 2.0.8
* Updated howler.js to 2.0.9
* Updated Android NDK platform to a minimum of API 14
* Updated macOS minimum support version to 10.9
* Added support for `-D foo` in addition to `-Dfoo`
* Added support for `--` in addition to `-args` for runtime arguments
* Added catching of key/value runtime arguments as `window.config.parameters`
* Added support for `--window-` flags at runtime on Lime applications
* Added a workaround to fix memory leaks in Apple's OpenAL implementation
* Added initial HTML5 accelerometer sensor support
* Added support for exporting multiple iOS IPA types when using `lime deploy`
* Added `ENHANCED` profile to AIR extern types
* Improved the behavior of `lime setup`
* Improved the output of `lime help`
* Improved failed sound loading on HTML5 to print a runtime warning
* Improved support for multiple threads in OpenAL, Cairo and cURL GC
* Improved the generation of webfonts to ignore non-essential formats
* Improved behavior when calling closure compiler to minify JS
* Improved `openfl.Vector` to typed array conversion to support OpenFL 8
* Improved `Assets.getPath` to return the first path if using a path group
* Improved support for `KHR_debug` in OpenGL
* Improved handling of errors within OpenAL generation of sources and buffers
* Improved window focus mouse clicks to still fire an event
* Improvde handling of disposed native `AudioSource` objects
* Improved support for opening files with spaces in the path
* Improved the Gradle template to use jcenter instead of maven for dependencies
* Fixed detection of font family names on some Android 4.x devices
* Fixed support for `-dce full` with `embed=true` assets on native
* Fixed a small memory leak in Zlib compress
* Fixed a small memory leak when using cURL request headers
* Fixed a small memory leak in `gamepad.guid`
* Fixed support for a software fallback when GL support is too old
* Fixed a regression in support for static desktop builds
* Fixed a possible garbage collection issue in cURL support
* Fixed calling `UTF8String.substr()` internally without a length field
* Fixed request of keyboard input on WebKit when in fullscreen
* Fixed a possible issue when building on macOS with spaces in the Lime directory
* Fixed the behavior of `embed="false"` assets on HTML5
* Fixed a possible race condition in `-Dsimulate-preloader` on Flash target
* Fixed support for additional iOS icon sizes
* Fixed fullscreen text input on WebKit browsers
* Fixed an issue using `Image.fromBase64` in ES6/NPM-based builds
* Fixed disabling of vsync on native targets when not desired

6.2.0 (02/16/2018)
------------------

* Added new implementation of `Font.renderGlyphs` for native platforms
* Added generation of font metrics for embedded HTML5 fonts
* Improved support for ANGLE builds on Windows
* Improved accuracy of file seeking in streaming OGG Vorbis sounds on native
* Fixed regression in `renderer.readPixels` when using an OpenGL renderer
* Fixed addition of an empty character when using arrow keys on HTML5 text input
* Fixed fallback for OpenGL ES 2.0 on older iOS devices when 3.0 is not available
* Fixed using environment variables to define the path to the Emscripten SDK
* Fixed letting the user focus outside a Lime embed when text input is enabled
* Fixed `FileDialog.save` to require FileSaver.js when using CommonJS

6.1.0 (02/07/2018)
------------------

* Added OpenGL ES 3.0 support on iOS
* Added `System.deviceVendor` and `System.deviceModel`
* Added `System.platformLabel`, `.platformName` and `.platformVersion`
* Added support for `<config:html5 dependency-path="lib" />`
* Added support for `<config:air sdk-version="25.0" />`
* Improved garbage collection behavior in `lime.net.curl.CURL`
* Improved performance when requesting static `System` values repeatedly
* Improved Xcode template for iPhone X and Xcode 9.2
* Renamed `-Dmodular` to `-Dlime-modular` (to allow for using lib modular)
* Fixed a possible crash in `ImageDataUtil.gaussianBlur`
* Fixed an iOS template path for "haxe/Build.hxml"
* Fixed an issue when setting volume in HTML5 before playback starts
* Fixed default framebuffer binding when using iOS simulator
* Fixed support for properly detecting MP3 format in some files
* Fixed support for builds on macOS/Linux when `$HOME` variable is not present
* Fixed crash in continuous-testing when no window can be initialized

6.0.1 (01/16/2018)
------------------

* Minor fix for `haxelib run openfl setup` command-line alias installation

6.0.0 (01/15/2018)
------------------

* Added `-watch` for simple \*.hx file watching support on commands
* Added support for OpenAL effects extension where available
* Added support for forcing a WebGL 1 context at runtime
* Added support for defining an HTML5 DOM renderer at runtime
* Added support for automatic iOS device provisioning and registration
* Added improved support for CommonJS output
* Improved support for the `haxe-modular` library
* Improved support for haxelibs that define `classPath` in haxelib.json
* Improved performance of `image.copyPixels` on HTML5 when image is not a canvas
* Improved use of external libraries when using CommonJS
* Improved the quality of locale values returned on Windows
* Improved handling of null responses in `HTTPRequest`
* Improved `ObjectPool` to not use generics on HTML5 for better file size
* Fixed issues preventing compilation of tools for Node.js
* Fixed use of `rootPath` when loading packed asset libraries
* Fixed launch image sizes for iPhone X
* Fixed support for `-Dnocffi` when compiling CLI tools
* Fixed a possible range error in `DataPointer`
* Fixed a minor debug message when HXCPP "std" is statically linked

5.9.1 (11/30/2017)
------------------

* Updated howler.js with minor fixes for IE11 and Firefox browsers

5.9.0 (11/29/2017)
------------------

* Added support for {{variable}} substitution in template file/folder names
* Added support for packed asset libraries, with optional compression
* Added initial support for Adobe native extensions (ANE) for AIR
* Added `-Dlime-default-timeout` to override the default HTTPRequest timeout
* Added a prompt for keystore password on Android if no password is provided
* Added a hint to request a discrete GPU on dual-GPU Windows systems
* Added a general "ios/template" template path for copying additional files
* Added ability to export iOS `-archive` on build
* Added ability to `lime deploy ios` and output IPA for store or ad-hoc
* Improved `-verbose` to be ignored by default on `lime display` for IDEs
* Improved iOS launch image list to support iPhone X fullscreen resolution
* Improved CSS font generation to skip formats that are not able to convert
* Improved the behavior of `<window resizable="false" />` on HTML5
* Fixed handling of HTTP status 0 as an error when not running on Tizen HTML5
* Fixed an issue with `ContextMenuItem`/`NativeContextMenuItem` for Flash/AIR
* Fixed the AIR target install folder if `<meta company="" />` is empty
* Fixed reference to the `EMSCRIPTEN_SDK` when targeting Emscripten/WebAssembly
* Fixed an issue with double playing of sound on Firefox using howler.js
* Fixed a possible error in some web browsers when reloading the current page
* Fixed handling of the newer iOS simulator and file extensions for AIR builds
* Fixed return to Android fullscreen when dismissing an on-screen keyboard
* Fixed a minor naming issue when using newer HXCPP and MSVC for static builds
* Fixed setting of "ios" and "android" project values when using AIR iOS/Android
* Fixed handling of Haxe version output with newer Haxe development build

5.8.2 (11/10/2017)
------------------

* Updated cURL to 7.56.1 and changed SSL library from axTLS to mbedTLS
* Updated howler.js to 2.0.5, FileSaver.js to 1.3.3
* Added `-Dcurl-verbose` for additional cURL debug info in native `HTTPRequest`
* Improved support for `<window color-depth="32" />` on HTML5 target
* Improved `renderer.readPixels` on native platforms to allow transparency
* Fixed the behavior of `<asset path="Assets" library="default" />`

5.8.1 (11/06/2017)
------------------

* Added support for `AudioBuffer.fromBytes` on HTML5
* Added initial support for `fileDialog.save` on HTML5 (using FileSaver.js)
* Added initial support for native extensions on the Adobe AIR target
* Improved the behavior of missing webfonts to no longer crash a web application
* Improved `window.onClose` to be cancelable on HTML5
* Improved tools to print warning for unrecognized `<asset type="" />` values
* Fixed support for Adobe AIR where `nativeWindow` is `null`

5.8.0 (10/24/2017)
------------------

* Added `httpRequest.withCredentials` for sending cookies with web requests
* Added initial support for `Touch.onCancel` events
* Restored `false` as the default `httpRequest.enableResponseHeaders` value
* Improved image loading to better support progress events on some browsers
* Improved support for `HTTPRequest` headers on native platforms
* Improved the handling of `lime.utils.Log` output on web browsers
* Improved `lime.utils.ObjectPool` to allow abstract types
* Improved AIR builds to support the `<certificate />` tag for signing
* Improved the default window size for AIR output for mobile platforms
* Improved AIR template to respect `<window allow-high-dpi="" />` for iOS
* Improved AIR template to support additional icon sizes for mobile
* Fixed the behavior of tailing the `trace` log on Windows/Flash target
* Fixed HTML5 "same origin" calculation for CORS requests
* Fixed return to Android fullscreen after losing window focus
* Fixed support for `ANDROID_GRADLE_TASK` with command-line arguments
* Fixed support for relative provisioning profile paths for AIR target

5.7.1 (10/12/2017)
------------------

* Updated default `MACOSX_DEPLOYMENT_TARGET` on macOS to 10.7
* Improved native `HTTPRequest` to complete as error if response status is error
* Fixed `HTTPRequest` to treat HTTP status code 400 as an error

5.7.0 (10/10/2017)
------------------

* Updated Freetype to 2.7.1, compiled with Harfbuzz/PNG support enabled
* Added initial Adobe AIR backend support for multiple windows, alerts, etc
* Added `threadPool.onRun` to be notified when work is about to be run
* Added `ModuleHelper.addModuleSource` to improve JS modules from HXP projects
* Added initial Dockerfile script
* Added a polyfill for `performance.now()` to restore iPhone 4 HTML5 support
* Improved Raspberry Pi support by adding "Escape" as a default key to exit
* Improved support for non-premultiplied alpha in `imageDataUtil.gaussianBlur`
* Improved native `HTTPRequest` to size bytes initially based on Content-Length
* Improved support for Xcode 9.1
* Improved support for combined characters in `TextLayout`
* Fixed setting of `MACOSX_DEPLOYMENT_TARGET` on macOS
* Fixed support for resolving iOS provisioning profiles for AIR/iOS on Windows
* Fixed the addition of the HTML5 default cache break string for assets
* Fixed default asset type assignment for files with upper-case file extensions
* Fixed support for Raspberry Pi
* Fixed `threadPool.onProgress` to dispatch in the proper foreground thread
* Fixed native `HTTPRequest` to calculate timeout from when requests run

5.6.0 (09/26/2017)
------------------

* Added `lime.system.FileWatcher` for notifications of file events
* Added support for color output on the Windows 10 standard command prompt
* Added support for `lime config NAME VALUE` to add/set config values
* Added initial template support for `lime test winjs` for HTML5/UWP support
* Updated haxe.io.Bytes to match current official version
* Improved key events to always set the key modifier on alt/ctrl/shift key press
* Improved support for Adobe AIR iOS and Android builds
* Improved Android builds to minimize to background on back button and not exit
* Improved Linux target to build without HXCPP liblinuxcompat.a
* Improved support for setting `-dce` on the command-line
* Fixed support for setting `--window-minimized`, maximized and hidden using CLI
* Fixed escaping of spaces in Windows paths
* Fixed the behavior of `image.copyPixels` using an alpha image
* Fixed the class path order when embedding Flash assets in certain conditions
* Fixed support for Tizen HTML5 applications
* Fixed progress event update on HTML5 HTTPRequest uploads
* Fixed `ImageHelper.resizeImage` to properly handle null parameters

5.5.0 (09/12/2017)
------------------

* Added an instance-based API for cURL (such as `new CURL ()`)
* Added `<config:ios non-exempt-encryption="true" />` setting value
* Added generation of source map when minifying HTML5 on debug
* Deprecated `lime.net.curl.CURLEasy` in favor of `CURL`
* Updated tinyfiledialogs to 2.9.3
* Updated bundled Google Closure Compiler to v20170806
* Improved the functionality of `System.endianness`
* Improved Adobe AIR `deploy` command to generate a \*.bundle file
* Improved the behavior of native HTTPRequest for better memory management
* Fixed endianness issues in `image.setPixels`
* Fixed support for `image.copyPixels` using alpha image and offset point
* Fixed support for newer HXCPP, including dynamic libs only on Haxe 3.2.1
* Fixed ability to exclude default architectures on builds
* Fixed support for `<window fullscreen="false" />` on Android
* Fixed minor issues caused by detecting some AWD files as text

5.4.0 (08/25/2017)
------------------

* Added tooling for Adobe AIR (`lime test air`, `lime test windows -air`, etc)
* Added externs for Adobe AIR classes and types
* Added `<haxelib repository="" />` for choosing a custom haxelib repository path
* Added OpenGL ES 3 API support (currently enabled on Linux and Emscripten)
* Added support for setting `HAXELIB_PATH` environment variable in projects
* Changed the output directory to not include the build type by default
* Improved HTML5 to default images to canvas, not a typed array
* Improved HXP to handle `-nocolor`, `-verbose` and other compile flags
* Improved HXP to be able to update environment variables for build process
* Fixed tvOS target to use `<config:tvos provisioning-profile="" />`
* Fixed Android builds when using an Android SDK older than API 23
* Fixed an issue when running command-line tools from a root directory
* Fixed UTF-8 `charCodeAt` when index is out of range
* Fixed the `strength` property of `ImageDataUtils.gaussianBlur`

5.3.0 (07/31/2017)
------------------

* Added support for WebAssembly (`emscripten -webassembly` or `-wasm`)
* Added `lime -version` for simpler Lime version output
* Added `@:compiler` to add extra compiler arguments to HXP projects
* Updated howler.js to 2.0.4, plus an additional Firefox WebAudio patch
* Improved support for using Lime in local .haxelib directories
* Improved detection of default asset type in command-line tools
* Improved support for HTML5 -Dmodular builds
* Improved handling of error messages from howler.js
* Fixed support for asset libraries in Emscripten/WebAssembly target
* Fixed `lime create extension` to preserve `ANDROID_GRADLE_PLUGIN` variable
* Fixed support for preloading fonts on Safari

5.2.1 (06/21/2017)
------------------

* Improved HTTPRequest with default "Content-Type" headers when sending data
* Fixed case where HTML5 could preload sounds twice, unintentionally
* Fixed support for compiling HTML5 -Dmodular builds

5.2.0 (06/20/2017)
------------------

* Added ability to override the target output directory
* Added `Assets.hasLibrary` to check if a given library is registered
* Improved webfonts to cache upon generation and not save in asset directory
* Updated JavaScript timers to use `performance.now()` instead of `new Date()`
* Fixed support for *.bundle directories which include "include.xml"
* Fixed `AssetLibrary` to preload non-embedded assets if set to preload
* Fixed an issue when converting non-String values to `UTF8String`
* Fixed an issue with Node http-server resolving properly to localhost
* Fixed support for `lime test linux -32` on 64-bit systems

5.1.0 (06/07/2017)
------------------

* Added `lime.text.UTF8String` with unifill for handling UTF-8 text
* Added support for `Clipboard.onUpdate` on native and HTML5
* Added initial support for HTML5 fullscreen
* Added initial support for `window.setIcon` and `window.title` on HTML5
* Added support for 32-bit GL color depth on native platforms
* Added support for making 64-bit Windows builds
* Added support for automatically detecting latest Android build tools
* Added support for setting `<config:android build-tools-version="" />`
* Added support for `<config:ios allow-insecure-http="" />`
* Added support for `<config:android gradle-build-directory="" />`
* Updated Node http-server to version 0.10.0
* Improved handling of crossOrigin requests on HTML5 for same-origin
* Improved the accuracy of `image.copyPixels` when using alpha image
* Improved performance of ObjectPool when constantly recycling objects
* Improved `image.setPixels` to accept bytes and offset
* Improved performance of creating a new Image with no fill color
* Fixed issue with OpenAL GC
* Fixed loading of some WAV files
* Fixed minor issues in using output of `lime display` for code completion
* Fixed semi-transparent fillRect on canvas-based Image
* Fixed minor issues with cURL

5.0.3 (05/24/2017)
------------------

* Reverted inclusion of custom haxelib build in Lime tools
* Support for wildcard versioning requires a compatible install of haxelib
* Added support for optional runtime overriding of haxelib script
* Improved handling of haxelib errors during HXML generation
* Fixed support for uploading larger byte objects using HTTPRequest
* Fixed support for config.rootPath

5.0.2 (05/22/2017)
------------------

* Improved support for finding versioned haxelib path when using haxelib git

5.0.1 (05/22/2017)
------------------

* Fixed an issue with PathHelper.getHaxelib outside of Lime tools
* Fixed regressions in haxelib path resolution

5.0.0 (05/19/2017)
------------------

* Updated the OpenGL bindings for better performance on HTML5
* WebGL-specific signatures are now available using "WEBGL" suffix
* Added support for wildcard haxelib versions (such as "1.0.\*")
* Added a new joystick.onTrackballMove with both x and y values
* Added support for ThreadPool when there is no Application instance
* Added haxelib to Lime tools to support path resolution fixes
* Added ProjectXMLParser.fromFile for consistency
* Updated default SWF version to 17 to prevent common compile issues
* Removed deprecated config.assetsPrefix (use config.rootPath)
* Improved support for HXP projects on Windows
* Improved performance of image.copyPixels
* Improved the `lime create extension <name>` template
* Improved the behavior of Flash Player logging on Linux
* Improved memory use in Matrix4 and TextLayout
* Improved render event to allow canceling (avoids a screen flip)
* Improved `lime setup` to quiet the "no setup required" message
* Fixed dead-code-elimination with OpenGL extension classes
* Fixed support for >, <, >=, <= and == in XML "unless" attribute
* Fixed complete exit on Android when using the back button

4.1.0 (05/04/2017)
------------------

* Updated SDL to latest development version
* Updated Freetype to 2.7.1
* Updated Harfbuzz to 1.4.6
* Updated Howler.js to 2.0.3
* Added window.alwaysOnTop, with initial support on Windows and Linux
* Added WebP compatibility on HTML5, improved file format detection
* Added EXT_texture_compression_s3tc to GL extensions
* Added ability to specify architecture when performing iOS simulator builds
* Removed deprecated HTML meta for Google Chrome Frame
* Improved macro compile performance
* Improved asset manifests to embed when all of their assets are embedded
* Improved the web template for Flash for better relative URL resolution
* Improved support for OpenGL extensions when dead-code-elimination is enabled
* Improved the suspend/resume behavior on Android
* Improved System.endianness to return BIG_ENDIAN on Flash Player
* Improved file copying in tools to not copy templates that have not changed
* Improved Cairo bindings to return the same object reference when possible
* Improved OpenAL bindings to return the same object reference when possible
* Fixed an issue with exiting fullscreen on HTML5
* Fixed an issue with escaped paths when generating Neko executables
* Fixed possible cases where paths could have been escaped twice in Haxe 3.3
* Fixed support for GL.compressedTexImage on HTML5
* Fixed CORS exception on HTML5 if there is no content-type header
* Fixed static initialization order of core lime.system.CFFI methods
* Fixed a dead-code-elimination issue in NativeHTTPRequest
* Fixed the Android Gradle Plugin setting in the Lime extension template

4.0.3 (03/28/2017)
------------------

* Added support for GL EXT_packed_depth_stencil
* Improved safety around DataPointer when performing arithmetic
* Improved Image.loadFromBytes when bytes are not a known image type
* Improved the performance of Image.fillRect in some cases

4.0.2 (03/21/2017)
------------------

* Added an internal transfer queue for limiting simultaneous HTML5 requests
* Added an internal thread pool for limiting simultaneous native HTTPRequests
* Fixed compilation support with newer Haxe releases on Raspberry Pi
* Fixed the default "end" argument value of ArrayBufferView subarray
* Fixed a performance regression in WebGL support
* Fixed native HTTPRequest so that it always returns on the correct thread
* Fixed path resolution to APK-based assets using HTTPRequest on Android
* Fixed "unused pattern" warning caused by duplicate constant in GL bindings
* Fixed a mismatch between intptr_t and uintptr_t (affecting Android)
* Fixed several Window properties when creating a new window without a config

4.0.1 (03/17/2017)
------------------

* Improved error message when an asset library is not found
* Improved generated code performance when using ArrayBufferView
* Fixed some issues with incorrect OpenGL garbage collection
* Fixed AssetLibrary loadText to use text (not binary) loading on HTML5
* Fixed support `<library />` tag without using a "path" attribute
* Fixed premature loading of `embed="false"` assets on HTML5
* Fixed missing bufferData API in WebGLContext
* Fixed OpenGL bindings to return null OpenGL objects if an ID is zero

4.0.0 (03/15/2017)
------------------

* Added support for WebGL 2 APIs on HTML5
* Recreated GL bindings in preparation for GLES3 support
* Added support for running different Lime tools to match project version
* Added WebGL, WebGL 2, GLES 2 and GLES 3 abstracts
* Added initial support for WebGL/GLES2 extension constants
* Added GL context, type and version properties
* Added window.displayMode for full-screen display mode switching
* Added lime.utils.DataPointer for managing native pointers
* Added lime.utils.BytePointer for Bytes + offset without a new typed array
* Added lime.utils.ObjectPool as a convenience API for object pooling
* Added support for `<assets path="" library="" />` for library packing
* Added support for loading \*.bundle directories as asset libraries
* Added support for `${meta.title}` and other project data in project.xml
* Added support for Cairo textPath
* Added support for multiple Lime embeds, rewrote HTML5 embed code
* Added asset type to verbose Preloader messages
* Added `-Dwebgl1` to use a WebGL 1 context instead of WebGL 2 on HTML5
* Removed deprecated behaviors from Lime 3
* Updated Gamepad mappings to support additional models
* Updated HTML5 window to dispatch resize event if parent element is resized
* Improved support for deferred loading of asset libraries
* Improved Asset error events, updated to throw errors when assets not found
* Improved handling of GL context loss on WebGL
* Improved behavior of asset manifests included as assets of another library
* Improved behavior of path groups for audioBuffer assets
* Improved error message if ANDROID_SDK or ANDROID_NDK_ROOT is not defined
* Fixed caching for HTML5 cache groups
* Fixed native HTTPRequest if file is not found or uses ~/ for home directory
* Fixed copying of files when a directory exists of the same name
* Fixed dispatch of Renderer.onRender when there is no context
* Fixed dispatch of Renderer.onContextLost on native platforms
* Fixed use of image.threshold when source is canvas or HTML5 image
* Fixed missing warning if `<icon path="" />` is null
* Fixed `<app path="" />` to be relative to include.xml path
* Fixed `<splashScreen path="" />` to be relative to include.xml path
* Fixed case where assets could be processed as templates
* Fixed support for ATF textures on Flash target
* Fixed ID value for Joystick/Gamepad guid property
* Fixed double dispatch of preloader complete verbose message
* Fixed path of `-options` parameter when calling HXCPP

3.7.4 (02/15/2017)
------------------

* Improved AudioBuffer/Font/Image/Sound.loadFromFile to support URLs
* Deprecated AudioBuffer.fromURL and onload/onerror callbacks
* Added verbose log messages during asset library preload
* Fixed crash on iOS when rewinding or looping sounds

3.7.3 (02/13/2017)
------------------

* Improved support for Raspberry Pi
* Improved configuration for Gradle version on Android builds
* Fixed a crash in VorbisFile.fromBytes
* Fixed httpRequest.timeout to timeout only on opening a connection
* Fixed setting of system clipboard when using Clipboard.text on HTML5
* Fixed Assets.getBytes for cached text assets
* Fixed the final progress value when using -Dsimulate-preloader
* Fixed valid image check when returning cached image assets
* Fixed a minor memory leak in System application directories
* Fixed filters and default file name in FileDialog
* Fixed AudioBuffer.loadFromFile on native for remote assets

3.7.2 (01/26/2017)
------------------

* Reverted high-DPI HTML5 mouse scale change
* Improved the DPI values returned from display.dpi
* Fixed "Update to Recommended Settings" message on Xcode 8.2

3.7.1 (01/25/2017)
------------------

* Improved output of Flash Player log output
* Fixed minor issues with Flash Player preload logic
* Fixed use of AudioBuffer in multiple native AudioSource instances

3.7.0 (01/24/2017)
------------------

* Added `<define />` (implies `<set />` and `<haxedef />`)
* Added `<dependency force-load="" />` (will default to false in Lime 4)
* Added `-Dsimulate-preloader=3000` for simulating preload progress
* Improved Image.loadFromBase64/loadFromBytes/loadFromFile on HTML5
* Improved Image.loadFromBytes/loadFromFile support on Flash target
* Improved support for "library.json" files that are not embedded
* Improved support for browsers that do not have context.isPointInPath
* Improved `lime setup linux` command for some newer environments
* Improved caching behavior of text assets in AssetLibrary
* Improved seeking behavior for AudioSource on native targets
* Improved preload behavior on Flash target
* Fixed metadata-based font embedding for Flash Player
* Fixed issues with Windows paths when building tools with Haxe 3.4
* Fixed preloading of fonts similar to default sans-serif on HTML5
* Fixed base path for assets loaded from non-default asset libraries
* Fixed scale of mouse events dispatched for high-DPI HTML5 windows

3.6.2 (01/20/2017)
------------------

* Improved error when making a directory on an unavailable drive letter
* Fixed regression in support for HTML5 font preloading
* Fixed possible font overflow when embedding fonts on Flash target
* Fixed crash on Neko when using AudioSource with no AudioBuffer

3.6.1 (01/18/2017)
------------------

* Added streaming audio support to AudioSource
* Fixed issues in bytesLoaded/bytesTotal calculation
* Fixed a regression in support for static-linking
* Fixed a regression in support for lime.utils.JNI

3.6.0 (01/16/2017)
------------------

* Moved "lime.audio" to "lime.media"
* Added Vorbis bindings under "lime.media.codecs.vorbis"
* Added lime.ui.ScanCode, with conversion support to/from KeyCode on native
* Added tool support for the "--no-output" argument
* Migrated from NFD to tinyfiledialogs for better dialog support
* Made window.close cancelable on desktop platforms
* Updated libjpeg to 9b
* Updated howler.js to 2.0.2
* Improved support for Haxe 3.4
* Improved support for progress events while preloading
* Fixed force install when deploying to Android (API 16+ devices)
* Fixed an invalid state when returning from background on Android
* Fixed playback of a single audio buffer multiple times on HTML5
* Fixed initial volume level in AudioSource on HTML5
* Fixed a regression in the default architecture list for iOS
* Fixed merging of multiple `<architecture />` tags in project files
* Fixed a possible crash when retrieving OpenGL strings
* Fixed the default template for HTML5 when multiple projects are embedded
* Fixed support for non-preloaded assets on HTML5
* Fixed support for image.copyChannel on HTML5 when using WebGL
* Fixed support for command-line arguments with "lime rebuild"

3.5.2 (12/19/2016)
------------------

* Fixed issues related to @:bitmap, @:file and @:sound
* Fixed support for HTML5 font preloading
* Fixed issue with HTTPRequest and IE 11
* Fixed an issue when merging multiple project.config values
* Reverted bytes changes to resolve C++ GC issues

3.5.1 (12/16/2016)
------------------

* Made major changes to Assets and the behavior of asset libraries
* Made progress on a better asset manifest system
* Made significant improvements to the iOS project templates
* Moved lime.Assets to lime.utils.Assets
* Added lime.utils.AssetLibrary, lime.utils.AssetType, lime.utils.AssetManifest
* Added static "loadFrom" constructors for core types
* Improved C++ performance on debug builds, added -Dlime-debug
* Updated CFFI bytes to better support C# target
* Fixed the 'cannot find build target "by"' error with current Haxe releases
* Fixed support for *.hxp projects
* Fixed some compile errors when core types were used in macros
* Fixed a minor issue with HTTPRequest on HTML5
* Fixed Android template so READ\_PHONE\_STATE is not a required permission
* Fixed support for `<haxelib name="" path="" />`
* Fixed a regression with the quality of generated SVG icons

3.5.0 (12/07/2016)
------------------

* Significantly improved lime.net.HTTPRequest
* Added support for lime.system.Clipboard on HTML5
* Added System.openURL to launch a website externally
* Added System.openFile to open a file using a system default application
* Added -nolaunch option for HTML5 "test" command
* Added support for `<config:ios provisioning-profile="" />` for iOS
* Updated SDL to dev version to fix Linux keyboard events
* Updated lime.app.Future with better progress events
* Updated to initialize WebGL2 on HTML5, when available
* Refactored certificate storage in HXProject
* Improved the parsing and merge support for default Lime config
* Improved the GL context in anticipation for GLES3/WebGL2 support
* Improved HTML5 mouse events to allow canceling
* Improved auto-build number detection to support SVN
* Improved support for toggling window.resizable on native
* Fixed audioBuffer.dispose for Howler.js buffers
* Fixed use of deprecated APIs in lime.ui.Haptic implementation on iOS
* Fixed use of deprecated APIs in accelerometer implementation on iOS
* Fixed crash when resuming iOS applications from the background
* Fixed crash if an asset manifest is not found and live reloading is enabled
* Fixed handling of the default framebuffer on iOS
* Fixed handling of \*.jpeg file extension when making Flash builds
* Fixed an issue in bytes handling for C#
* Fixed the behavior of window onEnter/onLeave on DOM
* Fixed the behavior of image.scroll
* Fixed garbage collection for lime.audio.openal.ALSource
* Fixed incorrect window scale calculation on the iPhone Plus
* Fixed some standard APIs when making modular HTML5 builds
* Fixed crash when setting window.title
* Fixed the return value of gl.shaderInfoLog on some platforms
* Fixed the behavior of Event.ACTIVATE when resuming on iOS
* Fixed missing input event initially on HTML5

3.4.1 (11/01/2016)
------------------

* Fixed order of Assets.registerLibrary and app.onPreloaderComplete
* Added a workaround for HAXE_STD_PATH error on -Dmodular

3.4.0 (10/31/2016)
------------------

* Moved Lime config from ~/.hxcpp_config.xml to ~/.lime/config.xml
* Added a new "lime config" command to print the current config
* Added "lime config VARNAME" command to print a value from the current config
* Added initial support for modular HTML5 builds (generates separate lime.js)
* Added support for comparisons in project XML (like ${haxe >= 3.2.1})
* Added lime.ui.Haptic for initial support of vibrate on iOS/Android
* Added `<log />` to project XML for info/warning/error/verbose messages
* Added a build-time error if Haxe is less than 3.2.0
* Added support for GIT-based meta build number value
* Added initial high-DPI support for HTML5
* Updated SDL to version 2.0.5
* Improved support for Android immersive mode
* Improved idle performance on macOS
* Improved Gradle template to output APK filenames based on build type
* Improved verbose messages for embedded fonts
* Removed Neko template binaries, updated tools to use host version
* Fixed IPHONE_VER issues with certain versions of HXCPP
* Fixed iOS device deployment on macOS Sierra
* Fixed iOS simulator deployment on macOS Sierra
* Fixed node.js HTTP server support on macOS Sierra
* Fixed duplicate symbol error on iOS
* Fixed support for older CPUs without SSE4 instruction support
* Fixed crash on negative seek position for HTML5 AudioSource
* Fixed initial gain and position when playing HTML5 AudioSource sound
* Fixed compatibility issues with current Haxe development versions

3.3.0 (10/10/2016)
-----------------

* Added Future.ready and Future.result
* Added AudioBuffer.loadFromFile and AudioBuffer.loadFromFiles
* Added favicon support to HTML5 builds
* Added automatic garbage collection to OpenAL bindings
* Improved the behavior of AudioSource, added Howler.js for HTML5
* Improved CFFI bindings to prevent early GC of bytes
* Improved the behavior of \*.hxp project files
* Improved support for the C# target
* Improved `<meta build-number="" />` to allow a value of 0
* Improved support for "-lib lime" from plain HXML
* Implemented relative mouse movement events for Flash and HTML5
* Implemented Locale support for Android
* Updated the behavior of "lime run" to imply "trace" (unless "-notrace")
* Updated Android template to allow submission to non-touchscreen devices
* Fixed support for `<java path="" />` on Android
* Fixed the value of Assets.isLocal for certain non-embedded assets
* Fixed an issue affecting touch events after an HTML5 build was rotated
* Fixed use of a custom HAXELIB_PATH for iOS builds (in Xcode)
* Fixed numpad key values in HTML5
* Fixed C++ casting when converting openfl.Vector to Float32Array
* Fixed support for `<window allow-high-dpi="true" />`
* Fixed Android compilation using debug

3.2.1 (09/20/2016)
------------------

* Fixed an issue when GC was executed from another thread

3.2.0 (09/19/2016)
------------------

* Updated to support Xcode 8 and iOS 10
* Added lime.system.Locale
* Added initial changes to support the C# target
* Updated to OpenAL-Soft 1.17.2
* Cleaned up some API paths with GC optimizations
* Changed macOS to use OpenAL.framework, not OpenAL-Soft
* Changed Android to use the standard OpenAL-Soft release
* Improved suspend/resume support for Android audio
* Improved support for `lime setup` on Linux
* Improved CADisplayLink support for iOS
* Improved the behavior of ColorMatrix
* Fixed some crash issues in lime.system.System
* Fixed setting of window.title
* Fixed an issue with the Android NDK and debuggable=false
* Fixed a possible crash when using multiple windows
* Fixed the Android template for `lime create extension`
* Corrected support for high DPI windows

3.1.0 (08/29/2016)
------------------

* Switched from Ant to Gradle for Android builds
* Added workarounds for some Haxe 3.3.0-rc1 issues
* Added support for hidden windows on the desktop
* Improved HTML5 mouse move by ignoring repeat events
* Fixed issues in ArrayBuffer when values were null
* Fixed a cross-origin issue that affected some browsers
* Fixed support for System directories on Android
* Fixed null fromBytes/fromImage conversion

3.0.3 (07/27/2016)
------------------

* Improved "lime test flash -web" behavior to use HTTP server
* Fixed an issue with Neko native byte resizing

3.0.2 (07/22/2016)
------------------

* Added lime.utils.compress.* Deflate, GZip, LZMA and Zlib
* Added -Dcairo to force use of Cairo software rendering on native
* Deprecated lime.utils.LZMA
* Fixed issue where assets were not found on Linux

3.0.1 (07/20/2016)
------------------

* Improved the exclude/include filter behavior on `<asset />` tags
* Fixed an issue that caused Window to duplicate event dispatches
* Fixed the name of generated folder for HTML5 output
* Fixed support for OpenAL getSource3f

3.0.0 (07/08/2016)
------------------

* Changed to different build directories for release/debug/final
* Added support for transparent HTML5 windows
* Added support for cairo.showGlyphs
* Added garbage collection to the OpenGL bindings
* Added audioSource.position for panning
* Improved the behavior of Image when using WebGL
* Improved the behavior of the HTML5 cache string
* Improved the Flash target to embed unsupported audio assets
* Improved support for integer positioning of unscaled HTML5 content
* Updated the SVG tool using the latest SVG/OpenFL versions
* Updated the module system to be more resilient to API changes
* Updated the iOS plist for newer app store submission guidelines
* Updated the HTML5 canvas to allow for premultiplied alpha
* Integrated changes to improve tvOS support
* Fixed issues in the Cairo bindings for improved Neko support
* Fixed image.copyPixels when using a negative destination
* Fixed the fillRect behavior when using alpha on native
* Fixed an issue with PNG encoding on HTML5
* Fixed an issue in typed arrays where offset/length were ignored
* Fixed a crash in ExternalInterface
* Fixed a case where displayInfo.currentMode is not active yet

2.9.1 (03/28/2016)
------------------

* Added automatic support for mouse capture when dragging
* Added initial support for `<haxelib path="" \>`
* Added window.onDropFile, window.maximized
* Added a missing dependency in the iOS project template
* Added a polyfill for context.isPointInStroke (for IE support)
* Added a flag to disable "allow-high-dpi" support
* Improved support for Assets.loadBytes on Flash
* Fixed some minor memory leaks when allocating CFFI strings
* Fixed a rare crash in the tools when `haxelib path` does not work
* Fixed the name suffix for Windows builds on newer HXCPP versions
* Fixed an issue where Cairo could render text at the wrong size
* Fixed the default company meta to be blank instead of a dummy value
* Fixed the window position and size to update after fullscreen

2.9.0 (01/22/2016)
------------------

* Updated to SDL 2.0.4
* Updated to Cairo 1.14.6 and pixman 0.32.8
* Changed default Android SDK version to 19 (enables immersive mode)
* Added initial support for display.dpi
* Added initial support for window.borderless and window.resizable
* Added initial support for renderer.readPixels
* Added support for image.threshold
* Added open directory support to file dialog
* Added support for stopping propagation of browser keyboard events
* Added support for environment variables in if/unless conditionals
* Added support for variable substitution in if/unless conditionals
* Added MIPS and MIPSEL to architectures in tools
* Improved guards against using lime.* classes with legacy
* Improved support for the newer Android NDK
* Improved handling of reference leaks in JNI access
* Removed @:finalizer support, due to issues it caused
* Fixed compatibility with HXCPP changes regarding Visual Studio 2015
* Fixed support for window.display on scaled windows
* Fixed a tool crash when using an unrecognized -armvX flag

2.8.3 (01/02/2016)
------------------

* Improved support for the latest Android NDK
* Improved cross-domain image loading on HTML5
* Improved support for rebuilding and using tools without haxelib
* Ensured that OpenAL is disabled in static builds by default
* Fixed support for the current Haxe development build
* Fixed the setup command to ensure all requested dependencies
* Fixed a compile error when using `<source />` and an empty path
* Fixed the -notrace flag (to disable "trace" on "test" commands)

2.8.2 (12/16/2015)
------------------

* Enabled WebGL by default on HTML5
* Added support for Lime event canceling
* Added default keyboard shortcuts for toggling fullscreen
* Added default Android back button behavior to quit
* Added support for `<window resizable="false" />` on HTML5 template
* Changed iOS default system font path to be more generic
* Fixed issues with OGG decoding on newer Android NDK
* Fixed AudioSource complete event when setting currentTime or length
* Fixed minor issue compiling Neko Windows binaries from Linux
* Minor updates to the default Android ADB output filter
* Updated ANGLE binaries to resolve ALT + Enter fullscreen issue
* Fixed font paths on iOS (legacy)

2.8.1 (12/09/2015)
------------------

* Disable ANGLE by default on Windows, need to do additional testing
* Added support for optional haxelib references in XML
* Fixed an issue with incorrect joystick IDs on connect

2.8.0 (12/07/2015)
------------------

* Removed lime.utils.ByteArray in favor of Haxe (3.2+) Bytes
* Enabled ANGLE on Windows builds by default
* Restored compatibility with Windows XP
* Added support for HTML5 gamepad/joystick events
* Removed lime.net.URLLoader, added HTTPRequest as a temporary patch
* Added cache-break support to HTML5 based on each build
* Fixed use of 32-bit Windows builds on recent HXCPP versions
* Fixed support for correct touch event coordinates in HTML5 fullscreen
* Fixed importing of lime.system.JNI on platforms other than Android
* Fixed an issue that could cause native crashes on null Vector2 values
* Fixed embed of runtime-generate asset files
* Fixed default font paths on new versions of iOS (legacy)

2.7.0 (10/28/2015)
------------------

* Added a minimum version check for OpenGL (software fallback otherwise)
* Improved the consistency of frame time on native platforms
* Fixed an issue where Android applications would crash on unfound files
* Updated the Neko template for Lime legacy builds

2.6.9 (10/15/2015)
------------------

* Fixed an issue with certain predictive text keyboards on Android
* Fixed an issue where ImageBuffer did not update after certain changes
* Fixed a red tint that occurred on some mobile graphics
* Fixed a crash on closing applications on OS X 10.11 due to OpenAL
* Fixed an issue with VERIFY_HOST in the cURL bindings
* Additional fixes for tvOS compatibility
* Made minor template updates
* Fixed the default virtual keyboard type on BlackBerry (legacy)

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
* Added check to remove duplicated `<dependency />` references
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
* Improved default \_sans, \_serif and \_typewriter font matching for Mac and iOS
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
* Updated for automated builds: <http://openfl.org/builds/lime>

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
