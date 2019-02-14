package flash.security;

@:fakeEnum(String) extern enum RevocationCheckSettings
{
	ALWAYS_REQUIRED;
	BEST_EFFORT;
	NEVER;
	REQUIRED_IF_AVAILABLE;
}
