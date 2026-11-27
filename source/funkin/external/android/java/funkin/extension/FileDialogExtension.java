package funkin.extensions;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.DocumentsContract;
import android.provider.OpenableColumns;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import org.haxe.extension.Extension;

public class FileDialogExtension extends Extension
{
  private static final int REQUEST_SAVE_FILE = 0x4601;
  private static final int REQUEST_OPEN_FILE = 0x4602;
  private static final int REQUEST_SAVE_FOLDER = 0x4603;

  private static String pendingSourcePath = null;

  public static void saveFile(String sourcePath, String fileName, String mimeType)
  {
    pendingSourcePath = sourcePath;

    Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
    intent.addCategory(Intent.CATEGORY_OPENABLE);
    intent.setType(mimeType == null || mimeType.isEmpty() ? "*/*" : mimeType);
    intent.putExtra(Intent.EXTRA_TITLE, fileName);
    start(intent, REQUEST_SAVE_FILE, "onFileSaveCancelled");
  }

  public static void saveFolder(String sourceFolderPath)
  {
    pendingSourcePath = sourceFolderPath;

    Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
    intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION | Intent.FLAG_GRANT_READ_URI_PERMISSION);
    start(intent, REQUEST_SAVE_FOLDER, "onFileSaveCancelled");
  }

  public static void openFile(String mimeType)
  {
    Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
    intent.addCategory(Intent.CATEGORY_OPENABLE);
    intent.setType(mimeType == null || mimeType.isEmpty() ? "*/*" : mimeType);
    start(intent, REQUEST_OPEN_FILE, "onFileOpenCancelled");
  }

  public static boolean writeFile(String sourcePath, String uriString)
  {
    try
    {
      copyFileToUri(new File(sourcePath), Uri.parse(uriString));
      return true;
    }
    catch (Exception e)
    {
      Log.e("FileDialogExtension", "Could not write the file", e);
      return false;
    }
  }

  private static void start(final Intent intent, final int requestCode, final String cancelCallback)
  {
    mainActivity.runOnUiThread(new Runnable()
    {
      @Override
      public void run()
      {
        try
        {
          mainActivity.startActivityForResult(intent, requestCode);
        }
        catch (Exception e)
        {
          Log.e("FileDialogExtension", "Could not open the file picker", e);
          CallbackUtil.callMethod(cancelCallback);
        }
      }
    });
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data)
  {
    if (requestCode != REQUEST_SAVE_FILE && requestCode != REQUEST_OPEN_FILE && requestCode != REQUEST_SAVE_FOLDER) return true;

    final Uri uri = (resultCode == Activity.RESULT_OK && data != null) ? data.getData() : null;
    final String sourcePath = pendingSourcePath;
    pendingSourcePath = null;

    switch (requestCode)
    {
      case REQUEST_SAVE_FILE:
        if (uri == null || sourcePath == null)
        {
          CallbackUtil.callMethod("onFileSaveCancelled");
          break;
        }
        try
        {
          copyFileToUri(new File(sourcePath), uri);
          CallbackUtil.callMethod("onFileSaved", uri.toString());
        }
        catch (IOException e)
        {
          Log.e("FileDialogExtension", "Could not save the file", e);
          CallbackUtil.callMethod("onFileSaveFailed", String.valueOf(e.getMessage()));
        }
        break;

      case REQUEST_SAVE_FOLDER:
        if (uri == null || sourcePath == null)
        {
          CallbackUtil.callMethod("onFileSaveCancelled");
          break;
        }
        try
        {
          mainContext.getContentResolver().takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
        }
        catch (Exception ignored)
        {
        }
        try
        {
          Uri root = DocumentsContract.buildDocumentUriUsingTree(uri, DocumentsContract.getTreeDocumentId(uri));
          copyFolderToTree(new File(sourcePath), root);
          CallbackUtil.callMethod("onFileSaved", uri.toString());
        }
        catch (Exception e)
        {
          Log.e("FileDialogExtension", "Could not save the folder", e);
          CallbackUtil.callMethod("onFileSaveFailed", String.valueOf(e.getMessage()));
        }
        break;

      case REQUEST_OPEN_FILE:
        if (uri == null)
        {
          CallbackUtil.callMethod("onFileOpenCancelled");
          break;
        }
        try
        {
          CallbackUtil.callMethod("onFileOpened", copyUriToCache(uri));
        }
        catch (IOException e)
        {
          Log.e("FileDialogExtension", "Could not open the file", e);
          CallbackUtil.callMethod("onFileOpenCancelled");
        }
        break;
    }

    return true;
  }

  private static void copyFileToUri(File source, Uri target) throws IOException
  {
    ContentResolver resolver = mainContext.getContentResolver();
    try (InputStream input = new FileInputStream(source); OutputStream output = resolver.openOutputStream(target, "wt"))
    {
      if (output == null) throw new IOException("Could not open " + target);
      copy(input, output);
    }
  }

  private static void copyFolderToTree(File source, Uri parent) throws Exception
  {
    File[] children = source.listFiles();
    if (children == null) return;

    ContentResolver resolver = mainContext.getContentResolver();
    for (File child : children)
    {
      if (child.isDirectory())
      {
        Uri folder = DocumentsContract.createDocument(resolver, parent, DocumentsContract.Document.MIME_TYPE_DIR, child.getName());
        if (folder != null) copyFolderToTree(child, folder);
      }
      else
      {
        Uri file = DocumentsContract.createDocument(resolver, parent, "application/octet-stream", child.getName());
        if (file != null) copyFileToUri(child, file);
      }
    }
  }

  private static String copyUriToCache(Uri uri) throws IOException
  {
    String name = queryName(uri);
    File folder = new File(mainContext.getCacheDir(), "picked");
    if (!folder.exists() && !folder.mkdirs()) throw new IOException("Could not create " + folder);

    File target = new File(folder, name);
    try (InputStream input = mainContext.getContentResolver().openInputStream(uri); OutputStream output = new FileOutputStream(target))
    {
      if (input == null) throw new IOException("Could not read " + uri);
      copy(input, output);
    }
    return target.getAbsolutePath();
  }

  private static String queryName(Uri uri)
  {
    String name = null;
    try (Cursor cursor = mainContext.getContentResolver().query(uri, new String[] {OpenableColumns.DISPLAY_NAME}, null, null, null))
    {
      if (cursor != null && cursor.moveToFirst()) name = cursor.getString(0);
    }
    catch (Exception ignored)
    {
    }

    if (name == null || name.isEmpty()) name = "picked-" + System.currentTimeMillis();
    return name.replace('/', '_');
  }

  private static void copy(InputStream input, OutputStream output) throws IOException
  {
    byte[] buffer = new byte[65536];
    int read;
    while ((read = input.read(buffer)) != -1)
      output.write(buffer, 0, read);
    output.flush();
  }
}
