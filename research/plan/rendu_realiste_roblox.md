# Rendu photoréaliste sur Roblox fin 2026 et limites des téléphones (pour BLIND SPOT)

Notes de recherche rédigées le 6 novembre 2026. Chaque limite porte la date de sa source. Les pages de documentation de create.roblox.com n'ont pas de date de publication visible (sauf mention) : elles reflètent l'état consulté le 6 novembre 2026. « Non vérifié » = affirmation d'un utilisateur du forum ou d'un média secondaire, pas de Roblox.

## Question 1 : Éclairage (technologies, téléphones, ombres des lumières locales, Atmosphere, Sky, exposition, nouveautés 2025-2026)

### Takeaway
Depuis le 23 juillet 2025, `Lighting.Technology` (Voxel / ShadowMap / Future) est remplacé par **Unified Lighting** : `LightingStyle` (Realistic ou Soft) et `PrioritizeLightingQuality`, non scriptables ; Realistic + Prioritize activé équivaut à l'ancien Future. Les téléphones affichent l'éclairage « Future » mais le moteur le réduit seul sur les appareils faibles. Les ombres sont coupées sous le niveau de qualité graphique 4. Le nombre de lumières avec ombres est plafonné par image, sans chiffre public. La portée des lumières locales est passée de 60 à 120 studs le 23 septembre 2025.

### Cited Findings

**Unified Lighting (remplace Technology)**
- Bêta Studio le **21 janvier 2025**. Le **23 juillet 2025**, le post annonce : « Unified Lighting has been fully released and is now live in all experiences! ». Les expériences qui n'avaient pas réglé les nouveaux paramètres ont reçu leur réglage `Technology` converti automatiquement. — [DevForum, Unified Lighting (post d'origine + mises à jour)](https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-enters-studio-beta/3401512/1)
- Unified Lighting « replaces the existing *Technology* property in the Lighting Service with two new, intuitive properties ». « Neither of these properties are scriptable, similar to the old *Technology* property. » — [DevForum, Unified Lighting](https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-enters-studio-beta/3401512/1)
- Correspondances officielles : Future = `LightingStyle` Realistic + `PrioritizeLightingQuality` activé ; ShadowMap = Soft + activé ; Voxel = Soft + désactivé. Aucune correspondance donnée pour Compatibility. FAQ : Realistic + désactivé = éclairage Future avec une distance d'ombrage plus courte, donc le passage à l'éclairage moins détaillé se fait plus près du joueur. — [DevForum, Unified Lighting](https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-enters-studio-beta/3401512/1)
- `PrioritizeLightingQuality` : activé = garder la qualité d'éclairage le plus haut possible en réduisant d'abord le reste (distance d'affichage) ; désactivé = réduire d'abord l'éclairage. — [DevForum, Unified Lighting](https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-enters-studio-beta/3401512/1) ; [Docs, Lighting](https://create.roblox.com/docs/environment/lighting)
- Doc API : `Technology` est marqué « Deprecated » : « This property has been superseded by LightingStyle ». `LightingStyle.Soft is the stylized look; LightingStyle.Realistic is the naturalistic look.` — [Docs API, Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting)
- Docs Lighting : « Realistic provides the most advanced and realistic lighting and shadows Roblox can deliver. » `ShadowSoftness` va de 0 (bords nets) à 1 (bords flous) et « is only valid when LightingStyle is set to Realistic ». — [Docs, Lighting](https://create.roblox.com/docs/environment/lighting)
- Contradiction mineure : la doc API dit encore que `ShadowSoftness` (défaut 0,2) « only works when Technology mode is ShadowMap or Future and the device is capable of rendering shadow maps ». C'est un texte de l'ère Technology, pas mis à jour. — [Docs API, Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting)
- Réponse du staff (ItsRainingPixels, **22 janvier 2025**) : « We're still actively tweaking how and when Unified Lighting scales throughout the duration of this Studio Beta. » — [DevForum, Unified Lighting, page 4](https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-enters-studio-beta/3401512?page=4)
- Le post dit que l'éclairage « scales smoothly across all devices », sans tableau par appareil. — [DevForum, Unified Lighting](https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-enters-studio-beta/3401512/1)

**Téléphones**
- **29 octobre 2024** : l'éclairage Future est « fully rolled-out to all **Android** devices as a Client Beta ». Avant, Android affichait ShadowMap à la place. Future « can run on all Android devices » mais reste « costly in performance and not all devices can run Future Lighting at interactive framerate ». Sur les appareils d'entrée et de milieu de gamme, « the engine will reduce their lighting quality to offer them better framerate ». Pas de niveaux de qualité ni d'exigences matérielles précis. iOS n'est pas mentionné. — [DevForum, Future is Bright on Android](https://devforum.roblox.com/t/future-is-bright-on-android-is-fully-rolled-out-client-beta/3235808)
- **19 novembre 2020** (Phase 3) : Future d'abord sur ordinateur (D3D11, Vulkan, Metal), puis sur les mobiles Metal et Vulkan « after further testing ». Les appareils incompatibles retombent sur ShadowMap, ou Voxel si ShadowMap n'est pas pris en charge. « per-pixel lighting distance depends on the current quality level. » — [DevForum, Future is Bright Phase 3 Released](https://devforum.roblox.com/t/future-is-bright-phase-3-released/878634)
- Ombres et niveau de qualité : le moteur baisse la qualité des ombres quand la qualité graphique baisse, et coupe les ombres « at quality levels below 4 ». — [Docs, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)

**Lumières locales et ombres**
- Trois types : PointLight (sphérique), SpotLight (cône ; `Angle` max 180, « street lamps, flashlights »), SurfaceLight (émise par toute une face ; exemple donné : « fluorescent panels »). Propriété commune `Shadows` : « projects shadows where light is blocked by an obstacle ». Recommandation : placer PointLight et SpotLight dans un Attachment. — [Docs, Light sources](https://create.roblox.com/docs/effects/light-sources)
- Coût des ombres (Phase 3, 2020, toujours la référence officielle la plus précise trouvée) : « Spot shadows are the cheapest » quand l'angle est étroit, « say below 120 degrees ». Viennent ensuite les ombres de SurfaceLight, limitées par la taille de la lumière et la résolution de la shadow map. « the most expensive (by a margin) are point shadows. » « The number of per-pixel lights as well as number of shadowed lights is limited in each particular frame. » Le post ne donne aucun chiffre. Future « does proper specular highlights for local lights ». — [DevForum, Phase 3 Released](https://devforum.roblox.com/t/future-is-bright-phase-3-released/878634)
- Doc performance : « Handling shadows is an expensive process. » Leviers : `BasePart.CastShadow` à false (peut créer des artefacts), `Light.Shadows` à false, réduire portée et angle, moins de lumières, désactiver les lumières hors de la zone du joueur. Scopes MicroProfiler à surveiller : « LightGridCPU », « ShadowMapSystem ». — [Docs, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- `CastShadow` : « Disabling this property for a given part can cause visual artifacts on the shadows cast upon that part. » La propriété n'est pas faite pour gagner en performance. — [Docs API, BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart)
- **Portée** : le **23 septembre 2025**, Roblox double la portée de PointLight, SpotLight et SurfaceLight, de 60 à 120 studs. Les valeurs scriptées au-dessus de 120 sont ramenées à 120. « When we increase the range of a light, its computational cost rises exponentially. » Conseil : une grande lumière plutôt que quatre petites. Exemple : le circuit du Racing Template est passé de vingt lumières de portée 60 à cinq de portée 120. Le post ne dit rien des ombres. — [DevForum, Extended Light Ranges](https://devforum.roblox.com/t/extended-light-ranges-doubling-the-limit-to-120/3954367)
- Annoncé dans ce même post (septembre 2025) : une amélioration de l'atténuation des lumières dans « the next couple of months », et des portées plus grandes « no timeline to share yet ». — [DevForum, Extended Light Ranges](https://devforum.roblox.com/t/extended-light-ranges-doubling-the-limit-to-120/3954367)
- Non vérifié : un commentaire du forum parle d'une limite de 200 pour les comptes vérifiés de 13 ans et plus. Le post officiel ne le mentionne pas. — [DevForum, Extended Light Ranges](https://devforum.roblox.com/t/extended-light-ranges-doubling-the-limit-to-120/3954367)

**Propriétés de Lighting (doc API, consultée en novembre 2026)**
- `ExposureCompensation` : « Defaults to 0 (no exposure compensation) and has a range from -5 to 5. » — [Docs API, Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting)
- `EnvironmentDiffuseScale` (défaut 0) : lumière ambiante tirée de l'environnement. « When this property is increased, it's recommended to decrease Ambient and OutdoorAmbient accordingly. » `EnvironmentSpecularScale` (défaut 0) : « will make smooth objects reflect the environment ». Les deux vont de 0 à 1. Près de 1, le métal paraît plus réaliste. — [Docs API, Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting) ; [Docs, Lighting](https://create.roblox.com/docs/environment/lighting)
- `Ambient` : « the lighting hue applied to areas that are occluded from the sky, such as indoor areas », défaut [0, 0, 0] (noir). `OutdoorAmbient` : défaut [127, 127, 127], « clamped to be greater than or equal to Ambient in all channels ». — [Docs API, Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting)
- `GlobalShadows` à false : « shadows are not drawn and no distinction is made between indoor and outdoor areas ». — [Docs API, Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting)
- `FogStart` et `FogEnd` sont en studs depuis la caméra. « Note that fog properties are hidden when Lighting contains an Atmosphere object. » — [Docs API, Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting)
- **Atmosphere** : `Density` (« the higher the density, the more particles, which obstruct a player's view of objects and terrain »), `Offset`, `Haze`, `Color`, `Glare` (visible seulement si Haze > 0), `Decay`. La doc ne dit rien des intérieurs, du coût ni des téléphones. — [Docs, Atmosphere](https://create.roblox.com/docs/environment/atmosphere)
- Non vérifié (utilisateur, 2023) : `EnvironmentDiffuseScale` dépend du ciel ou de la cubemap de réflexion, « which isn't controllable », et `ColorShift_Bottom` « does nothing nowadays ». — [DevForum, Future Lighting needs to expose more internal properties](https://devforum.roblox.com/t/future-lighting-needs-to-expose-more-internal-hardcoded-properties-for-light-instances/2580333)

**Annonces 2025-2026 au-delà d'Unified Lighting**
- Feuille de route RDC (**26 septembre 2025**) : rien sur les ombres, le post-traitement ou le rendu vers texture. Rendu annoncé : textures 4K et cartes émissives pour SurfaceAppearance (« Late 2025 »), SLIM (« Late 2025 »), terrain voxel amélioré (« Mid 2026 »), Freecam amélioré (« Mid 2026 »). — [DevForum, Creator Roadmap 2025 : RDC Update](https://devforum.roblox.com/t/creator-roadmap-2025-rdc-update/3961527)
- **Roblox Reality** (annoncé le **1er mai 2026**) : surcouche de photoréalisme par IA (« Video World Models », Roblox Cloud) sur le moteur existant. « Roblox expects to release an early version later this year or in early 2027 ». Problèmes de mise à l'échelle et de coût de calcul encore à régler. Aucun détail sur les plateformes ni sur le contrôle laissé aux créateurs. — [MMOHuts, 1er mai 2026](https://mmohuts.com/news/roblox-says-its-new-ai-powered-reality-upscaler-could-arrive-in-early-form-by-2027) ; [Pulse.bot, reprise de Windows Central](https://www.pulse.bot/gaming/news/robloxs-new-reality-mode-shows-how-far-nvidias-dlss-5-ai-upscaling-can-push-a-simple-game-a8b30cd9-d8bd-40cc-b890-a290a9de89ff/) (cet agrégateur se contredit sur les dates : à traiter comme non fiable)

### Inferences
- Pour BLIND SPOT : `LightingStyle = Realistic` et `PrioritizeLightingQuality = true` reproduisent l'ancien Future. Le parking est petit : sacrifier la distance d'affichage au profit de l'éclairage est un bon échange. Ces réglages ne se changent pas par script : le joueur ne peut pas les ajuster dans un menu.
- Sur la plupart des téléphones, la scène doit faire peur **sans ombres dynamiques** (elles sautent sous le niveau 4, et l'éclairage est réduit sur l'entrée de gamme). L'ambiance doit tenir par la position et la couleur des lumières, `Ambient` presque noir sous terre (zone « occluded from the sky »), les zones noires et les émissifs. Les ombres sont un bonus pour les appareils puissants.
- Néons : une SurfaceLight sur la face du tube (cas d'usage officiel « fluorescent panels »), **sans ombres** pour la plupart. Garder les ombres pour quelques sources choisies. La lampe du caméscope ou du joueur en SpotLight étroite (< 120°) est l'ombre la moins chère. Éviter les PointLight avec ombres. Le clignotement se fait par script sur `Brightness` ou `Enabled` (pratique courante, pas de source officielle).
- Béton mouillé et métal : monter `EnvironmentSpecularScale` vers 1 et baisser `Ambient`/`OutdoorAmbient` si on monte `EnvironmentDiffuseScale`. Sous terre, la cubemap vient du Sky : un Sky sombre évite des reflets de ciel bleu sur le béton (déduction, pas de source).
- `ExposureCompensation` entre -5 et 5 sert à « sous-exposer » toute la scène. Réglé en LocalScript, il change seulement le client local (comportement général des services modifiés côté client, non vérifié ici). Il peut donc servir à l'effet caméscope.
- Ne pas planifier BLIND SPOT sur Roblox Reality : pas de date ferme, pas de contrôle développeur connu.

### Gaps
- Aucun chiffre officiel sur le nombre de lumières avec ombres par image, la résolution des shadow maps ou la distance de coupure des ombres locales.
- Pas de tableau officiel « appareil ou niveau de qualité → ce qui est rendu ». Seul fait chiffré : pas d'ombres sous le niveau 4.
- Je n'ai pas trouvé si l'amélioration de l'atténuation des lumières (prévue fin 2025) est sortie.
- Aucun nouveau type de lumière (AreaLight, etc.) trouvé pour 2025-2026.
- Le post officiel d'Unified Lighting (version « Fully Live ») redirigeait vers une page de maintenance le 6 novembre 2026 : lu à travers l'URL de la bêta (/1), qui contient les mises à jour jusqu'au 23 juillet 2025.
- Je n'ai pas lu la doc de Sky (seulement Atmosphere).

## Question 2 : Matériaux (SurfaceAppearance, MaterialService/MaterialVariant, Decals/Textures, changements 2025-2026)

### Takeaway
SurfaceAppearance prend 5 cartes PBR : couleur, normale, rugosité, métal et masque émissif (l'émissif est arrivé fin 2025). Les textures vont jusqu'à **4096 × 4096** dans les jeux publiés depuis le **30 janvier 2026**, grâce au **Texture Streaming** automatique (lancé en décembre 2025, déployé sur toutes les plateformes à partir du 23 mars 2026). Le moteur sert des mips plus petits aux appareils faibles ; la 4K est désactivée sur Android d'entrée de gamme (< 3,5 Go). La mémoire dépend du nombre de pixels, pas du poids du fichier.

### Cited Findings

**SurfaceAppearance**
- « Studio currently supports 5 types of PBR texture maps: color, normal, roughness, metalness, and emissive mask. » « You can add PBR textures to any MeshPart by adding a SurfaceAppearance object. » « you can't modify SurfaceAppearance properties by scripts during a game. » — [Docs, Surface appearance](https://create.roblox.com/docs/art/modeling/surface-appearance)
- `AlphaMode` : Overlay (défaut, laisse voir la couleur de base du maillage là où la carte est transparente), Transparency (découpe), TintMask (teinte sélective selon l'alpha), Opaque (ignore l'alpha ; **en bêta**, à activer dans File > Beta Features). — [Docs, Surface appearance](https://create.roblox.com/docs/art/modeling/surface-appearance)
- `SurfaceAppearance.Color` : « tinting applies as a multiplier », seulement sur la ColorMap. « Tinting does not affect performance and you can save on memory by reusing a single color map with different tints. » — [Docs, Surface appearance](https://create.roblox.com/docs/art/modeling/surface-appearance)
- Cartes normales : « Roblox only supports OpenGL format - Tangent Space normal maps. » — [Docs, Surface appearance](https://create.roblox.com/docs/art/modeling/surface-appearance)
- Transparence : `MeshPart.Transparency` à 0 pour les découpes nettes ; au moins 0,02 pour le semi-transparent (0,01 peut être traité comme opaque). — [Docs, Surface appearance](https://create.roblox.com/docs/art/modeling/surface-appearance)
- Émissif : `EmissiveMaskContent` (gris), `EmissiveTint`, `EmissiveStrength` (0 à 40 pour passer la validation du Marketplace). La carte émissive était annoncée « Late 2025 » à la RDC du 26 septembre 2025. — [Docs, Surface appearance](https://create.roblox.com/docs/art/modeling/surface-appearance) ; [DevForum, Creator Roadmap RDC 2025](https://devforum.roblox.com/t/creator-roadmap-2025-rdc-update/3961527)

**Résolution et formats**
- « Roblox supports up to 4096×4096 pixel texture resolutions (4K). » La section UV de la même page dit encore « up to 1024×1024 », un reste d'avant 2026. Formats : .png, .jpg, .tga, .bmp. Albedo et normale en RGB 24 bits ; rugosité, métal et masque émissif en gris 8 bits. Un seul matériau par maillage, un seul jeu d'UV, UV dans l'espace 0-1. — [Docs, Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)
- Résolutions conseillées : 256² pour un objet de 5 × 5 studs, 512² pour 10 × 10, 1024² pour 20 × 20. « When rendering many textures at the same time, Roblox may downsample textures to optimize for performance. » — [Docs, Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)
- **4K live le 30 janvier 2026** : « 4k Textures are now available in published experiences! » Pour MeshPart (avec ou sans squelette), SurfaceAppearance, Texture, Decal et MaterialVariant. Les textures des matériaux de base de Roblox ne sont pas encore passées en 4K. Un import 8K est ramené à 4K. Pour la 4K dans Studio, il faut le Texture Streaming. — [DevForum, 4k Texture Rendering](https://devforum.roblox.com/t/4k-texture-rendering/4316229)
- **Texture Streaming** (annoncé le **12 décembre 2025** ; mise à jour du **23 mars 2026** : début du déploiement sur toutes les plateformes) : rien à activer. Le moteur charge d'abord une qualité de base, puis monte selon l'importance de l'objet (distance à la caméra, surface à l'écran) et la mémoire de l'appareil. « Harmony » fixe un budget de textures à chaque image. Par niveau d'appareil : Android d'entrée de gamme < 3,5 Go a « 4k textures disabled » ; iOS d'entrée de gamme < 3,5 Go est pris en charge. — [DevForum, Introducing Texture Streaming](https://devforum.roblox.com/t/introducing-texture-streaming/4144855)
- Le Texture Streaming ne couvre pas encore les textures d'UI 2D, celles des SurfaceGui, ParticleEmitter, Terrain, TerrainDetail ni Sky. Atlas : « If one texture in an atlas is required at a certain mip level, the entire atlas will be streamed in at that mip level. » Conseil : « Use near-uniform texel density in your UV-mapped meshes. » — [DevForum, Introducing Texture Streaming](https://devforum.roblox.com/t/introducing-texture-streaming/4144855)

**Mémoire et draw calls**
- « The number of pixels in the texture determines memory usage. » « A 1024x1024 pixel texture consumes four times the graphics memory of a 512x512 texture. » Les images sont converties dans un format fixe : retirer l'alpha ne réduit pas la mémoire. « Unless an image is occupying a large amount of physical space on the screen, it usually needs at most 512x512 pixels. » Utiliser des trim sheets. — [Docs, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Des maillages identiques partagent un draw call si leurs SurfaceAppearance sont identiques. Decals, Textures et particules « don't batch well and introduce additional draw calls ». Importer une map entière d'un coup peut donner des ids différents à des maillages identiques, ce qui empêche l'instanciation. — [Docs, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)

**MaterialService / MaterialVariant**
- `MaterialVariant` (dans `MaterialService`) sert aux matériaux **tuilables** en PBR, alors que SurfaceAppearance sert à un maillage précis avec UV. Réglages **Studs Per Tile** et **Pattern**. « Set as Override » applique un matériau personnalisé à toutes les instances d'un matériau de base, pièces **et terrain**. « Refraction of light through the glass material is not supported on mobile devices due to computational limitations. » — [Docs, Materials](https://create.roblox.com/docs/parts/materials)

### Inferences
- Béton du parking : un MaterialVariant de béton (512 à 1024, tuilable) en override de Concrete couvre sols, murs et piliers à faible coût mémoire. Les objets clés (porte de sortie, bureau de sécurité, caméscope) en SurfaceAppearance avec ColorMap 1024 à 2048. La 4K seulement pour ce que le joueur voit de près, puisque le streaming la retire de toute façon aux appareils faibles.
- Saleté et usure : les Decals coûtent des draw calls. Mieux vaut mettre la saleté dans les textures (trim sheets, cartes de rugosité) et garder les Decals pour quelques taches uniques. La teinte SurfaceAppearance.Color permet de varier une même texture (voitures, portes) sans mémoire en plus.
- Panneaux de sortie de secours et écrans : masque émissif + `EmissiveStrength`, plus une petite SurfaceLight sans ombre.
- Pas de verre réfractant sur téléphone : les vitres du bureau de sécurité doivent rester crédibles sans réfraction.

### Gaps
- Je n'ai pas trouvé les propriétés exactes de MaterialVariant (liste des cartes, valeurs de Pattern) dans la doc consultée.
- Pas de nouveauté 2025-2026 trouvée pour Decal ou Texture, à part le passage à la 4K et le Texture Streaming.
- Pas de budget mémoire chiffré pour les textures sur téléphone, en dehors du seuil de 3,5 Go de l'annonce du Texture Streaming.

## Question 3 : Maillages, LOD, streaming, Editable*, mémoire sur téléphone, part du mobile

### Takeaway
Un maillage est limité à **20 000 triangles**. Le streaming d'instances est activé par défaut. **SLIM** (fin 2025) remplace l'ancien LOD des modèles, mais il exige StreamingEnabled et exclut les modèles animés ou modifiés à l'exécution. Le streaming des maillages est encore annoncé, pas livré (état décembre 2025). Aucun budget mémoire client chiffré n'est publié : le moteur (« Harmony ») s'adapte seul à l'appareil. **80 %** des joueurs quotidiens étaient sur mobile en 2024.

### Cited Findings

**Limites de maillage**
- « Individual meshes can not exceed 20,000 triangles. » Quads de préférence, maillage fermé. Au plus 4 os par sommet. Pas de limite par fichier d'import indiquée. — [Docs, Mesh specifications](https://create.roblox.com/docs/art/modeling/specifications)
- Les scènes avec `RenderFidelity = Precise` sur trop de maillages sont un problème courant. Utiliser `Automatic` ou `Performance` pour que le moteur passe à des versions simplifiées. Frustum culling et occlusion culling sont actifs par défaut. — [Docs, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- « Placing objects with partial transparency near each other forces the engine to render the overlapping pixels multiple times. » — [Docs, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)

**Streaming d'instances**
- `StreamingEnabled` est « enabled by default for new places » et ne se règle pas par script. `StreamingTargetRadius` 1024 et `StreamingMinRadius` 64 par défaut. `StreamOutBehavior` vaut `LowMemory` par défaut ; `Opportunistic` est conseillé pour libérer la mémoire plus vite et éviter les crashs par manque de mémoire. `ModelStreamingMode` : Nonatomic (défaut), Atomic, Persistent, PersistentPerPlayer. Côté client : attendre `Workspace.PersistentLoaded` pour les modèles Persistent, et faire `WaitForChild()` sur le modèle Atomic lui-même. — [Docs, Instance streaming](https://create.roblox.com/docs/workspace/streaming)
- « Games can be played on devices with less memory since content is dynamically streamed in and out. » Le streaming se fait selon la distance en 3D : les grands mondes en profitent le plus. — [Docs, Instance streaming](https://create.roblox.com/docs/workspace/streaming) ; [Docs, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)

**SLIM et mise à l'échelle automatique**
- Feuille de route du 26 septembre 2025 : SLIM « automatically composites your models and renders different LoDs for them », remplace Model Level of Detail, lancement « by the end of the year », d'abord pour les jeux avec streaming. — [DevForum, Creator Roadmap RDC 2025](https://devforum.roblox.com/t/creator-roadmap-2025-rdc-update/3961527) ; annonce dans le newsroom en décembre 2025, d'après l'URL ([Roblox Newsroom, 2025/12](https://about.roblox.com/fr/newsroom/2025/12/introducing-roblox-slim-scalable-lightweight-interactive-models) : page non lue)
- Doc SLIM : il faut StreamingEnabled, une place publiée (pas un .rbxl local) et Team Create. Il s'active par `Model.LevelOfDetail = SLIM` ; `Workspace.EnableSLIMAvatars` pour les avatars. « Composite meshes dramatically reduce draw calls, triangle counts, and memory usage. » Limites : pas de modèles modifiés à l'exécution, pas de modèles qui jouent des animations, pas de Humanoid ; avatars R15 seulement. — [Docs, SLIM](https://create.roblox.com/docs/workspace/streaming/slim)
- GamesBeat (article non daté, contexte RDC 2025) : « Harmony » « monitors each user's available resources every frame » (mémoire, GPU, CPU, réseau). Exemple de composition : une voiture de 112 maillages et 24 textures ramenée à 1 maillage et 4 textures. — [GamesBeat](https://gamesbeat.com/roblox-launches-scalable-graphics-for-rendering-more-realistic-and-detailed-worlds-exclusive/)
- Streaming des maillages : « we plan to bring the same improvements to meshes as well », avec un nouvel algorithme de simplification LOD (annonce du 12 décembre 2025). — [DevForum, Introducing Texture Streaming](https://devforum.roblox.com/t/introducing-texture-streaming/4144855)

**EditableMesh / EditableImage**
- EditableImage : « The maximum size is 1024×1024 ». « Editable assets are currently expensive for memory usage ». Les clients ont des « strict client-side memory budgets ». Dans un jeu publié, l'usage « fails by default » : il faut activer **Enable Mesh / Image APIs**. Utilisable dans toute propriété Content d'image (`ImageLabel.ImageContent`, `MeshPart.TextureContent`). « Only a single `EditableImage` can be updated per frame on the display side. » Page mise à jour le 5 novembre 2026. — [Docs API, EditableImage](https://create.roblox.com/docs/reference/engine/classes/EditableImage)
- `AssetService:CreateDataModelContentAsync` (bêta Studio le **27 mars 2026**, disponible dans les jeux publiés le **18 mai 2026**) : convertit des données Editable en contenu statique qui « do[es] not use up Editable* memory budgets » et est « paged to disk ». Contenu créé par le serveur limité à 200 Mo ; réplication du serveur vers le client seulement ; durée limitée à la session. — [DevForum, CreateDataModelContent](https://devforum.roblox.com/t/full-release-introducing-createdatamodelcontent-convert-editable-mesh-and-image-data-into-static-content/4541898)

**Mémoire et part du mobile**
- Aucun budget mémoire client fixe dans la doc. La mémoire haute n'est pas un problème en soi, mais il faut enquêter si le taux de crash dépasse 2-3 %. Serveur : rester sous 50 %, avec un total de 6,25 Gio + 100 Mio × joueurs connectés. — [Docs, Identify performance issues](https://create.roblox.com/docs/performance-optimization/identify)
- **80 %** des 82,9 millions d'utilisateurs actifs quotidiens jouaient sur mobile en **2024** (rapport annuel de Roblox, article du 23 avril 2025). 46 % des revenus Robux passaient par l'App Store (30 %) et Google Play (16 %). — [PocketGamer.biz](https://www.pocketgamer.biz/80-of-roblox-users-are-on-mobile-contributing-46-of-robux-revenue)

### Inferences
- Découper le parking en modules (travée de piliers, rampe, bureau, couloir) de moins de 20 000 triangles chacun, réutilisés à l'identique : même maillage + même SurfaceAppearance = instanciation, donc moins de draw calls (voitures, néons, piliers). Importer les modules un par un, pas toute la map d'un coup.
- Garder StreamingEnabled (exigé par SLIM). Mais la co-op dans un espace fermé et la peur des choses qui « apparaissent » demandent d'être prudent : un monstre ou une porte scriptée doivent être Atomic ou Persistent pour ne pas disparaître en plein moment clé. SLIM convient au décor statique, pas aux portes animées, aux néons scriptés ni aux PNJ.
- Le parking est petit et fermé : le culling par occlusion et des murs pleins entre les zones économisent plus que le LOD. RenderFidelity Automatic partout sauf sur les objets tenus en main.
- Avec 80 % de joueurs sur mobile (2024), la cible téléphone d'abord est justifiée. Les écrans de 844 × 390 sont la norme, pas l'exception.

### Gaps
- Pas de limite officielle par import (fichier FBX entier) trouvée.
- Le streaming des maillages n'était pas livré en décembre 2025 ; je n'ai pas trouvé de date de sortie ensuite.
- La date exacte de sortie de SLIM n'est pas vérifiée (newsroom de décembre 2025 non lu) ; la doc ne donne pas de statut.
- Je n'ai pas trouvé de chiffre officiel sur la part mobile pour 2025 ou 2026 (seulement 2024).
- Pas de budget mémoire par appareil publié : le seul chiffre est le seuil de 3,5 Go de RAM utilisé pour classer les appareils d'entrée de gamme dans l'annonce du Texture Streaming.
- La façon dont Roblox choisit le niveau de qualité graphique automatique (algorithme, niveaux 1 à 10 ou 1 à 21) n'est pas documentée dans les pages lues.

## Question 4 : Post-traitement et effets simulés (grain, VHS, aberration chromatique, vision nocturne)

### Takeaway
Six effets intégrés : Bloom, Blur, ColorCorrection, DepthOfField, SunRays et ColorGrading (choix du tonemapper). Placés dans `Lighting`, ils touchent tout le monde ; placés dans la `Camera`, un seul joueur, ce qui est idéal pour la vision infrarouge par joueur. Je n'ai trouvé aucune API de shader personnalisé. Grain, VHS et distorsion se simulent avec des superpositions d'UI ou des objets 3D devant la caméra.

### Cited Findings
- Effets intégrés : BloomEffect, BlurEffect (flou gaussien de toute la vue 3D), ColorCorrectionEffect (`Brightness`, `Contrast`, `Saturation`, `TintColor`), DepthOfFieldEffect, SunRaysEffect, ColorGradingEffect (`TonemapperPreset` : Default, ou Retro qui imite l'avant-2019). — [Docs, Post-processing effects](https://create.roblox.com/docs/environment/post-processing-effects)
- « When you add post-processing effects to the `Class.Lighting` service, they display to **all players** ». Dans `Camera`, « they only display to a **specific player** ». Certains effets n'apparaissent pas dans Studio si **Editor Quality Level** n'est pas au maximum. La page ne dit rien des téléphones ni de la qualité basse. — [Docs, Post-processing effects](https://create.roblox.com/docs/environment/post-processing-effects)
- Le staff a déjà refusé une fonction de rendu (SurfaceProjection) à cause de son coût et du support des textures de profondeur en OpenGL ES 3.0 : « We aren't going to be able to release this feature as of right now. » (citation rapportée par un utilisateur, 2023) — [DevForum, Future Lighting needs to expose more internal properties](https://devforum.roblox.com/t/future-lighting-needs-to-expose-more-internal-hardcoded-properties-for-light-instances/2580333)
- VHS par la communauté (**23 septembre 2024**) : distorsion en barillet obtenue par une sphère en verre (transparence 0,5) devant la caméra, plus un asset VHS acheté. Limites signalées par les utilisateurs : ne marche qu'aux niveaux graphiques élevés ; bords visibles au-dessus de 60 de champ de vision ; particules et pièces transparentes invisibles à travers le verre ; les lumières donnent des reflets bizarres. — [DevForum, I made a realistic VHS effect](https://devforum.roblox.com/t/i-made-a-realistic-vhs-effect/3169359)
- Le verre ne réfracte pas sur mobile (« not supported on mobile devices »). La sphère de verre ne déforme donc pas l'image sur téléphone. — [Docs, Materials](https://create.roblox.com/docs/parts/materials)

### Inferences
- Absence de shaders personnalisés : déduite (la doc ne liste que 6 effets fixes ; aucune API de shader trouvée dans la doc ni dans la feuille de route 2025). Pas de déclaration officielle explicite trouvée.
- Vision infrarouge du caméscope, entièrement côté client : une ColorCorrectionEffect dans `workspace.CurrentCamera` (Saturation -1 puis TintColor verdâtre ou blanc, Contrast et Brightness élevés), un Bloom fort pour les sources IR, `ExposureCompensation` relevé en local, et une lumière locale non visible des autres (PointLight ou SpotLight créée côté client sans ombres) pour l'« illuminateur IR ». Le tout se coupe quand le caméscope est baissé.
- Grain, lignes de balayage, aberration chromatique et vignettage : ImageLabel plein écran avec des textures de bruit animées (changer `ImageRectOffset` ou l'image chaque image) et un cadre d'interface caméscope (REC, batterie, horodatage). La vraie aberration chromatique (décalage RVB de l'image 3D) est impossible sans shader : on la simule seulement sur les bords par une texture. La distorsion par sphère de verre est à exclure sur téléphone (pas de réfraction sur mobile).
- Coût : chaque ImageLabel plein écran semi-transparent ajoute du remplissage de pixels ; limiter à 1 ou 2 couches sur téléphone (déduction du conseil officiel sur la transparence superposée).

### Gaps
- Je n'ai trouvé aucune source officielle sur le coût des effets de post-traitement sur téléphone, ni sur leur désactivation aux bas niveaux de qualité.
- Pas de déclaration officielle explicite « pas de shaders personnalisés » trouvée (c'est déduit).
- Pas de guide de vision nocturne publié trouvé : la recette ci-dessus est une déduction, à prototyper.

## Question 5 : Flux de caméras de surveillance (moniteurs du bureau et écran du caméscope)

### Takeaway
Il n'existe pas de rendu vers texture ni de capture de caméra vers un écran (aucune annonce trouvée jusqu'à novembre 2026). Le seul moyen d'avoir un « direct » est un **ViewportFrame** dans un SurfaceGui, qui re-rend des **copies** d'objets avec un éclairage fixe : pas d'ombres, pas de post-traitement, Neon et Glass au plus bas, lumières de la scène ignorées. Les autres options : basculer la caméra du joueur sur le point de vue de la caméra de surveillance (CameraType Scriptable), ou afficher des images fixes.

### Cited Findings
- « A ViewportFrame uses a camera to render 3D objects into a 2D viewport. » Pour garder un objet visible dans le jeu, il faut le dupliquer dans le ViewportFrame. « When you want to update the view of your ViewportFrame, be sure to update the camera, not the objects within the view. » Éclairage propre au cadre : `Ambient`, `LightDirection`, `LightColor`. `ImageColor3` teinte l'image. — [Docs, ViewportFrames](https://create.roblox.com/docs/ui/viewport-frames)
- Doc API : « No shadows or post-processing effects are rendered. » « Material.Neon and Material.Glass materials render at the lowest quality. » « Nested GuiObjects aren't supported. » L'éclairage agit comme si EnvironmentSpecularScale et EnvironmentDiffuseScale valaient 0, donc les MetalnessMap peuvent avoir un autre rendu. La caméra ne se réplique pas. — [Docs API, ViewportFrame](https://create.roblox.com/docs/reference/engine/classes/ViewportFrame)
- Sortie (**30 novembre 2018**) : « Objects inside ViewportFrames are rendered using a fixed lighting setting. » Un utilisateur : « Updating ViewportFrame is more expensive and requires switching render targets. » Observation communautaire de 2018 (non vérifiée aujourd'hui) : la vue de la caméra du cadre « is capped to 1024x1024 », et au-delà l'image est étirée. — [DevForum, ViewportFrame Release](https://devforum.roblox.com/t/viewportframe-release/206476)
- Exemple communautaire récent (**10 juillet 2026**), « Security Camera System » : « creates physical Live CCTV camera feeds using ViewportFrames ». Les écrans sont des SurfaceGui côté client, les objets affichables sont clonés ou étiquetés. « Each player renders CCTV feeds locally. » « Distant displays consume no rendering cost. » Plafond `MaxActiveScreensPerPlayer`. Avec StreamingEnabled, « distant player characters may not exist on the client » : il faut des miroirs côté serveur. Problèmes de vêtements et d'accessoires, corrigés le 14 juillet selon l'auteur. — [DevForum, Security Camera System](https://devforum.roblox.com/t/security-camera-system/4729091)
- Le Texture Streaming ne couvre pas les textures de SurfaceGui (état décembre 2025). — [DevForum, Introducing Texture Streaming](https://devforum.roblox.com/t/introducing-texture-streaming/4144855)
- Caméra scriptée : `CameraType = Scriptable` « gives you full control of the camera ». Se place par `Camera.CFrame` ; `Focus` est à mettre à jour chaque image pour que le niveau de détail soit juste. `FieldOfView` de 1 à 120, 70 par défaut. — [Docs, Camera](https://create.roblox.com/docs/workspace/camera)
- La feuille de route RDC (26 septembre 2025) ne mentionne pas de rendu vers texture. — [DevForum, Creator Roadmap RDC 2025](https://devforum.roblox.com/t/creator-roadmap-2025-rdc-update/3961527)

### Inferences
- Mur de moniteurs : des ViewportFrames dans des SurfaceGui, avec 1 ou 2 flux actifs à la fois (les autres figés ou en neige), mis à jour à basse fréquence (10 à 15 im/s, effet « caméra de surveillance » naturel), une géométrie simplifiée et clonée seulement dans le champ de la caméra, `ImageColor3` gris-vert et une superposition de lignes de balayage. L'éclairage plat du ViewportFrame est cohérent avec l'esthétique d'une vieille caméra de sécurité, mais il ne montrera pas l'obscurité réelle : il faut la simuler (Ambient et LightColor bas, objets plus sombres).
- Le monstre « vu seulement sur les écrans » (idée de jeu) est faisable : un modèle placé uniquement dans le ViewportFrame n'existe pas dans le monde. C'est même plus simple qu'un vrai rendu vers texture.
- Moment clé « regarder une caméra » : basculer la caméra du joueur en Scriptable sur le point de vue de la caméra de surveillance, plein écran, avec le vrai éclairage, les ombres et le post-traitement. C'est l'approche la plus belle sur téléphone. Le joueur est alors aveugle sur son corps : bon ressort de peur en co-op.
- Écran du caméscope : il montre ce que voit le joueur. Donc **pas de ViewportFrame** : un cadre d'UI autour de la vraie vue, plus la ColorCorrection propre à la caméra (Question 4). Un ViewportFrame plein écran coûterait un second rendu sans ombres ni post-traitement.
- Attention au piège de Break a Gem (CLAUDE.md local, octobre 2026) : `execute_luau` du MCP remet le type de caméra pendant un appel. Tester les bascules Scriptable hors des appels en attente. — [CLAUDE.md de Break a Gem](https://github.com/AMoncade/BreakAGem/blob/main/CLAUDE.md)

### Gaps
- Aucune mesure officielle du coût d'un ViewportFrame mis à jour chaque image sur téléphone, ni de plafond de résolution actuel (la limite de 1024 vient d'une observation de 2018).
- Je n'ai pas vérifié si un ViewportFrame rend le Terrain ou les ParticleEmitter (la doc lue ne le dit pas ; l'exemple de juillet 2026 exclut le Terrain du clonage).
- Aucune API de capture d'écran vers texture trouvée (CaptureService sert aux captures d'écran du joueur, non vérifié pour cet usage).

## Question 6 : Première personne (LockFirstPerson, corps visible, viewmodel, balancement, contrôles tactiles)

### Takeaway
`CameraMode = LockFirstPerson` cache tout le personnage sauf les Tools équipés. Pour montrer le corps, on remet `LocalTransparencyModifier` à 0 côté client. Il n'y a pas de doc officielle de viewmodel ni de balancement de tête : ce sont des techniques communautaires (modèle collé à la caméra, décalage de `CFrame` chaque image).

### Cited Findings
- LockFirstPerson : « all parts/elements of the player's character are invisible to them, except for equipped » Tools. Pour bloquer le zoom, mettre `CameraMinZoomDistance` et `CameraMaxZoomDistance` à la même valeur (l'exemple de la page a ces deux valeurs inversées, 25 et 50). — [Docs, Camera](https://create.roblox.com/docs/workspace/camera)
- `LocalTransparencyModifier` : visible seulement par le client local, ne se réplique pas, multiplie la transparence selon 1 − (1 − Transparency) × (1 − LocalTransparencyModifier). La doc cite l'exemple d'un joueur qui ne voit pas son corps en première personne. — [Docs API, BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart)
- Mobile : `DevTouchCameraMovementMode` est un réglage à part pour les écrans tactiles. `CameraToggle` « Only functional on computers (not phones/tablets) ». — [Docs, Camera](https://create.roblox.com/docs/workspace/camera)
- Leçons internes de Break a Gem (octobre 2026) : l'avatar d'Adrien utilise les nouvelles articulations (`AnimationConstraint`, aucun `Motor6D`), il faut chercher les deux. Une pose posée par-dessus une animation s'écrit dans `RunService.PreSimulation` ; écrite dans RenderStepped, elle ne se voit pas. Un déplacement côté client met jusqu'à 1 s à atteindre le serveur. — [CLAUDE.md de Break a Gem](https://github.com/AMoncade/BreakAGem/blob/main/CLAUDE.md)

### Inferences
- Caméscope tenu : un viewmodel client (bras + caméscope) collé à `CurrentCamera.CFrame` à chaque image, au lieu d'un Tool visible par LockFirstPerson. On contrôle mieux la position, le balancement et le recul. Le modèle ne doit pas projeter d'ombres (CastShadow à false) pour éviter des ombres flottantes.
- Corps visible (pieds quand on regarde en bas) : remettre `LocalTransparencyModifier = 0` chaque image sur les jambes et le torse, la tête cachée, avec un petit décalage de caméra vers l'avant. Tenir compte des articulations AnimationConstraint.
- Balancement de tête : décalage sinusoïdal de `Humanoid.CameraOffset` ou de la CFrame de caméra, avec une option pour le couper (confort sur téléphone, mal des transports).
- Téléphone : le joystick dynamique à gauche et le glisser à droite pour tourner la vue suffisent. Les actions (lever le caméscope, IR, lampe, interagir) en boutons de 44 px ou plus. Tester à 844 × 390 que l'interface caméscope ne cache pas les boutons tactiles.

### Gaps
- Aucune doc officielle trouvée sur les viewmodels, le balancement de tête ou les contrôles tactiles propres à la première personne. Les recettes ci-dessus sont des déductions et la pratique courante, non vérifiées par une source dans ces notes.

## Question 7 : Outils de profilage et budgets conseillés

### Takeaway
MicroProfiler (Ctrl+Alt+F6), Render Stats (Shift+F2) pour les draw calls, Developer Console (F9) pour la mémoire par catégorie, et le Performance Dashboard du Creator Dashboard pour les vraies données (mémoire, images par seconde, crashs). Le **Device Simulator** de Studio simule l'écran, la densité de pixels et le tactile, **pas** la puissance d'un téléphone. Budget officiel : 16,67 ms par image (60 im/s). Pas de budget mémoire client chiffré.

### Cited Findings
- MicroProfiler : outil qui « breaks down how much computational time is spent on tasks each frame », côté client ou serveur, raccourci Ctrl+Alt+F6 (⌘⌥F6 sur Mac). « check the graph to see if the frame takes longer than 16.67 ms. » — [Docs, Identify performance issues](https://create.roblox.com/docs/performance-optimization/identify)
- Scopes de rendu : « Prepare and Perform », « LightGridCPU », « ShadowMapSystem », « Perform/Scene/RenderView ». Draw calls : **Render Stats** ⟩ **Timing** dans Studio, ou Shift+F2 dans le client. — [Docs, Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Developer Console (F9), onglet Memory, catégorie PlaceMemory : GraphicsMeshParts, GraphicsTexture, Sounds. « Use the client rather than Studio to get the most accurate readouts. » « Performance stats in Studio are skewed by the Studio application. » — [Docs, Identify performance issues](https://create.roblox.com/docs/performance-optimization/identify)
- Images par seconde du client plafonnées à 60 par défaut (240 possible sur Windows). Performance Dashboard : mémoire client et serveur, images par seconde, heartbeat du serveur, taux de crash. Enquêter si les crashs dépassent 2-3 %. — [Docs, Identify performance issues](https://create.roblox.com/docs/performance-optimization/identify)
- **Device Simulator** : aperçu « including its screen dimensions, pixel density, on-screen keyboard, and touch input ». `StudioDeviceSimulatorService` peut « override resolution and DPI, control orientation and scaling, and create custom device profiles that persist to disk ». La page ne dit rien de la simulation du GPU, de la mémoire ou de la qualité graphique. — [Docs, Testing modes](https://create.roblox.com/docs/studio/testing-modes)
- À comparer : le CLAUDE.md de Break a Gem (octobre 2026) notait que `StudioDeviceEmulatorService` était nil et que l'émulateur « n'est pas pilotable » (contournement : redimensionner la fenêtre de Studio, 1046 × 899 pour une vue de 844 × 390). — [CLAUDE.md de Break a Gem](https://github.com/AMoncade/BreakAGem/blob/main/CLAUDE.md)

### Inferences
- Le nouveau `StudioDeviceSimulatorService` (nom différent de celui testé dans Break a Gem) pourrait remplacer le redimensionnement de fenêtre pour tester à 844 × 390 : à vérifier dans Studio avant de l'écrire dans le plan.
- Ce que le simulateur ne mesure pas (images par seconde, mémoire, ombres coupées) doit se tester sur un vrai téléphone d'entrée de gamme (Android < 3,5 Go de RAM, le seuil de Roblox) avec F9 et le MicroProfiler du client, puis sur le Performance Dashboard après publication.
- Budgets de travail proposés pour le plan (déduits, pas officiels) : 16,67 ms par image sur un téléphone de milieu de gamme ; GraphicsTexture et GraphicsMeshParts suivis à chaque chapitre ; peu de lumières avec ombres visibles à la fois ; pas de ParticleEmitter ni de couches transparentes en grand nombre ; taux de crash sous 2 %.

### Gaps
- Je n'ai pas trouvé de budget officiel de draw calls, de triangles à l'écran ou de mémoire client pour les téléphones.
- Je n'ai pas trouvé de doc sur le profilage directement sur l'appareil mobile (MicroProfiler distant) dans les pages lues.
- La date d'arrivée de `StudioDeviceSimulatorService` n'est pas connue. Son existence est attestée par la doc consultée en novembre 2026, mais pas testée.
