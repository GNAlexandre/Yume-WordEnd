# Production des personnages, décors et objets 2D

État de référence établi le 7 octobre 2026, avant la nouvelle génération,
puis actualisé à réception du cahier HD-2D et de la confirmation utilisateur du
**pixel art**.

La demande utilisateur la plus récente confirme la production d'images en
pixel art selon [ASSETS_HD2D.md](../ASSETS_HD2D.md), abandonne la nouvelle
production de modèles 3D, et conserve **toutes les images anime** dans les
archives et la galerie. Le nouveau cahier a été copié à l'identique depuis la
pièce jointe, sans réécriture. Les anciennes prescriptions GLB, budgets de
triangles et rigs sont remplacées. `docs/ASSETS_3D.md` et `docs/lore/MONDE.md`
restent des sources d'apparence et de cohérence narrative ; leurs fichiers
fournis ne sont pas modifiés par cet inventaire.

L'utilisateur complète le cahier : **52 apparences**, chacune en **face, dos et
côté pour chaque mouvement** ; combat réservé aux sept héros `willem`,
`chtholly`, `ithea`, `nephren`, `nopht`, `rhantolk`, `lillia`. Les autres
personnages reçoivent `repos`, `marche`, `course`, `parle`. Ithea et Nephren ont
les sept mouvements de combat **et** `parle`. Ces instructions utilisateur
priment sur le profil droit unique et l'absence de course des PNJ dans le cahier.

Les premiers PNG sont conservés à l'identique dans `assets/source/legacy_2d/`.
Les nouveaux essais anime et les concepts de Chtholly/Willem sont également
conservés ; aucune réduction pixel ne remplace leurs originaux.
Leur manifeste contient les dimensions, empreintes SHA-256 et réserves connues.
Une planche générée n'est pas automatiquement un atlas animé : poses, marges,
découpage, origine aux pieds et cycles doivent être contrôlés avant intégration.
Les concepts 2D destinés à préparer la 3D et les portraits des anciens GLB ne
comptent pas comme sprites dans cet inventaire.

## 1. Couverture des onze premières planches

Onze PNG couvrent **24 apparences distinctes sur les 45 de REFERENCES.md**.
Les deux essais d'Ithea et les deux essais de Rhantolk sont des doublons de
personnages, sans augmenter ce total. Deux formes de Suowong et deux formes
d'Ebon Candle comptent chacune comme apparences à produire.

Les noms de fichiers ci-dessous sont relatifs à `assets/source/legacy_2d/`.

| Planche conservée | Identifiants couverts | Pages officielles | Limites déjà relevées |
| --- | --- | --- | --- |
| `exec-dfea400e-7d98-43b9-a35d-01e9b40fdf10.png` | `chtholly` | 11–20 | Deux charges ont les jambes coupées ; armes et effets débordent. |
| `exec-091e00a1-b867-4bba-b09f-4c10cbdcfdb7.png` | `willem` | 5–10 | Attaques et charges débordent ; cycles à contrôler. |
| `exec-10fe5105-30e6-4e13-9120-58a3f3d612be.png` | `ithea` | 21–26 | Les pointes de cheveux ressemblent à des oreilles animales, à corriger lors d'une reprise. |
| `exec-f088e71d-7719-46a2-b82f-5bc70e6a2d08.png` | `ithea`, deuxième essai | 21–26 | Même réserve de coiffure ; effets débordants. |
| `exec-860978ee-9d58-412a-9c8b-dc5f411347ed.png` | `rhantolk` | 37–40 | Armes et poses dépassent certaines cellules. |
| `exec-d018c554-3cdc-4d51-8fd6-10b13df1f84d.png` | `rhantolk`, deuxième essai | 37–40 | Arme flottante dans une pose ; effets entre cellules. |
| `exec-e553703f-4da9-4a57-85cb-328c24ceccfa.png` | `tiat`, `pannibal`, `collon`, `lakhesh` | 41–50 | Huit poses par personnage ; portraits indépendants absents. |
| `exec-defc4c62-799c-4436-a707-ed5fea9ffa6e.png` | `almita`, `sarya`, `willemia`, `ecluecla` | 64 | Deux poses chacune ; pixels parasites à contrôler. |
| `exec-fca440d1-5450-4194-aa88-24c5fbc047b2.png` | `jorget`, `tilfey`, `bitora`, `illustote` | 64 | Deux expressions chacune ; bas de planche proche du bord. |
| `exec-0d346a8c-1107-4c4d-90f8-6a25135f4238.png` | `knight_canine`, `knight_feline`, `police_golem`, `godrey` | 68–69 | Deux expressions chacune ; bas proche du bord. |
| `exec-a257f49a-96d1-479a-985f-06f74400a698.png` | `baroni`, `frog_soldier`, `bird_soldier`, `wolf_soldier` | 70–71 | Deux expressions chacune ; petites marges. |

## 2. Les 21 apparences encore absentes

Les pages sont les numéros de fichier `pNNN.jpg`, pas le folio imprimé qui est
généralement inférieur d'une unité. Scans hors du dépôt :
`/workspace/sukasuka-references/pages/`.

Les identifiants de la traduction demandés dans ASSETS_3D, section 4.9, sont
utilisés pour les nouvelles livraisons. La colonne « alias ancien » évite de
générer deux fois un même personnage.

| Nouvel identifiant | Alias ancien | Personnage / référence | Pages | Priorité narrative |
| --- | --- | --- | --- | --- |
| `nephren` | — | Nephren Ruq Insania : cheveux gris-lilas en couettes, manteau violet ; Insania p29. | 27–32 | Acte 1, maison des fées. |
| `nopht` | — | Nopht Keh Desperatio : cheveux corail courts, tenue brun-rouge, pantacourt ; Desperatio p35. | 33–36 | Actes suivants ; absente pour escorte de surface au début. |
| `nygglatho` | — | Troll d'apparence humaine, longs cheveux saumon, yeux verts, tablier blanc ; la description mise à jour prévoit un chemisier vert, distinct de la tenue noire des scans. | 51–53 | Acte 1, porche de l'entrepôt. |
| `glick` | `grick` | Glick Graycrack : boggart gris-vert, lunettes d'aviateur, gilet de cuir ; coupe et accessoires du scan. | 54 | Personnage canonique ; nom de traduction retenu. |
| `limeskin` | — | Reptilien géant draconique, uniforme noir/or, écailles blanc laiteux dans la description mise à jour ; p56 = tenue civile du même personnage. | 55–56 | Acte 1, amarrage de la Garde. |
| `almaria` | — | Longs cheveux bruns, robe rouge-brun et tablier brun, jupe sombre. | 57 | Passé / bonus, hors décor actif de l'acte 1. |
| `lillia` | — | Lillia Asplay : queue haute rouge, tenue blanche/bordeaux/or, cape ; héroïne du passé. | 58 | Bonus ; arme conservée dans son identité visuelle. |
| `suowong_young` | `souwong_young` | Jeune Suowong Kandel, cheveux blonds courts, cape blanche trop longue, vêtement bleu/blanc. | 59 | Forme du passé, hors acte 1. |
| `suowong` | `souwong_sage` | Grand Sage : silhouette imposante, barbe et longs cheveux dorés, cape blanche. | 60 | Actes suivants, hors acte 1. |
| `ebon_candle_ancient` | `eboncandle_ancient` | Ancien corps d'Ebon Candle, armure bordeaux/turquoise, tête large aplatie. | 61 | Forme du passé. |
| `ebon_candle` | `eboncandle_skull` | Ebon Candle, crâne dans un mécanisme ; description mise à jour : grand crâne noir aux orbites lumineuses, support rouge et fer forgé. | 62 | Actes suivants ; couleurs seulement partielles sur le scan. |
| `elq` | — | Elq Hrqstn : très longs cheveux rouges ondulés, robe blanche, pieds nus. | 63 | Hors acte 1 ; spoiler protégé dans la galerie / les scènes. |
| `rinsha` | — | Petite fée, longs cheveux blonds, cape brune, robe bordeaux ; bas de page, dernière figure à droite. | 64 | Dernière petite fée de la planche encore absente. |
| `ballman` | — | Ballman / ボールマン : petit être sphérique aux membres filiformes. Palette absente, adaptation à signaler. | 65, haut | PNJ de réserve, dessin au trait. |
| `golem` | — | Golem domestique : grand corps rond avec plaques. Palette absente, adaptation à signaler. | 65, bas | PNJ de réserve ; distinct du golem policier déjà couvert. |
| `doctor` | `cyclops_doctor` | Médecin cyclope gris, blouse blanche, pantalon brun ; description mise à jour : lunettes noires. | 66 | Actes suivants. |
| `phyr` | — | Phyracorlybia Dorio : lycanthrope, fine fourrure blanche, robe turquoise, chapeau à marguerite, ombrelle. | 67 | Actes suivants. |
| `kaya` | `kaiya` | Kaya, servante semifère : cheveux sombres, traits félins visibles, robe noire, tablier et coiffe blanche à voile. | 68, haut | Actes suivants. |
| `hawk_soldier` | — | Soldat rapace anonyme : visage humanoïde blond, ailes ocre, serres, uniforme noir/or. | 71, bas, figure 2 | Réserve de la Garde ; ne pas inventer de nom propre. |
| `cat_soldier` | — | Soldat félin anonyme : chat gris, oreilles noires, uniforme noir/or. | 71, bas, figure 3 | Réserve de la Garde. |
| `rabbit_soldier` | — | Soldat lapin anonyme : petit lapin brun, sans lunettes, uniforme noir/or. | 71, bas, figure 4 | Distinct de Baroni, déjà couvert. |

Les romans HISTOIRE.md et BIBLE.md cités par les documents ne sont pas présents
dans ce checkout. Les détails non établis par les sources disponibles restent
des adaptations de jeu et ne sont pas présentés comme des faits canoniques.

## 3. Sept PNJ supplémentaires de l'île 68

Ces sept apparences n'ont pas de planche dédiée parmi les 45 références.
L'identité narrative ci-dessous vient de MONDE, sections 2.4 et 2.5 ; les
descriptions visuelles viennent d'ASSETS_3D, section 4.8.

| Identifiant | Description à produire | Statut et source | Emplacement |
| --- | --- | --- | --- |
| `cat_waiter` | Homme-chat aimable, canines visibles, chemise, gilet et tablier de service. | Serveur canonique sans nom propre ; apparence adaptée au jeu, VEX « Cinq cents ans ». | Terrasse du café. |
| `egg_vendor` | Marchande à traits de mouton, laine bouclée, fichu et panier de paille. | Personnage **original**, explicitement indiqué dans ASSETS_3D. | Marché. |
| `snack_vendor` | Jeune lycanthrope à tête de chien, fourrure châtaine, tablier taché, poêle. | Commerçant canonique sans nom propre ; apparence adaptée, V1 « Directeur en carton ». | Snack. |
| `ramikeldi` | M. Rami : homme-chat mûr, yeux ambrés, chemise blanche, gilet rouge foncé, chapeau. | Ramikeldi Limashenka, canonique, VEX « L'homme-chat » ; costume adapté. | Maison Limashenka. |
| `ferryman` | Reptilien en ciré, casquette de pilote, lunettes de vol. | Rôle canonique du passeur de l'île 53, V1 ; apparence adaptée. | Passerelle. |
| `baker` | Homme-bête massif à tête d'ours, tablier fariné, manches retroussées. | Commerce cité au V3 ; identité et apparence individuelle adaptées au jeu. | Boulangerie. |
| `garde_lookout` | Lézard en uniforme de la Garde, longue-vue. | Personnage **original facultatif**. | Ancien poste de guet du Couchant. |

Le corpus cible compte donc **52 apparences** : 24 déjà représentées, 21
manquantes de l'artbook et 7 PNJ adaptés ou originaux. La génération de ces
réserves ne signifie pas leur apparition simultanée dans l'acte 1.

## 4. Décors prioritaires et références exactes

Le contenu de MONDE définit les lieux. Les scans apportent les formes,
accessoires et ambiances ; le choix du 2D n'autorise pas une géographie inventée.
Les cinq zones sont des vues de jeu et des fonds peints de la même île miniature,
pas cinq régions indépendantes.

Les descriptions de zone ci-dessous servent désormais de **briefs narratifs**
pour les tuiles, façades et panneaux de ASSETS_HD2D. Les panoramas anime déjà
générés restent archivés. Le cahier ne demande pas cinq nouvelles cartes
géographiques ni de nouvelles images d'intérieur obligatoires.

| Zone / livrable | Contenu principal | Source du contenu | Scans utiles / limites |
| --- | --- | --- | --- |
| `village` — L'entrepôt des fées | Entrepôt en L de bois brun rapiécé, soubassement de pierre, ardoise bleu-gris, porche, puits, linge, cour, grand arbre, quatre portails de rondins. | MONDE §2.2 et §3, lieu canonique, agencement adapté au jeu. | p098 extérieur, p108 cour. L'entrepôt anime de p098 est monumental : la version rustique décrite dans MONDE prime. |
| `forest` — Les bois du marais | Feuillus d'automne et grands sapins, sentier moussu, terrain d'entraînement dégagé, roseaux, marais, tronc-passerelle, rocher moussu. | MONDE §2.3. Ruisseau/cascade : **originaux**. | p127 haut : forêt et passerelle. Pas de planche dédiée au marais identifiée ; marais adapté d'après MONDE. |
| `dunes` — Le bord du Couchant | Pierre claire affleurante, sable pâle, herbes couchées, cercle de veille, cloche, tour de guet en ruine, fanion, falaise et mer de nuages. | MONDE §2.4 : cette zone et son poste de guet sont **originaux**, appuyés sur les vents et bords d'île du canon. | p097 pour les îles/nuages. Ne pas transformer ce bord en grand désert canonique. |
| `beach` — Le port et le bourg | Rue pavée, maisons de pierre aux tuiles rouges, étals beiges, café, boulangerie, snack, quai de métal riveté, passerelles, grue, dirigeables au bord du vide. | MONDE §2.5. Nom « La Clochette » : **original**. | p125 port/île 68, p126 docks 68, p127 bas snack rustique. p113–117 sont explicitement **l'île 11** : inspiration architecturale seulement, pas localisation directe dans l'île 68. Aucune mer liquide ni plage tropicale. |
| `hill` — La colline des étoiles | Herbes dorées, chemin en lacets, sommet dégagé, banc/belvédère, arbre noueux, myosotis, ciel violet puis étoiles. | MONDE §2.6 ; colline de la promesse canonique, implantation et massifs de myosotis **originaux**. | Atmosphère des îles p097 ; aucun plan dédié identifié. Les talismans autour de Seniorious sont un effet séparé. |

Les quatre intérieurs précédemment envisagés sont des références / archives
complémentaires, sans remplacer les 96 fichiers précis du cahier HD-2D :

| Intérieur | Référence | Adaptation / réserve |
| --- | --- | --- |
| Réfectoire | p104 | Tables, bancs, cheminée, panneaux de corvées ; marques de taille d'après MONDE. |
| Salle de lecture | p107, bibliothèque p111 comme complément | Livres, rayonnages, fenêtres à banc, lumière chaude. p107 = salle d'archives ; p111 = bibliothèque, noms du scan conservés dans la provenance. |
| Infirmerie | MONDE §2.2 ; mobilier et matériaux des pièces p101–103 | Pas de planche dédiée identifiée. **Adaptation de jeu**, sans attribuer p103 à l'infirmerie : c'est la chambre de Chtholly. |
| Armurerie | p109 ; clés p085 ; armes p007, p014–15, p023, p029, p035, p039 | Descente et porte rivetée à cinq serrures d'après MONDE, vitrines ou râteliers de Carillons. |

Références complémentaires : p099 couloir/lavabos, p100 salle de bain, p105
cuisine, p106 couloir, p110 pavillon/salon. Ces pages ne sont pas des lieux
supplémentaires obligatoires dans l'acte 1.

## 5. Objets, végétation, terrain, aéronefs et Timere

| Lot 2D | Contenu | Références et statut |
| --- | --- | --- |
| Objets domestiques et de quête | Page illustrée, drap, engrenage, baies, myosotis ; ballon cousu, panier, balai, seau, livre, clés, vaisselle, théière, pain, œufs. | MONDE §2 et §3 ; p081 lanternes/thé, p082–83 couverts/vaisselle, p084 paniers/balais/seaux/bocaux, p085 clés, p087 monnaie, p088 nourriture. Forme individuelle des pickups adaptée. |
| Architecture et équipements | Puits, lampadaire/cristal, palissade/portail, banc, linge, remise, porte d'armurerie, cloche, fanion, ruine, panneau à deux flèches rouges, étal, caisses, tonneaux, ferraille, grue, passerelle et amarrage. | Liste exhaustive de MONDE §3 ; objets de jeu adaptés. Éléments du Couchant originaux. p108 pour la cour, p125–126 pour les docks. |
| Végétation et relief | Feuillus or/rouille/jaune, sapin sombre, arbre à balançoire, arbre noueux, baies, roseaux, fougères, herbes, myosotis, potager, rochers moussus et érodés, tronc. | MONDE §2 et palette §5.4 ; p127 pour forêt/passerelle. Variantes de jeu, pas nouvelles espèces canoniques nommées. |
| Terrain et horizon | Herbe, terre, dalles, pavés, pierre claire, sable pâle, eau sombre du marais, falaises, silhouettes d'îles et mer de nuages. | MONDE §2, §5.4 ; p097, p125, p128. Ne qualifier une texture de « tuilable » qu'après contrôle réel des raccords. |
| Aéronefs | Ferry bois/cuivre à ballon allongé et deux rotors ; petit transport militaire Barocupot sombre à deux rotors ; variantes de vues si nécessaires. | Descriptions MONDE §2.5/§3. p093 = patrouilleur militaire non nommé ; p094 = **Saxifraga**, pas Barocupot ; p095 = remorqueurs, barge et cargos. Ces scans inspirent les mécanismes, sans renommer les appareils officiels. Les formes demandées par MONDE sont des adaptations interprétées. |
| Timere | Une même créature déclinée en repos/mouvement/attaque : corps vert sombre voûté et amorphe, cou souple, gueule irrégulière, six pattes tentaculaires, griffes ivoire sale ; effets séparés. | ASSETS_3D §5 / silhouette de l'easter egg : adaptation de jeu, pas planche anatomique officielle identifiée. Quatre tailles de gameplay (`small`, `runner`, `normal`, `big`) partagent la même identité ; le grand fragment peut être plus sombre. |

## 6. Plan et contrôles de livraison

1. Préserver tous les originaux anime et leurs SHA-256 ; les montrer dans la
   galerie avec leurs téléchargements, sans les transformer ni les écraser.
2. Produire les 52 apparences **en pixel art**, avec les trois vues et mouvements
   ci-dessous, puis portraits distincts. Remplacer les anciens noms seulement
   par les aliases documentés, sans fabriquer de doublons.
3. Produire les **96 images d'environnement** du cahier, aux chemins exacts,
   dimensions exactes et priorités des tableaux. Conserver chaque génération
   native avant ajustement aux dimensions de livraison.
4. Vérifier chaque PNG, ses rectangles, marges, alpha, densité et ancre, puis
   générer les JSON réellement correspondants aux cellules. Montrer les cycles
   dans une galerie de contrôle ; une rangée de poses non contrôlée n'est pas
   qualifiée d'animation intégrée.
5. Tester les raccords gauche/droite et haut/bas des tuiles et matières. Ne pas
   annoncer un raccord parfait après un simple redimensionnement.
6. Mettre en place les outils / la scène nécessaires au rendu HD-2D lorsque les
   images livrées sont contrôlées ; vérifier le rendu dans Godot et lancer les
   contrôles appropriés. Aucun nouveau maillage de personnage n'est requis.

La direction pixel a été confirmée explicitement par l'utilisateur ; elle ne
découle pas d'une interprétation d'Octopath. Pixels nets, contours teintés de
1 px, aplats et dégradés en paliers, aucun dégradé lisse de peinture numérique,
aucun anticrénelage sur le fond. Les décors restent européens rustiques en
automne : bois patiné, pierre, ardoise, tuiles, cuivre et fer ; lumière du
couchant et bleu/violet dans les lointains. Pas de torii, de cerisiers roses ni
de plage marine tropicale. Les images anime anciennes gardent leur propre
style et leur statut d'archive réutilisable.

## 7. Dimensions, chemins et mouvements HD-2D

**96 px/m** pour les personnages, sol, falaises, façades et panneaux proches ;
**48 px/m** pour les deux dirigeables lointains. Les dimensions exactes des
tableaux font foi, avec arrondi de la hauteur des personnages au pixel entier.

| Contenu | Chemin de livraison | Dimensions / cadrage |
| --- | --- | --- |
| Personnage | `assets/characters/<id>/<id>.png` + `<id>.json` | Atlas de trois vues ; la première pose de repos a la hauteur corporelle prescrite, mesurée sans l'épée. Au moins 2 px transparents entre cellules. Ancre entre les pieds. |
| Portrait | `assets/characters/<id>/<id>_portrait.png` | 256 × 256 ; buste trois quarts droit, fond transparent. |
| Timere | `assets/enemies/timere/timere.png` + `.json` | Corps moyen au repos 99 px de haut ; mêmes trois vues à la demande utilisateur, sans portrait. |
| Sol | `assets/hd2d/ground/<nom>.png` | 384 × 384, vue de dessus, opaque, raccords quatre bords. |
| Falaise | `assets/hd2d/cliff/<nom>.png` | `cliff` / `underside` 384 × 384, raccords quatre bords ; `lip` 384 × 96, raccord horizontal. |
| Façade | `assets/hd2d/buildings/<nom>.png` | Dimensions exactes §6.1 ; élévation sans perspective ni dessus de toit ; mur jusqu'aux bords gauche, droit et bas. |
| Matière bâtiment | `assets/hd2d/buildings/materials/<nom>.png` | 192 × 192, opaque, raccords quatre bords. |
| Décor panneau | `assets/hd2d/props/<nom>.png` | Dimensions exactes §7 ; entier, centré, base au bord inférieur, aucune ombre portée peinte au sol. |
| Ciel / horizon | `assets/hd2d/sky/<nom>.png` | Dimensions exactes §8 ; panorama 2048 × 1024 à raccord horizontal, nuages 1024 × 1024 à quatre raccords. |
| Icône d'objet | `assets/items/<id>.png` | 64 × 64, objet centré, transparent ; IDs à vérifier dans les sources disponibles. |

Tous les PNG sont RGBA 8 bits ; alpha binaire 0/255 pour sprites, façades et
panneaux ; matières et tuiles opaques. Cible moins de 1 Mo par image et moins
de 25 Mo pour le jeu : ces budgets seront mesurés sur les fichiers produits.

| Mouvements des sept héros | Images par vue | ips | Boucle | Métadonnée |
| --- | --- | --- | --- | --- |
| `repos` | 2 | 2 | oui | — |
| `marche` | 6 | 10 | oui | — |
| `course` | 5 | 14 | oui | — |
| `attaque` | 4 | 14 | non | `coup: [1, 2, 3]` |
| `charge` | 4 | 10 | non | `onde: 3` |
| `degats` | 1 | 1 | non | — |
| `mort` | 1 | 1 | non | Défaite / épuisement pour les fées. |

Ithea et Nephren ajoutent `parle` : **2 images à 6 ips**, en boucle, dans chaque
vue. Chaque héros a 23 images par vue (69 pour trois vues), ou 25 par vue (75)
pour Ithea et Nephren.

Les 45 autres apparences ont, par vue : `repos` **2 / 2 ips**, `marche`
**6 / 10 ips**, `course` **4 / 12 ips**, `parle` **2 / 6 ips**, toutes en boucle.
La course des PNJ et son compte 4 / 12 sont une adaptation technique de la
demande utilisateur : le cahier §3.2 ne mentionne pas ce mouvement. Les trois
vues font 42 images par PNJ ; le corpus de 52 apparences représente donc
**2 385 images de mouvement**, hors portraits et Timere.

Timere suit les nombres propres du cahier §3.3 : `repos` 5 / 6 ips,
`marche` 4 / 7, `course` 6 / 12, `fouet` 4 / 8 (`coup: [1, 2]`),
`morsure` 4 / 8 (`coup: [1, 2]`), `degats` 5 / 12, `mort` 6 / 8.
Les corps de gameplay partagent cette identité, sans portraits supplémentaires.

Les 18 personnages du tableau §3.4 ont une hauteur prescrite : Chtholly 144,
Willem 168, Nygglatho 178, Ithea 139, Nephren 125, Tiat 106, Pannibal 120,
Collon 115, Lakhesh 115, Almita 91, Limeskin 269, serveur 158, Rami 163,
snack 154, boulanger 192, passeur 163, marchande 149, guetteur 182 ; Nopht
134 et Rhantolk 142 figurent également à la fin du tableau. Le cahier ne
prescrit pas les hauteurs de toutes les 52 apparences : compléter explicitement
leurs tailles de travail dans le manifeste plutôt que prétendre qu'elles y
figurent déjà.

## 8. Inventaire machine des 96 décors et divergences du checkout

Extraction exhaustive des tableaux §4 à §8 :
`/workspace/sukasuka-production/hd2d_jobs.json` (fichier de travail hors dépôt).
Les champs comprennent `path`, `width`, `height`, `dimensions`, `description`,
`category`, `priority`, densité, alpha, axes de raccord et section source ;
les façades comportent aussi type et matières du volume, les panneaux leur zone.

| Catégorie | Nombre |
| --- | --- |
| Sol | 12 |
| Falaises | 3 |
| Façades | 11 |
| Matières des bâtiments | 6 |
| Panneaux proches | 56 |
| Aéronefs lointains | 2 |
| Ciel, nuages, îles lointaines, rocher flottant | 6 |
| **Total** | **96** |

Les icônes d'objets §9 n'ont pas de liste exhaustive dans ce cahier ; les
trois effets procéduraux y sont facultatifs. Ils ne sont pas ajoutés aux 96
fichiers obligatoires. L'extraction est une spécification, pas une affirmation
que les images ont déjà été générées ou contrôlées.

Inspection du dépôt à réception du document :

- `tools/hd2d_assets.py` **n'existe pas**, contrairement aux affirmations des
  paragraphes d'ouverture, §2 et §10. Les commandes `fit`, `check`, `gen` ne
  sont donc pas encore exécutables ; leur implémentation est une tâche séparée.
- `tools/hd2d_manifest.json` et `assets/hd2d/` **n'existent pas** ; il n'y a pas
  déjà 96 remplaçants aux chemins annoncés.
- `tools/wordend/decouper-planche.py` n'existe pas dans ce dépôt ; le document
  le situe dans Yume-WordPress. `tools/gen_placeholders.py` existe, mais cela
  n'établit pas l'existence des outils ou textures HD-2D absents.
- `src/world/island.tscn` et `tools/screenshot.sh` **existent**. La scène de
  l'île utilise encore un ciel procédural, un `PlaneMesh` d'eau, un terrain
  et des décors du prototype ; elle ne référence pas les futurs panneaux
  `assets/hd2d`. La commande de capture seule ne prouve donc pas une migration
  HD-2D, et déposer les PNG ne suffit pas encore à les afficher dans cette scène.
- HISTOIRE.md et BIBLE.md restent absents : les descriptions d'objets / tailles
  non disponibles ne sont pas inventées comme citations de ces documents.

Ces constats décrivent l'état contrôlé avant les changements d'intégration ;
ils pourront être levés au fur et à mesure de leur implémentation et validation.
