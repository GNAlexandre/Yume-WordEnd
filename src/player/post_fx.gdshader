// Post-traitement HD-2D de la caméra du joueur (CameraRig/PostFX/Screen, rectangle plein écran
// sous l'interface) : ce que le rendu Compatibility ne fait pas lui-même, en une passe.
// - (RD) Le flou de profondeur n'est plus ici : il suit la vraie profondeur, dans le monde 3D
//   (post_fx_depth.gdshader, CameraRig/Camera3D/DepthBlur). top_blur_px et bottom_blur_px restent
//   des uniformes de ce matériau, où les pose le réglage de lumière (HD2DLighting.apply_post) :
//   la caméra (camera_rig.gd) les recopie à chaque image sur le flou de profondeur (lointain, et
//   premier plan à NEAR_BLUR_PER_BOTTOM_PX fois bottom_blur_px).
// - Lueur : ce qui reste clair dans deux niveaux de flou (cristaux, fenêtres, ciel) déborde en
//   halo chaud, large et doux (bloom).
// - Étalonnage de fin d'après-midi d'automne (MONDE.md 5.4 : l'île est toujours au couchant) :
//   teinte chaude, ombres vers le lavande et hautes lumières vers l'or (virage partiel), voile
//   de brume du lointain en haut de l'écran, lumière du soleil couchant depuis l'ouest (la
//   gauche de l'écran : la caméra regarde le nord), contraste, saturation, vignette.
// - (E8b) Effets des jeux, nuls par défaut (le duel ingagnable : src/games/game_vision.gd) : l'image
//   pâlit (pale_amount : part de désaturation, sauf dans un disque net autour de pale_center, de
//   rayon pale_radius en hauteurs d'écran ; 0 : toute l'image) et l'écran blanchit (flash_color,
//   alpha = force). Atmosphere ne les touche pas.
// Les réglages de nuit et de crépuscule changent ces uniformes (src/world/materials/
// hd2d_lighting.gd). Lit l'image du monde 3D (hint_screen_texture) ; l'interface, dessinée après,
// reste nette. Compatible Compatibility / WebGL 2.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap, repeat_disable;
// (RD) Flou du lointain et du bas de l'écran (px), lus par la caméra pour le flou de profondeur.
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
// (E8b) Effets des jeux : pâleur (désaturation hors d'un disque) et écran blanc.
uniform float pale_amount = 0.0;
uniform vec2 pale_center = vec2(0.5, 0.5);
uniform float pale_radius = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);

float luminance(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float y = uv.y;
	vec3 c = textureLod(screen, uv, 0.0).rgb;
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
	if (pale_amount > 0.0) {
		vec2 off = (uv - pale_center) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
		float keep = pale_radius > 0.0 ? 1.0 - smoothstep(pale_radius * 0.55, pale_radius, length(off)) : 0.0;
		c = mix(c, vec3(luminance(c)) * 0.88 + 0.1, pale_amount * (1.0 - keep));
	}
	c = mix(c, flash_color.rgb, flash_color.a);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
