# Export Web et site (Lot 9)

Le jeu est un dossier de fichiers statiques (`build/web`) : GitHub Pages le sert sur
`https://jeu.yumenovel.fr/`, et une page de yumenovel.fr l'affiche dans une iframe. WordPress
n'exécute rien du jeu (PLAN.md section 10).

## Construire et vérifier en local

```bash
tools/godot --headless --export-release Web build/web/index.html   # ~6 s
tools/build_size.sh                       # wasm + pck, brut et gzip, budget 60 Mo (code 1 au-delà)
cp web/CNAME web/embed-test.html build/web/   # comme le déploiement
python3 -m http.server 8000 --directory build/web
```

Puis `http://localhost:8000/` (le jeu) et `http://localhost:8000/embed-test.html` (l'iframe du
site, bouton plein écran, formats 16:9 / 4:3 / portrait, diagnostic WebGL 2 et tactile).
`localhost` est un « contexte sécurisé » ; une adresse du réseau local (`http://192.168…`) ne
l'est pas et le jeu refuse de démarrer : pour essayer sur un téléphone, passer par Pages.

Mesure du 5 octobre 2026 (L0 + L9) : `index.wasm` 37,7 Mo brut → 9,7 Mo gzip, `index.pck` 1,1 Mo
→ 0,9 Mo, soit **10,6 Mo compressés** pour un budget de 25 Mo (dossier complet : 39,1 Mo brut).
Le wasm est le moteur : il ne grossit pas avec le jeu ; le pck suit les assets.

## Réglages d'export (`export_presets.cfg`)

| Clé | Valeur | Pourquoi |
| --- | --- | --- |
| `variant/thread_support` | `false` | Pas de SharedArrayBuffer, donc aucun en-tête COOP/COEP : Pages et WordPress servent le jeu tel quel |
| `variant/extensions_support` | `false` | Pas de GDExtension ; template plus petit |
| `vram_texture_compression/for_desktop` + `for_mobile` | `true` | S3TC/BPTC et ETC2/ASTC (exige `import_etc2_astc` dans project.godot) |
| `html/canvas_resize_policy` | `2` (Adaptive) | Le canevas suit la taille de la fenêtre, donc de l'iframe et du plein écran |
| `html/focus_canvas_on_start` | `true` | Le clavier va au jeu dès le démarrage (dans une iframe, un clic peut rester nécessaire) |
| `html/export_icon` | `true` | `index.icon.png` et `index.apple-touch-icon.png` ; l'icône vient de `application/config/icon` (demande au L0 : docs/CONTRACT_REQUESTS.md) |
| `html/custom_html_shell` | `res://web/shell.html` | Écran de chargement aux couleurs du jeu, en français |
| `progressive_web_app/enabled` | `false` | Pas de service worker : un cache hors ligne servirait de vieilles versions |
| `exclude_filter` | `addons/gut/*, tests/*, tools/*, docs/*, build/*, web/*` | Rien d'inutile dans le pck |

Vérifié sur l'export : `index.html` contient `const GODOT_THREADS_ENABLED = false;` et aucun
`serviceWorker` ; `index.wasm` et `index.js` sont identiques (md5) au template
`web_nothreads_release` ; la mémoire du wasm n'est pas partagée (`shared=false`, contre une
mémoire importée partagée dans le template à threads) ; le moteur l'annonce dans la console du
navigateur : `single-threaded, no GDExtension support`. La CI refait le premier contrôle.

## Chargement

1. **Shell HTML** (`web/shell.html`, avant le moteur) : couchant en dégradé, barre de
   téléchargement (`Téléchargement… 8,0 Mo sur 38,7 Mo`), puis `Démarrage du jeu…`. Si WebGL 2
   manque, un message clair remplace la barre (navigateurs conseillés, accélération graphique),
   de même sans HTTPS ou si le moteur n'a pas pu être téléchargé, avec un bouton « Recharger ».
   Les marqueurs `$GODOT_URL`, `$GODOT_CONFIG`, `$GODOT_THREADS_ENABLED`, `$GODOT_HEAD_INCLUDE`
   sont remplacés par l'export, y compris en headless (tests/unit/test_export_web.gd).
2. **Écran de démarrage du moteur** (intégration M2) : `assets/ui/boot_splash.png`, le même
   couchant que le shell, étiré en « Cover » sur le fond #1b1231 du shell (plus de logo Godot
   sur fond gris) ; l'icône du jeu (`assets/ui/icon.png`) sert de favicon et d'icône iPhone
   (`index.icon.png`, `index.apple-touch-icon.png`). Les deux sont générés par
   `tools/gen_branding.py` (Pillow).
3. **Écran Loading** (`src/ui/loading.tscn`, dans le jeu) : main.gd l'affiche et lui confie le
   chargement de `src/game.tscn` (`load_scene`, intégration M2), dont la barre avance.

**`ResourceLoader.load_threaded_*` sans threads** (code de Godot 4.7.2 lu, `main.cpp`,
`worker_thread_pool.cpp`, `resource_loader.cpp`) : le build mono-thread initialise le
WorkerThreadPool avec 0 fil ; une tâche postée s'exécute aussitôt sur le fil appelant. Donc
`load_threaded_request()` charge toute la scène **dans l'appel lui-même** (le navigateur est figé
pendant ce temps) et `load_threaded_get_status()` répond `THREAD_LOAD_LOADED` dès le premier
appel : aucune progression intermédiaire. Ce n'est ni une erreur ni un gain.
`Loading.load_scene(path)` donne une vraie progression sans thread : elle charge les dépendances
de la scène (feuilles d'abord) en plusieurs images, au plus 50 ms de travail par image, puis la
scène elle-même (`var scene: PackedScene = await loading.load_scene(GAME_SCENE)`) ; main.gd
l'utilise depuis l'intégration M2.

## Contrôles tactiles (`src/ui/touch_controls.tscn`, nœud `UI/TouchControls`)

Joystick à gauche (`move_*` avec intensité, la zone morte de l'input map s'applique ensuite),
Épée, Charge (maintenue), Saut, Parler (affiche l'invite d'`interaction_available`, « Suite »
pendant un dialogue), Cible, Sac, Pause ; glisser ailleurs sur la moitié droite = `camera_*`
(en HD-2D, la caméra est fixe : seuls `camera_up` / `camera_down` servent, au zoom).
Visibles seulement sur écran tactile (`'ontouchstart' in window`, Android, iOS) et dès le
premier toucher ; une touche du jeu, un clic de souris ou un bouton de manette les masquent ;
masqués, ils ne consomment aucun événement. Pause : seuls Pause et Sac restent ; dialogue :
Parler et Pause. Tout passe par des `InputEventAction` : aucun autre lot ne les connaît.
À savoir pour l'intégration : la molette de la caméra (zoom ; la caméra fixe du HD-2D ne
tourne plus à la souris) doit lire `_unhandled_input` (les contrôles
y consomment la souris émulée par le tactile) ; les écrans en pause gardent leur racine en
`mouse_filter = IGNORE` (déjà le cas des squelettes) ; le HUD laisse libre le coin haut droit
(Sac, Pause) et le bas de l'écran.

## Déployer sur GitHub Pages

Le workflow `.github/workflows/ci.yml` vérifie chaque PR et chaque push sur `main` dans le
conteneur `barichello/godot-ci:4.7.2` (`tools/check.sh`, contrôle mono-thread,
`tools/build_size.sh --summary` qui écrit la taille dans le résumé du job, artefacts `web`,
`shots`, `junit`, et `logs` en cas d'échec). Le job `deploy` ne tourne que sur `main` (push ou
« Run workflow ») : il ajoute `web/CNAME` et `web/embed-test.html` au build et publie.

À faire une fois, par le propriétaire du dépôt GitHub :

1. **Settings → Pages → Build and deployment → Source : « GitHub Actions »** (sans cela,
   `actions/configure-pages` échoue : « Get Pages site failed »).
2. **Settings → Environments → github-pages** : la règle de branche créée par GitHub autorise
   `main` ; la laisser ainsi.
3. Pousser sur `main` (ou Actions → ci → Run workflow sur `main`). Le site est servi sur
   `https://gnalexandre.github.io/Yume-WordEnd/` (chemins relatifs : le sous-dossier ne gêne pas).
4. Vérifier une fois la compression :
   `curl -sI -H 'Accept-Encoding: gzip' https://jeu.yumenovel.fr/index.wasm` doit montrer
   `content-type: application/wasm` et `content-encoding: gzip` (le budget suppose le gzip).

## Sous-domaine jeu.yumenovel.fr

1. **DNS** : chez OVH, *Web Cloud → Noms de domaine → yumenovel.fr → Zone DNS → Ajouter une
   entrée → CNAME*, sous-domaine `jeu`, cible `gnalexandre.github.io.` (point final). Si les
   serveurs DNS du domaine sont ceux de WordPress.com (`dig NS yumenovel.fr` répond
   `ns1.wordpress.com`), ajouter le même CNAME dans *WordPress.com → Domaines → yumenovel.fr →
   Enregistrements DNS*.
2. **GitHub** : *Settings → Pages → Custom domain* : `jeu.yumenovel.fr`, Save, attendre la
   vérification DNS, puis cocher **Enforce HTTPS** (certificat en quelques minutes à une heure).
   Avec un déploiement par Actions, GitHub ignore le fichier `CNAME` : c'est ce réglage qui compte
   (`web/CNAME` reste la trace du domaine, utile si l'on change d'hébergeur).
3. Conseillé contre la prise de contrôle du sous-domaine : *Settings du compte → Pages → Add a
   domain* `yumenovel.fr`, puis l'enregistrement TXT `_github-pages-challenge-GNAlexandre` que
   GitHub indique.

## Intégration au site

Snippet de la section 10, à coller tel quel (bloc « HTML personnalisé » ou modèle ci-dessous) :

```html
<div class="yume-game" style="aspect-ratio:16/9;max-width:1280px;margin:0 auto">
  <iframe src="https://jeu.yumenovel.fr/" title="WordEnd"
          allow="fullscreen; gamepad; autoplay" loading="lazy"
          style="width:100%;height:100%;border:0;border-radius:12px"></iframe>
</div>
```

`allow="fullscreen"` laisse le jeu passer lui-même en plein écran ; le bouton de la page, lui,
met l'iframe en plein écran depuis la page (`allowfullscreen` est inutile : Chrome avertit qu'il
est ignoré). Les en-têtes actuels du site le permettent (`Permissions-Policy` ne restreint que
caméra, micro et géolocalisation ; la CSP n'a que `frame-ancestors`) : ne pas y ajouter
`fullscreen=()` ni `gamepad=()`, et si une CSP `frame-src` apparaît, y mettre
`https://jeu.yumenovel.fr`.

**Modèle `page-jeu.php`** pour le thème bloc Yume (Yume-WordPress,
`wp-content/themes/yume/page-jeu.php`, publié avec la release du thème) : utilisé
automatiquement par la page de slug `jeu`, sélectionnable sinon sous le nom « Jeu WordEnd » ; le
contenu de la page s'affiche sous le jeu.

```php
<?php
/**
 * Template Name: Jeu WordEnd
 *
 * Page du jeu WordEnd : le jeu est servi par GitHub Pages (https://jeu.yumenovel.fr/) et
 * affiché dans une iframe ; WordPress n'exécute rien du jeu (Yume-WordEnd, docs/web.md).
 *
 * @package Yume
 */

defined( 'ABSPATH' ) || exit;

$yume_jeu_url = 'https://jeu.yumenovel.fr/';
// En-tête et pied du thème bloc, rendus avant wp_head() (comme template-canvas.php) pour que les
// styles de leurs blocs soient dans <head>.
$yume_jeu_entete = do_blocks( '<!-- wp:template-part {"slug":"header","tagName":"header","className":"yn-site-header"} /-->' );
$yume_jeu_pied   = do_blocks( '<!-- wp:template-part {"slug":"footer","tagName":"footer","className":"yn-site-footer"} /-->' );
?>
<!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
	<meta charset="<?php bloginfo( 'charset' ); ?>">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<?php wp_head(); ?>
	<style>
		.yume-jeu { max-width: 1344px; margin: 0 auto; padding: 0 16px 48px; }
		.yume-jeu__actions { display: flex; flex-wrap: wrap; gap: 8px 16px; align-items: center; max-width: 1280px; margin: 12px auto 24px; }
		.yume-jeu__note { margin: 0; font-size: 0.9rem; color: var(--wp--preset--color--texte-faible); }
	</style>
</head>
<body <?php body_class( 'yn-page-jeu' ); ?>>
<?php wp_body_open(); ?>
<div class="wp-site-blocks">
	<?php echo $yume_jeu_entete; // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped -- HTML des blocs du thème. ?>
	<main id="contenu" class="yn-main yume-jeu">
		<?php while ( have_posts() ) : ?>
			<?php the_post(); ?>
			<h1 class="wp-block-post-title"><?php the_title(); ?></h1>
			<div class="yume-game" style="aspect-ratio:16/9;max-width:1280px;margin:0 auto">
				<iframe id="yume-jeu-cadre" src="<?php echo esc_url( $yume_jeu_url ); ?>" title="WordEnd"
					allow="fullscreen; gamepad; autoplay" loading="lazy"
					style="width:100%;height:100%;border:0;border-radius:12px"></iframe>
			</div>
			<div class="yume-jeu__actions">
				<button type="button" class="wp-element-button" id="yume-jeu-plein-ecran"><?php esc_html_e( 'Plein écran', 'yume' ); ?></button>
				<p class="yume-jeu__note"><?php esc_html_e( 'Nécessite un navigateur compatible WebGL 2 (Firefox, Chrome, Edge, Safari 15 et plus). Clique dans le jeu pour lui donner le clavier ; Échap quitte le plein écran.', 'yume' ); ?></p>
			</div>
			<?php the_content(); ?>
		<?php endwhile; ?>
	</main>
	<?php echo $yume_jeu_pied; // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped -- HTML des blocs du thème. ?>
</div>
<script>
( function () {
	var cadre = document.getElementById( 'yume-jeu-cadre' );
	var bouton = document.getElementById( 'yume-jeu-plein-ecran' );
	var demande = cadre && ( cadre.requestFullscreen || cadre.webkitRequestFullscreen );
	if ( ! bouton ) {
		return;
	}
	// iPhone : pas de plein écran pour une iframe ; le jeu se joue téléphone à l'horizontale.
	if ( ! demande || ! ( document.fullscreenEnabled || document.webkitFullscreenEnabled ) ) {
		bouton.hidden = true;
		return;
	}
	bouton.addEventListener( 'click', function () {
		var promesse = demande.call( cadre );
		if ( promesse && promesse.then ) {
			promesse.then( function () { cadre.focus(); } );
		} else {
			cadre.focus();
		}
	} );
}() );
</script>
<?php wp_footer(); ?>
</body>
</html>
```

## Contraintes du Web

- **Son** : le navigateur exige un geste (clic, toucher, touche) avant tout son ; Godot reprend
  son contexte audio au premier geste dans le canevas. D'où l'écran « Cliquer pour jouer » du
  menu (L10) ; `allow="autoplay"` ne dispense pas de ce geste.
- **Sauvegarde** : `user://` vit dans l'IndexedDB de l'origine `https://jeu.yumenovel.fr`. Elle
  est perdue si le joueur efface les données du site, en navigation privée, et Safari peut
  l'effacer après 7 jours sans visite (ITP). Changer d'adresse (github.io → sous-domaine) repart
  de zéro. `jeu.yumenovel.fr` est du même site que `yumenovel.fr` : l'iframe et l'accès direct
  partagent la sauvegarde, ce que ne ferait pas une iframe vers `github.io` (stockage cloisonné
  des iframes d'un autre site). Parades prévues : export/import JSON au menu, compte WordPress à M4.
- **WebGL 2** obligatoire (rendu Compatibility) : Chrome, Edge, Firefox, Safari 15+ (iOS 15+) ;
  certains vieux Android ou pilotes en liste noire ne l'ont pas : le shell le dit.
- **Taille** : 60 Mo compressés au plus (`tools/build_size.sh`, échoue au-delà ; 25 Mo jusqu'au
  cahier des charges n° 2, relevé pour garder les images sans perte).
  Le premier chargement télécharge tout ; ensuite le cache HTTP du navigateur sert.
- **Mono-thread** : ni `Thread`, ni `OS.execute`, ni chargement en fil séparé (voir plus haut) ;
  les longues tâches se découpent en images.
- **Clavier dans l'iframe** : il faut que l'iframe ait le focus (clic dans le jeu) ; le shell
  donne le focus au canevas au démarrage, ce qui suffit en accès direct.
- **Plein écran** : impossible sur iPhone pour une iframe (Safari ne le permet qu'aux vidéos) ;
  iPad, Android et ordinateurs l'acceptent.

## Ce qui a été vérifié sans écran

Export headless (6 s) ; `tools/build_size.sh` ; `python3 -m http.server` sur `build/web` : chaque
fichier répond 200, `index.wasm` en `application/wasm`. Il n'y a pas de GPU, mais le Chromium
headless de Playwright (141, `/opt/pw-browsers`) fournit un WebGL 2 logiciel (SwiftShader) : le
moteur y démarre en 2 à 3 s sans erreur console, dans la page et dans l'iframe d'`embed-test.html`
(1248 × 702) ; sans WebGL 2 (`--disable-webgl2`) le shell affiche son message ; sur un téléphone
Android simulé (915 × 412, tactile), un toucher sur « Nouvelle partie » lance la partie, les
contrôles tactiles s'affichent, joystick et Épée tenus à deux doigts déplacent Chtholly ; sur
ordinateur (sans tactile), la partie se lance à la souris, aucun contrôle tactile n'apparaît et
le clavier déplace Chtholly. Restent à juger sur de vrais appareils : fluidité, taille des
boutons sous le pouce, Safari iOS.

## Raccourcis de test et vérification M1 (intégration)

Pour atteindre une zone sans parcourir l'île, `src/test_shortcuts.gd` lit des paramètres dans
l'adresse de la page (Web, par `JavaScriptBridge`) ou dans les arguments utilisateur
(`tools/godot -- --zone=dunes`, ou « Main Run Args » de l'éditeur). Sans paramètre, le jeu ne
change pas (testé) ; `src/game.gd` ne crée ce nœud que si l'un d'eux est présent.

| Paramètre | Effet |
| --- | --- |
| `?zone=dunes` | Le joueur part du Spawn du bord du Couchant (`dunes`), tourné vers la cloche de veille : 15 m tout droit (Z/W), puis E lance la veille. Toute zone de l'île : `village` (l'entrepôt des fées), `forest` (les bois du marais), `beach` (le port et le bourg), `hill` (la colline des étoiles), tourné vers son centre ; un nom inconnu est ignoré. La partie (nouvelle ou reprise) garde son état : l'acte 1 en est où il en était. |
| `&timeres=12` | Banc de performance : 12 Timeres (les quatre corps, 24 au plus) errent devant le joueur sans le poursuivre. |
| `?trace=1` | (intégration M2) Le journal seul : la partie (nouvelle ou reprise) n'est pas touchée. |

Avec l'un d'eux, la page reçoit aussi deux aides (acte 1) : `window.wordendFace("nygglatho")`
ou `window.wordendFace(x, z)` tourne le joueur vers un PNJ présent (son `NpcData.id`) ou un
point de l'île ; `window.wordendPos` donne la position du joueur (`[x, z]`) à chaque image. La
marche reste aux touches. (HD-2D) La caméra fixe ne tourne pas, les touches sont relatives à
l'écran (le haut est le nord) : `wordendFace` pose aussi la cible dans `window.wordendAim`
(`[x, z]`), et `tools/web_m2.js` en tire les touches à tenir (W, A, S, D physiques, soit Z, Q,
S, D en AZERTY, seules ou deux à deux), choisies de nouveau toutes les 300 ms en marchant.

Pendant ce temps, la console du navigateur reçoit `[m1] …` à chaque événement (zone, invite,
dialogue, quête et étape de quête, objet, vague, Timere tué, fin de série, dégâts, mort,
réapparition, perte du focus) et, toutes les 2 s, images/s, draw calls, primitives, position du
joueur, état de la sauvegarde et distance du Timere le plus proche. `tools/web_m1.js`
(Playwright, mode d'emploi en tête du fichier) s'en sert pour jouer une partie dans le Chromium
sans écran : nouvelle partie → Couchant → cloche de veille → vague 1 → combat → mort →
réapparition, puis le banc ; `tools/web_m2.js`, pour le début de l'acte 1 (plus bas).

Mesures du 6 octobre 2026 (build de l'intégration M1, Chromium 141 headless, SwiftShader, VM
partagée) : aucun message d'erreur dans la console ; 1,7 à 2,4 images/s seulement (rendu
logiciel : indicatif, sans valeur pour un vrai GPU) ; dans l'arène, 64 à 68 draw calls et 94 000
à 115 000 primitives (5 puis 12 Timeres) ; vue du village au départ : 75 draw calls, 112 000
primitives ; pire vue mesurée : le village vu des dunes (96 draw calls, 156 000 primitives dont
37 000 pour la passe d'ombre). Les mêmes chiffres sortent des captures natives
(`M1_SHOT=perf|village tools/screenshot.sh res://tests/integration/demo_m1.tscn …`, voir
docs/DECISIONS.md, section « Intégration M1 »).

## Vérification de l'acte 1 (navigateur)

`tools/web_m2.js` (Playwright, mode d'emploi en tête du fichier) joue le début de l'acte 1 dans
le Chromium sans écran, puis mesure chaque zone ; dernier argument : `acte1`, `zones` ou `tout`
(par défaut). Recette complète de l'acte 1 : [RECETTE_M2.md](RECETTE_M2.md).

- **`acte1`**, avec `?trace=1` (le journal « [m1] … » seul : la partie est celle du menu, telle
  quelle). Profil neuf : temps jusqu'au menu (repère `window.wordendMenuMs`, posé par
  `src/main.gd` quand le menu s'affiche), « Cliquer pour jouer », Entrée sur « Nouvelle partie » ;
  puis, à pied (touches tirées de `window.wordendAim`), les trois premières étapes
  d'`act1_main` : Nygglatho sous le porche et sa scène (étape `new_officer`), Willem devant la
  salle des armes et ses conseils (`to_the_woods`, drapeau `met_willem`), le portail nord et les
  bois du marais (`rejetons`). Le canevas perd le focus (SaveManager écrit la partie) ; le
  script attend la copie dans IndexedDB, recharge la page (même profil) et « Continuer »
  reprend la partie. Captures : `acte1_web_menu.png`, `acte1_web_entrepot.png`,
  `acte1_web_nygglatho.png`, `acte1_web_willem.png`, `acte1_web_bois.png`,
  `acte1_web_continue.png`.
- **`zones`** : `?zone=<id>` dans un profil neuf pour chacune des cinq zones, nouvelle partie,
  puis 20 s de mesures : images affichées par la page (compteur `requestAnimationFrame`) et
  relevés « [m1] … i/s, draw calls, primitives » du moteur ; captures
  `acte1_web_zone_<id>.png`.

Mesures du 7 octobre 2026 (build de l'intégration de l'acte 1, servi en local, Chromium 141
headless, SwiftShader, VM partagée : images/s indicatives, sans valeur pour un vrai GPU) :

- `acte1` (deux passages, le second sur le build final) : menu en 1,8 à 1,9 s (2,9 à 3,8 s au
  rechargement) ; partie chargée 9,0 à 9,2 s après Entrée (6,8 à 8,4 s au rechargement), la
  page affichant des images pendant le chargement (15 à 16) ; les trois étapes jouées à pied,
  répliques et étapes conformes (« Le vent a hurlé… », « verrouille ta cible », `new_officer`,
  `to_the_woods`, `rejetons`) ; partie copiée dans IndexedDB 12 à 60 s après la perte du focus ;
  après rechargement, « Continuer » reprend dans les bois du marais, à la position quittée
  (écart 0,00 m), à l'étape `rejetons`. Aucune erreur dans la console (seuls avertissements,
  ceux du pilote logiciel : « GPU stall due to ReadPixels »). Le panneau des fées du menu tient
  dans l'écran (`acte1_web_menu.png`).
- `zones` (vue du Spawn de chaque zone, joueur au repos) :

  | Zone | Images/s (page) | Draw calls | Primitives |
  | --- | --- | --- | --- |
  | L'entrepôt des fées (`village`) | 0,33 | 135 | 92 000 |
  | Les bois du marais (`forest`) | 0,40 | 100 | 68 000 |
  | Le bord du Couchant (`dunes`) | 0,41 | 70 | 54 000 |
  | Le port et le bourg (`beach`) | 0,34 | 76 | 59 000 |
  | La colline des étoiles (`hill`) | 0,54 | 72 | 83 000 |

  Le rendu logiciel de Chromium tombe sous l'image par seconde avec le décor de l'île n° 68
  (1,7 à 2,4 images/s pour l'île du jalon M1) : ces chiffres ne disent rien d'un vrai GPU.
  Draw calls et primitives, eux, ne dépendent pas de la machine : tous sous le budget Web du
  monde (150 draw calls, 150 000 primitives : docs/DECISIONS.md, « Monde — budget Web »),
  l'entrepôt au plus près (135). Mesure native de comparaison, rendu logiciel aussi (Xvfb, Mesa
  llvmpipe, 1280 × 720, `src/game.tscn -- --zone=<id>`, 40 s) : entrepôt 5,7 images/s (126 draw
  calls), bois 9,1 (91), Couchant 4,9 (61), port 5,8 (67), colline 4,6 (63).

Build : 18,4 Mo compressés (wasm 9,7 Mo, pck 8,8 Mo ; 47,3 Mo bruts), budget 25 Mo ; le pck
porte l'île n° 68 et les 45 modèles 3D de la PR n° 1 (en refonte).

### Socle HD-2D (7 octobre 2026)

Même méthode (`tools/web_m2.js … tout`, Chromium 141 headless, SwiftShader, VM partagée), sur
le build du socle HD-2D : décor en images, caméra fixe, post-traitement plein écran.

- `acte1` : menu en 2,6 s (3,1 s au rechargement) ; partie chargée 8,2 s après Entrée (6,6 s
  au rechargement) ; les trois étapes jouées à pied, touches choisies d'après la caméra fixe
  (Nygglatho, Willem, le portail nord, `new_officer`, `to_the_woods`, `rejetons`) ; partie
  copiée dans IndexedDB 27 s après la perte du focus ; « Continuer » reprend dans les bois à
  l'étape `rejetons`, écart 0,00 m. Aucune erreur dans la console (seuls avertissements : « GPU
  stall due to ReadPixels » du pilote logiciel).
- `zones` (Spawn de chaque zone, joueur au repos ; entre parenthèses, la mesure d'avant le
  socle) :

  | Zone | Images/s (page) | Draw calls | Primitives |
  | --- | --- | --- | --- |
  | L'entrepôt des fées (`village`) | 0,55 (0,33) | 67 (135) | 17 000 (92 000) |
  | Les bois du marais (`forest`) | 0,56 (0,40) | 55 (100) | 17 000 (68 000) |
  | Le bord du Couchant (`dunes`) | 0,57 (0,41) | 43 (70) | 17 000 (54 000) |
  | Le port et le bourg (`beach`) | 0,53 (0,34) | 50 (76) | 17 000 (59 000) |
  | La colline des étoiles (`hill`) | 0,45 (0,54) | 48 (72) | 17 000 (83 000) |

  Les images/s du rendu logiciel restent sans valeur pour un vrai GPU (le flou de profondeur et
  la lueur, plein écran, pèsent ici sur le processeur) ; draw calls et primitives, eux, baissent
  de 30 à 50 % et de 70 à 80 %. Ces vues (Spawn de chaque zone) ne sont pas celles de la
  mesure native ci-dessous.

Build : **12,4 Mo compressés** (40,8 Mo bruts), budget 25 Mo, désormais tenu par
`tools/check.sh` (rouge au-delà) ; les 45 modèles 3D sont partis, les 99 images de remplacement
du décor pèsent moins de 8 Mo. Mesure native (Xvfb, Mesa llvmpipe, `tools/hd2d_shots.sh`, draw
calls du moteur à l'image 50) : menu 38, cour de l'entrepôt 50, entrepôt de face au zoom le
plus large 70, bois 51, Couchant 32, port 39, colline 50, conversation 53, veille 44 (budget du
HD-2D : 200).

**Sauvegarde et fermeture de l'onglet.** SaveManager écrit la position toutes les 5 s de jeu si
le joueur a bougé (1 m), et au départ : perte du focus, page masquée (`visibilitychange`, que
Godot 4.7 ne relaie pas : SaveManager l'écoute par `JavaScriptBridge`), fermeture. Godot copie
`user://` vers IndexedDB au début de l'image qui suit l'écriture, en asynchrone : avec un vrai
GPU, c'est immédiat ; dans le Chromium logiciel de la VM, le fil principal saturé retarde la
copie de 12 à 70 s selon les essais, et `tools/web_m2.js` l'attend (il lit IndexedDB) avant de
recharger. Un onglet fermé dans la fraction de seconde qui suit une écriture peut donc perdre
cette dernière écriture ; la sauvegarde périodique borne la perte aux 5 dernières secondes de
marche.
Godot range aussi son cache de shaders dans `user://shader_cache` (33 entrées dans IndexedDB,
sans contenu dans le rendu WebGL).
