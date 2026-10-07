// Roche de l'île flottante (IslandRock, src/world/island_rock.gd) : lèvre de pierre claire,
// couche de terre et de racines, puis falaise et dessous de l'île en strates claires et sombres,
// qui virent au lavande en profondeur (le ciel du dessous). Facettes plates (normales du mesh),
// éclairage toon comme le sol. Compatible Compatibility / WebGL 2. COLOR.r = 1 : racine.
shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_disabled;

uniform vec4 lip_stone : source_color = vec4(0.8, 0.73, 0.63, 1.0);
uniform vec4 earth : source_color = vec4(0.42, 0.3, 0.22, 1.0);
uniform vec4 stone_light : source_color = vec4(0.8, 0.73, 0.63, 1.0);
uniform vec4 stone_dark : source_color = vec4(0.55, 0.48, 0.42, 1.0);
uniform vec4 depth_tint : source_color = vec4(0.45, 0.38, 0.55, 1.0);
uniform vec4 root_color : source_color = vec4(0.3, 0.21, 0.15, 1.0);

varying vec3 world_pos;
varying float root;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	root = COLOR.r;
}

void fragment() {
	float y = world_pos.y;
	// Strates : bandes claires et sombres, ondulées autour de l'île.
	float wave = 1.3 * sin(world_pos.x * 0.07) + 1.1 * sin(world_pos.z * 0.05 + 1.3);
	float band = 0.5 + 0.5 * sin((y + wave) * 1.05);
	vec3 c = mix(stone_light.rgb, stone_dark.rgb, smoothstep(0.3, 0.7, band) * 0.8);
	// Sous le sol : la lèvre de pierre (40 cm), puis la terre aux racines (jusqu'à −1,7 m).
	float soil = 1.0 - smoothstep(-2.0, -1.4, y);
	c = mix(earth.rgb, c, soil);
	c = mix(c, lip_stone.rgb, smoothstep(-0.55, -0.35, y));
	// En profondeur, la roche prend la couleur du ciel du dessous.
	c = mix(c, depth_tint.rgb, smoothstep(-14.0, -46.0, y) * 0.6);
	ALBEDO = mix(c, root_color.rgb, root);
	ROUGHNESS = 0.9;
}
