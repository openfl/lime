package lime.app;

interface IModule
{
	@:dox(show) @:noCompletion private function __registerLimeModule(application:Application):Void;
	@:dox(show) @:noCompletion private function __unregisterLimeModule(application:Application):Void;
}
