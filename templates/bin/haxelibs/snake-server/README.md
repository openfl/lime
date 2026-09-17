# Snake Server for Haxe

Create TCP and HTTP servers with the [Haxe](https://haxe.org/) programming language, or run `haxelib run snake-server` to start a local HTTP server that serves static files in a specific directory.

> **Warning!** snake-server is not recommended for production. It only implements basic security checks.

Available on [Haxe sys targets](https://haxe.org/manual/std-sys.html) only.

## Installation

Use the [**haxelib install**](https://lib.haxe.org/documentation/using-haxelib/#install) command to download Snake Server.

```sh
haxelib install snake-server
```

Requires Haxe 4.1 or newer.

## Command Line

Use the [**haxelib run**](https://lib.haxe.org/documentation/using-haxelib/#run) command to launch Snake Server in the current directory on port 8000.

```sh
haxelib run snake-server
```

### Options

The following options can be added to the **haxelib run snake-server** command to customize its behavior.

- **--bind _address_**

  bind to this address (default: 127.0.0.1)

- **--directory _path/to/dir_**

  serve this directory (default: current directory)

- **--protocol _HTTP/X.Y_**

  conform to this HTTP version (default: HTTP/1.0)

- **--port _number_**

  bind to this port (default: 8000)

- **--cors**

  add headers to enable CORS (Cross-Origin Resource Sharing)

- **--no-cache**

  add headers to disable caching in web browsers

- **--silent**

  disable logging of requests

- **--open-browser**

  launches the server's URL in a web browser

- **--help**

  print usage instructions

Example:

```sh
haxelib run snake-server --bind 0.0.0.0 --port 3000 --protocol HTTP/1.1 --directory www
```

## Haxe Documentation

- [snake-server API Reference](https://bowlerhatllc.github.io/snake-server/)

## Why did you choose "snake" for the name? 🐍

The Snake Server project's Haxe code is actually ported from the [Python](https://python.org/) language's [http.server](https://docs.python.org/3/library/http.server.html) and [socketserver](https://docs.python.org/3/library/socketserver.html) modules. [Pythons](<https://en.wikipedia.org/wiki/Python_(genus)>) are also a [type of snake](https://en.wikipedia.org/wiki/Snake). The name is simply meant to pay tribute to the code's origins.
