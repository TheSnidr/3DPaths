//This struct is returned when doing path.getPos(pathPos)
global.path3D_ret = 
{
	x: 0,
	y: 0,
	z: 0,
	A: 0,
	B: 0,
	C: 0,
	Aw: 0,
	Bw: 0,
	Cw: 0
};

function path3D() constructor
{
	//Create a new 3D path resource.
	//Script created by TheSnidr, 2021
	//www.TheSnidr.com
	
	smooth = true;
	closed = true;
	controlPoints = [];
	segments = -1;
	length = 0;
	precision = 20;
	vbuff = -1;
	
	/// @func clear()
	static clear = function()
	{
		controlPoints = -1;
		_clear_preprocessing();
	}
	
	/// @func setSmooth(smooth)
	static setSmooth = function(enable)
	{
		smooth = enable;
		_clear_preprocessing();
	}
	
	/// @func setClosed(closed)
	static setClosed = function(enable)
	{
		closed = enable;
		_clear_preprocessing();
	}
	
	/// @func setPrecision(precision)
	static setPrecision = function(value)
	{
		precision = value;
		_clear_preprocessing();
	}
	
	/// @func getSmooth()
	static getSmooth = function()
	{
		return smooth;
	}
	
	/// @func getClosed()
	static getClosed = function()
	{
		return closed;
	}
	
	/// @func getPrecision()
	static getPrecision = function()
	{
		return precision;
	}
	
	/// @func getNumber()
	static getNumber = function()
	{
		return array_length(controlPoints);
	}
	
	/// @func getPathPoint(index)
	static getPathPoint = function(index)
	{
		return controlPoints[index];
	}
	
	/// @func addPoint(x, y, z)
	static addPoint = function(x, y, z)
	{
		static path3d_point = function(_x, _y, _z) constructor
		{
			parent = other;
			
			static move = function(_x, _y, _z)
			{
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
		parent = other;
		A = _A;
		B = _B;
		length = point_distance_3d(A.x, A.y, A.z, B.x, B.y, B.z);
		pos = parent.length;
		parent.length += length;
		
		static getPos = function(t)
		{
			t = (t * parent.length - pos) / length;
			if (t < 0){return -1;}
			if (t > 1){return 1;}
			
			var Aw = 1 - t;
			var Bw = t;
			global.path3D_ret.x = A.x * Aw + B.x * Bw;
			global.path3D_ret.y = A.y * Aw + B.y * Bw;
			global.path3D_ret.z = A.z * Aw + B.z * Bw;
			global.path3D_ret.A = A;
			global.path3D_ret.B = B;
			global.path3D_ret.C = undefined;
			global.path3D_ret.Aw = Aw;
			global.path3D_ret.Bw = Bw;
			global.path3D_ret.Cw = undefined;
			return global.path3D_ret;
		}
	}
	
	/// @func curve(A, B, C)
	static curve = function(_A, _B, _C) constructor
	{
		parent = other;
		precision = parent.precision;
		A = _A;
		B = _B;
		C = _C;
		curveMap = array_create(precision + 1);
		
		static getPosRaw = function(t)
		{
			var tt = t * t;
			var Aw = (.5 - t + tt * .5);
			var Bw = (.5 + t - tt);
			var Cw = tt * .5;
			global.path3D_ret.x = A.x * Aw + B.x * Bw + C.x * Cw;
			global.path3D_ret.y = A.y * Aw + B.y * Bw + C.y * Cw;
			global.path3D_ret.z = A.z * Aw + B.z * Bw + C.z * Cw;
			global.path3D_ret.A = A;
			global.path3D_ret.B = B;
			global.path3D_ret.C = C;
			global.path3D_ret.Aw = Aw;
			global.path3D_ret.Bw = Bw;
			global.path3D_ret.Cw = Cw;
			return global.path3D_ret;
		}
		
		static getPos = function(t)
		{
			t = (t  - pos) / length;
			if (t < 0){return -1;}
			if (t > 1){return 1;}
			
			//Make an educated guess for where the point ends up, then search for the correct index from there
			var i = max(0, floor(t * (precision - 1)));
			var p1 = curveMap[i];
			var p2 = curveMap[i+1];
			while (p1 > t)
			{
				--i;
				p2 = p1;
				p1 = curveMap[i];
			}
			while (p2 < t)
			{
				++i;
				p1 = p2;
				p2 = curveMap[i+1];
			}
			
			//Remap the position to the new range, and find the new path position
			t = (i + (t - p1) / (p2 - p1)) / precision;
			return getPosRaw(t);
		}
		
		static updateCurveLength = function()
		{
			length = 0;
			curveMap = array_create(precision + 1);
			var pos = getPosRaw(0);
			for (var i = 1; i <= precision; i ++)
			{
				px = pos.x;
				py = pos.y;
				pz = pos.z;
				var pos = getPosRaw(i / precision);
				length += point_distance_3d(pos.x, pos.y, pos.z, px, py, pz);
				curveMap[i] = length;
			}
			for (var i = 1; i <= precision; i ++)
			{
				curveMap[i] /= length;
			}
		}
		
		updateCurveLength();
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
		pathPos = frac(pathPos);
		if (!is_array(segments))
		{
			update();
		}
		var num = array_length(controlPoints);
		var i = floor(pathPos * (num - 1));
		repeat (num)
		{
			var pos = segments[i].getPos(pathPos * length);
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
		vbuff = -1;
	}
}