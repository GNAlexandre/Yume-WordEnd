// Ciel de l'île n° 68 (WorldEnvironment de island.tscn) : dégradé bleu doux du zénith vers un
// horizon pâle et brumeux, halo chaud autour du soleil bas à l'ouest-sud-ouest (fin d'après-midi),
// nuages doux en bande au-dessus de l'horizon, éclairés côté soleil ; sous l'horizon, la couleur
// de la brume (la mer de nuages y fond vers la même teinte).
// Compatible Compatibility / WebGL 2 ; sans TIME : le ciel n'est calculé qu'une fois pour les
// reflets.
shader_type sky;

uniform vec4 zenith_color : source_color = vec4(0.36, 0.53, 0.76, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.76, 0.82, 0.88, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.82, 0.58, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.95, 0.84, 1.0);
uniform vec4 cloud_color : source_color = vec4(1.0, 0.98, 0.94, 1.0);
uniform vec4 cloud_shade : source_color = vec4(0.7, 0.75, 0.84, 1.0);
uniform sampler2D clouds : filter_linear_mipmap, repeat_enable;
// Part du ciel couverte, échelle des nuages, cosinus du rayon du disque solaire.
uniform float cloud_cover = 0.52;
uniform float cloud_scale = 0.35;
uniform float sun_disk = 0.9993;

void sky() {
	vec3 dir = EYEDIR;
	float up = clamp(dir.y, 0.0, 1.0);
	vec3 c = mix(horizon_color.rgb, zenith_color.rgb, smoothstep(0.0, 0.6, pow(up, 0.7)));
	// Halo chaud du soleil, large au ras de l'horizon.
	float toward = max(dot(dir, LIGHT0_DIRECTION), 0.0);
	float low = 1.0 - smoothstep(0.0, 0.45, up);
	c = mix(c, glow_color.rgb, pow(toward, 6.0) * (0.35 + 0.45 * low));
	c = mix(c, glow_color.rgb, pow(toward, 48.0) * 0.5);
	// Nuages doux : bruit projeté sur un plafond, en bande au-dessus de l'horizon.
	if (dir.y > 0.0) {
		vec2 uv = dir.xz / (dir.y + 0.15) * cloud_scale;
		float n = texture(clouds, uv).r * 0.7 + texture(clouds, uv * 2.7 + vec2(0.31, 0.57)).r * 0.3;
		float band = smoothstep(0.0, 0.08, dir.y) * (1.0 - smoothstep(0.35, 0.7, dir.y));
		float cover = smoothstep(cloud_cover, cloud_cover + 0.22, n) * band;
		vec3 cloud = mix(cloud_shade.rgb, cloud_color.rgb, smoothstep(cloud_cover, 0.9, n));
		cloud = mix(cloud, glow_color.rgb, pow(toward, 4.0) * 0.55);
		c = mix(c, cloud, cover * 0.85);
	}
	// Disque du soleil, adouci.
	c = mix(c, sun_color.rgb, smoothstep(sun_disk - 0.0004, sun_disk, toward));
	// Sous l'horizon : la brume.
	c = mix(c, horizon_color.rgb, 1.0 - smoothstep(-0.05, 0.0, dir.y));
	COLOR = c;
}
