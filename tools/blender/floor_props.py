"""Chapter 1's floor models (CLAUDE.md, "Blender d'abord"): the stairwell door, the P4 breaker panel and boilers, the
sledgehammer, the P2 crates, the fresh plaster of the sealed room and the service corridors' fire door. One collection
each, front toward -Y (+Z in Roblox), 1 unit = 1 stud, bounds matching their row in content/map_*.csv or their spot
look in World.luau. Generic and brand-free, no blood (plan section 7). Run in Blender:
    exec(open(r"<repo>/tools/blender/floor_props.py").read())      (set ONLY = "Boiler" for one model)
Parts named Rubble* in PlasterWall only show once the wall is broken (DoorService).
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


def painted_steel(seed, base, size=512, grime=0.25):
    """Painted steel: flat paint, a few scratches, grime toward the bottom."""
    r = np.random.default_rng(seed)
    img = np.ones((size, size, 3)) * np.array(base)
    img += K.blur(r.normal(0, 0.025, (size, size)), 4)[..., None]
    yy = np.linspace(0, 1, size)[:, None]
    img *= (1 - grime * yy ** 6)[..., None]
    for _ in range(40):
        x, y = r.integers(0, size, 2)
        length = r.integers(8, 50)
        img[y:y + 2, x:x + length] = img[y:y + 2, x:x + length] * 0.6 + 0.35
    return np.clip(img, 0, 1)


def plaster(seed, size=512):
    """Fresh plaster: warm off-white, trowel arcs, damp grey at the edges."""
    r = np.random.default_rng(seed)
    img = np.ones((size, size, 3)) * np.array((0.85, 0.82, 0.76))
    img += K.blur(r.normal(0, 0.035, (size, size)), 10)[..., None]
    yy, xx = np.mgrid[0:size, 0:size] / size
    for _ in range(26):
        cx, cy, rad = r.uniform(0, 1), r.uniform(0, 1), r.uniform(0.08, 0.25)
        ring = np.abs(np.hypot(xx - cx, yy - cy) - rad) < 0.004
        img[ring] *= 0.93
    edge = np.minimum(np.minimum(xx, 1 - xx), np.minimum(yy, 1 - yy))
    img *= (1 - 0.22 * np.exp(-edge * 14))[..., None]
    return np.clip(img, 0, 1)


def two_sided_uv(obj, x0, x1, z0, z1):
    """Planar mapping on x and z read the right way from both sides: the -Y faces as is, the +Y faces mirrored back
    (a door or a wall seen from the corridor and from the room shows its sign the right way round)."""
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        back = f.normal.y > 0.5
        for loop in f.loops:
            co = loop.vert.co
            u = (co.x - x0) / (x1 - x0)
            loop[uv].uv = ((1 - u) if back else u, (co.z - z0) / (z1 - z0))
    bm.to_mesh(mesh)
    bm.free()


def clamp(obj, x0, x1, z0, z1):
    """Pulls every vertex inside x0..x1 and z0..z1 (rubble must not poke through the floor or the next wall)."""
    for v in obj.data.vertices:
        v.co.x = min(max(v.co.x, x0), x1)
        v.co.z = min(max(v.co.z, z0), z1)
    obj.data.update()


def chunks(name, coll, rng, count, x0, x1, y0, y1, z0, z1, smin, smax):
    """Broken plaster: small boxes of random size and turn, joined into one object."""
    parts = []
    for k in range(count):
        s = rng.uniform(smin, smax, 3)
        cx, cy, cz = rng.uniform(x0, x1), rng.uniform(y0, y1), rng.uniform(z0, z1)
        o = K.box(f"{name}{k}", coll, -s[0] / 2, s[0] / 2, -s[1] / 2, s[1] / 2, -s[2] / 2, s[2] / 2, bevel=0.02)
        o.rotation_euler = tuple(rng.uniform(-0.6, 0.6, 3))
        o.location = (cx, cy, cz)
        bpy.context.view_layer.update()
        parts.append(o)
    return K.join(name, parts)


def stair_door():
    """The stairwell door: steel frame, a grey-blue leaf with a wired-glass window and a push bar, a green STAIRS
    sign above. It sits on the wall face: bounds x -2..2, y -0.4..0.5 (World centres the bounds on the spot, 0.4 off
    the wall: the back sinks 0.05 into it), z 0..8."""
    coll = K.begin("StairDoor", OUT)
    frame = K.join("Frame", [
        K.box("jambL", coll, -2.0, -1.75, -0.4, 0.5, 0, 7.5),
        K.box("jambR", coll, 1.75, 2.0, -0.4, 0.5, 0, 7.5),
        K.box("head", coll, -2.0, 2.0, -0.4, 0.5, 7.25, 7.5),
    ])
    K.flat(frame, "stair_frame", (0.16, 0.17, 0.18), roughness=0.5, metallic=0.6)
    leaf = K.box("Leaf", coll, -1.76, 1.76, -0.1, 0.2, 0, 7.26, bevel=0.02)
    img = Image.fromarray((painted_steel(201, (0.33, 0.40, 0.45)) * 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    # window (upper third), wire grid
    d.rectangle((300, 50, 430, 200), fill=(18, 22, 26), outline=(60, 64, 68), width=6)
    for k in range(1, 6):
        d.line((300 + k * 22, 50, 300 + k * 22, 200), fill=(70, 74, 78), width=1)
        d.line((300, 50 + k * 25, 430, 50 + k * 25), fill=(70, 74, 78), width=1)
    d.text((256, 300), "STAIRS", fill=(225, 225, 215), font=K.font(46), anchor="mm")
    d.rectangle((20, 450, 492, 500), fill=(120, 124, 126))  # kick plate
    K.face_uv(leaf, "y", -1.76, 1.76, 0, 7.26)
    K.material(leaf, "stair_leaf", K.to_float(img), roughness=0.55, metallic=0.4)
    bar = K.join("PushBar", [
        K.box("bar", coll, -1.35, 1.35, -0.28, -0.18, 3.35, 3.55, bevel=0.03),
        K.box("barL", coll, -1.4, -1.2, -0.28, -0.08, 3.25, 3.65, bevel=0.03),
        K.box("barR", coll, 1.2, 1.4, -0.28, -0.08, 3.25, 3.65, bevel=0.03),
    ])
    K.flat(bar, "stair_bar", (0.62, 0.63, 0.64), roughness=0.3, metallic=0.9)
    sign = K.box("Sign", coll, -1.1, 1.1, -0.18, 0.2, 7.47, 8.0, bevel=0.02)
    simg = Image.new("RGB", (512, 112), (24, 140, 70))
    sd = ImageDraw.Draw(simg)
    sd.text((300, 56), "STAIRS", fill=(240, 255, 240), font=K.font(64), anchor="mm")
    sd.polygon([(40, 56), (110, 20), (110, 92)], fill=(240, 255, 240))
    K.face_uv(sign, "y", -1.1, 1.1, 7.47, 8.0)
    K.material(sign, "stair_sign", K.to_float(simg), roughness=0.3)
    return coll


def breaker_panel():
    """The P4 main breaker panel: a floor-standing steel cabinet with rows of breakers behind a hinged cover, a
    warning plate, conduits up to the ceiling. Bounds x -2.05..2.05, y -0.42..0.45, z 0..10.05."""
    coll = K.begin("BreakerPanel", OUT)
    cab = K.box("Cabinet", coll, -2.0, 2.0, -0.3, 0.45, 0.2, 6.0, bevel=0.04)
    img = Image.fromarray((K.brushed_steel(seed=211, base=(0.52, 0.54, 0.52), seams=1, grime=0.25) * 255)
                          .astype(np.uint8))
    d = ImageDraw.Draw(img)
    d.rectangle((40, 30, 472, 80), fill=(30, 30, 32))
    d.text((256, 55), "P4  MAIN DISTRIBUTION", fill=(230, 230, 220), font=K.font(28), anchor="mm")
    for col in range(2):
        x0 = 60 + col * 210
        d.rectangle((x0 - 10, 100, x0 + 182, 380), fill=(40, 42, 44))
        for row in range(10):
            y = 112 + row * 26
            for k in range(6):
                d.rectangle((x0 + k * 30, y, x0 + k * 30 + 20, y + 18), fill=(16, 16, 18))
                d.rectangle((x0 + k * 30 + 6, y + 3, x0 + k * 30 + 14, y + 9), fill=(220, 220, 210))
    d.rectangle((150, 400, 362, 470), fill=(232, 192, 40))
    d.polygon([(190, 460), (215, 412), (240, 460)], fill=(20, 20, 20))
    d.text((300, 435), "DANGER", fill=(20, 20, 20), font=K.font(30), anchor="mm")
    K.face_uv(cab, "y", -2.0, 2.0, 0.2, 6.0)
    K.material(cab, "breaker_cabinet", K.to_float(img), roughness=0.5, metallic=0.6)
    plinth = K.box("Plinth", coll, -2.05, 2.05, -0.35, 0.45, 0, 0.22, bevel=0.02)
    handle = K.box("Handle", coll, 1.6, 1.75, -0.42, -0.28, 2.8, 3.8, bevel=0.03)
    conduits = [K.cylinder(f"conduit{k}", coll, (x, 0.18, 5.95), (x, 0.18, 10.05), 0.13, segments=10)
                for k, x in enumerate((-1.3, -0.4, 0.5, 1.4))]
    dark = K.join("Fittings", [plinth, handle] + conduits)
    K.flat(dark, "breaker_fittings", (0.20, 0.21, 0.22), roughness=0.5, metallic=0.7)
    return coll


def sledgehammer():
    """A sledgehammer lying on its side (on the P4 workbench): steel head, ash handle, black grip.
    Bounds x -1.3..1.36, y -0.34..0.34, z 0..0.42."""
    coll = K.begin("Sledgehammer", OUT)
    head = K.box("Head", coll, 0.96, 1.36, -0.34, 0.34, 0.0, 0.42, bevel=0.05)
    K.flat(head, "hammer_head", (0.22, 0.23, 0.24), roughness=0.45, metallic=0.9)
    handle = K.cylinder("Handle", coll, (-0.62, 0, 0.21), (1.05, 0, 0.21), 0.075, segments=12)
    K.box_uv(handle, tile=1.0)
    K.material(handle, "hammer_handle", K.wood(seed=221, size=256, base=(0.62, 0.46, 0.28), plank=256),
               roughness=0.6)
    grip = K.cylinder("Grip", coll, (-1.3, 0, 0.21), (-0.6, 0, 0.21), 0.09, segments=12)
    K.flat(grip, "hammer_grip", (0.05, 0.05, 0.05), roughness=0.9)
    return coll


def crates():
    """Shipping crates on a pallet in a P2 stall. Bounds x -3.5..3.5, y -4.5..4.5, z 0..5."""
    coll = K.begin("Crates", OUT)
    pallet = K.join("Pallet", [
        K.box("deck", coll, -3.4, 3.4, -4.4, 4.4, 0.32, 0.5, bevel=0.02),
        K.box("runner0", coll, -3.4, -2.8, -4.4, 4.4, 0, 0.33, bevel=0.02),
        K.box("runner1", coll, -0.3, 0.3, -4.4, 4.4, 0, 0.33, bevel=0.02),
        K.box("runner2", coll, 2.8, 3.4, -4.4, 4.4, 0, 0.33, bevel=0.02),
    ])
    K.box_uv(pallet, tile=3.0)
    K.material(pallet, "crate_pallet", K.wood(seed=231, base=(0.48, 0.38, 0.24)), roughness=0.8)
    img = Image.fromarray((K.wood(seed=232, base=(0.56, 0.44, 0.28), plank=96) * 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, 511, 30), fill=(92, 70, 44))
    d.rectangle((0, 481, 511, 511), fill=(92, 70, 44))
    d.text((256, 200), "THIS SIDE UP", fill=(40, 30, 22), font=K.font(40), anchor="mm")
    d.polygon([(226, 330), (256, 270), (286, 330)], fill=(40, 30, 22))
    d.polygon([(306, 330), (336, 270), (366, 330)], fill=(40, 30, 22))
    tex = K.to_float(img)
    boxes = [
        K.box("crateA", coll, -3.3, -0.05, -4.3, -0.1, 0.49, 3.3, bevel=0.05),
        K.box("crateB", coll, 0.1, 3.3, -4.3, -0.6, 0.49, 2.9, bevel=0.05),
        K.box("crateC", coll, -3.2, 3.2, 0.2, 4.3, 0.49, 3.0, bevel=0.05),
        K.box("crateD", coll, -2.8, -0.2, -3.8, -0.6, 3.28, 5.0, bevel=0.05),
    ]
    stack = K.join("Stack", boxes)
    K.box_uv(stack, tile=3.2)
    K.material(stack, "crate_wood", tex, roughness=0.75)
    return coll


def boiler():
    """An old boiler: a clad vertical tank on a plinth, a burner box, a gauge, a valve wheel and the flue.
    Bounds x -4..4, y -4..4, z 0..8."""
    coll = K.begin("Boiler", OUT)
    plinth = K.box("Plinth", coll, -3.8, 3.8, -3.8, 3.8, 0, 0.4, bevel=0.05)
    K.flat(plinth, "boiler_plinth", (0.36, 0.36, 0.35), roughness=0.9)
    tank = K.join("Tank", [
        K.cylinder("tank", coll, (0, 0, 0.38), (0, 0, 6.6), 3.2, segments=32),
        K.cylinder("dome", coll, (0, 0, 6.55), (0, 0, 7.2), 2.6, segments=32),
    ])
    img = Image.fromarray((K.brushed_steel(seed=241, base=(0.66, 0.67, 0.66), seams=1, grime=0.3) * 255)
                          .astype(np.uint8))
    d = ImageDraw.Draw(img)
    for k in (1, 3):
        d.rectangle((0, k * 128 - 3, 511, k * 128 + 3), fill=(120, 122, 120))
    for x in range(16, 512, 64):
        for y in (k * 128 for k in (1, 3)):
            d.ellipse((x - 4, y - 12, x + 4, y - 4), fill=(150, 152, 150))
    d.rectangle((210, 150, 300, 200), fill=(200, 196, 180))
    d.text((255, 175), "3 BAR", fill=(30, 30, 30), font=K.font(24), anchor="mm")
    K.box_uv(tank, tile=7.0)
    K.material(tank, "boiler_cladding", K.to_float(img), roughness=0.45, metallic=0.7)
    burner = K.box("Burner", coll, -1.3, 1.3, -3.95, -2.6, 0.38, 2.3, bevel=0.05)
    K.flat(burner, "boiler_burner", (0.30, 0.08, 0.06), roughness=0.6, metallic=0.4)
    fittings = K.join("Fittings", [
        K.cylinder("flue", coll, (0, 1.0, 7.15), (0, 1.0, 8.0), 0.6, segments=16),
        K.cylinder("gauge", coll, (1.6, -2.6, 4.0), (1.6, -3.4, 4.0), 0.35, segments=16),
        K.cylinder("valveStem", coll, (-1.8, -2.5, 3.0), (-1.8, -3.5, 3.0), 0.08, segments=8),
        K.cylinder("valveRimA", coll, (-2.35, -3.5, 3.0), (-1.25, -3.5, 3.0), 0.06, segments=8),
        K.cylinder("valveRimB", coll, (-1.8, -3.5, 2.45), (-1.8, -3.5, 3.55), 0.06, segments=8),
        K.cylinder("pipeOut", coll, (2.9, 0, 5.0), (4.0, 0, 5.0), 0.3, segments=12),
        K.cylinder("pipeDown", coll, (3.7, 0, 5.2), (3.7, 0, 0.38), 0.3, segments=12),
    ])
    K.flat(fittings, "boiler_fittings", (0.16, 0.16, 0.17), roughness=0.5, metallic=0.8)
    face = K.cylinder("GaugeFace", coll, (1.6, -3.38, 4.0), (1.6, -3.42, 4.0), 0.29, segments=16)
    K.flat(face, "boiler_gauge", (0.92, 0.90, 0.84), roughness=0.3)
    return coll


def plaster_wall():
    """The fresh plaster patch that seals a room on P4 (night 5), and what is left once it is broken: a jagged rim
    (RubbleEdge) and chunks on the floor on both sides (RubblePile). Bounds x -6.02..6.02, y -2..2, z 0..10."""
    coll = K.begin("PlasterWall", OUT)
    wall = K.box("Plaster", coll, -6.02, 6.02, -0.52, 0.52, 0, 10, bevel=0.06)
    img = Image.fromarray((plaster(251) * 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    # pencil marks a workman left (no message, just dates and a level line)
    d.line((40, 300, 470, 296), fill=(120, 116, 108), width=2)
    d.text((70, 270), "P4-07  11/94", fill=(110, 106, 98), font=K.font(22))
    two_sided_uv(wall, -6.02, 6.02, 0, 10)
    K.material(wall, "plaster_fresh", K.to_float(img), roughness=0.9)
    rng = np.random.default_rng(252)
    edge = K.join("RubbleEdge", [
        chunks("edgeL", coll, rng, 14, -6.0, -5.2, -0.45, 0.45, 0.3, 9.6, 0.4, 1.0),
        chunks("edgeR", coll, rng, 14, 5.2, 6.0, -0.45, 0.45, 0.3, 9.6, 0.4, 1.0),
        chunks("edgeT", coll, rng, 16, -5.6, 5.6, -0.45, 0.45, 9.3, 9.8, 0.4, 0.9),
    ])
    pile = K.join("RubblePile", [
        chunks("pileS", coll, rng, 30, -4.5, 4.5, -1.8, -0.7, 0.2, 0.45, 0.25, 0.7),
        chunks("pileN", coll, rng, 30, -4.5, 4.5, 0.7, 1.8, 0.2, 0.45, 0.25, 0.7),
        chunks("pileM", coll, rng, 16, -4.0, 4.0, -0.6, 0.6, 0.2, 0.35, 0.25, 0.6),
    ])
    clamp(edge, -6.0, 6.0, 0.0, 10.0)
    clamp(pile, -6.0, 6.0, 0.0, 10.0)
    for o in (edge, pile):
        K.box_uv(o, tile=2.0)
        K.material(o, "plaster_broken", plaster(253, size=256) * 0.92, roughness=0.95)
    # the rubble is symmetric so the bounds stay centred (World places the bottom centre of the bounds)
    return coll


def fire_door():
    """A service corridor fire door: red steel leaf, vision panel, push bars both sides, three hinges on its -X edge
    (DoorService swings it around that edge). Bounds x -2..2, y -0.32..0.32, z 0..8."""
    coll = K.begin("FireDoor", OUT)
    leaf = K.box("Leaf", coll, -1.98, 1.98, -0.2, 0.2, 0.0, 7.95, bevel=0.03)
    img = Image.fromarray((painted_steel(261, (0.50, 0.10, 0.08)) * 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    d.rectangle((300, 60, 410, 230), fill=(20, 24, 28), outline=(40, 40, 42), width=6)
    for k in range(1, 5):
        d.line((300 + k * 22, 60, 300 + k * 22, 230), fill=(70, 72, 76), width=1)
        d.line((300, 60 + k * 34, 410, 60 + k * 34), fill=(70, 72, 76), width=1)
    d.rectangle((110, 350, 400, 420), fill=(20, 60, 140))
    d.text((255, 372), "FIRE DOOR", fill=(240, 240, 240), font=K.font(30), anchor="mm")
    d.text((255, 402), "KEEP SHUT", fill=(240, 240, 240), font=K.font(24), anchor="mm")
    d.rectangle((20, 455, 492, 505), fill=(130, 132, 134))
    two_sided_uv(leaf, -1.98, 1.98, 0, 7.95)
    K.material(leaf, "firedoor_leaf", K.to_float(img), roughness=0.5, metallic=0.4)
    hardware = K.join("Hardware", [
        K.box("barF", coll, -1.4, 1.4, -0.32, -0.18, 3.35, 3.55, bevel=0.03),
        K.box("barB", coll, -1.4, 1.4, 0.18, 0.32, 3.35, 3.55, bevel=0.03),
        K.box("barFL", coll, -1.45, -1.25, -0.32, -0.15, 3.25, 3.65, bevel=0.02),
        K.box("barFR", coll, 1.25, 1.45, -0.32, -0.15, 3.25, 3.65, bevel=0.02),
        K.box("barBL", coll, -1.45, -1.25, 0.15, 0.32, 3.25, 3.65, bevel=0.02),
        K.box("barBR", coll, 1.25, 1.45, 0.15, 0.32, 3.25, 3.65, bevel=0.02),
        K.cylinder("hinge0", coll, (-1.93, 0, 0.8), (-1.93, 0, 1.4), 0.09, segments=8),
        K.cylinder("hinge1", coll, (-1.93, 0, 3.7), (-1.93, 0, 4.3), 0.09, segments=8),
        K.cylinder("hinge2", coll, (-1.93, 0, 6.6), (-1.93, 0, 7.2), 0.09, segments=8),
    ])
    K.flat(hardware, "firedoor_hardware", (0.62, 0.63, 0.64), roughness=0.3, metallic=0.9)
    return coll


def workbench():
    """The P4 workbench: a thick wooden top on a steel frame, a lower shelf, a vise at one end, a small toolbox at the
    other (the middle stays clear for the sledgehammer). Bounds x -5..5, y -1.5..1.5, z 0..3 (the top at 3)."""
    coll = K.begin("Workbench", OUT)
    top = K.box("Top", coll, -5.0, 5.0, -1.5, 1.5, 2.7, 3.0, bevel=0.04)
    K.box_uv(top, tile=4.0)
    K.material(top, "bench_top", K.wood(seed=271, base=(0.46, 0.34, 0.22), plank=170), roughness=0.75)
    frame = K.join("Frame", [
        K.box("legFL", coll, -4.8, -4.5, -1.35, -1.05, 0, 2.72),
        K.box("legFR", coll, 4.5, 4.8, -1.35, -1.05, 0, 2.72),
        K.box("legBL", coll, -4.8, -4.5, 1.05, 1.35, 0, 2.72),
        K.box("legBR", coll, 4.5, 4.8, 1.05, 1.35, 0, 2.72),
        K.box("railF", coll, -4.8, 4.8, -1.35, -1.15, 2.45, 2.72),
        K.box("railB", coll, -4.8, 4.8, 1.15, 1.35, 2.45, 2.72),
        K.box("shelf", coll, -4.8, 4.8, -1.3, 1.3, 0.55, 0.7),
    ])
    K.flat(frame, "bench_frame", (0.20, 0.27, 0.32), roughness=0.5, metallic=0.6)
    vise = K.join("Vise", [
        K.box("viseBase", coll, 3.6, 4.6, -1.2, -0.3, 2.98, 3.3, bevel=0.03),
        K.box("viseJaw", coll, 3.7, 4.5, -1.55, -1.2, 2.98, 3.5, bevel=0.03),
        K.cylinder("viseScrew", coll, (4.1, -1.55, 3.2), (4.1, -2.1, 3.2), 0.06, segments=8),
    ])
    K.flat(vise, "bench_vise", (0.15, 0.28, 0.45), roughness=0.4, metallic=0.7)
    box = K.box("Toolbox", coll, -4.7, -3.3, -0.5, 0.6, 2.98, 3.6, bevel=0.04)
    K.flat(box, "bench_toolbox", (0.62, 0.10, 0.08), roughness=0.45, metallic=0.5)
    return coll


def couch():
    """A worn two-seat couch in the P1 post (the guards' break corner). Bounds x -4..4, y -1.5..1.5, z 0..2.4,
    backrest on +Y."""
    coll = K.begin("Couch", OUT)
    r = np.random.default_rng(281)
    fabric = np.ones((256, 256, 3)) * np.array((0.22, 0.26, 0.22))
    fabric += K.blur(r.normal(0, 0.03, (256, 256)), 2)[..., None]
    fabric[::4] *= 0.92
    body = K.join("Body", [
        K.box("base", coll, -3.6, 3.6, -1.4, 1.3, 0.25, 0.95, bevel=0.1),
        K.box("back", coll, -3.6, 3.6, 0.7, 1.5, 0.9, 2.4, bevel=0.15),
        K.box("armL", coll, -4.0, -3.55, -1.45, 1.5, 0.25, 1.65, bevel=0.15),
        K.box("armR", coll, 3.55, 4.0, -1.45, 1.5, 0.25, 1.65, bevel=0.15),
    ])
    K.box_uv(body, tile=2.0)
    K.material(body, "couch_fabric", np.clip(fabric, 0, 1), roughness=0.95)
    cushions = K.join("Cushions", [
        K.box("cushL", coll, -3.55, 0.01, -1.4, 0.75, 0.9, 1.3, bevel=0.12),
        K.box("cushR", coll, -0.01, 3.55, -1.4, 0.75, 0.9, 1.3, bevel=0.12),
    ])
    K.box_uv(cushions, tile=2.0)
    K.material(cushions, "couch_cushion", np.clip(fabric * 1.15, 0, 1), roughness=0.95)
    feet = K.join("Feet", [
        K.box(f"foot{k}", coll, x - 0.15, x + 0.15, y - 0.15, y + 0.15, 0, 0.32, bevel=0.02)
        for k, (x, y) in enumerate(((-3.6, -1.15), (3.6, -1.15), (-3.6, 1.15), (3.6, 1.15)))
    ])
    K.flat(feet, "couch_feet", (0.10, 0.08, 0.06), roughness=0.6)
    return coll


BUILD = {
    "StairDoor": stair_door, "BreakerPanel": breaker_panel, "Sledgehammer": sledgehammer, "Crates": crates,
    "Boiler": boiler, "PlasterWall": plaster_wall, "FireDoor": fire_door, "Workbench": workbench, "Couch": couch,
}
for name, fn in BUILD.items():
    if WANT is None or WANT == name:
        c = fn()
        print(name, {o.name: [round(v, 2) for v in o.dimensions] for o in c.objects})
