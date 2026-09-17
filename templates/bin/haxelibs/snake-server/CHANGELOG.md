# Snake Server Change Log

## 2.0.0 (2026-09-17)

- Fixed failure to bind the same port when exiting and quickly restarting server.
- Fixed unknown exception when client disconnects before a request is completed.
- Changed to use libuv TCP socket on eval/interp target for better parity with `sys.net.Socket` on other targets.

## 1.2.0 (2024-08-06)

- Added `--silent` command line option to disable request logging (internal errors are still logged).
- Added `--open-browser` command line option to launch a web browser with the server's URL.
- Modified behavior when using HTTP/1.0 (the default protocol) to make server single threaded for improved stability.
- Fixed unclosed file handle when exception is thrown while copying to socket.
- Fixed client address in logs and errors that incorrectly showed host address instead.
- Fixed missing early return when request headers cannot be parsed due to being too large.

## 1.1.0 (2024-05-21)

- Added `--cors` command line option to enable CORS header.
- Added `--no-cache` command line option to set appropriate 'Cache-Control' header.
- Added `--help` command line option.
- Modified 'Server' header to replace 'SimpleHTTP' with 'SnakeServer'.
- Fixed `--directory` option, which was incorrectly ignored.

## 1.0.0 (2024-05-17)

- Initial release
