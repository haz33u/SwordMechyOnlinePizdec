# Blender 3.0+ / 5.x — Loc1 Dark Forest low-poly swords for Roblox
# Units: 1 BU = 1 stud. +Y = tip, origin = SM_Hilt (grip).
# Run: blender --background --python tools/blender/gen_loc1_dark_forest_swords.py

import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix, Euler

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
OUT = os.path.join(ROOT, "art", "meshes", "loc1_dark_forest")
PREVIEW = os.path.join(OUT, "preview")
os.makedirs(PREVIEW, exist_ok=True)

# ---------------------------------------------------------------------------
# Materials (flat / stylized)
# ---------------------------------------------------------------------------
PALETTE = {
    "bark": (0.18, 0.12, 0.08, 1.0),
    "bark_light": (0.28, 0.20, 0.14, 1.0),
    "moss": (0.12, 0.22, 0.10, 1.0),
    "rust": (0.32, 0.20, 0.14, 1.0),
    "steel": (0.35, 0.38, 0.40, 1.0),
    "steel_dark": (0.18, 0.20, 0.22, 1.0),
    "bone": (0.72, 0.66, 0.52, 1.0),
    "cord": (0.40, 0.30, 0.18, 1.0),
    "leaf": (0.22, 0.32, 0.20, 1.0),
    "leaf_edge": (0.45, 0.55, 0.40, 1.0),
    "amber": (0.75, 0.42, 0.08, 1.0),
    "shadow": (0.08, 0.05, 0.12, 1.0),
    "violet": (0.35, 0.22, 0.55, 1.0),
    "glow_spirit": (0.35, 0.85, 0.55, 1.0),
    "glow_amber": (1.0, 0.55, 0.12, 1.0),
    "glow_shadow": (0.45, 0.25, 0.85, 1.0),
}


def ensure_mat(name, rgba, emit=0.0):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = rgba
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = 0.72
        # Emission: Blender 4+ uses Emission Color + Strength
        if emit > 0:
            if "Emission Color" in bsdf.inputs:
                bsdf.inputs["Emission Color"].default_value = rgba
                bsdf.inputs["Emission Strength"].default_value = emit
            elif "Emission" in bsdf.inputs:
                bsdf.inputs["Emission"].default_value = rgba
                if "Emission Strength" in bsdf.inputs:
                    bsdf.inputs["Emission Strength"].default_value = emit
    return mat


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.curves):
        for b in list(block):
            if b.users == 0:
                block.remove(b)


def set_units():
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0


def make_empty_hilt():
    bpy.ops.object.empty_add(type="ARROWS", location=(0, 0, 0))
    empty = bpy.context.active_object
    empty.name = "SM_Hilt"
    empty.empty_display_size = 0.25
    return empty


def apply_mat(obj, mat_name, rgba, emit=0.0):
    mat = ensure_mat(mat_name, rgba, emit)
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)


def join_objects(objs, name):
    objs = [o for o in objs if o is not None]
    if not objs:
        return None
    # Apply transforms so join keeps world-space geometry correct
    for o in objs:
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    result = bpy.context.active_object
    result.name = name
    # Grip origin at world (0,0,0) — SM_Hilt lives there
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    return result


def add_cylinder(name, radius, depth, location, rotation=(0, 0, 0), verts=8):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=verts,
        radius=radius,
        depth=depth,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.active_object
    obj.name = name
    return obj


def add_cone(name, radius1, depth, location, rotation=(0, 0, 0), verts=8):
    bpy.ops.mesh.primitive_cone_add(
        vertices=verts,
        radius1=radius1,
        radius2=0.0,
        depth=depth,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.active_object
    obj.name = name
    return obj


def add_cube(name, scale, location, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location, rotation=rotation)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return obj


def add_uv_sphere(name, radius, location, segments=8, rings=6):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments, ring_count=rings, radius=radius, location=location
    )
    obj = bpy.context.active_object
    obj.name = name
    return obj


def taper_blade_cube(obj, tip_scale_x=0.35):
    """Scale top verts toward +Y tip (assumes cube along Y after build)."""
    me = obj.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    ys = [v.co.y for v in bm.verts]
    y_min, y_max = min(ys), max(ys)
    span = max(y_max - y_min, 1e-6)
    for v in bm.verts:
        t = (v.co.y - y_min) / span  # 0 base -> 1 tip
        s = 1.0 - t * (1.0 - tip_scale_x)
        v.co.x *= s
        v.co.z *= 0.85 + 0.15 * (1.0 - t)
    bm.to_mesh(me)
    bm.free()
    me.update()


# ---------------------------------------------------------------------------
# Sword builders — grip at y=0, tip toward +Y
# ---------------------------------------------------------------------------

def build_starter_stick():
    """#1 Common — continuous oak branch sword, total ~4.0 along +Y"""
    parts = []
    # Full continuous shaft: pommel y=-1.0 → tip y=3.0  (length 4.0)
    # Grip zone centered near y=0
    shaft = add_cylinder(
        "shaft", 0.085, 3.7, (0, 0.85, 0), rotation=(math.pi / 2, 0, 0), verts=8
    )
    apply_mat(shaft, "bark", PALETTE["bark"])
    parts.append(shaft)
    # Flatten upper half into a crude blade (scale Z after apply loc/rot)
    upper = add_cylinder(
        "blade", 0.075, 2.0, (0, 1.9, 0), rotation=(math.pi / 2, 0, 0), verts=6
    )
    apply_mat(upper, "bark_light", PALETTE["bark_light"])
    upper.scale = (1.55, 1.0, 0.5)
    parts.append(upper)
    # Cord wraps on grip
    for i, y in enumerate((-0.25, -0.05, 0.15)):
        ring = add_cylinder(
            f"cord{i}", 0.11, 0.09, (0, y, 0), rotation=(math.pi / 2, 0, 0), verts=6
        )
        apply_mat(ring, "cord", PALETTE["cord"])
        parts.append(ring)
    # Broken tip cone sitting on shaft end
    tip = add_cone(
        "tip", 0.1, 0.4, (0, 3.0, 0), rotation=(-math.pi / 2, 0, 0), verts=6
    )
    apply_mat(tip, "bark_light", PALETTE["bark_light"])
    parts.append(tip)
    # Side branch stub near mid
    stub = add_cylinder(
        "stub", 0.045, 0.32, (0.16, 1.1, 0), rotation=(0, math.pi / 2, 0.35), verts=5
    )
    apply_mat(stub, "bark", PALETTE["bark"])
    parts.append(stub)
    moss = add_cube("moss", (0.1, 0.22, 0.05), (0.07, 1.55, 0.06))
    apply_mat(moss, "moss", PALETTE["moss"])
    parts.append(moss)
    pom = add_uv_sphere("pommel", 0.12, (0, -1.0, 0), segments=6, rings=4)
    apply_mat(pom, "bark", PALETTE["bark"])
    parts.append(pom)
    return join_objects(parts, "DF_StarterStick")


def build_moss_rust():
    """#2 Common — short rust sword, moss on guard, total ~4.0"""
    parts = []
    handle = add_cylinder("handle", 0.07, 1.05, (0, -0.35, 0), rotation=(math.pi / 2, 0, 0), verts=8)
    apply_mat(handle, "bark", PALETTE["bark"])
    parts.append(handle)
    guard = add_cube("guard", (0.55, 0.12, 0.10), (0, 0.25, 0))
    apply_mat(guard, "rust", PALETTE["rust"])
    parts.append(guard)
    moss_l = add_cube("moss_l", (0.14, 0.10, 0.12), (-0.28, 0.25, 0.05))
    apply_mat(moss_l, "moss", PALETTE["moss"])
    parts.append(moss_l)
    moss_r = add_cube("moss_r", (0.12, 0.08, 0.10), (0.26, 0.28, -0.04))
    apply_mat(moss_r, "moss", PALETTE["moss"])
    parts.append(moss_r)
    blade = add_cube("blade", (0.22, 2.55, 0.08), (0, 1.65, 0))
    apply_mat(blade, "steel_dark", PALETTE["steel_dark"])
    taper_blade_cube(blade, 0.28)
    parts.append(blade)
    pom = add_uv_sphere("pom", 0.09, (0, -0.9, 0), segments=6, rings=4)
    apply_mat(pom, "rust", PALETTE["rust"])
    parts.append(pom)
    return join_objects(parts, "DF_MossRust")


def build_bone_thorn():
    """#3 Common dagger — total ~3.0"""
    parts = []
    handle = add_cylinder("handle", 0.065, 0.95, (0, -0.25, 0), rotation=(math.pi / 2, 0, 0), verts=6)
    apply_mat(handle, "cord", PALETTE["cord"])
    parts.append(handle)
    wrap = add_cylinder("wrap", 0.08, 0.35, (0, -0.1, 0), rotation=(math.pi / 2, 0, 0), verts=6)
    apply_mat(wrap, "bark", PALETTE["bark"])
    parts.append(wrap)
    # Bone blade (curved-ish via offset tip)
    blade = add_cube("blade", (0.16, 1.85, 0.07), (0.03, 1.15, 0))
    apply_mat(blade, "bone", PALETTE["bone"])
    taper_blade_cube(blade, 0.2)
    parts.append(blade)
    # Thorn side
    thorn = add_cone("thorn", 0.05, 0.35, (0.12, 0.7, 0), rotation=(0, 0, -0.9), verts=5)
    apply_mat(thorn, "bone", PALETTE["bone"])
    parts.append(thorn)
    pom = add_uv_sphere("pom", 0.08, (0, -0.75, 0), segments=5, rings=4)
    apply_mat(pom, "bone", PALETTE["bone"])
    parts.append(pom)
    return join_objects(parts, "DF_BoneThorn")


def build_root_mace():
    """#4 Rare — root mace, total ~4.0"""
    parts = []
    shaft = add_cylinder("shaft", 0.09, 2.6, (0, 0.7, 0), rotation=(math.pi / 2, 0, 0), verts=7)
    apply_mat(shaft, "bark", PALETTE["bark"])
    parts.append(shaft)
    # Grip wrap
    for i, y in enumerate((-0.2, 0.0, 0.2)):
        r = add_cylinder(f"g{i}", 0.11, 0.1, (0, y, 0), rotation=(math.pi / 2, 0, 0), verts=6)
        apply_mat(r, "cord", PALETTE["cord"])
        parts.append(r)
    head = add_uv_sphere("head", 0.42, (0, 2.55, 0), segments=10, rings=8)
    apply_mat(head, "bark_light", PALETTE["bark_light"])
    parts.append(head)
    # Spikes
    for i, ang in enumerate(range(0, 360, 45)):
        rad = math.radians(ang)
        x, z = 0.38 * math.cos(rad), 0.38 * math.sin(rad)
        sp = add_cone(f"sp{i}", 0.07, 0.28, (x, 2.55, z), rotation=(math.pi / 2, 0, rad), verts=5)
        apply_mat(sp, "bark", PALETTE["bark"])
        parts.append(sp)
    moss = add_cube("moss", (0.2, 0.2, 0.12), (0.15, 2.4, 0.2))
    apply_mat(moss, "moss", PALETTE["moss"])
    parts.append(moss)
    pom = add_uv_sphere("pom", 0.12, (0, -0.65, 0), segments=6, rings=4)
    apply_mat(pom, "bark", PALETTE["bark"])
    parts.append(pom)
    return join_objects(parts, "DF_RootMace")


def build_twinleaf():
    """#5 Epic double-edge"""
    parts = []
    handle = add_cylinder("handle", 0.07, 1.05, (0, -0.3, 0), rotation=(math.pi / 2, 0, 0), verts=8)
    apply_mat(handle, "bark", PALETTE["bark"])
    parts.append(handle)
    guard = add_cube("guard", (0.7, 0.1, 0.12), (0, 0.3, 0))
    apply_mat(guard, "leaf", PALETTE["leaf"])
    parts.append(guard)
    # Leaf ends on guard
    for sx in (-1, 1):
        leaf = add_cube(f"leaf{sx}", (0.22, 0.28, 0.05), (sx * 0.45, 0.45, 0))
        apply_mat(leaf, "leaf_edge", PALETTE["leaf_edge"])
        parts.append(leaf)
    blade = add_cube("blade", (0.32, 2.6, 0.09), (0, 1.7, 0))
    apply_mat(blade, "steel", PALETTE["steel"])
    taper_blade_cube(blade, 0.25)
    parts.append(blade)
    # Center ridge
    ridge = add_cube("ridge", (0.06, 2.4, 0.11), (0, 1.65, 0))
    apply_mat(ridge, "leaf_edge", PALETTE["leaf_edge"])
    parts.append(ridge)
    pom = add_uv_sphere("pom", 0.1, (0, -0.85, 0), segments=6, rings=4)
    apply_mat(pom, "leaf", PALETTE["leaf"])
    parts.append(pom)
    return join_objects(parts, "DF_Twinleaf")


def build_spirit_branch():
    """#6 Epic staff-blade, total ~4.5"""
    parts = []
    shaft = add_cylinder("shaft", 0.08, 3.2, (0, 1.0, 0), rotation=(math.pi / 2, 0, 0), verts=7)
    apply_mat(shaft, "bark", PALETTE["bark"])
    parts.append(shaft)
    # Grip
    for i, y in enumerate((-0.15, 0.1, 0.35)):
        r = add_cylinder(f"g{i}", 0.1, 0.09, (0, y, 0), rotation=(math.pi / 2, 0, 0), verts=6)
        apply_mat(r, "cord", PALETTE["cord"])
        parts.append(r)
    # Blade tip section
    blade = add_cube("blade", (0.18, 1.2, 0.07), (0, 3.2, 0))
    apply_mat(blade, "leaf_edge", PALETTE["leaf_edge"])
    taper_blade_cube(blade, 0.22)
    parts.append(blade)
    # Spirit core (emissive)
    core = add_uv_sphere("core", 0.14, (0, 2.55, 0), segments=8, rings=6)
    apply_mat(core, "glow_spirit", PALETTE["glow_spirit"], emit=2.5)
    parts.append(core)
    # Branch forks
    for sx, sy in ((0.2, 2.1), (-0.18, 2.3)):
        br = add_cylinder(f"br{sx}", 0.04, 0.45, (sx, sy, 0.05), rotation=(0.3, math.pi / 2, 0.5), verts=5)
        apply_mat(br, "bark_light", PALETTE["bark_light"])
        parts.append(br)
    pom = add_uv_sphere("pom", 0.1, (0, -0.65, 0), segments=6, rings=4)
    apply_mat(pom, "moss", PALETTE["moss"])
    parts.append(pom)
    return join_objects(parts, "DF_SpiritBranch")


def build_amberheart():
    """#7 Legendary — dark metal + amber"""
    parts = []
    handle = add_cylinder("handle", 0.075, 1.1, (0, -0.3, 0), rotation=(math.pi / 2, 0, 0), verts=8)
    apply_mat(handle, "bark", PALETTE["bark"])
    parts.append(handle)
    guard = add_cube("guard", (0.65, 0.14, 0.14), (0, 0.35, 0))
    apply_mat(guard, "steel_dark", PALETTE["steel_dark"])
    parts.append(guard)
    # Amber heart in guard
    amber = add_uv_sphere("amber", 0.12, (0, 0.35, 0.08), segments=8, rings=6)
    apply_mat(amber, "glow_amber", PALETTE["glow_amber"], emit=3.0)
    parts.append(amber)
    blade = add_cube("blade", (0.28, 2.55, 0.09), (0, 1.75, 0))
    apply_mat(blade, "steel_dark", PALETTE["steel_dark"])
    taper_blade_cube(blade, 0.22)
    parts.append(blade)
    # Amber edge strip
    strip = add_cube("strip", (0.05, 2.2, 0.1), (0.12, 1.7, 0))
    apply_mat(strip, "amber", PALETTE["amber"], emit=0.8)
    parts.append(strip)
    pom = add_uv_sphere("pom", 0.11, (0, -0.9, 0), segments=6, rings=4)
    apply_mat(pom, "amber", PALETTE["amber"])
    parts.append(pom)
    return join_objects(parts, "DF_Amberheart")


def build_canopy_fang():
    """#8 Mythic — living long blade + vines"""
    parts = []
    handle = add_cylinder("handle", 0.08, 1.1, (0, -0.25, 0), rotation=(math.pi / 2, 0, 0), verts=8)
    apply_mat(handle, "bark", PALETTE["bark"])
    parts.append(handle)
    guard = add_cube("guard", (0.75, 0.12, 0.15), (0, 0.4, 0))
    apply_mat(guard, "leaf", PALETTE["leaf"])
    parts.append(guard)
    blade = add_cube("blade", (0.30, 2.7, 0.09), (0, 1.85, 0))
    apply_mat(blade, "leaf_edge", PALETTE["leaf_edge"])
    taper_blade_cube(blade, 0.18)
    parts.append(blade)
    for i, y in enumerate((1.0, 1.5, 2.0, 2.5)):
        fang = add_cone(f"fang{i}", 0.06, 0.18, (0.18, y, 0), rotation=(0, 0, -math.pi / 2), verts=5)
        apply_mat(fang, "leaf", PALETTE["leaf"])
        parts.append(fang)
    for i, y in enumerate((0.6, 1.1, 1.6)):
        vine = add_cylinder(f"vine{i}", 0.04, 0.35, (0.1, y, 0.05), rotation=(0.5, 0.8, 0.3), verts=5)
        apply_mat(vine, "moss", PALETTE["moss"])
        parts.append(vine)
    pom = add_uv_sphere("pom", 0.12, (0, -0.85, 0), segments=6, rings=4)
    apply_mat(pom, "leaf", PALETTE["leaf"])
    parts.append(pom)
    return join_objects(parts, "DF_CanopyFang")


def build_umbral_bough():
    """#9 Secret — shadow silhouette + violet glow edge"""
    parts = []
    handle = add_cylinder("handle", 0.075, 1.05, (0, -0.3, 0), rotation=(math.pi / 2, 0, 0), verts=7)
    apply_mat(handle, "shadow", PALETTE["shadow"])
    parts.append(handle)
    guard = add_cube("guard", (0.6, 0.1, 0.12), (0, 0.3, 0))
    apply_mat(guard, "violet", PALETTE["violet"])
    parts.append(guard)
    blade = add_cube("blade", (0.35, 2.65, 0.08), (0, 1.75, 0))
    apply_mat(blade, "shadow", PALETTE["shadow"])
    taper_blade_cube(blade, 0.2)
    parts.append(blade)
    edge = add_cube("edge", (0.04, 2.4, 0.09), (0.16, 1.7, 0))
    apply_mat(edge, "glow_shadow", PALETTE["glow_shadow"], emit=2.2)
    parts.append(edge)
    br = add_cylinder("br", 0.05, 0.5, (-0.15, 1.2, 0.05), rotation=(0.2, math.pi / 2, -0.4), verts=5)
    apply_mat(br, "shadow", PALETTE["shadow"])
    parts.append(br)
    core = add_uv_sphere("core", 0.09, (0, 0.3, 0.1), segments=6, rings=4)
    apply_mat(core, "glow_shadow", PALETTE["glow_shadow"], emit=3.5)
    parts.append(core)
    pom = add_uv_sphere("pom", 0.1, (0, -0.88, 0), segments=6, rings=4)
    apply_mat(pom, "violet", PALETTE["violet"])
    parts.append(pom)
    return join_objects(parts, "DF_UmbralBough")


SWORDS = [
    ("DF_StarterStick", build_starter_stick),
    ("DF_MossRust", build_moss_rust),
    ("DF_BoneThorn", build_bone_thorn),
    ("DF_RootMace", build_root_mace),
    ("DF_Twinleaf", build_twinleaf),
    ("DF_SpiritBranch", build_spirit_branch),
    ("DF_Amberheart", build_amberheart),
    ("DF_CanopyFang", build_canopy_fang),
    ("DF_UmbralBough", build_umbral_bough),
]


def measure_bounds(obj):
    bpy.context.view_layer.update()
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    ys = [c.y for c in corners]
    xs = [c.x for c in corners]
    zs = [c.z for c in corners]
    return {
        "y_min": min(ys),
        "y_max": max(ys),
        "length": max(ys) - min(ys),
        "width": max(xs) - min(xs),
        "depth": max(zs) - min(zs),
        "verts": len(obj.data.vertices),
        "polys": len(obj.data.polygons),
    }


def export_fbx(obj, path):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    # Also select SM_Hilt if present
    hilt = bpy.data.objects.get("SM_Hilt")
    if hilt:
        hilt.select_set(True)
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        apply_scale_options="FBX_SCALE_UNITS",
        object_types={"MESH", "EMPTY"},
        mesh_smooth_type="FACE",
        add_leaf_bones=False,
        path_mode="AUTO",
        embed_textures=False,
        axis_forward="-Z",
        axis_up="Y",
    )


def save_blend(path):
    bpy.ops.wm.save_as_mainfile(filepath=path)


def setup_preview_camera():
    # 3/4 view of upright sword (tip +Y), inventory-ish framing
    bpy.ops.object.camera_add(location=(2.8, -2.6, 1.4))
    cam = bpy.context.active_object
    cam.name = "PreviewCam"
    cam.data.lens = 50
    target = Vector((0.0, 1.0, 0.0))
    direction = target - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    # Soft grey world so silhouette reads
    world = bpy.data.worlds.new("PrevWorld") if bpy.data.worlds.get("PrevWorld") is None else bpy.data.worlds["PrevWorld"]
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.12, 0.12, 0.14, 1.0)
        bg.inputs[1].default_value = 0.6
    light_data = bpy.data.lights.new(name="Key", type="AREA")
    light_data.energy = 120
    light_obj = bpy.data.objects.new(name="Key", object_data=light_data)
    bpy.context.collection.objects.link(light_obj)
    light_obj.location = (2.5, -2.0, 3.0)
    fill = bpy.data.lights.new(name="Fill", type="AREA")
    fill.energy = 40
    fill_obj = bpy.data.objects.new(name="Fill", object_data=fill)
    bpy.context.collection.objects.link(fill_obj)
    fill_obj.location = (-2.0, 1.0, 1.5)


def render_preview(name):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items.keys() else "BLENDER_EEVEE"
    # Fallback
    try:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    except Exception:
        try:
            scene.render.engine = "BLENDER_EEVEE"
        except Exception:
            scene.render.engine = "CYCLES"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.filepath = os.path.join(PREVIEW, f"{name}.png")
    scene.render.film_transparent = True
    bpy.ops.render.render(write_still=True)


def main():
    set_units()
    report = []
    for name, builder in SWORDS:
        clear_scene()
        bpy.context.scene.cursor.location = (0, 0, 0)
        make_empty_hilt()
        obj = builder()
        if obj is None:
            report.append(f"{name}: FAILED")
            continue
        # Parent mesh to keep hierarchy optional
        hilt = bpy.data.objects.get("SM_Hilt")
        stats = measure_bounds(obj)
        fbx_path = os.path.join(OUT, f"{name}.fbx")
        blend_path = os.path.join(OUT, f"{name}.blend")
        export_fbx(obj, fbx_path)
        # Preview camera + render
        setup_preview_camera()
        try:
            render_preview(name)
        except Exception as e:
            report.append(f"{name}: preview skip ({e})")
        save_blend(blend_path)
        line = (
            f"{name}: length={stats['length']:.2f} y=[{stats['y_min']:.2f},{stats['y_max']:.2f}] "
            f"w={stats['width']:.2f} verts={stats['verts']} polys={stats['polys']}"
        )
        print(line)
        report.append(line)

    report_path = os.path.join(OUT, "BUILD_REPORT.txt")
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("\n".join(report) + "\n")
    print("DONE", OUT)


if __name__ == "__main__":
    main()
