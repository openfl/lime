[![Stories in Ready](https://badge.waffle.io/openfl/lime.png?label=ready)](https://waffle.io/openfl/lime) [![Build Status](https://travis-ci.org/openfl/lime.png?branch=master)](https://travis-ci.org/openfl/lime)

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

The current version of Lime has not been released on haxelib, yet, so please install the latest [development build](http://www.openfl.org/builds/lime).


Development Builds
==================

When there are changes, Lime is built nightly. Builds are available for download [here](http://www.openfl.org/builds/lime).

To install a development build, use the "haxelib local" command:

    haxelib local filename.zip


Building from Source
====================

Clone the Lime repository, as well as the submodules:

    git clone --recursive https://github.com/openfl/lime

Tell haxelib where your development copy of Lime is installed:

    haxelib dev lime lime

You can build the binaries using "lime rebuild":

    lime rebuild lime windows
    lime rebuild lime linux -64 -release -clean

If you make modifications to the tools, you can rebuild them like this:

    lime rebuild tools

On a Windows machine, you should have Microsoft Visual Studio C++ (Express is just fine) installed. You will need Xcode on a Mac. To build on a Linux machine, you may need the following packages (or similar):

    sudo apt-get install libgl1-mesa-dev libglu1-mesa-dev g++ g++-multilib gcc-multilib

To switch away from a source build, use:

    haxelib dev lime


Sample
======

You can build a sample Lime project with the following commands:

    lime create lime:HelloWorld
    cd HelloWorld
    lime test neko

You can also list other projects that are available using "aether create lime".


Targets
=======

Lime currently supports the following targets:

    lime test windows
    lime test mac
    lime test linux
    lime test neko
    lime test html5
    lime test flash

Native builds must be built on the same operating system as the target. As supported in Lime legacy, additional platforms (iOS, Android, BlackBerry, Tizen) will be restored in the near future.


Lime "Legacy"
=============

OpenFL uses older Lime binaries, which are not used in the current version of Lime. These older binaries are derived from shared source within the NME repository, while the newer code has been rewritten to better suit the goals of the project.

In order to rebuild Lime "legacy", you should follow the directions above for building from the source. You will also need additional dependencies:

    git clone https://github.com/haxenme/nme
    git clone https://github.com/haxenme/nme-dev
    git clone https://github.com/haxefoundation/hxcpp
    
    haxelib dev nme nme
    haxelib dev nme-dev nme-dev
    haxelib dev hxcpp hxcpp
    
    cd nme-dev/project
    neko build.n
    
    lime rebuild hxcpp windows
    lime rebuild windows -Dlegacy

You can substitute "windows" for another available target. If you would like to use Lime from the source, but do not need to modify the content of the legacy binaries, it is much easier to download a current development build, and copy the "legacy" folder into your source checkout. Otherwise, the above steps should help.
