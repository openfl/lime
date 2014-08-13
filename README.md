[![Stories in Ready](https://badge.waffle.io/openfl/lime.png?label=ready)](https://waffle.io/openfl/lime) [![Build Status](https://travis-ci.org/openfl/lime.png?branch=master)](https://travis-ci.org/openfl/lime)

<p align="center"><img src="lime.png"/></p>

Introduction
============

Lime (Light Media Engine) is an abstraction layer that makes it simple to go cross-platform with only one codebase; without the compromise of relying upon a scripting language or a virtual machine.

Lime leverages the power of the [Haxe](http://haxe.org/) programming language, compiling directly to C++, JavaScript and other target environments. Haxe is a flexible, robust language, and the resulting applications are truly native. Lime provides the tools and the backend to seamlessly support many platforms.

Platforms
=========

Lime "next" currently supports:

 * Windows
 * Mac
 * Linux
 * Flash
 * HTML5
 * Firefox OS

The following are currently disabled, but will be restored soon:

 * iOS
 * Android
 * BlackBerry
 * Tizen
 * Emscripten

What It Does
============

Lime exposes the following:

 * Rendering context
 * Audio context
 * Unified window management
 * Unified input event management
 * Unified asset management
 * Platform API access

Lime can form the base layer, to provide unified "update", "render", "onMouseDown" or other events, across every target. Lime provides access to the rendering context for the current platform, such as OpenGL, canvas, DOM or Flash rendering. It does not include a renderer of its own, but provides the tools so projects can seamlessly support multiple environments, as well as additional utilities such as cross-target pixel manipulation.

Lime also provides support for platform-specific audio contexts, but a unified audio API is provided to (optionally) manage audio for you.

Window creation, destruction and management, input and assets are provided in a unified way across all supported targets.

License
=======

Lime is free, open-source software under the [MIT license](LICENSE.md).

Installing Lime
===============

First you will need to first install Haxe 3.0 for [Windows](http://haxe.org/file/haxe-3.0.0-win.exe), [Mac](http://haxe.org/file/haxe-3.0.0-osx-installer.dmg) or [Linux](http://www.openfl.org/download_file/view/726/12426/).

Lime "next" is still under development, so there is no release version. However, once it is released, you will be able to install Lime from a terminal or command-prompt with these commands:

    haxelib install aether
    haxelib run aether setup
    aether install lime

Some platforms will require some additional setup before you can use them. For example, you must have Visual Studio C++ in order to build native applications for Windows. Aether includes a "setup" command that can help you walk through the process for each target:

    aether setup windows
    aether setup android
    aether setup blackberry
    aether setup tizen
    aether setup emscripten

In order to build for Mac or iOS, you should already have a recent version of Xcode installed. In order to build for Linux, usually only g++ is required, which may be installed with your distribution already. No setup is required for these platforms.

Development Builds
==================

If you would like to begin using Lime directly from the repository, or want to help contribute to its development, you will first want to clone the repository (or your fork of the repository) then tell "haxelib" where your development version is installed.

    git clone --recursive https://github.com/openfl/lime
    haxelib dev lime lime

The "lime/ndll" directory will be empty, but you can easily rebuild the binaries for any platform using "aether rebuild", like:

    aether rebuild lime windows
    aether rebuild lime windows,blackberry
    aether rebuild lime linux -64
    aether rebuild lime android -debug

Most platforms do not require additional dependencies (other than usual dependencies) to rebuild, but if you are running linux you will development libraries for GL and GLU, as well as multilib versions of g++ if you plan to rebuild both 32- and 64-bit versions of the Lime native layer (which is done through "rebuild" by default)

    sudo apt-get install libgl1-mesa-dev libglu1-mesa-dev g++ g++-multilib gcc-multilib

By default, "rebuild" will compile every binary needed for a target, including both release and debug, and for certain platforms, multiple architectures (such as x86 for an emulator or arm for a device). You can use "-debug", "-release", "-64" and "-32" to specify that you only want to rebuild one kind of binary, and you can use commas to separate multiple builds, in the same command.

There is also a helpful "-rebuild" flag you can use, that rebuilds only the required Lime binary, in addition to the meaning of the original command. For example, the following will test the current application, rebuilding the Windows release binary for Lime first:

    aether test windows -rebuild
    
To return to release builds of Lime, use:

    haxelib dev lime
    
Usually, you will _not_ need to use development versions of Aether as well, but if you would like, you can find instructions at the [aether](https://github.com/openfl/aether) repository.

Using Lime
==========

Lime is designed to provide clear to each platform, while leaving rendering and other aspects to development completely up to you. If that sounds a little too low-level, you may enjoy using a Lime framework, such as the [OpenFL](https://github.com/openfl/openfl) library, which is implemented over Lime.

You can try out Lime by creating the "HelloWorld" or "SimpleImage" samples:

    aether create lime:HelloWorld
    cd HelloWorld
    aether test linux

You can substitute "HelloWorld" for "SimpleImage" in the above command, or use "lime create" to see all available samples. The "test" command combines "update", "build" and "run" into one step. If you are not running Linux, or would like to use a different target, you can try one of the following as well:

    aether test windows
    aether test mac
    aether test ios
    aether test ios -simulator
    aether test android
    aether test android -emulator
    aether test blackberry
    aether test blackberry -simulator
    aether test tizen
    aether test tizen -simulator
    aether test emscripten
    aether test html5
    aether test flash
