// (E9) Rideau de pluie à l'écran (AtmosphereRig, src/world/atmosphere_rig.gd) : la bande animée
// du cahier n° 3 (assets/hd2d/anim/rain_curtain.png ou rain_drizzle.png : frames images de
// 384 × 384 côte à côte, alpha doux, chacune sans raccord sur les quatre bords) répétée sur tout
// l'écran, une image de la bande couvrant tile_px pixels d'un écran haut de 720 (à l'échelle de
// la fenêtre), en deux couches décalées (la seconde plus grande et plus pâle : la pluie proche).
// Rectangle plein écran d'un CanvasLayer au-dessus du post-traitement et sous l'interface : un
// draw call. intensity (0..1) en règle l'opacité ; rain_time est posé par le nœud (arrêté pendant
// la pause). Compatible Compatibility / WebGL 2.
shader_type canvas_item;

uniform sampler2D strip : source_color, filter_linear, repeat_enable;
uniform float frames = 4.0;
uniform float fps = 12.0;
uniform float tile_px = 384.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.82, 0.86, 0.95, 1.0);
uniform float rain_time = 0.0;

vec4 layer(vec2 screen_px, float scale, float phase) {
	vec2 cell = fract(screen_px / (tile_px * scale) + vec2(phase, phase * 0.37));
	float frame = floor(mod(rain_time * fps + phase * frames, frames));
	return texture(strip, vec2((frame + cell.x) / frames, cell.y));
}

void fragment() {
	vec2 size = 1.0 / SCREEN_PIXEL_SIZE;
	// Pixels d'un écran haut de 720 : la pluie garde sa taille quelle que soit la fenêtre.
	vec2 screen_px = SCREEN_UV * size * (720.0 / size.y);
	vec4 near = layer(screen_px, 1.6, 0.5);
	vec4 far = layer(screen_px, 1.0, 0.0);
	float alpha = clamp(far.a + near.a * 0.6, 0.0, 1.0);
	vec3 c = (far.rgb * far.a + near.rgb * near.a * 0.6) / max(far.a + near.a * 0.6, 0.001);
	COLOR = vec4(c * tint.rgb, alpha * intensity * tint.a);
}
