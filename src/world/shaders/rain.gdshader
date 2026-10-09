// (E9) Pluie dans le monde (RainFall, src/world/rain_fall.gd) : gouttes qui tombent en traits
// (assets/hd2d/fx/rain_drop.png) et éclaboussures au sol (assets/hd2d/anim/rain_splash.png, bande
// animée de frames images) dans une boîte autour du point que regarde la caméra. Un mesh, un draw
// call par sorte (splash = 0 : gouttes, 1 : éclaboussures). Comme ambient_sprites.gdshader, chaque
// goutte a une place fixe dans un pavage du monde de période box_size (sommet = graine 0..1 de
// sa place, UV2 et COLOR = tirages), décalée par sa chute puis ramenée dans la boîte : la boîte
// suit la caméra sans que les gouttes la suivent. intensity (0..1) dit la part des gouttes qui
// tombent : la pluie fine en montre un tiers, l'averse toutes, sans reconstruire le mesh ; une
// goutte s'éteint au-dessus de son tirage, la pluie s'arrête en douceur. Le trait suit à l'écran
// la direction de la chute (vent d'ouest : il penche vers l'est). rain_time est posé par le nœud
// (arrêté pendant la pause). Non éclairée : la teinte vient du préréglage (tint). Compatible
// Compatibility / WebGL 2.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, skip_vertex_transform, shadows_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear, repeat_disable;
uniform vec4 tint : source_color = vec4(0.8, 0.85, 0.95, 0.55);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform int splash = 0;
uniform vec3 box_center = vec3(0.0);
uniform vec3 box_size = vec3(28.0, 12.0, 26.0);
uniform float rain_time = 0.0;
// Chute (m/s) et vent (m/s vers l'est) des gouttes ; taille d'un trait ou d'une éclaboussure (m).
uniform float fall_speed = 9.0;
uniform float wind = 1.8;
uniform vec2 sprite_size = vec2(0.04, 0.5);
// Éclaboussures : images de la bande et cadence.
uniform float frames = 1.0;
uniform float fps = 12.0;

varying float drop_alpha;

void vertex() {
	float t = rain_time;
	float rate = 0.8 + 0.4 * UV2.y;
	vec3 box_min = box_center - box_size * 0.5;
	vec3 velocity = vec3(wind, -fall_speed, 0.0) * rate;
	vec3 home = VERTEX * box_size;
	if (splash == 0) {
		home += velocity * t + vec3(0.0, UV2.x * box_size.y, 0.0);
	} else {
		home.y = 0.0;
	}
	vec3 world = box_min + mod(home - box_min, box_size);
	if (splash != 0) {
		world.y = box_min.y;
	}
	// La goutte tombe si son tirage est sous l'intensité ; effacement aux bords de la boîte.
	vec3 rel = (world - box_min) / box_size;
	float edge = min(min(rel.x, 1.0 - rel.x), min(rel.z, 1.0 - rel.z));
	drop_alpha = smoothstep(0.0, 0.08, edge) * (1.0 - smoothstep(intensity - 0.08, intensity, COLOR.w));
	if (splash == 0) {
		drop_alpha *= smoothstep(0.0, 0.05, rel.y) * smoothstep(0.0, 0.1, 1.0 - rel.y);
	}
	vec4 view = VIEW_MATRIX * vec4(world, 1.0);
	vec2 corner;
	if (splash == 0) {
		// Trait le long de la chute vue à l'écran.
		vec3 fall_view = (VIEW_MATRIX * vec4(velocity, 0.0)).xyz;
		vec2 along = normalize(fall_view.xy + vec2(0.0, -0.0001));
		vec2 across = vec2(-along.y, along.x);
		float length_scale = 0.6 + 0.4 * intensity;
		corner = across * (UV.x - 0.5) * sprite_size.x + along * (UV.y - 0.5) * sprite_size.y * length_scale;
	} else {
		// Éclaboussure : ancrée au sol par le milieu du bas, image de la bande selon sa phase.
		corner = vec2((UV.x - 0.5) * sprite_size.x, (1.0 - UV.y) * sprite_size.y);
		float frame = floor(mod(t * fps * rate + UV2.x * frames, frames));
		UV.x = (frame + UV.x) / frames;
	}
	view.xy += corner;
	VERTEX = view.xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec4 c = texture(albedo_texture, UV);
	ALBEDO = c.rgb * tint.rgb;
	ALPHA = c.a * tint.a * drop_alpha;
}
