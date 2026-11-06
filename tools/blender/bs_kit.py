"""Shared helpers for BLIND SPOT's Blender models (CLAUDE.md, "Blender d'abord": every model is a script that rebuilds
it from scratch). 1 Blender unit = 1 stud, +Z up, the front faces -Y (it faces +Z in Roblox after the import).
Textures are drawn here with numpy and Pillow, saved as PNG next to the .blend, and used as the Base Color of one
material per object (Roblox: one material per mesh). No blood, no real brands (plan section 7).
"""

import math
import os

import bmesh
import bpy
import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUT = None  # set by begin(): the folder for textures and the .blend


def begin(name, out_dir):
    """Clears the collection `name` (objects, meshes, materials it used) and returns a fresh one."""
    global OUT
    OUT = out_dir
    os.makedirs(os.path.join(OUT, "textures"), exist_ok=True)
    old = bpy.data.collections.get(name)
    if old:
        for obj in list(old.objects):
            mesh = obj.data
            bpy.data.objects.remove(obj, do_unlink=True)
            if mesh and mesh.users == 0:
                bpy.data.meshes.remove(mesh)
        bpy.data.collections.remove(old)
    coll = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(coll)
    return coll


def _link(obj, coll):
    coll.objects.link(obj)
    return obj


def box(name, coll, x0, x1, y0, y1, z0, z1, bevel=0.03):
    """An axis-aligned box from its bounds, with a small bevel (no perfectly sharp edge, plan section 7)."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x = x0 if v.co.x < 0 else x1
        v.co.y = y0 if v.co.y < 0 else y1
        v.co.z = z0 if v.co.z < 0 else z1
    if bevel > 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=1, affect="EDGES")
    bm.to_mesh(mesh)
    bm.free()
    return _link(bpy.data.objects.new(name, mesh), coll)


def cylinder(name, coll, a, b, radius, segments=12):
    """A cylinder from point a to point b."""
    a, b = np.array(a, float), np.array(b, float)
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius, radius2=radius, depth=1.0)
    d = b - a
    length = float(np.linalg.norm(d))
    from mathutils import Matrix, Vector

    rot = Vector((0, 0, 1)).rotation_difference(Vector(d / length)).to_matrix().to_4x4()
    m = Matrix.Translation(Vector((a + b) / 2)) @ rot @ Matrix.Diagonal((1, 1, length, 1))
    bmesh.ops.transform(bm, matrix=m, verts=bm.verts)
    bm.to_mesh(mesh)
    bm.free()
    return _link(bpy.data.objects.new(name, mesh), coll)


def join(name, objs):
    """Joins objects into the first one (same material, never moves on its own), merges doubles."""
    objs = [o for o in objs if o]
    target = objs[0]
    bm = bmesh.new()
    for o in objs:
        tmp = o.data.copy()
        tmp.transform(o.matrix_world)
        bm.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    coll = target.users_collection[0]
    for o in objs:
        old = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        if old.users == 0:
            bpy.data.meshes.remove(old)
    return _link(bpy.data.objects.new(name, mesh), coll)


def box_uv(obj, tile=4.0, offset=(0.0, 0.0)):
    """Box mapping: each face takes the two world axes across its normal, `tile` studs per texture repeat."""
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    uv = bm.loops.layers.uv.verify()
    mw = obj.matrix_world
    for f in bm.faces:
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for loop in f.loops:
            co = mw @ loop.vert.co
            if ax == 0:
                u, v = co.y * (-1 if n[0] < 0 else 1), co.z
            elif ax == 1:
                u, v = co.x * (1 if n[1] < 0 else -1), co.z
            else:
                u, v = co.x, co.y
            loop[uv].uv = (u / tile + offset[0], v / tile + offset[1])
    bm.to_mesh(mesh)
    bm.free()


def face_uv(obj, axis, x0, x1, y0, y1):
    """Planar mapping of the whole object onto one image: world (a, b) -> (0..1, 0..1). axis: the axis it faces."""
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    uv = bm.loops.layers.uv.verify()
    mw = obj.matrix_world
    for f in bm.faces:
        for loop in f.loops:
            co = mw @ loop.vert.co
            a, b = (co.x, co.z) if axis == "y" else (co.y, co.z) if axis == "x" else (co.x, co.y)
            loop[uv].uv = ((a - x0) / (x1 - x0), (b - y0) / (y1 - y0))
    bm.to_mesh(mesh)
    bm.free()


def material(obj, name, pixels, roughness=0.6, metallic=0.0):
    """One material with the image as Base Color. pixels: (h, w, 3) floats 0..1, row 0 at the top."""
    path = os.path.join(OUT, "textures", name + ".png")
    img8 = (np.clip(pixels, 0, 1) * 255).astype(np.uint8)
    Image.fromarray(img8, "RGB").save(path)
    img = bpy.data.images.get(name + ".png")
    if img:
        img.filepath = path
        img.reload()
    else:
        img = bpy.data.images.load(path)
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = img
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    mat.node_tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    return mat


def flat(obj, name, rgb, roughness=0.5, metallic=0.0):
    """A plain colour material (imports as a solid colour)."""
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    return mat


# ---------------------------------------------------------------- textures (numpy, seeded: the same every run)

def _rng(seed):
    return np.random.default_rng(seed)


def blur(a, k=2):
    out = a.copy()
    for _ in range(k):
        out = (out + np.roll(out, 1, 0) + np.roll(out, -1, 0) + np.roll(out, 1, 1) + np.roll(out, -1, 1)) / 5
    return out


def brushed_steel(seed=1, size=512, base=(0.58, 0.59, 0.61), seams=4, grime=0.12):
    r = _rng(seed)
    # brushed: streaks run along each row, plus fine noise
    streak = r.normal(0, 1, (size, 1)) * 0.035 + r.normal(0, 1, (size, size)) * 0.018
    img = np.ones((size, size, 3)) * np.array(base) + streak[..., None]
    # dirt toward the bottom of each panel, panel seams
    yy = np.linspace(0, 1, size)[:, None]
    img *= (1 - grime * yy ** 3)[..., None]
    for k in range(1, seams):
        x = k * size // seams
        img[:, x - 1 : x + 2] *= 0.55
    return img


def rubber_floor(seed=2, size=512):
    r = _rng(seed)
    img = np.ones((size, size, 3)) * 0.13 + r.normal(0, 0.012, (size, size, 1))
    yy, xx = np.mgrid[0:size, 0:size]
    dots = ((xx % 32 - 16) ** 2 + (yy % 32 - 16) ** 2) < 30
    img[dots] += 0.05
    img += blur(r.normal(0, 0.03, (size, size)), 6)[..., None]
    return img


def wood(seed=3, size=512, base=(0.36, 0.22, 0.13), plank=128):
    r = _rng(seed)
    yy, xx = np.mgrid[0:size, 0:size].astype(float)
    grain = np.sin(yy * 0.35 + 3 * np.sin(xx * 0.01 + r.uniform(0, 6))) * 0.05
    img = np.ones((size, size, 3)) * np.array(base) + grain[..., None] + r.normal(0, 0.01, (size, size, 1))
    for k in range(0, size, plank):
        img[k : k + 3] *= 0.5
    return img


def laminate(seed=4, size=512, base=(0.20, 0.19, 0.18)):
    r = _rng(seed)
    img = np.ones((size, size, 3)) * np.array(base) + blur(r.normal(0, 0.02, (size, size)), 3)[..., None]
    img[:, :] += r.normal(0, 0.006, (size, size, 1))
    return img


def font(size):
    for path in ("C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/consolab.ttf", "C:/Windows/Fonts/arial.ttf"):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def to_float(img):
    return np.asarray(img.convert("RGB")).astype(float) / 255.0


def screens(seed=5, size=1024, cols=3, rows=3, cams=None):
    """A wall of CCTV monitors: dim grey-green views of a parking garage drawn as noise and pillars, a camera label."""
    r = _rng(seed)
    img = Image.new("RGB", (size, size), (14, 15, 16))
    d = ImageDraw.Draw(img)
    f = font(size // 28)
    w, h = size // cols, size // rows
    k = 0
    for j in range(rows):
        for i in range(cols):
            x0, y0 = i * w + 10, j * h + 10
            x1, y1 = x0 + w - 20, y0 + h - 20
            view = (r.normal(0, 1, (y1 - y0, x1 - x0)) * 10 + 60).clip(0, 255)
            # a horizon line, pillars and a floor gradient: a garage seen from the ceiling
            hz = int((y1 - y0) * r.uniform(0.35, 0.5))
            view[:hz] *= 0.55
            view[hz:] *= np.linspace(0.8, 1.25, (y1 - y0) - hz)[:, None]
            for _ in range(r.integers(2, 4)):
                px = r.integers(10, x1 - x0 - 30)
                pw = r.integers(10, 26)
                view[: hz + r.integers(20, 60), px : px + pw] *= 0.45
            view[::3] *= 0.85  # scan lines
            tile = np.stack([view * 0.75, view, view * 0.85], -1).clip(0, 255).astype(np.uint8)
            img.paste(Image.fromarray(tile, "RGB"), (x0, y0))
            k += 1
            label = cams[k - 1] if cams and k - 1 < len(cams) else f"CAM {k:02d}"
            d.text((x0 + 12, y0 + 8), label, fill=(225, 230, 225), font=f)
            d.ellipse((x1 - 34, y0 + 12, x1 - 18, y0 + 28), fill=(220, 40, 30))
    return to_float(img)


def notice_board(seed=6, w=1024, h=640):
    """Cork with pinned papers: a MISSING notice (a grey silhouette, no face), the night rules, shift sheets."""
    r = _rng(seed)
    cork = np.ones((h, w, 3)) * np.array([0.55, 0.40, 0.26]) + r.normal(0, 0.05, (h, w, 1))
    cork += blur(r.normal(0, 0.05, (h, w)), 4)[..., None]
    img = Image.fromarray((cork.clip(0, 1) * 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)
    big, mid, small = font(64), font(30), font(20)

    def paper(x, y, pw, ph, tint=(232, 228, 214)):
        d.rectangle((x + 6, y + 6, x + pw + 6, y + ph + 6), fill=(70, 50, 34))
        d.rectangle((x, y, x + pw, y + ph), fill=tint)
        d.ellipse((x + pw // 2 - 7, y + 4, x + pw // 2 + 7, y + 18), fill=(190, 40, 40))

    # MISSING
    paper(60, 50, 300, 470)
    d.text((80, 70), "MISSING", fill=(20, 20, 20), font=big)
    d.rectangle((95, 160, 325, 360), fill=(150, 150, 150))
    d.ellipse((175, 185, 245, 255), fill=(95, 95, 95))
    d.rectangle((160, 255, 260, 360), fill=(95, 95, 95))
    d.text((85, 375), "D. HALLORAN", fill=(20, 20, 20), font=mid)
    d.text((85, 415), "NIGHT GUARD. LAST SEEN: P3", fill=(40, 40, 40), font=font(17))
    d.text((85, 445), "OCT 1998", fill=(40, 40, 40), font=small)
    # the rules
    paper(420, 60, 290, 360, (240, 236, 210))
    d.text((440, 85), "NIGHT RULES", fill=(140, 20, 20), font=mid)
    for k, line in enumerate(["1. STAY ON CAMERA.", "2. WATCH THE RED LIGHTS.", "3. WHEN THE POWER DIES,",
                              "    FIND A LIGHT THAT STAYS.", "4. NEVER LEAVE P3 DARK.", "5. DO NOT LOOK FOR HIM."]):
        d.text((440, 140 + k * 42), line, fill=(30, 30, 30), font=small)
    # shift sheets
    paper(760, 80, 210, 260, (220, 226, 232))
    d.text((775, 100), "SHIFT LOG", fill=(30, 30, 60), font=small)
    for k in range(8):
        d.line((775, 140 + k * 24, 950, 140 + k * 24), fill=(150, 160, 180), width=2)
    paper(760, 380, 210, 200, (236, 224, 160))
    d.text((775, 400), "KESTREL & VANE", fill=(30, 30, 30), font=small)
    d.text((775, 430), "NOW HIRING", fill=(30, 30, 30), font=font(23))
    d.text((775, 475), "NO EXPERIENCE", fill=(30, 30, 30), font=small)
    d.text((775, 500), "REQUIRED", fill=(30, 30, 30), font=small)
    paper(420, 460, 290, 120, (232, 228, 214))
    d.text((440, 490), "CAM 14 TURNS BY ITSELF.", fill=(30, 30, 30), font=small)
    d.text((440, 520), "DON'T REPORT IT.", fill=(30, 30, 30), font=small)
    return to_float(img)


def save_blend(name):
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, name + ".blend"))
