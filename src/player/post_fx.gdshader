// Post-traitement HD-2D de la caméra du joueur (CameraRig/PostFX/Screen, rectangle plein écran
// sous l'interface) : ce que le rendu Compatibility ne fait pas lui-même, en une passe.
// - Flou de profondeur à la manière d'Octopath Traveler : net dans une bande autour du joueur,
//   de plus en plus flou vers le haut (le lointain) et un peu vers le bas (le premier plan) ;
//   disque de Poisson de 12 échantillons, rayon croissant (blur_px) hors de la bande nette.
// - Lueur : les pixels clairs (ciel, cristaux, fenêtres) débordent en halo chaud (bloom).
// - Étalonnage chaud du couchant, léger contraste, vignette.
// Lit l'image du monde 3D (hint_screen_texture) ; l'interface, dessinée après, reste nette.
// Compatible Compatibility / WebGL 2.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear, repeat_disable;
// Bande nette (fractions de la hauteur de l'écran, 0 en haut) et flou maximal (px).
uniform float focus_center = 0.56;
uniform float focus_half = 0.16;
uniform float top_blur_px = 5.0;
uniform float bottom_blur_px = 2.5;
// Lueur : seuil de luminance, force, rayon (px).
uniform float glow_threshold = 0.86;
uniform float glow_strength = 0.5;
uniform float glow_radius_px = 9.0;
// Étalonnage : teinte multipliée, contraste, saturation, vignette.
uniform vec4 grade : source_color = vec4(1.04, 0.99, 0.92, 1.0);
uniform float contrast = 1.06;
uniform float saturation = 1.08;
uniform float vignette = 0.28;

const int TAPS = 12;
const vec2 POISSON[TAPS] = {
	vec2(-0.326, -0.406), vec2(-0.840, -0.074), vec2(-0.696, 0.457), vec2(-0.203, 0.621),
	vec2(0.962, -0.195), vec2(0.473, -0.480), vec2(0.519, 0.767), vec2(0.185, -0.893),
	vec2(0.507, 0.064), vec2(0.896, 0.412), vec2(-0.322, -0.933), vec2(-0.792, -0.598)
};

float luminance(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	float y = SCREEN_UV.y;
	float above = clamp((focus_center - focus_half - y) / max(focus_center - focus_half, 0.001), 0.0, 1.0);
	float below = clamp((y - focus_center - focus_half) / max(1.0 - focus_center - focus_half, 0.001), 0.0, 1.0);
	float radius = max(above * above * top_blur_px, below * below * bottom_blur_px);
	vec3 base = texture(screen, SCREEN_UV).rgb;
	vec3 sum = base;
	vec3 glow = vec3(0.0);
	for (int i = 0; i < TAPS; i++) {
		vec2 offset = POISSON[i] * px;
		sum += texture(screen, SCREEN_UV + offset * radius).rgb;
		vec3 g = texture(screen, SCREEN_UV + offset * glow_radius_px).rgb;
		glow += g * smoothstep(glow_threshold, 1.0, luminance(g));
	}
	vec3 c = radius > 0.05 ? sum / float(TAPS + 1) : base;
	c += glow / float(TAPS) * glow_strength;
	c *= grade.rgb;
	c = (c - 0.5) * contrast + 0.5;
	float l = luminance(c);
	c = mix(vec3(l), c, saturation);
	vec2 v = SCREEN_UV - 0.5;
	c *= 1.0 - vignette * dot(v, v) * 1.6;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
