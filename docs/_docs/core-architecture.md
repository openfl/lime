---
title: Core Architecture
---

## Command-Line Tools

 * [Source](https://github.com/lime/lime/tree/master/tools)

Building a Lime application relies upon the Lime command-line tools. Whether you are using an `lime` command, a `lime` command, or are using an editor with Lime support built-in, these tools provide the backbone for delivering projects to each target platform.

As needed, the tools will copy asset files, process template files, trigger compilers, package applications and deliver to a connected device or run on your local machine. There are many other features in the tools, but these are the basics that drive the creation of Lime projects.

## Haxe

 * [Website](http://www.haxe.org)
 * [Source](https://github.com/haxefoundation/haxe)

Lime developers write code in [Haxe](https://en.wikipedia.org/wiki/Haxe), a powerful language that can compile to _other_ programming languages. This unique (and proven) ability is the cornerstone to Lime's cross-platform nature.

Based on your project, the arguments used and the target platform, the command-line tools use Haxe to compile Haxe source files into SWF bytecode, Neko bytecode, C++ or JavaScript.

## HXCPP _(C++ Targets Only)_

 * [Source](https://github.com/haxefoundation/hxcpp)

After generating C++ source, Haxe calls the HXCPP library, which includes a standard C++ library to enable unique Haxe features, and calls the target compiler toolchain.

By default, HXCPP uses g++ to build Linux executables, Visual Studio C++ for Windows, Xcode for macOS and iOS, or the standard native toolchain for other platforms, such as the Android NDK when targeting Android.

## Lime

 * [Source](https://github.com/lime/lime)

Lime is a foundational library, providing a single API for managing windows, receiving system events, accessing the rendering context and playing audio, as well as other system APIs.

When targeting a runtime such as HTML5 or Flash Player, Lime is a Haxe-based library that unifies these environments under a single Lime API. When building a native application instead, Lime uses a hand-written C++ library that exposes native windowing, rendering and other low-level features necessary to support the Lime API.

Native dependencies include SDL2, Freetype, Harfbuzz, libogg, libvorbis, libjpeg, libpng, zlib and OpenAL. These are all included. The Lime binary is linked dynamically by default, but can be linked statically. OpenAL is excluded in static builds, due to its license.

## Lime

 * [Source](https://github.com/lime/lime)

Lime is a Haxe library, designed to work over Lime. System events, windowing and other features are mapped to Flash-style APIs for convenience. Lime has a renderer designed for use with HTML5 DOM, HTML5 Canvas, a Cairo (a native software renderer) or OpenGL targets (WebGL, OpenGL, OpenGL ES).

The HTML5 target supports three render modes. The default is HTML5 WebGL, but there is also canvas mode. Lime also supports a DOM render mode, which uses different image, div or canvas elements, and animates using CSS. The DOM rendering mode also supports `Video` and `DOMSprite` elements. Using `bitmapData.draw`, it is possible to selectively merge lements into a single canvas, similar to how canvas mode behaves for the whole project. Adding `-Dcanvas` or `-Ddom` will force canvas or DOM mode when building.