# Atelier 2D

Ces outils Python utilisent uniquement la bibliothèque standard. Ils regroupent
les nouvelles planches et les premières images 2D sans modifier les PNG.

Depuis la racine du dépôt :

```sh
python3 tools/sukasuka2d/make_gallery.py
python3 tools/sukasuka2d/make_package.py --output /workspace/sukasuka-production/Yume_WorldEnd_2D.zip
```

La galerie est écrite dans `docs/sprites/ATELIER_2D.html`. Elle fonctionne en
ouvrant directement le fichier ou depuis un serveur HTTP. Le ZIP conserve la
structure des chemins relatifs ; il faut le décompresser entièrement avant
d’ouvrir la galerie. Les images disponibles possèdent un lien de téléchargement
et un fond quadrillé pour visualiser leur transparence.

## Catalogue

Les premières planches proviennent de `assets/source/legacy_2d/manifest.json`.
Les nouvelles proviennent de `assets/source/resumed_2d/catalog.json` :

```json
{
  "status": "À examiner",
  "entries": [
    {
      "id": "exemple",
      "name": "Nom de la planche",
      "category": "characters",
      "path": "assets/sprites2d/generated/exemple.png",
      "description": "Contenu précis de la planche",
      "reference_pages": [5, 6],
      "character_ids": ["exemple"],
      "dimensions": [1536, 1024],
      "status": "À examiner",
      "limitations": "Cycles et découpage à vérifier."
    }
  ]
}
```

Les catégories acceptées sont `characters`, `ground`, `cliff`, `buildings`,
`materials`, `props`, `sky`, `environments`, `terrain` et `enemies`. Les filtres
de la galerie sont affichés en français. Les chemins sont relatifs à la racine
du projet. Les identifiants
doivent être uniques. Une image manquante est signalée comme en préparation,
sans produire un lien cassé. Un catalogue absent affiche seulement les archives.
Les entrées `archived: true` ou de style `anime_archive` rejoignent les archives.
Les ébauches à statut `archived*` ou `superseded*` et les anciens chemins
`assets/sprites2d/generated/` / `assets/source/resumed_2d/interim/` sont aussi
archivés ; un style explicite `pixel_art` prime sur ces anciens chemins.

Le paquet inclut le catalogue, la galerie, les outils et les PNG disponibles.
Il ajoute les documents `ASSETS_HD2D.md`, `PRODUCTION_2D.md` et les crédits s’ils
sont présents. Les sources natives et métadonnées de `assets/source/resumed_2d/`
ainsi que les dossiers `assets/sprites2d/metadata/` et `resources/` sont inclus.
Une liste `package_files` à la racine du catalogue permet d’ajouter des fichiers
ou dossiers précis, notamment la scène d’atelier et ses scripts. Les champs
optionnels `source_path`, `metadata_path`, `resource_path`, `portrait_path`,
`runtime_path`, `scene_path` de chaque entrée peuvent aussi les désigner. Les
dépendances statiques `res://` des scènes, ressources et scripts sont ajoutées.
Les fichiers explicitement désignés doivent exister. Le paquet fournit les
ressources à copier dans le dépôt ; ce n’est pas un export du jeu complet.
La scène `scenes/dev/atelier_2d`, les trois scripts `src/visuals/`, les ressources
`data/visuals2d/generated/` et les outils `hd2d_assets.py` / `hd2d_manifest.json`
sont inclus automatiquement s’ils existent.
Il exclut les scans officiels et les modèles 3D. `MANIFEST_SHA256.json` contient
les tailles et empreintes de chaque fichier, vérifiées avec les CRC après
création. L’empreinte du ZIP est aussi écrite dans un fichier `.zip.sha256`.
L’option `--output` du générateur de galerie permet une destination alternative ;
le générateur de paquet utilise toujours la galerie canonique du dépôt.

## Ressources directionnelles Godot

`python3 tools/sukasuka2d/make_resources.py` expose les images actives et leurs
animations dans `data/visuals2d/generated/`. Les archives anime et les images
sous un dossier `.gdignore` restent accessibles dans la galerie, sans produire
de ressources Godot. Un `frames_json_path` (ou `frames_json_paths` par direction)
prime sur la grille déclarée : chaque AtlasTexture utilise le rectangle et
l’ancre effectivement fournis. Les dimensions, les bornes et la cohérence des
cadences et fenêtres de combat entre orientations sont vérifiées.

Le statut `measured_crops_animation_review` signifie que la découpe est mesurée ;
les cycles et contacts des pieds demandent encore une revue visuelle.

Après préparation des trois vues et des portraits de chaque combattant,
`python3 tools/sukasuka2d/make_resources.py --activate-pixel-skins` remplace les
sept skins SukaSuka enregistrés, Chtholly par défaut et le visuel partagé du
Timere. Les identifiants du registre et les quatre tailles d’ennemis sont
conservés. Les autres PNJ ne sont pas ajoutés aux skins jouables.

Tests des métadonnées : `python3 tools/sukasuka2d/test_make_resources.py`.

## Contrôle de la galerie

```sh
node tools/sukasuka2d/check_gallery.cjs --root /workspace/Yume-WordEnd --output /workspace/sukasuka-production/atelier2d.png
```

Ce contrôle lance un serveur local temporaire, charge chaque image et lien de
téléchargement, teste les filtres et le débordement horizontal sur mobile. Il
produit une capture de bureau, une capture mobile et un résultat JSON. Il
nécessite Chromium et `playwright-core` ; `PLAYWRIGHT_MODULE` et `CHROMIUM_PATH`
permettent d’en préciser les chemins.
