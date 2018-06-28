package lime.app;


import lime.ui.Window;
import lime.utils.Preloader;


interface IModule {
	
	
	@:noCompletion public function addWindow (window:Window):Void;
	@:noCompletion public function registerModule (application:Application):Void;
	@:noCompletion public function removeWindow (window:Window):Void;
	@:noCompletion public function setPreloader (preloader:Preloader):Void;
	@:noCompletion public function unregisterModule (application:Application):Void;
	
	
}