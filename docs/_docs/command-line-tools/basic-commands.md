---
title: Basic Commands
redirect_from:
 - /docs/index.html
 - /docs/home/index.html
---

## lime build

To build a Lime project, you can use a code editor which is integrated with Lime, or you can open a command-prompt or terminal, and run the command directly.

If you are in the same directory as your project:

    lime build neko

You can substitute "neko" for any Lime target, including:

 * windows
 * mac
 * linux
 * ios
 * android
 * flash
 * air
 * html5

Some targets are not available from every host platform. For example, iOS is only available when using macOS.

If you are not in the same directory as your project, you can add an additional argument with either the path to the project directory or to the project file:

    lime build /path/to/project neko
    lime build /path/to/project/project.xml neko

There are also additional "target flags" you can use to specify adjustments to the current target:

 * `(windows|mac|linux) -neko` -- Build with Neko instead of C++
 * `(mac|linux) -32` -- Compile for 32-bit instead of the OS default
 * `(mac|linux) -64` -- Compile for 64-bit instead of the OS default
 * `(ios|tvos) -simulator` -- Target the device simulator
 * `(ios) -simulator -ipad` -- Build/test for the iPad Simulator
 * `(android) -emulator` -- Target the device emulator
 * `(html5) -minify` -- Minify application file
 * `(flash) -web` -- Test Flash target using a web template
 * `(windows|mac|ios|android)` -air -- Build with AIR instead of C++
 * `(air) -ios` -- Target iOS instead of AIR desktop
 * `(air) -android` -- Target Android instead of AIR desktop

By default, the tools will perform a release build, but you can add "-debug" to perform a debug build instead. You can also add "-verbose" in order to get verbose output. If you would like to remove the output directory and perform a clean build, you can also add "-clean".

You can also add defines when building on the command-line:

    lime build neko -Dhello

## lime run

Similar to the "build" command, the tools also support "run" to launch your application on the desktop, or to install and launch the application on a connected mobile device, depending on the target.

All of the same flags and targets apply.

## lime test

"lime test" is a combination of build and run, in a single command. If you are running commands by hand, this is usually the most valuable.

## lime setup

The "setup" command can help download and install the dependencies needed to target certain platforms, or to tell the command-line tools where it can find where these tools are installed. For example, the Android SDK and NDK when targeting Android, or installing Visual Studio C++ for Windows.

Follow the directions under [Advanced Setup](/docs/advanced-setup/) to setup each platform.

## lime help

For more information about the command-line tools, and the commands available, run "lime help"
