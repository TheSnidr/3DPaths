// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function loadObj(filename)
{
	static make_format = function()
	{
		vertex_format_begin();
		vertex_format_add_position_3d();
		vertex_format_add_normal();
		vertex_format_add_texcoord();
		vertex_format_add_colour();
		return vertex_format_end();
	}
	static read_face = function(faceList, str) 
	{
		gml_pragma("forceinline");
		str = string_delete(str, 1, string_pos(" ", str))
		if (string_char_at(str, string_length(str)) == " ")
		{
			//Make sure the string doesn't end with an empty space
			str = string_copy(str, 0, string_length(str) - 1);
		}
		var triNum = string_count(" ", str);
		var vertString = array_create(triNum + 1);
		for (var i = 0; i < triNum; i ++)
		{
			//Add vertices in a triangle fan
			vertString[i] = string_copy(str, 1, string_pos(" ", str));
			str = string_delete(str, 1, string_pos(" ", str));
		}
		vertString[i--] = str;
		while i--
		{
			for (var j = 2; j >= 0; j --)
			{
				var vstr = vertString[(i + j) * (j > 0)];
				var v = 0, n = 0, t = 0;
				//If the vertex contains a position, texture coordinate and normal
				if string_count("/", vstr) == 2 and string_count("//", vstr) == 0
				{
					v = abs(real(string_copy(vstr, 1, string_pos("/", vstr) - 1)));
					vstr = string_delete(vstr, 1, string_pos("/", vstr));
					t = abs(real(string_copy(vstr, 1, string_pos("/", vstr) - 1)));
					n = abs(real(string_delete(vstr, 1, string_pos("/", vstr))));
				}
				//If the vertex contains a position and a texture coordinate
				else if string_count("/", vstr) == 1
				{
					v = abs(real(string_copy(vstr, 1, string_pos("/", vstr) - 1)));
					t = abs(real(string_delete(vstr, 1, string_pos("/", vstr))));
				}
				//If the vertex only contains a position
				else if (string_count("/", vstr) == 0)
				{
					v = abs(real(vstr));
				}
				//If the vertex contains a position and normal
				else if string_count("//", vstr) == 1
				{
					vstr = string_replace(vstr, "//", "/");
					v = abs(real(string_copy(vstr, 1, string_pos("/", vstr) - 1)));
					n = abs(real(string_delete(vstr, 1, string_pos("/", vstr))));
				}
				ds_list_add(faceList, [v-1, n-1, t-1]);
			}
		}
	}
	static read_line = function(str) 
	{
		gml_pragma("forceinline");
		str = string_delete(str, 1, string_pos(" ", str));
		var retNum = string_count(" ", str) + 1;
		var ret = array_create(retNum);
		for (var i = 0; i < retNum; i ++)
		{
			var pos = string_pos(" ", str);
			if (pos == 0)
			{
				pos = string_length(str);
				ret[i] = real(string_copy(str, 1, pos)); 
				break;
			}
			ret[i] = real(string_copy(str, 1, pos)); 
			str = string_delete(str, 1, pos);
		}
		return ret;
	}
	var file = file_text_open_read(filename);
	if (file == -1)
	{
		show_debug_message("Failed to load model " + string(filename)); 
		return -1;
	}
	show_debug_message("Script loadObj: Loading obj file " + string(filename));

	//Create the necessary lists
	var V = ds_list_create();
	var N = ds_list_create();
	var T = ds_list_create();
	var F = ds_list_create();

	//Read .obj as textfile
	while !file_text_eof(file)
	{
		var str = string_replace_all(file_text_read_string(file),"  "," ");
		//Different types of information in the .obj starts with different headers
		switch string_copy(str, 1, string_pos(" ", str)-1)
		{
			//Load vertex positions
			case "v":
				ds_list_add(V, read_line(str));
				break;
			//Load vertex normals
			case "vn":
				ds_list_add(N, read_line(str));
				break;
			//Load vertex texture coordinates
			case "vt":
				ds_list_add(T, read_line(str));
				break;
			//Load faces
			case "f":
				read_face(F, str);
				break;
		}
		file_text_readln(file);
	}
	file_text_close(file);
	
	//Loop through the loaded information and generate a model
	static format = make_format();
	static bytesPerVert = 3 * 4 + 3 * 4 + 2 * 4 + 4 * 1;
	var vertNum = ds_list_size(F);
	var mbuff = buffer_create(vertNum * bytesPerVert, buffer_fixed, 1);
	for (var f = 0; f < vertNum; f ++)
	{
		var vnt = F[| f];
		
		//Add the vertex to the model buffer
		var v = V[| vnt[0]];
		if !is_array(v){v = [0, 0, 0];}
		buffer_write(mbuff, buffer_f32, v[0]);
		buffer_write(mbuff, buffer_f32, v[2]);
		buffer_write(mbuff, buffer_f32, v[1]);
		
		var n = N[| vnt[1]];
		if !is_array(n){n = [0, 0, 1];}
		buffer_write(mbuff, buffer_f32, n[0]);
		buffer_write(mbuff, buffer_f32, n[2]);
		buffer_write(mbuff, buffer_f32, n[1]);
		
		var t = T[| vnt[2]];
		if !is_array(t){t = [0, 0];}
		buffer_write(mbuff, buffer_f32, t[0]);
		buffer_write(mbuff, buffer_f32, 1-t[1]);
		
		buffer_write(mbuff, buffer_u8, 255);
		buffer_write(mbuff, buffer_u8, 255);
		buffer_write(mbuff, buffer_u8, 255);
		buffer_write(mbuff, buffer_u8, 255);
	}
	ds_list_destroy(F);
	ds_list_destroy(V);
	ds_list_destroy(N);
	ds_list_destroy(T);
	show_debug_message("Script loadObj: Successfully loaded obj " + string(filename));
	
	var vbuff = vertex_create_buffer_from_buffer(mbuff, format);
	vertex_freeze(vbuff);
	buffer_delete(mbuff);
	return vbuff;
}