package lime.tools;

// "Command-Line Interface Command"
class CLICommand
{
	public var command:String;
	public var args:Array<String>;

	public function new(command:String, args:Array<String> = null)
	{
		this.command = command;
		this.args = args != null ? args : new Array<String>();
	}
}
