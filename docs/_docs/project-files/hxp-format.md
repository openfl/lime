---
title: HXP Format
---

## Overview

The \*.hxp format is based upon Haxe, it mirrors the internal project format used within Lime tools. There is a lot of flexibility and power that can come from using an \*.hxp project, but be aware that as the Lime tools evolve, the specification may change slightly.

### Structure

The basic structure of an \*.hxp project looks like this:

```java
import lime.project.*;

class Project extends HXProject {

    public function new () {

        super ();

        // Code goes here!

    }

}
```

You can put all of your settings within the `new` function, or you can create additional methods, if you prefer.

### Conditionals

Being in Haxe, you can use standard if/else logic in order to control your build process.

A variety of values are set for you. For example, the `platformType` value may be PlatformType.MOBILE, PlatformType.DESKTOP or PlatformType.WEB.

There is also a `target` value, which may be Platform.IOS, Platform.ANDROID, Platform.WINDOWS, Platform.MAC, Platform.LINUX, Platform.FLASH or Platform.HTML5, among others.

If needed, you can also check the `host` property, which should define Platform.WINDOWS, Platform.MAC or Platform.LINUX.

You can also set your own values (of course):

```java
import lime.project.*;

class Project extends HXProject {

    public function new () {

        super ();

        if (platformType == PlatformType.WEB) {

            windows[0].width = 800;
            windows[0].height = 600;

        }

        var iOSSimulator = (target == Platform.IOS && targetFlags.exists ("simulator"));

        if (iOSSimulator) {

            trace ("Targeting the iOS simulator");

        }

    }

}
```

## Common Values

### meta

Use the `meta` typedef to add information about your application, which usually will not affect how the application runs, but how it is identified to the target operating system or on an application store.

The `meta` property is a typedef, allowing you to use it as an object. This type of use can be ideal for code completion, where supported by a code editor:

    meta.title = "My Application";
    meta.packageName = "com.example.myapplication";
    meta.version = "1.0.0";
    meta.company = "My Company";

...or you can override the full value of the property. You don't need to specify every value, as the tools will automatically complete any missing values with default ones:

    meta = { title: "Hello World", packageName: "com.example.myapplication", version: "1.0.0" };

### app

The `app` typedef sets values important to building your project, including the entry point (main class), the output file directory, or if you want to customize the executable filename or define a custom preloader for a web platform.

    app.main = "com.example.MyApplication";
    app.file = "MyApplication";
    app.path = "Export";
    app.preloader = "CustomPreloader";
    app.swfVersion = 11;

Similar to the `meta` property, the `app` property is a typedef, so you can define it either as an object literal or by naming the properties, whichever you prefer.

    app = { main: "com.example.MyApplication", file: "MyApplication", path: "Export", preloader:  "CustomPreloader", swfVersion: 11 };

### window

You can use the `window` array to control how an application will be initialized. Lime currently supports only one window, but this has been updated to be an array of typedefs in order to be prepared when multi-monitor support is available.

Each `window` includes the screen resolution and background color, as well as other options, such as whether hardware should be allowed or display mode flags.

By default, mobile platforms use a window width and height of 0, which is a special value that uses the resolution of the current display. This is available on desktop platforms, but usually it is recommended to enable the `fullscreen` value instead, and to set the `width` and `height` values to a good windowed resolution. There is a special `fps="0"` value for HTML5, which is default, which uses "requestAnimationFrame" instead of forcing a frame rate.

    windows[0].width = 640;
    windows[0].height = 480;
    windows[0].background = 0xFFFFFF;
    windows[0].fps = 30;
    windows[0].hardware = true;
    windows[0].allowShaders = true;
    windows[0].requireShaders = true;
    windows[0].depthBuffer = false;
    windows[0].stencilBuffer = false;
    windows[0].fullscreen = false;
    windows[0].resizable = true;
    windows[0].borderless = false;
    windows[0].vsync = false;
    windows[0].orientation = Orientation.PORTRAIT;
    windows[0].antialiasing = 0;

Similar to `app` and `meta`, the `window` property is a typedef, so you can use either an object literal or set each property, depending on your preference. If you use an object literal, any values you do not define will be added later with default values by the tools.

    windows[0] = { width: 640, height: 480, background: 0xFFFFFF, fps: 30, hardware: true, allowShaders: true, requireShaders: true, depthBuffer: false, stencilBuffer: false, fullscreen:false, resizable: true, borderless: false, vsync: false, orientation: Orientation.PORTRAIT, antialiasing: 0 };

### sources

Use the `sources` array to add additional Haxe class paths:

    sources.push ("Source");

If you are using `@:file`, `@:bitmap`, `@:sound` or `@:file` tags in your project, be sure that the asset files are available within your Haxe source paths.

### haxelibs

Use the `haxelibs` array to include Haxe libraries:

    haxelibs.push (new Haxelib ("actuate"));

You can also specify a version, if you prefer:

    haxelibs.push (new Haxelib ("actuate", "1.0.0"));

### ndlls

You can use the `ndlls` array to include native libraries. These are usually located under an "ndll" directory, with additional directories based upon the target platform. Usually NDLLs are included as a part of an extension (using an include), so they are rare to be used directly:

    ndlls.push (new NDLL ("std", new Haxelib ("hxlibc"));

### icons

Use the `icons` array to add icon files to your project. When the command-line tools request icons for a target platform, it will either use an exact size match you have provided, or it will attempt to find the closest match possible and resize. If you include an SVG vector icon, it should prefer this file over resizing bitmap files.

    icons.push (new Icon ("icon.png", 64));

    var icon = new Icon ("icon2.png");
    icon.width = 96;
    icon.height = 96;

    icons.push (new Icon ("icon.svg"));

### assets, includeAssets

Use the `assets` array, as well as the `includeAssets` method, to add resources to your project, available using `lime.Assets` at runtime.

The path attribute can point to either a file or a directory. These files will be copied (or embedded) in your final project, and can be accessed using the `lime.Assets` class.

For example, if you include the following asset in your project file:

    assets.push (new Asset ("images/MyImage.jpg"));

You can access it in your application like this:

    var bitmapData = Assets.getBitmapData ("images/MyImage.png");

The target path will mirror the source path by default, but you also can include a rename attribute, if you wish to use a different target path. The `lime.Assets` class will use the *target* path by default, so using the rename attribute will alter the names you use to reference your files.

If you would prefer to set the ID for your asset file yourself, use a `id` property.

If you would like to include a directory, you can use the `includeAssets` method to help automate the process. When using `includeAssets`, you can specify include or exclude attributes to set patterns for which files to include. Wildcards are supported. To include all the files under the directory, for example, use an include value of "*". The `include` and `exclude` values are arrays, allowing you to include multiple patterns, if you want.

    includeAssets ("Assets", "assets", [ "*" ], [ "lime.svg" ]);

The type for each file will be determined automatically, based on each file extension, but you can use the type attribute to set it for the file or directory yourself. If you are nesting a node inside of another assets node, you can also use the name of the type as the name of your node.

    var asset = new Asset ("image.png");
    asset.type = AssetType.IMAGE;

If an asset is specified as "template", it will not be copied/embedded as an ordinary asset, but instead will be copied to the root directory of your project, so you can replace any of the template HX, HXML or platform-specific files for the target.

    includeAssets ("assets");
    includeAssets ("../../assets", "assets");
    includeAssets ("assets/images", "images", [ "*.jpg", "*.png" ], [ "example.jpg" ]);

    var sound = new Asset ("sound/MySound.wav");
    sound.id = "MySound";
    assets.push (sound);

    assets.push (new Asset ("sound/BackgroundMusic.ogg"));

## Additional Values

### templatePaths

Use the `templates` array to add paths which can override the templates used by the command-line tools.

You can add a full template path like this:

    templatePaths.push ("templates");

### haxeflags

Use the `haxeflags` array to add additional arguments in the Haxe compile process:

    haxeflags.push ("-dce");
    haxeflags.push ("std");

### haxedefs

Use the `haxedefs` map to add Haxe defines (similar to using `haxeflags` with "-D"):

    haxedefs.set ("define", 1);

### setenv

Use the `setenv` method to set environment variables:

    setenv ("GLOBAL_DEFINE");

### javaPaths

Use the `javaPaths` array to add Java classes to the project when targeting Android:

    javaPaths.push ("java/classes");

### certificate

Use the `certificate` value to add a keystore for release signing on certain platforms.

If you do not include the password attribute, you will be prompted for your certificate password at the command-line.

For Android, the alias will be set to the file name of your certificate by default, without the extension. If the alias name is different, you can use the alias property.

If you have set the password property, the alias_password property will default to the same value. Otherwise you can add an alias-password property to specify a different value.

iOS does not use a certificate `path` and `password`, but instead uses an `identity` property matching the provisioning profile you have configured on your system:

    certificate = new Keystore ();
    certificate.identity = "iPhone Developer";

### platformConfig.ios

Control iOS-specific values when compiling.

The `deployment` property can set the minimum iOS version you wish to target.

    platformConfig.ios.deployment = 5;
    platformConfig.ios.devices = "universal";
    platformConfig.ios.linkerFlags = "";
    platformConfig.ios.prerenderedIcon = false;

Since the "ios" value is a typedef, you can also use an object literal. Any values you do not define will be added later using the defaults:

    platformConfig.ios = { deployment: 5, devices: "universal", linkerFlags: "", prerenderedIcon: false };

### platformConfig.android

Use the `android` typedef to set Android-specific values:

    platformConfig.android.extensions.push ("MyExtension");
    platformConfig.android.installLocation = "preferExternal";
    platformConfig.android.minimumSDKVersion = 9;
    platformConfig.android.targetSDKVersion = 16;
    platformConfig.android.permissions.push ("android.permission.WAKE_LOCK");

    platformConfig.android = { installLocation: "preferExternal", minimumSDKVersion: 9, targetSDKVersion: 16 };

### dependencies

Use the `dependencies` array to specify native frameworks or references that are required to compile your project, as well as additional libraries you need copied.

    if (target == Platform.IOS) {

        dependencies.push ("GameKit.framework");

    }

### path

Use the `path` method to add directories to your system's PATH environment variable.

    path ("path/to/add/to/system/PATH");

## LogHelper.error

Use `LogHelper.error` to throw your own errors during the build process, if necessary.

    LogHelper.error ("Something is wrong");
