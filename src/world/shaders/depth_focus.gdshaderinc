// (RD) Mise au point HD-2D partagée : le flou (px à 720 px de haut) d'un point selon sa profondeur
// le long de l'axe de la caméra (m), net dans une bande autour du joueur. Lu par le flou de
// profondeur de l'écran (src/player/post_fx_depth.gdshader, qui floute le décor opaque) et par les
// matériaux mélangés, dessinés après lui, qui se floutent eux-mêmes (ombres des décors, décalques
// doux, panneaux à alpha doux, ciel qui dérive) : sans quoi une flaque ou une ombre resterait nette
// sur un sol flou. La caméra du joueur (camera_rig.gd) pose ces uniformes à chaque image sur le flou
// de l'écran, et DepthFocus (src/world/depth_focus.gd) les recopie sur les matériaux inscrits.
// Compatible Compatibility / WebGL 2.

// Profondeur du joueur (m), bande nette devant lui (vers la caméra) et derrière lui (m).
uniform float focus_depth = 21.0;
uniform float focus_near = 1.8;
uniform float focus_far = 4.0;
// Premier plan : écart (m, au-delà de la bande) où le flou est plein, et ce flou (px).
uniform float near_full = 3.5;
uniform float near_blur_px = 7.0;
// Lointain : écart (m, au-delà de la bande) où le flou est plein, et ce flou (px).
uniform float far_full = 16.0;
uniform float far_blur_px = 5.0;

// Flou (px) du premier plan pour une profondeur.
float focus_near_radius(float z) {
	return near_blur_px * smoothstep(0.0, near_full, focus_depth - focus_near - z);
}

// Flou (px) d'un point à la profondeur z.
float focus_radius(float z) {
	float far_part = far_blur_px * smoothstep(0.0, far_full, z - focus_depth - focus_far);
	return max(focus_near_radius(z), far_part);
}

// Image tex lue floue d'un rayon radius_px (px de l'écran) autour de uv : neuf lectures dans
// l'image, réparties sur le disque d'après les dérivées des UV à l'écran (calculées par l'appelant
// hors de tout branchement), moyennées en alpha prémultiplié (pas de frange sombre au bord).
vec4 focus_tap(sampler2D tex, vec2 uv) {
	vec4 c = textureLod(tex, uv, 0.0);
	return vec4(c.rgb * c.a, c.a);
}

vec4 focus_sample(sampler2D tex, vec2 uv, vec2 uv_dx, vec2 uv_dy, float radius_px) {
	if (radius_px < 0.5) {
		return textureLod(tex, uv, 0.0);
	}
	vec2 ax = uv_dx * radius_px;
	vec2 ay = uv_dy * radius_px;
	vec4 sum = focus_tap(tex, uv);
	sum += focus_tap(tex, uv + ax * 0.5);
	sum += focus_tap(tex, uv - ax * 0.5);
	sum += focus_tap(tex, uv + ay * 0.5);
	sum += focus_tap(tex, uv - ay * 0.5);
	sum += focus_tap(tex, uv + (ax + ay) * 0.65);
	sum += focus_tap(tex, uv - (ax + ay) * 0.65);
	sum += focus_tap(tex, uv + (ax - ay) * 0.65);
	sum += focus_tap(tex, uv - (ax - ay) * 0.65);
	return vec4(sum.rgb / max(sum.a, 0.0001), sum.a / 9.0);
}
