package lime.ui;


import lime._backend.native.NativeCFFI;
import lime.app.Event;
import lime.system.BackgroundWorker;
import lime.utils.Resource;

#if sys
import sys.io.File;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)


class FileDialog {
	
	
	public var onCancel = new Event<Void->Void> ();
	public var onOpen = new Event<Resource->Void> ();
	public var onSave = new Event<String->Void> ();
	public var onSelect = new Event<String->Void> ();
	public var onSelectMultiple = new Event<Array<String>->Void> ();
	
	
	public function new () {
		
		
		
	}
	
	
	public function browse (type:FileDialogType = null, filter:String = null, defaultPath:String = null):Bool {
		
		if (type == null) type = FileDialogType.OPEN;
		
		#if desktop
		
		var worker = new BackgroundWorker ();
		
		worker.doWork.add (function (_) {
			
			switch (type) {
				
				case OPEN:
					
					worker.sendComplete (NativeCFFI.lime_file_dialog_open_file (filter, defaultPath));
				
				case OPEN_MULTIPLE:
					
					worker.sendComplete (NativeCFFI.lime_file_dialog_open_files (filter, defaultPath));
				
				case OPEN_DIRECTORY:
					
					worker.sendComplete (NativeCFFI.lime_file_dialog_open_directory (filter, defaultPath));
				
				case SAVE:
					
					worker.sendComplete (NativeCFFI.lime_file_dialog_save_file (filter, defaultPath));
				
			}
			
		});
		
		worker.onComplete.add (function (result) {
			
			switch (type) {
				
				case OPEN, OPEN_DIRECTORY, SAVE:
					
					var path:String = cast result;
					
					if (path != null) {
						
						onSelect.dispatch (path);
						
					} else {
						
						onCancel.dispatch ();
						
					}
				
				case OPEN_MULTIPLE:
					
					var paths:Array<String> = cast result;
					
					if (paths != null && paths.length > 0) {
						
						onSelectMultiple.dispatch (paths);
						
					} else {
						
						onCancel.dispatch ();
						
					}
				
			}
			
		});
		
		worker.run ();
		
		return true;
		
		#else
		
		onCancel.dispatch ();
		return false;
		
		#end
		
	}
	
	
	public function open (filter:String = null, defaultPath:String = null):Bool {
		
		#if desktop
		
		var worker = new BackgroundWorker ();
		
		worker.doWork.add (function (_) {
			
			worker.sendComplete (NativeCFFI.lime_file_dialog_open_file (filter, defaultPath));
			
		});
		
		worker.onComplete.add (function (path:String) {
			
			if (path != null) {
				
				try {
					
					var data = File.getBytes (path);
					onOpen.dispatch (data);
					return;
					
				} catch (e:Dynamic) {}
				
			}
			
			onCancel.dispatch ();
			
		});
		
		worker.run ();
		
		return true;
		
		#else
		
		onCancel.dispatch ();
		return false;
		
		#end
		
	}
	
	
	public function save (data:Resource, filter:String = null, defaultPath:String = null):Bool {
		
		#if desktop
		
		var worker = new BackgroundWorker ();
		
		worker.doWork.add (function (_) {
			
			worker.sendComplete (NativeCFFI.lime_file_dialog_save_file (filter, defaultPath));
			
		});
		
		worker.onComplete.add (function (path:String) {
			
			if (path != null) {
				
				try {
					
					File.saveBytes (path, data);
					onSave.dispatch (path);
					return;
					
				} catch (e:Dynamic) {}
				
			}
			
			onCancel.dispatch ();
			
		});
		
		worker.run ();
		
		return true;
		
		#else
		
		onCancel.dispatch ();
		return false;
		
		#end
		
	}
	
	
}