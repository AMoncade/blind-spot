"""The lobby's service lift (Config.Lifts, server LobbyService): cabin, door frame and two sliding doors.
Run in Blender:  exec(open(r"<repo>/tools/blender/lobby_elevator.py").read())
Origin: the cabin centre on its floor. The cabin inside is 7 x 7.5 studs (lift_zone_width/depth), 8.4 high. The hall
wall is 1 stud thick in front of it (Roblox z 117..118 when the cabin centre is at z 113.25): the doors sit in the
wall's 6 x 8 opening, the frame on the hall face. DoorL and DoorR stay separate: LobbyService slides them.
Bounds: x -4..4, y -5.15..4.05, z 0..9.2 (the bounds centre is 0.55 toward the hall: Config lift_model_dz).
"""

import importlib
import os
import sys

REPO = os.environ.get("BLINDSPOT_REPO", r"C:\Users\adrie\blind-spot")
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import bs_kit as K  # noqa: E402

importlib.reload(K)
import numpy as np  # noqa: E402

NAME = "Elevator"
coll = K.begin(NAME, OUT_DIR if "OUT_DIR" in dir() else os.path.join(REPO, "build", "blender"))  # noqa: F821

W, D, H, T = 3.5, 3.75, 8.4, 0.3  # half width, half depth, height, wall thickness
FRONT = -D  # the cabin front (the hall wall's back face)
WALL0, WALL1 = FRONT - 1.0, FRONT  # the hall wall's thickness, y
DOOR_Y = (WALL0 + WALL1) / 2

# cabin: floor, back and side walls, ceiling (one brushed steel mesh), the floor in rubber
walls = K.join("Cabin", [
    K.box("back", coll, -W - T, W + T, D, D + T, 0, H + 0.2),
    K.box("left", coll, -W - T, -W, FRONT - 0.25, D, 0, H + 0.2),
    K.box("right", coll, W, W + T, FRONT - 0.25, D, 0, H + 0.2),
    K.box("ceiling", coll, -W - T, W + T, FRONT - 0.25, D + T, H, H + 0.2),
    # the front wall around the opening, inside the cabin (the hall wall covers it from the hall)
    K.box("frontL", coll, -W, -3.0, FRONT - 0.25, FRONT + 0.05, 0, H),
    K.box("frontR", coll, 3.0, W, FRONT - 0.25, FRONT + 0.05, 0, H),
    K.box("frontTop", coll, -3.0, 3.0, FRONT - 0.25, FRONT + 0.05, 8.0, H),
])
K.box_uv(walls, tile=8.0)
K.material(walls, "lift_cabin_steel", K.brushed_steel(seed=11, seams=4), roughness=0.35, metallic=0.9)

floor = K.box("Floor", coll, -W, W, FRONT - 0.2, D, 0, 0.08, bevel=0.01)
K.box_uv(floor, tile=4.0)
K.material(floor, "lift_floor_rubber", K.rubber_floor(seed=12), roughness=0.9)

rail = K.join("Rail", [
    K.cylinder("bar", coll, (-W + 0.4, D - 0.35, 3.2), (W - 0.4, D - 0.35, 3.2), 0.08),
    K.cylinder("postL", coll, (-W + 0.6, D - 0.35, 3.2), (-W + 0.6, D, 3.2), 0.06),
    K.cylinder("postR", coll, (W - 0.6, D - 0.35, 3.2), (W - 0.6, D, 3.2), 0.06),
])
K.flat(rail, "lift_rail", (0.75, 0.74, 0.70), roughness=0.25, metallic=1.0)

light = K.box("Light", coll, -2.0, 2.0, -1.5, 1.5, H - 0.08, H, bevel=0.02)
K.flat(light, "lift_light", (0.95, 0.96, 1.0), roughness=0.3)

# the doors, closed, in the hall wall's opening (x -3..3, z 0..8)
for name, x0, x1 in (("DoorL", -2.98, 0.0), ("DoorR", 0.0, 2.98)):
    door = K.box(name, coll, x0, x1, DOOR_Y - 0.09, DOOR_Y + 0.09, 0.08, 7.98, bevel=0.015)
    K.box_uv(door, tile=6.0)
    K.material(door, "lift_door_steel", K.brushed_steel(seed=13, base=(0.66, 0.66, 0.67), seams=1, grime=0.2),
               roughness=0.3, metallic=0.9)

# the frame on the hall face: two jambs and a header with the floor indicator, a threshold
HALL = WALL0  # the hall face of the wall
frame = K.join("Frame", [
    K.box("jambL", coll, -4.0, -3.0, HALL - 0.4, HALL + 0.02, 0, 9.2),
    K.box("jambR", coll, 3.0, 4.0, HALL - 0.4, HALL + 0.02, 0, 9.2),
    K.box("header", coll, -3.0, 3.0, HALL - 0.4, HALL + 0.02, 8.0, 9.2),
    K.box("revealL", coll, -3.05, -2.98, HALL, WALL1, 0, 8.0, bevel=0.0),
    K.box("revealR", coll, 2.98, 3.05, HALL, WALL1, 0, 8.0, bevel=0.0),
    K.box("revealTop", coll, -3.05, 3.05, HALL, WALL1, 7.98, 8.05, bevel=0.0),
    K.box("sill", coll, -3.0, 3.0, HALL - 0.4, FRONT, 0, 0.08, bevel=0.01),
])
K.box_uv(frame, tile=6.0)
bronze = K.brushed_steel(seed=14, base=(0.24, 0.20, 0.16), seams=1, grime=0.05)
K.material(frame, "lift_frame_bronze", bronze, roughness=0.4, metallic=0.8)

indicator = K.box("Indicator", coll, -0.9, 0.9, HALL - 0.41, HALL - 0.37, 8.25, 8.95, bevel=0.01)
K.flat(indicator, "lift_indicator", (1.0, 0.45, 0.12), roughness=0.4)

result = {o.name: [round(v, 2) for v in o.dimensions] for o in coll.objects}
print(result)
