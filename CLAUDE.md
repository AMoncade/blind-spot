# BLIND SPOT

Jeu d'horreur Roblox en Luau : première personne, solo ou coop de 1 à 4, décor photoréaliste. La seule chose qui protège le joueur, c'est l'œil d'une caméra : l'Invisible n'existe que dans les angles morts. Lancement visé : vendredi 12 février 2027 (à confirmer par Adrien). Ce dépôt contient le plan et la recherche ; le code vient ensuite, bâti avec Claude Code en 4 phases (plan, section 12).

## À lire d'abord

- [`blind-spot-plan.md`](blind-spot-plan.md) : tout le plan. La version vivante est le [doc Claude](https://claude.ai/artifact/VMZVexNFcuM3uneHSmL6jm) ; le md en est l'export. La section 11 est le plan technique, la section 12 les phases et ce que « fini » veut dire pour chacune.
- [`research/plan/`](research/plan/) : la recherche derrière le plan (The Locust et les références, rendu réaliste sur Roblox, assets et licences, atmosphère et son, maturité et monétisation).
- [`research/concurrence/`](research/concurrence/) : ce qui existe déjà sur Roblox dans le genre (4 novembre 2026).

## Règles

- **Le serveur décide.** Il calcule qui est filmé, où est l'Invisible, qui meurt, ce qui est payé et sauvegardé. Le client envoie des intentions et anime. Chaque remote vérifie ses arguments et a une limite de débit.
- **Le doute profite au joueur.** Un joueur au bord d'un champ de caméra compte comme filmé ; le lag ne doit jamais tuer.
- **Les règles de l'Invisible ne changent jamais** (plan, section 4) : jamais dans un champ, jamais à l'écran, il voyage par l'ombre, il tue au contact dans un angle mort.
- **Tous les chiffres viennent de la config** : caméras (position, angle, portée), phases, Invisible, batteries, paie. Aucun chiffre en dur dans le code.
- **Un seul profil ProfileStore par joueur.** S'il ne charge pas, le joueur ne joue pas ; on ne démarre jamais personne sur une sauvegarde vide.
- **Téléphone d'abord :** tout marche au tactile, cibles d'au moins 44 px, testé à 844 × 390, et les budgets de rendu du plan (section 7) tenus sur un téléphone d'entrée de gamme.
- **Réaliste, rien de blocky.** Matériaux PBR, éclairage réglé à la main, aucune texture studs. Chaque asset importé a sa ligne dans `assets/SOURCES.csv` (source, licence, lien, date) avant d'être téléversé sur Roblox ; aucune source sans licence commerciale claire (plan, section 7).
- **Blender d'abord.** Tout objet plus complexe qu'une simple dalle (piliers, tuyaux, portes, caméras, néons, voitures, mobilier, caméscope, mains, l'Invisible) se modélise en 3D dans Blender par le MCP Blender, puis s'importe en MeshPart avec sa SurfaceAppearance. Jamais d'objet fait de Parts assemblés : les Parts ne servent qu'aux collisions, aux zones invisibles et à la version grise. Chaque modèle est un script dans `tools/blender/` qui le reconstruit de zéro ; budgets de triangles et de textures au plan, section 7.
- **Peur sans gore :** pas de sang, jamais plus de 3 flashs par seconde, et les options d'accessibilité du plan (sections 2 et 8).
- **Ne jamais créer de produits Robux, publier le jeu ou changer ses réglages.** Demander à Adrien.
- **Le dépôt est public** (choix d'Adrien du 6 novembre 2026) : n'y mettre ni secret, ni clé, ni nom d'utilisateur d'un autre joueur, ni capture qui en montre.
- Une tâche, un commit. Avant de dire qu'une tâche est finie : lint, format, specs, un playtest dans Studio, une console sans erreur, et une capture comparée aux images de référence.

## Break a Gem et Roll an Anomaly, les jeux d'Adrien

Dépôts **AMoncade/BreakAGem** et **AMoncade/roll-an-anomaly**, en lecture seule : les cloner à côté de celui-ci au besoin, ne jamais y pousser. Reprendre leur façon de travailler et leurs outils, pas leur art (Roll an Anomaly est en studs et en part-builder : rien de ça ici).

- `BreakAGem/CLAUDE.md` : la pile (Rojo, Rokit, Selene, StyLua, specs Lune, le MCP de Roblox Studio pour les playtests et les captures, ProfileStore) et une longue liste de pièges.
- `BreakAGem/tools/blender/` : des modèles écrits en code dans Blender.
- `BreakAGem/scripts/check.sh` : la seule porte avant chaque commit.
- `docs/WORKLOG.md` et `docs/DECISIONS.md` : ce qui a été fait, dans l'ordre, et les choix tranchés.

Pièges de Break a Gem qui toucheront ce jeu aussi :

- Les téléportations, Analytics, les vrais DataStores, `ProcessReceipt`, la voix et les parties à plusieurs clients ne se prouvent pas dans Studio : les marquer « à vérifier sur le jeu publié », jamais « fini ».
- Le MCP de Studio est une seule instance partagée : ne pas lancer de playtest pendant qu'une autre session s'en sert.
- `InsertService:LoadAsset` ne charge que les assets du propriétaire : garder une copie de chaque modèle dans la place, dans `ServerStorage`.
- `screen_capture` ne dessine pas les BillboardGui `AlwaysOnTop` : une invite absente d'une capture n'est pas un défaut.
- Une porte se juge à son code de sortie : `./scripts/check.sh | tail -1 && git commit` commite même quand la vérification échoue.
- Python écrit en CRLF sur le PC Windows d'Adrien : écrire les fichiers avec `newline="\n"`.
- Avec les réglages d'export FBX de Break a Gem, Blender (x, y, z) arrive dans Roblox en (−x, z, y) : vérifier les axes et l'échelle sur le premier modèle.

## Code, porte et Studio

- Lire d'abord [`docs/WORKLOG.md`](docs/WORKLOG.md) (ce qui a été fait, dans l'ordre) et [`docs/DECISIONS.md`](docs/DECISIONS.md) (les choix tranchés). Ajouter une entrée au WORKLOG quand une tâche est finie, puis commiter.
- **Arbre :** `src/shared` (ReplicatedStorage.Shared : `Config`, `Logic`, `Net`), `src/server` (ServerScriptService.Server : `Core`, `Services`), `src/client` (StarterPlayerScripts.Client : `State`, `Settings`, `Controllers`). `--!strict` partout ; les modules partagés font `require(if script then ... else "./chemin")` pour que les specs Lune les chargent.
- **Les chiffres :** `content/*.csv`, puis `py scripts/make_config.py` écrit `src/shared/Config/Content/` (jamais à la main).
- **La logique** des champs, de l'ombre, de la nuit et du directeur est pure (`src/shared/Logic`) et testée par `tests/*.spec.luau`. `lune run tools/sim/fieldmap [C03 C10 ...]` dessine les champs du P3 en ASCII (`#` solide, `.` filmé, blanc = angle mort).
- **La porte :** `./scripts/check.sh` (StyLua, Selene, config à jour, specs, build Rojo, manifeste) doit finir sur CHECK OK.
- **La place de travail** est `Documents\Roblox\BlindSpot.rbxl` (pas dans git) : elle garde le P3, le lobby et `ServerStorage.LobbyModels` (les modèles Blender du lobby ; `World` les place depuis `content/lobby_props.csv` et `content/lifts.csv`). Un modèle refait dans Blender : relancer son script de `tools/blender/`, l'importer, le ranger dans `LobbyModels` (MeshParts DoubleSided, collision précise pour les pièces creuses), enregistrer la place.
- **Charger dans Studio sans Rojo :** `py scripts/manifest.py`, `py scripts/serve.py` en arrière-plan (port 34896 ; 34893-34894 sont à Break a Gem, 34895 à Roll an Anomaly), puis en Edit : `return loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:34896/scripts/studio-load.luau?t=" .. os.clock(), true))()`. Ou ouvrir `build/BlindSpot.rbxl` que la porte construit.
- **En jeu, dans Studio :** F6 peint le sol (vert filmé, rouge angle mort), F7 passe à la phase suivante, F8 joue la nuit suivante. Le P3 gris se construit au démarrage du serveur depuis `content/map_p3.csv` (et supprime la Baseplate du gabarit).
- **L'éclairage** : Lighting.LightingStyle Realistic et PrioritizeLightingQuality sont déjà réglés dans la place (un script de jeu ne peut pas les changer, le plugin en Edit oui).
- **Les menus du lobby** : `src/client/Ui/Kit.luau` (le style : art de `Config/UiArt`, polices Oswald, Special Elite, Roboto Mono ; jamais Gotham ni une police par défaut) et `Ui/Menu.luau` ; côté serveur `Core/Data` (ProfileStore) et `Services/MenuService`. Aperçu en Edit sans playtest : `scripts/studio-ui-preview.luau` (`_G.BS_PREVIEW = "Shop"`, `"Daily"`, `"Settings"`, `"clear"`).
- **Le P3** : les modèles de la carte et des tâches sont dans `ServerStorage.LevelModels` (`tools/blender/level_props.py`) ; `World` les place depuis `content/map_p3.csv` (piliers, voitures, tuyaux, peinture) et `content/spots.csv` (les tâches), les textes peints depuis `content/signs.csv`. Les tâches : `content/tasks.csv`, `Services/TaskService` ; en Studio, l'intention `Debug "task" <spot>` agit comme l'invite du lieu. Aperçu de l'interface de quart en Edit : `_G.BS_PREVIEW = "Shift"` ou `"Report"`.
- **Le lobby** : les joueurs apparaissent au lobby (z 108 à 161, au nord du P3) ; un ascenseur lance le quart (`LobbyService`, puis `NightService.launch`). F8 en Studio relance une nuit avec les gardes en quart (ou tout le monde).

## Où on en est (7 novembre 2026, soir)

La boucle de jeu du chapitre 1 est en place et jouée dans Studio (`docs/WORKLOG.md`) : lobby et ascenseurs, six nuits qui se débloquent, ronde avec tâches et objets, zones sûres, Invisible et son directeur (apparitions, silence), mort (3 vies en solo, badge et surveillance en coop), lignes coupées, radio, cahier de bord, cassettes, paie et boutique, sons synthétisés, mains et caméscope en première personne, et les quatre niveaux du chapitre (P1 et son poste, P2, P3, P4 et la fin de la nuit 5 ; escalier, portes coupe-feu, plâtre). Aussi : le simulateur de 1 000 nuits (`tools/sim/nights.luau`), la ronde qui arrive au fil de la nuit, les signaux de coop sans chat, 10 cassettes, uniformes et lampes, l'uniforme du groupe Kestrel & Vane, l'analytique, le modèle de l'Invisible d'Adrien, l'Invisible qui saute au rythme de la barre, la préparation de partie, les compétences (sprint, fusée), K&V SUPPLY (le magasin d'améliorations du lobby, `docs/UPGRADES.md`). Restent : importer les sons dans Studio et mettre leurs ids dans `content/sounds.csv` ; prouver la coop, la vraie sauvegarde et l'analytique sur le jeu publié, puis régler la difficulté avec les vrais taux de prise ; le test sur un vrai téléphone ; la miniature et l'icône à choisir (`docs/A-FAIRE-ADRIEN.md`). Les décisions ouvertes pour Adrien sont à la section 13 du plan.
