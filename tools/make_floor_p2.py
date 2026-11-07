"""Writes the P2 config (content/map_p2.csv, cameras_p2.csv, spots_p2.csv, signs_p2.csv) from the P3's, in P3's local
coordinates (floors.csv moves it). Plan section 5: "Le P2 et le P3 sont presque identiques, à trois détails près".
The P2 has no guard cabin (the post is on P1), and its three details are:
  1. a car left across the aisle near the east end (it breaks the east aisle camera's view: a new blind spot);
  2. the north row's east tubes are dead (a dark stretch even in LIVE);
  3. crates stacked in the south west stalls (a hiding place, for him).
Run after editing the P3 files:  py -I tools/make_floor_p2.py   (then py scripts/make_config.py)
"""

import csv
import io
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "content")

CABIN = {"BoothE", "BoothS", "BoothDesk", "BoothLamp", "Spawn", "LockerBlock"}
CABIN_CAMS = {"C01", "C02"}


def read(name):
    with open(os.path.join(CONTENT, name), encoding="utf-8", newline="") as f:
        r = csv.DictReader(f)
        return r.fieldnames, list(r)


def write(name, fields, rows):
    out = io.StringIO(newline="")
    w = csv.DictWriter(out, fieldnames=fields, lineterminator="\n")
    w.writeheader()
    for row in rows:
        w.writerow(row)
    with open(os.path.join(CONTENT, name), "w", encoding="utf-8", newline="\n") as f:
        f.write(out.getvalue())
    print(name, len(rows), "rows")


def cam_id(old):
    return "C" + str(int(old[1:]) + 20)


fields, rows = read("map_p3.csv")
out = []
for r in rows:
    if r["id"] in CABIN:
        continue
    r = dict(r)
    r["id"] = "P2_" + r["id"]
    if r["id"] == "P2_TubeN":
        r["count"] = "2"  # detail 2: the east half of the north row's tubes are dead
        r["note"] = "P2: only the west half of the north row is lit"
    out.append(r)
blank = {k: "" for k in fields}
out.append({**blank, "id": "P2_CarAisle", "kind": "car", "x": "30", "y": "2.5", "z": "5", "sx": "15", "sy": "5",
            "sz": "6.5", "count": "1", "step_x": "0", "occludes": "1", "blocks": "1",
            "note": "P2 detail 1: a car left across the aisle"})
out.append({**blank, "id": "P2_Crates", "kind": "crates", "x": "-48", "y": "2.5", "z": "-25", "sx": "7", "sy": "5",
            "sz": "9", "count": "1", "step_x": "0", "occludes": "1", "blocks": "1",
            "note": "P2 detail 3: crates in the south west stalls"})
write("map_p2.csv", fields, out)

fields, rows = read("cameras.csv")
out = []
for r in rows:
    if r["id"] in CABIN_CAMS:
        continue
    r = dict(r)
    r["id"] = cam_id(r["id"])
    r["zone"] = "P2-" + r["zone"]
    out.append(r)
write("cameras_p2.csv", fields, out)

fields, rows = read("spots.csv")
out = []
for r in rows:
    if r["kind"] in ("checkpoint", "collect", "stairs"):
        r = dict(r)
        r["id"] = "P2_" + r["id"]
        if r["kind"] == "checkpoint":
            r["label"] = "P2 " + r["label"]
        out.append(r)
write("spots_p2.csv", fields, out)

fields, rows = read("signs.csv")
out = []
for r in rows:
    if r["id"] in ("Security", "Booth"):
        continue
    r = dict(r)
    r["id"] = "P2_" + r["id"]
    r["text"] = r["text"].replace("P3", "P2")
    out.append(r)
write("signs_p2.csv", fields, out)
