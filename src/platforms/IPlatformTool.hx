package platforms;


import project.OpenFLProject;


interface IPlatformTool {
	
	
	public function build (project:OpenFLProject):Void;
	public function clean (project:OpenFLProject):Void;
	public function display (project:OpenFLProject):Void;
	public function install (project:OpenFLProject):Void;
	public function run (project:OpenFLProject, arguments:Array <String>):Void;
	public function trace (project:OpenFLProject):Void;
	public function uninstall (project:OpenFLProject):Void;
	public function update (project:OpenFLProject):Void;
	
	
}
