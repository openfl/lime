package net;

import lime.net.IPVersion;
import lime.net.InterfaceAddress;
import lime.net.NetworkInterface;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	`NetworkInterface.getInterfaces` and `onChange`.

	The interfaces are checked against what the system's own tools list. Where
	`LIME_TEST_NETWORK` is `1`, as on the Linux and macOS steps of CI, the
	network is changed for real with `sudo`, by adding a dummy interface on
	Linux and an address on the loopback interface on macOS, and both are
	removed again, also in `teardown`.
**/
@:access(lime.net.NetworkInterface)
class NetworkInterfaceTest extends Test
{
	#if (lime_cffi && !macro && (linux || mac))
	private var changed:Bool = false;
	#end

	public function new()
	{
		super();
	}

	public function testTheEventIsThereToListenTo():Void
	{
		Assert.notNull(NetworkInterface.onChange);

		var listener = function() {};
		NetworkInterface.onChange.add(listener);
		Assert.isTrue(NetworkInterface.onChange.has(listener));
		NetworkInterface.onChange.remove(listener);
		Assert.isFalse(NetworkInterface.onChange.has(listener));
	}

	public function testOnChangeIsDispatchedOnlyWhenTheListDiffers():Void
	{
		// The first list is how the network was, so only a list that differs from the last is a change
		var changes = 0;
		var listener = function() changes++;
		NetworkInterface.onChange.add(listener);

		NetworkInterface.__known = null;
		NetworkInterface.__compare("a");
		Assert.equals(0, changes, "the first list was taken for a change");
		NetworkInterface.__compare("a");
		Assert.equals(0, changes, "the same list was taken for a change");
		NetworkInterface.__compare(null);
		Assert.equals(0, changes, "a list that could not be read was taken for a change");
		NetworkInterface.__compare("b");
		Assert.equals(1, changes, "a list that differs was not taken for a change");
		NetworkInterface.__compare("b");
		Assert.equals(1, changes);

		NetworkInterface.onChange.remove(listener);
		// The next poll starts again from what is listed then
		NetworkInterface.__known = null;
	}

	#if (lime_cffi && !macro && (windows || mac || linux))
	public function testTheInterfacesCanBeListed():Void
	{
		Assert.isTrue(NetworkInterface.isSupported);

		var interfaces = NetworkInterface.getInterfaces();
		Assert.isTrue(interfaces.length > 0, "no interface is listed");

		var names = new Map<String, Bool>();

		for (networkInterface in interfaces)
		{
			var name = networkInterface.name;
			Assert.isTrue(name != null && name.length > 0, "an interface has no name");
			Assert.isFalse(names.exists(name), name + " is listed twice");
			names.set(name, true);

			Assert.isTrue(networkInterface.displayName != null && networkInterface.displayName.length > 0, name + " has no display name");
			#if !windows
			Assert.equals(name, networkInterface.displayName);
			#end
			Assert.isTrue(networkInterface.mtu == -1 || networkInterface.mtu > 0, name + " has an MTU of " + networkInterface.mtu);

			if (networkInterface.hardwareAddress != null)
			{
				Assert.isTrue(~/^[0-9A-F]{2}(-[0-9A-F]{2})+$/.match(networkInterface.hardwareAddress),
					"\"" + networkInterface.hardwareAddress + "\" of " + name + " is not a hardware address");
			}

			Assert.notNull(networkInterface.addresses);
			if (networkInterface.addresses == null) continue;

			for (address in networkInterface.addresses)
			{
				assertAddress(name, address);
			}
		}
	}

	public function testTheLoopbackIsListed():Void
	{
		var found = null;

		for (networkInterface in NetworkInterface.getInterfaces())
		{
			for (address in networkInterface.addresses)
			{
				if (address.address == "127.0.0.1")
				{
					found = networkInterface;
					Assert.equals(IPVersion.IPV4, address.ipVersion);
					Assert.equals(8, address.prefixLength);
				}
			}
		}

		Assert.notNull(found, "127.0.0.1 is not listed");
		if (found != null) Assert.isTrue(found.active, found.name + ", the loopback, is not active");
	}

	public function testTheInterfacesAreWhatTheSystemLists():Void
	{
		var interfaces = new Map<String, NetworkInterface>();
		for (networkInterface in NetworkInterface.getInterfaces()) interfaces.set(networkInterface.name, networkInterface);

		#if windows
		// Each adapter as GUID, name, hardware address and status, then each address as alias, address and prefix
		var output = powerShell("[Console]::OutputEncoding = [Text.Encoding]::UTF8\n"
			+ "Get-NetAdapter | ForEach-Object { 'A|' + $_.InterfaceGuid + '|' + $_.Name + '|' + $_.MacAddress + '|' + $_.Status }\n"
			+ "Get-NetIPAddress | ForEach-Object { 'I|' + $_.InterfaceAlias + '|' + $_.IPAddress + '|' + $_.PrefixLength }\n");
		Assert.notNull(output, "PowerShell could not list the adapters");
		if (output == null) return;

		var byDisplayName = new Map<String, NetworkInterface>();
		for (networkInterface in interfaces) byDisplayName.set(networkInterface.displayName, networkInterface);

		var adapters = 0;
		var addresses = 0;

		for (line in output.split("\n"))
		{
			var fields = StringTools.trim(line).split("|");

			if (fields[0] == "A" && fields.length == 5)
			{
				// An adapter without TCP/IP is not listed, so only those that are are compared
				var networkInterface = null;
				for (candidate in interfaces)
				{
					if (candidate.name.toUpperCase() == fields[1].toUpperCase()) networkInterface = candidate;
				}
				if (networkInterface == null) continue;

				adapters++;
				Assert.equals(fields[2], networkInterface.displayName);
				Assert.equals(fields[3] != "" ? fields[3] : null, networkInterface.hardwareAddress, fields[2] + "'s hardware address");
				Assert.equals(fields[4] == "Up", networkInterface.active, fields[2] + " is " + fields[4]);
			}
			else if (fields[0] == "I" && fields.length == 4)
			{
				// Link-local IPv6 addresses carry their zone, as %12, which the address itself does not
				var text = fields[2].split("%")[0];
				var networkInterface = byDisplayName.get(fields[1]);
				Assert.notNull(networkInterface, fields[1] + ", which has " + text + ", is not listed");
				if (networkInterface == null) continue;

				addresses++;
				var address = findAddress(networkInterface, text);
				Assert.notNull(address, text + " is not listed on " + fields[1]);
				if (address != null) Assert.equals(Std.parseInt(fields[3]), address.prefixLength, text + "'s prefix length");
			}
		}

		Assert.isTrue(adapters > 0, "no adapter Get-NetAdapter lists is listed");
		Assert.isTrue(addresses > 0, "Get-NetIPAddress listed no address");
		#elseif linux
		// Each interface has a folder here, with its MTU and hardware address
		var folder = "/sys/class/net";
		for (name in sys.FileSystem.readDirectory(folder))
		{
			// bonding_masters, where there is one, is a file and not an interface
			if (!sys.FileSystem.isDirectory(folder + "/" + name)) continue;

			var networkInterface = interfaces.get(name);
			Assert.notNull(networkInterface, name + " is not listed");
			if (networkInterface == null) continue;

			Assert.equals(Std.parseInt(StringTools.trim(readSysFile(folder + "/" + name + "/mtu"))), networkInterface.mtu, name + "'s MTU");

			var hardwareAddress = try StringTools.trim(readSysFile(folder + "/" + name + "/address")) catch (_:Dynamic) "";
			if (hardwareAddress != "" && ~/[1-9a-f]/.match(hardwareAddress))
			{
				Assert.equals(hardwareAddress.toUpperCase().split(":").join("-"), networkInterface.hardwareAddress, name + "'s hardware address");
			}
			else
			{
				Assert.isNull(networkInterface.hardwareAddress, name + " has no hardware address");
			}
		}

		// Each address, as "2: eth0    inet 10.1.0.4/16 brd 10.1.255.255 scope global eth0"
		var output = run(find(["/usr/sbin/ip", "/sbin/ip", "/usr/bin/ip", "/bin/ip"]), ["-o", "addr", "show"]);
		if (output == null)
		{
			trace("ip could not be run, so the addresses were not compared");
			return;
		}

		var addresses = 0;
		var pattern = ~/^\d+:\s+(\S+)\s+inet6?\s+([0-9a-fA-F.:]+)\/(\d+)/;

		for (line in output.split("\n"))
		{
			if (!pattern.match(line)) continue;

			var name = pattern.matched(1).split("@")[0];
			var text = pattern.matched(2);
			var networkInterface = interfaces.get(name);
			Assert.notNull(networkInterface, name + ", which has " + text + ", is not listed");
			if (networkInterface == null) continue;

			addresses++;
			var address = findAddress(networkInterface, text);
			Assert.notNull(address, text + " is not listed on " + name);
			if (address != null) Assert.equals(Std.parseInt(pattern.matched(3)), address.prefixLength, text + "'s prefix length");
		}

		Assert.isTrue(addresses > 0, "ip listed no address");
		#elseif mac
		var output = run(find(["/sbin/ifconfig", "/usr/sbin/ifconfig"]), ["-l"]);
		Assert.notNull(output, "ifconfig could not be run");
		if (output == null) return;

		for (name in StringTools.trim(output).split(" "))
		{
			if (name != "") Assert.isTrue(interfaces.exists(name), name + " is not listed");
		}
		#end
	}

	@:timeout(10000)
	public function testOnChangeIsNotDispatchedWhileTheNetworkStaysTheSame(async:Async):Void
	{
		// The first poll reads how the network is, which is not a change
		var changes = 0;
		var listener = function() changes++;
		NetworkInterface.onChange.add(listener);

		haxe.Timer.delay(function()
		{
			NetworkInterface.onChange.remove(listener);
			Assert.equals(0, changes, "onChange was dispatched with nothing changing");
			async.done();
		}, 2500);
	}

	@:timeout(10000)
	public function testThePollingDispatchesOnChangeOnTheMainThread(async:Async):Void
	{
		// A list that is not the network's stands in for a change, as the next poll differs from it
		var changes = 0;
		var onMainThread = true;
		var listener = function()
		{
			changes++;
			if (!lime.system.ThreadPool.isMainThread()) onMainThread = false;
		};

		NetworkInterface.onChange.add(listener);
		NetworkInterface.__known = "stale";

		haxe.Timer.delay(function()
		{
			NetworkInterface.onChange.remove(listener);
			Assert.equals(1, changes, "the polling did not dispatch onChange once for a list that differs");
			Assert.isTrue(onMainThread, "onChange was dispatched on another thread");
			async.done();
		}, 3500);
	}

	#if (linux || mac)
	@:timeout(30000)
	public function testOnChangeIsDispatchedWhenTheNetworkChanges(async:Async):Void
	{
		if (Sys.getEnv("LIME_TEST_NETWORK") != "1")
		{
			// utest takes a warning as a failure, so the test passes, saying why
			trace("LIME_TEST_NETWORK is not 1, so the network was not changed");
			Assert.pass();
			async.done();
			return;
		}

		var changes = 0;
		var onMainThread = true;
		var listener = function()
		{
			changes++;
			if (!lime.system.ThreadPool.isMainThread()) onMainThread = false;
		};

		var finish = function()
		{
			NetworkInterface.onChange.remove(listener);
			undoChange();
			async.done();
		};

		// Listening starts the polling, whose first list is how the network is now
		NetworkInterface.onChange.add(listener);

		haxe.Timer.delay(function()
		{
			var exitCode = makeChange();
			changed = true;
			Assert.equals(0, exitCode, "the network could not be changed");
			if (exitCode != 0)
			{
				finish();
				return;
			}

			waitFor(function() return changes > 0, 6, function()
			{
				Assert.isTrue(changes > 0, "onChange was not dispatched when " + CHANGE + " was added");
				Assert.isTrue(onMainThread, "onChange was dispatched on another thread");
				assertChange(true);

				changes = 0;
				Assert.equals(0, undoChange(), CHANGE + " could not be removed");

				waitFor(function() return changes > 0, 6, function()
				{
					Assert.isTrue(changes > 0, "onChange was not dispatched when " + CHANGE + " was removed");
					assertChange(false);
					finish();
				});
			});
		}, 1500);
	}

	public function teardown():Void
	{
		if (changed) undoChange();
	}

	#if linux
	private static inline var CHANGE:String = "limetest0";

	private static function makeChange():Int
	{
		return exitCodeOf(find(["/usr/bin/sudo", "/bin/sudo"]), ["-n", find(["/usr/sbin/ip", "/sbin/ip", "/usr/bin/ip", "/bin/ip"]), "link", "add", CHANGE, "type", "dummy"]);
	}

	private function undoChange():Int
	{
		changed = false;
		return exitCodeOf(find(["/usr/bin/sudo", "/bin/sudo"]), ["-n", find(["/usr/sbin/ip", "/sbin/ip", "/usr/bin/ip", "/bin/ip"]), "link", "delete", CHANGE]);
	}

	private static function assertChange(made:Bool):Void
	{
		var found = null;
		for (networkInterface in NetworkInterface.getInterfaces())
		{
			if (networkInterface.name == CHANGE) found = networkInterface;
		}

		if (!made)
		{
			Assert.isNull(found, CHANGE + " is still listed");
			return;
		}

		Assert.notNull(found, CHANGE + " is not listed");
		if (found == null) return;

		// A new dummy interface is down, with a random hardware address
		Assert.isFalse(found.active, CHANGE + " is active before it was brought up");
		Assert.notNull(found.hardwareAddress, CHANGE + " has no hardware address");
		Assert.isTrue(found.mtu > 0, CHANGE + " has an MTU of " + found.mtu);
	}
	#else
	private static inline var CHANGE:String = "127.0.0.2";

	private static function makeChange():Int
	{
		return exitCodeOf("/usr/bin/sudo", ["-n", find(["/sbin/ifconfig", "/usr/sbin/ifconfig"]), "lo0", "alias", CHANGE, "netmask", "255.0.0.0", "up"]);
	}

	private function undoChange():Int
	{
		changed = false;
		return exitCodeOf("/usr/bin/sudo", ["-n", find(["/sbin/ifconfig", "/usr/sbin/ifconfig"]), "lo0", "-alias", CHANGE]);
	}

	private static function assertChange(made:Bool):Void
	{
		var found = null;
		for (networkInterface in NetworkInterface.getInterfaces())
		{
			if (networkInterface.name == "lo0") found = networkInterface;
		}

		Assert.notNull(found, "lo0 is not listed");
		if (found == null) return;

		var address = findAddress(found, CHANGE);

		if (made)
		{
			Assert.notNull(address, CHANGE + " is not listed on lo0");
			if (address != null)
			{
				Assert.equals(IPVersion.IPV4, address.ipVersion);
				Assert.equals(8, address.prefixLength);
			}
		}
		else
		{
			Assert.isNull(address, CHANGE + " is still listed on lo0");
		}
	}
	#end

	private static function exitCodeOf(executable:String, arguments:Array<String>):Int
	{
		var process = new sys.io.Process(executable, arguments);
		var output = process.stdout.readAll().toString() + process.stderr.readAll().toString();
		var exitCode = process.exitCode();
		process.close();
		if (exitCode != 0) trace(executable + " " + arguments.join(" ") + ": " + StringTools.trim(output));
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
	#end

	private static function assertAddress(name:String, address:InterfaceAddress):Void
	{
		var text = address.address;
		Assert.notNull(text, name + " has an address without its text");
		if (text == null) return;

		if (address.ipVersion == IPVersion.IPV4)
		{
			Assert.isTrue(~/^\d{1,3}(\.\d{1,3}){3}$/.match(text), text + " on " + name + " is not an IPv4 address");
			Assert.isTrue(address.prefixLength >= 0 && address.prefixLength <= 32, text + " has a prefix length of " + address.prefixLength);

			if (address.broadcast != null)
			{
				// The address with every bit past the prefix set
				Assert.equals(broadcastOf(text, address.prefixLength), address.broadcast, text + "/" + address.prefixLength + "'s broadcast address");
			}
		}
		else
		{
			Assert.equals(IPVersion.IPV6, address.ipVersion, text + " on " + name + " is neither IPv4 nor IPv6");
			Assert.isTrue(text.indexOf(":") > -1 && ~/^[0-9a-f:.]+$/.match(text), text + " on " + name + " is not an IPv6 address");
			Assert.isTrue(address.prefixLength >= 0 && address.prefixLength <= 128, text + " has a prefix length of " + address.prefixLength);
			Assert.isNull(address.broadcast, text + ", an IPv6 address, has a broadcast address");
		}
	}

	private static function broadcastOf(address:String, prefixLength:Int):String
	{
		var octets = address.split(".");
		var result = [];

		for (i in 0...4)
		{
			var bits = prefixLength - i * 8;
			if (bits < 0) bits = 0;
			if (bits > 8) bits = 8;
			var mask = (0xFF << (8 - bits)) & 0xFF;
			result.push(Std.string((Std.parseInt(octets[i]) | (~mask & 0xFF)) & 0xFF));
		}

		return result.join(".");
	}

	private static function findAddress(networkInterface:NetworkInterface, text:String):InterfaceAddress
	{
		for (address in networkInterface.addresses)
		{
			if (address.address == text) return address;
		}

		return null;
	}

	#if !windows
	/**
		Reads a sysfs file. File.getContent() takes the size from stat(), which
		is the page size for these files, and Neko fails when fewer bytes come.
	**/
	private static function readSysFile(path:String):String
	{
		var input = sys.io.File.read(path, false);
		var text = input.readAll().toString();
		input.close();
		return text;
	}

	private static function find(paths:Array<String>):String
	{
		for (path in paths)
		{
			if (sys.FileSystem.exists(path)) return path;
		}

		return paths[0];
	}

	/**
		Runs a tool, and returns what it printed, or `null` when it could not
		be run.
	**/
	private static function run(executable:String, arguments:Array<String>):String
	{
		try
		{
			var process = new sys.io.Process(executable, arguments);
			var output = process.stdout.readAll().toString();
			var exitCode = process.exitCode();
			process.close();
			return exitCode == 0 ? output : null;
		}
		catch (_:Dynamic)
		{
			return null;
		}
	}
	#else
	/**
		Runs a PowerShell script, and returns what it printed, or `null` when it
		failed.
	**/
	private static function powerShell(script:String):String
	{
		// An encoded command is UTF-16, and needs no quoting
		var utf16 = haxe.io.Bytes.alloc(script.length * 2);
		for (i in 0...script.length)
		{
			utf16.setUInt16(i * 2, StringTools.fastCodeAt(script, i));
		}

		// HashLink starts a process by its path, without looking through PATH
		var root = Sys.getEnv("SystemRoot");
		var path = root != null ? root + "\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" : null;
		var executable = path != null && sys.FileSystem.exists(path) ? path : "powershell";

		var process = new sys.io.Process(executable, ["-NoProfile", "-NonInteractive", "-EncodedCommand", haxe.crypto.Base64.encode(utf16)]);
		var output = process.stdout.readAll().toString();
		var exitCode = process.exitCode();
		process.close();
		return exitCode == 0 ? output : null;
	}
	#end
	#else
	public function testNoInterfacesAreListed():Void
	{
		// Web and Flash cannot list the interfaces
		Assert.isFalse(NetworkInterface.isSupported);
		Assert.equals(0, NetworkInterface.getInterfaces().length);
	}

	#if (js && html5)
	public function testOnChangeIsDispatchedWhenTheBrowserGoesOnlineOrOffline():Void
	{
		var changes = 0;
		var listener = function() changes++;
		NetworkInterface.onChange.add(listener);

		js.Browser.window.dispatchEvent(new js.html.Event("offline"));
		Assert.equals(1, changes, "onChange was not dispatched when the browser went offline");
		js.Browser.window.dispatchEvent(new js.html.Event("online"));
		Assert.equals(2, changes, "onChange was not dispatched when the browser went online");

		NetworkInterface.onChange.remove(listener);
	}
	#end
	#end
}
