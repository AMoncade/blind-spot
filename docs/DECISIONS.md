# Décisions

Les choix tranchés, avec leur raison. Les décisions ouvertes pour Adrien sont à la section 13 du plan.

## Les champs se calculent sur les boîtes de la config, pas par des rayons Roblox (6 novembre 2026)

Le serveur ne lance aucun `workspace:Raycast` pour savoir ce qui est filmé : chaque boîte de `content/map_p3.csv` qui a `occludes` arrête les rayons, dans un test segment-boîte en Luau pur (`Logic/Grid.segmentHits`). Ces boîtes sont aussi les collisions invisibles que l'art final gardera (CLAUDE.md : les Parts servent aux collisions). Ainsi les specs Lune, le futur simulateur de 1 000 nuits et le serveur calculent exactement les mêmes champs, et un modèle Blender plus détaillé ne change jamais une règle.

## Une case est filmée dès qu'un seul de ses points est vu (6 novembre 2026)

Chaque case est testée au centre et à quatre coins rentrés de 0,4 stud, à 0,5, 3 et 6,5 studs du sol (6,5 couvre la tête de l'Invisible de 8,5 studs). Un seul point vu suffit. Un joueur compte comme filmé si une case filmée touche son cercle de 1,5 stud plus 1 stud de marge de lag. Le doute profite au joueur, et l'Invisible ne peut se tenir nulle part où un bout de lui serait à l'image.

## Le caméscope est placé par le serveur (6 novembre 2026)

Le client n'envoie que « levé » et sa direction (lacet, tangage) dix fois par seconde. Le serveur place l'œil à la tête du personnage, limite la rotation à 540° par seconde et tient la batterie. Le caméscope teste seulement le centre des cases, à deux hauteurs, pour rester léger à quatre joueurs.

## Les néons clignotent par créneaux de 0,34 s minimum (6 novembre 2026)

Le motif du FLICKER est tiré du temps du serveur et de la graine de la nuit, donc identique chez tous les joueurs, et chaque état dure au moins 0,34 s : jamais plus de 3 flashs par seconde (WCAG 2.3.1). Avec « Réduire les flashs », les néons baissent au lieu de clignoter et les LED ne clignotent plus.

## Phase 0 : la nuit 3 en boucle, réveil au poste (6 novembre 2026)

Pour la preuve de la peur, le serveur joue la nuit 3 (les premiers blackouts) dès qu'un joueur est là, puis recommence. Une mort fige le joueur 2,2 s et le réveille au poste ; la reprise à la dernière tâche, la paie et la sauvegarde viennent en phase 1.

## Le lobby est dans la même place, avec des ascenseurs (6 novembre 2026)

Demande d'Adrien : un lobby où les gens lancent la partie, inspiré des autres jeux d'horreur. On a pris la forme la plus connue du genre, des ascenseurs où un groupe de 1 à 4 se forme avant un compte à rebours, et on l'a habillée pour l'histoire : le hall de nuit du Halloway, d'où les monte-charges descendent au P3. Tant qu'il n'y a pas de place de jeu séparée (Adrien seul peut la créer), le quart se joue dans la même place, un à la fois. Avec `game_place_id`, `LobbyService` envoie le groupe dans un serveur réservé.

## L'éclairage Realistic se règle par le plugin (6 novembre 2026)

La recherche disait que LightingStyle et PrioritizeLightingQuality ne se règlent pas par script. Un script de jeu ne le peut pas, mais le plugin en Edit le peut : la place est en Realistic, priorité à la qualité, comme le demande le plan (section 7).

## Les zones sûres se voient au sol (6 novembre 2026)

Demande d'Adrien : afficher clairement où les caméras protègent. Le plan voulait tout dire sans interface (la caméra qui pivote, le silence) ; on garde ces signes et on ajoute une lueur au sol, calculée case par case avec les mêmes champs que le serveur, donc qui ne ment jamais, plus l'état ON CAMERA / BLIND SPOT en haut de l'écran. Les deux se coupent dans les réglages pour qui veut l'ancienne version. La lueur montre les cases du champ ; un garde compte comme filmé un peu au-delà (marge de lag), donc elle est du côté sûr.

## Les tâches ont un effet sur la nuit (6 novembre 2026)

Le générateur, le fusible de la caméra 07 : tant qu'ils ne sont pas faits, des caméras sont mortes et une zone est noire. Faire sa ronde rend donc le niveau plus sûr, et les objets à chercher sont mis dans des angles morts : le joueur doit sortir des champs pour gagner de la sécurité.

## Les modèles Blender gardent les boîtes de la config (6 novembre 2026)

Les piliers et les voitures sont des modèles Blender, mais les boîtes de `map_p3.csv` restent, invisibles, comme collisions et comme bloqueurs des rayons de caméra : les champs ne dépendent jamais du détail d'un modèle (voir « Les champs se calculent sur les boîtes de la config »).

## Une nuit se réussit en finissant la ronde avant 6 h (6 novembre 2026)

Survivre ne suffit pas : la nuit est réussie seulement si toute la ronde est faite avant 6 h, et seule une nuit réussie débloque la suivante. Les tâches poussent à sortir des champs (les objets sont dans des angles morts) : c'est la tension du jeu.

## Solo : 3 vies ; coop : le badge (6 novembre 2026)

Le plan disait qu'en solo la nuit reprend à la dernière tâche. Sans limite, la mort ne coûtait rien : trois prises par nuit, puis la nuit est perdue. En coop, le plan est suivi : le garde pris surveille par les caméras, et son badge rapporté au poste le ramène une fois.

## L'apparition au loin peut changer d'île (6 novembre 2026)

L'Invisible voyage par l'ombre (règle 4), mais le plan veut aussi qu'il « se montre au bout d'un couloir sombre, immobile, puis n'y est plus ». Pour une apparition, il peut se tenir sur n'importe quelle case d'ombre en vue du garde, jamais dans un champ (règle 1). Le reste du temps, il marche par l'ombre.

## Nos sons sont synthétisés (6 novembre 2026)

Aucun outil ne téléverse de l'audio ; les sons sont donc faits par code (`tools/audio/make_sounds.py`), à nous sans licence à suivre, et Adrien les importe dans Studio. Freesound CC0 reste possible pour les remplacer.

## Les étages côte à côte dans une seule grille (7 novembre 2026)

Les quatre niveaux du chapitre 1 sont posés côte à côte le long de x (P1 à -190, P2 à 160, P3 à 0, P4 à 330), pas empilés. Une seule grille les couvre ; les cases entre les dalles sont bloquées, donc chaque étage est une île : l'Invisible ne marche jamais d'un étage à l'autre, il prend l'escalier hors de vue (`unseen_floor_delay`). Les caméras, les rayons et les chemins restent en 2D, sans rien changer à `Logic/Watch` ni à `Logic/Shadow`. On passe d'un étage à l'autre par la porte de l'escalier (une téléportation devant la porte d'arrivée).

## Les portes coupe-feu et le plâtre changent la grille (7 novembre 2026)

Un bloc de la carte peut changer d'état pendant une nuit (`Watch.DYNAMIC` : `firedoor` ouvert par défaut, `plaster` plein par défaut). Le serveur recalcule la grille sur place et seulement les champs des caméras proches ; les clients font pareil à partir de l'attribut `Solid` de la boîte. Une porte fermée protège d'un côté mais aveugle les caméras de l'autre : c'est un choix pour le joueur, pas une cachette sûre.

## La ronde arrive au fil de la nuit (7 novembre 2026)

Le simulateur a montré qu'un garde efficace finissait toute la ronde en une ou deux minutes, avant le premier vacillement, puis attendait au poste toujours filmé : le cycle du courant ne comptait plus. Le plan dit l'inverse (« le cycle du courant tourne pendant toute la ronde »). Chaque tâche a donc une heure d'arrivée (`tasks.csv`, colonne `hours`) ; elle apparaît sur la planchette avec un avis et la radio, et son effet commence avec elle. La nuit reste gagnée si tout est fait à 6 h.

## En LIVE, l'Invisible ne tue pas (7 novembre 2026)

Les morts de la nuit 1 venaient toutes d'un garde qui entrait dans un angle mort en cul-de-sac où l'Invisible rôdait sans pouvoir s'écarter. En LIVE (rôder) et pendant la pause du directeur, il ne touche personne ; un garde qui arrive à moins de 7 studs le voit disparaître (« il se montre, puis n'y est plus »). Le danger du LIVE, c'est la barre SIGNAL : un garde marqué est chassé dans toutes les phases.

## La difficulté au simulateur, et sa limite (7 novembre 2026)

Cibles du plan : moins de 5 % de gardes pris à la nuit 1, environ 30 % à la nuit 3, environ 50 % à la nuit 5. Avec les robots (moitié prudents, moitié distraits) et les réglages retenus (une seule caméra qui tient par zone dès la nuit 3, vacillements de 5 à 3,5 s à la nuit 5, Invisible de 0,85 à 1,35 fois sa vitesse selon la nuit), on obtient environ 0 % à la nuit 1, 14 % à la nuit 3, 20 % à la nuit 4, 44 % à la nuit 5, 50 % à la nuit 6 (100 nuits par mesure aux nuits 3 et 5 : ±4 à 5 points). Les prudents sont pris 3 fois moins que les distraits. Les robots savent toujours où est la caméra qui tiendra et y courent au plus court ; un vrai joueur cherche, hésite, se perd. On n'a donc pas poussé les réglages jusqu'aux cibles chez les robots : ce serait trop dur pour des humains. Le vrai réglage se fera avec l'analytique du jeu publié (`GuardCaught` par nuit, étage et phase), puis le simulateur servira à vérifier qu'un changement va dans le bon sens.

## La coop sans chat (7 novembre 2026)

Pas de chat écrit pendant un quart : six signaux courts dans une roue (`content/signals.csv`), un repère dans le monde et une ligne dans le fil. Ça marche au téléphone, sans traduction, sans modération de texte, et ça garde le silence de la nuit.

## L'Invisible ne marche plus : il saute, au rythme de ta barre (7 novembre 2026)

Demande d'Adrien. Avant, il marchait par l'ombre et chassait pendant les blackouts. Maintenant il ne bouge jamais à vue : il apparaît dans un angle mort, te regarde, et réapparaît ailleurs d'autant plus près que ta barre SIGNAL est basse ; barre vide hors caméra, c'est la prise. La barre devient la vie de la nuit, lisible d'un coup d'œil, et la peur vient de le voir plus proche à chaque fois. Les règles du plan tiennent : jamais dans un champ (une caméra sur sa case l'envoie ailleurs), jamais à l'écran, tes yeux ne comptent pas. Les phases jouent sur la vitesse de la barre et la fréquence des sauts. Les cibles de difficulté du plan sont à mesurer de nouveau sur de vraies parties.

## La préparation de partie et ses récompenses (7 novembre 2026)

Avant chaque nuit : chapitre, carte, nuit, gardes, vies. La paie est multipliée par la difficulté (nuit, moins de vies, moins de gardes), calculée par le même module à l'écran et au serveur. Les vies sont partagées par l'équipe.

## Des choix plutôt que de l'attente (8 novembre 2026)

Adrien : « que ce soit pas juste toujours attendre ta barre qui se reset ». Trois leviers : (1) des caméras mortes dès le début des nuits avancées, donc des zones noires qu'on doit traverser ; (2) des compétences limitées qui sont des décisions sur le noir : le SPRINT pour traverser, la FUSÉE pour faire une île sûre là où il faut travailler (et pour un coéquipier), le caméscope à 5 s qu'on rallonge en achetant des batteries ; (3) des tâches qui se font dans les angles morts. Le caméscope reste un outil de groupe : ce qu'il filme protège les autres. Idées pour plus tard : un trépied qui pose une caméra pour une minute, un leurre sonore, une lampe qui fait baisser la barre moins vite mais qu'il voit de loin.
