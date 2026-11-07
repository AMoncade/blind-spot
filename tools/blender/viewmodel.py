"""The first-person viewmodel (plan section 7: "Les mains et le caméscope en première personne ... les objets les plus
soignés du jeu"): a 1990s VHS camcorder held in two gloved hands, the uniform's navy sleeves running out of view.
The lens points to -Y (forward); the client turns it to face the camera's look. Origin: the camcorder's centre.
Separate objects: Body, Lens, Glass, Eyepiece, Handle, Mic, RecLight (the client blinks it), Trim (the client tints it
with the equipped viewfinder's colour), Strap, HandR, HandL, SleeveR, SleeveL.
    exec(open(r"<repo>/tools/blender/viewmodel.py").read())
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
coll = K.begin("Viewmodel", OUT)


def fabric(seed, base):
    r = np.random.default_rng(seed)
    size = 256
    img = np.ones((size, size, 3)) * np.array(base)
    yy, xx = np.mgrid[0:size, 0:size]
    weave = ((xx + yy) % 4 < 2) * 0.03 - 0.015
    img += weave[..., None] + r.normal(0, 0.015, (size, size, 1))
    img += K.blur(r.normal(0, 0.03, (size, size)), 5)[..., None]
    return img


# the camcorder
body = K.box("Body", coll, -0.22, 0.22, -0.45, 0.45, -0.24, 0.24, bevel=0.04)
img = Image.fromarray((K.brushed_steel(seed=201, base=(0.16, 0.16, 0.17), seams=1, grime=0.15) * 255).astype(np.uint8))
d = ImageDraw.Draw(img)
d.rectangle((300, 150, 470, 360), outline=(60, 60, 64), width=6)  # the tape door
d.text((385, 420), "HI8", fill=(170, 170, 160), font=K.font(40), anchor="mm")
K.box_uv(body, tile=1.0)
K.material(body, "vm_body", K.to_float(img), roughness=0.45, metallic=0.5)

lens = K.cylinder("Lens", coll, (0, -0.45, 0.03), (0, -0.78, 0.03), 0.17, segments=20)
K.flat(lens, "vm_lens", (0.05, 0.05, 0.055), roughness=0.5)
glass = K.cylinder("Glass", coll, (0, -0.78, 0.03), (0, -0.8, 0.03), 0.13, segments=20)
K.flat(glass, "vm_glass", (0.08, 0.12, 0.16), roughness=0.05, metallic=0.3)
eye = K.join("Eyepiece", [
    K.cylinder("tube", coll, (-0.12, 0.42, 0.17), (-0.12, 0.62, 0.17), 0.075, segments=14),
    K.cylinder("cup", coll, (-0.12, 0.6, 0.17), (-0.12, 0.68, 0.17), 0.095, segments=14),
])
K.flat(eye, "vm_rubber", (0.03, 0.03, 0.03), roughness=0.9)
handle = K.join("Handle", [
    K.box("bar", coll, -0.05, 0.05, -0.22, 0.3, 0.34, 0.4, bevel=0.02),
    K.box("postF", coll, -0.04, 0.04, -0.22, -0.16, 0.22, 0.36, bevel=0.01),
    K.box("postB", coll, -0.04, 0.04, 0.24, 0.3, 0.22, 0.36, bevel=0.01),
])
K.flat(handle, "vm_handle", (0.09, 0.09, 0.1), roughness=0.6, metallic=0.3)
mic = K.cylinder("Mic", coll, (0.1, -0.3, 0.28), (0.1, -0.62, 0.28), 0.05, segments=12)
K.flat(mic, "vm_rubber", (0.03, 0.03, 0.03), roughness=0.9)
rec = K.box("RecLight", coll, 0.12, 0.18, -0.465, -0.44, 0.13, 0.18, bevel=0.0)
K.flat(rec, "vm_rec", (1.0, 0.16, 0.12), roughness=0.3)
trim = K.box("Trim", coll, 0.215, 0.232, -0.4, 0.4, -0.035, 0.035, bevel=0.0)
K.flat(trim, "vm_trim", (0.9, 0.9, 0.9), roughness=0.4)
strap = K.box("Strap", coll, 0.22, 0.25, -0.3, 0.32, -0.16, 0.16, bevel=0.02)
K.flat(strap, "vm_strap", (0.12, 0.08, 0.05), roughness=0.8)

# the hands: gloves (a palm, the fingers wrapped as one, a thumb)
glove = (0.07, 0.065, 0.06)
handR = K.join("HandR", [
    K.box("palm", coll, 0.21, 0.37, -0.22, 0.2, -0.17, 0.16, bevel=0.06),
    K.box("fingers", coll, 0.02, 0.26, -0.2, 0.12, 0.2, 0.3, bevel=0.05),  # over the top, under the handle
    K.box("thumb", coll, 0.12, 0.26, -0.26, -0.12, 0.02, 0.14, bevel=0.04),
])
K.flat(handR, "vm_glove", glove, roughness=0.75)
handL = K.join("HandL", [
    K.box("palm", coll, -0.2, 0.14, -0.18, 0.28, -0.4, -0.23, bevel=0.06),
    K.box("fingers", coll, -0.26, -0.18, -0.16, 0.24, -0.34, -0.06, bevel=0.04),  # curled up the left side
])
K.flat(handL, "vm_glove", glove, roughness=0.75)

# the sleeves, out of view toward the bottom of the screen (+Y back, -Z down)
sleeveR = K.join("SleeveR", [
    K.cylinder("wrist", coll, (0.33, 0.12, -0.04), (0.42, 0.62, -0.3), 0.14, segments=14),
    K.cylinder("arm", coll, (0.42, 0.6, -0.29), (0.62, 1.7, -0.9), 0.17, segments=14),
])
K.box_uv(sleeveR, tile=1.0)
K.material(sleeveR, "vm_sleeve", fabric(211, (0.07, 0.09, 0.15)), roughness=0.9)
sleeveL = K.join("SleeveL", [
    K.cylinder("wrist", coll, (-0.07, 0.2, -0.32), (-0.2, 0.7, -0.55), 0.14, segments=14),
    K.cylinder("arm", coll, (-0.2, 0.68, -0.54), (-0.52, 1.7, -1.05), 0.17, segments=14),
])
K.box_uv(sleeveL, tile=1.0)
K.material(sleeveL, "vm_sleeve", fabric(211, (0.07, 0.09, 0.15)), roughness=0.9)

print({o.name: [round(v, 2) for v in o.dimensions] for o in coll.objects})

# Seen from behind (the player's view), +X is on the left: mirror the whole model so the gripping hand and the strap
# are on the right, as on a real camcorder.
import bmesh  # noqa: E402
from mathutils import Matrix  # noqa: E402

for obj in coll.objects:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.transform(bm, matrix=Matrix.Scale(-1, 4, (1, 0, 0)), verts=bm.verts)
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()
