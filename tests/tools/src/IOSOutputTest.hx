import haxe.PosInfos;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import hxp.Path;
import lime.tools.IOSHelper;
import sys.io.File;
import utest.Assert;
import utest.Test;

/**
	What `lime update ios` writes from templates/ios: the application's Info.plist and the
	Xcode project. The plist is read as strict XML, as Xcode reads it.
**/
class IOSOutputTest extends Test
{
	private static inline var INFO_PLIST = "MyApplication/MyApplication-Info.plist";
	private static inline var PRIVACY_MANIFEST = "MyApplication/PrivacyInfo.xcprivacy";
	private static inline var XCODE_PROJECT = "MyApplication.xcodeproj/project.pbxproj";
	private static inline var ENTITLEMENTS = "MyApplication/MyApplication.entitlements";

	private var fixture:Fixture;
	private var output:PlatformFixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
		fixture.target = IOS;
		fixture.write("Main.hx", "class Main {}");

		output = new PlatformFixture(fixture);
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	// Core Animation only runs above 60 Hz on a ProMotion iPhone with this key, which iPads don't
	// need. Without a window asking for more than 60 frames a second, the display link is left
	// at 60, so an application at 60 isn't woken for frames it skips.
	public function testAWindowAbove60FramesASecondCanUseProMotionOnIPhone():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		Assert.isFalse(infoPlist().exists("CADisableMinimumFrameDurationOnPhone"));

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<window fps="120" />
		</project>');

		Assert.equals(true, infoPlist().get("CADisableMinimumFrameDurationOnPhone"));
	}

	// <config:ios high-frame-rate="..." /> decides for an application that changes its frame rate as it runs
	public function testHighFrameRateCanBeAskedForOrLeftOut():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:ios high-frame-rate="true" />
		</project>');

		Assert.equals(true, infoPlist().get("CADisableMinimumFrameDurationOnPhone"));

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<window fps="120" />
			<config:ios high-frame-rate="false" />
		</project>');

		Assert.isFalse(infoPlist().exists("CADisableMinimumFrameDurationOnPhone"));
	}

	// App Store Connect refuses apps whose privacy manifest doesn't give a reason for each
	// required reason API they call. Lime's frame clock reads the system boot time, and
	// hxcpp's sys.FileSystem reads file timestamps.
	// The arm64 simulator is a platform of its own, so its libraries are kept apart from those of
	// arm64 devices, and the Xcode project finds them for simulator builds alone
	public function testArm64SimulatorLibrariesAreKeptApartFromArm64Devices():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		var project = output.read("MyApplication.xcodeproj/project.pbxproj");
		Assert.isTrue(project.indexOf('"LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*][arch=arm64]"') > -1);
		// Devices name their SDK too, or the simulator's setting would inherit their folder first
		Assert.isTrue(project.indexOf('"LIBRARY_SEARCH_PATHS[sdk=iphoneos*][arch=arm64]"') > -1);
		Assert.equals(-1, project.indexOf('"LIBRARY_SEARCH_PATHS[arch=arm64]"'));
		Assert.isTrue(project.indexOf('/MyApplication/lib/arm64-simulator') > -1);
		Assert.isTrue(project.indexOf('/MyApplication/lib/arm64-simulator-debug') > -1);

		var makefile = output.read("MyApplication/haxe/makefile");
		Assert.isTrue(makefile.indexOf("HXCPP_FLAGS_arm64 = -D simulator -D HXCPP_ARM64") > -1);
		Assert.isTrue(makefile.indexOf("LIBDIR_arm64 = arm64-simulator") > -1);
		Assert.isTrue(makefile.indexOf("../lib/$(LIBDIR_$*)$(LIB_DEST)") > -1);
	}

	// libhxcpp builds for the arm64 simulator, which hxcpp up to 4.3 does not
	public function testArm64SimulatorBuildsNeedAnHxcppThatMakesThem():Void
	{
		fixture.addHaxelib("toolstest-newhxcpp", "<project />", [
			"toolchain/finish-setup.xml" => '<xml><set name="LIBEXTRA" value=".iphonesim-arm64" if="HXCPP_ARM64"/></xml>'
		]);
		fixture.addHaxelib("toolstest-oldhxcpp", "<project />", [
			"toolchain/finish-setup.xml" => '<xml><set name="LIBEXTRA" value=".iphonesim-64" if="iphonesim"/></xml>'
		]);

		Assert.isTrue(lime.tools.IOSHelper.buildsArm64Simulator("toolstest-newhxcpp"));
		Assert.isFalse(lime.tools.IOSHelper.buildsArm64Simulator("toolstest-oldhxcpp"));
	}

	public function testX86_64CanBeAskedForInsteadOfTheArm64Simulator():Void
	{
		var project = fixture.parse('<project>
			<app main="Main" file="MyApplication" />
		</project>');
		project.targetFlags.set("simulator", "");
		project.targetFlags.set("x86_64", "");

		Assert.isFalse(lime.tools.IOSHelper.useArm64Simulator(project));
	}

	public function testThePrivacyManifestDeclaresTheAPIsLimeUses():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		var types = accessedAPITypes();
		Fixture.assertSame(["35F9.1"], types.get("NSPrivacyAccessedAPICategorySystemBootTime"));
		Fixture.assertSame(["C617.1"], types.get("NSPrivacyAccessedAPICategoryFileTimestamp"));

		var manifest = Plist.parse(output.read(PRIVACY_MANIFEST));
		Assert.equals(false, manifest.get("NSPrivacyTracking"));

		// It is copied into the application, as the Xcode project's resources
		var project = output.read("MyApplication.xcodeproj/project.pbxproj");
		var phase = project.substring(project.indexOf("/* Begin PBXResourcesBuildPhase section */"), project.indexOf("/* End PBXResourcesBuildPhase section */"));
		Assert.isTrue(phase.indexOf("PrivacyInfo.xcprivacy in Resources") > -1, "the privacy manifest is not among the application's resources");
		Assert.isTrue(project.indexOf('path = "MyApplication/PrivacyInfo.xcprivacy"') > -1);
	}

	// <config:ios privacy-accessed-api="NSPrivacyAccessedAPICategoryUserDefaults CA92.1" />
	public function testAnApplicationCanDeclareAPIsOfItsOwn():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:ios privacy-accessed-api="NSPrivacyAccessedAPICategoryUserDefaults CA92.1" />
			<config:ios privacy-accessed-api="NSPrivacyAccessedAPICategoryFileTimestamp 3B52.1" />
		</project>');

		var types = accessedAPITypes();
		Fixture.assertSame(["CA92.1"], types.get("NSPrivacyAccessedAPICategoryUserDefaults"));
		Fixture.assertSame(["C617.1", "3B52.1"], types.get("NSPrivacyAccessedAPICategoryFileTimestamp"));
		Fixture.assertSame(["35F9.1"], types.get("NSPrivacyAccessedAPICategorySystemBootTime"));
	}

	// libhxcpp's TLS checks a server's certificate with the system's trust store on iOS and tvOS,
	// and a static build there leaves Security.framework to the app's link. hxcpp 4.3 and hxcpp's
	// master branch link it on macOS alone. Each fixture is that hxcpp's own src/hx/libs/ssl/Build.xml:
	// hxcpp 4.3.2, hxcpp's master at f5142e8a0, libhxcpp 6.0.0, and HaxeFoundation/hxcpp#1331 at e1e81adbf.
	public function testEachHxcppsTLSBuildFileSaysWhetherAnAppLinksSecurity():Void
	{
		Assert.isFalse(IOSHelper.sslBuildLinksSecurity(sslBuild("hxcpp-4.3.2")), "hxcpp 4.3.2");
		Assert.isFalse(IOSHelper.sslBuildLinksSecurity(sslBuild("hxcpp-master")), "hxcpp's master branch");
		Assert.isTrue(IOSHelper.sslBuildLinksSecurity(sslBuild("libhxcpp-6.0.0")), "libhxcpp 6.0.0");
		Assert.isTrue(IOSHelper.sslBuildLinksSecurity(sslBuild("hxcpp-pr1331")), "HaxeFoundation/hxcpp#1331");
	}

	public function testOnlyASecurityFlagThatIsNotForMacOSAloneCounts():Void
	{
		// A build file that doesn't parse says nothing, even with a Security flag in it
		Assert.isFalse(IOSHelper.sslBuildLinksSecurity('<xml><target id="haxe"><flag value="Security"/></xml>'), "a target left open");
		Assert.isFalse(IOSHelper.sslBuildLinksSecurity('<xml><target id="haxe"><flag value="Security"'), "a file that stops in a tag");

		Assert.isFalse(IOSHelper.sslBuildLinksSecurity('<xml><target id="haxe"><flag value="Security" if="mac"/></target></xml>'), "if=\"mac\"");
		Assert.isFalse(IOSHelper.sslBuildLinksSecurity('<xml><target id="haxe"><section if="macos"><flag value="-framework"/><flag value="Security"/></section></target></xml>'),
			"a flag in a section for macOS");

		Assert.isTrue(IOSHelper.sslBuildLinksSecurity('<xml><target id="haxe"><flag value="-framework"/><flag value="Security"/></target></xml>'), "a flag for every platform");
	}

	// <config:cpp buildLibrary="..." /> names the hxcpp an application is built with
	public function testAnAppBuiltWithAnHxcppThatAsksForSecurityLinksIt():Void
	{
		addHxcpp("toolstest-libhxcpp", "libhxcpp-6.0.0");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:cpp buildLibrary="toolstest-libhxcpp" />
		</project>');

		assertLinksSecurityOnce(output.read(XCODE_PROJECT));
	}

	// Without one, it is the hxcpp haxelib, which libhxcpp's setup points at libhxcpp
	public function testTheHxcppHaxelibIsTheHxcppByDefault():Void
	{
		addHxcpp("hxcpp", "libhxcpp-6.0.0");

		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		assertLinksSecurityOnce(output.read(XCODE_PROJECT));
	}

	public function testAnAppBuiltWithHxcpp43DoesNotLinkSecurity():Void
	{
		addHxcpp("toolstest-hxcpp43", "hxcpp-4.3.2");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:cpp buildLibrary="toolstest-hxcpp43" />
		</project>');

		Assert.equals(-1, output.read(XCODE_PROJECT).indexOf("Security"), "the Xcode project names Security");
	}

	public function testSecurityAProjectAlreadyListsIsLinkedOnce():Void
	{
		addHxcpp("toolstest-libhxcpp", "libhxcpp-6.0.0");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:cpp buildLibrary="toolstest-libhxcpp" />
			<dependency name="Security.framework" />
		</project>');

		assertLinksSecurityOnce(output.read(XCODE_PROJECT));
	}

	// The provisioning profile gives get-task-allow, true for development and false for
	// distribution, and an entitlement of the application's own that set it true kept a build
	// from being signed for distribution (#1335)
	public function testTheEntitlementsLeaveGetTaskAllowToTheProvisioningProfile():Void
	{
		for (build in ["release", "debug", "final"])
		{
			fixture.debug = build == "debug";
			if (build == "final") fixture.targetFlags.set("final", "") else fixture.targetFlags.remove("final");

			output.update('<project>
				<app main="Main" file="MyApplication" />
			</project>');

			var entitlements = Plist.parse(output.read(ENTITLEMENTS));
			Assert.isFalse(entitlements.exists("get-task-allow"), "get-task-allow in the entitlements of a " + build + " build");

			// The application's build configurations sign with them still
			Fixture.assertSame(["Debug: " + ENTITLEMENTS, "Release: " + ENTITLEMENTS], signingEntitlements(output.read(XCODE_PROJECT)));
		}
	}

	/**
		Each build configuration of an Xcode project that signs with an entitlements file, as
		"Debug: MyApplication/MyApplication.entitlements", sorted.
	**/
	private static function signingEntitlements(project:String):Array<String>
	{
		var start = project.indexOf("/* Begin XCBuildConfiguration section */");
		var end = project.indexOf("/* End XCBuildConfiguration section */");
		if (start == -1 || end < start) return [];

		var found = [];
		var entitlements = ~/CODE_SIGN_ENTITLEMENTS = "?([^";]*)"?;/;
		var name = ~/\bname = "?([^";]*)"?;/;

		for (configuration in project.substring(start, end).split("isa = XCBuildConfiguration;").slice(1))
		{
			if (entitlements.match(configuration))
			{
				var path = entitlements.matched(1);
				found.push((name.match(configuration) ? name.matched(1) : "?") + ": " + path);
			}
		}

		found.sort(Reflect.compare);
		return found;
	}

	private function accessedAPITypes():Map<String, Array<String>>
	{
		var types = new Map<String, Array<String>>();
		var manifest = Plist.parse(output.read(PRIVACY_MANIFEST));
		var entries:Array<Dynamic> = manifest.get("NSPrivacyAccessedAPITypes");

		for (entry in entries)
		{
			var dict:Map<String, Dynamic> = entry;
			var reasons:Array<Dynamic> = dict.get("NSPrivacyAccessedAPITypeReasons");
			Assert.isFalse(types.exists(dict.get("NSPrivacyAccessedAPIType")), dict.get("NSPrivacyAccessedAPIType") + " is listed twice");
			types.set(dict.get("NSPrivacyAccessedAPIType"), [for (reason in reasons) (reason : String)]);
		}

		return types;
	}

	private function infoPlist():Map<String, Dynamic>
	{
		return Plist.parse(output.read(INFO_PLIST));
	}

	/**
		Adds a haxelib named `name` that stands for an hxcpp, with the TLS build file in
		tests/tools/fixtures/hxcpp-ssl named `sslBuildFixture`.
	**/
	// A framework of the project's own that asks to be embedded is copied into the app, where it is
	// found at run time, when it is dynamic (#1944). A static one is linked into the app instead.
	public function testADynamicFrameworkThatAsksToBeEmbeddedIsCopiedIntoTheApp():Void
	{
		writeBinary("Frameworks/Dynamic.framework/Dynamic", machO(6));
		writeBinary("Frameworks/Universal.framework/Universal", universal(machO(6)));
		writeBinary("Frameworks/Shared.xcframework/ios-arm64/Shared.framework/Shared", machO(6));
		writeBinary("Frameworks/Static.framework/Static", archive());
		writeBinary("Frameworks/Unasked.framework/Unasked", machO(6));

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<dependency path="Frameworks/Dynamic.framework" embed="true" />
			<dependency path="Frameworks/Universal.framework" embed="true" />
			<dependency path="Frameworks/Shared.xcframework" embed="true" />
			<dependency path="Frameworks/Static.framework" embed="true" />
			<dependency path="Frameworks/Unasked.framework" />
		</project>');

		var xcode = output.read(XCODE_PROJECT);
		var phase = section(xcode, "PBXCopyFilesBuildPhase");

		Assert.isTrue(phase.indexOf("name = \"Embed Frameworks\";") > -1, "there is no Embed Frameworks phase");
		Assert.isTrue(phase.indexOf("dstSubfolderSpec = 10;") > -1, "the phase doesn't copy into the app's Frameworks folder");
		Assert.equals(1, count(xcode, "isa = PBXCopyFilesBuildPhase;"));

		for (name in ["Dynamic.framework", "Universal.framework", "Shared.xcframework"])
		{
			Assert.isTrue(phase.indexOf(name + " in Embed Frameworks") > -1, name + " is not embedded");
			Assert.isTrue(lineWith(xcode, name + " in Embed Frameworks */ = {isa = PBXBuildFile;").indexOf("CodeSignOnCopy") > -1, name + " is not signed as it is copied");
		}

		for (name in ["Static.framework", "Unasked.framework"])
		{
			Assert.equals(-1, xcode.indexOf(name + " in Embed Frameworks"), name + " is embedded");
			Assert.isTrue(xcode.indexOf(name + " in Frameworks") > -1, name + " is not linked");
		}

		var buildPhases = xcode.substring(xcode.indexOf("buildPhases = ("), xcode.indexOf("buildRules = ("));
		Assert.isTrue(buildPhases.indexOf("/* Embed Frameworks */,") > -1, "the phase isn't one of the application's build phases");
		// The debug and release configurations each look for frameworks in the app
		Assert.equals(2, count(xcode, "\"@executable_path/Frameworks\""));
	}

	public function testWithNothingToEmbedTheProjectIsLeftAsItWas():Void
	{
		writeBinary("Frameworks/Static.framework/Static", archive());

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<dependency path="Frameworks/Static.framework" embed="true" />
		</project>');

		var xcode = output.read(XCODE_PROJECT);
		Assert.equals(-1, xcode.indexOf("PBXCopyFilesBuildPhase"));
		Assert.equals(-1, xcode.indexOf("LD_RUNPATH_SEARCH_PATHS"));
		Assert.equals(-1, xcode.indexOf("Embed Frameworks"));
	}

	private function addHxcpp(name:String, sslBuildFixture:String):Void
	{
		fixture.addHaxelib(name, "<project />", ["src/hx/libs/ssl/Build.xml" => sslBuild(sslBuildFixture)]);
	}

	/**
		Security.framework once in each place an Xcode project names a framework the app links:
		a build file, a file reference to the SDK's framework, the frameworks build phase and the
		Frameworks group, tied together by the build file's and the file reference's IDs.
	**/
	private function assertLinksSecurityOnce(project:String, ?pos:PosInfos):Void
	{
		var buildFiles = section(project, "PBXBuildFile");
		Assert.equals(1, count(buildFiles, "/* Security.framework in Frameworks */ = {isa = PBXBuildFile;"), "build files for Security.framework", pos);

		var buildFile = ~/([0-9A-Za-z]+) \/\* Security\.framework in Frameworks \*\/ = \{isa = PBXBuildFile; fileRef = ([0-9A-Za-z]+) \/\* Security\.framework \*\/; \};/;
		if (!Assert.isTrue(buildFile.match(buildFiles), "no build file for Security.framework", pos)) return;

		var buildFileID = buildFile.matched(1);
		var fileReferenceID = buildFile.matched(2);

		var fileReferences = section(project, "PBXFileReference");
		Assert.equals(1, count(fileReferences, "/* Security.framework */ = {isa = PBXFileReference;"), "file references to Security.framework", pos);

		var fileReference = lineWith(fileReferences, fileReferenceID + " /* Security.framework */ = {isa = PBXFileReference;");
		Assert.notNull(fileReference, "the build file's reference is not among the file references", pos);

		if (fileReference != null)
		{
			Assert.isTrue(fileReference.indexOf('lastKnownFileType = "wrapper.framework";') > -1, fileReference, pos);
			Assert.isTrue(fileReference.indexOf('path = "/System/Library/Frameworks/Security.framework";') > -1, fileReference, pos);
			Assert.isTrue(fileReference.indexOf("sourceTree = SDKROOT;") > -1, fileReference, pos);
		}

		var buildPhase = section(project, "PBXFrameworksBuildPhase");
		Assert.equals(1, count(buildPhase, "/* Security.framework in Frameworks */"), "Security.framework in the frameworks build phase", pos);
		Assert.isTrue(buildPhase.indexOf(buildFileID + " /* Security.framework in Frameworks */,") > -1, "the frameworks build phase does not list the build file", pos);

		var group = frameworksGroup(project);
		Assert.equals(1, count(group, "/* Security.framework */"), "Security.framework in the Frameworks group", pos);
		Assert.isTrue(group.indexOf(fileReferenceID + " /* Security.framework */,") > -1, "the Frameworks group does not list the file reference", pos);
	}

	private static function count(text:String, part:String):Int
	{
		return text.split(part).length - 1;
	}

	/**
		The group of an Xcode project that its linked frameworks are shown in.
	**/
	private static function frameworksGroup(project:String):String
	{
		var groups = section(project, "PBXGroup");
		var start = groups.indexOf("/* Frameworks */ = {");
		if (start == -1) return "";

		var end = groups.indexOf("};", start);
		return groups.substring(start, end == -1 ? groups.length : end);
	}

	private static function lineWith(text:String, part:String):String
	{
		for (line in ~/\r?\n/g.split(text))
		{
			if (line.indexOf(part) > -1) return line;
		}

		return null;
	}

	/**
		A section of an Xcode project, such as "PBXBuildFile", or "" when it has none.
	**/
	private static function section(project:String, name:String):String
	{
		var start = project.indexOf("/* Begin " + name + " section */");
		var end = project.indexOf("/* End " + name + " section */");
		return (start > -1 && end > start) ? project.substring(start, end) : "";
	}

	private static function sslBuild(name:String):String
	{
		return File.getContent(Path.combine(LimeRepo.path(), "tests/tools/fixtures/hxcpp-ssl/" + name + ".xml"));
	}

	private function writeBinary(file:String, bytes:Bytes):Void
	{
		File.saveBytes(fixture.write(file, ""), bytes);
	}

	// The 64-bit Mach-O header of an arm64 binary of the given file type, where 6 is a dynamic library
	private static function machO(fileType:Int):Bytes
	{
		var output = new BytesOutput();
		output.bigEndian = false;
		for (value in [0xFEEDFACF, 0x0100000C, 0, fileType, 0, 0, 0, 0])
		{
			output.writeInt32(value);
		}
		return output.getBytes();
	}

	// A universal binary holding one architecture, at an offset of 4096 bytes
	private static function universal(slice:Bytes):Bytes
	{
		var output = new BytesOutput();
		output.bigEndian = true;
		for (value in [0xCAFEBABE, 1, 0x0100000C, 0, 4096, slice.length, 12])
		{
			output.writeInt32(value);
		}
		while (output.length < 4096)
		{
			output.writeByte(0);
		}
		output.write(slice);
		return output.getBytes();
	}

	// A static library, an ar archive
	private static function archive():Bytes
	{
		return Bytes.ofString("!<arch>\n");
	}
}
