"""K&V SUPPLY's furniture (Adrien, 8 Nov: a little shop in the lobby where you upgrade your skills): the counter with
its till, and four stands, each with what it upgrades on top and a brass plate with its name. One collection each, the
front toward -Y (+Z in Roblox), 1 unit = 1 stud, set by content/lobby_props.csv. Run in Blender:
    exec(open(r"<repo>/tools/blender/shop_props.py").read())      (set ONLY = "StandSignal" for one model)
"""

import importlib
import os
import sys

REPO = os.environ.get("BLINDSPOT_REPO", r"C:\\Users\\adrie\\blind-spot")
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import bs_kit as K  # noqa: E402

importlib.reload(K)
import numpy as np  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

OUT = OUT_DIR if "OUT_DIR" in dir() else os.path.join(REPO, "build", "blender")  # noqa: F821
WANT = ONLY if "ONLY" in dir() else None  # noqa: F821


def plate_texture(text, sub, seed):
    img = Image.fromarray((K.brushed_steel(seed=seed, base=(0.12, 0.12, 0.13), seams=1, grime=0.2) * 255)
                          .astype(np.uint8))
    d = ImageDraw.Draw(img)
    d.rectangle((14, 14, 497, 497), outline=(201, 164, 106), width=10)
    d.text((256, 220), text, fill=(201, 164, 106), font=K.font(78), anchor="mm")
    d.text((256, 330), sub, fill=(232, 226, 214), font=K.font(34), anchor="mm")
    return K.to_float(img)


def stand(name, label, sub, seed):
    """A display plinth: a dark steel column with brass trim and the name plate on its front. Top at z 3."""
    coll = K.begin(name, OUT)
    plinth = K.box("Plinth", coll, -0.9, 0.9, -0.9, 0.9, 0.2, 3.0, bevel=0.04)
    K.box_uv(plinth, tile=3.0)
    K.material(plinth, name.lower() + "_plinth",
               K.brushed_steel(seed=seed, base=(0.16, 0.16, 0.17), seams=2, grime=0.25), roughness=0.5, metallic=0.6)
    trim = K.join("Trim", [
        K.box("base", coll, -1.0, 1.0, -1.0, 1.0, 0.0, 0.22, bevel=0.03),
        K.box("top", coll, -1.0, 1.0, -1.0, 1.0, 2.98, 3.1, bevel=0.03),
    ])
    K.flat(trim, "stand_brass", (0.62, 0.48, 0.28), roughness=0.35, metallic=0.9)
    plate = K.box("Plate", coll, -0.7, 0.7, -0.95, -0.88, 1.2, 2.6, bevel=0.01)
    K.face_uv(plate, "y", -0.7, 0.7, 1.2, 2.6)
    K.material(plate, name.lower() + "_plate", plate_texture(label, sub, seed + 1), roughness=0.4, metallic=0.5)
    return coll


def stand_signal():
    """SIGNAL: a field radio amplifier with a big dial, a needle gauge and an antenna."""
    coll = stand("StandSignal", "SIGNAL", "your nerve", 301)
    box = K.box("Radio", coll, -0.6, 0.6, -0.35, 0.35, 3.08, 3.7, bevel=0.04)
    img = Image.new("RGB", (512, 256), (40, 44, 38))
    d = ImageDraw.Draw(img)
    d.rectangle((40, 40, 250, 200), fill=(220, 210, 170), outline=(20, 20, 20), width=6)
    d.arc((60, 70, 230, 240), 200, 340, fill=(30, 30, 30), width=4)
    d.line((145, 170, 200, 95), fill=(200, 40, 30), width=6)
    d.ellipse((300, 70, 440, 210), fill=(25, 25, 25), outline=(150, 150, 150), width=6)
    K.face_uv(box, "y", -0.6, 0.6, 3.08, 3.7)
    K.material(box, "signal_radio", K.to_float(img), roughness=0.6, metallic=0.3)
    antenna = K.join("Antenna", [
        K.cylinder("rod", coll, (0.45, 0.15, 3.65), (0.45, 0.15, 4.9), 0.025, segments=8),
        K.cylinder("tip", coll, (0.45, 0.15, 4.88), (0.45, 0.15, 4.96), 0.05, segments=8),
    ])
    K.flat(antenna, "signal_antenna", (0.7, 0.7, 0.72), roughness=0.3, metallic=0.9)
    return coll


def stand_sprint():
    """SPRINT: a pair of worn black guard boots."""
    coll = stand("StandSprint", "SPRINT", "your legs", 311)
    parts = []
    for side, x in (("L", -0.28), ("R", 0.3)):
        parts += [
            K.box("sole" + side, coll, x - 0.2, x + 0.2, -0.5, 0.4, 3.08, 3.2, bevel=0.03),
            K.box("foot" + side, coll, x - 0.18, x + 0.18, -0.45, 0.35, 3.18, 3.42, bevel=0.06),
            K.box("shaft" + side, coll, x - 0.17, x + 0.17, 0.0, 0.36, 3.4, 4.0, bevel=0.05),
        ]
    boots = K.join("Boots", parts)
    K.box_uv(boots, tile=1.0)
    K.material(boots, "sprint_boots", K.brushed_steel(seed=312, base=(0.07, 0.07, 0.07), seams=1, grime=0.4) * 1.1,
               roughness=0.55, metallic=0.1)
    return coll


def stand_camera():
    """CAMCORDER: a 1990s camcorder with its lens, viewfinder and strap."""
    coll = stand("StandCamera", "CAMCORDER", "tape and battery", 321)
    body = K.join("Body", [
        K.box("body", coll, -0.25, 0.25, -0.55, 0.45, 3.08, 3.55, bevel=0.05),
        K.box("viewfinder", coll, -0.38, -0.2, 0.05, 0.4, 3.52, 3.68, bevel=0.03),
    ])
    K.flat(body, "camera_body", (0.1, 0.1, 0.11), roughness=0.45, metallic=0.3)
    lens = K.cylinder("Lens", coll, (0, -0.5, 3.32), (0, -0.78, 3.32), 0.17, segments=16)
    K.flat(lens, "camera_lens", (0.04, 0.05, 0.08), roughness=0.15, metallic=0.6)
    rec = K.box("Rec", coll, 0.12, 0.2, -0.57, -0.53, 3.45, 3.5, bevel=0.0)
    K.flat(rec, "camera_rec", (1.0, 0.15, 0.12), roughness=0.3)
    return coll


def stand_flares():
    """FLARES: an open wooden box with four red road flares in it."""
    coll = stand("StandFlares", "FLARES", "cameras you drop", 331)
    box = K.join("Box", [
        K.box("bottom", coll, -0.65, 0.65, -0.42, 0.42, 3.08, 3.14, bevel=0.01),
        K.box("front", coll, -0.65, 0.65, -0.42, -0.36, 3.08, 3.4, bevel=0.01),
        K.box("back", coll, -0.65, 0.65, 0.36, 0.42, 3.08, 3.4, bevel=0.01),
        K.box("left", coll, -0.65, -0.59, -0.42, 0.42, 3.08, 3.4, bevel=0.01),
        K.box("right", coll, 0.59, 0.65, -0.42, 0.42, 3.08, 3.4, bevel=0.01),
    ])
    K.box_uv(box, tile=1.0)
    K.material(box, "flares_box", K.wood(seed=332, base=(0.5, 0.38, 0.24), plank=128), roughness=0.75)
    flares = K.join("Flares", [
        K.cylinder(f"f{k}", coll, (-0.5, y, 3.21), (0.5, y, 3.21), 0.08, segments=10)
        for k, y in enumerate((-0.24, -0.08, 0.08, 0.24))
    ])
    K.flat(flares, "flares_red", (0.62, 0.07, 0.05), roughness=0.7)
    return coll


def shop_counter():
    """The K&V SUPPLY counter: a wooden top on a steel front with the company plate, and an old till on it.
    Bounds x -4..4, y -1.2..1.2, z 0..4.4."""
    coll = K.begin("ShopCounter", OUT)
    front = K.box("Front", coll, -4, 4, -1.2, 1.1, 0, 3.2, bevel=0.04)
    img = Image.fromarray((K.brushed_steel(seed=341, base=(0.2, 0.21, 0.22), seams=3, grime=0.3) * 255)
                          .astype(np.uint8))
    d = ImageDraw.Draw(img)
    d.rectangle((136, 120, 376, 230), fill=(20, 20, 22), outline=(201, 164, 106), width=6)
    d.text((256, 160), "K&V SUPPLY", fill=(201, 164, 106), font=K.font(22), anchor="mm")
    d.text((256, 200), "NIGHT STAFF", fill=(232, 226, 214), font=K.font(15), anchor="mm")
    K.face_uv(front, "y", -4, 4, 0, 3.2)
    K.material(front, "counter_front", K.to_float(img), roughness=0.5, metallic=0.6)
    top = K.box("Top", coll, -4.1, 4.1, -1.3, 1.2, 3.18, 3.42, bevel=0.03)
    K.box_uv(top, tile=4.0)
    K.material(top, "counter_top", K.wood(seed=342, base=(0.38, 0.26, 0.16), plank=150), roughness=0.6)
    till = K.join("Till", [
        K.box("tillBase", coll, 1.4, 2.6, -0.5, 0.6, 3.4, 3.85, bevel=0.04),
        K.box("tillTop", coll, 1.5, 2.5, 0.1, 0.55, 3.84, 4.4, bevel=0.04),
    ])
    K.flat(till, "counter_till", (0.25, 0.22, 0.2), roughness=0.4, metallic=0.5)
    bell = K.cylinder("Bell", coll, (-2, 0, 3.4), (-2, 0, 3.6), 0.18, segments=14)
    K.flat(bell, "counter_bell", (0.75, 0.6, 0.35), roughness=0.25, metallic=0.95)
    return coll


BUILD = {
    "ShopCounter": shop_counter, "StandSignal": stand_signal, "StandSprint": stand_sprint,
    "StandCamera": stand_camera, "StandFlares": stand_flares,
}
for name, fn in BUILD.items():
    if WANT is None or WANT == name:
        c = fn()
        print(name, {o.name: [round(v, 2) for v in o.dimensions] for o in c.objects})
