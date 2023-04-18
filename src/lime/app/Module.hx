package lime.app;

import lime.ui.Window;
import lime.utils.Preloader;

/**
	`Module` instances can be added to a running `Application`,
	simplifying support for adding new components, such as a renderer,
	input handler or higher-level framework.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Module implements IModule
{
	/**
		Exit events are dispatched when the application is exiting
	**/
	public var onExit = new Event<Int->Void>();

	/**
		Creates a new `Module` instance
	**/
	public function new() {}

	@:noCompletion private function __registerLimeModule(application:Application):Void {}

	@:noCompletion private function __unregisterLimeModule(application:Application):Void {}
}
