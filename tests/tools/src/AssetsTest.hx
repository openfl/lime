import lime.tools.AssetType;
import utest.Assert;
import utest.Test;

/**
	`<assets />` paths, renames, patterns, types and the `embed` attribute, from the
	"assets" entry of Lime's XML format documentation.
**/
class AssetsTest extends Test
{
	private var fixture:Fixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();

		for (file in [
			"assets/images/a.png", "assets/images/b.jpg", "assets/images/example.jpg", "assets/images/sub/c.png", "assets/sound/MySound.wav",
			"assets/sound/BackgroundMusic.ogg", "assets/fonts/f.ttf", "assets/data/readme.txt", "assets/data/blob.bin"
		])
		{
			fixture.write(file, file);
		}
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	// "The path attribute can point to either a file or a directory."
	public function testAssetPathCanPointToAFile():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets/images/a.png" />
		</project>');

		Assert.equals(1, project.assets.length);
		var asset = project.assets[0];
		Assert.equals("assets/images/a.png", asset.sourcePath);
		// "The target path will mirror the source path by default"
		Assert.equals("assets/images/a.png", asset.targetPath);
		// "The lime.Assets class will use the target path by default"
		Assert.equals("assets/images/a.png", asset.id);
		Assert.equals(AssetType.IMAGE, asset.type);
	}

	// "If you would prefer to set the ID for your asset file yourself, use an “id” attribute."
	public function testIdNamesAFileAsset():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets/images/a.png" id="logo" />
		</project>');

		Assert.equals("logo", project.assets[0].id);
		Assert.equals("assets/images/a.png", project.assets[0].targetPath);
	}

	// "using the rename attribute will alter the names you use to reference your files"
	public function testRenameChangesTheTargetPathOfAFile():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets/images/a.png" rename="img/logo.png" />
		</project>');

		Assert.equals("assets/images/a.png", project.assets[0].sourcePath);
		Assert.equals("img/logo.png", project.assets[0].targetPath);
		Assert.equals("img/logo.png", project.assets[0].id);
	}

	// "To include all the files under the directory, for example, use an include value of “*”."
	public function testStarIncludesEveryFileInADirectory():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets/images" include="*" />
		</project>');

		Fixture.assertSame([
			"assets/images/a.png",
			"assets/images/b.jpg",
			"assets/images/example.jpg",
			"assets/images/sub/c.png"
		], Fixture.targetPaths(project));
	}

	// <assets path="../../assets" rename="assets" include="*" />
	public function testRenameAppliesToEveryFileInADirectory():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets/images" rename="images" include="*" />
		</project>');

		Fixture.assertSame(["images/a.png", "images/b.jpg", "images/example.jpg", "images/sub/c.png"], Fixture.targetPaths(project));
		Assert.equals("assets/images/sub/c.png", Fixture.findAsset(project, "images/sub/c.png").sourcePath);
	}

	// <assets path="assets/images" rename="images" include="*.jpg|*.png" exclude="example.jpg" />
	public function testIncludeAndExcludeFilterFiles():Void
	{
		fixture.write("assets/images/notes.txt", "notes");

		var project = fixture.parse('<project>
			<assets path="assets/images" rename="images" include="*.jpg|*.png" exclude="example.jpg" />
		</project>');

		Fixture.assertSame(["images/a.png", "images/b.jpg", "images/sub/c.png"], Fixture.targetPaths(project));
	}

	// "Wildcards are supported." A pattern describes the whole file name, as it does for exclude
	@Ignored("Waiting on #2167")
	public function testIncludePatternMatchesTheWholeName():Void
	{
		fixture.write("assets/globs/x.png", "x");
		fixture.write("assets/globs/x.png.bak", "x");
		fixture.write("assets/globs/x.pngx", "x");

		var project = fixture.parse('<project>
			<assets path="assets/globs" include="*.png" />
		</project>');

		Fixture.assertSame(["assets/globs/x.png"], Fixture.targetPaths(project));
	}

	// Outside of wildcards and "|", a pattern is a file name, so it matches that file
	@Ignored("Waiting on #2167")
	public function testPatternsMatchFileNamesLiterally():Void
	{
		fixture.write("assets/names/keep.png", "x");
		fixture.write("assets/names/skip (old).png", "x");
		fixture.write("assets/names/c++.txt", "x");

		var project = fixture.parse('<project>
			<assets path="assets/names" include="*" exclude="skip (old).png|c++.txt" />
		</project>');

		Fixture.assertSame(["assets/names/keep.png"], Fixture.targetPaths(project));
	}

	// "The type for each file will be determined automatically, based on each file extension"
	public function testTypeIsInferredFromTheExtension():Void
	{
		for (file in ["a.png", "b.jpg", "c.gif", "d.ttf", "e.otf", "f.wav", "g.mp3", "h.txt", "i.json", "j.xml", "k.bin"])
		{
			fixture.write("assets/types/" + file, "x");
		}

		var project = fixture.parse('<project>
			<assets path="assets/types" rename="types" />
		</project>');

		var type = function(file:String):AssetType
		{
			var asset = Fixture.findAsset(project, "types/" + file);
			return asset != null ? asset.type : null;
		};

		Assert.equals(AssetType.IMAGE, type("a.png"));
		Assert.equals(AssetType.IMAGE, type("b.jpg"));
		Assert.equals(AssetType.IMAGE, type("c.gif"));
		Assert.equals(AssetType.FONT, type("d.ttf"));
		Assert.equals(AssetType.FONT, type("e.otf"));
		Assert.equals(AssetType.SOUND, type("f.wav"));
		Assert.isTrue(type("g.mp3") == AssetType.SOUND || type("g.mp3") == AssetType.MUSIC, "mp3 is not audio");
		Assert.equals(AssetType.TEXT, type("h.txt"));
		Assert.equals(AssetType.TEXT, type("i.json"));
		Assert.equals(AssetType.TEXT, type("j.xml"));
		Assert.equals(AssetType.BINARY, type("k.bin"));
	}

	// "you can use the type attribute to set it for the file or directory yourself"
	public function testTypeAttributeSetsTheTypeOfAFileOrDirectory():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets/data" rename="data" type="binary" />
			<assets path="assets/images/a.png" rename="raw.png" type="text" />
		</project>');

		Assert.equals(AssetType.BINARY, Fixture.findAsset(project, "data/readme.txt").type);
		Assert.equals(AssetType.BINARY, Fixture.findAsset(project, "data/blob.bin").type);
		Assert.equals(AssetType.TEXT, Fixture.findAsset(project, "raw.png").type);
	}

	// <assets path="assets"><sound path="sound/MySound.wav" id="MySound" /><music path="sound/BackgroundMusic.ogg" /></assets>
	public function testNestedNodesAppendTheParentPath():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets">
				<sound path="sound/MySound.wav" id="MySound" />
				<music path="sound/BackgroundMusic.ogg" />
			</assets>
		</project>');

		Assert.equals(2, project.assets.length);

		var sound = project.assets[0];
		Assert.equals("assets/sound/MySound.wav", sound.sourcePath);
		Assert.equals("MySound", sound.id);
		Assert.equals(AssetType.SOUND, sound.type);

		var music = Fixture.findAsset(project, "assets/sound/BackgroundMusic.ogg");
		Assert.notNull(music);
		if (music != null)
		{
			Assert.equals("assets/sound/BackgroundMusic.ogg", music.sourcePath);
			Assert.equals(AssetType.MUSIC, music.type);
		}
	}

	// "If you are nesting a node inside of another assets node, you can also use the name of the type as the name of your node."
	public function testNestedNodesCanBeNamedAfterTheirType():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets">
				<image path="images/a.png" />
				<font path="fonts/f.ttf" />
				<sound path="sound/BackgroundMusic.ogg" />
				<music path="sound/MySound.wav" />
			</assets>
		</project>');

		Assert.equals(AssetType.IMAGE, Fixture.findAsset(project, "assets/images/a.png").type);
		Assert.equals(AssetType.FONT, Fixture.findAsset(project, "assets/fonts/f.ttf").type);
		Assert.equals(AssetType.SOUND, Fixture.findAsset(project, "assets/sound/BackgroundMusic.ogg").type);
		Assert.equals(AssetType.MUSIC, Fixture.findAsset(project, "assets/sound/MySound.wav").type);
	}

	// The documented types include "binary" and "text", so they name nodes too
	@Ignored("Waiting on #2162")
	public function testNestedNodesCanBeNamedBinaryOrText():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets">
				<binary path="data/readme.txt" />
				<text path="data/blob.bin" />
			</assets>
		</project>');

		Assert.equals(AssetType.BINARY, Fixture.findAsset(project, "assets/data/readme.txt").type);
		Assert.equals(AssetType.TEXT, Fixture.findAsset(project, "assets/data/blob.bin").type);
	}

	public function testNestedNodesUseTheParentRename():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets/sound" rename="audio">
				<sound path="MySound.wav" />
			</assets>
		</project>');

		Assert.equals("assets/sound/MySound.wav", project.assets[0].sourcePath);
		Assert.equals("audio/MySound.wav", project.assets[0].targetPath);
	}

	// "You can nest assets nodes inside of each other. If you specify a directory in the top assets node,
	// its path will be appended to the paths you specify in subsequent nodes."
	// <assets path="assets"> <assets path="images" include="*" type="image" />
	@Ignored("Waiting on #2162")
	public function testNestedAssetsNodeCanNameADirectory():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets">
				<assets path="images" include="*.png" type="image" />
			</assets>
		</project>');

		Fixture.assertSame(["assets/images/a.png", "assets/images/sub/c.png"], Fixture.targetPaths(project));

		for (asset in project.assets)
		{
			Assert.equals(AssetType.IMAGE, asset.type);
		}
	}

	// "every node in the project file format supports if and unless attributes"
	public function testNestedNodesHonourIfAndUnless():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets">
				<image path="images/a.png" if="never-set" />
				<image path="images/b.jpg" unless="never-set" />
			</assets>
		</project>');

		Fixture.assertSame(["assets/images/b.jpg"], Fixture.targetPaths(project));
	}

	public function testEmbedIsTakenFromTheAttribute():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets/images/a.png" embed="true" />
			<assets path="assets/images/b.jpg" embed="false" />
			<assets path="assets/images/example.jpg" />
		</project>');

		Assert.equals(true, Fixture.findAsset(project, "assets/images/a.png").embed);
		Assert.equals(false, Fixture.findAsset(project, "assets/images/b.jpg").embed);
		Assert.isNull(Fixture.findAsset(project, "assets/images/example.jpg").embed);
	}

	public function testDirectoryEmbedAppliesToEveryFile():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets/images" embed="true" />
		</project>');

		Assert.equals(4, project.assets.length);

		for (asset in project.assets)
		{
			Assert.equals(true, asset.embed);
		}
	}

	public function testNestedNodesInheritEmbedUnlessTheyOverrideIt():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets" embed="false">
				<image path="images/a.png" />
				<image path="images/b.jpg" embed="true" />
			</assets>
		</project>');

		Assert.equals(false, Fixture.findAsset(project, "assets/images/a.png").embed);
		Assert.equals(true, Fixture.findAsset(project, "assets/images/b.jpg").embed);
	}

	// <assets path="assets/other" library="myOtherLibrary" />
	public function testLibraryAssignsAssetsToALibrary():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets/images" library="myOtherLibrary" />
			<assets path="assets/data/readme.txt" />
		</project>');

		for (asset in project.assets)
		{
			if (asset.targetPath == "assets/data/readme.txt")
			{
				Assert.isNull(asset.library);
			}
			else
			{
				Assert.equals("myOtherLibrary", asset.library);
			}
		}
	}

	// "If an asset is specified as “template”, it will not be copied/embedded as an ordinary asset,
	// but instead will be copied to the root directory of your project"
	public function testTemplateTypeMakesATemplateAsset():Void
	{
		var project = fixture.parse('<project>
			<assets path="assets/data/readme.txt" rename="README.txt" type="template" />
		</project>');

		Assert.equals(AssetType.TEMPLATE, project.assets[0].type);
		Assert.equals("README.txt", project.assets[0].targetPath);
	}

	public function testAssetPathsCanUseSubstitution():Void
	{
		var project = fixture.parse('<project>
			<set name="folder" value="assets/images" />
			<assets path="$${folder}" rename="images" include="*.png" />
		</project>');

		Fixture.assertSame(["images/a.png", "images/sub/c.png"], Fixture.targetPaths(project));
	}
}
