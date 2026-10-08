# Corrections des sprites et décors

Ouvrir [l’aperçu autonome](CORRECTIONS_ASSETS.html) pour examiner les quatre poses
d’attaque de face, de dos et de profil. Les images sont incorporées au HTML :
il peut être ouvert seul dans l’aperçu de Codex. Les PNG et JSON proposés au
téléchargement sont ceux utilisés par le projet.

La prise d’Insania de Nephren a été redessinée sur les douze poses d’attaque.
Les deux mains sont placées sur le manche, derrière la garde. La main de soutien
est partiellement masquée par le corps dans certaines vues de dos. Les autres
animations et le portrait sont conservés.

Valgulious, le Carillon d’Ithea, suit la planche d’arme fournie : lame droite qui
s’élargit vers une extrémité arrondie, plaques claires fissurées, nervure bronze,
garde droite, manche brun et rubans. Les trois planches complètes sont corrigées,
y compris les poses hors combat où l’arme est visible.

Les détails de la bible fournis dans l’audit sont appliqués aux trois vues et
aux portraits : Ithea blond paille, tresses à perles bleues, écharpe rouge,
veste vert pâle et robe brun-rouge ; Lakhesh cheveux pêche, couette latérale et
gilet brun clouté ; Nygglatho chemisier vert vif à volants. Collon retrouve son
bandeau rouge et sa canine, Pannibal son épée de bois et sa brindille, Limeskin
ses cornes, sa tresse à plumes et son collier tribal.

Les poses de profil défectueuses sont corrigées : premier pas de Nygglatho
178 px, première course du serveur 158 px, deux dialogues du boulanger
192 px et deux dialogues du chevalier félin 139 px. Le traitement des
remplacements peut utiliser la hauteur du repos, pour éviter de reproduire
la taille erronée d’une ancienne pose. Un remplacement par indices permet de
conserver les autres poses du mouvement.

Les îles B et C ont chacune une seule silhouette opaque. L’enduit crème est
refait sans quadrillage de bois ; les colombages restent dans les façades de
bâtiments. L’aperçu montre aussi sa répétition 3 × 3.

Les références sont les scans `p023.jpg` pour Valgulious et `p029.jpg` pour
Insania, soit les pages imprimées 22 et 28 du recueil fourni. Les scans restent
hors de cette livraison. Les premières planches, essais intermédiaires et
prompts sont conservés dans `assets/source/resumed_2d/pixel/characters/`.

Les rectangles des atlas sont mesurés après découpe. Le contrôle technique
vérifie leur chargement et les contrats d’animation ; la fluidité et les ancres
des pieds restent à valider visuellement.

```sh
python tools/sukasuka2d/prepare_delivery.py
python tools/sukasuka2d/make_resources.py --activate-pixel-skins
tools/godot --headless --editor --import
xvfb-run -a tools/godot --path . --script tools/hd2d_weapon_preview.gd
python tools/sukasuka2d/make_asset_review.py
```

Les galeries autonomes des priorités [1](PRIORITE_1_AUTONOME.html),
[2](PRIORITE_2_AUTONOME.html), [3](PRIORITE_3_AUTONOME.html) et
[4](PRIORITE_4_AUTONOME.html) contiennent tous les assets de ces lots.
Les galeries avec chemins relatifs restent
destinées au dépôt complet et aux ZIP entièrement extraits.
