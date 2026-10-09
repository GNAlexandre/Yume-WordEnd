# L'acte 1 en jours : « Dans la forêt céleste »

Ce document raconte l'acte 1 jour par jour et scène par scène. Il **remplace la section 3 de
`HISTOIRE.md`** (la quête principale `act1_main`, les quêtes secondaires, les rejetons de Timere et
la veille du Couchant). Il suit le tableau des douze jours de `docs/REFONTE.md` (section 6.1), les
33 scènes relevées par le dossier `docs/lore/canon/v1_vex.md` (rubrique 10) et la chronologie de la
fiche `docs/lore/volumes/vol1.md` (section 9). Les lieux sont ceux de `docs/lore/CARTE.md`, dont il
cite les **points nommés** sous la forme `carte:point` (`entrepot:cour_willem`) ; la vie autour des
scènes (emplois du temps, jeux des petites, faune) est dans `docs/lore/VIE.md`.

**Sources.** Citées comme dans les dossiers : `(V1, « L'Homme sans Marque »)`, `(VEX, « Cinq cents
ans »)`, suivies du numéro de la scène dans le dossier, `[s. 12]`. Ce que l'œuvre ne dit pas et que
ce document décide est marqué **(original)** ; ce qu'elle laisse deviner, **(déduction)** ; une
scène dont le jeu change le point de vue ou le lieu, **(adapté)**. La liste des inventions est en
section 7.

## 0. Mode d'emploi

### 0.1 Le récit en jours

- **Douze jours.** Un jour se compose de **moments** : aube, matin, midi, après-midi, soir, nuit.
  La lumière et le ciel suivent le moment et la météo du jour (lot E9). Le joueur ne voit pas
  d'heure : on compte en **cloches** (V1, « La femme forte et robotique ») ; l'horloge des archives
  sonne chaque moment **(original)**, et la « huitième cloche » du départ tombe au couchant
  **(original)**.
- **Scène clé** : elle se déclenche en un lieu et à un moment (son **déclencheur**). Quand elle
  commence, le monde passe à son moment, jamais en arrière.
- **Séquence** : une scène sans Chtholly, vue d'ailleurs, **sans contrôle** (`docs/REFONTE.md`,
  6.1) ; de 20 s à 2 min ; on peut la passer d'une touche dès qu'on l'a vue une fois.
- **Temps libre** : entre deux scènes clés, le joueur va où il veut parmi les lieux ouverts
  (section 1.3) ; la vie suit `VIE.md`. Le moment n'avance pas tout seul **(original)** : il avance
  quand le joueur déclenche la scène suivante, ou quand il choisit **« Laisser passer le temps »**
  assis sur un banc, une chaise ou son lit (un moment par usage, jamais au-delà du moment de la
  prochaine scène clé). Ainsi rien ne se rate faute de temps.
- **Moment de vie** : facultatif, tiré de l'œuvre (`docs/REFONTE.md`, 6.3), offert à certains
  moments ; il ne bloque rien et revient un autre jour (section 4).
- **Passage au jour suivant** : le soir ou la nuit, quand les scènes clés du jour sont faites,
  Chtholly se couche (`entrepot_etage:chtholly_lit`, invite « Dormir ») ; elle raye son calendrier :
  fondu au noir, la ligne du jour s'écrit à l'écran, aube du jour suivant. Les jours 7 et 8 se
  ferment sur une scène, le jour 12 sur la fin de l'acte.
- **Calendrier** : `wallitem_calendar`, dans la chambre de Chtholly (`chtholly_calendrier`) ; une
  ligne par jour, de sa main, sèche et courte (idées sous chaque jour) ; le jour 12 y est entouré
  dès le jour 1 (section 1.2). On le relit en l'examinant ; il remplace le journal des quêtes
  (`docs/REFONTE.md`, 6.2).
- **Indice discret** : quand une scène clé attend le joueur, une ligne de 60 signes au plus
  s'affiche quelques secondes en bas de l'écran, puis se rappelle par une touche ; ni « ! », ni
  flèche, ni encadré d'objectif (`docs/REFONTE.md`, 6.2).

### 0.2 La fiche d'une scène

Chaque scène donne : **lieu et moment** ; **présents** ; **déclencheur** ; **déroulé** en étapes
de mise en scène ; **choix** (deux au plus, qui ne changent pas l'histoire) ; **répliques**
(idées paraphrasées, jamais recopiées : le texte du jeu reste à écrire) ; **contrôle** (ce que le
joueur fait) ; **indice** ; **source**.

Mots de la mise en scène, pour le lot E6 **(original)** :

| Mot | Sens |
| --- | --- |
| **caméra du jeu** | la caméra fixe qui regarde le nord (`src/player/camera_rig.gd`) |
| **cadrage** | la caméra glisse vers un point nommé sans tourner, puis revient |
| **gros plan** | la caméra s'approche (21 m → 9 m) sous le même angle |
| **lever les yeux** | le tangage passe de 32° à 15° pour montrer le ciel (colline, départ) |
| **fondu** | au noir (temps qui passe) ou au blanc (souvenir, vol, éblouissement) |
| **coupe** | changement de carte ou de point de vue sans fondu long |
| **planche** | la planche de sprites et son animation : `willem_home:effondre` |

Les animations citées sont celles des planches livrées (`assets/characters/<id>/<id>*.json`) ;
une planche encore à livrer est dite « à livrer » avec sa priorité au cahier n° 3
(`docs/ASSETS_HD2D_SUKASUKA.md`, section 4), et la scène donne son repli.

### 0.3 Ton, pudeur, spoilers

- **Le ton** (`MONDE.md`, 1.4 ; `BIBLE.md`, 9) : la douceur du quotidien sur fond de fin
  annoncée ; l'humour constant (avalanches, menaces gourmandes de Nygglatho, taquineries d'Ithea,
  laconisme de Nephren, sifflantes de Limeskin) ; les drames passent par des gestes ; aucune
  tirade héroïque ; les fées parlent de leur fin avec une légèreté qui doit gêner, pas séduire.
- **La pudeur**, règles de mise en scène :
  - Chtholly a 15 ans ; Willem la traite en enfant (V1). Aucun contenu sexualisé, aucun cadrage
    insistant, jamais de fan-service, surtout sur les petites (`BIBLE.md`, 9.4).
  - Bain, toilette, pyjama : personnages habillés (serviette sur les épaules, pyjama long),
    plans larges ; on ne montre jamais personne dans la baignoire.
  - Le baiser de la nuit de fièvre est **sur le front**, vu en plan large, à contre-jour ; le
    massage du venenum se fait par-dessus la chemise de nuit, la caméra cadre la fenêtre et
    l'horloge.
  - Blessures : on voit un bandage, jamais la plaie ; l'effondrement de Willem est sans sang ; la
    mort hallucinée du duel est un écran blanc et un silence, sans corps.
- **Le dosage des spoilers** (`MONDE.md`, 1.5) : rien au-delà du volume 1 et de l'épisode du VEX.
  Interdits : les cheveux ou les yeux qui rougissent, l'empiètement, l'origine des fées, le Grand
  Sage, la chute de l'île n° 15, Elq, Willem changé en Bête, la mort à venir d'un personnage du
  canon. Clins d'œil permis, marqués **(clin d'œil)** là où ils servent : Tiat rêve d'une épée aussi
  grande que Seniorious ; Lakhesh remercie l'épée qu'elle astique ; Ithea glisse que tout le monde
  joue un rôle ; Nephren dit Willem « fissuré » ; le tableau des corvées porte « Nopht, Rhantolk :
  escorte de surface » ; Nygglatho chasse l'ours quand elle est triste ; le gâteau au beurre se
  fait aux noix.
- **Les noms** : le joueur est Chtholly, `{player}` dans tous les textes ; son nom complet s'écrit
  `{player}` suivi du nom de son arme (« … Seniorious ») ; on ne met jamais « Chtholly » en dur
  dans une réplique (`CLAUDE.md`). Willem l'appelle par son prénom ; les petites aussi.

## 1. L'acte en un coup d'œil

### 1.1 Les douze jours

| Jour | Titre | Moments et météo | Scènes clés (n° du dossier) | Lieux | Fin du jour |
| --- | --- | --- | --- | --- | --- |
| 1 | La nuit du grand vent | soir puis nuit ; vent violent qui hurle, ciel étoilé sans lune | 1.1 à 1.7 (s. 1 à 4) | `port`, `sentier`, `entrepot`, `entrepot_rdc`, `entrepot_etage` | se coucher |
| 2 | Les jours de fuite | matin clair, vent tombé, ciel d'automne | 2.1 à 2.3 (s. 5) | entrepôt | se coucher |
| 3 | Déjeuner en ville | beau et doux | 3.1 à 3.3 (s. 6) | `sentier`, `ville_haute`, `ville_snack` | se coucher |
| 4 | Le dessert spécial | nuages hauts ; après-midi, soir | 4.1 à 4.2 (s. 7) | `entrepot_rdc` | se coucher |
| 5 | Le jeu de Willem | beau, vent léger | 5.1 à 5.3 (s. 8) | champ, salle de lecture | se coucher |
| 6 | Le livre d'images | beau ; nuit fraîche | 6.1 à 6.4 (s. 9, 10) | `entrepot_rdc`, `entrepot_etage` | se coucher |
| 7 | Le jour de pluie | aube grise, pluie le matin, sol mou l'après-midi, coups de vent ; pluie fine au crépuscule | 7.1 à 7.6 (s. 11 à 15) | entrepôt, `salle_des_armes`, `port` | séquence des archives |
| 8 | Le duel et la colline | couvert au réveil, puis bleu d'automne sans nuages ; nuit claire, vent calme | 8.1 à 8.8 (s. 16 à 21) | entrepôt, `colline`, `barocupot` | fondu sur la colline |
| 9 | Le premier matin (VEX) | ciel bleu, matin frais | 9.1 à 9.5 (s. 22 à 25) | clairière, `village`, `cafe`, réfectoire | se coucher |
| 10 | Sous les nuages (VEX) | nuageux, la pluie menace ; brève averse en fin d'après-midi ; nuit dégagée | 10.1 à 10.5 (s. 26 à 28) | clairière, `foret_profonde`, `entrepot_toit`, salle de jeux | se coucher |
| 11 | L'homme-chat (VEX) | matin froid, eau glacée ; beau | 11.1 à 11.4 (s. 29 à 31) | couloir, `village`, `maison_limashenka`, clairière, marais | se coucher |
| 12 | Le départ | beau, froid sec ; couchant cramoisi puis vermillon | 12.1 à 12.3 (s. 32, 33) | entrepôt | fin de l'acte |

Les 33 scènes du dossier sont toutes jouées ou montrées, dans l'ordre du récit. Le **prologue** de
l'île n° 28 (le chat noir, la broche, la rencontre ; V1, « Le chat qui filait et la jeune fille »),
que `docs/REFONTE.md` (6.1) propose en ouverture jouable, n'a pas de carte dans `CARTE.md` : il
reste à décider (section 6).

### 1.2 Écarts avec le tableau de la refonte et avec la chronologie de l'œuvre

| Refonte (6.1) | Ici | Pourquoi |
| --- | --- | --- |
| 2-3 : fuite, déjeuner, dessert | jours 2, 3, 4 | une scène clé par jour pour laisser vivre l'entrepôt ; l'œuvre place le dessert trois jours après l'arrivée (vol1, 9) |
| 4 : salle de lecture, livre d'images | jours 5 et 6 | l'œuvre les sépare d'une semaine (vol1, 9) ; le jour 5 apprend aussi le ballon |
| 5 : souvenir, match, salle des armes, départ des aînées | jour 6 (souvenir, ordre de mission) et jour 7 (départ à l'aube, match et salle des armes en séquences) | l'œuvre met le match, la salle des armes et le retour au port **le même jour de pluie** (V1, « Entrepôt de fées » : pluie le matin, pluie fine au crépuscule) |
| « match après la pluie (jouable) » | séquence | Chtholly est en mission ce jour-là (V1) ; le ballon jouable est celui du temps libre, chaque après-midi dès le jour 5 (`docs/REFONTE.md`, 6.3) |
| 6 : port, fièvre | jour 7, crépuscule et nuit | même jour que le match (V1) |
| 7 : réveil, archives, duel, cristal ; 8 : réunion, fugue, colline | jour 8 ; la nuit des archives est celle du jour 7 | l'œuvre met le duel, le cristal, la réunion, la fugue et la colline le même jour, J−4 (vol1, 9) |
| 9 à 11 (VEX) | jours 9 à 11 | inchangés : l'épisode du VEX tient « entre la nuit de la colline et le départ » (dossier v1_vex, conventions) |
| 12 : départ, épilogue | jour 12 | l'épisode du VEX tient trois jours pleins avant le départ ; le jour 12 est celui du départ |

**Chronologie de l'œuvre et du jeu** (vol1, 9) : l'arrivée (J0 de l'île n° 68) est le jour 1 ; le
dessert, trois jours après, le jour 4 ; le livre d'images, une semaine plus tard, le jour 6 ; les
quelques jours de mission des aînées sont **ramassés en un seul**, le jour 7 (J−5) ; le duel et la
colline, J−4, le jour 8 ; les trois jours du VEX, J−3 à J−1, les jours 9 à 11 ; le départ, au
couchant de J−1 dans l'œuvre, a son jour à lui, le 12 (**un jour de plus, assumé**, pour les adieux
de la scène 12.1, **original**).

**Les nombres dits à voix haute** suivent le calendrier du jeu, jamais un compte qui le
contredirait **(original)** : « dans cinq jours », dit Chtholly la nuit du jour 7, et c'est bien le
départ du jour 12 ; le « un peu plus de dix jours » de la salle de lecture (vol1, 9) et le « dans
trois jours » de l'ordre du cristal (V1, « La femme forte et robotique ») ne sont pas chiffrés à
l'écran, puisque le jeu ramasse le temps : Chtholly compte sur ses doigts sans dire le nombre, et
la voix du cristal confirme « le jour prévu ». Ce jour est **entouré sur le calendrier** de
Chtholly depuis le jour 1 **(original)** : le joueur voit le compte à rebours sans qu'on le lui
dise.

### 1.3 Lieux ouverts et découverte

| Jour | Ouvert | Fermé |
| --- | --- | --- |
| 1 | `sentier`, `entrepot`, `entrepot_rdc`, `entrepot_etage` (la nuit) ; `port` en séquence | tout le reste |
| 2 | toute l'île à pied : `entrepot_toit`, `village`, `cafe`, `colline`, `foret_profonde`, `montagne`, `port` (poste d'amarrage vide) | `salle_des_armes` (porte à cinq serrures, « Fermé à clé » : Nygglatho garde les clés **(original)**) ; `maison_limashenka` (« La maison est close. ») ; la ville (le chemin de la ville est ouvert, mais Ithea propose d'y aller le jour 3 : rien n'empêche d'y aller avant) |
| 3 | `ville_haute`, `ville_marche`, `ville_snack`, `ville_cafe`, `ville_librairie`, `ville_boulangerie`, `ville_horloger` | `ville_projection` (« Pas sans un adulte. » jusqu'au jour 5) |
| 7 | `salle_des_armes` en séquence seulement ; `transport_garde` jamais (on n'y monte pas à l'acte 1, `CARTE.md` 6.3) | — |
| 8 | `barocupot` par la scène 8.7 seulement | — |
| 11 | `maison_limashenka`, scène 11.3, puis en temps libre jusqu'au soir | — |

Une carte se **découvre** quand on y entre à pied ; elle porte alors son nom et sa durée de marche
sur la carte de l'île (`CARTE.md`, 1.2). La ville est découverte le jour 3 au plus tard.

## 2. Les jours

### Jour 1 — La nuit du grand vent (s. 1 à 4)

- **Moment et météo** : du soir à la nuit ; vent violent qui hurle et fait claquer le manteau de
  Willem, ciel étoilé, pas de lune (V1, « L'Homme sans Marque ») ; au sentier, préréglage
  `nuit_sans_lune` : pas une lumière, seulement les étoiles par les trouées et les lumières de fée.
- **État du monde** : les petites sont couchées mais éveillées (elles épient) ; Nygglatho attend
  dans sa chambre, le thé prêt ; Ithea et Nephren restent dans leurs chambres (Willem ne les
  rencontre qu'en ville, le jour 3 : vol1, 2) ; Pannibal est sortie en douce avec son épée de bois
  et sa lumière ; Willem débarque au port.
- **Temps libre** : aucun avant 1.2 ; après 1.6, l'entrepôt de nuit (couloirs à la lueur des
  cristaux, petites qui détalent au bout des couloirs).
- **Passage** : après 1.7, se coucher.
- **Calendrier** : « Un nouveau responsable. Tombé dans le marais avant même d'arriver. »

#### 1.1 Séquence : l'homme au port (s. 1)

- **Lieu et moment** : `port`, nuit tombée.
- **Présents** : Willem (`willem`) ; le passeur (`ferryman`), à peine vu.
- **Déclencheur** : nouvelle partie, après le carton « Cet acte suit le volume 1 de la traduction
  Yume Novel » (`MONDE.md`, 1.5).
- **Déroulé** :
  1. Fondu du noir sur le son du vent. Willem au bord du quai (`port:accostage`), le passeur à côté
     de lui, qui repart aussitôt : on n'entend qu'un bruit de métal, puis ses feux s'éloignent au
     nord, dans le vide (un `airship_far_*` qui rapetisse). Le bateau n'est jamais décrit (V1).
  2. Willem traverse le quai jusqu'au panneau (`port:panneau`). Gros plan sur les flèches rouges :
     2 000 marmer vers la ville à droite, 500 vers l'entrepôt à gauche.
  3. Il remonte son col et part vers l'ouest (sortie `vers_sentier`) ; la caméra reste sur le
     panneau qui tremble dans le vent ; fondu au noir.
- **Répliques (idées)** : Willem, seul, se moque de lui-même : personne ne l'attend, ce qui est
  logique, puisqu'il n'a prévenu personne ; il suppose qu'un message part tout seul à l'entrepôt
  quand quelqu'un arrive (sa supposition, V1).
- **Contrôle** : aucun (40 s).
- **Source** : V1, « L'Homme sans Marque » [s. 1].

#### 1.2 La lumière dans la nuit (s. 2)

- **Lieu et moment** : `entrepot` (porche), puis `sentier`, nuit.
- **Présents** : Chtholly, Nygglatho ; Pannibal, cachée.
- **Déclencheur** : fin de 1.1 ; coupe sur `entrepot:porche_banc`.
- **Déroulé** :
  1. Sous le porche, Nygglatho (`nygglatho_life:hanches`) : le nouveau responsable arrive cette
     nuit, mais le lit de Pannibal est vide, et son épée de bois a disparu. Chtholly fait naître une
     petite lumière dans sa main (`anim/fairy_light`) : elle éclaire 4 m autour d'elle (E9).
  2. Marche libre jusqu'au sentier (sortie `entrepot:vers_sentier`).
  3. Sur le sentier, près de `sentier:premiere_embuscade` : une lumière zigzague dans les roseaux ;
     Pannibal bondit avec son cri de guerre et prend Chtholly pour l'intrus : **combat 3.1**,
     première manche.
  4. Pannibal reconnaît Chtholly, renifle, dit qu'elle a entendu quelqu'un venir du port, et
     repart en courant vers l'est. Chtholly la suit.
- **Choix** (à Nygglatho) : « J'y vais. » / « Encore elle ? » (même suite).
- **Répliques (idées)** : Nygglatho, toute en sourires, se demande si le nouveau sera appétissant,
  et ajoute qu'elle mangerait bien la petite fugueuse pour la peine ; Pannibal, pince-sans-rire,
  explique qu'on frappe d'abord et qu'on regarde ensuite (registre de `BIBLE.md`, 9.3).
- **Contrôle** : marche libre ; combat d'entraînement (3.1).
- **Indice** : « Pannibal est sortie. Cherche-la sur le sentier. »
- **Source** : Pannibal la nuit dans la forêt, épée de bois, lumière, cri de guerre (V1, « L'Homme
  sans Marque ») [s. 2] ; Chtholly envoyée la chercher, et la première embuscade sur elle,
  **(original)** : l'œuvre la fait seulement arriver « avec sa lumière ».

#### 1.3 L'intrus maîtrisé (s. 2)

- **Lieu et moment** : `sentier`, place `embuscade`, nuit.
- **Présents** : Willem, Pannibal, Chtholly.
- **Déclencheur** : Chtholly arrive à `sentier:chtholly_arrivee`.
- **Déroulé** :
  1. Le contrôle se coupe ; cadrage vers l'est : Willem avance à tâtons sur la levée, les pieds
     dans l'eau, et renifle l'odeur du marais. Au nord, la lumière zigzague
     (`sentier:lumiere_pannibal`).
  2. Pannibal jaillit des roseaux avec son cri ; Willem esquive deux fois par réflexe, glisse à la
     troisième et tombe dans l'eau basse (`sentier:marais_chute`), éclaboussures. Pannibal s'assoit
     sur son dos, l'épée de bois levée, et proclame qu'elle a maîtrisé l'intrus (plan large,
     comique).
  3. Contrôle rendu. Chtholly approche ; à 3 m, sa lumière éclaire le visage de Willem : gros plan.
     Ils se reconnaissent : l'homme sans traits du marché de l'île n° 28, la fille au chapeau gris.
  4. Chtholly fait descendre Pannibal ; Willem se relève, trempé.
- **Choix** : « Toi ? » / « Pannibal, descends. Tout de suite. » (même suite).
- **Répliques (idées)** : Willem demande si l'accueil est toujours aussi chaleureux ; Chtholly,
  raide, rappelle qu'elle lui avait demandé de l'oublier ; il répond qu'il a essayé, mais qu'on
  oublie mal quelqu'un qui vous est tombé dessus ; Pannibal exige qu'on reconnaisse sa victoire.
- **Contrôle** : marche au début et à la fin ; séquence de 30 s pendant l'embuscade.
- **Source** : V1, « L'Homme sans Marque » [s. 2] ; la rencontre de l'île n° 28 (V1, « Le chat qui
  filait et la jeune fille »).

#### 1.4 Le chemin de l'entrepôt (original)

- **Lieu et moment** : `sentier`, puis `entrepot`, nuit.
- **Présents** : Chtholly, Willem, Pannibal.
- **Déclencheur** : fin de 1.3.
- **Déroulé** :
  1. Chtholly mène, sa lumière à la main ; Willem la suit à 2 m. Si elle s'éloigne de plus de 8 m,
     il s'arrête : sans sa lumière, il ne voit rien. Pannibal marche devant en agitant son épée.
  2. Arrivée dans la cour : la façade sombre, la lanterne à cristal de la porte, une seule fenêtre
     allumée à l'étage (Nygglatho). Nygglatho sous le porche (`entrepot:porche_banc`).
- **Répliques (idées)** : quelques mots en marchant ; Willem demande ce qu'il y a à garder dans un
  entrepôt perdu dans les bois ; Chtholly répond qu'il verra.
- **Contrôle** : marche, en escorte.
- **Indice** : « Ramène-le à l'entrepôt. »
- **Source** : **(original)** ; pas une lumière sur le sentier (V1, « L'Homme sans Marque »).

#### 1.5 Premiers pas dans l'entrepôt (s. 3)

- **Lieu et moment** : `entrepot` (porche), `entrepot_rdc` (salle de bains, couloirs),
  `entrepot_etage` (chambre de Nygglatho), nuit.
- **Présents** : Willem, Chtholly, Nygglatho ; les petites de l'avalanche n° 1 : Lakhesh (pêche),
  Tiat (jade, **déduction** du dossier), Pannibal (violet), Collon (rose).
- **Déclencheur** : Chtholly arrive à `entrepot:porte_seuil` avec Willem.
- **Déroulé** :
  1. Sous le porche, Nygglatho joint les mains près du visage : elle reconnaît Willem, qu'elle a
     soigné à son réveil (vol1, 2), le trouve bien maigre et l'envoie se laver : il sent le marais.
     Fondu.
  2. Séquence (15 s) : salle de bains ; Willem, déjà rhabillé, cheveux mouillés, serviette sur les
     épaules, devant le miroir : pas de cornes, pas d'écailles, pas d'oreilles de bête ; un « sans
     traits ».
  3. Contrôle rendu : Chtholly attend dans le couloir (`entrepot_rdc:couloir_ouest`) et doit mener
     Willem chez Nygglatho, à l'étage. Les couloirs aux écriteaux (« On ne court pas dans les
     couloirs ») et au planning des corvées (`entrepot_rdc:planning`, à examiner) ; des petites
     cachées derrière les portes chuchotent (« la cible va nous entendre ») et détalent quand Willem
     tourne la tête.
  4. À l'étage, Willem entre chez Nygglatho (`entrepot_etage:nygglatho_the`) ; on entend leurs voix
     à travers la porte. Quand Chtholly revient du palier, les quatre petites sont collées à la
     porte. Elle l'ouvre : **avalanche n° 1** ; les quatre s'écroulent sur le tapis
     (`entrepot_etage:nygglatho_tapis`, animation `tombe`).
  5. Nygglatho sourit « comme une déchirure dans un tissu » : au lit, ou elle les mange ; elles
     s'éparpillent en un instant (`course`). Willem, la tasse à la main, n'est pas tout à fait à
     l'aise devant la troll. Nygglatho envoie Chtholly coucher Pannibal.
- **Choix** (devant la porte) : « Écouter aussi. » (Chtholly colle l'oreille et part dans
  l'avalanche avec elles) / « Ouvrir. » (même suite).
- **Répliques (idées)** : Nygglatho, à Willem : bienvenue, il a l'air délicieux mais il faudra
  l'engraisser ; aux petites : la menace, avec le même sourire ; Willem, à part : il avale sa
  salive.
- **Contrôle** : marche libre dans le rez-de-chaussée et l'étage ; examiner les écriteaux et le
  planning.
- **Indice** : « Conduis Willem chez Nygglatho, à l'étage. »
- **Source** : V1, « L'Homme sans Marque » [s. 3] ; avalanche [ill. V1 image17] ; la porte ouverte
  par Chtholly (le moment scripté de `docs/REFONTE.md`, 4.2), **(original)**.

#### 1.6 Séquence : le dîner de restes (s. 4)

- **Lieu et moment** : `entrepot_rdc`, réfectoire, nuit.
- **Présents** : Willem, Nygglatho ; des têtes de petites à la porte.
- **Déclencheur** : Chtholly a couché Pannibal (elle entre dans `entrepot_etage:dortoir_b`).
- **Déroulé** : Willem mange des restes au bout de la grande table (`refectoire_bout_est`) ;
  Nygglatho lui promet un festin pour le lendemain (V1) ; deux têtes de petites dépassent du
  chambranle et disparaissent quand il lève les yeux (25 s).
- **Contrôle** : aucun.
- **Source** : V1, « L'Homme sans Marque » [s. 4].

#### 1.7 La chambre nue (s. 4)

- **Lieu et moment** : `entrepot_etage`, chambre de Willem, nuit.
- **Présents** : Willem ; Collon, Pannibal, Lakhesh, Tiat et deux fées génériques en pyjama
  (`*_pajamas`) ; Chtholly.
- **Déclencheur** : après 1.6, Chtholly entend du bruit dans le couloir de l'étage (indice).
- **Déroulé** :
  1. Séquence vue du couloir : les petites collées à la porte de Willem ; il ouvre, **avalanche
     n° 2** dans sa chambre nue (un lit, rien d'autre) ; interrogatoire en rafale.
  2. Contrôle rendu : Chtholly arrive à `entrepot_etage:willem_porte` ; poings sur les hanches
     (`chtholly_home:hanches`) : au lit. Les petites s'en vont en chantonnant un au revoir qui
     traîne sur le prénom de Willem.
  3. Willem demande son nom. Elle le donne en entier, jusqu'au nom de son épée, et explique que
     les armes dont il a la charge, ce sont elles. Elle le dit à plat, comme un fait. Il ne rit pas.
     Fondu.
- **Choix** (à la fin) : « Dors bien, responsable. » / « Ne t'inquiète pas pour nous. »
- **Répliques (idées)** : les petites, en chœur : d'où il vient, s'il a des cornes cachées, s'il
  mange les fées, pourquoi il n'a pas de queue ; Chtholly : l'aînée ici, c'est elle ; les fées ne
  sont pas des enfants qu'on protège mais des armes qu'on range, et il n'a pas à s'en faire.
- **Contrôle** : marche ; dialogue.
- **Indice** : « Du bruit devant la chambre du nouveau. »
- **Source** : V1, « L'Homme sans Marque » [s. 4].

### Jour 2 — Les jours de fuite (s. 5)

- **Moment et météo** : de l'aube à la nuit ; matin clair après la nuit de vent, ciel d'automne
  bleu pâle, feuilles au sol (`anim/falling_leaf_*`).
- **État du monde** : l'emploi du temps de base (`VIE.md`, section 2) avec la variation **fuite**
  (`VIE.md`, 3) : les petites détalent quand Willem approche à moins de 6 m. Willem erre autour du
  bâtiment le matin, s'assoit au rebord de sa fenêtre l'après-midi, dîne seul.
- **Temps libre** : toute l'île à pied (section 1.3). Moments de vie : la toilette du matin, aider
  la cuisinière du jour, le thé chez Nygglatho, le goûter au café du village (Nygglatho glisse en
  cachette l'argent de poche, VEX), le linge sur le toit.
- **Passage** : se coucher.
- **Calendrier** : « Les petites ont peur de lui. Lui s'ennuie à sa fenêtre. »

#### 2.1 Le matin de l'aînée (V1 ; VEX)

- **Lieu et moment** : `entrepot_etage`, puis `entrepot_rdc`, aube.
- **Présents** : Chtholly, les petites en pyjama, Nygglatho (panier de linge), Lakhesh.
- **Déclencheur** : début du jour.
- **Déroulé** :
  1. Réveil dans `chtholly_lit` ; le calendrier s'examine pour la première fois (la ligne du
     jour 1 y est).
  2. Les petites en pyjama vont au point d'eau du couloir (`entrepot_rdc:point_eau`), se lavent le
     visage à l'eau froide (`*_pajamas:travaille`) et se brossent les dents ; Chtholly rappelle la
     règle, pour l'exemple.
  3. La cloche du petit-déjeuner sonne. Heure fixe : qui arrive après la seconde cloche (90 s)
     ne trouve plus rien (`docs/REFONTE.md`, 4.1) ; dans ce cas, Lakhesh glisse un morceau de pain à
     Chtholly **(original)**.
- **Contrôle** : marche libre ; ce matin sert de prise en main de la journée.
- **Indice** : « La cloche du petit-déjeuner. Au réfectoire ! »
- **Source** : `docs/REFONTE.md`, 4.1 ; VEX, « L'homme-chat » (la toilette) ; VEX, « Cinq cents
  ans » (argent de poche).

#### 2.2 La fuite (s. 5)

- **Lieu et moment** : `entrepot_rdc`, réfectoire, matin.
- **Présents** : Willem, les petites, Chtholly, Nygglatho.
- **Déclencheur** : Chtholly s'assoit à sa place (`entrepot_rdc:refectoire_allee`).
- **Déroulé** : Willem paraît à la porte ; en un instant les chaises se vident, les petites filent
  par l'autre porte (`course`) ; il mange seul. Chtholly peut s'asseoir en face de lui.
- **Choix** : « Elles ont peur de toi. » / (s'asseoir plus loin, sans un mot).
- **Répliques (idées)** : Willem se demande s'il sent encore le marais ; Chtholly explique que la
  plupart n'ont jamais vu un homme de près, et qu'un sans-traits, c'est pire.
- **Contrôle** : dialogue, puis temps libre.
- **Source** : V1, « Directeur en carton » [s. 5] ; une petite dit voir un garçon pour la première
  fois (V1, « L'Homme sans Marque »).

#### 2.3 Le directeur au rebord de la fenêtre (s. 5)

- **Lieu et moment** : `entrepot_etage`, chambre de Willem, après-midi.
- **Présents** : Willem (`willem_home:assis`, au rebord de la fenêtre, `willem_fenetre`), Chtholly.
- **Déclencheur** : l'après-midi, Chtholly passe devant la porte ouverte (`willem_porte`).
- **Déroulé** : cadrage sur Willem qui regarde dehors ; dialogue de la porte ; il décide d'aller en
  ville le lendemain.
- **Choix** : « Va te promener en ville. » / « Les petites finiront par venir. »
- **Répliques (idées)** : il ne sait pas ce qu'un responsable est censé faire ici : les armes n'ont
  besoin de rien, les enfants le fuient ; Chtholly répond que c'est justement ça, le poste.
- **Contrôle** : dialogue.
- **Indice** : —
- **Source** : V1, « Directeur en carton » [s. 5].

### Jour 3 — Déjeuner en ville (s. 6)

- **Moment et météo** : beau et doux ; la scène clé est à midi, en ville.
- **État du monde** : Willem part pour la ville au matin ; Ithea a décidé de le suivre ; Nephren
  suit Ithea. En ville, les passants s'écartent un peu des fées de l'entrepôt : on y craint la
  maison, à cause de Nygglatho (V1 ; V5).
- **Temps libre** : le matin à l'entrepôt ; l'après-midi en ville (découverte de `ville_haute`,
  `ville_marche` et des boutiques ouvertes), puis retour.
- **Passage** : se coucher.
- **Calendrier** : « Ithea veut tout savoir de lui. Le serveur a cru qu'on venait le manger. »

#### 3.1 L'information (V1)

- **Lieu et moment** : `entrepot`, porche, matin.
- **Présents** : Chtholly, Ithea, Nephren.
- **Déclencheur** : Chtholly sort par la porte d'entrée le matin.
- **Déroulé** : Ithea, assise sur le banc du porche, balance le pied ; le nouveau est parti en
  ville ; qui tient l'information tient l'île : on le suit. Nephren hoche la tête.
- **Choix** : « Allons-y. » / « Laisse-le tranquille. » (Ithea part quand même ; Chtholly suit).
- **Répliques (idées)** : Ithea, « nya-ha-ha », imagine déjà un roman ; Nephren : un mot.
- **Contrôle** : dialogue.
- **Indice** : « Ithea et Nephren t'attendent sous le porche. »
- **Source** : V1, « Directeur en carton » (la formule d'Ithea sur l'information) ; la filature,
  **(original)**.

#### 3.2 Le chemin de la ville (original)

- **Lieu et moment** : `entrepot`, `sentier` (bifurcation), `ville_haute`, matin puis midi.
- **Présents** : Chtholly ; Ithea et Nephren la suivent.
- **Déroulé** : marche libre ; au sentier, la bifurcation (`sentier:bifurcation`) puis le chemin
  qui **descend** vers la ville ; à l'entrée de la ville haute, la rue en pente, les terrasses ;
  un passant homme-bête change de trottoir en voyant les trois fées (gag).
- **Contrôle** : marche ; Ithea bavarde en chemin (répliques d'ambiance).
- **Indice** : « Le snack-bar est sur la rue du café, en ville. »
- **Source** : on descend vers la ville (V3, « Je suis à la maison ») ; la crainte de l'entrepôt
  (V1, « Directeur en carton »).

#### 3.3 Le snack-bar (s. 6)

- **Lieu et moment** : `ville_snack`, midi.
- **Présents** : Willem (au comptoir, `ville_snack:snack_tabouret`), le serveur lycanthrope
  (`snack_vendor`), Chtholly, Ithea, Nephren.
- **Déclencheur** : entrer dans `ville_snack` (`ville_haute:porte_snack`).
- **Déroulé** :
  1. Willem au comptoir ; le lycanthrope fait sauter sa poêle (geste `travaille` à livrer ; repli
     `parle`) : pommes de terre, lard épais, petit pain, soupe dans une tasse (V1).
  2. Les trois aînées entrent ; les oreilles du serveur tombent : il croit que l'entrepôt vient le
     manger ; il sert en tremblant.
  3. Elles s'installent à `ville_snack:snack_table` ; Ithea se présente, présente Nephren, taquine
     Willem en le vouvoyant (« Officier ») ; Nephren l'observe sans un mot.
  4. Ithea commande à voix haute pour trois ; Willem paie ; le serveur respire.
- **Choix** (Ithea demande à Chtholly s'ils se connaissaient) : « Jamais vu. » / « Une fois, sur
  l'île n° 28. »
- **Répliques (idées)** : Ithea, sur Willem, pour Chtholly, à voix pas assez basse : il est mieux
  que dans les romans ; Willem, qui a entendu, demande quels romans ; Nephren : « Mm. »
- **Contrôle** : dialogue, puis temps libre en ville.
- **Source** : V1, « Directeur en carton » [s. 6] ; Willem y rencontre Ithea et Nephren (vol1, 2).

### Jour 4 — Le dessert spécial (s. 7)

- **Moment et météo** : nuages hauts, doux ; scènes l'après-midi et le soir.
- **État du monde** : Willem a obtenu la cuisine pour l'après-midi (d'ordinaire, seule la fée
  chargée de la nourriture du jour y entre : V1) ; la cuisinière du jour (`fairy_12`) le regarde
  faire ; les petites, encore méfiantes, rôdent devant la porte.
- **Temps libre** : le matin ; après le dîner.
- **Passage** : se coucher. À partir d'ici, la variation **fuite** cesse : les petites suivent
  Willem partout (`VIE.md`, 3).
- **Calendrier** : « Il a fait un dessert. Les petites ne fuient plus. »

#### 4.1 La cuisine interdite (s. 7)

- **Lieu et moment** : `entrepot_rdc`, cuisine et porte du réfectoire, après-midi.
- **Présents** : Willem (`willem_cook:travaille`, en tablier), la cuisinière du jour (`fairy_12`),
  les petites espionnes, Chtholly.
- **Déclencheur** : l'après-midi, Chtholly approche de `entrepot_rdc:refectoire_porte_cuisine`.
- **Déroulé** :
  1. Les petites sont collées à la porte de la cuisine et chuchotent ; une odeur de caramel passe
     (particules de vapeur, E9).
  2. Si Chtholly les chasse, elles s'éparpillent et reviennent 20 s plus tard ; si elle se joint à
     elles, cadrage par l'entrebâillement : Willem remue la casserole au fourneau
     (`cuisine_fourneau`).
  3. Willem ouvre : **avalanche** dans la cuisine. Il demande à l'aînée de goûter : Chtholly goûte
     le caramel à la cuillère, l'air de rien, et ne dit rien ; ses joues disent le reste.
- **Choix** : « Je suis des vôtres. » (elle espionne avec elles) / « Dispersez-vous ! » (même
  suite).
- **Répliques (idées)** : les petites en chœur, à voix basse, sur la « cible » ; la cuisinière du
  jour, outrée, sur le règlement ; Willem demande un avis « d'aînée ».
- **Contrôle** : marche ; dialogue.
- **Indice** : « Il se passe quelque chose à la cuisine. »
- **Source** : V1, « Directeur en carton » [s. 7] ; la goûteuse de corvée (vol1, 10) ; l'avalanche à
  la cuisine, **(original)**.

#### 4.2 Le réfectoire illuminé (s. 7)

- **Lieu et moment** : `entrepot_rdc`, réfectoire, soir.
- **Présents** : toute la maison (28 places), Willem, Nygglatho.
- **Déclencheur** : Chtholly s'assoit à sa place à l'heure du dîner.
- **Déroulé** :
  1. Prière, fourchettes levées ensemble ; dîner.
  2. On sert le dessert (`dessert_flans`, flans au caramel : **déduction** du dossier). Première
     cuillère : une petite laisse tomber la sienne ; tintement, silence.
  3. Le réfectoire « s'illumine » : la lumière se réchauffe (E9), les petites se lèvent
     (`saut`), entourent Willem (`course`), l'assaillent de questions.
  4. Nygglatho passe derrière Willem, le renifle : il sent le sucre ; elle se passe la langue sur
     les lèvres (menace gourmande, comique).
- **Choix** (Ithea à Chtholly) : « C'est trop sucré. » / « … Oui. »
- **Répliques (idées)** : les petites veulent savoir s'il en refera demain ; Nygglatho avertit
  qu'elle ne le laissera pas lui voler l'estomac de ses filles (VEX, trait de caractère).
- **Contrôle** : s'asseoir ; dialogue ; temps libre après le dîner.
- **Indice** : « Le dîner est servi. »
- **Source** : V1, « Directeur en carton » [s. 7].

### Jour 5 — Le jeu de Willem (s. 8)

- **Moment et météo** : beau, vent léger ; papillons orange au champ (VEX, ill.).
- **État du monde** : les petites suivent Willem ; après le déjeuner, il leur apprend un jeu de
  ballon où tout le monde joue et où même les maladroites touchent la balle (V1, « Les filles de
  l'entrepôt »). Dès ce jour, le ballon a lieu chaque après-midi (sauf les jours 7 et 8).
- **Temps libre** : partout ; nouveaux moments de vie : le ballon (jouable), la lecture à la
  fenêtre, le cinéma en ville avec un adulte (Nygglatho ou Willem).
- **Passage** : se coucher.
- **Calendrier** : « Plus beaucoup de jours. Ithea m'a encore serrée trop fort. »

#### 5.1 Le jeu de Willem (V1)

- **Lieu et moment** : `entrepot`, champ (`place champ`), midi.
- **Présents** : Willem, une quinzaine de petites ; Chtholly, si elle passe.
- **Déclencheur** : à midi, Chtholly arrive à 15 m du champ, ou « Laisser passer le temps ».
- **Déroulé** : courte séquence (30 s) : Willem pose le ballon à `entrepot:champ_centre`, fait
  deux équipes, rouge et blanche, montre les cages (`champ_but_nord`, `champ_but_sud`) ; la règle
  tient en une phrase : tout le monde joue. Premier coup de pied (`frappe`) ; la partie commence
  (`VIE.md`, 5.1).
- **Contrôle** : aucun pendant la séquence ; ensuite, temps libre.
- **Indice** : « Willem rassemble les petites au champ. »
- **Source** : V1, « Les filles de l'entrepôt » ; équipes, cages, ballon haut dans le ciel (V1,
  « Entrepôt de fées »).

#### 5.2 La fenêtre de la salle de lecture (s. 8)

- **Lieu et moment** : `entrepot_rdc`, salle de lecture, après-midi.
- **Présents** : Chtholly (`chtholly_home:lit`), Nephren (à `lecture_table`, un papier roulé à la
  main), Ithea, une grande qui lit (`fairy_11`).
- **Déclencheur** : Chtholly s'assoit sur la banquette de la fenêtre (`lecture_banquette`, invite
  « S'asseoir à la fenêtre »).
- **Déroulé** :
  1. Coupe sur le champ, vu de loin, comme par la fenêtre (8 s) : les petites courent, Willem au
     milieu, le ballon monte haut dans le ciel.
  2. Retour dans la salle : Ithea entre sans bruit et enlace Chtholly par derrière ; elle la
     taquine : ce n'est pas le ballon qu'elle regarde.
  3. Nephren leur tape la tête de son papier roulé : silence, c'est une salle de lecture.
  4. À voix basse, Chtholly compte sur ses doigts les jours qui restent, sans dire le nombre (le
     jour entouré du calendrier). Le sourire d'Ithea se fige une
     seconde, puis revient. Gorge serrée, rien de plus.
  5. Une petite tape à la vitre : il manque une joueuse chez les blancs (**original**).
- **Choix** (à la petite) : « J'arrive. » (la partie s'ouvre au joueur, 5.3) / « Une autre
  fois. » (elle reste ouverte tout l'après-midi, et les jours suivants).
- **Répliques (idées)** : Ithea, l'air de rien, qu'on ne regarde pas un ballon avec ces yeux-là ;
  Nephren : « Chut. » ; Chtholly, après un temps, qu'il en reste plus beaucoup, et que c'est long
  quand même, quand on y pense.
- **Contrôle** : s'asseoir ; dialogue ; puis temps libre.
- **Indice** : « La banquette de la salle de lecture est libre. »
- **Source** : V1, « Les filles de l'entrepôt » [s. 8] ; « un peu plus de dix jours » (vol1, 9),
  non chiffré ici (section 1.2).

#### 5.3 Le premier match (facultatif, jouable)

- **Lieu et moment** : `entrepot`, champ, après-midi.
- **Présents** : Willem, les petites, Chtholly chez les blancs.
- **Déclencheur** : choix « J'arrive. » en 5.2, ou entrer dans le champ pendant la partie.
- **Déroulé** : la partie de ballon de `VIE.md` (5.1), jouée par le lot E8 : deux mi-temps,
  l'envoi haut dans le ciel, les meilleures buteuses gardées pour la seconde mi-temps.
- **Contrôle** : jeu de ballon.
- **Source** : V1, « Entrepôt de fées » ; V5 ; `docs/REFONTE.md`, 6.3.

### Jour 6 — Le livre d'images (s. 9, 10)

- **Moment et météo** : beau ; nuit fraîche et claire.
- **État du monde** : la vie de base ; le soir, Nygglatho reçoit au cristal l'ordre de mission des
  aînées : départ à l'aube, pour quelques jours, hors de l'île (V1, « Entrepôt de fées » : les
  aînées partent se battre ailleurs).
- **Temps libre** : le matin ; l'après-midi après 6.2 ; le soir.
- **Passage** : se coucher, après 6.4.
- **Calendrier** : « Demain, mission. Il a lu aux petites un livre où les méchants lui
  ressemblent. »

#### 6.1 « Soif de sang ! » (s. 9)

- **Lieu et moment** : `entrepot_rdc`, couloir (`couloir_centre`), matin.
- **Présents** : Willem, Collon, Pannibal, Tiat, Lakhesh, deux fées génériques ; Chtholly.
- **Déclencheur** : Chtholly entre dans le couloir le matin.
- **Déroulé** :
  1. Collon prend son élan et saute à pieds joints dans le dos de Willem (`saut`) ; il tombe à
     genoux ; Pannibal lui fait une clé au bras, assise par terre ; les autres scandent leur cri de
     guerre.
  2. Elles expliquent qu'il faut montrer sa force avant de demander une faveur ; la faveur : qu'il
     leur lise le livre d'images.
  3. Chtholly rappelle qu'on ne court pas dans les couloirs (`chtholly_home:hanches`).
- **Choix** : « Lâchez-le. » / « Montre-moi cette clé de bras, Pannibal. » (Pannibal la tente sur
  le bras de Chtholly, qui s'en défait d'un geste ; gag).
- **Répliques (idées)** : Pannibal, docte, sur l'art de tenir un adversaire ; Lakhesh s'excuse pour
  toutes les autres ; Willem, par terre, accepte de lire, à condition qu'on le lâche.
- **Contrôle** : dialogue, puis temps libre.
- **Indice** : —
- **Source** : V1, « Les filles de l'entrepôt » [s. 9].

#### 6.2 Le livre d'images (s. 9)

- **Lieu et moment** : `entrepot_rdc`, salle de jeux (`jeux_tapis`), après-midi.
- **Présents** : Willem (`willem_home:assis`), une douzaine de petites autour de lui sur le tapis,
  Chtholly.
- **Déclencheur** : l'après-midi, Chtholly entre dans la salle de jeux.
- **Déroulé** :
  1. Les petites lisent seules d'habitude, mais ce livre-là fait peur : elles veulent Willem à côté
     d'elles. Il lit à voix haute l'histoire des emnetwiht, les méchants du livre, qui ont fait
     venir les Bêtes ; les petites disent qu'elles aussi sont des Braves.
  2. Gros plan sur les mains de Willem qui se serrent sur le livre ; un bref fondu au blanc : une
     table d'orphelinat dans une lumière chaude, des voix d'enfants, aucun visage, aucun nom (3 s) ;
     retour.
  3. Il finit la page d'une voix égale. Chtholly le regarde.
- **Choix** : s'asseoir sur le tapis (`assis`) ou rester à la porte (aucune différence).
- **Répliques (idées)** : une petite, au passage le plus effrayant, se cache derrière le bras de
  Willem ; une autre demande s'il a déjà vu un emnetwiht ; il répond qu'il en a connu un, de loin.
- **Contrôle** : marche ; s'asseoir.
- **Indice** : « Les petites ont un livre à faire lire. »
- **Source** : V1, « Les filles de l'entrepôt » [s. 9] ; l'orphelinat (V1, prologue), sans rien
  nommer.

#### 6.3 L'ordre de mission (V1)

- **Lieu et moment** : `entrepot_rdc`, réfectoire, soir.
- **Présents** : toute la maison.
- **Déclencheur** : le dîner.
- **Déroulé** : Nygglatho annonce, mains jointes, que les trois aînées partent à l'aube pour
  quelques jours ; les petites trouvent cela normal et réclament des souvenirs ; Willem regarde
  Chtholly, qui mange.
- **Répliques (idées)** : une petite demande ce qu'on rapporte d'une mission ; Ithea promet des
  histoires ; Willem demande à Nygglatho, à part, ce qu'est cette mission ; elle répond qu'il le
  saura bien assez tôt.
- **Contrôle** : s'asseoir ; dialogue.
- **Indice** : « Le dîner est servi. »
- **Source** : l'absence des aînées (V1, « Entrepôt de fées ») ; l'annonce au dîner,
  **(original)**.

#### 6.4 Le souvenir (s. 10)

- **Lieu et moment** : `entrepot_etage`, chambre de la grande sœur, nuit.
- **Présents** : Chtholly seule ; dans le souvenir, la grande sœur, **en ombre et en voix**
  seulement (aucune planche à commander, **original**).
- **Déclencheur** : après 6.3, quand Chtholly s'approche de son lit, elle ne s'y couche pas :
  l'indice la mène à la porte de la chambre voisine, jamais fermée à clé.
- **Déroulé** :
  1. La chambre en désordre : cartes à jouer par terre, vêtements sur la chaise ; seul le bureau est
     propre (`entrepot_etage:grande_soeur_bureau`).
  2. Examiner le bureau : fondu au blanc ; le souvenir, en lumière sépia (E9) : la même chambre, la
     broche d'argent posée sur le bureau propre ; la voix de la sœur raconte qu'elle l'a volée à sa
     propre aînée ; puis le réfectoire d'autrefois, un gâteau au beurre sur la table, une ombre qui
     le dévore au retour d'un combat, une grande épée posée contre la chaise.
  3. Retour : Chtholly porte la main à la broche, sur sa poitrine. Le gâteau au beurre a disparu
     du menu avant qu'elle ait l'âge de tenir une épée.
- **Répliques (idées)**, monologue intérieur, trois lignes : elle se souvient du rire de sa sœur,
  pas du goût du gâteau ; elle ne sait plus s'il était bon ; elle sait seulement qu'il ne revient
  plus.
- **Contrôle** : marche ; examiner ; puis se coucher.
- **Indice** : « Tu n'arrives pas à dormir. »
- **Source** : V1, « Entrepôt de fées » [s. 10] ; « Le ciel étoilé sous le ciel étoilé » (le
  gâteau disparu du menu) ; la broche visible sur le bureau dans le souvenir seulement
  (`CARTE.md`, 3.2).

### Jour 7 — Le jour de pluie (s. 11 à 15)

- **Moment et météo** : aube grise et brume sur le marais ; pluie le matin ; l'après-midi, sol
  mou, flaques, coups de vent ; au crépuscule, pluie fine au port ; nuit de pluie (V1, « Entrepôt
  de fées »).
- **État du monde** : les trois aînées sont absentes de l'aube au crépuscule ; Willem reste avec
  les petites et Nygglatho. **C'est le seul jour sans Chtholly** : passé l'aube, il se joue en
  séquences, et elle revient au crépuscule.
- **Temps libre** : aucun.
- **Passage** : la séquence des archives (7.6) finit sur un fondu ; aube du jour 8 à l'infirmerie.
- **Calendrier** (écrit le lendemain) : « Pluie. Je ne me souviens pas de tout. Je crois que j'ai
  trop parlé. »

#### 7.1 Le départ dans la brume (original)

- **Lieu et moment** : `entrepot_etage`, puis `entrepot`, aube.
- **Présents** : Chtholly, Ithea, Nephren, Nygglatho ; Willem à sa fenêtre.
- **Déclencheur** : début du jour.
- **Déroulé** :
  1. Chtholly se lève avant les petites ; sous le porche, Nygglatho remet à chacune son épée
     emmaillotée dans un tissu blanc ; Chtholly porte Seniorious au dos (planche `chtholly`).
  2. Marche avec Ithea et Nephren jusqu'à la sortie `entrepot:vers_sentier`.
  3. Séquence : vue de la fenêtre de Willem (`entrepot_etage:willem_fenetre`) ; trois silhouettes
     entrent dans la brume du sentier et s'effacent ; les premières gouttes sur la vitre.
- **Choix** (à Nygglatho) : « On revient dans quelques jours. » / « Garde-les bien. »
- **Répliques (idées)** : Nygglatho, sans changer de sourire, leur dit de rentrer avant qu'elle ait
  faim ; Ithea promet une histoire à chaque petite ; Nephren : « Mm. »
- **Contrôle** : marche, puis séquence.
- **Indice** : « Nygglatho t'attend sous le porche, avec les épées. »
- **Source** : la mission, le tissu blanc des épées (V1, « Entrepôt de fées » ; dossier v1_vex,
  4) ; la marche à l'aube, Willem à la fenêtre, **(original)**. Le transport de la Garde n'est pas
  montré au départ, pour garder intacte son arrivée au port (7.4).

#### 7.2 Séquence : le match après la pluie (s. 11)

- **Lieu et moment** : `entrepot`, champ, après-midi.
- **Présents** : Willem, une vingtaine de petites, Nygglatho (au porche).
- **Déroulé** :
  1. Le terrain est mou, des flaques partout (`mud_patch`, `puddle_*`) ; rouges contre blancs,
     mi-temps, le ballon envoyé haut.
  2. Un coup de vent violent emporte le ballon dans le fourré de l'est (`entrepot:fourre_ballon`).
     Une petite (`fairy_06`, **original**) plonge dedans en riant ; craquement de branches.
  3. Elle ressort, une main sur la cuisse, une tache sombre sur sa jambière ; elle veut continuer,
     les autres trouvent ça normal. Gros plan sur le visage de Willem.
  4. Il la prend dans ses bras et court vers l'entrée ; fondu. À l'infirmerie, Nygglatho bande la
     cuisse (on voit le bandage blanc, jamais la plaie) et dit, calmement, que les fées ne tiennent
     pas à leur corps comme des enfants ordinaires.
- **Contrôle** : aucun (90 s).
- **Source** : V1, « Entrepôt de fées » [s. 11].

#### 7.3 Séquence : la salle des armes (s. 12)

- **Lieu et moment** : `entrepot_rdc` (`porte_armes`), puis `salle_des_armes`, après-midi.
- **Présents** : Willem, Nygglatho.
- **Déroulé** :
  1. Nygglatho ouvre les cinq serrures de la porte rivetée (`door_armory`) ; noir complet
     (préréglage `noir`) ; seule sa lanterne éclaire.
  2. La crypte : des Carillons usés sur leurs râteliers (`salle_des_armes:armes_rateliers`),
     d'autres dans leur tissu.
  3. Gros plan : Willem pose la main sur une garde et la reconnaît ; il ne dit pas d'où.
- **Répliques (idées)** : Nygglatho explique que seules les fées éveillent ces épées ; Willem
  murmure quelques mots sur leur fabrication, puis se tait.
- **Contrôle** : aucun (60 s).
- **Source** : V1, « Entrepôt de fées » [s. 12].

#### 7.4 Le port sous la pluie (s. 13)

- **Lieu et moment** : `port`, crépuscule, pluie fine (`anim/rain_drizzle`, flaques).
- **Présents** : Willem ; Limeskin (`limeskin`) ; Chtholly, Ithea, Nephren.
- **Déclencheur** : fin de 7.3 (fondu).
- **Déroulé** :
  1. Séquence : Willem seul au bord du vide (`port:bord_du_vide`) ; par une trouée, la surface
     grise.
  2. Une lumière perce les nuages (`sky/ship_searchlight`), si forte qu'on ne voit pas la forme du
     navire ; le transport de la Garde se pose de flanc au nord du quai ; les trois bras d'ancrage
     se referment de l'arrière vers l'avant (`anim/mooring_arm_clamp`) ; les deux pales
     ralentissent ; la chaudière se tait ; la trappe s'ouvre dans un souffle.
  3. Limeskin se fait petit pour sortir, jette les épées emmaillotées dans les bras de Willem
     (elles pèsent : gag) et remonte aussitôt : le pont est aux guerriers.
  4. Contrôle rendu : Chtholly descend la passerelle (marqueur `port:from_transport_garde`) ; le
     joueur avance de quelques pas, la caméra tangue (empoisonnement au venenum), elle tombe à
     genoux (`degats`). Willem la prend sur son dos.
  5. Séquence : le retour sous la pluie, Chtholly sur le dos de Willem, Ithea à côté qui parle du
     roman qu'elle lit, Nephren avec les épées ; fondu.
- **Choix** (sur son dos) : « Pose-moi. Je peux marcher. » / (se taire, poser la tête).
- **Répliques (idées)** : Limeskin, en sifflantes, rend les armes à leur gardien et salue les
  guerrières ; Ithea juge que le troisième tome de sa série d'amour l'a plus éprouvée que la
  bataille ; Willem remarque que Chtholly pèse moins que les épées.
- **Contrôle** : cinq secondes de marche, puis séquence.
- **Source** : V1, « Entrepôt de fées » [s. 13] ; le transport (dossier v1_vex, 8).

#### 7.5 La nuit de fièvre (s. 14)

- **Lieu et moment** : `entrepot_rdc`, infirmerie, nuit.
- **Présents** : Chtholly (`infirmerie_lit_a`, `chtholly_home:dort`), Willem (sur la chaise),
  Nygglatho au début (en blouse : `nygglatho_labcoat`, à livrer, prio 2 ; repli
  `nygglatho_life`).
- **Déclencheur** : fin de 7.4.
- **Déroulé** :
  1. Fièvre : l'image ondule et se réchauffe (E9). Nygglatho sort ; Willem reste.
  2. La fièvre fait parler Chtholly (choix ci-dessous) ; dans les deux cas, il comprend : dans
     cinq jours, elle doit ouvrir la porte contre un fragment de Timere qui menace l'île n° 15.
     C'est la première fois que l'acte nomme Timere ; on le dit une fois, simplement.
  3. À demi endormie, elle demande un baiser, comme on demande une dernière faveur. Il l'embrasse
     **sur le front** ; plan large, à contre-jour de la fenêtre.
  4. Il explique les nœuds du venenum : dix points le long du dos, dix minutes. La caméra cadre la
     fenêtre où coule la pluie et l'horloge ; voix seules ; fondu ; elle dort.
- **Choix** : « Dans cinq jours, je dois ouvrir la porte. » / « Rien. Laisse-moi dormir. »
- **Répliques (idées)** : Chtholly, entre deux frissons, dit qu'elle n'a pas peur, que c'est son
  rôle, qu'il n'a pas à faire cette tête ; Willem ne promet rien ; il lui dit de dormir.
- **Contrôle** : dialogue seulement.
- **Indice** : —
- **Source** : V1, « Les valeureux et leurs successeurs » [s. 14] ; le massage (dossier v1_vex, 9).

#### 7.6 Séquence : la nuit blanche aux archives (s. 15)

- **Lieu et moment** : `entrepot_rdc`, archives, nuit.
- **Présents** : Willem, Nephren (`nephren_home`).
- **Déroulé** :
  1. Willem au bureau (`archives_bureau`), dans une mer de papiers, sous l'horloge.
  2. Nephren entre avec un café si sucré qu'il coule comme un sirop et un sandwich (pigeonneau,
     laitue fatiguée, moutarde) ; elle s'assoit à côté de lui et lit avec lui les rapports sur les
     fées et les Carillons.
  3. L'horloge sonne ; ils se sont endormis sur le canapé (`archives_canape`), la tête de Nephren
     sur son genou. Fondu au noir.
- **Contrôle** : aucun (60 s).
- **Source** : V1, « Les valeureux et leurs successeurs » [s. 15]. Ce qu'ils apprennent n'est pas
  dit à l'écran (`MONDE.md`, 1.5).

### Jour 8 — Le duel, la fugue et la colline (s. 16 à 21)

- **Moment et météo** : au réveil, ciel couvert de nuages de pluie, lueur entre eux, puis bleu
  d'automne sans nuages ; nuit claire, vent calme, air limpide (V1).
- **État du monde** : Chtholly se réveille à l'infirmerie ; Willem et Nephren dorment aux archives ;
  après le duel, Willem est couché à l'infirmerie ; les petites sont dans tous leurs états
  (`VIE.md`, 3, variation **Willem malade**).
- **Temps libre** : court, entre 8.2 et 8.3 ; aucun ensuite jusqu'à la colline.
- **Passage** : la colline finit sur un fondu ; Chtholly se réveille dans son lit (aube du jour 9),
  la ligne du calendrier s'écrit seule.
- **Calendrier** : « Il m'a battue sans bouger. Il a dit que je devais revenir. Il a promis un
  gâteau. »

#### 8.1 Le réveil honteux (s. 16)

- **Lieu et moment** : `entrepot_rdc`, infirmerie, matin.
- **Présents** : Chtholly ; Collon et Lakhesh.
- **Déclencheur** : début du jour.
- **Déroulé** :
  1. Réveil ; deux éclats de la nuit reviennent (le front, « cinq jours ») ; Chtholly se cache
     sous la couverture et s'y roule ; le lit tremble (gag porté par E6 : il n'y a pas d'animation
     de roulade) ; elle frappe l'oreiller.
  2. Collon et Lakhesh entrent en visite ; Lakhesh propose quelque chose à manger ; Collon répète
     à tue-tête que Willem n'a pas dormi dans sa chambre.
- **Choix** (Collon : elle est toute rouge) : « C'est la fièvre. » / « Dehors ! »
- **Répliques (idées)** : Lakhesh, polie, « M. Willem » ; Collon, les ragots de la nuit.
- **Contrôle** : marche dans l'infirmerie, puis libre.
- **Indice** : « Où Willem a-t-il passé la nuit ? »
- **Source** : V1, « Les valeureux et leurs successeurs » [s. 16].

#### 8.2 Les endormis des archives (s. 16)

- **Lieu et moment** : `entrepot_rdc`, archives, matin.
- **Présents** : Willem et Nephren endormis ; Chtholly.
- **Déclencheur** : Chtholly entre dans les archives.
- **Déroulé** : plan sur le canapé ; Chtholly s'arrête, les poings serrés ; selon son choix,
  Nephren ouvre un œil, ou Willem se réveille sous la couverture ; il se lève, s'étire et propose un
  « exercice » dans la cour ; il prend un Carillon de série sur l'épaule.
- **Choix** : « Debout ! » (Nephren : « Mm. ») / « Les couvrir d'une couverture. »
- **Contrôle** : dialogue.
- **Indice** : —
- **Source** : V1, « Les valeureux et leurs successeurs » [s. 16].

#### 8.3 Le duel dans la cour (s. 17)

- **Lieu et moment** : `entrepot`, place `duel`, matin ; le ciel s'éclaircit.
- **Présents** : Willem (`willem_home`, tenue ample, le Carillon de série Percival), Chtholly,
  Nephren, Ithea ; les petites au porche et aux fenêtres.
- **Déclencheur** : Chtholly entre dans la place `duel`.
- **Déroulé** :
  1. Willem s'étire à `entrepot:cour_willem` ; Nephren apporte Seniorious et la remet à Chtholly à
     `cour_chtholly`.
  2. **Combat 3.3** (le duel ingagnable).
  3. Projetée, Chtholly se relève sur un coude ; Willem vient à elle et lui dit, sans grands mots,
     qu'elle peut devenir bien plus forte, et que pour ça il faut revenir.
  4. Il se retourne, chancelle et s'effondre (`willem_home:effondre`) ; cri des petites ; Nygglatho
     accourt ; fondu.
- **Choix** (avant ses mots) : « Encore une fois ! » (une reprise, section 3.3) / « … D'accord. »
- **Répliques (idées)** : Willem ne dit rien de grand ; il remarque qu'elle se jette dans chaque
  coup comme si c'était le dernier, et que c'est justement ce qu'il ne faut pas.
- **Contrôle** : combat (3.3), puis dialogue.
- **Indice** : « Willem t'attend dans la cour. »
- **Source** : V1, « Les valeureux et leurs successeurs » [s. 17].

#### 8.4 Séquence : Nygglatho au cristal (s. 18)

- **Lieu et moment** : `entrepot_etage`, chambre de Nygglatho, midi.
- **Présents** : Nygglatho ; trois petites (Collon, Pannibal, Tiat).
- **Déroulé** :
  1. Nygglatho seule devant le cristal de communication (`nygglatho_cristal`), qui luit ; une voix
     de la Garde confirme le départ : le jour prévu, à la huitième cloche. Elle répond d'une voix
     égale.
  2. La lueur s'éteint ; elle pleure, de dos, les épaules secouées (aucun gros plan).
  3. Trois petites font irruption : Willem va mourir ! Elle s'essuie les yeux, le sourire revient,
     elle court.
- **Contrôle** : aucun (45 s).
- **Source** : V1, « La femme forte et robotique » [s. 18] ; « dans trois jours », non chiffré ici
  (section 1.2).

#### 8.5 La réunion au réfectoire, l'infirmerie envahie (s. 19)

- **Lieu et moment** : `entrepot_rdc`, réfectoire, puis infirmerie, après-midi.
- **Présents** : Nygglatho, une vingtaine de fées (petites, Ithea, Nephren) ; Willem couché ;
  Chtholly à la porte de l'infirmerie (**adapté**).
- **Déroulé** :
  1. Séquence : Nygglatho, debout au bout du réfectoire, raconte Willem : un homme d'un autre
     temps, retrouvé pétrifié au fond d'un lac gelé, au corps usé comme une vieille lame ; il ne
     devrait pas être en vie. Silence.
  2. Les petites ne s'en effraient pas : elles se lèvent d'un bond et courent à l'infirmerie, où
     elles envahissent son lit pour l'encourager.
  3. Contrôle rendu : Chtholly, alertée par le vacarme, arrive à la porte de l'infirmerie : Willem
     enseveli sous les petites rit faiblement ; Ithea, assise au pied du lit, l'interroge. Personne
     ne la voit. Elle recule ; le joueur sort : la fugue commence.
- **Contrôle** : aucun, puis marche.
- **Indice** : « Du vacarme à l'infirmerie. »
- **Source** : V1, « Celui qui ne devrait pas être en vie » [s. 19] ; Chtholly à la porte,
  **(original)** : le lien avec la fugue.

#### 8.6 La fugue (s. 20)

- **Lieu et moment** : `entrepot`, `colline`, fin d'après-midi.
- **Présents** : Chtholly.
- **Déclencheur** : fin de 8.5.
- **Déroulé** :
  1. Course libre : la porte d'entrée, la cour, le chemin du nord (`entrepot:vers_colline`), la
     lisière, la montée de la colline ; derrière elle, des petites appellent son nom, de plus en
     plus loin.
  2. Au bord (`colline:vue_nord`), invite « S'envoler ». Séquence : elle s'élance ; une lueur
     phosphorescente naît dans son dos (les ailes ne sont jamais décrites dans l'œuvre : on ne les
     dessine pas, **original**) ; elle monte vers le nord, cesse de battre des ailes, tombe.
  3. La chute dans la mer de nuages : le vent hurle, tout devient blanc, l'image se couvre de givre
     (le froid, l'humidité) ; elle pleure, vue de loin, minuscule dans le blanc.
  4. Une ombre passe dans les nuages ; une ellipse ; elle reconnaît le Barocupot ; fondu au blanc.
- **Contrôle** : course jusqu'au bord, puis séquence.
- **Indice** : « Le bord de l'île, au-delà de la colline. »
- **Source** : V1, « La fille errante et le lézard volant » [s. 20] ; la colline comme lieu de
  l'envol, **(original)** : l'œuvre dit seulement « de l'entrepôt au bord, par la forêt ».

#### 8.7 Le Barocupot (s. 20)

- **Lieu et moment** : `barocupot`, fin d'après-midi (le jour gris des nuages par les hublots).
- **Présents** : Chtholly, Limeskin.
- **Déclencheur** : fin de 8.6.
- **Déroulé** :
  1. Chtholly reprend conscience dans la coursive (`barocupot:Spawn`), une serviette prêtée sur les
     épaules.
  2. Marche jusqu'à la salle du conseil de guerre ; Limeskin, debout, la tête sous le plafond (deux
     fois sa taille), l'invite à s'asseoir (`barocupot:conseil_chtholly`).
  3. Il sert un thé chaud, amer et piquant, dans des tasses minuscules, et tient la sienne comme un
     jouet ; il parle par images ; il distingue la résolution de la résignation, deux lames qui se
     ressemblent sans trancher de la même façon (image **originale**, pas une citation) ; il parle
     d'un ermitage toujours ouvert aux guerriers ; il rit comme une cloche de céramique qu'on fait
     tourner.
  4. Sortie `echelle`, « Remonter sur le pont » : séquence du retour ; elle vole vers l'île,
     escortée un moment par un navire de la Garde qui croisait près de l'île n° 66 ; arrivée dans la
     cour au crépuscule (`entrepot:from_barocupot`).
- **Choix** : « Ce n'est pas la même chose ? » / « Merci pour le thé. »
- **Répliques (idées)** : Limeskin ne ment pas et ne promet pas qu'elle reviendra ; il dit qu'un
  guerrier qui a un endroit où rentrer ne se bat pas de la même façon ; Chtholly le vouvoie.
- **Contrôle** : marche ; dialogue.
- **Indice** : —
- **Source** : V1, « La fille errante et le lézard volant » [s. 20] ; « Le ciel étoilé sous le ciel
  étoilé » (le retour escorté).

#### 8.8 La colline aux étoiles (s. 21)

- **Lieu et moment** : `colline`, nuit claire (préréglage `nuit_claire`).
- **Présents** : Chtholly, Willem (remis debout, lent), Seniorious démontée.
- **Déclencheur** : dans la cour, Ithea, assise sur le banc du porche, dit que Willem est monté sur
  la colline avec Seniorious et qu'il a demandé après elle.
- **Déroulé** :
  1. Marche de nuit, la lumière à la main, jusqu'à la place `cercle_talismans`.
  2. Willem au centre, près du petit cristal (`colline:talismans_centre`) : les quarante et un
     talismans flottent à cinq pas autour de lui comme une lumière d'étoiles et tintent comme un
     métallophone (`anim/talisman_float`). On **lève les yeux** : le ciel étoilé.
  3. Moment facultatif, sans échec **(original)** : Chtholly marche parmi les talismans ; chacun
     qu'elle frôle tinte une note, et Willem, amusé, nomme ce qu'il règle (ne pas se brûler la
     langue, trouver le nord, imiter un miaulement, ne pas se couper les ongles trop court : V1) ;
     quatre à six talismans ; puis il remet les résistances en ordre.
  4. Ils s'assoient dos à dos (`colline:dos_a_dos`, `assis`). Dialogue ; la promesse : il lui fera
     manger du gâteau au beurre jusqu'à l'indigestion, à condition qu'elle revienne. Elle sourit.
  5. Fondu au noir.
- **Choix** : « Épouse-moi. » (il refuse doucement : pour lui, c'est une enfant ; puis la promesse)
  / « Tu sais faire un gâteau au beurre ? » (son maître l'a forcé à apprendre ; puis la promesse).
- **Répliques (idées)** : Willem, sur le gâteau : il le fait aux noix (**clin d'œil**) ; Chtholly,
  en riant à moitié, lui dit de la laisser faire, qu'elle rentrera le manger ; rien de plus grand.
- **Contrôle** : marche ; frôler les talismans ; dialogue.
- **Indice** : « Willem t'attend sur la colline, avec Seniorious. »
- **Source** : V1, « Le ciel étoilé sous le ciel étoilé » [s. 21] ; talismans [ill. V1 image24].

### Jour 9 — Le premier matin (VEX, s. 22 à 25)

- **Moment et météo** : ciel bleu, matin frais (VEX, « Chtholly Nota Seniorious »).
- **État du monde** : Willem, debout et pâle, entraîne les trois aînées chaque matin dans la
  clairière, jusqu'au départ ; les petites font la vie de base ; l'après-midi, les aînées vont au
  café du village avec l'argent de poche de Nygglatho (VEX, « Cinq cents ans »).
- **Temps libre** : après l'entraînement ; après le café ; le soir.
- **Passage** : se coucher, après 9.5.
- **Calendrier** : « Bâtons à l'aube, en pyjama, devant tout le monde. Thé à la moutarde. Je ne
  recommencerai pas. »

#### 9.1 On frappe à la porte (s. 22)

- **Lieu et moment** : `entrepot_etage`, chambre de Chtholly, aube.
- **Présents** : Chtholly (pyjama et gilet : `chtholly_pajamas`, à livrer, prio 2 ; repli
  `chtholly_home`), Willem.
- **Déclencheur** : début du jour.
- **Déroulé** : on frappe ; Chtholly ouvre (`chtholly_porte`), cheveux en bataille ; Willem, frais
  comme l'aube, propose des exercices du matin ; elle referme la porte d'un coup (comique, plan du
  couloir) ; fondu ; elle ressort habillée.
- **Choix** (derrière la porte) : « Cinq minutes ! » / « Tu aurais pu prévenir ! »
- **Répliques (idées)** : Willem, à travers la porte, que la clairière n'attend pas ; Ithea, qui
  passe dans le couloir, ricane.
- **Contrôle** : dialogue, puis marche.
- **Indice** : « Willem t'attend dans la clairière. »
- **Source** : VEX, « Chtholly Nota Seniorious » [s. 22]. Pudeur : un pyjama long, un gilet, une
  porte qui claque ; rien d'autre.

#### 9.2 Les bâtons dans la clairière (s. 22)

- **Lieu et moment** : `entrepot`, place `clairiere`, matin.
- **Présents** : Willem, Chtholly ; Ithea et Nephren sur le banc (`clairiere_banc`), Ithea qui
  balance le pied.
- **Déclencheur** : Chtholly entre dans la place `clairiere`.
- **Déroulé** :
  1. Willem ramasse deux bâtons au pied du râtelier, en lance un à Chtholly.
  2. **Combat 3.2**, phase A (seule contre Willem), puis phase B (trois contre un, Ithea et Nephren
     se lèvent du banc).
  3. Fin : Ithea s'allonge dans l'herbe, bras en croix ; Nephren s'assoit, puis se renverse en
     arrière ; les genoux de Chtholly lâchent ; Willem se gratte la tête.
- **Répliques (idées)** : Willem, sur le poids qu'on répartit entre tenir et pousser ; il ajoute que
  contre des monstres, un peu de maladresse ne gêne pas ; Ithea, de l'herbe, demande grâce.
- **Contrôle** : combat d'entraînement (3.2).
- **Indice** : —
- **Source** : VEX, « Chtholly Nota Seniorious » ; « Cinq cents ans » [s. 22].

#### 9.3 Le café du village (s. 23)

- **Lieu et moment** : `village`, puis `cafe`, après-midi.
- **Présents** : Chtholly, Ithea, Nephren ; le serveur homme-chat (`cat_waiter`) ; deux buveurs à
  `cafe:table_buveurs` ; dehors, Willem et un homme-chat élégant (Ramikeldi, `ramikeldi`).
- **Déclencheur** : après le déjeuner, sous le porche, Nygglatho glisse en cachette l'argent de
  poche aux trois aînées (un clin d'œil) ; on entre dans le café.
- **Déroulé** :
  1. Les trois, fourbues, s'affalent à `cafe:table_fees` ; le serveur, complice, leur offre des jus.
  2. Par la fenêtre (cadrage sur `village:cafe_terrasse`), Willem serre la main de l'homme-chat
     élégant, qui soulève son chapeau ; ils parlent à voix basse.
  3. Ithea en tire aussitôt un roman : on recrute Willem, il va partir. Nephren, qui écoute de loin
     les yeux fermés, ne dit rien. Chtholly boude sans savoir pourquoi.
- **Choix** (Ithea : « On le recrute, c'est sûr. ») : « Qu'il parte, s'il veut. » / « Il ne
  partirait pas. »
- **Répliques (idées)** : le serveur, que la maison offre aux demoiselles de l'entrepôt, à
  condition que la grande dame n'en sache rien ; Ithea, « nya-ha-ha », mais un peu moins fort.
- **Contrôle** : marche ; s'asseoir ; dialogue.
- **Indice** : « Ithea et Nephren vont au café du village. »
- **Source** : VEX, « Cinq cents ans » [s. 23] ; le malentendu du recrutement (fiche volEX, 2).

#### 9.4 Le thé à la moutarde (s. 24)

- **Lieu et moment** : `entrepot_rdc`, réfectoire, soir (goûter du soir).
- **Présents** : Chtholly, Tiat, des petites, Ithea.
- **Déclencheur** : Chtholly s'assoit au réfectoire après le café.
- **Déroulé** : deux pots sur la table, étiquetés à la main d'une écriture d'enfant ; Chtholly,
  de mauvaise humeur, en verse une cuillère dans son thé : c'était la moutarde. Devant tout le
  monde, elle vide la tasse d'un trait. Tiat la regarde, émerveillée, et l'imite aussitôt en
  criant ; désormais Tiat boit son thé à la moutarde (gag récurrent, `VIE.md`, 2.4).
- **Choix** : « Boire d'un trait. » / « Faire comme si de rien n'était. » (elle boit d'un trait
  quand même).
- **Répliques (idées)** : Tiat, que c'est ça, être une grande ; Ithea, les larmes aux yeux de rire.
- **Contrôle** : s'asseoir ; dialogue.
- **Indice** : —
- **Source** : VEX, « Cinq cents ans » [s. 24] ; le pot étiqueté (dossier v1_vex, 4) ; la méprise
  entre les deux pots, **(déduction)**.

#### 9.5 La veillée (s. 25)

- **Lieu et moment** : `entrepot_rdc`, réfectoire, nuit.
- **Présents** : Nygglatho (`nygglatho_tea:travaille`), Chtholly.
- **Déclencheur** : la nuit, Chtholly passe devant le réfectoire éclairé.
- **Déroulé** :
  1. Nygglatho sert un thé qui n'empêche pas de dormir, verse le lait, tourne la cuillère, pose une
     part de cheese-cake cuit de sa main.
  2. Elle parle des fées parties sans revenir, nom après nom (Tuca, Orco, Clakia, Ayol,
     Katariella : VEX) ; elle n'en a oublié aucune.
  3. Quand le chagrin déborde, dit-elle en souriant, elle va chasser l'ours dans la montagne
     (**clin d'œil**). Douceur triste ; fondu.
- **Choix** : « Du sucre, s'il te plaît. » (personne ne regarde : le code des grandes est sauf) /
  « Sans sucre. »
- **Répliques (idées)** : Nygglatho, qu'elle mange quand elle s'inquiète, et qu'elle s'inquiète
  beaucoup ces jours-ci ; Chtholly, qu'il est meilleur que le thé à la moutarde.
- **Contrôle** : s'asseoir ; dialogue.
- **Indice** : « Il y a de la lumière au réfectoire. »
- **Source** : VEX, « Cinq cents ans » [s. 25] ; pas de sucre devant les petites (même chapitre).

### Jour 10 — Sous les nuages (VEX, s. 26 à 28)

- **Moment et météo** : ciel nuageux, la pluie menace (VEX, « Des émotions sans nom ») ; brève
  averse en fin d'après-midi **(original)** ; la nuit se dégage (VEX, « Le cas de la fée aux
  cheveux gris »).
- **État du monde** : entraînement du matin ; l'après-midi, Nygglatho guette le ciel et le linge
  sur le toit ; après l'averse, les petites courent dans la boue, puis bain (`VIE.md`, 5.8).
- **Temps libre** : après 10.2 ; l'après-midi ; le soir avant 10.4.
- **Passage** : se coucher, après 10.5.
- **Calendrier** : « J'ai tout raté. J'ai couru dans la forêt. Je sais ce que c'est, maintenant. Je
  ne l'écrirai pas. »

#### 10.1 Tout rater (s. 26)

- **Lieu et moment** : `entrepot`, clairière, matin.
- **Présents** : Willem, Chtholly, Ithea, Nephren.
- **Déclencheur** : Chtholly entre dans la clairière.
- **Déroulé** :
  1. **Combat 3.2**, variante du jour 10 : rien ne passe ; ses yeux vont au visage de Willem au lieu
     du bâton (gros plan sur lui, deux fois).
  2. Au troisième raté, elle pousse un grand cri (le « gros ahhhh » d'Ithea) et s'enfuit vers le
     sud.
- **Contrôle** : combat, puis course.
- **Indice** : —
- **Source** : VEX, « Des émotions sans nom » [s. 26].

#### 10.2 Dans la forêt (s. 26)

- **Lieu et moment** : `foret_profonde`, refuge, fin de matinée.
- **Présents** : Chtholly ; puis Ithea.
- **Déclencheur** : fin de 10.1 (contrôle de course jusqu'à la sortie `entrepot:vers_foret`).
- **Déroulé** :
  1. Course libre dans la forêt profonde jusqu'au grand chêne du refuge (`foret_profonde:refuge`,
     `refuge_creux`) ; elle s'y laisse tomber, assise (`assis`).
  2. Cadrage sur les feuilles qui tombent, les rais de lumière ; monologue intérieur, trois lignes :
     elle comprend ce que c'est, ce qui la fait rater ; le mot n'est jamais écrit à l'écran.
  3. Ithea la trouve (**original**), s'assoit à côté sans rien demander, et la ramène.
- **Répliques (idées)** : Chtholly, pour elle seule, qu'elle a compris, que c'est la pire chose à
  comprendre deux jours avant de partir ; Ithea, en chemin, que tout le monde joue un rôle, et
  qu'elle joue très mal le sien (**clin d'œil**).
- **Contrôle** : course ; s'asseoir ; marche.
- **Indice** : —
- **Source** : VEX, « Des émotions sans nom » [s. 26] ; le refuge, **(original)** (`CARTE.md`, 8).

#### 10.3 Rentrer le linge (moment de vie)

- **Lieu et moment** : `entrepot_toit`, fin d'après-midi, avant l'averse.
- **Présents** : Nygglatho (`nygglatho_life:porte`), deux petites ; Chtholly si elle vient.
- **Déclencheur** : le vent devient humide ; indice.
- **Déroulé** : le linge claque sur les séchoirs (`toit_sechoir`) ; Chtholly décroche les draps
  avant la pluie (trois à cinq interactions) ; la pluie tombe comme un seau renversé ; on redescend
  par la trappe en courant. Si personne ne vient, Nygglatho rentre le linge seule, trop tard
  (gag : les draps mouillés pendent au réfectoire le soir).
- **Contrôle** : marche ; décrocher.
- **Indice** : « Le vent sent la pluie. Le linge est sur le toit. »
- **Source** : `docs/REFONTE.md`, 6.3 ; averses soudaines (V2, « De ce côté-ci de l'écran ») ; le
  linge sur le toit (V3).

#### 10.4 Séquence : le toit, la nuit (s. 27)

- **Lieu et moment** : `entrepot_toit`, début de nuit, ciel dégagé.
- **Présents** : Nephren, Nygglatho.
- **Déroulé** :
  1. Nephren à la balustrade (`toit_balustrade_nord`), les étoiles ; elle penche la tête d'un côté,
     puis de l'autre.
  2. Nygglatho monte par la trappe et lui pose une écharpe sur les épaules.
  3. En trois mots, Nephren dit que Willem est « fissuré », comme elle (**clin d'œil**) ;
     Nygglatho lui confie de rester à ses côtés, de le soutenir. « Mm. »
- **Contrôle** : aucun (60 s).
- **Source** : VEX, « Le cas de la fée aux cheveux gris » [s. 27] ; fiche volEX, 2.

#### 10.5 La tour de fées (s. 28)

- **Lieu et moment** : `entrepot_rdc`, salle de jeux, soir.
- **Présents** : Willem (assis sur le tapis, `jeux_tapis`), Nephren, Collon, Pannibal, Kana, Almita,
  Giniette (Kana et Giniette : planches à livrer, prio 2 ; repli `fairy_03` et `fairy_05`),
  Nygglatho, Chtholly, Ithea.
- **Déclencheur** : après le dîner, Chtholly entre dans la salle de jeux.
- **Déroulé** :
  1. Jeux de société sur le tapis (pions, cartes) ; Willem assis en tailleur.
  2. Nephren se colle à son dos ; Collon saute sur elle, puis Pannibal, Kana, Almita et Giniette,
     l'une après l'autre (`saut`) ; la pile vacille.
  3. Nygglatho, à la porte, agite les dix doigts et saute sur la pile ; tout s'écroule dans les
     rires (`tombe`).
  4. Chtholly, rouge, s'enfuit.
- **Choix** : « Sauter sur la pile. » (elle prend son élan, s'arrête au bord, et s'enfuit) /
  « S'enfuir. »
- **Répliques (idées)** : Collon, ses cris de bataille ; Willem, écrasé, demande si c'est une
  vengeance ; Ithea crie à Chtholly qu'il reste une place.
- **Contrôle** : marche ; choix.
- **Indice** : « On joue à la salle de jeux. »
- **Source** : VEX, « Le cas de la fée aux cheveux gris » [s. 28].

### Jour 11 — L'homme-chat (VEX, s. 29 à 31)

- **Moment et météo** : matin froid, l'eau de la toilette glacée (VEX, « L'homme-chat ») ; beau ;
  après-midi doux.
- **État du monde** : Ramikeldi Limashenka attend Willem à l'entrée ; la maison Limashenka, au
  village, est ouverte toute la journée ; entraînement spécial en fin d'après-midi.
- **Temps libre** : entre 11.3 et 11.4 ; le soir.
- **Passage** : se coucher.
- **Calendrier** : « J'ai crié devant tout le monde. Il allait réparer une horloge. Une horloge. »

#### 11.1 La toilette du matin (s. 29)

- **Lieu et moment** : `entrepot_rdc`, point d'eau du couloir (`point_eau`), aube.
- **Présents** : les petites en pyjama ; Collon (`collon_pajamas:travaille` : elle trempe un doigt,
  grimace et refuse) ; Chtholly.
- **Déclencheur** : début du jour.
- **Déroulé** : l'eau est glacée, les petites se plaignent ; Collon file dans le couloir ; Chtholly
  doit la rattraper (en marchant vite : on ne court pas dans les couloirs) ; au bout de 30 s, ou
  rattrapée, Collon revient se laver en grimaçant. Chtholly rappelle les règles : se laver le
  visage, se brosser les dents, montrer l'exemple.
- **Contrôle** : marche ; poursuite douce, sans échec.
- **Indice** : « Collon s'est sauvée de la toilette. »
- **Source** : VEX, « L'homme-chat » [s. 29].

#### 11.2 « Ne pars pas ! » (s. 29)

- **Lieu et moment** : `entrepot_rdc`, couloir puis entrée, matin.
- **Présents** : Willem en pardessus (`willem_coat`), un sac à la main ; les petites ; Ithea,
  Nephren ; Ramikeldi à l'entrée (`ramikeldi`) ; Chtholly.
- **Déclencheur** : après 11.1, Willem traverse le couloir vers l'entrée (`couloir_centre` →
  `entree`).
- **Déroulé** :
  1. Chtholly voit le pardessus, le sac, l'homme-chat du café : le recrutement (9.3). Elle se plante
     au milieu du couloir, bras écartés, devant toute la maison, et le supplie de ne pas partir.
  2. Silence. Willem, perplexe : il va seulement au village réparer une vieille horloge pour ce
     monsieur, qui soulève son chapeau.
  3. Les petites font « oooh » ; Ithea s'étouffe de rire ; Nephren regarde le plafond. Chtholly
     voudrait disparaître.
- **Choix** (après) : « Je viens avec toi. » / « … Va réparer ton horloge. » (Ithea la pousse à
  le suivre quand même).
- **Répliques (idées)** : Chtholly ne trouve qu'une phrase, courte, qui sort trop fort ; Willem, que
  son contrat ne prévoit pas de démission avant le dessert ; une petite demande si c'était une
  demande en mariage.
- **Contrôle** : dialogue.
- **Indice** : —
- **Source** : VEX, « L'homme-chat » [s. 29] ; l'homme-chat qui attend à l'entrée et soulève son
  chapeau (dossier v1_vex, 2).

#### 11.3 L'horloge des Limashenka (s. 30)

- **Lieu et moment** : `village`, puis `maison_limashenka`, matin jusqu'à la deuxième cloche de
  l'après-midi.
- **Présents** : Willem (`willem_home:assis`, puis debout à l'horloge), Ramikeldi, Chtholly.
- **Déclencheur** : entrer dans la maison (`village:porte_limashenka`, ouverte ce jour-là).
- **Déroulé** :
  1. Le salon aux housses ; Ramikeldi, né sur l'île, parti il y a vingt ans, revenu pour la mort de
     sa mère ; la vieille horloge murale (`wallitem_clock_limashenka`, `maison_limashenka:horloge`).
  2. Willem l'ouvre : engrenages, ressorts, le peigne doré (`toolbox_gears`). Moment facultatif
     **(original)** : Chtholly tend la pièce qu'il demande (trois fois, sans échec possible).
  3. « Laisser passer le temps » ou attendre : vers la deuxième cloche, l'horloge repart et joue sa
     comptine. Ramikeldi pleure.
  4. En le raccompagnant, Willem appelle les fées sa famille, la plus précieuse qu'il ait ;
     Chtholly l'entend.
- **Choix** (Ramikeldi lui demande si l'air est joli) : « Il est triste. » / « Il est beau. »
- **Répliques (idées)** : Ramikeldi, sur la ville qui l'a attiré, sur la maison qui l'a attendu ;
  Willem, que les vieilles mécaniques se réparent, quand on les écoute.
- **Contrôle** : marche ; s'asseoir sur le canapé (`canape`) ; tendre les pièces.
- **Indice** : « Willem répare une horloge au village. »
- **Source** : VEX, « L'homme-chat » [s. 30] ; la réparation finit vers deux heures (dossier
  v1_vex, 4) ; remplace la quête `old_clock` (`docs/REFONTE.md`, 6.2).

#### 11.4 L'entraînement avec Seniorious (s. 31)

- **Lieu et moment** : `entrepot`, clairière, puis marais de la clairière, fin d'après-midi.
- **Présents** : Willem, Chtholly, Seniorious ; personne d'autre.
- **Déclencheur** : retour à l'entrepôt après 11.3 ; Willem attend à `clairiere_centre`, Seniorious
  emmaillotée contre l'arbre.
- **Déroulé** :
  1. **Combat 3.4** (respiration, mouvements de base, Grue de Gossamer).
  2. À la troisième Grue, l'impact arrache l'épée : elle tourne en l'air et plonge dans le marais
     (`entrepot:marais_epee`). Chtholly entre dans l'eau basse, de la boue aux genoux, et la
     ramasse.
  3. Assis contre l'arbre de la clairière (`clairiere_arbre`) : elle demande où il ira, après ; il
     répond qu'il les attendra ici, et qu'il la gavera de gâteau au beurre.
- **Choix** (la question) : « Et toi, après, tu iras où ? » / « Tu seras encore là ? »
- **Répliques (idées)** : Willem, sur la Grue, qu'on l'apprend d'abord à mains nues ; puis, sur la
  question, qu'un endroit où l'on attend quelqu'un, c'est un endroit où l'on reste.
- **Contrôle** : combat (3.4) ; marche dans le marais ; dialogue.
- **Indice** : « Willem t'attend dans la clairière, avec Seniorious. »
- **Source** : VEX, « L'endroit où je veux retourner » [s. 31] ; fiche volEX, 2.

### Jour 12 — Le départ (s. 32, 33)

- **Moment et météo** : beau, froid sec ; au couchant, les nuages soyeux virent du cramoisi au
  vermillon (V1, « Même après la fin de cette guerre »).
- **État du monde** : le matin, Nygglatho repasse les uniformes au réfectoire ; les petites cachent
  un dessin dans la salle de jeux ; Ithea range ses romans ; Nephren est sur le toit ; Willem répare
  au marteau le plafond qui fuit, dans le couloir de l'étage (`couloir_fuite`) (`VIE.md`, 3,
  variation **départ**).
- **Temps libre** : toute la journée, jusqu'au couchant : les adieux (12.1).
- **Passage** : la fin de l'acte.
- **Calendrier** (le matin) : « Départ au couchant. » La ligne suivante reste vide.

#### 12.1 La dernière journée (original)

- **Lieu et moment** : l'entrepôt, de l'aube à l'après-midi.
- **Présents** : toute la maison.
- **Déroulé** : chaque personnage a une réplique d'adieu, sans scène imposée : Nygglatho, le fer à
  la main, demande qu'on lui rapporte l'uniforme propre ; Tiat promet de devenir aussi grande, avec
  une épée aussi grande (**clin d'œil**) ; Lakhesh demande si elle peut astiquer Seniorious, et
  remercie l'épée (**clin d'œil**) ; Pannibal tente une dernière embuscade (3.1) ; Collon crie ;
  les petites offrent leur dessin (les trois aînées, Willem, un gâteau énorme) ; Ithea, sérieuse un
  instant, demande si on revient, hein ; Nephren : « Mm. » ; Willem, sur l'échelle, que le plafond
  tiendra jusqu'à leur retour. Le ballon a lieu l'après-midi ; Chtholly peut y jouer une dernière
  fois.
- **Contrôle** : libre.
- **Indice** (au couchant) : « La huitième cloche approche. Tous sont dans la cour. »
- **Source** : la veille du départ de l'ancienne fiche (`HISTOIRE.md`, 3.1), reprise ; les gestes
  de `docs/REFONTE.md`, 4.3.

#### 12.2 Le départ au couchant (s. 32)

- **Lieu et moment** : `entrepot`, cour, couchant.
- **Présents** : toute la maison, une trentaine de fées, Nygglatho, Willem ; Chtholly, Ithea et
  Nephren en uniforme et armure légère, l'épée au dos (planches `chtholly`, `ithea`, `nephren`), la
  broche qui brille sur la poitrine de Chtholly.
- **Déclencheur** : Chtholly entre dans la cour au couchant.
- **Déroulé** :
  1. La huitième cloche sonne, au loin (l'horloge des archives).
  2. Les trois s'avancent à `entrepot:cour_centre` ; les petites tout autour ; Nygglatho, mains
     jointes près du visage ; Tiat crie de revenir.
  3. Willem devant Chtholly : peu de mots ; le gâteau.
  4. On **lève les yeux** : les trois s'élèvent dans le couchant, la lueur dans le dos ; les nuages
     passent du cramoisi au vermillon ; elles deviennent trois points de lumière. La caméra reste sur
     le ciel ; fondu.
- **Choix** (dernier mot à Willem) : « Fais-le aux noix, le gâteau. » (**clin d'œil**) / « À
  bientôt. »
- **Répliques (idées)** : Willem ne fait pas de discours ; il rappelle qu'il a promis une montagne
  de gâteau, et qu'une montagne, ça ne se mange pas seule.
- **Contrôle** : marche jusqu'au centre ; un dialogue ; séquence.
- **Source** : V1, « Même après la fin de cette guerre » [s. 32].

#### 12.3 Épilogue facultatif : le retour de Willem (s. 33)

- **Lieu et moment** : `entrepot`, champ, puis `entrepot_rdc`, cuisine ; plus tard.
- **Présents** : Willem (`willem_coat`, puis `willem_cook`), les petites.
- **Déclencheur** : après 12.2, invite « Voir l'épilogue » / « Passer ».
- **Déroulé** : séquence (90 s) : Willem revient par le sentier, un sac de beurre et de farine
  dans les bras ; les petites, au ballon dans le champ, l'appellent pour jouer ; il promet de venir
  plus tard et entre à la cuisine ; il noue son tablier ; au premier geste, il croit entendre une
  voix d'enfant l'appeler « papa », très loin ; il sourit et continue. Fondu ; carton : « Fin de
  l'acte 1. L'acte 2 suit le volume 2. »
- **Contrôle** : aucun.
- **Source** : V1, « Même après la fin de cette guerre » [s. 33] ; le beurre et la farine (vol1, 2).

## 3. Les combats de l'acte 1

L'acte 1 ne montre aucune Bête (`docs/REFONTE.md`, 5) : ses combats sont des **entraînements**, un
**duel ingagnable** et la **faune**. Les chiffres ci-dessous sont des propositions pour le lot E8
(entraînements) et le lot E5 (faune) ; ils vivent dans les données (`data/attacks`, `data/fauna`),
jamais dans un script (`CLAUDE.md`).

### 3.0 Règles communes

- **Pas de mort.** À l'entraînement, Chtholly à bout de forces s'assoit dans l'herbe, essoufflée
  (animation `mort` des planches de bâton, « assise, sans blessure ») ; l'exercice s'arrête, la scène
  continue. Contre la faune, à zéro point de vie : fondu, réveil à l'infirmerie
  (`entrepot_rdc:infirmerie_lit_a`), une remontrance de Nygglatho, le moment avance d'un cran, rien
  n'est perdu.
- **Les armes** **(original)** : hors des scènes, Chtholly n'a pas Seniorious (les Carillons dorment
  dans la salle des armes, sous la clé de Nygglatho : V1) ; elle porte un **bâton** (on en prend un
  au râtelier de la clairière, `stick_rack`). Le bâton a les coups de base (trois coups enchaînés),
  la parade et l'esquive, **pas la charge de venenum**, qui demande un Carillon. Seniorious ne sert
  qu'au duel (3.3), à l'entraînement spécial (3.4) et à la colline (sans combat). Pannibal se bat à
  l'épée de bois.
- **Pas de « Défaite ».** Aucun écran d'échec : une scène continue, réussie ou non ; la réussite
  donne seulement une réplique en plus.
- **Animations** : Chtholly en combat, planche `chtholly` (`attaque`, `charge`, `degats`, `mort`) ;
  les planches de bâton `<id>_stick` (cahier n° 3, 4.7 : `pare` est un nom proposé) sont en
  priorité 3 et attendent l'accord d'E8 ; en attendant, la planche `chtholly` et un bâton dessiné
  en main.

### 3.1 L'embuscade de Pannibal

- **Où, quand** : le jour 1 sur le sentier (1.2) ; puis, du jour 2 au jour 12, en temps libre, sous
  forme de **jeu d'embuscade** (`VIE.md`, 5.5) : Pannibal, et Collon à partir du jour 5, se
  cachent sur les chemins de l'entrepôt (fourrés, derrière le grand arbre, angles des couloirs) et
  bondissent sur Chtholly, au plus une fois par moment.
- **Pannibal** : une **lumière qui zigzague** ou un froissement annonce le **bond** (0,8 s), qu'elle
  lance de 4 m ; puis trois **taillades** rapides (0,35 s d'écart) ; à partir du jour 5, une
  **feinte** sur trois (elle s'arrête au milieu du bond). Un coup d'épée de bois ne fait aucun
  dégât : Chtholly recule de 0,5 m et Pannibal compte un point.
- **Le joueur** esquive le bond (pas de côté), pare ou esquive les taillades.
- **Réussite** : cinq attaques esquivées ou parées de suite, ou une riposte qui la touche après une
  esquive : Pannibal tombe à plat ventre dans l'herbe ou la boue (`tombe`), vexée, et rit.
- **Échec** : trois points pour Pannibal : elle lève son épée, proclame sa victoire et détale. Le
  jour 1, la scène continue de la même façon (elle reconnaît Chtholly).
- **Le jour 1** : dans le noir, seule la lumière de Chtholly éclaire ; deux lignes d'aide, une
  seule fois : esquiver, parer.
- **Source** : V1, « L'Homme sans Marque » ; les embuscades au cri de guerre (V2) ; Pannibal, une
  vraie maîtrise de l'épée (dossier v1_vex, 9).

### 3.2 L'entraînement au bâton, à trois contre un

- **Où, quand** : la clairière (`entrepot:clairiere`, 16 × 15 m), le matin ; en scène les jours 9
  (9.2) et 10 (10.1) ; en temps libre chaque matin des jours 9 à 12 (Willem attend à
  `clairiere_centre` de l'aube à midi).
- **Phase A, « des attaques venues de partout »** (Chtholly seule contre Willem) :
  - Willem frappe en rythme, de quatre côtés (gauche, droite, haut, estoc), chaque coup annoncé
    0,5 s avant par sa posture ; le tempo monte de 50 à 75 coups par minute (1,2 s → 0,8 s).
  - Trois réponses : **bloquer** (tenir la parade : le maintien) ; **dévier** (relâcher la parade
    dans les 0,15 s avant l'impact : la projection ; le coup glisse et la garde de Willem s'ouvre
    0,5 s) ; **esquiver** (pas de côté).
  - Une réponse juste garde le rythme ; un coup reçu ou une réponse en retard le casse (le compte
    revient à zéro). Toutes les 30 s, les genoux fatiguent : la fenêtre de parade rétrécit d'un
    cinquième ; à 90 s, Chtholly s'assoit.
  - **Réussite** : douze réponses de suite, dont au moins trois déviations.
- **Phase B, « trois contre un »** (Ithea et Nephren se joignent à Chtholly) :
  - les deux alliées attaquent Willem toutes les 2 à 3 s ; il pare tout et contre « comme un
    serpent », sous des angles désagréables (bas, par-dessus l'épaule), une contre toutes les 2 s,
    sur l'une des trois ; sur Chtholly, la contre est annoncée 0,4 s avant : il faut **l'esquiver**,
    c'est la leçon ;
  - après une déviation (de n'importe laquelle des trois), Willem est découvert 0,4 s.
  - **Réussite** : tenir 60 s en ne recevant pas plus de trois contres, ou **toucher Willem une
    fois** (il rit et se gratte la tête).
- **Fin** : réussite ou fatigue ; la scène continue de toute façon ; la réussite du jour 9 donne une
  réplique d'Ithea et de Willem, et fait commencer l'entraînement spécial du jour 11 directement à
  l'étape 2.
- **Variante du jour 10** : phase A seulement ; au bout de 15 s, la fenêtre de déviation se ferme
  (le rythme tremble à l'écran, le son s'étouffe) ; au troisième raté, la scène 10.1 continue.
- **Source** : VEX, « Chtholly Nota Seniorious » ; « Cinq cents ans » ; « Des émotions sans nom »
  (dossier v1_vex, 9).

### 3.3 Le duel ingagnable

- **Où, quand** : le jour 8 au matin, place `duel` (12 × 12 m) de la cour ; les spectateurs au
  porche et le long de la cour.
- **Les armes** : Chtholly a Seniorious et tous ses gestes (`attaque`, `charge`, verrouillage) ;
  Willem tient le Carillon de série Percival, en tenue ample.
- **Phase 1** (30 s au plus) : Willem s'étire ; chaque attaque de Chtholly passe à côté : il fait un
  pas, ne pare jamais. Si le joueur n'attaque pas en 8 s, Willem lui fait signe d'approcher.
- **Phase 2** : Chtholly allume son venenum (charge tenue 2 s) : la **vision accélérée** ;
  l'image pâlit (désaturation de 60 %, E9), le monde ralentit autour d'elle (vitesse des autres
  × 0,6, son étouffé : de l'eau tiède), son élan franchit 8 m en deux foulées ; la lumière s'échappe
  des fissures de la lame.
- **Phase 3** : au premier coup chargé, Willem **retourne l'élan** : écran blanc, silence, un
  battement de cœur qui s'arrête (0,6 s : la mort hallucinée, sans corps ni sang) ; puis il dévie
  la lame, la touche à peine de la main, et elle est **projetée** à 6 m, sur le dos dans l'herbe
  (`degats`). Un instant, Percival brille autant que Seniorious (un Carillon puise dans le plus fort
  de ceux qui le touchent : V1).
- **Reprise** : si le joueur choisit « Encore une fois ! », les phases 2 et 3 se rejouent une fois,
  plus vite, et finissent pareil.
- **Réussite** : impossible, et c'est voulu. Aucun point de vie perdu ; aucun écran de défaite.
- **Source** : V1, « Les valeureux et leurs successeurs » (dossier v1_vex, 9).

### 3.4 L'entraînement spécial avec Seniorious

- **Où, quand** : le jour 11, fin d'après-midi, la clairière ; Chtholly et Willem seuls.
- **Étape 1, la respiration** : la respiration réglée par le venenum ; une jauge de souffle
  (inspirer 2 s, expirer 2 s) ; le joueur tient la charge à l'inspiration et la relâche à la fin
  de l'expiration (à 0,3 s près) ; cinq cycles. Pas d'échec : Willem corrige (« plus lent »).
- **Étape 2, les mouvements de base** : Willem annonce un geste (« Trois coups. », « Pare. »,
  « Côté. ») ; le joueur l'exécute dans les 1,5 s ; neuf annonces.
- **Étape 3, la Grue de Gossamer**, coup de dernier recours : quand Willem fend (annonce 0,6 s),
  une parade parfaite (fenêtre de 0,2 s) suivie d'une attaque fait pivoter Chtholly, qui détourne
  son coup et le renvoie. **Réussite** : trois Grues ; la troisième arrache Seniorious (11.4).
- **Étape 4** : ramasser l'épée dans le marais (`entrepot:marais_epee`, eau basse, éclaboussures),
  invite « Ramasser Seniorious ».
- **Source** : VEX, « L'endroit où je veux retourner » (dossier v1_vex, 9) ; la Grue, à l'origine
  une technique à mains nues (même chapitre).

### 3.5 La faune

- **Où, quand** : en temps libre, à partir du jour 2, dans la forêt profonde et la montagne
  (`VIE.md`, 6) ; jamais à l'entrepôt, au village ni en ville.
- **Les animaux paisibles** (cerfs, renards, écureuils, oiseaux, grenouilles, corbeaux) ne se
  battent pas : un coup de bâton les fait fuir, rien de plus.
- **Les loups** (forêt profonde, `clairiere_loups`, au crépuscule et la nuit) : une meute de trois ou
  quatre tourne autour de Chtholly et attaque un par un (morsure en bond, annoncée 0,5 s : le loup
  se ramasse) ; esquiver, puis frapper ; un loup touché trois fois s'enfuit ; quand la moitié de la
  meute a fui, le reste suit. Dégâts : 1.
- **Le sanglier** (forêt profonde, `souille`, matin et soir) : il gratte le sol (1 s), puis charge
  en ligne droite ; esquiver de côté ; s'il heurte un arbre ou un rocher, il reste étourdi 2 s ;
  quatre coups et il s'enfuit. Dégâts : 1.
- **L'ours** (montagne, `taniere`, le jour ; il n'hiberne pas encore, l'hiver approche) : grands
  coups de patte en arc, et il se dresse en rugissant avant de frapper (annonce 0,8 s) ; dix coups
  pour le chasser ; il ne poursuit pas au-delà de 15 m de sa tanière. Dégâts : 2. Conseil des
  petites : fuir. Si Chtholly le chasse, Nygglatho se plaint le soir qu'on lui vole son dîner.
- **Un animal vaincu s'enfuit** ; il ne meurt jamais à l'écran **(original)**, pour le ton. La loi ne
  protège que les êtres intelligents et chasser l'ours est permis (V1 ; VEX), mais le jeu n'en fait
  pas une récompense.
- **Source** : `docs/REFONTE.md`, 4.4 et 5 ; dossier v1_vex, 6.

## 4. Les moments de vie

Facultatifs, rejouables, tirés de l'œuvre (`docs/REFONTE.md`, 6.3). Les détails (qui, où,
quelles animations) sont dans `VIE.md`.

| Moment | Où | Quand | Comment ça commence et finit | Source |
| --- | --- | --- | --- | --- |
| Le thé chez Nygglatho | `entrepot_etage`, `nygglatho_the` | après-midi, jours 2 à 12 (sauf 7 et 8) | frapper à sa porte ; une tasse, une ou deux répliques qui changent chaque jour ; fin quand la tasse est vide | V1 ; VEX |
| Le goûter au café du village | `cafe`, `table_fees` | après-midi, jours 2 à 12 (sauf 7 et 8) | l'argent de poche (Nygglatho le glisse en cachette le jour 2) ; commander un jus ou une part de gâteau au comptoir ; s'asseoir ; fin en sortant | VEX, « Cinq cents ans » |
| La lecture à la fenêtre | `entrepot_rdc`, `lecture_banquette` | tout moment de jour, à partir du jour 5 | s'asseoir (`lit`) ; la vue sur le champ ; Nephren impose le silence si l'on parle ; fin en se levant | V1, « Les filles de l'entrepôt » |
| Rentrer le linge avant l'averse | `entrepot_toit`, `toit_sechoir` | jour 10, fin d'après-midi (10.3) ; tout matin de vent ensuite (sans averse) | le vent devient humide ; décrocher draps et chemises ; fin quand les séchoirs sont vides | V3 ; `docs/REFONTE.md` |
| Aider la cuisinière du jour | `entrepot_rdc`, cuisine | matin et soir, tous les jours sauf 7 | la cuisinière du jour (`fairy_12`) demande un coup de main ; éplucher, remuer (trois gestes) ; fin par la goûte du plat | V1, « Directeur en carton » |
| Le cinéma avec les petites | `ville_projection` | après-midi, à partir du jour 5, avec un adulte (Nygglatho ou Willem) | trois petites le demandent au porche ; on marche jusqu'en ville avec l'adulte ; un film muet de lézards amoureux, aux images floues ; la lumière revient ; fin en sortant | V2 ; `docs/REFONTE.md`, 4.1 |
| Suivre Lakhesh à la boulangerie | `ville_boulangerie` | matin, à partir du jour 3 | Lakhesh part tôt par le sentier ; la suivre ; le boulanger grincheux ; elle offre un petit pain ; fin en sortant | V3 ; `docs/REFONTE.md`, 4.1 |
| Le ballon | `entrepot`, champ | après-midi, à partir du jour 5 (sauf 7 et 8) | entrer dans le champ pendant la partie ; deux mi-temps ; fin au goûter | V1 ; V5 |
| Les jeux des petites | voir `VIE.md`, 5 | selon le jeu | chat, arbre, embuscade, course du couloir, tour de fées, boue et bain | V1 ; V2 ; V5 ; VEX |

## 5. Ce que devient l'ancienne fiche (`HISTOIRE.md`, section 3)

- **La quête principale `act1_main`** devient le récit en jours : plus d'objectif au HUD, plus
  d'étapes « parler à », « atteindre », « abattre ». Ses étapes deviennent :
  - `morning`, `new_officer` → la nuit d'arrivée (jour 1) et la fuite (jour 2) ;
  - `to_the_woods`, `rejetons` → **supprimées** : pas de rejetons de Timere sur l'île n° 68
    (dossier v1_vex, 7) ;
  - `pannibal` → l'embuscade du jour 1 (1.2, 1.3) ;
  - `report`, `first_vigil` → **supprimées** : pas de veille du Couchant, pas de bord ouest aux
    dunes ; l'arène à vagues rejoint l'acte 2 (`docs/REFONTE.md`, 5) ;
  - `fever` → la nuit de fièvre (7.5), après le port sous la pluie (7.4) ;
  - `training` → le duel dans la cour (8.3) ;
  - `the_edge`, `barocupot` → la fugue (8.6) et le Barocupot (8.7), qui n'est plus « au port » ;
  - `starry_hill`, `promise` → la colline aux étoiles (8.8).
- **Les quêtes secondaires** (`docs/REFONTE.md`, 6.2) : `picture_book` → la scène 6.2 ;
  `special_dessert` → les scènes 4.1 et 4.2 ; `flying_laundry` → le moment « rentrer le linge » ;
  `vigil_register` et `forget_me_nots` → retirées (ni veille, ni myosotis sur la colline) ;
  `old_clock` → la scène 11.3.
- **Les récompenses** : la promesse n'est plus un objet (`butter_cake_promise`) ; elle s'écrit au
  calendrier. Les points de vie de Chtholly ne montent plus par la quête : **à trancher** avec E8
  (proposition : un cœur de plus à la fin des jours 9 et 11, après les entraînements réussis ou
  non).
- **L'ancienne île reste jouable** jusqu'à la phase 5 (`docs/REFONTE.md`, 9) : ses quêtes JSON et
  ses tests restent tels quels tant que le récit en jours n'existe pas.

## 6. Ce que les lots du moteur doivent savoir

- **E6 (récit)** :
  - l'état du récit tient en deux valeurs, le **jour** (1 à 12) et le **moment** (aube à nuit), et
    la liste des scènes faites ; chaque scène de la section 2 est une entrée de données (lieu,
    moment, déclencheur, présents, étapes) ; les séquences se passent d'une touche après la
    première fois ;
  - le vocabulaire de mise en scène est en 0.2 ; « Laisser passer le temps » est en 0.1 ;
  - le calendrier (`wallitem_calendar`) reçoit une ligne par jour ; les indices font 60 signes au
    plus ;
  - les invites nouvelles : « Dormir », « S'asseoir à la fenêtre », « S'envoler »,
    « Remonter sur le pont », « Ramasser Seniorious », « Voir l'épilogue » ;
  - gags sans animation : Chtholly qui se roule dans son lit (8.1), la pile de la tour de fées
    (10.5) : des déplacements de sprites, pas des planches nouvelles.
- **E4 (vie)** : les variations par jour (`VIE.md`, 3) : **fuite** (jours 1 à 3), **aînées
  absentes** (jour 7), **Willem malade** (jour 8), **entraînement du matin** (jours 9 à 12),
  **départ** (jour 12) ; les petites qui suivent Willem à partir du jour 4.
- **E8 (jeux)** : le ballon à partir du jour 5 ; l'embuscade de Pannibal (3.1) ; l'entraînement au
  bâton (3.2) ; le duel (3.3) ; l'entraînement spécial (3.4) ; le bâton comme arme hors des scènes
  (3.0).
- **E9 (lumière et temps)** : la météo de chaque jour (1.1) ; les effets : la lumière de fée portée
  (jour 1, colline), la fièvre (image qui ondule), le souvenir (sépia), la vision accélérée
  (désaturation, ralenti), l'écran blanc du duel, la chute dans les nuages (blanc, givre), la
  lumière d'étoiles des talismans, le couchant cramoisi puis vermillon.
- **E1 (cartes)** : la tranche de la phase 2 (« jours 1 à 4 », `docs/REFONTE.md`, 9) a besoin, en
  plus de l'entrepôt, du `sentier` (jour 1), du `port` (séquence 1.1) et de `ville_haute` et
  `ville_snack` (jour 3) ; à défaut, des cartes d'essai grises suffisent. Le `barocupot` ne
  s'atteint que par la scène 8.7 ; `transport_garde` ne sert pas à l'acte 1 ; `maison_limashenka`
  n'ouvre que le jour 11. Un point nommé ajouté pour ce document : `sentier:premiere_embuscade`
  (`CARTE.md`, 4).
- **E7 (navires)** : le transport de la Garde ne paraît qu'au crépuscule du jour 7 (descente,
  amarrage, trappe, départ) ; le Barocupot n'est vu que de l'intérieur (8.7) et comme une ombre dans
  les nuages (8.6).
- **E5 (faune)** : section 3.5 ; `VIE.md`, 6.
- **Planches à prévoir pour ces scènes** (cahier n° 3, section 4) : `chtholly_pajamas` (prio 2, jour
  9), `nygglatho_labcoat` (prio 2, jour 7), les planches de bâton `_stick` (prio 3, jours 9 à 11),
  `kana` et `giniette` (prio 2, jour 10), un geste `travaille` pour le serveur du snack
  (`snack_vendor`, jour 3). La grande sœur du souvenir n'a pas de planche (ombre et voix). Les ailes
  ne se dessinent pas : une lueur (E9).
- **À décider** : le prologue de l'île n° 28 (`docs/REFONTE.md`, 6.1), qui demanderait une carte que
  `CARTE.md` ne dessine pas ; la montée des points de vie (section 5).

## 7. Où l'œuvre se tait : ce que ce document invente

1. Le découpage en douze jours, une scène clé principale par jour, et les compressions de la
   section 1.2 (la mission des aînées en un jour, le départ dans un jour à lui).
2. Le jour 1 : Chtholly envoyée chercher Pannibal ; la première embuscade sur elle ; l'escorte de
   Willem jusqu'à l'entrepôt ; Chtholly qui ouvre la porte de l'avalanche n° 1.
3. Le petit-déjeuner raté et le pain de Lakhesh (2.1).
4. Ithea qui entraîne Chtholly en ville le jour 3 (sa formule sur l'information est de l'œuvre).
5. L'avalanche à la cuisine et Chtholly goûteuse du caramel (4.1).
6. La petite qui appelle Chtholly au ballon (5.2) : le ballon jouable par elle.
7. L'annonce de la mission au dîner (6.3), le départ dans la brume, Willem à sa fenêtre (7.1).
8. La grande sœur en ombre et en voix ; le souvenir en sépia (6.4).
9. La petite blessée au match : `fairy_06` (7.2).
10. Chtholly à la porte de l'infirmerie avant la fugue (8.5) ; la colline comme lieu de l'envol ;
    les ailes rendues par une lueur (8.6).
11. Le jeu des talismans sur la colline (8.8).
12. La méprise entre les deux pots (9.4).
13. Le refuge sous le grand chêne de la forêt profonde ; Ithea qui y retrouve Chtholly (10.2).
14. L'averse du jour 10 et le linge (10.3).
15. La poursuite de Collon à la toilette (11.1) ; les pièces tendues à Willem (11.3).
16. La dernière journée et ses adieux (12.1) ; la ligne vide du calendrier.
17. Les cloches : l'horloge des archives qui sonne les moments ; la huitième cloche au couchant ;
    le jour du départ entouré au calendrier ; les comptes de jours de l'œuvre que le jeu ne chiffre
    pas à l'écran (1.2).
18. « Laisser passer le temps » ; le moment qui n'avance pas tout seul.
19. Le bâton comme arme hors des scènes ; les chiffres des entraînements, du duel et de la faune ;
    l'animal vaincu qui s'enfuit ; le réveil à l'infirmerie.
20. Les images de mise en scène du duel (écran blanc, désaturation) et de la chute (givre).
21. Les répliques : toutes sont des idées originales écrites dans le registre de `BIBLE.md`
    (section 9.3) ; les mots de l'œuvre n'y servent que de repère.
