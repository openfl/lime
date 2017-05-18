/*
 * Copyright (C)2005-2016 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package haxelib.client;

import haxe.io.Path;
import sys.FileSystem;
using StringTools;

class FsUtils {
    static var IS_WINDOWS = (Sys.systemName() == "Windows");

    //recursively follow symlink
    public static function realPath(path:String):String {
        var proc = new sys.io.Process('readlink', [path.endsWith("\n") ? path.substr(0, path.length-1) : path]);
        var ret = switch (proc.stdout.readAll().toString()) {
            case "": //it is not a symlink
                path;
            case targetPath:
                if (targetPath.startsWith("/")) {
                    realPath(targetPath);
                } else {
                    realPath(new Path(path).dir + "/" + targetPath);
                }
        }
        proc.close();
        return ret;
    }

    public static function isSamePath(a:String, b:String):Bool {
        a = Path.normalize(a);
        b = Path.normalize(b);
        if (IS_WINDOWS) { // paths are case-insensitive on Windows
            a = a.toLowerCase();
            b = b.toLowerCase();
        }
        return a == b;
    }

    public static function safeDir(dir:String, checkWritable = false):Bool {
        if (FileSystem.exists(dir)) {
            if (!FileSystem.isDirectory(dir))
                throw 'A file is preventing $dir to be created';
            if (checkWritable) {
                var checkFile = dir+"/haxelib_writecheck.txt";
                try {
                    sys.io.File.saveContent(checkFile, "This is a temporary file created by Haxelib to check if directory is writable. You can safely delete it!");
                } catch (_:Dynamic) {
                    throw '$dir exists but is not writeable, chmod it';
                }
                FileSystem.deleteFile(checkFile);
            }
            return false;
        } else {
            try {
                FileSystem.createDirectory(dir);
                return true;
            } catch (_:Dynamic) {
                throw 'You don\'t have enough user rights to create the directory $dir';
            }
        }
    }

    public static function deleteRec(dir:String):Bool {
        if (!FileSystem.exists(dir))
            return false;
        for (p in FileSystem.readDirectory(dir)) {
            var path = Path.join([dir, p]);

            if (isBrokenSymlink(path)) {
                safeDelete(path);
            } else if (FileSystem.isDirectory(path)) {
                if (!IS_WINDOWS) {
                    // try to delete it as a file first - in case of path
                    // being a symlink, it will success
                    if (!safeDelete(path))
                        deleteRec(path);
                } else {
                    deleteRec(path);
                }
            } else {
                safeDelete(path);
            }
        }
        FileSystem.deleteDirectory(dir);
        return true;
    }

    static function safeDelete(file:String):Bool {
        try {
            FileSystem.deleteFile(file);
            return true;
        } catch (e:Dynamic) {
            if (IS_WINDOWS) {
                try {
                    Sys.command("attrib", ["-R", file]);
                    FileSystem.deleteFile(file);
                    return true;
                } catch (_:Dynamic) {
                }
            }
            return false;
        }
    }

    static function isBrokenSymlink(path:String):Bool {
        // TODO: figure out what this method actually does :)
        var errors = 0;
        try FileSystem.isDirectory(path) catch (error:String) if (error == "std@sys_file_type") errors++;
        try FileSystem.fullPath(path) catch (error:String) if (error == "std@file_full_path") errors++;
        return errors == 2;
    }
}
