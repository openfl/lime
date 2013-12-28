#lime 
---
light media engine   
A lightweight OpenGL framework for [haxe](http://haxe.org).

![lime](lime.png)


A starting point for building OpenGL applications across Mac, Windows, Linux, Blackberry, HTML5(WebGL), Android, iOS and more.

#What it does
	
lime exposes the following

- OpenGL
- Audio
- Input
- Windowing
- Useful native features

By setting up a bootstrap for your application, lime will handle all the low level events and call into your main class (this can be overridden) for you. 

#How it works

lime is a cross platform haxe library powered by [lime-tools](http://github.com/openfl/lime-tools), for building upon opengl across many platforms. 

### lime is two parts
**One part** is the native code, the underlying platform templates and systems to expose the features.    
**The second part** is the haxe wrapper, forwarding the events to your application.

For example, frameworks like [OpenFL](http://github.com/openfl) leverage lime to implement a cross platform Flash API by leaning on the native portion, without using the current lime haxe classes at all.

#Things to note

- lime (native, and wrapper) are low level. It does the bare minimum to give you access to the metal - without making it difficult.
- The lime wrapper works by default by bootstrapping your application main class into the framework. 
- The lime wrapper will call functions into your class, for mouse, keys, gamepad and other system or windowing events (resizing, for example). Then, you handle them.
- The lime wrapper exposes an API to talk to the windowing, audio and other API's across platforms.

- The lime GL wrapper code is based on WebGL Api. It matches very closely. Including types and constants.
- The lime native parts were forked from [nme](http://github.com/haxenme/nme) (native media engine) and merged into  openfl-native - but now (and lastly) been merged into lime and joined forces to create an agnostic, cross platform starting point to widen the haxe landscape for all frameworks and framework developers.
- See the wiki for a 1.0 wrapper [roadmap](https://github.com/openfl/lime/wiki/lime-wrapper-1.0-Roadmap). 

Expect docs, diagrams and breakdowns of how to get started using lime soon. See the examples/ folder for the basics for now.

# Using Development Builds

    git clone https://github.com/openfl/lime
    haxelib dev lime lime
    git clone https://github.com/openfl/lime-build
    haxelib dev lime-build lime-build

After cloning, "lime/ndll" will be empty. You can build binaries for a platform, use "lime rebuild" or "openfl rebuild", such as:

    lime rebuild windows
    lime rebuild windows,blackberry
    lime rebuild linux -64
    lime rebuild android -debug

If you are running Linux, you will (probably) need to install additional packages to build from the source. For an Ubuntu system, it may look like this:

    sudo apt-get install libgl1-mesa-dev libglu1-mesa-dev g++ g++-multilib gcc-multilib
    
For other platforms, the dependencies will be similar to compiling standard Lime/OpenFL applications for the platform, for example, you will need Visual Studio for Windows builds, Xcode for Mac and iOS builds, etc. Platforms which require "setup" step, such as Android, should have that completed, such as "lime setup android"

The default "rebuild" for each target compiles all needed binaries, such as x86, armv5 and arm7 for release and debug. You can use "-debug", "-release", "-64" and "-32" to specify that you only want to rebuild one kind of binary. You can use commas to separate multiple builds.

There is also a helpful "-rebuild" flag you can use in combination with other Lime/OpenFL commands, to rebuild the required binaries in addition to the meaning of the original command. For example, this will test the current application for Windows, while first building release platform binary before packaging:

    lime test windows -rebuild
    
To return to release builds:

    haxelib dev lime
