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
	
	
	public function browse (type:FileDialogType = null, filter:String = null, defaultPath:String = null, title:String = null):Bool {
		
		if (type == null) type = FileDialogType.OPEN;
		
		#if desktop
		
		var worker = new BackgroundWorker ();
		
		worker.doWork.add (function (_) {
			
			switch (type) {
				
				case OPEN:
					
					#if linux
					if (title == null) title = "Open File";
					#end
					
					worker.sendComplete (NativeCFFI.lime_file_dialog_open_file (title, filter, defaultPath));
				
				case OPEN_MULTIPLE:
					
					#if linux
					if (title == null) title = "Open Files";
					#end
					
					worker.sendComplete (NativeCFFI.lime_file_dialog_open_files (title, filter, defaultPath));
				
				case OPEN_DIRECTORY:
					
					#if linux
					if (title == null) title = "Open Directory";
					#end
					
					worker.sendComplete (NativeCFFI.lime_file_dialog_open_directory (title, filter, defaultPath));
				
				case SAVE:
					
					#if linux
					if (title == null) title = "Save File";
					#end
					
					worker.sendComplete (NativeCFFI.lime_file_dialog_save_file (title, filter, defaultPath));
				
			}
			
		});
		
		worker.onComplete.add (function (result) {
			
			switch (type) {
				
				case OPEN, OPEN_DIRECTORY, SAVE:
					
					var path:String = cast result;
					
					if (path != null) {
						
						// Makes sure the filename ends with extension
						if (type == SAVE && filter != null && path.indexOf (".") == -1) {
							
							path += "." + filter;
							
						}
						
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
	
	
	public function open (filter:String = null, defaultPath:String = null, title:String = null):Bool {
		
		#if desktop
		
		var worker = new BackgroundWorker ();
		
		worker.doWork.add (function (_) {
			
			#if linux
			if (title == null) title = "Open File";
			#end
			
			worker.sendComplete (NativeCFFI.lime_file_dialog_open_file (title, filter, defaultPath));
			
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
	
	
	public function save (data:Resource, filter:String = null, defaultPath:String = null, title:String = null):Bool {
		
		#if desktop
		
		var worker = new BackgroundWorker ();
		
		worker.doWork.add (function (_) {
			
			#if linux
			if (title == null) title = "Save File";
			#end
			
			worker.sendComplete (NativeCFFI.lime_file_dialog_save_file (title, filter, defaultPath));
			
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