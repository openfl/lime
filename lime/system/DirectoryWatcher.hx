package lime.system;


import lime._backend.native.NativeCFFI;
import lime.app.Application;
import lime.app.Event;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)


class DirectoryWatcher {
	
	
	public var onChange = new Event<Void->Void> ();
	public var onFileAdd = new Event<String->Void> ();
	public var onFileModify = new Event<String->Void> ();
	public var onFileRemove = new Event<String->Void> ();
	
	private var handle:CFFIPointer;
	private var hasUpdate:Bool;
	private var ids:Map<String, Int>;
	
	
	public function new () {
		
		#if (lime_cffi && !macro)
		handle = NativeCFFI.lime_directory_watcher_create (this_onChange);
		ids = new Map ();
		#end
		
	}
	
	
	public function addPath (path:String, recursive:Bool = true):Void {
		
		#if (lime_cffi && !macro)
		if (!hasUpdate) {
			
			Application.current.onUpdate.add (this_onUpdate);
			hasUpdate = true;
			
		}
		
		var id:Int = NativeCFFI.lime_directory_watcher_add_watch (handle, path, recursive);
		ids[path] = id;
		#end
		
	}
	
	
	public function removePath (path:String):Void {
		
		#if (lime_cffi && !macro)
		if (ids.exists (path)) {
			
			NativeCFFI.lime_directory_watcher_remove_watch (handle, ids[path]);
			ids.remove (path);
			
			if (!ids.keys ().hasNext ()) {
				
				Application.current.onUpdate.remove (this_onUpdate);
				hasUpdate = false;
				
			}
			
			
		}
		#end
		
	}
	
	
	private function this_onChange (directory:String, file:String, action:Int):Void {
		
		var trailingSlash = (directory.substr (-1) == "/" || directory.substr (-1) == "\\");
		var startingSlash = (file.substr (0, 1) == "/" || file.substr (0, 1) == "\\");
		var path;
		
		if (trailingSlash && startingSlash) {
			
			path = directory + file.substr (1);
			
		} else if (!trailingSlash && !startingSlash) {
			
			path = directory + #if windows "\\" #else "/" #end + file;
			
		} else {
			
			path = directory + file;
			
		}
		
		switch (action) {
			
			case 1:
				
				onFileAdd.dispatch (path);
				onChange.dispatch ();
			
			case 2:
				
				onFileRemove.dispatch (path);
				onChange.dispatch ();
			
			case 4:
				
				onFileModify.dispatch (path);
				onChange.dispatch ();
			
		}
		
	}
	
	
	private function this_onUpdate (_):Void {
		
		#if (lime_cffi && !macro)
		NativeCFFI.lime_directory_watcher_update (handle);
		#end
		
	}
	
	
}