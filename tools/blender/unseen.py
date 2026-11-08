"""The Unseen's model (CLAUDE.md, "Blender d'abord"): Adrien's rigged figure (a Tripo conversion, FBX, 7 November
2026; not in the repository), posed and baked here: a slight hunch, the head hanging and tilted, the long arms down
along the body. Scaled to unseen_height (8.5 studs), feet on the ground, the skin darkened to a cold grey so he
reads as a silhouette. Imported as ReplicatedStorage.ClientModels.Unseen (Controllers/UnseenView). POSE = "lunge"
builds the catch pose instead (Controllers/Death: bent forward, knees bent, both arms reaching out, head craned and
tilted), at the same scale, as the collection UnseenLunge (ClientModels.UnseenLunge, no longer used).
In play he has no face: he stays a mystery (Adrien, 8 Nov). Only the kill shows one ("des yeux lui sortent, une bouche
qu'on voit s'ouvrir"), on two models: POSE = "catch" is the standing pose with the face (ClientModels.UnseenCatch), POSE
= "reach" bends him down to the guard's eyes, his long arms reaching forward around their head (ClientModels.
UnseenReach). The face is cast onto the head with rays from the front: two deep slanted sockets, a pale pinpoint eye in
each (Eyes), a grin far too wide (Mouth) and two rows of needle teeth (TeethTop, TeethBottom); the client makes them
come out and open (Controllers/Death). FACE = True puts it on any pose (kept for later levels: docs/UNSEEN.md). No blood.
Run in Blender:
    FBX = r"<path to the .fbx>"; POSE = "stand"; exec(open(r"<repo>/tools/blender/unseen.py").read())
"""

import math
import os

import bpy
import numpy as np
from mathutils import Matrix, Vector

SRC = FBX if "FBX" in dir() else os.path.expanduser(r"~\Downloads\unseen.fbx")  # noqa: F821
HEIGHT = 8.5  # content/constants.csv: unseen_height (of the standing pose; the lunge keeps its scale)
WANT = POSE if "POSE" in dir() else "stand"  # noqa: F821
NAME = {"stand": "Unseen", "catch": "UnseenCatch", "lunge": "UnseenLunge", "reach": "UnseenReach"}[WANT]
# the face only on the kill's models (Adrien, 8 Nov: "de base le Unseen doit être mystérieux"); FACE = True forces it
WITH_FACE = FACE if "FACE" in dir() else WANT in ("catch", "reach")  # noqa: F821
OUT = OUT_DIR if "OUT_DIR" in dir() else os.path.join(os.path.expanduser("~"), "Documents", "Ropilot", "Blender")  # noqa: F821

old = bpy.data.collections.get(NAME)
if old:
    for o in list(old.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.collections.remove(old)
before = set(bpy.data.objects)
bpy.ops.import_scene.fbx(filepath=SRC)
new = [o for o in bpy.data.objects if o not in before]
arm = next(o for o in new if o.type == "ARMATURE")
mesh = next(o for o in new if o.type == "MESH")

# the pose, bone by bone, rotated around world axes through each bone's head (the armature is unrotated)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="POSE")


def rot(name, axis, deg):
    pb = arm.pose.bones["mixamorig:" + name]
    m = pb.matrix.copy()
    head = m.translation.copy()
    pb.matrix = Matrix.Translation(head) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-head) @ m
    bpy.context.view_layer.update()


def stand():
    rot("Spine1", "X", 6)
    rot("Spine2", "X", 8)
    rot("Neck", "X", 10)
    rot("Head", "X", 12)
    rot("Head", "Y", 14)
    rot("LeftArm", "Y", 78)
    rot("RightArm", "Y", -78)
    rot("LeftArm", "X", 6)
    rot("RightArm", "X", 6)
    rot("LeftForeArm", "X", -14)
    rot("RightForeArm", "X", -10)
    for side in ("Left", "Right"):
        for finger in ("Index", "Middle", "Ring", "Pinky"):
            for k in (1, 2):
                if arm.pose.bones.get(f"mixamorig:{side}Hand{finger}{k}"):
                    rot(f"{side}Hand{finger}{k}", "X", -18)


def lunge():
    # bent forward over the guard, knees bent, both long arms reaching out at them, the head craned and tilted
    rot("LeftUpLeg", "X", -28)
    rot("RightUpLeg", "X", -20)
    rot("LeftLeg", "X", 42)
    rot("RightLeg", "X", 34)
    rot("Spine", "X", 12)
    rot("Spine1", "X", 14)
    rot("Spine2", "X", 12)
    rot("Neck", "X", 18)
    rot("Head", "X", 6)
    rot("Head", "Y", 24)
    rot("LeftArm", "Z", -84)  # out along +x: turned toward the front (-y)
    rot("RightArm", "Z", 80)
    rot("LeftArm", "X", 34)  # down toward the guard's face: his shoulders are far above their eyes
    rot("RightArm", "X", 28)
    rot("LeftArm", "Z", -6)  # a little inward, toward the face
    rot("RightArm", "Z", 6)
    rot("LeftForeArm", "X", -4)
    rot("RightForeArm", "X", -8)
    for side in ("Left", "Right"):
        for finger in ("Index", "Middle", "Ring", "Pinky"):
            if arm.pose.bones.get(f"mixamorig:{side}Hand{finger}1"):
                rot(f"{side}Hand{finger}1", "X", -12)


def reach():
    # he bends down to the guard's eyes, face to face, his long arms reaching forward around their head, hands open
    rot("LeftUpLeg", "X", -12)
    rot("RightUpLeg", "X", -12)
    rot("LeftLeg", "X", 20)
    rot("RightLeg", "X", 20)
    rot("Spine", "X", 16)
    rot("Spine1", "X", 16)
    rot("Spine2", "X", 12)
    rot("Neck", "X", 6)
    rot("Head", "X", -38)  # the face comes back up to look straight at them
    rot("Head", "Y", 14)
    rot("LeftArm", "Z", -86)  # out along +x, turned toward the front (-y): straight at the guard
    rot("RightArm", "Z", 86)
    rot("LeftArm", "X", 20)  # level with his face (the bend of his back already lifts them)
    rot("RightArm", "X", 20)
    rot("LeftForeArm", "X", -4)
    rot("RightForeArm", "X", -4)
    rot("LeftHand", "X", -40)  # palms toward the guard, fingers up
    rot("RightHand", "X", -40)
    for side, sign in (("Left", 1), ("Right", -1)):
        for finger, spread in (("Index", -10), ("Middle", -3), ("Ring", 4), ("Pinky", 11)):
            if arm.pose.bones.get(f"mixamorig:{side}Hand{finger}1"):
                rot(f"{side}Hand{finger}1", "Y", spread * sign)
                rot(f"{side}Hand{finger}1", "X", -12)  # a little hooked, like claws
                if arm.pose.bones.get(f"mixamorig:{side}Hand{finger}2"):
                    rot(f"{side}Hand{finger}2", "X", -14)


# the standing pose sets the scale (HEIGHT); the others keep it
stand()
bpy.context.view_layer.update()
standing_height = mesh.dimensions.z
if WANT not in ("stand", "catch"):
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    {"lunge": lunge, "reach": reach}[WANT]()
bpy.ops.object.mode_set(mode="OBJECT")


# the head's frame in the posed world (his face is cast onto the baked body afterwards, along the same frame)
def head_frame():
    pb = arm.pose.bones["mixamorig:Head"]
    m = arm.matrix_world @ pb.matrix
    top = arm.pose.bones.get("mixamorig:HeadTop_End")
    up = (m.to_3x3() @ Vector((0, 1, 0))).normalized()
    base = m.translation.copy()
    tip = (arm.matrix_world @ top.matrix).translation if top else base + up * 0.25
    # his front: the bone axis that faced -y at rest, as the pose turned it
    rest = (arm.matrix_world @ pb.bone.matrix_local).to_3x3()
    best, axis = None, None
    for k in (0, 2):
        for sgn in (1, -1):
            v = (rest @ Vector([sgn if i == k else 0 for i in range(3)])).normalized()
            d = v.dot(Vector((0, -1, 0)))
            if best is None or d > best:
                best, axis = d, (k, sgn)
    fwd = (m.to_3x3() @ Vector([axis[1] if i == axis[0] else 0 for i in range(3)])).normalized()
    fwd = (fwd - up * fwd.dot(up)).normalized()
    return {"base": base, "tip": tip, "up": up, "fwd": fwd, "right": fwd.cross(up).normalized()}


frame = head_frame()

# bake the pose, drop the rig, scale and centre
bpy.context.view_layer.objects.active = mesh
for m in list(mesh.modifiers):
    if m.type == "ARMATURE":
        bpy.ops.object.modifier_apply(modifier=m.name)
mw = mesh.matrix_world.copy()
mesh.parent = None
mesh.matrix_world = mw
bpy.data.objects.remove(arm, do_unlink=True)
for o in bpy.context.selected_objects:
    o.select_set(False)
mesh.select_set(True)
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
pivot = mesh.matrix_world.translation.copy()
s = HEIGHT / standing_height
mesh.scale = (s, s, s)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
bb = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
shift = Vector(((min(v.x for v in bb) + max(v.x for v in bb)) / 2,
                (min(v.y for v in bb) + max(v.y for v in bb)) / 2, min(v.z for v in bb)))
mesh.location -= shift
bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
for key in ("base", "tip"):
    frame[key] = pivot + (frame[key] - pivot) * s - shift
mesh.name = {"stand": "Body", "catch": "CatchBody", "lunge": "LungeBody", "reach": "ReachBody"}[WANT]
mesh.data.name = mesh.name

# a darker, colder skin
mat = mesh.data.materials[0]
tex = next(n for n in mat.node_tree.nodes if n.type == "TEX_IMAGE")
img = tex.image
img.scale(1024, 1024)
px = np.array(img.pixels[:], dtype=np.float32).reshape(1024, 1024, 4)
rgb = px[..., :3]
rgb = (rgb.mean(axis=2, keepdims=True) * 0.7 + rgb * 0.3) * 0.42
rgb[..., 2:3] *= 1.08
px[..., :3] = np.clip(rgb, 0, 1)
skin = bpy.data.images.new("unseen_skin", 1024, 1024)
skin.pixels = px.ravel().tolist()
skin.filepath_raw = os.path.join(OUT, "unseen_skin.png")
skin.file_format = "PNG"
skin.save()
tex.image = skin


# his face, cast onto the baked head with rays along its front. Every feature is a thin shell laid on the head's
# surface, lifted a little toward the viewer, so it follows the egg of the head: two deep, slanted black sockets, a
# pale pinpoint eye in each (Eyes: the client lights them), a grin far too wide, rising at its ends (Mouth), and two
# rows of needle teeth between each other (TeethTop, TeethBottom: the client makes them chatter). No blood.
def face_parts(f):
    import bmesh as _bm

    # the head as seen from the front (-y): the rig's head bone is skewed on this figure, so its axes only seed the
    # search; the outline is found with rays (straight ahead, z up, x across)
    fwd, up, right = Vector((0, -1, 0)), Vector((0, 0, 1)), Vector((1, 0, 0))
    seed = (f["base"] + f["tip"]) / 2

    def hits(x, z):
        ok, loc, _, _ = mesh.ray_cast(Vector((x, -20, z)), Vector((0, 1, 0)))
        return ok

    def extent(x, z, dx, dz, step=0.02, limit=1.2):
        n = 0
        while n * step < limit and hits(x + dx * n * step, z + dz * n * step):
            n += 1
        return n * step

    cx, cz = seed.x, seed.z
    for _ in range(3):
        left, rightw = extent(cx, cz, -1, 0), extent(cx, cz, 1, 0)
        cx += (rightw - left) / 2
    w = (extent(cx, cz, -1, 0) + extent(cx, cz, 1, 0)) / 2
    # the egg is about 1.3 times as tall as it is wide: its centre under the top of the head (the neck runs on below)
    cz = cz + extent(cx, cz, 0, 1) - 1.3 * w
    centre = Vector((cx, 0, cz))
    far = 20

    def cast(a, b, out):
        origin = Vector((centre.x + a * w, -far, centre.z + b * w))
        ok, loc, _, _ = mesh.ray_cast(origin, -fwd)
        # lifted toward the viewer (a constant direction: the low-poly head's normals jump from face to face)
        return loc + fwd * (out * w) if ok else None

    def material(name, color):
        mt = bpy.data.materials.get(name) or bpy.data.materials.new(name)
        mt.use_nodes = True
        bsdf = mt.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (*color, 1)
        bsdf.inputs["Roughness"].default_value = 0.45
        return mt

    def shell(name, mat, rows):
        # rows: lists of world points (None where a ray missed); quads between neighbouring rows
        bm = _bm.new()
        grid = [[bm.verts.new(p) if p is not None else None for p in row] for row in rows]
        for i in range(len(grid) - 1):
            for j in range(len(grid[i]) - 1):
                quad = [grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]]
                if all(quad):
                    bm.faces.new(quad)
        md = bpy.data.meshes.new(name)
        bm.to_mesh(md)
        bm.free()
        o = bpy.data.objects.new(name, md)
        bpy.context.scene.collection.objects.link(o)
        o.data.materials.append(mat)
        return o

    black = material("unseen_sockets", (0.003, 0.003, 0.004))
    eyes = material("unseen_eyes", (0.86, 0.93, 0.82))
    mouth = material("unseen_mouth", (0.002, 0.002, 0.002))
    teeth = material("unseen_teeth", (0.78, 0.75, 0.64))
    parts = {"Sockets": [], "Eyes": [], "Mouth": [], "TeethTop": [], "TeethBottom": []}

    # the sockets: tall slanted ovals, their outer corners dropping
    for side in (-1, 1):
        cx, cy, rx, ry, tilt = 0.34 * side, 0.12, 0.16, 0.32, math.radians(-24 * side)
        rows = []
        for r in (0.0, 0.25, 0.5, 0.75, 1.0):
            row = []
            for j in range(25):
                t = 2 * math.pi * j / 24
                lx, ly = r * rx * math.cos(t), r * ry * math.sin(t)
                row.append(cast(cx + lx * math.cos(tilt) - ly * math.sin(tilt),
                                cy + lx * math.sin(tilt) + ly * math.cos(tilt), 0.04))
            rows.append(row)
        parts["Sockets"].append(shell("Socket", black, rows))
        # the eye: a pale pinpoint low in the socket
        p = cast(cx, cy - 0.05, 0.07)
        if p is not None:
            bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.035 * w, location=p)
            o = bpy.context.active_object
            o.data.materials.append(eyes)
            parts["Eyes"].append(o)

    # the grin: far too wide, its ends rising, tapering to points
    half = 0.66

    def centre_line(a):
        return -0.52 + 0.32 * (a / half) ** 2

    def lip(a):
        return 0.12 * max(0.0, 1 - (a / (half * 1.02)) ** 2) ** 0.5

    cols = [-half + 2 * half * j / 32 for j in range(33)]
    rows = [[cast(a, centre_line(a) + k * lip(a), 0.04) for a in cols] for k in (-1.0, -0.5, 0.0, 0.5, 1.0)]
    parts["Mouth"].append(shell("Mouth", mouth, rows))

    # the teeth: thin needles from each lip toward the middle, the two rows between each other
    for rowname, sign, shift_k in (("TeethTop", 1, 0.0), ("TeethBottom", -1, 0.5)):
        count = 15
        for k in range(count):
            a = -half * 0.86 + (2 * half * 0.86) * (k + shift_k) / (count - 1 + 0.5)
            if abs(a) > half * 0.88:
                continue
            h = lip(a)
            root = cast(a, centre_line(a) + sign * h * 0.92, 0.05)
            point = cast(a + 0.01 * sign, centre_line(a) - sign * h * (0.25 + 0.2 * ((k * 7) % 3) / 2), 0.08)
            if root is None or point is None:
                continue
            bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.024 * w, radius2=0.0, depth=(point - root).length,
                                            location=(root + point) / 2)
            o = bpy.context.active_object
            o.rotation_mode = "QUATERNION"
            o.rotation_quaternion = (point - root).to_track_quat("Z", "Y")
            o.data.materials.append(teeth)
            parts[rowname].append(o)

    joined = []
    for name, objs in parts.items():
        if not objs:
            continue
        for o in bpy.context.selected_objects:
            o.select_set(False)
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        if len(objs) > 1:
            bpy.ops.object.join()
        o = bpy.context.view_layer.objects.active
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        o.name = name
        o.data.name = name
        joined.append(o)
    return joined


pieces = [mesh] + (face_parts(frame) if WITH_FACE else [])
coll = bpy.data.collections.new(NAME)
bpy.context.scene.collection.children.link(coll)
for o in pieces:
    for c in list(o.users_collection):
        c.objects.unlink(o)
    coll.objects.link(o)
print(NAME, {o.name: [round(v, 2) for v in o.dimensions] for o in pieces})
