##What it the lime wrapper?
---

The lime wrapper handles creating the window, forwarding events from the window, and giving you access to an external API that allows you to access the lime features across platforms.

For example - on html5 - it will handle the canvas creation, run loop, and provide an api like `lime.audio.create` or `lime.input.keydown` allowing you to access the features in a consistent way.

---

##Structure

The lime wrapper consistents of :   

- **Lime.hx**
  - the main entry point, and bootstrapper
- ***feature***Handler.hx 
  - The _feature_ handler, which implements the internal and external API
- **helpers/**
  - helpers to define enums, values or types and to convert values to and from the types. 
  - Also where the implementation for specific platforms is held, if needed
- **gl/**
  - The OpenGL bindings api, based directly on the WebGL spec
- **utils/**
  - common and cross platform variations of the utility classes

&nbsp;

---

##Bootstrapped?

Traditionally [bootstrapping](https://en.wikipedia.org/wiki/Bootstrapping) is characterized by a few things, but specifically in our case :

>The process involves a chain of stages, in which at each stage a smaller simpler program loads and then executes the larger more complicated program of the next stage.

This is exactly the purpose of the lime wrapper, it is light weight, low level, to the point. It picks itself up by the bootstraps, and directly executes your application with end points that allow you to communicate with the bindings.

The flow is simple, lime starts, handles any setup necessary, and immediately calls ready. Whenever an event arrives from the system, it tells your application directly. Imagine it like strapping your application on top of the wrapper, filling in the handlers for the events you want to know about.

---

##Feature details

###native
When the term native is used, it refers to the cpp targets, such as _mac_, _windows_, _linux_, _tizen_, _android_, _iOS_, and so on.

- Audio - Handled by OpenAL on all platforms
- Input - Handled by SDL and lime native code
- Windowing - Handled by SDL and lime native code
- Rendering - OpenGL exposed via the wrapper as WebGL

###html5
When the term html5 is used, it refers directly to the WebGL implementation of the lime wrapper.

- Audio - Handled by the lime wrapper through [SoundManager 2](http://www.schillmania.com/projects/soundmanager2/)
- Input - Handled by the lime wrapper
- Windowing - Handled by the lime wrapper
- Rendering - WebGL exposed via the wrapper

