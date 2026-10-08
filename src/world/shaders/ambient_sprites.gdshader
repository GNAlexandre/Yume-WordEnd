// (H9) Petites vies (AmbientSprites, src/world/ambient_sprites.gd) : sprites animés (bande
// animée) qui vivent dans une boîte autour du point que regarde la caméra : feuilles qui tombent
// en tournoyant (motion 0), oiseaux qui traversent (1), papillons qui volettent (2), lucioles qui
// flottent et palpitent (3). Tout le mouvement est ici : un mesh, un draw call. Chaque sprite a
// une place fixe dans un pavage du monde de période box_size (sommet = graine 0..1 de sa place,
// UV2 et COLOR = tirages), décalée par son mouvement puis ramenée dans la boîte : la boîte suit
// la caméra sans que les sprites la suivent, et ils s'effacent aux bords de la boîte et de la
// région (region : centre x, z et demi-taille ; demi-taille nulle : partout). Billboards face à
// la caméra, ancre au centre ; ambient_time est posé par le nœud (il s'arrête pendant la pause).
// Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, specular_disabled, skip_vertex_transform;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"

uniform sampler2D albedo_texture : source_color, filter_linear, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float glow = 0.0;
uniform vec3 box_center = vec3(0.0);
uniform vec3 box_size = vec3(26.0, 9.0, 20.0);
uniform vec4 region = vec4(0.0);
uniform float ambient_time = 0.0;
uniform int motion = 0;
uniform float speed = 1.0;
uniform float sway = 0.8;
uniform vec2 sprite_size = vec2(0.17, 0.17);
uniform float frames = 1.0;
uniform float fps = 8.0;

varying float sprite_alpha;

vec3 motion_offset(float t, float phase, float rate, vec4 r) {
	if (motion == 0) {
		// Feuille : tombe, se balance, dérive un peu vers l'est (vent d'ouest).
		return vec3(
				sway * sin(t * 1.3 * rate + phase) + 0.3 * speed * t,
				-speed * rate * t,
				0.5 * sway * cos(t * 0.9 * rate + phase * 2.0));
	}
	if (motion == 1) {
		// Oiseau : traverse d'ouest en est (vers l'ouest si speed < 0), ondule à peine.
		return vec3(speed * rate * t, 0.25 * sway * sin(t * 2.1 + phase), 0.1 * sway * sin(t * 0.7 + phase));
	}
	if (motion == 2) {
		// Papillon : boucles irrégulières, dérive lente.
		return vec3(
				sway * sin(t * 0.7 * rate + phase) + 0.3 * sway * sin(t * 2.9 + r.x * 6.3) + 0.2 * speed * t,
				0.4 * sway * sin(t * 1.9 * rate + r.y * 6.3),
				sway * cos(t * 0.6 * rate + r.z * 6.3));
	}
	// Luciole : flotte sur place.
	return sway * vec3(sin(t * 0.5 * rate + phase), 0.5 * sin(t * 0.8 + r.x * 6.3), cos(t * 0.4 * rate + r.y * 6.3));
}

void vertex() {
	float t = ambient_time;
	float phase = UV2.x * TAU;
	float rate = 0.7 + 0.6 * UV2.y;
	vec3 box_min = box_center - box_size * 0.5;
	vec3 home = VERTEX * box_size + motion_offset(t, phase, rate, COLOR);
	vec3 world = box_min + mod(home - box_min, box_size);
	// Effacement aux bords de la boîte (le bas : le sol) et de la région.
	vec3 rel = (world - box_min) / box_size;
	float edge = min(min(rel.x, 1.0 - rel.x), min(rel.z, 1.0 - rel.z));
	sprite_alpha = smoothstep(0.0, 0.08, edge) * smoothstep(0.0, 0.04, rel.y) * smoothstep(0.0, 0.08, 1.0 - rel.y);
	if (region.z > 0.0) {
		vec2 d = abs(world.xz - region.xy) - region.zw;
		sprite_alpha *= 1.0 - smoothstep(-2.0, 0.0, max(d.x, d.y));
	}
	if (motion == 3) {
		sprite_alpha *= 0.3 + 0.7 * (0.5 + 0.5 * sin(t * 2.3 * rate + COLOR.w * 6.3));
	}
	vec2 corner = (UV - 0.5) * vec2(sprite_size.x, -sprite_size.y);
	vec2 uv = UV;
	if (motion == 1 && speed < 0.0) {
		uv.x = 1.0 - uv.x;
	}
	if (frames > 1.5) {
		float frame = floor(mod(t * fps + UV2.x * frames, frames));
		uv.x = (frame + uv.x) / frames;
	}
	UV = uv;
	vec4 view = VIEW_MATRIX * vec4(world, 1.0);
	view.xy += corner;
	VERTEX = view.xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec4 c = pixel_art(albedo_texture, UV);
	ALBEDO = c.rgb * tint.rgb;
	ALPHA = c.a * tint.a * sprite_alpha;
	EMISSION = c.rgb * glow;
	ROUGHNESS = 1.0;
}
