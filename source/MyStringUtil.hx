package;

class MyStringUtil
{
	public static function repeat(s:String, n:Int):String
	{
		var newstr = '';
		for (_ in 0...n)
		{
			newstr += s;
		}
		return newstr;
	}
}