# À faire par Adrien, hors du jeu

Ce que Claude ne peut pas faire (droits, comptes, appareils, ou réglages réservés à Adrien par CLAUDE.md). À cocher au fur et à mesure. Mis à jour le 11 novembre 2026.

## Tout de suite

- [ ] **Sortir les modèles Blender dans GitHub, une première fois** (Rojo d'abord, `docs/DECISIONS.md`) : ouvrir BLIND SPOT dans Studio, **File → Save to File As** → `Documents\Roblox\BlindSpot.rbxl` (remplacer la copie du 6 novembre, qui n'a aucun modèle), puis me le dire. Je lance `./scripts/sync-models.sh`, la porte, et je commite. Ensuite, refaire la même sauvegarde locale chaque fois qu'un modèle change dans Studio.
- [ ] **Connect dans le plugin Rojo**, à chaque ouverture de Studio où je travaille : je lance `rojo serve` (port 34878), tu cliques Connect dans l'onglet Rojo. Le plugin est en 7.7.1 depuis le 11 novembre.
- [x] **Enregistrer la place dans Studio** : fait par Claude le 7 novembre (Ctrl+S, « Saved new changes in BLIND SPOT to Roblox » ; la place est dans le cloud, pas publiée en ligne). À refaire après chaque séance. Les modèles Blender (`ServerStorage.LobbyModels`, `ServerStorage.LevelModels`, `ReplicatedStorage.ClientModels`) n'existent que dans la place tant que la première sortie ci-dessus n'est pas faite.
- [x] **Les sons** : remplacés par 8 effets ProSoundEffects de la bibliothèque Roblox (libres dans tout jeu Roblox, ids dans `content/sounds.csv`). Nos fichiers synthétisés restent dans `assets/sounds/` si tu préfères les importer un jour. Ancienne note : les 8 fichiers de `assets/sounds/` (hum, vent, drone, drip, motor, clack, static, tear) dans Studio, Asset Manager, Import. Donner les ids à Claude (ou les mettre dans la colonne `asset` de `content/sounds.csv`). Sans eux le jeu est muet.
- [ ] **Vérifier son compte pour l'audio** : sans vérification d'identité, Roblox limite les imports audio à 100 par 30 jours (2 000 avec).
- [ ] **La licence du modèle de l'Invisible** : ton fichier Tripo (`tripo_convert_…fbx`). Avec un plan Tripo payant, le modèle est à toi ; avec le plan gratuit, il est public sous CC BY 4.0 et il faut créditer Tripo (dans la description du jeu par exemple). Dis-moi lequel, je l'écris dans `assets/SOURCES.csv`.
- [ ] **Le groupe Kestrel & Vane Security** (id 689591627) : ses membres reçoivent l'uniforme Kestrel & Vane dans la boutique (testé en Studio avec ton compte). Le jeu appartient encore à ton compte : le transférer au groupe est ton choix (revenus et accès d'équipe au groupe ; à faire avant de téléverser plus d'assets, sinon il faut les republier sous le groupe).
- [x] **Fusionner `phase-0` dans `main`** : fait le 8 novembre (main avancée jusqu'à phase-0).

## Tester ce que Studio ne prouve pas

- [ ] **Le test du plan, phase 0** : un ami qui ne connaît pas le jeu joue 10 minutes. A-t-il eu peur ? Noter ce qu'il n'a pas compris.
- [ ] **Un vrai téléphone**, le plus faible sous la main (idéalement un Android de 3 à 4 Go) : fluidité (30 images par seconde visées), boutons au doigt, lisibilité des zones sûres et de la barre SIGNAL.
- [ ] **La coop à 2, 3 ou 4** (avec des amis, sur le jeu publié ou en Team Test) : les seringues (tenir 6 s sur le badge d'un coéquipier pris), surveillance par les caméras, caméra tournée vers un coéquipier, nuit perdue si tout le monde est pris.
- [ ] **La vraie sauvegarde** : activer l'accès aux API (Game Settings, Security, Enable Studio Access to API Services) ou tester sur le jeu publié. La paie, le daily, les nuits débloquées et les cassettes doivent rester d'une session à l'autre.
- [ ] **Les boutons à la main** : l'outil de clic simulé n'a jamais marché ; toutes les actions ont été testées par leurs intentions réseau. Essayer PLAY, SOLO, START, LEAVE, les flèches de nuit, SHOP (acheter, équiper), DAILY, INVITE, SETTINGS, TAPES.

## Publier et régler le jeu (réservé à Adrien)

- [ ] **Publier la place** sur Roblox (le jeu, son nom, sa description).
- [ ] **Les deux places : un lobby de 20, des nuits de 4** (le code est prêt : `src/shared/Config/Places.luau`, `Services/LaunchService`, `Services/ArrivalService`). Tant que `Places.Night` vaut 0, rien ne change : le lobby joue les nuits lui-même.
  1. **Le lobby = la place de départ** « BLIND SPOT » (109730217990790). Dans Studio : Home → Game Settings → Places (ou le Creator Dashboard → ton expérience → Places → BLIND SPOT → Configure) : **Server size 20** (il est à 50).
  2. **Créer la place « Night »** : dans Studio, View → Asset Manager → Places → clic droit → **Add New Place** (ou Creator Dashboard → Places → Create place). La renommer **Night**. Sa configuration : **Server size 4**.
  3. **Fermer son accès direct** : dans le Creator Dashboard, la place Night → Access (ou Permissions) → décocher l'accès direct, pour qu'on n'y entre que par téléportation depuis l'univers. (Une place qui n'est pas la place de départ n'apparaît de toute façon pas sur la page du jeu.)
  4. **Y publier le même jeu** : la place de travail ouverte dans Studio, File → **Publish to Roblox As…** → ton expérience → la place **Night** → Overwrite. Les deux places tournent le même code : chaque serveur sait lequel il est par son PlaceId.
  5. **Me donner l'id de la place Night** (Creator Dashboard, ou `game.PlaceId` dans la barre de commande quand elle est ouverte) : je le mets dans `Places.Night`, puis tu **publies les deux places** (BLIND SPOT et Night) avec ce code.
  6. **Tester sur le jeu publié** (les téléportations ne marchent pas dans Studio) : seul sur LIFT A (une nuit solo, puis le retour au lobby avec la paie) ; à deux sur un même ascenseur (le chef appuie sur GO) ; QUICK PLAY (LIFT C) avec deux comptes qui ne sont pas amis ; et une mort en solo (RETRY rejoue la nuit dans le même serveur, LOBBY remonte).
  - À chaque mise à jour du jeu, publier **les deux** places.
- [ ] **Créer les produits Robux** : VIP (499 R$ dans le plan) et Overtime, +25 % de paie (299 R$). Donner leurs ids à Claude (`content/shop.csv`, colonne `robux_product`).
- [ ] **Le questionnaire de maturité** : viser **Mild** (pas de sang, pas de jurons, l'Invisible reste une silhouette).
- [ ] **Les serveurs privés** : les activer (prix Roblox) pour jouer entre amis.
- [ ] **L'analytique** (après publication) : Creator Dashboard, Analytics. Événements `NightStarted`, `NightEnded`, `GuardCaught` (nuit, étage, phase), `QuitDuringShift`, l'entonnoir d'accueil (Joined, FirstShift, FirstNightEnded, Night1Cleared) et l'économie de la paie. Les taux de prise réels par nuit serviront à régler la difficulté mieux que les robots du simulateur.

## Comptes et calendrier

- [ ] **Vérification d'identité et authentification à deux facteurs** sur le compte qui publie (condition pour les moins de 16 ans, plan section 10).
- [ ] **Abonnement Roblox Plus ou Premium avant le 12 décembre** : il faut deux mois d'abonnement continu pour que le jeu soit visible aux 9 à 15 ans au lancement du 12 février.
- [ ] **Les 250 parties de « joueurs très engagés » en 60 jours** pour la sélection : prévoir le test fermé et les amis.
- [ ] **Publier sous un groupe** plutôt que sous le compte perso, si c'est le plan : `InsertService` ne charge que les assets du propriétaire, et les modèles devront être téléversés au bon endroit.

## Décisions à trancher (plan, section 13)

- [ ] **Le nom** : BLIND SPOT [Stay on Camera], ou autre (la recherche Roblox confond « Blind Spot » et « Blind Shot »).
- [ ] **La date** : lancement le vendredi 12 février 2027 ?
- [ ] **Les avatars** : un modèle de garde réaliste commun à tous (recommandé), ou les avatars Roblox de chacun (c'est le cas en ce moment).
- [x] **La forme de l'Invisible** : ton modèle, posé (dos voûté, tête penchée, bras ballants), 8,5 studs, peau gris froid.
- [ ] **La seconde chance payante** : oui (environ 25 R$, une par nuit) ou rien au lancement.
- [ ] **Les noms de l'histoire** : le Halloway, Kestrel & Vane, Halloran (l'agent disparu des cassettes) : garder ou changer.
- [ ] **Un budget pour des assets payants**, ou seulement nos modèles et du CC0.
- [ ] **The Locust** : quel jeu tu visais, et 15 minutes sur Aisles Of The Locust et PERIPHERAL avant la suite de l'art.

## Lancement (phase 3 du plan)

- [x] **La miniature et l'icône** : Adrien a les siennes (4 miniatures, 7 novembre). Les mettre dans le Creator Dashboard (Places, Thumbnails ; Experience, Icon) au moment de publier.
- [ ] **La bande-annonce** (capture vidéo en jeu).
- [ ] **Le test fermé** d'une vingtaine de joueurs : la moitié doit finir la nuit 3.
- [ ] **Relire chaque cassette, note et réplique radio** (`content/tapes.csv`, `logbook.csv`, `radio.csv`) : pas de jurons, rien qui ferait monter le label.
