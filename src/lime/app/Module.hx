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
	
	
	@:noCompletion private function __registerLimeModule (application:Application):Void {}
	@:noCompletion private function __unregisterLimeModule (application:Application):Void {}
	
	
}