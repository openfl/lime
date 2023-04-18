package lime.system;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;
import lime.app.Application;
import lime.app.Event;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class FileWatcher
{
	public var onAdd = new Event<String->Void>();
	public var onDelete = new Event<String->Void>();
	public var onModify = new Event<String->Void>();
	public var onMove = new Event<String->String->Void>();

	@:noCompletion private var handle:CFFIPointer;
	@:noCompletion private var __hasUpdate:Bool;
	@:noCompletion private var __ids:Map<String, Int>;

	public function new()
	{
		#if (lime_cffi && !macro)
		handle = NativeCFFI.lime_file_watcher_create(this_onChange);
		__ids = new Map();
		#end
	}

	public function addDirectory(path:String, recursive:Bool = true):Bool
	{
		#if (lime_cffi && !macro)
		if (!__hasUpdate && Application.current != null)
		{
			Application.current.onUpdate.add(this_onUpdate);
			__hasUpdate = true;
		}

		var id:Int = NativeCFFI.lime_file_watcher_add_directory(handle, path, recursive);

		if (id >= 0)
		{
			__ids[path] = id;
			return true;
		}
		else
		{
			// throw error?
			// FileNotFound	= -1,
			// FileRepeated	= -2,
			// FileOutOfScope	= -3,
			// FileNotReadable	= -4,
			// FileRemote		= -5, /** Directory in remote file system ( create a generic FileWatcher instance to watch this directory ). */
		}
		#end

		return false;
	}

	@:noCompletion private function combine(directory:String, file:String):String
	{
		var trailingSlash = (directory.substr(-1) == "/" || directory.substr(-1) == "\\");
		var startingSlash = (file.substr(0, 1) == "/" || file.substr(0, 1) == "\\");
		var path;

		if (trailingSlash && startingSlash)
		{
			path = directory + file.substr(1);
		}
		else if (!trailingSlash && !startingSlash)
		{
			path = directory + #if windows "\\" #else "/" #end + file;
		}
		else
		{
			path = directory + file;
		}

		return path;
	}

	public function removeDirectory(path:String):Bool
	{
		#if (lime_cffi && !macro)
		if (__ids.exists(path))
		{
			NativeCFFI.lime_file_watcher_remove_directory(handle, __ids[path]);
			__ids.remove(path);

			if (!__ids.keys().hasNext())
			{
				Application.current.onUpdate.remove(this_onUpdate);
				__hasUpdate = false;
			}

			return true;
		}
		#end

		return false;
	}

	@:noCompletion private function this_onChange(directory:String, file:String, action:Int, oldFile:String):Void
	{
		var path = combine(directory, file);

		switch (action)
		{
			case 1:
				onAdd.dispatch(path);

			case 2:
				onDelete.dispatch(path);

			case 3:
				onModify.dispatch(path);

			case 4:
				onMove.dispatch(combine(directory, oldFile), path);
		}
	}

	@:noCompletion private function this_onUpdate(_):Void
	{
		#if (lime_cffi && !macro)
		NativeCFFI.lime_file_watcher_update(handle);
		#end
	}
}
#end
