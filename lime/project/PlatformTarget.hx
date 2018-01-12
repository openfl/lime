package lime.project;


import haxe.rtti.Meta;
import lime.tools.helpers.AssetHelper;
import lime.tools.helpers.CommandHelper;
import lime.tools.helpers.LogHelper;


class PlatformTarget {
	
	
	public var additionalArguments:Array<String>;
	public var buildType:String;
	public var command:String;
	public var noOutput:Bool;
	public var project:HXProject;
	public var targetDirectory:String;
	public var targetFlags:Map<String, String>;
	public var traceEnabled = true;
	
	
	public function new (command:String = null, project:HXProject = null, targetFlags:Map<String, String> = null) {
		
		this.command = command;
		this.project = project;
		this.targetFlags = targetFlags;
		
		buildType = "release";
		
		if (project != null) {
			
			if (project.debug) {
				
				buildType = "debug";
				
			} else if (project.targetFlags.exists ("final")) {
				
				buildType = "final";
				
			}
			
		}
		
		for (haxeflag in project.haxeflags) {
			
			if (haxeflag == "--no-output") {
				
				noOutput = true;
				
			}
			
		}
		
	}
	
	
	public function execute (additionalArguments:Array<String>):Void {
		
		LogHelper.info ("", LogHelper.accentColor + "Using target platform: " + Std.string (project.target).toUpperCase () + LogHelper.resetColor);
		
		this.additionalArguments = additionalArguments;
		var metaFields = Meta.getFields (Type.getClass (this));
		
		if (/*!Reflect.hasField (metaFields.watch, "ignore") && */(project.targetFlags.exists ("watch"))) {
			
			LogHelper.info ("", "\n" + LogHelper.accentColor + "Running command: WATCH" + LogHelper.resetColor);
			watch ();
			return;
			
		}
		
		if (!Reflect.hasField (metaFields.display, "ignore") && (command == "display")) {
			
			display ();
			
		}
		
		//if (!Reflect.hasField (metaFields.clean, "ignore") && (command == "clean" || targetFlags.exists ("clean"))) {
		if (!Reflect.hasField (metaFields.clean, "ignore") && (command == "clean" || (project.targetFlags.exists ("clean") && (command == "update" || command == "build" || command == "test")))) {
			
			LogHelper.info ("", LogHelper.accentColor + "Running command: CLEAN" + LogHelper.resetColor);
			clean ();
			
		}
		
		if (!Reflect.hasField (metaFields.rebuild, "ignore") && (command == "rebuild" || project.targetFlags.exists ("rebuild"))) {
			
			LogHelper.info ("", "\n" + LogHelper.accentColor + "Running command: REBUILD" + LogHelper.resetColor);
			
			// hack for now, need to move away from project.rebuild.path, probably
			
			if (project.targetFlags.exists ("rebuild")) {
				
				project.config.set ("project.rebuild.path", null);
				
			}
			
			rebuild ();
			
		}
		
		if (!Reflect.hasField (metaFields.update, "ignore") && (command == "update" || command == "build" || command == "test")) {
			
			LogHelper.info ("", "\n" + LogHelper.accentColor + "Running command: UPDATE" + LogHelper.resetColor);
			AssetHelper.processLibraries (project, targetDirectory);
			update ();
			
		}
		
		if (!Reflect.hasField (metaFields.build, "ignore") && (command == "build" || command == "test")) {
			
			CommandHelper.executeCommands (project.preBuildCallbacks);
			
			LogHelper.info ("", "\n" + LogHelper.accentColor + "Running command: BUILD" + LogHelper.resetColor);
			build ();
			
			CommandHelper.executeCommands (project.postBuildCallbacks);
			
		}
		
		if (!Reflect.hasField (metaFields.deploy, "deploy") && (command == "deploy")) {
			
			LogHelper.info ("", "\n" + LogHelper.accentColor + "Running command: DEPLOY" + LogHelper.resetColor);
			deploy ();
			
		}
		
		if (!Reflect.hasField (metaFields.install, "ignore") && (command == "install" || command == "run" || command == "test")) {
			
			LogHelper.info ("", "\n" + LogHelper.accentColor + "Running command: INSTALL" + LogHelper.resetColor);
			install ();
			
		}
		
		if (!Reflect.hasField (metaFields.run, "ignore") && (command == "run" || command == "rerun" || command == "test")) {
			
			LogHelper.info ("", "\n" + LogHelper.accentColor + "Running command: RUN" + LogHelper.resetColor);
			run ();
			
		}
		
		if (!Reflect.hasField (metaFields.trace, "ignore") && (command == "test" || command == "trace" || command == "run" || command == "rerun" )) {
			
			if (traceEnabled || command == "trace") {
				
				LogHelper.info ("", "\n" + LogHelper.accentColor + "Running command: TRACE" + LogHelper.resetColor);
				this.trace ();
				
			}
			
		}
		
		if (!Reflect.hasField (metaFields.uninstall, "ignore") && (command == "uninstall")) {
			
			LogHelper.info ("", "\n" + LogHelper.accentColor + "Running command: UNINSTALL" + LogHelper.resetColor);
			uninstall ();
			
		}
		
	}
	
	
	@ignore public function build ():Void {}
	@ignore public function clean ():Void {}
	@ignore public function deploy ():Void {}
	@ignore public function display ():Void {}
	@ignore public function install ():Void {}
	@ignore public function rebuild ():Void {}
	@ignore public function run ():Void {}
	@ignore public function trace ():Void {}
	@ignore public function uninstall ():Void {}
	@ignore public function update ():Void {}
	@ignore public function watch ():Void {}
	
	
}