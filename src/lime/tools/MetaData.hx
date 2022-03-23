package lime.tools;

typedef MetaData =
{
	@:optional var buildNumber:String;
	@:optional var company:String;
	@:optional var companyId:String;
	@:optional var companyUrl:String;
	@:optional var description:String;
	@:optional var packageName:String;
	@:optional var title:String;
	@:optional var version:String;
}

@:dox(hide) class _MetaDataType
{
	public static var fields:MetaData =
		{
			buildNumber: "",
			company: "",
			companyId: "",
			companyUrl: "",
			description: "",
			packageName: "",
			title: "",
			version: ""
		}
}
