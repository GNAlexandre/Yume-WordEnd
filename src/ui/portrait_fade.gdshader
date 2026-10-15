shader_type canvas_item;
// (U1) Portrait en buste de la boîte de dialogue : il s'estompe vers le bas, de `fade_from` (part
// de la hauteur du nœud) jusqu'au bas. La hauteur du nœud (`height`, px) est tenue à jour par
// dialogue_box.gd ; la position locale du sommet sert de repère (les portraits tirés d'une planche
// sont des AtlasTexture : leur UV n'est pas celui du nœud).

uniform float height = 190.0;
uniform float fade_from = 0.72;

varying float local_y;

void vertex() {
	local_y = VERTEX.y;
}

void fragment() {
	float t = clamp(local_y / max(height, 1.0), 0.0, 1.0);
	float fade = 1.0 - smoothstep(fade_from, 1.0, t);
	COLOR.a *= fade;
}
