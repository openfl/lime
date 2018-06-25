---
title: Getting Started
---

## Install Haxe

First, you will need to install Haxe and Neko. OpenFL uses Haxe to power the build process, and Neko to run the command-line tools. Both are included in the following installers, one for each platform:

<div class="row">
	<div class="col-md-4 text-center">
		<h3><a href="http://haxe.org/website-content/downloads/3.2.1/downloads/haxe-3.2.1-win.exe"><span class="icon-windows"></span></a> <a href="http://haxe.org/website-content/downloads/3.2.1/downloads/haxe-3.2.1-win.exe">Windows</a></h3>
	</div>
	<div class="col-md-4 text-center">
		<h3><a href="http://haxe.org/website-content/downloads/3.2.1/downloads/haxe-3.2.1-osx-installer.pkg"><span class="icon-apple"></span></a> <a href="http://haxe.org/website-content/downloads/3.2.1/downloads/haxe-3.2.1-osx-installer.pkg">macOS</a></h3>
	</div>
	<div class="col-md-4 text-center">
		<h3><a href="http://www.openfl.org/builds/haxe/haxe-3.2.1-linux-installer.tar.gz"><span class="icon-linux"></span></a> <a href="http://www.openfl.org/builds/haxe/haxe-3.2.1-linux-installer.tar.gz">Linux</a></h3>
	</div>
</div>

<br />

<div class="alert alert-warning">
<p><strong>macOS users:</strong> You will need to run the following commands to finish your install:</p>
<br/>
```bash
sudo haxelib setup /usr/local/lib/haxe/lib
sudo chmod 777 /usr/local/lib/haxe/lib
```
</div>

<div class="alert alert-info">
<p><strong>Linux users:</strong> The versions of Haxe and Neko distributed on Linux package repositories can be old, or experience other issues after the install, so we recommend that you use the above install script instead.</p>
</div>

## Install OpenFL

With the latest versions of Haxe and Neko installed, open a command-prompt (Windows) or terminal (macOS/Linux) and run these commands:

```bash
haxelib install openfl
haxelib run openfl setup
```

To confirm that OpenFL is installed and working properly, try running the "openfl" command:

```bash
openfl
```

If you are upgrading, you can find more information about changes <a href="https://github.com/openfl/lime/blob/master/CHANGELOG.md" target="_blank">here</a> and <a href="https://github.com/openfl/openfl/blob/master/CHANGELOG.md" target="_blank">here</a>.

## Run a Sample

OpenFL includes a set of sample projects, from simple tutorials to more complex demos. This is a good way to confirm that OpenFL is installed properly.

You can use the "openfl create" command for a list of available samples.

```bash
openfl create
```

For example, here is how to build and run the DisplayingABitmap sample on HTML5:

```bash
openfl create DisplayingABitmap
cd DisplayingABitmap
openfl test html5
```



## Next Steps

Now that OpenFL is installed, you can [choose a code editor](/learn/docs/choosing-a-code-editor/) or start creating [your first project](/learn/tutorials/displaying-a-bitmap/)!
