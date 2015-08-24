package lime.ui;


import lime.app.Event;
import lime.system.BackgroundWorker;
import lime.system.System;
import lime.utils.Resource;

#if sys
import sys.io.File;
#end


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
					
					worker.sendComplete (lime_file_dialog_open_file (filter, defaultPath));
				
				case OPEN_MULTIPLE:
					
					worker.sendComplete (lime_file_dialog_open_files (filter, defaultPath));
				
				case SAVE:
					
					worker.sendComplete (lime_file_dialog_save_file (filter, defaultPath));
				
			}
			
		});
		
		worker.onComplete.add (function (result) {
			
			switch (type) {
				
				case OPEN, SAVE:
					
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
			
			worker.sendComplete (lime_file_dialog_open_file (filter, defaultPath));
			
		});
		
		worker.onComplete.add (function (path) {
			
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
			
			worker.sendComplete (lime_file_dialog_save_file (filter, defaultPath));
			
		});
		
		worker.onComplete.add (function (path) {
			
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
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_file_dialog_open_file = System.load ("lime", "lime_file_dialog_open_file", 2);
	private static var lime_file_dialog_open_files = System.load ("lime", "lime_file_dialog_open_files", 2);
	private static var lime_file_dialog_save_file = System.load ("lime", "lime_file_dialog_save_file", 2);
	#end
	
	
}