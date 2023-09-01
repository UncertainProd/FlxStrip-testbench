import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.mouse.FlxMouseEvent;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class VertexPoint extends FlxSprite
{
	public var curColor:FlxColor;
	public var selected = false;
	public var radius:Float = 5.0;

	public var pointIndex:Int;

	// public var textureU:Float;
	// public var textureV:Float;

	public function new(X = 0.0, Y = 0.0, idx:Int)
	{
		super(X, Y);
		makeGraphic(Std.int(2 * radius), Std.int(2 * radius), FlxColor.TRANSPARENT, true);
		curColor = FlxColor.BLUE;
		pointIndex = idx;
		FlxMouseEvent.add(this, handleMouseDown, handleMouseUp, handleMouseOver, handleMouseOut);
	}

	function handleMouseDown(vp:VertexPoint)
	{
		vp.curColor = FlxColor.RED;
		vp.selected = true;
		PlayState.selectedPoint = vp;
	}

	function handleMouseUp(vp:VertexPoint)
	{
		vp.curColor = FlxColor.BLUE;
		vp.selected = false;
		PlayState.selectedPoint = null;

		if (PlayState.currentMode == VERTEX_REMOVE)
		{
			PlayState.removeVertex(this);
			PlayState.currentMode = NORMAL;
		}
	}

	function handleMouseOver(vp:VertexPoint)
	{
		vp.curColor = FlxColor.GREEN.getLightened();
	}

	function handleMouseOut(vp:VertexPoint)
	{
		vp.curColor = FlxColor.BLUE;
	}

	override function draw()
	{
		super.draw();
		FlxSpriteUtil.drawCircle(this, -1, -1, radius, curColor);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (selected)
		{
			x += FlxG.mouse.deltaScreenX;
			y += FlxG.mouse.deltaScreenY;
			PlayState.flxstripSprite.vertices[pointIndex * 2] = x;
			PlayState.flxstripSprite.vertices[pointIndex * 2 + 1] = y;
		}
	}
}