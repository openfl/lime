/**
	Puts back the environment variables a test changed. `Sys.putEnv(name, null)` removes a variable,
	but neko before 2.4 can't remove one and throws, so there a variable that wasn't set is set to
	`unset` instead, which is empty unless the test gives a value that reads as no variable.
**/
class Environment
{
	public static function restore(name:String, value:Null<String>, unset:String = ""):Void
	{
		if (value != null)
		{
			Sys.putEnv(name, value);
			return;
		}

		try
		{
			Sys.putEnv(name, null);
		}
		catch (e:Dynamic)
		{
			Sys.putEnv(name, unset);
		}
	}
}
