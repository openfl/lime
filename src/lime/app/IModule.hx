package lime.app;


interface IModule {
	
	
	@:noCompletion private function __registerLimeModule (application:Application):Void;
	@:noCompletion private function __unregisterLimeModule (application:Application):Void;
	
	
}