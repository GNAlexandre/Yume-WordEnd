// Post-traitement HD-2D de la caméra du joueur (CameraRig/PostFX/Screen, rectangle plein écran
// sous l'interface) : ce que le rendu Compatibility ne fait pas lui-même, en une passe.
// - Flou de profondeur à la manière d'Octopath Traveler : net dans une bande autour du joueur
//   (focus_center ± focus_half, posés à chaque image par la caméra : de quelques mètres devant
//   le joueur à neuf mètres derrière lui, le joueur n'est jamais flou), de plus en plus flou
//   jusqu'au haut de l'écran (le lointain) et un peu vers le bas (le premier plan), sans
//   cassure. (H5) Le flou lit les mipmaps de l'image (copie floutée par le moteur) : rayon
//   continu, quatre lectures en croix au lieu de douze, sans grain.
// - Lueur : ce qui reste clair dans deux niveaux de flou (cristaux, fenêtres, ciel) déborde en
//   halo chaud, large et doux (bloom).
// - Étalonnage de fin d'après-midi d'automne (MONDE.md 5.4 : l'île est toujours au couchant) :
//   teinte chaude, ombres vers le lavande et hautes lumières vers l'or (virage partiel), voile
//   de brume du lointain en haut de l'écran, lumière du soleil couchant depuis l'ouest (la
//   gauche de l'écran : la caméra regarde le nord), contraste, saturation, vignette.
// Les réglages de nuit et de crépuscule changent ces uniformes (src/world/materials/
// hd2d_lighting.gd). Lit l'image du monde 3D (hint_screen_texture) ; l'interface, dessinée après,
// reste nette. Compatible Compatibility / WebGL 2.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap, repeat_disable;
// Bande nette (fractions de la hauteur de l'écran, 0 en haut) et flou maximal (px) au haut et
// au bas de l'écran.
uniform float focus_center = 0.5;
uniform float focus_half = 0.18;
uniform float top_blur_px = 5.5;
uniform float bottom_blur_px = 2.5;
// Lueur : seuil de luminance (après flou), force, teinte.
uniform float glow_threshold = 0.7;
uniform float glow_strength = 0.6;
uniform vec4 glow_tint : source_color = vec4(1.0, 0.86, 0.66, 1.0);
// Étalonnage : teinte multipliée, virage des ombres et des hautes lumières, contraste,
// saturation, vignette.
uniform vec4 grade : source_color = vec4(1.04, 0.99, 0.92, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.47, 0.4, 0.62, 1.0);
uniform vec4 highlight_tint : source_color = vec4(1.0, 0.8, 0.55, 1.0);
uniform float split_strength = 0.12;
uniform float contrast = 1.06;
uniform float saturation = 1.06;
uniform float vignette = 0.3;
// Brume du lointain (haut de l'écran) et lumière du couchant (bord gauche de l'écran).
uniform vec4 haze_color : source_color = vec4(0.95, 0.78, 0.7, 1.0);
uniform float haze_strength = 0.14;
uniform vec4 sun_color : source_color = vec4(1.0, 0.72, 0.42, 1.0);
uniform float sun_strength = 0.1;

float luminance(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// Image floutée d'un rayon d'environ radius_px : mipmap de ce rayon, lue en croix d'un
// demi-pixel de ce niveau (adoucit les blocs du sur-échantillonnage bilinéaire).
vec3 blurred(vec2 uv, vec2 pixel, float radius_px) {
	if (radius_px < 0.3) {
		return textureLod(screen, uv, 0.0).rgb;
	}
	float lod = log2(1.0 + radius_px);
	vec2 o = pixel * exp2(lod) * 0.5;
	return 0.25
			* (textureLod(screen, uv + vec2(o.x, o.y), lod).rgb
					+ textureLod(screen, uv + vec2(-o.x, o.y), lod).rgb
					+ textureLod(screen, uv + vec2(o.x, -o.y), lod).rgb
					+ textureLod(screen, uv + vec2(-o.x, -o.y), lod).rgb);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float y = uv.y;
	// Flou de profondeur par bandes : nul dans la bande nette, croissant jusqu'aux bords.
	float top_edge = focus_center - focus_half;
	float bottom_edge = focus_center + focus_half;
	float above = smoothstep(0.0, max(top_edge, 0.05), top_edge - y);
	float below = smoothstep(0.0, max(1.0 - bottom_edge, 0.05), y - bottom_edge);
	float radius = max(above * top_blur_px, below * bottom_blur_px);
	vec3 c = blurred(uv, SCREEN_PIXEL_SIZE, radius);
	// Lueur : deux largeurs de halo.
	vec3 near_glow = textureLod(screen, uv, 3.0).rgb;
	vec3 wide_glow = textureLod(screen, uv, 5.0).rgb;
	float near_amount = smoothstep(glow_threshold, 1.0, luminance(near_glow));
	float wide_amount = smoothstep(glow_threshold, 1.0, luminance(wide_glow));
	c += (near_glow * near_amount + wide_glow * wide_amount * 0.7) * glow_tint.rgb * glow_strength;
	// Étalonnage.
	c *= grade.rgb;
	float l = luminance(c);
	vec3 toned = mix(c * shadow_tint.rgb * 1.6, c * highlight_tint.rgb * 1.25, smoothstep(0.15, 0.8, l));
	c = mix(c, toned, split_strength);
	c = (c - 0.5) * contrast + 0.5;
	l = luminance(c);
	c = mix(vec3(l), c, saturation);
	// Brume du lointain et lumière du couchant.
	c = mix(c, haze_color.rgb, haze_strength * (1.0 - smoothstep(0.0, 0.45, y)));
	float west = 1.0 - smoothstep(0.0, 0.6, uv.x + 0.4 * y);
	c += sun_color.rgb * sun_strength * west;
	vec2 v = uv - 0.5;
	c *= 1.0 - vignette * dot(v, v) * 1.6;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
