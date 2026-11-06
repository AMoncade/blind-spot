"""The P3 parking level's models (CLAUDE.md, "Blender d'abord"): the kit (Pillar, Sedan, PipeRun) and the task props
(Checkpoint, Generator, FuelCan, Locker, FuseBox, VHSTape, VCR). One collection each, front toward -Y (+Z in Roblox),
1 unit = 1 stud. Generic and brand-free (plan section 7). Run in Blender:
    exec(open(r"<repo>/tools/blender/level_props.py").read())      (set ONLY = "Sedan" for one model)
"""

import importlib
import math
import os
import sys

REPO = os.environ.get("BLINDSPOT_REPO", r"C:\\Users\\adrie\\blind-spot")
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import bs_kit as K  # noqa: E402

importlib.reload(K)
import bmesh  # noqa: E402
import bpy  # noqa: E402
import numpy as np  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

OUT = OUT_DIR if "OUT_DIR" in dir() else os.path.join(REPO, "build", "blender")  # noqa: F821
WANT = ONLY if "ONLY" in dir() else None  # noqa: F821


def prism(name, coll, profile, x0, x1, bevel=0.08):
    """A side profile [(y, z), ...] (counter-clockwise seen from +X) extruded along x from x0 to x1."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    left = [bm.verts.new((x0, y, z)) for y, z in profile]
    right = [bm.verts.new((x1, y, z)) for y, z in profile]
    bm.faces.new(list(reversed(left)))
    bm.faces.new(right)
    n = len(profile)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((left[i], left[j], right[j], right[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if bevel > 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=2, affect="EDGES", clamp_overlap=True)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    return obj


def concrete(seed, size=512, base=(0.47, 0.47, 0.46), stains=True):
    r = np.random.default_rng(seed)
    img = np.ones((size, size, 3)) * np.array(base)
    img += K.blur(r.normal(0, 0.06, (size, size)), 6)[..., None]
    img += r.normal(0, 0.02, (size, size, 1))
    if stains:
        yy = np.linspace(0, 1, size)[:, None]
        img *= (1 - 0.18 * (1 - yy) ** 4)[..., None]  # water marks at the top
    return img


def pillar():
    """A concrete column 2.5 x 2.5 x 10 with a yellow and black band at its foot (Roblox: the map's pillar boxes)."""
    coll = K.begin("Pillar", OUT)
    col = K.box("Column", coll, -1.25, 1.25, -1.25, 1.25, 0, 10, bevel=0.08)
    # texture: 4 faces side by side in u, height in v (512 px = 10 studs); the band is the lowest 1.4 studs
    w, h = 1024, 512
    img = concrete(61, size=1024)[:h, :w].copy()
    band = int(h * 1.4 / 10)
    yy, xx = np.mgrid[0:band, 0:w]
    stripes = ((xx + yy) // 24) % 2 == 0
    img[h - band:h][stripes] = (0.85, 0.66, 0.08)
    img[h - band:h][~stripes] = (0.08, 0.08, 0.08)
    img[h - band:h] *= 0.85 + 0.15 * np.random.default_rng(62).random((band, w, 1))
    img[h - band - 4:h - band] *= 0.5
    mesh = col.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        n = f.normal
        for loop in f.loops:
            co = loop.vert.co
            if abs(n.z) > 0.7:
                loop[uv].uv = (0.0, 0.98)
                continue
            # walk around the column: u in 0..1 over the perimeter 4 x 2.5
            if abs(n.y) > abs(n.x):
                side, t = (0, co.x + 1.25) if n.y < 0 else (2, 1.25 - co.x)
            else:
                side, t = (1, co.y + 1.25) if n.x > 0 else (3, 1.25 - co.y)
            loop[uv].uv = ((side * 2.5 + t) / 10.0, co.z / 10.0)
    bm.to_mesh(mesh)
    bm.free()
    K.material(col, "pillar_concrete", img, roughness=0.9)
    return coll


def sedan():
    """A generic four-door car (no brand): body (plain colour, recoloured per car in Studio), tinted glass, tyres,
    lights. Bounds about x -3.2..3.2, y -7.5..7.5, z 0..4.8 (the map's car boxes are 6.5 x 5 x 15)."""
    coll = K.begin("Sedan", OUT)
    lower = [(-7.5, 0.9), (7.5, 0.9), (7.5, 2.3), (7.2, 3.05), (4.6, 3.15), (-3.6, 2.95), (-7.2, 2.6), (-7.5, 2.2)]
    body = prism("Body", coll, lower, -3.05, 3.05, bevel=0.22)
    roof = prism("Roof", coll, [(-1.5, 4.5), (2.6, 4.5), (2.5, 4.72), (-1.4, 4.72)], -2.45, 2.45, bevel=0.1)
    K.flat(body, "car_paint", (0.30, 0.31, 0.33), roughness=0.35, metallic=0.4)
    K.flat(roof, "car_paint", (0.30, 0.31, 0.33), roughness=0.35, metallic=0.4)
    glass = prism("Glass", coll, [(-3.7, 2.9), (4.7, 3.1), (2.65, 4.55), (-1.6, 4.55)], -2.55, 2.55, bevel=0.06)
    K.flat(glass, "car_glass", (0.04, 0.05, 0.06), roughness=0.08, metallic=0.2)
    tyres = []
    for x in (-2.75, 2.75):
        for y in (-4.7, 4.5):
            tyres.append(K.cylinder(f"tyre{x}{y}", coll, (x - 0.45, y, 1.25), (x + 0.45, y, 1.25), 1.25, segments=18))
    rubber = K.join("Tyres", tyres)
    K.flat(rubber, "car_rubber", (0.04, 0.04, 0.04), roughness=0.9)
    hubs = []
    for x in (-3.22, 3.22):
        for y in (-4.7, 4.5):
            hubs.append(K.cylinder(f"hub{x}{y}", coll, (x - 0.04, y, 1.25), (x + 0.04, y, 1.25), 0.75, segments=14))
    hub = K.join("Hubs", hubs)
    K.flat(hub, "car_hub", (0.55, 0.56, 0.58), roughness=0.3, metallic=1.0)
    trim = K.join("Bumpers", [
        K.box("bumperF", coll, -3.1, 3.1, -7.65, -7.1, 0.9, 1.7, bevel=0.12),
        K.box("bumperR", coll, -3.1, 3.1, 7.1, 7.65, 0.9, 1.7, bevel=0.12),
        K.box("sillL", coll, -3.12, -2.9, -3.3, 3.2, 0.85, 1.25, bevel=0.05),
        K.box("sillR", coll, 2.9, 3.12, -3.3, 3.2, 0.85, 1.25, bevel=0.05),
    ])
    K.flat(trim, "car_trim", (0.06, 0.06, 0.07), roughness=0.7)
    heads = K.join("Headlights", [
        K.box("hl", coll, -2.7, -1.6, -7.56, -7.3, 2.0, 2.45, bevel=0.05),
        K.box("hr", coll, 1.6, 2.7, -7.56, -7.3, 2.0, 2.45, bevel=0.05),
    ])
    K.flat(heads, "car_headlight", (0.82, 0.84, 0.80), roughness=0.2)
    tails = K.join("Taillights", [
        K.box("tl", coll, -2.9, -1.7, 7.3, 7.56, 2.2, 2.65, bevel=0.05),
        K.box("tr", coll, 1.7, 2.9, 7.3, 7.56, 2.2, 2.65, bevel=0.05),
    ])
    K.flat(tails, "car_taillight", (0.55, 0.04, 0.03), roughness=0.3)
    return coll


def pipe_run():
    """A 24-stud stretch of ceiling services: three pipes, a square duct, hangers. Hangs from y 0 (the ceiling) down
    to about -1.6 (z here: 0 at the bottom, the top touches the ceiling at z 1.6)."""
    coll = K.begin("PipeRun", OUT)
    pipes = []
    # each pipe rests on the hangers' bottom bar (top at z 0.2), sunk 0.02 into it
    for x, r in ((-1.0, 0.32), (-0.3, 0.22), (0.3, 0.18)):
        pipes.append(K.cylinder(f"pipe{x}", coll, (x, -12, 0.18 + r), (x, 12, 0.18 + r), r, segments=12))
    pipe = K.join("Pipes", pipes)
    K.flat(pipe, "pipe_paint", (0.42, 0.40, 0.33), roughness=0.6, metallic=0.4)
    duct = K.box("Duct", coll, 0.7, 2.1, -12, 12, 0.18, 1.27, bevel=0.03)
    K.box_uv(duct, tile=6.0)
    K.material(duct, "duct_steel", K.brushed_steel(seed=71, base=(0.52, 0.53, 0.54), seams=6, grime=0.25),
               roughness=0.5, metallic=0.8)
    hangers = []
    for y in (-10, -2, 6):
        hangers.append(K.box(f"rod{y}", coll, -1.5, 2.2, y - 0.05, y + 0.05, 1.25, 1.35, bevel=0.0))
        hangers.append(K.box(f"strapA{y}", coll, -1.5, -1.42, y - 0.05, y + 0.05, 0.1, 1.6, bevel=0.0))
        hangers.append(K.box(f"strapB{y}", coll, 2.08, 2.16, y - 0.05, y + 0.05, 0.1, 1.6, bevel=0.0))
        hangers.append(K.box(f"bar{y}", coll, -1.5, 2.2, y - 0.05, y + 0.05, 0.1, 0.2, bevel=0.0))
    hanger = K.join("Hangers", hangers)
    K.flat(hanger, "pipe_hanger", (0.12, 0.12, 0.13), roughness=0.6, metallic=0.7)
    return coll


def checkpoint():
    """A wall-mounted guard tour checkpoint: a steel plate, a reader with a green light. Bounds x -0.5..0.5, z 0..1.6."""
    coll = K.begin("Checkpoint", OUT)
    plate = K.box("Plate", coll, -0.5, 0.5, -0.1, 0.25, 0, 1.6, bevel=0.04)
    img = Image.fromarray((K.brushed_steel(seed=81, base=(0.30, 0.33, 0.31), seams=1) * 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    d.rectangle((60, 40, 452, 120), fill=(230, 196, 60))
    d.text((256, 80), "CHECKPOINT", fill=(20, 20, 20), font=K.font(52), anchor="mm")
    d.text((256, 440), "KESTREL & VANE", fill=(200, 200, 190), font=K.font(34), anchor="mm")
    K.face_uv(plate, "y", -0.5, 0.5, 0, 1.6)
    K.material(plate, "checkpoint_plate", K.to_float(img), roughness=0.5, metallic=0.6)
    reader = K.box("Reader", coll, -0.3, 0.3, -0.22, -0.08, 0.55, 1.1, bevel=0.03)
    K.flat(reader, "checkpoint_reader", (0.05, 0.05, 0.06), roughness=0.4)
    led = K.box("ReaderLed", coll, -0.08, 0.08, -0.25, -0.2, 0.95, 1.03, bevel=0.0)
    K.flat(led, "checkpoint_led", (0.3, 1.0, 0.45), roughness=0.3)
    return coll


def generator():
    """A diesel generator on a skid: louvred housing, control panel, exhaust. Bounds x -2.5..2.5, y -1.2..1.2, z 0..3.5."""
    coll = K.begin("Generator", OUT)
    skid = K.box("Skid", coll, -2.5, 2.5, -1.2, 1.2, 0, 0.35, bevel=0.03)
    K.flat(skid, "gen_skid", (0.08, 0.08, 0.09), roughness=0.7, metallic=0.6)
    housing = K.box("Housing", coll, -2.3, 2.3, -1.05, 1.05, 0.33, 2.9, bevel=0.06)
    img = (K.brushed_steel(seed=91, base=(0.30, 0.36, 0.24), seams=3, grime=0.3) * 255).astype(np.uint8)
    pil = Image.fromarray(img)
    d = ImageDraw.Draw(pil)
    for k in range(10):
        d.rectangle((60, 120 + k * 26, 300, 132 + k * 26), fill=(30, 34, 24))
    d.rectangle((330, 120, 470, 170), fill=(210, 170, 40))
    d.text((400, 145), "DANGER", fill=(20, 20, 20), font=K.font(28), anchor="mm")
    K.box_uv(housing, tile=5.0)
    K.material(housing, "gen_housing", K.to_float(pil), roughness=0.6, metallic=0.5)
    panel = K.box("Panel", coll, 1.0, 2.1, -1.15, -1.0, 1.4, 2.5, bevel=0.03)
    K.flat(panel, "gen_panel", (0.10, 0.10, 0.11), roughness=0.5)
    lamp = K.box("Lamp", coll, 1.15, 1.45, -1.2, -1.12, 2.1, 2.3, bevel=0.0)
    K.flat(lamp, "gen_lamp", (1.0, 0.25, 0.1), roughness=0.3)
    exhaust = K.cylinder("Exhaust", coll, (-1.6, 0.4, 2.85), (-1.6, 0.4, 3.5), 0.2, segments=12)
    K.flat(exhaust, "gen_exhaust", (0.12, 0.10, 0.09), roughness=0.8, metallic=0.5)
    return coll


def fuel_can():
    """A red jerry can. Bounds x -0.6..0.6, y -0.4..0.4, z 0..1.6."""
    coll = K.begin("FuelCan", OUT)
    can = K.join("Can", [
        K.box("body", coll, -0.6, 0.6, -0.35, 0.35, 0, 1.3, bevel=0.1),
        K.box("handle", coll, -0.5, 0.2, -0.08, 0.08, 1.25, 1.55, bevel=0.05),
        K.box("spout", coll, 0.3, 0.5, -0.1, 0.1, 1.25, 1.6, bevel=0.03),
    ])
    K.box_uv(can, tile=2.0)
    K.material(can, "fuel_red", K.brushed_steel(seed=101, base=(0.55, 0.08, 0.06), seams=1, grime=0.35),
               roughness=0.5, metallic=0.4)
    return coll


def locker():
    """A double steel locker (the fuses). Bounds x -1.2..1.2, y -0.8..0.8, z 0..7."""
    coll = K.begin("Locker", OUT)
    box = K.box("Cabinet", coll, -1.2, 1.2, -0.8, 0.8, 0, 7, bevel=0.04)
    img = Image.fromarray((K.brushed_steel(seed=111, base=(0.36, 0.40, 0.44), seams=2, grime=0.2) * 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    for door in (0, 1):
        x0 = 20 + door * 246
        for k in range(5):
            d.rectangle((x0 + 60, 40 + k * 14, x0 + 180, 46 + k * 14), fill=(40, 44, 48))
        d.rectangle((x0 + 190, 230, x0 + 205, 290), fill=(25, 25, 28))
    d.rectangle((150, 380, 360, 430), fill=(230, 220, 190))
    d.text((255, 405), "FUSES / SPARES", fill=(30, 30, 30), font=K.font(22), anchor="mm")
    K.face_uv(box, "y", -1.2, 1.2, 0, 7)
    K.material(box, "locker_steel", K.to_float(img), roughness=0.5, metallic=0.7)
    return coll


def fuse_box():
    """A grey electrical box with a hazard sticker (the fuse box, the cut lines' junction boxes); World paints the
    camera's name on its label frame. Bounds x -0.8..0.8, y -0.25..0.25, z 0..2."""
    coll = K.begin("FuseBox", OUT)
    box = K.box("Box", coll, -0.8, 0.8, -0.25, 0.25, 0, 2, bevel=0.04)
    img = Image.fromarray((K.brushed_steel(seed=121, base=(0.58, 0.58, 0.55), seams=1, grime=0.3) * 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    d.polygon([(256, 120), (356, 290), (156, 290)], fill=(230, 190, 30), outline=(20, 20, 20))
    d.text((256, 235), "!", fill=(20, 20, 20), font=K.font(90), anchor="mm")
    # no camera name in the texture: World labels each box (CAM 07, a cut line's camera)
    d.rectangle((150, 330, 362, 390), outline=(40, 40, 40), width=4)
    K.face_uv(box, "y", -0.8, 0.8, 0, 2)
    K.material(box, "fusebox_steel", K.to_float(img), roughness=0.6, metallic=0.5)
    return coll


def vhs_tape():
    """A VHS cassette lying flat, with a white label. Bounds x -0.45..0.45, y -0.28..0.28, z 0..0.18."""
    coll = K.begin("VHSTape", OUT)
    tape = K.box("Tape", coll, -0.45, 0.45, -0.28, 0.28, 0, 0.18, bevel=0.015)
    img = Image.new("RGB", (512, 320), (16, 16, 18))
    d = ImageDraw.Draw(img)
    d.rectangle((40, 40, 472, 150), fill=(226, 220, 200))
    d.text((256, 95), "P3 - DO NOT ERASE", fill=(150, 30, 25), font=K.font(40), anchor="mm")
    d.ellipse((110, 190, 190, 270), fill=(40, 40, 44))
    d.ellipse((322, 190, 402, 270), fill=(40, 40, 44))
    K.face_uv(tape, "z", -0.45, 0.45, -0.28, 0.28)
    K.material(tape, "vhs_tape", K.to_float(img), roughness=0.5)
    return coll


def vcr():
    """A 1990s VCR: black box, tape slot, green clock display. Bounds x -1..1, y -0.75..0.75, z 0..0.5."""
    coll = K.begin("VCR", OUT)
    box = K.box("Deck", coll, -1.0, 1.0, -0.75, 0.75, 0, 0.5, bevel=0.03)
    img = Image.new("RGB", (512, 128), (18, 18, 20))
    d = ImageDraw.Draw(img)
    d.rectangle((40, 40, 250, 70), fill=(4, 4, 4))
    d.rectangle((300, 36, 460, 84), fill=(8, 20, 10))
    d.text((380, 60), "03:14", fill=(110, 255, 140), font=K.font(34), anchor="mm")
    K.face_uv(box, "y", -1.0, 1.0, 0, 0.5)
    K.material(box, "vcr_front", K.to_float(img), roughness=0.4)
    return coll


BUILD = {
    "Pillar": pillar, "Sedan": sedan, "PipeRun": pipe_run, "Checkpoint": checkpoint, "Generator": generator,
    "FuelCan": fuel_can, "Locker": locker, "FuseBox": fuse_box, "VHSTape": vhs_tape, "VCR": vcr,
}
for name, fn in BUILD.items():
    if WANT is None or WANT == name:
        c = fn()
        print(name, {o.name: [round(v, 2) for v in o.dimensions] for o in c.objects})
