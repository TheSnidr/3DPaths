/// @description

//Move along the path
pathPos += spd;
var pos = path.getPos(pathPos / path.length);

//Find a vector pointing from the previous position to the new
var dx = pos.x - x;
var dy = pos.y - y;
var dz = pos.z - z;

//Make the path speed change depending on steepness of the path. The steeper it is, the faster it accelerates
var l = sqrt(dx * dx + dy * dy + dz * dz);
spd = max(minSpd, spd * .99 - min(0., .07 * dz / l));

//Update the player's position
x = pos.x;
y = pos.y;
z = pos.z;
mat[12] = x;
mat[13] = y;
mat[14] = z;

//Update the player's looking direction
mat[0] += dx * .5;
mat[1] += dy * .5;
mat[2] += dz * .5;

//Update the player's up direction based on the custom vector that we created when adding points to the path
var A = pos.A;
var B = pos.B;
var C = pos.C;
var Aw = pos.Aw;
var Bw = pos.Bw;
var Cw = pos.Cw;
var xup = A.xup * Aw + B.xup * Bw + C.xup * Cw;
var yup = A.yup * Aw + B.yup * Bw + C.yup * Cw;
var zup = A.zup * Aw + B.zup * Bw + C.zup * Cw;
mat[8]  += xup * .5;
mat[9]  += yup * .5;
mat[10] += zup * .5;

//Orthonormalize the final matrix
matrix_orthonormalize_to(mat);

//Make the camera's matrix lag slightly behind the player's matrix
for (var i = 0; i < 16; i ++)
{
	camMat[i] = lerp(camMat[i], mat[i], .2);
}

//Set the view matrix
var xfrom = x - camMat[0] * 40 + camMat[8] * 30;
var yfrom = y - camMat[1] * 40 + camMat[9] * 30;
var zfrom = z - camMat[2] * 40 + camMat[10] * 30;
camera_set_view_mat(view_camera[0], matrix_build_lookat(xfrom, yfrom, zfrom, x + camMat[8] * 2, y + camMat[9] * 2, z + camMat[10] * 2, camMat[8], camMat[9], camMat[10]));