import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/app_style.dart';
import 'surface_card.dart';

/// Building blocks for the bento layout: an editorial screen header with a
/// small eyebrow over an oversized title, a flexible bento tile, and a
/// big-number stat tile. The whole app reads through these so the large
/// typography and tile rhythm stay consistent across screens and styles.

/// Standard gap between bento tiles.
const double kBentoGap = 12;

/// Outer horizontal padding for bento content.
const double kBentoPad = 16;

/// A small eyebrow label above an oversized screen title.
class BentoHeader extends StatelessWidget {
  const BentoHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String? eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(kBentoPad + 4, 14, kBentoPad, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  title,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A flexible bento tile: a styled surface with consistent padding, optional
/// fixed height, accent-tinted or gradient fill, and tap feedback.
class BentoTile extends ConsumerWidget {
  const BentoTile({
    super.key,
    required this.child,
    this.onTap,
    this.height,
    this.padding = const EdgeInsets.all(18),
    this.gradient,
    this.accentFill = false,
    this.alt = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double? height;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;

  /// Subtle accent-tinted fill (used to make a tile feel "live").
  final bool accentFill;

  /// Use the lighter nested surface fill.
  final bool alt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    Color? fill;
    if (accentFill && gradient == null) {
      fill = Color.alphaBlend(
        style.accent.withValues(alpha: dark ? 0.16 : 0.12),
        style.cardColor(dark),
      );
    }

    final card = SurfaceCard(
      onTap: onTap,
      padding: padding,
      alt: alt,
      gradient: gradient,
      fillOverride: fill,
      child: child,
    );

    if (height == null) return card;
    return SizedBox(height: height, child: card);
  }
}

/// An accent-gradient action tile (e.g. "New task", "Add friend"): a plus
/// badge with a bold label. Shares the stat-tile footprint.
class BentoAddTile extends ConsumerWidget {
  const BentoAddTile({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_rounded,
    this.height = 116,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    return BentoTile(
      height: height,
      onTap: onTap,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [style.accent, style.accent2],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: style.onAccent),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: style.onAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// A big-number stat tile: an oversized value with a small caption, and an
/// optional leading icon badge. The number is the hero of the tile.
class BentoStat extends ConsumerWidget {
  const BentoStat({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.valueColor,
    this.onTap,
    this.height = 116,
    this.accentFill = false,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? valueColor;
  final VoidCallback? onTap;
  final double height;
  final bool accentFill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return BentoTile(
      height: height,
      onTap: onTap,
      accentFill: accentFill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              height: 1.0,
            ).copyWith(color: valueColor ?? theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
