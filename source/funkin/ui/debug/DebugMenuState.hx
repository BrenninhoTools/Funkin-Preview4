package funkin.ui.debug;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.typeLimit.NextState;
import funkin.assets.Paths;
import funkin.audio.FunkinSound;
import funkin.graphics.shaders.HSVShader;
import funkin.ui.MusicBeatState;
import funkin.ui.TextMenuList;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.transition.Transition;

class DebugMenuState extends MusicBeatState
{
  static final CAMERA_MARGIN:Int = 150;

  static var rememberedSelectedIndex:Int = 0;

  var items:TextMenuList;
  var camFocusPoint:FlxObject;
  var leaving:Bool = false;

  public function new()
  {
    super();
  }

  override function create():Void
  {
    persistentUpdate = true;

    var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/main-menu/menu-bg').toFlxGraphicAsset());
    menuBG.shader = new HSVShader(0.4, 0.6, 1.2);
    menuBG.setGraphicSize(Std.int(FlxG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    add(items = new TextMenuList());

    #if FEATURE_CHART_EDITOR
    createItem('CHART EDITOR', () -> openEditor(() -> new funkin.ui.debug.charting.ChartEditorState(), funkin.ui.debug.charting.ChartEditorState.queryAssets.bind(_, null)));
    #end
    #if FEATURE_ANIMATION_EDITOR
    createItem('ANIMATION EDITOR', () -> openEditor(() -> new funkin.ui.debug.anim.DebugBoundingState(), Transition.NO_ASSETS));
    #end
    #if FEATURE_STAGE_EDITOR
    createItem('STAGE EDITOR', () -> openEditor(() -> new funkin.ui.debug.stageeditor.StageEditorState(), Transition.NO_ASSETS));
    #end
    #if FEATURE_CAMERA_EDITOR
    createItem('CAMERA EDITOR', () -> openEditor(() -> new funkin.ui.debug.cameraeditor.CameraEditorState(), Transition.NO_ASSETS));
    #end
    #if !FEATURE_TOUCH_CONTROLS
    createItem('EXIT', exit);
    #end

    camFocusPoint = new FlxObject(0, 0, 140, 70);
    add(camFocusPoint);

    FlxG.camera.follow(camFocusPoint, null, 0.085);
    FlxG.camera.deadzone.set(0, CAMERA_MARGIN / 2, FlxG.camera.width, FlxG.camera.height - CAMERA_MARGIN + 40);
    FlxG.camera.minScrollY = -CAMERA_MARGIN / 2;

    items.onChange.add(onMenuChange);
    if (items.length > 0)
    {
      items.selectItem(Std.int(Math.min(rememberedSelectedIndex, items.length - 1)));
      onMenuChange(items.selectedItem);
    }

    super.create();

    #if FEATURE_TOUCH_CONTROLS
    addBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, exit, 1.0);
    backButton?.onConfirmStart.add(() ->
    {
      items.busy = true;
      leaving = true;
    });
    #end
  }

  function createItem(name:String, callback:Void->Void):TextMenuItem
  {
    var item:TextMenuItem = items.createItem(0, 100 + items.length * 100, name, BOLD, callback);
    item.screenCenter(X);
    return item;
  }

  function onMenuChange(selected:TextMenuItem):Void
  {
    camFocusPoint.y = selected.y;
  }

  function openEditor(state:NextState, assetQuery:(funkin.assets.Assets.AssetType) -> Array<funkin.assets.Paths.AssetPath>):Void
  {
    if (leaving) return;
    leaving = true;
    items.busy = true;
    rememberedSelectedIndex = items.selectedIndex;

    funkin.ui.quickpanel.QuickPanelState.stopMusic();
    Transition.switchState(state, {
      transition: Throbber,
      assetQuery: assetQuery
    });
  }

  function exit():Void
  {
    leaving = true;
    items.busy = true;
    rememberedSelectedIndex = items.selectedIndex;

    Transition.switchState(() -> new MainMenuState(), {
      transition: BlackScreen(Fade(North), Fade(South)),
      assetQuery: MainMenuState.queryAssets
    });
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (leaving) return;

    var androidBack:Bool = #if android FlxG.android.justReleased.BACK #else false #end;
    if (controls.BACK || androidBack)
    {
      FunkinSound.playOnce(funkin.assets.ValidatedPaths.sound('ui/main-menu/cancel-menu').toString());
      exit();
    }
  }
}
