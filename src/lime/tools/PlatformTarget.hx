package lime.tools;

import haxe.rtti.Meta;
import hxp.*;
import lime.tools.AssetHelper;
import lime.tools.CommandHelper;

class PlatformTarget
{
	public var additionalArguments:Array<String>;
	public var buildType:String;
	public var command:String;
	public var noOutput:Bool;
	public var project:HXProject;
	public var targetDirectory:String;
	public var targetFlags:Map<String, String>;
	public var traceEnabled = true;

	public function new(command:String = null, project:HXProject = null, targetFlags:Map<String, String> = null)
	{
		this.command = command;
		this.project = project;
		this.targetFlags = targetFlags;

		buildType = "release";

		if (project != null)
		{
			if (project.debug)
			{
				buildType = "debug";
			}
			else if (project.targetFlags.exists("final"))
			{
				buildType = "final";
			}
		}

		for (haxeflag in project.haxeflags)
		{
			if (haxeflag == "--no-output")
			{
				noOutput = true;
			}
		}
	}

	public function execute(additionalArguments:Array<String>):Void
	{
		// Log.info ("", Log.accentColor + "Using target platform: " + Std.string (project.target).toUpperCase () + Log.resetColor);

		this.additionalArguments = additionalArguments;
		var metaFields = Meta.getFields(Type.getClass(this));

		if (/*!Reflect.hasField (metaFields.watch, "ignore") && */ (project.targetFlags.exists("watch")))
		{
			Log.info("", "\n" + Log.accentColor + "Running command: WATCH" + Log.resetColor);
			watch();
			return;
		}

		if ((!Reflect.hasField(metaFields, "display") || !Reflect.hasField(metaFields.display, "ignore")) && (command == "display"))
		{
			display();
		}

		// if (!Reflect.hasField (metaFields.clean, "ignore") && (command == "clean" || targetFlags.exists ("clean"))) {
		if ((!Reflect.hasField(metaFields, "clean") || !Reflect.hasField(metaFields.clean, "ignore"))
			&& (command == "clean"
				|| (project.targetFlags.exists("clean") && (command == "update" || command == "build" || command == "test"))))
		{
			Log.info("", Log.accentColor + "Running command: CLEAN" + Log.resetColor);
			clean();
		}

		if ((!Reflect.hasField(metaFields, "rebuild") || !Reflect.hasField(metaFields.rebuild, "ignore"))
			&& (command == "rebuild" || project.targetFlags.exists("rebuild")))
		{
			Log.info("", "\n" + Log.accentColor + "Running command: REBUILD" + Log.resetColor);

			// hack for now, need to move away from project.rebuild.path, probably

			if (project.targetFlags.exists("rebuild"))
			{
				project.config.set("project.rebuild.path", null);
			}

			rebuild();
		}

		if ((!Reflect.hasField(metaFields, "update") || !Reflect.hasField(metaFields.update, "ignore"))
			&& (command == "update" || command == "build" || command == "test"))
		{
			Log.info("", "\n" + Log.accentColor + "Running command: UPDATE" + Log.resetColor);
			// #if lime
			// AssetHelper.processLibraries (project, targetDirectory);
			// #end
			update();
		}

		if ((!Reflect.hasField(metaFields, "build") || !Reflect.hasField(metaFields.build, "ignore"))
			&& (command == "build" || command == "test"))
		{
			CommandHelper.executeCommands(project.preBuildCallbacks);

			Log.info("", "\n" + Log.accentColor + "Running command: BUILD" + Log.resetColor);
			build();

			CommandHelper.executeCommands(project.postBuildCallbacks);
		}

		if ((!Reflect.hasField(metaFields, "deploy") || !Reflect.hasField(metaFields.deploy, "ignore")) && (command == "deploy"))
		{
			Log.info("", "\n" + Log.accentColor + "Running command: DEPLOY" + Log.resetColor);
			deploy();
		}

		if ((!Reflect.hasField(metaFields, "install") || !Reflect.hasField(metaFields.install, "ignore"))
			&& (command == "install" || command == "run" || command == "test"))
		{
			Log.info("", "\n" + Log.accentColor + "Running command: INSTALL" + Log.resetColor);
			install();
		}

		if ((!Reflect.hasField(metaFields, "run") || !Reflect.hasField(metaFields.run, "ignore"))
			&& (command == "run" || command == "rerun" || command == "test"))
		{
			Log.info("", "\n" + Log.accentColor + "Running command: RUN" + Log.resetColor);
			run();
		}

		if ((!Reflect.hasField(metaFields, "trace") || !Reflect.hasField(metaFields.trace, "ignore"))
			&& (command == "test" || command == "trace" || command == "run" || command == "rerun"))
		{
			if (traceEnabled || command == "trace")
			{
				Log.info("", "\n" + Log.accentColor + "Running command: TRACE" + Log.resetColor);
				this.trace();
			}
		}

		if ((!Reflect.hasField(metaFields, "uninstall") || !Reflect.hasField(metaFields.uninstall, "ignore")) && (command == "uninstall"))
		{
			Log.info("", "\n" + Log.accentColor + "Running command: UNINSTALL" + Log.resetColor);
			uninstall();
		}
	}

	@ignore public function build():Void {}

	@ignore public function clean():Void {}

	@ignore public function deploy():Void {}

	@ignore public function display():Void {}

	@ignore public function install():Void {}

	@ignore public function rebuild():Void {}

	@ignore public function run():Void {}

	@ignore public function trace():Void {}

	@ignore public function uninstall():Void {}

	@ignore public function update():Void {}

	@ignore public function watch():Void {}
}
