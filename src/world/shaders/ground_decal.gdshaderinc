// (H9) Décalque au sol (GroundDecal, src/world/ground_decal.gd ; docs/ASSETS_HD2D_MONDE.md,
// section 3.3), partagé par ground_decal.gdshader (alpha découpé) et ground_decal_soft.gdshader
// (alpha doux) : image vue de dessus couchée sur les triangles mêmes du sol, éclairée comme lui
// (hd2d_light.gdshaderinc, relief 1, normales du sol). Pour ne jamais scintiller avec le sol ni
// avec un autre décalque, chaque sommet est tiré vers la caméra le long de son rayon d'une part de
// sa distance (rien ne bouge à l'écran) : depth_bias pour passer au-dessus du sol, plus
// layer_bias par couche (UV2.y : la couche du décalque, les plus hautes dessus) et une part
// propre à l'exemplaire (UV2.x, 0..1, tirée de sa position) : deux décalques superposés ont
// toujours un ordre, le même d'une image à l'autre. Compatible Compatibility / WebGL 2.

uniform sampler2D albedo_texture : source_color, filter_linear, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float depth_bias = 0.001;
uniform float layer_bias = 0.0004;
uniform float instance_bias = 0.0002;

vec4 decal_position(vec3 vertex, vec2 uv2, mat4 modelview, mat4 projection) {
	vec4 view = modelview * vec4(vertex, 1.0);
	view.xyz *= 1.0 - (depth_bias + uv2.y * layer_bias + uv2.x * instance_bias);
	return projection * view;
}
