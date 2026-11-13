import lime.tools.AssetHelper;
import lime.tools.HXProject;
import lime.tools.Platform;
import utest.Assert;
import utest.Test;

/**
	How the `embed` attribute decides between an embedded asset and one loaded from a path,
	in the asset manifest `AssetHelper` writes and the template context the generated code
	comes from. CHANGELOG 8.4.0: "Changed asset copying and embedding to behave consistently
	across targets" and "Changed embedded assets to no longer be copied to the output folder".
**/
class AssetEmbeddingTest extends Test
{
	private var fixture:Fixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();

		for (file in ["embedded.png", "loaded.png", "default.png"])
		{
			fixture.write("assets/" + file, file);
		}
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	public function testEmbeddedAssetsAreClassesOnNativeTargets():Void
	{
		var project = parseFor(WINDOWS);
		var entry = manifestEntry(project, "assets/embedded.png");

		Assert.equals("__ASSET__" + Fixture.findAsset(project, "assets/embedded.png").flatName, entry.className);
		Assert.isNull(entry.path);
	}

	public function testAssetsThatAreNotEmbeddedArePathsOnNativeTargets():Void
	{
		var project = parseFor(WINDOWS);

		for (id in ["assets/loaded.png", "assets/default.png"])
		{
			var entry = manifestEntry(project, id);
			Assert.equals(id, entry.path);
			Assert.isNull(entry.className);
		}
	}

	public function testFlashEmbedsAssetsUnlessEmbedIsFalse():Void
	{
		var project = parseFor(FLASH);

		Assert.notNull(manifestEntry(project, "assets/embedded.png").className);
		Assert.notNull(manifestEntry(project, "assets/default.png").className);
		Assert.equals("assets/loaded.png", manifestEntry(project, "assets/loaded.png").path);
	}

	public function testHtml5PreloadsAssetsUnlessEmbedIsFalse():Void
	{
		var project = parseFor(HTML5);

		Assert.equals(true, manifestEntry(project, "assets/embedded.png").preload);
		Assert.equals(true, manifestEntry(project, "assets/default.png").preload);
		Assert.isNull(manifestEntry(project, "assets/loaded.png").preload);

		for (id in ["assets/embedded.png", "assets/loaded.png", "assets/default.png"])
		{
			Assert.equals(id, manifestEntry(project, id).path);
		}
	}

	// Where the generated code embeds an asset (the template context's embed), the manifest
	// names its class, and where it doesn't, the manifest gives its path, so no asset is
	// both embedded and loaded from a file
	@Ignored("Waiting on #2165")
	public function testTemplatesAndManifestsAgreeOnWhatIsEmbedded():Void
	{
		var disagreements = [];

		for (target in [WINDOWS, MAC, LINUX, ANDROID, IOS, FLASH, AIR, WEB_ASSEMBLY])
		{
			var project = parseFor(target);
			var context = project.templateContext;
			var assets:Array<Dynamic> = context.assets;

			for (asset in assets)
			{
				var entry = manifestEntry(project, asset.id);
				var embedded = (asset.embed == true);
				var hasClass = (entry.className != null);

				if (embedded != hasClass)
				{
					disagreements.push(Std.string(target) + " " + asset.id + ": template embed " + asset.embed + ", manifest "
						+ (hasClass ? "class" : "path"));
				}
			}
		}

		Fixture.assertSame([], disagreements);
	}

	private function manifestEntry(project:HXProject, id:String):Dynamic
	{
		var manifest = AssetHelper.createManifest(project);

		for (entry in manifest.assets)
		{
			if (entry.id == id) return entry;
		}

		Assert.fail("The manifest has no \"" + id + "\"");
		return {};
	}

	private function parseFor(target:Platform):HXProject
	{
		fixture.target = target;

		return fixture.parse('<project>
			<assets path="assets/embedded.png" embed="true" />
			<assets path="assets/loaded.png" embed="false" />
			<assets path="assets/default.png" />
		</project>');
	}
}
