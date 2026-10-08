# Personnages SukaSuka en 3D

> **Ancienne livraison chibi refusée visuellement.** Les résultats techniques ci-dessous concernent cet ancien pack. La nouvelle direction et les concepts de Chtholly sont dans `assets/source/chtholly/` et `docs/sprites/ATELIER_CHTHOLLY.html`. Ce pipeline de modélisation procédurale ne respecte pas les consignes mises à jour.


Adaptations chibi low-poly construites dans Blender 4.3.2 à partir des 162 pages fournies par l’utilisateur. Ce pack contient des volumes, des squelettes et des animations ; les portraits sont des rendus des modèles. Les cartes restent différées jusqu’aux volumes du récit.

L’inventaire visuel et les correspondances personnage → pages se trouvent dans `docs/sprites/REFERENCES.md` et `reference_inventory.json`. Les scans originaux restent hors du dépôt, dans `/workspace/sukasuka-references/pages/`. Les tailles non indiquées par le cahier des charges sont des dimensions de travail déduites du style, pas des tailles canoniques.

## Régénérer

Depuis la racine du dépôt, avec Blender 4.3.2 :

```bash
blender --background --threads 2 --python tools/sukasuka3d/build_models.py -- --ids chtholly
blender --background --threads 2 --python tools/sukasuka3d/build_models.py
python3 tools/sukasuka3d/assemble.py
source /workspace/cloud-setup/activate.sh
tools/import.sh
python3 tools/sukasuka3d/validate.py
```

Les configurations `heroes.json`, `humanoids.json` et `species.json` contiennent les couleurs, silhouettes, références et réserves de fidélité. Les extensions de géométrie ajoutent les vêtements, armes et particularités des espèces. Les fichiers PNG de palette sont incorporés dans les GLB. Les aperçus de travail sont rendus hors du dépôt dans le dossier temporaire du système (`sukasuka3d/`). La variable `SUKASUKA_PREVIEW_DIR` permet de choisir un autre emplacement ; les rendus de cette livraison sont conservés dans `/workspace/sukasuka-production/3d-pipeline/`.

## Livrables

Chaque dossier `assets/models/characters/<id>/` contient le GLB animé, son `.anim.json`, un portrait transparent 256 × 256, une scène Godot et une ressource `SkinData`. La scène applique les métadonnées d’animation avant que `CharacterVisual` ne prenne en charge le modèle. Les sept ressources dans `data/skins/sukasuka_<id>.tres` rendent ces apparences 3D sélectionnables.

Les modèles regardent vers +Z après export glTF, avec Y vers le haut et l’origine aux pieds. Le matériau utilise une palette de couleurs, une rugosité de 0,82 et aucun métal. Les personnages partagent les noms d’os pour leurs animations. Les clips de combat suivent les cadences et durées de la section 4.3 de `docs/ASSETS_3D.md` ; les PNJ ont repos, marche et parole. Les mouvements de combat sont des adaptations de jeu, pas des affirmations sur le récit.

## Limites artistiques

Ce sont des adaptations procédurales stylisées, pas une reconstruction exacte des dessins officiels : coiffures, visages, vêtements et ornements sont simplifiés. Les textures de peau et les détails fins de dentelle ne sont pas reproduits. Les palettes absentes ou partielles dans les sources au trait sont signalées dans les configurations. Une tenue principale est livrée par personnage ; les autres tenues restent référencées dans l’inventaire. Les deux âges de Souwong et les deux formes d’Eboncandle sont des variantes distinctes.

La provenance de chaque fichier est indiquée dans `assets/CREDITS.md`, et le tableau des personnages dans `assets/characters/CREDITS.md`. Les droits des personnages et dessins sources restent ceux de leurs ayants droit ; la licence du code de génération ne constitue pas une licence sur ces designs.

## Examiner les modèles

Ouvrir `docs/sprites/ATELIER_3D.html` dans un navigateur avec WebGL 2 : les 45 GLB et le moteur de visualisation sont incorporés, aucun serveur ni réseau requis. Choisir un personnage et une animation, tourner la vue ou afficher le squelette.

Pour reconstruire cette galerie après modification des GLB, installer Three.js 0.180.0 et esbuild 0.25.10 dans un dossier de travail, compiler `viewer.js` avec esbuild (`--bundle --format=iife --minify`), puis lancer `python3 tools/sukasuka3d/make_gallery.py --bundle <bundle.js>`. Ces dépendances concernent uniquement la galerie ; le jeu utilise Godot.

## Archive

`python3 tools/sukasuka3d/write_credits.py` met à jour la provenance en conservant les crédits existants. `python3 tools/sukasuka3d/make_package.py --output <destination.zip>` prépare les assets, les profils, la galerie, les sources Blender et un manifeste SHA-256. Extraire dans le projet Yume-WordEnd ; les ressources reposent sur son interface `SkinData`/`CharacterVisual`.

La galerie incorpore Three.js 0.180.0 sous licence MIT : texte dans `docs/sprites/THREE_LICENSE.txt`, également inclus dans le HTML autonome.
