"""The lobby's furniture (Config.LobbyProps): SecurityDesk, NoticeBoard, Bench. One collection each, front toward -Y.
Run in Blender:  exec(open(r"<repo>/tools/blender/lobby_props.py").read())   (set ONLY = "Bench" for one model)
"""

import importlib
import os
import sys

REPO = os.environ.get("BLINDSPOT_REPO", r"C:\Users\adrie\blind-spot")
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import bs_kit as K  # noqa: E402

importlib.reload(K)
from PIL import Image, ImageDraw  # noqa: E402
import numpy as np  # noqa: E402

OUT = OUT_DIR if "OUT_DIR" in dir() else os.path.join(REPO, "build", "blender")  # noqa: F821
WANT = ONLY if "ONLY" in dir() else None  # noqa: F821


def security_desk():
    """The Kestrel & Vane check-in counter, the guard's chair and the CCTV monitor wall behind it.
    Bounds: x -6.2..6.2, y -3.8..3.5, z 0..7."""
    coll = K.begin("SecurityDesk", OUT)
    body = K.join("Counter", [
        K.box("sideL", coll, -6.0, -5.7, -3.0, -1.2, 0, 2.6),
        K.box("sideR", coll, 5.7, 6.0, -3.0, -1.2, 0, 2.6),
        K.box("work", coll, -6.0, 6.0, -3.05, -1.2, 2.6, 2.75),
        K.box("plinth", coll, -5.9, 5.9, -3.3, -2.9, 0, 0.3),
    ])
    K.box_uv(body, tile=6.0)
    K.material(body, "desk_laminate", K.laminate(seed=21), roughness=0.55)

    # the counter front, with its name in brass letters
    front = K.box("CounterFront", coll, -6.0, 6.0, -3.5, -3.0, 0.3, 3.6, bevel=0.02)
    img = Image.fromarray((K.laminate(seed=22, size=1024, base=(0.15, 0.14, 0.135)) * 255).astype(np.uint8), "RGB")
    img = img.resize((1024, 280))
    d = ImageDraw.Draw(img)
    d.line((40, 40, 984, 40), fill=(150, 120, 74), width=4)
    d.line((40, 240, 984, 240), fill=(150, 120, 74), width=4)
    d.text((512, 110), "KESTREL & VANE", fill=(201, 164, 106), font=K.font(78), anchor="mm")
    d.text((512, 185), "NIGHT SECURITY  -  CHECK-IN", fill=(160, 132, 88), font=K.font(34), anchor="mm")
    K.face_uv(front, "y", -6.0, 6.0, 0.3, 3.6)
    K.material(front, "desk_front", K.to_float(img), roughness=0.5)

    ledge = K.box("Ledge", coll, -6.2, 6.2, -3.8, -2.6, 3.6, 3.8)
    K.box_uv(ledge, tile=4.0)
    K.material(ledge, "desk_ledge_wood", K.wood(seed=23, base=(0.30, 0.18, 0.10), plank=512), roughness=0.45)

    book = K.box("LogBook", coll, -2.6, -1.2, -2.6, -1.6, 2.75, 2.95, bevel=0.02)
    K.flat(book, "desk_logbook", (0.32, 0.08, 0.06), roughness=0.7)

    chair = K.join("Chair", [
        K.box("seat", coll, -0.9, 0.9, -0.3, 1.4, 1.6, 1.9, bevel=0.08),
        K.box("back", coll, -0.85, 0.85, 1.3, 1.55, 1.82, 4.0, bevel=0.08),
        K.cylinder("column", coll, (0, 0.55, 0.12), (0, 0.55, 1.66), 0.12),
        K.box("baseX", coll, -1.1, 1.1, 0.45, 0.65, 0, 0.2),
        K.box("baseY", coll, -0.1, 0.1, -0.5, 1.6, 0, 0.2),
    ])
    K.flat(chair, "desk_chair", (0.07, 0.07, 0.08), roughness=0.8)

    rack = K.join("Rack", [
        K.box("frame", coll, -5.6, 5.6, 2.55, 3.5, 0, 7.0),
        K.box("shelf", coll, -5.6, 5.6, 1.6, 3.5, 1.0, 1.5),
    ])
    K.box_uv(rack, tile=6.0)
    K.material(rack, "desk_rack", K.brushed_steel(seed=24, base=(0.12, 0.12, 0.13), seams=3, grime=0.1),
               roughness=0.5, metallic=0.7)
    cams = ["CAM 01  BOOTH", "CAM 03  P3 WEST", "CAM 04  P3 EAST", "CAM 05  STALLS", "CAM 07  STALLS",
            "CAM 09  P3 SW", "CAM 10  SERVICE", "CAM 11  SERVICE", "CAM 14  ---"]
    screens = K.box("Screens", coll, -5.3, 5.3, 2.5, 2.56, 1.7, 6.8, bevel=0.0)
    K.face_uv(screens, "y", -5.3, 5.3, 1.7, 6.8)
    K.material(screens, "desk_screens", K.screens(seed=25, cams=cams), roughness=0.2)
    return coll


def notice_board():
    """Cork board in a wood frame, hung on a wall: MISSING, the night rules, the shift log. Bounds x -4..4, z 0..5."""
    coll = K.begin("NoticeBoard", OUT)
    frame = K.join("BoardFrame", [
        K.box("back", coll, -4.0, 4.0, 0.05, 0.3, 0, 5.0),
        K.box("top", coll, -4.0, 4.0, -0.08, 0.3, 4.7, 5.0),
        K.box("bottom", coll, -4.0, 4.0, -0.08, 0.3, 0, 0.3),
        K.box("left", coll, -4.0, -3.7, -0.08, 0.3, 0.3, 4.7),
        K.box("right", coll, 3.7, 4.0, -0.08, 0.3, 0.3, 4.7),
    ])
    K.box_uv(frame, tile=4.0)
    K.material(frame, "board_frame_wood", K.wood(seed=31, base=(0.28, 0.17, 0.09), plank=512), roughness=0.5)
    cork = K.box("Cork", coll, -3.72, 3.72, -0.02, 0.06, 0.28, 4.72, bevel=0.0)
    K.face_uv(cork, "y", -3.72, 3.72, 0.28, 4.72)
    K.material(cork, "board_cork", K.notice_board(seed=32), roughness=0.85)
    return coll


def bench():
    """A lobby bench: steel frame, three seat slats and two back slats in wood. Bounds x -3..3, y -0.8..0.8, z 0..2.8."""
    coll = K.begin("Bench", OUT)
    steel = []
    for x in (-2.6, 2.6):
        steel += [
            K.box(f"legF{x}", coll, x - 0.08, x + 0.08, -0.7, -0.55, 0, 1.45),
            K.box(f"legB{x}", coll, x - 0.08, x + 0.08, 0.6, 0.75, 0, 2.8),
            K.box(f"rail{x}", coll, x - 0.08, x + 0.08, -0.72, 0.75, 1.3, 1.48),
        ]
    steel.append(K.box("stretcher", coll, -2.6, 2.6, 0.6, 0.75, 0.4, 0.55))
    frame = K.join("BenchFrame", steel)
    K.flat(frame, "bench_steel", (0.10, 0.10, 0.11), roughness=0.4, metallic=0.8)
    slats = []
    for k, y in enumerate((-0.8, -0.32, 0.16)):
        slats.append(K.box(f"seat{k}", coll, -3.0, 3.0, y, y + 0.42, 1.45, 1.6))
    for k, z in enumerate((1.95, 2.4)):
        slats.append(K.box(f"backrest{k}", coll, -3.0, 3.0, 0.48, 0.63, z, z + 0.38))
    wood = K.join("BenchWood", slats)
    K.box_uv(wood, tile=6.0)
    K.material(wood, "bench_wood", K.wood(seed=41, base=(0.42, 0.27, 0.15), plank=512), roughness=0.55)
    return coll


def street_lamp():
    """A street lamp seen through the lobby glass: a pole, an arm over the street (-Y) and a head whose underside
    (LampGlow) World lights with a SpotLight. Bounds: x -0.6..0.6, y -4.6..0.4, z 0..14."""
    coll = K.begin("StreetLamp", OUT)
    pole = K.join("Pole", [
        K.box("base", coll, -0.6, 0.6, -0.6, 0.4, 0, 0.8),
        K.cylinder("pole", coll, (0, -0.1, 0.7), (0, -0.1, 13.7), 0.22, segments=12),
        K.box("arm", coll, -0.12, 0.12, -4.0, 0.0, 13.4, 13.7),
        K.box("head", coll, -0.5, 0.5, -4.6, -3.1, 13.3, 14.0),
    ])
    K.box_uv(pole, tile=4.0)
    K.material(pole, "lamp_pole", K.brushed_steel(seed=51, base=(0.16, 0.17, 0.18), seams=1, grime=0.3),
               roughness=0.6, metallic=0.6)
    glow = K.box("LampGlow", coll, -0.4, 0.4, -4.5, -3.2, 13.25, 13.31, bevel=0.0)
    K.flat(glow, "lamp_glow", (1.0, 0.86, 0.62), roughness=0.3)
    return coll


BUILD = {"SecurityDesk": security_desk, "NoticeBoard": notice_board, "Bench": bench, "StreetLamp": street_lamp}
for name, fn in BUILD.items():
    if WANT is None or WANT == name:
        c = fn()
        print(name, {o.name: [round(v, 2) for v in o.dimensions] for o in c.objects})
