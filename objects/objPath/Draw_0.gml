/// @description

//Draw player
matrix_set(matrix_world, matrix_multiply(matrix_build(0, 0, 0, 0, 0, 90, 3, 3, 3), mat));
vertex_submit(minecart, pr_trianglelist, sprite_get_texture(texMinecart, 0));
matrix_set(matrix_world, matrix_build_identity());

//Draw sky
matrix_set(matrix_world, matrix_build(x, y, z, 0, 0, 0, 20000, 20000, 20000));
vertex_submit(sphere, pr_trianglelist, sprite_get_texture(texSky, 0));
matrix_set(matrix_world, matrix_build_identity());

//Draw ground
draw_primitive_begin_texture(pr_trianglestrip, sprite_get_texture(texGrass, 0));
draw_vertex_texture(0, 0, 0, 0);
draw_vertex_texture(512, 0, 4, 0);
draw_vertex_texture(0, 512, 0, 4);
draw_vertex_texture(512, 512, 4, 4);
draw_primitive_end();

//Draw rollercoaster
vertex_submit(rollercoaster, pr_trianglestrip, sprite_get_texture(texMineTrack, 0));
