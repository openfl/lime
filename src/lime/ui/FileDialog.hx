package lime.ui;

import haxe.io.Bytes;
import haxe.io.Path;
import lime._internal.backend.native.NativeCFFI;
import lime.app.Event;
import lime.graphics.Image;
import lime.system.BackgroundWorker;
import lime.utils.ArrayBuffer;
import lime.utils.Resource;
#if hl
import hl.Bytes as HLBytes;
import hl.NativeArray;
#end
#if sys
import sys.io.File;
#end
#if (js && html5)
import js.html.Blob;
#end

/**
	Simple file dialog used for asking user where to save a file, or select
	files to open.

	Example usage:
	```haxe
	var fileDialog = new FileDialog();

	fileDialog.onCancel.add( () -> trace("Canceled.") );

	fileDialog.onSave.add( path -> trace("File saved in " + path) );

	fileDialog.onOpen.add( res -> trace("Size of the file = " + cast(res, haxe.io.Bytes).length) );

	if ( fileDialog.open("jpg", null, "Load file") )
		trace("Triggered opening file");
	else
		trace("This dialog is unsupported.");
	```
**/

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.graphics.Image)
class FileDialog
{

	/**
		Handles clicking the "Cancel" button by the user. It is also triggered on unsupported platforms (like HTML5 for `open()`).
	**/
	public var onCancel = new Event<Void->Void>();

	/**
		Triggers when file was successfuly opened. `lime.utils.Resource` is the argument passed
		which in essence is `haxe.io.Bytes` of the selected file's contents. Triggers only when used with `open()`.
	**/
	public var onOpen = new Event<Resource->Void>();

	/**
		Triggers when file was successfuly saved by the user. Argument is `String` - the path under which the file was saved.
		Triggers only when used with `save()`.
	**/
	public var onSave = new Event<String->Void>();

	/**
		Selected single file from `browse()`. Passes `String` path to the file.
	**/
	public var onSelect = new Event<String->Void>();

	/**
		Is called with array of selected file paths from `browse()` with `FileDialogType.OPEN_MULTIPLE`.
	**/
	public var onSelectMultiple = new Event<Array<String>->Void>();


	public function new() {}

	/**
		Opens a file dialog that will trigger either `onSelect` or `onSelectMultiple` returting path(s) to file(s).
		@param type 		type of the file dialog: `OPEN`, `SAVE`, `OPEN_DIRECTORY` or `OPEN_MULTIPLE`.
		@param filter 		filter to be used when browsing for the file. For example for `"*.jpg"` it will be `"jpg"`.
		@param defaultPath 	directory in which to start browsing. Default is current working directory of the application.
		@param title 		title to give the dialog window.
		@return `false` if the dialog is unsupported.
	**/
	public function browse(type:FileDialogType = null, filter:String = null, defaultPath:String = null, title:String = null):Bool
	{
		if (type == null) type = FileDialogType.OPEN;

		#if desktop
		var worker = new BackgroundWorker();

		worker.doWork.add(function(_)
		{
			switch (type)
			{
				case OPEN:
					#if linux
					if (title == null) title = "Open File";
					#end

					var path = null;
					#if hl
					var bytes = NativeCFFI.lime_file_dialog_open_file(title, filter, defaultPath);
					path = @:privateAccess String.fromUTF8(cast bytes);
					#else
					path = NativeCFFI.lime_file_dialog_open_file(title, filter, defaultPath);
					#end

					worker.sendComplete(path);

				case OPEN_MULTIPLE:
					#if linux
					if (title == null) title = "Open Files";
					#end

					var paths = null;
					#if hl
					var bytes:NativeArray<HLBytes> = cast NativeCFFI.lime_file_dialog_open_files(title, filter, defaultPath);
					if (bytes != null)
					{
						paths = [];
						for (i in 0...bytes.length)
						{
							paths[i] = @:privateAccess String.fromUTF8(bytes[i]);
						}
					}
					#else
					paths = NativeCFFI.lime_file_dialog_open_files(title, filter, defaultPath);
					#end

					worker.sendComplete(paths);

				case OPEN_DIRECTORY:
					#if linux
					if (title == null) title = "Open Directory";
					#end

					var path = null;
					#if hl
					var bytes = NativeCFFI.lime_file_dialog_open_directory(title, filter, defaultPath);
					path = @:privateAccess String.fromUTF8(cast bytes);
					#else
					path = NativeCFFI.lime_file_dialog_open_directory(title, filter, defaultPath);
					#end

					worker.sendComplete(path);

				case SAVE:
					#if linux
					if (title == null) title = "Save File";
					#end

					var path = null;
					#if hl
					var bytes = NativeCFFI.lime_file_dialog_save_file(title, filter, defaultPath);
					path = @:privateAccess String.fromUTF8(cast bytes);
					#else
					path = NativeCFFI.lime_file_dialog_save_file(title, filter, defaultPath);
					#end

					worker.sendComplete(path);
			}
		});

		worker.onComplete.add(function(result)
		{
			switch (type)
			{
				case OPEN, OPEN_DIRECTORY, SAVE:
					var path:String = cast result;

					if (path != null)
					{
						// Makes sure the filename ends with extension
						if (type == SAVE && filter != null && path.indexOf(".") == -1)
						{
							path += "." + filter;
						}

						onSelect.dispatch(path);
					}
					else
					{
						onCancel.dispatch();
					}

				case OPEN_MULTIPLE:
					var paths:Array<String> = cast result;

					if (paths != null && paths.length > 0)
					{
						onSelectMultiple.dispatch(paths);
					}
					else
					{
						onCancel.dispatch();
					}
			}
		});

		worker.run();

		return true;
		#else
		onCancel.dispatch();
		return false;
		#end
	}

	/**
		Shows an open file dialog and immediately returns the contents of the file in `onOpen` listeners.
		@param 	filter 		filter to be used when browsing for the file. For example for `"*.jpg"` it will be `"jpg"`.
		@param 	defaultPath directory in which to start browsing. Default is current working directory of the application.
		@param 	title 		title to give the dialog window.
		@return `false` if the dialog is unsupported.
	**/
	public function open(filter:String = null, defaultPath:String = null, title:String = null):Bool
	{
		#if desktop
		var worker = new BackgroundWorker();

		worker.doWork.add(function(_)
		{
			#if linux
			if (title == null) title = "Open File";
			#end

			var path = null;
			#if hl
			var bytes = NativeCFFI.lime_file_dialog_open_file(title, filter, defaultPath);
			path = @:privateAccess String.fromUTF8(cast bytes);
			#else
			path = NativeCFFI.lime_file_dialog_open_file(title, filter, defaultPath);
			#end

			worker.sendComplete(path);
		});

		worker.onComplete.add(function(path:String)
		{
			if (path != null)
			{
				try
				{
					var data = File.getBytes(path);
					onOpen.dispatch(data);
					return;
				}
				catch (e:Dynamic) {}
			}

			onCancel.dispatch();
		});

		worker.run();

		return true;
		#else
		onCancel.dispatch();
		return false;
		#end
	}

	/**
		Asks the user where to save the `data`. Will return path of the saved file in `onSave`.
		@param filter filter to be used when browsing for the file. For example for `"*.jpg"` it will be `"jpg"`.
		@param defaultPath directory in which to start browsing. Default is current working directory of the application.
		@param title title to give the dialog window.
		@param type MIME type of the file. Used only on HTML5 targets.
		@return `false` if the dialog is unsupported.
	**/
	public function save(data:Resource, filter:String = null, defaultPath:String = null, title:String = null, type:String = "application/octet-stream"):Bool
	{
		if (data == null)
		{
			onCancel.dispatch();
			return false;
		}

		#if desktop
		var worker = new BackgroundWorker();

		worker.doWork.add(function(_)
		{
			#if linux
			if (title == null) title = "Save File";
			#end

			var path = null;
			#if hl
			var bytes = NativeCFFI.lime_file_dialog_save_file(title, filter, defaultPath);
			path = @:privateAccess String.fromUTF8(cast bytes);
			#else
			path = NativeCFFI.lime_file_dialog_save_file(title, filter, defaultPath);
			#end

			worker.sendComplete(path);
		});

		worker.onComplete.add(function(path:String)
		{
			if (path != null)
			{
				try
				{
					File.saveBytes(path, data);
					onSave.dispatch(path);
					return;
				}
				catch (e:Dynamic) {}
			}

			onCancel.dispatch();
		});

		worker.run();

		return true;
		#elseif (js && html5)
		// TODO: Cleaner API for mimeType detection

		var defaultExtension = "";

		if (Image.__isPNG(data))
		{
			type = "image/png";
			defaultExtension = ".png";
		}
		else if (Image.__isJPG(data))
		{
			type = "image/jpeg";
			defaultExtension = ".jpg";
		}
		else if (Image.__isGIF(data))
		{
			type = "image/gif";
			defaultExtension = ".gif";
		}
		else if (Image.__isWebP(data))
		{
			type = "image/webp";
			defaultExtension = ".webp";
		}

		var path = defaultPath != null ? Path.withoutDirectory(defaultPath) : "download" + defaultExtension;
		var buffer = (data : Bytes).getData();
		buffer = buffer.slice(0, (data : Bytes).length);

		#if commonjs
		untyped #if haxe4 js.Syntax.code #else __js__ #end ("require ('file-saver')")(new Blob([buffer], {type: type}), path, true);
		#else
		untyped window.saveAs(new Blob([buffer], {type: type}), path, true);
		#end
		onSave.dispatch(path);
		return true;
		#else
		onCancel.dispatch();
		return false;
		#end
	}
}
