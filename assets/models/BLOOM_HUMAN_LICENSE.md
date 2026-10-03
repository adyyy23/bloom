# Original Bloom human — CC0-1.0

Applies only to `bloom_human.glb`, `bloom_human.mesh.gz`, and the original geometry construction in `tools/build_human.py`.

This human was procedurally authored for Bloom in this change. No downloaded human, animal, photograph, scan, or third-party character asset was used. The supplied inspiration informed the screen composition; it is not bundled in the application.

The original geometry is dedicated to the public domain under Creative Commons CC0 1.0 Universal: https://creativecommons.org/publicdomain/zero/1.0/legalcode . You may copy, modify, and redistribute it without attribution. This dedication does not relicense the repository's existing code, fonts, legacy models, or generator dependencies.

The build script constructs a smoothly united implicit anatomical skin surface and extracts and simplifies it into one connected watertight mesh. Eyes, lips, eyebrows, hairstyle variants, glasses, headband, and shoe shells are separate attached detail meshes. Clothing is a fitted surface material with exact subdivided seams, not simulated fabric. The compressed mesh bundle contains all variants; the GLB exports the default bun and two-piece exercise outfit for interchange.

Rebuild: `python -m pip install -r tools/requirements-model.txt`, then `python tools/build_human.py`. The generator verifies topology in its console output. Axes: centimetres, +Y up, +Z front. Mesh gzip uses a fixed timestamp; no network is needed at runtime.
