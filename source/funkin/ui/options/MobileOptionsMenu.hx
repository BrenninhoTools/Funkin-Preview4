package funkin.ui.options;

#if mobile
import funkin.touch.ui.FunkinHitbox.FunkinHitboxControlSchemes;
#if android
import funkin.util.mobile.StorageUtil;
import funkin.util.mobile.StorageUtil.StorageType;
#end

class MobileOptionsMenu extends PreferencesMenu
{
  override function createPrefItems():Void
  {
    createPrefItemEnum('Hitbox Mode', 'Choose how the hitbox is laid out during gameplay.', [
      "Four Lanes" => FunkinHitboxControlSchemes.FourLanes,
      "Arrows" => FunkinHitboxControlSchemes.Arrows
    ], function(key:String, value:FunkinHitboxControlSchemes):Void
    {
      Preferences.controlsScheme = value;
    }, Preferences.controlsScheme == FunkinHitboxControlSchemes.FourLanes ? "Four Lanes" : "Arrows");
    createPrefItemCheckbox('Invisible Hitbox', 'When enabled, the hitbox is hidden but still works.', function(value:Bool):Void
    {
      Preferences.invisibleHitbox = value;
    }, Preferences.invisibleHitbox);
    createPrefItemCheckbox('Invisible Pause Button', 'When enabled, the pause button is hidden but still works.', function(value:Bool):Void
    {
      Preferences.invisiblePauseButton = value;
    }, Preferences.invisiblePauseButton);
    #if FEATURE_CHART_EDITOR
    createPrefItemCheckbox('Chart Editor in Pause', 'When enabled, the pause menu shows an option to open the Chart Editor.', function(value:Bool):Void
    {
      Preferences.chartEditorInPause = value;
    }, Preferences.chartEditorInPause);
    #end
    createPrefItemCheckbox('Touch Cursor', 'When enabled, Kevin and Michael follow your fingers on the screen.', function(value:Bool):Void
    {
      Preferences.touchCursor = value;
    }, Preferences.touchCursor);
    createPrefItemEnum('Screen Style', 'Original keeps the 16:9 screen, Full fills the whole screen without stretching.', [
      "Original" => "Original",
      "Full" => "Full"
    ], function(key:String, value:String):Void
    {
      Preferences.screenStyle = value;
    }, Preferences.screenStyle == "Full" ? "Full" : "Original");
    #if android
    createPrefItemEnum('Storage Type', 'Where mods, charts and backups are kept. External uses the .FNFPreview4 folder.', [
      "Data" => StorageType.Data,
      "Media" => StorageType.Media,
      "Obb" => StorageType.Obb,
      "External" => StorageType.External
    ], function(key:String, value:StorageType):Void
    {
      StorageUtil.switchTo(value);
    }, Std.string(StorageUtil.storageType));
    #end
  }
}
#end
