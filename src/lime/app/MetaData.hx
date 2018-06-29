package lime.app;


typedef MetaData = {
	
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
	@:optional var build:String;
	
	/**
	 * A company name
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<meta company="" />` attribute in XML
	**/
	@:optional var company:String;
	
	/**
	 * An application file name, without a file extension
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<app file="" />` attribute in XML
	**/
	@:optional var file:String;
	
	/**
	 * An application name, used as the default Window title
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<meta title="" />` attribute in XML
	**/
	@:optional var name:String;
	
	/**
	 * A package name, this usually corresponds to the unique ID used
	 * in application stores to identify the current application
	 *
	 * In the default generated config for Lime applications, this value 
	 * corresponds to the `<meta package="" />` attribute in XML
	**/
	@:optional var packageName:String;
	
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
	@:optional var version:String;
	
}