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
