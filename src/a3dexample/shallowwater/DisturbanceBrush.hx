package a3dexample.shallowwater;


import flash.display.BitmapData;
import flash.display.GradientType;
import flash.display.SpreadMethod;
import flash.display.Sprite;
import flash.filters.BlurFilter;
import flash.geom.Matrix;
import flash.geom.Rectangle;

/*
 Handles bitmap images to use with a FluidDisturb on a Fluid simulation.
 */
class DisturbanceBrush
{
	private var _bmd:BitmapData;

	public function new()
	{
	}

	public function generateGradient(radius:Float):Void
	{
		var drawer:Sprite = new Sprite();
		var fillType:GradientType = GradientType.RADIAL;
		var colors:Array<UInt> = [0xFFFFFF, 0x000000];
		var alphas = [1, 1];
		var ratios = [0x00, 0xFF];
		var matrix:Matrix = new Matrix();
		matrix.createGradientBox(radius, radius, 0, 0, 0);
		var spreadMethod:SpreadMethod = SpreadMethod.PAD;
		drawer.graphics.beginGradientFill(fillType, colors, alphas, ratios, matrix, spreadMethod);
		drawer.graphics.drawRect(0, 0, radius, radius);
		drawer.graphics.endFill();
		fromSprite(drawer);
	}

	/*
	 Converts a sprite to a bitmapData with blur.
	 Adds bleeding to avoid liquid stickiness to image's edges.
	 Accounts for bounding box variations due to blur.
	 */
	public function fromSprite(spr:Sprite, blur:Float = 4):Void
	{
		_bmd = new BitmapData(Std.int(spr.width), Std.int(spr.height), false, 0x000000);

		var blurFilter:BlurFilter = new BlurFilter(blur, blur, 3);
		var blurRect:Rectangle = _bmd.generateFilterRect(_bmd.rect, blurFilter);

		_bmd = new BitmapData(Std.int(blurRect.width), Std.int(blurRect.height), false, 0x000000);
		var matrix:Matrix = new Matrix();
		matrix.translate(-blurRect.x, -blurRect.y);
		spr.filters = [blurFilter];
		_bmd.draw(spr, matrix);
	}

	public var bitmapData(get,set):BitmapData;
	public function set_bitmapData(value:BitmapData):BitmapData
	{
		return _bmd = value;
	}

	public function get_bitmapData():BitmapData
	{
		return _bmd;
	}
}
