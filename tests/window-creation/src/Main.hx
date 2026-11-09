import lime.app.Application;
import lime.system.System;

@:access(lime.app.Application)
class Main extends Application
{
	public function new()
	{
		var driver = Sys.getEnv("SDL_VIDEODRIVER");
		Sys.putEnv("SDL_VIDEODRIVER", "lime-test-invalid");
		super();

		#if !window_creation_startup_failure
		var created = 0;
		onCreateWindow.add(function(_) created++);

		var rejected = createWindow({width: 64, height: 64, hidden: true, context: {hardware: false}});
		require(rejected == null, "Failed creation did not return null");
		require(window == null && windows.length == 0, "A failed window was registered");
		require(created == 0, "Failed creation dispatched onCreateWindow");
		require(__windowCreationError != null && __windowCreationError.indexOf("lime-test-invalid") >= 0, "The SDL error was lost");

		// Neko throws on a null value; SDL takes an empty driver name as its default
		Sys.putEnv("SDL_VIDEODRIVER", driver != null ? driver : "");
		var recovered = createWindow({width: 64, height: 64, hidden: true, context: {hardware: false}});
		require(recovered != null, "A window could not be created after a failure");
		require(window == recovered && windows.length == 1, "The recovered window was not registered");
		require(created == 1, "Recovery did not dispatch onCreateWindow once");
		require(__windowCreationError == null, "Successful creation kept the previous error");

		Sys.println("Window creation recovered after a failed first window");
		System.exit(0);
		#end
	}

	private static function require(condition:Bool, message:String):Void
	{
		if (!condition)
		{
			Sys.stderr().writeString(message + "\n");
			System.exit(1);
		}
	}
}
