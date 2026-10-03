import 'package:flutter/material.dart';

import 'theme.dart';
import 'utils.dart';

/// Rounded content container with a soft shadow — the basic building block.
class BubbleCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  const BubbleCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(BloomSpacing.md),
    this.onTap,
    this.radius = BloomRadii.card,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: dark
              ? Colors.white.withOpacity(0.07)
              : BloomColors.line.withOpacity(0.6),
          width: 0.8,
        ),
        boxShadow: BloomShadows.soft(context),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: card,
    );
  }
}

/// Primary pill action.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool expanded;

  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.secondary = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    final btn = secondary
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(textStyle: style),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
            label: Text(label),
            style: FilledButton.styleFrom(textStyle: style),
          );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// Section heading with an optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? subtitle;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        4,
        BloomSpacing.lg,
        4,
        BloomSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: t.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Friendly empty state.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? tint;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BubbleCard(
      color: tint ?? (dark ? BloomColors.surface2D : BloomColors.surface2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: BloomSpacing.md),
          Text(title, style: t.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: BloomSpacing.xs),
          Text(body, style: t.bodySmall, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: BloomSpacing.md),
            PillButton(
              label: actionLabel!,
              onPressed: onAction,
              secondary: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact stat bubble used on the Today screen.
class StatBubble extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color tint;
  final Color deep;
  final double progress; // 0..1
  final VoidCallback? onTap;

  const StatBubble({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
    required this.deep,
    this.progress = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BubbleCard(
      onTap: onTap,
      padding: const EdgeInsets.all(BloomSpacing.sm),
      radius: BloomRadii.bubble,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: deep),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: t.titleMedium?.copyWith(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: t.bodySmall?.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: deep.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(deep),
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented pill selector.
class SegmentedPills<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  const SegmentedPills({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasFiniteWidth = constraints.hasBoundedWidth;
        final pills = List.generate(values.length, (i) {
          final sel = values[i] == selected;
          final pill = GestureDetector(
            onTap: () => onChanged(values[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
              decoration: BoxDecoration(
                color: sel ? scheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(BloomRadii.pill),
                border: sel
                    ? Border.all(
                        color: dark
                            ? Colors.white.withOpacity(0.08)
                            : BloomColors.line.withOpacity(0.8),
                        width: 0.8,
                      )
                    : null,
                boxShadow: sel ? BloomShadows.soft(context) : null,
              ),
              alignment: hasFiniteWidth ? Alignment.center : null,
              child: Text(
                labels[i],
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: sel
                      ? scheme.primary
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
          return hasFiniteWidth ? Expanded(child: pill) : pill;
        });

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(BloomRadii.pill),
            border: Border.all(
              color: dark
                  ? Colors.white.withOpacity(0.06)
                  : BloomColors.line.withOpacity(0.5),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: hasFiniteWidth ? MainAxisSize.max : MainAxisSize.min,
            children: pills,
          ),
        );
      },
    );
  }
}

/// Multi-select chips.
class ChoiceChips extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final List<String>? labels;

  const ChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (i) {
        final v = options[i];
        final sel = selected.contains(v);
        return FilterChip(
          label: Text(labels != null ? labels![i] : v),
          selected: sel,
          onSelected: (_) => onToggle(v),
          selectedColor: scheme.primary.withOpacity(0.2),
          checkmarkColor: scheme.primary,
        );
      }),
    );
  }
}

/// Timeline row for the Today activity feed.
class TimelineTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color deep;
  final String title;
  final String subtitle;
  final String time;
  final VoidCallback? onTap;

  const TimelineTile({
    super.key,
    required this.icon,
    required this.tint,
    required this.deep,
    required this.title,
    required this.subtitle,
    required this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BloomRadii.bubble),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: deep, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleSmall),
                  Text(
                    subtitle,
                    style: t.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(time, style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Small informational note bubble.
class InfoNote extends StatelessWidget {
  final String text;
  final IconData icon;
  const InfoNote({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(BloomSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(BloomRadii.bubble),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Settings-style row.
class SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? tint;
  final Color? deep;

  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.onTap,
    this.tint,
    this.deep,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = tint ?? (dark ? BloomColors.surface2D : BloomColors.surface2);
    final fg = deep ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BloomRadii.bubble),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: fg, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleSmall),
                  if (subtitleWidget != null)
                    DefaultTextStyle(
                      style: t.bodySmall!,
                      child: subtitleWidget!,
                    ),
                  if (subtitleWidget == null && subtitle != null)
                    Text(subtitle!, style: t.bodySmall),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Ring progress indicator.
class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Widget? center;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 56,
    this.strokeWidth = 7,
    required this.color,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

/// Macro distribution bar.
class MacroBar extends StatelessWidget {
  final double protein, carbs, fat;
  final double? targetProtein, targetCarbs, targetFat;
  const MacroBar({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.targetProtein,
    this.targetCarbs,
    this.targetFat,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final total = protein + carbs + fat;
    final trackColor = dark
        ? Colors.white.withOpacity(0.08)
        : BloomColors.surface2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 8,
            color: trackColor,
            child: total <= 0
                ? const SizedBox.expand()
                : Row(
                    children: [
                      if (protein > 0)
                        Expanded(
                          flex: (protein / total * 1000).round().clamp(1, 1000),
                          child: Container(color: BloomColors.lavenderDeep),
                        ),
                      if (carbs > 0)
                        Expanded(
                          flex: (carbs / total * 1000).round().clamp(1, 1000),
                          child: Container(color: BloomColors.peachDeep),
                        ),
                      if (fat > 0)
                        Expanded(
                          flex: (fat / total * 1000).round().clamp(1, 1000),
                          child: Container(color: BloomColors.mintDeep),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _legendItem(
              context,
              'Protein',
              Fmt.grams(protein),
              BloomColors.lavenderDeep,
            ),
            _legendItem(
              context,
              'Carbs',
              Fmt.grams(carbs),
              BloomColors.peachDeep,
            ),
            _legendItem(context, 'Fat', Fmt.grams(fat), BloomColors.mintDeep),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(
    BuildContext context,
    String label,
    String value,
    Color c,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ],
    );
  }
}

/// Shows a rounded bottom sheet and returns the result.
Future<T?> showBubbleSheet<T>(
  BuildContext context,
  Widget child, {
  bool scrollable = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(BloomRadii.sheet),
      ),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: BloomSpacing.lg,
          right: BloomSpacing.lg,
          top: BloomSpacing.sm,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + BloomSpacing.lg,
        ),
        child: scrollable ? SingleChildScrollView(child: child) : child,
      ),
    ),
  );
}

/// Confirmation dialog; returns true when confirmed.
Future<bool> askConfirm(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = 'Confirm',
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body, style: Theme.of(ctx).textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return res == true;
}

/// Number input sheet used for quick logging.
Future<double?> askNumber(
  BuildContext context, {
  required String title,
  required String unit,
  double? initial,
  double min = 0,
  double? max,
}) async {
  final ctrl = TextEditingController(text: initial?.toString() ?? '');
  final res = await showBubbleSheet<double>(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BloomSpacing.md),
        TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall,
          decoration: InputDecoration(hintText: '0', suffixText: unit),
        ),
        const SizedBox(height: BloomSpacing.md),
        PillButton(
          label: 'Save',
          expanded: true,
          onPressed: () {
            final v = double.tryParse(ctrl.text.trim());
            if (v == null || v < min || (max != null && v > max)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Enter a value between $min and ${max ?? '∞'} $unit',
                  ),
                ),
              );
              return;
            }
            Navigator.of(context).pop(v);
          },
        ),
      ],
    ),
    scrollable: false,
  );
  ctrl.dispose();
  return res;
}

// --------------------------------------------------- 3D clay illustrations

/// Soft dimensional clay-styled dumbbell illustration.
class ClayDumbbellIllustration extends StatelessWidget {
  final double size;
  final Color? color;
  const ClayDumbbellIllustration({super.key, this.size = 56, this.color});

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? BloomColors.lavenderDeep;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ClayDumbbellPainter(baseColor: baseColor)),
    );
  }
}

class _ClayDumbbellPainter extends CustomPainter {
  final Color baseColor;
  _ClayDumbbellPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.52);

    // 1. Contact shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, h * 0.88),
        width: w * 0.72,
        height: h * 0.22,
      ),
      shadowPaint,
    );

    // Canvas rotation for dynamic athletic angle (-25 deg)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.44);

    final shaftLength = w * 0.52;
    final shaftRadius = w * 0.08;

    // 2. Barbell handle (shaft)
    final shaftRect = Rect.fromCenter(
      center: Offset.zero,
      width: shaftLength,
      height: shaftRadius * 2,
    );
    final shaftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          BloomColors.line.withOpacity(0.9),
          const Color(0xFFC7CBD8),
          const Color(0xFF9096A8),
        ],
      ).createShader(shaftRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shaftRect, Radius.circular(shaftRadius)),
      shaftPaint,
    );

    // Handle grip bands
    final gripPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var gx = -w * 0.14; gx <= w * 0.14; gx += w * 0.07) {
      canvas.drawLine(
        Offset(gx, -shaftRadius),
        Offset(gx, shaftRadius),
        gripPaint,
      );
    }

    // 3. Weight plates (left and right)
    void drawPlate(double cx, double radiusX, double radiusY) {
      final plateRect = Rect.fromCenter(
        center: Offset(cx, 0),
        width: radiusX * 2,
        height: radiusY * 2,
      );

      // Plate body gradient
      final platePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: [
            Color.lerp(baseColor, Colors.white, 0.45)!,
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.35)!,
          ],
        ).createShader(plateRect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(plateRect, Radius.circular(radiusX * 0.5)),
        platePaint,
      );

      // Clay specular highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - radiusX * 0.25, -radiusY * 0.35),
          width: radiusX * 0.6,
          height: radiusY * 0.3,
        ),
        highlightPaint,
      );

      // Rim bevel
      final bevelPaint = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          plateRect.deflate(1.2),
          Radius.circular(radiusX * 0.45),
        ),
        bevelPaint,
      );
    }

    final pWidth = w * 0.18;
    final pHeight = h * 0.54;
    // Left outer & inner plates
    drawPlate(-w * 0.28, pWidth * 0.85, pHeight * 0.92);
    drawPlate(-w * 0.21, pWidth, pHeight);

    // Right inner & outer plates
    drawPlate(w * 0.21, pWidth, pHeight);
    drawPlate(w * 0.28, pWidth * 0.85, pHeight * 0.92);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ClayDumbbellPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor;
}

/// Soft dimensional clay-styled sneaker / walking shoe illustration.
class ClaySneakerIllustration extends StatelessWidget {
  final double size;
  final Color? color;
  const ClaySneakerIllustration({super.key, this.size = 56, this.color});

  @override
  Widget build(BuildContext context) {
    final upperColor = color ?? BloomColors.mintDeep;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ClaySneakerPainter(upperColor: upperColor)),
    );
  }
}

class _ClaySneakerPainter extends CustomPainter {
  final Color upperColor;
  _ClaySneakerPainter({required this.upperColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft contact shadow beneath sole
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.88),
        width: w * 0.84,
        height: h * 0.2,
      ),
      shadowPaint,
    );

    // 2. Thick sculpted clay sole
    final solePath = Path();
    solePath.moveTo(w * 0.12, h * 0.72);
    solePath.cubicTo(
      w * 0.28,
      h * 0.70,
      w * 0.65,
      h * 0.68,
      w * 0.90,
      h * 0.62,
    );
    solePath.cubicTo(
      w * 0.96,
      h * 0.64,
      w * 0.95,
      h * 0.78,
      w * 0.88,
      h * 0.82,
    );
    solePath.cubicTo(
      w * 0.65,
      h * 0.85,
      w * 0.32,
      h * 0.85,
      w * 0.14,
      h * 0.83,
    );
    solePath.cubicTo(
      w * 0.08,
      h * 0.81,
      w * 0.07,
      h * 0.74,
      w * 0.12,
      h * 0.72,
    );
    solePath.close();

    final soleRect = Rect.fromLTWH(0, h * 0.6, w, h * 0.3);
    final solePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFF1F4F9), Color(0xFFD6DBE5)],
      ).createShader(soleRect);
    canvas.drawPath(solePath, solePaint);

    // Sole tread ridges
    final treadPaint = Paint()
      ..color = const Color(0xFFBDC4D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var tx = w * 0.22; tx <= w * 0.82; tx += w * 0.1) {
      canvas.drawLine(
        Offset(tx, h * 0.75),
        Offset(tx + w * 0.03, h * 0.83),
        treadPaint,
      );
    }

    // 3. Shoe upper body
    final upperPath = Path();
    upperPath.moveTo(w * 0.16, h * 0.71);
    upperPath.cubicTo(
      w * 0.14,
      h * 0.52,
      w * 0.24,
      h * 0.42,
      w * 0.35,
      h * 0.40,
    ); // Heel & collar
    upperPath.cubicTo(
      w * 0.44,
      h * 0.48,
      w * 0.50,
      h * 0.52,
      w * 0.58,
      h * 0.52,
    ); // Ankle dip
    upperPath.cubicTo(
      w * 0.68,
      h * 0.45,
      w * 0.76,
      h * 0.52,
      w * 0.88,
      h * 0.62,
    ); // Toe box
    upperPath.cubicTo(
      w * 0.70,
      h * 0.67,
      w * 0.40,
      h * 0.69,
      w * 0.16,
      h * 0.71,
    ); // Bottom junction
    upperPath.close();

    final upperRect = Rect.fromLTWH(w * 0.1, h * 0.35, w * 0.8, h * 0.4);
    final upperPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.4),
        radius: 0.85,
        colors: [
          Color.lerp(upperColor, Colors.white, 0.4)!,
          upperColor,
          Color.lerp(upperColor, Colors.black, 0.3)!,
        ],
      ).createShader(upperRect);
    canvas.drawPath(upperPath, upperPaint);

    // 4. Heel counter accent overlay
    final heelPath = Path();
    heelPath.moveTo(w * 0.16, h * 0.71);
    heelPath.cubicTo(
      w * 0.14,
      h * 0.52,
      w * 0.24,
      h * 0.42,
      w * 0.32,
      h * 0.41,
    );
    heelPath.cubicTo(
      w * 0.30,
      h * 0.56,
      w * 0.26,
      h * 0.68,
      w * 0.25,
      h * 0.71,
    );
    heelPath.close();

    final heelPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(upperColor, BloomColors.peach, 0.5)!,
          BloomColors.peachDeep,
        ],
      ).createShader(upperRect);
    canvas.drawPath(heelPath, heelPaint);

    // 5. Clay laces
    final lacePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.52, h * 0.48),
      Offset(w * 0.62, h * 0.53),
      lacePaint,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.45),
      Offset(w * 0.68, h * 0.50),
      lacePaint,
    );
    canvas.drawLine(
      Offset(w * 0.64, h * 0.42),
      Offset(w * 0.73, h * 0.48),
      lacePaint,
    );

    // 6. Specular catchlight on toe
    final catchPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.78, h * 0.57),
        width: w * 0.18,
        height: h * 0.08,
      ),
      catchPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ClaySneakerPainter oldDelegate) =>
      oldDelegate.upperColor != upperColor;
}
