#lime - Light Media Engine

A lightweight OpenGL framework for [haxe](http://haxe.org).

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

lime is a cross platform haxe library powered by [hxtools](http://github.com/openfl/hxtools), for building opengl across many platforms. 

Frameworks like [OpenFL](http://github.com/openfl) leverage lime to implement a cross platform Flash API.

#Things to note

- lime is low level. It does the bare minimum to give you access to the metal - without making it difficult.
- lime works by default by bootstrapping your application main class into the framework. 
- lime will call functions into your class, for mouse, keys, gamepad and other system or windowing events (resizing, for example).
- lime exposes an API to talk to the windowing, audio and other API's across platforms.
