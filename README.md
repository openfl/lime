[![Stories in Ready](https://badge.waffle.io/openfl/lime.png?label=ready)](https://waffle.io/openfl/lime) [![Build Status](https://travis-ci.org/openfl/lime.png?branch=master)](https://travis-ci.org/openfl/lime)

<img src="lime.png" width="40%"/>

Lime
====

Lime is a flexible, lightweight layer for Haxe cross-platform developers.

Lime supports native, Flash and HTML5 targets with unified support for:

 * Windowing
 * Input
 * Events
 * Audio
 * Render contexts
 * Network access
 * Assets

Lime does not include a renderer, but exposes the current context:

 * Canvas
 * DOM
 * Flash
 * GL

The GL context is based upon the WebGL standard, implemented for both OpenGL and OpenGL ES as needed.

Lime provides a unified audio API, but also provides access to OpenAL for advanced audio on native targets.


License
=======

Lime is free, open-source software under the [MIT license](LICENSE.md).


Installation
============

First install the latest version of [Haxe](http://www.haxe.org/download).

Next, until the new version of Lime is released, you can download the current [development build](http://www.openfl.org/builds/lime), and install using:

    haxelib local filename.zip

You will also want to install Aether:

    haxelib install aether
    haxelib run aether setup


Building from Source
====================

Clone the Lime "next" branch, as well as the submodules:

    git clone --recursive -b next https://github.com/openfl/lime

Tell haxelib where your development copy of Lime is installed:

    haxelib dev lime ./lime

If Aether is installed, you can build the binaries using "aether rebuild":

    aether rebuild lime windows
    aether rebuild lime linux -64 -release -clean

On a Windows machine, you should have Microsoft Visual Studio C++ (Express is just fine) installed. You will need Xcode on a Mac. To build on a Linux machine, you may need the following packages (or similar):

    sudo apt-get install libgl1-mesa-dev libglu1-mesa-dev g++ g++-multilib gcc-multilib

To switch away from a source build, use:

    haxelib dev lime


Sample
======

You can build a sample Lime project with the following commands:

    aether create lime:HelloWorld
    cd HelloWorld
    aether test neko

You can also list other projects that are available using "aether create lime".


Targets
=======

Lime currently supports the following targets:

    aether test windows
    aether test mac
    aether test linux
    aether test neko
    aether test html5
    aether test flash

Native builds must be built on the same operating system as the target. As supported in other versions of Lime, additional platforms (iOS, Android, BlackBerry, Tizen) will be restored in the near future.