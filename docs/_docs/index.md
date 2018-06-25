---
title: Getting Started
permalink: /docs/home/
redirect_from: docs/index.html
---

## Install Haxe

If you have not already, install [Haxe](https://haxe.org/download/) for your current platform. Lime supports Windows, macOS and Linux host platforms.


## Install Lime

Next, open a command-prompt (Windows) or terminal (macOS/Linux) and run the following commands:

```bash
haxelib install lime
haxelib run lime setup
```

To confirm that Lime is installed and working properly, try running the "lime" command:

```bash
lime
```


## Install a Code Editor

We recommend [Visual Studio Code](https://code.visualstudio.com), using the [Lime Extension](https://marketplace.visualstudio.com/items?itemName=openfl.lime-vscode-extension), but many other code editors are also compatible with Haxe development.


## Run a Sample

Lime includes some simple sample projects to help you get started. For example, the "SimpleImage" sample illustrates an example of rendering graphics for multiple platforms and renderers:

```bash
lime create SimpleImage
cd SimpleImage
lime test html5
lime test html5 -Dcanvas
lime test html5 -Ddom
lime test neko
lime test neko -Dcairo
lime test flash
```

Lime will use a OpenGL-based renderer by default, but attempts to fallback to a software renderer (such as HTML5 canvas or Cairo) when it is unavailable.


## Use Additional Platforms

Some platforms require some setup before they will work properly with Lime. After you confirm that things are running properly, you can try configuring a new platform:

```bash
lime setup windows
lime setup linux
lime setup mac
lime setup android
lime setup ios
```
