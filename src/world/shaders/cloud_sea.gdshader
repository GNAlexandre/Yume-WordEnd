// Mer de nuages sous l'île flottante (nœud « Water » de island.tscn, très bas sous l'île) :
// moutonnements blancs qui dérivent avec le vent d'ouest, creux gris-bleu, crêtes dorées du côté
// du soleil, quelques trouées sur la surface grise très loin en bas ; vers l'horizon, la couleur
// de la brume et du bas du ciel (shaders/sky.gdshader). Pas d'eau.
// Non éclairé (le relief des moutons est ombré par le shader d'après la pente du bruit et la
// direction du soleil), compatible Compatibility / WebGL 2 : un bruit en texture
// (NoiseTexture2D sans couture) lu à trois échelles, aucune texture d'écran.
// island.gd recopie la direction du soleil (Sun) dans sun_direction au lancement.
shader_type spatial;
render_mode unshaded, cull_back, fog_disabled, shadows_disabled;

uniform sampler2D clouds : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 crest_color : source_color = vec4(0.97, 0.96, 0.93, 1.0);
uniform vec4 trough_color : source_color = vec4(0.76, 0.81, 0.88, 1.0);
uniform vec4 shade_color : source_color = vec4(0.6, 0.67, 0.77, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.86, 0.64, 1.0);
uniform vec4 ground_color : source_color = vec4(0.42, 0.47, 0.53, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.76, 0.82, 0.88, 1.0);
// Vent (m/s), vers le soleil (x, z), taille d'une tuile du bruit (m), fondu vers l'horizon (m).
uniform vec2 wind = vec2(1.4, 0.3);
uniform vec2 sun_direction = vec2(-0.96, 0.29);
uniform float tile_size = 520.0;
uniform float fade_start = 450.0;
uniform float fade_end = 1350.0;
// Relief des moutons (force de la pente), creux → crêtes, part des trouées.
uniform float relief = 9.0;
uniform vec2 crest_range = vec2(0.22, 0.62);
uniform float hole_threshold = 0.9;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	vec2 uv = (p - wind * TIME) / tile_size;
	float step_uv = 3.0 / float(textureSize(clouds, 0).x);
	float big = texture(clouds, uv).r;
	float big_x = texture(clouds, uv + vec2(step_uv, 0.0)).r;
	float big_z = texture(clouds, uv + vec2(0.0, step_uv)).r;
	float small = texture(clouds, (p - wind * 1.7 * TIME) / (tile_size * 0.27) + vec2(0.37, 0.71)).r;
	float billow = big * 0.75 + small * 0.25;
	// Couleur par hauteur du mouton, puis ombre propre d'après la pente et le soleil.
	vec3 c = mix(trough_color.rgb, crest_color.rgb, smoothstep(crest_range.x, crest_range.y, billow));
	vec3 normal = normalize(vec3((big - big_x) * relief, 1.0, (big - big_z) * relief));
	vec3 sun = normalize(vec3(sun_direction.x, 0.45, sun_direction.y));
	float light = clamp(dot(normal, sun) * 1.1, 0.0, 1.0);
	c = mix(shade_color.rgb, c, 0.45 + 0.55 * light);
	// Le couchant dore les crêtes du côté du soleil.
	vec2 view = p - CAMERA_POSITION_WORLD.xz;
	float dist = length(view);
	float sunward = max(dot(view / max(dist, 0.001), sun_direction), 0.0);
	c = mix(c, sun_color.rgb, smoothstep(0.5, 0.8, billow) * light * sunward * 0.55);
	// Rares trouées (le cœur des plus gros moutons, à une autre échelle) : très loin en bas, la
	// surface grise.
	float gaps = texture(clouds, (p - wind * 0.45 * TIME) / (tile_size * 3.3) + vec2(0.13, 0.52)).r;
	float hole = smoothstep(hole_threshold, hole_threshold + 0.04, gaps);
	c = mix(c, ground_color.rgb, hole * 0.75);
	c = mix(c, horizon_color.rgb, smoothstep(fade_start, fade_end, dist));
	ALBEDO = c;
}
