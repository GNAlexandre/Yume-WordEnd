class_name UiStyle
extends RefCounted
## (U1) L'interface « Nuit douce » : ses jetons et ses aides. Propriétaire : U1.
##
## Une seule source : src/ui/wordend_theme.tres. Chaque écran le porte à sa racine (`theme`) et
## tout Control qu'on y ajoute en prend le style sans rien faire : panneau prune translucide aux
## coins arrondis et filet doré (PanelContainer), entrées en texte simple avec halo et point doré
## (Button), titres en serif doré (HeaderLabel), texte crème ombré (Label)…
## Les jetons que lisent les scripts sont les éléments du type « Nuit » du thème :
## - couleurs (UiStyle.color) : panel (fond des panneaux), gold (filet, noms, accents), cream
##   (texte), ink (prune foncé des glyphes sur l'or), muted (texte secondaire), error, black
##   (fondu des cartes) ; les voiles sont des styles (Panel aux variations Dim, FadeBlack,
##   FlashWhite, GoldRule, BandeauVeil) ; l'indicateur de suite du dialogue et sa géométrie sont
##   au type DialogueBox, les couleurs des boutons tactiles au type TouchButton ;
## - constantes (UiStyle.constant, UiStyle.seconds pour les durées en ms) : appear_ms (fondu
##   d'apparition), slide_px (glissement d'apparition), breath_ms (respiration de l'indicateur
##   de suite), heart_px (taille des cœurs du HUD).
## Le reste (tailles de police, marges, rayons, ombres) est dans les styles du thème.
##
## Aides : frost(panneau) ajoute le verre dépoli (flou de l'arrière-plan sous un panneau dont la
## boîte est une NuitBox) ; appear(nœud) fait entrer un écran en fondu et léger glissement.

const THEME := preload("res://src/ui/wordend_theme.tres")
const FROST_SHADER := preload("res://src/ui/frost.gdshader")
## Type du thème qui porte les jetons.
const TOKENS := &"Nuit"
## Métadonnée d'un nœud en train d'apparaître : [Tween, position de repos].
const APPEAR_META := &"ui_style_appear"


## Couleur du jeton token (type « Nuit » du thème).
static func color(token: StringName) -> Color:
	return THEME.get_color(token, TOKENS)


## Constante du jeton token (type « Nuit » du thème).
static func constant(token: StringName) -> int:
	return THEME.get_constant(token, TOKENS)


## Durée du jeton token (une constante en millisecondes), en secondes.
static func seconds(token: StringName) -> float:
	return constant(token) / 1000.0


## Verre dépoli sous le panneau panel (un Control dont la boîte `panel` est une NuitBox) : le
## fond translucide laisse voir l'arrière-plan flouté. Sans NuitBox, rien ne change.
static func frost(panel: Control, style_name: StringName = &"panel") -> void:
	var box := panel.get_theme_stylebox(style_name) as NuitBox
	if box == null:
		return
	var material := panel.material as ShaderMaterial
	if material == null or material.shader != FROST_SHADER:
		material = ShaderMaterial.new()
		material.shader = FROST_SHADER
		panel.material = material
	material.set_shader_parameter(&"tint", box.fill)


## Retire le verre dépoli de panel.
static func unfrost(panel: Control) -> void:
	var material := panel.material as ShaderMaterial
	if material != null and material.shader == FROST_SHADER:
		panel.material = null


## true si panel a le verre dépoli.
static func is_frosted(panel: Control) -> bool:
	var material := panel.material as ShaderMaterial
	return material != null and material.shader == FROST_SHADER


## Fait apparaître node (déjà visible) : fondu de son opacité et glissement de slide_px vers sa
## place, en appear_ms. node est placé par ses ancres, pas par un conteneur. Un nouvel appel
## pendant l'apparition repart de la place de repos.
static func appear(node: Control, direction: Vector2 = Vector2.DOWN) -> Tween:
	var rest := node.position
	if node.has_meta(APPEAR_META):
		var running: Array = node.get_meta(APPEAR_META)
		(running[0] as Tween).kill()
		rest = running[1]
	var duration := seconds(&"appear_ms")
	node.modulate.a = 0.0
	node.position = rest + direction * float(constant(&"slide_px"))
	var tween := node.create_tween().set_parallel()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, ^"modulate:a", 1.0, duration)
	tween.tween_property(node, ^"position", rest, duration)
	tween.chain().tween_callback(node.remove_meta.bind(APPEAR_META))
	node.set_meta(APPEAR_META, [tween, rest])
	return tween


## Arrête l'apparition de node (s'il apparaissait) et le remet à sa place, opaque.
static func settle(node: Control) -> void:
	if not node.has_meta(APPEAR_META):
		return
	var running: Array = node.get_meta(APPEAR_META)
	(running[0] as Tween).kill()
	node.position = running[1]
	node.modulate.a = 1.0
	node.remove_meta(APPEAR_META)
