import 'package:flutter/material.dart';

import '../theme/app_style.dart';

/// Full-screen backdrop that paints the style's base color plus two soft
/// radial accent glows. Sits behind every route to give the UI depth
/// ("premium glow" direction).
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.style,
    required this.brightness,
    this.child,
  });

  final AppStyle style;
  final Brightness brightness;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    final base = dark ? style.baseDark : style.baseLight;
    final glow = style.glowOpacity * (dark ? 1.0 : 0.6);

    return DecoratedBox(
      decoration: BoxDecoration(color: base),
      child: Stack(
        children: [
          // Primary glow, top-trailing. Large and soft for clean ambience.
          Positioned(
            top: -220,
            right: -180,
            child: _Glow(color: style.accent.withValues(alpha: glow), size: 560),
          ),
          // Secondary glow, lower-leading.
          Positioned(
            bottom: -240,
            left: -200,
            child: _Glow(
              color: style.accent2.withValues(alpha: glow * 0.7),
              size: 520,
            ),
          ),
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
