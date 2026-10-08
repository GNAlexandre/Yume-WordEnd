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

## Afficher un HTML seul dans l’aperçu

La galerie classique utilise les fichiers du dépôt par chemins relatifs. Un
aperçu qui ne reçoit que le HTML ne peut pas charger ces PNG. Pour ce cas,
générer une galerie autonome par lot :

```sh
python3 tools/sukasuka2d/make_gallery.py --catalog assets/source/resumed_2d/priority2_catalog.json --no-archives --embed-images --output docs/sprites/PRIORITE_2_AUTONOME.html
node tools/sukasuka2d/check_gallery.cjs --file docs/sprites/PRIORITE_2_AUTONOME.html --isolated --output /workspace/sukasuka-production/priorite2-autonome.png
```

Pour produire les quatre lots puis leurs contrôles autonomes :

```sh
for priority in 1 2 3 4; do
  python3 tools/sukasuka2d/make_gallery.py --catalog "assets/source/resumed_2d/priority${priority}_catalog.json" --no-archives --embed-images --output "docs/sprites/PRIORITE_${priority}_AUTONOME.html"
  node tools/sukasuka2d/check_gallery.cjs --file "docs/sprites/PRIORITE_${priority}_AUTONOME.html" --isolated --output "/workspace/sukasuka-production/priorite${priority}-autonome.png"
done
python3 tools/sukasuka2d/make_gallery.py
```

Après génération des pages autonomes, la galerie classique affiche les liens des
priorités 1 à 4 présentes dans le dépôt. Chaque lot garde ses images natives et
son catalogue ; les anciens dessins anime restent conservés dans la galerie
complète et ses archives.

Le HTML contient chaque PNG une seule fois, sans conversion ni redimensionnement.
Les liens d’ouverture et de téléchargement utilisent des URL Blob créées à partir
de ces mêmes octets ; les téléchargements conservent le SHA-256 des PNG du projet.
Le catalogue JSON et le manifeste des archives, si celles-ci sont incluses, sont
aussi incorporés. La page ne demande aucun fichier extérieur.

`--catalog` choisit le catalogue affiché. `--no-archives` retire les anciens
dessins anime de cette page, sans toucher à leurs fichiers. `--embed-images`
fonctionne également via `build(destination, embed_images=True)` ; le mode relatif
reste le mode par défaut pour les galeries distribuées avec les assets dans les
ZIP. Les pages par lot limitent la taille du HTML ; la bibliothèque complète
embarquée peut dépasser 100 Mo et doit rester hors des fichiers Git ordinaires.

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

Pour corriger quelques personnages sans recalculer le reste de la bibliothèque :

```sh
python tools/sukasuka2d/prepare_delivery.py --only-characters ithea cat_waiter baker knight_feline
```

Les sources et portraits dédiés des personnages sélectionnés sont traités dans
l’ordre habituel ; les autres entrées du catalogue sont conservées. Une erreur
de découpe interrompt la publication du catalogue ciblé.
Dans `animation_sources`, `indices: [0]` remplace seulement une pose du clip ;
`original_count` décrit toujours les silhouettes présentes dans la planche de
base. `scale_reference: "idle"` ajuste chaque correction à la hauteur de la
première pose de repos. Ce réglage évite de transmettre la hauteur défectueuse
d’un ancien dialogue miniature ou d’un personnage empilé à la nouvelle pose.

`python tools/sukasuka2d/make_asset_review.py` produit un aperçu autonome des
corrections, à partir des rectangles des atlas réellement utilisés. Cette
commande utilise Pillow ; la préparation utilise aussi NumPy et SciPy,
contrairement au simple assemblage HTML de la galerie.

## Contrôle de la galerie

```sh
node tools/sukasuka2d/check_gallery.cjs --root /workspace/Yume-WordEnd --output /workspace/sukasuka-production/atelier2d.png
```

Ce contrôle lance un serveur local temporaire, charge chaque image et lien de
téléchargement, teste les filtres et le débordement horizontal sur mobile. Il
produit une capture de bureau, une capture mobile et un résultat JSON. Il
nécessite Chromium et `playwright-core` ; `PLAYWRIGHT_MODULE` et `CHROMIUM_PATH`
permettent d’en préciser les chemins.
L’option `--page /docs/sprites/PRIORITE_2.html` sélectionne une autre page du dépôt.
`--file <chemin>` accepte aussi un fichier précis. Avec `--isolated`, seul le HTML
est copié dans un répertoire temporaire, sans les dossiers d’assets : toutes les
images doivent se décoder, les téléchargements PNG réels doivent conserver leur
SHA-256, les JSON doivent rester conformes et aucune requête extérieure ne doit
être émise. `--verify-downloads` peut aussi forcer les téléchargements réels dans
le mode classique.
`--verbose` affiche les étapes et une progression par groupes de dix images,
sans afficher les données base64. Le contrôle utilise `image.decode()` avec un
diagnostic borné pour chaque PNG. Les clics de téléchargement sont espacés de
200 ms pour respecter le limiteur Chromium ; chaque événement attendu est borné
à dix secondes. Le débit ne change ni les images ni les empreintes vérifiées.

## Livraison par priorité

Les lots 2, 3 et 4 héritent des priorités documentaires ; les vues et portraits
restent dans le même lot que le personnage. Les effets facultatifs restent
procéduraux. Chaque lot est contrôlé avant création de la galerie et du ZIP :

```sh
python tools/sukasuka2d/make_priority_package.py --priority 2
python tools/sukasuka2d/make_priority_package.py --priority 3
python tools/sukasuka2d/make_priority_package.py --priority 4
```

`--include-native` ajoute les sources conservées ; `--output` choisit le ZIP.
Une image requise absente ou non conforme interrompt la livraison. Les checks
séparés utilisent `tools/hd2d_priorityN_manifest.json`. La bibliothèque de tous
les lots dépasse 25 Mo ; cette taille ne correspond pas à celle du jeu Web, qui
exporte les personnages réellement utilisés. Le contrôle global de bibliothèque
signale toujours le dépassement de son budget de 25 Mo, sans le masquer.
