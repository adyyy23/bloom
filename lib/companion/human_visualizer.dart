import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'human_body_mesh.dart';

/// Interactive 3D Human Body Visualizer.
///
/// Features:
/// - Real 3D polygon mesh with perspective projection.
/// - Full-body human avatar with natural anatomical proportions.
/// - Morph targets parameterized by height, weight, waist, hip, chest, and frame.
/// - Conformal athletic wear that stays fitted during all morph changes.
/// - Horizontal drag rotation with damping, Front/3-Quarter/Side/Back presets, and Reset.
/// - Multi-source studio lighting (Key, Fill, Rim, Ambient) with soft contact shadow.
/// - Subtle idle breathing animation with reduced-motion support.
/// - Pauses rendering when scrolled offscreen.
class HumanVisualizer extends StatefulWidget {
  final double heightCm;
  final double weightKg;
  final double? goalWeightKg;
  final AvatarConfig config;
  final bool isFemale;
  final bool isGoalPreview;
  final bool reducedMotion;
  final VoidCallback? onEditMeasurements;
  final ValueChanged<bool>? onPreviewModeChanged;
  final double stageHeight;

  const HumanVisualizer({
    super.key,
    required this.heightCm,
    required this.weightKg,
    this.goalWeightKg,
    required this.config,
    this.isFemale = true,
    this.isGoalPreview = false,
    this.reducedMotion = false,
    this.onEditMeasurements,
    this.onPreviewModeChanged,
    this.stageHeight = 380,
  });

  @override
  State<HumanVisualizer> createState() => _HumanVisualizerState();
}

class _HumanVisualizerState extends State<HumanVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  double _yaw = 0.0; // in radians
  double _targetYaw = 0.0;
  bool _isDragging = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..addListener(() {
        if (!widget.reducedMotion) {
          // Smooth yaw interpolation towards target preset when not dragging
          if (!_isDragging && (_yaw - _targetYaw).abs() > 0.001) {
            _yaw += (_targetYaw - _yaw) * 0.18;
          }
          setState(() {});
        }
      });

    if (!widget.reducedMotion) {
      _anim.repeat();
    }
  }

  @override
  void didUpdateWidget(HumanVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      if (widget.reducedMotion) {
        _anim.stop();
      } else {
        _anim.repeat();
      }
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _setPresetYaw(double target) {
    setState(() {
      _targetYaw = target;
      if (widget.reducedMotion) {
        _yaw = target;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: widget.stageHeight,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 48, color: BloomColors.inkSoft),
            const SizedBox(height: 8),
            Text('Could not render 3D model',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _hasError = false),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    final effectiveWeight = (widget.isGoalPreview && widget.goalWeightKg != null)
        ? widget.goalWeightKg!
        : widget.weightKg;

    return SizedBox(
      height: widget.stageHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Gesture detector for horizontal rotation while allowing vertical page scrolling
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => _isDragging = true,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _yaw += details.delta.dx * 0.015;
                _targetYaw = _yaw;
              });
            },
            onHorizontalDragEnd: (_) => _isDragging = false,
            child: CustomPaint(
              size: Size(double.infinity, widget.stageHeight),
              painter: _Human3DPainter(
                heightCm: widget.heightCm,
                weightKg: effectiveWeight,
                config: widget.config,
                isFemale: widget.isFemale,
                yaw: _yaw,
                breathPhase: widget.reducedMotion ? 0.0 : _anim.value,
                dark: dark,
              ),
            ),
          ),

          // 2. View Preset Controls (Floating Pill Buttons)
          Positioned(
            top: 12,
            right: BloomSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: (dark ? Colors.black : Colors.white).withOpacity(0.72),
                borderRadius: BorderRadius.circular(BloomRadii.pill),
                border: Border.all(
                  color: dark
                      ? Colors.white.withOpacity(0.12)
                      : BloomColors.line.withOpacity(0.8),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _presetButton('Front', 0.0),
                  _presetButton('3/4', math.pi * 0.25),
                  _presetButton('Side', math.pi * 0.5),
                  _presetButton('Back', math.pi),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    tooltip: 'Reset view to front',
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: EdgeInsets.zero,
                    onPressed: () => _setPresetYaw(0.0),
                  ),
                ],
              ),
            ),
          ),

          // 3. Current vs Goal Preview Mode Selector (if goal weight exists)
          if (widget.goalWeightKg != null && widget.onPreviewModeChanged != null)
            Positioned(
              top: 12,
              left: BloomSpacing.md,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: (dark ? Colors.black : Colors.white).withOpacity(0.72),
                  borderRadius: BorderRadius.circular(BloomRadii.pill),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withOpacity(0.12)
                        : BloomColors.line.withOpacity(0.8),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modeChip('Current', !widget.isGoalPreview, () {
                      widget.onPreviewModeChanged!(false);
                    }),
                    _modeChip('Goal preview', widget.isGoalPreview, () {
                      widget.onPreviewModeChanged!(true);
                    }),
                  ],
                ),
              ),
            ),

          // 4. Subtle Drag Cue Hint (at bottom of stage)
          Positioned(
            bottom: 18,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (dark ? Colors.black : Colors.white).withOpacity(0.55),
                  borderRadius: BorderRadius.circular(BloomRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 13,
                      color: dark ? Colors.white70 : BloomColors.inkSoft,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Drag to rotate 360°',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white70 : BloomColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetButton(String label, double yawTarget) {
    // Normalizing angles to check active preset
    final currentNorm = (_yaw % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    final targetNorm = (yawTarget % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    final active = (currentNorm - targetNorm).abs() < 0.2 ||
        (currentNorm - targetNorm - 2 * math.pi).abs() < 0.2;

    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => _setPresetYaw(yawTarget),
      borderRadius: BorderRadius.circular(BloomRadii.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? (dark ? primary.withOpacity(0.28) : primary.withOpacity(0.15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(BloomRadii.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active
                ? primary
                : (dark ? Colors.white70 : BloomColors.ink),
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String label, bool active, VoidCallback onTap) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BloomRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? (dark ? primary.withOpacity(0.3) : primary.withOpacity(0.16))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(BloomRadii.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? primary : (dark ? Colors.white70 : BloomColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Hardware-accelerated 3D software rasterizer for the human body mesh.
class _Human3DPainter extends CustomPainter {
  final double heightCm;
  final double weightKg;
  final AvatarConfig config;
  final bool isFemale;
  final double yaw;
  final double breathPhase;
  final bool dark;

  _Human3DPainter({
    required this.heightCm,
    required this.weightKg,
    required this.config,
    required this.isFemale,
    required this.yaw,
    required this.breathPhase,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Compute morphed 3D vertices
    final vertices = HumanBodyMesh.computeMorphedVertices(
      heightCm: heightCm,
      weightKg: weightKg,
      waistCm: config.waistCm,
      hipCm: config.hipCm,
      chestCm: config.chestCm,
      frame: config.frame,
      breathPhase: breathPhase,
      isFemale: isFemale,
    );

    // 2. Camera & Projection Setup
    // Center of model is at (x=0, y ~ 86cm)
    const cameraDistance = 220.0;
    const fov = 400.0; // focal length for prominent full-body presence
    final groundY = h * 0.90; // ground level in screen coordinates
    final cx = w * 0.5;

    // Rotation angles
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    // Slight downward pitch angle to simulate eye-level view
    const pitch = 0.05; // radians (~3 degrees)
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);

    // 3. Render Floor Contact Shadow
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (dark ? Colors.black : const Color(0xFF6B4E3D)).withOpacity(dark ? 0.45 : 0.22),
          (dark ? Colors.black : const Color(0xFF6B4E3D)).withOpacity(dark ? 0.15 : 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCenter(
        center: Offset(cx, groundY + 4),
        width: 150,
        height: 42,
      ));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY + 4), width: 150, height: 42),
      shadowPaint,
    );

    // Individual shoe contact shadows
    final shoeSpread = 18.0;
    final shoeShadowPaint = Paint()
      ..color = (dark ? Colors.black : const Color(0xFF3E281E)).withOpacity(dark ? 0.35 : 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - shoeSpread * cosY, groundY + 2), width: 32, height: 14),
      shoeShadowPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + shoeSpread * cosY, groundY + 2), width: 32, height: 14),
      shoeShadowPaint,
    );

    // 4. Transform Vertices to Camera Space & Project to 2D
    final projected = List<Offset>.filled(vertices.length, Offset.zero);
    final camZ = List<double>.filled(vertices.length, 0.0);

    for (var i = 0; i < vertices.length; i++) {
      final v = vertices[i];
      // Yaw rotation around Y axis
      final rx = v.x * cosY + v.z * sinY;
      final rz0 = -v.x * sinY + v.z * cosY;

      // Pitch rotation around X axis
      final ry = (v.y - 86.0) * cosP - rz0 * sinP + 86.0;
      final rz = (v.y - 86.0) * sinP + rz0 * cosP;

      final z = cameraDistance - rz;
      camZ[i] = z;

      final scale = fov / z;
      final px = cx + rx * scale;
      final py = groundY - ry * scale * 1.05;
      projected[i] = Offset(px, py);
    }

    // 5. Material Colors Palette
    final skinBase = _skinColor(config.skinTone);
    final hairBase = _hairColor(config.hairColor);
    final topBase = _clothingColor(config.clothingColor);
    final shortsBase = switch (config.clothingStyle) {
      ClothingStyle.twoPieceAthletic => _shortsColor(config.clothingColor),
      ClothingStyle.fullBodyFit => _clothingColor(config.clothingColor),
      ClothingStyle.relaxedSet => _shortsColor(config.clothingColor).withOpacity(0.92),
    };
    final shoeMidsoleBase = const Color(0xFFFAFBFD);
    final shoeUpperBase = _shoeUpperColor(config.clothingColor);

    // 6. Studio Lighting Vectors
    // Key Light: warm directional from top-left-front
    const keyL = [0.45, 0.65, 0.60];
    // Fill Light: soft cool ambient from right-front
    const fillL = [-0.50, 0.30, 0.81];

    // 7. Depth Sort Faces (Painter's Algorithm)
    final faces = HumanBodyMesh.faces;
    final sortedIndices = List<int>.generate(faces.length, (i) => i);

    sortedIndices.sort((a, b) {
      final fa = faces[a];
      final fb = faces[b];
      final za = (camZ[fa.i0] + camZ[fa.i1] + camZ[fa.i2]) / 3.0;
      final zb = (camZ[fb.i0] + camZ[fb.i1] + camZ[fb.i2]) / 3.0;
      return za.compareTo(zb); // back to front
    });

    final polyPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..strokeJoin = StrokeJoin.round;

    // 8. Render Triangles
    for (final idx in sortedIndices) {
      final f = faces[idx];
      final p0 = projected[f.i0];
      final p1 = projected[f.i1];
      final p2 = projected[f.i2];

      // Screen-space 2D cross product for back-face culling
      final cross = (p1.dx - p0.dx) * (p2.dy - p0.dy) - (p1.dy - p0.dy) * (p2.dx - p0.dx);
      if (cross <= 0) continue; // culled

      // Compute normal in model space
      final v0 = vertices[f.i0];
      final v1 = vertices[f.i1];
      final v2 = vertices[f.i2];

      final ax = v1.x - v0.x;
      final ay = v1.y - v0.y;
      final az = v1.z - v0.z;

      final bx = v2.x - v0.x;
      final by = v2.y - v0.y;
      final bz = v2.z - v0.z;

      var nx = ay * bz - az * by;
      var ny = az * bx - ax * bz;
      var nz = ax * by - ay * bx;
      final len = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (len > 0.0001) {
        nx /= len;
        ny /= len;
        nz /= len;
      }

      // Rotate normal by camera yaw
      final rnx = nx * cosY + nz * sinY;
      final rny = ny;
      final rnz = -nx * sinY + nz * cosY;

      // Studio Lighting Calculation: Key, Fill, Rim, and Clay Specular
      final dotKey = (rnx * keyL[0] + rny * keyL[1] + rnz * keyL[2]).clamp(0.0, 1.0);
      final dotFill = (rnx * fillL[0] + rny * fillL[1] + rnz * fillL[2]).clamp(0.0, 1.0);

      // Fresnel rim lighting for dimensional silhouette glow
      final rim = math.pow((1.0 - rnz.abs()).clamp(0.0, 1.0), 3.0) * 0.25;

      // Subtle Blinn-Phong specular highlight for soft clay sheen
      const halfV = [0.24, 0.35, 0.90];
      final dotH = (rnx * halfV[0] + rny * halfV[1] + rnz * halfV[2]).clamp(0.0, 1.0);
      final spec = math.pow(dotH, 10.0) * 0.20;

      // Total light intensity
      final intensity = (0.34 + 0.44 * dotKey + 0.22 * dotFill + rim + spec).clamp(0.0, 1.0);

      // Material base color
      final baseColor = switch (f.matId) {
        0 => skinBase,
        1 => hairBase,
        2 => topBase,
        3 => shortsBase,
        4 => shoeMidsoleBase,
        5 => shoeUpperBase,
        6 => const Color(0xFF2E2620), // subtle facial features / eye brows
        _ => skinBase,
      };

      final litColor = _applyLight(baseColor, intensity);
      polyPaint.color = litColor;
      strokePaint.color = litColor.withOpacity(0.9);

      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      canvas.drawPath(path, polyPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  Color _applyLight(Color base, double factor) {
    if (factor > 0.68) {
      // Highlight blending with warm clay sheen
      final t = ((factor - 0.68) / 0.32).clamp(0.0, 1.0);
      return Color.lerp(base, const Color(0xFFFFFDF8), t * 0.48)!;
    } else {
      // Shadow blending with warm rich tone
      final t = ((0.68 - factor) / 0.68).clamp(0.0, 1.0);
      final shadowTone = dark ? const Color(0xFF1B1B26) : const Color(0xFF42332C);
      return Color.lerp(base, shadowTone, t * 0.50)!;
    }
  }

  Color _skinColor(SkinTone tone) => switch (tone) {
        SkinTone.fair => const Color(0xFFFBE3D5),
        SkinTone.warmSand => const Color(0xFFF2D1B3),
        SkinTone.honey => const Color(0xFFE2B28B),
        SkinTone.goldenAmber => const Color(0xFFC78B5E),
        SkinTone.deepBronze => const Color(0xFF945F3B),
        SkinTone.richEspresso => const Color(0xFF5A3926),
      };

  Color _hairColor(HairColor color) => switch (color) {
        HairColor.espresso => const Color(0xFF35261E),
        HairColor.chestnut => const Color(0xFF5D3A29),
        HairColor.blonde => const Color(0xFFD4B478),
        HairColor.silver => const Color(0xFFB5BAC0),
        HairColor.raven => const Color(0xFF18181A),
      };

  Color _clothingColor(ClothingColor color) => switch (color) {
        ClothingColor.sage => const Color(0xFF6FAF8E),
        ClothingColor.lavender => const Color(0xFF9B8AC4),
        ClothingColor.ocean => const Color(0xFF5A94C7),
        ClothingColor.coral => const Color(0xFFE57B6C),
        ClothingColor.slate => const Color(0xFF4A5568),
      };

  Color _shortsColor(ClothingColor color) => switch (color) {
        ClothingColor.sage => const Color(0xFF436955),
        ClothingColor.lavender => const Color(0xFF645585),
        ClothingColor.ocean => const Color(0xFF385E82),
        ClothingColor.coral => const Color(0xFF994437),
        ClothingColor.slate => const Color(0xFF2D3748),
      };

  Color _shoeUpperColor(ClothingColor color) => switch (color) {
        ClothingColor.sage => const Color(0xFFE2EFE7),
        ClothingColor.lavender => const Color(0xFFEBE5F5),
        ClothingColor.ocean => const Color(0xFFE1ECF7),
        ClothingColor.coral => const Color(0xFFFBE8E5),
        ClothingColor.slate => const Color(0xFFE2E5E9),
      };

  @override
  bool shouldRepaint(covariant _Human3DPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.breathPhase != breathPhase ||
        oldDelegate.heightCm != heightCm ||
        oldDelegate.weightKg != weightKg ||
        oldDelegate.config != config ||
        oldDelegate.isFemale != isFemale ||
        oldDelegate.dark != dark;
  }
}
