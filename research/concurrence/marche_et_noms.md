# Roblox horror market (fall 2026) and name availability for BLIND SPOT

All Roblox numbers were read on **Nov 4, 2026, around 18:50–19:30 UTC** unless noted otherwise.

**About the counts.** I used two Roblox endpoints:

- **The games API** (`games.roblox.com/v1/games`): this gives the live `playing` count, and I treat it as authoritative.
- **The omni-search API** (`apis.roblox.com/search-api/omni-search`): this gives `playerCount`, `totalUpVotes` and `totalDownVotes`.

The two disagree for the same game at the same moment:

| Game | Games API | Omni-search |
|---|---|---|
| Hide from Camera or Die! | 1,601 | 261–266 |
| 99 Nights | 114,727 | 194,919 in the "horror" query, 115,090 in another |
| Sarab | 6,289 | 29,628 in the "horror" query, 6,352 in another |

The "horror" query also returned *lower* up-vote totals than later queries for the same games (for example he ate them: 289,851 against 384,656). That query was probably served from an older cache. So treat omni-search player counts as rough, and like ratios are computed from the most recent query that returned each game.

**Like ratio** below means up / (up + down).

## 1. Is horror a good genre to enter on Roblox right now? What tops the genre, what broke out in 2026, and what is saturated?

### Takeaway

Horror is one of the healthiest genres on Roblox in fall 2026. The top is held by very large survival or co-op horror games (99 Nights in the Forest at about 115K concurrent, Forsaken at about 64K, DOORS at about 25K). 2026 produced several huge breakouts:

- **Animal Hospital (Anomaly):** created in May 2026, now at 2.5B visits.
- **Unseen Liminality:** created in March 2026, about 100M visits.
- **DONT SPLASH:** created on Oct 17, 2026, with 185M visits and about 78K concurrent within 18 days.
- **Sarab:** created on Sep 24, 2026, with 71M visits.

Two formats are visibly crowded with low-player clones: the anomaly or night-shift format and the Forsaken-style asymmetric derivatives. The "___ or Die" format keeps spawning new entrants.

### Cited Findings

**Current top horror and horror-adjacent games** (games API live count where available)

- **99 Nights in the Forest** (group Grandma's Favourite Games): 114,727 playing; 30,404,049,753 visits; created Mar 4, 2025; updated Nov 3, 2026. The description is a co-op survival camp-building game in which "an unseen presence watches from the forest" — [games API](https://games.roblox.com/v1/games?universeIds=2440500124,2294168059,7326934954,10148749921,6635513269). Like ratio about 90.5% (5,538,126 up / 581,369 down) — [omni-search "Night Crew"](https://apis.roblox.com/search-api/omni-search?searchQuery=Night%20Crew&sessionId=1&pageType=all)
- **DONT SPLASH** (group Bacon Theory): 77,762 playing; 185,608,974 visits; created **Oct 17, 2026**; genre "Obby & Platformer". The description is an eerie pool-themed runner obby "inspired by the Poolrooms and House of the Locust" — [games API](https://games.roblox.com/v1/games?universeIds=10771421858,10767825538,10770728771,10769902948,9745765358). Like ratio about 86.9% (102,300 / 15,452) — [omni-search "Stay on Camera"](https://apis.roblox.com/search-api/omni-search?searchQuery=Stay%20on%20Camera&sessionId=1&pageType=all)
- **Forsaken** (Forsaken Dev Team), the asymmetric killer game: about 63,863 playing (omni-search); 2,363,945 up / 432,061 down, so a like ratio of about 84.5% — [omni-search "Forsaken"](https://apis.roblox.com/search-api/omni-search?searchQuery=Forsaken&sessionId=1&pageType=all). RoWatcher describes it as "Asymmetric 1v8, inspired by Dead by Daylight" — [RoWatcher article](https://rowatcher.com/news/10-best-roblox-horror-games-in-2026-from-dandy-s-world-to-hidden-gems)
- **DOORS** (group LSPLASH), the roguelite room-crawler: 24,909 playing; 8,001,774,424 visits; created 2021; updated Nov 3, 2026 — [games API](https://games.roblox.com/v1/games?universeIds=2440500124,2294168059,7326934954,10148749921,6635513269). Like ratio about 93.0% (4,779,618 / 357,072) — [omni-search "Unseen"](https://apis.roblox.com/search-api/omni-search?searchQuery=Unseen&sessionId=1&pageType=all)
- **Flee the Facility**, an older asymmetric 1-beast-vs-survivors game: about 19,993 playing (omni-search); like ratio about 92.1% (2,825,236 / 242,517) — [omni-search "Don't Leave the Frame"](https://apis.roblox.com/search-api/omni-search?searchQuery=Don%27t%20Leave%20the%20Frame&sessionId=1&pageType=all)
- **Animal Hospital (Anomaly)** (group Animal Anomaly): 15,801 playing; **2,505,190,362 visits**; created **May 10, 2026**. It is an anomaly-style night-shift game — [games API](https://games.roblox.com/v1/games?universeIds=2440500124,2294168059,7326934954,10148749921,6635513269). Like ratio about 92.9% (1,347,130 / 102,933) — [omni-search "Night Crew"](https://apis.roblox.com/search-api/omni-search?searchQuery=Night%20Crew&sessionId=1&pageType=all)
- **Sarab** (group Patience Zone): 6,289 playing; 70,974,079 visits; created **Sep 24, 2026**. It is story survival horror with puzzles, chases and three endings — [games API](https://games.roblox.com/v1/games?universeIds=10771421858,10767825538,10770728771,10769902948,9745765358). Like ratio about 88.4% (70,986 / 9,271) — [omni-search "Night Crew"](https://apis.roblox.com/search-api/omni-search?searchQuery=Night%20Crew&sessionId=1&pageType=all)
- **Unseen Liminality** (group The Unseen Zone): 5,164 playing; 99,926,405 visits; created **Mar 15, 2026**. It is liminal and backrooms exploration — [games API](https://games.roblox.com/v1/games?universeIds=10231960870,9885372266,3326279937,4523856444,7521520342). Like ratio about 93.9% (168,035 / 10,926) — [omni-search "The Unseen"](https://apis.roblox.com/search-api/omni-search?searchQuery=The%20Unseen&sessionId=1&pageType=all)
- **The Mimic** (group CTStudio), anthology story chapters: 4,166 playing; 1,277,431,865 visits — [games API](https://games.roblox.com/v1/games?universeIds=2440500124,2294168059,7326934954,10148749921,6635513269). Like ratio about 90.1% (1,144,088 / 126,084) — [omni-search "The Unseen"](https://apis.roblox.com/search-api/omni-search?searchQuery=The%20Unseen&sessionId=1&pageType=all)
- **he ate them. [HORROR]**, a creator-lore story game: 3,798 playing; 60,460,644 visits; created Oct 2024 — [games API](https://games.roblox.com/v1/games?universeIds=2440500124,2294168059,7326934954,10148749921,6635513269). Like ratio about 97.3% (384,656 / 10,764) — [omni-search "Night Crew"](https://apis.roblox.com/search-api/omni-search?searchQuery=Night%20Crew&sessionId=1&pageType=all)
- **Other active horror titles** (omni-search snapshots, counts possibly stale):

  | Game | Playing | Like ratio |
  |---|---|---|
  | THRESHOLD | about 2,450 | about 96.8% |
  | Survive Overnight in a Mega Store | about 3,513 | about 94.9% |
  | Home Alone: Anomalies | about 1,765 | about 94.7% |
  | Pasahero [ANOMALY HORROR] (new; universe ID in the 10.768B range) | about 1,874 | about 96.8% |
  | PREHISTORIC [HORROR] (new) | about 2,700 | about 71.8% |
  | Blair (co-op ghost hunting) | about 770 | about 92.2% |
  | FNAF: Co-op | about 1,284 | not given |

  Sources: [omni-search "Night Crew"](https://apis.roblox.com/search-api/omni-search?searchQuery=Night%20Crew&sessionId=1&pageType=all) and [omni-search "Stay on Camera"](https://apis.roblox.com/search-api/omni-search?searchQuery=Stay%20on%20Camera&sessionId=1&pageType=all)
- **From the "horror" query** (possibly stale cache): MONOCHROME about 5,397; Lethal Ape about 5,357; Scary Shawarma Kiosk: the ANOMALY about 4,580; Motel Maniac [HORROR] about 3,803; SUNYI [HORROR] about 2,569; IT WANTS IN [HORROR] about 1,884 — [omni-search "horror"](https://apis.roblox.com/search-api/omni-search?searchQuery=horror&sessionId=1&pageType=all)
- **Liminal and backrooms format:** Experience Abstraction about 6,126; Backrooms Company about 2,113; Build Your Backrooms about 1,885 (608,843 up / 12,555 down); M.E.G. Endless Reality about 1,415. Older leaders are now small: Apeirophobia about 455 and Interliminality about 454 — [omni-search "Unseen"](https://apis.roblox.com/search-api/omni-search?searchQuery=Unseen&sessionId=1&pageType=all)

**Formats and saturation**

- **The anomaly or night-shift format is crowded.** One "Night Crew" query alone returned these:

  | Game | Playing |
  |---|---|
  | Animal Hospital (Anomaly) | 16,010 |
  | Pasahero | 1,874 |
  | Route Zero (Anomaly) | 1,023 |
  | Night At The Infirmary (Anomaly) | 545 |
  | Thai Anomalies | 315 |
  | Midnight Shift (Anomaly) | 262 |
  | Somtum Anomaly | 75 |
  | Hotel Night Shift (Anomaly) | 24 |

  Source: [omni-search "Night Crew"](https://apis.roblox.com/search-api/omni-search?searchQuery=Night%20Crew&sessionId=1&pageType=all). Others include The Exit 8! (about 235–339), Anomaly Detected (461), Shawarma Truck: ANOMALIES (313) and Scary Shawarma Kiosk: the ANOMALY — [omni-search "horror"](https://apis.roblox.com/search-api/omni-search?searchQuery=horror&sessionId=1&pageType=all)
- **Forsaken derivatives are numerous:** Forsaken RP (396), Forsaken: Free For All (738), Forsaken Combat (3,761), Custom Forsaken Creator (274), Steal A Forsaken (7), Forsaken Tycoon (10) and more — [omni-search "Forsaken"](https://apis.roblox.com/search-api/omni-search?searchQuery=Forsaken&sessionId=1&pageType=all)
- **Clone speed (DONT SPLASH):** within about 18 days of its Oct 17 launch, there were already "It Hears The Water [DONT SPLASH]" (2,337 playing), "DONT SPLASH💦Monster Escape" (13), "Don't splash Prilili" (445), "Don't Splash for Eggs" (150) and "DONT NOISE! VERITY [DONT SPLASH]" (32) — [omni-search "Don't Leave the Frame"](https://apis.roblox.com/search-api/omni-search?searchQuery=Don%27t%20Leave%20the%20Frame&sessionId=1&pageType=all); [omni-search "Stay on Camera or Die"](https://apis.roblox.com/search-api/omni-search?searchQuery=Stay%20on%20Camera%20or%20Die&sessionId=1&pageType=all)
- **Roblox's official Halloween 2026 event:** "Nine Nights of Fright in The Hollow" ran Oct 22 – Nov 2, 2026. The horror experiences named as participants were DOORS, 99 Nights in the Forest and Piggy. Home Alone Anomalies and The Mimic had integrations — [Outlook Respawn, Oct 27, 2026](https://respawn.outlookindia.com/gaming/gaming-news/roblox-halloween-2026-brings-horror-games-rewards-and-more)
- **The Hollow event hub** (group Roblox Presents): 2,700 playing on Nov 4; 193,197,696 visits; created Oct 13, 2026 — [games API](https://games.roblox.com/v1/games?universeIds=10771421858,10767825538,10770728771,10769902948,9745765358)
- **Editorial view (RoWatcher, author Marcus Chen; the page's date metadata says May 9, 2025 but the content covers 2026, so the date is unreliable):**
  - "Asymmetric horror is the fastest-growing subgenre."
  - "Traditional jump-scare horror is losing ground to games with deeper mechanics."
  - "2026 is the best year yet for horror on Roblox."
  - Its top tier is Doors, The Mimic, Pressure and Dandy's World.
  - It calls Road-Side Shawarma (a CCTV-and-rulebook night-shift game) "the breakout horror hit of the season."

  Its quoted concurrents (99 Nights 226K, Dandy's World 110K, Forsaken 82K) do not match today's live numbers, so treat them as older — [RoWatcher](https://rowatcher.com/news/10-best-roblox-horror-games-in-2026-from-dandy-s-world-to-hidden-gems)

### Inferences

- **Horror is a good genre to enter, but not with a me-too format.** The money is concentrated in a few mega-hits, and each new format gets cloned within days (DONT SPLASH clones within about 2 weeks). A new entrant needs a hook that reads instantly from the thumbnail and title. "Stay in the camera or the monster gets you" is such a hook.
- **2026 breakouts came from simple, readable rules or strong atmosphere,** not from complex systems:
  - anomaly-spotting (Animal Hospital);
  - "don't splash" (DONT SPLASH);
  - liminal exploration (Unseen Liminality);
  - one-sentence story premises (Sarab).

  BLIND SPOT's rule is in that spirit.
- **Crowded formats to avoid copying outright:** anomaly or night shift, Forsaken-style asymmetric spin-offs, and backrooms. BLIND SPOT uses cameras (an anomaly-adjacent prop) but has a different core rule. Its PvP mode (one player is the Unseen) touches asymmetric territory, where Forsaken and Flee the Facility are entrenched.
- **The seasonal peak has just passed.** Halloween (The Hollow, Oct 22 – Nov 2) has ended. Peak dates of "___ or Die" games (Oct 26, 2025 and Dec 28, 2025; see section 2) suggest holiday periods drive peaks. A late-November or December launch would catch the winter holidays but not the Halloween horror tailwind. This is inference from two data points.

### Gaps

- I did not fetch live counts for Dandy's World, Pressure, Piggy, Evade, Dead Rails, Road-Side Shawarma or Blair's history, so their current standing is **unverified**.
- I did not get a reliable genre-ranked horror chart. The RoWatcher genre page lists crowd-tagged junk (top entry "Indian Bank Story", 2K) and is useless ([RoWatcher Horror genre](https://rowatcher.com/genres/Horror)). Rotrends and the official Roblox Charts were not fetched.
- I have no historical trend data (growing or declining) for most horror games. Only the two "or Die" games in section 2 have 30-day trends.
- The games.gg and playnews.gg 2026 horror articles and the progameguides The Hollow article failed to load.

## 2. The "___ or Die" title format: how big is it, and is it still growing?

### Takeaway

The format is large and still alive:

- **Color or Die** (1.38B visits, about 4.1K playing) is stable (+8.4% over 30 days).
- **Quiet or Die!** (281M visits, about 2K playing) is growing (+28.5% over 30 days).

At least 9 new "or Die" games appeared in Sep–Oct 2026, two of them already above 4.8K concurrent. One new entrant, **"📸 Hide from Camera or Die!"** (created Sep 2, 2026, 6.75M visits), is a direct camera-themed competitor whose rule is the *inverse* of BLIND SPOT's.

### Cited Findings

- **Color or Die 🎨** (group BIGworks Games):
  - 4,127 playing; 1,378,844,971 visits; 1,762,593 favorites; max 15 players; genre Survival.
  - Created Mar 29, 2023; updated Oct 14, 2026.
  - Rule: "stand on their matching color to avoid a monster while navigating a maze."

  Source: [games API](https://games.roblox.com/v1/games?universeIds=10231960870,9885372266,3326279937,4523856444,7521520342). Up / down: 1,643,918 / 181,660, so about 90.0% — [omni-search "Stay on Camera or Die"](https://apis.roblox.com/search-api/omni-search?searchQuery=Stay%20on%20Camera%20or%20Die&sessionId=1&pageType=all)
- **Color or Die trend:** verdict "Stable"; 7-day and 30-day averages 4K; **30-day change +8.4%** against +1% for Roblox overall; peak 17K on Oct 26, 2025 within the tracked window (713 daily aggregates) — [RoWatcher "dying?" page](https://rowatcher.com/games/4523856444/color-or-die/dying). The main RoWatcher page instead gives an all-time peak of **29K (November 2024)**, which is probably outside the 713-day window — [RoWatcher game page](https://rowatcher.com/games/4523856444/color-or-die)
- **Quiet or Die!** (created by an individual user account, not a group):
  - 1,987 playing; 281,116,100 visits; max 9 players; Party & Casual.
  - Created Apr 11, 2025; updated Nov 1, 2026.
  - Rule: "a blinded seeker hunts players who must stay silent."

  Source: [games API](https://games.roblox.com/v1/games?universeIds=10231960870,9885372266,3326279937,4523856444,7521520342). Up / down: 121,413 / 27,829, so about 81.4% — [omni-search "Stay on Camera or Die"](https://apis.roblox.com/search-api/omni-search?searchQuery=Stay%20on%20Camera%20or%20Die&sessionId=1&pageType=all)
- **Quiet or Die! trend:** verdict "growing, outpacing Roblox overall"; 7-day average 2K, 30-day average 1K; **30-day change +28.5%**; all-time peak 10K on Dec 28, 2025 — [RoWatcher "dying?" page](https://rowatcher.com/games/7521520342/quiet-or-die/dying)
- **Other established "or Die" titles** (omni-search snapshot):

  | Game | Playing | Like ratio |
  |---|---|---|
  | Bake or Die 💀 | 3,573 | 92.3% (146,840 / 12,256) |
  | Find or Die! 🔎 | 3,176 | 95.9% |
  | 💀 Hide or OOF! | 2,532 | 86.2% |
  | Dodge or Die | 703 | 88.3% |
  | Answer or Die | 672 | 79.6% |
  | PLAY OR DIE | 510 | 85.4% |
  | Pass or Die 💣 | 238 | not given |
  | 🎨 Right Color or Die💀 | 266 | not given |
  | 🥾 Walk or Die | 11 | 68.2% |

  Source: [omni-search "Stay on Camera or Die"](https://apis.roblox.com/search-api/omni-search?searchQuery=Stay%20on%20Camera%20or%20Die&sessionId=1&pageType=all)
- **New "or Die" entrants from fall 2026** (universe IDs in the 10.764B–10.772B range; see the inference on dating below):

  | Game | Playing | Up / down |
  |---|---|---|
  | 👁️ Steal Or Die [LIMINAL LUCIDITY!] | 6,736 | 41,448 / 4,058 (about 91.1%) |
  | Fake Dead or DIE | 4,806 | 8,168 / 2,626 (about 75.7%) |
  | 💀 Run Or Die! | 1,550 | about 77.0% |
  | Sleep or Die | 129 | not given |
  | Kill Or Die | 111 | not given |
  | Match or DIE!!! | 68 | not given |
  | Grow or Die🌱 | 61 | 49% |
  | Scrub or Die | 45 | not given |

  Also [🧬MUTATIONS] PAINT OR DIE! has 846 playing and 244,963 up. Sources: [omni-search "Stay on Camera or Die"](https://apis.roblox.com/search-api/omni-search?searchQuery=Stay%20on%20Camera%20or%20Die&sessionId=1&pageType=all); [omni-search "In Frame"](https://apis.roblox.com/search-api/omni-search?searchQuery=In%20Frame&sessionId=1&pageType=all)
- **📸 Hide from Camera or Die! 💀** (group Avid Experiences):
  - Playing: 1,601 by the games API, but only 261–266 by omni-search; the two disagree.
  - 6,752,730 visits; 315,390 favorites; max 12 players; genre_l1 Party & Casual.
  - Created **Sep 2, 2026**; updated Oct 14, 2026.
  - Rule: run to a hiding spot before the camera takes a photo and stay out of its view. Rounds get harder. Win by being the last player standing or by surviving 5 rounds. Slapping, and spectators who can troll. Inspired by "Hide or Die, Hide or Oof, and Spin or Die."

  Source: [games API](https://games.roblox.com/v1/games?universeIds=10764794065). Up / down: 6,784 / 5,497, so about **55.2%**, a poor ratio — [omni-search "Blind Spot"](https://apis.roblox.com/search-api/omni-search?searchQuery=Blind%20Spot&sessionId=1&pageType=all)
- **👀 Look Away!** (group Reaction Time Games): hunters and lookers on a shrinking platform; anyone in a hunter's view cone turns to stone. 53 playing; 3,342,668 visits; created Feb 17, 2026 — [games API](https://games.roblox.com/v1/games?universeIds=10771421858,10767825538,10770728771,10769902948,9745765358). Up / down: 9,176 / 5,193, so about 63.9% — [omni-search "Stay on Camera"](https://apis.roblox.com/search-api/omni-search?searchQuery=Stay%20on%20Camera&sessionId=1&pageType=all)

### Inferences

- **How I dated the new entrants.** Games created in Sep–Oct 2026 have universe IDs of about 10.764B and above: Hide from Camera or Die (10764794065) was created Sep 2, Sarab (10767825538) Sep 24, FRAMEBREAK (10769902948) Oct 8, The Hollow (10770728771) Oct 13, and DONT SPLASH (10771421858) Oct 17. So the "or Die" games with IDs of about 10.764B–10.772B were created in the last two months. That is at least 9 new titles, two of them (Steal Or Die, Fake Dead or DIE) already above Color or Die's current concurrent count.
- **The format is still growing, not declining:**
  - the flagship is stable;
  - Quiet or Die is up 28.5% over 30 days;
  - new entrants still break out.

  It is also clearly crowded, and many entrants have poor like ratios (55–77%).
- **"Hide from Camera or Die!" matters for BLIND SPOT:**
  - It proves a camera-themed round game can pull 6.75M visits in two months.
  - Its 55% like ratio suggests players find it shallow or frustrating, which leaves an opening for a better-made camera game.
  - A title like "Stay on Camera or Die" would read as its direct opposite. That could help (search adjacency, curiosity) or confuse (players may think it is the same game).
- **BLIND SPOT is heavier than typical "or Die" games:** 5-minute rounds, a monster that exists only in blind spots, 4–8 players, and a phase cycle. "Or Die" games are usually short, one-rule party rounds. An "or Die" title would place it in the party-casual lane, where the audience expects instant, simple rounds.

### Gaps

- I have no 30-day trend for the new fall 2026 "or Die" entrants. Only Color or Die and Quiet or Die were checked on RoWatcher.
- I have no format-level aggregate (for example, total concurrent across all "or Die" games over time). The breadth is shown only by search snapshots.
- I could not resolve the 1,601 vs 266 player discrepancy for Hide from Camera or Die!. The games API is presumed accurate.

## 3. Name availability: who already uses the candidate names, and which are free?

### Takeaway

- **Effectively free** (no game with that title in the top 40 search results): **Blind Spot / Blindspot**, **Stay on Camera**, **Stay on Camera or Die**, **Don't Leave the Frame**, **In Frame**, **REC**.
- **"Blind Spot" has a search problem:** Roblox search maps it to the active **"Blind Shot"** (677K likes).
- **Taken in practice:**
  - **The Unseen / Unseen:** "🎃Unseen Liminality" by group "The Unseen Zone", a 2026 horror hit with about 100M visits.
  - **Night Crew:** an active co-op paranormal horror game with that exact title.
  - **Blackout:** "Blackout: Revival", an active zombie shooter with 75.7M visits.

### Cited Findings

Each row is one omni-search query (top 40 results) read on Nov 4, 2026. Player counts come from the games API where noted, otherwise from omni-search.

| Candidate | Exact or near-exact title found? | Closest existing games (players, up / down, status) | Verdict | Source |
|---|---|---|---|---|
| **Blind Spot** | No game titled "Blind Spot" in the top 40 | Top result is **"[UPD] Blind Shot"** (group Blind Shot Group): 152 playing; 677,033 / 44,877 (93.8%), active. Also "100 Players Blind Shot" (1), "Blind Duel" (15), "Blind clone shot!" (48), "📸 Hide from Camera or Die! 💀" (261), "Exposed" (16) | **Free, but search collision with Blind Shot** | [omni "Blind Spot"](https://apis.roblox.com/search-api/omni-search?searchQuery=Blind%20Spot&sessionId=1&pageType=all) |
| **Blindspot** | No | Same as above: Blind Shot first, then shooter games | **Free, same collision** | [omni "Blindspot"](https://apis.roblox.com/search-api/omni-search?searchQuery=Blindspot&sessionId=1&pageType=all) |
| **REC** | No game titled "REC" | Results are video and movie experiences: "Rec It" (22 playing; 76,088 / 15,568), "🎥My Movie" (8,028), "Clip It" (4,853), "Movie Maker 4" (766). No horror game | **Free, but generic and hard to search** | [omni "REC"](https://apis.roblox.com/search-api/omni-search?searchQuery=REC&sessionId=1&pageType=all) |
| **The Unseen** | Near match | **"🎃Unseen Liminality"** (group **The Unseen Zone**): 5,164 playing (games API); 99,926,405 visits; created Mar 15, 2026; updated Nov 3, 2026; 168,035 / 10,926 (93.9%); **active horror**. Also "Unseen Truth" (0 playing; 2,428 / 367), dead | **Taken in practice** (an active horror brand uses "Unseen") | [omni "The Unseen"](https://apis.roblox.com/search-api/omni-search?searchQuery=The%20Unseen&sessionId=1&pageType=all); [games API](https://games.roblox.com/v1/games?universeIds=10231960870,9885372266,3326279937,4523856444,7521520342) |
| **Unseen** | Near match | Same Unseen Liminality on top. "UNSEEN obby [1 life]" (0 playing; 2,794 / 1,820), dead. "Unseen Truth" (0), dead | **Taken in practice** | [omni "Unseen"](https://apis.roblox.com/search-api/omni-search?searchQuery=Unseen&sessionId=1&pageType=all) |
| **Stay on Camera** | No | "📸 Hide from Camera or Die! 💀" (1,601 by games API; 6,784 / 5,497); "BODYCAM" (3; 4,906 / 6,695, net negative); "👀 Look Away!" (50); "Observation Duty [5 PLAYERS SUPPORT]" (0, dead); "Cameraman" (19); "Be My Camera [2 Player Obby]" (294) | **Free** | [omni "Stay on Camera"](https://apis.roblox.com/search-api/omni-search?searchQuery=Stay%20on%20Camera&sessionId=1&pageType=all) |
| **Stay on Camera or Die** | No | Results are other "or Die" games (see section 2); the closest is "📸 Hide from Camera or Die! 💀" | **Free** (direct opposite of an existing title) | [omni "Stay on Camera or Die"](https://apis.roblox.com/search-api/omni-search?searchQuery=Stay%20on%20Camera%20or%20Die&sessionId=1&pageType=all) |
| **Don't Leave the Frame** | No | "Don't leave the circle! ⭕️" (523); "FRAMEBREAK [BETA]" (350; a build-and-shoot game by an individual user, created Oct 8, 2026); "Don't Let Them See" (0; 112 / 63), dead; "Don't Let Them Find You [HORROR]" (4) | **Free** | [omni "Don't Leave the Frame"](https://apis.roblox.com/search-api/omni-search?searchQuery=Don%27t%20Leave%20the%20Frame&sessionId=1&pageType=all); [games API](https://games.roblox.com/v1/games?universeIds=10771421858,10767825538,10770728771,10769902948,9745765358) |
| **In Frame** | No | "[🎃] FrameD! 🎨 Draw with Friends" (38); "Framed!" (0 playing; 244,982 / 71,415), old and dead; "[⚡] Frame Perfect" (0), dead; "FRAMEBREAK [BETA]" (349) | **Free** | [omni "In Frame"](https://apis.roblox.com/search-api/omni-search?searchQuery=In%20Frame&sessionId=1&pageType=all) |
| **Blackout** | Yes, partial | **"Blackout: Revival [FREE ZOMBIES]"** (group **Blackout District**): 155 playing (games API); 75,700,702 visits; created Feb 2022; updated Nov 3, 2026; 114,185 / 19,428 (85.5%); **active** zombie shooter. Dead small ones: "Survive the Blackout ⚡️" (0), "Blackout \| новый" (0), "BLACKOUT - ESCAPE THE HOUSE" (0) | **Taken** (active game with a large visit history) | [omni "Blackout"](https://apis.roblox.com/search-api/omni-search?searchQuery=Blackout&sessionId=1&pageType=all); [games API](https://games.roblox.com/v1/games?universeIds=10231960870,9885372266,3326279937,4523856444,7521520342) |
| **Night Crew** | **Yes, exact** | **"Night Crew"** (group **Evil Twin Games**): 53 playing (games API); 6,480,498 visits; 101,245 favorites; max 45 players; Survival; created May 27, 2026; updated **Nov 2, 2026**; 23,576 / 1,234 (95.0%). "Crews travel to dimensions overrun by paranormal entities to collect anomalies, evade threats, and close the rift." Also "MIDNIGHT CREW [HORROR]" (55; created recently) | **Taken** (exact title, active co-op horror) | [omni "Night Crew"](https://apis.roblox.com/search-api/omni-search?searchQuery=Night%20Crew&sessionId=1&pageType=all); [games API](https://games.roblox.com/v1/games?universeIds=10231960870,9885372266,3326279937,4523856444,7521520342) |

### Inferences

- **Best-placed names:**
  - **"Stay on Camera"** and **"Stay on Camera or Die"**: no title conflict, the rule is in the name, and the second plugs into a format that is still growing.
  - **"Don't Leave the Frame"**: no conflict.

  "Blind Spot" is free as a title. But Roblox's search fuzzes "Blind Spot" to "Blind Shot" (an active game with 677K likes and many spin-offs). Players typing the name may land on Blind Shot clones, and the thumbnail and SEO would compete with a shooter niche.
- **"The Unseen" as a monster name** inside the game is probably fine. As a *title* it would sit next to "Unseen Liminality / The Unseen Zone" (about 100M visits, active horror) and invite confusion.
- **"REC" has no Roblox conflict,** but it is a generic word that search surrounds with movie and video games. It also shares its name with the [REC] horror film franchise. That is general knowledge; I did not check trademarks, so it is **unverified** as a legal risk.
- **"Night Crew" and "Blackout" should be dropped.** Night Crew is an exact, recently created and actively updated horror game. Blackout is an established active game.
- **Roblox does not enforce unique titles,** so "free" here means "no visible active game uses it", not legal or platform exclusivity.

### Gaps

- Omni-search returns the top ~40 results ranked by relevance and popularity. Low-player or private games with identical titles beyond those results were not enumerated.
- I did not check trademarks (USPTO or CIPO) for any candidate, so their legal status is **unverified**.
- I did not check Roblox group names or usernames matching the candidates (relevant if a matching group name is wanted).
- I did not check name collisions outside Roblox (Steam, mobile stores).

## 4. Has anyone remade or adapted Nicky Case's "Nothing to Hide"?

### Takeaway

I found **no remake or adaptation** of Nothing to Hide's "stay in view of the cameras" anti-stealth mechanic on Roblox, itch.io or Steam. The closest neighbours either share only the name, flip the rule (hide *from* cameras), or are CCTV-watching observation horror. Source-code mirrors and a translation repo appear to exist (seen in search results only, **unverified**).

### Cited Findings

- **The original:**
  - Nicky Case's "anti-stealth game." The art and code are "completely open and dedicated to the public domain" (CC0).
  - It was crowdfunded with a piece-by-piece pledge model, with 10% going to the EFF, Demand Progress and the Freedom of the Press Foundation.
  - A playable demo was released for The Day We Fight Back.

  Source: [Opensource.com, Feb 27, 2014](https://opensource.com/life/14/2/nothing-to-hide-anti-stealth-game). Wikipedia's disambiguation page lists it as a "2013 video game prototype" by Nicky Case — [Wikipedia](https://en.wikipedia.org/wiki/Nothing_to_Hide). A Popular Science headline describes it as an "anti-stealth game [where] you make sure you're always watched" (headline seen in search results; article not fetched) — [PopSci](https://www.popsci.com/article/gadgets/anti-stealth-game-you-make-sure-youre-always-watched/)
- **Roblox:** a search for "Nothing to Hide" returns only generic hide-and-seek games (Mega Hide and Seek!, Hide or OOF!, HIDE VS DRONE, Paint and Hide!, etc.). None is titled "Nothing to Hide" or uses a stay-visible rule — [omni-search "Nothing to Hide"](https://apis.roblox.com/search-api/omni-search?searchQuery=Nothing%20to%20Hide&sessionId=1&pageType=all)
- **Roblox camera-mechanic neighbours,** none of which is a Nothing to Hide adaptation:
  - "📸 Hide from Camera or Die!": stay *out of* the camera's view, the inverse rule — [games API](https://games.roblox.com/v1/games?universeIds=10764794065)
  - "👀 Look Away!": being in a hunter's view cone turns you to stone — [games API](https://games.roblox.com/v1/games?universeIds=10771421858,10767825538,10770728771,10769902948,9745765358)
- **itch.io:**
  - "Nothing To Hide" by HolyPerceval is an **unrelated** Ludum Dare 47 prototype (hide an item from police drones; tagged Stealth; no mention of Nicky Case) — [itch.io](https://holyperceval.itch.io/nothing-to-hide)
  - "Counter Stealth" (TimberRoar, a university final-year project) aims at "the idea of an anti-stealth game," but you *play the guards*. It has no stay-visible rule and does not mention Nicky Case — [itch.io](https://timberroar.itch.io/counter-stealth)
  - "I See Me?" (Mi1 and Yukimura Creations): you see only through cameras and must *avoid* being filmed. It does not mention Nicky Case — [itch.io](https://mi111.itch.io/i-see-me)
- **Steam:**
  - "Within His View" (Darksteady. Studio, planned Oct 28, 2026) is CCTV observation horror. Audio plays only from the feed you have open, so an unwatched room "effectively doesn't exist", while a Wendigo advances when you look away. There is no reference to Nicky Case — [Steam](https://store.steampowered.com/app/4190900)
  - "Silent Surveillance" (Oct 11, 2024) is camera-feed anomaly horror with no stay-visible rule — [Steam](https://store.steampowered.com/app/3249120)
- **Source mirrors and translation:** search results list a Gitee repository "cmx/nothing-to-hide" and a GitHub "nothing-to-hide-i18n" translation file. These look like mirrors or translations of the original source, not new games. **Not fetched, unverified** — [Gitee](https://gitee.com/cmx/nothing-to-hide); [GitHub i18n](https://raw.github.com/valioDOTch/nothing-to-hide-i18n/master/code/FINAL/locales/translation-en.json)

### Inferences

- **The rule appears unclaimed in a horror, multiplayer, Roblox context:** "you are safe only while a camera sees you; the monster exists only in blind spots." The nearest Roblox title uses the opposite rule, which helps BLIND SPOT stand out but also invites comparison.
- **Because the original is CC0, adapting its mechanic carries no licence issue.** Crediting Nicky Case is optional but good practice. This rests on the Opensource.com description of the CC0 dedication.

### Gaps

- I did not run an exhaustive Steam or itch.io search (many Steam results returned no titles, and only two were checked). There may be an obscure adaptation I missed.
- I did not check the Gitee and GitHub repositories' contents, or GitHub forks of the original repo (`ncase/nothing-to-hide`) that might be playable remakes.
- I checked no mobile stores or other UGC platforms (Fortnite UEFN, Rec Room).
