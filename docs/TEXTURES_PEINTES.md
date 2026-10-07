# Textures peintes à commander (ChatGPT ou autre générateur d'images)

Le décor de l'île n° 68 est construit par le jeu ; ce qui lui manque le plus pour s'approcher de
*The Legend of Zelda: Breath of the Wild*, ce sont des **textures peintes à la main**. Ce document
liste les images à produire, avec une consigne prête à donner pour chacune. Le jeu les utilise dès
qu'elles sont déposées dans le dépôt ; tant qu'une texture manque, il garde sa version calculée.

## Règles communes (pour toutes les textures)

- **Tuile sans raccord** (« seamless », « tileable ») : le bord droit doit se raccorder au bord
  gauche et le haut au bas, sans ligne visible quand on répète l'image en mosaïque.
- **Éclairage plat et uniforme** : ni ombre portée, ni reflet, ni lumière venant d'un côté, ni
  vignettage. Le jeu ajoute lui-même la lumière et les ombres.
- **Vue parfaitement de face** (murs, roche, toits) ou **parfaitement de dessus** (sols), sans
  perspective.
- **Style peint à la main**, comme *Breath of the Wild* : touches de pinceau douces, aplats
  légèrement texturés, détails simplifiés, palette naturelle un peu désaturée et chaude (automne,
  soleil couchant). Ni photo, ni rendu réaliste, ni dessin au trait, ni contour noir.
- **Sans texte, sans signature, sans filigrane, sans personnage, sans bordure.**
- **Format** : PNG carré de **1024 × 1024** (sauf indication), couleurs sRGB.
- **Dépôt** : `assets/textures/painted/<nom>.png`, avec exactement le nom indiqué, et une ligne de
  crédit dans `assets/CREDITS.md` (outil, date, licence ; « image générée avec ChatGPT le
  JJ/MM/AAAA »).

Consigne de base à recopier en tête de chaque demande, puis compléter avec le sujet de la ligne :

> Texture de jeu vidéo, tuile carrée sans raccord (seamless, tileable) de 1024 × 1024 px,
> éclairage plat et uniforme sans ombre ni reflet, vue parfaitement de dessus (ou de face pour un
> mur), style peint à la main façon *The Legend of Zelda: Breath of the Wild* : touches de pinceau
> douces, détails simplifiés, palette naturelle un peu désaturée, ambiance d'automne. Sans texte,
> sans bordure, sans personnage. Sujet :

## 1. Sols (priorité 1)

| Nom | Sujet à ajouter à la consigne |
| --- | --- |
| `grass` | Herbe courte d'une prairie vue de dessus, vert-jaune doux (`#789445` en moyenne), petites touffes et variations de teinte, quelques brins plus clairs. |
| `grass_dry` | Herbe sèche et dorée d'automne vue de dessus (`#A39954`), touffes couchées par le vent. |
| `dirt_path` | Chemin de terre battue ocre (`#947A54`) vu de dessus, petits cailloux, traces légères, bords sans herbe. |
| `cobblestone` | Pavés et dalles de pierre usés et irréguliers vus de dessus, gris beige (`#999C99`), joints de terre et de mousse. |
| `sand` | Sable fin ridé par le vent vu de dessus, beige doré (`#C2B087`). |
| `forest_floor` | Sol de forêt vu de dessus : aiguilles de pin, feuilles mortes or et rouille, mousse, terre sombre. |
| `marsh_mud` | Vase humide de marais vue de dessus, brun-vert sombre, flaques et petits roseaux couchés. |

## 2. Roche et île (priorité 1)

| Nom | Sujet à ajouter à la consigne |
| --- | --- |
| `rock_cliff` | Paroi de falaise vue de face : roche gris-bleu (`#696E73` à `#999C99`) en strates horizontales, fissures, arêtes claires usées. |
| `rock_top` | Dessus de rocher vu de dessus : roche grise avec plaques de mousse vert sombre et lichen. |
| `island_underside` | Roche du dessous de l'île vue de face : strates brunes et grises, racines fines qui pendent, sans ciel. |

## 3. Ciel et nuages (priorité 2)

| Nom | Taille | Sujet |
| --- | --- | --- |
| `sky_panorama` | **2048 × 1024** (panorama équirectangulaire 360°, horizon exactement au milieu ; pas besoin de raccord haut et bas, mais les bords gauche et droit se raccordent) | Ciel de fin d'après-midi peint : bleu doux en haut (`#5C87C2`), horizon clair (`#C2D1E0`), quelques nuages cotonneux, soleil bas et chaud à l'ouest-sud-ouest avec halo doré ; aucun sol, aucune montagne. |
| `cloud_sea` | 1024 × 1024 | Mer de nuages vue de dessus : cumulus blancs et gris-bleu serrés, crêtes légèrement dorées, sans ciel ni sol. |

## 4. Bâtiments (priorité 2)

| Nom | Sujet à ajouter à la consigne |
| --- | --- |
| `wood_planks` | Mur de planches de bois verticales patinées vu de face, bois brun (`#8C6645`), planches de teintes un peu différentes, nœuds, clous. |
| `timber_dark` | Poutres de bois sombre (`#594230`) vues de face, veinage marqué, usure aux arêtes. |
| `slate_roof` | Toit d'ardoises bleu-gris (`#5C6675`) vu de face, rangs réguliers d'ardoises en écailles, quelques ardoises plus claires. |
| `tile_roof` | Toit de tuiles de terre cuite (`#A35C47`) vu de face, rangs de tuiles canal, mousse légère. |
| `plaster_wall` | Mur d'enduit crème (`#D9CFB5`) vu de face, enduit un peu craquelé laissant voir quelques pierres. |
| `stone_wall` | Soubassement de moellons de pierre vu de face, pierres irrégulières gris beige, joints sombres, mousse au pied. |
| `iron_plates` | Plaques de fer riveté du port vues de face (`#737880`), rivets, coulures de rouille. |

## 5. Végétation (priorité 3, avec transparence)

PNG **avec canal alpha** (fond transparent, contours nets, pas de fond blanc), 512 × 512, éclairage
plat, vue de face :

| Nom | Sujet |
| --- | --- |
| `leaves_autumn` | Grappe de feuilles de feuillu d'automne (or `#BD8C38`, rouille `#994F29`, jaune `#C7A84D`) qui remplit le carré, bords découpés. |
| `leaves_pine` | Grappe de rameaux d'aiguilles de pin vert sombre (`#364F33`). |
| `grass_blades` | Touffe d'herbes hautes vert-jaune, vue de côté, base en bas de l'image. |
| `bark` | Écorce de pin brun-gris en tuile sans raccord (sans transparence pour celle-ci). |

## Après la livraison

Dépose les fichiers dans `assets/textures/painted/` (commit ou PR) : la prochaine session Claude
Code vérifie les raccords (et les corrige au besoin par décalage et fondu), règle la taille des
motifs dans les shaders et compare des captures avant et après.
