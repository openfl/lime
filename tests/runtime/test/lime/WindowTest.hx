package lime;


import lime.app.Application;
import lime.ui.Window;
import massive.munit.Assert;


class WindowTest {
	
	
	private var app:Application;
	
	
	public function new () {
		
		
		
	}
	
	
	@BeforeClass public function beforeClass ():Void {
		
		app = new Application ();
		app.create (null);
		
	}
	
	
	@Test public function addWindow ():Void {
		
		Assert.isNull (app.window);
		Assert.areEqual (0, app.windows.length);
		
		var window = new Window ();
		app.addWindow (window);
		
		Assert.isNotNull (app.window);
		Assert.areEqual (1, app.windows.length);
		Assert.areEqual (window, app.window);
		Assert.areEqual (window, app.windows[0]);
		
		//Assert.areEqual (0, window.width);
		//Assert.areEqual (0, window.height);
		
	}
	
	
	@AfterClass public function afterClass ():Void {
		
		// shutdown
		
		//app = new Application ();
		//app.create (null);
		
	}
	
	
}