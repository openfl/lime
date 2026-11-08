# Window creation tests

Run `lime test neko`, `lime test hl`, or `lime test windows` from this directory.
On Linux, use `xvfb-run -a lime test neko` or `xvfb-run -a lime test linux`.

The application rejects its first window using an invalid SDL video driver,
checks that the error reaches Haxe without registering a window, then restores
the driver and creates a window in the same process.

To check the generated startup failure path on a Linux runner without a display:

```sh
lime build neko -release -Dwindow_creation_startup_failure
python3 check_startup.py bin/neko/bin/WindowCreationTest
```

This checks that startup reports the SDL error and exits with code 1.
