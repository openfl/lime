package system;

import lime.system.StorageVolume;
import utest.Assert;
import utest.Async;
import utest.Test;
#if sys
import haxe.io.Path;
import sys.FileSystem;
#end

/**
	`StorageVolume.getVolumes`, `onMount` and `onUnmount`.

	On Windows, where `LIME_TEST_VOLUMES` is `1`, as on CI, a folder is
	mounted with `subst` on a free drive letter and removed again, which
	`onMount` and `onUnmount` see as a volume coming and going. The drive is
	removed whatever happens, also in `teardown`.
**/
class StorageVolumeTest extends Test
{
	#if windows
	private var substDrive:String;
	private var substFolder:String;
	#end

	public function new()
	{
		super();
	}

	public function testTheEventsAreThereToListenTo():Void
	{
		// Even where volumes cannot be listed, so code listening works everywhere
		Assert.notNull(StorageVolume.onMount);
		Assert.notNull(StorageVolume.onUnmount);

		var listener = function(volume:StorageVolume) {};
		StorageVolume.onMount.add(listener);
		StorageVolume.onUnmount.add(listener);
		Assert.isTrue(StorageVolume.onMount.has(listener));
		StorageVolume.onMount.remove(listener);
		StorageVolume.onUnmount.remove(listener);
		Assert.isFalse(StorageVolume.onMount.has(listener));
	}

	public function testNothingIsListedWhereVolumesAreNotSupported():Void
	{
		if (StorageVolume.isSupported)
		{
			Assert.notNull(StorageVolume.getVolumes());
			return;
		}

		var volumes = StorageVolume.getVolumes();
		Assert.notNull(volumes);
		Assert.equals(0, volumes.length);
	}

	#if (lime_cffi && !macro && (windows || mac || linux))
	public function testEachVolumeHasARootAndAName():Void
	{
		if (!canList()) return;

		var volumes = StorageVolume.getVolumes();
		Assert.isTrue(volumes.length > 0, "no volume is listed");

		var roots = new Map<String, Bool>();

		for (volume in volumes)
		{
			Assert.notNull(volume.rootDirectory);
			Assert.notNull(volume.name);
			Assert.notNull(volume.fileSystemType);
			if (volume.rootDirectory == null || volume.name == null) continue;

			Assert.isTrue(volume.name.length > 0, volume.rootDirectory + " has no name");
			Assert.isFalse(roots.exists(volume.rootDirectory), volume.rootDirectory + " is listed twice");
			roots.set(volume.rootDirectory, true);

			#if windows
			Assert.isTrue(volume.drive != null && ~/^[A-Z]$/.match(volume.drive), "\"" + volume.drive + "\" is not a drive letter");
			Assert.equals(volume.drive + ":\\", volume.rootDirectory);
			#else
			Assert.isNull(volume.drive, "a volume has a drive letter outside Windows");
			Assert.isTrue(StringTools.startsWith(volume.rootDirectory, "/"), volume.rootDirectory + " is not a path from the root");
			#end
		}
	}

	public function testTheSystemVolumeIsListed():Void
	{
		if (!canList()) return;

		#if windows
		var systemDrive = Sys.getEnv("SystemDrive");
		var root = (systemDrive != null && systemDrive != "" ? systemDrive : "C:").toUpperCase() + "\\";
		#else
		var root = "/";
		#end

		var found = null;

		for (volume in StorageVolume.getVolumes())
		{
			if (volume.rootDirectory == root) found = volume;
		}

		Assert.notNull(found, root + " is not listed");
		if (found == null) return;

		Assert.isTrue(found.fileSystemType != null && found.fileSystemType.length > 0, root + " has no file system type");
		Assert.isTrue(FileSystem.exists(root), root + " is listed but cannot be read");

		#if !mac
		// The system volume is read only on macOS, where the user's files are on another
		Assert.isTrue(found.isWritable, root + " is not writable");
		#end
	}

	public function testTheVolumesAreReadOnABackgroundThread():Void
	{
		if (!canList()) return;

		// Listing from another thread, as the polling does where there are threads
		var count = StorageVolume.getVolumes().length;

		#if lime_threads
		var mutex = new sys.thread.Mutex();
		var result = -1;
		var lock = new sys.thread.Lock();

		sys.thread.Thread.create(function()
		{
			var volumes = StorageVolume.getVolumes();
			mutex.acquire();
			result = volumes.length;
			mutex.release();
			lock.release();
		});

		Assert.isTrue(lock.wait(10), "listing the volumes on a background thread did not finish");
		mutex.acquire();
		Assert.equals(count, result);
		mutex.release();
		#else
		Assert.isTrue(count > 0);
		#end
	}

	#if windows
	@:timeout(20000)
	public function testASubstDriveMountsAndUnmounts(async:Async):Void
	{
		if (!canList())
		{
			async.done();
			return;
		}

		if (Sys.getEnv("LIME_TEST_VOLUMES") != "1")
		{
			// utest takes a warning as a failure, so the test passes, saying why
			trace("LIME_TEST_VOLUMES is not 1, so no drive was mounted");
			Assert.pass();
			async.done();
			return;
		}

		substFolder = Path.join([temporaryFolder(), "lime-test-volume-" + Std.random(0x3FFFFFFF)]);
		FileSystem.createDirectory(substFolder);

		var mounted:StorageVolume = null;
		var unmounted:StorageVolume = null;
		var mountedOnMainThread = false;
		var unmountedOnMainThread = false;

		var onMount = function(volume:StorageVolume)
		{
			if (substDrive != null && volume.rootDirectory == substDrive + ":\\")
			{
				mounted = volume;
				mountedOnMainThread = lime.system.ThreadPool.isMainThread();
			}
		};

		var onUnmount = function(volume:StorageVolume)
		{
			if (substDrive != null && volume.rootDirectory == substDrive + ":\\")
			{
				unmounted = volume;
				unmountedOnMainThread = lime.system.ThreadPool.isMainThread();
			}
		};

		var finish = function()
		{
			StorageVolume.onMount.remove(onMount);
			StorageVolume.onUnmount.remove(onUnmount);
			removeSubst();
			async.done();
		};

		// Listening starts the polling, whose first list is what is mounted already
		StorageVolume.onMount.add(onMount);
		StorageVolume.onUnmount.add(onUnmount);

		haxe.Timer.delay(function()
		{
			if (!addSubst())
			{
				Assert.fail("no free drive letter could be mounted with subst");
				finish();
				return;
			}

			waitFor(function() return mounted != null, 6, function()
			{
				Assert.notNull(mounted, "onMount was not dispatched for " + substDrive + ":\\");

				if (mounted != null)
				{
					Assert.isTrue(mountedOnMainThread, "onMount was dispatched on another thread");
					Assert.equals(substDrive, mounted.drive);
					Assert.isFalse(mounted.isRemovable, "a subst drive is removable");
					Assert.isTrue(mounted.isWritable, "a subst drive is not writable");
				}

				var listed = false;
				for (volume in StorageVolume.getVolumes())
				{
					if (volume.rootDirectory == substDrive + ":\\") listed = true;
				}
				Assert.isTrue(listed, substDrive + ":\\ is mounted but not listed");

				subst([substDrive + ":", "/d"]);

				waitFor(function() return unmounted != null, 6, function()
				{
					Assert.notNull(unmounted, "onUnmount was not dispatched for " + substDrive + ":\\");

					if (unmounted != null)
					{
						Assert.isTrue(unmountedOnMainThread, "onUnmount was dispatched on another thread");
						// The volume as it was listed, as it can no longer be read
						Assert.equals(substDrive, unmounted.drive);
						Assert.equals(mounted != null ? mounted.name : unmounted.name, unmounted.name);
					}

					for (volume in StorageVolume.getVolumes())
					{
						Assert.isFalse(volume.rootDirectory == substDrive + ":\\", substDrive + ":\\ is still listed");
					}

					finish();
				});
			});
		}, 1500);
	}

	public function teardown():Void
	{
		removeSubst();
	}

	/**
		Mounts `substFolder` on the last free drive letter, and returns whether
		one was.
	**/
	private function addSubst():Bool
	{
		var used = new Map<String, Bool>();
		for (volume in StorageVolume.getVolumes()) used.set(volume.drive, true);

		// subst refuses a letter in use, as a disconnected network drive, so the next is tried
		var letter = "Z".code;

		while (letter >= "M".code)
		{
			var drive = String.fromCharCode(letter);
			letter--;
			if (used.exists(drive)) continue;

			if (subst([drive + ":", substFolder]) == 0)
			{
				substDrive = drive;
				return true;
			}
		}

		return false;
	}

	private function removeSubst():Void
	{
		if (substDrive != null)
		{
			subst([substDrive + ":", "/d"]);
			substDrive = null;
		}

		if (substFolder != null)
		{
			if (FileSystem.exists(substFolder)) FileSystem.deleteDirectory(substFolder);
			substFolder = null;
		}
	}

	/**
		Runs `subst`, and returns its exit code.
	**/
	private static function subst(arguments:Array<String>):Int
	{
		// subst does not take "/d" in quotes, as Process passes each argument, so this goes through the shell
		var command = "subst";
		for (argument in arguments)
		{
			command += " " + (argument.indexOf(" ") > -1 ? "\"" + argument + "\"" : argument);
		}

		var process = new sys.io.Process(command);
		var exitCode = process.exitCode();
		process.close();
		return exitCode;
	}

	/**
		Calls `done` once `condition` is true, or after `seconds`, checking
		between frames so events are still dispatched.
	**/
	private static function waitFor(condition:Void->Bool, seconds:Float, done:Void->Void):Void
	{
		var end = haxe.Timer.stamp() + seconds;
		var timer = new haxe.Timer(50);

		timer.run = function()
		{
			if (condition() || haxe.Timer.stamp() > end)
			{
				timer.stop();
				done();
			}
		};
	}

	private static function temporaryFolder():String
	{
		for (name in ["TEMP", "TMP"])
		{
			var value = Sys.getEnv(name);
			if (value != null && value != "") return value;
		}

		return "C:\\Windows\\Temp";
	}
	#end

	/**
		Whether the volumes can be listed, or else why not, passing the test.
	**/
	private static function canList():Bool
	{
		if (StorageVolume.isSupported) return true;

		#if (native_desktop < "1.2.0")
		// Listing the volumes needs a native-desktop with StorageVolumes
		trace("native-desktop " + haxe.macro.Compiler.getDefine("native-desktop") + " cannot list the volumes, so they were not tested");
		Assert.pass();
		return false;
		#else
		Assert.fail("the volumes cannot be listed");
		return false;
		#end
	}
	#else
	public function testNoVolumesAreListed():Void
	{
		// Web, Flash and mobile have no volumes to list
		Assert.isFalse(StorageVolume.isSupported);
		Assert.equals(0, StorageVolume.getVolumes().length);
	}
	#end
}
