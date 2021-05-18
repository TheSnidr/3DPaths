//This struct is returned when doing path.getPos(pathPos)
global.path3D_ret = 
{
	x:  0, y:  0, z:  0,
	A:  0, B:  0, C:  0,
	Aw: 0, Bw: 0, Cw: 0
};

function path3D() constructor
{
	//Create a new 3D path resource.
	//Script created by TheSnidr, 2021
	//www.TheSnidr.com
	//https://www.youtube.com/watch?v=Gfm1zTIp8BU
	
	smooth = true;
	closed = true;
	controlPoints = [];
	precision = 20;
	segments = -1;
	length = 0;
	vbuff = -1;
	segmentNum = 0;
	
	/// @func clear()
	static clear = function()
	{
		//Clears the path of all control points
		controlPoints = -1;
		_clear_preprocessing();
	}
	
	/// @func setSmooth(smooth)
	static setSmooth = function(enable)
	{
		//Enables quadratic interpolation
		smooth = enable;
		_clear_preprocessing();
	}
	
	/// @func setClosed(closed)
	static setClosed = function(enable)
	{
		//Whether or not the path is joined at the ends
		closed = enable;
		_clear_preprocessing();
	}
	
	/// @func setPrecision(precision)
	static setPrecision = function(value)
	{
		//A higher precision means smoother curves at the cost of more processing. Default value is 20.
		precision = value;
		_clear_preprocessing();
	}
	
	/// @func getSmooth()
	static getSmooth = function()
	{
		//Returns whether the path is smoothened or not
		return smooth;
	}
	
	/// @func getClosed()
	static getClosed = function()
	{
		//Returns whether the path is closed or not
		return closed;
	}
	
	/// @func getPrecision()
	static getPrecision = function()
	{
		//Returns the path's precision value
		return precision;
	}
	
	/// @func getNumber()
	static getNumber = function()
	{
		//Returns the number of control points
		return array_length(controlPoints);
	}
	
	/// @func getPathPoint(index)
	static getPathPoint = function(index)
	{
		//Returns the path point with the given index
		return controlPoints[index];
	}
	
	/// @func addPoint(x, y, z)
	static addPoint = function(x, y, z)
	{
		//Add a new path point to the path
		static path3d_point = function(_x, _y, _z) constructor
		{
			parent = other;
			
			static move = function(_x, _y, _z)
			{
				//Lets you move the path point around
				x = _x;
				y = _y;
				z = _z;
				
				parent._clear_preprocessing();
			}
			
			move(_x, _y, _z);
		}
		
		var point = new path3d_point(x, y, z);
		array_push(controlPoints, point);
		return point;
	}
	
	/// @func line(A, B)
	static line = function(_A, _B) constructor
	{
		//Constructor function for line segments. These are used when smooth is false
		parent = other;
		A = _A;
		B = _B;
		length = point_distance_3d(A.x, A.y, A.z, B.x, B.y, B.z);
		pos = parent.length;
		parent.length += length;
		
		static getPos = function(t)
		{
			t = (t - pos) / length;
			if (t < 0){return -1;}
			if (t > 1){return 1;}
			
			var Aw = 1 - t;
			var Bw = t;
			var ret = global.path3D_ret;
			ret.x = A.x * Aw + B.x * Bw;
			ret.y = A.y * Aw + B.y * Bw;
			ret.z = A.z * Aw + B.z * Bw;
			ret.A = A;
			ret.B = B;
			ret.C = A;
			ret.Aw = Aw;
			ret.Bw = Bw;
			ret.Cw = 0;
			return ret;
		}
	}
	
	/// @func curve(A, B, C)
	static curve = function(_A, _B, _C) constructor
	{
		//Constructor function for curved segments. These are used when smooth is true
		parent = other;
		A = _A;
		B = _B;
		C = _C;
		curveMap = array_create(parent.precision + 1);
		
		static getPosRaw = function(t)
		{
			//Returns an unprocessed quadratically interpolated point from a given value of t in the range 0-1
			var tt = t * t;
			var Aw = (.5 - t + tt * .5);
			var Bw = (.5 + t - tt);
			var Cw = tt * .5;
			var ret = global.path3D_ret;
			ret.x = A.x * Aw + B.x * Bw + C.x * Cw;
			ret.y = A.y * Aw + B.y * Bw + C.y * Cw;
			ret.z = A.z * Aw + B.z * Bw + C.z * Cw;
			ret.A = A;
			ret.B = B;
			ret.C = C;
			ret.Aw = Aw;
			ret.Bw = Bw;
			ret.Cw = Cw;
			return ret;
		}
		
		static getPos = function(t)
		{
			//t should be a value between 0 and pathLength, NOT 0-1.
			//This function will return -1 if t is too small and 1 if t is too large.
			//If t falls in the range of this segment, it will process t so that the movement speed of a point following the path is constant
			t -= pos;
			if (t < 0){return -1;}
			if (t > length){return 1;}
			
			//Make an educated guess for where the point ends up, then search for the correct index from there
			var p = parent.precision;
			var i = clamp(floor(t * p / length), 0, p - 1);
			var p1 = curveMap[i];
			var p2 = curveMap[i+1];
			while (p1 > t)
			{
				p2 = p1;
				p1 = curveMap[--i];
			}
			while (p2 < t)
			{
				p1 = p2;
				p2 = curveMap[++i + 1];
			}
			
			//Remap the position to the new range, and find the new path position
			return getPosRaw((i + (t - p1) / (p2 - p1)) / p);
		}
		
		static update = function()
		{
			//This function will update the curve's curve length.
			//It also updates the curveMap, which maps path position to actual distance travelled, for smoothening out the movement speed along the path
			length = 0;
			var p = parent.precision;
			var pos = getPosRaw(0);
			for (var i = 1; i <= p; i ++)
			{
				var px = pos.x;
				var py = pos.y;
				var pz = pos.z;
				var pos = getPosRaw(i / p);
				length += point_distance_3d(pos.x, pos.y, pos.z, px, py, pz);
				curveMap[i] = length;
			}
		}
		
		update();
		pos = parent.length;
		parent.length += length;
	}
	
	/// @func update()
	static update = function()
	{
		var num = array_length(controlPoints);
		if (!smooth && !closed){--num;}
		segments = array_create(num);
		length = 0;
		
		for (var i = 0; i < num; i ++)
		{
			if (smooth)
			{
				if (closed)
				{
					var A = controlPoints[i];
					var B = controlPoints[(i + 1) % num];
					var C = controlPoints[(i + 2) % num];
				}
				else
				{
					var A = controlPoints[max(i - 1, 0)];
					var B = controlPoints[i];
					var C = controlPoints[min(i + 1, num - 1)];
				}
				segments[@ i] = new curve(A, B, C);
			}
			else
			{
				if (closed)
				{
					var A = controlPoints[i];
					var B = controlPoints[(i + 1) % num];
				}
				else
				{
					var A = controlPoints[i];
					var B = controlPoints[min(i + 1, num)];
				}
				segments[@ i] = new line(A, B);
			}
		}
	}
	
	/// @func getPos(pathPos)
	static getPos = function(pathPos)
	{
		//This will find the point along the path that corresponds to the given pathPos, which should be in the range 0-1
		if (!is_array(segments))
		{
			//Whenever settings are changed or points are moved, all preprocessed info gets wiped and needs to be created again
			update();
			segmentNum = array_length(segments);
		}
		pathPos = (pathPos == 1) ? 1 : frac(pathPos);
		var i = clamp(floor(pathPos * segmentNum), 0, segmentNum - 1);
		var t = pathPos * length;
		repeat (segmentNum)
		{
			var pos = segments[i].getPos(t);
			if (is_real(pos))
			{
				i += pos;
				continue;
			}
			return pos;
		}
	}
	
	/// @func draw()
	static draw = function()
	{
		//A useful function for debugging. Draws the path as a linestrip. Also works in 3D.
		if (vbuff == -1){_update_vbuff();}
		vertex_submit(vbuff, pr_linestrip, -1);
	}
	
	/// @func _update_vbuff()
	static _update_vbuff = function()
	{
		static createFormat = function()
		{
			vertex_format_begin();
			vertex_format_add_position_3d();
			vertex_format_add_normal();
			vertex_format_add_texcoord();
			vertex_format_add_colour();
			return vertex_format_end();
		}
		static format = createFormat();
		
		if (vbuff >= 0)
		{
			vertex_delete_buffer(vbuff);
		}
		vbuff = vertex_create_buffer();
		vertex_begin(vbuff, format);
		
		if (smooth)
		{
			var num = precision * array_length(controlPoints);
			for (var i = 0; i <= num; i ++)
			{
				var pos = getPos(i / num);
				vertex_position_3d(vbuff, pos.x, pos.y, pos.z);
				vertex_normal(vbuff, 0, 0, 0);
				vertex_texcoord(vbuff, 0, 0);
				vertex_colour(vbuff, c_white, 1);
			}
		}
		else
		{
			var num = array_length(controlPoints);
			for (var i = 0; i < num + closed; i ++)
			{
				var A = controlPoints[i % num];
				vertex_position_3d(vbuff, A.x, A.y, A.z);
				vertex_normal(vbuff, 0, 0, 0);
				vertex_texcoord(vbuff, 0, 0);
				vertex_colour(vbuff, c_white, 1);
			}
		}
		
		vertex_end(vbuff);
		vertex_freeze(vbuff);
	}
	
	/// @func _clear_preprocessing()
	static _clear_preprocessing = function()
	{
		segments = -1;
		if (vbuff >= 0)
		{
			vertex_delete_buffer(vbuff);
		}
		vbuff = -1;
	}
}