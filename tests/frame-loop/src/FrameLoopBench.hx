package;

import haxe.Timer;
import lime.app.Application;
import lime.app.Future;
import lime.ui.Window;
import sys.thread.Thread;
#if bench_84
import lime.app.FrameProfile;
import lime.app.TimePrecision;
import lime.app.UncapMode;
#end

/**
	Measures the native frame loop at Lime's own API, the same way for whichever Lime it is built
	against: 8.3, 8.4 before the frame loop work (`-Dbench_84`), or 8.4 with it (`-Dbench_84
	-Dbench_request`). `run.py` builds it against each and prints them side by side.

	Each line it prints is `BENCH scenario.measure value`. README.md says what each measure is.
	`BENCH_ONLY=idle60,behind` in the environment runs those scenarios alone.
	Windows only: input is posted to a hidden window by a PowerShell helper, and another reads
	the process's processor cycles and context switches.
**/
class FrameLoopBench extends Application
{
	private static inline var TITLE = "LimeFrameLoopBenchInput";
	private static inline var SECONDS = 6.0;

	private var input:Window;
	// One PowerShell posts the input, and another reads the processor cycles and context
	// switches meanwhile, and sends the messages that are timed
	private var helper:sys.io.Process;
	private var sampler:sys.io.Process;
	// The cycles a processor of this machine runs in a second
	private var cyclesPerSecond = 0.0;
	// What the sampler said of the messages it sent
	private var sentLine:String = null;
	private var posting = false;
	private var started = false;
	private var steps:Array<(Void->Void)->Void> = [];
	private var waits:Array<{at:Float, run:Void->Void}> = [];
	private var updates = 0;

	// What the scenario under way records
	private var frames:Array<Float> = null;
	private var deltas:Array<Int> = null;
	private var preciseDeltas:Array<Float> = null;
	private var heard = 0;
	private var moveTimes:Array<Float> = [];
	private var moveIndexes:Array<Int> = [];
	private var moveUpdates:Array<Int> = [];
	// The moves heard while the last recording ran: from the first of these to before the last
	private var recordedFrom = 0;
	private var recordedTo = 0;
	private var perUpdate:Void->Void = null;
	private var perMove:Void->Void = null;

	public function new()
	{
		super();
	}

	// Timer.stamp() counts in whole milliseconds on native targets
	private static inline function clock():Float
	{
		return #if cpp untyped __global__.__time_stamp() #else Sys.time() #end;
	}

	private static function spin(seconds:Float):Void
	{
		var until = clock() + seconds;
		while (clock() < until) {}
	}

	private static function report(scenario:String, measure:String, value:Float):Void
	{
		Sys.println("BENCH " + scenario + "." + measure + " " + (Math.round(value * 1000) / 1000));
	}

	private function after(seconds:Float, run:Void->Void):Void
	{
		waits.push({at: clock() + seconds, run: run});
	}

	override public function update(deltaTime:Int):Void
	{
		var now = clock();

		if (!started)
		{
			started = true;
			after(0.6, begin);
		}

		updates++;

		if (frames != null)
		{
			frames.push(now);
			deltas.push(deltaTime);
			#if bench_request
			preciseDeltas.push(frameDeltaTime);
			#end
		}

		if (perUpdate != null) perUpdate();

		var i = 0;
		while (i < waits.length)
		{
			if (now >= waits[i].at) waits.splice(i, 1)[0].run();
			else i++;
		}
	}

	private function begin():Void
	{
		if (Sys.systemName() != "Windows")
		{
			Sys.println("BENCH skipped: input is posted through Windows messages");
			Sys.exit(0);
		}

		input = createWindow({width: 64, height: 64, hidden: true, title: TITLE});

		input.onMouseMove.add(function(x:Float, y:Float)
		{
			// SDL adds moves of its own as the real cursor comes and goes
			if (y != 7) return;
			moveTimes.push(clock());
			moveIndexes.push(heard++);
			moveUpdates.push(updates);
			if (perMove != null) perMove();
		});

		startHelpers();
		window.frameRate = 60;

		var only = Sys.getEnv("BENCH_ONLY");
		var chosen = only != null && only != "" ? only.split(",") : null;
		var add = function(name:String, step:(Void->Void)->Void)
		{
			if (chosen == null || chosen.indexOf(name) != -1) steps.push(step);
		};

		add("idle60", function(next) idle("idle60", 60, next));
		add("input1000", function(next) stream("input1000", 1000, next));
		add("input4000", function(next) stream("input4000", 4000, next));
		add("behind", function(next) behind(next));
		add("hitch", function(next) hitch(next));
		add("idle5", function(next) idle("idle5", 5, next));
		add("rest2", function(next) rest("rest2", false, next));
		#if bench_request
		add("restIdle", function(next) rest("restIdle", true, next));
		#end
		add("minimised", function(next) minimised("minimised", false, next));
		#if bench_84
		add("minimisedHard", function(next) minimised("minimisedHard", true, next));
		add("precision60", function(next)
		{
			frameProfile = FrameProfile.PRECISION;
			idle("precision60", 60, function()
			{
				frameProfile = FrameProfile.BALANCED;
				next();
			});
		});
		add("precision1000", function(next)
		{
			frameProfile = FrameProfile.PRECISION;
			stream("precision1000", 1000, function()
			{
				frameProfile = FrameProfile.BALANCED;
				next();
			});
		});
		add("lowEnergy60", function(next)
		{
			frameProfile = FrameProfile.LOW_ENERGY;
			idle("lowEnergy60", 60, function()
			{
				frameProfile = FrameProfile.BALANCED;
				next();
			});
		});
		add("lowEnergy1000", function(next)
		{
			frameProfile = FrameProfile.LOW_ENERGY;
			stream("lowEnergy1000", 1000, function()
			{
				frameProfile = FrameProfile.BALANCED;
				next();
			});
		});
		// The default profile with the clock in whole milliseconds, to tell what the clock does
		// from what the wait does
		add("millisecond60", function(next)
		{
			var options = frameOptions;
			options.timePrecision = TimePrecision.MILLISECOND;
			frameOptions = options;

			idle("millisecond60", 60, function()
			{
				var options = frameOptions;
				options.timePrecision = TimePrecision.AUTO;
				frameOptions = options;
				next();
			});
		});
		#end
		add("always60", function(next) onDemand("always60", 0, next));
		add("toggled", function(next) onDemand("toggled", 1, next));
		#if bench_request
		add("asked", function(next) onDemand("asked", 2, next));
		#end

		steps.push(function(next)
		{
			for (process in [helper, sampler])
			{
				process.stdin.writeString("quit\n");
				process.stdin.flush();
			}

			Sys.println("BENCH done");
			Sys.exit(0);
		});

		runNext();
	}

	private function runNext():Void
	{
		var step = steps.shift();
		// Each scenario starts from a moment of the loop at rest
		after(0.3, function() step(runNext));
	}

	// Scenarios

	/** Frames at a rate with nothing else going on: what waiting costs, and how evenly frames start **/
	private function idle(name:String, rate:Float, done:Void->Void):Void
	{
		window.frameRate = rate;

		#if bench_84
		// The time before a frame is offered to an idle listener. One with nothing to do, as
		// this one, should not be what the loop wakes for.
		var backend = @:privateAccess __backend;
		var previous = @:privateAccess backend.__idleCallback;
		var idleCalls = 0;
		@:privateAccess backend.__setIdleCallback(function() idleCalls++);
		#end

		record(name, SECONDS, 1000 / rate, function(seconds:Float)
		{
			#if bench_84
			@:privateAccess backend.__setIdleCallback(previous);
			report(name, "idleCalls", idleCalls / seconds);
			#end
			window.frameRate = 60;
			done();
		});
	}

	/**
		Nothing going on and nothing to draw: what an application at rest costs. Its frame rate is
		2, as an application sets it today, or its idle frame rate is, with no frame asked for.
	**/
	private function rest(name:String, idle:Bool, done:Void->Void):Void
	{
		#if bench_request
		if (idle)
		{
			var options = frameOptions;
			options.idleFrameRate = 2;
			frameOptions = options;
		}
		#end

		if (!idle) window.frameRate = 2;

		// Once the frames that were under way are over
		after(0.6, function()
		{
			record(name, SECONDS, 0, function(seconds:Float)
			{
				#if bench_request
				if (idle)
				{
					var options = frameOptions;
					options.idleFrameRate = 0;
					frameOptions = options;
				}
				#end

				window.frameRate = 60;
				done();
			});
		});
	}

	/**
		Mouse moves at a steady rate: what input costs, how often it wakes the loop, and how long
		it waits. Ten times a second meanwhile another process sends the window a message and
		waits for the answer, as a screen reader or the shell does.
	**/
	private function stream(name:String, rate:Int, done:Void->Void):Void
	{
		var interval = 1000 / rate;
		heard = 0;
		moveTimes = [];
		moveIndexes = [];
		post(Std.int(rate * (SECONDS + 2.5)), interval);

		var wait:Void->Void = null;
		wait = function()
		{
			if (heard < 20)
			{
				after(0.05, wait);
				return;
			}

			record(name, SECONDS, 1000 / 60, function(seconds:Float)
			{
				var first = recordedFrom;
				var last = recordedTo;
				var turns = 0;
				var early = Math.POSITIVE_INFINITY;

				// Each move's time against the place it has in the helper's schedule. The one
				// that came soonest stands for a move heard at once.
				for (i in first...last)
				{
					var offset = moveTimes[i] * 1000 - moveIndexes[i] * interval;
					if (offset < early) early = offset;
					if (i == first || moveTimes[i] - moveTimes[i - 1] >= 0.0005) turns++;
				}

				var delays = [for (i in first...last) moveTimes[i] * 1000 - moveIndexes[i] * interval - early];
				delays.sort(Reflect.compare);

				report(name, "moves", (last - first) / seconds);
				report(name, "turns", turns / seconds);

				if (delays.length > 0)
				{
					report(name, "delayMean", mean(delays));
					report(name, "delayP95", delays[Std.int(delays.length * 0.95)]);
					report(name, "delayMax", delays[delays.length - 1]);
				}

				if (sentLine != null)
				{
					var sent = sentLine.split(" ");
					report(name, "sendMedian", Std.parseFloat(sent[1]));
					report(name, "sendP95", Std.parseFloat(sent[2]));
					report(name, "sendMax", Std.parseFloat(sent[3]));
					sentLine = null;
				}

				finishPost();
				done();
			}, function()
			{
				// Over well before the recording is, as the sampler reads the cycles after them
				sentLine = null;
				sampler.stdin.writeString("send " + Std.int((SECONDS - 2) * 10) + " 100\n");
				sampler.stdin.flush();
			});
		};

		wait();
	}

	/**
		Forty moves posted together while every update takes 30 ms of a frame of under 17, so a
		frame is always due: how many frames the moves are spread over, and how long the last waits
	**/
	private function behind(done:Void->Void):Void
	{
		var spreads:Array<Float> = [];
		var times:Array<Float> = [];
		var missed = 0;
		var round = 0;
		var burst:Void->Void = null;

		window.frameRate = 60;
		perUpdate = function() spin(0.03);

		burst = function()
		{
			heard = 0;
			moveTimes = [];
			moveIndexes = [];
			moveUpdates = [];
			post(40, 0);

			var begun = clock();
			var wait:Void->Void = null;

			wait = function()
			{
				if (heard < 40 && clock() - begun < 4)
				{
					after(0.03, wait);
					return;
				}

				finishPost();

				if (heard >= 2)
				{
					spreads.push(moveUpdates[heard - 1] - moveUpdates[0] + 1);
					times.push((moveTimes[heard - 1] - moveTimes[0]) * 1000);
				}

				if (heard < 40) missed += 40 - heard;

				if (++round < 5)
				{
					after(0.2, burst);
					return;
				}

				perUpdate = null;
				report("behind", "frames", median(spreads));
				report("behind", "lastWaited", median(times));
				report("behind", "missed", missed);
				done();
			};

			wait();
		};

		burst();
	}

	/** One update of 210 ms at 50 frames a second: how soon the frame after the late one follows it **/
	private function hitch(done:Void->Void):Void
	{
		var gaps:Array<Float> = [];
		var stage = 0;
		var count = 0;
		var late = 0.0;

		window.frameRate = 50;

		perUpdate = function()
		{
			count++;

			if (stage == 0 && count >= 10)
			{
				stage = 1;
				spin(0.21);
			}
			else if (stage == 1)
			{
				// The frame that was due while the long one ran
				late = clock();
				stage = 2;
			}
			else if (stage == 2)
			{
				gaps.push((clock() - late) * 1000);
				stage = 0;
				count = 0;

				if (gaps.length == 5)
				{
					perUpdate = null;
					window.frameRate = 60;
					report("hitch", "gapAfterLate", median(gaps));
					done();
				}
			}
		};
	}

	/** Every window minimised while the application asks for 120 frames a second **/
	private function minimised(name:String, hard:Bool, done:Void->Void):Void
	{
		#if bench_84
		if (hard)
		{
			var options = frameOptions;
			options.uncapMode = UncapMode.HARD;
			frameOptions = options;
		}
		#end

		window.frameRate = 120;
		window.minimized = true;

		after(0.8, function()
		{
			record(name, SECONDS, 0, function(seconds:Float)
			{
				window.minimized = false;

				#if bench_84
				if (hard)
				{
					var options = frameOptions;
					options.uncapMode = UncapMode.OFF;
					frameOptions = options;
				}
				#end

				window.frameRate = 60;
				after(0.6, done);
			});
		});
	}

	/**
		An application that draws only when something changes, with an input every 200 ms: frames
		always at 60 a second (mode 0), the frame rate dropped to 2 and raised on input, which is
		what applications do today (mode 1), or an idle frame rate of 2 with a frame asked for on
		input (mode 2). What it costs while it idles, how soon the frame follows the input, how
		late a timer of 100 ms fires, and how soon an update follows work that ended on another thread.
	**/
	private function onDemand(name:String, mode:Int, done:Void->Void):Void
	{
		var responses:Array<Float> = [];
		var timers:Array<Float> = [];
		var threads:Array<Float> = [];
		var futures:Array<Float> = [];
		var events:Array<Float> = [];
		#if (haxe_ver >= 4.2)
		var main = Thread.current();
		#end
		var pending = -1.0;
		var threadEnded = 0.0;
		var count = 0;
		// Reading the context switches as the recording ends holds the loop up, so a timer or
		// a thread started just before it would be charged with that
		var startUntil = Math.POSITIVE_INFINITY;

		if (mode == 1) window.frameRate = 2;

		#if bench_request
		if (mode == 2)
		{
			var options = frameOptions;
			options.idleFrameRate = 2;
			frameOptions = options;
		}
		#end

		perMove = function()
		{
			var now = clock();
			if (pending < 0) pending = now;
			count++;

			if (mode == 1) window.frameRate = 60;
			#if bench_request
			if (mode == 2) requestFrame();
			#end

			if (count % 4 == 1 && now < startUntil)
			{
				Timer.delay(function() timers.push((clock() - now) * 1000 - 100), 100);
			}

			if (count % 4 == 3 && now < startUntil)
			{
				Thread.create(function()
				{
					Sys.sleep(0.05);
					threadEnded = clock();
					#if bench_request
					if (mode == 2) requestFrame();
					#end
				});
			}

			#if (haxe_ver >= 4.2)
			// An event for the main thread's loop from another thread, with no frame asked for
			if (count % 4 == 2 && now < startUntil)
			{
				Thread.create(function()
				{
					Sys.sleep(0.05);
					var given = clock();
					main.events.run(function() events.push((clock() - given) * 1000));
				});
			}
			#end

			// Work for a thread pool, as a load is, which the application asks no frame for
			if (count % 4 == 0 && now < startUntil)
			{
				var ended = 0.0;

				new Future<Int>(function()
				{
					Sys.sleep(0.05);
					ended = clock();
					return 1;
				}, true).onComplete(function(_) futures.push((clock() - ended) * 1000));
			}
		};

		perUpdate = function()
		{
			var now = clock();

			if (pending >= 0)
			{
				responses.push((now - pending) * 1000);
				pending = -1;
				if (mode == 1) window.frameRate = 2;
			}

			if (threadEnded > 0)
			{
				threads.push((now - threadEnded) * 1000);
				threadEnded = 0;
			}
		};

		heard = 0;
		moveTimes = [];
		moveIndexes = [];

		record(name, SECONDS, 0, function(seconds:Float)
		{
			// The timers and threads of the last inputs
			after(0.7, function()
			{
				perMove = null;
				perUpdate = null;
				window.frameRate = 60;

				#if bench_request
				if (mode == 2)
				{
					var options = frameOptions;
					options.idleFrameRate = 0;
					frameOptions = options;
				}
				#end

				finishPost();
				report(name, "inputs", responses.length);
				if (responses.length > 0) report(name, "responseMean", mean(responses));
				if (responses.length > 0) report(name, "responseMax", max(responses));
				if (timers.length > 0) report(name, "timerLate", mean(timers));
				if (threads.length > 0) report(name, "threadWait", mean(threads));
				if (futures.length > 0) report(name, "futureWait", mean(futures));
				if (events.length > 0) report(name, "eventWait", mean(events));
				done();
			});
		}, function()
		{
			startUntil = clock() + SECONDS - 0.7;
			post(Std.int(SECONDS * 5) + 2, 200);
		});
	}

	// Recording

	/**
		Records a scenario for the seconds given: the processor cycles and context switches the
		process used, and, with a frame period in milliseconds, how evenly its updates came.
		`begun` is called as the recording starts.
	**/
	private function record(name:String, seconds:Float, period:Float, done:Float->Void, ?begun:Void->Void):Void
	{
		var sample0 = sample();
		var sampleTime0 = clock();

		// The reading held the loop up, so the frames are recorded once it has run again
		after(0.25, function()
		{
			var time0 = clock();
			frames = [];
			deltas = [];
			preciseDeltas = [];
			recordedFrom = moveTimes.length;
			if (begun != null) begun();

			after(seconds, function()
			{
				var time1 = clock();
				var times = frames;
				var whole = deltas;
				var precise = preciseDeltas;
				frames = null;
				deltas = null;
				preciseDeltas = null;
				recordedTo = moveTimes.length;

				var sample1 = sample();
				var sampled = clock() - sampleTime0;
				var elapsed = time1 - time0;

				// The cycles the process ran for, of those one processor runs in that time.
				// Processor time as Sys.cpuTime() gives it is counted in clock ticks of 15.6 ms,
				// which a loop that wakes for microseconds mostly falls between.
				report(name, "cpu", (sample1.cycles - sample0.cycles) / (cyclesPerSecond * sampled) * 100);
				report(name, "wakes", (sample1.wakes - sample0.wakes) / sampled);
				report(name, "switches", (sample1.switches - sample0.switches) / sampled);

				if (times.length > 2)
				{
					var gaps = [for (i in 1...times.length) (times[i] - times[i - 1]) * 1000];
					report(name, "fps", gaps.length / (times[times.length - 1] - times[0]));
					report(name, "longest", max(gaps));

					if (period > 0)
					{
						report(name, "jitter", mean([for (gap in gaps) Math.abs(gap - period)]));

						// How far the time an update is given is from the time that passed
						report(name, "deltaError", mean([for (i in 1...times.length) Math.abs(whole[i] - gaps[i - 1])]));
						#if bench_request
						report(name, "frameDeltaError", mean([for (i in 1...times.length) Math.abs(precise[i] - gaps[i - 1])]));
						#end
					}
				}

				done(elapsed);
			});
		});
	}

	// The helpers

	private function startHelpers():Void
	{
		var script = "$ErrorActionPreference = 'Stop'\n"
			+ "Add-Type -Namespace LimeBench -Name User32 -MemberDefinition '"
			+ "[DllImport(\"user32.dll\")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);"
			+ "[DllImport(\"user32.dll\", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowW(IntPtr className, string title);'\n"
			// The context switches of a process's threads, from one system call. The performance
			// counters give the same number, and take seconds to. The cycles its threads ran for
			// are counted by the system as each is switched in and out, and a second of them is
			// measured on a thread that does nothing else.
			+ "Add-Type -TypeDefinition '"
			+ "using System; using System.Diagnostics; using System.Globalization; using System.Collections.Generic; using System.Runtime.InteropServices;"
			+ " namespace LimeBench { public static class Threads {"
			+ " [DllImport(\"ntdll.dll\")] static extern int NtQuerySystemInformation(int kind, IntPtr buffer, int length, out int needed);"
			+ " [DllImport(\"kernel32.dll\")] static extern IntPtr OpenProcess(int access, bool inherit, int id);"
			+ " [DllImport(\"kernel32.dll\")] static extern bool QueryProcessCycleTime(IntPtr process, out ulong cycles);"
			+ " [DllImport(\"kernel32.dll\")] static extern bool QueryThreadCycleTime(IntPtr thread, out ulong cycles);"
			+ " [DllImport(\"kernel32.dll\")] static extern IntPtr GetCurrentThread();"
			+ " [DllImport(\"user32.dll\")] static extern IntPtr SendMessageTimeoutW(IntPtr window, uint message, IntPtr wParam, IntPtr lParam, uint flags, uint timeout, out IntPtr result);"
			+ " static IntPtr process = IntPtr.Zero;"
			+ " public static ulong Cycles(int id) { if (process == IntPtr.Zero) process = OpenProcess(0x1000, false, id);"
			+ " ulong cycles; return QueryProcessCycleTime(process, out cycles) ? cycles : 0; }"
			+ " public static double CyclesPerSecond() { double best = 0; for (int i = 0; i < 8; i++) { ulong before, after; Stopwatch watch = Stopwatch.StartNew();"
			+ " QueryThreadCycleTime(GetCurrentThread(), out before); while (watch.Elapsed.TotalMilliseconds < 40) { }"
			+ " QueryThreadCycleTime(GetCurrentThread(), out after); double rate = (after - before) / watch.Elapsed.TotalSeconds; if (rate > best) best = rate; } return best; }"
			+ " public static string Send(IntPtr window, int count, int apart) { List<double> waits = new List<double>(); for (int i = 0; i < count; i++) {"
			+ " System.Threading.Thread.Sleep(apart); long start = Stopwatch.GetTimestamp(); IntPtr result;"
			+ " SendMessageTimeoutW(window, 0, IntPtr.Zero, IntPtr.Zero, 0, 2000, out result);"
			+ " waits.Add((Stopwatch.GetTimestamp() - start) * 1000.0 / Stopwatch.Frequency); } waits.Sort(); if (waits.Count == 0) return \"0 0 0\";"
			+ " return String.Format(CultureInfo.InvariantCulture, \"{0:F3} {1:F3} {2:F3}\", waits[waits.Count / 2], waits[(int)(waits.Count * 0.95)], waits[waits.Count - 1]); }"
			// Those of every thread, and those of the thread that was made first, which the
			// application's loop runs on
			+ " public static string Switches(int id) { int size = 1 << 21; for (int attempt = 0; attempt < 8; attempt++) {"
			+ " IntPtr buffer = Marshal.AllocHGlobal(size); try { int needed; int status = NtQuerySystemInformation(5, buffer, size, out needed);"
			+ " if (status == unchecked((int)0xC0000004)) { size = needed + (1 << 18); continue; } if (status != 0) return \"-1 -1\";"
			+ " long offset = 0; while (true) { IntPtr entry = new IntPtr(buffer.ToInt64() + offset);"
			+ " int next = Marshal.ReadInt32(entry, 0); int threads = Marshal.ReadInt32(entry, 4);"
			+ " if (Marshal.ReadIntPtr(entry, 0x50).ToInt64() == id) { long total = 0; long first = Int64.MaxValue; long main = 0;"
			+ " for (int i = 0; i < threads; i++) { int at = 0x100 + i * 0x50; long made = Marshal.ReadInt64(entry, at + 0x10);"
			+ " long count = (uint)Marshal.ReadInt32(entry, at + 0x40); total += count; if (made < first) { first = made; main = count; } }"
			+ " return total + \" \" + main; }"
			+ " if (next == 0) return \"-1 -1\"; offset += next; } } finally { Marshal.FreeHGlobal(buffer); } } return \"-1 -1\"; } } }'\n"
			+ "$h = [LimeBench.User32]::FindWindowW([IntPtr]::Zero, '" + TITLE + "')\n"
			+ "if ($h -eq [IntPtr]::Zero) { exit 2 }\n"
			+ "$parent = (Get-CimInstance Win32_Process -Filter \"ProcessId=$PID\").ParentProcessId\n"
			+ "$watch = [Diagnostics.Stopwatch]::StartNew()\n"
			+ "[Console]::Out.WriteLine('ready')\n"
			+ "while ($true) {\n"
			+ "  $line = [Console]::In.ReadLine()\n"
			+ "  if ($line -eq $null) { break }\n"
			+ "  $a = $line.Split(' ')\n"
			+ "  if ($a[0] -eq 'post') {\n"
			+ "    $n = [int]$a[1]; $dt = [double]$a[2]; $t0 = $watch.Elapsed.TotalMilliseconds\n"
			+ "    for ($i = 0; $i -lt $n; $i++) {\n"
			+ "      while ($watch.Elapsed.TotalMilliseconds - $t0 -lt $i * $dt) { }\n"
			+ "      [void][LimeBench.User32]::PostMessage($h, 0x0200, [IntPtr]0, [IntPtr](($i % 60) + 1 + (7 -shl 16)))\n"
			+ "    }\n"
			+ "    [Console]::Out.WriteLine('posted')\n"
			+ "  } elseif ($a[0] -eq 'sample') {\n"
			+ "    $sum = [LimeBench.Threads]::Switches($parent)\n"
			+ "    $cycles = [LimeBench.Threads]::Cycles($parent)\n"
			+ "    [Console]::Out.WriteLine(\"sample $sum $cycles\")\n"
			+ "  } elseif ($a[0] -eq 'rate') {\n"
			+ "    $rate = [LimeBench.Threads]::CyclesPerSecond().ToString('F0', [Globalization.CultureInfo]::InvariantCulture)\n"
			+ "    [Console]::Out.WriteLine(\"rate $rate\")\n"
			+ "  } elseif ($a[0] -eq 'send') {\n"
			+ "    $sent = [LimeBench.Threads]::Send($h, [int]$a[1], [int]$a[2])\n"
			+ "    [Console]::Out.WriteLine(\"sent $sent\")\n"
			+ "  } elseif ($a[0] -eq 'quit') { break }\n"
			+ "}\n";

		// From a file beside the application, which needs no quoting
		var file = "FrameLoopBenchHelper.ps1";
		sys.io.File.saveContent(file, script);

		// HashLink starts a process by its path, without looking through PATH
		var root = Sys.getEnv("SystemRoot");
		var path = root != null ? root + "\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" : null;
		var powerShell = path != null && sys.FileSystem.exists(path) ? path : "powershell";
		var arguments = ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", file];

		helper = new sys.io.Process(powerShell, arguments);
		sampler = new sys.io.Process(powerShell, arguments);

		for (process in [helper, sampler])
		{
			var line = try process.stdout.readLine() catch (error:Dynamic) null;

			if (line != "ready")
			{
				Sys.println("BENCH failed: a helper did not start: " + process.stderr.readAll().toString());
				Sys.exit(1);
			}
		}

		sampler.stdin.writeString("rate\n");
		sampler.stdin.flush();
		cyclesPerSecond = Std.parseFloat(sampler.stdout.readLine().substr(5));

		if (!(cyclesPerSecond > 0))
		{
			Sys.println("BENCH failed: the processor's cycles could not be counted");
			Sys.exit(1);
		}

		// The first reading is slow
		sample();
	}

	/** Has the helper post moves, the milliseconds given apart, and returns at once **/
	private function post(count:Int, interval:Float):Void
	{
		helper.stdin.writeString("post " + count + " " + interval + "\n");
		helper.stdin.flush();
		posting = true;
	}

	/** Waits for the helper to have posted everything **/
	private function finishPost():Void
	{
		if (!posting) return;
		posting = false;
		helper.stdout.readLine();
	}

	/**
		The context switches of every thread of this process since it started, those of its main
		thread, and the cycles its threads ran for
	**/
	private function sample():{switches:Float, wakes:Float, cycles:Float}
	{
		sampler.stdin.writeString("sample\n");
		sampler.stdin.flush();

		while (true)
		{
			var line = sampler.stdout.readLine();

			// What it has to say of the messages it sent comes first
			if (StringTools.startsWith(line, "sent "))
			{
				sentLine = line;
				continue;
			}

			var parts = line.split(" ");
			return {switches: Std.parseFloat(parts[1]), wakes: Std.parseFloat(parts[2]), cycles: Std.parseFloat(parts[3])};
		}
	}

	// Numbers

	private static function mean(values:Array<Float>):Float
	{
		var total = 0.0;
		for (value in values) total += value;
		return values.length > 0 ? total / values.length : 0;
	}

	private static function max(values:Array<Float>):Float
	{
		var most = values[0];
		for (value in values) if (value > most) most = value;
		return most;
	}

	private static function median(values:Array<Float>):Float
	{
		if (values.length == 0) return 0;
		var sorted = values.copy();
		sorted.sort(Reflect.compare);
		return sorted[sorted.length >> 1];
	}
}
