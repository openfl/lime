package lime.ui;


import lime.app.Event;
import lime.system.BackgroundWorker;
import lime.utils.Resource;

#if sys
import sys.io.File;
#end

#if !macro
@:build(lime.system.CFFI.build())
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
		#if !mac
		
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
		
		#else
		
		var path:String = null;
		var paths:Array<String> = null;
		
		switch (type) {
				
			case OPEN:
				
				path = lime_file_dialog_open_file (filter, defaultPath);
			
			case OPEN_MULTIPLE:
				
				paths = lime_file_dialog_open_files (filter, defaultPath);
			
			case SAVE:
				
				path = lime_file_dialog_save_file (filter, defaultPath);
			
		}
			
		switch (type) {
			
			case OPEN, SAVE:
				
				if (path != null) {
					
					onSelect.dispatch (path);
					
				} else {
					
					onCancel.dispatch ();
					
				}
			
			case OPEN_MULTIPLE:
				
				if (paths != null && paths.length > 0) {
					
					onSelectMultiple.dispatch (paths);
					
				} else {
					
					onCancel.dispatch ();
					
				}
			
		}
		
		#end
		
		return true;
		
		#else
		
		onCancel.dispatch ();
		return false;
		
		#end
		
	}
	
	
	public function open (filter:String = null, defaultPath:String = null):Bool {
		
		#if desktop
		#if !mac
		
		var worker = new BackgroundWorker ();
		
		worker.doWork.add (function (_) {
			
			worker.sendComplete (lime_file_dialog_open_file (filter, defaultPath));
			
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
		
		#else
		
		// Doesn't work in a thread
		
		var path:String = lime_file_dialog_open_file (filter, defaultPath);
		
		if (path != null) {
			
			try {
				
				var data = File.getBytes (path);
				onOpen.dispatch (data);
				return true;
				
			} catch (e:Dynamic) {}
			
		}
		
		onCancel.dispatch ();
		
		#end
		
		return true;
		
		#else
		
		onCancel.dispatch ();
		return false;
		
		#end
		
	}
	
	
	public function save (data:Resource, filter:String = null, defaultPath:String = null):Bool {
		
		#if desktop
		#if !mac
		
		var worker = new BackgroundWorker ();
		
		worker.doWork.add (function (_) {
			
			worker.sendComplete (lime_file_dialog_save_file (filter, defaultPath));
			
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
		
		#else
		
		var path:String = lime_file_dialog_save_file (filter, defaultPath);
		
		if (path != null) {
			
			try {
				
				File.saveBytes (path, data);
				onSave.dispatch (path);
				return true;
				
			} catch (e:Dynamic) {}
			
		}
		
		onCancel.dispatch ();
		
		#end
		
		return true;
		
		#else
		
		onCancel.dispatch ();
		return false;
		
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	@:cffi private static function lime_file_dialog_open_file (filter:String, defaultPath:String):Dynamic;
	@:cffi private static function lime_file_dialog_open_files (filter:String, defaultPath:String):Dynamic;
	@:cffi private static function lime_file_dialog_save_file (filter:String, defaultPath:String):Dynamic;
	#end
	
	
}