// (E3) Sols, murs et dessus de mur d'un intérieur (InteriorRoom) : matière répétée en pixel art
// (pixel_art.gdshaderinc), éclairage plat de l'île (hd2d_light.gdshaderinc), lumière de la pièce
// et coupe (interior_core.gdshaderinc). Données de chaque sommet :
// - UV2.x : coordonnée de coupe (z du monde) ;
// - UV2.y : partie (0 : sol ou face de mur, coupée au-dessus de cut_height ; 1 : dessus d'un mur
//   entier, effacé quand le mur est coupé ; 2 : dessus d'un mur coupé, à cut_height, montré
//   seulement quand il l'est), plus 4 × (ligne + 1) pour un mur nord-sud (ligne x de la carte) :
//   la colonne de coupe (cut_column : x et z du joueur dans le repère de la pièce, demi-largeur,
//   longueur) coupe le mur nord-sud dont la ligne passe sous le joueur (dans une porte de ce mur,
//   le bout de cloison au sud le cacherait, vu par la tranche), de column_front à
//   column_front + longueur m au sud de lui.
// Les deux faces sont dessinées : l'intérieur d'un mur, vu par une coupe, prend section_color
// (la tranche d'un mur coupé, comme sur un plan). Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"
#include "res://src/world/shaders/interior_core.gdshaderinc"

uniform sampler2D albedo_texture : source_color, filter_linear, repeat_enable;
uniform float cut_height = 0.15;
uniform vec4 section_color : source_color = vec4(0.3, 0.22, 0.17, 1.0);
uniform vec4 cut_column = vec4(-1000000.0, -1000000.0, 0.0, 0.0);
uniform float column_front = 0.3;

varying vec3 world_pos;
varying vec2 light_xz;
varying float cut_coord;
varying float part;
varying float line_x;
varying float local_z;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 n = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	light_xz = world_pos.xz + normalize(n + vec3(0.0, 0.0001, 0.0)).xz * 0.3;
	cut_coord = UV2.x;
	float code = floor(UV2.y + 0.5);
	part = mod(code, 4.0);
	line_x = code > 3.5 ? floor(code / 4.0) - 1.0 : -1000000.0;
	local_z = VERTEX.z;
}

void fragment() {
	vec4 c = pixel_art(albedo_texture, UV);
	float height = world_pos.y - floor_y;
	float ahead = local_z - cut_column.y - column_front;
	bool column = abs(line_x - cut_column.x) < cut_column.z && ahead > 0.0 && ahead < cut_column.w;
	bool cut = interior_is_cut(cut_coord) || column;
	if (part < 0.5) {
		if (cut && height > cut_height + 0.002) {
			discard;
		}
	} else if (part < 1.5) {
		if (cut) {
			discard;
		}
	} else if (!cut) {
		discard;
	}
	ROUGHNESS = 1.0;
	if (FRONT_FACING) {
		ALBEDO = c.rgb;
		EMISSION = c.rgb * interior_light(light_xz, height);
	} else {
		ALBEDO = section_color.rgb;
	}
}
