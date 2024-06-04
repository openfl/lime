package lime.tools;

import hxp.HostArchitecture;

#if (haxe_ver >= 4.0) enum #else @:enum #end abstract Architecture(String) to String

{
	var ARMV5 = "ARMV5";
	var ARMV6 = "ARMV6";
	var ARMV7 = "ARMV7";
	var ARMV7S = "ARMV7S";
	var ARM64 = "ARM64";
	var X86 = "X86";
	var X64 = "X64";
	var MIPS = "MIPS";
	var MIPSEL = "MIPSEL";

	public static function exists(architecture:String):Bool
	{
		switch (architecture)
		{
			case ARMV5, ARMV6, ARMV7, ARMV7S, ARM64, X86, X64, MIPS, MIPSEL:
				return true;
			default:
				return false;
		}
	}

	@:from private static function fromHostArchitecture(hostArchitecture:HostArchitecture):Architecture
	{
		if (hostArchitecture == HostArchitecture.ARMV6)
		{
			return ARMV6;
		}
		else if (hostArchitecture == HostArchitecture.ARMV7)
		{
			return ARMV7;
		}
		else if (hostArchitecture == HostArchitecture.ARM64)
		{
			return ARM64;
		}
		else if (hostArchitecture == HostArchitecture.X86)
		{
			return X86;
		}
		else /* if (hostArchitecture == HostArchitecture.X64) */
		{
			return X64;
		}
	}

	@:from private static function fromString(string:String):Architecture
	{
		if (exists(string))
		{
			return cast string;
		}
		else
		{
			return null;
		}
	}

	public inline function is64():Bool
	{
		return this == ARM64 || this == X64;
	}

	public inline function isARM():Bool
	{
		return this.indexOf("ARM") == 0;
	}

	public inline function isMIPS():Bool
	{
		return this == MIPS || this == MIPSEL;
	}

	public inline function isX():Bool
	{
		return this == X86 || this == X64;
	}
}
