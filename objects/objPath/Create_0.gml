/// @description

//Load the necessary OBJ files
sphere = loadObj("Sphere.obj");
minecart = loadObj("Minecart.obj");

//Create a new 3D path, and add path points to it
path = new path3D();
var num = path_get_number(Path1);
for (var i = 0; i < num; i ++)
{
	//Add a new point to the path
	var point = path.addPoint(path_get_point_x(Path1, i), path_get_point_y(Path1, i), random(200));
	
	//Give the point a random up vector
	var xup = random_range(-3, 3);
	var yup = random_range(-3, 3);
	var zup = 1;
	var l = sqrt(xup * xup + yup * yup + zup * zup);
	if (l == 0)
	{
		zup = 1;
	}
	else
	{
		xup /= l;
		yup /= l;
		zup /= l;
	}
	point.xup = xup;
	point.yup = yup;
	point.zup = zup;
}

//Enable 3D views
view_enabled = true;
view_visible[0] = true;
view_camera[0] = camera_create();
camera_set_proj_mat(view_camera[0], matrix_build_projection_perspective_fov(-80, -window_get_width() / window_get_height(), 1, 32000));
gpu_set_ztestenable(true);
gpu_set_zwriteenable(true);
gpu_set_texrepeat(true);

//Some player settings
pathPos = 0;
var pos = path.getPos(pathPos);
x = pos.x;
y = pos.y;
z = pos.z;
mat = matrix_build(x, y, z, 0, 0, 0, 1, 1, 1);
camMat = matrix_build(x, y, z, 0, 0, 0, 1, 1, 1);
spd = 0;
minSpd = .0004;

//Create a function for more easily adding vertices to the rollercoaster
var addVert = function(x, y, z, u, v)
{
	vertex_position_3d(rollercoaster, x, y, z);
	vertex_normal(rollercoaster, 0, 0, 0);
	vertex_texcoord(rollercoaster, u, v);
	vertex_colour(rollercoaster, c_white, 1);
}

//Create the roller coaster vertex buffer
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_normal();
vertex_format_add_texcoord();
vertex_format_add_colour();
format = vertex_format_end();
rollercoaster = vertex_create_buffer();
vertex_begin(rollercoaster, format);
var num = path.getPrecision() * path.getNumber();
var pos = path.getPos(0);
var M = matrix_build(0, 0, 0, 0, 0, 0, 1, 1, 1);
for (var i = 1; i <= num + 1; i ++)
{
	//Create the matrix for this position
	var prevX = pos.x;
	var prevY = pos.y;
	var prevZ = pos.z;
	var pos = path.getPos(i / num);
	M[12] = pos.x;
	M[13] = pos.y;
	M[14] = pos.z;
	M[0]  = pos.x - prevX;
	M[1]  = pos.y - prevY;
	M[2]  = pos.z - prevZ;
	M[8]  = pos.A.xup * pos.Aw + pos.B.xup * pos.Bw + pos.C.xup * pos.Cw;
	M[9]  = pos.A.yup * pos.Aw + pos.B.yup * pos.Bw + pos.C.yup * pos.Cw;
	M[10] = pos.A.zup * pos.Aw + pos.B.zup * pos.Bw + pos.C.zup * pos.Cw;
	matrix_orthonormalize_to(M);
	
	//Add vertices to the vertex buffer
	var width = 8;
	var p1 = matrix_transform_vertex(M, 0, -width, 0);
	var p2 = matrix_transform_vertex(M, 0, width, 0);
	addVert(p1[0], p1[1], p1[2], 0, i / 2);
	addVert(p2[0], p2[1], p2[2], 1, i / 2);
}
vertex_end(rollercoaster);