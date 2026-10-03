import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'human_body_mesh.dart';
import 'sculpted_human.dart';

/// Offline perspective renderer of actual 3D vertices, with smooth vertex lighting.
/// No image fallback: loading failures present a retry action.
class HumanVisualizer extends StatefulWidget {
  final double heightCm, weightKg, stageHeight;
  final double? goalWeightKg;
  final AvatarConfig config;
  final bool isFemale, isGoalPreview, reducedMotion;
  final VoidCallback? onEditMeasurements;
  final ValueChanged<bool>? onPreviewModeChanged;
  const HumanVisualizer({
    super.key,
    required this.heightCm,
    required this.weightKg,
    required this.config,
    this.goalWeightKg,
    this.stageHeight = 360,
    this.isFemale = true,
    this.isGoalPreview = false,
    this.reducedMotion = false,
    this.onEditMeasurements,
    this.onPreviewModeChanged,
  });
  @override
  State<HumanVisualizer> createState() => _HumanVisualizerState();
}

class _HumanVisualizerState extends State<HumanVisualizer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation;
  Timer? _visibility;
  HumanGeometry? _geometry;
  SculptedHuman? _model;
  bool _failed = false, _visible = true, _foreground = true;
  double _yaw = -.18;
  int _lastFrame = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _animation.addListener(() {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastFrame >= 33) {
        _lastFrame = now;
        setState(() {});
      }
    });
    _load();
    _visibility = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => _checkVisibility(),
    );
  }

  Future<void> _load({bool retry = false}) async {
    setState(() {
      _failed = false;
      _geometry = null;
    });
    try {
      final model = await SculptedHuman.load(retry: retry);
      final geometry = model.geometry(widget.config);
      if (!mounted) return;
      setState(() {
        _model = model;
        _geometry = geometry;
      });
      _syncAnimation();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _syncAnimation() {
    final enabled = mounted &&
        _geometry != null &&
        _visible &&
        _foreground &&
        !widget.reducedMotion &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.of(context);
    if (enabled && !_animation.isAnimating) _animation.repeat();
    if (!enabled && _animation.isAnimating) _animation.stop();
  }

  void _checkVisibility() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize && box.attached) {
      final top = box.localToGlobal(Offset.zero).dy;
      _visible =
          top + box.size.height > 0 && top < MediaQuery.sizeOf(context).height;
    }
    _syncAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncAnimation();
  }

  @override
  void didUpdateWidget(HumanVisualizer old) {
    super.didUpdateWidget(old);
    if (old.config != widget.config && _model != null) {
      try {
        _geometry = _model!.geometry(widget.config);
      } catch (_) {
        _failed = true;
      }
    }
    _syncAnimation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _visibility?.cancel();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.isGoalPreview && widget.goalWeightKg != null;
    final weight = goal ? widget.goalWeightKg! : widget.weightKg;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
        height: widget.stageHeight,
        child: ColoredBox(
          color: dark ? BloomColors.bgD : BloomColors.bg,
          child: Column(
            children: [
              Expanded(
                child: Semantics(
                  label:
                      'Interactive approximate human visualization. ${goal ? "Illustrative goal" : "Current"} weight ${weight.toStringAsFixed(1)} kilograms. Drag horizontally to rotate.',
                  child: _failed
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('The 3D human could not load.'),
                              TextButton.icon(
                                onPressed: () => _load(retry: true),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _geometry == null
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 12),
                                  Text('Preparing your 3D human…'),
                                ],
                              ),
                            )
                          : RepaintBoundary(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onHorizontalDragUpdate: (d) =>
                                    setState(() => _yaw += d.delta.dx * .012),
                                child: SizedBox.expand(
                                  child: CustomPaint(
                                    painter: _Human3DPainter(
                                      geometry: _geometry!,
                                      heightCm: widget.heightCm,
                                      weightKg: weight,
                                      config: widget.config,
                                      yaw: _yaw,
                                      dark: dark,
                                      breathPhase: widget.reducedMotion ||
                                              MediaQuery.disableAnimationsOf(
                                                  context)
                                          ? 0
                                          : _animation.value,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 2,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final v in [
                      ('Front', 0.0),
                      ('3/4', math.pi / 4),
                      ('Side', math.pi / 2),
                      ('Back', math.pi),
                    ])
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          backgroundColor: (_yaw - v.$2).abs() < .1
                              ? (dark
                                  ? BloomColors.paleLavenderD
                                  : BloomColors.paleLavender)
                              : null,
                        ),
                        onPressed: () => setState(() => _yaw = v.$2),
                        child: Text(v.$1),
                      ),
                    IconButton(
                      tooltip: 'Reset view',
                      onPressed: () => setState(() => _yaw = 0),
                      icon: const Icon(Icons.restart_alt, size: 20),
                    ),
                    if (widget.onEditMeasurements != null)
                      IconButton(
                        tooltip: 'Customize appearance',
                        onPressed: widget.onEditMeasurements,
                        icon: const Icon(Icons.palette_outlined, size: 20),
                      ),
                  ],
                ),
              ),
              if (widget.goalWeightKg != null &&
                  widget.onPreviewModeChanged != null)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Current'),
                      selected: !goal,
                      onSelected: (_) => widget.onPreviewModeChanged!(false),
                    ),
                    ChoiceChip(
                      label: const Text('Illustrative goal'),
                      selected: goal,
                      onSelected: (_) => widget.onPreviewModeChanged!(true),
                    ),
                  ],
                ),
            ],
          ),
        ));
  }
}

class _Human3DPainter extends CustomPainter {
  final HumanGeometry geometry;
  final double heightCm, weightKg, yaw, breathPhase;
  final AvatarConfig config;
  final bool dark;
  _Human3DPainter({
    required this.geometry,
    required this.heightCm,
    required this.weightKg,
    required this.config,
    required this.yaw,
    required this.breathPhase,
    required this.dark,
  });
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRect(Offset.zero & size,
        Paint()..color = dark ? BloomColors.heroPeachD : BloomColors.heroPeach);
    final floor = Path()
      ..moveTo(0, size.height * .72)
      ..quadraticBezierTo(
          size.width * .5, size.height * .57, size.width, size.height * .72)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        floor, Paint()..color = dark ? BloomColors.bgD : BloomColors.bg);

    final points = geometry.deform(
      heightCm: heightCm,
      weightKg: weightKg,
      config: config,
      breath: math.sin(breathPhase * math.pi * 2),
    );
    final normals = List.generate(points.length, (_) => Vec3(0, 0, 0));
    for (final f in geometry.faces) {
      final a = points[f.i0], b = points[f.i1], c = points[f.i2];
      final nx = (b.y - a.y) * (c.z - a.z) - (b.z - a.z) * (c.y - a.y);
      final ny = (b.z - a.z) * (c.x - a.x) - (b.x - a.x) * (c.z - a.z);
      final nz = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
      for (final i in [f.i0, f.i1, f.i2]) {
        normals[i].x += nx;
        normals[i].y += ny;
        normals[i].z += nz;
      }
    }
    final cy = math.cos(yaw), sy = math.sin(yaw);
    // Fit the projected bounds, including hair, hands and shoes, to every stage.
    final raw = <Offset>[], depth = <double>[];
    for (final p in points) {
      final x = p.x * cy + p.z * sy, z = -p.x * sy + p.z * cy;
      final d = 420 - z;
      raw.add(Offset(x * 420 / d, -p.y * 420 / d));
      depth.add(d);
    }
    var minX = double.infinity,
        maxX = -double.infinity,
        minY = double.infinity,
        maxY = -double.infinity;
    for (final p in raw) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    final scale = math.min(
      (size.height - 20) / (maxY - minY),
      (size.width - 50) / (maxX - minX),
    );
    final dx = size.width / 2 - (minX + maxX) * .5 * scale,
        dy = size.height - 10 - maxY * scale;
    final projected =
        raw.map((p) => Offset(p.dx * scale + dx, p.dy * scale + dy)).toList();
    final shadow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 8),
      width: 80 * scale,
      height: 14 * scale,
    );
    canvas.drawOval(
      shadow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withOpacity(dark ? .35 : .18),
            Colors.transparent,
          ],
        ).createShader(shadow),
    );
    final sorted = List<int>.generate(geometry.faces.length, (i) => i)
      ..sort((a, b) {
        final fa = geometry.faces[a], fb = geometry.faces[b];
        return (depth[fb.i0] + depth[fb.i1] + depth[fb.i2]).compareTo(
          depth[fa.i0] + depth[fa.i1] + depth[fa.i2],
        );
      });
    final palette = [
      _skinColor(config.skinTone),
      _hairColor(config.hairColor),
      _clothingColor(config.clothingColor),
      _shortsColor(config.clothingColor),
      const Color(0xFFFAFBFD),
      _shoeUpperColor(config.clothingColor),
      const Color(0xFF292331),
      const Color(0xFFFFFDF8),
      const Color(0xFF694D36),
      const Color(0xFFB97069),
    ];
    final positions = <Offset>[], colors = <Color>[];
    for (final idx in sorted) {
      final f = geometry.faces[idx];
      final a = projected[f.i0], b = projected[f.i1], c = projected[f.i2];
      if ((b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx) >= 0)
        continue;
      final material = geometry.material(f, config);
      if (material == 10) continue;
      final base = palette[material];
      for (final i in [f.i0, f.i1, f.i2]) {
        final n = normals[i];
        final len = math.sqrt(n.x * n.x + n.y * n.y + n.z * n.z);
        final nx = (n.x * cy + n.z * sy) / len,
            ny = n.y / len,
            nz = (-n.x * sy + n.z * cy) / len;
        final key = math.max(0.0, nx * -.35 + ny * .65 + nz * .68),
            fill = math.max(0.0, nx * .65 + ny * .2 + nz * .73);
        final spec =
            math.pow(math.max(0.0, nx * -.18 + ny * .36 + nz * .91), 22) * .14;
        colors.add(
          _applyLight(
            base,
            (.38 + .42 * key + .16 * fill + spec).clamp(0.0, 1.0),
          ),
        );
        positions.add(projected[i]);
      }
    }
    canvas.drawVertices(
      ui.Vertices(ui.VertexMode.triangles, positions, colors: colors),
      BlendMode.srcOver,
      Paint(),
    );
  }

  Color _applyLight(Color base, double factor) {
    if (factor > 0.68) {
      // Highlight blending with warm clay sheen
      final t = ((factor - 0.68) / 0.32).clamp(0.0, 1.0);
      return Color.lerp(base, const Color(0xFFFFFDF8), t * 0.48)!;
    } else {
      // Shadow blending with warm rich tone
      final t = ((0.68 - factor) / 0.68).clamp(0.0, 1.0);
      final shadowTone =
          dark ? const Color(0xFF1B1B26) : const Color(0xFF42332C);
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
    return oldDelegate.geometry != geometry ||
        oldDelegate.yaw != yaw ||
        oldDelegate.breathPhase != breathPhase ||
        oldDelegate.heightCm != heightCm ||
        oldDelegate.weightKg != weightKg ||
        oldDelegate.config != config ||
        oldDelegate.dark != dark;
  }
}
