package lime.app;


@:forward()


abstract MetaData(Dynamic) from Dynamic to Dynamic {
	
	/**
	 * A build number
	 *
	 * The build number is a unique, integer-based value which increases
	 * upon each build or release of an application. This is distinct from
	 * the version number.
	 *
	 * In the default generated config for Lime applications, this is often
	 * updated automatically, or can be overriden in XML project files using
	 * the `<app build="" />` attribute
	**/
	public var build (get, set):String;
	@:noCompletion private inline function get_build () { return this.build; }
	@:noCompletion private inline function set_build (value) { return this.build = value; }
	
	/**
	 * A company name
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<meta company="" />` attribute in XML
	**/
	public var company (get, set):String;
	@:noCompletion private inline function get_company () { return this.company; }
	@:noCompletion private inline function set_company (value) { return this.company = value; }
	
	/**
	 * An application file name, without a file extension
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<app file="" />` attribute in XML
	**/
	public var file (get, set):String;
	@:noCompletion private inline function get_file () { return this.file; }
	@:noCompletion private inline function set_file (value) { return this.file = value; }
	
	/**
	 * An application name, used as the default Window title
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<meta title="" />` attribute in XML
	**/
	public var name (get, set):String;
	@:noCompletion private inline function get_name () { return this.name; }
	@:noCompletion private inline function set_name (value) { return this.name = value; }
	
	/**
	 * A package name, this usually corresponds to the unique ID used
	 * in application stores to identify the current application
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<meta package="" />` attribute in XML
	**/
	public var packageName (get, set):String;
	@:noCompletion private inline function get_packageName () { return this.packageName; }
	@:noCompletion private inline function set_packageName (value) { return this.packageName = value; }
	
	/**
	 * A version number
	 *
	 * The version number is what normally corresponds to the user-facing
	 * version for an application, such as "1.0.0" or "12.2.5". This is 
	 * distinct from the build number. Many application stores expect the
	 * version number to include three segments.
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<meta title="" />` attribute in XML
	**/
	public var version (get, set):String;
	@:noCompletion private inline function get_version () { return this.version; }
	@:noCompletion private inline function set_version (value) { return this.version = value; }
	
}