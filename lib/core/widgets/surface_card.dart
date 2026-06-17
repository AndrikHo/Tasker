import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/app_style.dart';

/// The single elevated surface used across the app: cards, rows, sheets and
/// bars. Gives reference-grade depth via a layered fill, a soft drop shadow
/// and a hairline lip. The Glass style swaps the solid fill for a real
/// backdrop blur. Pass [onTap] to make it a tactile, press-scaling button.
class SurfaceCard extends ConsumerStatefulWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius,
    this.onTap,
    this.alt = false,
    this.elevated = true,
    this.border = true,
    this.gradient,
    this.fillOverride,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? radius;
  final VoidCallback? onTap;

  /// Use the lighter, nested surface fill (for surfaces sitting on a card).
  final bool alt;

  /// Whether to cast the soft drop shadow.
  final bool elevated;

  /// Whether to draw the hairline edge.
  final bool border;

  /// Paints this gradient as the surface fill instead of the themed color.
  /// Disables the glass blur for this tile so the gradient stays crisp.
  final Gradient? gradient;

  /// Solid fill that overrides the themed surface color (and the blur).
  final Color? fillOverride;

  @override
  ConsumerState<SurfaceCard> createState() => _SurfaceCardState();
}

class _SurfaceCardState extends ConsumerState<SurfaceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(styleProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final br = BorderRadius.circular(widget.radius ?? style.cardRadius);

    final hasPaint = widget.gradient != null || widget.fillOverride != null;
    final useBlur = style.glassy && style.blurSigma > 0 && !hasPaint;
    final fill = widget.fillOverride ??
        (useBlur
            ? style.glassFill(dark)
            : (widget.alt
                ? style.cardColorAlt(dark)
                : style.cardColor(dark)));

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.gradient == null ? fill : null,
        gradient: widget.gradient,
        borderRadius: br,
        border: widget.border
            ? Border.all(color: style.hairline(dark), width: 1)
            : null,
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );

    if (useBlur) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: style.blurSigma, sigmaY: style.blurSigma),
        child: content,
      );
    }

    Widget card = DecoratedBox(
      // Shadow lives on an outer box so it is not clipped by the surface.
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: widget.elevated ? style.cardShadow(dark) : null,
      ),
      child: ClipRRect(borderRadius: br, child: content),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? style.pressScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}
