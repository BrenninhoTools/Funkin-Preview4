package funkin.external.android;

#if android
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.zip.Entry;
import sys.FileSystem;
import sys.io.File;

class FileDialogUtil
{
  static final CLASS_NAME:String = 'funkin/extensions/FileDialogExtension';

  static var initialized:Bool = false;

  static var pendingSave:Null<String->Void> = null;
  static var pendingSaveCancel:Null<Void->Void> = null;
  static var pendingOpen:Null<String->Void> = null;
  static var pendingOpenCancel:Null<Void->Void> = null;

  public static function saveBytes(fileName:String, data:Bytes, ?mimeType:String, ?onSave:String->Void, ?onCancel:Void->Void):Void
  {
    init();

    final source:String = Path.join([tempFolder('save'), Path.withoutDirectory(fileName)]);
    File.saveBytes(source, data);

    pendingSave = onSave;
    pendingSaveCancel = onCancel;

    final saveFileJNI:Null<Dynamic> = JNIUtil.createStaticMethod(CLASS_NAME, 'saveFile', '(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V');
    if (saveFileJNI == null)
    {
      finishSave(null);
      return;
    }
    saveFileJNI(source, Path.withoutDirectory(fileName), mimeType ?? 'application/octet-stream');
  }

  public static function saveEntries(entries:Array<Entry>, ?onSave:String->Void, ?onCancel:Void->Void):Void
  {
    init();

    final folder:String = tempFolder('folder');
    clearFolder(folder);

    for (entry in entries)
    {
      if (entry.data == null) continue;
      final target:String = Path.join([folder, entry.fileName]);
      final directory:String = Path.directory(target);
      if (!FileSystem.exists(directory)) FileSystem.createDirectory(directory);
      File.saveBytes(target, entry.data);
    }

    pendingSave = onSave;
    pendingSaveCancel = onCancel;

    final saveFolderJNI:Null<Dynamic> = JNIUtil.createStaticMethod(CLASS_NAME, 'saveFolder', '(Ljava/lang/String;)V');
    if (saveFolderJNI == null)
    {
      finishSave(null);
      return;
    }
    saveFolderJNI(folder);
  }

  public static function openFile(?mimeType:String, ?onOpen:String->Void, ?onCancel:Void->Void):Void
  {
    init();

    pendingOpen = onOpen;
    pendingOpenCancel = onCancel;

    final openFileJNI:Null<Dynamic> = JNIUtil.createStaticMethod(CLASS_NAME, 'openFile', '(Ljava/lang/String;)V');
    if (openFileJNI == null)
    {
      finishOpen(null);
      return;
    }
    openFileJNI(mimeType ?? '*/*');
  }

  public static function writeBytesToUri(uri:String, data:Bytes):Bool
  {
    final source:String = Path.join([tempFolder('write'), 'pending']);
    File.saveBytes(source, data);

    final writeFileJNI:Null<Dynamic> = JNIUtil.createStaticMethod(CLASS_NAME, 'writeFile', '(Ljava/lang/String;Ljava/lang/String;)Z');
    return writeFileJNI != null && writeFileJNI(source, uri) == true;
  }

  public static inline function isContentUri(path:Null<String>):Bool
  {
    return path != null && StringTools.startsWith(path, 'content://');
  }

  static function init():Void
  {
    if (initialized) return;
    initialized = true;

    CallbackUtil.onFileSaved.add((uri:String) -> finishSave(uri));
    CallbackUtil.onFileSaveFailed.add((_) -> finishSave(null));
    CallbackUtil.onFileSaveCancelled.add(() -> finishSave(null));
    CallbackUtil.onFileOpened.add((path:String) -> finishOpen(path));
    CallbackUtil.onFileOpenCancelled.add(() -> finishOpen(null));
  }

  static function finishSave(uri:Null<String>):Void
  {
    final onSave:Null<String->Void> = pendingSave;
    final onCancel:Null<Void->Void> = pendingSaveCancel;
    pendingSave = null;
    pendingSaveCancel = null;

    if (uri != null)
    {
      if (onSave != null) onSave(uri);
    }
    else if (onCancel != null)
    {
      onCancel();
    }
  }

  static function finishOpen(path:Null<String>):Void
  {
    final onOpen:Null<String->Void> = pendingOpen;
    final onCancel:Null<Void->Void> = pendingOpenCancel;
    pendingOpen = null;
    pendingOpenCancel = null;

    if (path != null)
    {
      if (onOpen != null) onOpen(path);
    }
    else if (onCancel != null)
    {
      onCancel();
    }
  }

  static function tempFolder(name:String):String
  {
    final cache:String = androidmanager.content.Context.getCacheDir() ?? Sys.getCwd();
    final folder:String = Path.join([cache, 'file-dialog', name]);
    if (!FileSystem.exists(folder)) FileSystem.createDirectory(folder);
    return folder;
  }

  static function clearFolder(folder:String):Void
  {
    for (name in FileSystem.readDirectory(folder))
    {
      final path:String = Path.join([folder, name]);
      if (FileSystem.isDirectory(path))
      {
        clearFolder(path);
        FileSystem.deleteDirectory(path);
      }
      else
      {
        FileSystem.deleteFile(path);
      }
    }
  }
}
#end
