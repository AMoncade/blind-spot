# Journal

Ce qui a été fait, dans l'ordre (la plus récente en dernier).

## 2026-11-06 : le code de la phase 0, sans Studio

Studio n'était pas connecté : tout est écrit et vérifié hors de Studio (StyLua, Selene, specs Lune, build Rojo). Rien n'est encore joué : le playtest, la console et les captures restent à faire (voir « À faire ensuite »).

- **La pile** reprise de Roll an Anomaly : `game.project.json`, `rokit.toml`, Selene, StyLua, specs Lune (`tests/run.luau`), chargeur Studio par HTTP (`scripts/manifest.py`, `scripts/serve.py` sur le port **34896**, `scripts/studio-load.luau`), et la porte `scripts/check.sh`.
- **La config** : `content/*.csv` (constantes, nuits, caméras, carte du P3, bornes de ronde) → `scripts/make_config.py` → `src/shared/Config/Content/*.luau` (générés, jamais à la main ; la porte vérifie qu'ils sont à jour).
- **La logique pure** (`src/shared/Logic`, testée par 31 specs) :
  - `Grid` : la carte en cases de 2 × 2 studs, les boîtes solides, le test segment-boîte ;
  - `Look` : le cône d'une caméra (lacet, tangage, champ horizontal et vertical, portée) ;
  - `Watch` : le champ d'une caméra (une case est filmée dès qu'un de ses points d'échantillon est vu : le doute profite au joueur), l'union des champs, « ce joueur est-il filmé » avec la marge de lag ;
  - `Shadow` : les chemins de l'Invisible par les cases ni solides ni filmées, les îles, la distance au champ le plus proche ;
  - `Timeline` : la nuit LIVE, FLICKER, BLACKOUT qui s'accélère, un FLICKER sur cinq en fausse alerte, les caméras qui tiennent par zone (leurs LED annoncent le blackout) ;
  - `Hunt` : le directeur (rôde, approche, chasse, répit), la cible, le contact, le silence 1,5 s avant la portée.
- **Le serveur** : `World` (le P3 en blocs gris, les 12 caméras, les 5 bornes, l'éclairage), `Actions` (routage et débit des remotes), `WatchService`, `CamcorderService`, `PowerDirector`, `UnseenService`, `NightService` (la nuit 3 en boucle, la mort et le réveil au poste), `DebugService` (Studio seulement : F6 peint le sol, F7 phase suivante, F8 nuit suivante).
- **Le client** : `FirstPerson` (verrouillée, corps visible, balancement réglable), `Camcorder` (F, R2 ou le bouton REC de 64 px : vision nocturne, REC, heure, batterie, trace VHS), `Atmosphere` (néons et LED REC selon la phase, au plus 3 flashs par seconde, option Réduire les flashs), `CameraHeads` (une caméra qui te filme pivote vers toi), `UnseenView` (la silhouette grise, cachée dans le caméscope), `Death` (gel, déchirure de bande, noir, réveil), `Hud` (montre, rondes, titre de nuit, point REC en option).
- **Les champs du P3** (`lune run tools/sim/fieldmap [ids]` les dessine en ASCII) : en LIVE, 21 % des cases ouvertes sont des angles morts (derrière les voitures, l'ombre des piliers, le fond des places) ; un blackout qui ne garde que C03 et C10 laisse 72 % du niveau dans le noir.

### À faire ensuite

1. Ouvrir une place dans Studio, charger le code (`CLAUDE.md`, « Code, porte et Studio ») ou ouvrir `build/BlindSpot.rbxl`, régler l'éclairage à la main (LightingStyle Realistic, PrioritizeLightingQuality), jouer une nuit : console sans erreur, captures, le sol peint en F6 phase par phase.
2. Les sons (Freesound CC0, une ligne par fichier dans `assets/SOURCES.csv`) : bourdonnement, ventilation, moteur de caméra, et le directeur du son (étouffé hors champ, silence de l'Invisible) avec l'API audio.
3. La travée de stationnement en art final dans Blender, testée sur un vrai téléphone.
4. Le trépied (solo) et les signes de l'Invisible en LIVE (objets déplacés, apparition au loin).

## 2026-11-06 (après-midi) : la carte dans Studio, et le lobby

- **Studio** : la place de travail est `Documents\Roblox\BlindSpot.rbxl` (copiée du build Rojo, puis enregistrée avec le P3, le lobby et `ServerStorage.LobbyModels`). L'éclairage est passé à LightingStyle Realistic et PrioritizeLightingQuality par le plugin (en Edit, ça marche).
- **Premier playtest** de la nuit 3 : 8 puis 9 modules au démarrage, aucune erreur ; le poste est filmé par C01 et C02 ; l'Invisible se déplace ; en BLACKOUT les caméras actives passent de 12 à 6. Les champs se calculent en 51 ms (une pause tous les 1 500 cases au lieu de 300).
- **Le lobby** (demande d'Adrien), dans l'esprit des lobbies d'horreur coop (les ascenseurs de DOORS et de Pressure, un groupe de 1 à 4) : le rez-de-chaussée du Halloway la nuit, au nord du P3 (z 108 à 161).
  - Coque en dalles simples depuis `content/map_lobby.csv`. Objets Blender faits par code (`tools/blender/lobby_elevator.py`, `lobby_props.py`), rangés dans `ServerStorage.LobbyModels` et placés depuis `content/lobby_props.csv` et `content/lifts.csv` : 3 monte-charges (cabine, cadre bronze, portes qui coulissent), le comptoir Kestrel & Vane et son mur de 9 écrans, le babillard (avis MISSING, règles de la nuit), 2 bancs, 2 lampadaires dehors derrière la vitrine.
  - `LobbyService` : un garde qui entre dans un ascenseur rejoint son groupe (4 au plus), 15 s de compte à rebours (START le ramène à 3 s, LEAVE fait sortir), les portes se ferment, fondu au noir, et le groupe se réveille au poste du P3. Pendant un quart, les ascenseurs affichent SHIFT IN PROGRESS. À 6 h, retour au lobby.
  - Client : `Controllers/Lobby` (panneau d'ascenseur, boutons de 48 px), troisième personne au lobby et première personne pendant le quart ; montre, rondes et bouton REC seulement pendant le quart.
  - Testé en playtest : apparition au lobby, portes ouvertes, panneau « LIFT B · P3 · 1/4 », départ, poste du P3 en première personne, SHIFT IN PROGRESS, fin de nuit et retour au lobby, sans erreur. **Pas vérifié** : les boutons START et LEAVE (l'outil de clic simulé n'a pas répondu de la session) ; à essayer à la main.
  - À vérifier sur le jeu publié : avec `game_place_id` réglé, le groupe part dans un serveur réservé de la place de jeu (TeleportService), ce qui ne se prouve pas dans Studio. Il faut qu'Adrien crée la place de jeu dans l'univers.

## 2026-11-06 (soir) : l'écran noir, et les menus du lobby

- **Le playtest tout noir** (signalé par Adrien) : rien de cassé (personnage, caméra, interface normaux), mais une lumière ambiante quasi nulle (RGB 5-7), sans lune, avec seulement quelques lampes : selon la qualité graphique, tout devenait noir. `Controllers/Atmosphere` règle maintenant la lumière de base par zone et par phase, côté client (constantes `lobby_*`, `p3_live_*`, `p3_flicker_*`, `p3_blackout_*`) : chaude au lobby, froide au P3, plus sombre en BLACKOUT mais jamais à zéro (plan, section 2). Le sol et les murs du lobby sont plus clairs. Le caméscope part de cette base pour sa vision nocturne.
- **La sauvegarde** : `Core/Data` (ProfileStore, copié de Roll an Anomaly), un profil par joueur, expulsion avec un message s'il ne charge pas. Dans Studio, ProfileStore tourne sur sa base simulée (rien n'est sauvé) : les vrais DataStores sont à vérifier sur le jeu publié.
- **Les menus du lobby** (demande d'Adrien), disposés comme dans DOORS et Pressure : la paie en haut à gauche, une rangée d'icônes-objets (SHOP, DAILY, INVITE, SETTINGS ; les codes sont dans Settings), PLAY et SOLO en bas au centre, loin du joystick et du bouton de saut.
  - Art généré dans un seul style (bureau de sécurité des années 90 : métal usé, laiton, papier, rouge REC), ids dans `src/shared/Config/UiArt.luau` ; polices Oswald, Special Elite et Roboto Mono partout (plus aucune police Roblox par défaut, ni Gotham), `Ui/Kit`.
  - SHOP (« Supply Room ») : des viseurs de caméscope payés avec la paie des quarts (`content/shop.csv`) ; le viseur équipé colore le caméscope en jeu. VIP et Overtime affichent SOON tant qu'Adrien n'a pas créé leurs produits.
  - DAILY : 7 jours (`content/daily.csv`), une réclamation par jour UTC, la série recommence si on rate un jour (`Logic/Daily`, specs).
  - INVITE : l'invitation de Roblox (`SocialService`), sans récompense.
  - SETTINGS : balancement de tête, champ de vision, réduire les flashs, point REC, et les codes (`content/codes.csv`), sauvés dans le profil.
  - PLAY entre dans l'ascenseur qui a le plus de gardes ; SOLO prend un ascenseur vide qui part en 3 s.
  - La paie d'un quart : `pay_shift` + `pay_round` par borne de l'équipe + `pay_no_death` si le garde n'a jamais été pris.
  - `scripts/studio-ui-preview.luau` dessine l'écran du lobby en Edit avec un faux profil (captures sans playtest).
- **Testé en playtest** : daily, codes, achat, équiper, réglages, SOLO jusqu'au P3, sans erreur. Les clics simulés n'ont jamais répondu de la session : chaque action est passée par son intention réseau ; les boutons sont à essayer à la main.

## 2026-11-06 (nuit) : un vrai stationnement, les zones sûres, les tâches

Demandes d'Adrien : que la carte ressemble à un bâtiment, qu'on voie clairement où les caméras protègent, et qu'on ait quelque chose à faire (une liste de tâches, aller chercher des objets, redémarrer un générateur), plus l'interface de jeu et les objets dans le style des menus.

- **Le P3 habillé** : dix modèles Blender faits par code (`tools/blender/level_props.py`, rangés dans `ServerStorage.LevelModels`) : le pilier en béton à bande jaune et noire, une berline générique sans marque (repeinte par voiture depuis `content/car_colors.csv`), les tuyaux et la gaine du plafond, la borne de ronde, le générateur, le bidon, le casier, la boîte à fusibles, la cassette et le magnétoscope. Les boîtes de la carte restent comme collisions invisibles et bloqueurs de caméra (DECISIONS). Peinture et signalétique par code : lignes de places et numéros au sol, ligne jaune pointillée, bande peinte et filet jaune sur les murs, pochoirs P3, LEVEL P3, SERVICE CORRIDOR, SECURITY (`content/map_p3.csv`, `content/signs.csv`).
- **Les zones sûres** (`Controllers/SafeZones`) : le sol filmé par chaque caméra en marche brille, case par case, à partir des mêmes champs que le serveur ; discret en LIVE, rouge sur les caméras qui tiennent en FLICKER et en BLACKOUT ; rien pour une caméra en panne. Les LED REC sont plus grosses et les caméras qui tiennent ont un halo rouge. En haut de l'écran : ● ON CAMERA ou BLIND SPOT. Les deux se coupent dans les réglages.
- **Les tâches** (`Logic/Tasks`, `Services/TaskService`, `content/tasks.csv`, `spots.csv`, `items.csv`) : chaque nuit, 2 bornes à scanner, redémarrer le générateur (le bidon d'essence est dans un angle mort ; d'ici là le couloir est noir et ses caméras C10 et C11 sont mortes), réparer le fusible de la caméra 07 (fusible dans le casier du poste), rapporter la cassette perdue (dans un de trois angles morts) au magnétoscope. Un objet à la fois ; un garde pris lâche ce qu'il porte. La paie compte les tâches faites. Planchette des tâches en haut à droite et repères dans le monde (`Controllers/Tasks`).
- **L'interface de quart** refaite dans le style des menus (`Controllers/Hud`) : la montre LCD, l'état caméra, le titre de la nuit, le rapport de 6 h (tâches, gardes perdus, paie). Le bouton du caméscope montre le caméscope équipé. Le panneau d'ascenseur est sur la plaque d'acier.
- **Les objets de la boutique** ont leur illustration (5 caméscopes, badge VIP, heures sup), dans le même style ; la montre et la planchette aussi (`Config/UiArt`).
- **Corrigé en route** : le module d'état du client plantait au chargement (il lisait l'ancienne config des rondes, supprimée).
- **Testé en playtest** (par les intentions réseau et la commande Studio `Debug task <spot>`) : les cinq tâches de bout en bout, les caméras qui reviennent, le couloir qui se rallume, 68 rectangles de zones sûres, la planchette à 5/5, sans erreur.
- **Pas encore fait** : le bureau du poste est encore une boîte, les mains et le caméscope en première personne, les sons, la coop au poste après la mort, les cassettes à regarder.

## 2026-11-06 (fin de soirée) : le gameplay, étape par étape

Demande d'Adrien : faire tout le gameplay, étape par étape. Six étapes, chacune commitée et jouée en playtest (par les intentions réseau et les commandes Studio `Debug`).

1. **Les nuits et la difficulté** (`content/nights.csv`) : six nuits nommées, ORIENTATION, STATIC, BLACKOUT, CUT LINES, THE LAST ROUND et SLEEPLESS (la Nuit blanche du plan), chacune avec sa durée, ses phases, la vitesse de l'Invisible, des bornes en plus et des câbles coupés. Une nuit est réussie si toute la ronde est faite avant 6 h : ça débloque la suivante (`bestNight` dans le profil). Le premier garde d'un ascenseur choisit la nuit (< >). Plus de gardes : une borne de plus et un Invisible 5 % plus rapide par garde. Rapport : NIGHT CLEARED, ROUND UNFINISHED ou ALL GUARDS LOST.
2. **La mort et la coop** : 3 vies en solo (à zéro, la nuit est perdue). En coop, un garde pris se réveille au poste et regarde par les caméras (`Controllers/Watcher`, l'Invisible n'y est jamais) ; il peut tourner une caméra de 40° au plus vers un coéquipier (le serveur recalcule son champ, la tête et la zone sûre suivent). Son badge tombe où il a été pris ; un coéquipier qui le rapporte au registre du poste le ramène, une fois par nuit (`Services/CoopService`). Tout le monde pris : la nuit est perdue. **À vérifier sur le jeu publié** (plusieurs joueurs).
3. **Les lignes coupées** (nuits 4 à 6) : pendant la nuit, la ligne d'une caméra est arrachée : elle meurt et pend, une boîte de jonction apparaît dessous (`World.addSpot`), une tâche demande de la réparer.
4. **Le guidage et l'histoire** (`Services/StoryService`, `Controllers/Story`, `Ui/TapePlayer`) : la radio de la répartitrice en sous-titres (`content/radio.csv` : le tutoriel de la nuit 1, puis de plus en plus étrange), le cahier de bord du poste (`content/logbook.csv`), une cassette cachée par nuit dans un angle mort profond (`content/tapes.csv`, 5 cassettes, gardées dans le profil, jouées dans TAPES au lobby).
5. **Les signes de l'Invisible** : en LIVE il apparaît parfois loin devant un garde, immobile, puis n'y est plus ; le silence avant qu'il soit à portée se voit (bords de l'écran qui s'assombrissent, [ THE HUM STOPS ]).
6. **Le son** (`Controllers/SoundDirector`, `content/sounds.csv`) : 8 sons synthétisés par code (`tools/audio/make_sounds.py` vers `assets/sounds/`) ; bourdonnement et ventilation qui s'étouffent hors champ et meurent au silence, drone de blackout, moteur d'une caméra qui te filme, néons qui claquent, grésillement radio, bande qui se déchire, gouttes d'eau ; sous-titres des sons qui comptent. **Les sons ne s'entendent pas encore** : il faut les importer dans Studio (Asset Manager, Import) et mettre leurs ids dans `content/sounds.csv`.

Studio : `Debug` accepte maintenant `kill`, `done`, `tape`, `sight` et `task <spot>` (Studio seulement).

## 2026-11-07 : la barre de signal et les bords qui noircissent

Demande d'Adrien. En bas au centre, la barre SIGNAL : pleine sous une caméra, elle se vide hors champ (25 s en LIVE, 18 en FLICKER, 12 en BLACKOUT) et se remplit en 5 s sous une caméra. Vide, le garde est marqué : HE KNOWS WHERE YOU ARE, l'Invisible le chasse quelle que soit la phase jusqu'à ce que la barre repasse 40 % (`Hunt.exposure`, specs). Hors champ, les bords de l'écran noircissent, de plus en plus à mesure que la barre se vide. La radio est remontée pour lui laisser la place.
