# Camera- and surveillance-based horror games on Roblox (vs. BLIND SPOT)

Read date for all live numbers: **November 4, 2026** (Roblox omni-search API, several reads within about an hour; counts moved by a few percent between reads, so ranges are given). Closeness to BLIND SPOT is scored 0–3: **0** = unrelated or just the word "camera"; **1** = shares the setting (cameras as a monitor, night shift, found footage); **2** = shares a core lever (a camera or someone's gaze decides survival, or a camera role protects a teammate); **3** = same core loop (being in a camera's view keeps you safe, blind spots kill). **No game scored 3.**

Data-quality warnings, for the report writer:
- The single-ID `games.roblox.com/v1/games` endpoint returned **stale snapshots** for some games. Examples: Airport Security showed 177,994 visits and 180 playing ([games API](https://games.roblox.com/v1/games?universeIds=10768761562)), while rotrends showed 7.4M visits and 5,781 CCU ([rotrends](https://www.rotrends.com/game/10768761562/airport-security-anomaly)); Anomaly Detected showed 1,674,554 visits and 3,320 playing ([games API](https://games.roblox.com/v1/games?universeIds=10391036163)) against 10.9M visits and 469 CCU on rotrends ([rotrends](https://www.rotrends.com/game/10391036163/anomaly-detected)). Use games-API **visits/playing as lower bounds or past values**; its **created dates and descriptions** are reliable. Rotrends figures are used where fetched.
- Multi-ID requests to `games.roblox.com` were refused (client error); only single IDs worked. Direct `curl` to `apis.roblox.com` was blocked by the sandbox proxy, so everything went through WebFetch.
- One search read ("ghost hunting") returned numbers that disagree with every other read (e.g. Animal Hospital 74,426 players vs 16,010–16,036 elsewhere; Demonology 7,813 vs 3,012), so that read looks cached; its numbers are not used for current counts ([ghost hunting search](https://apis.roblox.com/search-api/omni-search?searchQuery=ghost%20hunting&sessionId=2&pageType=all) vs [demonology search](https://apis.roblox.com/search-api/omni-search?searchQuery=demonology&sessionId=14&pageType=all)).
- Developer user accounts are described as "solo dev (user account)" rather than by username, per the brief.

## FNAF-style night-shift / security-guard games where you watch cameras: which are biggest now?

### Takeaway
The classic FNAF "sit in the office and flip cameras" genre is large but old and declining: the biggest live entries (FNAF: Eternal Nights ~2.2K, FNAF: Co-op ~1.3K, Residence Massacre ~960) sit at 1–2K players with 90%+ ratings, while 2026's growth has moved to "visitor judging" games where a door camera is one tool (Home Alone: Anomalies, Keep the Door Locked). In all of them the camera is a **monitor** (information), never a shield.

### Cited Findings
**Biggest FNAF / security-office games now (players on Nov 4, 2026; up/down votes; like ratio)**
- **FNAF: Eternal Nights 🍕** (universe 4053293514, place 11392373641): 2,207 players; 245,005 up / 14,651 down (94.4%) — [fnaf search](https://apis.roblox.com/search-api/omni-search?searchQuery=fnaf&sessionId=4&pageType=all). Description, dates and camera use not fetched (gap).
- **FNAF: Co-op** (4391829435 / 12495498157): 1,284 players; 354,999 up / 21,544 down (94.3%) — [fnaf search](https://apis.roblox.com/search-api/omni-search?searchQuery=fnaf&sessionId=4&pageType=all). Group "Z0KTAR's Community Group" (verified); created 2023-02-15; last updated 2026-05-02; max 50 per server; 390,515,992 visits and 4,259,630 favorites at the API snapshot — [games API](https://games.roblox.com/v1/games?universeIds=4391829435).
  - Mechanic per description: survive the nights in the pizzeria "with a friend" until dawn. Player-controlled animatronics are announced as "coming soon" — [games API](https://games.roblox.com/v1/games?universeIds=4391829435). The description does not mention cameras.
- **[🎃] Residence Massacre** (4987467534 / 14437001043): 964 players; 148,781 up / 13,778 down (91.5%) — [residence massacre search](https://apis.roblox.com/search-api/omni-search?searchQuery=residence%20massacre&sessionId=11&pageType=all).
  - Cameras: there are 3 to turn on before sunset. You turn on the radio first, then carry a ladder to place each one. They are "an important tool to help you survive the night" and must be up "before the monster arrives at 12 am" — [Gamezebo](https://www.gamezebo.com/walkthroughs/residence-massacre-cameras/). The guide does not say *how* they help (deterrent or just a monitor).
- **Animatronic Nights [NEW]** (6011188518 / 17559596992): 289–299 players; 138,774 / 9,131 (93.8%) — [night guard search](https://apis.roblox.com/search-api/omni-search?searchQuery=night%20guard&sessionId=1&pageType=all).
- **The Intruder** (3109731140 / 8073154099): 77–102 players; 244,045 / 29,957 (89.1%) — [security camera search](https://apis.roblox.com/search-api/omni-search?searchQuery=security%20camera&sessionId=1&pageType=all). Made by a solo dev (verified user account); created 2021-11-22; updated 2026-04-16; max 30; 463,073,991 visits — [games API](https://games.roblox.com/v1/games?universeIds=3109731140).
  - Mechanic: a phone call warns that a criminal is targeting you. You "monitor your room's security cameras to track him"; if he enters you hide in the closet with the lights off and wait for the phone to come back — [games API](https://games.roblox.com/v1/games?universeIds=3109731140). Inspired by FNAF and The Mandela Catalogue (same source).
- **[P2] The Night Shift Experience** (4507204989 / 12877981041): 32 players; 108,758 / 12,723 (89.5%) — [night guard search](https://apis.roblox.com/search-api/omni-search?searchQuery=night%20guard&sessionId=1&pageType=all).
- **[CO-OP] Five Nights At Your Friends** (2515205133 / 6677423742): 26 players; 68,018 / 3,637 (94.9%) — [fnaf search](https://apis.roblox.com/search-api/omni-search?searchQuery=fnaf&sessionId=4&pageType=all).
- **Ultimate Custom Night** (4810175915): 48 players; 15,576 / 2,655 (85.4%). **Five Nights at Freddy's** (7079106954): 38 players; 5,474 / 758 (87.8%) — [fnaf search](https://apis.roblox.com/search-api/omni-search?searchQuery=fnaf&sessionId=4&pageType=all).
- **Night Watch** (4861126364 / 14034683097): 0 players; 22,477 / 2,111 (91.4%) — [night guard search](https://apis.roblox.com/search-api/omni-search?searchQuery=night%20guard&sessionId=1&pageType=all).
  - You are the "guardian angel" of a family and watch over them; created 2023-07-11; updated 2026-05-31; 4,167,933 visits; max 23 — [games API](https://games.roblox.com/v1/games?universeIds=4861126364). The description does not mention cameras. This is a thematic cousin of "watching keeps people safe", but the mechanic is unverified.
- **Security-guard simulators** (cameras not verified): Security Guard Simulator (4798233640), 17 players, 13,692 / 6,969 (66.3%); Mall Security Simulator (5082567812), 19 players, 76,739 / 6,270 (92.4%) — [security camera search](https://apis.roblox.com/search-api/omni-search?searchQuery=security%20camera&sessionId=1&pageType=all).
- **The "Secure the X" wave (2026)**: Secure the Airport (9912025777), 977 players, 181,580 / 13,296 (93.2%); Secure the Waterpark (10768949861), 2,093 players, 1,529 / 305; Secure the Prison (10621542040), 630 players, 10,206 / 1,154; plus Supermarket, Hospital, Jail, Border, School, Bank, Castle and others — [security office search](https://apis.roblox.com/search-api/omni-search?searchQuery=security%20office&sessionId=7&pageType=all). Their camera use was not checked.

**Door-visitor games with a camera (the 2026 hit format)**
- **Home Alone: Anomalies** (10123059921 / 87468080405188), by the group "3 AM Productions & Freeground":
  - Live: 1,742–1,765 players; 196,544 up / 11,059 down — [observation duty search](https://apis.roblox.com/search-api/omni-search?searchQuery=observation%20duty&sessionId=6&pageType=all).
  - Rotrends: 1,774 CCU, **25.1K peak CCU**, **232.1M visits**, 639K favorites, 94.67% rating; created May 4, 2026; last updated Oct 31, 2026 — [rotrends](https://www.rotrends.com/game/10123059921/home-alone-anomalies).
  - Mechanic: visitors come to the door and some aren't who they claim to be. You "check the cameras to monitor who is at the door", listen to them, open the door for those who need help, turn the porch light off when something is wrong, and can prank friends with jumpscare items; max 18 per server — [games API](https://games.roblox.com/v1/games?universeIds=10123059921).
- **Keep the Door Locked🔒[UPDATE]** (10232686472 / 124338404742585), by the verified group "Hotel Room Services":
  - Live: 1,101 players; 66,113 / 6,560 (91.0%) — [security camera search](https://apis.roblox.com/search-api/omni-search?searchQuery=security%20camera&sessionId=1&pageType=all).
  - Created 2026-05-28; max 20; 77.1M visits at the API snapshot — [games API](https://games.roblox.com/v1/games?universeIds=10232686472).
  - Mechanic: alone in a hotel room after midnight, you "watch the cameras, follow the rules, and decide who gets inside" — [games API](https://games.roblox.com/v1/games?universeIds=10232686472). A guide says you "use the feeds to size up whoever is on the other side of the door" and that "the wrong person getting past the threshold can be fatal". It presents the cameras as an information tool, not a defense — [allthings.how](https://allthings.how/?p=103837).

### Inferences
- FNAF-likes have high ratings but low live counts (hundreds to about 2K). The proven camera-monitoring audience on Roblox has migrated to short "judge what you see" anomaly and visitor games with cheap production.
- No security-office game found uses the camera as **protection**. Cameras supply information (who's there, where the threat is), and survival comes from a separate action (door, closet, light). BLIND SPOT's inversion, where the frame itself is the safe zone, is not present in this family.
- FNAF: Co-op's announced "player-controlled animatronics" is the nearest FNAF-family hint of an asymmetric PvP mode like BLIND SPOT's Unseen-player mode. It is still listed as "coming soon".

### Gaps
- Camera mechanics of FNAF: Eternal Nights, FNAF: Co-op, Animatronic Nights and the "Secure the X" series were not verified (descriptions don't cover them; no gameplay source fetched).
- How Residence Massacre's cameras protect you (deterrent, warning, or monitor) is not explained by the guide found.
- Created/updated dates and visits for FNAF: Eternal Nights, Animatronic Nights and Residence Massacre were not fetched.

## "Observation Duty" / anomaly-spotting camera games: how do they play, and are cameras protective or just a monitor?

### Takeaway
Anomaly spotting on CCTV is one of Roblox's hottest 2026 formats (Anomaly Detected peaked at 11.3K CCU, Airport Security at 14K within weeks of launch). In every verified case the camera is a **monitor**: you memorize the feed, spot and report changes, and lose when too many slip by. None makes being on camera a safe state.

### Cited Findings
- **[🎃] Anomaly Detected** (10391036163 / 126096010539917), by a solo dev (user account); the game page points to an "X Core Studios" group for updates:
  - Live: 461–470 players; 20,671 up / 2,769 down (88.2%) — [security camera search](https://apis.roblox.com/search-api/omni-search?searchQuery=security%20camera&sessionId=1&pageType=all).
  - Rotrends: 469 CCU, **11.3K peak**, 10.9M visits, 205.6K favorites; created Jun 25, 2026; updated Oct 1, 2026 — [rotrends](https://www.rotrends.com/game/10391036163/anomaly-detected). Max 8 per server — [games API](https://games.roblox.com/v1/games?universeIds=10391036163).
  - Mechanic: "Memorize every room, spot anomalies, and report them before whatever lurks in the shadows notices you"; anomalies are spotted in surveillance feeds; missing too many ends your shift for good; solo or co-op — [Roblox game page](https://www.roblox.com/games/126096010539917). Tags include found footage and psychological horror (same source).
  - Cameras: monitor only.
- **[🎃] Airport Security (Anomaly) ✈️** (10768761562 / 108334808788078), by the group "Hollow Creek Airport":
  - Live: 5,881–5,980 players; 12,844 / 980 (92.9%) — [security camera search](https://apis.roblox.com/search-api/omni-search?searchQuery=security%20camera&sessionId=1&pageType=all), [cctv search](https://apis.roblox.com/search-api/omni-search?searchQuery=cctv&sessionId=1&pageType=all).
  - Rotrends: 5,781 CCU, **14K peak**, 7.4M visits, 97K favorites, 92.91%; created Sep 30, 2026; updated Oct 7, 2026 (rotrends) vs Oct 13 (games API, conflicting) — [rotrends](https://www.rotrends.com/game/10768761562/airport-security-anomaly).
  - Mechanic: a "Papers, Please"-style checkpoint. You check IDs and photos, X-ray luggage and body-scan travelers; "Some passengers aren't human. Let one through and it won't board the plane... it will hunt you." You "monitor the camera feeds" to catch details. Other tools: lie detector, brain scan, eye exam, fingerprint test.
  - Players and events: solo or with up to 4 friends; you can tase coworkers or monsters. Shifts are endless, with events such as emergency landings, ghosts, lockdowns and a returning serial killer. There is no health bar: you "crash out" if too scared — [games API](https://games.roblox.com/v1/games?universeIds=10768761562).
  - Cameras: monitor only.
- **Observation Duty [5 PLAYERS SUPPORT]** (2855362296 / 7316593979), by a solo dev (user account):
  - Live: 0 players in the search read (games API snapshot: 1); 6,833 / 1,628 (80.8%) — [observation duty search](https://apis.roblox.com/search-api/omni-search?searchQuery=observation%20duty&sessionId=6&pageType=all).
  - Created 2021-08-24; updated 2026-01-11; 5,370,085 visits; 68,660 favorites; max 20 — [games API](https://games.roblox.com/v1/games?universeIds=2855362296).
  - Mechanic: based on "I'm on Observation Duty". You report anomalies and survive 6 in-game hours, in groups of up to 5 (same source). **Dead** (0–2 players).
- **[CHURCH] Anomaly Watch** (5421898784 / 15694887572), by the group "Bachibo":
  - Live: 24 players; 39,268 / 5,816 (87.1%) — [cctv search](https://apis.roblox.com/search-api/omni-search?searchQuery=cctv&sessionId=1&pageType=all).
  - Created 2023-12-20; last updated 2025-09-28; 34,489,845 visits; max 28 — [games API](https://games.roblox.com/v1/games?universeIds=5421898784).
  - Mechanic: inspired by The Mandela Catalogue and I'm On Observation Duty. In a rural house, objects go missing or distort and humanoids appear; you report them with a tablet and survive until 6 AM. The description does not mention cameras (same source). Nearly dead.
- **Home Alone: Anomalies** and **Keep the Door Locked**: see the previous section (door-camera monitor). Both are big, with 232.1M and roughly 77M visits respectively.
- **Small or new anomaly-camera titles** (not analyzed) — [observation duty search](https://apis.roblox.com/search-api/omni-search?searchQuery=observation%20duty&sessionId=6&pageType=all):
  - Discrepancy 🎃 (9490944126): 0 players; 1,933 / 681.
  - Hotel Night Shift (Anomaly) 🎃 (10765506686): 22 players; 124 / 36.
  - [🎃] Night Duty [HORROR] (10765444225): 4 players; 57 / 19.
  - Midnight Shift (Anomaly) ⛽ (10621093890): 241 players; 1,858 / 357.
  - Night At The Infirmary (Anomaly) (9585346472): 545 players; 47,519 / 5,447.
- **"Anomaly" genre giants, for context** (camera use not verified):
  - Animal Hospital (Anomaly) 🧪 (10148749921): 16,010–16,036 players; 1,347,130 / 102,933 (92.9%) — [security camera search](https://apis.roblox.com/search-api/omni-search?searchQuery=security%20camera&sessionId=1&pageType=all).
  - [CH2] Sell Fries! [Anomaly] 🍟 (10767380385): 24,306–24,821 players; 38,696 / 6,972 — [night guard search](https://apis.roblox.com/search-api/omni-search?searchQuery=night%20guard&sessionId=1&pageType=all).
  - Clone Baby Care (Anomaly) (10770018231): 11,254 players; 12,562 / 1,408 — [observation duty search](https://apis.roblox.com/search-api/omni-search?searchQuery=observation%20duty&sessionId=6&pageType=all).

### Inferences
- The camera-anomaly format proves Roblox players will happily stare at CCTV feeds in co-op horror. It is the audience BLIND SPOT would draw from. But the format is "spot and report" (a memory and perception test). BLIND SPOT's "move into a frame or die" is a different, movement-based verb.
- Airport Security went from launch (Sep 30) to a 14K peak and 7.4M visits in about five weeks. The "(Anomaly)" tag plus a CCTV/inspection job is currently a strong discovery hook. BLIND SPOT could borrow the vocabulary (shifts, feeds, "REC") without copying the loop.
- None of these lets dead players act. A missed anomaly ends the shift.

### Gaps
- How Anomaly Detected's co-op splits work (who watches which feed) was not verified; descriptions are short and no gameplay video was checked.
- Whether Animal Hospital (Anomaly) uses cameras at all was not verified.

## Handheld camcorder / found-footage / night-vision / ghost-hunting games: does any use a battery camera as a protective tool?

### Takeaway
None verified. Handheld cameras on Roblox are either **evidence tools** (Demonology's video camera reveals Ghost Orbs), **content-creation goals** (Scream Stream, "keep the cameras rolling", Content Warning-style), **recording premises** (ANALOG, UNRECORDED), or a **visual style** for shooters (PARACAM, Hypercam, BODYCAM). The closest "looking protects you" mechanic is PERIPHERAL, where the creature retreats when you look back at it and light (with a battery) is your ally. It has no camera.

### Cited Findings
- **[🎃] Demonology🕯️** (6170143659 / 18199615050): 3,012 players; 360,795 up / 16,687 down (95.6%) — [demonology search](https://apis.roblox.com/search-api/omni-search?searchQuery=demonology&sessionId=14&pageType=all).
  - The Ghost Orb "only shows up through a camera, so view it through the Video Monitor". A Head-Mounted Camera worn by a teammate also works. For the Laser Projector you "point a Video Camera at the projector" — [allthings.how](https://allthings.how/demonology-evidence-types-and-how-to-confirm-each-one/). No camera protection is described (same source).
  - Camera = evidence. A teammate's head-cam feed on a shared monitor is a "watch over your teammate remotely" seed.
- **[🎃] SPECTER** (3171190217 / 8267733039), by the verified group "Lithium Labs":
  - Live: 240–241 players; 252,424 / 12,306 (95.4%) — [demonology search](https://apis.roblox.com/search-api/omni-search?searchQuery=demonology&sessionId=14&pageType=all).
  - Created 2021-12-16; updated 2026-09-02; 237,916,283 visits; max 50 — [games API](https://games.roblox.com/v1/games?universeIds=3171190217).
  - Mechanic: Phasmophobia-inspired; 15+ haunted locations; "Use hiding spots ... and carefully control your stamina to survive the hunt phase". Spirit Box and team radio use voice chat (same source). Cameras are not mentioned (unverified).
- **Blair** (2239430935 / 6137321701): 770 players; 238,425 / 20,090 (92.2%) — [demonology search](https://apis.roblox.com/search-api/omni-search?searchQuery=demonology&sessionId=14&pageType=all). Mechanic not fetched; Phasmophobia-like by reputation (**unverified**).
- **The Ghost Hunter Experience 👻** (5124598533): 5 players; 19,786 / 1,354 (from the possibly cached read) — [ghost hunting search](https://apis.roblox.com/search-api/omni-search?searchQuery=ghost%20hunting&sessionId=2&pageType=all).
- **❄️Scream Stream** (5866004245 / 17121106661), by the group "CandleLit!":
  - Live: 41–49 players; 59,772 / 8,666 (87.3%) — [camcorder search](https://apis.roblox.com/search-api/omni-search?searchQuery=camcorder&sessionId=1&pageType=all), [content warning search](https://apis.roblox.com/search-api/omni-search?searchQuery=content%20warning&sessionId=12&pageType=all).
  - Created 2024-04-13; updated 2025-12-30; 71,494,932 visits; 469,629 favorites; max 50 — [games API](https://games.roblox.com/v1/games?universeIds=5866004245).
  - Mechanic: you and friends film for "viral online success"; a divebell sends you into nightmares where you must "keep the cameras rolling". "Inspired by Content Warning" (same source). Camera = filming goal; protection not mentioned.
- **[🎃] ANALOG 📂[HORROR]** (10768800151 / 105916934349181), by the group "Kioverse Games":
  - Live: 1,250–1,280 players; 5,700 / 820 (87.4%) — [camcorder search](https://apis.roblox.com/search-api/omni-search?searchQuery=camcorder&sessionId=1&pageType=all).
  - Created 2026-10-01; updated 2026-11-03; 5,852,643 visits; 70,918 favorites; max 45 — [games API](https://games.roblox.com/v1/games?universeIds=10768800151).
  - Mechanic: you work for "an organization that doesn't exist" and must "record, report, and survive". You enter anomalous sites, collect telemetry and document the entities hunting there; "keep your camera focused and your signal clear". Inspired by the analog-horror series *I Made A Self-Aware Robot* (same source). Whether the camera protects you is **unverified**. Active and growing.
- **UNRECORDED** (10770389809 / 110766616293031), by the group "Triggurod Studios":
  - Live: 53 players; 83 / 37 (69.2%) — [camcorder search](https://apis.roblox.com/search-api/omni-search?searchQuery=camcorder&sessionId=1&pageType=all).
  - Created 2026-10-11; updated 2026-11-04; 77,789 visits; max 50 — [games API](https://games.roblox.com/v1/games?universeIds=10770389809).
  - Mechanic: escape a sealed house alone or with friends; "Someone left a camcorder behind." Vol. 01, inspired by the *Vita Carnis* web series; early development (same source). Camcorder use, battery and protection are **not described (unverified)**.
- **PERIPHERAL (BETA)** (10768473690 / 120912658283903), by the group "Cloversky Studios":
  - Live: 701–702 players; 4,609 / 1,025 (81.8%) — [camcorder search](https://apis.roblox.com/search-api/omni-search?searchQuery=camcorder&sessionId=1&pageType=all).
  - Created 2026-09-28; updated 2026-11-04; 2,494,479 visits; max 32 — [games API](https://games.roblox.com/v1/games?universeIds=10768473690).
  - Mechanic: procedurally generated facility; restore 3 generators, find a key, memorize a code and escape. A single creature "watches, waits"; "it retreats when you look back at it", but "if you stare too long, it loses patience". "Light is your main ally", so you manage your flashlight battery. When the last generator starts, the lights go red and the hunt begins. 3 lives; co-op (same source).
- **Bodycam / helmet-cam shooters** (camera = visual style, not a mechanic):
  - PARACAM (5708533287 / 16587913123, group "Mudrock Studios"): 3–6 players; 89,084 / 14,040 (86.4%); created 2024-03-02; updated 2026-10-15; 35.8M visits; a police bodycam horror shooter with squads of 4 — [games API](https://games.roblox.com/v1/games?universeIds=5708533287), [night vision search](https://apis.roblox.com/search-api/omni-search?searchQuery=night%20vision&sessionId=3&pageType=all).
  - Hypercam (6267943144, group "HYPERCAM"): 41–47 players; 23,688 / 9,576 (71.2%); created 2024-07-15; a tactical shooter "inspired by Unrecord and Bodycam" — [games API](https://games.roblox.com/v1/games?universeIds=6267943144).
  - BODYCAM (10766826976): 3 players; 4,906 / 6,695 (42.3%). BODYCAM: SWAT Simulator (5654670037): 190–222 players; 130,809 / 25,133 — [security camera search](https://apis.roblox.com/search-api/omni-search?searchQuery=security%20camera&sessionId=1&pageType=all).
- **Found-footage / backrooms**: "Rooms: Found Footage: RENOVATED" (7288050875), 16 players, 1,770 / 298; the rest of the "found footage" results are Backrooms or "Find the X" games with no camera mechanic — [found footage search](https://apis.roblox.com/search-api/omni-search?searchQuery=found%20footage&sessionId=1&pageType=all).

### Inferences
- The "battery camcorder that keeps a teammate safe while you point it at them" is unclaimed on Roblox as far as this search shows. The nearest analogues are Demonology's head-cam (a teammate's view on a monitor) and PERIPHERAL's look-to-repel plus flashlight battery. PERIPHERAL shows the look-to-repel idea already draws ~700 CCU in beta.
- 2026's analog-horror wave (ANALOG, UNRECORDED, Anomaly Detected's found-footage tag) means the VHS/REC look is fashionable but getting crowded. BLIND SPOT's differentiator must be the protective rule, not the aesthetic.

### Gaps
- No gameplay video or guide was checked for UNRECORDED, ANALOG, Scream Stream or Blair. Their camera mechanics (battery, protective effect) remain **unverified**.
- SPECTER's equipment list (whether it has video cameras) was not verified.

## Any game where spectators or dead players control cameras, lights or doors to help the living?

### Takeaway
No Roblox game found lets dead or spectating players run cameras, lights or doors **to help** survivors. The nearest cases are opposites or partial versions: Hide from Camera or Die lets eliminated players "spectate and troll" (hinder) the living; Be My Camera gives a *living* player a camera role that protects a partner; Be an Anomaly or Guard swaps a player into a monster role when one falls.

### Cited Findings
- **📸 Hide from Camera or Die! 💀**: "Eliminated players can spectate and troll the remaining players" — [games API](https://games.roblox.com/v1/games?universeIds=10764794065). Full entry in the last section.
- **Be My Camera [2 Player Obby]** (7145230420 / 95205997597502), by the verified group "Obby Republic":
  - Live: 281–294 players; 6,376 / 4,620 (58.0%) — [security camera search](https://apis.roblox.com/search-api/omni-search?searchQuery=security%20camera&sessionId=1&pageType=all), [camcorder search](https://apis.roblox.com/search-api/omni-search?searchQuery=camcorder&sessionId=1&pageType=all).
  - Created 2025-01-25; updated 2026-09-21; **52,938,322 visits**; 1,058,638 favorites; max 15 — [games API](https://games.roblox.com/v1/games?universeIds=7145230420).
  - Mechanic: one player is the jumper and the other the camera operator, who "has a full view of the map, watches for danger, and fights off evil drones with lasers to protect the jumper" (same source).
- **[BACKROOMS] Be an Anomaly or Guard** (9890892152 / 137539410262731), by the verified group "icce":
  - Live: 29 players; 17,139 / 6,098 (73.8%) — [observation duty search](https://apis.roblox.com/search-api/omni-search?searchQuery=observation%20duty&sessionId=6&pageType=all).
  - Created 2026-03-16; updated 2026-07-13; 11,681,245 visits; max 45 — [games API](https://games.roblox.com/v1/games?universeIds=9890892152).
  - Mechanic: players are Guards or a player-controlled Anomaly (SCP-173, The Locust, Ao Oni and others); "If an Anomaly falls, another player is selected to take its place". No cameras mentioned (same source).
- **FNAF: Co-op** announces player-controlled animatronics as "coming soon" — [games API](https://games.roblox.com/v1/games?universeIds=4391829435).
- A targeted web search for Roblox games where spectators control cameras or doors returned only DevForum scripting threads about generic spectate systems, not a game with this mechanic — [DevForum: How to make a spectate](https://devforum.roblox.com/t/how-to-make-a-spectate/606352), [DevForum: Help With Spectating System](https://devforum.roblox.com/t/help-with-spectating-system/3046350).

### Inferences
- "Dead players become the security desk" looks like an open niche on Roblox. It also addresses a known weakness of round-based horror (dead players idle until the next round). Hide from Camera or Die's "spectate and troll" shows Roblox designers already give dead players something to do, but adversarially.
- Be My Camera's 52.9M visits show the "one player is the camera that protects the other" duo role is understood and popular. Its 58% rating suggests the execution, not the idea, is weak (inference; no reviews read).

### Gaps
- Web search results for this question were dominated by SEO spam domains, so a game with this mechanic could exist and be missed. Popular asymmetric games (e.g. Piggy, Flee the Facility, DOORS) were not checked for spectator features.

## "Cameraman" genre and camera-photo games

### Takeaway
On Roblox, "Cameraman" means the **Skibidi Toilet** fandom (fighting toilets), not a camera mechanic. The biggest is Cameraman Tower Defense at ~41.8K players. The lead game "Cameraman" (15022850780) is a small PvP toilet-fighting game with 19 players. Photo/camera games are mostly obbies and puzzles; **Say Cheese! [STORY]** (new, ~9.6K players) was noted but not researched, per the brief.

### Cited Findings
- **Cameraman** (5173296366 / 15022850780), by the group "Mozeraid GAMES!":
  - Live: 19 players; 759 up / 573 down (57.0%) — [cameraman search](https://apis.roblox.com/search-api/omni-search?searchQuery=cameraman&sessionId=5&pageType=all).
  - Created 2023-10-10; updated 2026-10-17; 18,510,485 visits; 1,230,924 favorites; max 14 — [games API](https://games.roblox.com/v1/games?universeIds=5173296366).
  - Mechanic: equip gear and fight evil toilets, with PvP and a no-PvP world (same source). Closeness 0.
  - Oddity: 1.23M favorites against only 1,332 total votes is inconsistent. The cause is unknown (possibly a vote reset); **unverified**.
- **[🌟UPD] Cameraman Tower Defense** (10762636904 / 132929771812494): 41,829 players; 247,955–248,000 / 3,728–3,735 (98.5%) — [cameraman search](https://apis.roblox.com/search-api/omni-search?searchQuery=cameraman&sessionId=5&pageType=all). A Skibidi-themed tower defense game. Closeness 0.
- Other camera-named games (not camera horror):
  - [UPD20+] Cam Conqueror (5086129645): 22 players; 26,255 / 4,917.
  - Camera Swap! 📸 [2 Player Obby] (5151260562): 0 players; 1,255 / 354.
  - VIEWFINDER but in roblox (6921771391): 310 players; 7,616 / 540.
  - Sources: [cameraman search](https://apis.roblox.com/search-api/omni-search?searchQuery=cameraman&sessionId=5&pageType=all), [camcorder search](https://apis.roblox.com/search-api/omni-search?searchQuery=camcorder&sessionId=1&pageType=all).
- **📸 Say Cheese! [STORY]** (10771871836 / 100453542816833): 9,600 players; 28,252 / 3,032 (90.3%) — [say cheese search](https://apis.roblox.com/search-api/omni-search?searchQuery=say%20cheese&sessionId=13&pageType=all). Not researched. Per the brief, it is a story game about a camera based on Nicky Case's "We Become What We Behold".

### Inferences
- A title or icon built around "Cameraman" would collide with Skibidi search traffic. Avoid it as a keyword.
- Say Cheese!'s ~9.6K players for a Nicky Case adaptation (a recent universe ID) shows Nicky Case-derived camera concepts can draw a crowd on Roblox right now. That is relevant because BLIND SPOT's rule comes from Case's "Nothing to Hide" (inference from the player count only).

### Gaps
- Say Cheese!'s dates, developer and mechanic were deliberately not researched.

## Per-game summary: stats and closeness to BLIND SPOT (0–3)

### Takeaway
The only games scoring 2 are **Hide from Camera or Die!** (the same lever, a camera's field of view deciding life or death in rounds, but **inverted**: the camera kills) and **Be My Camera** (a camera-operator role that protects a teammate). Nothing on Roblox was found where **being in a camera's view is the safe zone** or where **dead players run the cameras**, so BLIND SPOT's core loop appears unclaimed on Roblox as of Nov 4, 2026.

### Cited Findings
**Hide from Camera or Die!** (the inverse of BLIND SPOT), by the group "Avid Experiences":
- Universe 10764794065, place 98242614091515.
- Live: 261–266 players; 6,784 up / 5,497 down (**55.2%**) — [security camera search](https://apis.roblox.com/search-api/omni-search?searchQuery=security%20camera&sessionId=1&pageType=all).
- Rotrends: 266 CCU, **peak 5.6K**, **8.6M visits**, 381.2K favorites, 55.24%; created Sep 2, 2026; updated Sep 21, 2026 (rotrends FAQ) vs Oct 14, 2026 (games API, conflicting) — [rotrends](https://www.rotrends.com/game/10764794065/hide-from-camera-or-die).
- Mechanic: "Find a hiding spot before the camera takes a picture"; being caught in its view eliminates you. 5 rounds, with the map harder each round; win by being last standing or surviving all 5. You can slap other players. Eliminated players spectate and troll. Max 12. Inspired by Hide or Die, Hide or Oof and Spin or Die — [games API](https://games.roblox.com/v1/games?universeIds=10764794065).

**Summary table** (players and votes from the omni-search reads on Nov 4, 2026; visits, created and updated from rotrends where marked R, otherwise from the games API snapshot, which may lag)

| Game (universe / root place) | Family | Players Nov 4 | Up / Down (ratio) | Created / Updated | Visits | Camera role | Active? | Close (0–3) |
|---|---|---|---|---|---|---|---|---|
| Hide from Camera or Die! (10764794065 / 98242614091515) | Camera-hide party | 261–266 | 6,784 / 5,497 (55.2%) | 2026-09-02 / 09-21 R or 10-14 API | 8.6M R | Camera = **death** (inverse) | Yes, past its peak (5.6K) | **2** |
| Be My Camera [2 Player Obby] (7145230420 / 95205997597502) | Duo obby | 281–294 | 6,376 / 4,620 (58.0%) | 2025-01-25 / 2026-09-21 | 52.9M | Camera player **protects** jumper (lasers vs drones) | Yes | **2** |
| Anomaly Detected (10391036163 / 126096010539917) | CCTV anomaly | 461–470 | 20,671 / 2,769 (88.2%) | 2026-06-25 / 10-01 R | 10.9M R | Monitor (spot and report) | Yes (peak 11.3K) | 1 |
| Airport Security (Anomaly) (10768761562 / 108334808788078) | Checkpoint anomaly | 5,881–5,980 | 12,844 / 980 (92.9%) | 2026-09-30 / 10-07 R | 7.4M R | Monitor (feeds) | Yes, hot (peak 14K) | 1 |
| Home Alone: Anomalies (10123059921 / 87468080405188) | Door visitor | 1,742–1,765 | 196,544 / 11,059 (94.7%) | 2026-05-04 / 10-31 R | 232.1M R | Monitor (door cam) | Yes (peak 25.1K) | 1 |
| Keep the Door Locked (10232686472 / 124338404742585) | Door visitor | 1,101 | 66,113 / 6,560 (91.0%) | 2026-05-28 / 09-09 API | 77.1M API | Monitor (door cam) | Yes | 1 |
| Observation Duty [5 PLAYERS] (2855362296 / 7316593979) | CCTV anomaly | 0–2 | 6,833 / 1,628 (80.8%) | 2021-08-24 / 2026-01-11 | 5.37M API | Monitor | **Dead** | 1 |
| [CHURCH] Anomaly Watch (5421898784 / 15694887572) | Anomaly report | 24 | 39,268 / 5,816 (87.1%) | 2023-12-20 / 2025-09-28 | 34.5M API | Tablet reporter; cameras unverified | Nearly dead | 1 |
| FNAF: Co-op (4391829435 / 12495498157) | FNAF office | 1,284 | 354,999 / 21,544 (94.3%) | 2023-02-15 / 2026-05-02 | 390.5M API | Cameras inferred from genre (unverified) | Yes | 1 |
| FNAF: Eternal Nights (4053293514 / 11392373641) | FNAF office | 2,207 | 245,005 / 14,651 (94.4%) | not fetched | not fetched | Unverified | Yes | 1 |
| Residence Massacre (4987467534 / 14437001043) | Survive the night | 964 | 148,781 / 13,778 (91.5%) | not fetched | not fetched | 3 cameras to install, a "survival tool" (how is unverified) | Yes | 1 |
| The Intruder (3109731140 / 8073154099) | Home intruder | 77–102 | 244,045 / 29,957 (89.1%) | 2021-11-22 / 2026-04-16 | 463M API | Monitor (track the intruder) | Low | 1 |
| PERIPHERAL (BETA) (10768473690 / 120912658283903) | Co-op escape | 701–702 | 4,609 / 1,025 (81.8%) | 2026-09-28 / 11-04 | 2.49M API | No camera; **looking** repels the creature; flashlight battery | Yes, new | 1 |
| Demonology (6170143659 / 18199615050) | Ghost hunting | 3,012 | 360,795 / 16,687 (95.6%) | not fetched | not fetched | Evidence (Ghost Orb via camera, head-cam) | Yes | 1 |
| SPECTER (3171190217 / 8267733039) | Ghost hunting | 240–241 | 252,424 / 12,306 (95.4%) | 2021-12-16 / 2026-09-02 | 237.9M API | Unverified | Low | 0 |
| Blair (2239430935 / 6137321701) | Ghost hunting | 770 | 238,425 / 20,090 (92.2%) | not fetched | not fetched | Unverified | Yes | 0–1 (unverified) |
| ANALOG (10768800151 / 105916934349181) | Analog horror | 1,250–1,280 | 5,700 / 820 (87.4%) | 2026-10-01 / 11-03 | 5.85M API | Recording tool; protection unverified | Yes, new | 1 |
| UNRECORDED (10770389809 / 110766616293031) | Camcorder escape | 53 | 83 / 37 (69.2%) | 2026-10-11 / 11-04 | 77,789 API | Camcorder; use unverified | New, small | 1 |
| Scream Stream (5866004245 / 17121106661) | Content Warning-like | 41–49 | 59,772 / 8,666 (87.3%) | 2024-04-13 / 2025-12-30 | 71.5M API | Filming goal | Low | 1 |
| Be an Anomaly or Guard (9890892152 / 137539410262731) | PvP monster vs guards | 29 | 17,139 / 6,098 (73.8%) | 2026-03-16 / 07-13 | 11.7M API | None mentioned | Low | 1 |
| PARACAM (5708533287 / 16587913123) | Bodycam shooter | 3–6 | 89,084 / 14,040 (86.4%) | 2024-03-02 / 2026-10-15 | 35.8M API | Visual style | Nearly dead | 0 |
| Hypercam (6267943144 / 18497073993) | Bodycam shooter | 41–47 | 23,688 / 9,576 (71.2%) | 2024-07-15 / 2026-07-10 | 17.9M API | Visual style | Low | 0 |
| Cameraman (5173296366 / 15022850780) | Skibidi PvP | 19 | 759 / 573 (57.0%) | 2023-10-10 / 2026-10-17 | 18.5M API | None | Low | 0 |
| Cameraman Tower Defense (10762636904 / 132929771812494) | Skibidi TD | 41,829 | ~248,000 / ~3,735 (98.5%) | not fetched | not fetched | None | Very active | 0 |

Sources for the table: the per-game links cited in the sections above. Additional live counts come from the [security camera](https://apis.roblox.com/search-api/omni-search?searchQuery=security%20camera&sessionId=1&pageType=all), [fnaf](https://apis.roblox.com/search-api/omni-search?searchQuery=fnaf&sessionId=4&pageType=all), [demonology](https://apis.roblox.com/search-api/omni-search?searchQuery=demonology&sessionId=14&pageType=all), [camcorder](https://apis.roblox.com/search-api/omni-search?searchQuery=camcorder&sessionId=1&pageType=all) and [residence massacre](https://apis.roblox.com/search-api/omni-search?searchQuery=residence%20massacre&sessionId=11&pageType=all) searches.

**Name checks**
- A Roblox search for "blind spot" returned no game with that name. Results were "Blind Shot" shooters (e.g. [UPD] Blind Shot, 677,033 up) and hide-and-seek games — [blind spot search](https://apis.roblox.com/search-api/omni-search?searchQuery=blind%20spot&sessionId=8&pageType=all).
- "Unseen" collides with **🎃Unseen Liminality** (9885372266 / 82797688803922): 5,248 players; 168,035 / 10,926 (93.9%). It is a liminal/backrooms game, not a camera game — [unseen search](https://apis.roblox.com/search-api/omni-search?searchQuery=unseen&sessionId=10&pageType=all).

### Inferences
- **Hide from Camera or Die!** is the most important comparable. It validates the "camera field of view decides who dies, round by round" hook (8.6M visits and a 5.6K peak within weeks), but its 55% rating and quick decline suggest the shallow party version does not retain players. BLIND SPOT's inverted, cooperative and horror-paced take differs clearly. Marketing should avoid looking like a copy (e.g. a 📸 icon with "or Die").
- **Be My Camera** shows the "one player protects another through a camera" role reaches large audiences (52.9M visits). It is the closest precedent for BLIND SPOT's handheld-camcorder and dead-player camera roles.
- The biggest addressable audience is the 2026 "Anomaly" CCTV/door-camera crowd: Home Alone 232M visits and 25.1K peak; Airport Security 14K peak; Anomaly Detected 11.3K peak. These players already associate cameras with horror, but no game gives the camera a protective role.
- The "Blind Spot" name appears free in Roblox search; "the Unseen" sits next to an active game called Unseen Liminality.

### Gaps
- Current visits and dates for FNAF: Eternal Nights, Residence Massacre, Demonology, Blair and Cameraman Tower Defense were not fetched. Games-API visits for the other titles may lag (see the warnings at the top).
- No YouTube or video verification was done for any mechanic. Every mechanic above comes from the official description or a single guide, and protective effects not described there are marked unverified.
- Several titles were not opened: Discrepancy, Hotel Night Shift (Anomaly), Night Duty, Midnight Shift (Anomaly), the "Secure the X" series, Night At The Infirmary (Anomaly) and Rooms: Found Footage. A small new game with a protective-camera rule could exist among them, or outside the queries run.
