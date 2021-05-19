global.path3D_ret = 
{
	//This struct is returned when doing path.getPos(pathPos)
	x:  0, y:  0, z:  0,
	A:  0, B:  0, C:  0,
	Aw: 0, Bw: 0, Cw: 0
};

function path3D() constructor
{
	/*
		Create a new 3D path resource.
		This script was created for a youtube video, and has since been cleaned up and optimized further.
		YouTube link: https://www.youtube.com/watch?v=Gfm1zTIp8BU
		
		When smooth is enabled, it uses quadratic interpolation, like the built-in path system in GM.
		It also has a system for counteracting the weird speed changes that often appear along the path 
		when doing quadratic interpolation.
		
		Script created by TheSnidr, 2021
		www.TheSnidr.com
	*/
	
	smooth = true;
	closed = true;
	controlPoints = [];
	precision = 20;
	segments = -1;
	segmentNum = 0;
	length = 0;
	vbuff = -1;
	
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
		pos = 0;
		A = _A;
		B = _B;
		length = point_distance_3d(A.x, A.y, A.z, B.x, B.y, B.z);
		
		static getPos = function(t)
		{
			var Bw = t / length;
			var Aw = 1 - Bw;
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
		pos = 0;
		A = _A;
		B = _B;
		C = _C;
		length = 0;
		curveMap = array_create(parent.precision + 1);
		
		static quadraticInterpolation = function(t)
		{
			/*
				Returns an unprocessed quadratically interpolated point from a given value of t in the range 0-1.
				Interpolates from the midpoint between A and B to the midpoint between B and C
			*/
			var tt = t * t;
			var Aw = .5 - t + tt * .5;
			var Bw = .5 + t - tt;
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
			/*
				t should be a value between 0 and curveLength, NOT 0-1.
				
				This function will counteract the weird changes in speed when following a path with quadratic interpolation.
				When the curve is created, it also maps the path position to the actual distance travelled along the curve.
				We can then use this map to search for the best fitting part of the curve for a given path position, so that a point
				following the path will move at a constant speed throughout. This is just an approximation, but it's a pretty good 
				approximation, and at a precision of 20 the changes in speed are not perceptible.
			*/
			var p = parent.precision;
			
			//Make an initial guess for the first curveMap position
			var i = clamp(floor(t * p / length), 0, p - 1);
			var p1 = curveMap[i];
			var p2 = curveMap[i+1];
			
			//Search for the best fitting curveMap position, so that p1 is less or equal to t and p2 is larger or equal to t
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
			
			//Remap t to the new semi-uniform range
			t = (i + (t - p1) / (p2 - p1)) / p;
			
			//Find the quadratically interpolated point
			return quadraticInterpolation(t);
		}
		
		static update = function()
		{
			//This function will update the curve's curve length.
			//It also updates the curveMap, which maps path position to actual distance travelled, for smoothening out the movement speed along the path
			length = 0;
			var p = parent.precision;
			var pos = quadraticInterpolation(0);
			for (var i = 1; i <= p; i ++)
			{
				var px = pos.x;
				var py = pos.y;
				var pz = pos.z;
				var pos = quadraticInterpolation(i / p);
				length += point_distance_3d(pos.x, pos.y, pos.z, px, py, pz);
				curveMap[i] = length;
			}
		}
		
		//Update the curve as soon as it is created
		update();
	}
	
	/// @func update()
	static update = function()
	{
		/*
			This function will assemble the path as an array of segments.
			The segments will be either curves (for smooth paths) or lines (for straight paths).
			The segments update their own lengths in their constructor functions.
		*/
		var A, B, C, S;
		length = 0;
		segmentNum = array_length(controlPoints);
		if (!smooth && !closed){--segmentNum;}
		segments = array_create(segmentNum);
		for (var i = 0; i < segmentNum; i ++)
		{
			if (smooth)
			{
				if (closed)
				{
					//When closed, the first segment actually starts at the midpoint between the first and second points.
					A = controlPoints[i];
					B = controlPoints[(i + 1) % segmentNum];
					C = controlPoints[(i + 2) % segmentNum];
				}
				else
				{
					//When open, the first segment will reference the first point twice, resulting in a straight line. The last segment will reference the last point twice.
					A = controlPoints[max(i - 1, 0)];
					B = controlPoints[i];
					C = controlPoints[min(i + 1, segmentNum - 1)];
				}
				//When the path is smooth, the segments will do quadratic interpolation across three control points
				S = new curve(A, B, C);
			}
			else
			{
				if (closed)
				{
					A = controlPoints[i];
					B = controlPoints[(i + 1) % segmentNum];
				}
				else
				{
					A = controlPoints[i];
					B = controlPoints[i + 1];
				}
				//When the path is not smooth, the segments will do linear interpolation along two control points
				S = new line(A, B);
			}
			S.pos = length;
			length += S.length;
			segments[@ i] = S;
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
		}
		
		//Modify the pathPos so that it's always in the range 0-1
		if (closed || pathPos != 1){pathPos -= floor(pathPos);}
		var t = pathPos * length;
		
		//Make an initial guess for the segment index
		var i = clamp(floor(pathPos * segmentNum), 0, segmentNum - 1);
		
		//Start a loop for searching for the correct segment. Worst case scenario we'll end up looping segmentNum times, but that's very unlikely.
		repeat (segmentNum)
		{
			var S = segments[i];
			
			//Search for the correct segment from the initial first guess
			if (t < S.pos)
			{
				//t is too low. Reduce i by one and try again
				--i;
				continue;
			}
			if (t > S.pos + S.length)
			{
				//t is too high. Increase i by one and try again
				++i;
				continue;
			}
			
			//We've found the correct segment. Get the interpolated position from it.
			return S.getPos(t - S.pos);
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
		//Create a basic format that works without the need for custom shaders
		static createFormat = function()
		{
			vertex_format_begin();
			vertex_format_add_position_3d();
			vertex_format_add_normal();
			vertex_format_add_texcoord();
			vertex_format_add_colour();
			return vertex_format_end();
		}
		
		//Simple function for adding vertices to vbuff
		static addVert = function(x, y, z)
		{
			vertex_position_3d(vbuff, x, y, z);
			vertex_normal(vbuff, 0, 0, 0);
			vertex_texcoord(vbuff, 0, 0);
			vertex_colour(vbuff, c_white, 1);
		}
		
		//Create the format as a static variable to avoid memory leaks
		static format = createFormat();
		
		if (vbuff >= 0)
		{
			//Delete the vbuff if it already exists
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
				addVert(pos.x, pos.y, pos.z);
			}
		}
		else
		{
			var num = array_length(controlPoints);
			for (var i = 0; i < num + closed; i ++)
			{
				var A = controlPoints[i % num];
				addVert(A.x, A.y, A.z);
			}
		}
		
		vertex_end(vbuff);
		vertex_freeze(vbuff);
	}
	
	/// @func _clear_preprocessing()
	static _clear_preprocessing = function()
	{
		//This function clears all precalculated info from the path. The info will be recreated the next time the path is sampled.
		segments = -1;
		if (vbuff >= 0)
		{
			vertex_delete_buffer(vbuff);
		}
		vbuff = -1;
	}
}