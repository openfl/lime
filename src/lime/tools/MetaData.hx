package lime.tools;

@:forward
abstract MetaData({
	@:optional var buildNumber:String;
	@:optional var company:String;
	@:optional var companyId:String;
	@:optional var companyUrl:String;
	@:optional var description:String;
	@:optional var packageName:String;
	@:optional var title:String;
	@:optional var version:String;
}) from Dynamic
{
	@:noCompletion
	public static var expectedFields:MetaData = {
		buildNumber: "",
		company: "",
		companyId: "",
		companyUrl: "",
		description: "",
		packageName: "",
		title: "",
		version: ""
	};
}
