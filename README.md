[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.md) [![Haxelib Version](https://img.shields.io/github/tag/openfl/lime.svg?style=flat&label=haxelib)](http://lib.haxe.org/p/lime) [![Build Status](https://img.shields.io/github/actions/workflow/status/openfl/lime/main.yml?branch=develop)](https://github.com/openfl/lime/actions) [![Community](https://img.shields.io/discourse/posts?color=24afc4&server=https%3A%2F%2Fcommunity.openfl.org&label=community)](https://community.openfl.org/c/lime/19) [![Discord Server](https://img.shields.io/discord/415681294446493696.svg?color=7289da)](https://discordapp.com/invite/tDgq8EE)

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

 * Cairo
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

First, install the latest version of [Haxe](http://www.haxe.org/download).

Then, install Lime from Haxelib and run Lime's setup command.

    haxelib install lime
    haxelib run lime setup


Development Builds
==================

When there are changes, Lime is built nightly. Builds are available for download [here](https://github.com/openfl/lime/actions?query=branch%3Adevelop+is%3Asuccess).

To install a development build, use the "haxelib local" command:

    haxelib local lime-haxelib.zip


Building from Source
====================

1. Clone the Lime repository, as well as the submodules:

        haxelib git lime https://github.com/openfl/lime

2. Install required dependencies:

        haxelib install format
        haxelib install hxp

3. Copy the ndll directory from the latest [Haxelib release](https://lib.haxe.org/p/lime/), or see [project/README.md](project/README.md) for details about building native binaries.

4. After any changes to the [tools](tools) or [lime/tools](src/lime/tools) directories, rebuild from source:

        lime rebuild tools

5. To switch away from a source build:

        haxelib set lime [version number]


Sample
======

You can build a sample Lime project with the following commands:

    lime create HelloWorld
    cd HelloWorld
    lime test neko

You can also list other projects that are available using "lime create".


Targets
=======

Lime currently supports the following targets:

    lime test windows
    lime test mac
    lime test linux
    lime test android
    lime test ios
    lime test html5
    lime test flash
    lime test air
    lime test neko
    lime test hl

Desktop builds are currently designed to be built on the same host OS
