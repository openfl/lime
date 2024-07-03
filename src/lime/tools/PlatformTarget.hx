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

		// known issue: this may not log in `-eval` mode on Linux
		inline function logCommand(command:String):Void
		{
			if (!Reflect.hasField(metaFields, command)
				|| !Reflect.hasField(Reflect.field(metaFields, command), "ignore"))
			{
				Log.info("", "\n" + Log.accentColor + "Running command: " + command.toUpperCase() + Log.resetColor);
			}
		}

		if (project.targetFlags.exists("watch"))
		{
			Log.info("", "\n" + Log.accentColor + "Running command: WATCH" + Log.resetColor);
			watch();
			return;
		}

		if (command == "display")
		{
			display();
		}

		// if (command == "clean" || project.targetFlags.exists ("clean")) {
		if (command == "clean"
			|| (project.targetFlags.exists("clean") && (command == "update" || command == "build" || command == "test")))
		{
			logCommand("CLEAN");
			clean();
		}

		if (command == "rebuild" || project.targetFlags.exists("rebuild"))
		{
			logCommand("REBUILD");

			// hack for now, need to move away from project.rebuild.path, probably

			if (project.targetFlags.exists("rebuild"))
			{
				project.config.set("project.rebuild.path", null);
			}

			rebuild();
		}

		if (command == "update" || command == "build" || command == "test")
		{
			logCommand("update");
			// #if lime
			// AssetHelper.processLibraries (project, targetDirectory);
			// #end
			update();
		}

		if (command == "build" || command == "test")
		{
			CommandHelper.executeCommands(project.preBuildCallbacks);

			logCommand("build");
			build();

			CommandHelper.executeCommands(project.postBuildCallbacks);
		}

		if (command == "deploy")
		{
			logCommand("deploy");
			deploy();
		}

		if (command == "install" || command == "run" || command == "test")
		{
			logCommand("install");
			install();
		}

		if (command == "run" || command == "rerun" || command == "test")
		{
			logCommand("run");
			run();
		}

		if ((command == "test" || command == "trace" || command == "run" || command == "rerun")
			&& (traceEnabled || command == "trace"))
		{
			logCommand("trace");
			this.trace();
		}

		if (command == "uninstall")
		{
			logCommand("UNINSTALL");
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
