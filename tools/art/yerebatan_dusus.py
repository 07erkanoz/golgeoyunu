"""Build the opening's motion guide and transparent water-impact frames.

blender -b -t 6 --python tools/art/yerebatan_dusus.py -- /absolute/output
"""
import json
import math
from pathlib import Path
import random
import sys

import bpy

out = Path(sys.argv[sys.argv.index("--") + 1]).resolve()
out.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 4
scene.render.film_transparent = True
scene.render.resolution_x = 320
scene.render.resolution_y = 144
scene.render.resolution_percentage = 100
scene.render.image_settings.color_mode = "RGBA"
scene.render.fps = 24
scene.frame_start = -21
scene.frame_end = 81
scene.view_settings.view_transform = "Standard"

bpy.ops.object.camera_add(location=(0, 36, 240))
camera = bpy.context.object
camera.data.type = "ORTHO"
camera.data.ortho_scale = 320
scene.camera = camera


def ink(name, color, strength=1.0):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    nodes.clear()
    transparent = nodes.new("ShaderNodeBsdfTransparent")
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs[0].default_value = (*color, 1)
    mix = nodes.new("ShaderNodeMixShader")
    mix.inputs[0].default_value = strength
    output = nodes.new("ShaderNodeOutputMaterial")
    links = material.node_tree.links
    links.new(transparent.outputs[0], mix.inputs[1])
    links.new(emission.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], output.inputs[0])
    return material, mix.inputs[0]


def shape(name, vertices, material, depth=0):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([(x, y, depth) for x, y in vertices], [], [list(range(len(vertices)))])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(obj)
    mesh.materials.append(material)
    return obj


def key(obj, prop, frame, value):
    setattr(obj, prop, value)
    obj.keyframe_insert(data_path=prop, frame=frame)


def opacity(socket, frames):
    for frame, value in frames:
        key(socket, "default_value", frame, value)


# Sâye uses the Flame rig. This empty supplies screen-space timing and lean.
guide = bpy.data.objects.new("Sâye · düşüş (oyun kuklası)", None)
guide.empty_display_type = "ARROWS"
scene.collection.objects.link(guide)
guide.rotation_mode = "XYZ"
guide_frames = [(-21, 0.00, 0.00, -0.12), (-16, 0.17, 0.07, 0.05),
                (-10, 0.44, 0.27, 0.26), (-5, 0.73, 0.57, 0.43),
                (0, 1.00, 1.00, 0.51)]
for frame, x, y, lean in guide_frames:
    key(guide, "location", frame, (x, y, 0))
    key(guide, "rotation_euler", frame, (0, 0, lean))
def bake(obj, first, last):
    result = []
    for frame in range(first, last + 1):
        scene.frame_set(frame)
        result.append([round(v, 5) for v in
                       (obj.location.x, obj.location.y, obj.rotation_euler.z)])
    return result


def track(name, keys):
    control = bpy.data.objects.new(name, None)
    scene.collection.objects.link(control)
    for frame, x, y, angle in keys:
        key(control, "location", frame, (x, y, 0))
        key(control, "rotation_euler", frame, (0, 0, angle))
    return bake(control, keys[0][0], keys[-1][0])


swim = []
for stroke in range(3):
    for f, x, y, lean in [(0, 0, 0, 0), (5, .17, -.65, -.04),
                           (11, .49, .43, .045), (17, .84, .72, .055)]:
        swim.append((stroke * 23 + f, (stroke + x) / 3, y, lean))
swim.append((69, 1, 0, 0))
motion = {
    "fall": bake(guide, -21, 0),
    "swim": track("Sâye · üç kulaç", swim),
    "climb": track("Sâye · sete çıkış", [
        (0, 0, 0, 0), (7, .04, .03, .16), (15, .23, .44, .43),
        (23, .70, .84, .72), (34, 1, 1, 1),
    ]),
    "walk": track("Sâye · set boyunca yürüyüş", [
        (0, 0, 0, 0), (12, .11, 0, 0), (38, .49, 0, 0),
        (66, .91, 0, 0), (81, 1, 0, 0),
    ]),
}
(out / "dusus.json").write_text(json.dumps(motion, separators=(",", ":")), encoding="utf-8")

# Broken rings read as light passing through painted shadow-play leather.
for i in range(3):
    material, alpha = ink(f"Halka {i}", (0.49, 0.58, 0.48))
    start = i * 4
    for j, (first, last) in enumerate([(0.12, 2.8), (3.3, 4.4), (4.7, 6.1)]):
        angles = [first + (last - first) * k / 48 for k in range(49)]
        def edge(a, inner):
            r = 1 - inner * (0.022 + 0.014 * math.sin(a * 3) ** 2)
            return r * math.cos(a), r * math.sin(a)
        ring = shape(f"Halka {i} · {j}", [edge(a, 0) for a in angles] +
                     [edge(a, 1) for a in reversed(angles)], material, i * .01)
        key(ring, "scale", start, (10, 2, 1))
        key(ring, "scale", start + 13, (81 - i * 7, 14 - i * 1.5, 1))
        key(ring, "scale", 34, (153 - i * 12, 25 - i * 2, 1))
    opacity(alpha, [(0, 0), (start + 1, .57 - i * .12), (start + 10, .48 - i * .10), (34, 0)])

for i, direction in enumerate((-1, 1)):
    material, alpha = ink(f"Su tacı {i}", (.61, .67, .49))
    crown = shape(f"Su tacı {i}", [(direction * x, y) for x, y in [
        (0, 0), (13, 2), (24, 11), (34, 35), (41, 39), (39, 28),
        (35, 17), (33, 5), (21, -2), (8, -3)]], material, .1)
    key(crown, "scale", 0, (.08, .08, 1))
    key(crown, "scale", 4, (1, 1.11 if i == 0 else .92, 1))
    key(crown, "scale", 8, (1.34, .56, 1))
    key(crown, "scale", 12, (1.5, .08, 1))
    opacity(alpha, [(0, 0), (2, .75), (6, .57), (12, 0)])

rng = random.Random(672)
for i in range(19):
    material, alpha = ink(f"Damla {i}", (.75, .72, .47))
    rx = rng.uniform(.65, 2.1)
    drop = shape(f"Damla {i}", [(rx * math.cos(a * math.tau / 14),
                 rx * 1.6 * math.sin(a * math.tau / 14)) for a in range(14)],
                 material, .2)
    direction = -1 if i % 2 else 1
    spread = rng.uniform(28, 112)
    height = rng.uniform(15, 63)
    launch = rng.randrange(0, 4)
    duration = rng.randrange(9, 17)
    for step in range(duration + 1):
        t = step / duration
        key(drop, "location", launch + step, (direction * spread * t,
            4 * height * t * (1 - t), 0))
    opacity(alpha, [(0, 0), (launch + 1, .88), (launch + duration - 2, .62),
                    (launch + duration, 0)])

scene.frame_set(4)
scene.render.filepath = "//su_"
bpy.ops.wm.save_as_mainfile(filepath=str(out / "Yerebatan_Dusus.blend"))
if "--motion-only" not in sys.argv[sys.argv.index("--") + 2:]:
    for frame in range(0, 35, 2):
        scene.frame_set(frame)
        scene.render.filepath = str(out / f"su_{frame // 2:02}.png")
        bpy.ops.render.render(write_still=True)

# Far vault and water are a separate flat stage. Flame draws the figures,
# foreground pillars, stone landing and practical lights over this plate.
stage = bpy.data.scenes.new("Yerebatan · oyma gölge perdesi")
bpy.context.window.scene = stage
scene = stage
scene.render.engine = "CYCLES"
scene.cycles.samples = 24
scene.render.film_transparent = True
scene.render.resolution_x = 1296
scene.render.resolution_y = 672
scene.render.resolution_percentage = 100
scene.render.image_settings.color_mode = "RGBA"
scene.view_settings.view_transform = "Standard"
bpy.ops.object.camera_add(location=(390, -200, 240))
camera = bpy.context.object
camera.data.type = "ORTHO"
camera.data.ortho_scale = 1620
scene.camera = camera


def screen(name, points, material, depth=0):
    return shape(name, [(x, -y) for x, y in points], material, depth)


def rectangle(name, x, y, w, h, material, depth):
    screen(name, [(x, y), (x + w, y), (x + w, y + h), (x, y + h)], material, depth)


dark, _ = ink("Bakır mürekkep · tonoz", (.027, .017, .010), .54)
far, _ = ink("Arkadaki tonoz", (.035, .024, .016), .36)
edge, _ = ink("Oyma kenar", (.32, .18, .075), .24)
stone, _ = ink("Taşın sol kenarı", (.20, .115, .058), .19)
water, _ = ink("Sarnıç suyu", (.018, .052, .051), .30)
reflection, _ = ink("Kesik su yansımaları", (.20, .31, .25), .25)
shaft, _ = ink("Kandil perdesinden süzülen ışık", (.63, .33, .10), .12)
deep, _ = ink("Dipteki akis", (.022, .040, .045), .30)

# Cut the arches like a Karagöz backdrop, with narrow translucent scoring.
for row, (spacing, spring, height, first, material) in enumerate([
    (122, 151, 49, -450, far),
    (213, 127, 86, -500, dark),
]):
    z = .2 + .4 * row
    for x in range(first, 1300, spacing):
        width = 15 + 12 * row
        rectangle("Sütun", x - width / 2, spring, width, 329 - spring, material, z)
        rectangle("Başlık", x - width * .74, spring - 5, width * 1.48, 12, material, z + .01)
        rectangle("Kaide", x - width * .7, 309, width * 1.4, 20, material, z + .01)
        rectangle("Kenar ışığı", x - width / 2 + 2, spring + 9, 2, 169, stone, z + .02)
        for side in (0, 1):
            points = [(x + spacing * (1 - math.cos(i * math.pi / 36)) / 2,
                       spring - height * math.sin(i * math.pi / 36)) for i in range(37)]
            lift = (11 + 6 * row) if side == 0 else 2
            screen("Tonoz oyması", points + [(px, py - lift) for px, py in reversed(points)],
                   material if side == 0 else edge, z + .03 + side * .01)

for x, w, alpha_shift in [(175, 186, 1), (595, 158, -1), (945, 110, 1)]:
    screen("Süzülen altın ışık", [(x - 13, -135), (x + 14, -135),
           (x + w / 2 + 56 * alpha_shift, 327), (x - w / 2 + 56 * alpha_shift, 327)],
           shaft, .05)

screen("Su yüzeyi", [(-420, 330), (1200, 330), (1200, 620), (-420, 620)], water, .15)
stage_rng = random.Random(38)
for i in range(180):
    x = stage_rng.uniform(-450, 1190)
    y = stage_rng.uniform(332, 566)
    length = stage_rng.uniform(8, 95)
    h = stage_rng.uniform(.55, 2.8)
    if 435 < x < 660 and y < 347:
        continue
    screen("Yansıma · kırık çizgi", [(x, y), (x + length * .84, y),
           (x + length, y + h * .38), (x + length * .19, y + h)],
           reflection if i % 4 == 0 else deep, .29)

scene.render.filepath = str(out / "zemin.png")
bpy.ops.render.render(write_still=True)
scene.render.filepath = "//zemin.png"
bpy.ops.wm.save_as_mainfile(filepath=str(out / "Yerebatan_Dusus.blend"))
