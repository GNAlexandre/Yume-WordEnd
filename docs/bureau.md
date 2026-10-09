# Application de bureau Windows (bureau)

En plus du jeu dans le navigateur (`https://jeu.yumenovel.fr/`, inchangé : docs/web.md), WordEnd
existe en application Windows avec un installateur. Même projet, même rendu (Compatibility,
OpenGL 3, avec repli automatique sur Direct3D 11 par ANGLE), même jeu : le pck intégré à l'exe
pèse le même poids que celui du Web, à quelques octets près (38,2 Mo).

| Fichier | Pour qui | Contenu |
| --- | --- | --- |
| `WordEnd-Setup-<version>.exe` | les joueurs | l'installateur (français, par utilisateur, sans droits d'administrateur) |
| `WordEnd-<version>-windows-portable.zip` | ceux qui ne veulent rien installer | `WordEnd.exe` seul (le jeu entier : le pck est dans l'exe) |

Windows 10 ou 11 en 64 bits. Les deux fichiers sont attachés à chaque Release GitHub
(`https://github.com/GNAlexandre/Yume-WordEnd/releases/latest`).

## Publier une version

1. (Conseillé) Mettre la version dans `project.godot`, `application/config/version="X.Y.Z"`, par
   une PR fusionnée sur `main`. C'est la seule source de la version : Godot l'écrit dans l'exe
   (Propriétés → Détails), l'installateur l'affiche et l'inscrit dans « Applications et
   fonctionnalités », et elle nomme les fichiers.
2. Sur GitHub : **Releases → Draft a new release → Choose a tag**, taper `vX.Y.Z` (par exemple
   `v0.3.0`), « Create new tag on publish », cible `main` ; un texte si l'on veut (la CI nomme
   la Release « WordEnd X.Y.Z ») ; **Publish release**.
3. Le tag lance la CI (onglet Actions, workflow `ci`) : `check` et `bureau` (installateur et
   zip) en parallèle, puis `release`, qui attache `WordEnd-Setup-X.Y.Z.exe` et le zip à la
   Release et ajoute à son texte le mode d'emploi (SmartScreen, sauvegardes). Compter une
   dizaine de minutes ; si `check` ou `bureau` échouent, aucun fichier n'est attaché (corriger,
   puis supprimer la Release et le tag et recommencer, ou relancer la tâche ratée).

Le tag fait foi : si `project.godot` annonce une autre version, la Release prend celle du tag
et la tâche `bureau` le signale par un avertissement (à corriger ensuite sur `main`). Un tag qui
n'a pas la forme `vX.Y.Z` fait échouer la tâche. Autres façons de publier : `git tag v0.3.0 &&
git push origin v0.3.0`, ou **Actions → ci → Run workflow** sur `main` avec « release » coché
(tag `v<version de project.godot>` créé sur ce commit). Sans tag, chaque PR et chaque push sur
`main` construisent quand même l'installateur et le zip : artefact `bureau` de l'exécution
(7 jours), tailles dans son résumé.

## Construire en local

```bash
bash tools/setup.sh               # Godot 4.7.2, templates Web, Windows et Linux, NSIS, zip (idempotent)
tools/build_desktop.sh            # export Windows → installateur + zip dans build/dist (≈ 2 min)
tools/build_desktop.sh --linux    # en plus : build Linux du même pck, lancé sans écran jusqu'à une partie
tools/desktop_boot.sh --xvfb      # le build Linux sous Xvfb : captures build/shots/bureau_menu*.png
```

`tools/build_desktop.sh` : import, export « Windows Desktop » (`build/desktop/windows/WordEnd.exe`),
`makensis` (`tools/installer/wordend.nsi`, avertissements = erreurs) →
`build/dist/WordEnd-Setup-<version>.exe`, puis le zip. Journaux dans `build/desktop/*.log` ; une
erreur ou un avertissement de Godot non toléré (`tools/warnings_allow.txt`) fait échouer, comme
`tools/check.sh`. `tools/check.sh` ne construit pas l'installateur (trop long) : il vérifie que les
préréglages « Windows Desktop » et « Linux » et le script de l'installateur existent.

`tools/desktop_boot.sh` lance le build Linux deux fois sur un profil neuf (`build/desktop/xdg`)
avec l'argument `--desktop-check=<phase>`, qui fait jouer au jeu exporté lui-même
(`src/desktop_check.gd`, dans le pck : un jeu exporté ignore `--script`) : « Cliquer pour
jouer », menu avec « Plein écran » et « Quitter », F11 et Alt+Entrée, nouvelle partie, quelques
pas, pause, « Quitter le jeu » (partie écrite) ; puis la reprise : plein écran rétabli,
« Continuer ». Journal sans erreur exigé. Sans cet argument, ce nœud n'existe pas.

## Installer, mettre à jour, désinstaller

- **Installer** : télécharger `WordEnd-Setup-X.Y.Z.exe` depuis la page des Releases, le lancer
  (voir SmartScreen ci-dessous), « Suivant », choisir le dossier (par défaut
  `%LOCALAPPDATA%\Programs\WordEnd`), « Installer », « Lancer WordEnd ». Aucun droit
  d'administrateur : le jeu s'installe pour la session Windows en cours. Raccourcis « WordEnd »
  dans le menu Démarrer et sur le Bureau, avec l'icône du jeu.
- **Mettre à jour** : fermer le jeu, lancer l'installateur de la nouvelle version ; il reprend
  le même dossier et remplace l'exe. Les sauvegardes ne bougent pas.
- **Désinstaller** : Paramètres → Applications → Applications installées → WordEnd →
  Désinstaller (ou Panneau de configuration → Programmes et fonctionnalités). Le désinstalleur
  demande s'il faut **garder les sauvegardes** : « Oui » (par défaut, et en désinstallation
  silencieuse `/S`) les laisse pour une prochaine installation, « Non » efface
  `%APPDATA%\WordEnd`.
- **Sans installation** : extraire le zip n'importe où et lancer `WordEnd.exe` ; les sauvegardes
  vont au même endroit.

## « Windows a protégé votre ordinateur » (SmartScreen)

Le jeu et son installateur ne sont pas signés (un certificat de signature de code coûte de
quelques dizaines à quelques centaines d'euros par an). Au premier lancement d'une nouvelle
version, Windows SmartScreen affiche donc « Windows a protégé votre ordinateur » : cliquer sur
**Informations complémentaires**, vérifier « Application : WordEnd-Setup-X.Y.Z.exe », puis
**Exécuter quand même**. Le navigateur peut aussi prévenir que le fichier « n'est pas
couramment téléchargé » : Edge, « … » → Conserver ; Chrome, Conserver. L'avertissement s'efface
de lui-même quand assez de joueurs ont téléchargé la même version. Pour le supprimer : signer
l'exe et l'installateur (par exemple Azure Trusted Signing, ou un certificat OV/EV) dans la
tâche `bureau`, avec un secret du dépôt ; rien n'est prévu pour l'instant.

## Où sont les sauvegardes

| Plateforme | Dossier (`user://`) | Contenu |
| --- | --- | --- |
| Windows | `%APPDATA%\WordEnd` (`C:\Users\<nom>\AppData\Roaming\WordEnd`) | `save_v1.json` (la partie), `settings.cfg` (plein écran), `logs/` |
| Linux | `~/.local/share/WordEnd` | idem |
| Web | IndexedDB du site, `/userfs/godot/app_userdata/WordEnd` | `save_v1.json` (chemin inchangé : les parties du Web sont gardées) |

Le dossier porte le nom du jeu (`application/config/use_custom_user_dir`,
`custom_user_dir_name = "WordEnd"`), et non `Godot\app_userdata\WordEnd`. Le Web n'est pas
concerné : `config/use_custom_user_dir.web=false` lui garde son ancien chemin (vérifié dans
Chromium : la sauvegarde d'une nouvelle partie est écrite sous
`/userfs/godot/app_userdata/WordEnd/`). Pour passer une partie du navigateur au bureau (ou
l'inverse) : menu principal → **Sauvegarde** → copier le texte exporté, puis l'importer de
l'autre côté.

## Dans le jeu

- **Fenêtre** : au lancement, 80 % de l'écran en 16:9, centrée (1536 × 864 sur un écran
  1920 × 1080) ; redimensionnable, 640 × 360 au moins ; l'interface suit (`canvas_items`).
- **Plein écran** : F11 ou Alt+Entrée, partout (menu, partie, pause), ou le bouton « Plein écran :
  oui / non (F11) » du menu principal et du menu pause. Le choix est écrit dans
  `user://settings.cfg` (hors de la sauvegarde) et rétabli au lancement suivant.
- **Quitter** : bouton « Quitter » du menu principal et « Quitter le jeu » du menu pause ; la
  partie en cours est écrite avant (comme « Retour au menu »). Fermer la fenêtre l'écrit aussi.
- Sur le **Web**, rien de cela : ces boutons sont cachés, F11 reste au navigateur, aucun fichier
  de réglages. Inversement, ce qui est propre au Web est sans effet sur le bureau :
  `JavaScriptBridge` n'est appelé que sous `OS.has_feature("web")`, les raccourcis de test ne
  s'activent qu'avec des arguments (`WordEnd.exe -- --zone=dunes`), et les contrôles tactiles
  n'apparaissent qu'au premier toucher (jamais d'emblée, même sur un écran tactile).
- Textes des boutons : `data/texts/story.json`, section `desktop`.

## Réglages d'export (`export_presets.cfg`)

| Préréglage, clé | Valeur | Pourquoi |
| --- | --- | --- |
| « Web » (préréglage 0) | inchangé | reste celui de `tools/check.sh`, du déploiement et du lancement en un clic |
| « Windows Desktop » `binary_format/architecture` | `x86_64` | Windows 10 et 11 64 bits |
| `binary_format/embed_pck` | `true` | un seul fichier : l'exe contient le jeu |
| `texture_format/s3tc_bptc`, `etc2_astc` | `true`, `false` | les formats des cartes graphiques de PC |
| `application/modify_resources` | `true` | icône et métadonnées (produit « WordEnd », éditeur « Yume Novel », description, copyright) écrites dans l'exe par Godot 4.7 lui-même : **ni rcedit ni wine**, aucun avertissement à l'export |
| `application/icon` | `res://tools/installer/wordend.ico` | 16 à 256 px, tirée de `assets/ui/icon.png` (`python3 tools/installer/make_installer_art.py`) |
| `application/file_version`, `product_version` | vides | Godot prend `application/config/version` |
| `debug/export_console_wrapper` | `0` | pas de second exe « console » |
| `codesign/enable` | `false` | pas de certificat (voir SmartScreen) |
| `application/export_angle`, `export_d3d12` | `0` | aucune DLL à côté de l'exe : ANGLE (repli Direct3D 11 du rendu Compatibility) est déjà lié dans le template officiel |
| « Linux » | x86_64, pck intégré, même filtre | lancer le même jeu ici, sans écran, pour prouver qu'il démarre |

Vérifié sur l'export (`7z l build/desktop/windows/WordEnd.exe`) : `.rsrc/version.txt`
(FileVersion 0.3.0.0, ProductName WordEnd, CompanyName Yume Novel…), six icônes
`.rsrc/ICON/1` à `6` et le pck en section `pck`.

## Installateur (`tools/installer/wordend.nsi`)

NSIS 3 (`makensis`, paquet `nsis` sous Linux), interface « Modern UI » en français, installateur
64 bits compressé en LZMA solide. `RequestExecutionLevel user`, dossier
`%LOCALAPPDATA%\Programs\WordEnd` (retenu pour les mises à jour), raccourcis menu Démarrer et
Bureau avec `wordend.ico`, clé `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\WordEnd`
(nom, version, éditeur, icône, taille, désinstalleur, désinstallation silencieuse), page
d'accueil avec le bandeau `welcome.bmp` (le couchant et l'épée de l'écran de démarrage), page de
fin « Lancer WordEnd ». Version et éditeur aussi dans les propriétés de l'installateur.
`tools/installer/` a un `.gdignore` : Godot n'importe ni l'icône ni le bandeau.

## Vérifications faites (8 octobre 2026, Godot 4.7.2)

| Mesure | Valeur |
| --- | --- |
| `WordEnd.exe` (pck intégré) | 168,9 Mo (template 104 Mo + pck 65 Mo) |
| `WordEnd-Setup-0.3.0.exe` | 90,0 Mo (LZMA solide) |
| `WordEnd-0.3.0-windows-portable.zip` | 99,9 Mo |
| `WordEnd.x86_64` (Linux) | 134,9 Mo |
| Web (`tools/build_size.sh`) | 73,5 Mo compressés (wasm 9,7 + pck 63,8), budget 100 : préréglage inchangé |

Tailles mesurées avec toutes les images du cahier n° 2 (lots A à G) ; avant elles, l'installateur
faisait 63,3 Mo et le Web 47,2 Mo.

- `tools/check.sh` vert (793 tests, 155 scènes de fumée, export Web) ; dans Chromium sans écran,
  une nouvelle partie du build Web écrit toujours `/userfs/godot/app_userdata/WordEnd/save_v1.json`
  et rien sous `/userfs/WordEnd`, sans erreur dans la console.
- Build Linux lancé sans écran puis sous Xvfb (avec openbox) : les deux phases de
  `tools/desktop_boot.sh` passent, journal sans erreur ; fenêtre de départ 1536 × 864 sur un
  écran 1920 × 1080 ; captures `build/shots/bureau_menu.png` (menu avec « Plein écran » et
  « Quitter »), `bureau_menu_pause.png`, `bureau_menu_reprise.png`.
- Installateur sous wine 9.0 (Ubuntu 24.04) : installation silencieuse (`/S`) dans
  `C:\users\<nom>\AppData\Local\Programs\WordEnd` (exe, icône, désinstalleur), raccourcis du menu
  Démarrer et du Bureau, clé d'« Applications et fonctionnalités » complète ; désinstallation
  silencieuse : tout est retiré, les sauvegardes restent ; page d'accueil capturée
  (`build/shots/bureau_installateur.png`).
- Le jeu lui-même ne démarre pas sous ce wine 9.0 (plantage dans `kernelbase` dès le lancement,
  le template officiel nu aussi) : limite de wine, pas du projet. **Le jeu n'a pas été lancé sur
  un vrai Windows** : à faire à la première Release (menu, plein écran, sauvegarde dans
  `%APPDATA%\WordEnd`, désinstallation).

## Limites connues

- Pas de signature de code (SmartScreen), pas de mise à jour automatique (relancer
  l'installateur d'une version plus récente), Windows 64 bits seulement.
- Alt+Entrée pendant une conversation fait aussi avancer la réplique (la boîte de dialogue lit
  `ui_accept` avant l'autoload) ; F11 n'a pas cet effet.
- Pas d'export macOS : il demanderait une signature et une notarisation Apple.
