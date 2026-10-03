> Active renderer: the original human in `bloom_human.mesh.gz`. See [license and provenance](BLOOM_HUMAN_LICENSE.md) and [review](../../docs/HUMAN_STAGE_REVIEW.md). The older assets below are retained for compatibility and are not the active human renderer.

# Bloom 3D Model Assets & Documentation

## 1. human_body.glb & human_body.obj
- **Name**: Bloom Interactive 3D Human Body Visualizer
- **Description**: Full-body stylized anatomical human mesh featuring natural human proportions, relaxed standing pose, athletic fitted sportswear (sports tank and high-waisted shorts), hairstyle geometry, and athletic sneakers.
- **Topology**:
  - Head & Face: Cranium, jawline, chin, facial contours, ear landmarks.
  - Hair: Volumetric hair geometry supporting styling options (bun, crop, curls, waves).
  - Neck & Shoulders: Anatomical neck transition into clavicles, trapezius, and deltoids.
  - Torso: Chest/pectoral contours, ribcage taper, waist indentation, abdomen, pelvis, and gluteal volume.
  - Athletic Fitted Wear: Registered athletic top and shorts geometry configured with zero-penetration conformal morph tracking.
  - Arms & Hands: Biceps, elbows, forearms, wrists, and relaxed resting hands in natural standing posture.
  - Legs & Feet: Quadriceps, patellar knees, gastrocnemius calves, ankles, and athletic running shoes with soles and uppers.
- **Formats**:
  - glTF 2.0 Binary (`human_body.glb`) with vertex positions, triangle indices, PBR materials.
  - Wavefront OBJ (`human_body.obj`) with vertices and faces.
  - Parametric Mesh Definition (`lib/companion/human_body_mesh.dart`) for real-time Flutter Canvas rendering.
- **Source**: Original anatomical 3D geometry authored for the Bloom Wellness application.
- **License**: Creative Commons Attribution 4.0 International (CC-BY 4.0).
- **Morph Deformation System**:
  - Real-time parametric vertex morphing driven by height ($H$), weight ($W$), waist ($W_{waist}$), hip ($W_{hip}$), chest ($W_{chest}$), and body frame (narrow, medium, broad).
  - Preserves physiological skeletal landmarks, avoids uniform stretching, and maintains fitted athletic clothing.
  - Bounded to realistic physiological limits ($BMI \in [15, 45]$) with safety labeling: *"Approximate visualization — not a body scan."*

## 2. pip.glb
- **Name**: Pip — Bloom Wellness Sprout Mascot
- **Description**: 3D rounded clay companion character with soft mint clay material (`#9BDFBB`), subtle highlights, and sprout foliage.
- **Format**: glTF 2.0 Binary (`.glb`) compliant with standard PBR Metallic-Roughness workflow.
- **Source**: Original character design created for Bloom.
- **License**: MIT / Creative Commons Attribution (CC-BY 4.0).

## 3. Rendering Architecture
Bloom employs a cross-platform 3D visualization architecture:
1. **Interactive 3D Canvas Mesh Engine (`human_visualizer.dart`)**:
   - Renders the complete 3D human mesh with multi-point studio lighting (key light, fill light, rim light, ambient clay sheen).
   - Real-time perspective projection with horizontal drag rotation ($360^\circ$), view angle presets (Front, 3/4, Side, Back), and reset view.
   - Smooth sinusoidal respiratory kinematics (idle breathing).
   - Dynamic soft contact shadow grounded on the floor plane ($Y = 0$).
   - 100% offline, zero-latency execution across Flutter Web (CanvasKit/HTML) and Mobile (iOS/Android) without external WebView dependencies.
2. **Bundled Asset Containers**:
   - `assets/models/human_body.glb` and `assets/models/human_body.obj` for native glTF interchange.
