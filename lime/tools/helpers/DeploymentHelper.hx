package lime.tools.helpers;


import lime.project.HXProject;


class DeploymentHelper {
	
	
	public static function deploy (project:HXProject, targetFlags:Map <String, String>, targetDirectory:String) {
		
		var name = project.meta.title + " (" + project.meta.version + ").zip";
		
		ZipHelper.compress (PathHelper.combine (targetDirectory, "bin"), PathHelper.combine (targetDirectory, name));
		
	}
	
	
}