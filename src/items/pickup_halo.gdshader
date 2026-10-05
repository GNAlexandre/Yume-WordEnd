// Halo discret d'un pickup (src/items/pickup.tscn, nœud Mesh) : disque lumineux tourné vers la
// caméra, rayons doux qui tournent lentement. Teinte : ItemData.color (Pickup._apply_item).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.86, 0.52, 1.0);
uniform float strength = 0.6;
uniform float spin = 0.6;
uniform float ray_count = 3.0;

void vertex() {
	// Face à la caméra en gardant l'échelle du nœud (comme le billboard de StandardMaterial3D).
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float angle = atan(p.y, p.x) + TIME * spin;
	float rays = 0.55 + 0.45 * pow(abs(cos(angle * ray_count)), 6.0);
	float glow = 1.0 - smoothstep(0.0, 1.0, r);
	ALBEDO = tint.rgb;
	ALPHA = glow * glow * rays * strength;
}
