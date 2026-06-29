#!/usr/bin/env python3
"""Blender script for rendering Meshy GLB models into directional PNG sequences.

Run through Blender, for example:

/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/art/render_directional_sprites.py -- \
  --model /private/tmp/emberfall_phase6b/crawler/Meshy_AI_Emberclad_Golem_quadruped/Meshy_AI_Emberclad_Golem_quadruped_model_Animation_Walking_withSkin.glb \
  --entity crawler --animation walk --output assets/sprites/enemies/crawler/generated --frame-size 96 --frames 8 --directions 8
"""

import argparse
import math
import os
from pathlib import Path

import bpy
from mathutils import Vector


def parse_args() -> argparse.Namespace:
    args = []
    if "--" in os.sys.argv:
        args = os.sys.argv[os.sys.argv.index("--") + 1 :]
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--entity", required=True)
    parser.add_argument("--animation", default="walk")
    parser.add_argument("--source-action")
    parser.add_argument("--output", required=True)
    parser.add_argument("--frame-size", type=int, default=96)
    parser.add_argument("--frames", type=int, default=8)
    parser.add_argument("--directions", type=int, default=8)
    parser.add_argument("--camera-pitch", type=float, default=50.0)
    parser.add_argument("--samples", type=int, default=64)
    parser.add_argument("--ortho-padding", type=float, default=1.35)
    parser.add_argument("--emission-strength", type=float, default=0.0)
    parser.add_argument("--exposure", type=float, default=0.0)
    parser.add_argument("--recenter-motion", action="store_true")
    return parser.parse_args(args)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def import_model(path: str) -> list[bpy.types.Object]:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    imported = [obj for obj in bpy.data.objects if obj not in before]
    for obj in list(imported):
        if obj.type in {"CAMERA", "LIGHT"}:
            bpy.data.objects.remove(obj, do_unlink=True)
            imported.remove(obj)
        elif obj.type == "MESH" and len(obj.data.vertices) < 100:
            bpy.data.objects.remove(obj, do_unlink=True)
            imported.remove(obj)
    return imported


def bounds_for(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    mins = Vector((math.inf, math.inf, math.inf))
    maxs = Vector((-math.inf, -math.inf, -math.inf))
    found = False
    for obj in objects:
        if obj.type != "MESH":
            continue
        for corner in obj.bound_box:
            world = obj.matrix_world @ Vector(corner)
            mins.x = min(mins.x, world.x)
            mins.y = min(mins.y, world.y)
            mins.z = min(mins.z, world.z)
            maxs.x = max(maxs.x, world.x)
            maxs.y = max(maxs.y, world.y)
            maxs.z = max(maxs.z, world.z)
            found = True
    if not found:
        raise RuntimeError("Imported model has no renderable bounds")
    return mins, maxs


def normalize_model(objects: list[bpy.types.Object], target_height: float = 2.0) -> bpy.types.Object:
    root = bpy.data.objects.new("EMBERFALL_RENDER_ROOT", None)
    bpy.context.collection.objects.link(root)
    root.empty_display_type = "PLAIN_AXES"
    top_level = [obj for obj in objects if obj.parent is None]
    for obj in top_level:
        obj.parent = root
    mins, maxs = bounds_for(objects)
    center = (mins + maxs) * 0.5
    height = max(0.001, maxs.z - mins.z)
    scale = target_height / height
    for obj in top_level:
        obj.location -= center
    root.scale = (scale, scale, scale)
    bpy.context.view_layer.update()
    return root


def look_at(obj: bpy.types.Object, target: Vector) -> None:
    direction = target - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_scene(frame_size: int, samples: int, camera_pitch: float, ortho_padding: float, exposure: float) -> bpy.types.Camera:
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = samples
    scene.render.resolution_x = frame_size
    scene.render.resolution_y = frame_size
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Filmic"
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.exposure = exposure
    scene.view_settings.gamma = 1.0

    camera_data = bpy.data.cameras.new("EMBERFALL_CAMERA")
    camera = bpy.data.objects.new("EMBERFALL_CAMERA", camera_data)
    bpy.context.collection.objects.link(camera)
    pitch = math.radians(camera_pitch)
    distance = 6.0
    camera.location = (0.0, -math.cos(pitch) * distance, math.sin(pitch) * distance)
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 2.8 * ortho_padding
    look_at(camera, Vector((0.0, 0.0, 0.55)))
    scene.camera = camera

    def add_light(name: str, loc: tuple[float, float, float], power: float, color: tuple[float, float, float]) -> None:
        light_data = bpy.data.lights.new(name, "AREA")
        light_data.energy = power
        light_data.size = 4.0
        light = bpy.data.objects.new(name, light_data)
        bpy.context.collection.objects.link(light)
        light.location = loc
        light_data.color = color

    add_light("forge_key", (-2.5, -3.5, 4.5), 650.0, (1.0, 0.55, 0.24))
    add_light("slag_rim", (3.5, 2.0, 3.0), 210.0, (0.28, 0.62, 0.72))
    add_light("ember_fill", (0.0, 3.0, 1.6), 95.0, (1.0, 0.36, 0.18))
    return camera


def select_action(objects: list[bpy.types.Object], action_name: str | None) -> tuple[int, int]:
    action = None
    if action_name:
        action = bpy.data.actions.get(action_name)
        if action is None:
            available = ", ".join(sorted(candidate.name for candidate in bpy.data.actions))
            raise RuntimeError(f"Action '{action_name}' not found. Available actions: {available}")
    elif len(bpy.data.actions) == 1:
        action = bpy.data.actions[0]

    if action is None:
        scene = bpy.context.scene
        return int(scene.frame_start), int(scene.frame_end)

    assigned = False
    for obj in objects:
        if obj.type != "ARMATURE":
            continue
        if obj.animation_data is None:
            obj.animation_data_create()
        obj.animation_data.action = action
        assigned = True
    if not assigned:
        raise RuntimeError(f"No armature found for action '{action.name}'")
    return int(action.frame_range[0]), int(action.frame_range[1])


def apply_emission_boost(objects: list[bpy.types.Object], strength: float) -> None:
    if strength <= 0.0:
        return
    for obj in objects:
        if obj.type != "MESH":
            continue
        for material in obj.data.materials:
            if material is None or not material.use_nodes:
                continue
            for node in material.node_tree.nodes:
                if node.type != "BSDF_PRINCIPLED":
                    continue
                emission_color = node.inputs.get("Emission Color") or node.inputs.get("Emission")
                emission_strength = node.inputs.get("Emission Strength")
                if emission_color:
                    emission_color.default_value = (1.0, 0.68, 0.28, 1.0)
                if emission_strength:
                    emission_strength.default_value = strength


def recenter_animated_root(root: bpy.types.Object, objects: list[bpy.types.Object]) -> None:
    root.location.x = 0.0
    root.location.y = 0.0
    bpy.context.view_layer.update()
    mins, maxs = bounds_for(objects)
    center = (mins + maxs) * 0.5
    root.location.x = -center.x
    root.location.y = -center.y
    bpy.context.view_layer.update()


def render(args: argparse.Namespace) -> None:
    clear_scene()
    imported = import_model(args.model)
    root = normalize_model(imported)
    apply_emission_boost(imported, args.emission_strength)
    setup_scene(args.frame_size, args.samples, args.camera_pitch, args.ortho_padding, args.exposure)
    scene = bpy.context.scene
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)

    frame_start, frame_end = select_action(imported, args.source_action)
    if frame_end <= frame_start:
        frame_start = 1
        frame_end = max(1, args.frames)
    frame_span = max(1, frame_end - frame_start)

    for direction in range(args.directions):
        angle = (math.tau * float(direction) / float(args.directions))
        root.rotation_euler = (0.0, 0.0, angle)
        for frame_index in range(args.frames):
            source_frame = frame_start + round(frame_span * frame_index / max(1, args.frames - 1))
            scene.frame_set(source_frame)
            if args.recenter_motion:
                recenter_animated_root(root, imported)
            scene.render.filepath = str(output / f"{args.entity}_{args.animation}_dir{direction:02d}_frame{frame_index:02d}.png")
            bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    render(parse_args())
