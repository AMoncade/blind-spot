# Asymmetric (1 vs survivors) and round-based survival horror on Roblox, plus games built on light/blackout cycles: the landscape BLIND SPOT would enter

Read date for every live figure: **Wednesday, November 4, 2026**, US school hours (afternoon UTC; the exact minute wasn't logged). Weekday daytime counts are well below evening and weekend peaks, so treat them as a floor.

How the data was gathered, and its limits:
- "Playing", visits, created/updated and maxPlayers come from the official games API (`games.roblox.com/v1/games?universeIds=…`), unless stated otherwise. Up/down votes come from Roblox omni-search (`apis.roblox.com/search-api/omni-search`) or the votes API.
- **Omni-search player counts are sometimes stale.** For the same game they can disagree with the games API: Doors showed 72,353 in omni-search against 25,053 in the API, and Piggy 28,561 against 11,700. One omni-search result for Forsaken still had the summer title "[WEEK 2 ⛱️]" and older vote totals. When the two disagree, I report the API figure and give the other.
- **Forsaken's sources conflict.** The games API returned 52,757 playing under the title "[✨BONUS] Forsaken". Omni-search (three separate queries) gave 27,440–27,445 and rotrends gave 27,361. I report about 27.4K, with 52.8K as an unexplained outlier.
- Like ratio = up / (up + down), computed from the vote totals cited.
- Individual developers' usernames are left out on purpose. Only groups and studios are named.

---

## Q1. The leading asymmetric horror games on Roblox now: players, votes, what survivors and killers do

### Takeaway
The asymmetric field is led by **Violence District** (about 43K playing, a Dead by Daylight-style 5v1), **Forsaken** (about 27K, generators plus a timer, peak 1.2M), **Flee the Facility** (about 20K, the 2017 veteran) and **Piggy** (about 12K). **Survive the Killer** (about 3.6K) and **Die of Death** (about 1.4K) form the middle tier. **Bite By Night**, the big breakout of 2026 (peak 350,238 on April 7, 2026), is **offline for maintenance with 0 players**. Every leader runs the same loop: survivors repair or hack objectives to open an exit, or outlast a timer, while one killer hunts. None uses light, cameras or "being seen" as the core rule. **Murder Mystery 2** (about 253K) is the dominant social-deduction round format.

### Cited Findings

**Violence District** (universe 6739698191, group VIOLENCE DISTRICT)
- Read Nov 4, 2026 as "[WEEK 2 🎃 x BUTCHER] Violence District": 43,094 playing, 1,682,546,821 visits, maxPlayers 6, created 2024-10-31, updated 2026-11-04 — [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624)
- Votes 817,324 up / 61,949 down (93.0%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Pillar%20Chase%202&sessionId=1&pageType=all)
- Rotrends lists 43,975 CCU, a 277.7K peak, 1.7B visits, a 7-day average of 57,563 (down 11.1%), an average session of 16.9 min and a global rank of #20. It files the game as "Survival / 1 vs All" — [rotrends](https://www.rotrends.com/game/6739698191/violence-district)
- Mechanic per its description: five survivors against one killer. Survivors complete objectives to escape and use limited pallets to stun the killer. The game is labeled alpha — [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624)
- The killer is picked at random each match. Survivors open an escape route through objectives such as repairing generators. Matches last up to 15 minutes, and survivors win if any are alive when time runs out — [Sportskeeda](https://widgets.sportskeeda.com/roblox-news/violence-district-a-beginner-s-guide)
- Roblox removed the game on Sept 1, 2025 after an automated system flagged a blood decal. It had averaged about 20,000 CCU after its late-May release — [Destructoid](https://www.destructoid.com/bizarre-reason-behind-robloxs-takedown-of-violence-district/)

**Forsaken** (universe 6331902150, rootPlace 18687417158, group Forsaken Dev Team)
- Players: about 27.4K (omni-search 27,440 and rotrends 27,361). The games API reading of 52,757 under "[✨BONUS] Forsaken" conflicts and is unexplained — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Bite%20by%20Night&sessionId=1&pageType=all); [rotrends](https://www.rotrends.com/game/6331902150/forsaken); [games API](https://games.roblox.com/v1/games?universeIds=6331902150)
- Votes 2,420,857 up / 446,658 down (84.4%, the lowest ratio among the leaders) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Bite%20by%20Night&sessionId=1&pageType=all)
- Visits 5,767,332,440, maxPlayers 9, created 2024-07-28, last updated 2026-10-02. The description says it won "RIA 2025 Best Survival Experience" and that the game is "IN ALPHA" — [games API](https://games.roblox.com/v1/games?universeIds=6331902150)
- Rotrends: peak CCU 1.2M (no date given), 7-day average CCU 37,660 (down 13.6%), average session 16.7 min, global rank #35 — [rotrends](https://www.rotrends.com/game/6331902150/forsaken)
- Mechanic: survivors protect teammates, complete objectives and survive until the timer reaches zero, and the killer must eliminate everyone — [games API description](https://games.roblox.com/v1/games?universeIds=6331902150). Survivors repair generators through skill checks, and "Failing a skill check alerts the Killer". Once "all required generators are repaired" the exit gates power up. The killer tracks "through sound and sight cues", and a Malice Meter charges its power — [BlueStacks guide](https://www.bluestacks.com/blog/game-guides/roblox/rl-forsaken-beginners-guide-en.html)
- Rowatcher credits its success to Dead by Daylight-style asymmetry plus nostalgia for Roblox's own history (survivors and killers drawn from platform figures and myths) — [Rowatcher](https://rowatcher.com/news/the-golden-age-of-roblox-horror-how-three-games-are-redefining-survival-on-the-platform)

**Flee the Facility** (universe 372226183, rootPlace 893973440, group A.W. Apps)
- 20,086 playing, 6,137,549,033 visits, maxPlayers 5, created 2017-07-01, updated 2026-11-03 — [games API](https://games.roblox.com/v1/games?universeIds=372226183,1489026993)
- Votes 2,825,236 / 242,517 (92.1%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=flee%20facility&sessionId=2&pageType=all)
- Mechanic: one Beast against survivors. Survivors hack computers "scattered around the map", and "Once you've hacked them all, the Exit Doors will swing wide open". The Beast knocks survivors out and puts them in Freeze Pods, and teammates can free them — [Sportskeeda](https://www.sportskeeda.com/roblox-news/how-to-play-roblox-flee-the-facility)

**Piggy** (universe 1516533665, rootPlace 4623386862, group Piggy Dev Team)
- 11,700 playing as "Piggy [X2 SEASON XP]" (omni-search showed 28,561, likely stale). 14,451,431,278 visits, maxPlayers 6, created 2020-01-23, updated 2026-11-03 — [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624)
- Votes 4,042,976 / 433,873 (90.3%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Piggy&sessionId=1&pageType=all)
- Mechanic per the description: escape Piggy, with item pickup and use, and crouching or placing traps. Objectives aren't detailed — [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624)

**Survive the Killer!** (universe 1489026993, rootPlace 4580204640, group Slyce Entertainment)
- 3,559 playing, 2,709,696,271 visits, maxPlayers 13, created 2020-01-06, updated 2026-11-03 — [games API](https://games.roblox.com/v1/games?universeIds=372226183,1489026993)
- Votes 1,031,242 / 111,249 (90.3%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Survive%20the%20Killer&sessionId=1&pageType=all)
- Mechanic: survivors hide, rescue teammates and escape together before time runs out, and the killer eliminates as many as possible — [games API](https://games.roblox.com/v1/games?universeIds=372226183,1489026993)

**Die of Death** (universe 7344582593, group Die of Deathians)
- 1,414 playing, 345,023,475 visits, maxPlayers 9, created 2025-03-08, updated 2026-11-03 — [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624)
- Votes 380,011 / 55,607 (87.2%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Die%20of%20Death&sessionId=1&pageType=all)
- Mechanic: a lighter, random-heavy asymmetric game. Game modes roll between matches, and survivors pick from random ability decks — [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624)

**Pillar Chase** (current live universe 9515324315, group "TBN : Pillar Chase 2")
- As "[HALLOWEEN PT2!] Pillar Chase": 151 playing, 12,117,594 visits, maxPlayers 12, created 2026-01-06, updated 2026-11-04 — [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624)
- Votes 26,459 / 8,681 (75.3%, the lowest in the asymmetric set) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Pillar%20Chase%202&sessionId=1&pageType=all)
- Mechanic: one or two monsters against survivors. Survivors do tasks and escape — [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624)

**Bite By Night** (universe 8202280624, rootPlace 70845479499574, group "totally not secret games"). The 2026 breakout, now offline.
- Read Nov 4 as "[🛠️MAINTENANCE] Bite By Night": **0 playing**, 342,840,603 visits, maxPlayers 9, created 2025-07-19, last updated 2026-09-18 — [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624)
- Votes 703,508 / 60,286 (92.1%) — [votes API](https://games.roblox.com/v1/games/votes?universeIds=66654135,8202280624)
- All-time peak 350,238 CCU on April 7, 2026. The maintenance covers backend work including a payment system, with no confirmed reopening (article updated Sept 10, 2026) — [AllThings.How](https://allthings.how/bite-by-night-maintenance-update-what-developer-saivv-confirmed/)
- Mechanic: "a 1v4 asymmetrical horror game" with an animatronic theme. Survivors pick a class (Customer, Fighter, Healer, Security Guard at launch), complete objectives and "power generators to open the exit", and can barricade doors. The killer must eliminate everyone before the clock reaches 6:00 AM and grows more aggressive as 6 AM nears — [fan wiki, How to Play](https://bite-by-night-wiki.pages.dev/how-to-play). Another source lists maps (Pizzeria, Warehouse, The Forest), objective progress such as "3/6" generators, and a Technician class — [AllThings.How](https://allthings.how/bite-by-night-maintenance-update-what-developer-saivv-confirmed/)

**Murder Mystery 2** (universe 66654135). The format benchmark, not asymmetric horror.
- 253,175 playing, 32,077,247,836 visits, maxPlayers 12, created 2014-01-18, updated 2026-11-04 — [games API](https://games.roblox.com/v1/games?universeIds=66654135,2440500124,1000233041,4367208330,10665420648)
- Votes 10,897,539 / 1,103,755 (90.8%) — [votes API](https://games.roblox.com/v1/games/votes?universeIds=66654135,8202280624)
- Mechanic: innocents hide and deduce, one sheriff holds the only gun, and the murderer must kill everyone without being shot. Collecting and trading knives is a major layer — [games API](https://games.roblox.com/v1/games?universeIds=66654135,2440500124,1000233041,4367208330,10665420648)

**Other asymmetric or near-asymmetric titles found in search** (mechanics unverified unless noted)
- "SPOOK BY FATE": 166 playing, 36,951 / 5,051 (88.0%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Doom%20by%20Fate&sessionId=9&pageType=all). A fan page calls "Doom by Fate" an "Asymmetrical Roblox Phenomenon" — [pages.dev](https://doom-by-fate-wiki.pages.dev/). The link between the two titles is unverified.
- Forsaken-likes in the long tail: Codename: Redux (about 227–627 playing), FPE:Blight (about 455–1,203), Eternal Destination, Damnation [INDEV] (426), Swapsaken (180). All are small — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Forsaken&sessionId=1&pageType=all); [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Doom%20by%20Fate&sessionId=9&pageType=all)

### Inferences
- The standard Roblox asymmetric loop is a copy of Dead by Daylight: generators or computers, then an exit gate, against one killer, often with a survival timer. A newcomer competes on characters and killers as collectible content, not on the core rule.
- The leading games' server sizes (maxPlayers 5–13: FTF 5, Piggy 6, VD 6, Forsaken 9, BBN 9, STK 13) bracket BLIND SPOT's 4–8 players.
- Average sessions of about 16.7–16.9 min (Forsaken, VD) mean players stay for roughly 3 rounds of BLIND SPOT's 5-minute length (my extrapolation).

### Gaps
- Forsaken's exact current CCU (27K vs 53K conflict). The exact round timer and generator count for Forsaken and Bite By Night weren't confirmed in the fetched sources.
- The original "Pillar Chase 2" universe (before the 2026 TBN re-release) wasn't checked. Its status is unverified.
- The status and player count of "Doom by Fate" are unverified.
- No YouTube sources were checked.

---

## Q2. Does any existing game already have BLIND SPOT's pieces?

### Takeaway
**No game found combines the pieces.** In particular, I found no game where *being inside a camera's field of view keeps you safe*, and no asymmetric PvP where the killer cuts cameras or power while survivors repair them. Each piece exists on its own:
- **Survivors repairing:** the generators or computers of every asymmetric leader.
- **Monster-linked blackouts:** Dandy's World's Blackout event, which one enemy, Twisted Brightney, can trigger.
- **Light as protection:** 99 Nights in the Forest's campfire safe zone and flashlight stun, plus small games like Lights Out and Stay In The Light.
- **Flicker as warning:** Doors and Pressure.
- **Cameras as a tool:** Keep the Door Locked and Anomaly Detected.
- **Cameras as the threat, the inverse of BLIND SPOT:** Hide from Camera or Die!, plus Squid Game "Red Light, Green Light", where being seen moving eliminates you.
- **Dead players doing something:** only spectating and "harassing" (Hide from Camera or Die!) or paid revives (Pressure). None found where dead players help the living through a camera.

### Cited Findings

**The killer cuts power, lights or cameras**
- Forsaken: the guides mention generators powering exit gates but no light, power-cut or camera mechanic — [BlueStacks](https://www.bluestacks.com/blog/game-guides/roblox/rl-forsaken-beginners-guide-en.html); [Designbeep, Aug 10, 2026](https://designbeep.com/2026/08/10/forsaken-roblox/)
- Violence District: no light, power or camera mechanic in the guide fetched — [Sportskeeda](https://widgets.sportskeeda.com/roblox-news/violence-district-a-beginner-s-guide)
- Bite By Night: none of the sources fetched mentions batteries, cameras, lights or power, despite the FNAF theme and a "Security Guard" class — [fan wiki](https://bite-by-night-wiki.pages.dev/how-to-play); [AllThings.How](https://allthings.how/bite-by-night-maintenance-update-what-developer-saivv-confirmed/)
- Closest PvE analog: in Dandy's World a Blackout means the power goes out, "plunging the floor into complete darkness". Twisted Brightney (an enemy) can trigger extra blackout rolls, and the chance starts at 5% on Floor 3, rises 2% per floor and caps at 30% — [ItemLevel, Sept 26, 2024](https://itemlevel.net/dandys-world-complete-blackout-guide-percentages-light-sources-more)
- In "[CHAP 3]💡Lights Out", a light-hating creature wants every light in the facility out, and the player collects 14 batteries to restore power. It is PvE, solo-oriented, with maxPlayers 12 — [games API](https://games.roblox.com/v1/games?universeIds=10423877607,4759813126,5266731280)

**Survivors repairing**
- Forsaken and Violence District: generator repair with skill checks — [BlueStacks](https://www.bluestacks.com/blog/game-guides/roblox/rl-forsaken-beginners-guide-en.html); [Sportskeeda](https://widgets.sportskeeda.com/roblox-news/violence-district-a-beginner-s-guide)
- Bite By Night: "power generators to open the exit". In one example objective, Electric Wiring, players hold to fix wires, and only one player can work an objective at a time — [fan wiki](https://bite-by-night-wiki.pages.dev/how-to-play)
- Flee the Facility: hack computers to open the exits — [Sportskeeda](https://www.sportskeeda.com/roblox-news/how-to-play-roblox-flee-the-facility)

**Light or being seen as protection**
- 99 Nights in the Forest: "During nighttime, The Deer will chase the player if they're not in the safe zone (Campfire)". It "won't invade the Campfire's safe zone unless the fire goes out", and a flashlight "would briefly stun them". This fan guide is partly AI-assisted, so treat the details with caution — [rblxguide](https://rblxguide.com/games/99-nights-in-the-forest/entities/the-deer)
- Stay In The Light: a dark creature repelled by light while you collect batteries. It has 1 player — [games API](https://games.roblox.com/v1/games?universeIds=10423877607,4759813126,5266731280)
- Nightlight [HORROR]: a candle is your only light, and you protect its flame by finding matches. It has 6 players — [games API](https://games.roblox.com/v1/games?universeIds=10423877607,4759813126,5266731280)
- Doors: Screech spawns only in "natural dark rooms", and staring it down prevents its attack, so looking protects you here. By contrast, with Eyes you must not look — [speedrun.com Doors guide](https://www.speedrun.com/roblox_doors/guide/l76ng)
- Dandy's World blackouts: all characters give off a little light, and some (Astro, Vee, Brightney) give off more. Items and cards widen the light radius — [ItemLevel](https://itemlevel.net/dandys-world-complete-blackout-guide-percentages-light-sources-more)

**The inverse rule: being seen kills you**
- "📸 Hide from Camera or Die! 💀" (universe 10764794065, group Avid Experiences): players sprint for cover before a camera takes a photo, getting caught eliminates you, and each round the map gets harder. Victory goes to the last player standing or to anyone who survives all five rounds. **"Eliminated players can spectate and harass those still alive."** 249 playing, 8,554,246 visits, maxPlayers 12, created 2026-09-02, updated 2026-10-30 — [games API](https://games.roblox.com/v1/games?universeIds=10764794065,10391036163,7008097940,2936053166). Votes 6,784 / 5,497 (55.2%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=camera&sessionId=8&pageType=all)
- Squid Game X lists Red Light, Green Light among its modes — [games API](https://games.roblox.com/v1/games?universeIds=10764794065,10391036163,7008097940,2936053166)

**Cameras as a tool for the player**
- Keep the Door Locked: alone in a hotel room after midnight, you watch security cameras, follow rules and decide which knocking visitors to let in — [games API](https://games.roblox.com/v1/games?universeIds=9257800423,10232686472,6635513269)
- Anomaly Detected: a surveillance shift where you report changes in rooms, such as "a light that has been switched off", solo or with friends — [games API](https://games.roblox.com/v1/games?universeIds=10764794065,10391036163,7008097940,2936053166)

**Blackout phases**
- Dandy's World Blackout (random per-floor event, above) — [ItemLevel](https://itemlevel.net/dandys-world-complete-blackout-guide-percentages-light-sources-more)
- 3008: day about 6 min, night about 5 min, and at night employees chase players — [GINX](https://www.ginx.tv/en/?p=60855)

**Dead players helping the living**
- Hide from Camera or Die!: eliminated players spectate and "harass" the living. This is hindering, not helping — [games API](https://games.roblox.com/v1/games?universeIds=10764794065,10391036163,7008097940,2936053166)
- Pressure: the premium Ferryman's Quarter can revive you late in the game, and after death a dossier describes the monster that killed you — [Sportskeeda](https://www.sportskeeda.com/roblox-news/roblox-pressure-a-survival-guide)
- Flee the Facility and Survive the Killer: *living* teammates rescue captured ones (Freeze Pods, rescues) — [Sportskeeda](https://www.sportskeeda.com/roblox-news/how-to-play-roblox-flee-the-facility); [games API](https://games.roblox.com/v1/games?universeIds=372226183,1489026993)

### Inferences
- BLIND SPOT's core rule (camera view = safety, darkness = death) seems unclaimed on Roblox. The nearest successful relative is 99 Nights' campfire safe zone, which is PvE, a fixed point and not a camera.
- The PvP mode (the Unseen cuts camera cables, survivors repair) is a reskinned generator-repair loop. Players will read it as familiar. That helps onboarding, but the camera-coverage twist has to carry the difference.
- Dandy's World shows that a random "Blackout" event is popular. It runs at 63K players (omni-search) with an 88.2% like ratio (1,785,153 / 239,490) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Dandys%20World&sessionId=12&pageType=all). BLIND SPOT's scheduled, escalating blackouts are a deliberate version of that spike of tension.
- "Hide from Camera or Die!" (created Sept 2026) is the most direct thematic relative, with the rule inverted. It has 249 players and a 55% like ratio, so it isn't a strong competitor. Its "dead players harass" idea is worth noting next to BLIND SPOT's "dead players help".

### Gaps
- I couldn't verify whether any Forsaken, Die of Death or Bite By Night killer has a light or blackout ability. The guides fetched don't list one, but per-killer wikis (fandom) weren't fetched.
- I couldn't verify whether Bite By Night has FNAF-style cameras or power. None of the sources mention it, and the game is offline, so it can't be checked live.
- No source confirmed a spectator-assist mechanic (dead players controlling cameras, pinging, opening doors) in any of the leaders. This is absence of evidence, not proof.

---

## Q3. Round-based horror built on phases or light cycles: how the phases work

### Takeaway
Three phase patterns dominate:
1. **Warning-then-strike entities** (Doors, Pressure): flickering lights mean hide now.
2. **Day/night economies** (3008, STAY INSIDE, 99 Nights): a safe phase to gather or build, then a dangerous night.
3. **Move/freeze rhythm games** (Squid Game Red Light, Green Light): being seen at the wrong moment eliminates you.

BLIND SPOT's LIVE → FLICKER → BLACKOUT maps onto Doors' flicker-as-telegraph plus 3008's timed cycle. Its REC lights showing which cameras survive the blackout are a new layer of information.

### Cited Findings

**DOORS** (universe 2440500124, studio LSPLASH)
- 25,053 playing (omni-search showed 72,353, likely stale), 8,001,766,650 visits, maxPlayers 50, created 2021-03-14, updated 2026-11-03 — [games API](https://games.roblox.com/v1/games?universeIds=66654135,2440500124,1000233041,4367208330,10665420648)
- Votes 4,752,179 / 355,981 (93.0%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Pressure&sessionId=1&pageType=all)
- Rush: "Lights flicker briefly as a warning", then a sound approaches and lights shatter. You hide in a closet or bed.
- Ambush: also preceded by a flicker, but it comes back repeatedly.
- Halt: announced by an unusually long flicker.
- Screech: spawns only in "natural dark rooms", and staring it down prevents its attack.
- Eyes: you must not look at it.
- Figure: blind and hunts by sound.
- Shadow: flickers the lights but is harmless, a false alarm.
- Source for all of the above — [speedrun.com Doors guide](https://www.speedrun.com/roblox_doors/guide/l76ng)

**Pressure** (universe 4367208330, group Urbanshade: Hadal Division)
- 860 playing, 493,607,702 visits, maxPlayers 50, created 2023-02-07, updated 2026-10-24 — [games API](https://games.roblox.com/v1/games?universeIds=66654135,2440500124,1000233041,4367208330,10665420648)
- Votes 732,101 / 111,521 (86.8%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Pressure&sessionId=1&pageType=all)
- If "lights and electronics suddenly start flickering", Angler is coming: run and hide in a locker. The guide recommends parties of up to four — [Sportskeeda](https://www.sportskeeda.com/roblox-news/roblox-pressure-a-survival-guide)

**3008** (universe 1000233041, individual developer)
- As "3008 [2.75]": 9,537 playing, 3,341,492,113 visits, maxPlayers 16, created 2019-01-20, updated 2026-10-31 — [games API](https://games.roblox.com/v1/games?universeIds=66654135,2440500124,1000233041,4367208330,10665420648)
- Votes 2,012,786 / 181,067 (91.7%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=STAY%20INSIDE&sessionId=1&pageType=all)
- A day "lasts six minutes, or 360 seconds", and "One night in 3008 lasts 5 minutes". At night employees chase players, and it is "much harder to navigate". A paid Personal Watch gamepass shows the time left in the current phase — [GINX](https://www.ginx.tv/en/?p=60855)

**STAY INSIDE!** (universe 9257800423, rootPlace 94495283121683, FalconRise Studio)
- 1,263 playing, 42,676,464 visits, maxPlayers 8, created 2025-11-28, updated 2026-11-03 — [games API](https://games.roblox.com/v1/games?universeIds=9257800423,10232686472,6635513269)
- Votes 169,625 / 10,238 (94.3%), matching the brief's earlier figure (169,620 / 10,237) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=STAY%20INSIDE&sessionId=1&pageType=all)
- Phases: by day you shop for furniture at the supermarket. At night strange entities roam and you must stay inside until morning. It is "cozy horror" with a home upgrade loop (Coziness) and multiplayer with friends — [games API](https://games.roblox.com/v1/games?universeIds=9257800423,10232686472,6635513269)

**Keep the Door Locked** (universe 10232686472, rootPlace 124338404742585, group Hotel Room Services)
- 1,096 playing, 82,077,249 visits, maxPlayers 20, created 2026-05-28, updated 2026-10-31 — [games API](https://games.roblox.com/v1/games?universeIds=9257800423,10232686472,6635513269)
- Votes 66,113 / 6,560 (91.0%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=STAY%20INSIDE&sessionId=1&pageType=all)
- Mechanic: after midnight in a hotel room, strangers knock. Some need help and some lie. You watch security cameras, follow rules and decide who comes in — [games API](https://games.roblox.com/v1/games?universeIds=9257800423,10232686472,6635513269)

**Squid Game "Red Light, Green Light" games**
- Squid Game X (universe 2936053166): 16,411 playing, 2,352,102,394 visits, maxPlayers 80, updated 2026-11-04. Modes include Red Light, Green Light, Glass Bridge and Tug of War — [games API](https://games.roblox.com/v1/games?universeIds=10764794065,10391036163,7008097940,2936053166). Votes 1,580,594 / 105,916 (93.7%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=squid%20game&sessionId=7&pageType=all)
- Ink Game (universe 7008097940): 15,131 playing, 3,379,377,206 visits, maxPlayers 100, created 2024-12-31. Squid Game-style deadly challenges with three endings — [games API](https://games.roblox.com/v1/games?universeIds=10764794065,10391036163,7008097940,2936053166). Votes 1,262,034 / 331,066 (79.2%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=squid%20game&sessionId=7&pageType=all)

**"Lights Out" games** (single-player and small horror; no party-game "Lights Out" was found in search)
- [CHAP 3]💡Lights Out (universe 10423877607, Prince Creations): 171 playing, 2,913,608 visits, maxPlayers 12, created 2026-07-01, updated 2026-10-16. A light-hating creature, and you collect 14 batteries to restore power — [games API](https://games.roblox.com/v1/games?universeIds=10423877607,4759813126,5266731280). Votes 27,076 / 1,048 (96.3%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=lights%20out&sessionId=1&pageType=all)
- [CLASSIC VERSION] Lights Out💡: 6 playing, 43,102 / 7,897 (84.5%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=lights%20out&sessionId=1&pageType=all)
- 😱 Stay In The Light (BloodyKiwi Studios): 1 playing, 20,447,515 visits, created 2023-06-11. Votes 30,411 / 15,230 (66.6%) — [games API](https://games.roblox.com/v1/games?universeIds=10423877607,4759813126,5266731280); [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=lights%20out&sessionId=1&pageType=all)
- Nightlight [HORROR] (Nokain Studio): 6 playing, 68,662,616 visits — [games API](https://games.roblox.com/v1/games?universeIds=10423877607,4759813126,5266731280)

**Light-cycle hits outside the asymmetric genre**
- 99 Nights in the Forest 🔦 (universe 7326934954, Grandma's Favourite Games): 114,392 playing per omni-search (not cross-checked against the games API), votes 5,538,126 / 581,369 (90.5%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=99%20Nights%20in%20the%20Forest&sessionId=11&pageType=all). Rowatcher cites over 219,000 CCU and calls it the highest-CCU horror game on Roblox (article date uncertain) — [Rowatcher](https://rowatcher.com/news/the-golden-age-of-roblox-horror-how-three-games-are-redefining-survival-on-the-platform). Night threat plus campfire safe zone — [rblxguide](https://rblxguide.com/games/99-nights-in-the-forest/entities/the-deer)
- Dandy's World (universe 5569032992, BlushCrunch Studio): 63,074 playing per omni-search (not cross-checked), 88.2% — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Dandys%20World&sessionId=12&pageType=all). Rowatcher cites team play of up to 8 and a peak of 866,577 — [Rowatcher](https://rowatcher.com/news/the-golden-age-of-roblox-horror-how-three-games-are-redefining-survival-on-the-platform). Blackout event — [ItemLevel](https://itemlevel.net/dandys-world-complete-blackout-guide-percentages-light-sources-more)

**New horror breakout (not light-based)**
- [UPD 2.1 🎃] THRESHOLD (universe 10665420648): 2,487 playing (omni-search 7,068), 36,573,161 visits, maxPlayers 45, created 2026-08-09, updated 2026-11-04. Its Chase Mode hears your voice, so "speaking aloud can get you killed" — [games API](https://games.roblox.com/v1/games?universeIds=66654135,2440500124,1000233041,4367208330,10665420648). Votes 269,244 / 8,406 (97.0%) — [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Pressure&sessionId=1&pageType=all)

### Inferences
- Doors established the "flicker means danger" telegraph on Roblox, so BLIND SPOT's FLICKER phase will be readable instantly. Doors also uses Shadow's harmless flicker as a fake-out, a device BLIND SPOT could borrow.
- 3008's timed 6-min/5-min cycle shows players accept fixed phase lengths. It also shows that phase-timer information can be sold as a gamepass (Personal Watch). BLIND SPOT's REC lights give that information away for free as a core mechanic.
- Red Light, Green Light (16K and 15K players) shows that a rule tied to being seen scales to huge free-for-all lobbies (80–100 players). BLIND SPOT's 4–8 players is a deliberate co-op choice in the other direction.

### Gaps
- No Roblox "Lights Out" *party* game (lights cut, players scramble) was found. Searches turned up only single-player horror titles with that name.
- Doors' and Pressure's in-run team sizes (as opposed to the lobby maxPlayers of 50) weren't verified.
- Neither STAY INSIDE's nor Keep the Door Locked's phase lengths were verified.

---

## Q4. Healthy player counts for asymmetric horror on Roblox, and what separates hits from dead games

### Takeaway
On a weekday afternoon (Nov 4, 2026) the asymmetric tiers look like this:
- **Hit:** 10K–45K playing (Violence District, Forsaken, Flee the Facility, Piggy).
- **Healthy niche:** 1K–4K (Survive the Killer, Die of Death).
- **Long tail:** about 150–1,200 for Forsaken-likes and revivals.
Even the hits run far below their peaks: Forsaken shows about 27K against a 1.2M peak, and Violence District 43K against 277.7K. The 7-day averages are falling 11–14%. The living games share these traits:
- constant live-service updates, visible in event tags in their titles and update timestamps within days;
- a roster of collectible killers and survivors;
- Roblox-native identity or nostalgia;
- uptime.
Bite By Night went from a 350K peak to 0 by going offline.

### Cited Findings
- Violence District: 43,094 now, 277.7K peak, 7-day average 57,563 (down 11.1%) — [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624); [rotrends](https://www.rotrends.com/game/6739698191/violence-district)
- Forsaken: about 27.4K now, 1.2M peak, 7-day average 37,660 (down 13.6%), sessions 16.7 min — [rotrends](https://www.rotrends.com/game/6331902150/forsaken)
- Bite By Night: peak 350,238 on April 7, 2026, now 0 across all tracked windows during the maintenance shutdown — [AllThings.How](https://allthings.how/bite-by-night-maintenance-update-what-developer-saivv-confirmed/)
- Mid tier: Survive the Killer at 3,559 and Die of Death at 1,414 — [games API](https://games.roblox.com/v1/games?universeIds=372226183,1489026993); [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624)
- Tail: Pillar Chase (TBN) 151, SPOOK BY FATE 166, Swapsaken 180, Codename: Redux about 227 — [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624); [omni-search](https://apis.roblox.com/search-api/omni-search?searchQuery=Doom%20by%20Fate&sessionId=9&pageType=all)
- Live-service signals in current titles: "[WEEK 2 🎃 x BUTCHER] Violence District" (updated 2026-11-04), "Piggy [X2 SEASON XP]", "[HALLOWEEN PT2!] Pillar Chase". Most leaders updated within the last two days (FTF, STK, Piggy and Die of Death on 2026-11-03) — [games API](https://games.roblox.com/v1/games?universeIds=372226183,1489026993); [games API](https://games.roblox.com/v1/games?universeIds=6739698191,9515324315,7344582593,1516533665,8202280624)
- Rowatcher's shared success factors: improved lighting and audio, more adaptive enemy AI, "creator-driven viral content on YouTube and TikTok", live-service update cycles and free-to-play. For Forsaken specifically: Dead by Daylight-style asymmetry plus Roblox-history nostalgia in its characters. The article's metadata date (Mar 13, 2025) conflicts with the 2026 references in its body — [Rowatcher](https://rowatcher.com/news/the-golden-age-of-roblox-horror-how-three-games-are-redefining-survival-on-the-platform)
- Designbeep credits Forsaken's growth to "asymmetrical tension", "Roblox-classic-inspired characters", teamwork and regular updates — [Designbeep, Aug 10, 2026](https://designbeep.com/2026/08/10/forsaken-roblox/)
- Platform risk: Violence District was taken down on Sept 1, 2025 after an automated moderation flag on a blood decal — [Destructoid](https://www.destructoid.com/bizarre-reason-behind-robloxs-takedown-of-violence-district/)
- The like ratio doesn't decide success. Forsaken leads the genre at 84.4%, below most of its rivals (FTF 92.1%, VD 93.0%), while the tail ranges from 75.3% (Pillar Chase) to 88.0% (SPOOK BY FATE) — votes from the omni-search links above

### Inferences
- For a new asymmetric round game in this genre, about 1K steady CCU puts it in the "healthy niche" alongside Die of Death and STK. A few hundred is the long-tail norm.
- Hits are driven by content cadence and a recognizable cast, not by the base loop. The base loop (generators to exit) is nearly identical across hits and dead copies. BLIND SPOT's distinctive camera rule is the kind of difference the tail games lack, but the evidence says a cast of killers or Unseen variants and a weekly update rhythm will matter as much.
- Downtime kills momentum fast: Bite By Night went from a 350K peak to 0 while closed. A launch should avoid planned shutdowns and keep moderation-safe assets, given Violence District's blood-decal takedown.
- Horror rounds survive at small server sizes. FTF thrives at 5 per server and VD at 6, so 4–8 players is not a handicap.

### Gaps
- No time series beyond rotrends' 7-day and 14-day averages was gathered. Peak dates for Forsaken and VD are unknown.
- No developer postmortems on failed asymmetric Roblox games were found.
- YouTube's role was asserted by Rowatcher but not measured.

---

## Q5. Per-game summary table (verified mechanic, players, like ratio, dates, visits, status, closeness to BLIND SPOT)

Closeness scale:
- **0:** shares the format only.
- **1:** shares one piece (asymmetric repair loop, or a phase or light cycle).
- **2:** shares several pieces or the light/seen-as-safety idea.
- **3:** a near-direct overlap (camera view as safety, killer cuts cameras, blackout phases). **No game scored 3.**

Players were read Nov 4, 2026 from the games API unless marked (o) for omni-search or (r) for rotrends. Sources for every row are in Q1–Q4.

| Game (universe) | Verified mechanic | Players Nov 4 | Like ratio | Created / updated | Visits | Status | Close (0–3) |
|---|---|---|---|---|---|---|---|
| Violence District (6739698191) | 5v1, generator objectives, pallets, up to 15-min matches | 43,094 | 93.0% | 2024-10-31 / 2026-11-04 | 1.68B | Active, weekly event | 1 |
| Forsaken (6331902150) | Killer vs survivors, generators with skill checks, timer, exit gates | ~27.4K (o, r); 52,757 API outlier | 84.4% | 2024-07-28 / 2026-10-02 | 5.77B | Active | 1 |
| Flee the Facility (372226183) | Beast vs survivors, hack computers, exits, Freeze Pod rescues | 20,086 | 92.1% | 2017-07-01 / 2026-11-03 | 6.14B | Active | 1 |
| Piggy (1516533665) | Escape Piggy, items, traps | 11,700 (o: 28,561) | 90.3% | 2020-01-23 / 2026-11-03 | 14.45B | Active | 1 |
| Survive the Killer! (1489026993) | Hide, rescue, escape before time runs out | 3,559 | 90.3% | 2020-01-06 / 2026-11-03 | 2.71B | Active | 1 |
| Die of Death (7344582593) | Random modes, survivor ability decks vs killer | 1,414 | 87.2% | 2025-03-08 / 2026-11-03 | 345M | Active | 1 |
| Pillar Chase, TBN (9515324315) | 1–2 monsters vs survivors, tasks and escape | 151 | 75.3% | 2026-01-06 / 2026-11-04 | 12.1M | Weak | 1 |
| Bite By Night (8202280624) | 1v4, power generators to open the exit, survive to 6 AM, barricade doors, classes incl. Security Guard | 0 (maintenance) | 92.1% | 2025-07-19 / 2026-09-18 | 343M | Offline; 350,238 peak Apr 7, 2026 | 1 (2 if FNAF-style power or cameras exist: unverified) |
| Murder Mystery 2 (66654135) | Innocents, sheriff, murderer; knife trading | 253,175 | 90.8% | 2014-01-18 / 2026-11-04 | 32.1B | Active (format benchmark) | 0 |
| DOORS (2440500124) | Light flicker warns of Rush, Ambush and Halt; Screech in dark rooms; hide in closets | 25,053 (o: 72,353) | 93.0% | 2021-03-14 / 2026-11-03 | 8.0B | Active | 2 |
| Pressure (4367208330) | Flicker warns of Angler; lockers; paid revive | 860 (o: 1,307) | 86.8% | 2023-02-07 / 2026-10-24 | 494M | Active, low | 1 |
| 3008 (1000233041) | Day about 6 min, night about 5 min with hostile employees; base building | 9,537 | 91.7% | 2019-01-20 / 2026-10-31 | 3.34B | Active | 2 |
| STAY INSIDE! (9257800423) | Day shopping, then night entities while you stay inside; cozy upgrades | 1,263 | 94.3% | 2025-11-28 / 2026-11-03 | 42.7M | Active | 1 |
| Keep the Door Locked (10232686472) | Night shift; watch security cameras; decide whom to let in | 1,096 | 91.0% | 2026-05-28 / 2026-10-31 | 82.1M | Active | 2 |
| Hide from Camera or Die! (10764794065) | Being seen by a camera eliminates you; 5 escalating rounds; dead spectate and harass | 249 | 55.2% | 2026-09-02 / 2026-10-30 | 8.55M | Weak | 2 (inverse rule) |
| Anomaly Detected (10391036163) | Surveillance feeds; report anomalies such as lights turned off | 473 | 88.2% | 2026-06-25 / 2026-11-02 | 10.9M | Small, active | 1 |
| Squid Game X (2936053166) | Red Light, Green Light and other modes, 80-player servers | 16,411 | 93.7% | 2021-09-24 / 2026-11-04 | 2.35B | Active | 1 |
| Ink Game (7008097940) | Squid Game challenges, 100-player servers | 15,131 | 79.2% | 2024-12-31 / 2026-11-03 | 3.38B | Active | 1 |
| [CHAP 3] Lights Out (10423877607) | Light-hating creature; 14 batteries to restore power | 171 | 96.3% | 2026-07-01 / 2026-10-16 | 2.9M | Small | 2 |
| Stay In The Light (4759813126) | Creature repelled by light; collect batteries | 1 | 66.6% | 2023-06-11 / 2026-10-25 | 20.4M | Dead | 2 |
| Nightlight (5266731280) | Protect a candle flame; find matches; notes | 6 | 84.6% | 2023-11-05 / 2026-09-11 | 68.7M | Dead | 1 |
| 99 Nights in the Forest (7326934954) | Night monster; campfire safe zone; flashlight stun | 114,392 (o) | 90.5% | not fetched | not fetched | Active, top horror | 2 |
| Dandy's World (5569032992) | Floors with a random Blackout event (5%→30%); light-emitting characters; one enemy raises the blackout chance | 63,074 (o) | 88.2% | not fetched | not fetched | Active | 2 |
| THRESHOLD (10665420648) | Chase Mode hears your voice | 2,487 (o: 7,068) | 97.0% | 2026-08-09 / 2026-11-04 | 36.6M | Rising, new | 0 |
| he ate them. (6635513269) | Story horror; mechanics not described | 3,738 | 97.3% | 2024-10-05 / 2026-11-03 | 60.5M | Active | 0 |

### Takeaway
No live Roblox game scores 3. The closest relatives each own one slice:
- Doors: flicker as warning.
- 3008: timed night phase.
- 99 Nights and Dandy's World: light as safety and blackout events (PvE).
- Keep the Door Locked: security cameras as a tool.
- Hide from Camera or Die!: camera field of view as the rule, inverted.

None of them is an asymmetric PvP game.

### Cited Findings
- All rows are sourced above. Votes for 99 Nights, Dandy's World, Spook by Fate and the Lights Out titles come from their omni-search links. Bite By Night and MM2 votes come from the [votes API](https://games.roblox.com/v1/games/votes?universeIds=66654135,8202280624).
- Other search results noted but not investigated: "Blackout: Revival [FREE ZOMBIES]" (151 playing, 85.5%), "[🎃 HALLOWED REACTOR] Examination" (3,898 playing) and "Animal Hospital (Anomaly)" (16,010 playing). Their mechanics are unverified, and they appear zombie- or anomaly-themed rather than about light cycles — [omni-search blackout](https://apis.roblox.com/search-api/omni-search?searchQuery=blackout&sessionId=1&pageType=all); [omni-search lights out](https://apis.roblox.com/search-api/omni-search?searchQuery=lights%20out&sessionId=1&pageType=all)

### Inferences
- The white space is an asymmetric PvP game in which **camera coverage is the safe zone** and **the killer attacks the coverage** (cables and power), with telegraphed blackout phases. No competitor I found occupies it.
- The two light-as-safety mega-hits (99 Nights and Dandy's World) are co-op PvE. They show the audience likes "darkness is dangerous, light saves you", but neither proves the PvP version.

### Gaps
- Created and updated dates and visits for 99 Nights and Dandy's World weren't fetched, and their player counts are from omni-search only.
- The mechanics of "Examination", "Animal Hospital (Anomaly)" and "Blackout: Revival" weren't checked.
- No YouTube or fandom sources were used, so per-character abilities (killers with blackout or blinding powers) remain unverified across Forsaken, Die of Death and Bite By Night.
