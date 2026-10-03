import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pip — Bloom's 3D-styled companion character.
///
/// Pip is rendered via a real-time procedural 3D clay engine with multi-layered
/// spherical lighting, directional diffuse + specular highlights, subsurface clay
/// rim lighting, rounded geometry, secondary spring kinematics, and dynamic contact
/// shadows on the stage plane.
///
/// Pip never shames the user: its body shape never changes with weight,
/// and missed days never trigger sad or punishing visuals.
enum PipAction {
  none,
  wave,
  celebrate,
  stretch,
  water,
  workout,
  walk,
  meal,
}

enum PipMood { idle, happy, sleepy, breathing }

class PipController extends ChangeNotifier {
  PipAction action = PipAction.none;
  String? speechReaction;
  int tick = 0;

  void play(PipAction a, {String? speech}) {
    action = a;
    speechReaction = speech;
    tick++;
    notifyListeners();
  }

  void reactToWater({int? ml}) {
    final text = ml != null
        ? 'Refreshing! +${ml}ml hydrated.'
        : 'Nice sip! Hydration looks great on you.';
    play(PipAction.water, speech: text);
  }

  void reactToWalk({int? steps}) {
    final text = steps != null
        ? 'Great stride! $steps steps logged.'
        : 'Steps in rhythm! Keep moving gently.';
    play(PipAction.walk, speech: text);
  }

  void reactToWorkout({String? name}) {
    final text = name != null
        ? 'Awesome work on $name! Feeling strong.'
        : 'Workout complete! Rest and restore.';
    play(PipAction.workout, speech: text);
  }

  void reactToMeal({String? name}) {
    final text = name != null
        ? 'Nourishing! $name logged.'
        : 'Fueling your body well today.';
    play(PipAction.meal, speech: text);
  }
}

class PipColors {
  final Color bodyHighlight;
  final Color body;
  final Color bodyShade;
  final Color belly;
  final Color cheek;
  final Color leaf;
  final Color leafHighlight;
  final Color leafDark;
  final Color eye;

  const PipColors({
    required this.bodyHighlight,
    required this.body,
    required this.bodyShade,
    required this.belly,
    required this.cheek,
    required this.leaf,
    required this.leafHighlight,
    required this.leafDark,
    required this.eye,
  });

  factory PipColors.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const PipColors(
            bodyHighlight: Color(0xFFA5E6C4),
            body: Color(0xFF7BC9A4),
            bodyShade: Color(0xFF4C8F6E),
            belly: Color(0xFFC5EBD6),
            cheek: Color(0xFFE89A7E),
            leaf: Color(0xFF6DC88C),
            leafHighlight: Color(0xFF9DE5B4),
            leafDark: Color(0xFF38855B),
            eye: Color(0xFF1E2822),
          )
        : const PipColors(
            bodyHighlight: Color(0xFFD6F9E6),
            body: Color(0xFF9BDFBB),
            bodyShade: Color(0xFF6ABF93),
            belly: Color(0xFFE3F7EC),
            cheek: Color(0xFFF7BFA0),
            leaf: Color(0xFF62C98C),
            leafHighlight: Color(0xFF8CEAB0),
            leafDark: Color(0xFF3B8E62),
            eye: Color(0xFF262A28),
          );
  }
}

class PipCompanion extends StatefulWidget {
  final double size;
  final String accessory; // sprout | flower | star | scarf
  final PipController? controller;
  final PipMood mood;
  final VoidCallback? onTap;
  final bool reducedMotion;
  final double? externalBreath; // 0..1 driven by breathing guide

  const PipCompanion({
    super.key,
    this.size = 180,
    this.accessory = 'sprout',
    this.controller,
    this.mood = PipMood.idle,
    this.onTap,
    this.reducedMotion = false,
    this.externalBreath,
  });

  @override
  State<PipCompanion> createState() => _PipCompanionState();
}

class _PipCompanionState extends State<PipCompanion>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _breath;
  late AnimationController _blink;
  late AnimationController _action;
  PipAction _currentAction = PipAction.none;
  bool _isBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _action = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (!widget.reducedMotion) {
      _breath.repeat();
      _blink.repeat();
    }
    widget.controller?.addListener(_onAction);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isBackgrounded = (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden);
    if (_isBackgrounded) {
      _breath.stop();
      _blink.stop();
      _action.stop();
    } else if (!widget.reducedMotion) {
      _breath.repeat();
      _blink.repeat();
      if (_action.isAnimating) _action.forward();
    }
  }

  void _onAction() {
    final c = widget.controller;
    if (c == null || c.tick == 0) return;
    setState(() => _currentAction = c.action);
    _action.reset();
    if (!widget.reducedMotion) {
      _action.forward().then((_) {
        if (mounted) setState(() => _currentAction = PipAction.none);
      });
    }
  }

  @override
  void didUpdateWidget(PipCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onAction);
      widget.controller?.addListener(_onAction);
    }
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      if (widget.reducedMotion) {
        _breath.stop();
        _blink.stop();
      } else if (!_isBackgrounded) {
        _breath.repeat();
        _blink.repeat();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?.removeListener(_onAction);
    _breath.dispose();
    _blink.dispose();
    _action.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = PipColors.of(context);
    return GestureDetector(
      onTap: () {
        widget.controller?.play(PipAction.wave);
        widget.onTap?.call();
      },
      child: Semantics(
        label: 'Pip, your animated 3D wellness companion.',
        child: AnimatedBuilder(
          animation: Listenable.merge([_breath, _blink, _action]),
          builder: (context, _) {
            double breathPhase;
            if (widget.externalBreath != null) {
              breathPhase = widget.externalBreath!;
            } else if (widget.reducedMotion || _isBackgrounded) {
              breathPhase = 0.5;
            } else {
              breathPhase =
                  (math.sin(_breath.value * 2 * math.pi - math.pi / 2) + 1) / 2;
            }

            // Blinking: soft eyelid descent and rebound
            double eyelid = 0;
            if (!widget.reducedMotion && !_isBackgrounded) {
              final t = _blink.value;
              if (t > 0.92) {
                eyelid = math.sin((t - 0.92) / 0.08 * math.pi);
              }
            }
            if (widget.mood == PipMood.sleepy) eyelid = 0.85;

            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _PipClay3DPainter(
                colors: colors,
                breath: breathPhase,
                eyelid: eyelid,
                action: _currentAction,
                actionT: _action.value,
                mood: widget.mood,
                accessory: widget.accessory,
                ink: colors.eye,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PipClay3DPainter extends CustomPainter {
  final PipColors colors;
  final double breath; // 0..1
  final double eyelid; // 0..1
  final PipAction action;
  final double actionT; // 0..1
  final PipMood mood;
  final String accessory;
  final Color ink;

  _PipClay3DPainter({
    required this.colors,
    required this.breath,
    required this.eyelid,
    required this.action,
    required this.actionT,
    required this.mood,
    required this.accessory,
    required this.ink,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;

    // Action dynamics & spring physics
    double jumpY = 0;
    double stretchY = 1.0;
    double stretchX = 1.0;
    double armWaveR = 0.0;
    double armRaise = 0.0;
    double torsoTilt = 0.0;

    switch (action) {
      case PipAction.celebrate:
      case PipAction.workout:
        if (actionT > 0) {
          jumpY = -math.sin(actionT * math.pi) * s * 0.12;
          stretchY = 1.0 + math.sin(actionT * math.pi * 2) * 0.08;
          stretchX = 1.0 / math.sqrt(stretchY);
          armRaise = math.sin(actionT * math.pi);
        }
        break;
      case PipAction.stretch:
      case PipAction.walk:
        if (actionT > 0) {
          stretchY = 1.0 + math.sin(actionT * math.pi) * 0.12;
          stretchX = 1.0 - math.sin(actionT * math.pi) * 0.05;
          torsoTilt = math.sin(actionT * math.pi * 2) * 0.05;
        }
        break;
      case PipAction.wave:
        if (actionT > 0) {
          armWaveR = math.sin(actionT * math.pi * 6) * 0.65 * (1 - actionT);
          torsoTilt = math.sin(actionT * math.pi * 2) * 0.03;
        }
        break;
      case PipAction.water:
        if (actionT > 0) {
          jumpY = -math.sin(actionT * math.pi) * s * 0.06;
          stretchY = 1.0 + math.sin(actionT * math.pi * 2) * 0.05;
        }
        break;
      case PipAction.meal:
        if (actionT > 0) {
          stretchX = 1.0 + math.sin(actionT * math.pi) * 0.06;
        }
        break;
      case PipAction.none:
        break;
    }

    // Breathing volume
    final breathScale = 1.0 + (breath - 0.5) * 0.04;
    final bodyW = s * 0.35 * stretchX * (mood == PipMood.breathing ? 1.06 : 1.0);
    final bodyH = s * 0.39 * breathScale * stretchY;
    final bodyCy = s * 0.58 + jumpY;

    // ---------------------------------------------------- 1. CONTACT SHADOW
    final shadowScale =
        (1.0 - (jumpY.abs() / (s * 0.15))).clamp(0.45, 1.0) * stretchX;
    final shadowAlpha = (0.24 - (jumpY.abs() / (s * 0.15)) * 0.14).clamp(0.04, 0.24);
    final shadowRect = Rect.fromCenter(
      center: Offset(cx, s * 0.88),
      width: s * 0.52 * shadowScale,
      height: s * 0.13 * shadowScale,
    );
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withOpacity(shadowAlpha),
          Colors.black.withOpacity(shadowAlpha * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(shadowRect);
    canvas.drawOval(shadowRect, shadowPaint);

    // Apply tilt if moving
    if (torsoTilt != 0) {
      canvas.save();
      canvas.translate(cx, bodyCy);
      canvas.rotate(torsoTilt);
      canvas.translate(-cx, -bodyCy);
    }

    // ----------------------------------------------------------- 2. FEET
    for (final dx in [-1, 1]) {
      final footCx = cx + dx * s * 0.15;
      final footCy = s * 0.86 + jumpY * 0.5;
      final footRect = Rect.fromCenter(
        center: Offset(footCx, footCy),
        width: s * 0.165,
        height: s * 0.105,
      );

      final footShader = RadialGradient(
        center: const Alignment(-0.25, -0.4),
        radius: 0.8,
        colors: [
          colors.bodyHighlight,
          colors.body,
          colors.bodyShade,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(footRect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(footRect, const Radius.circular(24)),
        Paint()..shader = footShader,
      );

      // Foot ambient occlusion shadow underneath
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(footCx, footCy + s * 0.04),
          width: s * 0.13,
          height: s * 0.035,
        ),
        Paint()..color = Colors.black.withOpacity(0.08),
      );
    }

    // ----------------------------------------------------- 3. ARMS (Back/Left)
    _draw3DArm(
      canvas,
      cx - s * 0.29,
      bodyCy - s * 0.01,
      -0.45 + (action == PipAction.stretch ? -0.8 * armRaise : 0),
      s,
      isRight: false,
    );

    // ----------------------------------------------------- 4. 3D CLAY BODY
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, bodyCy),
      width: bodyW * 2,
      height: bodyH * 2,
    );

    // Layer 1: Core 3D spherical clay lighting
    final bodyShader = RadialGradient(
      center: const Alignment(-0.35, -0.45),
      focal: const Alignment(-0.45, -0.55),
      focalRadius: 0.1,
      radius: 0.95,
      colors: [
        colors.bodyHighlight,
        colors.body,
        colors.bodyShade,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(bodyRect);

    canvas.drawOval(bodyRect, Paint()..shader = bodyShader);

    // Layer 2: Subtle subsurface rim sheen (clay tactile warmth)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..shader = SweepGradient(
        center: const Alignment(0, 0),
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          Colors.white.withOpacity(0.35), // top-left light
          Colors.transparent,
          Colors.white.withOpacity(0.12), // bottom-right bounce
          Colors.transparent,
          Colors.white.withOpacity(0.35),
        ],
        stops: const [0.0, 0.4, 0.7, 0.88, 1.0],
      ).createShader(bodyRect);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, bodyCy),
        width: bodyW * 2 - s * 0.02,
        height: bodyH * 2 - s * 0.02,
      ),
      rimPaint,
    );

    // Layer 3: Soft specular highlight spot on forehead
    final specRect = Rect.fromCenter(
      center: Offset(cx - bodyW * 0.35, bodyCy - bodyH * 0.45),
      width: s * 0.16,
      height: s * 0.10,
    );
    canvas.drawOval(
      specRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.42),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(specRect),
    );

    // ---------------------------------------------- 5. 3D CLAY BELLY PATCH
    final bellyCy = bodyCy + bodyH * 0.36;
    final bellyRect = Rect.fromCenter(
      center: Offset(cx, bellyCy),
      width: bodyW * 1.12,
      height: bodyH * 0.98,
    );
    final bellyShader = RadialGradient(
      center: const Alignment(-0.25, -0.35),
      radius: 0.85,
      colors: [
        Colors.white.withOpacity(0.85),
        colors.belly,
        colors.body.withOpacity(0.7),
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(bellyRect);
    canvas.drawOval(bellyRect, Paint()..shader = bellyShader);

    // ----------------------------------------------------- 6. ACCESSORIES
    if (accessory == 'star') {
      _draw3DStar(canvas, Offset(cx, bellyCy - bodyH * 0.08), s * 0.065);
    } else if (accessory == 'scarf') {
      _draw3DScarf(canvas, cx, bodyCy - bodyH * 0.42, bodyW, s);
    }

    // ----------------------------------------------------- 7. SPROUT / CROWN
    final headY = bodyCy - bodyH * 0.96;
    if (accessory == 'flower') {
      _draw3DFlowerCrown(canvas, cx, headY - s * 0.015, s);
    } else {
      _draw3DSprout(canvas, cx, headY, s, torsoTilt);
    }

    // ----------------------------------------------------- 8. 3D FACE
    final eyeY = bodyCy - bodyH * 0.16;
    final eyeDX = bodyW * 0.39;
    final eyeR = s * 0.040;

    for (final dx in [-1, 1]) {
      final ex = cx + dx * eyeDX;

      // Joyful closed eyes (arches)
      if (mood == PipMood.happy ||
          action == PipAction.celebrate ||
          action == PipAction.workout ||
          action == PipAction.walk) {
        final p = Path()
          ..moveTo(ex - eyeR * 1.3, eyeY + eyeR * 0.2)
          ..quadraticBezierTo(
              ex, eyeY - eyeR * 1.4, ex + eyeR * 1.3, eyeY + eyeR * 0.2);
        canvas.drawPath(
          p,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.014
            ..strokeCap = StrokeCap.round,
        );
      } else {
        // Deep clay bead eyes
        final eyeRect = Rect.fromCircle(center: Offset(ex, eyeY), radius: eyeR);
        final eyeShader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.8,
          colors: [
            const Color(0xFF4A4E4C),
            ink,
            Colors.black,
          ],
        ).createShader(eyeRect);
        canvas.drawCircle(Offset(ex, eyeY), eyeR, Paint()..shader = eyeShader);

        // Specular eye catchlights
        canvas.drawCircle(
          Offset(ex - eyeR * 0.28, eyeY - eyeR * 0.32),
          eyeR * 0.34,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(ex + eyeR * 0.32, eyeY + eyeR * 0.28),
          eyeR * 0.16,
          Paint()..color = Colors.white.withOpacity(0.7),
        );

        // Clay eyelids when blinking/sleepy
        if (eyelid > 0) {
          final lidH = eyeR * 2.2 * eyelid;
          final lidRect = Rect.fromCenter(
            center: Offset(ex, eyeY - eyeR * (1 - eyelid)),
            width: eyeR * 2.6,
            height: lidH,
          );
          canvas.drawOval(
            lidRect,
            Paint()..color = colors.body,
          );
          // Eyelid crease shadow
          canvas.drawArc(
            lidRect,
            0,
            math.pi,
            false,
            Paint()
              ..color = colors.bodyShade.withOpacity(0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          );
        }
      }

      // Soft diffused peach blush cheeks
      final cheekRect = Rect.fromCircle(
        center: Offset(ex + dx * eyeR * 1.8, eyeY + eyeR * 1.6),
        radius: eyeR * 1.1,
      );
      canvas.drawOval(
        cheekRect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              colors.cheek.withOpacity(0.72),
              colors.cheek.withOpacity(0.0),
            ],
          ).createShader(cheekRect),
      );
    }

    // ----------------------------------------------------- 9. MOUTH
    final mouthY = eyeY + s * 0.082;
    if (mood == PipMood.breathing) {
      // Gentle breathing 'o' mouth
      final mouthR = s * 0.024 * (0.8 + breath * 0.5);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, mouthY), width: mouthR * 1.4, height: mouthR * 1.8),
        Paint()..color = ink,
      );
    } else if (action == PipAction.celebrate || action == PipAction.workout) {
      // Open cheerful smile
      final openMouth = Path()
        ..moveTo(cx - s * 0.055, mouthY)
        ..quadraticBezierTo(cx, mouthY + s * 0.07, cx + s * 0.055, mouthY)
        ..close();
      canvas.drawPath(openMouth, Paint()..color = ink);
      // Tongue
      final tongue = Path()
        ..moveTo(cx - s * 0.035, mouthY + s * 0.035)
        ..quadraticBezierTo(cx, mouthY + s * 0.065, cx + s * 0.035, mouthY + s * 0.035)
        ..close();
      canvas.drawPath(tongue, Paint()..color = const Color(0xFFF28F95));
    } else {
      // Warm friendly smile
      final smile = Path()
        ..moveTo(cx - s * 0.052, mouthY)
        ..quadraticBezierTo(cx, mouthY + s * 0.045, cx + s * 0.052, mouthY);
      canvas.drawPath(
        smile,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.014
          ..strokeCap = StrokeCap.round,
      );
    }

    // ----------------------------------------------------- 10. ARMS (Front/Right)
    final rightAngle = 0.45 + armWaveR + armRaise * -1.35;
    _draw3DArm(
      canvas,
      cx + s * 0.29,
      bodyCy - s * 0.01,
      rightAngle,
      s,
      isRight: true,
    );

    if (torsoTilt != 0) canvas.restore();

    // ----------------------------------------------------- 11. ACTION PARTICLES
    _drawActionFX(canvas, cx, bodyCy, s);
  }

  void _draw3DArm(
    Canvas canvas,
    double x,
    double y,
    double angle,
    double s, {
    required bool isRight,
  }) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    final armRect = Rect.fromCenter(
      center: Offset(isRight ? s * 0.06 : -s * 0.06, 0),
      width: s * 0.17,
      height: s * 0.088,
    );

    final armShader = RadialGradient(
      center: Alignment(isRight ? -0.2 : 0.2, -0.3),
      radius: 0.85,
      colors: [
        colors.bodyHighlight,
        colors.body,
        colors.bodyShade,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(armRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(armRect, const Radius.circular(20)),
      Paint()..shader = armShader,
    );

    canvas.restore();
  }

  void _draw3DSprout(
    Canvas canvas,
    double cx,
    double headY,
    double s,
    double tilt,
  ) {
    // 3D Stalk with rounded cap
    final stemPath = Path()
      ..moveTo(cx - s * 0.008, headY + s * 0.01)
      ..lineTo(cx - s * 0.006, headY - s * 0.09)
      ..arcToPoint(Offset(cx + s * 0.006, headY - s * 0.09),
          radius: Radius.circular(s * 0.006))
      ..lineTo(cx + s * 0.008, headY + s * 0.01)
      ..close();

    final stemRect = Rect.fromCenter(
      center: Offset(cx, headY - s * 0.04),
      width: s * 0.02,
      height: s * 0.10,
    );
    canvas.drawPath(
      stemPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.leafHighlight, colors.leafDark],
        ).createShader(stemRect),
    );

    // Left and Right plump clay leaves
    final leafSway = math.sin(breath * math.pi * 2) * 0.05 + tilt * 0.5;
    for (final dx in [-1, 1]) {
      final p = Path()
        ..moveTo(cx, headY - s * 0.09)
        ..quadraticBezierTo(
          cx + dx * s * 0.11 + leafSway * s,
          headY - s * 0.14,
          cx + dx * s * 0.14 + leafSway * s,
          headY - s * 0.05,
        )
        ..quadraticBezierTo(
          cx + dx * s * 0.06,
          headY - s * 0.06,
          cx,
          headY - s * 0.09,
        )
        ..close();

      final leafRect = Rect.fromCircle(
        center: Offset(cx + dx * s * 0.07, headY - s * 0.09),
        radius: s * 0.07,
      );
      final leafShader = RadialGradient(
        center: Alignment(dx > 0 ? -0.3 : 0.3, -0.4),
        colors: [
          colors.leafHighlight,
          colors.leaf,
          colors.leafDark,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(leafRect);

      canvas.drawPath(p, Paint()..shader = leafShader);

      // Spine vein highlight
      final vein = Path()
        ..moveTo(cx, headY - s * 0.09)
        ..quadraticBezierTo(
          cx + dx * s * 0.07 + leafSway * s * 0.5,
          headY - s * 0.08,
          cx + dx * s * 0.12 + leafSway * s,
          headY - s * 0.06,
        );
      canvas.drawPath(
        vein,
        Paint()
          ..color = colors.leafHighlight.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _draw3DFlowerCrown(Canvas canvas, double cx, double headY, double s) {
    final rng = math.Random(5);
    for (var i = 0; i < 5; i++) {
      final a = math.pi * (0.12 + 0.19 * i) + (rng.nextDouble() - 0.5) * 0.08;
      final fx = cx + math.cos(a) * s * 0.17;
      final fy = headY - math.sin(a) * s * 0.06;

      // 5 rounded clay petals
      for (var p = 0; p < 5; p++) {
        final pa = p / 5 * math.pi * 2;
        final px = fx + math.cos(pa) * s * 0.024;
        final py = fy + math.sin(pa) * s * 0.024;
        final petRect = Rect.fromCircle(center: Offset(px, py), radius: s * 0.022);
        canvas.drawCircle(
          Offset(px, py),
          s * 0.020,
          Paint()
            ..shader = const RadialGradient(
              colors: [
                Color(0xFFFFDFEA),
                Color(0xFFF9A8C6),
              ],
            ).createShader(petRect),
        );
      }
      // Spherical yellow clay center
      final cenRect = Rect.fromCircle(center: Offset(fx, fy), radius: s * 0.017);
      canvas.drawCircle(
        Offset(fx, fy),
        s * 0.016,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [
              Color(0xFFFFF4B8),
              Color(0xFFFFC53D),
              Color(0xFFE5A110),
            ],
          ).createShader(cenRect),
      );
    }
  }

  void _draw3DStar(Canvas canvas, Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.46;
      final pt = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();

    final starRect = Rect.fromCircle(center: c, radius: r);
    canvas.drawPath(
      p,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [
            Color(0xFFFFF5C0),
            Color(0xFFFFC53D),
            Color(0xFFD99008),
          ],
        ).createShader(starRect),
    );
  }

  void _draw3DScarf(Canvas canvas, double cx, double y, double bodyW, double s) {
    final scarfRect = Rect.fromCenter(
      center: Offset(cx, y),
      width: bodyW * 1.55,
      height: s * 0.115,
    );
    final scarfShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFD1BFF8),
        Color(0xFFB79CED),
        Color(0xFF8F6CC8),
      ],
    ).createShader(scarfRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(scarfRect, const Radius.circular(22)),
      Paint()..shader = scarfShader,
    );

    // Scarf tail
    final tailRect = Rect.fromLTRB(
      cx + bodyW * 0.35,
      y,
      cx + bodyW * 0.64,
      y + s * 0.22,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tailRect, const Radius.circular(14)),
      Paint()..shader = scarfShader,
    );
  }

  void _drawActionFX(Canvas canvas, double cx, double cy, double s) {
    if (actionT <= 0 || actionT >= 0.95) return;

    if (action == PipAction.water) {
      // Floating translucent hydration droplets
      final dropPaint = Paint()..color = const Color(0xFF64B5F6).withOpacity(1 - actionT);
      for (var i = 0; i < 6; i++) {
        final angle = (i / 6) * math.pi * 2 + actionT * 2;
        final dist = s * (0.32 + actionT * 0.22);
        final dx = cx + math.cos(angle) * dist;
        final dy = cy + math.sin(angle) * dist * 0.7 - actionT * s * 0.15;
        canvas.drawCircle(Offset(dx, dy), s * 0.02 * (1 - actionT * 0.5), dropPaint);
      }
    } else if (action == PipAction.celebrate || action == PipAction.workout) {
      // Sparkles and golden bursts
      final sparkPaint = Paint()..color = const Color(0xFFFFC53D).withOpacity(1 - actionT);
      final rng = math.Random(11);
      for (var i = 0; i < 8; i++) {
        final a = rng.nextDouble() * math.pi * 2;
        final r = s * (0.38 + actionT * 0.32);
        final px = cx + math.cos(a) * r;
        final py = cy + math.sin(a) * r * 0.85;
        final sparkSize = s * 0.022 * (1 - actionT * 0.5);
        canvas.drawLine(
          Offset(px - sparkSize, py),
          Offset(px + sparkSize, py),
          sparkPaint..strokeWidth = sparkSize * 0.4,
        );
        canvas.drawLine(
          Offset(px, py - sparkSize),
          Offset(px, py + sparkSize),
          sparkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PipClay3DPainter old) =>
      old.breath != breath ||
      old.eyelid != eyelid ||
      old.actionT != actionT ||
      old.action != action ||
      old.mood != mood ||
      old.accessory != accessory;
}

/// Refined iOS-inspired speech bubble.
class SpeechBubble extends StatelessWidget {
  final String text;
  final Color? color;
  final TextStyle? style;
  final VoidCallback? onTap;

  const SpeechBubble({
    super.key,
    required this.text,
    this.color,
    this.style,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 290),
            decoration: BoxDecoration(
              color: color ??
                  (dark ? const Color(0xFF2C2822) : const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.04),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(dark ? 0.28 : 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: style ??
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
              textAlign: TextAlign.center,
            ),
          ),
          CustomPaint(
            size: const Size(20, 9),
            painter: _TailPainter(
              color ??
                  (dark ? const Color(0xFF2C2822) : const Color(0xFFFFFFFF)),
              border: dark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
            ),
          ),
        ],
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color color;
  final Color border;
  _TailPainter(this.color, {required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width / 2 - 7, 0)
      ..lineTo(size.width / 2 + 7, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawPath(
      p,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) =>
      old.color != color || old.border != border;
}
