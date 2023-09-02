package;

import flixel.FlxG;
import flixel.FlxStrip;
import flixel.addons.ui.FlxUIState;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;

using MyStringUtil;

enum UIMode
{
	NORMAL;
	VERTEX_ADD;
	VERTEX_REMOVE;
}

class PlayState extends FlxUIState
{
	public static var flxstripSprite:FlxStrip;
	var addPointsTxt:FlxText;

	public static var currentMode:UIMode = NORMAL;
	var points:Array<VertexPoint> = [];

	public static var selectedPoint:VertexPoint;

	override public function create()
	{
		_xml_id = "playgroundUI";
		super.create();
		flxstripSprite = new FlxStrip(0, 0, AssetPaths.haxe__png);
		flxstripSprite.vertices = DrawData.ofArray([]);
		flxstripSprite.indices = DrawData.ofArray([]);
		flxstripSprite.uvtData = DrawData.ofArray([]);
		add(flxstripSprite);

		addPointsTxt = new FlxText(0, 0, 0, "Click anywhere on the left half of the screen to add a new vertex", 20);
		addPointsTxt.setFormat(null, 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		addPointsTxt.screenCenter();
		add(addPointsTxt);
		addPointsTxt.visible = false;
		setPointAttrsVisibility(false);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.mouse.justPressed)
		{
			// trace('Global mouse click!');
			onMainAreaClick();
		}
		#if debug
		if (FlxG.keys.justPressed.R)
		{
			FlxG.resetGame();
		}
		#end
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		super.getEvent(id, sender, data, params);
		// trace('Got event: id=$id | sender=${Type.typeof(sender)} | data=$data | params=$params');

		switch id
		{
			case 'click_button':
				if(params[0] == "vertex-add")
				{
					// trace('switching current mode!');
					currentMode = VERTEX_ADD;
					addPointsTxt.text = "Click anywhere on the left half of the screen to add a new vertex";
					addPointsTxt.visible = true;
					FlxTween.tween(
						addPointsTxt, 
						{ alpha: 0 }, 
						0.5, 
						{
							startDelay: 1.5,
							ease: FlxEase.quadOut, 
							onComplete: (t) -> {
								addPointsTxt.visible = false;
								addPointsTxt.alpha = 1;
							},
						}
					);
				}
				else if (params[0] == "vertex-remove")
				{
					currentMode = VERTEX_REMOVE;
					addPointsTxt.text = "Click on a vertex to remove it (warning: will re-order other vertices)";
					addPointsTxt.visible = true;
					FlxTween.tween(
						addPointsTxt, 
						{ alpha: 0 }, 
						0.5, 
						{
							startDelay: 1.5,
							ease: FlxEase.quadOut, 
							onComplete: (t) -> {
								addPointsTxt.visible = false;
								addPointsTxt.alpha = 1;
							},
						}
					);
				}
		}
	}

	function onMainAreaClick()
	{
		var panel = _ui.getAsset("ui_panel");
		if(FlxG.mouse.x < panel.x)
		{
			// trace('Clicked on Area!');
			switch currentMode
			{
				case NORMAL:
				case VERTEX_ADD:
					var nextIdx = points.length;
					var vp = new VertexPoint(FlxG.mouse.x, FlxG.mouse.y, nextIdx);
					points.push(vp);
					add(vp);
					updateStrip();
					currentMode = NORMAL;
				case VERTEX_REMOVE:
			}
			var deselectAllPoints = true;
			for (p in points)
			{
				if (FlxG.mouse.overlaps(p))
				{
					deselectAllPoints = false;
					break;
				}
			}
			if (deselectAllPoints)
			{
				selectedPoint = null;
				setPointAttrsVisibility(false);
			}
		}
	}

	public static function removeVertex(vert: VertexPoint)
	{
		var thisState = cast(FlxG.state, PlayState);
		thisState.points.remove(vert);
		thisState.remove(vert);
		thisState.updateStrip();
		for(i in 0...thisState.points.length)
		{
			thisState.points[i].pointIndex = i;
		}
		selectedPoint = null;
		setPointAttrsVisibility(false);
	}

	public static function setPointAttrsVisibility(visible:Bool)
	{
		var thisState = cast(FlxG.state, PlayState);
		if (visible)
		{
			thisState._ui.setMode('vert_selected');
		}
		else
		{
			thisState._ui.setMode('no_selected');
		}
	}

	/**
	 * Does 3 things :
	 * - Arranges the vertices from the `points` array into a 1D vector into `flxstripSprite.vertices`
	 * 
	 * - Modifies the `indices` of `flxstripSprite` in such a way that adjacent indices form a triangle
	 * (Basically creates the order `0,1,2`, `1,3,2`, `2,3,4`, `3,5,4`, ....)
	 * 
	 * - Modifies the `uvtData` of `flxstripSprite` by having the uv coords sort of "interpolate" between vertices
	 */
	function updateStrip()
	{
		// update vertices
		points.sort((vp1, vp2) -> FlxSort.byValues(FlxSort.ASCENDING, vp1.pointIndex, vp2.pointIndex));

		var newVertices = [];
		for(p in points)
		{
			newVertices.push(p.x + p.radius);
			newVertices.push(p.y + p.radius);
		}
		flxstripSprite.vertices = DrawData.ofArray(newVertices);

		#if debug
		trace(sPrintArrayFancy(newVertices, 2));
		#end
		// update indices
		// i, i+1, i+2
		// i+1, i+3, i+2
		var i = 0;
		var newIndices = [];
		while (true)
		{
			if (i + 2 >= points.length)
			{
				break;
			}
			else 
			{
				newIndices.push(i);
				newIndices.push(i+1);
				newIndices.push(i+2);
			}

			if (i + 3 >= points.length)
			{
				break;
			}
			else 
			{
				newIndices.push(i+1);
				newIndices.push(i+3);
				newIndices.push(i+2);
			}
			i += 2;
		}

		#if debug
		trace(sPrintArrayFancy(newIndices, 3));
		#end
		flxstripSprite.indices = DrawData.ofArray(newIndices);

		// update uvtData
		var newUVData: Array<Float> = [];
		var curV = 0.0;
		for(j in 0...points.length)
		{
			newUVData.push(j % 2);
			newUVData.push(curV);
			// the 't' in uvtData (technically optional but keeping it for the sake of completeness)
			newUVData.push(1.0);
			if(j % 2 == 1)
			{
				curV += 1.0 / (Math.ceil(points.length * 0.5) - 1);
			}
		}

		#if debug
		trace(sPrintArrayFancy(newUVData, 3));
		#end
		flxstripSprite.uvtData = DrawData.ofArray(newUVData);
	}
	#if debug
	function sPrintArrayFancy<T>(arr:Array<T>, n:Int = 0, indentSpaces:Int = 2):String
	{
		if (n == 0)
			return Std.string(arr);

		var s = '[\n';
		var i = 0;
		while (i < arr.length)
		{
			s += ' '.repeat(indentSpaces);
			for (j in 0...n)
			{
				s += Std.string(arr[i + j]) + ', ';
			}
			s += '\n';
			i += n;
		}
		s += ']';

		return s;
	}
	#end
}