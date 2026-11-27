# Frame loop bench

Measures the native frame loop at Lime's own API, the same way for whichever Lime it is built
against, so that a change to the loop can be shown to be better and not only argued to be.

It is a Lime application with no framework on top: an empty window, an `update` and an empty
`Window.onMouseMove` listener. Windows only, as it posts its input with Windows messages.

## Running it

`run.py` builds the application against each Lime it is given and runs them in turn, round after
round, so that whatever else the machine is doing falls on all of them alike. Each figure it prints
is the median of the runs, with the least and the most.

```sh
python run.py --build 8.3.2=C:\haxelib-8.3.2 --build develop=C:\haxelib-develop,bench_84 --build branch=C:\haxelib-branch,bench_84,bench_request --targets neko,hl,windows --runs 5 --out results.json
```

A `--build` is a name, a haxelib repository (what `HAXELIB_PATH` would be) whose `lime` is the one
to measure, and the defines that Lime's API allows:

- none for Lime 8.3
- `bench_84` where there are frame profiles (Lime 8.4)
- `bench_request` as well where there is `Application.requestFrame()`

To make a repository for a released Lime, set `HAXELIB_PATH` to an empty folder, then
`haxelib install lime 8.3.2` and `haxelib install hxcpp`. For a checkout, copy a repository that
has what it needs, `haxelib dev lime <checkout>`, and rebuild its native library:
`lime rebuild windows -release` and `lime rebuild hl -release`.

One run takes about a minute and a half. `--runs 5` on three targets against three Limes is about
an hour. Close what else can be closed: other work on the machine shows up as late frames.

## The scenarios

| Scenario | What happens |
| --- | --- |
| `idle60`, `idle5` | 60 and 5 frames a second with nothing else going on |
| `input1000`, `input4000` | 60 frames a second while 1,000 and 4,000 mouse moves a second are posted |
| `behind` | 40 moves posted together while every update takes 30 ms of a frame of under 17 |
| `hitch` | one update of 210 ms at 50 frames a second |
| `minimised`, `minimisedHard` | every window minimised while asking for 120 frames a second, and the same with `UncapMode.HARD` |
| `precision60`, `precision1000` | as `idle60` and `input1000`, with `FrameProfile.PRECISION` |
| `lowEnergy60`, `lowEnergy1000` | the same with `FrameProfile.LOW_ENERGY` |
| `always60`, `toggled`, `asked` | an application that draws only when something changes, with an input every 200 ms. It keeps 60 frames a second regardless (`always60`), drops `Window.frameRate` to 2 and raises it on input, as applications do today (`toggled`), or sets `FrameOptions.idleFrameRate` to 2 and calls `requestFrame()` on input (`asked`) |

## The measures

| Measure | What it is | Better |
| --- | --- | --- |
| `cpu` | processor time the application used, as a share of one processor, % | lower |
| `switches` | context switches a second of every thread of the application: how often it woke | lower |
| `fps` | updates a second | the rate asked for |
| `longest` | the longest time between two updates, ms | nearer the frame period |
| `jitter` | how far the time between updates is from the frame period, on average, ms | lower |
| `deltaError` | how far the `deltaTime` an update is given is from the time since the last update, on average, ms | lower |
| `frameDeltaError` | the same for `Application.frameDeltaTime` | lower |
| `idleCalls` | calls a second of an idle listener that has nothing to do | lower |
| `moves` | moves heard a second | the rate posted |
| `turns` | separate times a second that moves were handed over: how often input woke the loop | lower |
| `delayMean`, `delayP95`, `delayMax` | how long a move waited before its listener heard it, ms, against the move that waited least | lower |
| `behind.frames` | how many frames the 40 moves were spread over | 1 |
| `behind.lastWaited` | the time from the first of them being heard to the last, ms | lower |
| `behind.missed` | moves not heard at all | 0 |
| `hitch.gapAfterLate` | the time between the frame that came late and the one after it, ms, at a frame period of 20 | 20 |
| `inputs` | inputs that were followed by an update | 21 or 22 |
| `responseMean`, `responseMax` | the time from an input's listener to the update that follows, ms | lower |
| `timerLate` | how late a `haxe.Timer` of 100 ms fired, ms | lower |
| `threadWait` | the time from work ending on another thread to the next update, ms | lower |

The clock is the performance counter on C++. On Neko it counts in whole milliseconds, and on
HashLink in about a tenth of one, so `jitter`, `deltaError` and the delays are worth reading on
C++ first.

## What it cannot measure

- A swap that waits for a display, or that should and doesn't: it draws with Cairo unless built
  with OpenGL, and the display has to be a real one.
- macOS, Linux and mobile, which have their own wait.
- A change of display scale, a game controller.
