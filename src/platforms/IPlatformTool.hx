package platforms;


import project.HXProject;


interface IPlatformTool {
	
	
	public function build (project:HXProject):Void;
	public function clean (project:HXProject):Void;
	public function display (project:HXProject):Void;
	public function install (project:HXProject):Void;
	public function run (project:HXProject, arguments:Array <String>):Void;
	public function trace (project:HXProject):Void;
	public function uninstall (project:HXProject):Void;
	public function update (project:HXProject):Void;
	
	
}
