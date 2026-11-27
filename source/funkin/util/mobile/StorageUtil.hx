package funkin.util.mobile;

#if android
import androidmanager.content.Context;
import androidmanager.os.Build.VERSION;
import androidmanager.os.Environment;
import androidmanager.tools.Permission;
import androidmanager.tools.PermissionUtils;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

using StringTools;

enum abstract StorageType(String) from String to String
{
  public var Data = 'Data';
  public var External = 'External';
}

class StorageUtil
{
  public static final EXTERNAL_FOLDER:String = '.FNFPreview4';

  static final CONFIG_FILE:String = 'storage-type.txt';

  static final COPIED_FOLDERS:Array<String> = ['mods', 'charts', 'backups'];

  public static var storageType(get, set):StorageType;

  static function configPath():Null<String>
  {
    final filesDir:Null<String> = Context.getFilesDir();
    return filesDir == null ? null : Path.join([filesDir, CONFIG_FILE]);
  }

  static function get_storageType():StorageType
  {
    final path:Null<String> = configPath();
    if (path == null || !FileSystem.exists(path)) return Data;

    try
    {
      return File.getContent(path).trim() == External ? External : Data;
    }
    catch (e)
    {
      return Data;
    }
  }

  static function set_storageType(value:StorageType):StorageType
  {
    final path:Null<String> = configPath();
    if (path != null)
    {
      try
      {
        File.saveContent(path, value);
      }
      catch (e) {}
    }
    return value;
  }

  public static function getDirectory(type:StorageType):String
  {
    final dataDir:String = Context.getExternalFilesDir() ?? Sys.getCwd();
    if (type == External)
    {
      final root:Null<String> = Environment.getExternalStorageDirectory();
      if (root != null && root.length > 0) return Path.addTrailingSlash(Path.join([root, EXTERNAL_FOLDER]));
    }
    return Path.addTrailingSlash(dataDir);
  }

  public static function hasExternalAccess():Bool
  {
    if (VERSION.SDK_INT >= 30) return PermissionUtils.isExternalStorageManager();
    return PermissionUtils.hasPermissions([Permission.READ_EXTERNAL_STORAGE, Permission.WRITE_EXTERNAL_STORAGE]);
  }

  public static function requestExternalAccess(callback:Bool->Void):Void
  {
    if (hasExternalAccess())
    {
      callback(true);
      return;
    }

    if (VERSION.SDK_INT >= 30)
    {
      PermissionUtils.requestManageExternalStorage(callback);
    }
    else
    {
      PermissionUtils.requestPermissions([Permission.READ_EXTERNAL_STORAGE, Permission.WRITE_EXTERNAL_STORAGE], (result) -> callback(result.denied.length == 0));
    }
  }

  public static function currentDirectory():String
  {
    final type:StorageType = storageType;
    if (type == External && !hasExternalAccess()) return getDirectory(Data);
    return getDirectory(type);
  }

  public static function applyWorkingDirectory():Void
  {
    final target:String = currentDirectory();

    try
    {
      if (!FileSystem.exists(target)) FileSystem.createDirectory(target);
      if (Path.addTrailingSlash(Sys.getCwd()) != target) Sys.setCwd(target);
    }
    catch (e)
    {
      final fallback:String = getDirectory(Data);
      if (!FileSystem.exists(fallback)) FileSystem.createDirectory(fallback);
      Sys.setCwd(fallback);
    }
  }

  public static function switchTo(type:StorageType):Void
  {
    final previous:String = Path.addTrailingSlash(Sys.getCwd());
    storageType = type;

    if (type == External)
    {
      requestExternalAccess(function(granted:Bool):Void
      {
        if (granted)
        {
          move(previous);
        }
        else
        {
          androidmanager.widget.Toast.makeText('Storage access denied, using Data.');
        }
      });
    }
    else
    {
      move(previous);
    }
  }

  static function move(previous:String):Void
  {
    applyWorkingDirectory();

    final current:String = Path.addTrailingSlash(Sys.getCwd());
    if (current == previous) return;

    for (folder in COPIED_FOLDERS)
    {
      final source:String = Path.join([previous, folder]);
      final destination:String = Path.join([current, folder]);
      if (FileSystem.exists(source) && !FileSystem.exists(destination))
      {
        try
        {
          funkin.util.FileUtil.copyDirectory(source, destination);
        }
        catch (e) {}
      }
    }

    androidmanager.widget.Toast.makeText('Storage set to ' + current);
  }
}
#end
