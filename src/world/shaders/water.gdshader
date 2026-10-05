// Eau de l'île (nœud « Water » de island.tscn), compatible Compatibility / WebGL 2 : couleur
// selon la distance à la côte (lagon clair, large profond), vaguelettes, lignes de vagues qui
// avancent vers la plage et écume au bord. Pas de texture d'écran ni de profondeur.
// coast_distance() reprend IslandTerrain.coast_distance() (src/world/terrain.gd) : à garder
// identiques. island.gd recopie les constantes de terrain.gd dans les uniformes au lancement.
shader_type spatial;
render_mode cull_back, diffuse_toon;

uniform vec4 shallow_color : source_color = vec4(0.38, 0.84, 0.82, 1.0);
uniform vec4 deep_color : source_color = vec4(0.12, 0.42, 0.72, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 0.98, 0.94, 1.0);
uniform float coast_radius = 74.5;
uniform float bay_depth = 6.0;
uniform float west_bulge = 2.5;
uniform float wave_speed = 0.12;

varying vec2 world_xz;

float wrap_angle(float a) {
	return mod(a + PI, TAU) - PI;
}

// Distance (m, approchée) à la ligne d'eau : > 0 sur l'île, < 0 en mer.
float coast_distance(vec2 p) {
	float x2 = p.x * p.x;
	float z2 = p.y * p.y;
	float norm = sqrt(sqrt(x2 * x2 + z2 * z2));
	float angle = atan(p.y, p.x);
	float radius = coast_radius + 1.2 * sin(3.0 * angle + 0.4) + 0.8 * sin(5.0 * angle + 2.1);
	radius += 0.4 * sin(9.0 * angle + 0.7);
	float bay = wrap_angle(angle - PI * 0.5) / 0.32;
	float bulge = wrap_angle(angle - PI) / 0.45;
	radius += -bay_depth * exp(-bay * bay) + west_bulge * exp(-bulge * bulge);
	return radius - norm;
}

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float offshore = -coast_distance(world_xz);
	vec3 color = mix(shallow_color.rgb, deep_color.rgb, smoothstep(0.0, 22.0, offshore));
	// Vaguelettes : deux trains d'ondes obliques qui glissent lentement.
	float ripple = sin(dot(world_xz, vec2(0.23, 0.11)) + TIME * 0.9);
	ripple += sin(dot(world_xz, vec2(-0.13, 0.29)) - TIME * 0.7);
	color *= 1.0 + ripple * 0.02;
	// Lignes de vagues qui avancent vers la côte et s'effacent au large.
	float phase = fract(offshore * 0.16 + TIME * wave_speed);
	float line = smoothstep(0.84, 0.9, phase) * (1.0 - smoothstep(0.9, 0.97, phase));
	line *= 1.0 - smoothstep(1.5, 13.0, offshore);
	// Écume au bord de l'eau, qui respire.
	float breath = 1.3 + 0.5 * sin(TIME * 1.3 + world_xz.x * 0.4 + world_xz.y * 0.3);
	float edge = 1.0 - smoothstep(0.0, breath, offshore);
	ALBEDO = mix(color, foam_color.rgb, max(edge, line * 0.75));
	ROUGHNESS = 0.3;
	SPECULAR = 0.35;
}
