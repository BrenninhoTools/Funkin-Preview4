package funkin.util;

import flixel.FlxG;

class TouchGestureUtil
{
  public static var active(default, null):Bool = false;

  public static var panX(default, null):Float = 0;

  public static var panY(default, null):Float = 0;

  public static var zoomRatio(default, null):Float = 1;

  public static var centerX(default, null):Float = 0;

  public static var centerY(default, null):Float = 0;

  static var lastDistance:Float = -1;

  public static function update():Bool
  {
    #if FLX_TOUCH
    if (FlxG.touches.list.length < 2)
    {
      reset();
      return false;
    }

    final first = FlxG.touches.list[0];
    final second = FlxG.touches.list[1];

    final distanceX:Float = first.viewX - second.viewX;
    final distanceY:Float = first.viewY - second.viewY;
    final distance:Float = Math.sqrt(distanceX * distanceX + distanceY * distanceY);

    centerX = (first.viewX + second.viewX) / 2;
    centerY = (first.viewY + second.viewY) / 2;

    final fresh:Bool = first.justPressed || second.justPressed || lastDistance <= 0;

    panX = fresh ? 0 : (first.deltaViewX + second.deltaViewX) / 2;
    panY = fresh ? 0 : (first.deltaViewY + second.deltaViewY) / 2;
    zoomRatio = (fresh || distance <= 0) ? 1 : Math.min(1.25, Math.max(0.8, distance / lastDistance));

    lastDistance = distance;
    active = true;
    return true;
    #else
    return false;
    #end
  }

  public static function reset():Void
  {
    active = false;
    panX = 0;
    panY = 0;
    zoomRatio = 1;
    lastDistance = -1;
  }
}
