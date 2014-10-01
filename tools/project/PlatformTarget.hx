package project;


import haxe.rtti.Meta;
import helpers.LogHelper;


class PlatformTarget {
	
	
	public var command:String;
	public var project:HXProject;
	public var targetFlags:Map <String, String>;
	public var traceEnabled = true;
	
	
	public function new (command:String = null, project:HXProject = null, targetFlags:Map <String, String> = null) {
		
		this.command = command;
		this.project = project;
		this.targetFlags = targetFlags;
		
	}
	
	
	public function execute ():Void {
		
		LogHelper.info ("", "\x1b[32;1mUsing target platform: " + Std.string (project.target).toUpperCase () + "\x1b[0m");
		
		var metaFields = Meta.getFields (Type.getClass (this));
		
		if (!Reflect.hasField (metaFields.display, "ignore") && (command == "display")) {
			
			display ();
			
		}
		
		//if (!Reflect.hasField (metaFields.clean, "ignore") && (command == "clean" || targetFlags.exists ("clean"))) {
		if (!Reflect.hasField (metaFields.clean, "ignore") && (command == "clean" || (project.targetFlags.exists ("clean") && command != "rebuild"))) {
			
			LogHelper.info ("", "\n\x1b[32;1mRunning command: CLEAN\x1b[0m");
			clean ();
			
		}
		
		if (!Reflect.hasField (metaFields.rebuild, "ignore") && (command == "rebuild" || project.targetFlags.exists ("rebuild"))) {
			
			LogHelper.info ("", "\n\x1b[32;1mRunning command: REBUILD\x1b[0m");
			rebuild ();
			
		}
		
		if (!Reflect.hasField (metaFields.update, "ignore") && (command == "update" || command == "build" || command == "test")) {
			
			LogHelper.info ("", "\n\x1b[32;1mRunning command: UPDATE\x1b[0m");
			update ();
			
		}
		
		if (!Reflect.hasField (metaFields.build, "ignore") && (command == "build" || command == "test")) {
			
			LogHelper.info ("", "\n\x1b[32;1mRunning command: BUILD\x1b[0m");
			build ();
			
		}
		
		if (!Reflect.hasField (metaFields.install, "ignore") && (command == "install" || command == "run" || command == "test")) {
			
			LogHelper.info ("", "\n\x1b[32;1mRunning command: INSTALL\x1b[0m");
			install ();
			
		}
		
		if (!Reflect.hasField (metaFields.run, "ignore") && (command == "run" || command == "rerun" || command == "test")) {
			
			LogHelper.info ("", "\n\x1b[32;1mRunning command: RUN\x1b[0m");
			run ();
			
		}
		
		if (!Reflect.hasField (metaFields.trace, "ignore") && (command == "test" || command == "trace")) {
			
			if (traceEnabled || command == "trace") {
				
				LogHelper.info ("", "\n\x1b[32;1mRunning command: TRACE\x1b[0m");
				this.trace ();
				
			}
			
		}
		
		if (!Reflect.hasField (metaFields.uninstall, "ignore") && (command == "uninstall")) {
			
			LogHelper.info ("", "\n\x1b[32;1mRunning command: UNINSTALL\x1b[0m");
			uninstall ();
			
		}
		
	}
	
	
	@ignore public function build ():Void {}
	@ignore public function clean ():Void {}
	@ignore public function display ():Void {}
	@ignore public function install ():Void {}
	@ignore public function rebuild ():Void {}
	@ignore public function run ():Void {}
	@ignore public function trace ():Void {}
	@ignore public function uninstall ():Void {}
	@ignore public function update ():Void {}
	
	
}