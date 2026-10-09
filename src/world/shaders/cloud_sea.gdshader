// Mer de nuages sous l'île (nœud « Water » d'island.tscn, plan très bas) : deux couches de la
// texture de pixel art assets/hd2d/sky/cloud_sea.png qui défilent lentement à des vitesses
// différentes ; la plus proche n'apparaît que par pixels d'art tramés (pas de mélange flou), et
// le côté du couchant (sun_direction) se réchauffe. Non éclairée. Compatible Compatibility /
// WebGL 2. (H5) tint assombrit ou refroidit le tout (réglages de crépuscule et de nuit,
// src/world/materials/hd2d_lighting.gd). (E9) Les préréglages de lumière (Atmosphere) posent
// tint, warm (couleur du côté du soleil ou de la lune) et sun_direction ; une autre image
// (clouds_next : la mer de nuages de nuit ou de pluie du cahier n° 3) se fond dans la première
// pendant une transition (clouds_mix de 0 à 1 ; à 1, Atmosphere la pose dans clouds).
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform sampler2D clouds : source_color, filter_nearest, repeat_enable;
uniform sampler2D clouds_next : source_color, filter_nearest, repeat_enable;
uniform float clouds_mix : hint_range(0.0, 1.0) = 0.0;
// Taille de la texture dans le monde (m) : grands bancs, vus de très haut.
uniform float tile_meters = 96.0;
uniform vec2 drift = vec2(0.6, 0.25);
// Direction (plan du sol) d'où vient la lumière du couchant, posée par island.gd.
uniform vec2 sun_direction = vec2(-1.0, 0.0);
uniform vec4 warm : source_color = vec4(0.99, 0.78, 0.55, 1.0);
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying vec3 world_pos;

float bayer(vec2 cell) {
	vec2 c = mod(cell, 4.0);
	int i = int(c.x) + int(c.y) * 4;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}

// Deux couches de l'image : la lointaine, et la proche par pixels tramés.
vec3 sea(sampler2D image, vec2 p, float t) {
	vec3 far_layer = texture(image, (p + TIME * drift) / tile_meters).rgb;
	vec3 near_layer = texture(image, (p.yx * 0.7 - TIME * drift * 1.8) / (tile_meters * 0.6)).rgb;
	float near_amount = smoothstep(0.55, 0.9, dot(near_layer, vec3(0.33)));
	return near_amount > t ? near_layer : far_layer;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float t = bayer(floor(p * 24.0 / tile_meters * 16.0));
	vec3 c = sea(clouds, p, t);
	if (clouds_mix > 0.001) {
		c = mix(c, sea(clouds_next, p, t), clouds_mix);
	}
	float toward_sun = clamp(dot(normalize(p + vec2(0.0001)), normalize(sun_direction)), 0.0, 1.0);
	c = mix(c, c * warm.rgb * 1.15, toward_sun * 0.5);
	ALBEDO = c * tint.rgb;
}
