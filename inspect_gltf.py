#!/usr/bin/env python3
"""
GLB/GLTF Model Inspection Script

This script extracts and displays the structure of a GLB model including:
- Node names and hierarchy
- Skin/joint information
- Mesh names
- Material information

Usage:
    pip install pygltflib
    python inspect_gltf.py path/to/model.glb

For the Breen model:
    python inspect_gltf.py ../appv1/assets/models/breen.glb
"""

import sys
from pathlib import Path

try:
    from pygltflib import GLTF2
except ImportError:
    print("ERROR: pygltflib not installed")
    print("Please install it with: pip install pygltflib")
    sys.exit(1)


def inspect_gltf(file_path):
    """Inspect a GLTF/GLB file and print its structure"""
    
    if not Path(file_path).exists():
        print(f"ERROR: File not found: {file_path}")
        sys.exit(1)
    
    print(f"\n{'='*80}")
    print(f"Inspecting: {file_path}")
    print(f"{'='*80}\n")
    
    try:
        gltf = GLTF2().load(file_path)
    except Exception as e:
        print(f"ERROR loading file: {e}")
        sys.exit(1)
    
    # Print nodes
    print(f"{'='*80}")
    print("NODES ({} total)".format(len(gltf.nodes) if gltf.nodes else 0))
    print(f"{'='*80}")
    if gltf.nodes:
        for i, node in enumerate(gltf.nodes):
            name = node.name if node.name else f"<unnamed_{i}>"
            mesh_ref = f" (mesh: {node.mesh})" if node.mesh is not None else ""
            skin_ref = f" (skin: {node.skin})" if node.skin is not None else ""
            children = f" children: {node.children}" if node.children else ""
            print(f"  [{i:3d}] {name}{mesh_ref}{skin_ref}{children}")
    else:
        print("  No nodes found")
    
    # Print skins
    print(f"\n{'='*80}")
    print("SKINS ({} total)".format(len(gltf.skins) if gltf.skins else 0))
    print(f"{'='*80}")
    if gltf.skins:
        for i, skin in enumerate(gltf.skins):
            name = skin.name if skin.name else f"<unnamed_{i}>"
            joints = skin.joints if skin.joints else []
            print(f"  [{i}] {name}")
            print(f"      Skeleton root: {skin.skeleton}")
            print(f"      Joint count: {len(joints)}")
            print(f"      Joint indices: {joints}")
            
            # Print joint names
            if joints:
                print(f"      Joint names:")
                for joint_idx in joints[:10]:  # Show first 10
                    if joint_idx < len(gltf.nodes):
                        joint_name = gltf.nodes[joint_idx].name or f"<unnamed_{joint_idx}>"
                        print(f"        [{joint_idx}] {joint_name}")
                if len(joints) > 10:
                    print(f"        ... and {len(joints) - 10} more joints")
    else:
        print("  No skins found")
    
    # Print meshes
    print(f"\n{'='*80}")
    print("MESHES ({} total)".format(len(gltf.meshes) if gltf.meshes else 0))
    print(f"{'='*80}")
    if gltf.meshes:
        for i, mesh in enumerate(gltf.meshes):
            name = mesh.name if mesh.name else f"<unnamed_{i}>"
            primitive_count = len(mesh.primitives) if mesh.primitives else 0
            print(f"  [{i:3d}] {name} ({primitive_count} primitives)")
    else:
        print("  No meshes found")
    
    # Print materials
    print(f"\n{'='*80}")
    print("MATERIALS ({} total)".format(len(gltf.materials) if gltf.materials else 0))
    print(f"{'='*80}")
    if gltf.materials:
        for i, material in enumerate(gltf.materials):
            name = material.name if material.name else f"<unnamed_{i}>"
            print(f"  [{i:3d}] {name}")
    else:
        print("  No materials found")
    
    # Print textures
    print(f"\n{'='*80}")
    print("TEXTURES ({} total)".format(len(gltf.textures) if gltf.textures else 0))
    print(f"{'='*80}")
    if gltf.textures:
        for i, texture in enumerate(gltf.textures):
            source_idx = texture.source if hasattr(texture, 'source') else None
            source_info = f" (source: {source_idx})" if source_idx is not None else ""
            print(f"  [{i:3d}] Texture{source_info}")
    else:
        print("  No textures found")
    
    # Print images
    print(f"\n{'='*80}")
    print("IMAGES ({} total)".format(len(gltf.images) if gltf.images else 0))
    print(f"{'='*80}")
    if gltf.images:
        for i, image in enumerate(gltf.images):
            name = image.name if image.name else f"<unnamed_{i}>"
            uri = image.uri if image.uri else "<embedded>"
            print(f"  [{i:3d}] {name} - {uri}")
    else:
        print("  No images found")
    
    # Recommendations
    print(f"\n{'='*80}")
    print("RECOMMENDATIONS FOR FLUTTER INTEGRATION")
    print(f"{'='*80}")
    
    # Find potential lower-body nodes to hide
    if gltf.nodes:
        lower_body_keywords = ['hip', 'leg', 'foot', 'toe', 'pelvis', 'lower']
        potential_hide = []
        for i, node in enumerate(gltf.nodes):
            if node.name:
                name_lower = node.name.lower()
                if any(keyword in name_lower for keyword in lower_body_keywords):
                    potential_hide.append(f"'{node.name}'")
        
        if potential_hide:
            print("\nPotential lower-body nodes to hide:")
            print("  final lowerBodyNames = [")
            for name in potential_hide:
                print(f"    {name},")
            print("  ];")
        else:
            print("\n  No obvious lower-body nodes detected.")
    
    # Find potential hand/wrist bones
    if gltf.nodes:
        hand_keywords = ['hand', 'wrist', 'finger', 'thumb', 'index', 'middle', 'ring', 'pinky']
        potential_hand = []
        for i, node in enumerate(gltf.nodes):
            if node.name:
                name_lower = node.name.lower()
                if any(keyword in name_lower for keyword in hand_keywords):
                    potential_hand.append((i, node.name))
        
        if potential_hand:
            print("\nPotential hand/finger bones found:")
            for idx, name in potential_hand:
                print(f"  [{idx:3d}] {name}")
        else:
            print("\n  No obvious hand bones detected.")
            print("  Note: This model may use a different naming convention.")
    
    print(f"\n{'='*80}")
    print("Use these node/bone names in your Flutter code:")
    print("  - _nodesByName['NodeName'] for hiding nodes")
    print("  - _bonesByName['BoneName'] for bone rotations")
    print(f"{'='*80}\n")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python inspect_gltf.py <path_to_glb_file>")
        print("\nExample:")
        print("  python inspect_gltf.py ../appv1/assets/models/breen.glb")
        sys.exit(1)
    
    file_path = sys.argv[1]
    inspect_gltf(file_path)
