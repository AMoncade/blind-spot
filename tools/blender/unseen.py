"""The Unseen's model (CLAUDE.md, "Blender d'abord"): Adrien's rigged figure (a Tripo conversion, FBX, 7 November
2026; not in the repository), posed and baked here: a slight hunch, the head hanging and tilted, the long arms down
along the body. Scaled to unseen_height (8.5 studs), feet on the ground, the skin darkened to a cold grey so he
reads as a silhouette. Imported as ReplicatedStorage.ClientModels.Unseen (Controllers/UnseenView). POSE = "lunge"
builds the catch pose instead (Controllers/Death: bent forward, knees bent, both arms reaching out, head craned and
tilted), at the same scale, as the collection UnseenLunge (ClientModels.UnseenLunge). Run in Blender:
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
NAME = "Unseen" if WANT == "stand" else "UnseenLunge"
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


# the standing pose sets the scale (HEIGHT); the lunge keeps it
stand()
bpy.context.view_layer.update()
standing_height = mesh.dimensions.z
if WANT == "lunge":
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    lunge()
bpy.ops.object.mode_set(mode="OBJECT")

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
s = HEIGHT / standing_height
mesh.scale = (s, s, s)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
bb = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
mesh.location -= Vector(((min(v.x for v in bb) + max(v.x for v in bb)) / 2,
                         (min(v.y for v in bb) + max(v.y for v in bb)) / 2, min(v.z for v in bb)))
bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
mesh.name = "Body" if WANT == "stand" else "LungeBody"

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

coll = bpy.data.collections.new(NAME)
bpy.context.scene.collection.children.link(coll)
for c in list(mesh.users_collection):
    c.objects.unlink(mesh)
coll.objects.link(mesh)
print(NAME, [round(v, 2) for v in mesh.dimensions])
