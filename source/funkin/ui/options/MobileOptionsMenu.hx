package funkin.ui.options;

#if mobile
import funkin.touch.ui.FunkinHitbox.FunkinHitboxControlSchemes;

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
    createPrefItemCheckbox('Touch Cursor', 'When enabled, a cursor follows your finger on the screen.', function(value:Bool):Void
    {
      Preferences.touchCursor = value;
    }, Preferences.touchCursor);
  }
}
#end
