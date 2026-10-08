// Cascade du ruisseau qui tombe du bord nord-ouest de l'île (IslandRock.waterfall_mesh :
// UV.y de 0 en haut à 1 en bas). Filets d'eau qui défilent, écume, et chute qui se défait en
// bruine vers le bas (pixels jetés, sans transparence mélangée). Non éclairée, compatible
// Compatibility / WebGL 2.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec4 water_color : source_color = vec4(0.7, 0.85, 0.94, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 0.98, 0.95, 1.0);
uniform float speed = 0.8;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float lanes = 0.5 + 0.5 * sin(UV.x * 29.0 + UV.y * 4.0);
	float streak = fract(UV.y * 6.0 - TIME * speed + 0.35 * sin(UV.x * 17.0));
	vec3 c = mix(water_color.rgb, foam_color.rgb, smoothstep(0.55, 0.95, streak) * lanes);
	// Bords effilés, puis la bruine : de plus en plus de trous en descendant.
	float side = abs(UV.x - 0.5) * 2.0;
	float spray = hash(floor(vec2(UV.x * 26.0, UV.y * 70.0 - TIME * 9.0)));
	if (side > 0.92 - 0.1 * lanes || spray < smoothstep(0.35, 1.0, UV.y)) {
		discard;
	}
	ALBEDO = mix(c, foam_color.rgb, smoothstep(0.5, 1.0, UV.y) * 0.6);
}
