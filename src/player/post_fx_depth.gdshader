// (RD) Flou de profondeur selon la vraie profondeur, à la manière d'Octopath Traveler : un
// rectangle plein écran dans le monde 3D (CameraRig/Camera3D/DepthBlur, camera_rig.gd), dessiné
// le premier des objets mélangés (render_priority −128), juste après le décor opaque. Il lit
// l'image du décor opaque (hint_screen_texture) et sa profondeur
// (hint_depth_texture), puis rend chaque pixel flou selon son écart à la profondeur du joueur :
// - une bande nette de focus_near m devant le joueur (vers la caméra) à focus_far m derrière lui ;
// - le premier plan (plus près de la caméra) de plus en plus flou, jusqu'à near_blur_px quand il
//   est near_full m plus près que la bande ;
// - le lointain s'adoucit jusqu'à far_blur_px, far_full m au-delà de la bande
// (réglages et courbe partagés : src/world/shaders/depth_focus.gdshaderinc).
// Le premier plan flou déborde sur ce qui est derrière lui (son flou s'étale sur ses bords) : huit
// lectures de profondeur autour du pixel, à la portée du flou du premier plan, en gardent le plus
// fort. Le flou est un disque de douze lectures (voir blurred) ; le post-traitement de l'écran
// (post_fx.gdshader) reste chargé de la lueur et de l'étalonnage de toute l'image.
// Ce qui est mélangé (ombres des décors, décalques doux, fumée, ciel qui dérive) est dessiné après
// lui et se floute lui-même selon la même courbe (depth_focus.gdshaderinc, DepthFocus) ; la pluie,
// les petites vies et les effets restent nets. Les personnages (découpés) sont dans l'image :
// floutés comme le décor.
// Rendu Compatibility / WebGL 2 : la profondeur va de 0 à 1 (NDC de −1 à 1).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, shadows_disabled,
		fog_disabled, skip_vertex_transform;

uniform sampler2D screen : hint_screen_texture, filter_linear, repeat_disable;
uniform sampler2D depth : hint_depth_texture, filter_nearest, repeat_disable;
#include "res://src/world/shaders/depth_focus.gdshaderinc"

// 0 : aucun flou (le rectangle recopie l'image).
uniform float strength = 1.0;

void vertex() {
	// Le rectangle couvre l'écran quelle que soit la caméra.
	POSITION = vec4(VERTEX.xy * 2.0, 0.0, 1.0);
}

// Profondeur (m le long de l'axe de la caméra) du décor opaque au point uv de l'écran.
float view_depth(vec2 uv, mat4 inv_projection) {
	float d = textureLod(depth, uv, 0.0).r;
	vec4 v = inv_projection * vec4(uv * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
	return -v.z / v.w;
}

// Disque de 12 lectures (spirale d'angle d'or, rayon 1), tourné d'un angle propre à chaque pixel
// (bruit à gradient entrelacé) : le rendu Compatibility ne fait pas de mipmaps de l'image lue
// dans le monde 3D (constaté : quatre lectures « en croix » d'un niveau de mipmap donnaient
// quatre images nettes décalées) ; les lectures bilinéaires, tournées d'un pixel à l'autre,
// donnent un flou doux au lieu d'images fantômes.
const vec2 DISC[12] = vec2[12](
	vec2(0.204, 0.000), vec2(-0.261, 0.239), vec2(0.040, -0.455), vec2(0.329, 0.429),
	vec2(-0.603, -0.107), vec2(0.571, -0.363), vec2(-0.191, 0.711), vec2(-0.364, -0.702),
	vec2(0.791, 0.289), vec2(-0.822, 0.339), vec2(0.396, -0.847), vec2(0.293, 0.934)
);

float gradient_noise(vec2 pixel) {
	return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}

vec3 blurred(vec2 uv, vec2 pixel, float radius_px, vec2 fragcoord) {
	vec3 center = textureLod(screen, uv, 0.0).rgb;
	if (radius_px < 0.35) {
		return center;
	}
	float angle = gradient_noise(fragcoord) * 6.2831853;
	mat2 turn = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
	vec2 step_uv = pixel * radius_px;
	vec3 sum = center * 0.5;
	for (int i = 0; i < 12; i++) {
		sum += textureLod(screen, uv + turn * DISC[i] * step_uv, 0.0).rgb;
	}
	return sum / 12.5;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	// Taille d'un pixel de l'écran, et le flou ramené à 720 px de haut.
	vec2 pixel = 1.0 / VIEWPORT_SIZE;
	float scale = VIEWPORT_SIZE.y / 720.0 * strength;
	mat4 inv = INV_PROJECTION_MATRIX;
	float z = view_depth(uv, inv);
	float radius = focus_radius(z) * scale;
	// Débord du premier plan : le flou le plus fort d'un voisin plus proche de la caméra, à la
	// portée de son flou.
	float reach = near_blur_px * scale;
	if (reach > 0.5) {
		vec2 r = pixel * reach;
		vec2 d = r * 0.7071;
		float spread = 0.0;
		spread = max(spread, focus_near_radius(view_depth(uv + vec2(r.x, 0.0), inv)));
		spread = max(spread, focus_near_radius(view_depth(uv - vec2(r.x, 0.0), inv)));
		spread = max(spread, focus_near_radius(view_depth(uv + vec2(0.0, r.y), inv)));
		spread = max(spread, focus_near_radius(view_depth(uv - vec2(0.0, r.y), inv)));
		spread = max(spread, focus_near_radius(view_depth(uv + d, inv)));
		spread = max(spread, focus_near_radius(view_depth(uv - d, inv)));
		spread = max(spread, focus_near_radius(view_depth(uv + vec2(d.x, -d.y), inv)));
		spread = max(spread, focus_near_radius(view_depth(uv + vec2(-d.x, d.y), inv)));
		radius = max(radius, spread * scale * 0.85);
	}
	ALBEDO = blurred(uv, pixel, radius, FRAGCOORD.xy);
	ALPHA = 1.0;
}
