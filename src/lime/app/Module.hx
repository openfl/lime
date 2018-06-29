package lime.app;


import lime.ui.Window;
import lime.utils.Preloader;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class Module implements IModule {
	
	
	/**
	 * Exit events are dispatched when the application is exiting
	 */
	public var onExit = new Event<Int->Void> ();
	
	
	public function new () {
		
		
		
	}
	
	
	@:noCompletion public function addWindow (window:Window):Void {}
	@:noCompletion public function registerModule (application:Application):Void {}
	@:noCompletion public function removeWindow (window:Window):Void {}
	@:noCompletion public function setPreloader (preloader:Preloader):Void {}
	@:noCompletion public function unregisterModule (application:Application):Void {}
	
	
}