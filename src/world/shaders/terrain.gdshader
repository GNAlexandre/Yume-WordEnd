// Couleurs du sol de l'île (mesh de IslandTerrain, src/world/terrain.gd), au pixel près :
// herbe, sous-bois, dunes, arène, chemins, place, plage et fond marin. Compatible
// Compatibility / WebGL 2. Les uniformes de forme (côte, arène, place, colline, eau) sont
// recopiés de terrain.gd au lancement ; coast_distance() est la même que dans terrain.gd et
// water.gdshader.
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform vec4 grass : source_color = vec4(0.49, 0.78, 0.4, 1.0);
uniform vec4 grass_light : source_color = vec4(0.62, 0.85, 0.46, 1.0);
uniform vec4 forest_floor : source_color = vec4(0.33, 0.6, 0.36, 1.0);
uniform vec4 sand : source_color = vec4(0.98, 0.9, 0.7, 1.0);
uniform vec4 wet_sand : source_color = vec4(0.85, 0.75, 0.57, 1.0);
uniform vec4 seabed : source_color = vec4(0.6, 0.73, 0.62, 1.0);
uniform vec4 dune_sand : source_color = vec4(0.97, 0.76, 0.5, 1.0);
uniform vec4 arena_sand : source_color = vec4(0.99, 0.86, 0.63, 1.0);
uniform vec4 arena_ring : source_color = vec4(0.88, 0.62, 0.45, 1.0);
uniform vec4 path_dirt : source_color = vec4(0.86, 0.75, 0.52, 1.0);
uniform vec4 plaza_stone : source_color = vec4(0.82, 0.8, 0.76, 1.0);
uniform vec4 plaza_ring : source_color = vec4(0.66, 0.63, 0.6, 1.0);

uniform float coast_radius = 74.5;
uniform float bay_depth = 6.0;
uniform float west_bulge = 2.5;
uniform vec2 arena_center = vec2(-51.0, 0.0);
uniform float arena_radius = 12.0;
uniform float plaza_radius = 9.0;
uniform float hill_height = 8.0;
uniform float water_level = -0.6;
uniform float sea_floor = -1.3;
uniform float path_half_width = 1.5;

// Chemins de terre : segments (x1, z1, x2, z2) en coordonnées de l'île.
const int PATH_COUNT = 13;
const vec4 PATHS[PATH_COUNT] = {
	vec4(0.0, -9.0, 0.0, -24.0), vec4(0.0, -24.0, 1.5, -33.0), vec4(1.5, -33.0, 0.0, -38.5),
	vec4(0.0, 9.0, 0.0, 24.0), vec4(0.0, 24.0, -2.0, 36.0), vec4(-2.0, 36.0, 1.0, 48.0),
	vec4(1.0, 48.0, 0.0, 56.0),
	vec4(-9.0, 0.0, -24.0, 0.0), vec4(-24.0, 0.0, -31.0, 1.0), vec4(-31.0, 1.0, -38.0, 0.0),
	vec4(9.0, 0.0, 24.0, 0.0), vec4(24.0, 0.0, 31.0, -1.5), vec4(31.0, -1.5, 38.0, -2.5)
};

varying vec3 world_pos;

float wrap_angle(float a) {
	return mod(a + PI, TAU) - PI;
}

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

float path_distance(vec2 p) {
	float best = 1e6;
	for (int i = 0; i < PATH_COUNT; i++) {
		vec2 a = PATHS[i].xy;
		vec2 ab = PATHS[i].zw - a;
		float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
		best = min(best, length(p - a - ab * t));
	}
	return best;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float h = world_pos.y;
	float coast = coast_distance(p);
	// Herbe, avec de grandes taches plus claires.
	float patches = sin(p.x * 0.13 + 1.7 * sin(p.y * 0.09)) * sin(p.y * 0.11 - p.x * 0.02);
	vec3 c = mix(grass.rgb, grass_light.rgb, 0.3 + 0.3 * patches);
	// Sous-bois au nord ; haut de la colline plus clair.
	c = mix(c, forest_floor.rgb, (1.0 - smoothstep(-31.0, -25.0, p.y)) * 0.9);
	c = mix(c, grass_light.rgb, smoothstep(3.0, hill_height, h) * 0.7);
	// Dunes à l'ouest, arène claire bordée d'un anneau.
	float arena = distance(p, arena_center);
	vec2 q = (p - arena_center) / vec2(1.0, 1.2);
	float lobe = atan(q.y, q.x);
	float edge = length(q) + 2.5 * sin(lobe * 3.0 + 0.7) + 1.5 * sin(lobe * 5.0 + 2.0);
	float dunes = 1.0 - smoothstep(25.0, 28.5, edge);
	c = mix(c, dune_sand.rgb, dunes);
	c = mix(c, arena_sand.rgb, 1.0 - smoothstep(arena_radius - 0.25, arena_radius, arena));
	float ring = abs(arena - arena_radius - 0.35);
	c = mix(c, arena_ring.rgb, 1.0 - smoothstep(0.18, 0.28, ring));
	// Chemins de terre, place pavée et son anneau.
	float path = 1.0 - smoothstep(path_half_width - 0.15, path_half_width + 0.15, path_distance(p));
	c = mix(c, path_dirt.rgb, path * (1.0 - 0.7 * dunes));
	float plaza = length(p);
	c = mix(c, plaza_stone.rgb, 1.0 - smoothstep(plaza_radius - 0.15, plaza_radius, plaza));
	c = mix(c, plaza_ring.rgb, 1.0 - smoothstep(0.25, 0.4, abs(plaza - plaza_radius + 0.4)));
	// Plage (bien plus large au sud), sable mouillé au bord de l'eau, fond marin.
	float south = wrap_angle(atan(p.y, p.x) - PI * 0.5) / 0.55;
	float sand_width = 4.5 + 8.0 * exp(-south * south);
	c = mix(c, sand.rgb, 1.0 - smoothstep(sand_width - 0.5, sand_width + 0.5, coast));
	c = mix(c, wet_sand.rgb, 1.0 - smoothstep(0.6, 1.4, abs(coast)));
	c = mix(c, seabed.rgb, 1.0 - smoothstep(sea_floor, water_level, h));
	ALBEDO = c;
	ROUGHNESS = 0.6;
}
